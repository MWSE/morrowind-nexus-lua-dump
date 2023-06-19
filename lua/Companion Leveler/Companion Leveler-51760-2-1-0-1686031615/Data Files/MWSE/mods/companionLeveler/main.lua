----Initialize-------------------------------------------------------------------------------------------------------------------
local config = require("companionLeveler.config")
local logger = require("logging.logger")
local func = require("companionLeveler.functions.common")
local buildMode = require("companionLeveler.modes.buildMode")
local npcMode = require("companionLeveler.modes.npcClassMode")
local creMode = require("companionLeveler.modes.creClassMode")
local root = require("companionLeveler.menus.root")
local abilities = require("companionLeveler.functions.abilities")

local log = logger.new {
	name = "Companion Leveler",
	logLevel = "TRACE",
}
log:setLogLevel(config.logLevel)

local function initialized()
	log:info("Initialized.")
	if not tes3.isModActive("companionLeveler.ESP") then
		log:warn("companionLeveler.esp not active. Errors will occur.")
		tes3.messageBox("companionLeveler.esp not active. Errors will occur.")
	end
end
event.register("initialized", initialized)

local function versionCheck()
	local partyTable = func.buildTable()

	for i = 1, #partyTable do
		func.updateModData(partyTable[i])
	end
end
event.register("loaded", versionCheck)



--
----Level-Up Mode------------------------------------------------------------------------------------------------------------------------------
--

local function onLevelUp()
	if config.modEnabled == false then return end
	if config.expMode == true then return end

	--Mode Select
	if config.buildMode == true then
		local buildTable = func.buildTable()

		if #buildTable > 0 then
			buildMode.companionLevelBuild(buildTable)
		end
	else
		local npcTable = func.npcTable()
		local creTable = func.creTable()

		if #npcTable > 0 then
			npcMode.companionLevelNPC(npcTable)
		end

		if #creTable > 0 then
			creMode.companionLevelCre(creTable)
		end
	end
end
event.register("levelUp", onLevelUp)


--
----Exp Mode----------------------------------------------------------------------------------------------------------------------
--

--Skill Experience
local function onSkillRaised(e)
	if config.modEnabled == false then return end

	abilities.comprehension(e)

	if config.expMode == false then return end

	--Determine EXP Rewarded------------------------------------------------
	local majSkills = tes3.player.object.class.majorSkills
	local minSkills = tes3.player.object.class.minorSkills
	local classSkill = 0
	local amtRewarded = 0

	for n = 1, 5 do
		if (e.skill == majSkills[n] or e.skill == minSkills[n]) then
			classSkill = 1
			amtRewarded = config.expClassSkill
			log:debug("Major/Minor skill detected.")
		end
	end

	if classSkill == 0 then
		amtRewarded = config.expMiscSkill
		log:debug("Misc skill detected.")
	end

	--Insight #88
	local finalAmt = abilities.insight(amtRewarded)

	--Add EXP to companions------------------------------------------------
	local build, npc, creature = func.awardEXP(finalAmt)

	if #build > 0 then
		buildMode.companionLevelBuild(build)
	else
		if #npc > 0 then
			npcMode.companionLevelNPC(npc)
		end
		if #creature > 0 then
			creMode.companionLevelCre(creature)
		end
	end
end
event.register("skillRaised", onSkillRaised)

--Kill Experience/Abilities
local function onDeath(e)
	if config.modEnabled == false then return end

	abilities.spectralWill(e)

	if string.startswith(e.reference.object.name, "Summoned") then return end

	abilities.contractKill(e)
	abilities.bountyKill(e)

	if config.expMode == false then return end

	--Level Up Tables
	local build, npc, creature = func.awardEXP(config.expKill)

	if #build > 0 then
		buildMode.companionLevelBuild(build)
	else
		if #npc > 0 then
			npcMode.companionLevelNPC(npc)
		end
		if #creature > 0 then
			creMode.companionLevelCre(creature)
		end
	end
end
event.register("death", onDeath)

--Quest Experience
local function onJournal(e)
	if config.modEnabled == false then return end
	if config.expMode == false then return end

	if not e.new then
		--Level Up Tables
		local build, npc, creature = func.awardEXP(config.expQuest)

		if #build > 0 then
			buildMode.companionLevelBuild(build)
		else
			if #npc > 0 then
				npcMode.companionLevelNPC(npc)
			end
			if #creature > 0 then
				creMode.companionLevelCre(creature)
			end
		end
	end
