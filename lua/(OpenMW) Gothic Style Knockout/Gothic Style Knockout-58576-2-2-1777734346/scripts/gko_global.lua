local types = require("openmw.types")
local core  = require("openmw.core")
local world = require("openmw.world")
local async = require("openmw.async")
local util  = require("openmw.util")

local shared   = require("scripts.gko_shared")
local data     = require("scripts.gko_data")
local DEFAULTS = shared.DEFAULTS
local GUARD_CLASS = shared.GUARD_CLASS

local GKO_SCRIPT = "scripts/gko_npc.lua"

local cachedSettings = {
    MOD_ENABLED          = DEFAULTS.MOD_ENABLED,
    KNOCKDOWN_DURATION   = DEFAULTS.KNOCKDOWN_DURATION,
    DROP_WEAPON          = DEFAULTS.DROP_WEAPON,
    PICKUP_DELAY         = DEFAULTS.PICKUP_DELAY,
    SET_FIGHT            = DEFAULTS.SET_FIGHT,
    SET_DISPOSITION      = DEFAULTS.SET_DISPOSITION,
    HP_AFTER_KNOCKDOWN   = DEFAULTS.HP_AFTER_KNOCKDOWN,
    BLUNT_ONLY           = DEFAULTS.BLUNT_ONLY,
    PLAYER_KNOCKDOWN     = DEFAULTS.PLAYER_KNOCKDOWN,
    NPC_LOOT_PLAYER      = DEFAULTS.NPC_LOOT_PLAYER,
    LOOT_MIN_PERCENT     = DEFAULTS.LOOT_MIN_PERCENT,
    PLAYER_FIGHT_THRESHOLD_ENABLED = DEFAULTS.PLAYER_FIGHT_THRESHOLD_ENABLED,
    PLAYER_FIGHT_THRESHOLD         = DEFAULTS.PLAYER_FIGHT_THRESHOLD,
    BOUNTY_THRESHOLD_ENABLED       = DEFAULTS.BOUNTY_THRESHOLD_ENABLED,
    BOUNTY_THRESHOLD               = DEFAULTS.BOUNTY_THRESHOLD,
}

local droppedWeapons = {}
local playerDroppedWeapon = nil
local originalFights = {}
-- set of actor ids whose gko_npc should have knockdown disabled for gko_npc
local disableKnockdownIds = {}

local function dropWeapon(actor)
    local eqTable = types.Actor.getEquipment(actor)
    if not eqTable then return nil end
    local weapon = eqTable[types.Actor.EQUIPMENT_SLOT.CarriedRight]
    if not weapon or not weapon:isValid() then return nil end
    if weapon.count < 1 then return nil end
    if not types.Weapon.objectIsInstance(weapon) then return nil end
    if weapon.recordId:find("^bound_") then return nil end

    local pos = actor.position
    local dropped = weapon:split(1)
    dropped:teleport(actor.cell, util.vector3(pos.x, pos.y, pos.z + 10))

    local rec = types.Weapon.record(weapon)
    local sound = rec and data.WEAPON_SOUND[rec.type]
    if sound then
        core.sound.playSound3d(sound:gsub(" Up$", " Down"), actor)
    end

    return dropped
end

local function scheduleWeaponPickup(actor, reequipEvent)
    local actorId = actor.id
    for dropped, ownerId in pairs(droppedWeapons) do
        if ownerId == actorId then
            droppedWeapons[dropped] = nil
            async:newUnsavableSimulationTimer(cachedSettings.PICKUP_DELAY, function()
                if not dropped:isValid() then return end
                if not actor:isValid() or types.Actor.isDead(actor) then return end
                if dropped.cell == nil then return end

                actor:sendEvent("GKD_StartWeaponPickup", {
                    weapon       = dropped,
                    reequipEvent = reequipEvent,
                })
            end)
            break
        end
    end
end

local function isGuard(npc)
    local rec = types.NPC.record(npc)
    if rec and rec.class and GUARD_CLASS[string.lower(rec.class)] then
        return true
    end

    local rid = string.lower(npc.recordId)
    for _, pattern in ipairs(shared.GUARD_PATTERNS) do
        if rid:find(pattern, 1, true) then return true end
    end
    return false
end

local function isKillPlayerNpc(npc)
    return shared.KILL_PLAYER_NPCS[string.lower(npc.recordId)] or false
end

local function isEligibleForScript(actor)
    if not actor:isValid() then return false end
    if types.Actor.isDead(actor) then return false end
    if not types.NPC.objectIsInstance(actor) then return false end
    if types.Player.objectIsInstance(actor) then return false end
    if shared.EXCLUDED_NPCS[string.lower(actor.recordId)] then return false end
    if isGuard(actor) then return false end
    if isKillPlayerNpc(actor) then return false end
    return true
end

