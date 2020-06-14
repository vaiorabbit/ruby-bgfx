#
# Ref.: bgfx/examples/00-helloworld/helloworld.cpp
#

require_relative './sample'
require_relative './logo.rb'

################################################################################

class Sample00 < Sample

  def initialize
    super("00-helloworld", "https://bkaradzic.github.io/bgfx/examples.html#helloworld", "Hello")
  end

  def setup(width, height, debug, reset)
    super(width, height, debug, reset)

    init = Bgfx_init_t.new
    init[:type] = BgfxUtils.platform_renderer_type() # OpenGL / Metal
    init[:vendorId] = Bgfx::Pci_Id_None
    init[:resolution][:width] = width
    init[:resolution][:height] = height
    init[:resolution][:reset] = reset
    init[:limits][:maxEncoders] = 1
    init[:limits][:transientVbSize] = 6<<20
    init[:limits][:transientIbSize] = 2<<20
    bgfx_init_success = Bgfx::bgfx_init(init)
    $stderr.puts("Failed to initialize Bgfx") unless bgfx_init_success
    ImGui::ImplBgfx_Init()

    Bgfx::bgfx_set_debug(debug)
    Bgfx::bgfx_set_view_clear(0, Bgfx::Clear_Color|Bgfx::Clear_Depth, 0x303080ff, 1.0, 0)

    @eye.setElements(0.0, 0.0, -7.0)
    @at.setElements(0.0, 0.0, 0.0)
    @up.setElements(0.0,  1.0,  0.0)
    @mtx_view.lookAtRH( @eye, @at, @up )
    @view.write_array_of_float(@mtx_view.to_a)

    @mtx_proj.perspectiveFovRH( 60.0*Math::PI/180.0, width.to_f/height.to_f, 0.1, 100.0 )
    @proj.write_array_of_float(@mtx_proj.to_a)
  end

  def teardown()
    ImGui::ImplBgfx_Shutdown()
    Bgfx::bgfx_shutdown()
    super()
  end

  def handle_event(event)
    super(event)
  end

  def update(dt)
    ret = super(dt)
    @time += dt

    # ImGui::NewFrame()
    # ImGui::PushFont(ImGui::ImplBgfx_GetFont())
    # ImGui::ShowDemoWindow()
    # ImGui::PopFont()
    # ImGui::Render()
    # ImGui::ImplBgfx_RenderDrawData(ImGui::GetDrawData())

    Bgfx::bgfx_reset(@window_width, @window_height, @reset, Bgfx::TextureFormat::Count)

    Bgfx::bgfx_set_view_transform(0, @view, @proj)
    Bgfx::bgfx_set_view_rect(0, 0, 0, @window_width, @window_height)
    Bgfx::bgfx_touch(0)

    Bgfx::bgfx_dbg_text_clear(0, false)
    Bgfx::bgfx_dbg_text_image(
      [@window_width /2/8, 20].max - 20,
      [@window_height /2/16, 6].max - 6,
      40,
      12,
      FFI::MemoryPointer.from_string(BGFX_LOGO_PATTERN.pack("C*")),
      160
    )

    Bgfx::bgfx_dbg_text_printf(0, 0, 0x0f, "Color can be changed with ANSI \x1b[9;me\x1b[10;ms\x1b[11;mc\x1b[12;ma\x1b[13;mp\x1b[14;me\x1b[0m code too.")
    Bgfx::bgfx_dbg_text_printf(0, 1, 0x0f, "\x1b[;0m    \x1b[;1m    \x1b[; 2m    \x1b[; 3m    \x1b[; 4m    \x1b[; 5m    \x1b[; 6m    \x1b[; 7m    \x1b[0m")
    Bgfx::bgfx_dbg_text_printf(0, 2, 0x0f, "\x1b[;8m    \x1b[;9m    \x1b[;10m    \x1b[;11m    \x1b[;12m    \x1b[;13m    \x1b[;14m    \x1b[;15m    \x1b[0m")

    Bgfx::bgfx_frame(false)

    return ret
  end

end
