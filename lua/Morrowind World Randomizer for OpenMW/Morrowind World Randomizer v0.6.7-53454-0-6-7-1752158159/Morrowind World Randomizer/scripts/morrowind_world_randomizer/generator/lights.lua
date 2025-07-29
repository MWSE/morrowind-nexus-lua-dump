local generatorData = require("scripts.morrowind_world_randomizer.generator.data")

local this = {}

local Light = require('openmw.types').Light

---@class mwr.lightParameters
---@field group string

---@class mwr.lightsData
---@field objects table<string, mwr.lightParameters>
---@field groups table<string, table<string>>

function this.generateData()
    ---@type mwr.lightsData
    local out = {groups = {}, objects = {}}

    local temp = {}
    for _, light in pairs(Light.records) do
        if not generatorData.forbiddenModels[light.model:lower()] then
            local id = light.id:lower()
            table.insert(temp, {object = light, id = id, color = light.color, colorStr = light.color:asHex(), haveModel = light.model ~= "meshes\\", canCarry = light.isCarriable})
        end
    end
    table.sort(temp, function(a, b) return a.colorStr < b.colorStr end)
    out.groups["0"] = {}
    out.groups["1"] = {}
    out.groups["2"] = {}
    for i, data in ipairs(temp) do
        if not data.haveModel then
            table.insert(out.groups["0"], data.id)
            out.objects[data.id] = {group = "0"}
        elseif data.canCarry then
            if not generatorData.forbiddenIcons[data.object.icon:lower()] then
                table.insert(out.groups["1"], data.id)
                out.objects[data.id] = {group = "1"}
            end
        else
            table.insert(out.groups["2"], data.id)
            out.objects[data.id] = {group = "2"}
        end
    end
    return out
end

return this