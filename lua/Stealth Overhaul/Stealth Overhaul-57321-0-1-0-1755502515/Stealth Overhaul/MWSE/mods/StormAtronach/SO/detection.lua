local config        = require("StormAtronach.SO.config")
local interop       = require("StormAtronach.SO.interop")
local util          = require("StormAtronach.SO.util")
local investigation = require("StormAtronach.SO.investigation")

local log = mwse.Logger.new({
	name = "Stealth Overhaul",
	level = config.logLevel,
})

local detection = {}
local npcsTracking = {}

---@param e loadEventData
local function onLoad(e)
	npcsTracking = {} 		 -- clean up the npcsTracking table
    staticsCooldown = {}
end
event.register(tes3.event.loaded,onLoad)

local function getFootwear()
	local equippedBootsArmor = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.armor,slot=5})
	local footwearType = 0
	if (equippedBootsArmor) then
		footwearType = (equippedBootsArmor.object.weightClass)
	else
		footwearType = 0
	end
    return footwearType
end


--- @param npcMobile tes3mobileNPC|tes3mobileCreature
local function onHearingNoise(npcMobile)
    local mp = tes3.mobilePlayer
    local detector = npcMobile
    -- A modified version of the vanilla logic for the player
    local playerScore = 0
    -- 1.1 Skill term
    if mp.isSneaking then
        local sneakTerm     = mp.sneak.current*config.sneakSkillMult/100
        local agilityTerm   = mp.agility.current*0.2
        local luckTerm      = mp.luck.current*0.1
        playerScore = playerScore + sneakTerm + agilityTerm + luckTerm
    end
    -- 1.2 Boots term
    local footwearType = getFootwear() or 0
    playerScore = playerScore - footwearType*config.bootMultiplier

    -- 1.3 Distance term
    local distanceTerm = config.sneakDistanceBase/100 + detector.reference.position:distance(mp.reference.position) / config.sneakDistanceMultiplier

    -- 1.4 Fatigue term
    local fatigueTerm = mp:getFatigueTerm()

    -- No invisibility bonus or chamaleon bonus
    playerScore = playerScore*distanceTerm*fatigueTerm

    -- Now for NPC score
    local sneakTermD = 0
    if detector.sneak then --it's an npc
		sneakTermD = detector.sneak.current
	else --it's a creature
		sneakTermD = detector.stealth.current
	end
    local detectorScore = (sneakTermD + config.npcSneakBonus --most npcs have very low sneak, too easy to fool
			+ detector.agility.current * 0.2
			+ detector.luck.current * 0.1
			- (detector.sound or 0)) *config.hearingMultiplier* detector:getFatigueTerm()

    -- Again, the same scoring as before
    local finalScore    = playerScore - detectorScore
    local heard      = config.sneakDifficulty >= finalScore
    return heard
end

local function didTheyHearThat()
        local mobileActors = tes3.findActorsInProximity({reference = tes3.player, range = 2000})
        local data = util.getData()
        for _,actor in pairs(mobileActors) do
            if actor == tes3.mobilePlayer then goto continue end
            -- If the actor has been called in the last 10 seconds, ignore them
            if npcsTracking[actor.object.id] then
                local cooldownCheck = tes3.getSimulationTimestamp(false) - npcsTracking[actor.object.id]
                if cooldownCheck < 10 then goto continue end
            end
			local actorName = actor.reference and actor.reference.object.name:lower()
            -- Is it a hostile actor or has the player stolen from them?
            local fightCheck = actor.fight < 80
            local stolenCheck = data.currentCrime.npcs[actorName] and true or false
            log:debug("Name: %s,Fight check: %s, Stolen Objects: %s",actor.reference.object.name, fightCheck, stolenCheck)
            if fightCheck and (not stolenCheck) then goto continue end
            
            log:debug("Actor detected, starting onHearingNoise for %s, actor name: %s",actor.object.id,actorName)
            local wasHeard = onHearingNoise(actor)
            log:debug("was heard? %s",wasHeard)
            if wasHeard then
                if actor.actorType == tes3.actorType.npc then
                tes3.messageBox("What was that?")
                elseif actor.actorType == tes3.actorType.creature then
                tes3.messageBox("Grroarr?")
                end
                investigation.startTravel(actor.reference,tes3.player.position)
                npcsTracking[actor.object.id] = tes3.getSimulationTimestamp(false)
            end
            ::continue::
        end
end

-- Name of footstep sounds 
local footStepName = {
	["footbareleft"] = true,
	["footbareright"] = true,
	["footlightleft"] = true,
	["footlightright"] = true,
	["footmedleft"] = true,
	["footmedright"] = true,
	["footheavyleft"] = true,
	["footheavyright"] = true,
    ["footwaterleft"] = true,
    ["footwaterright"] = true,
}

local function onAddSound(e)
    if e.isVoiceover then return end
    if e.reference ~= tes3.player then return end

    local id = e.sound.id:lower()
    if footStepName[id] then
        --tes3.messageBox(e.sound.id:lower())
        didTheyHearThat()
    end
