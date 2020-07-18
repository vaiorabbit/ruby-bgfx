require 'rmath3d/rmath3d'
require 'ffi'
require_relative '../../../bindings/ruby/bgfx'

module SampleMesh
  BGFX_CHUNK_MAGIC_VB = 'V'.ord | ('B'.ord << 8) | (' '.ord << 16) | 0x01 << 24
  BGFX_CHUNK_MAGIC_VBC = 'V'.ord | ('B'.ord << 8) | ('C'.ord << 16) | 0x0 << 24
  BGFX_CHUNK_MAGIC_IB = 'I'.ord | ('B'.ord << 8) | (' '.ord << 16) | 0x0 << 24
  BGFX_CHUNK_MAGIC_IBC = 'I'.ord | ('B'.ord << 8) | ('C'.ord << 16) | 0x1 << 24
  BGFX_CHUNK_MAGIC_PRI = 'P'.ord | ('R'.ord << 8) | ('I'.ord << 16) | 0x0 << 24

  class Sphere < FFI::Struct
    layout(
      :center, [:float, 3],
      :radius, :float
    )
  end

  class Aabb < FFI::Struct
    layout(
      :min, [:float, 3],
      :max, [:float, 3]
    )
  end

  class Obb < FFI::Struct
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
      @m_vbh = nil # Bgfx_vertex_buffer_handle_t
      @m_ibh = nil # Bgfx_index_buffer_handle_t
      @m_numVertices = 0
      @m_vertices = nil
      @m_numIndices = 0
      @m_indices = nil
      @m_sphere = Sphere.new
      @m_aabb = Aabb.new
      @m_obb = Obb.new
      @m_prims = [] # array of Primitive
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
      0x0017 => Bgfx::Attrib::TexCoord7
    }

    @@id_to_attrib_type = {
      0x0001 => Bgfx::AttribType::Uint8,
      0x0005 => Bgfx::AttribType::Uint10,
      0x0002 => Bgfx::AttribType::Int16,
      0x0003 => Bgfx::AttribType::Half,
      0x0004 => Bgfx::AttribType::Float
    }

    def self.id_to_attrib(id)
      @@id_to_attrib[id]
    end

    def self.id_to_attrib_type(id)
      @@id_to_attrib_type[id]
    end

    def self.read(io, layout)
      total = 0
      num_attrs = io.read(FFI.type_size(:uint8)).unpack1("C");      total += FFI.type_size(:uint8)
      stride = io.read(FFI.type_size(:uint16)).unpack1("S");        total += FFI.type_size(:uint16)

      layout.begin
      num_attrs.times do
        offset = io.read(FFI.type_size(:uint16)).unpack1("S");           total += FFI.type_size(:uint16)
        attrib_id = io.read(FFI.type_size(:uint16)).unpack1("S");        total += FFI.type_size(:uint16)
        num = io.read(FFI.type_size(:uint8)).unpack1("C");               total += FFI.type_size(:uint8)
        attrib_type_id = io.read(FFI.type_size(:uint16)).unpack1("S");   total += FFI.type_size(:uint16)
        normalized = io.read(FFI.type_size(:bool)).unpack1("C") != 0;    total += FFI.type_size(:bool)
        as_int = io.read(FFI.type_size(:bool)).unpack1("C") != 0;        total += FFI.type_size(:bool)

        attrib = id_to_attrib(attrib_id)
        type = id_to_attrib_type(attrib_type_id)
        if attrib != Bgfx::Attrib::Count && type != Bgfx::Attrib::Count
          layout.add(attrib, num, type, normalized, as_int)
          layout[:offset][attrib] = offset
        end
      end
      layout.end
      layout[:stride] = stride

      return total
    end
  end

  class Mesh
    attr_accessor :m_layout
    attr_accessor :m_groups

    def initialize
      @instance = nil
      @m_layout = Bgfx_vertex_layout_t.new
      @m_groups = []
    end

    def load(io, _ramcopy = false)
      group = Group.new
      chunk = ' ' * 4
      while io.read(4, chunk)
        case chunk.unpack1('L')
        when BGFX_CHUNK_MAGIC_VB
          group.m_sphere.pointer.write_string(io.read(Sphere.size))
          group.m_aabb.pointer.write_string(io.read(Aabb.size))
          group.m_obb.pointer.write_string(io.read(Obb.size))

          SampleMesh::VertexLayout.read(io, @m_layout)

          # NOTE : We can't find APIs like bgfx_vertex_layout_get_offset, bgfx_vertex_layout_get_stride, bgfx_vertex_layout_get_size.
          # These are marked as 'cpponly' in the IDL (bgfx.idl).
          # stride = @m_layout.get_stride()
          stride = @m_layout[:stride]
          group.m_numVertices = FFI::MemoryPointer.new(:uint16, 1, false).write_string(io.read(FFI.type_size(:uint16)))
          mem = Bgfx_memory_t.new(Bgfx.alloc(group.m_numVertices.read_uint16 * stride)) # TODO: make Bgfx::alloc directly return Bgfx_memory_t instance
          mem[:data].write_string(io.read(mem[:size]))
          # TODO: if ramcopy == true
          group.m_vbh = Bgfx.create_vertex_buffer(mem, m_layout)

        when BGFX_CHUNK_MAGIC_VBC
          pp "[TODO] VBC 0x#{chunk.unpack1('L').to_s(16)}"

        when BGFX_CHUNK_MAGIC_IB
          group.m_numIndices = FFI::MemoryPointer.new(:uint32, 1, false).write_string(io.read(FFI.type_size(:uint32)))
          mem = Bgfx_memory_t.new(Bgfx.alloc(group.m_numIndices.read_uint32 * 2)) # TODO: make Bgfx::alloc directly return Bgfx_memory_t instance
          mem[:data].write_string(io.read(mem[:size]))
          # TODO: if ramcopy == true
          group.m_ibh = Bgfx.create_index_buffer(mem)

        when BGFX_CHUNK_MAGIC_IBC
          pp "[TODO] IBC 0x#{chunk.unpack1('L').to_s(16)}"

        when BGFX_CHUNK_MAGIC_PRI
          len = io.read(FFI.type_size(:uint16)).unpack1('S')
          material = ' ' * len
          io.read(len, material)

          num = io.read(FFI.type_size(:uint16)).unpack1('S')
          num.times do
            len = io.read(FFI.type_size(:uint16)).unpack1('S')
            name = ' ' * len
            io.read(len, name)

            prim = Primitive.new
            prim.m_startIndex = io.read(FFI.type_size(:uint32)).unpack1('L')
            prim.m_numIndices = io.read(FFI.type_size(:uint32)).unpack1('L')
            prim.m_startVertex = io.read(FFI.type_size(:uint32)).unpack1('L')
            prim.m_numVertices = io.read(FFI.type_size(:uint32)).unpack1('L')
            prim.m_sphere.pointer.write_string(io.read(Sphere.size))
            prim.m_aabb.pointer.write_string(io.read(Aabb.size))
            prim.m_obb.pointer.write_string(io.read(Obb.size))

            group.m_prims << prim
          end

          m_groups << group
          group = Group.new
        end
      end
    end

    def unload; end

    def submit(id, program, mtx, state = Bgfx::State_Mask)
      if Bgfx::State_Mask == state
        state = 0 | Bgfx::State_Write_Rgb | Bgfx::State_Write_A | Bgfx::State_Write_Z | Bgfx::State_Depth_Test_Less | Bgfx::State_Cull_Ccw | Bgfx::State_Msaa
      end

      Bgfx.set_transform(mtx, 1) # TODO: Add missing default argument 'def self.set_transform(_mtx, _num = 1)''
      Bgfx.set_state(state)

      m_groups.each do |group|
        Bgfx.set_index_buffer(group.m_ibh, 0, 0xFFFFFFFF) # TODO Add missing default arguments _firstIndex, _numIndices
        Bgfx.set_vertex_buffer(0, group.m_vbh, 0, 0xFFFFFFFF)
        Bgfx.submit(id, program, 0, group == m_groups.last ? (Bgfx::Discard_IndexBuffer | Bgfx::Discard_VertexStreams | Bgfx::Discard_State) : Bgfx::Discard_None)
      end
    end
  end
end
