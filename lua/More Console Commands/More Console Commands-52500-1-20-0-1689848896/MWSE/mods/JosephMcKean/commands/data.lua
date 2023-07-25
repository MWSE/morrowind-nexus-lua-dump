local logger = require("logging.logger")

local config = require("JosephMcKean.commands.config")
local didYouMean = require("JosephmcKean.commands.didYouMean")

local log = logger.new({ name = "More Console Commands", logLevel = config.logLevel })

local console = tes3ui.registerID("MenuConsole")
local data = {}
local modName = "More Console Commands"

---@return tes3reference? ref
function data.getCurrentRef() return tes3ui.getConsoleReference() end

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
	["bushcrafting"] = { id = "Bushcrafting", mod = "Ashfall", luaMod = "mer.ashfall" },
	["climbing"] = { id = "climbing", mod = "Mantle of Ascension", luaMod = "mantle" },
	["cooking"] = { id = "mc_Cooking", mod = "Morrowind Crafting", luaMod = "Morrowind_Crafting_3" },
	["corpsepreparation"] = { id = "NC:CorpsePreparation", mod = "Necrocraft", luaMod = "necroCraft" },
	["crafting"] = { id = "mc_Crafting", mod = "Morrowind Crafting", luaMod = "Morrowind_Crafting_3" },
	["fishing"] = { id = "fishing", mod = "Ultimate Fishing", luaMod = "mer.fishing" },
	["fletching"] = { id = "fletching", mod = "Go Fletch", luaMod = "mer.goFletch" },
	["mcfletching"] = { id = "mc_Fletching", mod = "Morrowind Crafting", luaMod = "Morrowind_Crafting_3" },
	["inscription"] = { id = "Hermes:Inscription", mod = "Demon of Knowledge", luaMod = "MMM2018.sx2" },
	["masonry"] = { id = "mc_Masonry", mod = "Morrowind Crafting", luaMod = "Morrowind_Crafting_3" },
	["metalworking"] = { id = "mc_Metalworking", mod = "Morrowind Crafting", luaMod = "Morrowind_Crafting_3" },
	["mining"] = { id = "mc_Mining", mod = "Morrowind Crafting", luaMod = "Morrowind_Crafting_3" },
	["packrat"] = { id = "Packrat", mod = "Packrat Skill", luaMod = "gool.packrat" },
	["painting"] = { id = "painting", mod = "Joy of Painting", luaMod = "mer.joyOfPainting" },
	["performance"] = { id = "BardicInspiration:Performance", mod = "Bardic Inspiration", luaMod = "mer.bardicInspiration" },
	["sewing"] = { id = "mc_Sewing", mod = "Morrowind Crafting", luaMod = "Morrowind_Crafting_3" },
	["smithing"] = { id = "mc_Smithing", mod = "Morrowind Crafting", luaMod = "Morrowind_Crafting_3" },
	["staff"] = { id = "MSS:Staff", mod = "MWSE Staff Skill", luaMod = "inpv.Staff Skill" },
	["survival"] = { id = "Ashfall:Survival", mod = "Ashfall", luaMod = "mer.ashfall" },
	["woodworking"] = { id = "mc_Woodworking", mod = "Morrowind Crafting", luaMod = "Morrowind_Crafting_3" },
}

data.skillModuleSkillNames = {} ---@type string[]
for skillname, skillData in pairs(data.skillModuleSkills) do
	log:debug("if tes3.isLuaModActive(%s) %s", skillData.luaMod, tes3.isLuaModActive(skillData.luaMod))
	if tes3.isLuaModActive(skillData.luaMod) then table.insert(data.skillModuleSkillNames, skillname) end
end

local function listMarks()
	if not table.empty(config.marks) then
		tes3ui.log("\nHere is a list of marks that are available:")
		for id, mark in pairs(config.marks) do tes3ui.log("%s: %s", id, mark.name) end
	else
		tes3ui.log(
		"Type mark or recall to view all marks, type mark <id> to mark, type recall <id> to recall. \nExample: mark home, recall home.\n<id> needs to be one single word like this or likethis or like_this.")
	end
end

