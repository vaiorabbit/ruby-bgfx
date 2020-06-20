require 'ffi'
require 'sdl2'
require 'rmath3d/rmath3d'

module BgfxUtils

  ################################################################################

  def self.load_shader(name, runtime_path = "../runtime/")

    shader_path = case Bgfx::bgfx_get_renderer_type()
                  when Bgfx::RendererType::OpenGL
                    "shaders/glsl/"
                  when Bgfx::RendererType::Metal
                    "shaders/metal/"
                  when Bgfx::RendererType::Direct3D11, Bgfx::RendererType::Direct3D12
                    "shaders/dx11/"
                  else
                    $stderr.puts "BgfxUtils.load_shader: You should not be here!"
                  end

    file_path = runtime_path + shader_path + name + ".bin"

    shader_binary = IO.binread(file_path)
    shader_mem = FFI::MemoryPointer.from_string(shader_binary)
    handle = Bgfx::bgfx_create_shader(Bgfx::bgfx_make_ref(shader_mem, shader_mem.size))
    Bgfx::bgfx_set_shader_name(handle, name, 0x7fffffff) # 0x7fffffff == INT32_MAX

    return handle
  end

  def self.load_program(vs_name, fs_name, runtime_path = "../runtime/")
    vsh = load_shader(vs_name, runtime_path)
    fsh = fs_name != nil ? load_shader(fs_name, runtime_path) : Bgfx::Bgfx_Invalid_Handle
    return Bgfx::bgfx_create_program(vsh, fsh, true)
  end

  ################################################################################

  def self.load_texture(name, runtime_path = "../runtime/")
    texture_raw = IO.binread(runtime_path + name)
    texture_mem = FFI::MemoryPointer.from_string(texture_raw)

    return Bgfx::bgfx_create_texture(
      Bgfx::bgfx_make_ref(texture_mem, texture_mem.size),
      Bgfx::Texture_None|Bgfx::Sampler_None,
      0,
      nil
    )
  end

  ################################################################################

  def self.to_unorm(_value, _scale)
    ((_value.clamp(0.0, 1.0) * _scale) + 0.5).floor
  end

  # usage) pp BgfxUtils.encode_normal_rgba8(0.0, 1.0, 0.0).to_s(16) => "8080ff80"
  def self.encode_normal_rgba8(_x, _y = 0.0, _z = 0.0, _w = 0.0)
    to_unorm = lambda { |_value, _scale| ((_value.clamp(0.0, 1.0) * _scale) + 0.5).floor }
    src = [
      _x * 0.5 + 0.5,
      _y * 0.5 + 0.5,
      _z * 0.5 + 0.5,
      _w * 0.5 + 0.5,
    ]
    dst = [
      to_unorm(src[0], 255.0),
      to_unorm(src[1], 255.0),
      to_unorm(src[2], 255.0),
      to_unorm(src[3], 255.0),
    ]
    return dst.pack("C4").unpack1("L")
  end

  ################################################################################

  class PosTexcoord
    def initialize
      @m_pos = FFI::MemoryPointer.new(:float, 4)
      @m_texcoord = FFI::MemoryPointer.new(:float, 4)
    end
    def m_x; @m_pos[0]; end
    def m_y; @m_pos[1]; end
    def m_z; @m_pos[2]; end
    def m_u; @m_texcoord[0]; end
    def m_v; @m_texcoord[1]; end
  end

  def self.calc_tangents(_vertices, _numVertices, _layout, _indices)

    tangents = Array.new (2 * _numVertices) { RVec3.new }
    v0 = PosTexcoord.new
    v1 = PosTexcoord.new
    v2 = PosTexcoord.new

    num = _indices.length / 3
    num.times do |ii|
      indices = _indices[ii * 3, 3]
      i0 = indices[0]
      i1 = indices[1]
      i2 = indices[2]

      Bgfx::bgfx_vertex_unpack(v0.m_x, Bgfx::Attrib::Position, _layout, _vertices, i0)
      Bgfx::bgfx_vertex_unpack(v0.m_u, Bgfx::Attrib::TexCoord0, _layout, _vertices, i0)

      Bgfx::bgfx_vertex_unpack(v1.m_x, Bgfx::Attrib::Position, _layout, _vertices, i1)
      Bgfx::bgfx_vertex_unpack(v1.m_u, Bgfx::Attrib::TexCoord0, _layout, _vertices, i1)

      Bgfx::bgfx_vertex_unpack(v2.m_x, Bgfx::Attrib::Position, _layout, _vertices, i2)
      Bgfx::bgfx_vertex_unpack(v2.m_u, Bgfx::Attrib::TexCoord0, _layout, _vertices, i2)

      bax = v1.m_x.read_float - v0.m_x.read_float
      bay = v1.m_y.read_float - v0.m_y.read_float
      baz = v1.m_z.read_float - v0.m_z.read_float
      bau = v1.m_u.read_float - v0.m_u.read_float
      bav = v1.m_v.read_float - v0.m_v.read_float

      cax = v2.m_x.read_float - v0.m_x.read_float
      cay = v2.m_y.read_float - v0.m_y.read_float
      caz = v2.m_z.read_float - v0.m_z.read_float
      cau = v2.m_u.read_float - v0.m_u.read_float
      cav = v2.m_v.read_float - v0.m_v.read_float

      det = (bau * cav - bav * cau)
      invDet = 1.0 / det

      tx = (bax * cav - cax * bav) * invDet
      ty = (bay * cav - cay * bav) * invDet
      tz = (baz * cav - caz * bav) * invDet

      bx = (cax * bau - bax * cau) * invDet
      by = (cay * bau - bay * cau) * invDet
      bz = (caz * bau - baz * cau) * invDet

      3.times do |jj|
        tanu = tangents[indices[jj] + 0]
        tanv = tangents[indices[jj] + 1]
        tanu[0] += tx
        tanu[1] += ty
        tanu[2] += tz
        tanv[0] += bx
        tanv[1] += by
        tanv[2] += bz
      end
    end

    nxyzw = FFI::MemoryPointer.new(:float, 4)
    tangent = FFI::MemoryPointer.new(:float, 4)
    _numVertices.times do |ii|
      tanu = tangents[ii + 0]
      tanv = tangents[ii + 1]

      Bgfx::bgfx_vertex_unpack(nxyzw, Bgfx::Attrib::Normal, _layout, _vertices, ii)

      normal = RVec3.new(*nxyzw.read_array_of_float(3))
      ndt    = RVec3.dot(normal, tanu)
      nxt    = RVec3.cross(normal, tanu);
      tmp    = (tanu - (ndt * normal)).normalize!

      tangent.write_array_of_float([*tmp.to_a, RVec3.dot(nxt, tanv) < 0 ? -1.0 : 1.0])
      Bgfx::bgfx_vertex_pack(tangent, true, Bgfx::Attrib::Tangent, _layout, _vertices, ii)
    end
  end

  ################################################################################

  def self.platform_renderer_type()
    case RUBY_PLATFORM
    when /mswin|msys|mingw|cygwin/
      Bgfx::RendererType::OpenGL
    when /darwin/
      Bgfx::RendererType::Metal
    when /linux/
      raise RuntimeError, "Not supported yet: #{RUBY_PLATFORM}"
    else
      raise RuntimeError, "Unknown OS: #{RUBY_PLATFORM}"
    end
  end

