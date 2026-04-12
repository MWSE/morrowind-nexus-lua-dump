local types = require("openmw.types")
local core = require("openmw.core")
local world = require("openmw.world")
local async = require("openmw.async")
local util  = require("openmw.util")
local pickup = require("scripts.wdisarm_pickup")

local shared   = require("scripts.wdisarm_shared")
local DEFAULTS = shared.DEFAULTS

local cachedSettings = {
    MOD_ENABLED          = DEFAULTS.MOD_ENABLED,
    DISARM_NPCS          = DEFAULTS.DISARM_NPCS,
    DISARM_CREATURES     = DEFAULTS.DISARM_CREATURES,
    BASE_CHANCE          = DEFAULTS.BASE_CHANCE,
    STR_AGI_FACTOR       = DEFAULTS.STR_AGI_FACTOR,
    MAX_CHANCE           = DEFAULTS.MAX_CHANCE,
    PLAYER_CHANCE_MULT   = DEFAULTS.PLAYER_CHANCE_MULT,
    CHARGE_THRESHOLD     = DEFAULTS.CHARGE_THRESHOLD,
    WEIGHT_CHECK_ENABLED = DEFAULTS.WEIGHT_CHECK_ENABLED,
    WEIGHT_THRESHOLD     = DEFAULTS.WEIGHT_THRESHOLD,
    SHIELD_PROTECTS      = DEFAULTS.SHIELD_PROTECTS,
    NPC_PICKUP_ENABLED   = DEFAULTS.NPC_PICKUP_ENABLED,
    NPC_PICKUP_CHANCE    = DEFAULTS.NPC_PICKUP_CHANCE,
    PICKUP_RADIUS        = DEFAULTS.PICKUP_RADIUS,
    PICKUP_DELAY         = DEFAULTS.PICKUP_DELAY,
    DAMAGE_THRESHOLD     = DEFAULTS.DAMAGE_THRESHOLD,
    SKILL_THRESHOLD      = DEFAULTS.SKILL_THRESHOLD,
    CREATURE_COMBAT_MULT = DEFAULTS.CREATURE_COMBAT_MULT,
}

local droppedWeapons = {}
local refusedNpcs = {}
local processing = {}

return {
    eventHandlers = {
        Disarm_SettingsUpdated = function(data)
            cachedSettings = data
            for _, actor in ipairs(world.activeActors) do
                if actor:hasScript("scripts/wdisarm_npc.lua") then
                    actor:sendEvent("Disarm_SettingsUpdated", data)
                end
            end
        end,
        Disarm_NpcActivated = function(data)
            if data.npc and data.npc:isValid() then
                data.npc:sendEvent("Disarm_SettingsUpdated", cachedSettings)
            end
        end,

        Disarm_DoDisarm = function(data)
            if not data or not data.victim or not data.victim:isValid() then return end
            local victim   = data.victim
            local isPlayer = data.isPlayer or false

            local eqTable = types.Actor.getEquipment(victim)
            if not eqTable then return end
            local weapon = eqTable[types.Actor.EQUIPMENT_SLOT.CarriedRight]
            if not weapon or not weapon:isValid() then return end
            if not types.Weapon.objectIsInstance(weapon) then return end
            if weapon.recordId:find("^bound_") then return end

            local pos     = victim.position
            local dropped = weapon:split(1)
            dropped:teleport(victim.cell, util.vector3(pos.x, pos.y, pos.z + 10))
            local sound = shared.WEAPON_SOUND[types.Weapon.record(weapon).type]
            if sound then
                core.sound.playSound3d(sound:gsub(" Up$", " Down"), victim)
            end
            if isPlayer then
                droppedWeapons[dropped] = true
                return
            end

            async:newUnsavableSimulationTimer(cachedSettings.PICKUP_DELAY, function()
                if not dropped:isValid() then return end
                if not victim:isValid() or types.Actor.isDead(victim) then return end
                if (dropped.position - victim.position):length() > cachedSettings.PICKUP_RADIUS then return end
                if dropped.cell == nil then return end
                droppedWeapons[dropped] = nil
                refusedNpcs = {}
                local rec = types.Weapon.record(dropped)
                if dropped.cell == nil then return end
                local pickupSound = rec and shared.WEAPON_SOUND[rec.type]
                if pickupSound then core.sound.playSound3d(pickupSound, victim) end
                dropped:moveInto(types.Actor.inventory(victim))
                victim:sendEvent("Disarm_Reequip", { weapon = dropped })
            end)
        end,

        Disarm_CheckPickup = function(data)
            if not cachedSettings.NPC_PICKUP_ENABLED then return end
            if not data or not data.npc or not data.npc:isValid() then return end
            if not types.NPC.objectIsInstance(data.npc) then return end

            async:newUnsavableSimulationTimer(0.2, function()
                if not data.npc:isValid() then return end
                local npc = data.npc
                local npcId = npc.id

                local closest = nil
                local closestDist = math.huge
                for dropped, _ in pairs(droppedWeapons) do
                    if dropped:isValid() and dropped.cell ~= nil then
                        if not processing[dropped.id] and not (refusedNpcs[npcId] and refusedNpcs[npcId][dropped.id]) then
                            local dist = (dropped.position - npc.position):length()
                            if dist < cachedSettings.PICKUP_RADIUS and dist < closestDist then
                                closest = dropped
                                closestDist = dist
                            end
                        end
                    else
                        droppedWeapons[dropped] = nil
                    end
                end

                if not closest then return end

                if not pickup.shouldPickup(npc, closest, cachedSettings.NPC_PICKUP_CHANCE, cachedSettings.DAMAGE_THRESHOLD, cachedSettings.SKILL_THRESHOLD) then
                    if not refusedNpcs[npcId] then refusedNpcs[npcId] = {} end
                    refusedNpcs[npcId][closest.id] = true
                    return
                end

                processing[closest.id] = true
                droppedWeapons[closest] = nil
                async:newUnsavableSimulationTimer(cachedSettings.PICKUP_DELAY, function()
                    processing[closest.id] = nil
                    refusedNpcs[npcId] = nil
                    if not closest:isValid() then return end
                    if not npc:isValid() or types.Actor.isDead(npc) then return end
                    if closest.cell == nil then return end
                    local rec = types.Weapon.record(closest)
                    local sound = rec and shared.WEAPON_SOUND[rec.type]
                    if sound then core.sound.playSound3d(sound, npc) end
                    closest:moveInto(types.Actor.inventory(npc))
                    npc:sendEvent("Disarm_Reequip", {
                        weapon = closest
                    })
                end)
            end)
        end,
    },
}