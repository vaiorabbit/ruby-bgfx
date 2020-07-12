require_relative 'common/mesh'

if __FILE__ == $PROGRAM_NAME
  File.open('../runtime/meshes/bunny.bin') do |bin|
    pp bin.readlines
  end
end