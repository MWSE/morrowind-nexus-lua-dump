--[[
ErnSameHat for OpenMW.
Copyright (C) Erin Pentecost 2026

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

-- This file is in charge of tracking and exposing path information.
-- Interact with it via the interface it exposes.

local MOD_NAME = require("scripts.ErnSameHat.ns")
local types    = require('openmw.types')
local core     = require('openmw.core')
local pself    = require("openmw.self")

local persist  = {}

local function getHat(actor)
    local helmet = actor.type.getEquipment(actor, types.Actor.EQUIPMENT_SLOT.Helmet)
    if not helmet then
        return nil
    end
    local helmetRecord = helmet.type.record(helmet)
    return helmetRecord.model
end

local talkModes = {
    Enchanting = true,
    Training = true,
    MerchantRepair = true,
    Companion = true,
    SpellBuying = true,
    Barter = true,
    Dialogue = true,
}

local function apply(npc)
    core.sendGlobalEvent(MOD_NAME .. "onSameHatStart", {
        player = pself,
        npc = npc,
        -- only apply the bonus once, ever.
        applyBonus = persist[npc.id] == nil,
    })
    persist[npc.id] = true
end
local function remove(npc)
    --print("Not same hat.")
    core.sendGlobalEvent(MOD_NAME .. "onSameHatEnd", {
        player = pself,
        npc = npc,
    })
end

local function UiModeChanged(data)
    --print(tostring(data.newMode) .. " - " .. tostring(data.arg))
    if not data.newMode then
        --print("Done talking.")
        remove(data.npc)
    end
    if talkModes[data.newMode] and data.arg then
        local myHat = getHat(pself)
        local theirHat = getHat(data.arg)
        -- Same hat!
        local sameHat = myHat == theirHat
        if sameHat then
            apply(data.arg)
        else
            remove(data.npc)
        end
    end
end

local function onLoad(data)
    if data then
        persist = data
    end
end
local function onSave()
    return persist
end

return {
    eventHandlers = {
        UiModeChanged = UiModeChanged,
        onLoad = onLoad,
        onSave = onSave,
    },
}
