require_relative 'common/mesh'
require_relative 'common/utils'

if __FILE__ == $PROGRAM_NAME
  Bgfx.load_lib(SampleUtils.bgfx_dll_path())
  init = Bgfx_init_t.new
  init[:type] = Bgfx::RendererType::Noop
  init[:vendorId] = Bgfx::Pci_Id_None
  init[:resolution][:width] = 0
  init[:resolution][:height] = 0
  init[:resolution][:reset] = Bgfx::Reset_None
  init[:limits][:maxEncoders] = 1
  init[:limits][:transientVbSize] = 6<<20
  init[:limits][:transientIbSize] = 2<<20
  bgfx_init_success = Bgfx::init(init)
  $stderr.puts("Failed to initialize Bgfx") unless bgfx_init_success
  m = SampleMesh::Mesh.new
  File.open('../runtime/meshes/bunny.bin') do |bin|
    m.load(bin)
  end
  m.unload
  Bgfx::shutdown()
end
