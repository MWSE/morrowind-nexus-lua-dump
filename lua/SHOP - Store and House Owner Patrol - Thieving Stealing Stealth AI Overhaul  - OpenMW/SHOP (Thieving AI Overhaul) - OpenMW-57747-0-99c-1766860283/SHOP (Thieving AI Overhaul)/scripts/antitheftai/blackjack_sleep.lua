--[[
SHOP - Store & House Owner Patrol (NPC in interiors AI overhaul) for OpenMW.
Copyright (C) 2025 Łukasz Walczak

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
----------------------------------------------------------------------
-- Blackjack Sleep Effect Handler - LOCAL SCRIPT for NPCs
-- Handles sleep effects when NPC is hit by blackjack weapons
-- Integrates with detd_sleep_spell3 from another mod
----------------------------------------------------------------------

local self = require('openmw.self')
local types = require('openmw.types')
local time = require('openmw_aux.time')
local core = require('openmw.core')
local async = require('openmw.async')
local nearby = require('openmw.nearby')  -- For accessing nearby actors
local util = require('openmw.util')  -- For vector3 operations
local settings = require('scripts.antitheftai.SHOPsettings')
local companionDetection = require('scripts.antitheftai.modules.companion_detection')

-- Blackjack weapon IDs that trigger sleep effects
local BLACKJACK_WEAPONS = {
    ['blackjack-wooden'] = true,
    ['blackjack-iron'] = true,
    ['blackjack-imperial'] = true,
    ['blackjack-dwemer'] = true,
    ['blackjack-wooden-operative'] = true,
    ['blackjack-iron-operative'] = true,
    ['blackjack-imperial-operative'] = true,
    ['blackjack-dwemer-operative'] = true,
    ['blackjack-wooden-masterthief'] = true,
    ['blackjack-iron-masterthief'] = true,
    ['blackjack-imperial-masterthief'] = true,
    ['blackjack-dwemer-masterthief'] = true,
    ['blackjack-wooden-weighted'] = true,
    ['blackjack-iron-weighted'] = true,
    ['blackjack-imperial-weighted'] = true,
    ['blackjack-dwemer-weighted'] = true,
    ['blackjack-wooden-nimble'] = true,
    ['blackjack-iron-nimble'] = true,
    ['blackjack-imperial-nimble'] = true,
    ['blackjack-dwemer-nimble'] = true,
    ['blackjack-wooden-masterwork'] = true,
    ['blackjack-iron-masterwork'] = true,
    ['blackjack-imperial-masterwork'] = true,
    ['blackjack-dwemer-masterwork'] = true,
    ['blackjack-wooden-extended'] = true,
    ['blackjack-iron-extended'] = true,
    ['blackjack-imperial-extended'] = true,
    ['blackjack-dwemer-extended'] = true
}

local fleeRestoreData = nil -- Stores original stats during Flee behavior
local fleeItemCharges = {} -- Stores original charges during Flee behavior
local fleeScrolls = {} -- Stores removed scrolls during Flee behavior

-- List of weighted blackjacks for stun duration bonus
local WEIGHTED_BLACKJACKS = {
    ['blackjack-wooden-weighted'] = true,
    ['blackjack-iron-weighted'] = true,
    ['blackjack-imperial-weighted'] = true,
    ['blackjack-dwemer-weighted'] = true
}

local settings = require('scripts.antitheftai.SHOPsettings')

local SLEEP_SPELL_ID = 'detd_sleep_spell3'
local SLEEP_DURATION = 60  -- seconds
local ILLEGAL_SLEEP_VALUE = 99

local calculatedSleepDuration = 0
local mechanics = require('scripts.antitheftai.modules.blackjack_mechanics')
local bedVoices = require('scripts.antitheftai.modules.bed_voices')

-- State tracking
local doOnce = 0
local sleepTimerHandle = nil
local originalHelloValue = nil  -- Store original hello value to restore later
local originalAlarmValue = nil  -- Store original alarm value to restore later
local wasSpottedDuringHit = false  -- Track if player was spotted when blackjack hit occurred
local wasDiscoveredByOthers = false  -- Track if body was discovered by another NPC
local witnessTimer = nil  -- 60-second timer for victim witness detection
local lastStunTime = nil -- Track last time NPC was stunned

----------------------------------------------------------------------
-- Helper: Debug Logging
----------------------------------------------------------------------
local function log(...)
    if settings.general and settings.general:get('enableLogging') ~= false and settings.general:get('enableDebug') then
        print(...)
    end
end

----------------------------------------------------------------------
-- Helper: Guard Check
----------------------------------------------------------------------
local function isGuard(npc)
    if not npc then return false end
    local record = types.NPC.record(npc)
    if not (record and record.class) then return false end
    local class = record.class:lower()
    return class:find("guard") or class:find("ordinator") or class:find("buoyant") or class:find("lex")
end

----------------------------------------------------------------------
-- Helper: Civilian Reaction Logic (Level Scaling + Demoralize)
----------------------------------------------------------------------
local function handleCivilianReaction(npc, player)
    if not npc or not player then return end

    -- Calculate level-based probabilities
    local playerLevel = types.Actor.stats.level(player).current
    local civilianLevel = types.Actor.stats.level(npc).current
    local levelDiff = playerLevel - civilianLevel

    -- Base chances
    local attackChance = 10
    local voiceChance = 30
    local demoralizeChance = 60

    -- Apply level scaling
    if levelDiff > 0 then
        local scaledDiff = math.min(levelDiff, 20)
        if scaledDiff <= 10 then
            attackChance = math.max(0, attackChance - scaledDiff)
            demoralizeChance = demoralizeChance + scaledDiff
        else
            attackChance = 0
            local extraLevels = scaledDiff - 10
            voiceChance = math.max(20, 30 - extraLevels)
            demoralizeChance = math.min(80, 70 + extraLevels)
        end
    elseif levelDiff < 0 then
        local absDiff = math.abs(levelDiff)
        local change = absDiff * 2
        attackChance = attackChance + change
        demoralizeChance = math.max(0, demoralizeChance - change)
    end

    local roll = math.random(100)
    log("[CIVILIAN REACTION] Level Diff:", levelDiff, "Roll:", roll, "(Attack:", attackChance, "Voice:", attackChance + voiceChance, "Fear:", demoralizeChance, ")")

    -- Get NPC race and gender for voice responses
    local npcRecord = types.NPC.record(npc)
    local race = npcRecord.race:lower():gsub(" ", "")
    local gender = npcRecord.isMale and "male" or "female"

    if roll <= attackChance then
        log("[CIVILIAN REACTION] Result: COMBAT")
        npc:sendEvent('StartAIPackage', {type = 'Combat', target = player})
    elseif roll <= (attackChance + voiceChance) then
        log("[CIVILIAN REACTION] Result: VOICE ONLY")
        core.sendGlobalEvent('AntiTheft_PlayDetectionVoice', { 
            npcId = npc.id, 
            race = race, 
            gender = gender 
        })
    else
        log("[CIVILIAN REACTION] Result: DEMORALIZE / FLEE")
        -- Use the existing local event handler for fleeing
        npc:sendEvent('AntiTheft_ApplyFleeStats', { target = player })
        
        -- Shout for help
        core.sendGlobalEvent('AntiTheft_PlayDetectionVoice', { 
            npcId = npc.id, 
            race = race, 
            gender = gender 
        })
    end
end

----------------------------------------------------------------------
-- On Hit Handler - Detects blackjack weapon hits and applies spell
----------------------------------------------------------------------
local function onHit(attack)
    -- Master Toggle Check
    if not settings.general:get('enableBlackjackSpawning') then
         return -- Mechanics disabled
    end

    -- Skip player companions and escort NPCs
    if companionDetection.isCompanion(self) then
        log("[BLACKJACK SLEEP] Target is a companion or escort - skipping stun mechanics")
        return
    end

    -- Check if attacker exists
    if not attack.attacker then
        return  -- No attacker, allow normal processing
    end
    
    local weaponId = nil
    local isBlackjackWeapon = false
    local isHandToHand = false
    
    -- Check if hit by a weapon (blackjack)
    if attack.weapon and attack.weapon:isValid() then
        -- Validate weapon exists before getting record
        local weaponRecord = types.Weapon.record(attack.weapon)
        if weaponRecord and weaponRecord.id then
            weaponId = weaponRecord.id:lower()
            isBlackjackWeapon = BLACKJACK_WEAPONS[weaponId] or false
            log("[BLACKJACK SLEEP] NPC", self.id, "hit by weapon:", weaponId)
        end
    end
    
    -- Check if attacker has no weapon equipped (hand-to-hand)
    if not isBlackjackWeapon and types.Actor.getEquipment then
        local equipment = types.Actor.getEquipment(attack.attacker)
        if equipment then
            isHandToHand = equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight] == nil
            if isHandToHand then
                log("[BLACKJACK SLEEP] NPC", self.id, "hit by HAND-TO-HAND (unarmed)")
            end
        end
    end
    
    -- Proceed only if blackjack weapon OR hand-to-hand
    if not (isBlackjackWeapon or isHandToHand) then
        log("[BLACKJACK SLEEP] Not a stun-capable attack, allowing normal hit processing")
        return  -- Not a blackjack or hand-to-hand, allow normal processing
    end
    
    log("[BLACKJACK SLEEP] ★★★ STUN ATTEMPT DETECTED! ★★★")
    
    -- Reset flags for NEW stun attempt
    wasDiscoveredByOthers = false
    wasSpottedDuringHit = false
    calculatedSleepDuration = 0
    
    -- Calculate if attack is from behind
    local util = require('openmw.util')
    local npcPos = self.position
    local attackerPos = attack.attacker.position
    
    -- Get NPC's facing direction (forward vector)
    local npcRotation = self.rotation
    local npcForward = npcRotation * util.vector3(0, 1, 0)  -- Forward is +Y in OpenMW
    
    -- Calculate direction from NPC to attacker
    local toAttacker = util.vector3(
        attackerPos.x - npcPos.x,
        attackerPos.y - npcPos.y,
        0  -- Ignore Z for horizontal angle
    )
    
    -- Normalize vectors (get unit vectors)
    local npcForwardNorm = util.vector3(npcForward.x, npcForward.y, 0):normalize()
    local toAttackerNorm = toAttacker:normalize()
    
    -- Calculate dot product (ranges from -1 to 1)
    -- -1 = directly behind, 0 = perpendicular, 1 = directly in front
    local dotProduct = npcForwardNorm.x * toAttackerNorm.x + npcForwardNorm.y * toAttackerNorm.y
    
    log("[BLACKJACK SLEEP] Attack direction check:")
    log("[BLACKJACK SLEEP]   - Dot product:", dotProduct)
    
    -- Check if attack is from behind (dot product < -0.1 means behind)
    local isFromBehind = dotProduct < -0.1
    
    if not isFromBehind then
        log("[BLACKJACK SLEEP] ✗ Attack NOT from behind - sleep will NOT be applied")
        return  -- Allow normal attack processing
    end
    
    log("[BLACKJACK SLEEP] ✓ Attack IS from behind - proceeding with sleep check")
    
    -- Check fight value
    local FightValue = types.Actor.stats.ai.fight(self).base
    if FightValue >= 90 then
        log("[BLACKJACK SLEEP] Fight value too high (", FightValue, "), sleep not applied")
        if attack.damage then for stat, _ in pairs(attack.damage) do attack.damage[stat] = 0 end end
        return false
    end

    -- COOLDOWN CHECK
    -- Check if NPC was recently stunned
    local currentTime = core.getSimulationTime()
    if lastStunTime and (currentTime < lastStunTime + 60) then
         log("[BLACKJACK SLEEP] Target is immune/alert (Cooldown active). Time remaining:", (lastStunTime + 60) - currentTime)
         -- Fail the stun. Allow normal attack? 
         -- "rest of plan looks great" -> Plan said "Fail implies no stun... ensure normal combat/alert behavior"
         return -- Allow normal hit (combat/alert)
    end
    
    -- Calculate Chance using Shared Module
    local chance = mechanics.calculateStunChance(attack.attacker, self)
    log(string.format("[BLACKJACK SLEEP] Stun Chance Calculation: %.2f%%", chance))
    
    -- Roll Dice
    local roll = math.random() * 100
    if roll > chance then
        log(string.format("[BLACKJACK SLEEP] ✗ Stun FAILED (Roll: %.2f > Chance: %.2f)", roll, chance))
        -- Allow normal attack logic (alert/combat)
        return
    end
    
    log(string.format("[BLACKJACK SLEEP] ✓ Stun SUCCESS (Roll: %.2f <= Chance: %.2f)", roll, chance))
    
    -- Calculate Duration using Shared Module (Pass configurable max cap)
    local maxCap = settings.vars and settings.vars:get('maxBlackjackDuration') or 45
    local duration = mechanics.calculateDuration(attack.attacker, weaponId, maxCap)
    calculatedSleepDuration = duration
    log(string.format("[BLACKJACK SLEEP] Duration Calculated: %.2fs (Max Cap: %ds)", duration, maxCap))
    
    -- Set Cooldown
    lastStunTime = currentTime

    -- Apply the sleep spell
    local success, err = pcall(function()
        types.Actor.spells(self):add(SLEEP_SPELL_ID)
        log("[BLACKJACK SLEEP] Sleep spell applied successfully to NPC:", self.id)
        
        -- Send success event to attacker (Player) for XP and Durability handling
        if attack.attacker and attack.attacker.type == types.Player then
            attack.attacker:sendEvent('AntiTheft_BlackjackSuccess', { 
                weapon = attack.weapon 
            })
        end
    end)
    
    if not success then
        --log("[BLACKJACK SLEEP] ERROR applying spell:", err)
    else
        -- Check if player was already spotted BEFORE the blackjack hit
        local isPlayerSpotted = false
        if attack.attacker then
            local playerEffects = types.Actor.activeEffects(attack.attacker)
            if playerEffects then
                local drainSneakEffect = playerEffects:getEffect(core.magic.EFFECT_TYPE.DrainSkill, 'sneak')
                if drainSneakEffect and drainSneakEffect.magnitude > 0 then
                    isPlayerSpotted = true
                    log("[BLACKJACK SLEEP] Detected Drain Sneak effect - player is spotted")
                end
            end
        end
        
        -- Store spotted status
        wasSpottedDuringHit = isPlayerSpotted
        
        -- IMMEDIATELY disable alarm and hello to prevent crime detection
        if not originalHelloValue then
            originalHelloValue = types.NPC.stats.ai.hello(self).base
        end
        
        if not originalAlarmValue then
            originalAlarmValue = types.NPC.stats.ai.alarm(self).base
        end
        
        types.NPC.stats.ai.hello(self).base = 0
        types.NPC.stats.ai.alarm(self).base = 0
        
        -- Apply blind effect
        pcall(function()
            types.Actor.activeEffects(self):set(100, core.magic.EFFECT_TYPE.Blind)
        end)
    end
    
    -- CRITICAL: Zero out all damage to prevent health loss
    if attack.damage then
        for stat, _ in pairs(attack.damage) do
            attack.damage[stat] = 0
        end
    end
    
    -- CRITICAL: Return false to cancel attack processing
    return false
end

-- Register the onHit handler using the correct interface name
local I = require('openmw.interfaces')
if I.Combat and I.Combat.addOnHitHandler then
    I.Combat.addOnHitHandler(onHit)
    log("[BLACKJACK SLEEP] OnHit handler registered successfully")
else
    log("[BLACKJACK SLEEP] ERROR: Combat.addOnHitHandler not available!")
    log("[BLACKJACK SLEEP] Available interfaces:", I)
end

----------------------------------------------------------------------
-- Main repeating check (runs every second)
-- Manages fatigue, duration timer, and wakeup logic
----------------------------------------------------------------------
local stopFn = time.runRepeatedly(function()
    -- Safety check: ensure NPC type has necessary functions
    if not types.Actor or not types.Actor.stats or not types.Actor.activeSpells then
        return
    end

    local FightValue = types.Actor.stats.ai.fight(self).base
    local StanceValue = types.Actor.getStance(self)
    local HealthValueB = types.Actor.stats.dynamic.health(self).base
    local HealthValueC = types.Actor.stats.dynamic.health(self).current
    
    -- Check if sleep spell is active
    local isSleepActive = types.Actor.activeSpells(self):isSpellActive(SLEEP_SPELL_ID)
    
    -- If sleep spell is active, drain fatigue
    if isSleepActive then
        types.Actor.stats.dynamic.fatigue(self).current = -45
        -- log("[BLACKJACK DEBUG] Applying sleep fatigue drain (-45)") -- Commented out debug
        
        -- **PULSE DETECTION: Scan for conscious NPCs within 800 units**
        -- This runs every second while unconscious
        -- **VISUAL SCAN: Nearby NPCs checking for bodies**
        -- Only scan if not yet discovered to prevent spam and repeated bounties
        if doOnce == 1 and not wasDiscoveredByOthers then
            -- log("[VISUAL SCAN] Emitting detection scan from unconscious NPC", self.id)
            
            local myPos = self.position
            local player = nearby.players[1]  -- Get player from nearby module in NPC script
            
            -- Scan all nearby actors
            for _, actor in ipairs(nearby.actors) do
                if actor.type == types.NPC and actor.id ~= self.id then
                    
                    -- Check if potential observer is conscious (no sleep spell)
                    local isObserverConscious = not types.Actor.activeSpells(actor):isSpellActive(SLEEP_SPELL_ID)
                    
                    if isObserverConscious then
                        local dist = (actor.position - myPos):length()
                        
                        -- Vision range: 1500 units
                        if dist <= 1500 then
                            
                            -- Field of View Check (120 degrees - Frontal Cone)
                            -- This prevents guards from detecting bodies behind them
                            local toTarget = myPos - actor.position
                            local actorForward = actor.rotation:apply(util.vector3(0, 1, 0))
                            local angle = actorForward:dot(toTarget:normalize())
                            
                            -- Dot > 0.5 is approx 60 degrees either side (120 deg total)
                            if angle > 0.5 then 
                                -- Calculate rigorous Line of Sight
                                -- Origin: Observer's Eye Level (90 units up)
                                local observerEyePos = actor.position + util.vector3(0, 0, 90)
                                
                                -- Targets: Victim Body Parts (Prone on ground)
                                local vFeet = myPos + util.vector3(0, 0, 5)     -- Feet
                                local vTorso = myPos + util.vector3(0, 0, 10)   -- Torso
                                local vHead = myPos + util.vector3(0, 0, 15)    -- Head
                                
                                -- Cast Rays with strict collisionType=3 (Actors + World)
                                -- This matches standard detection logic for walls/statics
                                local rayOpts = {
                                    collisionType = 3, -- 3 = World + Actors
                                    ignore = {actor}   -- Ignore the observer
                                }
                                
                                -- Explicitly define helper to check visibility
                                local function checkPart(targetPos, name)
                                    local ray = nearby.castRay(observerEyePos, targetPos, rayOpts)
                                    
                                    -- Debug Logging for Verification
                                    -- Only log if we effectively HIT something that isn't the victim
                                    if ray.hit then
                                        if ray.hitObject and ray.hitObject.id == self.id then
                                            -- Hit the victim -> VISIBLE
                                            -- log("[VISUAL DEBUG]", name, "VISIBLE (Ray hit victim)")
                                            return true
                                        else
                                            -- Hit something else -> BLOCKED
                                            -- log("[VISUAL DEBUG]", name, "BLOCKED by", ray.hitObject and ray.hitObject.recordId or "Unknown Geometry")
                                            return false
                                        end
                                    else
                                        -- Hit nothing -> CLEAR LINE using collisionType logic
                                        -- log("[VISUAL DEBUG]", name, "VISIBLE (Clear Line)")
                                        return true
                                    end
                                end
                                
                                local canSeeFeet = checkPart(vFeet, "Feet")
                                local canSeeTorso = checkPart(vTorso, "Torso")
                                local canSeeHead = checkPart(vHead, "Head")
                                
                                local canSeeHead = checkPart(vHead, "Head")
                                
                                if canSeeFeet or canSeeTorso or canSeeHead then
                                    -- NPC discovered the body!
                                    log("[ANTI-THEFT] ★★★ BODY DISCOVERED! Witness:", actor.id, "saw unconscious NPC", self.id)
                                
                                    -- Apply bounty if player wasn't spotted during the hit (and bounty not yet applied)
                                    if not wasSpottedDuringHit and player then
                                        log("[ANTI-THEFT] Crime reported! Applying bounty.")
                                        
                                        -- Trigger reaction voice on the witness
                                        local witnessRecord = types.NPC.record(actor)
                                        if witnessRecord then
                                            local race = witnessRecord.race:lower():gsub(" ", "")
                                            local gender = witnessRecord.isMale and "male" or "female"
                                            core.sendGlobalEvent('AntiTheft_PlayDetectionVoice', { 
                                                npcId = actor.id, 
                                                race = race, 
                                                gender = gender 
                                            })
                                        end

                                        -- Pass table with AMOUNT and WITNESS ID
                                        player:sendEvent("AntiTheft_Relay_SleepBounty", { 
                                            amount = settings.bounties:get('stunNPCBounty') or 300, 
                                            npcId = actor.id 
                                        })
                                        wasSpottedDuringHit = true
                                    end
                                    
                                    -- Mark body as discovered so victim doesn't report upon waking
                                    wasDiscoveredByOthers = true
                                    
                                    -- Send discovering NPC into action
                                    if player then
                                        -- Notify player script to expect combat/arrest from this witness
                                        player:sendEvent("AntiTheft_NotifyWitnessAttack", { npcId = actor.id })
                                        
                                        if isGuard(actor) then
                                            log("[ANTI-THEFT] Witness is GUARD - Initiating ARREST")
                                            
                                            -- Revert to 'Pursue' pkg as requested.
                                            -- Added 0.3s delay to ensure bounty is applied first (Race Condition Fix).
                                            async:newUnsavableSimulationTimer(0.3, function()
                                                if actor and actor:isValid() and player then
                                                    actor:sendEvent('StartAIPackage', {
                                                        type = 'Pursue',
                                                        target = player
                                                    })
                                                end
                                            end)
                                            
                                            -- Notify player script to monitor distance and force dialogue (Safety Net)
                                        else
                                            log("[ANTI-THEFT] Witness is CIVILIAN")
                                            handleCivilianReaction(actor, player)
                                        end
                                        
                                        -- **chain reaction ALARM**: Witness alerts other nearby NPCs
                                        -- Radius: Configurable (Default 1000 Int / 3500 Ext)
                                        local alarmRadius = settings.vars:get('interiorAlarmRadius') or 1000
                                        if self.cell.isExterior then
                                            alarmRadius = settings.vars:get('exteriorAlarmRadius') or 3500
                                        end
                                        log("[ANTI-THEFT] Witness shouting alarm! Alerting neighbors within " .. alarmRadius .. "u (Exterior: " .. tostring(self.cell.isExterior) .. ")")
                                        
                                        for _, neighbor in ipairs(nearby.actors) do
                                            -- Filter: Must be NPC, Not Witness, Not Victim
                                            if neighbor.type == types.NPC and neighbor.id ~= actor.id and neighbor.id ~= self.id then
                                                -- Check distance to WITNESS
                                                local distToWitness = (neighbor.position - actor.position):length()
                                                
                                                if distToWitness <= alarmRadius then
                                                    -- Ensure neighbor is conscious
                                                    local isNeighborConscious = not types.Actor.activeSpells(neighbor):isSpellActive(SLEEP_SPELL_ID)
                                                    
                                                    if isNeighborConscious then
                                                        log("[ANTI-THEFT] Neighbor alerted by alarm:", neighbor.id)
                                                        
                                                        -- Notify player script (prevent disband) + Expect Arrest if Guard
                                                        player:sendEvent("AntiTheft_NotifyWitnessAttack", { npcId = neighbor.id })
                                                        
                                                        -- Engage Combat or Arrest
                                                        if isGuard(neighbor) then
                                                            log("   -> Neighbor is Guard: Arresting (Pursue)")
                                                            async:newUnsavableSimulationTimer(0.35, function()
                                                                if neighbor and neighbor:isValid() and player then
                                                                    neighbor:sendEvent('StartAIPackage', {
                                                                        type = 'Pursue',
                                                                        target = player
                                                                    })
                                                                end
                                                            end)
                                                        else
                                                            log("   -> Neighbor is Civilian: Reaction")
                                                            handleCivilianReaction(neighbor, player)
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                
                                    -- Mark as discovered to STOP further scans
                                    wasDiscoveredByOthers = true
                                    
                                    -- Stop checking other NPCs immediately
                                    break
                            end
                        end
                    end
                end
                end
            end
        end
        
        -- Disable NPC interaction (prevent dialogue/recruitment) while unconscious
        if not originalHelloValue then
            -- Store original hello value first time
            originalHelloValue = types.NPC.stats.ai.hello(self).base
            log("[BLACKJACK SLEEP] Stored original hello value:", originalHelloValue)
        end
        
        -- Store original alarm value to prevent crime detection
        if not originalAlarmValue then
            originalAlarmValue = types.NPC.stats.ai.alarm(self).base
            log("[BLACKJACK SLEEP] Stored original alarm value:", originalAlarmValue)
        end
        
        -- Set hello to 0 to prevent interaction
        if types.NPC.stats.ai.hello(self).base ~= 0 then
            types.NPC.stats.ai.hello(self).base = 0
            log("[BLACKJACK SLEEP] Disabled NPC interaction (hello = 0) - NPC cannot be recruited")
        end
        
        -- Set alarm to 0 to prevent crime detection
        if types.NPC.stats.ai.alarm(self).base ~= 0 then
            types.NPC.stats.ai.alarm(self).base = 0
            log("[BLACKJACK SLEEP] Disabled crime detection (alarm = 0) - NPC cannot report crimes")
        end
    end
    
    -- Send global event once when sleep spell activates (if fight value is low)
    -- If player was spotted during blackjack hit, send the bounty event
    if doOnce == 0 and StanceValue == 0 and FightValue < 90 and isSleepActive then
        doOnce = 1
        
        if wasSpottedDuringHit then
            -- Player was spotted - send bounty event
            log("[BLACKJACK SLEEP] Sending bounty event - player was spotted during blackjack")
            local stunBounty = settings.bounties:get('stunNPCBounty') or 300
            core.sendGlobalEvent("AntiTheft_Relay_SleepBounty", { amount = stunBounty, npcId = self.id })
        else
            -- Player was not spotted
            log("[BLACKJACK SLEEP] Sleep activated (Stealthy takedown)")
        end
        
        core.sendGlobalEvent('AntiTheft_Relay_NPCUnconscious', {
            npcId = self.id,
            wasSpotted = wasSpottedDuringHit
        })
        log("[BLACKJACK SLEEP] Sent unconscious event via player relay - wasSpotted:", wasSpottedDuringHit)
        
        -- Start custom duration timer (remove spell after DYNAMIC duration seconds)
        local duration = calculatedSleepDuration or SLEEP_DURATION -- Use calculated if available, else default
        log("[BLACKJACK SLEEP] Starting sleep timer for duration:", duration)
        
        if not sleepTimerHandle then
            sleepTimerHandle = async:newUnsavableSimulationTimer(duration, function()
                log("[BLACKJACK SLEEP] Duration timer expired")
                
                -- Wrap in pcall to prevent crash and ensure handle reset
                local success, err = pcall(function()
                    -- Force remove spell without checking active status (safe to remove even if not active)
                    if types.Actor.spells then
                        types.Actor.spells(self):remove(SLEEP_SPELL_ID)
                        log("[BLACKJACK SLEEP] Removed sleep spell")
                    else
                        log("[BLACKJACK SLEEP] ERROR: types.Actor.spells is nil")
                    end

                    if types.Actor.stats and types.Actor.stats.dynamic and types.Actor.stats.dynamic.fatigue then
                        types.Actor.stats.dynamic.fatigue(self).current = 10
                        log("[BLACKJACK SLEEP] Restored fatigue to 10")
                    else
                        log("[BLACKJACK SLEEP] ERROR: types.Actor.stats.dynamic.fatigue is nil")
                    end
                end)
                
                if not success then
                    log("[BLACKJACK SLEEP] CRITICAL ERROR in timer callback:", err)
                    -- Attempt emergency wake up
                    pcall(function() types.Actor.stats.dynamic.fatigue(self).current = 10 end)
                end
                sleepTimerHandle = nil  -- Reset latch
            end)
        end
    end
    
    -- If NPC takes damage while sleeping, wake them up
    if HealthValueB > HealthValueC and isSleepActive then
        log("[BLACKJACK SLEEP] NPC took damage while sleeping, waking up")
        types.Actor.spells(self):remove(SLEEP_SPELL_ID)
        types.Actor.stats.dynamic.fatigue(self).current = 10
        
        -- Cancel the sleep timer if it's running
        if sleepTimerHandle then
            sleepTimerHandle = nil
        end
    end
    
    -- Reset doOnce flag when spell ends AND restore hello/alarm values
    if doOnce == 1 and not isSleepActive then
        doOnce = 0
        log("[BLACKJACK SLEEP] Spell ended, resetting state")
        
        -- Restore original hello value
        if originalHelloValue then
            types.NPC.stats.ai.hello(self).base = originalHelloValue
            log("[BLACKJACK SLEEP] Restored hello value to:", originalHelloValue)
            originalHelloValue = nil  -- Clear stored value
        end
        
        -- Restore original alarm value
        if originalAlarmValue then
            types.NPC.stats.ai.alarm(self).base = originalAlarmValue
            log("[BLACKJACK SLEEP] Restored alarm value to:", originalAlarmValue)
            originalAlarmValue = nil  -- Clear stored value
        end
        
        -- Remove blind effect
        local removeBlindSuccess, removeBlindErr = pcall(function()
            types.Actor.activeEffects(self):remove(core.magic.EFFECT_TYPE.Blind)
        end)
        
        if removeBlindSuccess then
            log("[BLACKJACK SLEEP] Removed blind effect - NPC vision restored")
        else
            log("[BLACKJACK SLEEP] Could not remove blind effect:", removeBlindErr)
        end
        
        -- Remove blind effect (Moved resets to onHit to maintain memory across wake-up window)
        
        -- Notify global script that NPC is conscious again
        -- This will cancel the detection pulse
        core.sendGlobalEvent('AntiTheft_NPCConscious', {
            npcId = self.id
        })
        log("[BLACKJACK SLEEP] Sent conscious event directly to global - pulse cancelled / wander started")
        
        -- Check if NPC was discovered by others while unconscious
        if not wasDiscoveredByOthers then
            -- NPC was NOT discovered - start 60-second witness timer
            log("[BLACKJACK SLEEP] ★ NPC woke up undiscovered - starting 60-second witness window")
            
            local witnessStartTime = core.getRealTime()
            local witnessEndTime = witnessStartTime + 60
            
            -- Helper function for recursion
            local witnessCallback 
            witnessCallback = function()
                local currentTime = core.getRealTime()
                
                -- Check if 60 seconds have passed
                if currentTime >= witnessEndTime then
                    log("[BLACKJACK SLEEP] Witness window expired - NPC did not spot player")
                    witnessTimer = nil
                    return
                end
                
                -- Check if NPC can see player
                local player = nearby.players[1]
                
                if player then
                    -- Calculate distance to player
                    local dist = (self.position - player.position):length()
                    
                    -- Only check LoS if within reasonable range (e.g., 2000 units)
                    if dist <= 2000 then
                        -- Check line of sight using nearby module
                        -- Use eye level (approx +150 units z) to avoid ground clutter/terrain blocking
                        local zOffset = util.vector3(0, 0, 150)
                        local startPos = self.position + zOffset
                        local endPos = player.position + zOffset
                        local rayResult = nearby.castRay(startPos, endPos)
                        
                        if not rayResult or not rayResult.hit then
                            -- Player spotted! Apply bounty and attack
                            log("[BLACKJACK SLEEP] ★★★ VICTIM SPOTTED PLAYER ★★★")
                            
                            -- CANCEL WAKE UP WANDER IMMEDIATELY
                            core.sendGlobalEvent('AntiTheft_StopWakeUpWander', { npcId = self.id })
                            
                            local stunBounty = settings.bounties:get('stunNPCBounty') or 300
                            
                            -- Apply bounty if player wasn't spotted during the hit (and bounty not yet applied)
                            -- Note: This block runs if player IS spotted just now upon waking
                            if not wasSpottedDuringHit then
                                log("[BLACKJACK SLEEP] Applying " .. stunBounty .. " gold bounty for witness (Victim)")
                                
                                -- Trigger reaction voice on the victim
                                local npcRecord = types.NPC.record(self)
                                if npcRecord then
                                    local race = npcRecord.race:lower():gsub(" ", "")
                                    local gender = npcRecord.isMale and "male" or "female"
                                    core.sendGlobalEvent('AntiTheft_PlayDetectionVoice', { 
                                        npcId = self.id, 
                                        race = race, 
                                        gender = gender 
                                    })
                                end

                                -- Send bounty event through player relay (Targeting Player Script)
                                player:sendEvent("AntiTheft_Relay_SleepBounty", { 
                                    amount = stunBounty, 
                                    npcId = self.id 
                                })
                                wasSpottedDuringHit = true
                            else
                                log("[BLACKJACK SLEEP] Victim woke up and saw player, but crime was already reported. Skipping redundant shout/bounty.")
                            end
                            
                            -- Notify player script to expect combat/arrest from this witness
                            player:sendEvent("AntiTheft_NotifyWitnessAttack", { npcId = self.id })
                            
                            if isGuard(self) then
                                log("[BLACKJACK SLEEP] Victim is GUARD - Initiating ARREST (Pursue + ForceDialog)")
                                
                                -- Revert to 'Pursue' pkg as requested.
                                -- Added 0.3s delay to ensure bounty is applied first
                                async:newUnsavableSimulationTimer(0.3, function()
                                    if self and self:isValid() and player then
                                        self:sendEvent('StartAIPackage', {
                                            type = 'Pursue',
                                            target = player
                                        })
                                    end
                                end)
                                
                                -- Notify player script to monitor distance and force dialogue
                                player:sendEvent("AntiTheft_ExpectArrest", { npcId = self.id })
                            else
                                log("[BLACKJACK SLEEP] Victim is CIVILIAN")
                                handleCivilianReaction(self, player)
                            end
                            
                            -- Cancel witness timer
                            witnessTimer = nil
                            return
                        end
                    end
                end
                
                -- Continue witness timer for next second
                -- Use the FUNCTION itself as the callback, not the handle
                witnessTimer = async:newUnsavableSimulationTimer(1, witnessCallback)
            end
            
            -- Start the timer
            witnessTimer = async:newUnsavableSimulationTimer(1, witnessCallback)
        else
            log("[BLACKJACK SLEEP] NPC was discovered by others - no witness timer")
        end
        
        -- Reset discovered flag for future blackjack hits
        wasDiscoveredByOthers = false
        
        -- Cancel the sleep timer if it's running
        if sleepTimerHandle then
            sleepTimerHandle = nil
        end
    end
    
end, 1 * time.second)  -- Check every second

----------------------------------------------------------------------
-- Return event handlers for body discovery tracking
----------------------------------------------------------------------
return {
    eventHandlers = {
        S3CombatTargetAdded = function(target)
            -- Check if this NPC is in a Fleeing state that needs restoration
            if fleeRestoreData then
                log("[S3CombatTargetAdded] NPC", self.id, "entered combat while Fleeing. Initiating restoration timer.")
                
                -- Clear flag immediately to prevent double-trigger
                local data = fleeRestoreData
                fleeRestoreData = nil
                
                -- Wait 3 seconds then restore original behavior
                async:newUnsavableSimulationTimer(3, function()
                    log("[FleeRestore] Restoration Timer Expired for", self.id)
                    
                    if types.NPC.stats.ai.fight(self) then types.NPC.stats.ai.fight(self).base = data.fight end
                    if types.NPC.stats.ai.flee(self) then types.NPC.stats.ai.flee(self).base = data.flee end
                    
                    self:sendEvent('RemoveAIPackages')
                    log("[FleeRestore] Combat Cancelled & Stats Restored (Fight:", data.fight, "Flee:", data.flee, ")")
                end)
            end
        end,
        -- Event sent by global script when this NPC's unconscious body is discovered
        AntiTheft_BodyDiscovered = function(data)
            if data and data.npcId == self.id then
                -- This NPC's body was discovered by another NPC
                wasDiscoveredByOthers = true
                log("[BLACKJACK SLEEP] Body discovered by another NPC - victim will not become witness")
            end
        end,
        
        -- Flee Effects Handler (Triggered by Global)
        AntiTheft_ApplyFleeEffectsLocal = function(data)
            -- EXTENSIVE DEBUG LOGGING
            local debugPrefix = "[FLEE-DEBUG " .. self.id .. "] "
            log(debugPrefix .. "Event received.")
            
            -- Safety: Never run this on the player
            if self.type == types.Player then
                log(debugPrefix .. "BLOCKED: Self is Player.")
                return
            end

            if not data then 
                log(debugPrefix .. "ERROR: No data received.")
                return 
            end
            
            local requestedStance = data.stance
            log(debugPrefix .. "Requested Stance: " .. tostring(requestedStance))
            log(debugPrefix .. "Types.Actor.STANCE.Weapon: " .. tostring(types.Actor.STANCE.Weapon))

            if requestedStance then
                -- 1. Set Stance
                types.Actor.setStance(self, types.Actor.STANCE.Weapon)
                log(debugPrefix .. "SetStance called.")
                
                -- Only apply effects if entering Flee/Weapon stance (Stance 2 - Weapon)
                if requestedStance == types.Actor.STANCE.Weapon then
                    log(debugPrefix .. "ENTERING FLEE MODE (Weapon Stance)")
                    
                    -- 2. Drain Magicka
                    if types.Actor.stats.dynamic.magicka(self) then
                        local mag = types.Actor.stats.dynamic.magicka(self)
                        log(debugPrefix .. "Magicka before: " .. mag.current)
                        mag.current = 0
                        log(debugPrefix .. "Magicka drained to 0")
                    else 
                        log(debugPrefix .. "Magicka stat not found.")
                    end

                    -- 3. Enforce Silence (Magnitude 10000)
                    local activeEffects = types.Actor.activeEffects(self)
                    if activeEffects then
                        local silenceEffect = activeEffects:getEffect(core.magic.EFFECT_TYPE.Silence)
                        local currentMag = silenceEffect and silenceEffect.magnitude or 0
                        local delta = 10000 - currentMag
                        activeEffects:modify(delta, core.magic.EFFECT_TYPE.Silence)
                        log(debugPrefix .. "Silence enforced. Old: " .. currentMag .. " Delta: " .. delta)
                    else
                        log(debugPrefix .. "ActiveEffects interface missing.")
                    end

                    -- 3.5 Clear Selected Castable (Prevent current cast)
                    if types.Actor.clearSelectedCastable then
                        types.Actor.clearSelectedCastable(self)
                        log(debugPrefix .. "types.Actor.clearSelectedCastable(self) called.")
                    else
                        log(debugPrefix .. "WARN: types.Actor.clearSelectedCastable not available.")
                    end

                   -- 4. Drain Charges of ALL Items with Charge (Inventory + Equipped)
fleeItemCharges = {} 
log(debugPrefix .. "Starting Item Scan (Robust Mode)...")

local inventory = types.Actor.inventory(self)
local itemTypesToCheck = { types.Weapon, types.Armor, types.Clothing }
local totalItemsScanned = 0
local drainedCount = 0

for _, itemType in ipairs(itemTypesToCheck) do
    local items = inventory:getAll(itemType)
    for _, item in ipairs(items) do
        totalItemsScanned = totalItemsScanned + 1
        local rec = itemType.record(item)
        local debugId = rec.id
        
        -- Check if THIS specific item has an enchantment in its record
        if rec.enchant and rec.enchant ~= "" then
            -- Also verify the itemType supports enchantmentCharge
            if itemType.enchantmentCharge then
                local chargeStat = itemType.enchantmentCharge(item)
                if chargeStat then
                    local current = chargeStat.current
                    log(debugPrefix .. "Examine: " .. debugId .. " Charge: " .. tostring(current))
                    
                    -- Only drain if it has logic-relevant charge (>0)
                    if current > 0 then
                         -- Store original
                         fleeItemCharges[item] = current
                         -- Drain
                         chargeStat.current = 0
                         drainedCount = drainedCount + 1
                         log(debugPrefix .. "  >> DRAINED: " .. debugId .. " (Was " .. current .. ")")
                    end
                end
            else
                log(debugPrefix .. "Examine: " .. debugId .. " Has enchant but type doesn't support enchantmentCharge")
            end
        end
    end
end
log(debugPrefix .. "Item Scan Complete. Scanned: " .. totalItemsScanned .. " Drained: " .. drainedCount)
                    
                    -- 5. Remove Scrolls (Temp Disable)
                    fleeScrolls = {}
                    local inventory = types.Actor.inventory(self)
                    local books = inventory:getAll(types.Book)
                    local scrollsRemoved = 0
                    
                    for _, item in ipairs(books) do
                        local record = types.Book.record(item)
                        if record and record.enchantment then
                            table.insert(fleeScrolls, { recordId = record.id, count = item.count })
                            inventory:remove(item)
                            scrollsRemoved = scrollsRemoved + 1
                            log(debugPrefix .. "Removed Scroll: " .. record.id)
                        end
                    end
                    log(debugPrefix .. "Total Scrolls Removed: " .. scrollsRemoved)

                elseif requestedStance == types.Actor.STANCE.Nothing then
                    log(debugPrefix .. "EXITING FLEE MODE (Stance Nothing)")
                
                    -- Cleanup: Remove Silence (Reset magnitude)
                    local silenceEffect = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Silence)
                    if silenceEffect and silenceEffect.magnitude > 0 then
                         types.Actor.activeEffects(self):modify(-(silenceEffect.magnitude), core.magic.EFFECT_TYPE.Silence)
                         log(debugPrefix .. "Silence removed.")
                    end
                    
                    -- Cleanup: Restore Item Charges (Moved to Global)
                    
                    -- Cleanup: Restore Scrolls (Moved to Global)
                else 
                     log(debugPrefix .. "Unknown Stance Requested: " .. tostring(requestedStance))
                end
            end
        end,
        
        -- Event to initialize fleeing state locally (Self modifies Self)
        AntiTheft_ApplyFleeStats = function(data)
            log("[AntiTheft_ApplyFleeStats] Modifying AI stats for FLEE behavior on", self.id)
            
            -- Store original values for restoration
            local originalFight = 90
            local originalFlee = 0
            if types.NPC.stats.ai.fight(self) then originalFight = types.NPC.stats.ai.fight(self).base end
            if types.NPC.stats.ai.flee(self) then originalFlee = types.NPC.stats.ai.flee(self).base end

            fleeRestoreData = {
                fight = originalFight,
                flee = originalFlee,
                timestamp = core.getRealTime()
            }

            -- 1. Modify AI Stats (Fight=0, Flee=100)
            if types.NPC.stats.ai.fight(self) then types.NPC.stats.ai.fight(self).base = 0 end
            if types.NPC.stats.ai.flee(self) then types.NPC.stats.ai.flee(self).base = 100 end
            

            -- 3. Initial Setup: Set Stats Only
            -- Silence/Demoralize/Magicka Drain moved to S3CombatTargetAdded to ensure they persist after combat init
            
            -- 4. Force Combat to Evaluate new stats
            self:sendEvent('StartAIPackage', { 
                type = 'Combat', 
                target = data and data.target or nil 
            })
                        -- 2. Force Stance 0 (Nothing/Spell) to prevent weapon drawing during flee
            types.Actor.setStance(self, types.Actor.STANCE.Nothing)
            log("[ApplyFleeStats] Forced stance to 0 (Nothing) - NPC will flee without weapon")
            
            -- Debug: Verify stats
            local newFight = types.NPC.stats.ai.fight(self).base
            local newFlee = types.NPC.stats.ai.flee(self).base
            log("[ApplyFleeStats] Stats verified - Fight:", newFight, "(Expected 0) | Flee:", newFlee, "(Expected 100)")
            log("[ApplyFleeStats] Combat Started. Waiting for S3CombatTargetAdded event to trigger Silence & Restoration.")
        end,

        -- Flee Confirmation Event (Relayed from Player script when combat starts)
        AntiTheft_FleeConfirm = function(target)
            -- Check if this NPC is in a Fleeing state that needs restoration
            if fleeRestoreData then
                log("[AntiTheft_FleeConfirm] NPC", self.id, "entered combat while Fleeing. APPLYING SILENCE & RESTORATION TIMER.")
                
                -- Capture data closure
                local data = fleeRestoreData
                fleeRestoreData = nil -- Clear immediately to prevent loop/double trigger

                -- [[ APPLY EFFECT LOGIC MOVED TO GLOBAL ]] --
                core.sendGlobalEvent('AntiTheft_ApplyGlobalFlee', { npcId = self.id })
                log("[AntiTheft_FleeConfirm] Sent 'AntiTheft_ApplyGlobalFlee' event to Global Script")
                
                -- Wait 4 seconds then restore (Wait... previous logical duration was ~30s?)
                -- The restore timer is set to 30s in original code.
                async:newUnsavableSimulationTimer(30, function()
                    log("[FleeRestore] Timer Expired for", self.id)
                    
                    if types.NPC.stats.ai.fight(self) then types.NPC.stats.ai.fight(self).base = data.fight end
                    if types.NPC.stats.ai.flee(self) then types.NPC.stats.ai.flee(self).base = data.flee end
                    
                    self:sendEvent('RemoveAIPackages')
                    
                    -- Reset Stance via Global Script
                    core.sendGlobalEvent('AntiTheft_RemoveGlobalFlee', { npcId = self.id })
                    
                    log("[FleeRestore] Combat Cancelled, Stance Reset Requested & Stats Restored (Fight:", data.fight, "Flee:", data.flee, ")")
                end)
            else
                -- log("[S3CombatTargetAdded] Normal combat start (No Flee Data)")
            end
        end
    }
}