end
event.register("journal", onJournal)


--
----Class/Type/Build Change Controls-------------------------------------------------------------------------------
--

event.register("uiActivated", function()
	if config.modEnabled == false then return end

	local actor = tes3ui.getServiceActor()

	if actor and func.validCompanionCheck(actor) then
		log:debug("NPC Follower detected. Giving class change topic.")
		tes3.setGlobal("kl_companion", 1)
	else
		log:debug("Target not an NPC Follower. No class change topic given.")
		tes3.setGlobal("kl_companion", 0)
	end
end, { filter = "MenuDialog" })

event.register(tes3.event.keyDown, function(e)
	if e.keyCode ~= config.typeBind.keyCode then return end

	local t = tes3.getPlayerTarget()
	if not t then return end

	if func.validCompanionCheck(t.mobile) then
		log:trace("Ability Check triggered on " .. t.object.name .. ". (Key Press)")
		if t.object.objectType == tes3.objectType.creature then
			func.addAbilities(t)
		else
			func.addAbilitiesNPC(t)
		end
		root.createWindow(t)
	end
end)


--
----Ability Controls-----------------------------------------------------------------------------------------
--

--Clear Non-Companion Creature Abilities
local function abilityClear(e)
	if e.reference.object.objectType ~= tes3.objectType.creature then return end

	log:trace("Ability Check triggered on " .. e.reference.object.name .. ". (Activated)")
	if not func.validCompanionCheck(e.mobile) then
		func.removeAbilities(e.reference)
		abilities.tranquility(e.reference)
		abilities.pheromone(e.reference)
	else
		func.addAbilities(e.reference)
	end
end
event.register(tes3.event.mobileActivated, abilityClear)

--Triggered Ability Timer: From Levels. Will phase out in later updates.
local function abilityTimer(e)
	log:trace("Level ability timer triggered.")
	if config.modEnabled == false then return end
	local timer = e.timer
	local data = timer.data

	local party = func.npcTable()

	for i = 1, #party do
		local reference = party[i]
		if reference.object.name == data.name then
			abilities.executeAbilities(reference)
		end
	end

end
timer.register("companionLeveler:abilityTimer", abilityTimer)

--Triggered Ability Timer: Recurring
local function abilityTimer2()
	log:trace("Recurring ability timer triggered.")

	local float = math.random()
	local int = math.random(7, 23)
	timer.start({ type = timer.game, duration = (float + int), iterations = 1, callback = "companionLeveler:abilityTimer2" })

	if config.modEnabled == false then return end

	local party = func.npcTable()
	if #party > 0 then
		local choice = math.random(1, #party)
		local reference = party[choice]

		if math.random(0, 99) < config.triggerChance then
			abilities.executeAbilities(reference)
		end
	end
end
timer.register("companionLeveler:abilityTimer2", abilityTimer2)

--Combat Abilities
local function onCombat(e)
	if config.modEnabled == false then return end

	if math.random(0, 99) < config.combatChance then
		abilities.jest(e)
		abilities.thaumaturgy(e)
		abilities.inoculate(e)
		abilities.requiem(e)
		abilities.dirge(e)
		abilities.elegy(e)
	end
end
event.register(tes3.event.combatStarted, onCombat)

--Cell Change Abilities
local function onCellChanged(e)
	if config.modEnabled == false then return end

	abilities.bountyCheck()

	if config.expMode == false then return end

	local exp = abilities.survey()

	if exp > 0 then
		--Award EXP
		local build, npc, creature = func.awardEXP(exp)

		if #build > 0 then
			buildMode.companionLevelBuild(build)
		else
			if #npc > 0 then
				npcMode.companionLevelNPC(npc)
			end
			if #creature > 0 then
				creMode.companionLevelCre(creature)
			end
		end
	end
end
event.register(tes3.event.cellChanged, onCellChanged)



--
--Config Stuff------------------------------------------------------------------------------------------------------------------------------
--

event.register("modConfigReady", function()
	require("companionLeveler.mcm")
	config = require("companionLeveler.config")
end)

--for testing:
-- local function expTest()
-- 	if config.expMode == false then return end
-- 	tes3.player.mobile:exerciseSkill(10, 100)
-- end

-- event.register("jump", onLevelUp)
-- event.register("jump", expTest)



----Planned Features
----TR ingredient/item integration
----GMST text values for other languages OR i18n support