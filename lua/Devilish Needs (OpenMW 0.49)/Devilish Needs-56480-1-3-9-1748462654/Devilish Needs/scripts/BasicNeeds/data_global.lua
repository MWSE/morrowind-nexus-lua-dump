-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/data_global.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
--
-- Loads items from the 'patches' folder and merges them with consumable tables,
-- depending on what content files the user currently has loaded.
-- -----------------------------------------------------------------------------
local core = require("openmw.core")
local types = require("openmw.types")
local world = require("openmw.world")
local vfs = require('openmw.vfs')

--local PATCHES_PATH = "scripts.BasicNeeds.patches."

-- When creating a patch, add the corresponding .esm/.esp/.omwaddon file here
--local AVAILABLE_PATCHES = {
--   "morrowind.esm",
--   "tribunal.esm",
--   "bloodmoon.esm",
--   "tamriel_data.esm",
--   "oaab_data.esm",
--   "Devilish Needs.esp",
--"Expanded Loot.esm"
--}

local consumables = {}
local containers = {
   emptyToFilled = {},
   filledToEmpty = {},
}
local toxicSubstances = {}

-- -----------------------------------------------------------------------------
-- Helper functions
-- -----------------------------------------------------------------------------
local function checkItem(id, itemTypes)
   for _, itemType in ipairs(itemTypes) do
      for _, misc in ipairs(types[itemType].records) do
         if (misc.id == id) then return true end
      end
   end
   return false
end

local function processConsumables(data, filename)
	if (data.consumables) then
		for id, values in pairs(data.consumables) do
			if (checkItem(id, { "Ingredient", "Potion" })) then
				consumables[id] = values
			else
				print("Record for consumable '" .. id .. "' in patch '" .. filename .. "' doesn't exist in content files")
			end
		end
	end
end

local function processContainers(data, filename)
	if (data.containers) then
		for _, id in ipairs(data.containers) do
			if (checkItem(id, { "Miscellaneous" })) then
				local misc = types.Miscellaneous.record(id)
				local draft = types.Potion.createRecordDraft({
					effects = {},
					icon = misc.icon,
					id = misc.id .. "_filled",
					model = misc.model,
					name = misc.name .. " (Water)",
					value = misc.value + 10,
					weight = misc.weight + 1,
				})
				local record = world.createRecord(draft)
				containers.emptyToFilled[id] = record.id
				containers.filledToEmpty[record.id] = id
			else
				print("Record for container '" .. id .. "' in patch '" .. filename .. "' doesn't exist in content files")
			end
		end
   end
end

local function processToxicSubstances(data, filename)
	-- toxicSubstance section kept seperate & optional
	if (data.toxicsubstances) then
		for id, values in pairs(data.toxicsubstances) do
			if (checkItem(id, { "Ingredient", "Potion" })) then
				toxicSubstances[id] = values
			else
				print("Record for toxicSubstance '" .. id .. "' in patch '" .. filename .. "' doesn't exist in content files")
			end
		end
	end
end

-- -----------------------------------------------------------------------------
-- Initialization
-- -----------------------------------------------------------------------------
local function onNewGame()
   if(vfs == false) then
		print("VFS not found")
		return
   end
   for pkg in vfs.pathsWithPrefix("scripts\\BasicNeeds\\patches") do
		print("Applying patch for '" .. pkg .. "'.")
		local filepath = pkg:gsub("%.lua", "")
		local filepath = filepath:gsub("%/", ".")
        local data = require(filepath)
        processConsumables(data, filepath)
        processContainers(data, filepath)
   	    processToxicSubstances(data, filepath)
   end
end

local function onSave()
	return {
      consumables = consumables,
	  toxicSubstances = toxicSubstances,
      emptyToFilled = containers.emptyToFilled,
      filledToEmpty = containers.filledToEmpty,
   }
end

local function onLoad(data)
   consumables = data.consumables
   toxicSubstances = data.toxicSubstances
   containers = {
      emptyToFilled = data.emptyToFilled,
      filledToEmpty = data.filledToEmpty,
   }
end

return {
   interfaceName = "BasicNeedsData",
   interface = {
      version = 1,
      getConsumableValues = function(id)
         return consumables[id]
      end,
	  getToxicSubstancesValues = function(id)
         return toxicSubstances[id]
      end,
      getFilledVariantId = function(id)
         return containers.emptyToFilled[id]
      end,
      getEmptyVariantId = function(id)
         return containers.filledToEmpty[id]
      end,
   },
   engineHandlers = {
      onNewGame = onNewGame,
      onSave = onSave,
      onLoad = onLoad,
   },
}
