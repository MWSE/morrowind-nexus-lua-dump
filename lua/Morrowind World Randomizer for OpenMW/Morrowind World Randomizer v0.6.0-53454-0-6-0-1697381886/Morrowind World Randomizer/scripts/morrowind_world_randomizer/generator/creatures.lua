local types = require('openmw.types')
local world = require('openmw.world')
local log = require("scripts.morrowind_world_randomizer.utils.log")
local generatorData = require("scripts.morrowind_world_randomizer.generator.data")

local this = {}

---@class mwr.creatureParameters
---@field type number|nil
---@field pos number|nil

---@class mwr.creaturesData
---@field objects table<string, mwr.creatureParameters>
---@field groups table<string>

local function checkRequirements(record)
    local id = record.id:lower()
    if not generatorData.forbiddenIds[id] and (generatorData.scriptWhiteList[id] or record.mwscript == "") and
            not generatorData.forbiddenModels[record.model] and not id:find("summon") and not id:find("dead") then
        return true
    end
    return false
end

---@param safeMode boolean
---@return mwr.creaturesData
function this.generateCreatureData(safeMode)
    ---@type mwr.creaturesData
    local out = {objects = {}, groups = {}}

    local tempGroups = {}
    if not safeMode then
        for _, record in pairs(types.Creature.records) do
            local id = record.id:lower()
            if checkRequirements(record) then

                if not tempGroups[record.type] then tempGroups[record.type] = {} end
                table.insert(tempGroups[record.type], {id = id, soul = record.soulValue})
            end
        end
    else
        local tempData = {}
        for _, cell in pairs(world.cells) do
            local levLists = cell:getAll() or {}
            for _, levList in pairs(levLists) do
                if levList.type == types.LevelledCreature then
                    local record = types.LevelledCreature.record(levList)
                    local recordId = record.id:lower()
                    if not tempData[recordId] then
                        tempData[recordId] = {creatures = record.creatures, count = 1}
                    else
                        tempData[recordId].count = tempData[recordId].count + 1
                    end
                elseif levList.type == types.Creature or levList.type == types.NPC or levList.type == types.Container then
                    local recordId = levList.recordId:lower()
                    if not tempData[recordId] then
                        tempData[recordId] = {creatures = {{id = recordId}}, count = 1}
                    else
                        tempData[recordId].count = tempData[recordId].count + 1
                    end
                end
            end
        end
        local function findCreature(creaList, grp, cnt)
            if not creaList then return end
            for _, crea in pairs(creaList) do
                local id = crea.id:lower()
                local record = types.LevelledCreature.record(id)
                if record then
                    findCreature(record.creatures, grp, cnt)
                else
                    if grp[id] then
                        grp[id] = grp[id] + cnt
                    else
                        grp[id] = cnt
                    end
                end
            end
        end
        local creaTable = {}
        for _, data in pairs(tempData) do
            findCreature(data.creatures, creaTable, data.count)
        end
        for _, crea in pairs(types.Creature.records) do
            local id = crea.id:lower()
            if creaTable[id] and checkRequirements(crea) then
                if not tempGroups[crea.type] then tempGroups[crea.type] = {} end
                table.insert(tempGroups[crea.type], {id = id, soul = crea.soulValue})
            end
        end
    end

    for i, tb in pairs(tempGroups) do
        table.sort(tb, function(a, b) return a.soul < b.soul end)
    end

    for groupId, group in pairs(tempGroups) do
        for i, data in pairs(group) do
            out.objects[data.id] = {type = groupId, pos = i}
            if not out.groups[groupId] then out.groups[groupId] = {} end
            table.insert(out.groups[groupId], data.id)
        end
    end

    for i, data in pairs(out.groups) do
        log("Creature data", i, #data)
    end

    return out
end

return this