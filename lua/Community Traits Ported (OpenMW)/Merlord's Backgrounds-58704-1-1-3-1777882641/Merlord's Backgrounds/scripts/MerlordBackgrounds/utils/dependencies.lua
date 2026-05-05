---@diagnostic disable: duplicate-doc-field
local core = require("openmw.core")
local I = require("openmw.interfaces")

local deps = {}

---@class Dependency
---@field plugin      string   esp/omwaddon/omwscripts filename of the required plugin
---@field interface   any      The interface object retrieved from the other mod
---@field minVersion  number|nil
---@field curVersion  number|nil

---@param dep  Dependency
---@return     boolean, string|nil
local function checkDependency(dep)
    local checks = {
        {
            ok  = core.contentFiles.has(dep.plugin:lower()),
            msg = ("'%s' dependency not found."):format(dep.plugin)
        },
        {
            ok  = dep.interface ~= nil,
            msg = ("'%s' has to be loaded before this mod."):format(dep.plugin)
        },
        {
            ok  = not dep.minVersion or dep.curVersion >= dep.minVersion,
            msg = ("'%s' version too low. Required %s, found %s.")
                :format(dep.plugin, tostring(dep.minVersion), tostring(dep.curVersion))
        },
    }
    for _, c in ipairs(checks) do
        if not c.ok then
            return false, c.msg
        end
    end
    return true
end

---@param modName  string
---@param depList  Dependency[]
deps.checkAll = function(modName, depList)
    local errors = {}
    for _, dep in ipairs(depList) do
        local ok, msg = checkDependency(dep)
        if not ok then
            errors[#errors + 1] = msg
        end
    end
    if #errors > 0 then
        local msg = ("[%s]\nDependency error.\n\n%s\n"):format(modName, table.concat(errors, "\n\n"))
        I.UI.showInteractiveMessage(msg)
    end
end

return deps
