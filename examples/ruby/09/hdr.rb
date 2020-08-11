# coding: utf-8
#
# Ref.: bgfx/examples/09-hdr/hdr.cpp
#

require_relative '../common/sample'
require_relative '../common/mesh'

################################################################################

class Sample09 < Sample

  class PosColorTexCoord0Vertex < FFI::Struct
    @@ms_layout = nil

    def self.ms_layout
      @@ms_layout
    end

    layout(
      :m_x, :float,
      :m_y, :float,
      :m_z, :float,
      :m_rgba, :uint32,
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

  def screenSpaceQuad(_textureWidth, _textureHeight, _originBottomLeft = false, _width = 1.0, _height = 1.0)
    if Bgfx::get_avail_transient_vertex_buffer(3, PosColorTexCoord0Vertex::ms_layout) == 3

      vb = Bgfx_transient_vertex_buffer_t.new

      Bgfx::alloc_transient_vertex_buffer(vb, 3, PosColorTexCoord0Vertex::ms_layout)

      vertex = 3.times.collect do |i|
        PosColorTexCoord0Vertex.new(vb[:data] + i * PosColorTexCoord0Vertex.size)
      end

      zz = 0.0

      minx = -_width
      maxx =  _width
      miny = 0.0
      maxy = _height*2.0

      texelHalfW = @@s_texelHalf / _textureWidth
      texelHalfH = @@s_texelHalf / _textureHeight
      minu = -1.0 + texelHalfW
      maxu =  1.0 + texelHalfW

      minv = texelHalfH
      maxv = 2.0 + texelHalfH

      if _originBottomLeft
        temp = minv
        minv = maxv
        maxv = temp

        minv -= 1.0
        maxv -= 1.0
      end

      vertex[0][:m_x] = minx
      vertex[0][:m_y] = miny
      vertex[0][:m_z] = zz
      vertex[0][:m_rgba] = 0xffffffff
      vertex[0][:m_u] = minu
      vertex[0][:m_v] = minv

      vertex[1][:m_x] = maxx
      vertex[1][:m_y] = miny
      vertex[1][:m_z] = zz
      vertex[1][:m_rgba] = 0xffffffff
      vertex[1][:m_u] = maxu
      vertex[1][:m_v] = minv

      vertex[2][:m_x] = maxx
      vertex[2][:m_y] = maxy
      vertex[2][:m_z] = zz
      vertex[2][:m_rgba] = 0xffffffff
      vertex[2][:m_u] = maxu
      vertex[2][:m_v] = maxv

      Bgfx::set_transient_vertex_buffer(0, vb, 0, 0xffffffff)
    end
  end

  def setOffsets2x2Lum(_handle,  _width,  _height)
    offsets = FFI::MemoryPointer.new(:float, 16 * 4)
    stride = 4

    du = 1.0/_width
    dv = 1.0/_height

    num = 0
    3.times do |yy|
      3.times do |xx|
        offsets.put(:float, stride * num + 0, (xx - @@s_texelHalf) * du)
        offsets.put(:float, stride * num + 1, (yy - @@s_texelHalf) * dv)
        num += 1
      end
    end
    Bgfx::set_uniform(_handle, offsets, num)
  end

  def setOffsets4x4Lum(_handle,  _width,  _height)
    offsets = FFI::MemoryPointer.new(:float, 16 * 4)
    stride = 4

    du = 1.0/_width
    dv = 1.0/_height

    num = 0
    4.times do |yy|
      4.times do |xx|
        offsets.put(:float, stride * num + 0, (xx - 1.0 - @@s_texelHalf) * du)
        offsets.put(:float, stride * num + 1, (yy - 1.0 - @@s_texelHalf) * dv)
        num += 1
      end
    end
    Bgfx::set_uniform(_handle, offsets, num)
  end

  def initialize
    super("09-hdr", "https://bkaradzic.github.io/bgfx/examples.html#hdr", "Using multiple views with frame buffers, and view order remapping.")
    @ndc_homogeneous = true
    @origin_bottom_left = true

    # ProgramHandle
    @m_skyProgram = nil
    @m_lumProgram = nil
    @m_lumAvgProgram = nil
    @m_blurProgram = nil
    @m_brightProgram = nil
    @m_meshProgram = nil
    @m_tonemapProgram = nil

    # TextureHandle
    @m_uffizi = nil

    # UniformHandle
    @s_texCube = nil
    @s_texColor = nil
    @s_texLum = nil
    @s_texBlur = nil
    @u_mtx = nil
    @u_tonemap = nil
    @u_offset = nil

    # TextureHandle
    @m_fbtextures_mem = nil
    @m_fbtextures = nil
    @m_rb = nil

    # FrameBufferHandle
    @m_fbh = nil
    @m_lum = [nil, nil, nil, nil, nil]
    @m_bright = nil
    @m_blur = nil

    @m_mesh = nil

    @m_lumBgra8 = 0

    @@s_texelHalf = 0.0 # bgfx::RendererType::Direct3D9 == m_caps->rendererType ? 0.5f : 0.0f;

    @m_oldWidth  = 0
    @m_oldHeight = 0
    @m_oldReset  = @reset

    @m_speed = 0.37
    @m_middleGray = 0.18
    @m_white = 1.1
    @m_threshold = 1.5
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

    @@s_texelHalf = init[:type] == Bgfx::RendererType::Direct3D9 ? 0.5 : 0.0

    bgfx_caps = Bgfx_caps_t.new(Bgfx::get_caps())
    @ndc_homogeneous = bgfx_caps[:homogeneousDepth]
    @origin_bottom_left = bgfx_caps[:originBottomLeft]

    ImGui::ImplBgfx_Init()

    Bgfx::set_debug(debug)
    Bgfx::set_view_clear(0, Bgfx::Clear_Color|Bgfx::Clear_Depth, 0x303080ff, 1.0, 0)

    PosColorTexCoord0Vertex.init()

    @m_uffizi = BgfxUtils::load_texture("textures/uffizi.ktx", 0 | Bgfx::Sampler_UvwClamp)

    @m_skyProgram = BgfxUtils.load_program("vs_hdr_skybox",  "fs_hdr_skybox")
    @m_lumProgram = BgfxUtils.load_program("vs_hdr_lum",     "fs_hdr_lum") 
    @m_lumAvgProgram = BgfxUtils.load_program("vs_hdr_lumavg",  "fs_hdr_lumavg")
    @m_blurProgram = BgfxUtils.load_program("vs_hdr_blur",    "fs_hdr_blur")
    @m_brightProgram = BgfxUtils.load_program("vs_hdr_bright",  "fs_hdr_bright")
    @m_meshProgram = BgfxUtils.load_program("vs_hdr_mesh",    "fs_hdr_mesh")
    @m_tonemapProgram = BgfxUtils.load_program("vs_hdr_tonemap", "fs_hdr_tonemap")

    @s_texCube   = Bgfx::create_uniform("s_texCube",  Bgfx::UniformType::Sampler)
    @s_texColor  = Bgfx::create_uniform("s_texColor", Bgfx::UniformType::Sampler)
    @s_texLum    = Bgfx::create_uniform("s_texLum",   Bgfx::UniformType::Sampler)
    @s_texBlur   = Bgfx::create_uniform("s_texBlur",  Bgfx::UniformType::Sampler)
    @u_mtx       = Bgfx::create_uniform("u_mtx",      Bgfx::UniformType::Mat4)
    @u_tonemap   = Bgfx::create_uniform("u_tonemap",  Bgfx::UniformType::Vec4)
    @u_offset    = Bgfx::create_uniform("u_offset",   Bgfx::UniformType::Vec4, 16)

    @m_mesh = SampleMesh::Mesh.new
    File.open('../runtime/meshes/bunny.bin') do |bin|
      @m_mesh.load(bin)
    end

    @m_fbh = Bgfx_frame_buffer_handle_t.new
    @m_fbh[:idx] = Bgfx::InvalidHandleIdx

    # Ref.: Structs > Array of Structs  https://github.com/ffi/ffi/wiki/Structs
    @m_fbtextures_mem = FFI::MemoryPointer.new(Bgfx_texture_handle_t, 2)
    @m_fbtextures = 2.times.collect do |i|
      Bgfx_texture_handle_t.new(@m_fbtextures_mem + i * Bgfx_texture_handle_t.size)
    end

    @m_lum[0] = Bgfx::create_frame_buffer(128, 128, Bgfx::TextureFormat::BGRA8)
    @m_lum[1] = Bgfx::create_frame_buffer( 64,  64, Bgfx::TextureFormat::BGRA8)
    @m_lum[2] = Bgfx::create_frame_buffer( 16,  16, Bgfx::TextureFormat::BGRA8)
    @m_lum[3] = Bgfx::create_frame_buffer(  4,   4, Bgfx::TextureFormat::BGRA8)
    @m_lum[4] = Bgfx::create_frame_buffer(  1,   1, Bgfx::TextureFormat::BGRA8)

    @m_bright = Bgfx::create_frame_buffer_scaled(Bgfx::BackbufferRatio::Half,   Bgfx::TextureFormat::BGRA8)
    @m_blur   = Bgfx::create_frame_buffer_scaled(Bgfx::BackbufferRatio::Eighth, Bgfx::TextureFormat::BGRA8)

    @m_rb = Bgfx_texture_handle_t.new
    @m_rb[:idx] = Bgfx::InvalidHandleIdx
    if (bgfx_caps[:supported] & (Bgfx::Caps_TextureBlit|Bgfx::Caps_TextureReadBack)) == (Bgfx::Caps_TextureBlit|Bgfx::Caps_TextureReadBack)
      @m_rb = Bgfx::create_texture_2d(1, 1, false, 1, Bgfx::TextureFormat::BGRA8, Bgfx::Texture_ReadBack)
    end

    @eye.setElements(0.0, 1.0, -2.5)
    @at.setElements(0.0, 1.0, 0.0)
    @up.setElements(0.0,  1.0,  0.0)
    @mtx_view.lookAtLH( @eye, @at, @up )
    @view.write_array_of_float(@mtx_view.to_a)

    @mtx_proj.perspectiveFovLH( 60.0*Math::PI/180.0, width.to_f/height.to_f, 0.1, 100.0, @ndc_homogeneous )
    @proj.write_array_of_float(@mtx_proj.to_a)
  end

  def teardown()
    ImGui::ImplBgfx_Shutdown()

    @m_mesh.unload

    @m_lum.each do |lum|
      Bgfx::destroy_frame_buffer(lum)
    end
    Bgfx::destroy_frame_buffer(@m_bright)
    Bgfx::destroy_frame_buffer(@m_blur)

    Bgfx::destroy_frame_buffer(@m_fbh) if Bgfx::is_valid(@m_fbh)

    Bgfx::destroy_program(@m_meshProgram)
    Bgfx::destroy_program(@m_skyProgram)
    Bgfx::destroy_program(@m_tonemapProgram)
    Bgfx::destroy_program(@m_lumProgram)
    Bgfx::destroy_program(@m_lumAvgProgram)
    Bgfx::destroy_program(@m_blurProgram)
    Bgfx::destroy_program(@m_brightProgram)

    Bgfx::destroy_texture(@m_uffizi)
    Bgfx::destroy_texture(@m_rb) if Bgfx::is_valid(@m_rb)

    Bgfx::destroy_uniform(@s_texCube)
    Bgfx::destroy_uniform(@s_texColor)
    Bgfx::destroy_uniform(@s_texLum)
    Bgfx::destroy_uniform(@s_texBlur)
    Bgfx::destroy_uniform(@u_mtx)
    Bgfx::destroy_uniform(@u_tonemap)
    Bgfx::destroy_uniform(@u_offset)

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
    @time += dt * @m_speed

    if !Bgfx::is_valid(@m_fbh) || @m_oldWidth != @window_width || @m_oldHeight != @window_height || @m_oldReset != @reset

      # Recreate variable size render targets when resolution changes.
      @m_oldWidth  = @window_width
      @m_oldHeight = @window_height
      @m_oldReset  = @reset

      msaa = (@reset & Bgfx::Reset_Msaa_Mask) >> Bgfx::Reset_Msaa_Shift
      Bgfx::destroy_frame_buffer(@m_fbh) if Bgfx::is_valid(@m_fbh)

      fbtextures = [nil, nil]
      fbtextures[0] = Bgfx::create_texture_2d(@window_width, @window_height, false, 1, Bgfx::TextureFormat::BGRA8, ((msaa + 1) << Bgfx::Texture_Rt_Msaa_Shift) | Bgfx::Sampler_U_Clamp | Bgfx::Sampler_V_Clamp)

      textureFlags = Bgfx::Texture_Rt_WriteOnly | ((msaa+1) << Bgfx::Texture_Rt_Msaa_Shift)

      depthFormat =   Bgfx::is_texture_valid(0, false, 1, Bgfx::TextureFormat::D16,   textureFlags) ? Bgfx::TextureFormat::D16
                    : Bgfx::is_texture_valid(0, false, 1, Bgfx::TextureFormat::D24S8, textureFlags) ? Bgfx::TextureFormat::D24S8
                    : Bgfx::TextureFormat::D32

      fbtextures[1] = Bgfx::create_texture_2d(@window_width, @window_height, false, 1, depthFormat, textureFlags)

      # Note that @m_fbtextures resides in @m_fbtextures_mem (FFI::MemoryPointer)
      @m_fbtextures[0][:idx] = fbtextures[0][:idx]
      @m_fbtextures[1][:idx] = fbtextures[1][:idx]
      @m_fbh = Bgfx::create_frame_buffer_from_handles(@m_fbtextures.length, @m_fbtextures_mem, true)
    end

    ImGui::NewFrame()
    SampleDialog::show(self)

    ImGui::Render()
    ImGui::ImplBgfx_RenderDrawData(ImGui::GetDrawData())

    Bgfx::touch(0)

    mtx = FFI::MemoryPointer.new(:float, 16).write_array_of_float(RMtx4.new.rotationY(@time).to_a)

    state = Bgfx::State_Write_Rgb | Bgfx::State_Write_A | Bgfx::State_Write_Z | Bgfx::State_Depth_Test_Lequal | Bgfx::State_Cull_Ccw | Bgfx::State_Msaa

    shuffle = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9].shuffle
    hdrSkybox       = shuffle[0]
    hdrMesh         = shuffle[1]
    hdrLuminance    = shuffle[2]
    hdrLumScale0    = shuffle[3]
    hdrLumScale1    = shuffle[4]
    hdrLumScale2    = shuffle[5]
    hdrLumScale3    = shuffle[6]
    hdrBrightness   = shuffle[7]
    hdrVBlur        = shuffle[8]
    hdrHBlurTonemap = shuffle[9]

    # Set views.
    Bgfx::set_view_name(hdrSkybox, "Skybox")
    Bgfx::set_view_clear(hdrSkybox, Bgfx::Clear_Color | Bgfx::Clear_Depth, 0x303030ff, 1.0, 0)
    Bgfx::set_view_rect_ratio(hdrSkybox, 0, 0, Bgfx::BackbufferRatio::Equal)
    Bgfx::set_view_frame_buffer(hdrSkybox, @m_fbh)

    Bgfx::set_view_name(hdrMesh, "Mesh")
    Bgfx::set_view_clear(hdrMesh, Bgfx::Clear_DiscardDepth | Bgfx::Clear_DiscardStencil) # , 0x303030ff, 1.0, 0
    Bgfx::set_view_rect_ratio(hdrMesh, 0, 0, Bgfx::BackbufferRatio::Equal)
    Bgfx::set_view_frame_buffer(hdrMesh, @m_fbh)

    Bgfx::set_view_name(hdrLuminance, "Luminance")
    Bgfx::set_view_rect(hdrLuminance, 0, 0, 128, 128)
    Bgfx::set_view_frame_buffer(hdrLuminance, @m_lum[0])

    Bgfx::set_view_name(hdrLumScale0, "Downscale luminance 0")
    Bgfx::set_view_rect(hdrLumScale0, 0, 0, 64, 64)
    Bgfx::set_view_frame_buffer(hdrLumScale0, @m_lum[1])

    Bgfx::set_view_name(hdrLumScale1, "Downscale luminance 1")
    Bgfx::set_view_rect(hdrLumScale1, 0, 0, 16, 16)
    Bgfx::set_view_frame_buffer(hdrLumScale1, @m_lum[2])

    Bgfx::set_view_name(hdrLumScale2, "Downscale luminance 2")
    Bgfx::set_view_rect(hdrLumScale2, 0, 0, 4, 4)
    Bgfx::set_view_frame_buffer(hdrLumScale2, @m_lum[3])

    Bgfx::set_view_name(hdrLumScale3, "Downscale luminance 3")
    Bgfx::set_view_rect(hdrLumScale3, 0, 0, 1, 1)
    Bgfx::set_view_frame_buffer(hdrLumScale3, @m_lum[4])

    Bgfx::set_view_name(hdrBrightness, "Brightness")
    Bgfx::set_view_rect_ratio(hdrBrightness, 0, 0, Bgfx::BackbufferRatio::Half)
    Bgfx::set_view_frame_buffer(hdrBrightness, @m_bright)

    Bgfx::set_view_name(hdrVBlur, "Blur vertical")
    Bgfx::set_view_rect_ratio(hdrVBlur, 0, 0, Bgfx::BackbufferRatio::Eighth)
    Bgfx::set_view_frame_buffer(hdrVBlur, @m_blur)

    Bgfx::set_view_name(hdrHBlurTonemap, "Blur horizontal + tonemap")
    Bgfx::set_view_rect_ratio(hdrHBlurTonemap, 0, 0, Bgfx::BackbufferRatio::Equal)
    invalid = Bgfx_frame_buffer_handle_t.new
    invalid[:idx] = Bgfx::InvalidHandleIdx
    Bgfx::set_view_frame_buffer(hdrHBlurTonemap, invalid)

    order_src = [
      hdrSkybox,
      hdrMesh,
      hdrLuminance,
      hdrLumScale0,
      hdrLumScale1,
      hdrLumScale2,
      hdrLumScale3,
      hdrBrightness,
      hdrVBlur,
      hdrHBlurTonemap
    ]
    order_mem = FFI::MemoryPointer.new(:uint16, order_src.length).write_array_of_uint16(order_src)
    Bgfx::set_view_order(0, order_src.length, order_mem)

    mtx_ortho = RMtx4.new.orthoOffCenterLH(0.0, 1.0, 1.0, 0.0, 0.0, 100.0, @ndc_homogeneous)
    mtx_ortho_mem = FFI::MemoryPointer.new(:float, 16).write_array_of_float(mtx_ortho.to_a)

    # Set view and projection matrix for view 0.
    order_src.length.times do |ii|
      Bgfx::set_view_transform(ii, nil, mtx_ortho_mem)
    end

    mtx = FFI::MemoryPointer.new(:float, 16).write_array_of_float(RMtx4.new.rotationY(@time).to_a)

    # Set view and projection matrix for view hdrMesh.
    Bgfx::set_view_transform(hdrMesh, @view, @proj)

    tonemap_src = [@m_middleGray, @m_white * @m_white, @m_threshold, @time]
    tonemap = FFI::MemoryPointer.new(:float, 4).write_array_of_float(tonemap_src)

    # Render skybox into view hdrSkybox.
    Bgfx::set_texture(0, @s_texCube, @m_uffizi)
    Bgfx::set_state(Bgfx::State_Write_Rgb | Bgfx::State_Write_A)
    Bgfx::set_uniform(@u_mtx, mtx)
    screenSpaceQuad(@window_width.to_f, @window_height.to_f, true)
    Bgfx::submit(hdrSkybox, @m_skyProgram)

    # Render m_mesh into view hdrMesh.
    Bgfx::set_texture(0, @s_texCube, @m_uffizi)
    Bgfx::set_uniform(@u_tonemap, tonemap)
    @m_mesh.submit(hdrMesh, @m_meshProgram, mtx) # meshSubmit(m_mesh, hdrMesh, m_meshProgram, nil)

    # Calculate luminance.
    setOffsets2x2Lum(@u_offset, 128, 128)
    Bgfx::set_texture(0, @s_texColor, @m_fbtextures[0])
    Bgfx::set_state(Bgfx::State_Write_Rgb | Bgfx::State_Write_A)
    screenSpaceQuad(128.0, 128.0, @origin_bottom_left)
    Bgfx::submit(hdrLuminance, @m_lumProgram)

    # Downscale luminance 0.
    setOffsets4x4Lum(@u_offset, 128, 128)
    Bgfx::set_texture(0, @s_texColor, Bgfx::get_texture(@m_lum[0]) )
    Bgfx::set_state(Bgfx::State_Write_Rgb | Bgfx::State_Write_A)
    screenSpaceQuad(64.0, 64.0, @origin_bottom_left)
    Bgfx::submit(hdrLumScale0, @m_lumAvgProgram)

    # Downscale luminance 1.
    setOffsets4x4Lum(@u_offset, 64, 64)
    Bgfx::set_texture(0, @s_texColor, Bgfx::get_texture(@m_lum[1]) )
    Bgfx::set_state(Bgfx::State_Write_Rgb | Bgfx::State_Write_A)
    screenSpaceQuad(16.0, 16.0, @origin_bottom_left)
    Bgfx::submit(hdrLumScale1, @m_lumAvgProgram)

    # Downscale luminance 2.
    setOffsets4x4Lum(@u_offset, 16, 16)
    Bgfx::set_texture(0, @s_texColor, Bgfx::get_texture(@m_lum[2]) )
    Bgfx::set_state(Bgfx::State_Write_Rgb | Bgfx::State_Write_A)
    screenSpaceQuad(4.0, 4.0, @origin_bottom_left)
    Bgfx::submit(hdrLumScale2, @m_lumAvgProgram)

    # Downscale luminance 3.
    setOffsets4x4Lum(@u_offset, 4, 4)
    Bgfx::set_texture(0, @s_texColor, Bgfx::get_texture(@m_lum[3]) )
    Bgfx::set_state(Bgfx::State_Write_Rgb | Bgfx::State_Write_A)
    screenSpaceQuad(1.0, 1.0, @origin_bottom_left)
    Bgfx::submit(hdrLumScale3, @m_lumAvgProgram)

    # @m_bright pass m_threshold is tonemap[3].
    setOffsets4x4Lum(@u_offset, @window_width/2, @window_height/2)
    Bgfx::set_texture(0, @s_texColor, @m_fbtextures[0])
    Bgfx::set_texture(1, @s_texLum, Bgfx::get_texture(@m_lum[4]) )
    Bgfx::set_state(Bgfx::State_Write_Rgb | Bgfx::State_Write_A)
    Bgfx::set_uniform(@u_tonemap, tonemap)
    screenSpaceQuad( @window_width/2.0, @window_height/2.0, @origin_bottom_left)
    Bgfx::submit(hdrBrightness, @m_brightProgram)

    # m_blur m_bright pass vertically.
    Bgfx::set_texture(0, @s_texColor, Bgfx::get_texture(@m_bright) )
    Bgfx::set_state(Bgfx::State_Write_Rgb | Bgfx::State_Write_A)
    Bgfx::set_uniform(@u_tonemap, tonemap)
    screenSpaceQuad( @window_width/8.0, @window_height/8.0, @origin_bottom_left)
    Bgfx::submit(hdrVBlur, @m_blurProgram)

    # m_blur m_bright pass horizontally, do tonemaping and combine.
    Bgfx::set_texture(0, @s_texColor, @m_fbtextures[0])
    Bgfx::set_texture(1, @s_texLum, Bgfx::get_texture(@m_lum[4]) )
    Bgfx::set_texture(2, @s_texBlur, Bgfx::get_texture(@m_blur) )
    Bgfx::set_state(Bgfx::State_Write_Rgb | Bgfx::State_Write_A)
    screenSpaceQuad(@window_width.to_f, @window_height.to_f, @origin_bottom_left)
    Bgfx::submit(hdrHBlurTonemap, @m_tonemapProgram)

    if Bgfx::is_valid(@m_rb)
      Bgfx::blit(hdrHBlurTonemap, @m_rb, 0, 0, 0, 0, Bgfx::get_texture(@m_lum[4]), 0, 0, 0, 0, 0xffff, 0xffff, 0xffff)
      bgra8 = FFI::MemoryPointer.new(:uint32, 1)
      Bgfx::read_texture(@m_rb, bgra8)
    end

    Bgfx::frame()
  end

end
