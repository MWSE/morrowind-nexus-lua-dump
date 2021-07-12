local mod = "Taunt Failure Penalty"
local version = "1.2.1"

-- Config
local config

-- Info IDs of the Taunt Fail responses, loaded on initialization
local tauntFail = {}

-- GMSTs
-- Loaded on "initialized"
local fPersonalityMod
local fLuckMod
local fRepMod
local fFatigueBase
local fFatigueMult
local iPerMinChance
local iPerMinChange
local fPerDieRollMult
local fPerTempMult
local sPersuasion

local function onDialog(e)
	local dialogId = e.info.id
		
	-- Only react to taunt failures
	if tauntFail[dialogId] then
		local actor = tes3ui.getServiceActor()
		local baseActor = actor.reference.baseObject
	
		-- Recalculate the persuasion terms, as described in https://wiki.openmw.org/index.php?title=Research:Disposition_and_Persuasion
		-- Taunt uses "target1" for the check, which depends on Personality (20% by default), Luck (10% by default), 
		-- Reputation (100% by default), and Speechcraft (always 100%), all modified by fatigue		
		local playerPersTerm = tes3.mobilePlayer.personality.current / fPersonalityMod
		local playerLuckTerm = tes3.mobilePlayer.luck.current / fLuckMod
		local playerRepTerm = tes3.player.object.reputation * fRepMod
		local playerFatigueTerm = fFatigueBase - fFatigueMult * (1 - tes3.mobilePlayer.fatigue.normalized)
		local playerRating = (playerPersTerm + playerLuckTerm + playerRepTerm + tes3.mobilePlayer.speechcraft.current) * playerFatigueTerm
		
		local actorPersTerm = actor.personality.current / fPersonalityMod
		local actorLuckTerm = actor.luck.current / fLuckMod
		local actorFatigueTerm = fFatigueBase - fFatigueMult * (1 - actor.fatigue.normalized)
		local actorRepTerm = actor.object.reputation * fRepMod
		local actorRating = (actorPersTerm + actorLuckTerm + actorRepTerm + actor.speechcraft.current) * actorFatigueTerm
	
		local dispositionTerm = 1 - 0.02 * math.abs(actor.object.disposition - 50)
		local target = math.max(iPerMinChance, dispositionTerm * (playerRating - actorRating + 50))
		
		-- We know the taunt failed. So the roll must be greater than target
		local roll = math.random(math.min(100, target + 1), 100)
		local diff = roll - target -- equivalent to math.abs(target - roll), since roll > target
		local change = math.max(iPerMinChange, diff * fPerDieRollMult * fPerTempMult)
		
		if config.debugMode then
			mwse.log("Taunt failed!")
			mwse.log("Player terms: pers=%f luck=%f rep=%f fatigue=%f rating=%f", playerPersTerm, playerLuckTerm, playerRepTerm, playerFatigueTerm, playerRating)
			mwse.log("NPC terms: pers=%f luck=%f fatigue=%f rating=%f", actorPersTerm, actorLuckTerm, actorFatigueTerm, actorRating)
			mwse.log("Other terms: disposition=%f target=%f roll=%f diff=%f change=%f", dispositionTerm, target, roll, diff, change)
			mwse.log("Previous actor: flee=%d fight=%d", actor.flee, actor.fight)
		end
		
		-- Increase the actor's flee, up to the initial value
		-- Lower the actor's fight, down to the initial value
		actor.flee = math.min(baseActor.aiConfig.flee, actor.flee + change)
		actor.fight = math.max(baseActor.aiConfig.fight, actor.fight - change)
		
		if config.debugMode then
			mwse.log("Current actor: flee=%d fight=%d", actor.flee, actor.fight)
		end
	end
end

local function onConfigReady()
	config = require("Taunt Failure Penalty.config")
end

event.register("modConfigReady", onConfigReady)

local function onInitialized()
	event.register("infoGetText", onDialog)

	-- Load GMSTs
	fPersonalityMod = tes3.findGMST(tes3.gmst.fPersonalityMod).value
	fLuckMod = tes3.findGMST(tes3.gmst.fLuckMod).value
	fRepMod = tes3.findGMST(tes3.gmst.fReputationMod).value
	fFatigueBase = tes3.findGMST(tes3.gmst.fFatigueBase).value
	fFatigueMult = tes3.findGMST(tes3.gmst.fFatigueMult).value
	iPerMinChance = tes3.findGMST(tes3.gmst.iPerMinChance).value
	iPerMinChange = tes3.findGMST(tes3.gmst.iPerMinChange).value
	fPerDieRollMult = tes3.findGMST(tes3.gmst.fPerDieRollMult).value
	fPerTempMult = tes3.findGMST(tes3.gmst.fPerTempMult).value
	sPersuasion = tes3.findGMST(tes3.gmst.sPersuasion).value
	
	-- Load Taunt Fail dialog lines
	for _, info in pairs(tes3.findDialogue({ type = 3, page = 6}).info) do
		tauntFail[info.id] = true
	end

    mwse.log("[%s %s] Initialized", mod, version)
end

event.register("initialized", onInitialized)

-- MCM
local modConfig = {}

function modConfig.onCreate(container)
	local pane = container:createThinBorder{}
	pane.widthProportional = 1.0
	pane.heightProportional = 1.0
	pane.paddingAllSides = 12
    pane.flowDirection = "top_to_bottom"

	local settingBlock = pane:createBlock{}
	settingBlock.flowDirection = "left_to_right"
	settingBlock.widthProportional = 1.0
	settingBlock.height = 32
	settingBlock.borderRight = 6
	settingBlock.borderLeft = 6

	local label = settingBlock:createLabel{ text = "Debug Mode" }
	label.absolutePosAlignX = 0.0
	label.absolutePosAlignY = 0.5

	local onOffButton = settingBlock:createButton{ text = config.debugMode and "On" or "Off" }
	onOffButton.absolutePosAlignX = 1.0
	onOffButton.absolutePosAlignY = 0.5
	onOffButton:register("mouseClick", function(e)
		config.debugMode = not config.debugMode
		onOffButton.text = (config.debugMode and "On" or "Off")
	end)

	pane:updateLayout()
end

function modConfig.onClose(container)
	mwse.saveConfig(configPath, config)
end

local function registerModConfig()
	mwse.registerModConfig("Taunt Failure Penalty", modConfig)
end

event.register("modConfigReady", registerModConfig)