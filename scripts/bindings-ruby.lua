-- Usage:
-- local rubygen = require "bindings-ruby"
-- rubygen.write(rubygen.gen(), "../bindings/ruby/bgfx.rb")

local codegen = require "codegen"
local idl = codegen.idl "bgfx.idl"

local ruby_template = [[
# [NOTE] Generated automatically with Ruby-bgfx ( https://github.com/vaiorabbit/ruby-bgfx ). Do NOT edit.

require 'ffi'

#
# Typedefs
#

FFI.typedef :uint16, :Bgfx_view_id_t # [HACK] Hard-coded. Seems we can't get information about this from current 'bgfx.idl'.
$typedefs

#
# Enums / Bitflags
#
module Bgfx

  extend FFI::Library

  @@bgfx_import_done = false

  def self.load_lib(libpath = './libbgfx-shared-libRelease.dylib')
    ffi_lib_flags :now, :global
    ffi_lib libpath
    import_symbols() unless @@bgfx_import_done
  end

$types
end # module Bgfx


#
# Structs
#

class Bgfx_invalid_handle_t < FFI::Struct
  layout(:idx, :ushort)
  def self.create
    handle = new
    handle[:idx] = Bgfx::InvalidHandleIdx
    return handle
  end
end

$handles
$structs

#
# Functions
#
module Bgfx

  InvalidHandleIdx = 0xffff

  def self.is_valid(handle)
    return handle[:idx] != InvalidHandleIdx
  end

  InvalidHandle = Bgfx_invalid_handle_t.create

  def self.import_symbols()
    symbols = [
$attachfuncsymbols
    ]

    args = {
$attachfuncargs
    }

    retvals = {
$attachfuncretvals
    }

    symbols.each do |sym|
      begin
        attach_function sym, args[sym], retvals[sym]
      rescue FFI::NotFoundError => error
        $stderr.puts("[Warning] Failed to import #{sym} (#{error}).")
      end
    end
  end # self.import_symbols()

$modulefuncs
end # module Bgfx
]]

local converter = {}
local yield = coroutine.yield
local indent = ""

local typedefs_list = {}
local methods_list = {}

local attach_func_symbols = {}
local attach_func_args = {}
local attach_func_retvals = {}

----------------------------------------------------------------------------------------------------