end

####################################################################################################

module SampleUtils

  ################################################################################

  def self.sdl2_dll_path
    path = case RUBY_PLATFORM
           when /mswin|msys|mingw|cygwin/
             Dir.pwd + '/' + 'SDL2.dll'
           when /darwin/
             './libSDL2.dylib'
           when /linux/
             './libSDL2.so'
           else
             raise RuntimeError, "Unknown OS: #{RUBY_PLATFORM}"
           end
    return path
  end

  ################################################################################

  def self.bgfx_dll_path(config = "Release")
    path = case RUBY_PLATFORM
           when /mswin|msys|mingw|cygwin/
             Dir.pwd + "/bgfx-shared-lib#{config}.dll"
           when /darwin/
             "./libbgfx-shared-lib#{config}.dylib"
           when /linux/
             "./libbgfx-shared-lib#{config}.so"
           else
             raise RuntimeError, "Unknown OS: #{RUBY_PLATFORM}"
           end
    return path
  end

  ################################################################################

  def self.imgui_dll_path
    path = case RUBY_PLATFORM
           when /mswin|msys|mingw|cygwin/
             Dir.pwd + '/' + 'imgui.dll'
           when /darwin/
             './imgui.dylib'
           when /linux/
             './imgui.so'
           else
             raise RuntimeError, "Unknown OS: #{RUBY_PLATFORM}"
           end
    return path
  end

  ################################################################################

  def self.native_window_handle(sdl2_window)
    nwh = case RUBY_PLATFORM
          when /mswin|msys|mingw|cygwin/
            wminfo = SDL2::SDL_SysWMinfo_win.new
            if SDL2::SDL_GetWindowWMInfo(sdl2_window, wminfo) == SDL2::SDL_TRUE
              wminfo[:info][:win][:window]
            else
              nil
            end
          when /darwin/
            wminfo = SDL2::SDL_SysWMinfo_cocoa.new
            if SDL2::SDL_GetWindowWMInfo(sdl2_window, wminfo) == SDL2::SDL_TRUE
              wminfo[:info][:cocoa][:window]
            else
              nil
            end
          when /linux/
            raise RuntimeError, "Not supported yet: #{RUBY_PLATFORM}"
          else
            raise RuntimeError, "Unknown OS: #{RUBY_PLATFORM}"
          end
    return nwh
  end

end
