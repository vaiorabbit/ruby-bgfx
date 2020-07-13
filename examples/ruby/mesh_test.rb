require_relative 'common/mesh'
require_relative 'common/utils'

if __FILE__ == $PROGRAM_NAME
  Bgfx.load_lib(SampleUtils.bgfx_dll_path())
  m = SampleMesh::Mesh.new
  File.open('../runtime/meshes/bunny.bin') do |bin|
    m.load(bin)
  end
  m.unload
end
