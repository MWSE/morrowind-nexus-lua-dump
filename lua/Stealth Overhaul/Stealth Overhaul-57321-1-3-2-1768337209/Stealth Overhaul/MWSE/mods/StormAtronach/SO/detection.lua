local config        = require("StormAtronach.SO.config")
local interop       = require("StormAtronach.SO.interop")
local util          = require("StormAtronach.SO.util")
local investigation = require("StormAtronach.SO.investigation")

local log = mwse.Logger.new()

local detection = {}
local npcsTracking = {}
local staticsCooldown = {}

-- Track the worst detection state across all checks
local worstDetection = {
    score = 0,
    max = 100,
    source = nil, -- "visual" or "audio"
}

local function resetWorstDetection()
    worstDetection.score = 0
    worstDetection.max = 100
    worstDetection.source = nil
end

local function updateFillbarIfWorse(finalScore, maxScore, source)
    -- Lower score = closer to detection, so we want the minimum
    if finalScore < worstDetection.score then
        log:debug("Fillbar updated: %s detection (score: %.1f, max: %.1f) worse than previous (%.1f)", 
            source, finalScore, maxScore, worstDetection.score)
        worstDetection.score = finalScore
        worstDetection.max = maxScore
        worstDetection.source = source
        
        util.fillbarCurrent = math.abs(finalScore)
        util.fillbarMax = maxScore
    end
end

local function onLoad()
	npcsTracking = {} 		 -- clean up the npcsTracking table
    staticsCooldown = {}
    resetWorstDetection()
    log:debug("Detection system reset on load")
end
event.register(tes3.event.loaded, onLoad)

-- Get boot weight class (0 = barefoot/clothing, 1 = light, 2 = medium, 3 = heavy)
local function getFootwearWeight()
    local boots = tes3.getEquippedItem({
        actor = tes3.player,
        objectType = tes3.objectType.armor,
        slot = tes3.armorSlot.boots
    })
    local weight = boots and boots.object.weightClass or 0
    log:trace("Footwear weight class: %d", weight)
    return weight
end

-- Calculate base player stealth score from skills
local function getPlayerSkillScore(mp)
    local score = (mp.sneak.current * config.sneakSkillMult / 100)
         + (mp.agility.current * 0.2)
         + (mp.luck.current * 0.1)
    log:trace("Player skill score: %.1f (sneak: %d, agi: %d, luck: %d)", 
        score, mp.sneak.current, mp.agility.current, mp.luck.current)
    return score
end

-- Calculate detector's perception score
---@param detector tes3mobileNPC|tes3mobileCreature
---@param multiplier number
---@param penaltyStat number|nil Sound for audio, blind for visual
local function getDetectorScore(detector, multiplier, penaltyStat)
    ---@diagnostic disable-next-line: undefined-field
    local sneakStat = detector.sneak and detector.sneak.current or detector.stealth.current
    local score = (sneakStat + config.npcSneakBonus
          + detector.agility.current * 0.2
          + detector.luck.current * 0.1
          - (penaltyStat or 0))
          * multiplier * detector:getFatigueTerm()
    log:trace("Detector score: %.1f (sneak: %d, agi: %d, penalty: %d, mult: %.2f)", 
        score, sneakStat, detector.agility.current, penaltyStat or 0, multiplier)
    return score
end

-- Calculate max score for fillbar display
local function calculateMaxScore(finalScore)
    return finalScore < 0 and (config.sneakDifficulty - finalScore) or config.sneakDifficulty
end

