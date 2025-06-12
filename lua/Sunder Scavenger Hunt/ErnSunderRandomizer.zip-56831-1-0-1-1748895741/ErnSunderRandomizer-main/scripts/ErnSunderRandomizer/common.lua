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

local core = require("openmw.core")
local storage = require("openmw.storage")
local types = require("openmw.types")
local settings = require("scripts.ErnSunderRandomizer.settings")
local stepTable = storage.globalSection(settings.MOD_NAME .. "StepTable")


local function initCommon()
    stepTable:setLifeTime(storage.LIFE_TIME.Temporary)
end

local function hideItemOnce(actor, itemRecordID)
    settings.debugPrint("hideItemOnce called for " .. actor.id .. " with item " .. itemRecordID)

    -- don't repeat work.
    if stepTable:get("huntActive_" .. itemRecordID) == true then
        settings.debugPrint("Already hid " .. itemRecordID .. ", so skipping.")
        return
    end

    -- does actor even have the item?
    itemInstance = types.Actor.inventory(actor):find(itemRecordID)
    if itemInstance == nil then
        error("actor " .. types.NPC.record(self).id .. " doesn't have " .. itemRecordID)
        return
    end

    -- send event
    core.sendGlobalEvent("LMhideItem", {
        actor = actor,
        itemInstance = itemInstance,
    })
end

local function markAsHidden(actor, itemInstance)
    -- mark as done
    stepTable:set("huntActive_" .. itemInstance.type.record(itemInstance).id, true)
end

return {
    initCommon = initCommon,
    hideItemOnce = hideItemOnce,
    markAsHidden = markAsHidden,
    stepTable = stepTable,
}