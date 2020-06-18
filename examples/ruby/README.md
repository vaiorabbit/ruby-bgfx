## Prerequisites ##

*   rmath3d : Ruby Math Module for 3D Applications ( https://github.com/vaiorabbit/rmath3d , https://rubygems.org/gems/rmath3d )

        $ gem install rmath3d

*   sdl2-bindings : Experimental Ruby SDL2 bindings ( https://github.com/vaiorabbit/sdl2-bindings , https://rubygems.org/gems/sdl2-bindings )

        $ gem install sdl2-bindings

## Usage ##

    $ ruby applications.rb

*   'N' : Next sample
*   'P' : Previous sample
*   'Esc' : Quit

## License information ##

*   libbgfx-shared-libDebug.dylib, libbgfx-shared-libRelease.dylib
    *   bgfx ( https://github.com/bkaradzic/bgfx ) pre-build libraries for macOS
        *   Available under BSD 2-Clause License ( https://github.com/bkaradzic/bgfx/blob/master/LICENSE )
    *   [NOTE] bgfx build options:

            $ make osx-debug64 CFLAGS='-DBGFX_CONFIG_MULTITHREADED=0 -DBGFX_CONFIG_RENDERER_METAL'
            $ make osx-releaes64 CFLAGS='-DBGFX_CONFIG_MULTITHREADED=0 -DBGFX_CONFIG_RENDERER_METAL'

*   imgui.rb, imgui_impl_bgfx.rb and imgui_impl_sdl2.rb
    *   Copied from Ruby-ImGui ( https://github.com/vaiorabbit/ruby-imgui )

*   imgui.dylib
    *   cimgui ( https://github.com/cimgui/cimgui ) pre-build library for macOS
        *   Available under MIT License ( https://github.com/cimgui/cimgui/blob/master/LICENSE )
        *   You can get build scripts at https://github.com/vaiorabbit/ruby-imgui/tree/master/imgui_dll .

*   libSDL2.dylib
    *   SDL ( https://www.libsdl.org/ ) pre-build library for macOS
        *   Available under Zlib license ( https://www.libsdl.org/license.php )
