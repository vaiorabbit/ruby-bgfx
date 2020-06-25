# coding: utf-8
#
# Ref.: bgfx/examples/03-raymarch/raymarch.cpp
#

require_relative '../common/sample'

################################################################################

class Sample03 < Sample

  class PosColorTexCoord0Vertex < FFI::Struct
    @@ms_layout = nil

    def self.ms_layout
      @@ms_layout
    end

    layout(
      :m_x, :float,
      :m_y, :float,
      :m_z, :float,
      :m_abgr, :uint32,
      :m_u, :float,
      :m_v, :float
    )

    def self.init()
      if @@ms_layout == nil
        @@ms_layout = Bgfx_vertex_layout_t.new
        @@ms_layout.begin()
        @@ms_layout.add(Bgfx::Attrib::Position, 3, Bgfx::AttribType::Float)
        @@ms_layout.add(Bgfx::Attrib::Color0, 4, Bgfx::AttribType::Uint8, true)
        @@ms_layout.add(Bgfx::Attrib::TexCoord0, 2, Bgfx::AttribType::Float)
        @@ms_layout.end
      end
    end
  end

  def renderScreenSpaceQuad(_view, _program, _x, _y, _width, _height)
    tvb = Bgfx_transient_vertex_buffer_t.new
    tib = Bgfx_transient_index_buffer_t.new

    if Bgfx::bgfx_alloc_transient_buffers(tvb, PosColorTexCoord0Vertex.ms_layout, 4, tib, 6)
      zz = 0.0
      minx = _x
      maxx = _x + _width
      miny = _y
      maxy = _y + _height
      minu = -1.0
      minv = -1.0
      maxu =  1.0
      maxv =  1.0

      vertex = PosColorTexCoord0Vertex.new

      vertex[:m_x] = minx
      vertex[:m_y] = miny
      vertex[:m_z] = zz
      vertex[:m_abgr] = 0xff0000ff
      vertex[:m_u] = minu
      vertex[:m_v] = minv
      tvb[:data].put_bytes(0 * PosColorTexCoord0Vertex.size, vertex.to_ptr.read_bytes(PosColorTexCoord0Vertex.size))

      vertex[:m_x] = maxx
      vertex[:m_y] = miny
      vertex[:m_z] = zz
      vertex[:m_abgr] = 0xff00ff00
      vertex[:m_u] = maxu
      vertex[:m_v] = minv
      tvb[:data].put_bytes(1 * PosColorTexCoord0Vertex.size, vertex.to_ptr.read_bytes(PosColorTexCoord0Vertex.size))

      vertex[:m_x] = maxx
      vertex[:m_y] = maxy
      vertex[:m_z] = zz
      vertex[:m_abgr] = 0xffff0000
      vertex[:m_u] = maxu
      vertex[:m_v] = maxv
      tvb[:data].put_bytes(2 * PosColorTexCoord0Vertex.size, vertex.to_ptr.read_bytes(PosColorTexCoord0Vertex.size))

      vertex[:m_x] = minx
      vertex[:m_y] = maxy
      vertex[:m_z] = zz
      vertex[:m_abgr] = 0xffffffff
      vertex[:m_u] = minu
      vertex[:m_v] = maxv
      tvb[:data].put_bytes(3 * PosColorTexCoord0Vertex.size, vertex.to_ptr.read_bytes(PosColorTexCoord0Vertex.size))

      tib[:data].write_array_of_ushort([0, 2, 1, 0, 3, 2])

      Bgfx::set_state(Bgfx::State_Default)
      Bgfx::set_transient_index_buffer(tib, 0, 0xffffffff)
      Bgfx::set_transient_vertex_buffer(0, tvb, 0, 0xffffffff)
      Bgfx::submit(_view, _program)
    end

  end

  def initialize
    super("03-raymarch", "https://bkaradzic.github.io/bgfx/examples.html#raymarch", "Updating shader uniforms.")

    @ndc_homogeneous = true

    @m_program = nil # Bgfx_shader_handle_t
    @u_mtx = nil # Bgfx_uniform_handle_t
    @u_lightDirTime = nil # Bgfx_uniform_handle_t

    @mtx_vp = nil
    @mtx_ortho = RMtx4.new
    @ortho =  FFI::MemoryPointer.new(:float, 16)
  end

  def setup(width, height, debug, reset)
    super(width, height, debug, reset)
    init = Bgfx_init_t.new
    init[:type] = BgfxUtils.platform_renderer_type() # OpenGL / Metal
    init[:vendorId] = Bgfx::Pci_Id_None
    init[:resolution][:width] = width
    init[:resolution][:height] = height
    init[:resolution][:reset] = reset | Bgfx::Reset_Vsync
    init[:limits][:maxEncoders] = 1
    init[:limits][:transientVbSize] = 6<<20
    init[:limits][:transientIbSize] = 2<<20
    bgfx_init_success = Bgfx::init(init)
    $stderr.puts("Failed to initialize Bgfx") unless bgfx_init_success

    bgfx_caps = Bgfx_caps_t.new(Bgfx::get_caps())
    @ndc_homogeneous = bgfx_caps[:homogeneousDepth] # Metal == fase, OpenGL == true

    ImGui::ImplBgfx_Init()

    Bgfx::set_debug(debug)
    Bgfx::set_view_clear(0, Bgfx::Clear_Color|Bgfx::Clear_Depth, 0x303080ff, 1.0, 0)

    PosColorTexCoord0Vertex.init()

    @u_mtx = Bgfx::create_uniform("u_mtx", Bgfx::UniformType::Mat4)
    @u_lightDirTime = Bgfx::create_uniform("u_lightDirTime", Bgfx::UniformType::Vec4)

    @m_program = BgfxUtils.load_program("vs_raymarching", "fs_raymarching")

    @eye.setElements(0.0, 0.0, -15.0)
    @at.setElements(0.0, 0.0, 0.0)
    @up.setElements(0.0, 1.0, 0.0)
    @mtx_view.lookAtRH(@eye, @at, @up)
    @view.write_array_of_float(@mtx_view.to_a)

    @mtx_proj.perspectiveFovRH(60.0*Math::PI/180.0, width.to_f/height.to_f, 0.1, 100.0)
    @proj.write_array_of_float(@mtx_proj.to_a)

    @mtx_vp = @mtx_proj * @mtx_view

    @mtx_ortho.orthoOffCenterRH(0.0, width, height, 0.0, 0.0, 100.0, @ndc_homogeneous)
    @ortho.write_array_of_float(@mtx_ortho.to_a)
  end

  def teardown()
    ImGui::ImplBgfx_Shutdown()

    Bgfx::destroy_uniform(@u_mtx) if @u_mtx
    Bgfx::destroy_uniform(@u_lightDirTime) if @u_lightDirTime

    Bgfx::destroy_program(@m_program) if @m_program

    Bgfx::shutdown()

    super()
  end

  def resize(width, height)
    super(width, height)

    @mtx_proj.perspectiveFovRH( 60.0*Math::PI/180.0, width.to_f/height.to_f, 0.1, 100.0, @ndc_homogeneous )
    @proj.write_array_of_float(@mtx_proj.to_a)

    @mtx_ortho.orthoOffCenterRH(0.0, width, height, 0.0, 0.0, 100.0, @ndc_homogeneous)
    @ortho.write_array_of_float(@mtx_ortho.to_a)
  end

  def update(dt)
    super(dt)
    @time += dt

    Bgfx::reset(@window_width, @window_height, @reset)

    ImGui::NewFrame()
    SampleDialog::show(self)
    ImGui::Render()
    ImGui::ImplBgfx_RenderDrawData(ImGui::GetDrawData())

    Bgfx::set_view_rect(0, 0, 0, @window_width, @window_height)
    Bgfx::set_view_rect(1, 0, 0, @window_width, @window_height)
    Bgfx::touch(0)

    Bgfx::set_view_transform(0, @view, @proj)
    Bgfx::set_view_transform(1, nil, @ortho)

    mtx = RMtx4.new.rotationY(@time * 0.37) * RMtx4.new.rotationX(@time)

    mtxInv = mtx.getInverse()

    lightDirModelN = RVec3.new(-0.4, -0.5, -1.0).normalize!
    lightDirTime = RVec4.new(lightDirModelN.transform(mtxInv))
    lightDirTime.w = @time

    Bgfx::set_uniform(@u_lightDirTime, lightDirTime.to_a.pack("F4"))

    mvp = @mtx_vp * mtx
    invMvp = mvp.getInverse()
    Bgfx::set_uniform(@u_mtx, invMvp.to_a.pack("F16"))

    renderScreenSpaceQuad(1, @m_program, 0.0, 0.0, 1280, 720)

    Bgfx::frame()

  end

end
