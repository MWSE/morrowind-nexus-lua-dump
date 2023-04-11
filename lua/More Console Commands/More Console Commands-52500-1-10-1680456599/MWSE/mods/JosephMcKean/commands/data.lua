local config = require("JosephMcKean.commands.config")
local console = tes3ui.registerID("MenuConsole")
local data = {}
local modName = "More Console Commands"

data.objectType = {
	["alchemy"] = tes3.objectType.alchemy,
	["ammunition"] = tes3.objectType.ammunition,
	["apparatus"] = tes3.objectType.apparatus,
	["armor"] = tes3.objectType.armor,
	["book"] = tes3.objectType.book,
	["clothing"] = tes3.objectType.clothing,
	["ingredient"] = tes3.objectType.ingredient,
	["light"] = tes3.objectType.light,
	["lockpick"] = tes3.objectType.lockpick,
	["miscitem"] = tes3.objectType.miscItem,
	["probe"] = tes3.objectType.probe,
	["repairitem"] = tes3.objectType.repairItem,
	["weapon"] = tes3.objectType.weapon,
}

data.objectTypeNames = {} ---@type string[]
for objectTypeName, _ in pairs(data.objectType) do
	table.insert(data.objectTypeNames, objectTypeName)
end

---@return tes3reference ref
function data.getCurrentRef()
	local ref = tes3ui.findMenu(console):getPropertyObject("MenuConsole_current_ref")
	return ref
end

data.setNames = {
	"agility",
	"endurance",
	"intelligence",
	"luck",
	"personality",
	"speed",
	"strength",
	"willpower",
	"acrobatics",
	"alchemy",
	"alteration",
	"armorer",
	"athletics",
	"axe",
	"block",
	"bluntweapon",
	"conjuration",
	"destruction",
	"enchant",
	"handtohand",
	"heavyarmor",
	"illusion",
	"lightarmor",
	"longblade",
	"marksman",
	"mediumarmor",
	"mercantile",
	"mysticism",
	"restoration",
	"security",
	"shortblade",
	"sneak",
	"spear",
	"speechcraft",
	"unarmored",
	"health",
	"magicka",
	"fatigue",
}

---@param name string
---@return string?
local function getName(name)
	local camelCased = {
		["mediumarmor"] = "mediumArmor",
		["heavyarmor"] = "heavyArmor",
		["bluntweapon"] = "bluntWeapon",
		["longblade"] = "longBlade",
		["lightarmor"] = "lightArmor",
		["shortblade"] = "shortBlade",
		["handtohand"] = "handToHand",
	}
	name = camelCased[name] or name
	return name
end

data.skillModuleSkills = {
	["bushcrafting"] = { id = "Bushcrafting", mod = "Ashfall", include = "mer.ashfall.common.common" },
	["climbing"] = { id = "climbing", mod = "Mantle of Ascension", include = "mantle.main" },
	["cooking"] = { id = "mc_Cooking", mod = "Morrowind Crafting", include = "Morrowind_Crafting_3.mc_common" },
	["corpsepreparation"] = { id = "NC:CorpsePreparation", mod = "Necrocraft", include = "necroCraft.main" },
	["crafting"] = { id = "mc_Crafting", mod = "Morrowind Crafting", include = "Morrowind_Crafting_3.mc_common" },
	["fletching"] = { id = "fletching", mod = "Go Fletch", include = "mer.goFletch.main" },
	["mcfletching"] = { id = "mc_Fletching", mod = "Morrowind Crafting", include = "Morrowind_Crafting_3.mc_common" },
	["inscription"] = { id = "Hermes:Inscription", mod = "Demon of Knowledge", include = "MMM2018.sx2.main" },
	["masonry"] = { id = "mc_Masonry", mod = "Morrowind Crafting", include = "Morrowind_Crafting_3.mc_common" },
	["metalworking"] = { id = "mc_Metalworking", mod = "Morrowind Crafting", include = "Morrowind_Crafting_3.mc_common" },
	["mining"] = { id = "mc_Mining", mod = "Morrowind Crafting", include = "Morrowind_Crafting_3.mc_common" },
	["packrat"] = { id = "Packrat", mod = "Packrat Skill", include = "gool.packrat.main" },
	["performance"] = {
		id = "BardicInspiration:Performance",
		mod = "Bardic Inspiration",
		include = "mer.bardicInspiration.controllers.skillController",
	},
	["sewing"] = { id = "mc_Sewing", mod = "Morrowind Crafting", include = "Morrowind_Crafting_3.mc_common" },
	["smithing"] = { id = "mc_Smithing", mod = "Morrowind Crafting", include = "Morrowind_Crafting_3.mc_common" },
	["staff"] = { id = "MSS:Staff", mod = "MWSE Staff Skill", include = "inpv.Staff Skill.main" },
	["survival"] = { id = "Ashfall:Survival", mod = "Ashfall", include = "mer.ashfall.common.common" },
	["woodworking"] = { id = "mc_Woodworking", mod = "Morrowind Crafting", include = "Morrowind_Crafting_3.mc_common" },
}

