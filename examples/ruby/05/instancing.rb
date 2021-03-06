#
# Ref.: bgfx/examples/05-instancing/instancing.cpp
#       https://github.com/vaiorabbit/sdl2-bindings
#

require_relative '../common/sample'

################################################################################

class Sample05 < Sample
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

    def self.init
      if @@ms_layout.nil?
        @@ms_layout = Bgfx_vertex_layout_t.new

        @@ms_layout.begin
        @@ms_layout.add(Bgfx::Attrib::Position, 3, Bgfx::AttribType::Float)
        @@ms_layout.add(Bgfx::Attrib::Color0, 4, Bgfx::AttribType::Uint8, true)
        @@ms_layout.end
      end
    end
  end

  # Ref: Array of Structs https://github.com/ffi/ffi/wiki/Structs

  @@cubeVerticesSrc = [
    [-1.0, 1.0, 1.0, 0xff000000],
    [1.0,  1.0, 1.0, 0xff0000ff],
    [-1.0, -1.0, 1.0, 0xff00ff00],
    [1.0, -1.0,  1.0, 0xff00ffff],
    [-1.0, 1.0, -1.0, 0xffff0000],
    [1.0,  1.0, -1.0, 0xffff00ff],
    [-1.0, -1.0, -1.0, 0xffffff00],
    [1.0, -1.0, -1.0, 0xffffffff]
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
    6, 3, 7
  ]
  @@s_cubeTriList = FFI::MemoryPointer.new(:uint16, @@cubeTriListSrc.length).write_array_of_ushort(@@cubeTriListSrc)

  ################################################################################

  def initialize
    super('05-instancing', 'https://bkaradzic.github.io/bgfx/examples.html#instancing', 'Geometry instancing')
    @ndc_homogeneous = true

    @m_vbh = nil
    @m_ibh = nil
    @m_program = nil

    @instancing_supported = nil
  end

  def setup(width, height, debug, reset)
    super(width, height, debug, reset)

    @debug |= Bgfx::Debug_Text
    @reset |= Bgfx::Reset_Vsync

    init = Bgfx_init_t.new
    init[:type] = BgfxUtils.platform_renderer_type # OpenGL / Metal
    init[:vendorId] = Bgfx::Pci_Id_None
    init[:resolution][:width] = width
    init[:resolution][:height] = height
    init[:resolution][:reset] = reset
    init[:limits][:maxEncoders] = 1
    init[:limits][:transientVbSize] = 6 << 20
    init[:limits][:transientIbSize] = 2 << 20
    bgfx_init_success = Bgfx.init(init)
    warn('Failed to initialize Bgfx') unless bgfx_init_success

    bgfx_caps = Bgfx_caps_t.new(Bgfx.get_caps)
    @ndc_homogeneous = bgfx_caps[:homogeneousDepth]
    @instancing_supported = (bgfx_caps[:supported] & Bgfx::Caps_Instancing) != 0

    ImGui::ImplBgfx_Init()

    Bgfx.set_debug(@debug)
    Bgfx.set_view_clear(0, Bgfx::Clear_Color | Bgfx::Clear_Depth, 0x303080ff)

    PosColorVertex.init

    @m_vbh = Bgfx.create_vertex_buffer(
      Bgfx.make_ref(@@s_cubeVertices, @@s_cubeVertices.size),
      PosColorVertex.ms_layout,
      Bgfx::Buffer_None
    )

    @m_ibh = Bgfx.create_index_buffer(Bgfx.make_ref(@@s_cubeTriList, @@s_cubeTriList.size))

    @m_program = BgfxUtils.load_program('vs_instancing', 'fs_instancing', "#{__dir__}/../")
    # @m_program = BgfxUtils.load_program("vs_cubes", "fs_cubes", "#{__dir__}/../")

    @eye.setElements(0.0, 0.0, -35.0)
    @at.setElements(0.0, 0.0, 0.0)
    @up.setElements(0.0, 1.0, 0.0)
    @mtx_view.lookAtRH(@eye, @at, @up)
    @view.write_array_of_float(@mtx_view.to_a)
    resize(width, height)
  end

  def teardown
    ImGui::ImplBgfx_Shutdown()

    Bgfx.destroy_program(@m_program) if @m_program
    Bgfx.destroy_vertex_buffer(@m_vbh) if @m_vbh
    Bgfx.destroy_index_buffer(@m_ibh) if @m_ibh
    Bgfx.shutdown

    super()
  end

  def resize(width, height)
    super(width, height)
    @mtx_proj.perspectiveFovRH(60.0 * Math::PI / 180.0, width.to_f / height.to_f, 0.1, 100.0, @ndc_homogeneous)
    @proj.write_array_of_float(@mtx_proj.to_a)
  end

  def update(dt)
    super(dt)
    @time += dt

    Bgfx.reset(@window_width, @window_height, @reset)

    ImGui::NewFrame()
    SampleDialog.show(self)

    Bgfx.set_view_transform(0, @view, @proj)
    Bgfx.set_view_rect(0, 0, 0, @window_width, @window_height)
    Bgfx.touch(0)

    if @instancing_supported
      instanceStride = 80 # 80 bytes stride = 64 bytes for 4x4 matrix + 16 bytes for RGBA color.
      numInstances   = 121 # 11x11 cubes
      if numInstances == Bgfx.get_avail_instance_data_buffer(numInstances, instanceStride)
        idb = Bgfx_instance_data_buffer_t.new
        Bgfx.alloc_instance_data_buffer(idb, numInstances, instanceStride) # TODO alloc_instance_data_buffer should not return any value

        mtx_t = RMtx4.new
        mtx_ry = RMtx4.new
        mtx_rx = RMtx4.new
        offset = 0
        11.times do |yy|
          11.times do |xx|
            mtx_ptr = idb[:data] + offset
            mtx_transform = mtx_t.translation(-15.0 + xx * 3.0, -15.0 + yy * 3.0, 0.0) * mtx_ry.rotationY(@time + yy * 0.37) * mtx_rx.rotationX(@time + xx * 0.21)
            mtx_ptr.write_array_of_float(mtx_transform.to_a)

            color_ptr = mtx_ptr + 64
            color = [Math.sin(@time + xx.to_f/11.0)*0.5+0.5, Math.cos(@time + xx.to_f/11.0)*0.5+0.5, Math.sin(@time*3.0)*0.5+0.5, 1.0]
            color_ptr.write_array_of_float(color)
            offset += instanceStride
          end
        end

        Bgfx.set_vertex_buffer(0, @m_vbh, 0, 0xffffffff) # 0xffffffff == UINT32_MAX
        Bgfx.set_index_buffer(@m_ibh, 0, 0xffffffff) # 0xffffffff == UINT32_MAX
        Bgfx.set_instance_data_buffer(idb, 0, numInstances) # TODO support default argument
        Bgfx.set_state(Bgfx::State_Default)

        Bgfx.submit(0, @m_program)
      end
    else
      blink = ((@time * 3.0).to_i & 1) != 0
      Bgfx.dbg_text_printf(0, 0, blink ? 0x4f : 0x04, ' Instancing is not supported by GPU. ')
    end
    ImGui::Render()
    ImGui::ImplBgfx_RenderDrawData(ImGui::GetDrawData())

    Bgfx.frame
  end
end
