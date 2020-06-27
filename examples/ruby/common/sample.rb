# coding: utf-8
require 'rmath3d/rmath3d'
require 'sdl2'
require_relative '../../../bindings/ruby/bgfx'
require_relative '../imgui'
require_relative '../imgui_impl_bgfx'
require_relative 'utils'

class Sample

  attr_reader :name, :url, :desc
  attr_accessor :window_width, :window_height, :debug, :reset

  module State
    Continue = 0
    Next = 1
    Previous = 2
    SwitchTo = 3
    Restart = 4
    Pause = 5
    Resume = 6
    Quit = 7
  end

  def initialize(name = "", url = "", desc = "")
    @name = name
    @url = url
    @desc = desc

    @window_width = 0
    @window_height = 0
    @debug = Bgfx::Debug_None
    @reset = Bgfx::Reset_Vsync

    @eye = RMath3D::RVec3.new
    @at  = RMath3D::RVec3.new
    @up  = RMath3D::RVec3.new
    @mtx_view = RMath3D::RMtx4.new
    @view = FFI::MemoryPointer.new(:float, 16)

    @mtx_proj = RMath3D::RMtx4.new
    @proj =  FFI::MemoryPointer.new(:float, 16)

    @time = 0.0
  end

  def setup(width, height, debug, reset)
    @window_width = width
    @window_height = height
    @debug = debug
    @reset = reset
    @time = 0.0

    return true
  end

  def resize(width, height)
    @window_width = width
    @window_height = height
  end

  def teardown()
  end

  def handle_event(event)
  end

  def update(dt)
  end

end

####################################################################################################

class SampleData
  attr_reader :m_offset, :m_values, :m_min, :m_max, :m_avg

  NumSamples = 100

  def initialize
    @m_values = Array.new(NumSamples)
    reset()
  end

  def reset
    @m_offset = 0
    @m_values.fill(0.0)
    @m_min = 0.0
    @m_max = 0.0
    @m_avg = 0.0
  end

  def push_sample(value)
    @m_values[@m_offset] = value
    @m_offset = (@m_offset + 1) % NumSamples

    min = Float::MAX
    max = -Float::MAX
    avg = 0.0
    NumSamples.times do |ii|
      val = @m_values[ii]
      min = min < val ? min : val
      max = max > val ? max : val
      avg += val
    end

    @m_min = min
    @m_max = max
    @m_avg = avg / NumSamples
  end

end

####################################################################################################

