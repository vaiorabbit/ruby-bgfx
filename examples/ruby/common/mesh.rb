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

  module VertexLayout
    @@id_to_attrib = {
      0x0001 => Bgfx::Attrib::Position,
      0x0002 => Bgfx::Attrib::Normal,
      0x0003 => Bgfx::Attrib::Tangent,
      0x0004 => Bgfx::Attrib::Bitangent,
      0x0005 => Bgfx::Attrib::Color0,
      0x0006 => Bgfx::Attrib::Color1,
      0x0018 => Bgfx::Attrib::Color2,
      0x0019 => Bgfx::Attrib::Color3,
      0x000e => Bgfx::Attrib::Indices,
      0x000f => Bgfx::Attrib::Weight,
      0x0010 => Bgfx::Attrib::TexCoord0,
      0x0011 => Bgfx::Attrib::TexCoord1,
      0x0012 => Bgfx::Attrib::TexCoord2,
      0x0013 => Bgfx::Attrib::TexCoord3,
      0x0014 => Bgfx::Attrib::TexCoord4,
      0x0015 => Bgfx::Attrib::TexCoord5,
      0x0016 => Bgfx::Attrib::TexCoord6,
      0x0017 => Bgfx::Attrib::TexCoord7,
    }

    @@id_to_attrib_type = {
      0x0001 => Bgfx::AttribType::Uint8,
      0x0005 => Bgfx::AttribType::Uint10,
      0x0002 => Bgfx::AttribType::Int16,
      0x0003 => Bgfx::AttribType::Half,
      0x0004 => Bgfx::AttribType::Float,      
    }

    private_class_method
    def self.id_to_attrib(id)
      @@id_to_attrib[id]
    end

    private_class_method
    def self.id_to_attrib_type(id)
      @@id_to_attrib_type[id]
    end

    def self.read(io, layout)
      total = 0
      num_attrs = FFI::MemoryPointer.new(:uint8, 1, false).write_string(io.read(FFI::type_size(:uint8)))
      total += num_attrs.size
      stride = FFI::MemoryPointer.new(:uint16, 1, false).write_string(io.read(FFI::type_size(:uint16)))
      total += stride.type_size

      offset = FFI::MemoryPointer.new(:uint16, 1, false)
      attrib_id = FFI::MemoryPointer.new(:uint16, 1, false)
      num = FFI::MemoryPointer.new(:uint8, 1, false)
      attrib_type_id = FFI::MemoryPointer.new(:uint16, 1, false)
      normalized = FFI::MemoryPointer.new(:bool, 1, false)
      as_int = FFI::MemoryPointer.new(:bool, 1, false)

      layout.begin()
      num_attrs.read_uint8.times do |ii|
        offset.write_string(io.read(FFI::type_size(:uint16)))
        attrib_id.write_string(io.read(FFI::type_size(:uint16)))
        num.write_string(io.read(FFI::type_size(:uint8)))
        attrib_type_id.write_string(io.read(FFI::type_size(:uint16)))
        normalized.write_string(io.read(FFI::type_size(:bool)))
        as_int.write_string(io.read(FFI::type_size(:bool)))
        total += (offset.size + attrib_id.size + num.size + attrib_type_id.size + normalized.size + as_int.size)

        attrib = id_to_attrib(attrib_id.read_uint16)

        type = id_to_attrib_type(attrib_type_id.read_uint16)
        if attrib != Bgfx::Attrib::Count && type != Bgfx::Attrib::Count
          layout.add(attrib, num.read(:uint8), type, normalized.read(:bool), as_int.read(:bool))
          layout[:offset][attrib] = offset.read(:uint16)
        end
      end
      layout.end()
      layout[:stride] = stride.read_uint16
      return total
    end
  end

  class Mesh
    attr_accessor :m_layout
    attr_accessor :m_groups

    def initialize
      @instance = nil
      @m_layout = Bgfx_vertex_layout_t.new#(FFI::MemoryPointer.new(:uint8, Bgfx_vertex_layout_t.size, false))
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

          SampleMesh::VertexLayout::read(io, @m_layout)

          # NOTE : We can't find APIs like bgfx_vertex_layout_get_offset, bgfx_vertex_layout_get_stride, bgfx_vertex_layout_get_size.
          # These are marked as 'cpponly' in the IDL (bgfx.idl).
          # stride = @m_layout.get_stride()
          stride = @m_layout[:stride]
          group.m_numVertices = FFI::MemoryPointer.new(:uint16, 1, false).write_string(io.read(FFI::type_size(:uint16)))
          raw_mem = Bgfx::alloc(group.m_numVertices.read_uint16 * stride)
          mem = Bgfx_memory_t.new(raw_mem) # TODO make Bgfx::alloc directly return Bgfx_memory_t instance
          mem[:data].write_string(io.read(mem[:size]))
          # TODO if ramcopy == true
          group.m_vbh = Bgfx::create_vertex_buffer(mem, m_layout)
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
