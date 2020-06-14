## Shaders for ImGui : build options ##

    $ cd (path/to/bgfx)/examples/common/imgui
    $ mkdir -p shaders/metal/
    $ (path/to/bgfx)/.build/osx64_clang/bin/shadercRelease -i ../../../src  -f vs_ocornut_imgui.sc -o ./shaders/metal/vs_ocornut_imgui.bin --platform osx -p metal --type vertex --varyingdef ./varying.def.sc
    $ (path/to/bgfx)/.build/osx64_clang/bin/shadercRelease -i ../../../src  -f fs_ocornut_imgui.sc -o ./shaders/metal/fs_ocornut_imgui.bin --platform osx -p metal --type fragment --varyingdef ./varying.def.sc
    $ (path/to/bgfx)/.build/osx64_clang/bin/shadercRelease -i ../../../src  -f vs_imgui_image.sc -o ./shaders/metal/vs_imgui_image.bin --platform osx -p metal --type vertex --varyingdef ./varying.def.sc
    $ (path/to/bgfx)/.build/osx64_clang/bin/shadercRelease -i ../../../src  -f fs_imgui_image.sc -o ./shaders/metal/fs_imgui_image.bin --platform osx -p metal --type fragment --varyingdef ./varying.def.sc
    $ cp -a shaders (path/to/ruby-bgfx)/examples/ruby/
    $ cd (path/to/ruby-bgfx)/examples/ruby/
