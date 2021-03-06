#
# Ref.: bgfx/examples/07-callback/callback.cpp
#       https://github.com/vaiorabbit/sdl2-bindings
#

require_relative '../common/sample'

################################################################################

class Sample07 < Sample
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
    super('07-callback', 'https://bkaradzic.github.io/bgfx/examples.html#callback', 'Implementing application specific callbacks for taking screen shots, caching OpenGL binary shaders, and video capture.')
    @ndc_homogeneous = true

    @m_vbh = nil
    @m_ibh = nil
    @m_program = nil

    @m_callback = nil
    @m_allocator = nil
    @cb = nil
    @print_from_callback = nil

    @bgfx_init_success = nil
  end

  def setup(width, height, debug, reset)
    super(width, height, debug, reset)

    @debug = Bgfx::Debug_None
    @reset = 0 | Bgfx::Reset_Vsync | Bgfx::Reset_Capture | Bgfx::Reset_Msaa_X16

    @print_from_callback = true

    @cb = Bgfx_callback_vtbl_t.new
    @cb[:fatal] = FFI::Function.new(:void, [:pointer, :string, :uint16, :uint32, :string], blocking: true) do |_this, _filePath, _line, _code, _str|
      puts "fatal" if @print_from_callback
    end
    #@cb[:trace_vargs] = FFI::Function.new(:void, [:pointer, :string, :uint16, :string, :pointer], blocking: true) do |_this, _filePath, _line, _format, _argList|
    @cb[:trace_vargs] = Proc.new do |_this, _filePath, _line, _format, _argList|
      # [NOTE] Pracically unusable.
      # The last argument corresponds to "va_list" given to BX_TRACE.
      # Though we can pass variable arguments from Ruby to C by Ruby/FFI's :vararg feature, there's no way to handle "va_list" given from C in Ruby.
      puts "trace_vargs. #{_this}, #{_filePath}, #{_line}, #{_format}, #{_argList}" if @print_from_callback
    end
    # @cb[:profiler_begin] = FFI::Function.new(:void, [:pointer, :string, :uint32, :string, :uint16], blocking: true) do |_this, _name, _abgr, _filePath, _line|
    @cb[:profiler_begin] = Proc.new do |_this, _name, _abgr, _filePath, _line|
      puts "profiler_begin" if @print_from_callback
    end
    # @cb[:profiler_begin_literal] = FFI::Function.new(:void, [:pointer, :string, :uint32, :string, :uint16], blocking: true) do |_this, _name, _abgr, _filePath, _line|
    @cb[:profiler_begin_literal] = Proc.new do |_this, _name, _abgr, _filePath, _line|
      puts "profiler_begin_literal" if @print_from_callback
    end
    # @cb[:profiler_end] = FFI::Function.new(:void, [:pointer], blocking: true) do |_this|
    @cb[:profiler_end] = Proc.new do |_this|
      puts "profiler_end" if @print_from_callback
    end
    # @cb[:cache_read_size] = FFI::Function.new(:uint32, [:pointer, :uint64], blocking: true) do |_this, _id|
    @cb[:cache_read_size] = Proc.new do |_this, _id|
      puts "cache_read_size: %016" % _id if @print_from_callback
      filePath = "temp/#{_id}"
      if File.exist? filePath
        File.size(filePath)
      else
        0
      end
    end
    # @cb[:cache_read] = FFI::Function.new(:bool, [:pointer, :uint64, :pointer, :uint32], blocking: true) do |_this, _id, _data, _size|
    @cb[:cache_read] = Proc.new do |_this, _id, _data, _size|
      puts "cache_read: %016" % _id if @print_from_callback
      filePath = "temp/#{_id}"
      File.open(filePath, "rb") do |f|
        _data.write_string(f.read(_data.read_string_length(_size)))
      end
      return true
    end
    # @cb[:cache_write] = FFI::Function.new(:void, [:pointer, :uint64, :pointer, :uint32], blocking: true) do |_this, _id, _data, _size|
    @cb[:cache_write] = Proc.new do |_this, _id, _data, _size|
      puts "cache_write: %016" % _id if @print_from_callback
      Dir.mkdir("temp") if not Dir.exist?("temp")
      filePath = "temp/#{_id}"
      File.open(filePath, "wb") do |f|
        f.write(_data.read_string_length(_size))
      end
    end
    # @cb[:screen_shot] = FFI::Function.new(:void, [:pointer, :string, :uint32, :uint32, :uint32, :pointer, :uint32, :bool], blocking: true) do |_this, _filePath, _width, _height, _pitch, _data, _size, _yflip|
    @cb[:screen_shot] = Proc.new do |_this, _filePath, _width, _height, _pitch, _data, _size, _yflip|
      puts "screen_shot" if @print_from_callback
    end
    # @cb[:capture_begin] = FFI::Function.new(:void, [:pointer, :uint32, :uint32, :uint32, :bool], blocking: true) do |_this, _width, _height, _pitch, _format, _yflip|
    @cb[:capture_begin] = Proc.new do |_this, _width, _height, _pitch, _format, _yflip|
      puts "capture_begin" if @print_from_callback
    end
    # @cb[:capture_end] = FFI::Function.new(:void, [:pointer], blocking: true) do |_this|
    @cb[:capture_end] = Proc.new do |_this|
      puts "capture_end" if @print_from_callback
    end
    # @cb[:capture_frame] = FFI::Function.new(:void, [:pointer, :pointer, :uint32], blocking: true) do |_this, _data, _size|
    @cb[:capture_frame] = Proc.new do |_this, _data, _size|
      puts "capture_frame" if @print_from_callback
    end

    @m_callback = Bgfx_callback_interface_t.new
    @m_callback[:vtbl] = @cb

    init = Bgfx_init_t.new
    init[:type] = BgfxUtils.platform_renderer_type # OpenGL / Metal
    init[:vendorId] = Bgfx::Pci_Id_None
    init[:resolution][:width] = width
    init[:resolution][:height] = height
    init[:resolution][:reset] = reset
    init[:limits][:maxEncoders] = 1
    init[:limits][:transientVbSize] = 6 << 20
    init[:limits][:transientIbSize] = 2 << 20
    init[:callback] = @m_callback

    @bgfx_init_success = Bgfx.init(init)
    warn('Failed to initialize Bgfx') unless @bgfx_init_success

    bgfx_caps = Bgfx_caps_t.new(Bgfx.get_caps)
    @ndc_homogeneous = bgfx_caps[:homogeneousDepth]

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

    @m_program = BgfxUtils.load_program("vs_callback", "fs_callback", "#{__dir__}/../")

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
    Bgfx.shutdown if @bgfx_init_success

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

    mtx_t, mtx_ry, mtx_rx = RMtx4.new, RMtx4.new, RMtx4.new
    xfrm = FFI::MemoryPointer.new(:float, 16)
    11.times do |yy|
      11.times do |xx|
        mtx_transform = mtx_t.translation(-15.0 + xx * 3.0, -15.0 + yy * 3.0, 0.0) * mtx_ry.rotationY(@time + yy * 0.37) * mtx_rx.rotationX(@time + xx * 0.21)
        xfrm.write_array_of_float(mtx_transform.to_a)
        Bgfx::set_transform(xfrm, 1)
        Bgfx::set_vertex_buffer(0, @m_vbh, 0, 0xffffffff) # 0xffffffff == UINT32_MAX
        Bgfx::set_index_buffer(@m_ibh, 0, 0xffffffff) # 0xffffffff == UINT32_MAX
        Bgfx::set_state(Bgfx::State_Write_Rgb | Bgfx::State_Write_A | Bgfx::State_Write_Z | Bgfx::State_Depth_Test_Less | Bgfx::State_Cull_Cw | Bgfx::State_Msaa)

        Bgfx::submit(0, @m_program)
      end
    end

    ImGui::Render()
    ImGui::ImplBgfx_RenderDrawData(ImGui::GetDrawData())

    Bgfx.frame
  end
end