end
event.register("addSound", onAddSound,{priority = 999999}) -- The footsteps from 1st person overhaul are at 1 million

--While levitating
local messagesOnCollision = {"BONK!", "OUCH", "AIEE", "KABONK", "WHUMP","SPLOINK","THWOK","KADONK"}
--- @param e collisionEventData
local function onCollision(e)
    local target = e.target
    if not target then return end
    if tes3.mobilePlayer.levitate < 1 then return end

    if target.object.objectType == tes3.objectType.static then
        if staticsCooldown[e.target.id:lower()] then
        local cooldownCheck = tes3.getSimulationTimestamp(false) - staticsCooldown[e.target.id:lower()] < 5
        if cooldownCheck then return end
        end

        staticsCooldown[e.target.id:lower()] = tes3.getSimulationTimestamp(false)
        tes3.messageBox(messagesOnCollision[math.random(1,#messagesOnCollision)])
        didTheyHearThat()
    end
end
event.register(tes3.event.collision, onCollision, { filter = ("PlayerSaveGame"):lower() })

--- @param e detectSneakEventData
local function onVisualContact(e)
    -- Heavily yoinked from Stealth Improved. Thanks Mort!

    -- 1. We get the player term
    local mp = tes3.mobilePlayer
    local playerScore = 0
    -- 1.1 Skill term
    if mp.isSneaking then
        local sneakTerm     = mp.sneak.current*config.sneakSkillMult/100
        local agilityTerm   = mp.agility.current*0.2
        local luckTerm      = mp.luck.current*0.1
        playerScore = playerScore + sneakTerm + agilityTerm + luckTerm
    end
    -- 1.2 Boots term
    local footwearType = getFootwear() or 0
    playerScore = playerScore - footwearType*config.bootMultiplier

    -- 1.3 Distance term
    local distanceTerm = config.sneakDistanceBase/100 + e.detector.reference.position:distance(mp.reference.position) / config.sneakDistanceMultiplier
    -- Here comes the spice: Chamaleon adds to the distance term
    distanceTerm = distanceTerm + mp.chameleon/100

    -- 1.4 Fatigue term
    local fatigueTerm = mp:getFatigueTerm()

    -- 1.5 Invisibility bonus
    local invisibilityBonus = 0
    if mp.invisibility > 0 then
        invisibilityBonus = config.invisibilityBonus or 30
    end

    -- Ok, time to calculate the actual score
    playerScore = playerScore*fatigueTerm*distanceTerm + invisibilityBonus

    -- Now for NPC score
    local sneakTermD = 0
    local detector = e.detector
    if detector.sneak then --it's an npc
		sneakTermD = detector.sneak.current
	else --it's a creature
		sneakTermD = detector.stealth.current
	end
    local detectorScore = (sneakTermD + config.npcSneakBonus --most npcs have very low sneak, too easy to fool
			+ detector.agility.current * 0.2
			+ detector.luck.current * 0.1
			- detector.blind) *config.viewMultiplier* detector:getFatigueTerm()

    -- Ok, for the final scoring, straight from Mort's book
    local finalScore    = playerScore - detectorScore
    local detected      = config.sneakDifficulty >= finalScore

return detected
end

--- @param e detectSneakEventData
local function detectSneakCallback(e)
    -- If the detector's target is not the player, then do nothing
	if e.target ~= tes3.mobilePlayer then return end
    -- If the detector is in combat, do nothing
    if e.detector.inCombat then return end

    local distance = e.detector.position:distance(tes3.player.position)
    if distance < 25 then e.isDetected = true return end
    --- if distance > 1250 then return end -- Above 1250, let vanilla logic apply?


    local detectorEye = e.detector.position:copy()
    detectorEye.z = detectorEye.z + e.detector.height
    local playerEye = tes3.getPlayerEyePosition()
    local angle =  config.detectionAngle or 80-- degrees


    -- Calculate the angle between the detector's view vector and the player's position
    local viewAngle = math.abs(e.detector:getViewToPoint(playerEye))

    -- If the angle is less than the threshold, the player can be detected
    if viewAngle < angle then
    --createLineRed( detectorEye, playerEye,"sneakDetectionRed")
    --log:debug("You were seen by: %s, distance: %s, vanilla: %s", e.detector.reference.id, distance,e.isDetected)
    -- Check if the player is detected
    e.isDetected = onVisualContact(e) or false
    -- If detected, trigger the visual detection event
        if e.isDetected then
           -- log:debug("Attempting to trigger visual detection event")
            event.trigger("SA_SO_visualDetection", e)
        end
    else
    --createLineGreen( detectorEye, playerEye, "sneakDetectionGreen")
    log:debug("You were NOT seen by: %s, distance: %s, vanilla: %s", e.detector.reference.id, distance, e.isDetected)

    log:debug("Attempting to trigger no visual detection event")
    e = event.trigger("SA_SO_noVisualDetection",e)
        if not e.claim then
            e.claim = true
            e.isDetected = false
        end
    end


end
event.register(tes3.event.detectSneak, detectSneakCallback, {priority = 1000})

return detection