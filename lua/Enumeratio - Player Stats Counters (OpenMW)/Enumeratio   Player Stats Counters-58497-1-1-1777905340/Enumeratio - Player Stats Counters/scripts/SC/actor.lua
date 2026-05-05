-- ============================================================
-- StatCounters actor script (NPC, CREATURE)
-- 1. Counts melee/fist swings by the player (hits and misses).
-- 2. Tracks kills: when this actor dies, if the last attacker
--    was the player, sends a KilledActor event back to the
--    player script with the type of actor killed.
-- ============================================================
local self = require('openmw.self')
local T    = require('openmw.types')
local I    = require('openmw.interfaces')

local lastPlayerHitTime = nil  -- simulation time of last player hit
local handlersRegistered = false

local function register()
    if handlersRegistered then return end
    handlersRegistered = true

    local MELEE = I.Combat.ATTACK_SOURCE_TYPES.Melee

    local function isHandToHandAttack(attacker, sourceType)
        if sourceType ~= MELEE then return false end

        local weapon = T.Actor.getEquipment(attacker, T.Actor.EQUIPMENT_SLOT.CarriedRight)
        if weapon then return false end

        if T.NPC.objectIsInstance(attacker) then
            return true
        end

        if T.Creature.objectIsInstance(attacker) then
            local ok, rec = pcall(function() return T.Creature.record(attacker) end)
            return ok and rec and rec.canUseWeapons or false
        end

        return false
    end

    I.Combat.addOnHitHandler(function(attack)
        if not attack.attacker then return end

        -- Incoming combat damage to the player: on NPC/Creature local scripts,
        -- this hit handler runs for attacks they perform. If the target/victim is
        -- the player, notify the player script so it can attribute the next HP loss
        -- to combat.
        if attack.successful then
            local target = attack.target or attack.victim
            if target and T.Player.objectIsInstance(target) then
                target:sendEvent("SC_RecentCombatHit", {})
            end
        end

        if not T.Player.objectIsInstance(attack.attacker) then return end

        -- Track that the player hit us (for kill attribution)
        if attack.successful then
            local core = require('openmw.core')
            lastPlayerHitTime = core.getSimulationTime()
            -- Notify player of successful hit (for sneak attack detection)
            attack.attacker:sendEvent("SC_SuccessfulHit", {})
        end

        -- Swing tracking: OpenMW exposes melee, not a separate HandToHand
        -- source type. Treat unarmed attacks as melee from a weapon-capable
        -- actor with no weapon equipped.
        local src = attack.sourceType
        local isHandToHand = isHandToHandAttack(attack.attacker, src)
        if src ~= MELEE and not isHandToHand then return end
        attack.attacker:sendEvent("CombatSwing", {
            hit = attack.successful,
            isHandToHand = isHandToHand,
        })
    end)
end

-- ============================================================
-- KILL ATTRIBUTION
-- When this actor dies, check if the player was the most recent
-- attacker (within the last 30 seconds). This covers melee,
-- ranged, and hand-to-hand kills. Magic-only kills (spells,
-- enchantments) are also caught because Damage Health effects
-- from the player arrive through the same onHit pipeline.
-- If attribution succeeds, send a KilledActor event to the
-- player with the actor type (NPC or Creature).
-- ============================================================

local function onDied()
    if not lastPlayerHitTime then return end

    local core = require('openmw.core')
    local elapsed = core.getSimulationTime() - lastPlayerHitTime

    -- Only attribute the kill if the player hit within 30 seconds
    if elapsed > 30 then return end

    -- Determine actor type and creature name/category
    local actorType = "creature"
    local creatureName = nil
    local creatureType = nil  -- Creature.TYPE numeric value
    local npcClass = nil      -- NPC class ID string
    local npcRecordId = nil   -- NPC record ID for worshipper lookup
    local isEssential = false -- whether the actor was essential
    if T.NPC.objectIsInstance(self) then
        actorType = "npc"
        npcRecordId = self.recordId
        local classOk, classId = pcall(function() return T.NPC.record(self).class end)
        if classOk and classId then
            npcClass = classId
        end
        pcall(function() isEssential = T.NPC.record(self).isEssential end)
    else
        local ok, rec = pcall(function() return T.Creature.record(self) end)
        if ok and rec then
            creatureName = rec.name
            creatureType = rec.type
            pcall(function() isEssential = rec.isEssential end)
        end
    end

    -- Find the player to send the event to
    local nearby = require('openmw.nearby')
    for _, actor in ipairs(nearby.actors) do
        if T.Player.objectIsInstance(actor) then
            actor:sendEvent("KilledActor", {
                actorType = actorType,
                creatureName = creatureName,
                creatureType = creatureType,
                npcClass = npcClass,
                npcRecordId = npcRecordId,
                recordId = self.recordId,
                isEssential = isEssential,
            })
            break
        end
    end
end

return {
    engineHandlers = {
        onInit = register,
        onLoad = register,
    },
    eventHandlers = {
        Died = onDied,
    },
}
