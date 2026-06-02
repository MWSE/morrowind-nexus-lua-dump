-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/data_global.lua
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
   "mw_children_1_0.esm",
   "oaab_data.esm",
   "sky_main.esm",
   "taddeus_foods_of_tamriel.esp",
   "tamriel_data.esm",
   "morrowind rebirth [main].esp",
   "expanded loot.esm",
}

local consumables = {}
local containers = {
   emptyToFilled = {},
   filledToEmpty = {},
}

-- -----------------------------------------------------------------------------
-- Helper functions
-- -----------------------------------------------------------------------------

-- CORRECCIÓN: Comparación insensible a mayúsculas para asegurar que encuentre los ítems
local function checkItem(id, itemTypes)
   local searchId = id:lower()
   for _, itemType in ipairs(itemTypes) do
      for _, record in ipairs(types[itemType].records) do
         if (record.id:lower() == searchId) then return true end
      end
   end
   return false
end

local function processConsumables(data, filename)
   for id, values in pairs(data.consumables) do
      if (checkItem(id, { "Ingredient", "Potion" })) then
         consumables[id] = values
      else
         print("BasicNeeds: Record for consumable '" .. id .. "' in patch '" .. filename .. "' doesn't exist.")
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
            value = misc.value,
            weight = misc.weight + 1,
         })
         local record = world.createRecord(draft)
         containers.emptyToFilled[id] = record.id
         containers.filledToEmpty[record.id] = id
         -- print("BasicNeeds: Registro dinámico creado: " .. record.id)
      else
         print("BasicNeeds: Error - No se encontró el objeto base para contenedor: " .. id)
      end
   end
end

-- -----------------------------------------------------------------------------
-- Initialization Logic
-- -----------------------------------------------------------------------------
local function recreateRecords()
    for emptyId, filledId in pairs(containers.emptyToFilled) do
        local alreadyExists = false
        for _, record in ipairs(types.Potion.records) do
            if record.id:lower() == filledId:lower() then
                alreadyExists = true
                break
            end
        end
        if not alreadyExists then
            local misc = types.Miscellaneous.record(emptyId)
            local draft = types.Potion.createRecordDraft({
                effects = {},
                icon = misc.icon,
                id = filledId,
                model = misc.model,
                name = misc.name .. " (Water)",
                value = misc.value,
                weight = misc.weight + 1,
            })
            world.createRecord(draft)
        end
    end
end

local function loadAllPatches()
   -- Evita duplicados si ya hay datos
   if next(consumables) ~= nil or next(containers.emptyToFilled) ~= nil then return end 

   for _, pkg in ipairs(AVAILABLE_PATCHES) do
      if (core.contentFiles.has(pkg)) then
         local filename = pkg:gsub("%..+", "")
         -- Usamos pcall para evitar que el mod truene si falta un archivo de parche
         local success, data = pcall(require, PATCHES_PATH .. filename)
         if success then
            processConsumables(data, filename)
            processContainers(data, filename)
         else
            print("BasicNeeds: No se pudo cargar el archivo de parche para '" .. filename .. "'.")
         end
      end
   end
end

local function onNewGame()
   loadAllPatches()
end

local function onSave()
   return {
      consumables = consumables,
      emptyToFilled = containers.emptyToFilled,
      filledToEmpty = containers.filledToEmpty,
   }
end

local initialized = false

local function onLoad(data)
    if data and data.consumables and next(data.consumables) then
        consumables = data.consumables
        containers = {
            emptyToFilled = data.emptyToFilled,
            filledToEmpty = data.filledToEmpty,
        }
    end
    initialized = false  -- siempre recrear registros en onUpdate
end

-- -----------------------------------------------------------------------------
-- Interface & Handlers
-- -----------------------------------------------------------------------------
local function onUpdate(dt)
    if not initialized then
        initialized = true
        if next(containers.emptyToFilled) ~= nil then
            recreateRecords()
        else
            loadAllPatches()
        end
    end
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
      onUpdate = onUpdate,  -- ← nuevo
   },
}