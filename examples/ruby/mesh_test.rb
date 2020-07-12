require_relative 'common/mesh'

if __FILE__ == $PROGRAM_NAME
  m = SampleMesh::Mesh.new
  File.open('../runtime/meshes/bunny.bin') do |bin|
    m.load(bin)
  end
  m.unload
end