# coding: utf-8
#
# Ref.: bgfx/examples/02-metaballs/metaballs.cpp
#

require_relative '../common/sample'
require_relative '../common/mesh'

################################################################################

class Sample04 < Sample

  def initialize
    super("04-mesh", "https://bkaradzic.github.io/bgfx/examples.html#mesh", "Loading meshes.")
    @ndc_homogeneous = true

    @u_time = nil
    @m_program = nil
    @m_mesh = nil
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
    Bgfx::set_view_clear(0, Bgfx::Clear_Color|Bgfx::Clear_Depth, 0x303080ff, 1.0, 0)

    @u_time = Bgfx::create_uniform("u_time", Bgfx::UniformType::Vec4)
    @m_program = BgfxUtils.load_program("vs_mesh", "fs_mesh", "./" )
    @m_mesh = SampleMesh::Mesh.new
    File.open('../runtime/meshes/bunny.bin') do |bin|
      @m_mesh.load(bin)
    end

    @eye.setElements(0.0, 1.0, -2.5)
    @at.setElements(0.0, 1.0, 0.0)
    @up.setElements(0.0,  1.0,  0.0)
    @mtx_view.lookAtLH( @eye, @at, @up )
    @view.write_array_of_float(@mtx_view.to_a)

    @mtx_proj.perspectiveFovLH( 60.0*Math::PI/180.0, width.to_f/height.to_f, 0.1, 100.0, @ndc_homogeneous )
    @proj.write_array_of_float(@mtx_proj.to_a)

    # ret = RVec3.new(0.0, 1.0, -2.399999).transformCoord(@mtx_view).transformCoord(@mtx_proj)
    # pp ret[0], ret[1], ret[2]
  end

  def teardown()
    ImGui::ImplBgfx_Shutdown()

    @m_mesh.unload
    Bgfx::destroy_uniform(@u_time) if @u_time
    Bgfx::destroy_program(@m_program) if @m_program
  
    Bgfx::shutdown()

    super()
  end

  def resize(width, height)
    super(width, height)
    @mtx_proj.perspectiveFovLH( 60.0*Math::PI/180.0, width.to_f/height.to_f, 0.1, 100.0, @ndc_homogeneous )
    @proj.write_array_of_float(@mtx_proj.to_a)
  end

  def update(dt)
    super(dt)
    @time += dt

    Bgfx::reset(@window_width, @window_height, @reset)

    ImGui::NewFrame()
    SampleDialog::show(self)

    Bgfx::set_view_transform(0, @view, @proj)
    Bgfx::set_view_rect(0, 0, 0, @window_width, @window_height)
    Bgfx::touch(0)

    Bgfx::set_uniform(@u_time, [@time, 0, 0, 0].pack("F4"))

    mtx = FFI::MemoryPointer.new(:float, 16).write_array_of_float(RMtx4.new.rotationY(@time * 0.37).to_a)

    state = Bgfx::State_Write_Rgb | Bgfx::State_Write_A | Bgfx::State_Write_Z | Bgfx::State_Depth_Test_Lequal | Bgfx::State_Cull_Ccw | Bgfx::State_Msaa

    @m_mesh.submit(0, @m_program, mtx, state)

    ImGui::Render()
    ImGui::ImplBgfx_RenderDrawData(ImGui::GetDrawData())

    Bgfx::frame()
  end

end