data.skillModuleSkillNames = {} ---@type string[]
for skillname, skillData in pairs(data.skillModuleSkills) do
	if include(skillData.include) then
		table.insert(data.skillModuleSkillNames, skillname)
	end
end

local function listMarks()
	if not table.empty(config.marks) then
		tes3ui.log("\nHere is a list of marks that are available:")
		for id, mark in pairs(config.marks) do
			tes3ui.log("%s: %s", id, mark.name)
		end
	else
		tes3ui.log(
		"Type mark or recall to view all marks, type mark <id> to mark, type recall <id> to recall. \nExample: mark home, recall home.\n<id> needs to be one single word like this or likethis or like_this.")
	end
end

---@param name string
---@param value number
local function levelUp(name, value)
	local skillModule = include("OtherSkills.skillModule")
	if not skillModule then
		return
	end
	local skillData = data.skillModuleSkills[name:lower()]
	if not skillData then
		return
	end
	local skill = skillModule.getSkill(skillData.id)
	if not skill then
		return
	end
	skill:levelUpSkill(value)
end

---@class console.removeItems.params
---@field reference tes3reference
---@field goldOnly boolean?

---@param params console.removeItems.params
local function removeItems(params)
	if not params then
		return
	end
	local ref = params.reference
	if not ref then
		return
	end
	if params.goldOnly then
		local count = tes3.getItemCount({ reference = ref, item = "gold_001" })
		if ref then -- tes3.player might be nil
			tes3.removeItem({ reference = ref, item = "gold_001", count = count })
		end
	else
		for _, stack in pairs(ref.object.inventory.items) do
			tes3.removeItem({ reference = ref, item = stack.object, count = stack.count, playSound = false })
		end
		tes3ui.log("%s inventory has been emptied.", ref.id)
	end
end

---@param count number
local function giveGold(count)
	if count <= 0 then
		return
	end
	local ref = data.getCurrentRef() or tes3.player ---@type tes3reference
	if ref then
		tes3.addItem({ reference = ref, item = "gold_001", count = count, showMessage = true })
	end
end

---@param npc tes3mobileNPC
---@return table
function data.getSkillsDesc(npc)
	local skills = {}
	---@param index integer
	---@param value integer
	for index, value in ipairs(npc.skills) do -- index = skillId + 1
		table.insert(skills, { index = index, value = value.current })
	end
	table.sort(skills, function(a, b)
		return a.value > b.value
	end)
	return skills
end

---@class command.data.argument
---@field index integer
---@field metavar string
---@field required boolean
---@field choices string[]?
---@field help string

---@class command.data
---@field description string
---@field arguments command.data.argument[]?
---@field callback function

---@class command : command.data

