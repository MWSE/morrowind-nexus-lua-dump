local storageName = "MWR_By_Diject_Profiles"
local storage = require('openmw.storage').globalSection(storageName)
local tableLib = require("scripts.morrowind_world_randomizer.utils.table")

local this = {}

this.config = require("scripts.morrowind_world_randomizer.config.local")

---@type table<string, mwr.configData>
this.data = storage:asTable() or {}

this.protectedNames = {["default"] = true, ["extended"] = true, ["extended+"] = true,}

-- if not this.data["default"] then
    this.data["default"] = tableLib.deepcopy(this.config.default)
    storage:reset(this.data)
-- end

do
    local function updateRegionSettings(data)
        for name, var in pairs(data) do
            if name == "rregion" then
                if var.min < 50 then
                    var.min = 50
                end
                if var.max < 50 then
                    var.max = 50
                end
            elseif name == "vregion" then
                if data.additive then
                    var.min = var.min * 2
                    var.max = var.max * 2
                else
                    var.min = 0.25
                    var.max = 2
                end
            elseif name == "iregion" then
                var.max = var.max * 2
            elseif type(var) == "table" then
                updateRegionSettings(var)
            end
        end
    end

    ---@type mwr.configData
    local data = tableLib.deepcopy(this.config.default)
    updateRegionSettings(data)
    data.item.new.linkIconToModel = false
    data.creature.byType = false
    this.data["extended"] = data

    storage:reset(this.data)
end

do
    local function updateRegionSettings(data)
        for name, var in pairs(data) do
            if name == "rregion" then
                var.min = 100
                var.max = 100
            elseif name == "vregion" then
                if data.additive then
                    var.min = var.min * 3
                    var.max = var.max * 3
                else
                    var.min = 0.1
                    var.max = 2.5
                end
            elseif name == "iregion" then
                var.max = var.max * 3
            elseif type(var) == "table" then
                updateRegionSettings(var)
            end
        end
    end

    ---@type mwr.configData
    local data = tableLib.deepcopy(this.config.default)
    updateRegionSettings(data)
    data.item.new.linkIconToModel = false
    data.world.static.tree.typesPerCell = 5
    data.world.static.rock.typesPerCell = 5
    data.world.herb.typesPerCell = 10
    data.world.herb.item.randomize = true
    data.npc.stat.attributes.additive = true
    data.npc.stat.attributes.vregion.min = -100
    data.npc.stat.attributes.vregion.max = 100
    data.npc.spell.bySkill = true
    data.npc.spell.bySchool = false
    data.npc.spell.add.levelReference = 1
    data.npc.spell.add.count = 5
    data.creature.byType = false
    data.creature.onlyLeveled = false
    data.creature.spell.add.levelReference = 1
    data.creature.spell.add.count = 5
    data.item.safeMode = false
    data.item.new.chance = 50


    this.data["extended+"] = data
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