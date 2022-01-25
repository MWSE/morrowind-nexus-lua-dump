--[[
	Stealth
	Author: mort
	v1.1
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

--UI variables
local menuMultiFillbarsBlock = nil
local menuLightbar = nil

-- Register UI for standard HUD.
local ids = {
    LightbarBlock = tes3ui.registerID("Stealth:LightbarBlock"),
    Lightbar = tes3ui.registerID("Stealth:Lightbar"),
	Sidebar = tes3ui.registerID("Stealth:Sidebar")
}

-- Stealth Globals
local footwearType = 0
local lightMultiplier = 0

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    require("stealth.mcm")
end)

local function restoreInvisVar(e)
	--morrowind will decrement invisibility at the end of the activate frame below, this restores it
	tes3.mobilePlayer.invisibility = tes3.mobilePlayer.invisibility + 1
end

local function invisFix(e)

    if tes3.menuMode() then	return end
	if config.modEnabled == false then return end
	if config.invisFix == false then return end

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

local function getFootwear()
	local equippedBootsArmor = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.armor,slot=5})
	
	if (equippedBootsArmor) then
		footwearType = (equippedBootsArmor.object.weightClass)
	else
		footwearType = 0
	end
end

local function lightCheck()

	--base lighting term is 0.5, yes the player can change this option in settings but it might make the math way too weird
	local lightTerm = 0.5

	--weather
	--additional day stuff
	--hide bar during day?

	if tes3.player.cell.isInterior then
		for ref in tes3.player.cell:iterateReferences(tes3.objectType.light) do
			if tes3.testLineOfSight({reference1=ref,reference2=tes3.player}) then
				if (ref.light ~= nil) then
					local dist = ref.position:distance(tes3.player.position)
					if dist <= 150 then dist = 151 end --needed or math goes berserk
					local lightTest = 1/math.log10(dist/150)
					if lightTest > lightTerm then lightTerm = lightTest end
				end
			end
		end
	else
		--exterior
		lightTerm = config.viewMultiplier

--[[ 		if tes3.worldController.hour.value < 21 or tes3.worldController.hour.value > 5 then
			-- perfect darkness between 9 and 5
			-- variable time currently unused, math is hard
			--local timeMod = 8-math.abs(tes3.worldController.hour.value-13)
			-- todo
			-- ambient brightness as a function of hour of the day
			-- not a perfectly linear scale, as light diffuses through the atmosphere

		for _, cell in pairs(tes3.getActiveCells()) do
			for ref in cell:iterateReferences(tes3.objectType.light) do
				if tes3.testLineOfSight({reference1=ref,reference2=tes3.player}) then
					if (ref.light ~= nil) then
						local dist = ref.position:distance(tes3.player.position)
						if dist <= 150 then dist = 151 end
						local lightTest = 1/math.log10(dist/150)
						if lightTest > lightTerm then lightTerm = lightTest end --the light closest to you is going to be the final value
					end
				end
			end
		end
 ]]
		-- ash, blight, blizzard half visibility
		if tes3.getCurrentWeather().index == 6 or tes3.getCurrentWeather().index == 7 or tes3.getCurrentWeather().index == 9 then
			lightTerm = lightTerm/2
		end

	end

	for ref in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
		if (ref.light ~= nil) then
			if tes3.testLineOfSight({reference1=ref,reference2=tes3.player}) then
				local dist = ref.position:distance(tes3.player.position)
				if dist <= 150 then dist = 151 end --needed or math goes berserk
				local lightTest = 1/math.log10(dist/150)
				if lightTest > lightTerm then lightTerm = lightTest end
			end
		end
	end
	
	--tes3.messageBox(math.clamp(lightTerm,config.noViewMultiplier/100,config.viewMultiplier))
	--tes3.messageBox("%d %f", lightCount, (lightTerm-0.5)/config.viewMultiplier)

	local finalAlpha = math.clamp((lightTerm-0.5)/config.viewMultiplier,0,1.0)

	tes3ui.findMenu("MenuMulti"):findChild(ids.LightbarBlock):findChild(ids.Lightbar).alpha = finalAlpha

