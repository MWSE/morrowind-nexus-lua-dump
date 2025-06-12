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
local settings = require("scripts.ErnSunderRandomizer.settings")
local core = require("openmw.core")
local world = require("openmw.world")
local storage = require("openmw.storage")
local clue = require("scripts.ErnSunderRandomizer.clue")
local types = require("openmw.types")
local common = require("scripts.ErnSunderRandomizer.common")

if require("openmw.core").API_REVISION < 62 then
    error("OpenMW 0.49 or newer is required!")
end

common.initCommon()

-- Init settings first to init storage which is used everywhere.
settings.initSettings()

local function saveState()
    return common.stepTable:asTable()
end

local function loadState(saved)
    common.stepTable:reset(saved)
end

-- data.actor is the current posssessor
-- data.itemRecordID is the item to hide.
local function hideItem(data)
    settings.debugPrint("hideItem started")

    -- input validation
    actor = data.actor
    if actor == nil then
        error("hideItem handler passed in nil actor")
        return
    end
    itemInstance = data.itemInstance
    itemRecord = itemInstance.type.record(itemInstance)
    if itemRecord == nil then
        error("hideItem handler passed in nil itemRecord")
        return
    end

    itemRecord = itemInstance.type.record(itemInstance)
    -- apologize for the frame drops
    -- this could be hidden with a coroutine that is resumed every frame,
    -- but this just happens once per playthrough. don't bother.
    for _, player in ipairs(world.players) do
        player:sendEvent("LMshowHideMessage", {
            itemName = itemRecord.name,
        })
    end

    -- find treasure
    dvInventory = types.Actor.inventory(actor)
    treasureInstance = dvInventory:find(itemRecord.id)
    if treasureInstance == nil then
        error("possesor doesn't have " .. itemRecord.id)
        return
    end

    -- build clue chain
    totalSteps = settings.stepCount()
    chain = clue.getChain(totalSteps)
    if chain == nil then
        error("failed to create chain")
        return
    end

    -- put actor at start of chain.
    table.insert(chain, 1, {
        cell=nil,
        npc=actor,
    })

    -- mark so we don't hide this again
    common.markAsHidden(actor, itemInstance)

    for i, step in ipairs(chain) do
        settings.debugPrint(i .. "/" .. totalSteps)
        if i == totalSteps then
            settings.debugPrint(i .. " moving " .. itemRecord.id .. " to " .. step.npc.id)
            -- last in the chain. move item here.
            inventory = types.Actor.inventory(step.npc)
            treasureInstance:moveInto(inventory)
        elseif i < totalSteps then
            -- each npc should have a clue pointing to the next.
            local nextStep = chain[i+1]
            settings.debugPrint(i .. " placing clue for " .. nextStep.npc.recordId)
            noteRecord = clue.createClueRecord(i, itemRecord, nextStep.cell, nextStep.npc)
            noteInstance = world.createObject(noteRecord.id)
            noteInstance:moveInto(step.npc)
        else
            break
        end
    end
end

return {
    eventHandlers = {
        LMhideItem = hideItem
    },
    engineHandlers = {
        onSave = saveState,
        onLoad = loadState
    }
}
