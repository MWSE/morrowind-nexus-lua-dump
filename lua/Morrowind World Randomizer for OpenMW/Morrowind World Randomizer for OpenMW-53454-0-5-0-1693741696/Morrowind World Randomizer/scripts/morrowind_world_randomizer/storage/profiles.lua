local storageName = "MWR_By_Diject_Profiles"
local storage = require('openmw.storage').globalSection(storageName)
local tableLib = require("scripts.morrowind_world_randomizer.utils.table")

local this = {}

this.config = require("scripts.morrowind_world_randomizer.config.local")

---@type table<string, mwr.configData>
this.data = storage:asTable() or {}

this.protectedNames = {["default"] = true,}

if not this.data["default"] then
    this.data["default"] = tableLib.deepcopy(this.config.default)
    storage:reset(this.data)
end

function this.saveProfile(name, config)
    if not name or name == "" then return false end
    name = name:lower()
    if this.protectedNames[name] then return false end
    if not config then config = this.config end
    this.data[name] = tableLib.deepcopy(config.data)
    storage:reset(this.data)
    return true
end

function this.loadProfile(name, config)
    if not name or name == "" or not this.data[name] then return false end
    name = name:lower()
    if not config then config = this.config end
    config.loadData(this.config.default)
    config.loadData(this.data[name])
    return true
end

function this.deleteProfile(name)
    if not name or name == "" or not this.data[name] then return false end
    name = name:lower()
    this.data[name] = nil
    storage:reset(this.data)
    return true
end

function this.getProfileNames()
    local res = {}
    for name, _ in pairs(this.data) do
        table.insert(res, name)
    end
    table.sort(res, function(a, b) return a:upper() < b:upper() end)
    return res
end

return this