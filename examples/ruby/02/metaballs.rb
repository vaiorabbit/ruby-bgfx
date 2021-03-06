# coding: utf-8
#
# Ref.: bgfx/examples/02-metaballs/metaballs.cpp
#

require_relative '../common/sample'

################################################################################

class Sample02 < Sample

  DIMS_MIN = 8
  DIMS_MAX = 32

  class PosNormalColorVertex < FFI::Struct
    @@ms_layout = nil

    def self.ms_layout
      @@ms_layout
    end

    layout(
      :m_pos, [:float, 3],
      :m_normal, [:float, 3],
      :m_abgr, :uint32,
    )

    def self.init()
      if @@ms_layout == nil
        @@ms_layout = Bgfx_vertex_layout_t.new
        @@ms_layout.begin()
        @@ms_layout.add(Bgfx::Attrib::Position, 3, Bgfx::AttribType::Float)
        @@ms_layout.add(Bgfx::Attrib::Normal, 3, Bgfx::AttribType::Float)
        @@ms_layout.add(Bgfx::Attrib::Color0, 4, Bgfx::AttribType::Uint8, true)
        @@ms_layout.end
      end
    end
  end

  class Grid
    attr_accessor :m_val, :m_normal
    def initialize
      @m_val = 0.0
      @m_normal = [0.0, 0.0, 0.0]
    end
  end

  # Reference(s):
  # - Polygonising a scalar field
  #   https://web.archive.org/web/20181127124338/http://paulbourke.net/geometry/polygonise/

  @@s_edges_src = [ # static const uint16_t s_edges[256]
    0x000, 0x109, 0x203, 0x30a, 0x406, 0x50f, 0x605, 0x70c,
    0x80c, 0x905, 0xa0f, 0xb06, 0xc0a, 0xd03, 0xe09, 0xf00,
    0x190, 0x099, 0x393, 0x29a, 0x596, 0x49f, 0x795, 0x69c,
    0x99c, 0x895, 0xb9f, 0xa96, 0xd9a, 0xc93, 0xf99, 0xe90,
    0x230, 0x339, 0x033, 0x13a, 0x636, 0x73f, 0x435, 0x53c,
    0xa3c, 0xb35, 0x83f, 0x936, 0xe3a, 0xf33, 0xc39, 0xd30,
    0x3a0, 0x2a9, 0x1a3, 0x0aa, 0x7a6, 0x6af, 0x5a5, 0x4ac,
    0xbac, 0xaa5, 0x9af, 0x8a6, 0xfaa, 0xea3, 0xda9, 0xca0,
    0x460, 0x569, 0x663, 0x76a, 0x66 , 0x16f, 0x265, 0x36c,
    0xc6c, 0xd65, 0xe6f, 0xf66, 0x86a, 0x963, 0xa69, 0xb60,
    0x5f0, 0x4f9, 0x7f3, 0x6fa, 0x1f6, 0x0ff, 0x3f5, 0x2fc,
    0xdfc, 0xcf5, 0xfff, 0xef6, 0x9fa, 0x8f3, 0xbf9, 0xaf0,
    0x650, 0x759, 0x453, 0x55a, 0x256, 0x35f, 0x055, 0x15c,
    0xe5c, 0xf55, 0xc5f, 0xd56, 0xa5a, 0xb53, 0x859, 0x950,
    0x7c0, 0x6c9, 0x5c3, 0x4ca, 0x3c6, 0x2cf, 0x1c5, 0x0cc,
    0xfcc, 0xec5, 0xdcf, 0xcc6, 0xbca, 0xac3, 0x9c9, 0x8c0,
    0x8c0, 0x9c9, 0xac3, 0xbca, 0xcc6, 0xdcf, 0xec5, 0xfcc,
    0x0cc, 0x1c5, 0x2cf, 0x3c6, 0x4ca, 0x5c3, 0x6c9, 0x7c0,
    0x950, 0x859, 0xb53, 0xa5a, 0xd56, 0xc5f, 0xf55, 0xe5c,
    0x15c, 0x55 , 0x35f, 0x256, 0x55a, 0x453, 0x759, 0x650,
    0xaf0, 0xbf9, 0x8f3, 0x9fa, 0xef6, 0xfff, 0xcf5, 0xdfc,
    0x2fc, 0x3f5, 0x0ff, 0x1f6, 0x6fa, 0x7f3, 0x4f9, 0x5f0,
    0xb60, 0xa69, 0x963, 0x86a, 0xf66, 0xe6f, 0xd65, 0xc6c,
    0x36c, 0x265, 0x16f, 0x066, 0x76a, 0x663, 0x569, 0x460,
    0xca0, 0xda9, 0xea3, 0xfaa, 0x8a6, 0x9af, 0xaa5, 0xbac,
    0x4ac, 0x5a5, 0x6af, 0x7a6, 0x0aa, 0x1a3, 0x2a9, 0x3a0,
    0xd30, 0xc39, 0xf33, 0xe3a, 0x936, 0x83f, 0xb35, 0xa3c,
    0x53c, 0x435, 0x73f, 0x636, 0x13a, 0x033, 0x339, 0x230,
    0xe90, 0xf99, 0xc93, 0xd9a, 0xa96, 0xb9f, 0x895, 0x99c,
    0x69c, 0x795, 0x49f, 0x596, 0x29a, 0x393, 0x099, 0x190,
    0xf00, 0xe09, 0xd03, 0xc0a, 0xb06, 0xa0f, 0x905, 0x80c,
    0x70c, 0x605, 0x50f, 0x406, 0x30a, 0x203, 0x109, 0x000,
  ]

  @@s_indices_src = [ # static const int8_t s_indices[256][16]
    [  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  8,  3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  1,  9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   1,  8,  3,  9,  8,  1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   1,  2, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  8,  3,  1,  2, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   9,  2, 10,  0,  2,  9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   2,  8,  3,  2, 10,  8, 10,  9,  8, -1, -1, -1, -1, -1, -1, -1 ],
    [   3, 11,  2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   0, 11,  2,  8, 11,  0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   1,  9,  0,  2,  3, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   1, 11,  2,  1,  9, 11,  9,  8, 11, -1, -1, -1, -1, -1, -1, -1 ],
    [   3, 10,  1, 11, 10,  3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   0, 10,  1,  0,  8, 10,  8, 11, 10, -1, -1, -1, -1, -1, -1, -1 ],
    [   3,  9,  0,  3, 11,  9, 11, 10,  9, -1, -1, -1, -1, -1, -1, -1 ],
    [   9,  8, 10, 10,  8, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   4,  7,  8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   4,  3,  0,  7,  3,  4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  1,  9,  8,  4,  7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   4,  1,  9,  4,  7,  1,  7,  3,  1, -1, -1, -1, -1, -1, -1, -1 ],
    [   1,  2, 10,  8,  4,  7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   3,  4,  7,  3,  0,  4,  1,  2, 10, -1, -1, -1, -1, -1, -1, -1 ],
    [   9,  2, 10,  9,  0,  2,  8,  4,  7, -1, -1, -1, -1, -1, -1, -1 ],
    [   2, 10,  9,  2,  9,  7,  2,  7,  3,  7,  9,  4, -1, -1, -1, -1 ],
    [   8,  4,  7,  3, 11,  2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [  11,  4,  7, 11,  2,  4,  2,  0,  4, -1, -1, -1, -1, -1, -1, -1 ],
    [   9,  0,  1,  8,  4,  7,  2,  3, 11, -1, -1, -1, -1, -1, -1, -1 ],
    [   4,  7, 11,  9,  4, 11,  9, 11,  2,  9,  2,  1, -1, -1, -1, -1 ],
    [   3, 10,  1,  3, 11, 10,  7,  8,  4, -1, -1, -1, -1, -1, -1, -1 ],
    [   1, 11, 10,  1,  4, 11,  1,  0,  4,  7, 11,  4, -1, -1, -1, -1 ],
    [   4,  7,  8,  9,  0, 11,  9, 11, 10, 11,  0,  3, -1, -1, -1, -1 ],
    [   4,  7, 11,  4, 11,  9,  9, 11, 10, -1, -1, -1, -1, -1, -1, -1 ],
    [   9,  5,  4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   9,  5,  4,  0,  8,  3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  5,  4,  1,  5,  0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   8,  5,  4,  8,  3,  5,  3,  1,  5, -1, -1, -1, -1, -1, -1, -1 ],
    [   1,  2, 10,  9,  5,  4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   3,  0,  8,  1,  2, 10,  4,  9,  5, -1, -1, -1, -1, -1, -1, -1 ],
    [   5,  2, 10,  5,  4,  2,  4,  0,  2, -1, -1, -1, -1, -1, -1, -1 ],
    [   2, 10,  5,  3,  2,  5,  3,  5,  4,  3,  4,  8, -1, -1, -1, -1 ],
    [   9,  5,  4,  2,  3, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   0, 11,  2,  0,  8, 11,  4,  9,  5, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  5,  4,  0,  1,  5,  2,  3, 11, -1, -1, -1, -1, -1, -1, -1 ],
    [   2,  1,  5,  2,  5,  8,  2,  8, 11,  4,  8,  5, -1, -1, -1, -1 ],
    [  10,  3, 11, 10,  1,  3,  9,  5,  4, -1, -1, -1, -1, -1, -1, -1 ],
    [   4,  9,  5,  0,  8,  1,  8, 10,  1,  8, 11, 10, -1, -1, -1, -1 ],
    [   5,  4,  0,  5,  0, 11,  5, 11, 10, 11,  0,  3, -1, -1, -1, -1 ],
    [   5,  4,  8,  5,  8, 10, 10,  8, 11, -1, -1, -1, -1, -1, -1, -1 ],
    [   9,  7,  8,  5,  7,  9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   9,  3,  0,  9,  5,  3,  5,  7,  3, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  7,  8,  0,  1,  7,  1,  5,  7, -1, -1, -1, -1, -1, -1, -1 ],
    [   1,  5,  3,  3,  5,  7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   9,  7,  8,  9,  5,  7, 10,  1,  2, -1, -1, -1, -1, -1, -1, -1 ],
    [  10,  1,  2,  9,  5,  0,  5,  3,  0,  5,  7,  3, -1, -1, -1, -1 ],
    [   8,  0,  2,  8,  2,  5,  8,  5,  7, 10,  5,  2, -1, -1, -1, -1 ],
    [   2, 10,  5,  2,  5,  3,  3,  5,  7, -1, -1, -1, -1, -1, -1, -1 ],
    [   7,  9,  5,  7,  8,  9,  3, 11,  2, -1, -1, -1, -1, -1, -1, -1 ],
    [   9,  5,  7,  9,  7,  2,  9,  2,  0,  2,  7, 11, -1, -1, -1, -1 ],
    [   2,  3, 11,  0,  1,  8,  1,  7,  8,  1,  5,  7, -1, -1, -1, -1 ],
    [  11,  2,  1, 11,  1,  7,  7,  1,  5, -1, -1, -1, -1, -1, -1, -1 ],
    [   9,  5,  8,  8,  5,  7, 10,  1,  3, 10,  3, 11, -1, -1, -1, -1 ],
    [   5,  7,  0,  5,  0,  9,  7, 11,  0,  1,  0, 10, 11, 10,  0, -1 ],
    [  11, 10,  0, 11,  0,  3, 10,  5,  0,  8,  0,  7,  5,  7,  0, -1 ],
    [  11, 10,  5,  7, 11,  5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [  10,  6,  5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  8,  3,  5, 10,  6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   9,  0,  1,  5, 10,  6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   1,  8,  3,  1,  9,  8,  5, 10,  6, -1, -1, -1, -1, -1, -1, -1 ],
    [   1,  6,  5,  2,  6,  1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   1,  6,  5,  1,  2,  6,  3,  0,  8, -1, -1, -1, -1, -1, -1, -1 ],
    [   9,  6,  5,  9,  0,  6,  0,  2,  6, -1, -1, -1, -1, -1, -1, -1 ],
    [   5,  9,  8,  5,  8,  2,  5,  2,  6,  3,  2,  8, -1, -1, -1, -1 ],
    [   2,  3, 11, 10,  6,  5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [  11,  0,  8, 11,  2,  0, 10,  6,  5, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  1,  9,  2,  3, 11,  5, 10,  6, -1, -1, -1, -1, -1, -1, -1 ],
    [   5, 10,  6,  1,  9,  2,  9, 11,  2,  9,  8, 11, -1, -1, -1, -1 ],
    [   6,  3, 11,  6,  5,  3,  5,  1,  3, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  8, 11,  0, 11,  5,  0,  5,  1,  5, 11,  6, -1, -1, -1, -1 ],
    [   3, 11,  6,  0,  3,  6,  0,  6,  5,  0,  5,  9, -1, -1, -1, -1 ],
    [   6,  5,  9,  6,  9, 11, 11,  9,  8, -1, -1, -1, -1, -1, -1, -1 ],
    [   5, 10,  6,  4,  7,  8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   4,  3,  0,  4,  7,  3,  6,  5, 10, -1, -1, -1, -1, -1, -1, -1 ],
    [   1,  9,  0,  5, 10,  6,  8,  4,  7, -1, -1, -1, -1, -1, -1, -1 ],
    [  10,  6,  5,  1,  9,  7,  1,  7,  3,  7,  9,  4, -1, -1, -1, -1 ],
    [   6,  1,  2,  6,  5,  1,  4,  7,  8, -1, -1, -1, -1, -1, -1, -1 ],
    [   1,  2,  5,  5,  2,  6,  3,  0,  4,  3,  4,  7, -1, -1, -1, -1 ],
    [   8,  4,  7,  9,  0,  5,  0,  6,  5,  0,  2,  6, -1, -1, -1, -1 ],
    [   7,  3,  9,  7,  9,  4,  3,  2,  9,  5,  9,  6,  2,  6,  9, -1 ],
    [   3, 11,  2,  7,  8,  4, 10,  6,  5, -1, -1, -1, -1, -1, -1, -1 ],
    [   5, 10,  6,  4,  7,  2,  4,  2,  0,  2,  7, 11, -1, -1, -1, -1 ],
    [   0,  1,  9,  4,  7,  8,  2,  3, 11,  5, 10,  6, -1, -1, -1, -1 ],
    [   9,  2,  1,  9, 11,  2,  9,  4, 11,  7, 11,  4,  5, 10,  6, -1 ],
    [   8,  4,  7,  3, 11,  5,  3,  5,  1,  5, 11,  6, -1, -1, -1, -1 ],
    [   5,  1, 11,  5, 11,  6,  1,  0, 11,  7, 11,  4,  0,  4, 11, -1 ],
    [   0,  5,  9,  0,  6,  5,  0,  3,  6, 11,  6,  3,  8,  4,  7, -1 ],
    [   6,  5,  9,  6,  9, 11,  4,  7,  9,  7, 11,  9, -1, -1, -1, -1 ],
    [  10,  4,  9,  6,  4, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   4, 10,  6,  4,  9, 10,  0,  8,  3, -1, -1, -1, -1, -1, -1, -1 ],
    [  10,  0,  1, 10,  6,  0,  6,  4,  0, -1, -1, -1, -1, -1, -1, -1 ],
    [   8,  3,  1,  8,  1,  6,  8,  6,  4,  6,  1, 10, -1, -1, -1, -1 ],
    [   1,  4,  9,  1,  2,  4,  2,  6,  4, -1, -1, -1, -1, -1, -1, -1 ],
    [   3,  0,  8,  1,  2,  9,  2,  4,  9,  2,  6,  4, -1, -1, -1, -1 ],
    [   0,  2,  4,  4,  2,  6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   8,  3,  2,  8,  2,  4,  4,  2,  6, -1, -1, -1, -1, -1, -1, -1 ],
    [  10,  4,  9, 10,  6,  4, 11,  2,  3, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  8,  2,  2,  8, 11,  4,  9, 10,  4, 10,  6, -1, -1, -1, -1 ],
    [   3, 11,  2,  0,  1,  6,  0,  6,  4,  6,  1, 10, -1, -1, -1, -1 ],
    [   6,  4,  1,  6,  1, 10,  4,  8,  1,  2,  1, 11,  8, 11,  1, -1 ],
    [   9,  6,  4,  9,  3,  6,  9,  1,  3, 11,  6,  3, -1, -1, -1, -1 ],
    [   8, 11,  1,  8,  1,  0, 11,  6,  1,  9,  1,  4,  6,  4,  1, -1 ],
    [   3, 11,  6,  3,  6,  0,  0,  6,  4, -1, -1, -1, -1, -1, -1, -1 ],
    [   6,  4,  8, 11,  6,  8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   7, 10,  6,  7,  8, 10,  8,  9, 10, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  7,  3,  0, 10,  7,  0,  9, 10,  6,  7, 10, -1, -1, -1, -1 ],
    [  10,  6,  7,  1, 10,  7,  1,  7,  8,  1,  8,  0, -1, -1, -1, -1 ],
    [  10,  6,  7, 10,  7,  1,  1,  7,  3, -1, -1, -1, -1, -1, -1, -1 ],
    [   1,  2,  6,  1,  6,  8,  1,  8,  9,  8,  6,  7, -1, -1, -1, -1 ],
    [   2,  6,  9,  2,  9,  1,  6,  7,  9,  0,  9,  3,  7,  3,  9, -1 ],
    [   7,  8,  0,  7,  0,  6,  6,  0,  2, -1, -1, -1, -1, -1, -1, -1 ],
    [   7,  3,  2,  6,  7,  2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   2,  3, 11, 10,  6,  8, 10,  8,  9,  8,  6,  7, -1, -1, -1, -1 ],
    [   2,  0,  7,  2,  7, 11,  0,  9,  7,  6,  7, 10,  9, 10,  7, -1 ],
    [   1,  8,  0,  1,  7,  8,  1, 10,  7,  6,  7, 10,  2,  3, 11, -1 ],
    [  11,  2,  1, 11,  1,  7, 10,  6,  1,  6,  7,  1, -1, -1, -1, -1 ],
    [   8,  9,  6,  8,  6,  7,  9,  1,  6, 11,  6,  3,  1,  3,  6, -1 ],
    [   0,  9,  1, 11,  6,  7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   7,  8,  0,  7,  0,  6,  3, 11,  0, 11,  6,  0, -1, -1, -1, -1 ],
    [   7, 11,  6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   7,  6, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   3,  0,  8, 11,  7,  6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  1,  9, 11,  7,  6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   8,  1,  9,  8,  3,  1, 11,  7,  6, -1, -1, -1, -1, -1, -1, -1 ],
    [  10,  1,  2,  6, 11,  7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   1,  2, 10,  3,  0,  8,  6, 11,  7, -1, -1, -1, -1, -1, -1, -1 ],
    [   2,  9,  0,  2, 10,  9,  6, 11,  7, -1, -1, -1, -1, -1, -1, -1 ],
    [   6, 11,  7,  2, 10,  3, 10,  8,  3, 10,  9,  8, -1, -1, -1, -1 ],
    [   7,  2,  3,  6,  2,  7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   7,  0,  8,  7,  6,  0,  6,  2,  0, -1, -1, -1, -1, -1, -1, -1 ],
    [   2,  7,  6,  2,  3,  7,  0,  1,  9, -1, -1, -1, -1, -1, -1, -1 ],
    [   1,  6,  2,  1,  8,  6,  1,  9,  8,  8,  7,  6, -1, -1, -1, -1 ],
    [  10,  7,  6, 10,  1,  7,  1,  3,  7, -1, -1, -1, -1, -1, -1, -1 ],
    [  10,  7,  6,  1,  7, 10,  1,  8,  7,  1,  0,  8, -1, -1, -1, -1 ],
    [   0,  3,  7,  0,  7, 10,  0, 10,  9,  6, 10,  7, -1, -1, -1, -1 ],
    [   7,  6, 10,  7, 10,  8,  8, 10,  9, -1, -1, -1, -1, -1, -1, -1 ],
    [   6,  8,  4, 11,  8,  6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   3,  6, 11,  3,  0,  6,  0,  4,  6, -1, -1, -1, -1, -1, -1, -1 ],
    [   8,  6, 11,  8,  4,  6,  9,  0,  1, -1, -1, -1, -1, -1, -1, -1 ],
    [   9,  4,  6,  9,  6,  3,  9,  3,  1, 11,  3,  6, -1, -1, -1, -1 ],
    [   6,  8,  4,  6, 11,  8,  2, 10,  1, -1, -1, -1, -1, -1, -1, -1 ],
    [   1,  2, 10,  3,  0, 11,  0,  6, 11,  0,  4,  6, -1, -1, -1, -1 ],
    [   4, 11,  8,  4,  6, 11,  0,  2,  9,  2, 10,  9, -1, -1, -1, -1 ],
    [  10,  9,  3, 10,  3,  2,  9,  4,  3, 11,  3,  6,  4,  6,  3, -1 ],
    [   8,  2,  3,  8,  4,  2,  4,  6,  2, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  4,  2,  4,  6,  2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   1,  9,  0,  2,  3,  4,  2,  4,  6,  4,  3,  8, -1, -1, -1, -1 ],
    [   1,  9,  4,  1,  4,  2,  2,  4,  6, -1, -1, -1, -1, -1, -1, -1 ],
    [   8,  1,  3,  8,  6,  1,  8,  4,  6,  6, 10,  1, -1, -1, -1, -1 ],
    [  10,  1,  0, 10,  0,  6,  6,  0,  4, -1, -1, -1, -1, -1, -1, -1 ],
    [   4,  6,  3,  4,  3,  8,  6, 10,  3,  0,  3,  9, 10,  9,  3, -1 ],
    [  10,  9,  4,  6, 10,  4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   4,  9,  5,  7,  6, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  8,  3,  4,  9,  5, 11,  7,  6, -1, -1, -1, -1, -1, -1, -1 ],
    [   5,  0,  1,  5,  4,  0,  7,  6, 11, -1, -1, -1, -1, -1, -1, -1 ],
    [  11,  7,  6,  8,  3,  4,  3,  5,  4,  3,  1,  5, -1, -1, -1, -1 ],
    [   9,  5,  4, 10,  1,  2,  7,  6, 11, -1, -1, -1, -1, -1, -1, -1 ],
    [   6, 11,  7,  1,  2, 10,  0,  8,  3,  4,  9,  5, -1, -1, -1, -1 ],
    [   7,  6, 11,  5,  4, 10,  4,  2, 10,  4,  0,  2, -1, -1, -1, -1 ],
    [   3,  4,  8,  3,  5,  4,  3,  2,  5, 10,  5,  2, 11,  7,  6, -1 ],
    [   7,  2,  3,  7,  6,  2,  5,  4,  9, -1, -1, -1, -1, -1, -1, -1 ],
    [   9,  5,  4,  0,  8,  6,  0,  6,  2,  6,  8,  7, -1, -1, -1, -1 ],
    [   3,  6,  2,  3,  7,  6,  1,  5,  0,  5,  4,  0, -1, -1, -1, -1 ],
    [   6,  2,  8,  6,  8,  7,  2,  1,  8,  4,  8,  5,  1,  5,  8, -1 ],
    [   9,  5,  4, 10,  1,  6,  1,  7,  6,  1,  3,  7, -1, -1, -1, -1 ],
    [   1,  6, 10,  1,  7,  6,  1,  0,  7,  8,  7,  0,  9,  5,  4, -1 ],
    [   4,  0, 10,  4, 10,  5,  0,  3, 10,  6, 10,  7,  3,  7, 10, -1 ],
    [   7,  6, 10,  7, 10,  8,  5,  4, 10,  4,  8, 10, -1, -1, -1, -1 ],
    [   6,  9,  5,  6, 11,  9, 11,  8,  9, -1, -1, -1, -1, -1, -1, -1 ],
    [   3,  6, 11,  0,  6,  3,  0,  5,  6,  0,  9,  5, -1, -1, -1, -1 ],
    [   0, 11,  8,  0,  5, 11,  0,  1,  5,  5,  6, 11, -1, -1, -1, -1 ],
    [   6, 11,  3,  6,  3,  5,  5,  3,  1, -1, -1, -1, -1, -1, -1, -1 ],
    [   1,  2, 10,  9,  5, 11,  9, 11,  8, 11,  5,  6, -1, -1, -1, -1 ],
    [   0, 11,  3,  0,  6, 11,  0,  9,  6,  5,  6,  9,  1,  2, 10, -1 ],
    [  11,  8,  5, 11,  5,  6,  8,  0,  5, 10,  5,  2,  0,  2,  5, -1 ],
    [   6, 11,  3,  6,  3,  5,  2, 10,  3, 10,  5,  3, -1, -1, -1, -1 ],
    [   5,  8,  9,  5,  2,  8,  5,  6,  2,  3,  8,  2, -1, -1, -1, -1 ],
    [   9,  5,  6,  9,  6,  0,  0,  6,  2, -1, -1, -1, -1, -1, -1, -1 ],
    [   1,  5,  8,  1,  8,  0,  5,  6,  8,  3,  8,  2,  6,  2,  8, -1 ],
    [   1,  5,  6,  2,  1,  6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   1,  3,  6,  1,  6, 10,  3,  8,  6,  5,  6,  9,  8,  9,  6, -1 ],
    [  10,  1,  0, 10,  0,  6,  9,  5,  0,  5,  6,  0, -1, -1, -1, -1 ],
    [   0,  3,  8,  5,  6, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [  10,  5,  6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [  11,  5, 10,  7,  5, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [  11,  5, 10, 11,  7,  5,  8,  3,  0, -1, -1, -1, -1, -1, -1, -1 ],
    [   5, 11,  7,  5, 10, 11,  1,  9,  0, -1, -1, -1, -1, -1, -1, -1 ],
    [  10,  7,  5, 10, 11,  7,  9,  8,  1,  8,  3,  1, -1, -1, -1, -1 ],
    [  11,  1,  2, 11,  7,  1,  7,  5,  1, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  8,  3,  1,  2,  7,  1,  7,  5,  7,  2, 11, -1, -1, -1, -1 ],
    [   9,  7,  5,  9,  2,  7,  9,  0,  2,  2, 11,  7, -1, -1, -1, -1 ],
    [   7,  5,  2,  7,  2, 11,  5,  9,  2,  3,  2,  8,  9,  8,  2, -1 ],
    [   2,  5, 10,  2,  3,  5,  3,  7,  5, -1, -1, -1, -1, -1, -1, -1 ],
    [   8,  2,  0,  8,  5,  2,  8,  7,  5, 10,  2,  5, -1, -1, -1, -1 ],
    [   9,  0,  1,  5, 10,  3,  5,  3,  7,  3, 10,  2, -1, -1, -1, -1 ],
    [   9,  8,  2,  9,  2,  1,  8,  7,  2, 10,  2,  5,  7,  5,  2, -1 ],
    [   1,  3,  5,  3,  7,  5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  8,  7,  0,  7,  1,  1,  7,  5, -1, -1, -1, -1, -1, -1, -1 ],
    [   9,  0,  3,  9,  3,  5,  5,  3,  7, -1, -1, -1, -1, -1, -1, -1 ],
    [   9,  8,  7,  5,  9,  7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   5,  8,  4,  5, 10,  8, 10, 11,  8, -1, -1, -1, -1, -1, -1, -1 ],
    [   5,  0,  4,  5, 11,  0,  5, 10, 11, 11,  3,  0, -1, -1, -1, -1 ],
    [   0,  1,  9,  8,  4, 10,  8, 10, 11, 10,  4,  5, -1, -1, -1, -1 ],
    [  10, 11,  4, 10,  4,  5, 11,  3,  4,  9,  4,  1,  3,  1,  4, -1 ],
    [   2,  5,  1,  2,  8,  5,  2, 11,  8,  4,  5,  8, -1, -1, -1, -1 ],
    [   0,  4, 11,  0, 11,  3,  4,  5, 11,  2, 11,  1,  5,  1, 11, -1 ],
    [   0,  2,  5,  0,  5,  9,  2, 11,  5,  4,  5,  8, 11,  8,  5, -1 ],
    [   9,  4,  5,  2, 11,  3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   2,  5, 10,  3,  5,  2,  3,  4,  5,  3,  8,  4, -1, -1, -1, -1 ],
    [   5, 10,  2,  5,  2,  4,  4,  2,  0, -1, -1, -1, -1, -1, -1, -1 ],
    [   3, 10,  2,  3,  5, 10,  3,  8,  5,  4,  5,  8,  0,  1,  9, -1 ],
    [   5, 10,  2,  5,  2,  4,  1,  9,  2,  9,  4,  2, -1, -1, -1, -1 ],
    [   8,  4,  5,  8,  5,  3,  3,  5,  1, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  4,  5,  1,  0,  5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   8,  4,  5,  8,  5,  3,  9,  0,  5,  0,  3,  5, -1, -1, -1, -1 ],
    [   9,  4,  5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   4, 11,  7,  4,  9, 11,  9, 10, 11, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  8,  3,  4,  9,  7,  9, 11,  7,  9, 10, 11, -1, -1, -1, -1 ],
    [   1, 10, 11,  1, 11,  4,  1,  4,  0,  7,  4, 11, -1, -1, -1, -1 ],
    [   3,  1,  4,  3,  4,  8,  1, 10,  4,  7,  4, 11, 10, 11,  4, -1 ],
    [   4, 11,  7,  9, 11,  4,  9,  2, 11,  9,  1,  2, -1, -1, -1, -1 ],
    [   9,  7,  4,  9, 11,  7,  9,  1, 11,  2, 11,  1,  0,  8,  3, -1 ],
    [  11,  7,  4, 11,  4,  2,  2,  4,  0, -1, -1, -1, -1, -1, -1, -1 ],
    [  11,  7,  4, 11,  4,  2,  8,  3,  4,  3,  2,  4, -1, -1, -1, -1 ],
    [   2,  9, 10,  2,  7,  9,  2,  3,  7,  7,  4,  9, -1, -1, -1, -1 ],
    [   9, 10,  7,  9,  7,  4, 10,  2,  7,  8,  7,  0,  2,  0,  7, -1 ],
    [   3,  7, 10,  3, 10,  2,  7,  4, 10,  1, 10,  0,  4,  0, 10, -1 ],
    [   1, 10,  2,  8,  7,  4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   4,  9,  1,  4,  1,  7,  7,  1,  3, -1, -1, -1, -1, -1, -1, -1 ],
    [   4,  9,  1,  4,  1,  7,  0,  8,  1,  8,  7,  1, -1, -1, -1, -1 ],
    [   4,  0,  3,  7,  4,  3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   4,  8,  7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   9, 10,  8, 10, 11,  8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   3,  0,  9,  3,  9, 11, 11,  9, 10, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  1, 10,  0, 10,  8,  8, 10, 11, -1, -1, -1, -1, -1, -1, -1 ],
    [   3,  1, 10, 11,  3, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   1,  2, 11,  1, 11,  9,  9, 11,  8, -1, -1, -1, -1, -1, -1, -1 ],
    [   3,  0,  9,  3,  9, 11,  1,  2,  9,  2, 11,  9, -1, -1, -1, -1 ],
    [   0,  2, 11,  8,  0, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   3,  2, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   2,  3,  8,  2,  8, 10, 10,  8,  9, -1, -1, -1, -1, -1, -1, -1 ],
    [   9, 10,  2,  0,  9,  2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   2,  3,  8,  2,  8, 10,  0,  1,  8,  1, 10,  8, -1, -1, -1, -1 ],
    [   1, 10,  2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   1,  3,  8,  9,  1,  8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  9,  1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [   0,  3,  8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
    [  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ],
  ]

  @@s_cube = [
    [ 0.0, 1.0, 1.0 ], # 0
    [ 1.0, 1.0, 1.0 ], # 1
    [ 1.0, 1.0, 0.0 ], # 2
    [ 0.0, 1.0, 0.0 ], # 3
    [ 0.0, 0.0, 1.0 ], # 4
    [ 1.0, 0.0, 1.0 ], # 5
    [ 1.0, 0.0, 0.0 ], # 6
    [ 0.0, 0.0, 0.0 ], # 7
  ]

  ################################################################################

  def self.vertLerp(_result, _iso, _idx0, _v0, _idx1, _v1)
    edge0 = @@s_cube[_idx0]
    edge1 = @@s_cube[_idx1]

    if (_iso - _v1).abs < 0.00001
      _result[0] = edge1[0]
      _result[1] = edge1[1]
      _result[2] = edge1[2]
      return 1.0
    end

    if (_iso - _v0).abs < 0.00001 || (_v0 - _v1).abs < 0.00001
      _result[0] = edge0[0]
      _result[1] = edge0[1]
      _result[2] = edge0[2]
      return 0.0
    end

    lerp = (_iso - _v0) / (_v1 - _v0)
    _result[0] = edge0[0] + lerp * (edge1[0] - edge0[0])
    _result[1] = edge0[1] + lerp * (edge1[1] - edge0[1])
    _result[2] = edge0[2] + lerp * (edge1[2] - edge0[2])

    return lerp
  end

  def self.triangulate(_result, _stride, _rgb, _xyz, _val, _iso)
    cubeindex = 0
    cubeindex |= (_val[0].m_val < _iso) ? 0x01 : 0
    cubeindex |= (_val[1].m_val < _iso) ? 0x02 : 0
    cubeindex |= (_val[2].m_val < _iso) ? 0x04 : 0
    cubeindex |= (_val[3].m_val < _iso) ? 0x08 : 0
    cubeindex |= (_val[4].m_val < _iso) ? 0x10 : 0
    cubeindex |= (_val[5].m_val < _iso) ? 0x20 : 0
    cubeindex |= (_val[6].m_val < _iso) ? 0x40 : 0
    cubeindex |= (_val[7].m_val < _iso) ? 0x80 : 0
    return 0 if @@s_edges_src[cubeindex] == 0

    verts = Array.new(12) { Array.new(6) }
    flags = @@s_edges_src[cubeindex]

    indices1 = [1, 2, 3, 0, 5, 6, 7, 4, 4, 5, 6, 7]
    12.times do |ii|
      if (flags & (1 << ii)) != 0
        idx0 = ii & 7
        idx1 = indices1.at(ii) # "\x1\x2\x3\x0\x5\x6\x7\x4\x4\x5\x6\x7"[ii];
        vertex = verts[ii]
        lerp = vertLerp(vertex, _iso, idx0, _val[idx0].m_val, idx1, _val[idx1].m_val)
        na = _val[idx0].m_normal
        nb = _val[idx1].m_normal

        vertex[3] = na[0] + lerp * (nb[0] - na[0])
        vertex[4] = na[1] + lerp * (nb[1] - na[1])
        vertex[5] = na[2] + lerp * (nb[2] - na[2])
      end
    end

    dr = _rgb[3] - _rgb[0]
    dg = _rgb[4] - _rgb[1]
    db = _rgb[5] - _rgb[2]

    num = 0
    indices = @@s_indices_src[cubeindex]
    ii = 0

    while indices[ii] != -1

      result = PosNormalColorVertex.new(_result + _stride * ii)

      vertex = verts[indices[ii]]

      result[:m_pos][0] = _xyz[0] + vertex[0]
      result[:m_pos][1] = _xyz[1] + vertex[1]
      result[:m_pos][2] = _xyz[2] + vertex[2]

      result[:m_normal][0] = vertex[3]
      result[:m_normal][1] = vertex[4]
      result[:m_normal][2] = vertex[5]

      rr = ((_rgb[0] + vertex[0]*dr)*255.0).to_i
      gg = ((_rgb[1] + vertex[1]*dg)*255.0).to_i
      bb = ((_rgb[2] + vertex[2]*db)*255.0).to_i

      result[:m_abgr] = 0xff000000 | (bb<<16) | (gg<<8) | rr

      num += 1
      ii += 1
    end

    return num
  end

  ################################################################################

  def initialize
    super("02-metaball", "https://bkaradzic.github.io/bgfx/examples.html#metaballs", "Rendering with transient buffers and embedding shaders.")
    @ndc_homogeneous = true

    @m_program = nil

    @m_grid = nil
    @last = 0

    @dims = 0
    @dim_scale = 0.0
    @y_pitch = 0
    @z_pitch = 0
    @inv_dim = 0.0
  end

  def reset_dimension(dim = 16)
    return if dim < DIMS_MIN || dim > DIMS_MAX
    return if @dims == dim
    @dims = dim

    @dim_scale = @dims / DIMS_MAX.to_f
    @y_pitch = @dims
    @z_pitch = @dims * @dims
    @inv_dim = 1.0 / (@dims - 1).to_f

    @m_grid = Array.new(@dims * @dims * @dims) { Grid.new }

    @eye.setElements(0.0, 0.0, -50.0 * @dim_scale)
    @at.setElements(0.0, 0.0, 0.0)
    @up.setElements(0.0,  1.0,  0.0)
    @mtx_view.lookAtRH( @eye, @at, @up )
    @view.write_array_of_float(@mtx_view.to_a)
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

    bgfx_caps = Bgfx_caps_t.new(Bgfx::get_caps())
    @ndc_homogeneous = bgfx_caps[:homogeneousDepth]

    ImGui::ImplBgfx_Init()

    Bgfx::set_debug(debug)
    Bgfx::set_view_clear(0, Bgfx::Clear_Color|Bgfx::Clear_Depth, 0x303080ff, 1.0, 0)

    PosNormalColorVertex.init()

    @m_program = BgfxUtils.load_program("vs_metaballs", "fs_metaballs", "#{__dir__}/../")

    @last = SampleUtils.get_performance_counter()

    reset_dimension(16)

    @eye.setElements(0.0, 0.0, -50.0 * @dim_scale)
    @at.setElements(0.0, 0.0, 0.0)
    @up.setElements(0.0,  1.0,  0.0)
    @mtx_view.lookAtRH( @eye, @at, @up )
    @view.write_array_of_float(@mtx_view.to_a)

    @mtx_proj.perspectiveFovRH( 60.0*Math::PI/180.0, width.to_f/height.to_f, 0.1, 100.0, @ndc_homogeneous )
    @proj.write_array_of_float(@mtx_proj.to_a)
  end

  def teardown()
    ImGui::ImplBgfx_Shutdown()

    @dims = 0

    @m_grid = nil
    @last = 0

    Bgfx::destroy_program(@m_program) if @m_program

    Bgfx::shutdown()

    super()
  end

  def resize(width, height)
    super(width, height)
    @mtx_proj.perspectiveFovRH( 60.0*Math::PI/180.0, width.to_f/height.to_f, 0.1, 100.0, @ndc_homogeneous )
    @proj.write_array_of_float(@mtx_proj.to_a)
  end

  def update(dt)
    super(dt)
    @time += dt

    Bgfx::reset(@window_width, @window_height, @reset)

    ImGui::NewFrame()
    SampleDialog::show(self)

    Bgfx::set_view_transform(0, @view, @proj)
    Bgfx::set_view_rect(0, 0, 0, @window_width, @window_height)
    Bgfx::touch(0)

    now = SampleUtils.get_performance_counter()
    frameTime = now - @last
    @last = now
    freq = SampleUtils.get_performance_frequency().to_f
    toMs = 1000.0/freq

    numVertices = 0
    profUpdate = 0
    profNormal = 0
    profTriangulate = 0

    maxVertices = 32 << 10
    tvb = Bgfx_transient_vertex_buffer_t.new
    Bgfx::alloc_transient_vertex_buffer(tvb, maxVertices, PosNormalColorVertex.ms_layout)

    numSpheres = 16
    sphere = Array.new(numSpheres) { RVec4.new }

    coord_scale = 1.0 - ((DIMS_MAX - @dims).to_f / (DIMS_MAX - DIMS_MIN)) * (1.0 - 0.9)
    numSpheres.times do |ii|
      sphere[ii].setElements(
        coord_scale * Math.sin(@time*(ii*0.21)+ii*0.37) * (@dims * 0.5 - 8.0 * @dim_scale),
        coord_scale * Math.sin(@time*(ii*0.37)+ii*0.67) * (@dims * 0.5 - 8.0 * @dim_scale),
        coord_scale * Math.cos(@time*(ii*0.11)+ii*0.13) * (@dims * 0.5 - 8.0 * @dim_scale),
        1.0/(@dim_scale * (2.0 + (Math.sin(@time*(ii*0.13))*0.5+0.5)*2.0)) # 1.0/(2.0 + (Math.sin(@time*(ii*0.13) )*0.5+0.5)*2.0)
      )
    end

    profUpdate = SampleUtils.get_performance_counter()

    @dims.times do |zz|
      @dims.times do |yy|
        offset = (zz * @dims + yy) * @dims
        @dims.times do |xx|
          xoffset = offset + xx
          dist, prod = 0.0, 1.0
          numSpheres.times do |ii|
            pos = sphere[ii]
            dx = pos[0] - (-@dims*0.5 + xx.to_f)
            dy = pos[1] - (-@dims*0.5 + yy.to_f)
            dz = pos[2] - (-@dims*0.5 + zz.to_f)
            invr = pos[3]
            dot = dx*dx + dy*dy + dz*dz
            dot *= invr*invr

            dist *= dot
            dist += prod
            prod *= dot
          end
          @m_grid[xoffset].m_val = prod.abs >= 0.00001 ? dist / prod - 1.0 : -1.0
        end
      end
    end

    profUpdate = SampleUtils.get_performance_counter() - profUpdate

    profNormal = SampleUtils.get_performance_counter()

    normal = RVec3.new
    (1...(@dims-1)).each do |zz|
      (1...(@dims-1)).each do |yy|
        offset = (zz * @dims + yy) * @dims
        (1...(@dims-1)).each do |xx|
          xoffset = offset + xx
          normal.setElements(
            @m_grid[xoffset-1     ].m_val - @m_grid[xoffset+1     ].m_val,
            @m_grid[xoffset-@y_pitch].m_val - @m_grid[xoffset+@y_pitch].m_val,
            @m_grid[xoffset-@z_pitch].m_val - @m_grid[xoffset+@z_pitch].m_val
          )
          normal.normalize!
          @m_grid[xoffset].m_normal[0] = normal[0]
          @m_grid[xoffset].m_normal[1] = normal[1]
          @m_grid[xoffset].m_normal[2] = normal[2]
        end
      end
    end

    profNormal = SampleUtils.get_performance_counter() - profNormal

    profTriangulate = SampleUtils.get_performance_counter()

    rgb = Array.new(6) { 0.0 }
    (@dims - 1).times do |zz|
      break if numVertices + 12 >= maxVertices
      rgb[2] = zz * @inv_dim
      rgb[5] = (zz+1) * @inv_dim
      (@dims - 1).times do |yy|
        break if numVertices + 12 >= maxVertices
        offset = (zz * @dims + yy) * @dims
        rgb[1] = yy * @inv_dim
        rgb[4] = (yy+1) * @inv_dim
        (@dims - 1).times do |xx|
          xoffset = offset + xx
          rgb[0] = xx * @inv_dim
          rgb[3] = (xx+1) * @inv_dim
          pos = [-@dims * 0.5 + xx.to_f, -@dims * 0.5 + yy.to_f, -@dims * 0.5 + zz.to_f]
          val = [
            @m_grid[xoffset+@z_pitch+@y_pitch  ],
            @m_grid[xoffset+@z_pitch+@y_pitch+1],
            @m_grid[xoffset+@y_pitch+1       ],
            @m_grid[xoffset+@y_pitch         ],
            @m_grid[xoffset+@z_pitch         ],
            @m_grid[xoffset+@z_pitch+1       ],
            @m_grid[xoffset+1              ],
            @m_grid[xoffset                ],
          ]
          vertex = (tvb[:data] + PosNormalColorVertex.size * numVertices)
          num = Sample02::triangulate(vertex, PosNormalColorVertex::ms_layout[:stride], rgb, pos, val, 0.5)
          numVertices += num
        end
      end
    end

    profTriangulate = SampleUtils.get_performance_counter() - profTriangulate

    mtx = FFI::MemoryPointer.new(:float, 16).write_array_of_float((RMtx4.new.rotationY(@time) * RMtx4.new.rotationX(0.67 * @time)).to_a)

    Bgfx::set_transform(mtx, 1)
    Bgfx::set_transient_vertex_buffer(0, tvb, 0, numVertices)
    Bgfx::set_state(Bgfx::State_Write_Rgb | Bgfx::State_Write_A | Bgfx::State_Write_Z | Bgfx::State_Depth_Test_Less | Bgfx::State_Cull_Ccw | Bgfx::State_Msaa)
    Bgfx::submit(0, @m_program)

    # Stats
    ImGui::SetNextWindowPos(ImVec2.create(@window_width - @window_width / 5.0 - 10.0, 10.0), ImGuiCond_FirstUseEver)
    ImGui::SetNextWindowSize(ImVec2.create(@window_width / 5.0, @window_height / 6.0), ImGuiCond_FirstUseEver)
    ImGui::Begin("Stats", nil, 0)
    ImGui::Text("Num vertices:"); ImGui::SameLine(100); ImGui::Text("%5d (%6.4f%%)", :int, numVertices, :double, numVertices.to_f/maxVertices * 100)
    ImGui::Text("Update:");       ImGui::SameLine(100); ImGui::Text("% 7.3f[ms]", :double, profUpdate*toMs)
    ImGui::Text("Calc normals:"); ImGui::SameLine(100); ImGui::Text("% 7.3f[ms]", :double, profNormal*toMs)
    ImGui::Text("Triangulate:");  ImGui::SameLine(100); ImGui::Text("% 7.3f[ms]", :double, profTriangulate*toMs)
    ImGui::Text("Frame:");        ImGui::SameLine(100); ImGui::Text("% 7.3f[ms]", :double, frameTime*toMs)
    ImGui::End()

    # Parameters
    ImGui::SetNextWindowPos(ImVec2.create(@window_width - @window_width / 5.0 - 10.0, 150.0), ImGuiCond_FirstUseEver)
    ImGui::SetNextWindowSize(ImVec2.create(@window_width / 5.0, @window_height / 12.0), ImGuiCond_FirstUseEver)
    ImGui::Begin("Parameters", nil, 0)
    new_dims = FFI::MemoryPointer.new(:int, 1).put_int32(0, @dims)
    ImGui::SliderInt("Grid Dims", new_dims, DIMS_MIN, DIMS_MAX)
    reset_dimension(new_dims.read_int())
    ImGui::End()

    ImGui::Render()
    ImGui::ImplBgfx_RenderDrawData(ImGui::GetDrawData())

    Bgfx::frame()

  end

end
