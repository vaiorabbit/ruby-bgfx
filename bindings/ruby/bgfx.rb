require 'ffi'

#
# Typedefs
#

FFI.typedef :uint16, :Bgfx_view_id_t # [HACK] Hard-coded. Seems we can't get information about this from current 'bgfx.idl'.

FFI.typedef :int, :Bgfx_fatal_t

FFI.typedef :int, :Bgfx_renderer_type_t

FFI.typedef :int, :Bgfx_access_t

FFI.typedef :int, :Bgfx_attrib_t

FFI.typedef :int, :Bgfx_attrib_type_t

FFI.typedef :int, :Bgfx_texture_format_t

FFI.typedef :int, :Bgfx_uniform_type_t

FFI.typedef :int, :Bgfx_backbuffer_ratio_t

FFI.typedef :int, :Bgfx_occlusion_query_result_t

FFI.typedef :int, :Bgfx_topology_t

FFI.typedef :int, :Bgfx_topology_convert_t

FFI.typedef :int, :Bgfx_topology_sort_t

FFI.typedef :int, :Bgfx_view_mode_t

FFI.typedef :int, :Bgfx_render_frame_t


#
# Enums / Bitflags
#
module Bgfx

    extend FFI::Library

    @@bgfx_import_done = false

    def self.load_lib(libpath = './libbgfx-shared-libRelease.dylib')
      ffi_lib_flags :now, :global
      ffi_lib libpath
      import_symbols() unless @@bgfx_import_done
    end

    State_Write_R = 0x0000000000000001 # Enable R write.
	State_Write_G = 0x0000000000000002 # Enable G write.
	State_Write_B = 0x0000000000000004 # Enable B write.
	State_Write_A = 0x0000000000000008 # Enable alpha write.
	State_Write_Z = 0x0000004000000000 # Enable depth write.
	State_Write_Rgb = 0x0000000000000007 # Enable RGB write.
	State_Write_Mask = 0x000000400000000f # Write all channels mask.
	
	State_Depth_Test_Less = 0x0000000000000010 # Enable depth test, less.
	State_Depth_Test_Lequal = 0x0000000000000020 # Enable depth test, less or equal.
	State_Depth_Test_Equal = 0x0000000000000030 # Enable depth test, equal.
	State_Depth_Test_Gequal = 0x0000000000000040 # Enable depth test, greater or equal.
	State_Depth_Test_Greater = 0x0000000000000050 # Enable depth test, greater.
	State_Depth_Test_Notequal = 0x0000000000000060 # Enable depth test, not equal.
	State_Depth_Test_Never = 0x0000000000000070 # Enable depth test, never.
	State_Depth_Test_Always = 0x0000000000000080 # Enable depth test, always.
	State_Depth_Test_Shift = 4 # Depth test state bit shift
	State_Depth_Test_Mask = 0x00000000000000f0 # Depth test state bit mask
	
	State_Blend_Zero = 0x0000000000001000 # 0, 0, 0, 0
	State_Blend_One = 0x0000000000002000 # 1, 1, 1, 1
	State_Blend_SrcColor = 0x0000000000003000 # Rs, Gs, Bs, As
	State_Blend_InvSrcColor = 0x0000000000004000 # 1-Rs, 1-Gs, 1-Bs, 1-As
	State_Blend_SrcAlpha = 0x0000000000005000 # As, As, As, As
	State_Blend_InvSrcAlpha = 0x0000000000006000 # 1-As, 1-As, 1-As, 1-As
	State_Blend_DstAlpha = 0x0000000000007000 # Ad, Ad, Ad, Ad
	State_Blend_InvDstAlpha = 0x0000000000008000 # 1-Ad, 1-Ad, 1-Ad ,1-Ad
	State_Blend_DstColor = 0x0000000000009000 # Rd, Gd, Bd, Ad
	State_Blend_InvDstColor = 0x000000000000a000 # 1-Rd, 1-Gd, 1-Bd, 1-Ad
	State_Blend_SrcAlphaSat = 0x000000000000b000 # f, f, f, 1; f = min(As, 1-Ad)
	State_Blend_Factor = 0x000000000000c000 # Blend factor
	State_Blend_InvFactor = 0x000000000000d000 # 1-Blend factor
	State_Blend_Shift = 12 # Blend state bit shift
	State_Blend_Mask = 0x000000000ffff000 # Blend state bit mask
	
	State_Blend_Equation_Add = 0x0000000000000000 # Blend add: src + dst.
	State_Blend_Equation_Sub = 0x0000000010000000 # Blend subtract: src - dst.
	State_Blend_Equation_Revsub = 0x0000000020000000 # Blend reverse subtract: dst - src.
	State_Blend_Equation_Min = 0x0000000030000000 # Blend min: min(src, dst).
	State_Blend_Equation_Max = 0x0000000040000000 # Blend max: max(src, dst).
	State_Blend_Equation_Shift = 28 # Blend equation bit shift
	State_Blend_Equation_Mask = 0x00000003f0000000 # Blend equation bit mask
	
	State_Cull_Cw = 0x0000001000000000 # Cull clockwise triangles.
	State_Cull_Ccw = 0x0000002000000000 # Cull counter-clockwise triangles.
	State_Cull_Shift = 36 # Culling mode bit shift
	State_Cull_Mask = 0x0000003000000000 # Culling mode bit mask
	
	State_Alpha_Ref_Shift = 40 # Alpha reference bit shift
	State_Alpha_Ref_Mask = 0x0000ff0000000000 # Alpha reference bit mask
	def self.State_Alpha_Ref(v); return (v << State_Alpha_Ref_Shift) & State_Alpha_Ref_Mask; end
	
	State_Pt_Tristrip = 0x0001000000000000 # Tristrip.
	State_Pt_Lines = 0x0002000000000000 # Lines.
	State_Pt_Linestrip = 0x0003000000000000 # Line strip.
	State_Pt_Points = 0x0004000000000000 # Points.
	State_Pt_Shift = 48 # Primitive type bit shift
	State_Pt_Mask = 0x0007000000000000 # Primitive type bit mask
	
	State_Point_Size_Shift = 52 # Point size bit shift
	State_Point_Size_Mask = 0x00f0000000000000 # Point size bit mask
	def self.State_Point_Size(v); return (v << State_Point_Size_Shift) & State_Point_Size_Mask; end
	
	State_Msaa = 0x0100000000000000 # Enable MSAA rasterization.
	State_Lineaa = 0x0200000000000000 # Enable line AA rasterization.
	State_ConservativeRaster = 0x0400000000000000 # Enable conservative rasterization.
	State_None = 0x0000000000000000 # No state.
	State_FrontCcw = 0x0000008000000000 # Front counter-clockwise (default is clockwise).
	State_BlendIndependent = 0x0000000400000000 # Enable blend independent.
	State_BlendAlphaToCoverage = 0x0000000800000000 # Enable alpha to coverage.
	#
	# Default state is write to RGB, alpha, and depth with depth test less enabled, with clockwise
	# culling and MSAA (when writing into MSAA frame buffer, otherwise this flag is ignored).
	#
	State_Default = State_Write_Rgb | State_Write_A | State_Write_Z | State_Depth_Test_Less | State_Cull_Cw | State_Msaa
	State_Mask = 0xffffffffffffffff # State bit mask
	
	State_Reserved_Shift = 61
	State_Reserved_Mask = 0xe000000000000000
	
	Stencil_Func_Ref_Shift = 0
	Stencil_Func_Ref_Mask = 0x000000ff
	def self.Stencil_Func_Ref(v); return (v << Stencil_Func_Ref_Shift) & Stencil_Func_Ref_Mask; end
	
	Stencil_Func_Rmask_Shift = 8
	Stencil_Func_Rmask_Mask = 0x0000ff00
	def self.Stencil_Func_Rmask(v); return (v << Stencil_Func_Rmask_Shift) & Stencil_Func_Rmask_Mask; end
	
	Stencil_None = 0x00000000
	Stencil_Mask = 0xffffffff
	Stencil_Default = 0x00000000
	
	Stencil_Test_Less = 0x00010000 # Enable stencil test, less.
	Stencil_Test_Lequal = 0x00020000 # Enable stencil test, less or equal.
	Stencil_Test_Equal = 0x00030000 # Enable stencil test, equal.
	Stencil_Test_Gequal = 0x00040000 # Enable stencil test, greater or equal.
	Stencil_Test_Greater = 0x00050000 # Enable stencil test, greater.
	Stencil_Test_Notequal = 0x00060000 # Enable stencil test, not equal.
	Stencil_Test_Never = 0x00070000 # Enable stencil test, never.
	Stencil_Test_Always = 0x00080000 # Enable stencil test, always.
	Stencil_Test_Shift = 16 # Stencil test bit shift
	Stencil_Test_Mask = 0x000f0000 # Stencil test bit mask
	
	Stencil_Op_Fail_S_Zero = 0x00000000 # Zero.
	Stencil_Op_Fail_S_Keep = 0x00100000 # Keep.
	Stencil_Op_Fail_S_Replace = 0x00200000 # Replace.
	Stencil_Op_Fail_S_Incr = 0x00300000 # Increment and wrap.
	Stencil_Op_Fail_S_Incrsat = 0x00400000 # Increment and clamp.
	Stencil_Op_Fail_S_Decr = 0x00500000 # Decrement and wrap.
	Stencil_Op_Fail_S_Decrsat = 0x00600000 # Decrement and clamp.
	Stencil_Op_Fail_S_Invert = 0x00700000 # Invert.
	Stencil_Op_Fail_S_Shift = 20 # Stencil operation fail bit shift
	Stencil_Op_Fail_S_Mask = 0x00f00000 # Stencil operation fail bit mask
	
	Stencil_Op_Fail_Z_Zero = 0x00000000 # Zero.
	Stencil_Op_Fail_Z_Keep = 0x01000000 # Keep.
	Stencil_Op_Fail_Z_Replace = 0x02000000 # Replace.
	Stencil_Op_Fail_Z_Incr = 0x03000000 # Increment and wrap.
	Stencil_Op_Fail_Z_Incrsat = 0x04000000 # Increment and clamp.
	Stencil_Op_Fail_Z_Decr = 0x05000000 # Decrement and wrap.
	Stencil_Op_Fail_Z_Decrsat = 0x06000000 # Decrement and clamp.
	Stencil_Op_Fail_Z_Invert = 0x07000000 # Invert.
	Stencil_Op_Fail_Z_Shift = 24 # Stencil operation depth fail bit shift
	Stencil_Op_Fail_Z_Mask = 0x0f000000 # Stencil operation depth fail bit mask
	
	Stencil_Op_Pass_Z_Zero = 0x00000000 # Zero.
	Stencil_Op_Pass_Z_Keep = 0x10000000 # Keep.
	Stencil_Op_Pass_Z_Replace = 0x20000000 # Replace.
	Stencil_Op_Pass_Z_Incr = 0x30000000 # Increment and wrap.
	Stencil_Op_Pass_Z_Incrsat = 0x40000000 # Increment and clamp.
	Stencil_Op_Pass_Z_Decr = 0x50000000 # Decrement and wrap.
	Stencil_Op_Pass_Z_Decrsat = 0x60000000 # Decrement and clamp.
	Stencil_Op_Pass_Z_Invert = 0x70000000 # Invert.
	Stencil_Op_Pass_Z_Shift = 28 # Stencil operation depth pass bit shift
	Stencil_Op_Pass_Z_Mask = 0xf0000000 # Stencil operation depth pass bit mask
	
	Clear_None = 0x0000 # No clear flags.
	Clear_Color = 0x0001 # Clear color.
	Clear_Depth = 0x0002 # Clear depth.
	Clear_Stencil = 0x0004 # Clear stencil.
	Clear_DiscardColor_0 = 0x0008 # Discard frame buffer attachment 0.
	Clear_DiscardColor_1 = 0x0010 # Discard frame buffer attachment 1.
	Clear_DiscardColor_2 = 0x0020 # Discard frame buffer attachment 2.
	Clear_DiscardColor_3 = 0x0040 # Discard frame buffer attachment 3.
	Clear_DiscardColor_4 = 0x0080 # Discard frame buffer attachment 4.
	Clear_DiscardColor_5 = 0x0100 # Discard frame buffer attachment 5.
	Clear_DiscardColor_6 = 0x0200 # Discard frame buffer attachment 6.
	Clear_DiscardColor_7 = 0x0400 # Discard frame buffer attachment 7.
	Clear_DiscardDepth = 0x0800 # Discard frame buffer depth attachment.
	Clear_DiscardStencil = 0x1000 # Discard frame buffer stencil attachment.
	Clear_DiscardColorMask = 0x07f8
	Clear_DiscardMask = 0x1ff8
	
	Discard_None = 0x00 # Preserve everything.
	Discard_Bindings = 0x01 # Discard texture sampler and buffer bindings.
	Discard_IndexBuffer = 0x02 # Discard index buffer.
	Discard_InstanceData = 0x04 # Discard instance data.
	Discard_State = 0x08 # Discard state.
	Discard_Transform = 0x10 # Discard transform.
	Discard_VertexStreams = 0x20 # Discard vertex streams.
	Discard_All = 0xff # Discard all states.
	
	Debug_None = 0x00000000 # No debug.
	Debug_Wireframe = 0x00000001 # Enable wireframe for all primitives.
	#
	# Enable infinitely fast hardware test. No draw calls will be submitted to driver.
	# It's useful when profiling to quickly assess bottleneck between CPU and GPU.
	#
	Debug_Ifh = 0x00000002
	Debug_Stats = 0x00000004 # Enable statistics display.
	Debug_Text = 0x00000008 # Enable debug text display.
	Debug_Profiler = 0x00000010 # Enable profiler.
	
	Buffer_Compute_Format__8x1 = 0x0001 # 1 8-bit value
	Buffer_Compute_Format__8x2 = 0x0002 # 2 8-bit values
	Buffer_Compute_Format__8x4 = 0x0003 # 4 8-bit values
	Buffer_Compute_Format__16x1 = 0x0004 # 1 16-bit value
	Buffer_Compute_Format__16x2 = 0x0005 # 2 16-bit values
	Buffer_Compute_Format__16x4 = 0x0006 # 4 16-bit values
	Buffer_Compute_Format__32x1 = 0x0007 # 1 32-bit value
	Buffer_Compute_Format__32x2 = 0x0008 # 2 32-bit values
	Buffer_Compute_Format__32x4 = 0x0009 # 4 32-bit values
	Buffer_Compute_Format_Shift = 0
	Buffer_Compute_Format_Mask = 0x000f
	
	Buffer_Compute_Type_Int = 0x0010 # Type `int`.
	Buffer_Compute_Type_Uint = 0x0020 # Type `uint`.
	Buffer_Compute_Type_Float = 0x0030 # Type `float`.
	Buffer_Compute_Type_Shift = 4
	Buffer_Compute_Type_Mask = 0x0030
	
	Buffer_None = 0x0000
	Buffer_ComputeRead = 0x0100 # Buffer will be read by shader.
	Buffer_ComputeWrite = 0x0200 # Buffer will be used for writing.
	Buffer_DrawIndirect = 0x0400 # Buffer will be used for storing draw indirect commands.
	Buffer_AllowResize = 0x0800 # Allow dynamic index/vertex buffer resize during update.
	Buffer_Index32 = 0x1000 # Index buffer contains 32-bit indices.
	Buffer_ComputeReadWrite = 0x0300
	
	Texture_None = 0x0000000000000000
	Texture_MsaaSample = 0x0000000800000000 # Texture will be used for MSAA sampling.
	Texture_Rt = 0x0000001000000000 # Render target no MSAA.
	Texture_ComputeWrite = 0x0000100000000000 # Texture will be used for compute write.
	Texture_Srgb = 0x0000200000000000 # Sample texture as sRGB.
	Texture_BlitDst = 0x0000400000000000 # Texture will be used as blit destination.
	Texture_ReadBack = 0x0000800000000000 # Texture will be used for read back from GPU.
	
	Texture_Rt_Msaa_X2 = 0x0000002000000000 # Render target MSAAx2 mode.
	Texture_Rt_Msaa_X4 = 0x0000003000000000 # Render target MSAAx4 mode.
	Texture_Rt_Msaa_X8 = 0x0000004000000000 # Render target MSAAx8 mode.
	Texture_Rt_Msaa_X16 = 0x0000005000000000 # Render target MSAAx16 mode.
	Texture_Rt_Msaa_Shift = 36
	Texture_Rt_Msaa_Mask = 0x0000007000000000
	
	Texture_Rt_WriteOnly = 0x0000008000000000 # Render target will be used for writing
	Texture_Rt_Shift = 36
	Texture_Rt_Mask = 0x000000f000000000
	
	Sampler_U_Mirror = 0x00000001 # Wrap U mode: Mirror
	Sampler_U_Clamp = 0x00000002 # Wrap U mode: Clamp
	Sampler_U_Border = 0x00000003 # Wrap U mode: Border
	Sampler_U_Shift = 0
	Sampler_U_Mask = 0x00000003
	
	Sampler_V_Mirror = 0x00000004 # Wrap V mode: Mirror
	Sampler_V_Clamp = 0x00000008 # Wrap V mode: Clamp
	Sampler_V_Border = 0x0000000c # Wrap V mode: Border
	Sampler_V_Shift = 2
	Sampler_V_Mask = 0x0000000c
	
	Sampler_W_Mirror = 0x00000010 # Wrap W mode: Mirror
	Sampler_W_Clamp = 0x00000020 # Wrap W mode: Clamp
	Sampler_W_Border = 0x00000030 # Wrap W mode: Border
	Sampler_W_Shift = 4
	Sampler_W_Mask = 0x00000030
	
	Sampler_Min_Point = 0x00000040 # Min sampling mode: Point
	Sampler_Min_Anisotropic = 0x00000080 # Min sampling mode: Anisotropic
	Sampler_Min_Shift = 6
	Sampler_Min_Mask = 0x000000c0
	
	Sampler_Mag_Point = 0x00000100 # Mag sampling mode: Point
	Sampler_Mag_Anisotropic = 0x00000200 # Mag sampling mode: Anisotropic
	Sampler_Mag_Shift = 8
	Sampler_Mag_Mask = 0x00000300
	
	Sampler_Mip_Point = 0x00000400 # Mip sampling mode: Point
	Sampler_Mip_Shift = 10
	Sampler_Mip_Mask = 0x00000400
	
	Sampler_Compare_Less = 0x00010000 # Compare when sampling depth texture: less.
	Sampler_Compare_Lequal = 0x00020000 # Compare when sampling depth texture: less or equal.
	Sampler_Compare_Equal = 0x00030000 # Compare when sampling depth texture: equal.
	Sampler_Compare_Gequal = 0x00040000 # Compare when sampling depth texture: greater or equal.
	Sampler_Compare_Greater = 0x00050000 # Compare when sampling depth texture: greater.
	Sampler_Compare_Notequal = 0x00060000 # Compare when sampling depth texture: not equal.
	Sampler_Compare_Never = 0x00070000 # Compare when sampling depth texture: never.
	Sampler_Compare_Always = 0x00080000 # Compare when sampling depth texture: always.
	Sampler_Compare_Shift = 16
	Sampler_Compare_Mask = 0x000f0000
	
	Sampler_Border_Color_Shift = 24
	Sampler_Border_Color_Mask = 0x0f000000
	def self.Sampler_Border_Color(v); return (v << Sampler_Border_Color_Shift) & Sampler_Border_Color_Mask; end
	
	Sampler_Reserved_Shift = 28
	Sampler_Reserved_Mask = 0xf0000000
	
	Sampler_None = 0x00000000
	Sampler_SampleStencil = 0x00100000 # Sample stencil instead of depth.
	Sampler_Point = Sampler_Min_Point | Sampler_Mag_Point | Sampler_Mip_Point
	Sampler_UvwMirror = Sampler_U_Mirror | Sampler_V_Mirror | Sampler_W_Mirror
	Sampler_UvwClamp = Sampler_U_Clamp | Sampler_V_Clamp | Sampler_W_Clamp
	Sampler_UvwBorder = Sampler_U_Border | Sampler_V_Border | Sampler_W_Border
	Sampler_BitsMask = Sampler_U_Mask | Sampler_V_Mask | Sampler_W_Mask | Sampler_Min_Mask | Sampler_Mag_Mask | Sampler_Mip_Mask | Sampler_Compare_Mask
	
	Reset_Msaa_X2 = 0x00000010 # Enable 2x MSAA.
	Reset_Msaa_X4 = 0x00000020 # Enable 4x MSAA.
	Reset_Msaa_X8 = 0x00000030 # Enable 8x MSAA.
	Reset_Msaa_X16 = 0x00000040 # Enable 16x MSAA.
	Reset_Msaa_Shift = 4
	Reset_Msaa_Mask = 0x00000070
	
	Reset_None = 0x00000000 # No reset flags.
	Reset_Fullscreen = 0x00000001 # Not supported yet.
	Reset_Vsync = 0x00000080 # Enable V-Sync.
	Reset_Maxanisotropy = 0x00000100 # Turn on/off max anisotropy.
	Reset_Capture = 0x00000200 # Begin screen capture.
	Reset_FlushAfterRender = 0x00002000 # Flush rendering after submitting to GPU.
	#
	# This flag specifies where flip occurs. Default behavior is that flip occurs
	# before rendering new frame. This flag only has effect when `BGFX_CONFIG_MULTITHREADED=0`.
	#
	Reset_FlipAfterRender = 0x00004000
	Reset_SrgbBackbuffer = 0x00008000 # Enable sRGB backbuffer.
	Reset_Hdr10 = 0x00010000 # Enable HDR10 rendering.
	Reset_Hidpi = 0x00020000 # Enable HiDPI rendering.
	Reset_DepthClamp = 0x00040000 # Enable depth clamp.
	Reset_Suspend = 0x00080000 # Suspend rendering.
	
	Reset_Fullscreen_Shift = 0
	Reset_Fullscreen_Mask = 0x00000001
	
	Reset_Reserved_Shift = 31 # Internal bit shift
	Reset_Reserved_Mask = 0x80000000 # Internal bit mask
	
	Caps_AlphaToCoverage = 0x0000000000000001 # Alpha to coverage is supported.
	Caps_BlendIndependent = 0x0000000000000002 # Blend independent is supported.
	Caps_Compute = 0x0000000000000004 # Compute shaders are supported.
	Caps_ConservativeRaster = 0x0000000000000008 # Conservative rasterization is supported.
	Caps_DrawIndirect = 0x0000000000000010 # Draw indirect is supported.
	Caps_FragmentDepth = 0x0000000000000020 # Fragment depth is accessible in fragment shader.
	Caps_FragmentOrdering = 0x0000000000000040 # Fragment ordering is available in fragment shader.
	Caps_FramebufferRw = 0x0000000000000080 # Read/Write frame buffer attachments are supported.
	Caps_GraphicsDebugger = 0x0000000000000100 # Graphics debugger is present.
	Caps_Reserved = 0x0000000000000200
	Caps_Hdr10 = 0x0000000000000400 # HDR10 rendering is supported.
	Caps_Hidpi = 0x0000000000000800 # HiDPI rendering is supported.
	Caps_Index32 = 0x0000000000001000 # 32-bit indices are supported.
	Caps_Instancing = 0x0000000000002000 # Instancing is supported.
	Caps_OcclusionQuery = 0x0000000000004000 # Occlusion query is supported.
	Caps_RendererMultithreaded = 0x0000000000008000 # Renderer is on separate thread.
	Caps_SwapChain = 0x0000000000010000 # Multiple windows are supported.
	Caps_Texture_2dArray = 0x0000000000020000 # 2D texture array is supported.
	Caps_Texture_3d = 0x0000000000040000 # 3D textures are supported.
	Caps_TextureBlit = 0x0000000000080000 # Texture blit is supported.
	Caps_TextureCompareReserved = 0x0000000000100000 # All texture compare modes are supported.
	Caps_TextureCompareLequal = 0x0000000000200000 # Texture compare less equal mode is supported.
	Caps_TextureCubeArray = 0x0000000000400000 # Cubemap texture array is supported.
	Caps_TextureDirectAccess = 0x0000000000800000 # CPU direct access to GPU texture memory.
	Caps_TextureReadBack = 0x0000000001000000 # Read-back texture is supported.
	Caps_VertexAttribHalf = 0x0000000002000000 # Vertex attribute half-float is supported.
	Caps_VertexAttribUint10 = 0x0000000004000000 # Vertex attribute 10_10_10_2 is supported.
	Caps_VertexId = 0x0000000008000000 # Rendering with VertexID only is supported.
	Caps_TextureCompareAll = 0x0000000000300000 # All texture compare modes are supported.
	
	Caps_Format_TextureNone = 0x0000 # Texture format is not supported.
	Caps_Format_Texture_2d = 0x0001 # Texture format is supported.
	Caps_Format_Texture_2dSrgb = 0x0002 # Texture as sRGB format is supported.
	Caps_Format_Texture_2dEmulated = 0x0004 # Texture format is emulated.
	Caps_Format_Texture_3d = 0x0008 # Texture format is supported.
	Caps_Format_Texture_3dSrgb = 0x0010 # Texture as sRGB format is supported.
	Caps_Format_Texture_3dEmulated = 0x0020 # Texture format is emulated.
	Caps_Format_TextureCube = 0x0040 # Texture format is supported.
	Caps_Format_TextureCubeSrgb = 0x0080 # Texture as sRGB format is supported.
	Caps_Format_TextureCubeEmulated = 0x0100 # Texture format is emulated.
	Caps_Format_TextureVertex = 0x0200 # Texture format can be used from vertex shader.
	Caps_Format_TextureImage = 0x0400 # Texture format can be used as image from compute shader.
	Caps_Format_TextureFramebuffer = 0x0800 # Texture format can be used as frame buffer.
	Caps_Format_TextureFramebufferMsaa = 0x1000 # Texture format can be used as MSAA frame buffer.
	Caps_Format_TextureMsaa = 0x2000 # Texture can be sampled as MSAA.
	Caps_Format_TextureMipAutogen = 0x4000 # Texture format supports auto-generated mips.
	
	Resolve_None = 0x00 # No resolve flags.
	Resolve_AutoGenMips = 0x01 # Auto-generate mip maps on resolve.
	
	Pci_Id_None = 0x0000 # Autoselect adapter.
	Pci_Id_SoftwareRasterizer = 0x0001 # Software rasterizer.
	Pci_Id_Amd = 0x1002 # AMD adapter.
	Pci_Id_Intel = 0x8086 # Intel adapter.
	Pci_Id_Nvidia = 0x10de # nVidia adapter.
	
	Cube_Map_PositiveX = 0x00 # Cubemap +x.
	Cube_Map_NegativeX = 0x01 # Cubemap -x.
	Cube_Map_PositiveY = 0x02 # Cubemap +y.
	Cube_Map_NegativeY = 0x03 # Cubemap -y.
	Cube_Map_PositiveZ = 0x04 # Cubemap +z.
	Cube_Map_NegativeZ = 0x05 # Cubemap -z.
	
	module Fatal #enum: 5
		DebugCheck = 0
		InvalidShader = 1
		UnableToInitialize = 2
		UnableToCreateTexture = 3
		DeviceLost = 4
	
		Count = 5
	end # module Fatal
	
	module RendererType #enum: 11
		# No rendering.
		Noop = 0
		# Direct3D 9.0
		Direct3D9 = 1
		# Direct3D 11.0
		Direct3D11 = 2
		# Direct3D 12.0
		Direct3D12 = 3
		# GNM
		Gnm = 4
		# Metal
		Metal = 5
		# NVN
		Nvn = 6
		# OpenGL ES 2.0+
		OpenGLES = 7
		# OpenGL 2.1+
		OpenGL = 8
		# Vulkan
		Vulkan = 9
		# WebGPU
		WebGPU = 10
	
		Count = 11
	end # module RendererType
	
	module Access #enum: 3
		# Read.
		Read = 0
		# Write.
		Write = 1
		# Read and write.
		ReadWrite = 2
	
		Count = 3
	end # module Access
	
	module Attrib #enum: 18
		# a_position
		Position = 0
		# a_normal
		Normal = 1
		# a_tangent
		Tangent = 2
		# a_bitangent
		Bitangent = 3
		# a_color0
		Color0 = 4
		# a_color1
		Color1 = 5
		# a_color2
		Color2 = 6
		# a_color3
		Color3 = 7
		# a_indices
		Indices = 8
		# a_weight
		Weight = 9
		# a_texcoord0
		TexCoord0 = 10
		# a_texcoord1
		TexCoord1 = 11
		# a_texcoord2
		TexCoord2 = 12
		# a_texcoord3
		TexCoord3 = 13
		# a_texcoord4
		TexCoord4 = 14
		# a_texcoord5
		TexCoord5 = 15
		# a_texcoord6
		TexCoord6 = 16
		# a_texcoord7
		TexCoord7 = 17
	
		Count = 18
	end # module Attrib
	
	module AttribType #enum: 5
		# Uint8
		Uint8 = 0
		# Uint10, availability depends on: `BGFX_CAPS_VERTEX_ATTRIB_UINT10`.
		Uint10 = 1
		# Int16
		Int16 = 2
		# Half, availability depends on: `BGFX_CAPS_VERTEX_ATTRIB_HALF`.
		Half = 3
		# Float
		Float = 4
	
		Count = 5
	end # module AttribType
	
	module TextureFormat #enum: 85
		# DXT1 R5G6B5A1
		BC1 = 0
		# DXT3 R5G6B5A4
		BC2 = 1
		# DXT5 R5G6B5A8
		BC3 = 2
		# LATC1/ATI1 R8
		BC4 = 3
		# LATC2/ATI2 RG8
		BC5 = 4
		# BC6H RGB16F
		BC6H = 5
		# BC7 RGB 4-7 bits per color channel, 0-8 bits alpha
		BC7 = 6
		# ETC1 RGB8
		ETC1 = 7
		# ETC2 RGB8
		ETC2 = 8
		# ETC2 RGBA8
		ETC2A = 9
		# ETC2 RGB8A1
		ETC2A1 = 10
		# PVRTC1 RGB 2BPP
		PTC12 = 11
		# PVRTC1 RGB 4BPP
		PTC14 = 12
		# PVRTC1 RGBA 2BPP
		PTC12A = 13
		# PVRTC1 RGBA 4BPP
		PTC14A = 14
		# PVRTC2 RGBA 2BPP
		PTC22 = 15
		# PVRTC2 RGBA 4BPP
		PTC24 = 16
		# ATC RGB 4BPP
		ATC = 17
		# ATCE RGBA 8 BPP explicit alpha
		ATCE = 18
		# ATCI RGBA 8 BPP interpolated alpha
		ATCI = 19
		# ASTC 4x4 8.0 BPP
		ASTC4x4 = 20
		# ASTC 5x5 5.12 BPP
		ASTC5x5 = 21
		# ASTC 6x6 3.56 BPP
		ASTC6x6 = 22
		# ASTC 8x5 3.20 BPP
		ASTC8x5 = 23
		# ASTC 8x6 2.67 BPP
		ASTC8x6 = 24
		# ASTC 10x5 2.56 BPP
		ASTC10x5 = 25
		# Compressed formats above.
		Unknown = 26
		R1 = 27
		A8 = 28
		R8 = 29
		R8I = 30
		R8U = 31
		R8S = 32
		R16 = 33
		R16I = 34
		R16U = 35
		R16F = 36
		R16S = 37
		R32I = 38
		R32U = 39
		R32F = 40
		RG8 = 41
		RG8I = 42
		RG8U = 43
		RG8S = 44
		RG16 = 45
		RG16I = 46
		RG16U = 47
		RG16F = 48
		RG16S = 49
		RG32I = 50
		RG32U = 51
		RG32F = 52
		RGB8 = 53
		RGB8I = 54
		RGB8U = 55
		RGB8S = 56
		RGB9E5F = 57
		BGRA8 = 58
		RGBA8 = 59
		RGBA8I = 60
		RGBA8U = 61
		RGBA8S = 62
		RGBA16 = 63
		RGBA16I = 64
		RGBA16U = 65
		RGBA16F = 66
		RGBA16S = 67
		RGBA32I = 68
		RGBA32U = 69
		RGBA32F = 70
		R5G6B5 = 71
		RGBA4 = 72
		RGB5A1 = 73
		RGB10A2 = 74
		RG11B10F = 75
		# Depth formats below.
		UnknownDepth = 76
		D16 = 77
		D24 = 78
		D24S8 = 79
		D32 = 80
		D16F = 81
		D24F = 82
		D32F = 83
		D0S8 = 84
	
		Count = 85
	end # module TextureFormat
	
	module UniformType #enum: 5
		# Sampler.
		Sampler = 0
		# Reserved, do not use.
		End = 1
		# 4 floats vector.
		Vec4 = 2
		# 3x3 matrix.
		Mat3 = 3
		# 4x4 matrix.
		Mat4 = 4
	
		Count = 5
	end # module UniformType
	
	module BackbufferRatio #enum: 6
		# Equal to backbuffer.
		Equal = 0
		# One half size of backbuffer.
		Half = 1
		# One quarter size of backbuffer.
		Quarter = 2
		# One eighth size of backbuffer.
		Eighth = 3
		# One sixteenth size of backbuffer.
		Sixteenth = 4
		# Double size of backbuffer.
		Double = 5
	
		Count = 6
	end # module BackbufferRatio
	
	module OcclusionQueryResult #enum: 3
		# Query failed test.
		Invisible = 0
		# Query passed test.
		Visible = 1
		# Query result is not available yet.
		NoResult = 2
	
		Count = 3
	end # module OcclusionQueryResult
	
	module Topology #enum: 5
		# Triangle list.
		TriList = 0
		# Triangle strip.
		TriStrip = 1
		# Line list.
		LineList = 2
		# Line strip.
		LineStrip = 3
		# Point list.
		PointList = 4
	
		Count = 5
	end # module Topology
	
	module TopologyConvert #enum: 5
		# Flip winding order of triangle list.
		TriListFlipWinding = 0
		# Flip winding order of trinagle strip.
		TriStripFlipWinding = 1
		# Convert triangle list to line list.
		TriListToLineList = 2
		# Convert triangle strip to triangle list.
		TriStripToTriList = 3
		# Convert line strip to line list.
		LineStripToLineList = 4
	
		Count = 5
	end # module TopologyConvert
	
	module TopologySort #enum: 12
		DirectionFrontToBackMin = 0
		DirectionFrontToBackAvg = 1
		DirectionFrontToBackMax = 2
		DirectionBackToFrontMin = 3
		DirectionBackToFrontAvg = 4
		DirectionBackToFrontMax = 5
		DistanceFrontToBackMin = 6
		DistanceFrontToBackAvg = 7
		DistanceFrontToBackMax = 8
		DistanceBackToFrontMin = 9
		DistanceBackToFrontAvg = 10
		DistanceBackToFrontMax = 11
	
		Count = 12
	end # module TopologySort
	
	module ViewMode #enum: 4
		# Default sort order.
		Default = 0
		# Sort in the same order in which submit calls were called.
		Sequential = 1
		# Sort draw call depth in ascending order.
		DepthAscending = 2
		# Sort draw call depth in descending order.
		DepthDescending = 3
	
		Count = 4
	end # module ViewMode
	
	module RenderFrame #enum: 4
		# Renderer context is not created yet.
		NoContext = 0
		# Renderer context is created and rendering.
		Render = 1
		# Renderer context wait for main thread signal timed out without rendering.
		Timeout = 2
		# Renderer context is getting destroyed.
		Exiting = 3
	
		Count = 4
	end # module RenderFrame
	
