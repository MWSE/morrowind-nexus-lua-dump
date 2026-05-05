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

-- This file is in charge of tracking and exposing path information.
-- Interact with it via the interface it exposes.

local MOD_NAME        = require("scripts.ErnDebt.ns")
local mwvars          = require("scripts.ErnDebt.mwvars")
local gearup          = require("scripts.ErnDebt.gearup")
local world           = require("openmw.world")
local types           = require("openmw.types")
local util            = require("openmw.util")
local aux_util        = require('openmw_aux.util')

local collectorScript = "scripts\\ErnDebt\\debtcollector.lua"
local bodyguardScript = "scripts\\ErnDebt\\bodyguard.lua"

local function newDebtCollector(data, recordId, guardRecordIds)
    -- update mw vars from lua.
    world.mwscript.getGlobalVariables(data.player)[mwvars.erncurrentdebt] = data.currentDebt
    world.mwscript.getGlobalVariables(data.player)[mwvars.erncollectorskilled] = data.collectorsKilled
    world.mwscript.getGlobalVariables(data.player)[mwvars.erncurrentpaymentskipstreak] = data.currentPaymentSkipStreak
    world.mwscript.getGlobalVariables(data.player)[mwvars.erndebtminimumpayment] = data.minPayment

    world.mwscript.getGlobalVariables(data.player)[mwvars.erncurrentdebtcanpay] = (data.playerGold >= data.currentDebt) and
        1 or 0
    world.mwscript.getGlobalVariables(data.player)[mwvars.erndebtminimumpaymentcanpay] = (data.playerGold >= data.minPayment) and
        1 or 0

    print(aux_util.deepToString(data, 4))

    -- make the npc
    print("Spawning new debt collector " .. recordId .. " at " .. data.cellId .. ": " .. tostring(data.position) .. ".")
    local new = world.createObject(recordId, 1)

    local npcs = { new }
    data.guards = {}
    for _, id in ipairs(guardRecordIds) do
        local newGuard = world.createObject(id, 1)
        newGuard:addScript(bodyguardScript, { collector = new, player = data.player })
        newGuard:teleport(world.getCellById(data.cellId),
            util.vector3(data.position.x + math.random(30) - 15, data.position.y + math.random(30) - 15, data.position.z),
            {
                onGround = true,
            })
        table.insert(npcs, newGuard)
        table.insert(data.guards, newGuard)
    end

    new:addScript(collectorScript, data)

    -- move the collector
    new:teleport(world.getCellById(data.cellId),
        util.vector3(data.position.x + math.random(30) - 15, data.position.y + math.random(30) - 15, data.position.z),
        {
            onGround = true,
        })

    local pcLevel = types.Actor.stats.level(data.player).current
    gearup.gearupNPCs(npcs, pcLevel + data.collectorsKilled)
end

local function onCollectorSpawn(data)
    local guards = (data.collectorsKilled > 0) and { "erndebt_bodyguard" } or {}
    newDebtCollector(data, "erndebt_collector", guards)
end

local function onCollectorDespawn(data)
    data.npc:removeScript(collectorScript)
    if not data.dead then
        -- remove the collector if not dead
        data.npc.enabled = false
        data.npc:remove()
    end
    if not data.expired then
        -- pass through if we paid some debt. mwscript must set this value.
        data.justPaidAmount = world.mwscript.getGlobalVariables(data.player)[mwvars.ernjustpaidamount]
        data.player:sendEvent(MOD_NAME .. "onCollectorDespawn", data)
        world.mwscript.getGlobalVariables(data.player)[mwvars.ernjustpaidamount] = 0
    end
end

local function onBodyguardDespawn(data)
    data.npc:removeScript(bodyguardScript)
    if not data.dead then
        -- remove the collector if not dead
        data.npc.enabled = false
        data.npc:remove()
    end
end

local function onActivate(object, actor)
    if not types.Player.objectIsInstance(actor) then
        return
    end
    if not types.Door.objectIsInstance(object) then
        return
    end
    if not types.Door.isTeleport(object) then
        return
    end
    if types.Lockable.isLocked(object) then
        return
    end
    local destCell = types.Door.destCell(object)
    if (destCell ~= nil) and
        (destCell.isExterior or destCell:hasTag("QuasiExterior")) then
        -- The player is leaving an internal cell and entering an exterior cell.
        actor:sendEvent(MOD_NAME .. "onExitingInterior", { door = object })
    end
end

return {
    eventHandlers = {
        [MOD_NAME .. "onCollectorSpawn"] = onCollectorSpawn,
        [MOD_NAME .. "onCollectorDespawn"] = onCollectorDespawn,
        [MOD_NAME .. "onBodyguardDespawn"] = onBodyguardDespawn,
    },
    engineHandlers = {
        onActivate = onActivate
    }
}