local function hasPrefix(str, prefix)
   return prefix == "" or str:sub(1, #prefix) == prefix
end

local function hasSuffix(str, suffix)
   return suffix == "" or str:sub(-#suffix) == suffix
end

local function to_underscorecase(name)
   local tmp = {}
   for v in name:gmatch "[_%u][%l%d]*" do
      if v:byte() == 95 then    -- '_'
         v = v:sub(2)   -- remove _
      end
      tmp[#tmp+1] = v
   end
   return table.concat(tmp, "_")
end

----------------------------------------------------------------------------------------------------

local gen = {}

function generate(tmp, idl_info, conv)
   for _, object in ipairs(idl_info) do
      local co = coroutine.create(conv)
      local any
      while true do
         local ok, v = coroutine.resume(co, object)
         assert(ok, debug.traceback(co, v))
         if not v then
            break
         end
         table.insert(tmp, v)
         any = true
      end
      if any and tmp[#tmp] ~= "" then
         table.insert(tmp, "")
      end
   end
end

function gen.gen()
   -- 1st pass : Collect typedef/method information
   for _, object in ipairs(idl["types"]) do
      local co = coroutine.create(collect_typedefs_list)
      local any
      while true do
         local ok, v = coroutine.resume(co, object)
         assert(ok, debug.traceback(co, v))
         if not v then
            break
         end
      end
   end

   for _, object in ipairs(idl["funcs"]) do
      local co = coroutine.create(collect_methods_list)
      local any
      while true do
         local ok, v = coroutine.resume(co, object)
         assert(ok, debug.traceback(co, v))
         if not v then
            break
         end
      end
   end

   for _, object in ipairs(idl["funcs"]) do
      local co = coroutine.create(collect_attach_funcs)
      local any
      while true do
         local ok, v = coroutine.resume(co, object)
         assert(ok, debug.traceback(co, v))
         if not v then
            break
         end
      end
   end

   -- 2nd pass
   local r = ruby_template:gsub("$(%l+)", function(what)
                                   local tmp = {}
                                   if what == "handles" then
                                      -- Structs used as handles
                                      generate(tmp, idl["types"], converter["handles"])
                                      return table.concat(tmp, "\n")
                                   elseif what == "structs" then
                                      -- General structs / Instance methods
                                      generate(tmp, idl["types"], converter["structs"])
                                      return table.concat(tmp, "\n")
                                   elseif what == "typedefs" then
                                      -- Typedefs
                                      generate(tmp, idl["types"], converter["typedefs"])
                                      return table.concat(tmp)
                                   elseif what == "types" then
                                      -- Enums / Bitflags
                                      generate(tmp, idl["types"], converter["types"])
                                      return table.concat(tmp, "\n")
                                   elseif what == "attachfuncsymbols" then
                                      -- Raw function symbols(entry points)
                                      generate(tmp, idl["funcs"], converter["attachfunc_symbols"])
                                      return table.concat(tmp)
                                   elseif what == "attachfuncargs" then
                                      -- Arguments of raw functions
                                      generate(tmp, idl["funcs"], converter["attachfunc_args"])
                                      return table.concat(tmp)
                                   elseif what == "attachfuncretvals" then
                                      -- Return values of raw functions
                                      generate(tmp, idl["funcs"], converter["attachfunc_retvals"])
                                      return table.concat(tmp)
                                   elseif what == "modulefuncs" then
                                      -- Wrapper functions
                                      generate(tmp, idl["funcs"], converter["module_funcs"])
                                      return table.concat(tmp, "\n")
                                   end
   end)
   return r
end

----------------------------------------------------------------------------------------------------

local function convert_array(member)
   count = string.gsub(member.array, "%[(.+)%]", "%1")
   return member.array
end

local function convert_type(arg, array_as_pointer)
   local ctype = arg.ctype:gsub("%s%*", "*")
   if arg.fulltype == "bx::AllocatorI*" or arg.fulltype == "CallbackI*" or arg.fulltype == "ReleaseFn" then
      ctype = ":pointer"
   elseif hasPrefix(ctype, "const char") and hasSuffix(ctype, "*") then
      ctype = ":string"
   elseif string.match(ctype, "*") then
      ctype = ":pointer"
   end

   -- Omit 'const'
   ctype = string.gsub(ctype, "const ", "")

   if hasPrefix(ctype, "bgfx") then
      name = ctype:gsub("^%l", string.upper)
      local is_typedef = false
      if name == "Bgfx_view_id_t" then
         -- [HACK] Hard-coded. Seems we can't get information about this from current 'bgfx.idl'.
         is_typedef = true
      else
         for _, t in ipairs(typedefs_list) do
            if t == name then
               is_typedef = true
               break
            end
         end
      end
      if is_typedef then
         ctype = ":" .. name
      else
         ctype = name .. ".by_value"
      end
   elseif hasPrefix(ctype, "uint64_t") then
      ctype = ctype:gsub("uint64_t", ":uint64")
   elseif hasPrefix(ctype, "int64_t") then
      ctype = ctype:gsub("int64_t", ":int64")
   elseif hasPrefix(ctype, "uint32_t") then
      ctype = ctype:gsub("uint32_t", ":uint32")
   elseif hasPrefix(ctype, "int32_t") then
      ctype = ctype:gsub("int32_t", ":int32")
   elseif hasPrefix(ctype, "uint16_t") then
      ctype = ctype:gsub("uint16_t", ":uint16")
   elseif hasPrefix(ctype, "uint8_t") then
      ctype = ctype:gsub("uint8_t", ":uint8")
   elseif hasPrefix(ctype, "uintptr_t") then
      ctype = ctype:gsub("uintptr_t", ":ulong")
   elseif hasPrefix(ctype, "bool") then
      ctype = ctype:gsub("bool", ":bool")
   elseif hasPrefix(ctype, "char") then
      ctype = ctype:gsub("char", ":char")
   elseif hasPrefix(ctype, "float") then
      ctype = ":float"
   elseif hasPrefix(ctype, "double") then
      ctype = ":double"
   elseif hasPrefix(ctype, "...") then
      ctype = ":varargs"
   elseif hasPrefix(ctype, "va_list") then
      ctype = ":pointer"
   elseif hasPrefix(ctype, "void") then
      ctype = ":void"
   end

   if arg.array ~= nil then
      if array_as_pointer then
         ctype = ":pointer"
      else
         count = string.gsub(arg.array, "%[(.+)%]", "%1")
         if string.find(count, "::") then
            count = "Bgfx::" .. count -- e.g.) Topology::Count -> Bgfx::Topology::Count
         end
         ctype = "[" .. ctype .. ", " .. count .. "]"
      end
   end

   return ctype
end

local function convert_name(arg)
   if arg == "debug" then
      return arg .. "_"
   end
   return arg
end

local function convert_struct_member(member)
   return ":" .. convert_name(member.name) .. ", " .. convert_type(member)
end

-- C to Ruby literal conversion
local function sanitize_default_argument(arg_str)
   retval = ""

   if arg_str == "NULL" then
      retval = "nil"
   elseif arg_str == "BGFX_INVALID_HANDLE" then
      retval = "Bgfx::InvalidHandle"
   elseif arg_str == "BGFX_TEXTURE_NONE|BGFX_SAMPLER_NONE" then
      retval = "Bgfx::Texture_None|Bgfx::Sampler_None"
   elseif arg_str == "BGFX_SAMPLER_U_CLAMP|BGFX_SAMPLER_V_CLAMP" then
      retval = "Bgfx::Sampler_U_Clamp|Bgfx::Sampler_V_Clamp"
   elseif arg_str == "TextureFormat::Count" then
      retval = "Bgfx::TextureFormat::Count"
   elseif arg_str == "BGFX_BUFFER_NONE" then
      retval = "Bgfx::Buffer_None"
   elseif arg_str == "BGFX_DISCARD_ALL" then
      retval = "Bgfx::Discard_All"
   elseif arg_str == "BGFX_RESET_NONE" then
      retval = "Bgfx::Reset_None"
   elseif arg_str == "BGFX_STENCIL_NONE" then
      retval = "Bgfx::Stencil_None"
   elseif arg_str == "RendererType::Noop" then
      retval = "Bgfx::RendererType::Noop"
   elseif arg_str == "INT32_MAX" then
      retval = "0x7fffffff"
   elseif arg_str == "UINT32_MAX" then
      retval = "0xffffffff"
   elseif arg_str == "UINT16_MAX" then
      retval = "0xffff"
   elseif arg_str == "UINT8_MAX" then
      retval = "0xff"
   elseif string.find(tostring(arg_str), "^[+-]?%d*%.?%d*f$") then
      _, _, num = string.find(tostring(arg_str), "^([+-]?%d*%.?%d*)f$")
      retval = num
   else
      retval = arg_str
   end

   return retval
end

----------------------------------------------------------------------------------------------------

function collect_typedefs_list(typ)
   -- Collect list of typedefs
   if typ.enum then
      local typedef_name = typ.cname:gsub("^%l", string.upper)
      table.insert(typedefs_list, typedef_name)
   end
end

function converter.typedefs(typ)
   -- Write typedefs
   if typ.enum then
      local typedef_name = typ.cname:gsub("^%l", string.upper)
      yield("FFI.typedef :int, :" .. typedef_name .. "\n")
   end
end

----------------------------------------------------------------------------------------------------

function converter.handles(typ)
   -- Build handle definitions
   if typ.handle then
      -- Extract handle
      ruby_class_name = typ.cname:gsub("bgfx_(%l)", function(a) return "Bgfx_" .. a end)
      yield("class " .. ruby_class_name .. " < FFI::Struct; layout(:idx, :ushort); end")
   end
end

----------------------------------------------------------------------------------------------------

function collect_methods_list(func)
   if func.this ~= nil then
      table.insert(methods_list, func)
   end
end

function converter.structs(typ)

   if typ.struct == nil then
      return
   end

   indent = "  "
   class_name = typ.cname:gsub("^%l", string.upper)
   yield("class " .. class_name .. " < FFI::Struct")

   -- Member variables
   yield(indent .. "layout(")
   if class_name == "Bgfx_encoder_t" then
      yield(indent .. indent .. ":opaque, :pointer # dummy")
   else
      for idx, member in ipairs(typ.struct) do
         local comments = ""
         if member.comment ~= nil then
            if #member.comment == 1 then
               comments = " # " .. member.comment[1]
            else
               yield("\n" .. indent .. indent .. "#")
               for _, comment in ipairs(member.comment) do
                  yield(indent .. indent .. "# " .. comment)
               end
               yield(indent .. indent .. "#")
            end
         end
         ret = indent .. indent .. convert_struct_member(member)
         if idx < #typ.struct then
            ret = ret .. "," .. comments
         else
            ret = ret .. comments
         end
         yield(ret)
      end
   end
   yield(indent .. ")")

   -- Instance methods
   struct_name_key = typ.cname:gsub("^bgfx_", ""):gsub("_t$", "") .. "_"
   for _, func in ipairs(methods_list) do
      if string.match(func.cname, "^" .. struct_name_key) ~= nil then
         method_name = func.cname:gsub("^" .. struct_name_key, "")

         local args = {}
         local args_with_defaults = {}
         for _, arg in ipairs(func.args) do
            table.insert(args, arg.name)
            if arg.default ~= nil then
               table.insert(args_with_defaults, arg.name .. " = " .. tostring(sanitize_default_argument(arg.default)) )
            else
               table.insert(args_with_defaults, arg.name)
            end
         end

         yield("\n" .. indent .. "def " .. method_name .. "(" .. table.concat(args_with_defaults, ", ") .. ")")
         if #args < 1 then
            yield(indent .. indent .. "Bgfx::bgfx_" .. func.cname .. "(self)")
         else
            yield(indent .. indent .. "Bgfx::bgfx_" .. func.cname .. "(self, " .. table.concat(args, ", ") .. ")")
         end
         yield(indent .. "end")
      end
   end
   yield("end")

end

----------------------------------------------------------------------------------------------------

function converter.types(typ)

   indent = "  "

   if hasSuffix(typ.name, "::Enum") then
      -- Extract enum
      yield(indent .. "module " .. typ.typename)
      for idx, enum in ipairs(typ.enum) do
         if enum.comment ~= nil then
            for _, comment in ipairs(enum.comment) do
               yield(indent .. indent .. "# " .. comment)
            end
         end
         yield(indent .. indent .. enum.name .. " = " .. idx - 1)
      end
      yield("\n" .. indent .. indent .. "Count = " .. #typ.enum)
      yield(indent .. "end # module " .. typ.typename)
   elseif typ.bits ~= nil then
      -- Extract bitflag / Build bitflag helper function
      local prefix = typ.name
      local enumType = "uint"
      format = "%u"
      if typ.bits == 64 then
         format = "0x%016x"
         enumType = "ulong"
      elseif typ.bits == 32 then
         format = "0x%08x"
         enumType = "uint"
      elseif typ.bits == 16 then
         format = "0x%04x"
         enumType = "ushort"
      elseif typ.bits == 8 then
         format = "0x%02x"
         enumType = "ubyte"
      end

      for idx, flag in ipairs(typ.flag) do
         local value = flag.value
         if value ~= nil then
            value = string.format(flag.format or format, value)
         else
            for _, name in ipairs(flag) do
               local fixedname = prefix .. "_" .. to_underscorecase(name)
               if value ~= nil then
                  value = value .. " | " .. fixedname
               else
                  value = fixedname
               end
            end
         end
         local comments = ""
         if flag.comment ~= nil then
            if #flag.comment == 1 then
               comments = " # " .. flag.comment[1]
            else
               yield(indent .. "#")
               for _, comment in ipairs(flag.comment) do
                  yield(indent .. "# " .. comment)
               end
               yield(indent .. "#")
            end
         end
         yield(indent .. to_underscorecase(prefix) .. "_" .. flag.name .. " = " .. value .. comments)
      end

      if typ.shift then
         local name = to_underscorecase(prefix) .. "_Shift"
         local value = typ.shift
         local comments = ""
         if typ.desc then
            comments = string.format(" # %s bit shift", typ.desc)
         end
         yield(indent .. name .. " = " .. value .. comments)
      end
      if typ.range then
         local name = to_underscorecase(prefix) .. "_Mask"
         local value = string.format(format, typ.mask)
         local comments = ""
         if typ.desc then
            comments = string.format(" # %s bit mask", typ.desc)
         end
         yield(indent .. name .. " = " .. value .. comments)
      end

      if typ.helper then
         yield(indent .. string.format(
                  "def self.%s(v); return (v << %s) & %s; end",
                  to_underscorecase(prefix),
                  (to_underscorecase(prefix) .. "_Shift"),
                  (to_underscorecase(prefix) .. "_Mask")))
      end
   end
end

----------------------------------------------------------------------------------------------------

function collect_attach_funcs(func)
   if func.cpponly then
      return
   end

   -- codes
   local args = {}
   if func.this ~= nil then
      local ctype = string.gsub(func.this_type.ctype, "const ", "") -- remove const
      ctype = ctype:gsub("%*$", "") -- remove *
      ctype = ctype:gsub("^%l", string.upper) -- upcase
      args[1] = ctype .. ".by_ref"
   end
   for _, arg in ipairs(func.args) do
      -- table.insert(args, convert_type(arg) .. " " .. convert_name(arg.name))
      local array_as_pointer = true
      table.insert(args, convert_type(arg, array_as_pointer))
   end

   entry_point = ":bgfx_" .. func.cname

   func_sym = entry_point
   func_arg = "[" .. table.concat(args, ", ") .. "]"
   func_ret = convert_type(func.ret)

   attach_func_symbols[func.cname] = func_sym
   attach_func_args[func_sym] = func_arg
   attach_func_retvals[func_sym] = func_ret
end

function converter.attachfunc_symbols(func)
   if func.cpponly then
      return
   end

   indent = "      "
   yield(indent .. attach_func_symbols[func.cname] .. ",\n")
end

function converter.attachfunc_args(func)
   if func.cpponly then
      return
   end

   indent = "      "
   entry_point = attach_func_symbols[func.cname]
   yield(indent .. entry_point .. " => " .. attach_func_args[entry_point] .. ",\n")
end

function converter.attachfunc_retvals(func)
   if func.cpponly then
      return
   end

   indent = "      "
   entry_point = attach_func_symbols[func.cname]
   yield(indent .. entry_point .. " => " .. attach_func_retvals[entry_point] .. ",\n")
end

----------------------------------------------------------------------------------------------------

function converter.module_funcs(func)

   if func.cpponly then
      return
   end

   if func.this ~= nil then
      return
   end

   indent = "  "

   if func.comments ~= nil then
      -- comments
      yield(indent .. "#")
      for _, line in ipairs(func.comments) do
         local line = line:gsub("@remarks", "Remarks:")
         line = line:gsub("@remark", "Remarks:")
         line = line:gsub("@(%l)(%l+)", function(a, b) return a:upper()..b..":" end)
         yield(indent .. "# " .. line)
      end

      local hasParamsComments = false
      for _, arg in ipairs(func.args) do
         if arg.comment ~= nil then
            hasParamsComments = true
            break
         end
      end

      if hasParamsComments then
         yield(indent .. "# Params:")
      end

      for _, arg in ipairs(func.args) do
         if arg.comment ~= nil then
            yield(indent .. "# " .. convert_name(arg.name) .. " = " .. arg.comment[1])
            for i, comment in ipairs(arg.comment) do
               if (i > 1) then
                  yield(indent .. "# " .. comment)
               end
            end
         end
      end

      yield(indent .. "#")
   end

   -- codes
   local args = {}
   local args_with_defaults = {}
   for _, arg in ipairs(func.args) do
      table.insert(args, arg.name)
      if arg.default ~= nil then
         table.insert(args_with_defaults, arg.name .. " = " .. tostring(sanitize_default_argument(arg.default)) )
      else
         table.insert(args_with_defaults, arg.name)
      end
   end
   -- for func.dbgTextPrintf { vararg = "dbgTextPrintfVargs" }. Explicitly replace last element with *varargs, or we got empty last argument
   if func.vararg ~= nil then
      args[#args] = "*vargargs"
      args_with_defaults[#args_with_defaults] = "*vargargs"
   end

   entry_point = "bgfx_" .. func.cname
   yield(indent .. "def self." .. func.cname .. "(" .. table.concat(args_with_defaults, ", ") .. ")")
   yield(indent .. indent .. "return " .. entry_point .. "(" .. table.concat(args, ", ") .. ")")
   yield(indent .. "end")
end

----------------------------------------------------------------------------------------------------

function gen.write(codes, outputfile)
   local out = assert(io.open(outputfile, "wb"))
   out:write(codes)
   out:close()
   print("Generating: " .. outputfile)
end

if (...) == nil then
   -- run `lua bindings-ruby.lua` in command line
   print(gen.gen())
end

return gen