--[[ 
	if finalAlpha == 1.0 then
		tes3ui.findMenu("MenuMulti"):findChild(ids.LightbarBlock):findChild(ids.Lightbar).visible = false
	else
		tes3ui.findMenu("MenuMulti"):findChild(ids.LightbarBlock):findChild(ids.Lightbar).visible = true
	end ]]

	return math.clamp(lightTerm,config.noViewMultiplier/100,config.viewMultiplier)
end

local function sneakAttack(e)
	if e.attacker == tes3.player and config.modEnabled and config.sneakAttack and e.targetMobile then 
		--tes3.messageBox(tes3.player.position:distance(e.targetMobile.position))
		if tes3ui.findMenu(GUI_Sneak_Multi):findChild(GUI_Sneak_Icon).visible == true and tes3.player.position:distance(e.targetMobile.position) < 120 then
			e.hitChance = 100
		end
	end
end

local function forceStealthCheck(e)
	if config.modEnabled then
		tes3.worldController.mobController.processManager:detectPresence(tes3.mobilePlayer, true)
	end
end

local function forceLightCheck(e)
	if config.modEnabled and config.lightStealthEnabled then
		lightMultiplier = lightCheck()
	end
end

local function startStealthCheck(e)
	getFootwear()
	timer.start({duration = 1, callback = forceStealthCheck, iterations=-1})
	timer.start({duration = 0.5, callback = forceLightCheck, iterations=-1})
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
		if config.lightStealthEnabled then
			viewMultiplier = lightMultiplier
		else
			viewMultiplier = config.viewMultiplier --standing in front of an npc means you are seen, basically unless you are a god
		end
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

	local effectiveChameleonMagnitude = math.min(macp.chameleon, 100)
	local chameleonBonus = ( config.chameleonMultiplier / 100 ) * effectiveChameleonMagnitude
	local invisBonus = 0

	if macp.invisibility > 0 then
		invisBonus = config.invisibilityBonus
	end

	local finalBonus = math.max(chameleonBonus, invisBonus)
	playerScore = playerScore + finalBonus

	-- Get detector score.
	local sneakterm
	
	if detector.sneak then --it's an npc
		sneakterm = detector.sneak.current
	else --it's a creature
		sneakterm = detector.stealth.current
	end
	
	local detectorScore = (sneakterm + config.npcSneakBonus --most npcs have very low sneak, too easy to fool
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

local function createLightbar(element)
    local block = element:createRect({
        id = ids.LightbarBlock,
		color = {0,0,0}
    })
    block.autoWidth = true
	block.autoHeight = true	
	block.absolutePosAlignX = 0.5
	block.absolutePosAlignY = 0.5
	
	local rectBorder = block:createThinBorder()
	rectBorder.paddingAllSides = 2
	rectBorder.autoWidth = true
	rectBorder.autoHeight = true
	
	local rectBorder2 = rectBorder:createThinBorder()
	rectBorder2.paddingAllSides = 2
	rectBorder2.autoWidth = true
	rectBorder2.autoHeight = true

	local lightBar = rectBorder2:createRect({id = ids.Lightbar,color={1,1,0.6}})
	lightBar.borderAllSides = 0
	lightBar.width = 150
	lightBar.height = 15
	lightBar.alpha = 1.0
	
	block.visible = false

    element:updateLayout()

    return block
end

local function createMenuLightBar(e)
    if not e.newlyCreated then return end

    -- Find the UI element that holds the fillbars.
    menuMultiFillbarsBlock = e.element:findChild(tes3ui.registerID("MenuMulti_bottom_row"))
    menuLightbar = createLightbar(menuMultiFillbarsBlock)
end

local function sneakChecker()
	if tes3.mobilePlayer.isSneaking == false then
		if menuLightbar ~= nil then
			menuLightbar.visible = false
		end
	 else
		if tes3.player.cell.isInterior == true and config.showLightBar == true then
			if menuLightbar ~= nil then
				menuLightbar.visible = true
			end
		end
	end
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
	event.register("simulate", sneakChecker)
	event.register("uiActivated", createMenuLightBar, { filter = "MenuMulti" })
	
	mwse.log("[Stealth] Initialized.")
end
event.register("initialized", onInitialized)