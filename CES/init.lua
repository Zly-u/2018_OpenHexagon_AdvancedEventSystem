local curPath = (...) and (...):gsub("%.init$", "").."/" or ""
require(curPath.."/utils")

local _module = {
    files = {
        --Main Scripts
        curPath.."CES",
    },

    modules = {}
}
local module
for _, file in ipairs(_module.files) do
    module = require(file)
end

return module
