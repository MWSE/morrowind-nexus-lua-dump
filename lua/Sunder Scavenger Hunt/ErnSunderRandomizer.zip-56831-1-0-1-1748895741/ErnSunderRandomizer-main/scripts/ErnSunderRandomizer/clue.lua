--[[
ErnSunderRandomizer for OpenMW.
Copyright (C) 2025 Erin Pentecost

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
local world = require("openmw.world")
local types = require("openmw.types")
local settings = require("scripts.ErnSunderRandomizer.settings")
local core = require("openmw.core")
local localization = core.l10n(settings.MOD_NAME)

-- getCellName returns the name of the cell or nil, if the name can't be determined.
local function getCellName(cell)
    -- Don't know how to get localized cell names.
    location = cell.name
    if (location == nil or location == "") then
        if cell.gridX and cell.gridY then
            index = tostring(cell.gridX) .. ", " .. tostring(cell.gridY)
            location = localization(index)
            if location == index then
                -- failed to get a good name for the cell, so just drop it.
                return nil
            end
            settings.debugPrint("cell rename " .. index .. " -> " .. location)
        end
    end
    return location
end

local function filterCell(cell)
    name = getCellName(cell)
    if (name == nil) or (name == "") then
        return false
    end
    if string.find(string.lower(name), ".*test.*") ~= nil then
        return false
    end
    if string.find(string.lower(name), ".*_.*") ~= nil then
        return false
    end
    return true
end

local function filterNPC(npc)
    -- Try to get named NPCs that won't reset.
    rec = types.NPC.record(npc)
    return (string.lower(rec.class) ~= "guard") and
        (rec.isEssential ~= true) and
        (rec.isRespawning ~= true) and
        (types.Actor.isDead(npc) ~= true)
end

local function getRandomNPCinCell(cell)
    listSize = 0
    asList = {}
    for _, npc in ipairs(cell:getAll(types.NPC)) do
        if filterNPC(npc) then
            listSize = listSize + 1
            table.insert(asList, npc)
        end
    end

    if listSize == 0 then
        return nil
    end

    randIndex = math.random(1, listSize)
    return asList[randIndex]
end

-- getChain returns a list of {cell=cell,npc=npcInstance} of length steps.
-- Each step will have a unique cell.
local function getChain(steps)
    subset = {}
    subsetSize = 0
    for _, cell in ipairs(world.cells) do
        if filterCell(cell) then
            holder = getRandomNPCinCell(cell)
            if holder ~= nil then
                --settings.debugPrint(getCellName(cell) .. " -> " .. types.NPC.record(holder).id)
                subsetSize = subsetSize + 1
                -- end of table is n+1, where n is length of table
                randIndex = math.random(1, subsetSize)
                table.insert(subset, randIndex, {cell=cell,npc=holder})
            end
        end
    end

    -- subset is now a maximum-length, randomized chain
    settings.debugPrint("Found " .. subsetSize .. " potential steps in the chain.")

    if subsetSize < steps then
        error("want " .. steps .. " steps, but found only " .. subsetSize .. " valid steps.")
        return nil
    end

    -- return first "steps" elements in subset.
    output = {}
    count = 0
    for i, step in ipairs(subset) do
        recId = types.NPC.record(step.npc).id
        settings.debugPrint(tostring(i) .. ": " .. recId .. " in " .. getCellName(step.cell))
        table.insert(output, step)
        count = count + 1
        if count == steps then
            return output
        end
    end
    error("failed to get correct number of steps")
    return nil
end


local function createClueRecord(number, itemRecord, cell, npcInstance)
    cellName = getCellName(cell)
    npcName = types.NPC.record(npcInstance).name
    recordFields = {
        enchant = nil,
        enchantCapacity = 0,
        icon = "icons\\m\\tx_parchment_02.dds",
        isScroll = true,
        model = "meshes\\m\\text_parchment_02.nif",
        name = localization("clue_name", {number=number, itemName=itemRecord.name}),
        skill = nil,
        text = localization("clue_body", {itemName=itemRecord.name, npc=npcName, location=location}),
    }
    settings.debugPrint(recordFields.text)
    draftRecord = types.Book.createRecordDraft(recordFields)
    return world.createRecord(draftRecord)
end

return {
    getChain = getChain,
    createClueRecord = createClueRecord,
}