# coding: utf-8
#
# Ref.: bgfx/examples/06-bump/bump.cpp
#

require_relative './sample'

################################################################################

class Sample06 < Sample

  class PosNormalTangentTexcoordVertex < FFI::Struct
    @@ms_layout = nil

    def self.ms_layout
      @@ms_layout
    end

    layout(
      :m_x, :float,
      :m_y, :float,
      :m_z, :float,
      :m_normal, :uint32,
      :m_tangent, :uint32,
      :m_u, :int16,
      :m_v, :int16
    )

    def self.init()
      if @@ms_layout == nil
        @@ms_layout = Bgfx_vertex_layout_t.new
        Bgfx::bgfx_vertex_layout_begin(@@ms_layout, Bgfx::RendererType::Noop)
        Bgfx::bgfx_vertex_layout_add(@@ms_layout, Bgfx::Attrib::Position, 3, Bgfx::AttribType::Float, false, false)
        Bgfx::bgfx_vertex_layout_add(@@ms_layout, Bgfx::Attrib::Normal, 4, Bgfx::AttribType::Uint8, true, true)
        Bgfx::bgfx_vertex_layout_add(@@ms_layout, Bgfx::Attrib::Tangent, 4, Bgfx::AttribType::Uint8, true, true)
        Bgfx::bgfx_vertex_layout_add(@@ms_layout, Bgfx::Attrib::TexCoord0, 2, Bgfx::AttribType::Int16, true, true)
        Bgfx::bgfx_vertex_layout_end(@@ms_layout)
      end
    end
  end

  # Ref: Array of Structs https://github.com/ffi/ffi/wiki/Structs

  @@cubeVerticesSrc = [
    [-1.0,  1.0,  1.0, BgfxUtils.encode_normal_rgba8( 0.0,  0.0,  1.0), 0,      0,      0 ],
    [ 1.0,  1.0,  1.0, BgfxUtils.encode_normal_rgba8( 0.0,  0.0,  1.0), 0, 0x7fff,      0 ],
    [-1.0, -1.0,  1.0, BgfxUtils.encode_normal_rgba8( 0.0,  0.0,  1.0), 0,      0, 0x7fff ],
    [ 1.0, -1.0,  1.0, BgfxUtils.encode_normal_rgba8( 0.0,  0.0,  1.0), 0, 0x7fff, 0x7fff ],
    [-1.0,  1.0, -1.0, BgfxUtils.encode_normal_rgba8( 0.0,  0.0, -1.0), 0,      0,      0 ],
    [ 1.0,  1.0, -1.0, BgfxUtils.encode_normal_rgba8( 0.0,  0.0, -1.0), 0, 0x7fff,      0 ],
    [-1.0, -1.0, -1.0, BgfxUtils.encode_normal_rgba8( 0.0,  0.0, -1.0), 0,      0, 0x7fff ],
    [ 1.0, -1.0, -1.0, BgfxUtils.encode_normal_rgba8( 0.0,  0.0, -1.0), 0, 0x7fff, 0x7fff ],
    [-1.0,  1.0,  1.0, BgfxUtils.encode_normal_rgba8( 0.0,  1.0,  0.0), 0,      0,      0 ],
    [ 1.0,  1.0,  1.0, BgfxUtils.encode_normal_rgba8( 0.0,  1.0,  0.0), 0, 0x7fff,      0 ],
    [-1.0,  1.0, -1.0, BgfxUtils.encode_normal_rgba8( 0.0,  1.0,  0.0), 0,      0, 0x7fff ],
    [ 1.0,  1.0, -1.0, BgfxUtils.encode_normal_rgba8( 0.0,  1.0,  0.0), 0, 0x7fff, 0x7fff ],
    [-1.0, -1.0,  1.0, BgfxUtils.encode_normal_rgba8( 0.0, -1.0,  0.0), 0,      0,      0 ],
    [ 1.0, -1.0,  1.0, BgfxUtils.encode_normal_rgba8( 0.0, -1.0,  0.0), 0, 0x7fff,      0 ],
    [-1.0, -1.0, -1.0, BgfxUtils.encode_normal_rgba8( 0.0, -1.0,  0.0), 0,      0, 0x7fff ],
    [ 1.0, -1.0, -1.0, BgfxUtils.encode_normal_rgba8( 0.0, -1.0,  0.0), 0, 0x7fff, 0x7fff ],
    [ 1.0, -1.0,  1.0, BgfxUtils.encode_normal_rgba8( 1.0,  0.0,  0.0), 0,      0,      0 ],
    [ 1.0,  1.0,  1.0, BgfxUtils.encode_normal_rgba8( 1.0,  0.0,  0.0), 0, 0x7fff,      0 ],
    [ 1.0, -1.0, -1.0, BgfxUtils.encode_normal_rgba8( 1.0,  0.0,  0.0), 0,      0, 0x7fff ],
    [ 1.0,  1.0, -1.0, BgfxUtils.encode_normal_rgba8( 1.0,  0.0,  0.0), 0, 0x7fff, 0x7fff ],
    [-1.0, -1.0,  1.0, BgfxUtils.encode_normal_rgba8(-1.0,  0.0,  0.0), 0,      0,      0 ],
    [-1.0,  1.0,  1.0, BgfxUtils.encode_normal_rgba8(-1.0,  0.0,  0.0), 0, 0x7fff,      0 ],
    [-1.0, -1.0, -1.0, BgfxUtils.encode_normal_rgba8(-1.0,  0.0,  0.0), 0,      0, 0x7fff ],
    [-1.0,  1.0, -1.0, BgfxUtils.encode_normal_rgba8(-1.0,  0.0,  0.0), 0, 0x7fff, 0x7fff ],
  ]

  @@s_cubeVertices = FFI::MemoryPointer.new(PosNormalTangentTexcoordVertex, @@cubeVerticesSrc.length)
  @@cubeVertices = @@cubeVerticesSrc.length.times.collect do |i|
    PosNormalTangentTexcoordVertex.new(@@s_cubeVertices + i * PosNormalTangentTexcoordVertex.size)
  end

  @@cubeVertices.each_with_index do |c, i|
    c[:m_x], c[:m_y], c[:m_z], c[:m_normal], c[:m_tangent], c[:m_u], c[:m_v] = *@@cubeVerticesSrc[i]
  end


  @@cubeIndicesSrc = [
    0,  2,  1,
    1,  2,  3,
    4,  5,  6,
    5,  7,  6,

    8, 10,  9,
    9, 10, 11,
    12, 13, 14,
    13, 15, 14,

    16, 18, 17,
    17, 18, 19,
    20, 21, 22,
    21, 23, 22,
  ]
  @@s_cubeIndices = FFI::MemoryPointer.new(:uint16, @@cubeIndicesSrc.length).write_array_of_ushort(@@cubeIndicesSrc)

  def initialize
    super("06-bump", "https://bkaradzic.github.io/bgfx/examples.html#bump", "Loading textures.")

    @m_vbh = nil # Bgfx_dynamic_vertex_buffer_handle_t
    @m_ibh = nil # Bgfx_dynamic_index_buffer_handle_t
    @m_program = nil # Bgfx_shader_handle_t
    @s_texColor = nil # Bgfx_uniform_handle_t
    @s_texNormal = nil # Bgfx_uniform_handle_t
    @u_lightPosRadius = nil # Bgfx_uniform_handle_t
    @u_lightRgbInnerR = nil # Bgfx_uniform_handle_t
    @m_numLights = 4 # uint16
    @m_textureColor = nil # Bgfx_texture_handle_t
    @m_textureNormal = nil # Bgfx_texture_handle_t
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

    PosNormalTangentTexcoordVertex.init()

    BgfxUtils.calc_tangents(@@s_cubeVertices, @@s_cubeVertices.size / @@s_cubeVertices.type_size, PosNormalTangentTexcoordVertex.ms_layout, @@cubeIndicesSrc)

    @m_vbh = Bgfx::bgfx_create_vertex_buffer(
      Bgfx::bgfx_make_ref(@@s_cubeVertices, @@s_cubeVertices.size),
      PosNormalTangentTexcoordVertex.ms_layout,
      Bgfx::Buffer_None
    )

    @m_ibh = Bgfx::bgfx_create_index_buffer(
      Bgfx::bgfx_make_ref(@@s_cubeIndices, @@s_cubeIndices.size),
      Bgfx::Buffer_None
    )

    @s_texColor  = Bgfx::bgfx_create_uniform("s_texColor",  Bgfx::UniformType::Sampler, -1)
    @s_texNormal = Bgfx::bgfx_create_uniform("s_texNormal", Bgfx::UniformType::Sampler, -1)
    @u_lightPosRadius = Bgfx::bgfx_create_uniform("u_lightPosRadius", Bgfx::UniformType::Vec4, @m_numLights)
    @u_lightRgbInnerR = Bgfx::bgfx_create_uniform("u_lightRgbInnerR", Bgfx::UniformType::Vec4, @m_numLights)
    @m_textureColor = BgfxUtils.load_texture("textures/fieldstone-rgba.dds")
    @m_textureNormal = BgfxUtils.load_texture("textures/fieldstone-n.dds")

    @m_program = BgfxUtils.load_program("vs_bump", "fs_bump")

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

    Bgfx::bgfx_destroy_uniform(@s_texColor) if @s_texColor
    Bgfx::bgfx_destroy_uniform(@s_texNormal) if @s_texNormal
    Bgfx::bgfx_destroy_uniform(@u_lightPosRadius) if @u_lightPosRadius
    Bgfx::bgfx_destroy_uniform(@u_lightRgbInnerR) if @u_lightRgbInnerR
    Bgfx::bgfx_destroy_texture(@m_textureNormal) if @m_textureNormal
    Bgfx::bgfx_destroy_texture(@m_textureColor) if @m_textureColor

    Bgfx::bgfx_destroy_program(@m_program) if @m_program
    Bgfx::bgfx_destroy_vertex_buffer(@m_vbh) if @m_vbh
    Bgfx::bgfx_destroy_index_buffer(@m_ibh) if @m_ibh

    Bgfx::bgfx_shutdown()

    super()
  end

  def handle_event(event)
    super(event)
  end

  def update(dt)
    ret = super(dt)
    @time += dt

    Bgfx::bgfx_reset(@window_width, @window_height, @reset, Bgfx::TextureFormat::Count)

    ImGui::NewFrame()
    ImGui::PushFont(ImGui::ImplBgfx_GetFont())
    ImGui::ShowDemoWindow()
    ImGui::PopFont()
    ImGui::Render()
    ImGui::ImplBgfx_RenderDrawData(ImGui::GetDrawData())

    Bgfx::bgfx_set_view_transform(0, @view, @proj)
    Bgfx::bgfx_set_view_rect(0, 0, 0, @window_width, @window_height)
    Bgfx::bgfx_touch(0)

    light_pos_radius = Array.new(4) { Array.new(4, 0.0) }
    @m_numLights.times do |ii|
      light_pos_radius[ii][0] = Math.sin( (@time*(0.1 + ii*0.17) + ii*(0.5 * Math::PI) * 1.37 ) )*3.0
      light_pos_radius[ii][1] = Math.cos( (@time*(0.2 + ii*0.29) + ii*(0.5 * Math::PI) * 1.49 ) )*3.0
      light_pos_radius[ii][2] = -2.5
      light_pos_radius[ii][3] = 3.0
    end

    Bgfx::bgfx_set_uniform(@u_lightPosRadius, light_pos_radius.flatten!.pack("F16"), @m_numLights)

    light_rgb_inner_r = [
      [ 1.0, 0.7, 0.2, 0.8 ],
      [ 0.7, 0.2, 1.0, 0.8 ],
      [ 0.2, 1.0, 0.7, 0.8 ],
      [ 1.0, 0.4, 0.2, 0.8 ],
    ]

    Bgfx::bgfx_set_uniform(@u_lightRgbInnerR, light_rgb_inner_r.flatten!.pack("F16"), @m_numLights)

    state = 0 | Bgfx::State_Write_Rgb | Bgfx::State_Write_A | Bgfx::State_Write_Z | Bgfx::State_Depth_Test_Less | Bgfx::State_Msaa

    3.times do |yy|
      3.times do |xx|
        mtxTransform = RMtx4.new.translation(-3.0 + xx * 3.0, -3.0 + yy * 3.0, 0.0) * RMtx4.new.rotationY(@time * 0.03 + yy * 0.37) * RMtx4.new.rotationX(@time * 0.23 + xx * 0.21)
        mtx = FFI::MemoryPointer.new(:float, 16).write_array_of_float(mtxTransform.to_a)
        Bgfx::bgfx_set_transform(mtx, 1)
        Bgfx::bgfx_set_vertex_buffer(0, @m_vbh, 0, 0xffffffff) # 0xffffffff == UINT32_MAX
        Bgfx::bgfx_set_index_buffer(@m_ibh, 0, 0xffffffff) # 0xffffffff == UINT32_MAX
        Bgfx::bgfx_set_texture(0, @s_texColor,  @m_textureColor, 0xffffffff) # 0xffffffff == UINT32_MAX
        Bgfx::bgfx_set_texture(1, @s_texNormal, @m_textureNormal, 0xffffffff) # 0xffffffff == UINT32_MAX
        Bgfx::bgfx_set_state(state, 0)

        Bgfx::bgfx_submit(0, @m_program, 0, Bgfx::Discard_All)
      end
    end

    Bgfx::bgfx_frame(false)

    return ret
  end

end
