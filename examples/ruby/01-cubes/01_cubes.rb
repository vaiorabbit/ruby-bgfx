#
# Ref.: bgfx/examples/01-cubes/cubes.cpp
#       https://github.com/vaiorabbit/sdl2-bindings
#

require_relative '../common/sample'

################################################################################

class Sample01 < Sample

  class PosColorVertex < FFI::Struct
    @@ms_layout = nil

    def self.ms_layout
      @@ms_layout
    end

    layout(
      :m_x, :float,
      :m_y, :float,
      :m_z, :float,
      :m_abgr, :uint32
    )

    def self.init()
      if @@ms_layout == nil
        @@ms_layout = Bgfx_vertex_layout_t.new

        @@ms_layout.begin()
        @@ms_layout.add(Bgfx::Attrib::Position, 3, Bgfx::AttribType::Float)
        @@ms_layout.add(Bgfx::Attrib::Color0, 4, Bgfx::AttribType::Uint8, true)
        @@ms_layout.end
      end
    end
  end

  # Ref: Array of Structs https://github.com/ffi/ffi/wiki/Structs

  @@cubeVerticesSrc = [
    [-1.0,  1.0,  1.0, 0xff000000 ],
    [ 1.0,  1.0,  1.0, 0xff0000ff ],
    [-1.0, -1.0,  1.0, 0xff00ff00 ],
    [ 1.0, -1.0,  1.0, 0xff00ffff ],
    [-1.0,  1.0, -1.0, 0xffff0000 ],
    [ 1.0,  1.0, -1.0, 0xffff00ff ],
    [-1.0, -1.0, -1.0, 0xffffff00 ],
    [ 1.0, -1.0, -1.0, 0xffffffff ],
  ]

  @@s_cubeVertices = FFI::MemoryPointer.new(PosColorVertex, @@cubeVerticesSrc.length)
  @@cubeVertices = @@cubeVerticesSrc.length.times.collect do |i|
    PosColorVertex.new(@@s_cubeVertices + i * PosColorVertex.size)
  end

  @@cubeVertices.each_with_index do |c, i|
    c[:m_x], c[:m_y], c[:m_z], c[:m_abgr] = *@@cubeVerticesSrc[i]
  end


  @@cubeTriListSrc = [
    0, 1, 2, # 0
    1, 3, 2,
    4, 6, 5, # 2
    5, 6, 7,
    0, 2, 4, # 4
    4, 2, 6,
    1, 5, 3, # 6
    5, 7, 3,
    0, 4, 1, # 8
    4, 5, 1,
    2, 3, 6, # 10
    6, 3, 7,
  ]
  @@s_cubeTriList = FFI::MemoryPointer.new(:uint16, @@cubeTriListSrc.length).write_array_of_ushort(@@cubeTriListSrc)

  @@cubeTriStripSrc = [
    0, 1, 2,
    3,
    7,
    1,
    5,
    0,
    4,
    2,
    6,
    7,
    4,
    5,
  ]
  @@s_cubeTriStrip = FFI::MemoryPointer.new(:uint16, @@cubeTriStripSrc.length).write_array_of_ushort(@@cubeTriStripSrc)

  @@cubeLineListSrc = [
    0, 1,
    0, 2,
    0, 4,
    1, 3,
    1, 5,
    2, 3,
    2, 6,
    3, 7,
    4, 5,
    4, 6,
    5, 7,
    6, 7,
  ]
  @@s_cubeLineList = FFI::MemoryPointer.new(:uint16, @@cubeLineListSrc.length).write_array_of_ushort(@@cubeLineListSrc)

  @@cubeLineStripSrc = [
    0, 2, 3, 1, 5, 7, 6, 4,
    0, 2, 6, 4, 5, 7, 3, 1,
    0,
  ]
  @@s_cubeLineStrip = FFI::MemoryPointer.new(:uint16, @@cubeLineStripSrc.length).write_array_of_ushort(@@cubeLineStripSrc)

  @@cubePointsSrc = [
    0, 1, 2, 3, 4, 5, 6, 7
  ]
  @@s_cubePoints = FFI::MemoryPointer.new(:uint16, @@cubePointsSrc.length).write_array_of_ushort(@@cubePointsSrc)

  @@s_ptNames = [
    "Triangle List",
    "Triangle Strip",
    "Lines",
    "Line Strip",
    "Points",
  ]

  @@s_ptState = [
    0, # Triangles
    Bgfx::State_Pt_Tristrip,
    Bgfx::State_Pt_Lines,
    Bgfx::State_Pt_Linestrip,
    Bgfx::State_Pt_Points,
  ]

  ################################################################################

  def initialize
    super("01-cubes", "https://bkaradzic.github.io/bgfx/examples.html#cubes", "Rendering simple static mesh.")
    @ndc_homogeneous = true

    @m_vbh = nil
    @m_ibh = nil
    @m_program = nil
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
    bgfx_init_success = Bgfx::init(init)
    $stderr.puts("Failed to initialize Bgfx") unless bgfx_init_success

    bgfx_caps = Bgfx_caps_t.new(Bgfx::get_caps())
    @ndc_homogeneous = bgfx_caps[:homogeneousDepth]

    ImGui::ImplBgfx_Init()

    Bgfx::set_debug(debug)
    Bgfx::set_view_clear(0, Bgfx::Clear_Color|Bgfx::Clear_Depth, 0x303080ff)

    PosColorVertex.init()

    @m_vbh = Bgfx::create_vertex_buffer(
      Bgfx::make_ref(@@s_cubeVertices, @@s_cubeVertices.size),
      PosColorVertex.ms_layout,
      Bgfx::Buffer_None
    )

    @m_ibh = []
    @m_ibh[0] = Bgfx::create_index_buffer(Bgfx::make_ref(@@s_cubeTriList, @@s_cubeTriList.size))
    @m_ibh[1] = Bgfx::create_index_buffer(Bgfx::make_ref(@@s_cubeTriStrip, @@s_cubeTriStrip.size))
    @m_ibh[2] = Bgfx::create_index_buffer(Bgfx::make_ref(@@s_cubeLineList, @@s_cubeLineList.size))
    @m_ibh[3] = Bgfx::create_index_buffer(Bgfx::make_ref(@@s_cubeLineStrip, @@s_cubeLineStrip.size))
    @m_ibh[4] = Bgfx::create_index_buffer(Bgfx::make_ref(@@s_cubePoints, @@s_cubePoints.size))

    @m_program = BgfxUtils.load_program("vs_cubes", "fs_cubes")

    @eye.setElements(0.0, 0.0, -35.0)
    @at.setElements(0.0, 0.0, 0.0)
    @up.setElements(0.0,  1.0,  0.0)
    @mtx_view.lookAtRH( @eye, @at, @up )
    @view.write_array_of_float(@mtx_view.to_a)

    @mtx_proj.perspectiveFovRH( 60.0*Math::PI/180.0, width.to_f/height.to_f, 0.1, 100.0, @ndc_homogeneous )
    @proj.write_array_of_float(@mtx_proj.to_a)
  end

  def teardown()
    ImGui::ImplBgfx_Shutdown()

    Bgfx::destroy_program(@m_program) if @m_program
    Bgfx::destroy_vertex_buffer(@m_vbh) if @m_vbh
    @m_ibh.each do |ibh|
      Bgfx::destroy_index_buffer(ibh) if ibh
    end
    Bgfx::shutdown()

    super()
  end

  def handle_event(event)
    super(event)
  end

  def update(dt)
    ret = super(dt)
    @time += dt

    Bgfx::reset(@window_width, @window_height, @reset)

    # ImGui::NewFrame()
    # ImGui::PushFont(ImGui::ImplBgfx_GetFont())
    # ImGui::ShowDemoWindow()
    # ImGui::PopFont()
    # ImGui::Render()
    # ImGui::ImplBgfx_RenderDrawData(ImGui::GetDrawData())

    Bgfx::set_view_transform(0, @view, @proj)
    Bgfx::set_view_rect(0, 0, 0, @window_width, @window_height)
    Bgfx::touch(0)

    ibh = @m_ibh[0] # TODO use enum
    state = 0 | Bgfx::State_Write_R | Bgfx::State_Write_G | Bgfx::State_Write_B | Bgfx::State_Write_A | Bgfx::State_Write_Z | Bgfx::State_Depth_Test_Less | Bgfx::State_Cull_Cw | Bgfx::State_Msaa | @@s_ptState[0] # TODO use enum

    mtx_t, mtx_ry, mtx_rx = RMtx4.new, RMtx4.new, RMtx4.new
    xfrm = FFI::MemoryPointer.new(:float, 16)
    11.times do |yy|
      11.times do |xx|
        mtx_transform = mtx_t.translation(-15.0 + xx * 3.0, -15.0 + yy * 3.0, 0.0) * mtx_ry.rotationY(@time + yy * 0.37) * mtx_rx.rotationX(@time + xx * 0.21)
        xfrm.write_array_of_float(mtx_transform.to_a)
        Bgfx::set_transform(xfrm, 1)
        Bgfx::set_vertex_buffer(0, @m_vbh, 0, 0xffffffff) # 0xffffffff == UINT32_MAX
        Bgfx::set_index_buffer(ibh, 0, 0xffffffff) # 0xffffffff == UINT32_MAX
        Bgfx::set_state(state)

        Bgfx::submit(0, @m_program)
      end
    end

    Bgfx::frame()

  end

end
