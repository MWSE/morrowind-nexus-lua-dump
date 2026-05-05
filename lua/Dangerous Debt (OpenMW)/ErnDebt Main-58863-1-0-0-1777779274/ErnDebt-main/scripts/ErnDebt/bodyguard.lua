--[[
ErnDebt for OpenMW.
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

local MOD_NAME   = require("scripts.ErnDebt.ns")
local interfaces = require("openmw.interfaces")
local pself      = require("openmw.self")

local guardData  = {}

local function onInit(initData)
    print("Bodyguard " .. pself.recordId .. " initialized.")
    if initData ~= nil then
        guardData = initData
    end
end
local function onLoad(data)
    if data then
        guardData = data
    end
end
local function onSave()
    return guardData
end

local function onActive()
    print("Bodyguard " .. pself.recordId .. " is active.")
    -- Adjust dispo and fight
    pself.type.stats.ai.fight(pself).base = 70
    local startDisposition = pself.type.getBaseDisposition(pself, guardData.player)
    pself.type.modifyBaseDisposition(pself, guardData.player, 30 - startDisposition)
    -- Remove AI so we have full control
    interfaces.AI.removePackages()
    interfaces.AI.startPackage({
        type = "Wander",
        distance = 300,
        target = guardData.collector,
        cancelOther = true,
        isRepeat = true
    })
end

local function onEquip(data)
    pself.type.setEquipment(pself, data)
end

return {
    eventHandlers = {
        [MOD_NAME .. "onEquip"] = onEquip,
    },
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
        onSave = onSave,
        onActive = onActive,
    },
}
