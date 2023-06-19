local config = require("companionLeveler.config")
local tables = require("companionLeveler.tables")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")


local this = {}

--
----Mod Data------------------------------------------------------------------------------------------------------------------
--

function this.getModDataP(playerRef)
    log:trace("Checking player's saved Mod Data.")
    if not playerRef.data.companionLeveler then
        log:info("Player Mod Data not found, setting to base Mod Data values.")
        playerRef.data.companionLeveler = { ["noDupe"] = 0 }
        playerRef.modified = true
    else
        log:trace("Saved Mod Data found.")
    end
    return playerRef.data.companionLeveler
end

function this.getModData(ref)
	log = logger.getLogger("Companion Leveler")
	log:trace("Checking saved Mod Data.")
	if not ref.data.companionLeveler then
		--NPC Data-----------------------------------------------------------------------------------------------------------------------
		if ref.object.objectType ~= tes3.objectType.creature then
			log:info("NPC Mod Data not found, setting to base Mod Data values.")
			ref.data.companionLeveler = { ["version"] = tables.version, ["blacklist"] = false, ["level"] = ref.object.level,
				["class"] = ref.object.class.id,
				["summary"] = "No Summary.", ["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
				["skillMods"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
				["skillModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
				["att_gained"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
				["skill_gained"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
				["hth_gained"] = 0,
				["mgk_gained"] = 0,
				["fat_gained"] = 0, ["lvl_progress"] = 0, ["lvl_req"] = (config.expRequirement + (ref.object.level * config.expRate)), ["ignore_skill"] = 99, ["contracts"] = {}, ["bounties"] = {},
				["abilities"] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false,
					false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
					false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
					false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
					false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
					false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
					false, false, false, false, false, false, false, false, false, false, false } }
		else
			--Creature Data--------------------------------------------------------------------------------------------------------------
			local defType = this.determineDefault(ref)

			if defType == "Normal" then
				log:info("Normal type detected.")
				ref.data.companionLeveler = { ["version"] = tables.version, ["blacklist"] = false, ["level"] = ref.object.level, ["type"] = "Normal", ["typelevels"] = { ref.object.level, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
					["summary"] = "No Summary.",
					["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["abilities"] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false },
					["att_gained"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["hth_gained"] = 0,
					["mgk_gained"] = 0,
					["fat_gained"] = 0, ["lvl_progress"] = 0, ["lvl_req"] = (config.expRequirement + (ref.object.level * config.expRate)) }
			end
			if defType == "Daedra" then
				log:info("Daedra type detected.")
				ref.data.companionLeveler = { ["version"] = tables.version, ["blacklist"] = false, ["level"] = ref.object.level, ["type"] = "Daedra", ["typelevels"] = { 1, ref.object.level, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
					["summary"] = "No Summary.",
					["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["abilities"] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false },
					["att_gained"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["hth_gained"] = 0,
					["mgk_gained"] = 0,
					["fat_gained"] = 0, ["lvl_progress"] = 0, ["lvl_req"] = (config.expRequirement + (ref.object.level * config.expRate)) }
			end
			if defType == "Undead" then
				log:info("Undead type detected.")
				ref.data.companionLeveler = { ["version"] = tables.version, ["blacklist"] = false, ["level"] = ref.object.level, ["type"] = "Undead", ["typelevels"] = { 1, 1, ref.object.level, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
					["summary"] = "No Summary.",
					["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["abilities"] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false },
					["att_gained"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["hth_gained"] = 0,
					["mgk_gained"] = 0,
					["fat_gained"] = 0, ["lvl_progress"] = 0, ["lvl_req"] = (config.expRequirement + (ref.object.level * config.expRate)) }
			end
			if defType == "Humanoid" then
				log:info("Humanoid type detected.")
				ref.data.companionLeveler = { ["version"] = tables.version, ["blacklist"] = false, ["level"] = ref.object.level, ["type"] = "Humanoid", ["typelevels"] = { 1, 1, 1, ref.object.level, 1, 1, 1, 1, 1, 1, 1, 1 },
					["summary"] = "No Summary.",
					["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["abilities"] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false },
					["att_gained"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["hth_gained"] = 0,
					["mgk_gained"] = 0,
					["fat_gained"] = 0, ["lvl_progress"] = 0, ["lvl_req"] = (config.expRequirement + (ref.object.level * config.expRate)) }
			end
			--Custom Type Detection-------------------------------------------------------------------------------------------------
			if defType == "Centurion" then
				log:info("Centurion type detected.")
				ref.data.companionLeveler = { ["version"] = tables.version, ["blacklist"] = false, ["level"] = ref.object.level, ["type"] = "Centurion", ["typelevels"] = { 1, 1, 1, 1, ref.object.level, 1, 1, 1, 1, 1, 1, 1 },
					["summary"] = "No Summary.",
					["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["abilities"] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false },
					["att_gained"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["hth_gained"] = 0,
					["mgk_gained"] = 0,
					["fat_gained"] = 0, ["lvl_progress"] = 0, ["lvl_req"] = (config.expRequirement + (ref.object.level * config.expRate)) }
			end
			if defType == "Spriggan" then
				log:info("Spriggan type detected.")
				ref.data.companionLeveler = { ["version"] = tables.version, ["blacklist"] = false, ["level"] = ref.object.level, ["type"] = "Spriggan", ["typelevels"] = { 1, 1, 1, 1, 1, ref.object.level, 1, 1, 1, 1, 1, 1 },
					["summary"] = "No Summary.",
					["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["abilities"] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false },
					["att_gained"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["hth_gained"] = 0,
					["mgk_gained"] = 0,
					["fat_gained"] = 0, ["lvl_progress"] = 0, ["lvl_req"] = (config.expRequirement + (ref.object.level * config.expRate)) }
			end
			if defType == "Goblin" then
				log:info("Goblin type detected.")
				ref.data.companionLeveler = { ["version"] = tables.version, ["blacklist"] = false, ["level"] = ref.object.level, ["type"] = "Goblin", ["typelevels"] = { 1, 1, 1, 1, 1, 1, ref.object.level, 1, 1, 1, 1, 1 },
					["summary"] = "No Summary.",
					["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["abilities"] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false },
					["att_gained"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["hth_gained"] = 0,
					["mgk_gained"] = 0,
					["fat_gained"] = 0, ["lvl_progress"] = 0, ["lvl_req"] = (config.expRequirement + (ref.object.level * config.expRate)) }
			end
			if defType == "Domestic" then
				log:info("Domestic type detected.")
				ref.data.companionLeveler = { ["version"] = tables.version, ["blacklist"] = false, ["level"] = ref.object.level, ["type"] = "Domestic", ["typelevels"] = { 1, 1, 1, 1, 1, 1, 1, ref.object.level, 1, 1, 1, 1 },
					["summary"] = "No Summary.",
					["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["abilities"] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false },
					["att_gained"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["hth_gained"] = 0,
					["mgk_gained"] = 0,
					["fat_gained"] = 0, ["lvl_progress"] = 0, ["lvl_req"] = (config.expRequirement + (ref.object.level * config.expRate)) }
			end
			if defType == "Spectral" then
				log:info("Spectral type detected.")
				ref.data.companionLeveler = { ["version"] = tables.version, ["blacklist"] = false, ["level"] = ref.object.level, ["type"] = "Spectral", ["typelevels"] = { 1, 1, 1, 1, 1, 1, 1, 1, ref.object.level, 1, 1, 1 },
					["summary"] = "No Summary.",
					["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["abilities"] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false },
					["att_gained"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["hth_gained"] = 0,
					["mgk_gained"] = 0,
					["fat_gained"] = 0, ["lvl_progress"] = 0, ["lvl_req"] = (config.expRequirement + (ref.object.level * config.expRate)) }
			end
			if defType == "Insectile" then
				log:info("Insectile type detected.")
				ref.data.companionLeveler = { ["version"] = tables.version, ["blacklist"] = false, ["level"] = ref.object.level, ["type"] = "Insectile", ["typelevels"] = { 1, 1, 1, 1, 1, 1, 1, 1, 1, ref.object.level, 1, 1 },
					["summary"] = "No Summary.",
					["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["abilities"] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false },
					["att_gained"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["hth_gained"] = 0,
					["mgk_gained"] = 0,
					["fat_gained"] = 0, ["lvl_progress"] = 0, ["lvl_req"] = (config.expRequirement + (ref.object.level * config.expRate)) }
			end
			if defType == "Draconic" then
				log:info("Draconic type detected.")
				ref.data.companionLeveler = { ["version"] = tables.version, ["blacklist"] = false, ["level"] = ref.object.level, ["type"] = "Draconic", ["typelevels"] = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, ref.object.level, 1 },
					["summary"] = "No Summary.",
					["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["abilities"] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false },
					["att_gained"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["hth_gained"] = 0,
					["mgk_gained"] = 0,
					["fat_gained"] = 0, ["lvl_progress"] = 0, ["lvl_req"] = (config.expRequirement + (ref.object.level * config.expRate)) }
			end
			if defType == "Brute" then
				log:info("Brute type detected.")
				ref.data.companionLeveler = { ["version"] = tables.version, ["blacklist"] = false, ["level"] = ref.object.level, ["type"] = "Brute", ["typelevels"] = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, ref.object.level },
					["summary"] = "No Summary.",
					["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["abilities"] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
						false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false },
					["att_gained"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
					["hth_gained"] = 0,
					["mgk_gained"] = 0,
					["fat_gained"] = 0, ["lvl_progress"] = 0, ["lvl_req"] = (config.expRequirement + (ref.object.level * config.expRate)) }
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

function this.checkModData(ref)
	log = logger.getLogger("Companion Leveler")
	log:trace("Checking for existing Mod Data.")

	if not ref.data.companionLeveler then
		return false
	else
		return true
	end
end

function this.updateModData(ref)
	log = logger.getLogger("Companion Leveler")
	log:trace("Checking for updated Mod Data.")

	if ref.data.companionLeveler then
		local modData = this.getModData(ref)

		if modData.version == nil then
			modData["version"] = 0
		end

		if modData.version < tables.version then
			--Shared Mod Data--

			--Version
			modData.version = tables.version
			log:debug("" .. ref.object.name .. "'s version updated.")

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
				if (aiPackage.targetActor.reference ~= tes3.player) then
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

	table[#table + 1] = tes3.player.mobile

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
----Update Character Sheet---------------------------------------------------------------------------------------------------
--

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


return this