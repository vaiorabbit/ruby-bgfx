require 'rmath3d/rmath3d'
require 'sdl2'
require_relative '../../bindings/ruby/bgfx.rb'
require_relative './utils.rb'
require_relative 'imgui'
require_relative 'imgui_impl_bgfx'
require_relative 'imgui_impl_sdl2'

require_relative './sample.rb'
require_relative './00_helloworld.rb'
require_relative './01_cubes.rb'
require_relative './06_bump.rb'

include RMath3D

SDL2.load_lib(SampleUtils.sdl2_dll_path())
Bgfx.load_lib(SampleUtils.bgfx_dll_path())
ImGui.load_lib(SampleUtils.imgui_dll_path())

class Application

  include SDL2

  attr_reader :width, :height

  def initialize
    @width = 0
    @height = 0
    @window = nil
    @renderer = nil
    @native_window_handle = nil

    @imgui_ctx = nil

    @time = 0.0

    @samples = nil
    @current_sample = nil
    @sample_index = 0
    @sample_state = nil
  end

  def setup(width, height)
    @width = width
    @height = height

    init_status = SDL_Init(SDL_INIT_VIDEO)
    return false if init_status < 0

    @window = SDL_CreateWindow("Ruby-Bgfx : samples", 64, 64, width, height, SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE)

    renderer = SDL_CreateRenderer(@window, -1, 0)
    if renderer == nil
      $stderr.puts("Failed to initialize SDL")
      return false
    end

    @native_window_handle =  FFI::Pointer.new(:pointer, SampleUtils.native_window_handle(@window))

    pd = Bgfx_platform_data_t.new
    pd[:ndt] = nil
    pd[:nwh] = @native_window_handle
    pd[:context]      = nil
    pd[:backBuffer]   = nil
    pd[:backBufferDS] = nil
    Bgfx::bgfx_set_platform_data(pd)

    @imgui_ctx = ImGui::CreateContext()
    if @imgui_ctx == nil
      $stderr.puts("Failed to initialize ImGui")
      return false
    end
    ImGui::ImplSDL2_Init(@window)

    @samples = [
      Sample00.new,
      Sample01.new,
      Sample06.new,
    ]
    @current_sample = nil
    @sample_index = 0
    @sample_state = Sample::State::Next
  end

  def teardown
    if @current_sample != nil
      @current_sample.teardown()
      @current_sample = nil
    end

    if @imgui_ctx != nil
      ImGui::ImplSDL2_Shutdown()
      ImGui::DestroyContext(@imgui_ctx)
    end

    if @window != nil
      SDL_DestroyWindow(@window)
      SDL_Quit()
    end
  end

  def update
    @sample_index = 0
    @current_sample = @samples[@sample_index]
    @current_sample.setup(@width, @height, Bgfx::Debug_Text, Bgfx::Reset_None)
    SDL_SetWindowTitle(@window, "Ruby-Bgfx : #{@current_sample.name}")
    @sample_state = Sample::State::Continue

    event = SDL_Event.new
    done = false
    while not done
      # State transition
      if @sample_state != Sample::State::Continue
        @current_sample.teardown()
        @sample_index = (@sample_index + (@sample_state == Sample::State::Next ? +1 : -1)) % @samples.length
        @current_sample = @samples[@sample_index]
        @current_sample.setup(@width, @height, Bgfx::Debug_Text, Bgfx::Reset_None)
        SDL_SetWindowTitle(@window, "Ruby-Bgfx : #{@current_sample.name}")
        @sample_state = Sample::State::Continue
      end

      # Calculate time
      frequency = SDL2::SDL_GetPerformanceFrequency()
      current_time = SDL2::SDL_GetPerformanceCounter()

      dt = @time > 0 ? ((current_time - @time).to_f / frequency) : (1.0/60.0)
      @time = current_time

      # Handle events
      while SDL_PollEvent(event) != 0
        event_type = event[:common][:type]
        event_timestamp = event[:common][:timestamp]

        case event_type
        when SDL_WINDOWEVENT
          case event[:window][:event]
          when SDL_WINDOWEVENT_RESIZED
            width_current = event[:window][:data1]
            height_current = event[:window][:data2]
            Bgfx::bgfx_reset(width_current, height_current, Bgfx::Reset_None, Bgfx::TextureFormat::Count)
            window_width = width_current
            window_height = height_current
          end
        when SDL_KEYDOWN
          case event[:key][:keysym][:sym]
          when SDL2::SDLK_ESCAPE
            done = true
          when SDL2::SDLK_n
            @sample_state = Sample::State::Next
          when SDL2::SDLK_p
            @sample_state = Sample::State::Previous
          end
        end

        @current_sample.handle_event(event)
      end

      # Call sample update
      ImGui::ImplSDL2_NewFrame(@window)
      @current_sample.update(dt)
    end
  end

end

if __FILE__ == $PROGRAM_NAME
  begin
    app = Application.new
    setup_success = app.setup(1280, 720)
    exit if not setup_success
    app.update
  rescue => e
    pp e
  ensure
    app.teardown
  end
end
