# coding: utf-8
require 'ffi'
require_relative '../../bindings/ruby/bgfx.rb'
require_relative 'imgui'
require_relative 'utils'

module ImGui

  # [Not used yet] Structs for type conversion (or type-punning), used in ImplBgfx_RenderDrawData.

  class TextureIdBgfx < FFI::Struct
    layout :handle, Bgfx_texture_handle_t.by_value,
           :flags, :uint8,
           :mip, :uint8
  end

  class TextureIdImGui < FFI::Union
    layout :id, :ImTextureID,
           :id, TextureIdBgfx.by_value
  end

  @@m_layout = nil # bgfx::VertexLayout
  @@m_program = nil # bgfx::ProgramHandle
  @@m_imageProgram = nil # bgfx::ProgramHandle
  @@m_texture = nil # bgfx::TextureHandle
  @@s_tex = nil # bgfx::UniformHandle
  @@u_imageLodEnabled = nil # bgfx::UniformHandle
  @@m_viewId = 255 # bgfx::ViewId

  @@g_BackendRendererName = FFI::MemoryPointer.from_string("imgui_impl_bgfx")

  @@font = nil
  def self.ImplBgfx_GetFont()
    return @@font
  end

  def self.ImplBgfx_Init()
    io = ImGuiIO.new(ImGui::GetIO())
    io[:BackendRendererName] = @@g_BackendRendererName

    @@m_program = BgfxUtils.load_program("vs_ocornut_imgui", "fs_ocornut_imgui", "./")
    @@u_imageLodEnabled  = Bgfx::bgfx_create_uniform("u_imageLodEnabled",  Bgfx::UniformType::Vec4, -1)
    @@m_imageProgram = BgfxUtils.load_program("vs_imgui_image", "fs_imgui_image", "./")

    if @@m_layout == nil
      @@m_layout = Bgfx_vertex_layout_t.new
      Bgfx::bgfx_vertex_layout_begin(@@m_layout, Bgfx::RendererType::Noop)
      Bgfx::bgfx_vertex_layout_add(@@m_layout, Bgfx::Attrib::Position, 2, Bgfx::AttribType::Float, false, false)
      Bgfx::bgfx_vertex_layout_add(@@m_layout, Bgfx::Attrib::TexCoord0, 2, Bgfx::AttribType::Float, false, false)
      Bgfx::bgfx_vertex_layout_add(@@m_layout, Bgfx::Attrib::Color0, 4, Bgfx::AttribType::Uint8, true, false)
      Bgfx::bgfx_vertex_layout_end(@@m_layout)
    end

    @@s_tex  = Bgfx::bgfx_create_uniform("s_tex",  Bgfx::UniformType::Sampler, -1)

    if @@font == nil
      io[:Fonts].AddFontDefault()
      @@font = io[:Fonts].AddFontFromFileTTF('./jpfont/GenShinGothic-Normal.ttf', 24.0, nil, io[:Fonts].GetGlyphRangesChineseFull())
    end

    pixels = FFI::MemoryPointer.new :pointer
    width = FFI::MemoryPointer.new :int
    height = FFI::MemoryPointer.new :int
    io[:Fonts].GetTexDataAsRGBA32(pixels, width, height, nil)

    ptr = Bgfx::bgfx_copy(pixels.read_pointer, width.read_uint16 * height.read_uint16 * 4)
    mem = Bgfx_memory_t.new(ptr)
    @@m_texture = Bgfx::bgfx_create_texture_2d(width.read_uint16, height.read_uint16, false, 1, Bgfx::TextureFormat::BGRA8, 0, mem)

    return true
  end

  def self.ImplBgfx_Shutdown()
    Bgfx::bgfx_destroy_uniform(@@s_tex) if @@s_tex != nil
    Bgfx::bgfx_destroy_texture(@@m_texture) if @@m_texture != nil

    Bgfx::bgfx_destroy_uniform(@@u_imageLodEnabled) if @@u_imageLodEnabled != nil
    Bgfx::bgfx_destroy_program(@@m_imageProgram) if @@m_imageProgram != nil
    Bgfx::bgfx_destroy_program(@@m_program) if @@m_program != nil

    Bgfx::bgfx_destroy_vertex_layout(@@m_layout)

    @@m_texture = nil
    @@s_tex = nil
    @@m_imageProgram = nil
    @@u_imageLodEnabled = nil
    @@m_program = nil
    @@m_layout = nil
  end

  def self.ImplBgfx_RenderDrawData(draw_data_raw)
    io = ImGuiIO.new(ImGui::GetIO())
    window_width = io[:DisplaySize][:x]
    window_height = io[:DisplaySize][:y]

    Bgfx::bgfx_set_view_name(@@m_viewId, "ImGui")
    Bgfx::bgfx_set_view_mode(@@m_viewId, Bgfx::ViewMode::Sequential)

    mtxOrtho = RMtx4.new.orthoRH(window_width.to_f, window_height.to_f, 0.0, 1000.0 ) # TODO bgfx::getCaps()->homogeneousDepth
    ortho =  FFI::MemoryPointer.new(:float, 16).write_array_of_float(mtxOrtho.to_a)
    Bgfx::bgfx_set_view_transform(@@m_viewId, nil, ortho)
    Bgfx::bgfx_set_view_rect(@@m_viewId, 0, 0, window_width, window_height)

    draw_data = ImDrawData.new(draw_data_raw)

    #  Render command lists
    draw_data[:CmdListsCount].times do |n|
      tvb = Bgfx_transient_vertex_buffer_t.new
      tib = Bgfx_transient_index_buffer_t.new

      draw_list = ImDrawList.new((draw_data[:CmdLists].pointer + 8 * n).read_pointer) # 8 == const ImDrawList*
      num_vertices = draw_list[:VtxBuffer][:Size]
      num_indices =  draw_list[:IdxBuffer][:Size]

      transient_buffers_available =
        (num_vertices == Bgfx::bgfx_get_avail_transient_vertex_buffer(num_vertices, @@m_layout)) &&
        (0 == num_indices || num_indices == Bgfx::bgfx_get_avail_transient_index_buffer(num_indices)) # == checkAvailTransientBuffers()
      break if not transient_buffers_available

      Bgfx::bgfx_alloc_transient_vertex_buffer(tvb, num_vertices, @@m_layout)
      Bgfx::bgfx_alloc_transient_index_buffer(tib, num_indices)

      tvb[:data].write_string(draw_list[:VtxBuffer][:Data].read_bytes(num_vertices * ImDrawVert.size))
      tib[:data].write_string(draw_list[:IdxBuffer][:Data].read_bytes(num_indices * 2)) # 2 == ImDrawIdx(== :ushort ).size

      offset = 0
      draw_list[:CmdBuffer][:Size].times do |i|
        cmd = ImDrawCmd.new(draw_list[:CmdBuffer][:Data] + ImDrawCmd.size * i) # const ImDrawCmd*
        if cmd[:UserCallback] != nil
          # [TODO] Handle user callback (Ref.: https://github.com/ffi/ffi/wiki/Callbacks )
          #   cmd[:UserCallback](draw_list, cmd)
        elsif cmd[:ElemCount] != 0
          state = 0 | Bgfx::State_Write_Rgb | Bgfx::State_Write_A | Bgfx::State_Msaa
          th = @@m_texture
          program = @@m_program

          if cmd[:TextureId] != nil
            puts "Not implemented yet" # TODO
          else
            # ↓state |= BGFX_STATE_BLEND_FUNC(BGFX_STATE_BLEND_SRC_ALPHA, BGFX_STATE_BLEND_INV_SRC_ALPHA);
            state |= ((Bgfx::State_Blend_SrcAlpha | (Bgfx::State_Blend_InvSrcAlpha << 4)) |
                      ((Bgfx::State_Blend_SrcAlpha | (Bgfx::State_Blend_InvSrcAlpha << 4)) << 8)) 
          end
          xx = [cmd[:ClipRect][:x], 0.0].max.to_i
          yy = [cmd[:ClipRect][:y], 0.0].max.to_i
          Bgfx::bgfx_set_scissor(xx, yy, ([cmd[:ClipRect][:z], 65535.0].min-xx).to_i, ([cmd[:ClipRect][:w], 65535.0].min-yy).to_i)

          Bgfx::bgfx_set_state(state, 0)
          Bgfx::bgfx_set_texture(0, @@s_tex, th, 0xffffffff) # 0xffffffff == UINT32_MAX
          Bgfx::bgfx_set_transient_vertex_buffer(0, tvb, 0, num_vertices)
          Bgfx::bgfx_set_transient_index_buffer(tib, offset, cmd[:ElemCount])
          Bgfx::bgfx_submit(@@m_viewId, program, 0, Bgfx::Discard_All)
        end
        offset += cmd[:ElemCount]
      end
    end

  end

end
