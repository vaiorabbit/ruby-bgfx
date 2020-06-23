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
    Restart = 3
    Pause = 4
    Resume = 5
    Quit = 6
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

  @@state = Sample::State::Continue
  @@paused = false

  def self.get_state()
    @@state
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

  def self.show(sample)

    @@state = Sample::State::Continue if not @@paused

    ImGui::SetNextWindowPos(ImVec2.create(10.0, 50.0), ImGuiCond_FirstUseEver)
    ImGui::SetNextWindowSize(ImVec2.create(300.0, 210.0), ImGuiCond_FirstUseEver)
    ImGui::Begin(sample.name)
    ImGui::TextWrapped("%s", :string, sample.desc)

    ImGui::SameLine()
    if ImGui::Button("Doc")
      open_browser(sample.url)
    elsif ImGui::IsItemHovered()
      ImGui::SetTooltip("Documentation: %s", :string, sample.url)
    end
    ImGui::Separator()

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
      if ImGui::Button("◻", ctrl_button_wh)
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
      @@paused = false
    elsif ImGui::IsItemHovered()
      ImGui::BeginTooltip()
      ImGui::PushTextWrapPos(text_wrap_pos)
      ImGui::TextWrapped("Next")
      ImGui::PopTextWrapPos()
      ImGui::EndTooltip()
    end

    ImGui::SameLine()
    if ImGui::Button("ℚ", ctrl_button_wh)
      @@state = Sample::State::Quit
    elsif ImGui::IsItemHovered()
      ImGui::BeginTooltip()
      ImGui::PushTextWrapPos(text_wrap_pos)
      ImGui::TextWrapped("Quit application")
      ImGui::PopTextWrapPos()
      ImGui::EndTooltip()
    end

    stats = Bgfx_stats_t.new(Bgfx::get_stats())
    toMsCpu = 1000.0/stats[:cpuTimerFreq]
    toMsGpu = 1000.0/stats[:gpuTimerFreq]
    frameMs = stats[:cpuTimeFrame].to_f * toMsCpu

    @@s_frame_time.push_sample(frameMs.to_f)

    frame_text_overlay = sprintf("↓ %.3fms, ↑ %.3fms\nAvg: %.3fms, %.1f FPS", @@s_frame_time.m_min, @@s_frame_time.m_max, @@s_frame_time.m_avg, 1000.0 / @@s_frame_time.m_avg)

    ImGui::PushStyleColorVec4(ImGuiCol_PlotHistogram, ImVec4.create(0.0, 0.5, 0.15, 1.0))
    ImGui::PlotHistogramFloatPtr("Frame",
                                 @@s_frame_time.m_values.pack("F*"),
                                 SampleData::NumSamples,
                                 @@s_frame_time.m_offset,
                                 frame_text_overlay,
                                 0.0,
                                 60.0,
                                 ImVec2.create(0.0, 45.0))
    ImGui::PopStyleColor()

    ImGui::Text("Submit CPU %0.3f, GPU %0.3f (L: %d)",
                 :float, (stats[:cpuTimeEnd] - stats[:cpuTimeBegin]).to_f * toMsCpu,
                 :float, (stats[:gpuTimeEnd] - stats[:gpuTimeBegin]).to_f * toMsGpu,
                 :int32, stats[:maxGpuLatency])

    if stats[:gpuMemoryUsed] != -0x7fffffffffffffff # INT64_MAX
      ImGui::Text("GPU mem: #{stats[:gpuMemoryUsed]} / #{stats[:gpuMemoryMax]}")
    end

    ImGui::End()
  end

end
