require 'rmath3d/rmath3d'
require 'ffi'
require_relative '../../../bindings/ruby/bgfx'

module SampleMesh
  BGFX_CHUNK_MAGIC_VB = 'V'.ord | ('B'.ord << 8) | (' '.ord << 16) | 0x01 << 24
  BGFX_CHUNK_MAGIC_VBC = 'V'.ord | ('B'.ord << 8) | ('C'.ord << 16) | 0x0 << 24
  BGFX_CHUNK_MAGIC_IB = 'I'.ord | ('B'.ord << 8) | (' '.ord << 16) | 0x0 << 24
  BGFX_CHUNK_MAGIC_IBC = 'I'.ord | ('B'.ord << 8) | ('C'.ord << 16) | 0x1 << 24
  BGFX_CHUNK_MAGIC_PRI = 'P'.ord | ('R'.ord << 8) | ('I'.ord << 16) | 0x0 << 24

  class Sphere
    attr_accessor :center, :radius
    def initialize
      @center = RMath3D::RVec3.new
      @radius = 0.0
    end
  end

  class SphereBuf < FFI::Struct
    layout(
      :center, [:float, 3],
      :radius, :float
    )
  end

  class Aabb
    attr_accessor :min, :max
    def initialize
      @min = RMath3D::RVec3.new
      @max = RMath3D::RVec3.new
    end
  end

  class AabbBuf < FFI::Struct
    layout(
      :min, [:float, 3],
      :max, [:float, 3]
    )
  end

  class Obb
    attr_accessor :max
    def initialize
      @mtx = Array.new(16) { 0.0 }
      end
  end

  class ObbBuf < FFI::Struct
    layout(
      :mtx, [:float, 16]
    )
  end

  class Primitive
    attr_accessor :m_startIndex, :m_numIndices, :m_startVertex, :m_numVertices
    attr_accessor :m_sphere, :m_aabb, :m_obb

    def initialize
      @m_startIndex = 0
      @m_numIndices = 0
      @m_startVertex = 0
      @m_numVertices = 0
      @m_sphere = Sphere.new
      @m_aabb = Aabb.new
      @m_obb = Obb.new
    end
  end

  class Group
    attr_accessor :m_vbh, :m_ibh, :m_numVertices, :m_vertices, :m_numIndices, :m_indices
    attr_accessor :m_sphere, :m_aabb, :m_obb, :m_prims

    def initialize
      @m_vbh = Bgfx_vertex_buffer_handle_t.new
      @m_ibh = Bgfx_index_buffer_handle_t.new
      @m_numVertices = 0
      @m_vertices = nil
      @m_numIndices = 0
      @m_indices = nil
      @m_sphere = SphereBuf.new(FFI::MemoryPointer.new(:uint8, SphereBuf.size, false))
      @m_aabb = AabbBuf.new(FFI::MemoryPointer.new(:uint8, AabbBuf.size, false))
      @m_obb = ObbBuf.new(FFI::MemoryPointer.new(:uint8, ObbBuf.size, false))
      @m_prims = [] # array of Primitive
    end

    def reset
      @m_vbh[:idx] = Bgfx::InvalidHandleIdx
      @m_ibh[:idx] = Bgfx::InvalidHandleIdx
      @m_numVertices = 0
      @m_vertices = nil
      @m_numIndices = 0
      @m_indices = nil
      @m_prims.clear
    end
  end

  class Mesh
    attr_accessor :m_layout
    attr_accessor :m_groups

    def initialize
      @instance = nil
      @m_layout = Bgfx_vertex_layout_t.new(FFI::MemoryPointer.new(:uint8, Bgfx_vertex_layout_t.size, false))
      @m_groups = []
    end

    def load(io, ramcopy = false)
      group = Group.new
      chunk = " " * 4
      while io.read(4, chunk)
        case chunk.unpack1("L")
        when BGFX_CHUNK_MAGIC_VB
          # pp "0x#{chunk.unpack1("L").to_s(16)}"
          group.m_sphere.pointer.write_string(io.read(SphereBuf.size))
          group.m_aabb.pointer.write_string(io.read(AabbBuf.size))
          group.m_obb.pointer.write_string(io.read(ObbBuf.size))

          puts("Sphere #{group.m_sphere[:radius]}, #{group.m_sphere[:center][0]}, #{group.m_sphere[:center][1]}, #{group.m_sphere[:center][2]}")
          puts("Aabb #{group.m_aabb[:min][0]},#{group.m_aabb[:min][1]},#{group.m_aabb[:min][2]},  #{group.m_aabb[:max][0]},#{group.m_aabb[:max][1]},#{group.m_aabb[:max][2]}")
          puts("Obb #{group.m_obb[:mtx].to_a}")

          # TODO port bgfx::read(VertexLayout)
          # Ref: bgfx/src/vertexlayout.h|cpp

          group.m_numVertices = FFI::MemoryPointer.new(:uint16, 1, false).write_string(io.read(FFI::type_size(:uint16)))
          puts("#vertices #{group.m_numVertices.get_uint16(0)}")
          #pp group.m_aabb[:min][0], 
        when BGFX_CHUNK_MAGIC_VBC
          pp "0x#{chunk.unpack1("L").to_s(16)}"
        when BGFX_CHUNK_MAGIC_IB
          pp "0x#{chunk.unpack1("L").to_s(16)}"
        when BGFX_CHUNK_MAGIC_IBC
          pp "0x#{chunk.unpack1("L").to_s(16)}"
        when BGFX_CHUNK_MAGIC_PRI
          pp "0x#{chunk.unpack1("L").to_s(16)}"
        else

        end
      end
    end

    def unload; end

    def submit(id, program, mtx, state); end
  end
end
