--[[
	Stealth
	Author: mort
	v1.0
]] --

local config = require("stealth.config")

-- Ensure that the player has the necessary MWSE version.
if (mwse.buildDate == nil or mwse.buildDate < 20210412) then
	mwse.log("[Stealth] Build date of %s does not meet minimum build date of 2021-04-12.", mwse.buildDate)
	event.register(
		"initialized",
		function()
			tes3.messageBox("Stealth requires a newer version of MWSE. Please run MWSE-Update.exe.")
		end
	)
	return
end

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    require("stealth.mcm")
end)

local function restoreInvisVar(e)
	--morrowind will decrement invisibility at the end of the activate frame below, this restores it
	tes3.mobilePlayer.invisibility = tes3.mobilePlayer.invisibility + 1
end

local function invisFix(e)
    if tes3.menuMode() then
        return
    end
	
	if config.invisFix == false then
		return
	end

    if e.activator == tes3.player then
		if tes3.mobilePlayer.invisibility == 1 then
        -- remove player invisibility effect
			tes3.removeEffects{reference=e.activator, effect=tes3.effect.invisibility}
			tes3.mobilePlayer.invisibility = tes3.mobilePlayer.invisibility-1
        -- force observation
			tes3.worldController.mobController.processManager:detectPresence(tes3.mobilePlayer, true)
			timer.start({duration = 1, callback = restoreInvisVar})
			--return false
		end
    end
end

local footwearType = 0

local function getFootwear()
	local equippedBootsArmor = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.armor,slot=5})
	
	if (equippedBootsArmor) then
		footwearType = (equippedBootsArmor.object.weightClass)
	else
		footwearType = 0
	end
end

local function sneakAttack(e)
	if e.attacker == tes3.player and config.sneakAttack and e.targetMobile then 
		--tes3.messageBox(tes3.player.position:distance(e.targetMobile.position))
		if tes3ui.findMenu(GUI_Sneak_Multi):findChild(GUI_Sneak_Icon).visible == true and tes3.player.position:distance(e.targetMobile.position) < 120 then
			e.hitChance = 100
		end
	end
end

local function forceStealthCheck(e)
	tes3.worldController.mobController.processManager:detectPresence(tes3.mobilePlayer, true)
end

local function startStealthCheck(e)
	getFootwear()
	timer.start({duration = 2, callback = forceStealthCheck, iterations=-1})
end

local function lightCheck(e)
	--night/day
	--torches
	--cell ambient brightness
	for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.light) do
		print(ref)
	end
end

local function detectSneak(e)
	
	if config.modEnabled == false then return end
	local macp = tes3.mobilePlayer
	if (e.target ~= macp) then
		return
	end

	local detector = e.detector

	-- Get view multiplier.
	local viewMultiplier = config.noViewMultiplier/100
	local facingDifference = math.abs(detector:getViewToActor(macp))
	--tes3.messageBox(facingDifference)
	if (facingDifference < config.viewAngle) and macp.invisibility < 1 then --what is considered "behind" an npc is reduced by 1/3
		viewMultiplier = config.viewMultiplier --standing in front of an npc means you are seen, basically unless you are a god
	end

	-- Add bonuses for sneaking.
	local playerScore = 0
	if (macp.isSneaking) then
		--local fSneakSkillMult = config.sneakSkillMult/100
		local sneakTerm = macp.sneak.current * config.sneakSkillMult/100
		local agilityTerm = macp.agility.current * 0.2
		local luckTerm = macp.luck.current * 0.1
		playerScore = playerScore + sneakTerm + agilityTerm + luckTerm
	end

	-- Adjust for player's boot weight.
	-- now adds 10-20 penalty if you are wearing medium/heavy armor. light armor is the same as no shoes
	playerScore = playerScore - footwearType * config.bootMultiplier

	-- Get distance term.
	--local fSneakDistanceBase = tes3.findGMST(tes3.gmst.fSneakDistanceBase).value
	--local fSneakDistanceMultiplier = 0.002 --gmst value has floating point error
	local distanceTerm = config.sneakDistanceBase/100 + detector.reference.position:distance(macp.reference.position) / config.sneakDistanceMultiplier

	-- Multiply main terms together.
	local fatigueTerm = macp:getFatigueTerm()
	playerScore = playerScore * fatigueTerm * distanceTerm

	-- Add on chameleon modifier.
	playerScore = playerScore + (config.chameleonMultiplier/100 * macp.chameleon) --chameleon only counts for half
	
	-- Invisibility bonus, defaults to 0 but can be manually restored
	if (macp.invisibility > 0) then
		playerScore = playerScore + config.invisibilityBonus
	end

	-- Get detector score.
	local sneakterm
	
	if detector.sneak then --it's an npc
		sneakterm = detector.sneak.current
	else --it's a creature
		sneakterm = detector.stealth.current
	end
	
	local detectorScore = (sneakterm * config.npcSneakMultiplier/100 --most npcs have very low sneak, too easy to fool
			+ detector.agility.current * 0.2
			+ detector.luck.current * 0.1
			- detector.blind)
		* viewMultiplier * detector:getFatigueTerm()

	-- Set detection flags.
	local finalScore = playerScore - detectorScore
	local detected = (config.sneakDifficulty >= finalScore) --no more randomization
	detector.isPlayerDetected = detected
	detector.isPlayerHidden = not detected

	--tes3.messageBox("%s %s = %d > %.1f - %.1f", detector.reference, distanceTerm, config.sneakDifficulty, playerScore, detectorScore )
	
	local alphaval = tes3ui.findMenu(GUI_Sneak_Multi):findChild(GUI_Sneak_Icon).children[1].children[1].alpha
	if finalScore >= config.sneakDifficulty and config.adjustSneakIcon then
		--tes3.messageBox(math.clamp(finalScore/50*0.5,0,1))
		tes3ui.findMenu(GUI_Sneak_Multi):findChild(GUI_Sneak_Icon).children[1].children[1].alpha = math.clamp(finalScore/config.sneakDifficulty*0.4,0,1)
	end
	
	-- Let the event know to return the right value.
	e.isDetected = detected
	--playerSpotted = e.isDetected
end


local function onInitialized()

	-- Register necessary GUI element IDs.
	GUI_Sneak_Multi = tes3ui.registerID("MenuMulti")
	GUI_Sneak_Icon = tes3ui.registerID("MenuMulti_sneak_icon")

	--event.register("simulate", forceStealthCheck)
	event.register("equipped",getFootwear)
	event.register("unequipped",getFootwear)
	event.register("detectSneak", detectSneak)
	event.register("calcHitChance",sneakAttack)
	event.register("loaded", startStealthCheck)
	event.register("activate", invisFix)
	
	mwse.log("[Stealth] Initialized.")
end
event.register("initialized", onInitialized)