end # module Bgfx

#
# Structs
#
class Bgfx_dynamic_index_buffer_handle_t < FFI::Struct; layout(:idx, :ushort); end

class Bgfx_dynamic_vertex_buffer_handle_t < FFI::Struct; layout(:idx, :ushort); end

class Bgfx_frame_buffer_handle_t < FFI::Struct; layout(:idx, :ushort); end

class Bgfx_index_buffer_handle_t < FFI::Struct; layout(:idx, :ushort); end

class Bgfx_indirect_buffer_handle_t < FFI::Struct; layout(:idx, :ushort); end

class Bgfx_occlusion_query_handle_t < FFI::Struct; layout(:idx, :ushort); end

class Bgfx_program_handle_t < FFI::Struct; layout(:idx, :ushort); end

class Bgfx_shader_handle_t < FFI::Struct; layout(:idx, :ushort); end

class Bgfx_texture_handle_t < FFI::Struct; layout(:idx, :ushort); end

class Bgfx_uniform_handle_t < FFI::Struct; layout(:idx, :ushort); end

class Bgfx_vertex_buffer_handle_t < FFI::Struct; layout(:idx, :ushort); end

class Bgfx_vertex_layout_handle_t < FFI::Struct; layout(:idx, :ushort); end

class Bgfx_caps_gpu_t < FFI::Struct
	layout(
		:vendorId, :uint16,		# Vendor PCI id. See `BGFX_PCI_ID_*`.
		:deviceId, :uint16		# Device id.
	)
end

