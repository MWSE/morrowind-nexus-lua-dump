----Initialize-------------------------------------------------------------------------------------------------------------------
local config = require("companionLeveler.config")
local logger = require("logging.logger")
local func = require("companionLeveler.functions.common")
local buildMode = require("companionLeveler.modes.buildMode")
local npcMode = require("companionLeveler.modes.npcClassMode")
local creMode = require("companionLeveler.modes.creClassMode")
local root = require("companionLeveler.menus.root")
local abilities = require("companionLeveler.functions.abilities")
local tables = require("companionLeveler.tables")

local log = logger.new {
	name = "Companion Leveler",
	logLevel = "TRACE",
}
log:setLogLevel(config.logLevel)

local function initialized()
	log:info("" .. tables.version .. " Initialized.")
	if not tes3.isModActive("companionLeveler.ESP") then
		log:warn("companionLeveler.esp not active. Errors will occur.")
		tes3.messageBox("companionLeveler.esp not active. Errors will occur.")
	end
end
event.register("initialized", initialized)

local function versionCheck()
	log:info("Checking version...")
	local partyTable = func.partyTable()

	for i = 1, #partyTable do
		func.updateModData(partyTable[i])
	end

	log:info("Version check complete.")
end
event.register("loaded", versionCheck)



--
----Level-Up Mode------------------------------------------------------------------------------------------------------------------------------
--

local function onLevelUp()
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
			npcMode.levelUp(npcTable)
		end

		if #creTable > 0 then
			creMode.levelUp(creTable)
		end
	end
end
event.register("levelUp", onLevelUp)


--
----Exp Mode----------------------------------------------------------------------------------------------------------------------
--

--Skill Experience
local function onSkillRaised(e)
	abilities.comprehension(e)
	abilities.julianos(e)

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
			npcMode.levelUp(npc)
		end
		if #creature > 0 then
			creMode.levelUp(creature)
		end
	end
end
event.register("skillRaised", onSkillRaised)

--Kill Experience/Abilities
local function onDeath(e)
	abilities.spectralWill(e)

	if string.startswith(e.reference.object.name, "Summoned") then return end

	abilities.contractKill(e)
	abilities.bountyKill(e)
	abilities.bloodKarma(e)
	abilities.huntCheck(e)

	if config.expMode == false then return end

	--Level Up Tables
	local build, npc, creature = func.awardEXP(config.expKill)

	if #build > 0 then
		buildMode.companionLevelBuild(build)
	else
		if #npc > 0 then
			npcMode.levelUp(npc)
		end
		if #creature > 0 then
			creMode.levelUp(creature)
		end
	end
end
event.register("death", onDeath)

--Quest Experience
local function onJournal(e)
	
	if config.expMode == false then return end

	if not e.new then
		--Level Up Tables
		local build, npc, creature = func.awardEXP(config.expQuest)

		if #build > 0 then
			buildMode.companionLevelBuild(build)
		else
			if #npc > 0 then
				npcMode.levelUp(npc)
			end
			if #creature > 0 then
				creMode.levelUp(creature)
			end
		end
	end
end
event.register("journal", onJournal)


--
----Class/Type/Build Change Controls-------------------------------------------------------------------------------
--