return {
    engineHandlers = {
        onActorActive = function(actor)
            if not types.NPC.objectIsInstance(actor) then return end
            if types.Player.objectIsInstance(actor) then return end

            -- cache original fight before engine can change it
            local fightVal = types.Actor.stats.ai.fight(actor).base
            originalFights[actor.id] = fightVal

            -- send to player for threshold check
            for _, player in ipairs(world.players) do
                player:sendEvent("GKD_NpcFightCached", { npcId = actor.id, fight = fightVal })
            end

            -- attach dynamic script to eligible NPCs
            if isEligibleForScript(actor) and not actor:hasScript(GKO_SCRIPT) then
                actor:addScript(GKO_SCRIPT)
                actor:sendEvent("GKD_SettingsUpdated", cachedSettings)
                if disableKnockdownIds[actor.id] then
                    actor:sendEvent("GKD_DisableKnockdown", {})
                end
            end
        end,

        onSave = function()
            return { disableKnockdownIds = disableKnockdownIds }
        end,

        onLoad = function(data)
            disableKnockdownIds = {}
            if data and data.disableKnockdownIds then
                for k, v in pairs(data.disableKnockdownIds) do
                    disableKnockdownIds[k] = v
                end
            end
        end,
    },

    eventHandlers = {
        GKD_SettingsUpdated = function(newSettings)
            cachedSettings = newSettings
            for _, actor in ipairs(world.activeActors) do
                if actor:hasScript(GKO_SCRIPT) then
                    actor:sendEvent("GKD_SettingsUpdated", newSettings)
                end
            end
        end,

        -- mark a BH-escorted prisoner as no-knockdown for the rest of their short life
        GKD_MarkDisableKnockdown = function(d)
            if not d or not d.npc then return end
            disableKnockdownIds[d.npc.id] = true
            if d.npc:isValid() and d.npc:hasScript(GKO_SCRIPT) then
                d.npc:sendEvent("GKD_DisableKnockdown", {})
            end
        end,

        -- drop the disable flag entirely. Used when the prisoner is killed, deported to prison or restored after a cell-change escape
        GKD_ClearDisableKnockdown = function(d)
            if not d or not d.npcId then return end
            disableKnockdownIds[d.npcId] = nil
        end,

        -- NPC knocked out by player
        GKD_DoKnockdown = function(d)
            if not d or not d.victim or not d.victim:isValid() then return end

            if cachedSettings.DROP_WEAPON then
                local dropped = dropWeapon(d.victim)
                if dropped then
                    droppedWeapons[dropped] = d.victim.id
                end
            end

            if d.attacker and d.attacker:isValid() and types.Player.objectIsInstance(d.attacker) then
                d.victim:sendEvent("GKD_SetDisposition", {
                    player = d.attacker,
                    target = cachedSettings.SET_DISPOSITION,
                })
            end
        end,

        -- we do be suppressing with all our might
        -- bloody hell it took me so long to make a somewhat reliable solution
        GKD_BroadcastFollowerSuppress = function(d)
            if not d or not d.duration or not d.victim then return end

            for _, actor in ipairs(world.activeActors) do
                if actor.id == d.victim.id then goto continue end
                if not actor:isValid() or types.Actor.isDead(actor) then goto continue end
                if not types.NPC.objectIsInstance(actor) then goto continue end
                if types.Player.objectIsInstance(actor) then goto continue end
                if isGuard(actor) or isKillPlayerNpc(actor) then goto continue end

                actor:sendEvent("GKD_FollowerSuppressCombat", {
                    victim   = d.victim,
                    duration = d.duration,
                })

                ::continue::
            end
        end,

        -- NPC recovered from knockout by player
        GKD_Recovery = function(d)
            if not d.npc or not d.npc:isValid() then return end

            if d.recoveryMsg then
                for _, player in ipairs(world.players) do
                    player:sendEvent("GKD_ShowRecoveryMessage", { msg = d.recoveryMsg })
                end
            end

            scheduleWeaponPickup(d.npc, "GKD_Reequip")
        end,

        -- player knocked out by NPC
        GKD_DoPlayerKnockdown = function(d)
            if not d or not d.player or not d.player:isValid() then return end

            if cachedSettings.DROP_WEAPON then
                local dropped = dropWeapon(d.player)
                if dropped then
                    playerDroppedWeapon = dropped
                end
            end

            -- stop combat for ALL active NPCs except guards and kill-only NPCs
            local attacker = d.attacker
            for _, actor in ipairs(world.activeActors) do
                if actor:isValid() and not types.Actor.isDead(actor)
                    and types.NPC.objectIsInstance(actor)
                    and not types.Player.objectIsInstance(actor)
                then
                    if isGuard(actor) or isKillPlayerNpc(actor) then
                        -- guards and kill-only NPCs keep fighting
                    else
                        if actor:hasScript(GKO_SCRIPT) then
                            if attacker and attacker:isValid() and actor.id == attacker.id then
                                actor:sendEvent("GKD_LootPlayer", {
                                    player            = d.player,
                                    hasDroppedWeapon  = playerDroppedWeapon ~= nil,
                                })
                            else
                                actor:sendEvent("GKD_StopCombatFull", {})
                            end
                        end
                    end
                end
            end
        end,

        -- Fired by the NPC at the pickup animation's attach keyframe
        GKD_FinalizeWeaponPickup = function(d)
            if not d.npc or not d.npc:isValid() then return end
            if not d.weapon or not d.weapon:isValid() then return end
            if d.weapon.cell == nil then return end

            local pickupRec = types.Weapon.record(d.weapon)
            local pickupSound = pickupRec and data.WEAPON_SOUND[pickupRec.type]
            if pickupSound then
                core.sound.playSound3d(pickupSound, d.npc)
            end
            d.weapon:moveInto(types.Actor.inventory(d.npc))
            if d.reequipEvent then
                d.npc:sendEvent(d.reequipEvent, { weapon = d.weapon })
            end
        end,

        -- NPC steals gold from unconscious player
        GKD_NpcStealGold = function(d)
            if not d.npc or not d.npc:isValid() then return end
            if not d.player or not d.player:isValid() then return end

            local playerInv = types.Actor.inventory(d.player)
            local gold = nil
            for _, item in ipairs(playerInv:getAll()) do
                if item.recordId == "gold_001" then
                    gold = item
                    break
                end
            end

            local name = d.name or "Someone"
            local kh   = d.isKhajiit or false
            local msg

            if gold and gold.count > 0 then
                local minPct = cachedSettings.LOOT_MIN_PERCENT or 100
                if minPct < 10 then minPct = 10 end
                if minPct > 100 then minPct = 100 end

                local pct = math.random(minPct, 100)
                local takeCount = math.floor(gold.count * pct / 100 + 0.5)
                if takeCount < 1 then takeCount = 1 end
                if takeCount > gold.count then takeCount = gold.count end

                local toMove = (takeCount == gold.count) and gold or gold:split(takeCount)
                toMove:moveInto(types.Actor.inventory(d.npc))
                core.sound.playSound3d("Item Gold Up", d.npc)
                local pool = kh and shared.LOOT_GOLD_KHAJIIT_MESSAGES or shared.LOOT_GOLD_MESSAGES
                msg = pool[math.random(#pool)]
            else
                local pool = kh and shared.LOOT_NO_GOLD_KHAJIIT_MESSAGES or shared.LOOT_NO_GOLD_MESSAGES
                msg = pool[math.random(#pool)]
            end

            for _, player in ipairs(world.players) do
                player:sendEvent("GKD_ShowRecoveryMessage", { msg = name .. ": \"" .. msg .. "\"" })
            end
        end,

        -- NPC takes dropped weapon
        GKD_NpcTakePlayerWeapon = function(d)
            if not d.npc or not d.npc:isValid() then return end

            local dropped = playerDroppedWeapon
            if not dropped then return end
            if not dropped:isValid() or dropped.cell == nil then
                playerDroppedWeapon = nil
                return
            end

            local pickupRec = types.Weapon.record(dropped)
            local pickupSound = pickupRec and data.WEAPON_SOUND[pickupRec.type]
            if pickupSound then
                core.sound.playSound3d(pickupSound, d.npc)
            end
            dropped:moveInto(types.Actor.inventory(d.npc))
            playerDroppedWeapon = nil

            local name = d.name or "Someone"
            local kh   = d.isKhajiit or false
            local pool = kh and shared.LOOT_WEAPON_KHAJIIT_MESSAGES or shared.LOOT_WEAPON_MESSAGES
            local msg = pool[math.random(#pool)]
            for _, player in ipairs(world.players) do
                player:sendEvent("GKD_ShowRecoveryMessage", { msg = name .. ": \"" .. msg .. "\"" })
            end
        end,

        -- player recovered
        GKD_PlayerRecovery = function(d)
            playerDroppedWeapon = nil
        end,

        -- NPC went inactive, remove script and clean caches
        GKD_DynamicScriptCleanup = function(d)
            if not d.npc or not d.npc:isValid() then return end

            originalFights[d.npc.id] = nil
            for _, player in ipairs(world.players) do
                player:sendEvent("GKD_NpcFightRemoved", { npcId = d.npc.id })
            end
            for dropped, ownerId in pairs(droppedWeapons) do
                if ownerId == d.npc.id then
                    droppedWeapons[dropped] = nil
                end
            end

            if d.npc:hasScript(GKO_SCRIPT) then
                d.npc:removeScript(GKO_SCRIPT)
            end
        end,
    },
}