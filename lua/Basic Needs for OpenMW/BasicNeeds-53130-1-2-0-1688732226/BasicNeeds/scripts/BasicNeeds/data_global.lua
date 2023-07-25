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

local PATCHES_PATH = "scripts.BasicNeeds.patches."

-- When creating a patch, add the corresponding .esm/.esp/.omwaddon file here
local AVAILABLE_PATCHES = {
   "morrowind.esm",
   "tribunal.esm",
   "bloodmoon.esm",
   "tamriel_data.esm",
   "oaab_data.esm",
}

local consumables = {}
local containers = {
   emptyToFilled = {},
   filledToEmpty = {},
}

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
   for id, values in pairs(data.consumables) do
      if (checkItem(id, { "Ingredient", "Potion" })) then
         consumables[id] = values
      else
         print("Record for consumable '" .. id .. "' in patch '" .. filename .. "' doesn't exist in content files")
      end
   end
end

local function processContainers(data, filename)
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

-- -----------------------------------------------------------------------------
-- Initialization
-- -----------------------------------------------------------------------------
local function onNewGame()
   for _, pkg in ipairs(AVAILABLE_PATCHES) do
      if (core.contentFiles.has(pkg)) then
         print("Applying patch for '" .. pkg .. "'.")
         local filename = pkg:gsub("%..+", "")
         local data = require(PATCHES_PATH .. filename)
         processConsumables(data, filename)
         processContainers(data, filename)
      end
   end
end

local function onSave()
	return {
      consumables = consumables,
      emptyToFilled = containers.emptyToFilled,
      filledToEmpty = containers.filledToEmpty,
   }
end

local function onLoad(data)
   consumables = data.consumables
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
