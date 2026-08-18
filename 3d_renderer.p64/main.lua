
local _modules = {}

function require(name)
    local prefix = split(name, '.')[1]
    if _modules[name] == nil then
        local src_name = name:gsub('%.', '/') .. '.lua'
        _modules[name] = include(src_name)
    end
    return _modules[name]
end

DATP = ""
--DATP = "3d_renderer.p64/"
cp("/desktop/projects/3d-renderer/src", "src")
cp("/desktop/projects/3d-renderer/lib", "lib")

include "src/main.lua"

include "lib/profiler.lua"

include "lib/error_explorer.lua"
