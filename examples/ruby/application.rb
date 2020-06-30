# require 'ruby-prof'
require 'rmath3d/rmath3d'
require 'sdl2'
require_relative '../../bindings/ruby/bgfx'
require_relative 'imgui'
require_relative 'imgui_impl_bgfx'
require_relative 'imgui_impl_sdl2'

require_relative 'common/utils'
require_relative 'common/sample'
require_relative '00-helloworld/00_helloworld'
require_relative '01-cubes/01_cubes'
require_relative '02-metaballs/02_metaballs'
require_relative '03-raymarch/raymarch'
require_relative '06-bump/06_bump'

include RMath3D

SDL2.load_lib(SampleUtils.sdl2_dll_path())
Bgfx.load_lib(SampleUtils.bgfx_dll_path("Debug"))
ImGui.load_lib(SampleUtils.imgui_dll_path())

# RubyProf::measure_mode = RubyProf::WALL_TIME

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
    # @sample_state = nil
    # @sample_paused = false
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
    Bgfx::set_platform_data(pd)

    @imgui_ctx = ImGui::CreateContext()
    if @imgui_ctx == nil
      $stderr.puts("Failed to initialize ImGui")
      return false
    end
    ImGui::ImplSDL2_Init(@window)

    @samples = [
      Sample02.new,
      Sample00.new,
      Sample01.new,
      Sample03.new,
      Sample06.new,
    ]
    @current_sample = nil
    @sample_index = 0

    SampleDialog::register_samples(@samples)
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
    sample_state = Sample::State::Continue

    event = SDL_Event.new
    while sample_state != Sample::State::Quit

      sample_state, sample_switchto = SampleDialog::get_state() # sample_switchto == one of sample instances selected in the combobox of SampleDialog
      sample_paused = sample_state == Sample::State::Pause

      # State transition
      case sample_state
      when Sample::State::Next, Sample::State::Previous
        @current_sample.teardown()
        @sample_index = (@sample_index + (sample_state == Sample::State::Next ? +1 : -1)) % @samples.length
        @current_sample = @samples[@sample_index]
        @current_sample.setup(@width, @height, Bgfx::Debug_Text, Bgfx::Reset_None)
        SDL_SetWindowTitle(@window, "Ruby-Bgfx : #{@current_sample.name}")
      when Sample::State::SwitchTo
        @current_sample.teardown()
        @sample_index = @samples.find_index(sample_switchto)
        @current_sample = @samples[@sample_index]
        @current_sample.setup(@width, @height, Bgfx::Debug_Text, Bgfx::Reset_None)
        SDL_SetWindowTitle(@window, "Ruby-Bgfx : #{@current_sample.name}")
      when Sample::State::Restart
        @current_sample.teardown()
        @current_sample.setup(@width, @height, Bgfx::Debug_Text, Bgfx::Reset_None)
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
            @width = width_current
            @height = height_current
            @current_sample.resize(@width, @height)

            SDL_SetWindowSize(@window, @width, @height)
          end
        when SDL_KEYDOWN
=begin
          case event[:key][:keysym][:sym]
          when SDL2::SDLK_ESCAPE
            done = true
          when SDL2::SDLK_n
            @sample_state = Sample::State::Next
          when SDL2::SDLK_p
            @sample_state = Sample::State::Previous
          end
=end
        end

        @current_sample.handle_event(event)
      end

      # Call sample update
      ImGui::ImplSDL2_NewFrame(@window)
      @current_sample.update(sample_paused ? 0.0 : dt)
    end
  end

end

if __FILE__ == $PROGRAM_NAME
  begin
    # RubyProf.start
    app = Application.new
    setup_success = app.setup(1280, 720)
    exit if not setup_success
    app.update
  rescue => e
    pp e
  ensure
    app.teardown
    result = RubyProf.stop
    # printer = RubyProf::FlatPrinter.new(result)
    # printer.print(STDOUT)
  end
end