---@param name string
---@param value number
local function levelUp(name, value)
	local skillModule = include("OtherSkills.skillModule")
	if not skillModule then return end
	local skillData = data.skillModuleSkills[name:lower()]
	if not skillData then return end
	local skill = skillModule.getSkill(skillData.id)
	if not skill then return end
	for _ = 1, value do skill:progressSkill(100) end
end

---@class console.removeItems.params
---@field reference tes3reference
---@field goldOnly boolean?

---@param params console.removeItems.params
local function removeItems(params)
	if not params then return end
	local ref = params.reference
	if not ref then return end
	if not ref.object.inventory then
		tes3ui.log("error: %s does not have an inventory", ref.object.name or ref.id)
		return
	end
	if params.goldOnly then
		local count = tes3.getItemCount({ reference = ref, item = "gold_001" })
		if ref then -- tes3.player might be nil
			tes3.removeItem({ reference = ref, item = "gold_001", count = count })
		end
	else
		for _, stack in pairs(ref.object.inventory.items) do tes3.removeItem({ reference = ref, item = stack.object, count = stack.count, playSound = false }) end
		tes3ui.log("%s inventory has been emptied.", ref.id)
	end
end

---@param count number
local function giveGold(count)
	if count <= 0 then return end
	local ref = data.getCurrentRef() or tes3.player ---@type tes3reference
	if not ref then return end
	if not ref.object.inventory then
		tes3ui.log("error: %s does not have an inventory", ref.object.name or ref.id)
		return
	end
	tes3.addItem({ reference = ref, item = "gold_001", count = count, showMessage = true })
	tes3ui.log("%s gold added to %s inventory", count, ref.id)
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
	table.sort(skills, function(a, b) return a.value > b.value end)
	return skills
end

data.weather = { "clear", "cloudy", "foggy", "overcast", "rain", "thunder", "ash", "blight", "snow", "blizzard" }

local function calm()
	for _, cell in pairs(tes3.getActiveCells()) do
		for ref in cell:iterateReferences({ tes3.objectType.creature, tes3.objectType.npc }) do
			local mobile = ref.mobile ---@cast mobile tes3mobileCreature|tes3mobileNPC
			if mobile then
				mobile.fight = 0
				if mobile.inCombat then mobile:stopCombat(true) end
			end
		end
	end
end

---@return tes3cell
local function randomCell()
	local isBlacklistedRegion = { ["Abecean Sea Region"] = true }
	---@param cell tes3cell?
	local function isInvalidCell(cell)
		if not cell then return true end
		if not cell.activators.head and not cell.actors.head and not cell.statics.head then
			log:trace("randomCell: skip cell %s", cell.editorName)
			return true
		end
		if cell.isInterior then return false end
		if not cell.region or isBlacklistedRegion[cell.region.id] then
			log:trace("randomCell: skip cell %s", cell.editorName)
			return true
		end
		return false
	end
	local cell ---@type tes3cell
	while isInvalidCell(cell) do cell = table.choice(tes3.dataHandler.nonDynamicData.cells) end
	return cell
end

local isMarker = { ["TravelMarker"] = true, ["TempleMarker"] = true, ["DivineMarker"] = true, ["DoorMarker"] = true }
local cellIdAlias = {
	["mournhold"] = "mournhold, royal palace: courtyard",
	["mournhold, royal palace"] = "mournhold, royal palace: reception area",
	["mournhold temple"] = "mournhold temple: reception area",
	["solstheim"] = "fort frostmoth",
	["sotha sil"] = "sotha sil, outer flooded halls",
	["sotha sil,"] = "sotha sil, outer flooded halls",
}

--- This is a generic iterator function used
--- to loop over a tes3referenceList
---@param list tes3referenceList
---@return fun(): tes3reference
function data.iterReferenceList(list)
	local function iterator()
		local ref = list.head

		if list.size ~= 0 then coroutine.yield(ref) end

		while ref.nextNode do
			ref = ref.nextNode
			coroutine.yield(ref)
		end
	end
	return coroutine.wrap(iterator)
end

---@param name string
---@return number?
local function getObjectType(name) return tes3.objectType[name] end

