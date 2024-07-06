local types = require('openmw.types')
local core = require('openmw.core')
local log = require("scripts.morrowind_world_randomizer.utils.log")
local generatorData = require("scripts.morrowind_world_randomizer.generator.data")
local spellLib = require("scripts.morrowind_world_randomizer.utils.spell")

local this = {}

---@class mwr.spellParameters
---@field type string
---@field pos number
---@field schPoss table<number, number>

---@class mwr.spellsData
---@field objects table<string, mwr.spellParameters>
---@field groups table<string, table<string, any>>

---@return mwr.spellsData
function this.generateSpellData()
    ---@type mwr.spellsData
    local out = {objects = {}, groups = {}}

    local temp = {}

    for  _, spell in pairs(core.magic.spells.records) do
        local id = spell.id:lower()
        if not generatorData.forbiddenIds[id] then
            local cost = 0
            local effectSchools = {}
            local isTargetHarm = false
            local forTrap = true
            for _, eff in pairs(spell.effects) do
                if eff.effect.school then
                    effectSchools[eff.effect.school] = true
                end
                cost = cost + spellLib.calculateEffectCost(eff)
                if eff.effect.harmful and (eff.range == 1 or eff.range == 2) then
                    isTargetHarm = true
                end
                if forTrap and eff.range ~= 1 then
                    forTrap = false
                end
            end
            table.insert(temp, {id = id, cost = cost, type = spell.type, effectSchools = effectSchools, isTargetHarm = isTargetHarm,
                forTrap = forTrap})
        end
    end

    table.sort(temp, function(a, b) return a.cost < b.cost end)

    local curPos = {}

    for _, data in pairs(temp) do
        local id = data.id
        if not curPos[data.type] then curPos[data.type] = {["all"] = 0} end
        local posArr = curPos[data.type]
        posArr.all = posArr.all + 1
        if not out.groups[data.type] then out.groups[data.type] = {["all"] = {}, ["trapHarm"] = {}} end
        local group = out.groups[data.type]
        local schoolData = {}
        for school, _ in pairs(data.effectSchools) do
            if not posArr[school] then posArr[school] = 0 end
            posArr[school] = posArr[school] + 1
            if not schoolData[school] then
                schoolData[school] = posArr[school]
                if not group[school] then group[school] = {} end
                table.insert(group[school], id)
            end
        end
        out.objects[id] = {type = data.type, pos = posArr.all, schPoss = schoolData}
        table.insert(group.all, id)
        if data.forTrap and data.isTargetHarm then table.insert(out.groups[data.type]["trapHarm"], id) end
    end

    return out
end

return this