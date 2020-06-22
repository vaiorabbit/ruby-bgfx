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
    Quit = 4
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
    return Sample::State::Continue
  end

end

####################################################################################################

class SampleDialog

  @@state = Sample::State::Continue

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
    ImGui::SetNextWindowPos(ImVec2.create(10.0, 50.0), ImGuiCond_FirstUseEver)
    ImGui::SetNextWindowSize(ImVec2.create(300.0, 210.0), ImGuiCond_FirstUseEver)
    ImGui::Begin(sample.name)
    ImGui::TextWrapped("%s", :string, sample.desc)
    # if ImGui::IsItemHovered()
    #   ImGui::BeginTooltip()
    #   ImGui::PushTextWrapPos(ImGui::GetFontSize() * 35.0)
    #   ImGui::TextWrapped("%s", :string, sample.desc)
    #   ImGui::PopTextWrapPos()
    #   ImGui::EndTooltip()
    # end

    ImGui::SameLine()
    if ImGui::Button("Doc")
      open_browser(sample.url)
    elsif ImGui::IsItemHovered()
      ImGui::SetTooltip("Documentation: %s", :string, sample.url)
    end
    ImGui::Separator()
    if ImGui::Button("⟳ Restart")
    end
    ImGui::End()
  end

end