class Bgfx_caps_limits_t < FFI::Struct
	layout(
		:maxDrawCalls, :uint32,		# Maximum number of draw calls.
		:maxBlits, :uint32,		# Maximum number of blit calls.
		:maxTextureSize, :uint32,		# Maximum texture size.
		:maxTextureLayers, :uint32,		# Maximum texture layers.
		:maxViews, :uint32,		# Maximum number of views.
		:maxFrameBuffers, :uint32,		# Maximum number of frame buffer handles.
		:maxFBAttachments, :uint32,		# Maximum number of frame buffer attachments.
		:maxPrograms, :uint32,		# Maximum number of program handles.
		:maxShaders, :uint32,		# Maximum number of shader handles.
		:maxTextures, :uint32,		# Maximum number of texture handles.
		:maxTextureSamplers, :uint32,		# Maximum number of texture samplers.
		:maxComputeBindings, :uint32,		# Maximum number of compute bindings.
		:maxVertexLayouts, :uint32,		# Maximum number of vertex format layouts.
		:maxVertexStreams, :uint32,		# Maximum number of vertex streams.
		:maxIndexBuffers, :uint32,		# Maximum number of index buffer handles.
		:maxVertexBuffers, :uint32,		# Maximum number of vertex buffer handles.
		:maxDynamicIndexBuffers, :uint32,		# Maximum number of dynamic index buffer handles.
		:maxDynamicVertexBuffers, :uint32,		# Maximum number of dynamic vertex buffer handles.
		:maxUniforms, :uint32,		# Maximum number of uniform handles.
		:maxOcclusionQueries, :uint32,		# Maximum number of occlusion query handles.
		:maxEncoders, :uint32,		# Maximum number of encoder threads.
		:transientVbSize, :uint32,		# Maximum transient vertex buffer size.
		:transientIbSize, :uint32		# Maximum transient index buffer size.
	)
end

class Bgfx_caps_t < FFI::Struct
	layout(
		:rendererType, :Bgfx_renderer_type_t,		# Renderer backend type. See: `bgfx::RendererType`

		#
		# Supported functionality.
		#   @attention See BGFX_CAPS_* flags at https://bkaradzic.github.io/bgfx/bgfx.html#available-caps
		#
		:supported, :uint64,
		:vendorId, :uint16,		# Selected GPU vendor PCI id.
		:deviceId, :uint16,		# Selected GPU device id.
		:homogeneousDepth, :bool,		# True when NDC depth is in [-1, 1] range, otherwise its [0, 1].
		:originBottomLeft, :bool,		# True when NDC origin is at bottom left.
		:numGPUs, :uint8,		# Number of enumerated GPUs.
		:gpu, [Bgfx_caps_gpu_t.by_value, 4],		# Enumerated GPUs.
		:limits, Bgfx_caps_limits_t.by_value,		# Renderer runtime limits.

		#
		# Supported texture format capabilities flags:
		#   - `BGFX_CAPS_FORMAT_TEXTURE_NONE` - Texture format is not supported.
		#   - `BGFX_CAPS_FORMAT_TEXTURE_2D` - Texture format is supported.
		#   - `BGFX_CAPS_FORMAT_TEXTURE_2D_SRGB` - Texture as sRGB format is supported.
		#   - `BGFX_CAPS_FORMAT_TEXTURE_2D_EMULATED` - Texture format is emulated.
		#   - `BGFX_CAPS_FORMAT_TEXTURE_3D` - Texture format is supported.
		#   - `BGFX_CAPS_FORMAT_TEXTURE_3D_SRGB` - Texture as sRGB format is supported.
		#   - `BGFX_CAPS_FORMAT_TEXTURE_3D_EMULATED` - Texture format is emulated.
		#   - `BGFX_CAPS_FORMAT_TEXTURE_CUBE` - Texture format is supported.
		#   - `BGFX_CAPS_FORMAT_TEXTURE_CUBE_SRGB` - Texture as sRGB format is supported.
		#   - `BGFX_CAPS_FORMAT_TEXTURE_CUBE_EMULATED` - Texture format is emulated.
		#   - `BGFX_CAPS_FORMAT_TEXTURE_VERTEX` - Texture format can be used from vertex shader.
		#   - `BGFX_CAPS_FORMAT_TEXTURE_IMAGE` - Texture format can be used as image from compute
		#     shader.
		#   - `BGFX_CAPS_FORMAT_TEXTURE_FRAMEBUFFER` - Texture format can be used as frame
		#     buffer.
		#   - `BGFX_CAPS_FORMAT_TEXTURE_FRAMEBUFFER_MSAA` - Texture format can be used as MSAA
		#     frame buffer.
		#   - `BGFX_CAPS_FORMAT_TEXTURE_MSAA` - Texture can be sampled as MSAA.
		#   - `BGFX_CAPS_FORMAT_TEXTURE_MIP_AUTOGEN` - Texture format supports auto-generated
		#     mips.
		#
		:formats, [:uint16, Bgfx::TextureFormat::Count]
	)
end

class Bgfx_internal_data_t < FFI::Struct
	layout(
		:caps, :pointer,		# Renderer capabilities.
		:context, :pointer		# GL context, or D3D device.
	)
end

class Bgfx_platform_data_t < FFI::Struct
	layout(
		:ndt, :pointer,		# Native display type (*nix specific).

		#
		# Native window handle. If `NULL` bgfx will create headless
		# context/device if renderer API supports it.
		#
		:nwh, :pointer,
		:context, :pointer,		# GL context, or D3D device. If `NULL`, bgfx will create context/device.

		#
		# GL back-buffer, or D3D render target view. If `NULL` bgfx will
		# create back-buffer color surface.
		#
		:backBuffer, :pointer,

		#
		# Backbuffer depth/stencil. If `NULL` bgfx will create back-buffer
		# depth/stencil surface.
		#
		:backBufferDS, :pointer
	)
end

class Bgfx_resolution_t < FFI::Struct
	layout(
		:format, :Bgfx_texture_format_t,		# Backbuffer format.
		:width, :uint32,		# Backbuffer width.
		:height, :uint32,		# Backbuffer height.
		:reset, :uint32,		# Reset parameters.
		:numBackBuffers, :uint8,		# Number of back buffers.
		:maxFrameLatency, :uint8		# Maximum frame latency.
	)
end

class Bgfx_init_limits_t < FFI::Struct
	layout(
		:maxEncoders, :uint16,		# Maximum number of encoder threads.
		:transientVbSize, :uint32,		# Maximum transient vertex buffer size.
		:transientIbSize, :uint32		# Maximum transient index buffer size.
	)
end

class Bgfx_init_t < FFI::Struct
	layout(

		#
		# Select rendering backend. When set to RendererType::Count
		# a default rendering backend will be selected appropriate to the platform.
		# See: `bgfx::RendererType`
		#
		:type, :Bgfx_renderer_type_t,

		#
		# Vendor PCI id. If set to `BGFX_PCI_ID_NONE` it will select the first
		# device.
		#   - `BGFX_PCI_ID_NONE` - Autoselect adapter.
		#   - `BGFX_PCI_ID_SOFTWARE_RASTERIZER` - Software rasterizer.
		#   - `BGFX_PCI_ID_AMD` - AMD adapter.
		#   - `BGFX_PCI_ID_INTEL` - Intel adapter.
		#   - `BGFX_PCI_ID_NVIDIA` - nVidia adapter.
		#
		:vendorId, :uint16,

		#
		# Device id. If set to 0 it will select first device, or device with
		# matching id.
		#
		:deviceId, :uint16,
		:debug_, :bool,		# Enable device for debuging.
		:profile, :bool,		# Enable device for profiling.
		:platformData, Bgfx_platform_data_t.by_value,		# Platform data.
		:resolution, Bgfx_resolution_t.by_value,		# Backbuffer resolution and reset parameters. See: `bgfx::Resolution`.
		:limits, Bgfx_init_limits_t.by_value,		# Configurable runtime limits parameters.

		#
		# Provide application specific callback interface.
		# See: `bgfx::CallbackI`
		#
		:callback, :pointer,

		#
		# Custom allocator. When a custom allocator is not
		# specified, bgfx uses the CRT allocator. Bgfx assumes
		# custom allocator is thread safe.
		#
		:allocator, :pointer
	)
end

class Bgfx_memory_t < FFI::Struct
	layout(
		:data, :pointer,		# Pointer to data.
		:size, :uint32		# Data size.
	)
end

class Bgfx_transient_index_buffer_t < FFI::Struct
	layout(
		:data, :pointer,		# Pointer to data.
		:size, :uint32,		# Data size.
		:startIndex, :uint32,		# First index.
		:handle, Bgfx_index_buffer_handle_t.by_value		# Index buffer handle.
	)
end

class Bgfx_transient_vertex_buffer_t < FFI::Struct
	layout(
		:data, :pointer,		# Pointer to data.
		:size, :uint32,		# Data size.
		:startVertex, :uint32,		# First vertex.
		:stride, :uint16,		# Vertex stride.
		:handle, Bgfx_vertex_buffer_handle_t.by_value,		# Vertex buffer handle.
		:layoutHandle, Bgfx_vertex_layout_handle_t.by_value		# Vertex layout handle.
	)
end

class Bgfx_instance_data_buffer_t < FFI::Struct
	layout(
		:data, :pointer,		# Pointer to data.
		:size, :uint32,		# Data size.
		:offset, :uint32,		# Offset in vertex buffer.
		:num, :uint32,		# Number of instances.
		:stride, :uint16,		# Vertex buffer stride.
		:handle, Bgfx_vertex_buffer_handle_t.by_value		# Vertex buffer object handle.
	)
end

class Bgfx_texture_info_t < FFI::Struct
	layout(
		:format, :Bgfx_texture_format_t,		# Texture format.
		:storageSize, :uint32,		# Total amount of bytes required to store texture.
		:width, :uint16,		# Texture width.
		:height, :uint16,		# Texture height.
		:depth, :uint16,		# Texture depth.
		:numLayers, :uint16,		# Number of layers in texture array.
		:numMips, :uint8,		# Number of MIP maps.
		:bitsPerPixel, :uint8,		# Format bits per pixel.
		:cubeMap, :bool		# Texture is cubemap.
	)
end

class Bgfx_uniform_info_t < FFI::Struct
	layout(
		:name, [:char, 256],		# Uniform name.
		:type, :Bgfx_uniform_type_t,		# Uniform type.
		:num, :uint16		# Number of elements in array.
	)
end

class Bgfx_attachment_t < FFI::Struct
	layout(
		:access, :Bgfx_access_t,		# Attachement access. See `Access::Enum`.
		:handle, Bgfx_texture_handle_t.by_value,		# Render target texture handle.
		:mip, :uint16,		# Mip level.
		:layer, :uint16,		# Cubemap side or depth layer/slice.
		:resolve, :uint8		# Resolve flags. See: `BGFX_RESOLVE_*`
	)
end

class Bgfx_transform_t < FFI::Struct
	layout(
		:data, :pointer,		# Pointer to first 4x4 matrix.
		:num, :uint16		# Number of matrices.
	)
end

class Bgfx_view_stats_t < FFI::Struct
	layout(
		:name, [:char, 256],		# View name.
		:view, :Bgfx_view_id_t,		# View id.
		:cpuTimeBegin, :int64,		# CPU (submit) begin time.
		:cpuTimeEnd, :int64,		# CPU (submit) end time.
		:gpuTimeBegin, :int64,		# GPU begin time.
		:gpuTimeEnd, :int64		# GPU end time.
	)
end

class Bgfx_encoder_stats_t < FFI::Struct
	layout(
		:cpuTimeBegin, :int64,		# Encoder thread CPU submit begin time.
		:cpuTimeEnd, :int64		# Encoder thread CPU submit end time.
	)
end

class Bgfx_stats_t < FFI::Struct
	layout(
		:cpuTimeFrame, :int64,		# CPU time between two `bgfx::frame` calls.
		:cpuTimeBegin, :int64,		# Render thread CPU submit begin time.
		:cpuTimeEnd, :int64,		# Render thread CPU submit end time.
		:cpuTimerFreq, :int64,		# CPU timer frequency. Timestamps-per-second
		:gpuTimeBegin, :int64,		# GPU frame begin time.
		:gpuTimeEnd, :int64,		# GPU frame end time.
		:gpuTimerFreq, :int64,		# GPU timer frequency.
		:waitRender, :int64,		# Time spent waiting for render backend thread to finish issuing draw commands to underlying graphics API.
		:waitSubmit, :int64,		# Time spent waiting for submit thread to advance to next frame.
		:numDraw, :uint32,		# Number of draw calls submitted.
		:numCompute, :uint32,		# Number of compute calls submitted.
		:numBlit, :uint32,		# Number of blit calls submitted.
		:maxGpuLatency, :uint32,		# GPU driver latency.
		:numDynamicIndexBuffers, :uint16,		# Number of used dynamic index buffers.
		:numDynamicVertexBuffers, :uint16,		# Number of used dynamic vertex buffers.
		:numFrameBuffers, :uint16,		# Number of used frame buffers.
		:numIndexBuffers, :uint16,		# Number of used index buffers.
		:numOcclusionQueries, :uint16,		# Number of used occlusion queries.
		:numPrograms, :uint16,		# Number of used programs.
		:numShaders, :uint16,		# Number of used shaders.
		:numTextures, :uint16,		# Number of used textures.
		:numUniforms, :uint16,		# Number of used uniforms.
		:numVertexBuffers, :uint16,		# Number of used vertex buffers.
		:numVertexLayouts, :uint16,		# Number of used vertex layouts.
		:textureMemoryUsed, :int64,		# Estimate of texture memory used.
		:rtMemoryUsed, :int64,		# Estimate of render target memory used.
		:transientVbUsed, :int32,		# Amount of transient vertex buffer used.
		:transientIbUsed, :int32,		# Amount of transient index buffer used.
		:numPrims, [:uint32, Bgfx::Topology::Count],		# Number of primitives rendered.
		:gpuMemoryMax, :int64,		# Maximum available GPU memory for application.
		:gpuMemoryUsed, :int64,		# Amount of GPU memory used by the application.
		:width, :uint16,		# Backbuffer width in pixels.
		:height, :uint16,		# Backbuffer height in pixels.
		:textWidth, :uint16,		# Debug text width in characters.
		:textHeight, :uint16,		# Debug text height in characters.
		:numViews, :uint16,		# Number of view stats.
		:viewStats, :pointer,		# Array of View stats.
		:numEncoders, :uint8,		# Number of encoders used during frame.
		:encoderStats, :pointer		# Array of encoder stats.
	)
end

class Bgfx_vertex_layout_t < FFI::Struct
	layout(
		:hash, :uint32,		# Hash.
		:stride, :uint16,		# Stride.
		:offset, [:uint16, Bgfx::Attrib::Count],		# Attribute offsets.
		:attributes, [:uint16, Bgfx::Attrib::Count]		# Used attributes.
	)
end

class Bgfx_encoder_t < FFI::Struct
	layout(
	)
end


