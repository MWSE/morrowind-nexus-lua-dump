local config = require("companionLeveler.config")
local tables = require("companionLeveler.tables")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")


local this = {}

--
----Mod Data------------------------------------------------------------------------------------------------------------------
--

--Player Mod Data
function this.getModDataP(playerRef)
	log = logger.getLogger("Companion Leveler")
    log:trace("Checking player's saved Mod Data.")

    if not playerRef.data.companionLeveler then
        log:info("Player Mod Data not found, setting to base Mod Data values.")
        playerRef.data.companionLeveler = { ["noDupe"] = 0, ["lastExteriorPosition"] = {0.0, 0.0, 0.0} }
        playerRef.modified = true
    else
        log:trace("Saved Mod Data found.")
    end

    return playerRef.data.companionLeveler
end

--Companion Mod Data
function this.getModData(ref)
	log = logger.getLogger("Companion Leveler")
	log:trace("Checking " .. ref.object.name .. "'s Mod Data.")

	if not ref.data.companionLeveler then
		--General Data-------------------------------------------------------------------------------------------------------------------
		log:info("Companion Mod Data not found, setting to base Mod Data values.")
		ref.data.companionLeveler = { ["version"] = tables.version, ["blacklist"] = false, ["level"] = ref.object.level,
		["summary"] = "No Summary.", ["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
		["att_gained"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
		["hth_gained"] = 0,
		["mgk_gained"] = 0,
		["fat_gained"] = 0, ["lvl_progress"] = 0, ["lvl_req"] = (config.expRequirement + (ref.object.level * config.expRate)),
		["spellLearning"] = true, ["abilityLearning"] = true, ["tp_current"] = ref.object.level, ["tp_max"] = ref.object.level, ["abilities"] = {} }
		--NPC Data-----------------------------------------------------------------------------------------------------------------------
		if ref.object.objectType ~= tes3.objectType.creature then
			log:info("NPC Mod Data not found, setting to base Mod Data values.")

			ref.data.companionLeveler["class"] = ref.object.class.id
			ref.data.companionLeveler["skillMods"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
			ref.data.companionLeveler["skillModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
			ref.data.companionLeveler["skill_gained"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
			ref.data.companionLeveler["ignore_skill"] = 99
			ref.data.companionLeveler["contracts"] = {}
			ref.data.companionLeveler["bounties"] = {}
			ref.data.companionLeveler["sessions_current"] = 0
			ref.data.companionLeveler["sessions_max"] = 3
			
			--NPC Abilities
			for i = 1, tables.npcAbilityAmount do
				ref.data.companionLeveler["abilities"][i] = false
			end
		else
			--Creature Data----------------------------------------------------------------------------------------------------------------
			log:info("Creature Mod Data not found, setting to base Mod Data values.")
			local defType = this.determineDefault(ref)
			ref.data.companionLeveler["type"] = defType

			--Type Levels
			ref.data.companionLeveler["typelevels"] = {}

			for i = 1, #tables.typeTable do
				ref.data.companionLeveler["typelevels"][i] = 1
				if tables.typeTable[i] == defType then
					log:info("" .. defType .. " type detected.")
					ref.data.companionLeveler["typelevels"][i] = ref.object.level
				end
			end

			--Creature Abilities
			for i = 1, tables.creAbilityAmount do
				ref.data.companionLeveler["abilities"][i] = false
			end
		end

		--Initialize Ideal Sheet values
		this.updateIdealSheet(ref)

		ref.modified = true
	else
		log:trace("Saved Mod Data found.")
	end
	return ref.data.companionLeveler
end

--Simple Mod Data Check
function this.checkModData(ref)
	log = logger.getLogger("Companion Leveler")
	log:trace("Checking for existing Mod Data.")

	if not ref.data.companionLeveler then
		return false
	else
		return true
	end
end

--Version Control
function this.updateModData(ref)
	log = logger.getLogger("Companion Leveler")
	log:trace("Checking for updated Mod Data on " .. ref.object.name .. ".")

	if ref == tes3.player then
		log:trace("Version Check: Reference is player.")
		--Player Mod Data
		local modData = this.getModDataP(ref)

		if modData.lastExteriorPosition == nil then
			modData["lastExteriorPosition"] = {0.0, 0.0, 0.0}
			log:debug("" .. ref.object.name .. "'s lastExteriorPosition feature updated.")
		end
	else
		log:trace("Version Check: Reference is not the player.")
		--Non-Player Mod Data
		local modData = this.getModData(ref)

		if modData.version == nil then
			modData["version"] = 0
		end

		if modData.version < tables.version then
			--Shared Mod Data--

			--Version
			modData.version = tables.version
			log:debug("" .. ref.object.name .. "'s version updated to " .. tables.version .. ".")

			--Blacklist
			if modData.blacklist == nil then
				modData["blacklist"] = false
				log:debug("" .. ref.object.name .. "'s blacklist feature updated.")
			end

			--Att Gained
			if modData.att_gained == nil then
				modData["att_gained"] = {0, 0, 0, 0, 0, 0, 0, 0}
				log:debug("" .. ref.object.name .. "'s attribute gained feature updated.")
			end

			--Hth Gained
			if modData.hth_gained == nil then
				modData["hth_gained"] = 0
				log:debug("" .. ref.object.name .. "'s health gained feature updated.")
			end

			--Mgk Gained
			if modData.mgk_gained == nil then
				modData["mgk_gained"] = 0
				log:debug("" .. ref.object.name .. "'s magicka gained feature updated.")
			end

			--Fat Gained
			if modData.fat_gained == nil then
				modData["fat_gained"] = 0
				log:debug("" .. ref.object.name .. "'s fatigue gained feature updated.")
			end

			--Lvl Progress
			if modData.lvl_progress == nil then
				modData["lvl_progress"] = 0
				log:debug("" .. ref.object.name .. "'s level progress feature updated.")
			end

			--Lvl Req
			if modData.lvl_req == nil then
				modData["lvl_req"] = (config.expRequirement + (ref.object.level * config.expRate))
				log:debug("" .. ref.object.name .. "'s level requirement feature updated.")
			end

			--Learn Spells
			if modData.spellLearning == nil then
				modData["spellLearning"] = true
				log:debug("" .. ref.object.name .. "'s spell learning setting updated.")
			end

			--Learn Abilities
			if modData.abilityLearning == nil then
				modData["abilityLearning"] = true
				log:debug("" .. ref.object.name .. "'s ability learning setting updated.")
			end

			--Technique Points
			if modData.tp_current == nil then
				modData["tp_current"] = modData.level
				modData["tp_max"] = modData.level

				if modData.abilities ~= nil then
					local bonus = 0

					if ref.object.objectType ~= tes3.objectType.creature then
						--Battlemage
						if modData.abilities[7] == true then
							bonus = bonus + 1
						end
						--Hermit
						if modData.abilities[93] == true then
							bonus = bonus + 1
						end
						--Pilgrim
						if modData.abilities[14] == true then
							bonus = bonus + 1
						end
						--Wise Woman
						if modData.abilities[39] == true then
							bonus = bonus + 1
						end
						--Sorcerer
						if modData.abilities[17] == true then
							bonus = bonus + 2
						end
						--Warlock
						if modData.abilities[37] == true then
							bonus = bonus + 5
						end
					else
						--Daedric 5
						if modData.abilities[5] == true  then
							bonus = bonus + 1
						end
						--Daedric 15
						if modData.abilities[7] == true  then
							bonus = bonus + 2
						end
						--Humanoid 5
						if modData.abilities[13] == true  then
							bonus = bonus + 1
						end
						--Goblin 15
						if modData.abilities[30] == true then
							bonus = bonus + 2
						end
						--Insectile 10
						if modData.abilities[38] == true then
							bonus = bonus + 1
						end
						--Aquatic 15
						if modData.abilities[51] == true then
							bonus = bonus + 1
						end
						--Bestial 15
						if modData.abilities[59] == true then
							bonus = bonus + 1
						end
					end

					modData.tp_current = modData.tp_current + bonus
					modData.tp_max = modData.tp_max + bonus
				end
				log:debug("" .. ref.object.name .. "'s technique point setting updated.")
			end

			--NPC Mod Data--
			if ref.object.objectType ~= tes3.objectType.creature then
				--NPC Abilities
				if modData.abilities == nil then
					modData["abilities"] = {false}
				end

				if #modData.abilities < tables.npcAbilityAmount then
					local difference = tables.npcAbilityAmount - #modData.abilities

					for i = 1, difference do
						table.insert(modData.abilities, false)
					end
					log:debug("" .. ref.object.name .. "'s ability list updated.")
				end

				--Skill Gained
				if modData.skill_gained == nil then
					modData["skill_gained"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
					log:debug("" .. ref.object.name .. "'s skill gained feature updated.")
				end

				--Ignore Skill
				if modData.ignore_skill == nil then
					modData["ignore_skill"] = 99
					log:debug("" .. ref.object.name .. "'s ignore skill feature updated.")
				end

				--Contracts
				if modData.contracts == nil then
					modData["contracts"] = {}
					log:debug("" .. ref.object.name .. "'s contract feature updated.")
				end

				--Bounties
				if modData.bounties == nil then
					modData["bounties"] = {}
					log:debug("" .. ref.object.name .. "'s bounty feature updated.")
				end

				--Training Sessions
				if modData.sessions_current == nil then
					modData["sessions_current"] = 0
					modData["sessions_max"] = 3

					--Drillmaster
					if modData.abilities[25] == true then
						modData.sessions_max = modData.sessions_max + 1
					end
					log:debug("" .. ref.object.name .. "'s training session setting updated.")
				end
			else
				--Creature Mod Data--

				--Type Levels
				if modData.typelevels == nil then
					modData["typelevels"] = {1}
				end

				if #modData.typelevels < tables.creTypeAmount then
					local difference = tables.creTypeAmount - #modData.typelevels

					for i = 1, difference do
						table.insert(modData.typelevels, 1)
					end
					log:debug("" .. ref.object.name .. "'s type list updated.")
				end

				--Creature Abilities
				if modData.abilities == nil then
					modData["abilities"] = {false}
				end

				if #modData.abilities < tables.creAbilityAmount then
					local difference = tables.creAbilityAmount - #modData.abilities

					for i = 1, difference do
						table.insert(modData.abilities, false)
					end
					log:debug("" .. ref.object.name .. "'s ability list updated.")
				end
			end
		end
	end
end

--Update Ideal Character Sheet Values
function this.updateIdealSheet(companionRef)
	local modData = this.getModData(companionRef)
	local attTable = companionRef.mobile.attributes
	local baseTable = companionRef.baseObject.attributes
	local baseSkillTable = companionRef.baseObject.skills

	modData.hth_gained = companionRef.mobile.health.base - companionRef.baseObject.health
	modData.mgk_gained = companionRef.mobile.magicka.base - companionRef.baseObject.magicka
	modData.fat_gained = companionRef.mobile.fatigue.base - companionRef.baseObject.fatigue

	for n = 1, 8 do
		modData.att_gained[n] = (
			modData.att_gained[n] +
				(attTable[n].base - (baseTable[n] + modData.att_gained[n])))
	end

	if companionRef.object.objectType ~= tes3.objectType.creature then
		for n = 0, 26 do
			local skillStat = companionRef.mobile:getSkillStatistic(n)
			modData.skill_gained[n + 1] = (
				modData.skill_gained[n + 1] +
					(skillStat.base - (baseSkillTable[n + 1] + modData.skill_gained[n + 1])))
		end
	end
end


--
----Companion Check-------------------------------------------------------------------------------------------------------------
--

function this.validCompanionCheck(mobileActor)
	log = logger.getLogger("Companion Leveler")
	log:trace("Checking " .. mobileActor.object.name .. "...")

	if (mobileActor == tes3.mobilePlayer) then
		return false
	end

	--Following player?
	local aiPlanner = mobileActor.aiPlanner
	if aiPlanner then
		local aiPackage = aiPlanner:getActivePackage()
		if aiPackage then
			if (aiPackage.type ~= tes3.aiPackage.follow) then
				return false
			else
				if aiPackage.targetActor then
					if (aiPackage.targetActor.reference ~= tes3.player) then
						return false
					end
				else
					return false
				end
			end
		else
			return false
		end
	end

	--Dead Actors
	local animState = mobileActor.actionData.animationAttackState
	if (mobileActor.health.current <= 0 or animState == tes3.animationState.dying or animState == tes3.animationState.dead) then
		return false
	end

	--Slaughterfish made to follow player through Water Life
	if string.endswith(mobileActor.object.name, "Slaughterfish") then
		log:debug("" .. mobileActor.object.name .. " ends with Slaughterfish, invalid companion!")
		return false
	end

	--Abot birds and fish
	if string.startswith(mobileActor.object.id, "ab01") then
		if mobileActor.object.objectType == tes3.objectType.creature then
			log:debug("" .. mobileActor.object.name .. " is an invalid companion!")
			return false
		end
	end

	--Summoned Creatures
	if config.ignoreSummon == true and string.startswith(mobileActor.object.name, "Summoned") then
		log:debug("" .. mobileActor.object.name .. " is a summoned creature, invalid companion!")
		return false
	end

	return true
end


--
----Companion Table Generation--------------------------------------------------------------------------------------------------------
--

--NPC Companions
function this.npcTable()
	local table = {}

	for mobileActor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
		if (this.validCompanionCheck(mobileActor) and mobileActor.reference.object.objectType ~= tes3.objectType.creature) then
			table[#table + 1] = mobileActor.reference
		end
	end

	return table
end

--Creature Companions
function this.creTable()
	local table = {}

	for mobileActor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
		if (this.validCompanionCheck(mobileActor) and mobileActor.reference.object.objectType == tes3.objectType.creature) then
			table[#table + 1] = mobileActor.reference
		end
	end

	return table
end

--All companions
function this.buildTable()
	local table = {}

	for mobileActor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
		if (this.validCompanionCheck(mobileActor)) then
			table[#table + 1] = mobileActor.reference
		end
	end

	return table
end

--Includes player
function this.partyTable()
	local table = {}

	for mobileActor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
		if (this.validCompanionCheck(mobileActor)) then
			table[#table + 1] = mobileActor.reference
		end
	end

	table[#table + 1] = tes3.player

	return table
end


--
----Determine Default Creature Type-------------------------------------------------------------------------------------------------------
--

function this.determineDefault(ref)
	local name = ref.object.name
	local answer = "Normal"

	if ref.object.type == 1 then
		answer = "Daedra"
	end
	if ref.object.type == 2 then
		answer = "Undead"
	end
	if ref.object.type == 3 then
		answer = "Humanoid"
	end
	if (string.endswith(name, "Sphere") or string.endswith(name, "Centurion") or string.endswith(name, "Fabricant") or string.startswith(name, "Centurion")) then
		answer = "Centurion"
	end
	if string.startswith(name, "Spriggan") then
		answer = "Spriggan"
	end
	if (string.startswith(name, "Goblin") or string.startswith(name, "Warchief")) then
		answer = "Goblin"
	end
	if (string.startswith(name, "Guar") or string.endswith(name, "Guar") or string.startswith(name, "Corky") or string.startswith(name, "Pack Rat")) then
		answer = "Domestic"
	end
	if (string.startswith(name, "Ghost") or string.endswith(name, "Ghost") or string.startswith(name, "Wraith") or string.endswith(name, "Wraith") or string.startswith(name, "Spectral") or string.endswith(name, "Spectre")) then
		answer = "Spectral"
	end
	if (string.startswith(name, "Kwama") or string.endswith(name, "Scrib") or string.endswith(name, "Shalk")) then
		answer = "Insectile"
	end
	if (string.startswith(name, "Dragon") or string.endswith(name, "Dragon") or string.endswith(name, "Drake")) then
		answer = "Draconic"
	end
	if (string.startswith(name, "Giant") or string.endswith(name, "Giant") or string.endswith(name, "Ogrim") or string.startswith(name, "Ogrim")) then
		answer = "Brute"
	end
	if (string.startswith(name, "Dreugh") or string.endswith(name, "Dreugh") or string.endswith(name, "Slaughterfish") or string.endswith(name, "Mudcrab") or string.endswith(name, "Horker")) then
		answer = "Aquatic"
	end
	if (string.match(name, "Cliff Racer")) then
		answer = "Avian"
	end
	if (string.match(name, "Bear") or string.match(name, "Wolf")) then
		answer = "Bestial"
	end
	if (string.endswith(name, "Imp") or string.match(name, "Homunculus")) then
		answer = "Impish"
	end

	return answer
end


--
----Remove/Re-Add Abilities------------------------------------------------------------------------------------------------------------
--

function this.removeAbilities(ref)
	log = logger.getLogger("Companion Leveler")

	for i = 1, #tables.abList do
		local wasRemoved = tes3.removeSpell({ spell = tables.abList[i], reference = ref })
		if wasRemoved == true then
			log:debug("" .. tables.abList[i] .. " removed from " .. ref.object.name .. ".")
		else
			log:trace("" .. tables.abList[i] .. " not removed from " .. ref.object.name .. ".")
		end
	end
end

function this.addAbilities(ref)
	log = logger.getLogger("Companion Leveler")
	local modData = this.getModData(ref)
	for i = 1, #tables.abList do
		if modData.abilities[i] == true then
			local wasAdded = tes3.addSpell({ spell = tables.abList[i], reference = ref })
			if wasAdded == true then
				log:debug("" .. tables.abList[i] .. " added back to " .. ref.object.name .. ".")
			else
				log:trace("" .. tables.abList[i] .. " not learned by " .. ref.object.name .. ".")
			end
		end
	end
end

function this.removeAbilitiesNPC(ref)
	log = logger.getLogger("Companion Leveler")
	for i = 1, #tables.abListNPC do
		local wasRemoved = tes3.removeSpell({ spell = tables.abListNPC[i], reference = ref, })
		if wasRemoved == true then
			log:debug("" .. tables.abListNPC[i] .. " removed from " .. ref.object.name .. ".")
		else
			log:trace("" .. tables.abListNPC[i] .. " not removed from " .. ref.object.name .. ".")
		end
	end
end

function this.addAbilitiesNPC(ref)
	log = logger.getLogger("Companion Leveler")
	local modData = this.getModData(ref)
	for i = 1, #tables.abListNPC do
		if modData.abilities[i] == true then
			local wasAdded = tes3.addSpell({ spell = tables.abListNPC[i], reference = ref })
			if wasAdded == true then
				log:debug("" .. tables.abListNPC[i] .. " added back to " .. ref.object.name .. ".")
			else
				log:trace("" .. tables.abListNPC[i] .. " not learned by " .. ref.object.name .. ".")
			end
		end
	end
end


--
----Experience Functions--------------------------------------------------------------------------------------------------
--

function this.calcEXP(ref)
	log = logger.getLogger("Companion Leveler")
	local modData = this.getModData(ref)
	modData.lvl_req = (config.expRequirement + (modData.level * config.expRate))
	log:debug("" .. ref.object.name .. "'s EXP requirement recalculated.")
end

function this.awardEXP(amount)
	if config.buildMode == true then
		--Build Mode

		--Companion Table
		local buildTable = this.buildTable()

		--Level Up Table
		local levelUpTable = {}

		--Experience
		for i = 1, #buildTable do
			local modData = this.getModData(buildTable[i])
			if modData.blacklist == false then
				modData.lvl_progress = modData.lvl_progress + amount
				log:debug("" .. buildTable[i].object.name .. " gained " .. amount .. " experience.")

				this.calcEXP(buildTable[i])

				if modData.lvl_progress >= modData.lvl_req then
					modData.lvl_progress = 0
					levelUpTable[#levelUpTable + 1] = buildTable[i]
					log:debug("" .. buildTable[i].object.name .. " gained enough experience to level up!")
				end
			end
		end
		return levelUpTable, {}, {}
	else
		--Class Mode

		--Companion Tables
		local npcTable = this.npcTable()
		local creTable = this.creTable()

		--Level Up Tables
		local levelUpTable = {}
		local levelUpTableCre = {}

		--NPC Experience
		for i = 1, #npcTable do
			local modData = this.getModData(npcTable[i])
			if modData.blacklist == false then
				modData.lvl_progress = modData.lvl_progress + amount
				log:debug("" .. npcTable[i].object.name .. " gained " .. amount .. " experience.")

				this.calcEXP(npcTable[i])

				if modData.lvl_progress >= modData.lvl_req then
					modData.lvl_progress = 0
					levelUpTable[#levelUpTable + 1] = npcTable[i]
					log:debug("" .. npcTable[i].object.name .. " gained enough experience to level up!")
				end
			end
		end

		--Creature Experience
		for i = 1, #creTable do
			local modData = this.getModData(creTable[i])
			if modData.blacklist == false then
				modData.lvl_progress = modData.lvl_progress + amount
				log:debug("" .. creTable[i].object.name .. " gained " .. amount .. " experience.")

				this.calcEXP(creTable[i])

				if modData.lvl_progress >= modData.lvl_req then
					modData.lvl_progress = 0
					levelUpTableCre[#levelUpTableCre + 1] = creTable[i]
					log:debug("" .. creTable[i].object.name .. " gained enough experience to level up!")
				end
			end
		end
		return {}, levelUpTable, levelUpTableCre
	end
end


--
----Technique Functions--------------------------------------------------------------------------------------------------
--

function this.spendTP(ref, cost)
	local modData = this.getModData(ref)

	if modData.tp_current < cost then
		tes3.messageBox("Not enough Technique Points!")
		return false
	else
		modData.tp_current = modData.tp_current - cost
		return true
	end
end

function this.checkReq(test, item, count, ref)
	log = logger.getLogger("Companion Leveler")
	log:trace("Check Req triggered.")

	if test then
		local itemsRemoved = tes3.removeItem({ reference = ref, item = item, count = count, playSound = false })
		if itemsRemoved > 0 then
			local itemsAdded = tes3.addItem({ reference = ref, item = item, count = itemsRemoved, playSound = false })
		end

		if itemsRemoved == count then
			log:debug("" .. ref.object.name .. " has enough " .. item .. ".")
			return true
		else
			log:debug("" .. ref.object.name .. " does not have enough " .. item .. ".")
			return false
		end
	else
		local itemsRemoved = tes3.removeItem({ reference = ref, item = item, count = count })
		log:debug("" .. ref.object.name .. " used " .. count .. " " .. item .. ".")
	end
end


--
----UI--------------------------------------------------------------------------------------------------------------------
--

--Creates a Bar.
--
--1st: tes3uiElement
--
--2nd: string: small/standard
--
--3rd: string: red/blue/green/gold/purple
function this.configureBar(ele, type, color)
	ele.widget.showText = true
	ele.widget.fillColor = tables.colors[color]

	--Size
	if type == "standard" then
		ele.width = 180
	elseif type == "small" then
		ele.width = 120
		ele.height = 15
		local text = ele:findChild("PartFillbar_text_ptr")
		text.positionY = 3
	end

	--Tooltips
	if color == "purple" then
		this.clTooltip(ele, "tp")
	elseif color == "gold" then
		this.clTooltip(ele, "exp")
	elseif color == "red" then
		this.clTooltip(ele, "health")
	elseif color == "blue" then
		this.clTooltip(ele, "magicka")
	elseif color == "green" then
		this.clTooltip(ele, "fatigue")
	end
end

--Ability Tooltips. displays class ability (spell) tooltips
function this.abilityTooltip(ele, key, npc)
	local spellObject
	local type
	local desc
	local desc2

	if npc then
		spellObject = tes3.getObject(tables.abListNPC[key])
		type = tables.abTypeNPC[key]
		desc = tables.abDescriptionNPC[key]
		desc2 = tables.abDescriptionNPC2[key]
	else
		spellObject = tes3.getObject(tables.abList[key])
		type = tables.abType[key]
		desc = tables.abDescription[key]
		desc2 = tables.abDescription2[key]
	end

	ele:register("help", function(e)
		local tooltip = tes3ui.createTooltipMenu { spell = spellObject }

		local contentElement = tooltip:getContentElement()
		contentElement.paddingAllSides = 12
		contentElement.childAlignX = 0.5
		contentElement.childAlignY = 0.5

		tooltip:createDivider()

		local typeLabel = tooltip:createLabel { text = type }
		typeLabel.color = tables.colors["white"]

		if string.match(typeLabel.text, "TRIGGER") then
			--Green
			typeLabel.color = tables.colors["green"]
		elseif string.match(typeLabel.text, "COMBAT") then
			--Red
			typeLabel.color = tables.colors["red"]
		elseif string.match(typeLabel.text, "TECHNIQUE") then
			--Purple
			typeLabel.color = tables.colors["dark_purple"]
		elseif string.match(typeLabel.text, "AURA") then
			--Blue
			typeLabel.color = { 0.3, 0.3, 0.7 }
		end

		local helpLabel = tooltip:createLabel { text = desc }
		helpLabel.borderTop = 7

		if desc2 ~= "" then
			local helpLabel2 = tooltip:createLabel { text = desc2 }
			helpLabel2.borderTop = 7
		end
	end)
end

--CL General Tooltips.
--
--1st: tes3uiElement
--
--2nd: string: tp/exp/health/magicka/fatigue/ignore_skill/skill:0/att:0
function this.clTooltip(ele, type)
	ele:register("help", function(e)
		local tooltip = tes3ui.createTooltipMenu()

		local contentElement = tooltip:getContentElement()
		contentElement.flowDirection = tes3.flowDirection.leftToRight
		contentElement.paddingAllSides = 10

		local label
		local icon = nil

		if type == "tp" then
			icon = tooltip:createImage({ path = "textures\\companionLeveler\\tech_icon.tga" })
			label = tooltip:createLabel { text = "Used to perform techniques. Technique Points are restored each level.\nTotal TP is based on level + ability bonuses." }
		elseif type == "exp" then
			icon = tooltip:createImage({ path = "textures\\companionLeveler\\exp_icon.tga" })
			label = tooltip:createLabel { text = "" .. tes3.findGMST("sLevelProgress").value .. ". Experience is gained through\nskill training, quests, and combat." }
		elseif type == "health" then
			icon = tooltip:createImage({ path = "Icons\\k\\Health.dds" })
			label = tooltip:createLabel { text = "" .. tes3.findGMST("sHealthDesc").value .. "" }
		elseif type == "magicka" then
			icon = tooltip:createImage({ path = "Icons\\k\\Magicka.dds" })
			label = tooltip:createLabel { text = "" .. tes3.findGMST("sMagDesc").value .. "" }
		elseif type == "fatigue" then
			icon = tooltip:createImage({ path = "Icons\\k\\Fatigue.dds" })
			label = tooltip:createLabel { text = "" .. tes3.findGMST("sFatDesc").value .. "" }
		elseif type == "ignore_skill" then
			label = tooltip:createLabel { text = "Ignored skills are not trained at level up." }
		elseif string.startswith(type, "skill:") then
			for i = 0, 26 do
				if type == "skill:" .. i .. "" then
					local skill = tes3.getSkill(i)
					label = tooltip:createLabel { text = "Based on " .. skill.name .. " " .. tes3.findGMST("sSkill").value .. "." }
					break
				end
			end
		elseif string.startswith(type, "att:") then
			if type == "att:level" then
				label = tooltip:createLabel { text = "Based on " .. tes3.findGMST("sLevel").value .. "." }
			else
				for i = 0, 7 do
					if type == "att:" .. i .. "" then
						label = tooltip:createLabel { text = "Based on " .. tes3.findGMST("sAttribute" .. tables.capitalization[i] .. "").value .. "." }
					end
				end
			end
		end

		if icon ~= nil then
			label.borderLeft = 10
		end
	end)
end

--UI Ability Colors.
--
--1st: tes3uiElement
--
--2nd: int (the ability #)
--
--3rd: NPC? Boolean
function this.abilityColor(ele, num, npc)
	if config.abilityColors == true then
		ele.widget.idle = tables.colors["white"]

		local table

		if npc == true then
			table = tables.abTypeNPC
		else
			table = tables.abType
		end

		if string.match(table[num], "TRIGGER") then
			--Green
			ele.widget.idle = tables.colors["green"]
		elseif string.match(table[num], "COMBAT") then
			--Red
			ele.widget.idle = tables.colors["red"]
		elseif string.match(table[num], "TECHNIQUE") then
			--Purple
			ele.widget.idle = tables.colors["dark_purple"]
		elseif string.match(table[num], "AURA") then
			--UI Blue
			ele.widget.idle = tables.colors["ui_blue"]
		end
	end
end

--pane sort function?
--error handling?

return this