-- Get random message from table
local function randomMessage(messages)
    return messages[math.random(#messages)]
end


--- Audio detection check for a single NPC/creature
---@param detector tes3mobileNPC|tes3mobileCreature
local function onHearingNoise(detector)
    local mp = tes3.mobilePlayer
    
    -- Player score (only get skill bonus when sneaking)
    local playerScore = mp.isSneaking and getPlayerSkillScore(mp) or 0
    playerScore = playerScore - getFootwearWeight() * config.bootMultiplier
    
    -- Distance and fatigue modifiers (no invisibility/chameleon for audio)
    local distance = detector.reference.position:distance(mp.reference.position)
    local distanceTerm = config.sneakDistanceBase / 100 + distance / config.sneakDistanceMultiplier
    playerScore = playerScore * distanceTerm * mp:getFatigueTerm()
    
    -- Detector score
    local detectorScore = getDetectorScore(detector, config.hearingMultiplier, detector.sound or 0)
    
    local finalScore = playerScore - detectorScore
    local heard = config.sneakDifficulty >= finalScore
    
    log:debug("Audio check vs %s: player=%.1f, detector=%.1f, final=%.1f, dist=%.0f, heard=%s",
        detector.reference.id, playerScore, detectorScore, finalScore, distance, heard)
    
    updateFillbarIfWorse(finalScore, calculateMaxScore(finalScore), "audio")
    util.heard = heard
    return heard
end

local noiseMessages = {
    "What was that?", "Wait, what?", "Something moved.", "Who goes there?",
    "Show yourself!", "That noise again.", "Did that creak?", "Door just creaked.",
    "Footsteps? Where?", "Rats again?", "That sounded weird.", "Not again...",
    "Another scrib?", "Definitely not wind.", "Something's off.", "Explain that sound.",
    "The ancestors again?", "I heard something.", "That was... odd.",
    "Who's there?", "Hmmm, strange...",
}

--- Check if nearby actors heard the player
local function didTheyHearThat()
    resetWorstDetection()
    
    local mobileActors = tes3.findActorsInProximity({ reference = tes3.player, range = 2000 })
    local data = util.getData()
    local mp = tes3.mobilePlayer
    local playerPos = tes3.player.position
    local now = tes3.getSimulationTimestamp(false)
    
    for _, actor in pairs(mobileActors) do
        ---@cast actor tes3mobileNPC
        if actor == mp then goto continue end
        
        -- Cooldown check
        local lastTime = npcsTracking[actor.object.id]
        if lastTime and (now - lastTime) < 10 then goto continue end
        
        -- Get actor info safely
        local ref = actor.reference
        local actorName = ref and ref.object and ref.object.name
        actorName = actorName and actorName:lower() or ""
        
        -- Hostility check: skip friendly actors who haven't been stolen from
        local disposition = actor.object and actor.object.disposition or 50
        local isHostile = actor.fight >= 70 or (actor.fight >= 83 and disposition <= 25)
        local stolenFrom = data.currentCrime.npcs[actorName] and true or false
        
        if not isHostile and not stolenFrom then goto continue end
        
        log:debug("Name: %s, Fight check: %s, Stolen Objects: %s", ref.object.name, isHostile, stolenFrom)
        log:debug("Actor detected, starting onHearingNoise for %s, actor name: %s", actor.object.id, actorName)
        
        local wasHeard = onHearingNoise(actor)
        log:debug("was heard? %s", wasHeard)
        
        if wasHeard then
            if actor.actorType == tes3.actorType.npc and not mp.inCombat and stolenFrom then
                tes3.messageBox(randomMessage(noiseMessages))
            end
            investigation.startTravel(ref, playerPos)
            npcsTracking[actor.object.id] = now
        end
        
        ::continue::
    end
end

-- Footstep sounds that trigger audio detection
local footstepSounds = {
    footbareleft = true, footbareright = true,
    footlightleft = true, footlightright = true,
    footmedleft = true, footmedright = true,
    footheavyleft = true, footheavyright = true,
    footwaterleft = true, footwaterright = true,
}

local function onAddSound(e)
    if e.isVoiceover or e.reference ~= tes3.player then return end
    
    if footstepSounds[e.sound.id:lower()] then
        if math.random(100) <= config.stepTriggerChance then
            log:trace("Footstep sound triggered audio check: %s", e.sound.id)
            didTheyHearThat()
        end
    end
end
event.register("addSound", onAddSound, { priority = 999999 })

local collisionMessages = { "BONK!", "OUCH", "AIEE", "KABONK", "WHUMP", "SPLOINK", "THWOK", "KADONK" }

---@param e collisionEventData
local function onCollision(e)
    if e.reference ~= tes3.player then return end
    if not e.target or tes3.mobilePlayer.levitate < 1 then return end
    if e.target.object.objectType ~= tes3.objectType.static then return end
    
    local targetId = e.target.id:lower()
    local now = tes3.getSimulationTimestamp(false)
    
    -- Cooldown check
    if staticsCooldown[targetId] and (now - staticsCooldown[targetId]) < 5 then return end
    
    log:debug("Collision with static while levitating: %s", targetId)
    staticsCooldown[targetId] = now
    tes3.messageBox(randomMessage(collisionMessages))
    didTheyHearThat()
end
event.register(tes3.event.collision, onCollision)

--- Visual detection check
---@param e detectSneakEventData
local function onVisualContact(e)
    local mp = tes3.mobilePlayer
    local detector = e.detector
    
    -- Player score (reduced effectiveness when not sneaking)
    local skillScore = getPlayerSkillScore(mp)
    local playerScore = mp.isSneaking and skillScore or math.clamp(0.25 * skillScore, 0, 50)
    playerScore = playerScore - getFootwearWeight() * config.bootMultiplier
    
    -- Distance term (chameleon extends effective distance)
    local distance = detector.reference.position:distance(mp.reference.position)
    local distanceTerm = config.sneakDistanceBase / 100 + distance / config.sneakDistanceMultiplier + mp.chameleon / 100
    
    -- Invisibility bonus
    local invisBonus = mp.invisibility > 0 and (config.invisibilityBonus or 30) or 0
    
    playerScore = playerScore * mp:getFatigueTerm() * distanceTerm + invisBonus
    
    -- Detector score (uses blind instead of sound)
    ---@diagnostic disable-next-line: param-type-mismatch
    local detectorScore = getDetectorScore(detector, config.viewMultiplier, detector.blind)
    
    local finalScore = playerScore - detectorScore
    local detected = config.sneakDifficulty >= finalScore
    
    log:debug("Visual check vs %s: player=%.1f, detector=%.1f, final=%.1f, dist=%.0f, cham=%d, invis=%d, detected=%s",
        detector.reference.id, playerScore, detectorScore, finalScore, distance, mp.chameleon, mp.invisibility, detected)
    
    updateFillbarIfWorse(finalScore, calculateMaxScore(finalScore), "visual")
    util.detected = detected
    return detected
end

--- @param e detectSneakEventData
local function detectSneakCallback(e)
    if e.target ~= tes3.mobilePlayer then return end
    if e.detector.inCombat then return end
    
    local distance = e.detector.position:distance(tes3.player.position)
    
    -- Auto-detect at point-blank range
    if distance < 25 then
        log:debug("Auto-detected by %s at point-blank range (%.0f units)", e.detector.reference.id, distance)
        e.isDetected = true
        return
    end
    
    local playerEye = tes3.getPlayerEyePosition()
    local viewAngle = math.abs(e.detector:getViewToPoint(playerEye))
    local detectionAngle = config.detectionAngle or 80
    
    if viewAngle < detectionAngle then
        -- Player is in detector's field of view
        log:trace("In FOV of %s (angle: %.1f < %d)", e.detector.reference.id, viewAngle, detectionAngle)
        e.isDetected = onVisualContact(e)
        if e.isDetected then
            log:debug("Detected by %s!", e.detector.reference.id)
            event.trigger("SA_SO_visualDetection", e)
        end
    else
        -- Player is outside field of view
        log:debug("Outside FOV of %s (angle: %.1f >= %d, dist: %.0f)", 
            e.detector.reference.id, viewAngle, detectionAngle, distance)
        local result = event.trigger("SA_SO_noVisualDetection", e)
        if not result.claim then
            e.claim = true
            e.isDetected = false
        end
    end
    
    -- Stabilize stealth icon
    e.detector.isPlayerDetected = e.isDetected
    e.detector.isPlayerHidden = not e.isDetected
end
event.register(tes3.event.detectSneak, detectSneakCallback, { priority = 1000 })

return detection