#
# Functions
#
module Bgfx
    def self.import_symbols()
        	#
		# Init attachment.
		# Params:
		# _handle = Render target texture handle.
		# _access = Access. See `Access::Enum`.
		# _layer = Cubemap side or depth layer/slice.
		# _mip = Mip level.
		# _resolve = Resolve flags. See: `BGFX_RESOLVE_*`
		#
		attach_function :bgfx_attachment_init, :bgfx_attachment_init, [Bgfx_attachment_t.by_ref, Bgfx_texture_handle_t.by_value, :Bgfx_access_t, :uint16, :uint16, :uint8], :void
	
		#
		# Start VertexLayout.
		#
		attach_function :bgfx_vertex_layout_begin, :bgfx_vertex_layout_begin, [Bgfx_vertex_layout_t.by_ref, :Bgfx_renderer_type_t], :pointer
	
		#
		# Add attribute to VertexLayout.
		# Remarks: Must be called between begin/end.
		# Params:
		# _attrib = Attribute semantics. See: `bgfx::Attrib`
		# _num = Number of elements 1, 2, 3 or 4.
		# _type = Element type.
		# _normalized = When using fixed point AttribType (f.e. Uint8)
		# value will be normalized for vertex shader usage. When normalized
		# is set to true, AttribType::Uint8 value in range 0-255 will be
		# in range 0.0-1.0 in vertex shader.
		# _asInt = Packaging rule for vertexPack, vertexUnpack, and
		# vertexConvert for AttribType::Uint8 and AttribType::Int16.
		# Unpacking code must be implemented inside vertex shader.
		#
		attach_function :bgfx_vertex_layout_add, :bgfx_vertex_layout_add, [Bgfx_vertex_layout_t.by_ref, :Bgfx_attrib_t, :uint8, :Bgfx_attrib_type_t, :bool, :bool], :pointer
	
		#
		# Decode attribute.
		# Params:
		# _attrib = Attribute semantics. See: `bgfx::Attrib`
		# _num = Number of elements.
		# _type = Element type.
		# _normalized = Attribute is normalized.
		# _asInt = Attribute is packed as int.
		#
		attach_function :bgfx_vertex_layout_decode, :bgfx_vertex_layout_decode, [Bgfx_vertex_layout_t.by_ref, :Bgfx_attrib_t, :pointer, :pointer, :pointer, :pointer], :void
	
		#
		# Returns true if VertexLayout contains attribute.
		# Params:
		# _attrib = Attribute semantics. See: `bgfx::Attrib`
		#
		attach_function :bgfx_vertex_layout_has, :bgfx_vertex_layout_has, [Bgfx_vertex_layout_t.by_ref, :Bgfx_attrib_t], :bool
	
		#
		# Skip `_num` bytes in vertex stream.
		#
		attach_function :bgfx_vertex_layout_skip, :bgfx_vertex_layout_skip, [Bgfx_vertex_layout_t.by_ref, :uint8], :pointer
	
		#
		# End VertexLayout.
		#
		attach_function :bgfx_vertex_layout_end, :bgfx_vertex_layout_end, [Bgfx_vertex_layout_t.by_ref], :void
	
		#
		# Pack vertex attribute into vertex stream format.
		# Params:
		# _input = Value to be packed into vertex stream.
		# _inputNormalized = `true` if input value is already normalized.
		# _attr = Attribute to pack.
		# _layout = Vertex stream layout.
		# _data = Destination vertex stream where data will be packed.
		# _index = Vertex index that will be modified.
		#
		attach_function :bgfx_vertex_pack, :bgfx_vertex_pack, [:pointer, :bool, :Bgfx_attrib_t, :pointer, :pointer, :uint32], :void
	
		#
		# Unpack vertex attribute from vertex stream format.
		# Params:
		# _output = Result of unpacking.
		# _attr = Attribute to unpack.
		# _layout = Vertex stream layout.
		# _data = Source vertex stream from where data will be unpacked.
		# _index = Vertex index that will be unpacked.
		#
		attach_function :bgfx_vertex_unpack, :bgfx_vertex_unpack, [:pointer, :Bgfx_attrib_t, :pointer, :pointer, :uint32], :void
	
		#
		# Converts vertex stream data from one vertex stream format to another.
		# Params:
		# _dstLayout = Destination vertex stream layout.
		# _dstData = Destination vertex stream.
		# _srcLayout = Source vertex stream layout.
		# _srcData = Source vertex stream data.
		# _num = Number of vertices to convert from source to destination.
		#
		attach_function :bgfx_vertex_convert, :bgfx_vertex_convert, [:pointer, :pointer, :pointer, :pointer, :uint32], :void
	
		#
		# Weld vertices.
		# Params:
		# _output = Welded vertices remapping table. The size of buffer
		# must be the same as number of vertices.
		# _layout = Vertex stream layout.
		# _data = Vertex stream.
		# _num = Number of vertices in vertex stream.
		# _epsilon = Error tolerance for vertex position comparison.
		#
		attach_function :bgfx_weld_vertices, :bgfx_weld_vertices, [:pointer, :pointer, :pointer, :uint16, :float], :uint16
	
		#
		# Convert index buffer for use with different primitive topologies.
		# Params:
		# _conversion = Conversion type, see `TopologyConvert::Enum`.
		# _dst = Destination index buffer. If this argument is NULL
		# function will return number of indices after conversion.
		# _dstSize = Destination index buffer in bytes. It must be
		# large enough to contain output indices. If destination size is
		# insufficient index buffer will be truncated.
		# _indices = Source indices.
		# _numIndices = Number of input indices.
		# _index32 = Set to `true` if input indices are 32-bit.
		#
		attach_function :bgfx_topology_convert, :bgfx_topology_convert, [:Bgfx_topology_convert_t, :pointer, :uint32, :pointer, :uint32, :bool], :uint32
	
		#
		# Sort indices.
		# Params:
		# _sort = Sort order, see `TopologySort::Enum`.
		# _dst = Destination index buffer.
		# _dstSize = Destination index buffer in bytes. It must be
		# large enough to contain output indices. If destination size is
		# insufficient index buffer will be truncated.
		# _dir = Direction (vector must be normalized).
		# _pos = Position.
		# _vertices = Pointer to first vertex represented as
		# float x, y, z. Must contain at least number of vertices
		# referencende by index buffer.
		# _stride = Vertex stride.
		# _indices = Source indices.
		# _numIndices = Number of input indices.
		# _index32 = Set to `true` if input indices are 32-bit.
		#
		attach_function :bgfx_topology_sort_tri_list, :bgfx_topology_sort_tri_list, [:Bgfx_topology_sort_t, :pointer, :uint32, :pointer, :pointer, :pointer, :uint32, :pointer, :uint32, :bool], :void
	
		#
		# Returns supported backend API renderers.
		# Params:
		# _max = Maximum number of elements in _enum array.
		# _enum = Array where supported renderers will be written.
		#
		attach_function :bgfx_get_supported_renderers, :bgfx_get_supported_renderers, [:uint8, :pointer], :uint8
	
		#
		# Returns name of renderer.
		# Params:
		# _type = Renderer backend type. See: `bgfx::RendererType`
		#
		attach_function :bgfx_get_renderer_name, :bgfx_get_renderer_name, [:Bgfx_renderer_type_t], :string
	
		attach_function :bgfx_init_ctor, :bgfx_init_ctor, [:pointer], :void
	
		#
		# Initialize bgfx library.
		# Params:
		# _init = Initialization parameters. See: `bgfx::Init` for more info.
		#
		attach_function :bgfx_init, :bgfx_init, [:pointer], :bool
	
		#
		# Shutdown bgfx library.
		#
		attach_function :bgfx_shutdown, :bgfx_shutdown, [], :void
	
		#
		# Reset graphic settings and back-buffer size.
		# Attention: This call doesn't actually change window size, it just
		#   resizes back-buffer. Windowing code has to change window size.
		# Params:
		# _width = Back-buffer width.
		# _height = Back-buffer height.
		# _flags = See: `BGFX_RESET_*` for more info.
		#   - `BGFX_RESET_NONE` - No reset flags.
		#   - `BGFX_RESET_FULLSCREEN` - Not supported yet.
		#   - `BGFX_RESET_MSAA_X[2/4/8/16]` - Enable 2, 4, 8 or 16 x MSAA.
		#   - `BGFX_RESET_VSYNC` - Enable V-Sync.
		#   - `BGFX_RESET_MAXANISOTROPY` - Turn on/off max anisotropy.
		#   - `BGFX_RESET_CAPTURE` - Begin screen capture.
		#   - `BGFX_RESET_FLUSH_AFTER_RENDER` - Flush rendering after submitting to GPU.
		#   - `BGFX_RESET_FLIP_AFTER_RENDER` - This flag  specifies where flip
		#     occurs. Default behavior is that flip occurs before rendering new
		#     frame. This flag only has effect when `BGFX_CONFIG_MULTITHREADED=0`.
		#   - `BGFX_RESET_SRGB_BACKBUFFER` - Enable sRGB backbuffer.
		# _format = Texture format. See: `TextureFormat::Enum`.
		#
		attach_function :bgfx_reset, :bgfx_reset, [:uint32, :uint32, :uint32, :Bgfx_texture_format_t], :void
	
		#
		# Advance to next frame. When using multithreaded renderer, this call
		# just swaps internal buffers, kicks render thread, and returns. In
		# singlethreaded renderer this call does frame rendering.
		# Params:
		# _capture = Capture frame with graphics debugger.
		#
		attach_function :bgfx_frame, :bgfx_frame, [:bool], :uint32
	
		#
		# Returns current renderer backend API type.
		# Remarks:
		#   Library must be initialized.
		#
		attach_function :bgfx_get_renderer_type, :bgfx_get_renderer_type, [], :Bgfx_renderer_type_t
	
		#
		# Returns renderer capabilities.
		# Remarks:
		#   Library must be initialized.
		#
		attach_function :bgfx_get_caps, :bgfx_get_caps, [], :pointer
	
		#
		# Returns performance counters.
		# Attention: Pointer returned is valid until `bgfx::frame` is called.
		#
		attach_function :bgfx_get_stats, :bgfx_get_stats, [], :pointer
	
		#
		# Allocate buffer to pass to bgfx calls. Data will be freed inside bgfx.
		# Params:
		# _size = Size to allocate.
		#
		attach_function :bgfx_alloc, :bgfx_alloc, [:uint32], :pointer
	
		#
		# Allocate buffer and copy data into it. Data will be freed inside bgfx.
		# Params:
		# _data = Pointer to data to be copied.
		# _size = Size of data to be copied.
		#
		attach_function :bgfx_copy, :bgfx_copy, [:pointer, :uint32], :pointer
	
		#
		# Make reference to data to pass to bgfx. Unlike `bgfx::alloc`, this call
		# doesn't allocate memory for data. It just copies the _data pointer. You
		# can pass `ReleaseFn` function pointer to release this memory after it's
		# consumed, otherwise you must make sure _data is available for at least 2
		# `bgfx::frame` calls. `ReleaseFn` function must be able to be called
		# from any thread.
		# Attention: Data passed must be available for at least 2 `bgfx::frame` calls.
		# Params:
		# _data = Pointer to data.
		# _size = Size of data.
		#
		attach_function :bgfx_make_ref, :bgfx_make_ref, [:pointer, :uint32], :pointer
	
		#
		# Make reference to data to pass to bgfx. Unlike `bgfx::alloc`, this call
		# doesn't allocate memory for data. It just copies the _data pointer. You
		# can pass `ReleaseFn` function pointer to release this memory after it's
		# consumed, otherwise you must make sure _data is available for at least 2
		# `bgfx::frame` calls. `ReleaseFn` function must be able to be called
		# from any thread.
		# Attention: Data passed must be available for at least 2 `bgfx::frame` calls.
		# Params:
		# _data = Pointer to data.
		# _size = Size of data.
		# _releaseFn = Callback function to release memory after use.
		# _userData = User data to be passed to callback function.
		#
		attach_function :bgfx_make_ref_release, :bgfx_make_ref_release, [:pointer, :uint32, :pointer, :pointer], :pointer
	
		#
		# Set debug flags.
		# Params:
		# _debug = Available flags:
		#   - `BGFX_DEBUG_IFH` - Infinitely fast hardware. When this flag is set
		#     all rendering calls will be skipped. This is useful when profiling
		#     to quickly assess potential bottlenecks between CPU and GPU.
		#   - `BGFX_DEBUG_PROFILER` - Enable profiler.
		#   - `BGFX_DEBUG_STATS` - Display internal statistics.
		#   - `BGFX_DEBUG_TEXT` - Display debug text.
		#   - `BGFX_DEBUG_WIREFRAME` - Wireframe rendering. All rendering
		#     primitives will be rendered as lines.
		#
		attach_function :bgfx_set_debug, :bgfx_set_debug, [:uint32], :void
	
		#
		# Clear internal debug text buffer.
		# Params:
		# _attr = Background color.
		# _small = Default 8x16 or 8x8 font.
		#
		attach_function :bgfx_dbg_text_clear, :bgfx_dbg_text_clear, [:uint8, :bool], :void
	
		#
		# Print formatted data to internal debug text character-buffer (VGA-compatible text mode).
		# Params:
		# _x = Position x from the left corner of the window.
		# _y = Position y from the top corner of the window.
		# _attr = Color palette. Where top 4-bits represent index of background, and bottom
		# 4-bits represent foreground color from standard VGA text palette (ANSI escape codes).
		# _format = `printf` style format.
		#
		attach_function :bgfx_dbg_text_printf, :bgfx_dbg_text_printf, [:uint16, :uint16, :uint8, :string, :varargs], :void
	
		#
		# Print formatted data from variable argument list to internal debug text character-buffer (VGA-compatible text mode).
		# Params:
		# _x = Position x from the left corner of the window.
		# _y = Position y from the top corner of the window.
		# _attr = Color palette. Where top 4-bits represent index of background, and bottom
		# 4-bits represent foreground color from standard VGA text palette (ANSI escape codes).
		# _format = `printf` style format.
		# _argList = Variable arguments list for format string.
		#
		attach_function :bgfx_dbg_text_vprintf, :bgfx_dbg_text_vprintf, [:uint16, :uint16, :uint8, :string, :pointer], :void
	
		#
		# Draw image into internal debug text buffer.
		# Params:
		# _x = Position x from the left corner of the window.
		# _y = Position y from the top corner of the window.
		# _width = Image width.
		# _height = Image height.
		# _data = Raw image data (character/attribute raw encoding).
		# _pitch = Image pitch in bytes.
		#
		attach_function :bgfx_dbg_text_image, :bgfx_dbg_text_image, [:uint16, :uint16, :uint16, :uint16, :pointer, :uint16], :void
	
		#
		# Create static index buffer.
		# Params:
		# _mem = Index buffer data.
		# _flags = Buffer creation flags.
		#   - `BGFX_BUFFER_NONE` - No flags.
		#   - `BGFX_BUFFER_COMPUTE_READ` - Buffer will be read from by compute shader.
		#   - `BGFX_BUFFER_COMPUTE_WRITE` - Buffer will be written into by compute shader. When buffer
		#       is created with `BGFX_BUFFER_COMPUTE_WRITE` flag it cannot be updated from CPU.
		#   - `BGFX_BUFFER_COMPUTE_READ_WRITE` - Buffer will be used for read/write by compute shader.
		#   - `BGFX_BUFFER_ALLOW_RESIZE` - Buffer will resize on buffer update if a different amount of
		#       data is passed. If this flag is not specified, and more data is passed on update, the buffer
		#       will be trimmed to fit the existing buffer size. This flag has effect only on dynamic
		#       buffers.
		#   - `BGFX_BUFFER_INDEX32` - Buffer is using 32-bit indices. This flag has effect only on
		#       index buffers.
		#
		attach_function :bgfx_create_index_buffer, :bgfx_create_index_buffer, [:pointer, :uint16], Bgfx_index_buffer_handle_t.by_value
	
		#
		# Set static index buffer debug name.
		# Params:
		# _handle = Static index buffer handle.
		# _name = Static index buffer name.
		# _len = Static index buffer name length (if length is INT32_MAX, it's expected
		# that _name is zero terminated string.
		#
		attach_function :bgfx_set_index_buffer_name, :bgfx_set_index_buffer_name, [Bgfx_index_buffer_handle_t.by_value, :string, :int32], :void
	
		#
		# Destroy static index buffer.
		# Params:
		# _handle = Static index buffer handle.
		#
		attach_function :bgfx_destroy_index_buffer, :bgfx_destroy_index_buffer, [Bgfx_index_buffer_handle_t.by_value], :void
	
		#
		# Create vertex layout.
		# Params:
		# _layout = Vertex layout.
		#
		attach_function :bgfx_create_vertex_layout, :bgfx_create_vertex_layout, [:pointer], Bgfx_vertex_layout_handle_t.by_value
	
		#
		# Destroy vertex layout.
		# Params:
		# _layoutHandle = Vertex layout handle.
		#
		attach_function :bgfx_destroy_vertex_layout, :bgfx_destroy_vertex_layout, [Bgfx_vertex_layout_handle_t.by_value], :void
	
		#
		# Create static vertex buffer.
		# Params:
		# _mem = Vertex buffer data.
		# _layout = Vertex layout.
		# _flags = Buffer creation flags.
		#  - `BGFX_BUFFER_NONE` - No flags.
		#  - `BGFX_BUFFER_COMPUTE_READ` - Buffer will be read from by compute shader.
		#  - `BGFX_BUFFER_COMPUTE_WRITE` - Buffer will be written into by compute shader. When buffer
		#      is created with `BGFX_BUFFER_COMPUTE_WRITE` flag it cannot be updated from CPU.
		#  - `BGFX_BUFFER_COMPUTE_READ_WRITE` - Buffer will be used for read/write by compute shader.
		#  - `BGFX_BUFFER_ALLOW_RESIZE` - Buffer will resize on buffer update if a different amount of
		#      data is passed. If this flag is not specified, and more data is passed on update, the buffer
		#      will be trimmed to fit the existing buffer size. This flag has effect only on dynamic buffers.
		#  - `BGFX_BUFFER_INDEX32` - Buffer is using 32-bit indices. This flag has effect only on index buffers.
		#
		attach_function :bgfx_create_vertex_buffer, :bgfx_create_vertex_buffer, [:pointer, :pointer, :uint16], Bgfx_vertex_buffer_handle_t.by_value
	
		#
		# Set static vertex buffer debug name.
		# Params:
		# _handle = Static vertex buffer handle.
		# _name = Static vertex buffer name.
		# _len = Static vertex buffer name length (if length is INT32_MAX, it's expected
		# that _name is zero terminated string.
		#
		attach_function :bgfx_set_vertex_buffer_name, :bgfx_set_vertex_buffer_name, [Bgfx_vertex_buffer_handle_t.by_value, :string, :int32], :void
	
		#
		# Destroy static vertex buffer.
		# Params:
		# _handle = Static vertex buffer handle.
		#
		attach_function :bgfx_destroy_vertex_buffer, :bgfx_destroy_vertex_buffer, [Bgfx_vertex_buffer_handle_t.by_value], :void
	
		#
		# Create empty dynamic index buffer.
		# Params:
		# _num = Number of indices.
		# _flags = Buffer creation flags.
		#   - `BGFX_BUFFER_NONE` - No flags.
		#   - `BGFX_BUFFER_COMPUTE_READ` - Buffer will be read from by compute shader.
		#   - `BGFX_BUFFER_COMPUTE_WRITE` - Buffer will be written into by compute shader. When buffer
		#       is created with `BGFX_BUFFER_COMPUTE_WRITE` flag it cannot be updated from CPU.
		#   - `BGFX_BUFFER_COMPUTE_READ_WRITE` - Buffer will be used for read/write by compute shader.
		#   - `BGFX_BUFFER_ALLOW_RESIZE` - Buffer will resize on buffer update if a different amount of
		#       data is passed. If this flag is not specified, and more data is passed on update, the buffer
		#       will be trimmed to fit the existing buffer size. This flag has effect only on dynamic
		#       buffers.
		#   - `BGFX_BUFFER_INDEX32` - Buffer is using 32-bit indices. This flag has effect only on
		#       index buffers.
		#
		attach_function :bgfx_create_dynamic_index_buffer, :bgfx_create_dynamic_index_buffer, [:uint32, :uint16], Bgfx_dynamic_index_buffer_handle_t.by_value
	
		#
		# Create dynamic index buffer and initialized it.
		# Params:
		# _mem = Index buffer data.
		# _flags = Buffer creation flags.
		#   - `BGFX_BUFFER_NONE` - No flags.
		#   - `BGFX_BUFFER_COMPUTE_READ` - Buffer will be read from by compute shader.
		#   - `BGFX_BUFFER_COMPUTE_WRITE` - Buffer will be written into by compute shader. When buffer
		#       is created with `BGFX_BUFFER_COMPUTE_WRITE` flag it cannot be updated from CPU.
		#   - `BGFX_BUFFER_COMPUTE_READ_WRITE` - Buffer will be used for read/write by compute shader.
		#   - `BGFX_BUFFER_ALLOW_RESIZE` - Buffer will resize on buffer update if a different amount of
		#       data is passed. If this flag is not specified, and more data is passed on update, the buffer
		#       will be trimmed to fit the existing buffer size. This flag has effect only on dynamic
		#       buffers.
		#   - `BGFX_BUFFER_INDEX32` - Buffer is using 32-bit indices. This flag has effect only on
		#       index buffers.
		#
		attach_function :bgfx_create_dynamic_index_buffer_mem, :bgfx_create_dynamic_index_buffer_mem, [:pointer, :uint16], Bgfx_dynamic_index_buffer_handle_t.by_value
	
		#
		# Update dynamic index buffer.
		# Params:
		# _handle = Dynamic index buffer handle.
		# _startIndex = Start index.
		# _mem = Index buffer data.
		#
		attach_function :bgfx_update_dynamic_index_buffer, :bgfx_update_dynamic_index_buffer, [Bgfx_dynamic_index_buffer_handle_t.by_value, :uint32, :pointer], :void
	
		#
		# Destroy dynamic index buffer.
		# Params:
		# _handle = Dynamic index buffer handle.
		#
		attach_function :bgfx_destroy_dynamic_index_buffer, :bgfx_destroy_dynamic_index_buffer, [Bgfx_dynamic_index_buffer_handle_t.by_value], :void
	
		#
		# Create empty dynamic vertex buffer.
		# Params:
		# _num = Number of vertices.
		# _layout = Vertex layout.
		# _flags = Buffer creation flags.
		#   - `BGFX_BUFFER_NONE` - No flags.
		#   - `BGFX_BUFFER_COMPUTE_READ` - Buffer will be read from by compute shader.
		#   - `BGFX_BUFFER_COMPUTE_WRITE` - Buffer will be written into by compute shader. When buffer
		#       is created with `BGFX_BUFFER_COMPUTE_WRITE` flag it cannot be updated from CPU.
		#   - `BGFX_BUFFER_COMPUTE_READ_WRITE` - Buffer will be used for read/write by compute shader.
		#   - `BGFX_BUFFER_ALLOW_RESIZE` - Buffer will resize on buffer update if a different amount of
		#       data is passed. If this flag is not specified, and more data is passed on update, the buffer
		#       will be trimmed to fit the existing buffer size. This flag has effect only on dynamic
		#       buffers.
		#   - `BGFX_BUFFER_INDEX32` - Buffer is using 32-bit indices. This flag has effect only on
		#       index buffers.
		#
		attach_function :bgfx_create_dynamic_vertex_buffer, :bgfx_create_dynamic_vertex_buffer, [:uint32, :pointer, :uint16], Bgfx_dynamic_vertex_buffer_handle_t.by_value
	
		#
		# Create dynamic vertex buffer and initialize it.
		# Params:
		# _mem = Vertex buffer data.
		# _layout = Vertex layout.
		# _flags = Buffer creation flags.
		#   - `BGFX_BUFFER_NONE` - No flags.
		#   - `BGFX_BUFFER_COMPUTE_READ` - Buffer will be read from by compute shader.
		#   - `BGFX_BUFFER_COMPUTE_WRITE` - Buffer will be written into by compute shader. When buffer
		#       is created with `BGFX_BUFFER_COMPUTE_WRITE` flag it cannot be updated from CPU.
		#   - `BGFX_BUFFER_COMPUTE_READ_WRITE` - Buffer will be used for read/write by compute shader.
		#   - `BGFX_BUFFER_ALLOW_RESIZE` - Buffer will resize on buffer update if a different amount of
		#       data is passed. If this flag is not specified, and more data is passed on update, the buffer
		#       will be trimmed to fit the existing buffer size. This flag has effect only on dynamic
		#       buffers.
		#   - `BGFX_BUFFER_INDEX32` - Buffer is using 32-bit indices. This flag has effect only on
		#       index buffers.
		#
		attach_function :bgfx_create_dynamic_vertex_buffer_mem, :bgfx_create_dynamic_vertex_buffer_mem, [:pointer, :pointer, :uint16], Bgfx_dynamic_vertex_buffer_handle_t.by_value
	
		#
		# Update dynamic vertex buffer.
		# Params:
		# _handle = Dynamic vertex buffer handle.
		# _startVertex = Start vertex.
		# _mem = Vertex buffer data.
		#
		attach_function :bgfx_update_dynamic_vertex_buffer, :bgfx_update_dynamic_vertex_buffer, [Bgfx_dynamic_vertex_buffer_handle_t.by_value, :uint32, :pointer], :void
	
		#
		# Destroy dynamic vertex buffer.
		# Params:
		# _handle = Dynamic vertex buffer handle.
		#
		attach_function :bgfx_destroy_dynamic_vertex_buffer, :bgfx_destroy_dynamic_vertex_buffer, [Bgfx_dynamic_vertex_buffer_handle_t.by_value], :void
	
		#
		# Returns number of requested or maximum available indices.
		# Params:
		# _num = Number of required indices.
		#
		attach_function :bgfx_get_avail_transient_index_buffer, :bgfx_get_avail_transient_index_buffer, [:uint32], :uint32
	
		#
		# Returns number of requested or maximum available vertices.
		# Params:
		# _num = Number of required vertices.
		# _layout = Vertex layout.
		#
		attach_function :bgfx_get_avail_transient_vertex_buffer, :bgfx_get_avail_transient_vertex_buffer, [:uint32, :pointer], :uint32
	
		#
		# Returns number of requested or maximum available instance buffer slots.
		# Params:
		# _num = Number of required instances.
		# _stride = Stride per instance.
		#
		attach_function :bgfx_get_avail_instance_data_buffer, :bgfx_get_avail_instance_data_buffer, [:uint32, :uint16], :uint32
	
		#
		# Allocate transient index buffer.
		# Remarks:
		#   Only 16-bit index buffer is supported.
		# Params:
		# _tib = TransientIndexBuffer structure is filled and is valid
		# for the duration of frame, and it can be reused for multiple draw
		# calls.
		# _num = Number of indices to allocate.
		#
		attach_function :bgfx_alloc_transient_index_buffer, :bgfx_alloc_transient_index_buffer, [:pointer, :uint32], :void
	
		#
		# Allocate transient vertex buffer.
		# Params:
		# _tvb = TransientVertexBuffer structure is filled and is valid
		# for the duration of frame, and it can be reused for multiple draw
		# calls.
		# _num = Number of vertices to allocate.
		# _layout = Vertex layout.
		#
		attach_function :bgfx_alloc_transient_vertex_buffer, :bgfx_alloc_transient_vertex_buffer, [:pointer, :uint32, :pointer], :void
	
		#
		# Check for required space and allocate transient vertex and index
		# buffers. If both space requirements are satisfied function returns
		# true.
		# Remarks:
		#   Only 16-bit index buffer is supported.
		# Params:
		# _tvb = TransientVertexBuffer structure is filled and is valid
		# for the duration of frame, and it can be reused for multiple draw
		# calls.
		# _layout = Vertex layout.
		# _numVertices = Number of vertices to allocate.
		# _tib = TransientIndexBuffer structure is filled and is valid
		# for the duration of frame, and it can be reused for multiple draw
		# calls.
		# _numIndices = Number of indices to allocate.
		#
		attach_function :bgfx_alloc_transient_buffers, :bgfx_alloc_transient_buffers, [:pointer, :pointer, :uint32, :pointer, :uint32], :bool
	
		#
		# Allocate instance data buffer.
		# Params:
		# _idb = InstanceDataBuffer structure is filled and is valid
		# for duration of frame, and it can be reused for multiple draw
		# calls.
		# _num = Number of instances.
		# _stride = Instance stride. Must be multiple of 16.
		#
		attach_function :bgfx_alloc_instance_data_buffer, :bgfx_alloc_instance_data_buffer, [:pointer, :uint32, :uint16], :void
	
		#
		# Create draw indirect buffer.
		# Params:
		# _num = Number of indirect calls.
		#
		attach_function :bgfx_create_indirect_buffer, :bgfx_create_indirect_buffer, [:uint32], Bgfx_indirect_buffer_handle_t.by_value
	
		#
		# Destroy draw indirect buffer.
		# Params:
		# _handle = Indirect buffer handle.
		#
		attach_function :bgfx_destroy_indirect_buffer, :bgfx_destroy_indirect_buffer, [Bgfx_indirect_buffer_handle_t.by_value], :void
	
		#
		# Create shader from memory buffer.
		# Params:
		# _mem = Shader binary.
		#
		attach_function :bgfx_create_shader, :bgfx_create_shader, [:pointer], Bgfx_shader_handle_t.by_value
	
		#
		# Returns the number of uniforms and uniform handles used inside a shader.
		# Remarks:
		#   Only non-predefined uniforms are returned.
		# Params:
		# _handle = Shader handle.
		# _uniforms = UniformHandle array where data will be stored.
		# _max = Maximum capacity of array.
		#
		attach_function :bgfx_get_shader_uniforms, :bgfx_get_shader_uniforms, [Bgfx_shader_handle_t.by_value, :pointer, :uint16], :uint16
	
		#
		# Set shader debug name.
		# Params:
		# _handle = Shader handle.
		# _name = Shader name.
		# _len = Shader name length (if length is INT32_MAX, it's expected
		# that _name is zero terminated string).
		#
		attach_function :bgfx_set_shader_name, :bgfx_set_shader_name, [Bgfx_shader_handle_t.by_value, :string, :int32], :void
	
		#
		# Destroy shader.
		# Remarks: Once a shader program is created with _handle,
		#   it is safe to destroy that shader.
		# Params:
		# _handle = Shader handle.
		#
		attach_function :bgfx_destroy_shader, :bgfx_destroy_shader, [Bgfx_shader_handle_t.by_value], :void
	
		#
		# Create program with vertex and fragment shaders.
		# Params:
		# _vsh = Vertex shader.
		# _fsh = Fragment shader.
		# _destroyShaders = If true, shaders will be destroyed when program is destroyed.
		#
		attach_function :bgfx_create_program, :bgfx_create_program, [Bgfx_shader_handle_t.by_value, Bgfx_shader_handle_t.by_value, :bool], Bgfx_program_handle_t.by_value
	
		#
		# Create program with compute shader.
		# Params:
		# _csh = Compute shader.
		# _destroyShaders = If true, shaders will be destroyed when program is destroyed.
		#
		attach_function :bgfx_create_compute_program, :bgfx_create_compute_program, [Bgfx_shader_handle_t.by_value, :bool], Bgfx_program_handle_t.by_value
	
		#
		# Destroy program.
		# Params:
		# _handle = Program handle.
		#
		attach_function :bgfx_destroy_program, :bgfx_destroy_program, [Bgfx_program_handle_t.by_value], :void
	
		#
		# Validate texture parameters.
		# Params:
		# _depth = Depth dimension of volume texture.
		# _cubeMap = Indicates that texture contains cubemap.
		# _numLayers = Number of layers in texture array.
		# _format = Texture format. See: `TextureFormat::Enum`.
		# _flags = Texture flags. See `BGFX_TEXTURE_*`.
		#
		attach_function :bgfx_is_texture_valid, :bgfx_is_texture_valid, [:uint16, :bool, :uint16, :Bgfx_texture_format_t, :uint64], :bool
	
		#
		# Calculate amount of memory required for texture.
		# Params:
		# _info = Resulting texture info structure. See: `TextureInfo`.
		# _width = Width.
		# _height = Height.
		# _depth = Depth dimension of volume texture.
		# _cubeMap = Indicates that texture contains cubemap.
		# _hasMips = Indicates that texture contains full mip-map chain.
		# _numLayers = Number of layers in texture array.
		# _format = Texture format. See: `TextureFormat::Enum`.
		#
		attach_function :bgfx_calc_texture_size, :bgfx_calc_texture_size, [:pointer, :uint16, :uint16, :uint16, :bool, :bool, :uint16, :Bgfx_texture_format_t], :void
	
		#
		# Create texture from memory buffer.
		# Params:
		# _mem = DDS, KTX or PVR texture binary data.
		# _flags = Texture creation (see `BGFX_TEXTURE_*`.), and sampler (see `BGFX_SAMPLER_*`)
		# flags. Default texture sampling mode is linear, and wrap mode is repeat.
		# - `BGFX_SAMPLER_[U/V/W]_[MIRROR/CLAMP]` - Mirror or clamp to edge wrap
		#   mode.
		# - `BGFX_SAMPLER_[MIN/MAG/MIP]_[POINT/ANISOTROPIC]` - Point or anisotropic
		#   sampling.
		# _skip = Skip top level mips when parsing texture.
		# _info = When non-`NULL` is specified it returns parsed texture information.
		#
		attach_function :bgfx_create_texture, :bgfx_create_texture, [:pointer, :uint64, :uint8, :pointer], Bgfx_texture_handle_t.by_value
	
		#
		# Create 2D texture.
		# Params:
		# _width = Width.
		# _height = Height.
		# _hasMips = Indicates that texture contains full mip-map chain.
		# _numLayers = Number of layers in texture array. Must be 1 if caps
		# `BGFX_CAPS_TEXTURE_2D_ARRAY` flag is not set.
		# _format = Texture format. See: `TextureFormat::Enum`.
		# _flags = Texture creation (see `BGFX_TEXTURE_*`.), and sampler (see `BGFX_SAMPLER_*`)
		# flags. Default texture sampling mode is linear, and wrap mode is repeat.
		# - `BGFX_SAMPLER_[U/V/W]_[MIRROR/CLAMP]` - Mirror or clamp to edge wrap
		#   mode.
		# - `BGFX_SAMPLER_[MIN/MAG/MIP]_[POINT/ANISOTROPIC]` - Point or anisotropic
		#   sampling.
		# _mem = Texture data. If `_mem` is non-NULL, created texture will be immutable. If
		# `_mem` is NULL content of the texture is uninitialized. When `_numLayers` is more than
		# 1, expected memory layout is texture and all mips together for each array element.
		#
		attach_function :bgfx_create_texture_2d, :bgfx_create_texture_2d, [:uint16, :uint16, :bool, :uint16, :Bgfx_texture_format_t, :uint64, :pointer], Bgfx_texture_handle_t.by_value
	
		#
		# Create texture with size based on backbuffer ratio. Texture will maintain ratio
		# if back buffer resolution changes.
		# Params:
		# _ratio = Texture size in respect to back-buffer size. See: `BackbufferRatio::Enum`.
		# _hasMips = Indicates that texture contains full mip-map chain.
		# _numLayers = Number of layers in texture array. Must be 1 if caps
		# `BGFX_CAPS_TEXTURE_2D_ARRAY` flag is not set.
		# _format = Texture format. See: `TextureFormat::Enum`.
		# _flags = Texture creation (see `BGFX_TEXTURE_*`.), and sampler (see `BGFX_SAMPLER_*`)
		# flags. Default texture sampling mode is linear, and wrap mode is repeat.
		# - `BGFX_SAMPLER_[U/V/W]_[MIRROR/CLAMP]` - Mirror or clamp to edge wrap
		#   mode.
		# - `BGFX_SAMPLER_[MIN/MAG/MIP]_[POINT/ANISOTROPIC]` - Point or anisotropic
		#   sampling.
		#
		attach_function :bgfx_create_texture_2d_scaled, :bgfx_create_texture_2d_scaled, [:Bgfx_backbuffer_ratio_t, :bool, :uint16, :Bgfx_texture_format_t, :uint64], Bgfx_texture_handle_t.by_value
	
		#
		# Create 3D texture.
		# Params:
		# _width = Width.
		# _height = Height.
		# _depth = Depth.
		# _hasMips = Indicates that texture contains full mip-map chain.
		# _format = Texture format. See: `TextureFormat::Enum`.
		# _flags = Texture creation (see `BGFX_TEXTURE_*`.), and sampler (see `BGFX_SAMPLER_*`)
		# flags. Default texture sampling mode is linear, and wrap mode is repeat.
		# - `BGFX_SAMPLER_[U/V/W]_[MIRROR/CLAMP]` - Mirror or clamp to edge wrap
		#   mode.
		# - `BGFX_SAMPLER_[MIN/MAG/MIP]_[POINT/ANISOTROPIC]` - Point or anisotropic
		#   sampling.
		# _mem = Texture data. If `_mem` is non-NULL, created texture will be immutable. If
		# `_mem` is NULL content of the texture is uninitialized. When `_numLayers` is more than
		# 1, expected memory layout is texture and all mips together for each array element.
		#
		attach_function :bgfx_create_texture_3d, :bgfx_create_texture_3d, [:uint16, :uint16, :uint16, :bool, :Bgfx_texture_format_t, :uint64, :pointer], Bgfx_texture_handle_t.by_value
	
		#
		# Create Cube texture.
		# Params:
		# _size = Cube side size.
		# _hasMips = Indicates that texture contains full mip-map chain.
		# _numLayers = Number of layers in texture array. Must be 1 if caps
		# `BGFX_CAPS_TEXTURE_2D_ARRAY` flag is not set.
		# _format = Texture format. See: `TextureFormat::Enum`.
		# _flags = Texture creation (see `BGFX_TEXTURE_*`.), and sampler (see `BGFX_SAMPLER_*`)
		# flags. Default texture sampling mode is linear, and wrap mode is repeat.
		# - `BGFX_SAMPLER_[U/V/W]_[MIRROR/CLAMP]` - Mirror or clamp to edge wrap
		#   mode.
		# - `BGFX_SAMPLER_[MIN/MAG/MIP]_[POINT/ANISOTROPIC]` - Point or anisotropic
		#   sampling.
		# _mem = Texture data. If `_mem` is non-NULL, created texture will be immutable. If
		# `_mem` is NULL content of the texture is uninitialized. When `_numLayers` is more than
		# 1, expected memory layout is texture and all mips together for each array element.
		#
		attach_function :bgfx_create_texture_cube, :bgfx_create_texture_cube, [:uint16, :bool, :uint16, :Bgfx_texture_format_t, :uint64, :pointer], Bgfx_texture_handle_t.by_value
	
		#
		# Update 2D texture.
		# Attention: It's valid to update only mutable texture. See `bgfx::createTexture2D` for more info.
		# Params:
		# _handle = Texture handle.
		# _layer = Layer in texture array.
		# _mip = Mip level.
		# _x = X offset in texture.
		# _y = Y offset in texture.
		# _width = Width of texture block.
		# _height = Height of texture block.
		# _mem = Texture update data.
		# _pitch = Pitch of input image (bytes). When _pitch is set to
		# UINT16_MAX, it will be calculated internally based on _width.
		#
		attach_function :bgfx_update_texture_2d, :bgfx_update_texture_2d, [Bgfx_texture_handle_t.by_value, :uint16, :uint8, :uint16, :uint16, :uint16, :uint16, :pointer, :uint16], :void
	
		#
		# Update 3D texture.
		# Attention: It's valid to update only mutable texture. See `bgfx::createTexture3D` for more info.
		# Params:
		# _handle = Texture handle.
		# _mip = Mip level.
		# _x = X offset in texture.
		# _y = Y offset in texture.
		# _z = Z offset in texture.
		# _width = Width of texture block.
		# _height = Height of texture block.
		# _depth = Depth of texture block.
		# _mem = Texture update data.
		#
		attach_function :bgfx_update_texture_3d, :bgfx_update_texture_3d, [Bgfx_texture_handle_t.by_value, :uint8, :uint16, :uint16, :uint16, :uint16, :uint16, :uint16, :pointer], :void
	
		#
		# Update Cube texture.
		# Attention: It's valid to update only mutable texture. See `bgfx::createTextureCube` for more info.
		# Params:
		# _handle = Texture handle.
		# _layer = Layer in texture array.
		# _side = Cubemap side `BGFX_CUBE_MAP_<POSITIVE or NEGATIVE>_<X, Y or Z>`,
		#   where 0 is +X, 1 is -X, 2 is +Y, 3 is -Y, 4 is +Z, and 5 is -Z.
		#                  +----------+
		#                  |-z       2|
		#                  | ^  +y    |
		#                  | |        |    Unfolded cube:
		#                  | +---->+x |
		#       +----------+----------+----------+----------+
		#       |+y       1|+y       4|+y       0|+y       5|
		#       | ^  -x    | ^  +z    | ^  +x    | ^  -z    |
		#       | |        | |        | |        | |        |
		#       | +---->+z | +---->+x | +---->-z | +---->-x |
		#       +----------+----------+----------+----------+
		#                  |+z       3|
		#                  | ^  -y    |
		#                  | |        |
		#                  | +---->+x |
		#                  +----------+
		# _mip = Mip level.
		# _x = X offset in texture.
		# _y = Y offset in texture.
		# _width = Width of texture block.
		# _height = Height of texture block.
		# _mem = Texture update data.
		# _pitch = Pitch of input image (bytes). When _pitch is set to
		# UINT16_MAX, it will be calculated internally based on _width.
		#
		attach_function :bgfx_update_texture_cube, :bgfx_update_texture_cube, [Bgfx_texture_handle_t.by_value, :uint16, :uint8, :uint8, :uint16, :uint16, :uint16, :uint16, :pointer, :uint16], :void
	
		#
		# Read back texture content.
		# Attention: Texture must be created with `BGFX_TEXTURE_READ_BACK` flag.
		# Attention: Availability depends on: `BGFX_CAPS_TEXTURE_READ_BACK`.
		# Params:
		# _handle = Texture handle.
		# _data = Destination buffer.
		# _mip = Mip level.
		#
		attach_function :bgfx_read_texture, :bgfx_read_texture, [Bgfx_texture_handle_t.by_value, :pointer, :uint8], :uint32
	
		#
		# Set texture debug name.
		# Params:
		# _handle = Texture handle.
		# _name = Texture name.
		# _len = Texture name length (if length is INT32_MAX, it's expected
		# that _name is zero terminated string.
		#
		attach_function :bgfx_set_texture_name, :bgfx_set_texture_name, [Bgfx_texture_handle_t.by_value, :string, :int32], :void
	
		#
		# Returns texture direct access pointer.
		# Attention: Availability depends on: `BGFX_CAPS_TEXTURE_DIRECT_ACCESS`. This feature
		#   is available on GPUs that have unified memory architecture (UMA) support.
		# Params:
		# _handle = Texture handle.
		#
		attach_function :bgfx_get_direct_access_ptr, :bgfx_get_direct_access_ptr, [Bgfx_texture_handle_t.by_value], :pointer
	
		#
		# Destroy texture.
		# Params:
		# _handle = Texture handle.
		#
		attach_function :bgfx_destroy_texture, :bgfx_destroy_texture, [Bgfx_texture_handle_t.by_value], :void
	
		#
		# Create frame buffer (simple).
		# Params:
		# _width = Texture width.
		# _height = Texture height.
		# _format = Texture format. See: `TextureFormat::Enum`.
		# _textureFlags = Texture creation (see `BGFX_TEXTURE_*`.), and sampler (see `BGFX_SAMPLER_*`)
		# flags. Default texture sampling mode is linear, and wrap mode is repeat.
		# - `BGFX_SAMPLER_[U/V/W]_[MIRROR/CLAMP]` - Mirror or clamp to edge wrap
		#   mode.
		# - `BGFX_SAMPLER_[MIN/MAG/MIP]_[POINT/ANISOTROPIC]` - Point or anisotropic
		#   sampling.
		#
		attach_function :bgfx_create_frame_buffer, :bgfx_create_frame_buffer, [:uint16, :uint16, :Bgfx_texture_format_t, :uint64], Bgfx_frame_buffer_handle_t.by_value
	
		#
		# Create frame buffer with size based on backbuffer ratio. Frame buffer will maintain ratio
		# if back buffer resolution changes.
		# Params:
		# _ratio = Frame buffer size in respect to back-buffer size. See:
		# `BackbufferRatio::Enum`.
		# _format = Texture format. See: `TextureFormat::Enum`.
		# _textureFlags = Texture creation (see `BGFX_TEXTURE_*`.), and sampler (see `BGFX_SAMPLER_*`)
		# flags. Default texture sampling mode is linear, and wrap mode is repeat.
		# - `BGFX_SAMPLER_[U/V/W]_[MIRROR/CLAMP]` - Mirror or clamp to edge wrap
		#   mode.
		# - `BGFX_SAMPLER_[MIN/MAG/MIP]_[POINT/ANISOTROPIC]` - Point or anisotropic
		#   sampling.
		#
		attach_function :bgfx_create_frame_buffer_scaled, :bgfx_create_frame_buffer_scaled, [:Bgfx_backbuffer_ratio_t, :Bgfx_texture_format_t, :uint64], Bgfx_frame_buffer_handle_t.by_value
	
		#
		# Create MRT frame buffer from texture handles (simple).
		# Params:
		# _num = Number of texture handles.
		# _handles = Texture attachments.
		# _destroyTexture = If true, textures will be destroyed when
		# frame buffer is destroyed.
		#
		attach_function :bgfx_create_frame_buffer_from_handles, :bgfx_create_frame_buffer_from_handles, [:uint8, :pointer, :bool], Bgfx_frame_buffer_handle_t.by_value
	
		#
		# Create MRT frame buffer from texture handles with specific layer and
		# mip level.
		# Params:
		# _num = Number of attachements.
		# _attachment = Attachment texture info. See: `bgfx::Attachment`.
		# _destroyTexture = If true, textures will be destroyed when
		# frame buffer is destroyed.
		#
		attach_function :bgfx_create_frame_buffer_from_attachment, :bgfx_create_frame_buffer_from_attachment, [:uint8, :pointer, :bool], Bgfx_frame_buffer_handle_t.by_value
	
		#
		# Create frame buffer for multiple window rendering.
		# Remarks:
		#   Frame buffer cannot be used for sampling.
		# Attention: Availability depends on: `BGFX_CAPS_SWAP_CHAIN`.
		# Params:
		# _nwh = OS' target native window handle.
		# _width = Window back buffer width.
		# _height = Window back buffer height.
		# _format = Window back buffer color format.
		# _depthFormat = Window back buffer depth format.
		#
		attach_function :bgfx_create_frame_buffer_from_nwh, :bgfx_create_frame_buffer_from_nwh, [:pointer, :uint16, :uint16, :Bgfx_texture_format_t, :Bgfx_texture_format_t], Bgfx_frame_buffer_handle_t.by_value
	
		#
		# Set frame buffer debug name.
		# Params:
		# _handle = Frame buffer handle.
		# _name = Frame buffer name.
		# _len = Frame buffer name length (if length is INT32_MAX, it's expected
		# that _name is zero terminated string.
		#
		attach_function :bgfx_set_frame_buffer_name, :bgfx_set_frame_buffer_name, [Bgfx_frame_buffer_handle_t.by_value, :string, :int32], :void
	
		#
		# Obtain texture handle of frame buffer attachment.
		# Params:
		# _handle = Frame buffer handle.
		#
		attach_function :bgfx_get_texture, :bgfx_get_texture, [Bgfx_frame_buffer_handle_t.by_value, :uint8], Bgfx_texture_handle_t.by_value
	
		#
		# Destroy frame buffer.
		# Params:
		# _handle = Frame buffer handle.
		#
		attach_function :bgfx_destroy_frame_buffer, :bgfx_destroy_frame_buffer, [Bgfx_frame_buffer_handle_t.by_value], :void
	
		#
		# Create shader uniform parameter.
		# Remarks:
		#   1. Uniform names are unique. It's valid to call `bgfx::createUniform`
		#      multiple times with the same uniform name. The library will always
		#      return the same handle, but the handle reference count will be
		#      incremented. This means that the same number of `bgfx::destroyUniform`
		#      must be called to properly destroy the uniform.
		#   2. Predefined uniforms (declared in `bgfx_shader.sh`):
		#      - `u_viewRect vec4(x, y, width, height)` - view rectangle for current
		#        view, in pixels.
		#      - `u_viewTexel vec4(1.0/width, 1.0/height, undef, undef)` - inverse
		#        width and height
		#      - `u_view mat4` - view matrix
		#      - `u_invView mat4` - inverted view matrix
		#      - `u_proj mat4` - projection matrix
		#      - `u_invProj mat4` - inverted projection matrix
		#      - `u_viewProj mat4` - concatenated view projection matrix
		#      - `u_invViewProj mat4` - concatenated inverted view projection matrix
		#      - `u_model mat4[BGFX_CONFIG_MAX_BONES]` - array of model matrices.
		#      - `u_modelView mat4` - concatenated model view matrix, only first
		#        model matrix from array is used.
		#      - `u_modelViewProj mat4` - concatenated model view projection matrix.
		#      - `u_alphaRef float` - alpha reference value for alpha test.
		# Params:
		# _name = Uniform name in shader.
		# _type = Type of uniform (See: `bgfx::UniformType`).
		# _num = Number of elements in array.
		#
		attach_function :bgfx_create_uniform, :bgfx_create_uniform, [:string, :Bgfx_uniform_type_t, :uint16], Bgfx_uniform_handle_t.by_value
	
		#
		# Retrieve uniform info.
		# Params:
		# _handle = Handle to uniform object.
		# _info = Uniform info.
		#
		attach_function :bgfx_get_uniform_info, :bgfx_get_uniform_info, [Bgfx_uniform_handle_t.by_value, :pointer], :void
	
		#
		# Destroy shader uniform parameter.
		# Params:
		# _handle = Handle to uniform object.
		#
		attach_function :bgfx_destroy_uniform, :bgfx_destroy_uniform, [Bgfx_uniform_handle_t.by_value], :void
	
		#
		# Create occlusion query.
		#
		attach_function :bgfx_create_occlusion_query, :bgfx_create_occlusion_query, [], Bgfx_occlusion_query_handle_t.by_value
	
		#
		# Retrieve occlusion query result from previous frame.
		# Params:
		# _handle = Handle to occlusion query object.
		# _result = Number of pixels that passed test. This argument
		# can be `NULL` if result of occlusion query is not needed.
		#
		attach_function :bgfx_get_result, :bgfx_get_result, [Bgfx_occlusion_query_handle_t.by_value, :pointer], :Bgfx_occlusion_query_result_t
	
		#
		# Destroy occlusion query.
		# Params:
		# _handle = Handle to occlusion query object.
		#
		attach_function :bgfx_destroy_occlusion_query, :bgfx_destroy_occlusion_query, [Bgfx_occlusion_query_handle_t.by_value], :void
	
		#
		# Set palette color value.
		# Params:
		# _index = Index into palette.
		# _rgba = RGBA floating point values.
		#
		attach_function :bgfx_set_palette_color, :bgfx_set_palette_color, [:uint8, :pointer], :void
	
		#
		# Set palette color value.
		# Params:
		# _index = Index into palette.
		# _rgba = Packed 32-bit RGBA value.
		#
		attach_function :bgfx_set_palette_color_rgba8, :bgfx_set_palette_color_rgba8, [:uint8, :uint32], :void
	
		#
		# Set view name.
		# Remarks:
		#   This is debug only feature.
		#   In graphics debugger view name will appear as:
		#       "nnnc <view name>"
		#        ^  ^ ^
		#        |  +--- compute (C)
		#        +------ view id
		# Params:
		# _id = View id.
		# _name = View name.
		#
		attach_function :bgfx_set_view_name, :bgfx_set_view_name, [:Bgfx_view_id_t, :string], :void
	
		#
		# Set view rectangle. Draw primitive outside view will be clipped.
		# Params:
		# _id = View id.
		# _x = Position x from the left corner of the window.
		# _y = Position y from the top corner of the window.
		# _width = Width of view port region.
		# _height = Height of view port region.
		#
		attach_function :bgfx_set_view_rect, :bgfx_set_view_rect, [:Bgfx_view_id_t, :uint16, :uint16, :uint16, :uint16], :void
	
		#
		# Set view rectangle. Draw primitive outside view will be clipped.
		# Params:
		# _id = View id.
		# _x = Position x from the left corner of the window.
		# _y = Position y from the top corner of the window.
		# _ratio = Width and height will be set in respect to back-buffer size.
		# See: `BackbufferRatio::Enum`.
		#
		attach_function :bgfx_set_view_rect_ratio, :bgfx_set_view_rect_ratio, [:Bgfx_view_id_t, :uint16, :uint16, :Bgfx_backbuffer_ratio_t], :void
	
		#
		# Set view scissor. Draw primitive outside view will be clipped. When
		# _x, _y, _width and _height are set to 0, scissor will be disabled.
		# Params:
		# _id = View id.
		# _x = Position x from the left corner of the window.
		# _y = Position y from the top corner of the window.
		# _width = Width of view scissor region.
		# _height = Height of view scissor region.
		#
		attach_function :bgfx_set_view_scissor, :bgfx_set_view_scissor, [:Bgfx_view_id_t, :uint16, :uint16, :uint16, :uint16], :void
	
		#
		# Set view clear flags.
		# Params:
		# _id = View id.
		# _flags = Clear flags. Use `BGFX_CLEAR_NONE` to remove any clear
		# operation. See: `BGFX_CLEAR_*`.
		# _rgba = Color clear value.
		# _depth = Depth clear value.
		# _stencil = Stencil clear value.
		#
		attach_function :bgfx_set_view_clear, :bgfx_set_view_clear, [:Bgfx_view_id_t, :uint16, :uint32, :float, :uint8], :void
	
		#
		# Set view clear flags with different clear color for each
		# frame buffer texture. Must use `bgfx::setPaletteColor` to setup clear color
		# palette.
		# Params:
		# _id = View id.
		# _flags = Clear flags. Use `BGFX_CLEAR_NONE` to remove any clear
		# operation. See: `BGFX_CLEAR_*`.
		# _depth = Depth clear value.
		# _stencil = Stencil clear value.
		# _c0 = Palette index for frame buffer attachment 0.
		# _c1 = Palette index for frame buffer attachment 1.
		# _c2 = Palette index for frame buffer attachment 2.
		# _c3 = Palette index for frame buffer attachment 3.
		# _c4 = Palette index for frame buffer attachment 4.
		# _c5 = Palette index for frame buffer attachment 5.
		# _c6 = Palette index for frame buffer attachment 6.
		# _c7 = Palette index for frame buffer attachment 7.
		#
		attach_function :bgfx_set_view_clear_mrt, :bgfx_set_view_clear_mrt, [:Bgfx_view_id_t, :uint16, :float, :uint8, :uint8, :uint8, :uint8, :uint8, :uint8, :uint8, :uint8, :uint8], :void
	
		#
		# Set view sorting mode.
		# Remarks:
		#   View mode must be set prior calling `bgfx::submit` for the view.
		# Params:
		# _id = View id.
		# _mode = View sort mode. See `ViewMode::Enum`.
		#
		attach_function :bgfx_set_view_mode, :bgfx_set_view_mode, [:Bgfx_view_id_t, :Bgfx_view_mode_t], :void
	
		#
		# Set view frame buffer.
		# Remarks:
		#   Not persistent after `bgfx::reset` call.
		# Params:
		# _id = View id.
		# _handle = Frame buffer handle. Passing `BGFX_INVALID_HANDLE` as
		# frame buffer handle will draw primitives from this view into
		# default back buffer.
		#
		attach_function :bgfx_set_view_frame_buffer, :bgfx_set_view_frame_buffer, [:Bgfx_view_id_t, Bgfx_frame_buffer_handle_t.by_value], :void
	
		#
		# Set view view and projection matrices, all draw primitives in this
		# view will use these matrices.
		# Params:
		# _id = View id.
		# _view = View matrix.
		# _proj = Projection matrix.
		#
		attach_function :bgfx_set_view_transform, :bgfx_set_view_transform, [:Bgfx_view_id_t, :pointer, :pointer], :void
	
		#
		# Post submit view reordering.
		# Params:
		# _id = First view id.
		# _num = Number of views to remap.
		# _order = View remap id table. Passing `NULL` will reset view ids
		# to default state.
		#
		attach_function :bgfx_set_view_order, :bgfx_set_view_order, [:Bgfx_view_id_t, :uint16, :pointer], :void
	
		#
		# Reset all view settings to default.
		#
		attach_function :bgfx_reset_view, :bgfx_reset_view, [:Bgfx_view_id_t], :void
	
		#
		# Begin submitting draw calls from thread.
		# Params:
		# _forThread = Explicitly request an encoder for a worker thread.
		#
		attach_function :bgfx_encoder_begin, :bgfx_encoder_begin, [:bool], :pointer
	
		#
		# End submitting draw calls from thread.
		# Params:
		# _encoder = Encoder.
		#
		attach_function :bgfx_encoder_end, :bgfx_encoder_end, [:pointer], :void
	
		#
		# Sets a debug marker. This allows you to group graphics calls together for easy browsing in
		# graphics debugging tools.
		# Params:
		# _marker = Marker string.
		#
		attach_function :bgfx_encoder_set_marker, :bgfx_encoder_set_marker, [Bgfx_encoder_t.by_ref, :string], :void
	
		#
		# Set render states for draw primitive.
		# Remarks:
		#   1. To setup more complex states use:
		#      `BGFX_STATE_ALPHA_REF(_ref)`,
		#      `BGFX_STATE_POINT_SIZE(_size)`,
		#      `BGFX_STATE_BLEND_FUNC(_src, _dst)`,
		#      `BGFX_STATE_BLEND_FUNC_SEPARATE(_srcRGB, _dstRGB, _srcA, _dstA)`,
		#      `BGFX_STATE_BLEND_EQUATION(_equation)`,
		#      `BGFX_STATE_BLEND_EQUATION_SEPARATE(_equationRGB, _equationA)`
		#   2. `BGFX_STATE_BLEND_EQUATION_ADD` is set when no other blend
		#      equation is specified.
		# Params:
		# _state = State flags. Default state for primitive type is
		#   triangles. See: `BGFX_STATE_DEFAULT`.
		#   - `BGFX_STATE_DEPTH_TEST_*` - Depth test function.
		#   - `BGFX_STATE_BLEND_*` - See remark 1 about BGFX_STATE_BLEND_FUNC.
		#   - `BGFX_STATE_BLEND_EQUATION_*` - See remark 2.
		#   - `BGFX_STATE_CULL_*` - Backface culling mode.
		#   - `BGFX_STATE_WRITE_*` - Enable R, G, B, A or Z write.
		#   - `BGFX_STATE_MSAA` - Enable hardware multisample antialiasing.
		#   - `BGFX_STATE_PT_[TRISTRIP/LINES/POINTS]` - Primitive type.
		# _rgba = Sets blend factor used by `BGFX_STATE_BLEND_FACTOR` and
		#   `BGFX_STATE_BLEND_INV_FACTOR` blend modes.
		#
		attach_function :bgfx_encoder_set_state, :bgfx_encoder_set_state, [Bgfx_encoder_t.by_ref, :uint64, :uint32], :void
	
		#
		# Set condition for rendering.
		# Params:
		# _handle = Occlusion query handle.
		# _visible = Render if occlusion query is visible.
		#
		attach_function :bgfx_encoder_set_condition, :bgfx_encoder_set_condition, [Bgfx_encoder_t.by_ref, Bgfx_occlusion_query_handle_t.by_value, :bool], :void
	
		#
		# Set stencil test state.
		# Params:
		# _fstencil = Front stencil state.
		# _bstencil = Back stencil state. If back is set to `BGFX_STENCIL_NONE`
		# _fstencil is applied to both front and back facing primitives.
		#
		attach_function :bgfx_encoder_set_stencil, :bgfx_encoder_set_stencil, [Bgfx_encoder_t.by_ref, :uint32, :uint32], :void
	
		#
		# Set scissor for draw primitive.
		# Remarks:
		#   To scissor for all primitives in view see `bgfx::setViewScissor`.
		# Params:
		# _x = Position x from the left corner of the window.
		# _y = Position y from the top corner of the window.
		# _width = Width of view scissor region.
		# _height = Height of view scissor region.
		#
		attach_function :bgfx_encoder_set_scissor, :bgfx_encoder_set_scissor, [Bgfx_encoder_t.by_ref, :uint16, :uint16, :uint16, :uint16], :uint16
	
		#
		# Set scissor from cache for draw primitive.
		# Remarks:
		#   To scissor for all primitives in view see `bgfx::setViewScissor`.
		# Params:
		# _cache = Index in scissor cache.
		#
		attach_function :bgfx_encoder_set_scissor_cached, :bgfx_encoder_set_scissor_cached, [Bgfx_encoder_t.by_ref, :uint16], :void
	
		#
		# Set model matrix for draw primitive. If it is not called,
		# the model will be rendered with an identity model matrix.
		# Params:
		# _mtx = Pointer to first matrix in array.
		# _num = Number of matrices in array.
		#
		attach_function :bgfx_encoder_set_transform, :bgfx_encoder_set_transform, [Bgfx_encoder_t.by_ref, :pointer, :uint16], :uint32
	
		#
		#  Set model matrix from matrix cache for draw primitive.
		# Params:
		# _cache = Index in matrix cache.
		# _num = Number of matrices from cache.
		#
		attach_function :bgfx_encoder_set_transform_cached, :bgfx_encoder_set_transform_cached, [Bgfx_encoder_t.by_ref, :uint32, :uint16], :void
	
		#
		# Reserve matrices in internal matrix cache.
		# Attention: Pointer returned can be modifed until `bgfx::frame` is called.
		# Params:
		# _transform = Pointer to `Transform` structure.
		# _num = Number of matrices.
		#
		attach_function :bgfx_encoder_alloc_transform, :bgfx_encoder_alloc_transform, [Bgfx_encoder_t.by_ref, :pointer, :uint16], :uint32
	
		#
		# Set shader uniform parameter for draw primitive.
		# Params:
		# _handle = Uniform.
		# _value = Pointer to uniform data.
		# _num = Number of elements. Passing `UINT16_MAX` will
		# use the _num passed on uniform creation.
		#
		attach_function :bgfx_encoder_set_uniform, :bgfx_encoder_set_uniform, [Bgfx_encoder_t.by_ref, Bgfx_uniform_handle_t.by_value, :pointer, :uint16], :void
	
		#
		# Set index buffer for draw primitive.
		# Params:
		# _handle = Index buffer.
		# _firstIndex = First index to render.
		# _numIndices = Number of indices to render.
		#
		attach_function :bgfx_encoder_set_index_buffer, :bgfx_encoder_set_index_buffer, [Bgfx_encoder_t.by_ref, Bgfx_index_buffer_handle_t.by_value, :uint32, :uint32], :void
	
		#
		# Set index buffer for draw primitive.
		# Params:
		# _handle = Dynamic index buffer.
		# _firstIndex = First index to render.
		# _numIndices = Number of indices to render.
		#
		attach_function :bgfx_encoder_set_dynamic_index_buffer, :bgfx_encoder_set_dynamic_index_buffer, [Bgfx_encoder_t.by_ref, Bgfx_dynamic_index_buffer_handle_t.by_value, :uint32, :uint32], :void
	
		#
		# Set index buffer for draw primitive.
		# Params:
		# _tib = Transient index buffer.
		# _firstIndex = First index to render.
		# _numIndices = Number of indices to render.
		#
		attach_function :bgfx_encoder_set_transient_index_buffer, :bgfx_encoder_set_transient_index_buffer, [Bgfx_encoder_t.by_ref, :pointer, :uint32, :uint32], :void
	
		#
		# Set vertex buffer for draw primitive.
		# Params:
		# _stream = Vertex stream.
		# _handle = Vertex buffer.
		# _startVertex = First vertex to render.
		# _numVertices = Number of vertices to render.
		# _layoutHandle = Vertex layout for aliasing vertex buffer. If invalid
		# handle is used, vertex layout used for creation
		# of vertex buffer will be used.
		#
		attach_function :bgfx_encoder_set_vertex_buffer, :bgfx_encoder_set_vertex_buffer, [Bgfx_encoder_t.by_ref, :uint8, Bgfx_vertex_buffer_handle_t.by_value, :uint32, :uint32, Bgfx_vertex_layout_handle_t.by_value], :void
	
		#
		# Set vertex buffer for draw primitive.
		# Params:
		# _stream = Vertex stream.
		# _handle = Dynamic vertex buffer.
		# _startVertex = First vertex to render.
		# _numVertices = Number of vertices to render.
		# _layoutHandle = Vertex layout for aliasing vertex buffer. If invalid
		# handle is used, vertex layout used for creation
		# of vertex buffer will be used.
		#
		attach_function :bgfx_encoder_set_dynamic_vertex_buffer, :bgfx_encoder_set_dynamic_vertex_buffer, [Bgfx_encoder_t.by_ref, :uint8, Bgfx_dynamic_vertex_buffer_handle_t.by_value, :uint32, :uint32, Bgfx_vertex_layout_handle_t.by_value], :void
	
		#
		# Set vertex buffer for draw primitive.
		# Params:
		# _stream = Vertex stream.
		# _tvb = Transient vertex buffer.
		# _startVertex = First vertex to render.
		# _numVertices = Number of vertices to render.
		# _layoutHandle = Vertex layout for aliasing vertex buffer. If invalid
		# handle is used, vertex layout used for creation
		# of vertex buffer will be used.
		#
		attach_function :bgfx_encoder_set_transient_vertex_buffer, :bgfx_encoder_set_transient_vertex_buffer, [Bgfx_encoder_t.by_ref, :uint8, :pointer, :uint32, :uint32, Bgfx_vertex_layout_handle_t.by_value], :void
	
		#
		# Set number of vertices for auto generated vertices use in conjuction
		# with gl_VertexID.
		# Attention: Availability depends on: `BGFX_CAPS_VERTEX_ID`.
		# Params:
		# _numVertices = Number of vertices.
		#
		attach_function :bgfx_encoder_set_vertex_count, :bgfx_encoder_set_vertex_count, [Bgfx_encoder_t.by_ref, :uint32], :void
	
		#
		# Set instance data buffer for draw primitive.
		# Params:
		# _idb = Transient instance data buffer.
		# _start = First instance data.
		# _num = Number of data instances.
		#
		attach_function :bgfx_encoder_set_instance_data_buffer, :bgfx_encoder_set_instance_data_buffer, [Bgfx_encoder_t.by_ref, :pointer, :uint32, :uint32], :void
	
		#
		# Set instance data buffer for draw primitive.
		# Params:
		# _handle = Vertex buffer.
		# _startVertex = First instance data.
		# _num = Number of data instances.
		# Set instance data buffer for draw primitive.
		#
		attach_function :bgfx_encoder_set_instance_data_from_vertex_buffer, :bgfx_encoder_set_instance_data_from_vertex_buffer, [Bgfx_encoder_t.by_ref, Bgfx_vertex_buffer_handle_t.by_value, :uint32, :uint32], :void
	
		#
		# Set instance data buffer for draw primitive.
		# Params:
		# _handle = Dynamic vertex buffer.
		# _startVertex = First instance data.
		# _num = Number of data instances.
		#
		attach_function :bgfx_encoder_set_instance_data_from_dynamic_vertex_buffer, :bgfx_encoder_set_instance_data_from_dynamic_vertex_buffer, [Bgfx_encoder_t.by_ref, Bgfx_dynamic_vertex_buffer_handle_t.by_value, :uint32, :uint32], :void
	
		#
		# Set number of instances for auto generated instances use in conjuction
		# with gl_InstanceID.
		# Attention: Availability depends on: `BGFX_CAPS_VERTEX_ID`.
		#
		attach_function :bgfx_encoder_set_instance_count, :bgfx_encoder_set_instance_count, [Bgfx_encoder_t.by_ref, :uint32], :void
	
		#
		# Set texture stage for draw primitive.
		# Params:
		# _stage = Texture unit.
		# _sampler = Program sampler.
		# _handle = Texture handle.
		# _flags = Texture sampling mode. Default value UINT32_MAX uses
		#   texture sampling settings from the texture.
		#   - `BGFX_SAMPLER_[U/V/W]_[MIRROR/CLAMP]` - Mirror or clamp to edge wrap
		#     mode.
		#   - `BGFX_SAMPLER_[MIN/MAG/MIP]_[POINT/ANISOTROPIC]` - Point or anisotropic
		#     sampling.
		#
		attach_function :bgfx_encoder_set_texture, :bgfx_encoder_set_texture, [Bgfx_encoder_t.by_ref, :uint8, Bgfx_uniform_handle_t.by_value, Bgfx_texture_handle_t.by_value, :uint32], :void
	
		#
		# Submit an empty primitive for rendering. Uniforms and draw state
		# will be applied but no geometry will be submitted. Useful in cases
		# when no other draw/compute primitive is submitted to view, but it's
		# desired to execute clear view.
		# Remarks:
		#   These empty draw calls will sort before ordinary draw calls.
		# Params:
		# _id = View id.
		#
		attach_function :bgfx_encoder_touch, :bgfx_encoder_touch, [Bgfx_encoder_t.by_ref, :Bgfx_view_id_t], :void
	
		#
		# Submit primitive for rendering.
		# Params:
		# _id = View id.
		# _program = Program.
		# _depth = Depth for sorting.
		# _flags = Discard or preserve states. See `BGFX_DISCARD_*`.
		#
		attach_function :bgfx_encoder_submit, :bgfx_encoder_submit, [Bgfx_encoder_t.by_ref, :Bgfx_view_id_t, Bgfx_program_handle_t.by_value, :uint32, :uint8], :void
	
		#
		# Submit primitive with occlusion query for rendering.
		# Params:
		# _id = View id.
		# _program = Program.
		# _occlusionQuery = Occlusion query.
		# _depth = Depth for sorting.
		# _flags = Discard or preserve states. See `BGFX_DISCARD_*`.
		#
		attach_function :bgfx_encoder_submit_occlusion_query, :bgfx_encoder_submit_occlusion_query, [Bgfx_encoder_t.by_ref, :Bgfx_view_id_t, Bgfx_program_handle_t.by_value, Bgfx_occlusion_query_handle_t.by_value, :uint32, :uint8], :void
	
		#
		# Submit primitive for rendering with index and instance data info from
		# indirect buffer.
		# Params:
		# _id = View id.
		# _program = Program.
		# _indirectHandle = Indirect buffer.
		# _start = First element in indirect buffer.
		# _num = Number of dispatches.
		# _depth = Depth for sorting.
		# _flags = Discard or preserve states. See `BGFX_DISCARD_*`.
		#
		attach_function :bgfx_encoder_submit_indirect, :bgfx_encoder_submit_indirect, [Bgfx_encoder_t.by_ref, :Bgfx_view_id_t, Bgfx_program_handle_t.by_value, Bgfx_indirect_buffer_handle_t.by_value, :uint16, :uint16, :uint32, :uint8], :void
	
		#
		# Set compute index buffer.
		# Params:
		# _stage = Compute stage.
		# _handle = Index buffer handle.
		# _access = Buffer access. See `Access::Enum`.
		#
		attach_function :bgfx_encoder_set_compute_index_buffer, :bgfx_encoder_set_compute_index_buffer, [Bgfx_encoder_t.by_ref, :uint8, Bgfx_index_buffer_handle_t.by_value, :Bgfx_access_t], :void
	
		#
		# Set compute vertex buffer.
		# Params:
		# _stage = Compute stage.
		# _handle = Vertex buffer handle.
		# _access = Buffer access. See `Access::Enum`.
		#
		attach_function :bgfx_encoder_set_compute_vertex_buffer, :bgfx_encoder_set_compute_vertex_buffer, [Bgfx_encoder_t.by_ref, :uint8, Bgfx_vertex_buffer_handle_t.by_value, :Bgfx_access_t], :void
	
		#
		# Set compute dynamic index buffer.
		# Params:
		# _stage = Compute stage.
		# _handle = Dynamic index buffer handle.
		# _access = Buffer access. See `Access::Enum`.
		#
		attach_function :bgfx_encoder_set_compute_dynamic_index_buffer, :bgfx_encoder_set_compute_dynamic_index_buffer, [Bgfx_encoder_t.by_ref, :uint8, Bgfx_dynamic_index_buffer_handle_t.by_value, :Bgfx_access_t], :void
	
		#
		# Set compute dynamic vertex buffer.
		# Params:
		# _stage = Compute stage.
		# _handle = Dynamic vertex buffer handle.
		# _access = Buffer access. See `Access::Enum`.
		#
		attach_function :bgfx_encoder_set_compute_dynamic_vertex_buffer, :bgfx_encoder_set_compute_dynamic_vertex_buffer, [Bgfx_encoder_t.by_ref, :uint8, Bgfx_dynamic_vertex_buffer_handle_t.by_value, :Bgfx_access_t], :void
	
		#
		# Set compute indirect buffer.
		# Params:
		# _stage = Compute stage.
		# _handle = Indirect buffer handle.
		# _access = Buffer access. See `Access::Enum`.
		#
		attach_function :bgfx_encoder_set_compute_indirect_buffer, :bgfx_encoder_set_compute_indirect_buffer, [Bgfx_encoder_t.by_ref, :uint8, Bgfx_indirect_buffer_handle_t.by_value, :Bgfx_access_t], :void
	
		#
		# Set compute image from texture.
		# Params:
		# _stage = Compute stage.
		# _handle = Texture handle.
		# _mip = Mip level.
		# _access = Image access. See `Access::Enum`.
		# _format = Texture format. See: `TextureFormat::Enum`.
		#
		attach_function :bgfx_encoder_set_image, :bgfx_encoder_set_image, [Bgfx_encoder_t.by_ref, :uint8, Bgfx_texture_handle_t.by_value, :uint8, :Bgfx_access_t, :Bgfx_texture_format_t], :void
	
		#
		# Dispatch compute.
		# Params:
		# _id = View id.
		# _program = Compute program.
		# _numX = Number of groups X.
		# _numY = Number of groups Y.
		# _numZ = Number of groups Z.
		# _flags = Discard or preserve states. See `BGFX_DISCARD_*`.
		#
		attach_function :bgfx_encoder_dispatch, :bgfx_encoder_dispatch, [Bgfx_encoder_t.by_ref, :Bgfx_view_id_t, Bgfx_program_handle_t.by_value, :uint32, :uint32, :uint32, :uint8], :void
	
		#
		# Dispatch compute indirect.
		# Params:
		# _id = View id.
		# _program = Compute program.
		# _indirectHandle = Indirect buffer.
		# _start = First element in indirect buffer.
		# _num = Number of dispatches.
		# _flags = Discard or preserve states. See `BGFX_DISCARD_*`.
		#
		attach_function :bgfx_encoder_dispatch_indirect, :bgfx_encoder_dispatch_indirect, [Bgfx_encoder_t.by_ref, :Bgfx_view_id_t, Bgfx_program_handle_t.by_value, Bgfx_indirect_buffer_handle_t.by_value, :uint16, :uint16, :uint8], :void
	
		#
		# Discard previously set state for draw or compute call.
		# Params:
		# _flags = Discard or preserve states. See `BGFX_DISCARD_*`.
		#
		attach_function :bgfx_encoder_discard, :bgfx_encoder_discard, [Bgfx_encoder_t.by_ref, :uint8], :void
	
		#
		# Blit 2D texture region between two 2D textures.
		# Attention: Destination texture must be created with `BGFX_TEXTURE_BLIT_DST` flag.
		# Attention: Availability depends on: `BGFX_CAPS_TEXTURE_BLIT`.
		# Params:
		# _id = View id.
		# _dst = Destination texture handle.
		# _dstMip = Destination texture mip level.
		# _dstX = Destination texture X position.
		# _dstY = Destination texture Y position.
		# _dstZ = If texture is 2D this argument should be 0. If destination texture is cube
		# this argument represents destination texture cube face. For 3D texture this argument
		# represents destination texture Z position.
		# _src = Source texture handle.
		# _srcMip = Source texture mip level.
		# _srcX = Source texture X position.
		# _srcY = Source texture Y position.
		# _srcZ = If texture is 2D this argument should be 0. If source texture is cube
		# this argument represents source texture cube face. For 3D texture this argument
		# represents source texture Z position.
		# _width = Width of region.
		# _height = Height of region.
		# _depth = If texture is 3D this argument represents depth of region, otherwise it's
		# unused.
		#
		attach_function :bgfx_encoder_blit, :bgfx_encoder_blit, [Bgfx_encoder_t.by_ref, :Bgfx_view_id_t, Bgfx_texture_handle_t.by_value, :uint8, :uint16, :uint16, :uint16, Bgfx_texture_handle_t.by_value, :uint8, :uint16, :uint16, :uint16, :uint16, :uint16, :uint16], :void
	
		#
		# Request screen shot of window back buffer.
		# Remarks:
		#   `bgfx::CallbackI::screenShot` must be implemented.
		# Attention: Frame buffer handle must be created with OS' target native window handle.
		# Params:
		# _handle = Frame buffer handle. If handle is `BGFX_INVALID_HANDLE` request will be
		# made for main window back buffer.
		# _filePath = Will be passed to `bgfx::CallbackI::screenShot` callback.
		#
		attach_function :bgfx_request_screen_shot, :bgfx_request_screen_shot, [Bgfx_frame_buffer_handle_t.by_value, :string], :void
	
		#
		# Render frame.
		# Attention: `bgfx::renderFrame` is blocking call. It waits for
		#   `bgfx::frame` to be called from API thread to process frame.
		#   If timeout value is passed call will timeout and return even
		#   if `bgfx::frame` is not called.
		# Warning: This call should be only used on platforms that don't
		#   allow creating separate rendering thread. If it is called before
		#   to bgfx::init, render thread won't be created by bgfx::init call.
		# Params:
		# _msecs = Timeout in milliseconds.
		#
		attach_function :bgfx_render_frame, :bgfx_render_frame, [:int32], :Bgfx_render_frame_t
	
		#
		# Set platform data.
		# Warning: Must be called before `bgfx::init`.
		# Params:
		# _data = Platform data.
		#
		attach_function :bgfx_set_platform_data, :bgfx_set_platform_data, [:pointer], :void
	
		#
		# Get internal data for interop.
		# Attention: It's expected you understand some bgfx internals before you
		#   use this call.
		# Warning: Must be called only on render thread.
		#
		attach_function :bgfx_get_internal_data, :bgfx_get_internal_data, [], :pointer
	
		#
		# Override internal texture with externally created texture. Previously
		# created internal texture will released.
		# Attention: It's expected you understand some bgfx internals before you
		#   use this call.
		# Warning: Must be called only on render thread.
		# Params:
		# _handle = Texture handle.
		# _ptr = Native API pointer to texture.
		#
		attach_function :bgfx_override_internal_texture_ptr, :bgfx_override_internal_texture_ptr, [Bgfx_texture_handle_t.by_value, :ulong], :ulong
	
		#
		# Override internal texture by creating new texture. Previously created
		# internal texture will released.
		# Attention: It's expected you understand some bgfx internals before you
		#   use this call.
		# Returns: Native API pointer to texture. If result is 0, texture is not created yet from the
		#   main thread.
		# Warning: Must be called only on render thread.
		# Params:
		# _handle = Texture handle.
		# _width = Width.
		# _height = Height.
		# _numMips = Number of mip-maps.
		# _format = Texture format. See: `TextureFormat::Enum`.
		# _flags = Texture creation (see `BGFX_TEXTURE_*`.), and sampler (see `BGFX_SAMPLER_*`)
		# flags. Default texture sampling mode is linear, and wrap mode is repeat.
		# - `BGFX_SAMPLER_[U/V/W]_[MIRROR/CLAMP]` - Mirror or clamp to edge wrap
		#   mode.
		# - `BGFX_SAMPLER_[MIN/MAG/MIP]_[POINT/ANISOTROPIC]` - Point or anisotropic
		#   sampling.
		#
		attach_function :bgfx_override_internal_texture, :bgfx_override_internal_texture, [Bgfx_texture_handle_t.by_value, :uint16, :uint16, :uint8, :Bgfx_texture_format_t, :uint64], :ulong
	
		#
		# Sets a debug marker. This allows you to group graphics calls together for easy browsing in
		# graphics debugging tools.
		# Params:
		# _marker = Marker string.
		#
		attach_function :bgfx_set_marker, :bgfx_set_marker, [:string], :void
	
		#
		# Set render states for draw primitive.
		# Remarks:
		#   1. To setup more complex states use:
		#      `BGFX_STATE_ALPHA_REF(_ref)`,
		#      `BGFX_STATE_POINT_SIZE(_size)`,
		#      `BGFX_STATE_BLEND_FUNC(_src, _dst)`,
		#      `BGFX_STATE_BLEND_FUNC_SEPARATE(_srcRGB, _dstRGB, _srcA, _dstA)`,
		#      `BGFX_STATE_BLEND_EQUATION(_equation)`,
		#      `BGFX_STATE_BLEND_EQUATION_SEPARATE(_equationRGB, _equationA)`
		#   2. `BGFX_STATE_BLEND_EQUATION_ADD` is set when no other blend
		#      equation is specified.
		# Params:
		# _state = State flags. Default state for primitive type is
		#   triangles. See: `BGFX_STATE_DEFAULT`.
		#   - `BGFX_STATE_DEPTH_TEST_*` - Depth test function.
		#   - `BGFX_STATE_BLEND_*` - See remark 1 about BGFX_STATE_BLEND_FUNC.
		#   - `BGFX_STATE_BLEND_EQUATION_*` - See remark 2.
		#   - `BGFX_STATE_CULL_*` - Backface culling mode.
		#   - `BGFX_STATE_WRITE_*` - Enable R, G, B, A or Z write.
		#   - `BGFX_STATE_MSAA` - Enable hardware multisample antialiasing.
		#   - `BGFX_STATE_PT_[TRISTRIP/LINES/POINTS]` - Primitive type.
		# _rgba = Sets blend factor used by `BGFX_STATE_BLEND_FACTOR` and
		#   `BGFX_STATE_BLEND_INV_FACTOR` blend modes.
		#
		attach_function :bgfx_set_state, :bgfx_set_state, [:uint64, :uint32], :void
	
		#
		# Set condition for rendering.
		# Params:
		# _handle = Occlusion query handle.
		# _visible = Render if occlusion query is visible.
		#
		attach_function :bgfx_set_condition, :bgfx_set_condition, [Bgfx_occlusion_query_handle_t.by_value, :bool], :void
	
		#
		# Set stencil test state.
		# Params:
		# _fstencil = Front stencil state.
		# _bstencil = Back stencil state. If back is set to `BGFX_STENCIL_NONE`
		# _fstencil is applied to both front and back facing primitives.
		#
		attach_function :bgfx_set_stencil, :bgfx_set_stencil, [:uint32, :uint32], :void
	
		#
		# Set scissor for draw primitive.
		# Remarks:
		#   To scissor for all primitives in view see `bgfx::setViewScissor`.
		# Params:
		# _x = Position x from the left corner of the window.
		# _y = Position y from the top corner of the window.
		# _width = Width of view scissor region.
		# _height = Height of view scissor region.
		#
		attach_function :bgfx_set_scissor, :bgfx_set_scissor, [:uint16, :uint16, :uint16, :uint16], :uint16
	
		#
		# Set scissor from cache for draw primitive.
		# Remarks:
		#   To scissor for all primitives in view see `bgfx::setViewScissor`.
		# Params:
		# _cache = Index in scissor cache.
		#
		attach_function :bgfx_set_scissor_cached, :bgfx_set_scissor_cached, [:uint16], :void
	
		#
		# Set model matrix for draw primitive. If it is not called,
		# the model will be rendered with an identity model matrix.
		# Params:
		# _mtx = Pointer to first matrix in array.
		# _num = Number of matrices in array.
		#
		attach_function :bgfx_set_transform, :bgfx_set_transform, [:pointer, :uint16], :uint32
	
		#
		#  Set model matrix from matrix cache for draw primitive.
		# Params:
		# _cache = Index in matrix cache.
		# _num = Number of matrices from cache.
		#
		attach_function :bgfx_set_transform_cached, :bgfx_set_transform_cached, [:uint32, :uint16], :void
	
		#
		# Reserve matrices in internal matrix cache.
		# Attention: Pointer returned can be modifed until `bgfx::frame` is called.
		# Params:
		# _transform = Pointer to `Transform` structure.
		# _num = Number of matrices.
		#
		attach_function :bgfx_alloc_transform, :bgfx_alloc_transform, [:pointer, :uint16], :uint32
	
		#
		# Set shader uniform parameter for draw primitive.
		# Params:
		# _handle = Uniform.
		# _value = Pointer to uniform data.
		# _num = Number of elements. Passing `UINT16_MAX` will
		# use the _num passed on uniform creation.
		#
		attach_function :bgfx_set_uniform, :bgfx_set_uniform, [Bgfx_uniform_handle_t.by_value, :pointer, :uint16], :void
	
		#
		# Set index buffer for draw primitive.
		# Params:
		# _handle = Index buffer.
		# _firstIndex = First index to render.
		# _numIndices = Number of indices to render.
		#
		attach_function :bgfx_set_index_buffer, :bgfx_set_index_buffer, [Bgfx_index_buffer_handle_t.by_value, :uint32, :uint32], :void
	
		#
		# Set index buffer for draw primitive.
		# Params:
		# _handle = Dynamic index buffer.
		# _firstIndex = First index to render.
		# _numIndices = Number of indices to render.
		#
		attach_function :bgfx_set_dynamic_index_buffer, :bgfx_set_dynamic_index_buffer, [Bgfx_dynamic_index_buffer_handle_t.by_value, :uint32, :uint32], :void
	
		#
		# Set index buffer for draw primitive.
		# Params:
		# _tib = Transient index buffer.
		# _firstIndex = First index to render.
		# _numIndices = Number of indices to render.
		#
		attach_function :bgfx_set_transient_index_buffer, :bgfx_set_transient_index_buffer, [:pointer, :uint32, :uint32], :void
	
		#
		# Set vertex buffer for draw primitive.
		# Params:
		# _stream = Vertex stream.
		# _handle = Vertex buffer.
		# _startVertex = First vertex to render.
		# _numVertices = Number of vertices to render.
		#
		attach_function :bgfx_set_vertex_buffer, :bgfx_set_vertex_buffer, [:uint8, Bgfx_vertex_buffer_handle_t.by_value, :uint32, :uint32], :void
	
		#
		# Set vertex buffer for draw primitive.
		# Params:
		# _stream = Vertex stream.
		# _handle = Dynamic vertex buffer.
		# _startVertex = First vertex to render.
		# _numVertices = Number of vertices to render.
		#
		attach_function :bgfx_set_dynamic_vertex_buffer, :bgfx_set_dynamic_vertex_buffer, [:uint8, Bgfx_dynamic_vertex_buffer_handle_t.by_value, :uint32, :uint32], :void
	
		#
		# Set vertex buffer for draw primitive.
		# Params:
		# _stream = Vertex stream.
		# _tvb = Transient vertex buffer.
		# _startVertex = First vertex to render.
		# _numVertices = Number of vertices to render.
		#
		attach_function :bgfx_set_transient_vertex_buffer, :bgfx_set_transient_vertex_buffer, [:uint8, :pointer, :uint32, :uint32], :void
	
		#
		# Set number of vertices for auto generated vertices use in conjuction
		# with gl_VertexID.
		# Attention: Availability depends on: `BGFX_CAPS_VERTEX_ID`.
		# Params:
		# _numVertices = Number of vertices.
		#
		attach_function :bgfx_set_vertex_count, :bgfx_set_vertex_count, [:uint32], :void
	
		#
		# Set instance data buffer for draw primitive.
		# Params:
		# _idb = Transient instance data buffer.
		# _start = First instance data.
		# _num = Number of data instances.
		#
		attach_function :bgfx_set_instance_data_buffer, :bgfx_set_instance_data_buffer, [:pointer, :uint32, :uint32], :void
	
		#
		# Set instance data buffer for draw primitive.
		# Params:
		# _handle = Vertex buffer.
		# _startVertex = First instance data.
		# _num = Number of data instances.
		# Set instance data buffer for draw primitive.
		#
		attach_function :bgfx_set_instance_data_from_vertex_buffer, :bgfx_set_instance_data_from_vertex_buffer, [Bgfx_vertex_buffer_handle_t.by_value, :uint32, :uint32], :void
	
		#
		# Set instance data buffer for draw primitive.
		# Params:
		# _handle = Dynamic vertex buffer.
		# _startVertex = First instance data.
		# _num = Number of data instances.
		#
		attach_function :bgfx_set_instance_data_from_dynamic_vertex_buffer, :bgfx_set_instance_data_from_dynamic_vertex_buffer, [Bgfx_dynamic_vertex_buffer_handle_t.by_value, :uint32, :uint32], :void
	
		#
		# Set number of instances for auto generated instances use in conjuction
		# with gl_InstanceID.
		# Attention: Availability depends on: `BGFX_CAPS_VERTEX_ID`.
		#
		attach_function :bgfx_set_instance_count, :bgfx_set_instance_count, [:uint32], :void
	
		#
		# Set texture stage for draw primitive.
		# Params:
		# _stage = Texture unit.
		# _sampler = Program sampler.
		# _handle = Texture handle.
		# _flags = Texture sampling mode. Default value UINT32_MAX uses
		#   texture sampling settings from the texture.
		#   - `BGFX_SAMPLER_[U/V/W]_[MIRROR/CLAMP]` - Mirror or clamp to edge wrap
		#     mode.
		#   - `BGFX_SAMPLER_[MIN/MAG/MIP]_[POINT/ANISOTROPIC]` - Point or anisotropic
		#     sampling.
		#
		attach_function :bgfx_set_texture, :bgfx_set_texture, [:uint8, Bgfx_uniform_handle_t.by_value, Bgfx_texture_handle_t.by_value, :uint32], :void
	
		#
		# Submit an empty primitive for rendering. Uniforms and draw state
		# will be applied but no geometry will be submitted.
		# Remarks:
		#   These empty draw calls will sort before ordinary draw calls.
		# Params:
		# _id = View id.
		#
		attach_function :bgfx_touch, :bgfx_touch, [:Bgfx_view_id_t], :void
	
		#
		# Submit primitive for rendering.
		# Params:
		# _id = View id.
		# _program = Program.
		# _depth = Depth for sorting.
		# _flags = Which states to discard for next draw. See BGFX_DISCARD_
		#
		attach_function :bgfx_submit, :bgfx_submit, [:Bgfx_view_id_t, Bgfx_program_handle_t.by_value, :uint32, :uint8], :void
	
		#
		# Submit primitive with occlusion query for rendering.
		# Params:
		# _id = View id.
		# _program = Program.
		# _occlusionQuery = Occlusion query.
		# _depth = Depth for sorting.
		# _flags = Which states to discard for next draw. See BGFX_DISCARD_
		#
		attach_function :bgfx_submit_occlusion_query, :bgfx_submit_occlusion_query, [:Bgfx_view_id_t, Bgfx_program_handle_t.by_value, Bgfx_occlusion_query_handle_t.by_value, :uint32, :uint8], :void
	
		#
		# Submit primitive for rendering with index and instance data info from
		# indirect buffer.
		# Params:
		# _id = View id.
		# _program = Program.
		# _indirectHandle = Indirect buffer.
		# _start = First element in indirect buffer.
		# _num = Number of dispatches.
		# _depth = Depth for sorting.
		# _flags = Which states to discard for next draw. See BGFX_DISCARD_
		#
		attach_function :bgfx_submit_indirect, :bgfx_submit_indirect, [:Bgfx_view_id_t, Bgfx_program_handle_t.by_value, Bgfx_indirect_buffer_handle_t.by_value, :uint16, :uint16, :uint32, :uint8], :void
	
		#
		# Set compute index buffer.
		# Params:
		# _stage = Compute stage.
		# _handle = Index buffer handle.
		# _access = Buffer access. See `Access::Enum`.
		#
		attach_function :bgfx_set_compute_index_buffer, :bgfx_set_compute_index_buffer, [:uint8, Bgfx_index_buffer_handle_t.by_value, :Bgfx_access_t], :void
	
		#
		# Set compute vertex buffer.
		# Params:
		# _stage = Compute stage.
		# _handle = Vertex buffer handle.
		# _access = Buffer access. See `Access::Enum`.
		#
		attach_function :bgfx_set_compute_vertex_buffer, :bgfx_set_compute_vertex_buffer, [:uint8, Bgfx_vertex_buffer_handle_t.by_value, :Bgfx_access_t], :void
	
		#
		# Set compute dynamic index buffer.
		# Params:
		# _stage = Compute stage.
		# _handle = Dynamic index buffer handle.
		# _access = Buffer access. See `Access::Enum`.
		#
		attach_function :bgfx_set_compute_dynamic_index_buffer, :bgfx_set_compute_dynamic_index_buffer, [:uint8, Bgfx_dynamic_index_buffer_handle_t.by_value, :Bgfx_access_t], :void
	
		#
		# Set compute dynamic vertex buffer.
		# Params:
		# _stage = Compute stage.
		# _handle = Dynamic vertex buffer handle.
		# _access = Buffer access. See `Access::Enum`.
		#
		attach_function :bgfx_set_compute_dynamic_vertex_buffer, :bgfx_set_compute_dynamic_vertex_buffer, [:uint8, Bgfx_dynamic_vertex_buffer_handle_t.by_value, :Bgfx_access_t], :void
	
		#
		# Set compute indirect buffer.
		# Params:
		# _stage = Compute stage.
		# _handle = Indirect buffer handle.
		# _access = Buffer access. See `Access::Enum`.
		#
		attach_function :bgfx_set_compute_indirect_buffer, :bgfx_set_compute_indirect_buffer, [:uint8, Bgfx_indirect_buffer_handle_t.by_value, :Bgfx_access_t], :void
	
		#
		# Set compute image from texture.
		# Params:
		# _stage = Compute stage.
		# _handle = Texture handle.
		# _mip = Mip level.
		# _access = Image access. See `Access::Enum`.
		# _format = Texture format. See: `TextureFormat::Enum`.
		#
		attach_function :bgfx_set_image, :bgfx_set_image, [:uint8, Bgfx_texture_handle_t.by_value, :uint8, :Bgfx_access_t, :Bgfx_texture_format_t], :void
	
		#
		# Dispatch compute.
		# Params:
		# _id = View id.
		# _program = Compute program.
		# _numX = Number of groups X.
		# _numY = Number of groups Y.
		# _numZ = Number of groups Z.
		# _flags = Discard or preserve states. See `BGFX_DISCARD_*`.
		#
		attach_function :bgfx_dispatch, :bgfx_dispatch, [:Bgfx_view_id_t, Bgfx_program_handle_t.by_value, :uint32, :uint32, :uint32, :uint8], :void
	
		#
		# Dispatch compute indirect.
		# Params:
		# _id = View id.
		# _program = Compute program.
		# _indirectHandle = Indirect buffer.
		# _start = First element in indirect buffer.
		# _num = Number of dispatches.
		# _flags = Discard or preserve states. See `BGFX_DISCARD_*`.
		#
		attach_function :bgfx_dispatch_indirect, :bgfx_dispatch_indirect, [:Bgfx_view_id_t, Bgfx_program_handle_t.by_value, Bgfx_indirect_buffer_handle_t.by_value, :uint16, :uint16, :uint8], :void
	
		#
		# Discard previously set state for draw or compute call.
		# Params:
		# _flags = Draw/compute states to discard.
		#
		attach_function :bgfx_discard, :bgfx_discard, [:uint8], :void
	
		#
		# Blit 2D texture region between two 2D textures.
		# Attention: Destination texture must be created with `BGFX_TEXTURE_BLIT_DST` flag.
		# Attention: Availability depends on: `BGFX_CAPS_TEXTURE_BLIT`.
		# Params:
		# _id = View id.
		# _dst = Destination texture handle.
		# _dstMip = Destination texture mip level.
		# _dstX = Destination texture X position.
		# _dstY = Destination texture Y position.
		# _dstZ = If texture is 2D this argument should be 0. If destination texture is cube
		# this argument represents destination texture cube face. For 3D texture this argument
		# represents destination texture Z position.
		# _src = Source texture handle.
		# _srcMip = Source texture mip level.
		# _srcX = Source texture X position.
		# _srcY = Source texture Y position.
		# _srcZ = If texture is 2D this argument should be 0. If source texture is cube
		# this argument represents source texture cube face. For 3D texture this argument
		# represents source texture Z position.
		# _width = Width of region.
		# _height = Height of region.
		# _depth = If texture is 3D this argument represents depth of region, otherwise it's
		# unused.
		#
		attach_function :bgfx_blit, :bgfx_blit, [:Bgfx_view_id_t, Bgfx_texture_handle_t.by_value, :uint8, :uint16, :uint16, :uint16, Bgfx_texture_handle_t.by_value, :uint8, :uint16, :uint16, :uint16, :uint16, :uint16, :uint16], :void
	
    end # self.import_symbols()
end # module Bgfx

if __FILE__ == $0
  Bgfx.load_lib('./libbgfx-shared-libRelease.dylib')
  init = Bgfx_init_t.new
  init[:type] = Bgfx::RendererType::Metal
  init[:vendorId] = Bgfx::Pci_Id_None
  init[:resolution][:width] = 1280
  init[:resolution][:height] = 720
  if Bgfx::bgfx_init(init)
    Bgfx::bgfx_shutdown()
  else
    pp "Failed to initialize Bgfx"
  end
end