class SampleDialog

  @@s_frame_time = SampleData.new
  @@samples = nil

  @@state = Sample::State::Continue
  @@info = nil
  @@paused = false

  @@combo_current = nil
  @@combo_items_string = nil
  @@combo_items = nil

  @@show_stats = FFI::MemoryPointer.new(:bool, 1)

  def self.register_samples(samples)
    @@samples = samples

    @@combo_current =  FFI::MemoryPointer.new(:int, 1)
    @@combo_items_string = @@samples.map {|s| FFI::MemoryPointer.from_string(s.name)}
    @@combo_items = FFI::MemoryPointer.new(:pointer, @@samples.length).write_array_of_pointer(@@combo_items_string)
  end

  def self.get_state()
    return @@state, @@info
  end

  def self.open_browser(url)
    case RUBY_PLATFORM
    when /mswin|msys|mingw|cygwin/
      system("start", url)
    when /darwin/
      system("open", url)
    else
      $stderr.puts("[ERROR] SampleDialog::open_browser : Unknown OS: #{RUBY_PLATFORM}")
    end
  end

  def self.bar(_width, _maxWidth, _height, _color)
    style = ImGuiStyle.new(ImGui::GetStyle())

    hoveredColor = ImVec4.create(
      _color[:x] + _color[:x]*0.1,
      _color[:y] + _color[:y]*0.1,
      _color[:z] + _color[:z]*0.1,
      _color[:w] + _color[:w]*0.1)

    ImGui::PushStyleColorVec4(ImGuiCol_Button,        _color)
    ImGui::PushStyleColorVec4(ImGuiCol_ButtonHovered, hoveredColor)
    ImGui::PushStyleColorVec4(ImGuiCol_ButtonActive,  _color)
    ImGui::PushStyleVarFloat(ImGuiStyleVar_FrameRounding, 0.0)
    ImGui::PushStyleVarVec2(ImGuiStyleVar_ItemSpacing, ImVec2.create(0.0, style[:ItemSpacing][:y]) )

    itemHovered = false

    ImGui::Button("", ImVec2.create(_width, _height) )
    itemHovered |= ImGui::IsItemHovered()

    ImGui::SameLine()
    ImGui::InvisibleButton("", ImVec2.create([1.0, _maxWidth-_width].max, _height))
    itemHovered |= ImGui::IsItemHovered()

    ImGui::PopStyleVar(2)
    ImGui::PopStyleColor(3)

    return itemHovered;
  end

  @@s_resourceColor = ImVec4.create(0.5, 0.5, 0.5, 1.0)

  def self.resource_bar(_name, _tooltip, _num, _max, _maxWidth, _height)
    itemHovered = false

    ImGui::Text("%s: %4d / %4d", :string, _name, :int32, _num, :int32, _max)
    itemHovered |= ImGui::IsItemHovered()
    ImGui::SameLine()

    percentage = _num.to_f / _max

    itemHovered |= bar([1.0, percentage*_maxWidth].max, _maxWidth, _height, @@s_resourceColor)
    ImGui::SameLine()

    ImGui::Text("%5.2f%%", :float, percentage*100.0)

    if itemHovered
      ImGui::SetTooltip("%s %5.2f%%", :string, _tooltip, :float, percentage*100.00)
    end
  end

  def self.show(sample)

    @@state = Sample::State::Continue if not @@paused
    @@info = nil

    ImGui::PushFont(ImGui::ImplBgfx_GetUIFont())

    # Size and position of this window
    ImGui::SetNextWindowPos(ImVec2.create(10.0, 50.0), ImGuiCond_FirstUseEver)
    ImGui::SetNextWindowSize(ImVec2.create(300.0, 230.0), ImGuiCond_FirstUseEver)
    ImGui::Begin(sample.name)
    ImGui::TextWrapped("%s", :string, sample.desc)

    # Jump to documentation
    ImGui::SameLine()
    if ImGui::Button("Doc")
      open_browser(sample.url)
    elsif ImGui::IsItemHovered()
      ImGui::SetTooltip("Documentation: %s", :string, sample.url)
    end
    ImGui::Separator()

    # Example combobox
    if @@samples != nil
      if ImGui::ComboStr_arr("Example", @@combo_current, @@combo_items, @@samples.length)
        @@state = Sample::State::SwitchTo
        @@info = @@samples[@@combo_current.read_int]
        @@paused = false
      end
    end

    # Restart / Previous / Pause&Resume / Next / Quit
    ctrl_button_wh = ImVec2.create(ImGui::GetFontSize() * 1.2, 0)
    text_wrap_pos = ImGui::GetFontSize() * 35.0

    if ImGui::Button("↺", ctrl_button_wh)
      @@state = Sample::State::Restart
      @@paused = false
    elsif ImGui::IsItemHovered()
      ImGui::BeginTooltip()
      ImGui::PushTextWrapPos(text_wrap_pos)
      ImGui::TextWrapped("Restart")
      ImGui::PopTextWrapPos()
      ImGui::EndTooltip()
    end

    ImGui::SameLine()
    if ImGui::Button("◁", ctrl_button_wh)
      @@state = Sample::State::Previous
      @@combo_current.write_int((@@combo_current.read_int - 1) % @@samples.length)
      @@paused = false
    elsif ImGui::IsItemHovered()
      ImGui::BeginTooltip()
      ImGui::PushTextWrapPos(text_wrap_pos)
      ImGui::TextWrapped("Previous")
      ImGui::PopTextWrapPos()
      ImGui::EndTooltip()
    end

    ImGui::SameLine()
    if @@paused
      if ImGui::Button("⧐", ctrl_button_wh)
        @@state = Sample::State::Resume
        @@paused = false
      elsif ImGui::IsItemHovered()
        ImGui::BeginTooltip()
        ImGui::PushTextWrapPos(text_wrap_pos)
        ImGui::TextWrapped("Resume")
        ImGui::PopTextWrapPos()
        ImGui::EndTooltip()
      end
    else
      if ImGui::Button("||", ctrl_button_wh)
        @@state = Sample::State::Pause
        @@paused = true
      elsif ImGui::IsItemHovered()
        ImGui::BeginTooltip()
        ImGui::PushTextWrapPos(text_wrap_pos)
        ImGui::TextWrapped("Pause")
        ImGui::PopTextWrapPos()
        ImGui::EndTooltip()
      end
    end

    ImGui::SameLine()
    if ImGui::Button("▷", ctrl_button_wh)
      @@state = Sample::State::Next
      @@combo_current.write_int((@@combo_current.read_int + 1) % @@samples.length)
      @@paused = false
    elsif ImGui::IsItemHovered()
      ImGui::BeginTooltip()
      ImGui::PushTextWrapPos(text_wrap_pos)
      ImGui::TextWrapped("Next")
      ImGui::PopTextWrapPos()
      ImGui::EndTooltip()
    end

    ImGui::SameLine()
    if ImGui::Button("◻", ctrl_button_wh)
      @@state = Sample::State::Quit
    elsif ImGui::IsItemHovered()
      ImGui::BeginTooltip()
      ImGui::PushTextWrapPos(text_wrap_pos)
      ImGui::TextWrapped("Quit application")
      ImGui::PopTextWrapPos()
      ImGui::EndTooltip()
    end

    ImGui::SameLine()
    if ImGui::Button("⤨", ctrl_button_wh)
      @@show_stats.write(:bool, !@@show_stats.read(:bool))
    elsif ImGui::IsItemHovered()
      ImGui::BeginTooltip()
      ImGui::PushTextWrapPos(text_wrap_pos)
      ImGui::TextWrapped("Show Stats")
      ImGui::PopTextWrapPos()
      ImGui::EndTooltip()
    end

    # GPU/CPU time stats
    stats = Bgfx_stats_t.new(Bgfx::get_stats())
    toMsCpu = 1000.0/stats[:cpuTimerFreq]
    toMsGpu = 1000.0/stats[:gpuTimerFreq]
    frameMs = stats[:cpuTimeFrame].to_f * toMsCpu

    @@s_frame_time.push_sample(frameMs.to_f)

    frame_text_overlay = sprintf("⤓ %.3fms,  ⤒ %.3fms\nAvg: %.3fms, %.1f FPS", @@s_frame_time.m_min, @@s_frame_time.m_max, @@s_frame_time.m_avg, 1000.0 / @@s_frame_time.m_avg)

    ImGui::PushStyleColorVec4(ImGuiCol_PlotHistogram, ImVec4.create(0.0, 0.5, 0.15, 1.0))
    ImGui::PlotHistogramFloatPtr("Frame",
                                 @@s_frame_time.m_values.pack("F*"),
                                 SampleData::NumSamples,
                                 @@s_frame_time.m_offset,
                                 frame_text_overlay,
                                 0.0,
                                 60.0,
                                 ImVec2.create(0.0, 50.0))
    ImGui::PopStyleColor()

    ImGui::Text("Submit CPU %0.3f, GPU %0.3f (L: %d)",
                :float, (stats[:cpuTimeEnd] - stats[:cpuTimeBegin]).to_f * toMsCpu,
                :float, (stats[:gpuTimeEnd] - stats[:gpuTimeBegin]).to_f * toMsGpu,
                :int32, stats[:maxGpuLatency])

    if stats[:gpuMemoryUsed] != -0x7fffffffffffffff # INT64_MAX
      ImGui::Text("GPU mem: #{stats[:gpuMemoryUsed]} / #{stats[:gpuMemoryMax]}")
    end

    # bgfx internal stats
    if @@show_stats.read(:bool) == true
      ImGui::SetNextWindowSize(ImVec2.create(300.0, 500.0), ImGuiCond_FirstUseEver)
      if ImGui::Begin("⤨ Stats", @@show_stats)
        if ImGui::CollapsingHeaderTreeNodeFlags("Resources")
          caps = Bgfx_caps_t.new(Bgfx::get_caps())
          itemHeight = ImGui::GetTextLineHeightWithSpacing()
          maxWidth   = 90.0
          ImGui::PushFont(ImGui::ImplBgfx_GetMonoFont())
          ImGui::Text("Res: Num  / Max")
          resource_bar("DIB", "Dynamic index buffers",  stats[:numDynamicIndexBuffers],  caps[:limits][:maxDynamicIndexBuffers],  maxWidth, itemHeight)
          resource_bar("DVB", "Dynamic vertex buffers", stats[:numDynamicVertexBuffers], caps[:limits][:maxDynamicVertexBuffers], maxWidth, itemHeight)
          resource_bar(" FB", "Frame buffers",          stats[:numFrameBuffers],         caps[:limits][:maxFrameBuffers],         maxWidth, itemHeight)
          resource_bar(" IB", "Index buffers",          stats[:numIndexBuffers],         caps[:limits][:maxIndexBuffers],         maxWidth, itemHeight)
          resource_bar(" OQ", "Occlusion queries",      stats[:numOcclusionQueries],     caps[:limits][:maxOcclusionQueries],     maxWidth, itemHeight)
          resource_bar("  P", "Programs",               stats[:numPrograms],             caps[:limits][:maxPrograms],             maxWidth, itemHeight)
          resource_bar("  S", "Shaders",                stats[:numShaders],              caps[:limits][:maxShaders],              maxWidth, itemHeight)
          resource_bar("  T", "Textures",               stats[:numTextures],             caps[:limits][:maxTextures],             maxWidth, itemHeight)
          resource_bar("  U", "Uniforms",               stats[:numUniforms],             caps[:limits][:maxUniforms],             maxWidth, itemHeight)
          resource_bar(" VB", "Vertex buffers",         stats[:numVertexBuffers],        caps[:limits][:maxVertexBuffers],        maxWidth, itemHeight)
          resource_bar(" VL", "Vertex layouts",         stats[:numVertexLayouts],        caps[:limits][:maxVertexLayouts],        maxWidth, itemHeight)
          ImGui::PopFont()
        end
        if ImGui::CollapsingHeaderTreeNodeFlags("Profiler")
          if stats[:numViews] == 0
            ImGui::Text("Profiler is not enabled.")
          else
            # TODO
          end
        end
      end
      ImGui::End()
    end

    ImGui::PopFont()

    ImGui::End()
  end

end
