require 'rmath3d/rmath3d'
require 'ffi'
require_relative '../../../bindings/ruby/bgfx'

module SampleMesh
  class Sphere
    attr_accessor :center, :radius
    def initialize
      @center = RMath3D::RVec3.new
      @radius = 0.0
    end
    end

  class Aabb
    attr_accessor :min, :max
    def initialize
      @min = RMath3D::RVec3.new
      @max = RMath3D::RVec3.new
    end
  end

  class Obb
    attr_accessor :max
    def initialize
      @mtx = Array.new(16) { 0.0 }
      end
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
      @m_sphere = Sphere.new
      @m_aabb = Aabb.new
      @m_obb = Obb.new
      @m_prims = [] # array of Primitive
    end

    def reset; end
  end

  class Mesh
    attr_accessor :m_layout
    attr_accessor :m_groupd

    def initialize; end

    def load(data, ramcopy); end

    def unload; end

    def submit(id, program, mtx, state); end
  end
end