---@type command[]
data.commands = {
	-- Money cheats
	["kaching"] = {
		description = "Give current reference 1,000 gold.",
		callback = function()
			giveGold(1000)
		end,
	},
	["motherlode"] = {
		description = "Give current reference 50,000 gold.",
		callback = function()
			giveGold(50000)
		end,
	},
	["money"] = {
		description = "Set current reference gold amount to the input value. e.g. money 420",
		arguments = { { index = 1, metavar = "goldcount", required = true, help = "the amount of gold to add" } },
		callback = function(argv)
			local ref = data.getCurrentRef() or tes3.player ---@type tes3reference
			local count = tonumber(argv[1])
			if not count then
				return
			end
			removeItems({ reference = ref, goldOnly = true })
			giveGold(count)
		end,
	},
	-- stats cheats
	["cure"] = {
		description = "Cure current reference of disease, blight, poison, and restore attributes and skills",
		callback = function(argv)
			local cureCommon = tes3.getObject("Cure Common Disease Other") ---@cast cureCommon tes3spell
			local cureBlight = tes3.getObject("Cure Blight Disease") ---@cast cureBlight tes3spell
			local curePoison = tes3.getObject("Cure Poison Touch") ---@cast curePoison tes3spell
			local restoreAttribute = tes3.getObject("Almsivi Restoration") ---@cast restoreAttribute tes3spell
			local restoreSkillsFighter = tes3.getObject("Almsivi Restore Fighter") ---@cast restoreSkillsFighter tes3spell
			local restoreSkillsMage = tes3.getObject("Almsivi Restore Mage") ---@cast restoreSkillsMage tes3spell
			local restoreSkillsThief = tes3.getObject("Almsivi Restore Stealth") ---@cast restoreSkillsThief tes3spell
			local restoreSkillsOther = tes3.getObject("Almsivi Restore Other") ---@cast restoreSkillsOther tes3spell
			local ref = data.getCurrentRef() or tes3.player ---@type tes3reference
			if ref.mobile.isDiseased then
				tes3.applyMagicSource({ reference = ref, source = cureCommon, castChance = 100, bypassResistances = true })
				tes3.applyMagicSource({ reference = ref, source = cureBlight, castChance = 100, bypassResistances = true })
			end
			if tes3.isAffectedBy({ reference = ref, effect = tes3.effect.poison }) then
				tes3.applyMagicSource({ reference = ref, source = curePoison, castChance = 100, bypassResistances = true })
			end
			tes3.applyMagicSource({ reference = ref, source = restoreAttribute, castChance = 100, bypassResistances = true })
			-- Restore Skills
			tes3.applyMagicSource({ reference = ref, source = restoreSkillsFighter, castChance = 100, bypassResistances = true })
			tes3.applyMagicSource({ reference = ref, source = restoreSkillsMage, castChance = 100, bypassResistances = true })
			tes3.applyMagicSource({ reference = ref, source = restoreSkillsThief, castChance = 100, bypassResistances = true })
			tes3.applyMagicSource({ reference = ref, source = restoreSkillsOther, castChance = 100, bypassResistances = true })
		end,
	},
	["levelup"] = {
		description = "Increase the player's skill by the input value. e.g. levelup bushcrafting 69, levelup survival 420",
		arguments = {
			{
				index = 1,
				metavar = "skillname",
				required = true,
				choices = data.skillModuleSkillNames,
				help = "the name of the skill to level up",
			},
			{ index = 2, metavar = "value", required = true, help = "the increase value" },
		},
		callback = function(argv)
			levelUp(argv[1], tonumber(argv[2]) or 0)
		end,
	},
	["max"] = {
		description = "Set the current reference's all attributes and skills base value to the input value.",
		arguments = { { index = 1, metavar = "value", required = false, help = "the value to set" } },
		callback = function(argv)
			local ref = data.getCurrentRef() or tes3.player
			if not ref then
				return
			end
			local value = tonumber(argv[1]) or 200
			for _, name in ipairs(data.setNames) do
				tes3.setStatistic({ reference = tes3.player, name = getName(name), value = value })
			end
		end,
	},
	["set"] = {
		description = "Set the current reference's attribute or skill base value.",
		arguments = {
			{
				index = 1,
				metavar = "name",
				required = true,
				choices = data.setNames,
				help = "the name of the attribute or skill to set",
			},
			{ index = 2, metavar = "value", required = true, help = "the value to set" },
		},
		callback = function(argv)
			local ref = data.getCurrentRef() or tes3.player
			if not ref then
				return
			end
			local name = getName(argv[1])
			tes3.setStatistic({ reference = ref, name = name, value = tonumber(argv[2]) })
		end,
	},
	["skills"] = {
		description = "Print the current reference's skills.",
		callback = function(argv)
			local ref = data.getCurrentRef()
			if not ref then
				tes3ui.log("skills: error: currentRef not found")
				return
			end
			local npc = ref.mobile
			if not npc then
				return
			end
			---@cast npc tes3mobileNPC
			tes3ui.log("%s skills:", npc.reference.object.name)
			for _, skill in ipairs(data.getSkillsDesc(npc)) do
				tes3ui.log("%s %s", tes3.skillName[skill.index - 1], skill.value)
			end
		end,
	},
	["speedy"] = {
		description = "Increase the player's speed to 200, athletics to 200.",
		callback = function(argv)
			tes3.setStatistic({ reference = tes3.player, attribute = tes3.attribute.speed, value = 200 })
			tes3.setStatistic({ reference = tes3.player, skill = tes3.skill.athletics, value = 200 })
		end,
	},
	-- mark and recall
	["mark"] = {
		description = "Mark the player's current cell and position for recall. Type mark to view all marks, type mark <id> to mark. e.g. mark home",
		arguments = { { index = 1, metavar = "id", required = false, help = "the id of the mark" } },
		callback = function(argv)
			if not argv[1] then
				listMarks()
			else
				local cell = nil
				if tes3.player.cell.isInterior then
					cell = tes3.player.cell.id
				end
				local position = tes3.player.position
				local orientation = tes3.player.orientation
				config.marks[argv[1]] = {
					name = tes3.player.cell.editorName,
					cell = cell,
					position = { x = position.x, y = position.y, z = position.z },
					orientation = { x = orientation.x, y = orientation.y, z = orientation.z },
				}
				mwse.saveConfig(modName, config)
				tes3ui.log("%s: %s", argv[1], tes3.player.cell.editorName)
				mwse.log("marks[%s].cell = {\nname = %s,\ncell = %s,\nposition = { %s, %s, %s },\norientation = { %s, %s, %s }\n}",
				         argv[1], tes3.player.cell.editorName, cell, position.x, position.y, position.z, orientation.x,
				         orientation.y, orientation.z)
			end
		end,
	},
	["recall"] = {
		description = "Teleport the player to a previous mark. Type recall to view all marks, type recall <id> to recall. e.g. recall home",
		arguments = { { index = 1, metavar = "id", required = false, help = "the id of the mark" } },
		callback = function(argv)
			if not argv[1] then
				listMarks()
			else
				local mark = config.marks[argv[1]]
				if mark then
					if mark.cell then
						tes3.positionCell({
							cell = tes3.getCell({ id = mark.cell }),
							position = { mark.position.x, mark.position.y, mark.position.z },
							orientation = { mark.orientation.x, mark.orientation.y, mark.orientation.z },
							forceCellChange = true,
						})
					else
						tes3.positionCell({
							position = { mark.position.x, mark.position.y, mark.position.z },
							orientation = { mark.orientation.x, mark.orientation.y },
							forceCellChange = true,
						})
					end
				end
			end
		end,
	},
	-- NPC command
	["emptyinventory"] = {
		description = "Empty the current reference's inventory.",
		arguments = { { index = 1, metavar = "player", required = false, help = "specified to empty player inventory" } },
		callback = function(argv)
			if argv[1] == "player" then
				removeItems({ reference = tes3.player })
				return
			end
			local ref = data.getCurrentRef()
			if not ref or (ref == tes3.player) then
				tes3ui.log("For safety reason, type emptyinventory player to empty player inventory.")
			else
				removeItems({ reference = ref })
			end
		end,
	},
	["follow"] = {
		description = "Make the current reference your follower.",
		callback = function(argv)
			local ref = data.getCurrentRef()
			if not ref then
				return
			end
			tes3.setAIFollow({ reference = ref, target = tes3.player })
		end,
	},
	["kill"] = {
		description = "Kill the current reference. For safety reason, type kill player to kill the player.",
		arguments = { { index = 1, metavar = "player", required = false, help = "specified to kill player" } },
		callback = function(argv)
			local ref = data.getCurrentRef()
			if not argv[1] and ref and ref.mobile then
				local actor = ref.mobile ---@cast actor tes3mobileNPC|tes3mobileCreature|tes3mobilePlayer
				if actor ~= tes3.mobilePlayer then
					actor:kill()
				else
					tes3ui.log("For safety reason, type kill player to kill the player.")
				end
			elseif argv[1] == "player" then
				tes3.mobilePlayer:kill()
			end
		end,
	},
	["resurrect"] = {
		description = "Resurrect the current reference and keep the inventory.",
		callback = function(argv)
			local ref = data.getCurrentRef()
			if ref and ref.mobile then
				local actor = ref.mobile ---@cast actor tes3mobileNPC|tes3mobileCreature|tes3mobilePlayer
				actor:resurrect({ resetState = false })
			end
		end,
	},
	["showinventory"] = {
		description = "Show the current reference's inventory.",
		callback = function(argv)
			local ref = data.getCurrentRef()
			if not ref then
				return
			end
			tes3ui.leaveMenuMode()
			tes3ui.findMenu(console).visible = false
			timer.delayOneFrame(function()
				tes3.showContentsMenu({ reference = ref })
			end)
		end,
	},
	["spawn"] = {
		description = "Spawn a reference with the specified id.",
		arguments = { { index = 1, metavar = "id", required = true, help = "the id of the reference to spawn" } },
		callback = function(argv)
			local obj = tes3.getObject(argv[1])
			if not obj then
				tes3ui.log("spawn: error: %s is not a valid object id", argv[1])
				return
			end
			tes3.createReference({
				object = argv[1],
				position = tes3.player.position,
				orientation = tes3.player.orientation,
				cell = tes3.player.cell,
			})
		end,
	},
	["wander"] = {
		description = "Make the current reference wander.",
		callback = function(argv)
			local ref = data.getCurrentRef()
			if not ref then
				return
			end
			tes3.setAIWander({ reference = ref, range = 512, idles = { 60, 20, 20, 0, 0, 0, 0, 0 } })
		end,
	},
	-- item commands
	["addall"] = {
		description = "Add all objects of the objectType type to the current reference's inventory.",
		arguments = {
			{
				index = 1,
				metavar = "name",
				required = true,
				choices = data.objectTypeNames,
				help = "the name of the object type to add all",
			},
			{ index = 2, metavar = "value", required = false, help = "the add item count" },
		},
		callback = function(argv)
			local ref = data.getCurrentRef() or tes3.player
			if not ref then
				return
			end
			local count = tonumber(argv[2])
			if not count then
				count = 1
			elseif count <= 0 then
				return
			end
			local filter = data.objectType[argv[1]]
			---@param object tes3object|tes3light
			for object in tes3.iterateObjects(filter) do
				if (object.name ~= "") and not object.script then
					if filter == tes3.objectType.light then
						if object.canCarry then
							tes3.addItem({ reference = ref, item = object.id, count = count, playSound = false })
						end
					else
						tes3.addItem({ reference = ref, item = object.id, count = count, playSound = false })
					end
				end
			end
		end,
	},
	["addone"] = {
		description = "Add one object of the objectType type to the current reference's inventory.",
		arguments = {
			{
				index = 1,
				metavar = "name",
				required = true,
				choices = data.objectTypeNames,
				help = "the name of the object type to add one",
			},
			{ index = 2, metavar = "value", required = false, help = "the add item count" },
		},
		callback = function(argv)
			local ref = data.getCurrentRef() or tes3.player
			if not ref then
				return
			end
			local filter = data.objectType[argv[1]]
			local count = tonumber(argv[2])
			if not count then
				count = 1
			elseif count <= 0 then
				return
			end
			---@param object tes3object|tes3light
			for object in tes3.iterateObjects(filter) do
				if (object.name ~= "") and not object.script then
					if filter == tes3.objectType.light then
						if object.canCarry then
							tes3.addItem({ reference = ref, item = object.id, count = count, playSound = false })
							return
						end
					else
						local function isGold(id)
							local goldList = {
								["gold_001"] = true,
								["gold_005"] = true,
								["gold_010"] = true,
								["gold_025"] = true,
								["gold_100"] = true,
								["gold_dae_cursed_001"] = true,
								["gold_dae_cursed_005"] = true,
							}
							return goldList[id]
						end
						if not isGold(object.id:lower()) then
							tes3.addItem({ reference = ref, item = object.id, count = count, playSound = false })
							return
						end
					end
				end
			end
		end,
	},
	["setownership"] = {
		description = "Set ownership of the current reference to none, or the specified NPC or faction with specified base ID.",
		arguments = {
			{ index = 1, metavar = "id", required = false, help = "the base id of the npc or faction to set ownership" },
		},
		---@param argv string[]?
		callback = function(argv)
			local ref = data.getCurrentRef()
			if not ref then
				return
			end
			local owner = argv and not table.empty(argv) and table.concat(argv, " ") or nil
			local faction = owner and tes3.getFaction(owner)
			local npc = owner and tes3.getObject(owner)
			if not (npc and npc.objectType == tes3.objectType.npc) then
				npc = nil
			end
			---@cast npc tes3npc
			if not owner then
				tes3.setOwner({ reference = ref, remove = true })
				tes3ui.log("Clear %s ownership", ref.id)
			elseif faction then
				tes3.setOwner({ reference = ref, owner = faction })
				tes3ui.log("%s is now Faction Owned by %s", ref.id, faction.name)
			elseif npc then
				tes3.setOwner({ reference = ref, owner = npc })
				tes3ui.log("%s is now Owned by %s", ref.id, npc.name)
			else
				tes3ui.log("usage: setownership id?")
				tes3ui.log("setownership: error: argument id: invalid input.")
			end
		end,
	},
	--- util
	["cls"] = {
		description = "Clear console.",
		callback = function(argv)
			if (not console) then
				return
			end
			console:findChild("MenuConsole_scroll_pane"):findChild("PartScrollPane_pane"):destroyChildren()
		end,
	},
	["qqq"] = {
		description = "Quit Morrowind.",
		callback = function(argv)
			os.exit()
		end,
	},
}

return data