event.register("uiActivated", function()
	

	local actor = tes3ui.getServiceActor()
	log:debug("Object Type: " .. actor.reference.baseObject.objectType .. "")

	if actor and func.validCompanionCheck(actor) and actor.inCombat == false then
		log:debug("NPC Follower detected. Giving class change topic.")
		tes3.setGlobal("kl_companion", 1)
	else
		log:debug("Target not an NPC Follower. No class change topic given.")
		tes3.setGlobal("kl_companion", 0)
	end

	--Abilities
	abilities.fRep(actor)
	abilities.dibella(actor)

	--Clavicus Vile: Scampson
	if actor.object.baseObject.id == "kl_scamp_scampson" then
		--Weapons Con-tract 5k
		if func.checkReq(true, "kl_scampson_weapons_contract", 1, tes3.player) then
			actor.object.baseObject.aiConfig.bartersWeapons = true
			actor.object.baseObject.modified = true
		end
		--Armor Con-tract 3k
		if func.checkReq(true, "kl_scampson_armor_contract", 1, tes3.player) then
			actor.object.baseObject.aiConfig.bartersArmor = true
			actor.object.baseObject.modified = true
		end
		--Clothing Con-tract 2k
		if func.checkReq(true, "kl_scampson_clothing_contract", 1, tes3.player) then
			actor.object.baseObject.aiConfig.bartersClothing = true
			actor.object.baseObject.modified = true
		end
		--Ingredient Con-tract 3k
		if func.checkReq(true, "kl_scampson_ingredient_contract", 1, tes3.player) then
			actor.object.baseObject.aiConfig.bartersIngredients = true
			actor.object.baseObject.modified = true
		end
		--Roguish 2k
		if func.checkReq(true, "kl_scampson_roguish_contract", 1, tes3.player) then
			actor.object.baseObject.aiConfig.bartersProbes = true
			actor.object.baseObject.aiConfig.bartersLockpicks = true
			actor.object.baseObject.modified = true
		end
		--Shiny 1k
		if func.checkReq(true, "kl_scampson_shiny_contract", 1, tes3.player) then
			actor.object.baseObject.aiConfig.bartersLights= true
			actor.object.baseObject.modified = true
		end
		--Domestic 1k
		if func.checkReq(true, "kl_scampson_domestic_contract", 1, tes3.player) then
			actor.object.baseObject.aiConfig.bartersMiscItems= true
			actor.object.baseObject.modified = true
		end
		--Alchemical
		if func.checkReq(true, "kl_scampson_alchemical_contract", 1, tes3.player) then
			actor.object.baseObject.aiConfig.bartersApparatus= true
			actor.object.baseObject.aiConfig.bartersAlchemy= true
			actor.object.baseObject.modified = true
		end
		--500:500g Bronze
		if func.checkReq(true, "kl_scampson_bronze_contract", 1, tes3.player) and actor.object.baseObject.barterGold < 500 then
			actor.object.baseObject.barterGold = 500
			actor.object.baseObject.modified = true
		end
		--1000:2000g Silver
		if func.checkReq(true, "kl_scampson_silver_contract", 1, tes3.player) and actor.object.baseObject.barterGold < 1000 then
			actor.object.baseObject.barterGold = 1000
			actor.object.baseObject.modified = true
		end
		--2000:5000g Gold
		if func.checkReq(true, "kl_scampson_gold_contract", 1, tes3.player) and actor.object.baseObject.barterGold < 2000 then
			actor.object.baseObject.barterGold = 2000
			actor.object.baseObject.modified = true
		end
		--3000:5000g Pearl
		if func.checkReq(true, "kl_scampson_pearl_contract", 1, tes3.player) and actor.object.baseObject.barterGold < 3000 then
			actor.object.baseObject.barterGold = 3000
			actor.object.baseObject.modified = true
		end
		--5000:10000g Diamond
		if func.checkReq(true, "kl_scampson_diamond_contract", 1, tes3.player) and actor.object.baseObject.barterGold < 5000 then
			actor.object.baseObject.barterGold = 5000
			actor.object.baseObject.modified = true
		end
		--10000:50000g Crystal
		if func.checkReq(true, "kl_scampson_crystal_contract", 1, tes3.player) and actor.object.baseObject.barterGold < 10000 then
			actor.object.baseObject.barterGold = 10000
			actor.object.baseObject.modified = true
		end
		--Repair Con-tract 10k
		if func.checkReq(true, "kl_scampson_repair_contract", 1, tes3.player) then
			actor.object.baseObject.aiConfig.offersRepairs = true
			actor.object.baseObject.modified = true
		end
	end

end, { filter = "MenuDialog" })