data.canCarryObjectType = {
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

---@param object tes3object|tes3light
---@return boolean
local function canCarry(object)
	if table.find(data.canCarryObjectType, object.objectType) then
		if object.objectType == tes3.objectType.light then
			return true
		else
			return true
		end
	end
	return false
end

data.time = { ["midnight"] = "1:00", ["sunrise"] = "6:00", ["day"] = "8:00", ["noon"] = "13:00", ["sunset"] = "18:00", ["night"] = "20:00" }

---@param obj tes3object|tes3npc|tes3cell
---@return string type
local function getTypeOfObject(obj)
	local type
	type = obj.objectType and table.find(tes3.objectType, obj.objectType)
	type = obj.cellFlags and "cell" or type
	return type
end

local function killAll()
	for npcRef in tes3.player.cell:iterateReferences({ tes3.objectType.npc, tes3.objectType.creature }) do
		if not npcRef.object.isEssential then
			local mobileNPC = npcRef.mobile ---@cast mobileNPC tes3mobileNPC
			mobileNPC:kill()
		end
	end
end

---@class command.data.argument
---@field index integer
---@field containsSpaces boolean? If the parameter can contain spaces. Only available for the first parameter
---@field metavar string
---@field required boolean
---@field choices string[]?
---@field help string
---@field didYouMean boolean?

---@class command.data
---@field name string The name of the command
---@field description string The description of the command
---@field arguments command.data.argument[]?
---@field argPattern string?
---@field callback fun(argv:string[]) The callback function
---@field aliases string[]?
---@field caseSensitive boolean? If the arguments are case sensitive

---@class command : command.data
local command = {
	schema = {
		name = "Command",
		fields = {
			description = { type = "string", required = true },
			aliases = { type = "table", required = false },
			arguments = { type = "table", required = false },
			callback = { type = "function", required = true },
			caseSensitive = { type = "boolean", required = false },
		},
	},
}

---@type table<string, command>
data.commands = {
	-- Money cheats
	["kaching"] = { description = "Give current reference 1,000 gold", argPattern = "", callback = function() giveGold(1000) end },
	["motherlode"] = { description = "Give current reference 50,000 gold", argPattern = "", callback = function() giveGold(50000) end },
	["money"] = {
		description = "Set current reference gold amount to the input value. e.g. money 420",
		arguments = { { index = 1, metavar = "goldcount", required = true, help = "the amount of gold to add" } },
		callback = function(argv)
			local ref = data.getCurrentRef() or tes3.player ---@type tes3reference
			if not ref then return end
			if not ref.object.inventory then
				tes3ui.log("error: %s does not have an inventory", ref.object.name or ref.id)
				return
			end
			local count = tonumber(argv[1])
			if not count then return end
			removeItems({ reference = ref, goldOnly = true })
			giveGold(count)
		end,
	},
	-- stats cheats
	["cure"] = {
		description = "Cure current reference of disease, blight, poison, and restore attributes and skills",
		callback = function(argv)
			local ref = data.getCurrentRef() or tes3.player ---@type tes3reference
			if not ref.mobile then
				tes3ui.log("cure: error: invalid mobile")
				return
			end
			local cureCommon = tes3.getObject("Cure Common Disease Other") ---@cast cureCommon tes3spell
			local cureBlight = tes3.getObject("Cure Blight Disease") ---@cast cureBlight tes3spell
			local curePoison = tes3.getObject("Cure Poison Touch") ---@cast curePoison tes3spell
			local restoreAttribute = tes3.getObject("Almsivi Restoration") ---@cast restoreAttribute tes3spell
			local restoreSkillsFighter = tes3.getObject("Almsivi Restore Fighter") ---@cast restoreSkillsFighter tes3spell
			local restoreSkillsMage = tes3.getObject("Almsivi Restore Mage") ---@cast restoreSkillsMage tes3spell
			local restoreSkillsThief = tes3.getObject("Almsivi Restore Stealth") ---@cast restoreSkillsThief tes3spell
			local restoreSkillsOther = tes3.getObject("Almsivi Restore Other") ---@cast restoreSkillsOther tes3spell
			if ref.mobile.isDiseased then
				tes3.applyMagicSource({ reference = ref, source = cureCommon, castChance = 100, bypassResistances = true })
				tes3.applyMagicSource({ reference = ref, source = cureBlight, castChance = 100, bypassResistances = true })
			end
			if tes3.isAffectedBy({ reference = ref, effect = tes3.effect.poison }) then tes3.applyMagicSource({ reference = ref, source = curePoison, castChance = 100, bypassResistances = true }) end
			tes3.applyMagicSource({ reference = ref, source = restoreAttribute, castChance = 100, bypassResistances = true })
			-- Restore Skills
			tes3.applyMagicSource({ reference = ref, source = restoreSkillsFighter, castChance = 100, bypassResistances = true })
			tes3.applyMagicSource({ reference = ref, source = restoreSkillsMage, castChance = 100, bypassResistances = true })
			tes3.applyMagicSource({ reference = ref, source = restoreSkillsThief, castChance = 100, bypassResistances = true })
			tes3.applyMagicSource({ reference = ref, source = restoreSkillsOther, castChance = 100, bypassResistances = true })
		end,
	},
	["join"] = {
		description = "Join the specified faction and raise to the specified rank.",
		aliases = { "addtofaction" },
		arguments = {
			{ index = 1, metavar = "faction-id", required = true, help = "the id of the faction you wish to join" },
			{ index = 2, metavar = "rank", required = false, help = "the rank in the faction" },
		},
		callback = function(argv)
			local rank = tonumber(argv[#argv])
			if rank then table.remove(argv, #argv) end
			local factionId = argv and not table.empty(argv) and table.concat(argv, " ") or nil
			local faction = factionId and tes3.getFaction(factionId)
			if not faction then
				tes3ui.log("join: error: factionId %s not found", factionId)
				if didYouMean[factionId] then tes3ui.log("Did you mean: %s", didYouMean[factionId]) end
				return
			end
			faction.playerJoined = true
			faction.playerRank = rank or 0
		end,
	},
	["levelup"] = {
		description = "Increase the player's skill by the input value. e.g. levelup bushcrafting 69, levelup survival 420",
		arguments = {
			{ index = 1, metavar = "skillname", required = true, choices = data.skillModuleSkillNames, help = "the name of the skill to level up" },
			{ index = 2, metavar = "value", required = true, help = "the increase value" },
		},
		callback = function(argv) levelUp(argv[1], tonumber(argv[2]) or 0) end,
	},
	["max"] = {
		description = "Set the current reference's all attributes and skills base value to the input value",
		arguments = { { index = 1, metavar = "value", required = false, help = "the value to set" } },
		callback = function(argv)
			local ref = data.getCurrentRef() or tes3.player
			if not ref then return end
			local value = tonumber(argv[1]) or 200
			for _, name in ipairs(data.setNames) do tes3.setStatistic({ reference = tes3.player, name = getName(name), value = value }) end
		end,
	},
	["set"] = {
		description = "Set the current reference's attribute or skill base value",
		arguments = {
			{ index = 1, metavar = "name", required = true, choices = data.setNames, help = "the name of the attribute or skill to set", didYouMean = true },
			{ index = 2, metavar = "value", required = true, help = "the value to set" },
		},
		callback = function(argv)
			local ref = data.getCurrentRef() or tes3.player
			if not ref then return end
			if not ref.mobile then
				tes3ui.log("set: error: currentRef has no mobile.")
				return
			end
			local name = getName(argv[1])
			log:trace("set: name = %s", name)
			tes3.setStatistic({ reference = ref, name = name, value = tonumber(argv[2]) })
			tes3ui.log("Set %s on %s", name, ref.id)
		end,
	},
	["skills"] = {
		description = "Print the current reference's skills",
		callback = function(argv)
			local ref = data.getCurrentRef()
			if not ref then
				tes3ui.log("skills: error: currentRef not found")
				return
			end
			local npc = ref.mobile
			if not npc then return end
			---@cast npc tes3mobileNPC
			tes3ui.log("%s skills:", npc.reference.object.name)
			for _, skill in ipairs(data.getSkillsDesc(npc)) do tes3ui.log("%s %s", tes3.skillName[skill.index - 1], skill.value) end
		end,
	},
	["speedy"] = {
		description = "Increase the player's speed to 200, athletics to 200",
		callback = function(argv)
			tes3.setStatistic({ reference = tes3.player, attribute = tes3.attribute.speed, value = 200 })
			tes3.setStatistic({ reference = tes3.player, skill = tes3.skill.athletics, value = 200 })
		end,
	},
	-- teleportation and movements
	["coc"] = {
		description = "Teleport the player to a cell with specified id or specified grid x and grid y",
		arguments = { { index = 1, metavar = "id", required = false, help = "the id of the cell to teleport to" } },
		callback = function(argv)
			if not tes3.player then
				tes3ui.log("Please load a save first.")
				return
			end
			local cell2coc ---@type tes3cell
			local cellId = argv and not table.empty(argv) and table.concat(argv, " ") or nil
			log:debug("coc %s", cellId)
			if not cellId then
				tes3ui.log("cellId not found")
				return
			elseif cellIdAlias[cellId] then
				cellId = cellIdAlias[cellId]
			elseif cellId == "random" then
				cell2coc = randomCell()
			end

			local grid = false
			local gridX = tonumber(argv[1])
			local gridY = tonumber(argv[2])
			if gridX and gridY and not argv[3] then
				cell2coc = tes3.getCell({ x = gridX, y = gridY })
				if not cell2coc then
					tes3ui.log("cell %s %s not found", gridX, gridY)
					return
				end
				cellId = cell2coc.id
				grid = true
			end

			local position = tes3vector3.new()
			local orientation = tes3vector3.new()

			local markers = {} ---@type table<tes3cell,table<string,tes3reference>>
			if grid then
				markers[cell2coc] = {}
			elseif cellId == "random" then
				markers[cell2coc] = {}
			else
				for _, cell in ipairs(tes3.dataHandler.nonDynamicData.cells) do
					if cell.id:lower() == cellId:lower() then
						markers[cell] = {}
						cell2coc = cell2coc or cell
					end
				end
			end
			if table.empty(markers) then
				tes3ui.log("cellId %s not found", cellId)
				return
			end
			if not cell2coc.isInterior then
				local gridSize = 8192
				position = tes3vector3.new(gridSize / 2 + cell2coc.gridX * gridSize, gridSize / 2 + cell2coc.gridY * gridSize, 994)
			end
			tes3.positionCell({ cell = cell2coc, position = position, orientation = orientation })

			timer.delayOneFrame(function()
				local intervention = false
				for cell, mks in pairs(markers) do
					-- TravelMarker, TempleMarker, DivineMarker, and DoorMarker are activators in game but static in TESCS
					local activators = cell.activators
					if activators.head then
						for activator in data.iterReferenceList(activators) do
							if isMarker[activator.id] and not markers[cell][activator.id] then
								markers[cell][activator.id] = activator
								log:debug("Found %s at %s (%s, %s), %s", activator.id, cell.editorName, position.x, position.y, activator.sourceMod)
							end
						end
						cell2coc = cell
						if mks["TravelMarker"] then
							position = mks["TravelMarker"].position
							orientation = mks["TravelMarker"].orientation
							log:debug("Found TravelMarker at %s (%s, %s)", cell.editorName, position.x, position.y)
							break
						end
						if not intervention and mks["DoorMarker"] then
							position = mks["DoorMarker"].position
							orientation = mks["DoorMarker"].orientation
							log:debug("Found DoorMarker at %s (%s, %s)", cell.editorName, position.x, position.y)
						end
						if mks["DivineMarker"] then
							position = mks["DivineMarker"].position
							orientation = mks["DivineMarker"].orientation
							intervention = true
							log:debug("Found DivineMarker at %s (%s, %s)", cell.editorName, position.x, position.y)
						end
						if mks["TempleMarker"] then
							position = mks["TempleMarker"].position
							orientation = mks["TempleMarker"].orientation
							intervention = true
							log:debug("Found TempleMarker at %s (%s, %s)", cell.editorName, position.x, position.y)
						end
					end
				end
				log:debug("Teleporting to %s (%s, %s)", cell2coc.editorName, position.x, position.y)
				tes3.positionCell({ cell = cell2coc, position = position, orientation = orientation })
			end, timer.real)
		end,
	},
	["fly"] = {
		description = "Toggle levitate",
		callback = function(argv)
			tes3.mobilePlayer.isFlying = not tes3.mobilePlayer.isFlying
			tes3ui.log("Levitate -> %s", tes3.mobilePlayer.isFlying and "On" or "Off")
		end,
	},
	["mark"] = {
		description = "Mark the player's current cell and position for recall. Type mark to view all marks, type mark <id> to mark. e.g. mark home",
		arguments = { { index = 1, metavar = "id", required = false, help = "the id of the mark" } },
		callback = function(argv)
			if not argv[1] then
				listMarks()
			else
				local cell = nil
				if tes3.player.cell.isInterior then cell = tes3.player.cell.id end
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
				log:info("marks[%s].cell = {\nname = %s,\ncell = %s,\nposition = { %s, %s, %s },\norientation = { %s, %s, %s }\n}", argv[1], tes3.player.cell.editorName, cell, position.x, position.y,
				         position.z, orientation.x, orientation.y, orientation.z)
			end
		end,
	},
	["position"] = {
		description = "Teleport the player to a npc with specified id",
		alias = { "moveto" },
		arguments = { { index = 1, metavar = "id", required = true, help = "the id of the npc to teleport to" } },
		callback = function(argv)
			local refId = argv and not table.empty(argv) and table.concat(argv, " ") or nil
			if refId then
				local ref = tes3.getReference(refId)
				if ref and ref.baseObject.objectType == tes3.objectType.npc then
					tes3.positionCell({
						cell = ref.cell,
						position = { ref.position.x - 64, ref.position.y + 64, ref.position.z },
						orientation = { ref.orientation.x, ref.orientation.y, ref.orientation.z + math.pi },
					})
				end
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
						tes3.positionCell({ position = { mark.position.x, mark.position.y, mark.position.z }, orientation = { mark.orientation.x, mark.orientation.y }, forceCellChange = true })
					end
				end
			end
		end,
	},
	-- NPC command
	["emptyinventory"] = {
		description = "Empty the current reference's inventory",
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
		description = "Make the current reference your follower",
		callback = function(argv)
			local ref = data.getCurrentRef()
			if not ref then return end
			tes3.setAIFollow({ reference = ref, target = tes3.player })
			-- ref.modified = true
		end,
	},
	["kill"] = {
		description = "Kill the current reference. For safety reason, type kill player to kill the player",
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
			elseif argv[1] == "all" then
				killAll()
			end
		end,
	},
	["killall"] = { description = "Kills all non-essential NPCs and creatures within the cell the player is currently in", callback = function(argv) killAll() end },
	["peace"] = {
		description = "Pacify all enemies. Irreversible",
		callback = function(argv)
			calm()
			if not event.isRegistered("cellChanged", calm) then event.register("cellChanged", calm) end
		end,
	},
	["resurrect"] = {
		description = "Resurrect the current reference and keep the inventory",
		callback = function(argv)
			local ref = data.getCurrentRef()
			if ref and ref.mobile then
				local actor = ref.mobile ---@cast actor tes3mobileNPC|tes3mobileCreature|tes3mobilePlayer
				actor:resurrect({ resetState = false })
			end
		end,
	},
	["showinventory"] = {
		description = "Show the current reference's inventory",
		callback = function(argv)
			local ref = data.getCurrentRef()
			if not ref then return end
			tes3ui.leaveMenuMode()
			tes3ui.findMenu(console).visible = false
			timer.delayOneFrame(function() tes3.showContentsMenu({ reference = ref }) end)
		end,
	},
	["spawn"] = {
		description = "Spawn a reference with the specified id",
		aliases = { "summon" },
		arguments = { { index = 1, metavar = "id", required = true, help = "the id of the reference to spawn" } },
		callback = function(argv)
			local id = argv and not table.empty(argv) and table.concat(argv, " ") or nil
			if not id then return end
			local obj = tes3.getObject(id)
			if not obj then
				tes3ui.log("spawn: error: %s is not a valid object id", id)
				return
			end
			tes3.createReference({ object = id, position = tes3.player.position, orientation = tes3.player.orientation, cell = tes3.player.cell })
		end,
	},
	["wander"] = {
		description = "Make the current reference wander",
		callback = function(argv)
			local ref = data.getCurrentRef()
			if not ref then return end
			tes3.setAIWander({ reference = ref, range = 512, idles = { 60, 20, 20, 0, 0, 0, 0, 0 } })
			-- ref.modified = true
		end,
	},
	-- item commands
	["additem"] = {
		description = "Add item(s) to the current reference's inventory",
		arguments = { { index = 1, metavar = "id", required = true, help = "the id of the item to add" }, { index = 2, metavar = "count", required = false, help = "the add item count" } },
		callback = function(argv)
			local ref = data.getCurrentRef() or tes3.player
			if not ref then return end
			if not ref.object.inventory then
				tes3ui.log("error: %s does not have an inventory", ref.object.name or ref.id)
				return
			end
			local count = tonumber(argv[#argv])
			if count then table.remove(argv, #argv) end
			local itemId = argv and not table.empty(argv) and table.concat(argv, " ") or nil
			if not itemId then return end
			if didYouMean[itemId] then itemId = didYouMean[itemId] end -- this is a quick and temporary solution, i plan to support crafting framework material
			local item = tes3.getObject(itemId) ---@cast item tes3object|any
			if not item then
				tes3ui.log("additem: error: itemId %s not found", itemId)
				return
			end
			if not canCarry(item) then
				tes3ui.log("error: %s is not carryable", item.id)
				return
			end
			tes3.addItem({ reference = ref, item = itemId, count = count, playSound = false })
			tes3ui.log("additem %s%s to %s", count and count .. " " or "", itemId, ref.id)
		end,
	},
	["dupe"] = {
		description = "Duplicate the item that is the current reference to the player's inventory",
		arguments = { { index = 1, metavar = "count", required = false, help = "the count of the item to duplicate" } },
		callback = function(argv)
			local ref = data.getCurrentRef()
			if not ref then return end
			local item = ref.baseObject
			if not canCarry(item) then
				tes3ui.log("error: %s is not carryable", item.name or ref.id)
				return
			end
			local count = tonumber(argv[1])
			tes3.addItem({ reference = tes3.player, item = item.id, count = count or 1, playSound = false })
			tes3ui.log("additem %s%s to player", count and count .. " " or "", item.id)
		end,
	},
	["setownership"] = {
		description = "Set ownership of the current reference to none, or the specified NPC or faction with specified base ID",
		arguments = { { index = 1, containsSpaces = true, metavar = "id", required = false, help = "the base id of the npc or faction to set ownership" } },
		callback = function(argv)
			local ref = data.getCurrentRef()
			if not ref then return end
			local owner = argv[1] ~= "" and argv[1] or nil
			local faction = owner and tes3.getFaction(owner)
			local npc = owner and tes3.getObject(owner)
			if not (npc and npc.objectType == tes3.objectType.npc) then npc = nil end
			---@cast npc tes3npc?
			if not owner then
				tes3.setOwner({ reference = ref, remove = true })
				tes3ui.log("Clear %s ownership", ref.id)
				ref.modified = true
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
	["unlock"] = {
		description = "Unlock lock",
		callback = function(argv)
			local ref = data.getCurrentRef()
			if not ref then return end
			tes3.unlock({ reference = ref })
		end,
	},
	["untrap"] = {
		description = "Untrap trap",
		callback = function(argv)
			local ref = data.getCurrentRef()
			if not ref or not ref.lockNode or not ref.lockNode.trap then return end
			ref.lockNode.trap = nil
		end,
	},
	--- world cheats
	["time"] = {
		description = "Set current ingame time",
		arguments = { { index = 1, metavar = "time", required = true, help = "the time to set, e.g. 18:23 or day/night/noon/midnight/sunrise/sunset" } },
		callback = function(argv)
			local time = data.time[argv[1]] or argv[1]
			local hourStr, minuteStr = table.unpack(time:split(":"))
			local hour, minute = tonumber(hourStr), tonumber(minuteStr)
			if hour and minute then
				local minuteMod = minute % 60
				hour = hour + (minute - minuteMod) / 60
				local hourMod = hour % 24
				tes3.setGlobal("GameHour", hourMod + minuteMod / 60)
			end
		end,
	},
	["weather"] = {
		description = "Set current weather",
		aliases = { "forceweather", "fw" },
		arguments = { { index = 1, metavar = "weather", required = true, choices = data.weather, help = "the name of the weather" } },
		callback = function(argv)
			local weatherController = tes3.worldController.weatherController
			local weather = tes3.weather[argv[1]] ---@type number?
			if weather then
				weatherController:switchImmediate(weather)
				weatherController:updateVisuals()
			end
		end,
	},
	--- util
	["cls"] = {
		description = "Clear console",
		callback = function(argv)
			if (not console) then return end
			tes3ui.findMenu(console):findChild("MenuConsole_scroll_pane"):findChild("PartScrollPane_pane"):destroyChildren()
		end,
	},
	["lookup"] = {
		description = "Look up objects by id or name",
		arguments = {
			{ index = 1, metavar = "name", required = true, help = "the id or name of the object to look up" },
			{ index = 1, metavar = "objecttype", required = false, help = "the type of the object to look up" },
		},
		callback = function(argv)
			local isCellType = argv[#argv] == "cell"
			local objectType = getObjectType(argv[#argv])
			if isCellType or objectType then
				log:trace("%s is objectType", argv[#argv])
				table.remove(argv, #argv)
			end
			local name = argv and not table.empty(argv) and table.concat(argv, " ") or nil
			if not isCellType and not objectType and not name then return end
			local lookUpObjs = {}
			if objectType then
				for object in tes3.iterateObjects(objectType) do
					local obj = object ---@cast obj tes3object|tes3npc
					local objId = obj.id and obj.id:lower()
					local objName = obj.name and obj.name:lower()
					if not name or (objId:find(name) or (objName and objName:find(name))) then table.insert(lookUpObjs, obj) end
				end
			end
			if isCellType then
				local nonDynamicData = tes3.dataHandler.nonDynamicData
				for _, cell in ipairs(nonDynamicData.cells) do if not name or (cell.id:lower():find(name)) then table.insert(lookUpObjs, cell) end end
			end
			if table.empty(lookUpObjs) then
				tes3ui.log("No matching information")
			else
				tes3ui.log("%s matching information:", #lookUpObjs)
				---@param obj tes3object|tes3npc|tes3cell
				for _, obj in ipairs(lookUpObjs) do
					local objType = getTypeOfObject(obj)
					local info = string.format("- %s, %s", objType, obj.id)
					if objType == "cell" then
						info = string.format("%s, %s", info, obj.editorName)
					elseif obj.name then
						info = string.format("%s, %s", info, obj.name)
					end
					local ref = tes3.getReference(obj.id)
					if ref and ref.cell then info = string.format("%s, %s", info, ref.cell.editorName) end
					if obj.sourceMod then info = string.format("%s, %s", info, obj.sourceMod) end
					tes3ui.log(info)
				end
			end
		end,
	},
	["qqq"] = { aliases = { "quitgame" }, description = "Quit Morrowind", callback = function(argv) os.exit() end },
}

---@param cmd command.data
function data.new(cmd)

	local name = cmd.name
	name = name:lower() -- Make sure the command is lower case
	if data.commands[name] then
		log:error("Attempt to create existing command `%s`. Use `modify()` instead.", name)
		return
	end

	local commandData = {}
	local fields = command.schema.fields
	for field, fieldData in pairs(fields) do
		if fieldData.type == "table" then
			commandData[field] = table.deepcopy(cmd[field])
		else
			commandData[field] = cmd[field]
		end
	end

	data.commands[name] = commandData
end

data.aliases = {}

return data
