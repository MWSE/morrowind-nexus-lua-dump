local config = require("Command Menu.config")

local i18n = mwse.loadTranslations("Command Menu")
local log = mwse.Logger.new()
local util = {}

--- @param faction tes3faction
function util.getFactionLabel(faction)
	if not faction.playerJoined then
		return i18n("Status: not a member.")
	end
	if faction.playerExpelled then
		return i18n("Status: expelled.")
	end
	return string.format(i18n("Status: member, rank") .. ": %s.",
		faction:getRankName(faction.playerRank)
	)
end

--- https://stackoverflow.com/questions/2421695/first-character-uppercase-lua
--- @param str string
function util.capitalize(str)
	return (str:gsub("^%l", string.upper))
end

--- This can be replaced with fuzzy or wildcard matching.
--- @param str string
--- @param substr string
function util.ciContains(str, substr)
	return (str:lower():find(substr, 1, true)) and true or false
end

-- For "<Deprecated>", "<Template>", "< DEPRECATED >" etc.
--- @param str string
function util.isDeprecated(str)
	return string.sub(str, 1, 1) == "<"
end

--- @param object tes3creature|tes3item|tes3faction|tes3npc
function util.getNiceName(object)
	if util.isDeprecated(object.name) then
		return string.format("%s (%s)", object.name, object.id)
	end
	return object.name
end

--- Returns the first creature that can fit in given soul gem.
--- @param creatures tes3creature[]
--- @param startingGem tes3misc
function util.getStartingCreature(creatures, startingGem)
	local maxSoulSize = startingGem.soulGemCapacity
	-- Make sure starting creature can fit into starting gem.
	for _, creature in ipairs(creatures) do
		if creature.soul <= maxSoulSize then
			return creature
		end
	end
end

local offset = tes3vector3.new(0, 128, 0)

function util.getPointInFrontOfPlayer()
	local pos = tes3.player.position:copy()
	local rot = tes3matrix33.new()
	rot:toRotationZ(tes3.mobilePlayer.facing)
	pos = pos + rot * offset
	return pos
end

--- @param cell tes3cell
--- @return tes3vector3
function util.getTeleportPosition(cell)
	local doorMarker = tes3.getObject("DoorMarker")
	for reference in cell:iterateReferences(tes3.objectType.static) do
		if reference.object == doorMarker then
			return reference.position
		end
	end

	-- Fallback, use first available persistent ref, if there is one.
	local firstRef = cell.activators[1]
	if firstRef then
		return firstRef.position
	end

	-- We rely on engine to trace the Z coordinate to the ground.
	return tes3vector3.new(cell.gridX * 8192 + 4096, cell.gridY * 8192 + 4096, -1000)
end


local itemTypes = {
	[tes3.objectType.alchemy] = true,
	[tes3.objectType.ammunition] = true,
	[tes3.objectType.apparatus] = true,
	[tes3.objectType.armor] = true,
	[tes3.objectType.book] = true,
	[tes3.objectType.clothing] = true,
	[tes3.objectType.ingredient] = true,
	[tes3.objectType.lockpick] = true,
	[tes3.objectType.miscItem] = true,
	[tes3.objectType.probe] = true,
	[tes3.objectType.repairItem] = true,
	[tes3.objectType.weapon] = true,
}

--- @param item tes3object|tes3light
local function carryableLight(item)
	return item.objectType == tes3.objectType.light and item.canCarry
end

--- @param object tes3object
local function validItem(object)
	if itemTypes[object.objectType]
	or carryableLight(object) then
		return true
	end

	return false
end

--- @param object tes3object|tes3armor|tes3misc|tes3cell|tes3faction
local function filterDeprecated(object)
	if not config.filterOutDeprecated then
		return false
	end

	if object.name and util.isDeprecated(object.name) then
		return true
	end

	return false
end

--- @param object tes3object|tes3npc
local function validNpc(object)
	-- Filter out cloned actors so we don't have duplicates.
	if object.objectType == tes3.objectType.npc and not object.isInstance then
		-- Make sure we only list NPC eligible for teleporting that are placed in the in-game world.
		if tes3.getReference(object.id) then
			return true
		end
	end
	return false
end

--- @param a tes3armor|tes3misc|tes3spell|tes3cell
--- @param b tes3armor|tes3misc|tes3spell|tes3cell
--- @return boolean
local function nameSorter(a, b)
	local aName = a.name or a.editorName
	local bName = b.name or b.editorName
	if aName == "<Deprecated>" then
		aName = a.id
	end
	if bName == "<Deprecated>" then
		bName = b.id
	end
	return aName < bName
end

function util.getObjects()
	--- @class CommandMenu.objectsTable
	local objects = {
		--- @type tes3creature[]
		creatures = {},
		--- @type tes3misc[]
		soulGems = {},
		--- @type tes3npc[]
		npcs = {},
		--- @type tes3misc[]|tes3armor[]
		items = {},
		--- @type tes3cell[]
		cells = {},
		--- @type tes3spell[]
		spells = {},
		--- @type tes3faction[]
		factions = {}
	}

	-- Shorthands
	local creatures = objects.creatures
	local soulGems = objects.soulGems
	local npcs = objects.npcs
	local items = objects.items
	for _, object in ipairs(tes3.dataHandler.nonDynamicData.objects) do
		if not filterDeprecated(object) then
			if object.objectType == tes3.objectType.creature then
				table.insert(creatures, object)
			end
			if object.objectType == tes3.objectType.miscItem and object.isSoulGem then
				table.insert(soulGems, object)
			end
			if validNpc(object) then
				table.insert(npcs, object)
			end
			if validItem(object) then
				table.insert(items, object)
			end
		end
	end
	table.sort(creatures, nameSorter)
	table.sort(soulGems, nameSorter)
	table.sort(npcs, nameSorter)
	table.sort(items, nameSorter)

	local cells = objects.cells
	for _, cell in ipairs(tes3.dataHandler.nonDynamicData.cells) do
		table.insert(cells, cell)
	end
	table.sort(cells, nameSorter)

	local spells = objects.spells
	for _, spell in ipairs(tes3.dataHandler.nonDynamicData.spells) do
		table.insert(spells, spell)
	end
	table.sort(spells, nameSorter)

	local factions = objects.factions
	for _, faction in ipairs (tes3.dataHandler.nonDynamicData.factions) do
		if not filterDeprecated(faction) then
			table.insert(factions, faction)
		end
	end
	table.sort(factions, nameSorter)

	return objects
end

return util