event.register(tes3.event.keyDown, function(e)
	if e.keyCode ~= config.typeBind.keyCode then return end

	local t = tes3.getPlayerTarget()
	if not t then return end
	if t.mobile.inCombat then return end

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

--Tools-----------------------------------------------------------------

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

--Triggered Ability Timer: Recurring
local function abilityTimer2()
	log:trace("Recurring ability timer triggered.")

	local party = func.npcTable()
	local num = 0
	if #party > 0 then
		for i = 1, #party do
			local modData = func.getModData(party[i])
			if modData.patron and modData.patron == 23 then
				num = 1
				log:debug("Peryite oversees the party's tasks.")
				break
			end
		end
	end
	local float = math.random()
	local int = math.random(8, 23) - num
	timer.start({ type = timer.game, duration = (float + int), iterations = 1, callback = "companionLeveler:abilityTimer2" })

	if #party > 0 then
		local choice = math.random(1, #party)
		local reference = party[choice]

		if math.random(0, 99) < config.triggerChance then
			abilities.executeAbilities(reference)
		end
	end
end
timer.register("companionLeveler:abilityTimer2", abilityTimer2)

--Hourly Timer: For Time-Based Abilities
local function hourlyTimer()
	log:trace("Hourly timer triggered.")

	--Begin Next Iteration
	local gameHour = tes3.getGlobal('GameHour')
	local rounded = math.round(gameHour)
	if rounded < gameHour then
		timer.start({ type = timer.game, duration = (rounded + 1) - gameHour, iterations = 1, callback = "companionLeveler:hourlyTimer" })
	else
		local num = rounded - gameHour
		if num < 0 then
			num = 0
		end
		timer.start({ type = timer.game, duration = num, iterations = 1, callback = "companionLeveler:hourlyTimer" })
	end

	--Patrons--
	log:debug("Time is now " .. gameHour .. ".")
	--tes3.messageBox("Time is now " .. gameHour .. " (" .. tes3.getGlobal('GameHour') .. ").")

	--Vaermina Tribute
	abilities.vaerminaTribute()

	--Dagon Tribute
	if gameHour >= 1 and gameHour < 2 then
		log:debug("1am detected.")
		abilities.dagonTribute()
	end

	--Sanguine Tribute
	if gameHour >= 2 and gameHour < 3 then
		log:debug("2am detected.")
		abilities.sanguineTribute()
	end

	--Mephala Tribute
	if gameHour >= 3 and gameHour < 4 then
		log:debug("3am detected.")
		abilities.mephalaTribute()
	end

	--Meridia Tribute
	if gameHour >= 12 and gameHour < 13 then
		log:debug("12pm detected.")
		abilities.meridiaTribute()
	end

	--Azura Tribute
	if gameHour >= 17 and gameHour < 18 then
		log:debug("5pm detected.")
		abilities.azuraTribute()
	end

	--Malacath Tribute
	if gameHour >= 18 and gameHour < 19 then
		log:debug("6pm detected.")
		abilities.malacathTribute()
	end

	--Azura Gift
	if (gameHour < 8 and gameHour >= 6) or (gameHour < 20 and gameHour >= 18) then
		log:debug("Twilight hours detected.")
		abilities.azuraGift()
	end

	--Hircine Tribute
	if gameHour >= 22 and gameHour < 23 then
		log:debug("10pm detected.")
		abilities.hircineTribute()
	end

	--Boethiah Tribute
	if gameHour < 1 then
		log:debug("Midnight detected.")
		abilities.boethiahTribute()
		abilities.moraTribute()
	end
end
timer.register("companionLeveler:hourlyTimer", hourlyTimer)

--Hircine Werewolf Timer
local function wereTimer()
	log:trace("Werewolf timer triggered.")

	local werewolf = tes3.getReference("kl_werewolf_companion")

	if not werewolf.isDead then
		local modData = func.getModData(werewolf)
		local cleric = tes3.getReference(modData.npcID)
		local cModData = func.getModData(cleric)
		cleric:enable()
		cModData.hircineHunt = modData.hircineHunt
		cModData.lycanthropicPower = modData.lycanthropicPower
		tes3.positionCell({ reference = cleric, cell = werewolf.cell, position = werewolf.position })
		tes3.createVisualEffect({ object = "VFX_DefaultHit", lifespan = 1, reference = cleric })
		tes3.setAIFollow({ reference = cleric, target = tes3.player })
		if werewolf.mobile.health.current < cleric.mobile.health.base then
			cleric.mobile.health.current = werewolf.mobile.health.current
		end
		timer.delayOneFrame(function()
			timer.delayOneFrame(function()
				timer.delayOneFrame(function()
					werewolf:disable()
				end)
			end)
		end)
	end
end
timer.register("companionLeveler:wereTimer", wereTimer)

--Ability Triggers--------------------------------------------------------

--Combat Abilities
local function onCombat(e)
	--100%

	abilities.combustion(e) --Mehrunes Dagon
	abilities.sheoCombat(e) --Sheogorath
	abilities.nightmare(e) --Vaermina

	if math.random(0, 99) < config.combatChance then
		abilities.jest(e)
		abilities.thaumaturgy(e)
		abilities.inoculate(e)
		abilities.requiem(e)
		abilities.dirge(e)
		abilities.elegy(e)
		abilities.communion(e)
		abilities.dominance(e)
		abilities.weather(e)
	end
end
event.register(tes3.event.combatStarted, onCombat)

--Before Damage Abilities
local function onDamage(e)
	if e.source == "attack" then
		local result = 0

		--Reliable
		abilities.ignition(e)
		abilities.permafrost(e)
		abilities.venomous(e)
		result = result + abilities.poach(e)
		result = result + abilities.deceptor(e)
		result = result + abilities.shed(e)
		result = result + abilities.broadside(e)
		result = result + abilities.boethiahGift(e)
		result = result - abilities.dibellaDuty(e)
		result = result - abilities.talosDuty(e)
		abilities.malacathGift(e)
		abilities.namiraGift(e)

		--Combat Chance
		if math.random(0, 99) < config.combatChance then
			result = result + abilities.thuum(e)
			result = result + abilities.maneater(e)
			result = result + abilities.ladykiller(e)
			abilities.misdirection(e)
			abilities.misstep(e)
			abilities.rage(e)
			abilities.voltaic(e)
			abilities.mephalaGift(e)
			abilities.meridiaGift(e)

			if e.projectile then
				abilities.arcaneA(e)
			else
				abilities.arcaneK(e)
			end

		end

		e.damage = e.damage + result
	elseif e.source == "fall" then
		e.damage = abilities.acrobatic(e)
	end
end
event.register("damage", onDamage)

--After Damage Abilities
local function damaged(e)
	--Reliable
	abilities.beastwithin(e)
	abilities.stendarrDuty(e)
	abilities.dagonSacrifice(e)
	abilities.mephalaSacrifice(e)
	abilities.meridiaSacrifice(e)
	abilities.molagGift(e)

	--Combat Chance
	if math.random(0, 99) < config.combatChance then
		abilities.adrenaline(e)
	end
end
event.register("damaged", damaged)

--After H2H Damage
local function damagedHandToHandCallback(e)
	--Reliable
	abilities.knifehand(e)
end
event.register(tes3.event.damagedHandToHand, damagedHandToHandCallback)

--Cell Change Abilities
local function onCellChanged(e)
	abilities.instinct()
	abilities.barrier()
	abilities.dream()
	abilities.refractors()
	abilities.jadewind()
	abilities.springstep()
	abilities.freedom()
	abilities.temper()
	abilities.aqualung()
	abilities.composition()
	abilities.mystery()
	abilities.manasponge()
	abilities.resolve()
	abilities.blessed()
	abilities.bountyCheck()
	abilities.track()
	abilities.wont()
	abilities.intuition()
	abilities.kynareth(e)
	abilities.sanguineGift()

	if config.expMode == false then return end

	local exp = abilities.survey(e)

	if exp > 0 then
		--Award EXP
		local build, npc, creature = func.awardEXP(exp)

		if #build > 0 then
			buildMode.companionLevelBuild(build)
		else
			if #npc > 0 then
				npcMode.levelUp(npc)
			end
			if #creature > 0 then
				creMode.levelUp(creature)
			end
		end
	end
end
event.register(tes3.event.cellChanged, onCellChanged)

--On Rest Abilities
local function onCalcRestInterrupt(e)
	abilities.cunning(e)
	if e.resting then
		abilities.vaerminaGift()
	end
end
event.register(tes3.event.calcRestInterrupt, onCalcRestInterrupt)

--Soul Capture Abilities
local function filterSoulGemTargetCallback(e)
	local arkay = abilities.arkay(e)
	local molag = abilities.molagTribute(e)
	if arkay == false or molag == false then
		e.filter = false
	end
end
event.register(tes3.event.filterSoulGemTarget, filterSoulGemTargetCallback)

--On Activate Abilities
local function onActivate(e)
	if e.activator ~= tes3.player then return end

	if (e.target.baseObject.objectType == tes3.objectType.door) then
		log:trace("Door callback triggered.")
		local cell = tes3.player.cell

		if cell.isOrBehavesAsExterior then
			local vector = tes3.getLastExteriorPosition()
			local modData = func.getModDataP()
			modData.lastExteriorPosition = {vector.x, vector.y, vector.z}

			log:debug("Last Exterior Position Assigned: " .. tostring(vector) .. "")
		end
	elseif (tes3.hasOwnershipAccess({target = e.target}) == false or (e.target.baseObject.objectType == tes3.objectType.npc and tes3.mobilePlayer.isSneaking and e.target.mobile.health.current > 0)) then
		abilities.zenitharDuty(e.target)
	end

	if tes3.getLocked({ reference = e.target }) then
		abilities.nocturnalGift(e.target)
	end

	if (e.target.baseObject.objectType == tes3.objectType.npc) then
		abilities.deliveryCheck(e.target)
	end
end
event.register("activate", onActivate)


--Economic Events-------------------------------------------------------------------------------------------------------------------------

--Travel Price
local function onCalcTravelPrice(e)
	abilities.navigator(e)
	abilities.zenithar(e)
end
event.register("calcTravelPrice", onCalcTravelPrice)

--Repair Price
local function calcRepairPriceCallback(e)
	abilities.zenithar(e)
end
event.register(tes3.event.calcRepairPrice, calcRepairPriceCallback)

--Training Price
local function calcTrainingPriceCallback(e)
	abilities.zenithar(e)
end
event.register(tes3.event.calcTrainingPrice, calcTrainingPriceCallback)

--Spell Price
local function calcSpellPriceCallback(e)
	abilities.zenithar(e)
end
event.register(tes3.event.calcSpellPrice, calcSpellPriceCallback)

--Spellmaking Price
local function calcSpellmakingPriceCallback(e)
	abilities.zenithar(e)
end
event.register(tes3.event.calcSpellmakingPrice, calcSpellmakingPriceCallback)

--Enchanting Price
local function calcEnchantmentPriceCallback(e)
	abilities.zenithar(e)
end
event.register(tes3.event.calcEnchantmentPrice, calcEnchantmentPriceCallback)

--Stealth Events-----------------------------------------------------------------------------------------------

--Sneaking Abilities
local function detectSneakCallback(e)
	if e.target == tes3.mobilePlayer or func.validCompanionCheck(e.target) then
		e.isDetected = abilities.shadow(e)
	end
end
event.register(tes3.event.detectSneak, detectSneakCallback)

--Crime Abilities
local function crimeWitnessedCallback(e)
	abilities.akatosh(e)
	abilities.julianosDuty(e)
end
event.register(tes3.event.crimeWitnessed, crimeWitnessedCallback)









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
--