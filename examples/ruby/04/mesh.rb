# coding: utf-8
#
# Ref.: bgfx/examples/02-metaballs/metaballs.cpp
#

require_relative '../common/sample'
require_relative '../common/mesh'

################################################################################

class Sample04 < Sample

  def perspectiveFovLH( fovy_radian, aspect, znear, zfar, ndc_homogeneous = true)
    height = Math::tan( fovy_radian / 2.0 )
    height = 1.0 / height
    width = height / aspect

    diff = zfar-znear
    aa = ndc_homogeneous ? (zfar+znear) / diff : zfar / diff
    bb = ndc_homogeneous ? (2*znear*zfar) / diff : znear*aa

    @mtx_proj.setZero()
    @mtx_proj.setElement( 0, 0, width )
    @mtx_proj.setElement( 1, 1, height )
    @mtx_proj.setElement( 2, 2, -aa )
    @mtx_proj.setElement( 2, 3, bb )
    @mtx_proj.setElement( 3, 2, 1.0 )
  end

  def perspectiveFovRH( fovy_radian, aspect, znear, zfar, ndc_homogeneous = true)
    height = Math::tan( fovy_radian / 2.0 )
    height = 1.0 / height
    width = height / aspect

    diff = zfar-znear
    aa = ndc_homogeneous ? (zfar+znear) / diff : zfar / diff
    bb = ndc_homogeneous ? (2*znear*zfar) / diff : znear*aa

    @mtx_proj.setZero()
    @mtx_proj.setElement( 0, 0, width )
    @mtx_proj.setElement( 1, 1, height )
    @mtx_proj.setElement( 2, 2, -aa )
    @mtx_proj.setElement( 2, 3, -bb )
    @mtx_proj.setElement( 3, 2, -1.0 )
  end
  
  def lookAtLH( eye, at, up )
    axis_z = (at - eye).normalize!
    axis_x = RVec3.cross( up, axis_z ).normalize!
    axis_y = RVec3.cross( axis_z, axis_x )

    @mtx_view.setIdentity()

    @mtx_view.e00 = axis_x[0]
    @mtx_view.e01 = axis_x[1]
    @mtx_view.e02 = axis_x[2]
    @mtx_view.e03 = -RVec3.dot( axis_x, eye )

    @mtx_view.e10 = axis_y[0]
    @mtx_view.e11 = axis_y[1]
    @mtx_view.e12 = axis_y[2]
    @mtx_view.e13 = -RVec3.dot( axis_y, eye )

    @mtx_view.e20 = axis_z[0]
    @mtx_view.e21 = axis_z[1]
    @mtx_view.e22 = axis_z[2]
    @mtx_view.e23 = -RVec3.dot( axis_z, eye )
  end

  def lookAtRH( eye, at, up )
    axis_z = (eye - at).normalize!
    axis_x = RVec3.cross( up, axis_z ).normalize!
    axis_y = RVec3.cross( axis_z, axis_x )

    @mtx_view.setIdentity()

    @mtx_view.e00 = axis_x[0]
    @mtx_view.e01 = axis_x[1]
    @mtx_view.e02 = axis_x[2]
    @mtx_view.e03 = -RVec3.dot( axis_x, eye )

    @mtx_view.e10 = axis_y[0]
    @mtx_view.e11 = axis_y[1]
    @mtx_view.e12 = axis_y[2]
    @mtx_view.e13 = -RVec3.dot( axis_y, eye )

    @mtx_view.e20 = axis_z[0]
    @mtx_view.e21 = axis_z[1]
    @mtx_view.e22 = axis_z[2]
    @mtx_view.e23 = -RVec3.dot( axis_z, eye )
  end

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
    # Bgfx::set_view_clear(0, Bgfx::Clear_Color|Bgfx::Clear_Depth, 0x303080ff, 1.0, 0) # for GL/RH Coordinate
    Bgfx::set_view_clear(0, Bgfx::Clear_Color|Bgfx::Clear_Depth, 0x303080ff, 0.0, 0) # for GL/LH Coordinate
    

    @u_time = Bgfx::create_uniform("u_time", Bgfx::UniformType::Vec4)
    @m_program = BgfxUtils.load_program("vs_mesh", "fs_mesh", "./" )
    @m_mesh = SampleMesh::Mesh.new
    File.open('../runtime/meshes/bunny.bin') do |bin|
      @m_mesh.load(bin)
    end

    @eye.setElements(0.0, 1.0, -2.5)
    @at.setElements(0.0, 1.0, 0.0)
    @up.setElements(0.0,  1.0,  0.0)
    lookAtLH( @eye, @at, @up )
    #lookAtRH( @eye, @at, @up )
    #@mtx_view.lookAtRH(@eye, @at, @up)
    @view.write_array_of_float(@mtx_view.to_a)

    perspectiveFovLH( 60.0*Math::PI/180.0, width.to_f/height.to_f, 0.1, 100.0, @ndc_homogeneous )
    #perspectiveFovRH( 60.0*Math::PI/180.0, width.to_f/height.to_f, 0.1, 100.0, @ndc_homogeneous )
    #@mtx_proj.perspectiveFovRH( 60.0*Math::PI/180.0, width.to_f/height.to_f, 0.1, 100.0, @ndc_homogeneous )
    @proj.write_array_of_float(@mtx_proj.to_a)

    pp RVec3.new(0.0, 1.0, -2.399999).transformCoord(@mtx_view).transformCoord(@mtx_proj)
  end

  def teardown()
    ImGui::ImplBgfx_Shutdown()

    Bgfx::shutdown()

    super()
  end

  def resize(width, height)
    super(width, height)
    perspectiveFovLH( 60.0*Math::PI/180.0, width.to_f/height.to_f, 0.1, 100.0, @ndc_homogeneous )
    #perspectiveFovRH( 60.0*Math::PI/180.0, width.to_f/height.to_f, 0.1, 100.0, @ndc_homogeneous )
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
    #Bgfx::set_uniform(@u_time, [0, 0, 0, 0].pack("F4"))

    #mtx = FFI::MemoryPointer.new(:float, 16).write_array_of_float((RMtx4.new.rotationY(@time) * RMtx4.new.rotationX(0.67 * @time)).to_a)
    #mtx = FFI::MemoryPointer.new(:float, 16).write_array_of_float((RMtx4.new.rotationY(@time)).to_a)
    mtx = FFI::MemoryPointer.new(:float, 16).write_array_of_float((RMtx4.new.setIdentity.to_a))

    #Bgfx::set_transform(mtx, 1)
    #Bgfx::set_state(Bgfx::State_Write_Rgb | Bgfx::State_Write_A | Bgfx::State_Write_Z | Bgfx::State_Depth_Test_Less | Bgfx::State_Cull_Ccw | Bgfx::State_Msaa)
    # state = Bgfx::State_Write_Rgb | Bgfx::State_Write_A | Bgfx::State_Write_Z | Bgfx::State_Depth_Test_Lequal | Bgfx::State_Cull_Ccw | Bgfx::State_Msaa # for GL/RH Coordinate
    state = Bgfx::State_Write_Rgb | Bgfx::State_Write_A | Bgfx::State_Write_Z | Bgfx::State_Depth_Test_Gequal | Bgfx::State_Cull_Ccw | Bgfx::State_Msaa # for GL/LH Coordinate

    @m_mesh.submit(0, @m_program, mtx, state)

    ImGui::Render()
    ImGui::ImplBgfx_RenderDrawData(ImGui::GetDrawData())

    Bgfx::frame()

  end

end
