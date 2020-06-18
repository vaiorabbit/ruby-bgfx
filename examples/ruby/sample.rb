require 'rmath3d/rmath3d'
require 'sdl2'
require_relative '../../bindings/ruby/bgfx.rb'
require_relative './utils.rb'
require_relative 'imgui'
require_relative 'imgui_impl_bgfx'

class Sample

  attr_reader :name, :url, :desc
  attr_reader :window_width, :window_height, :debug, :reset

  module State
    Continue = 0
    Next = 1
    Previous = 2
  end

  def initialize(name = "", url = "", desc = "")
    @name = name
    @url = url
    @desc = desc

    @window_width = 0
    @window_height = 0
    @debug = Bgfx::Debug_None
    @reset = Bgfx::Reset_Vsync

    @eye = RMath3D::RVec3.new
    @at  = RMath3D::RVec3.new
    @up  = RMath3D::RVec3.new
    @mtx_view = RMath3D::RMtx4.new
    @view = FFI::MemoryPointer.new(:float, 16)

    @mtx_proj = RMath3D::RMtx4.new
    @proj =  FFI::MemoryPointer.new(:float, 16)

    @time = 0.0
  end

  def setup(width, height, debug, reset)
    @window_width = width
    @window_height = height
    @debug = debug
    @reset = reset

    return true
  end

  def teardown()
  end

  def handle_event(event)
  end

  def update(dt)
    return Sample::State::Continue
  end

end
