-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/global.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com> (original author)
-- 2025 -- Modified by DetailDevil for Devilish Needs 
--
-- Because access to data and item creation happens in the GLOBAL scope, we need
-- to pass events back and forth, otherwise we'd end up loading and transforming
-- data multiple times. 
-- -----------------------------------------------------------------------------
local types = require("openmw.types")
local world = require("openmw.world")
local time  = require("openmw_aux.time")
local inventory = types.Actor.inventory


local Data = require("openmw.interfaces").BasicNeedsData

local function getNextFillable(inventory)
   local miscItems = inventory:getAll(types.Miscellaneous)
   for _, item in ipairs(miscItems) do
      if (Data.getFilledVariantId(item.recordId)) then
         return item
      end
   end
   return nil
end

local function playerFillContainer(eventData)
   local playerInventory = types.Actor.inventory(eventData.player)
   local container = getNextFillable(playerInventory)
   if (not container) then
      eventData.player:sendEvent("PlayerFilledContainer", {})
      return
   end

   local filled = Data.getFilledVariantId(container.recordId)
   if (filled) then
      container:remove(1)
      world.createObject(filled, 1):moveInto(playerInventory)
      local containerName = types.Miscellaneous.record(container.recordId).name
      eventData.player:sendEvent("PlayerFilledContainer", {
         containerName = containerName
      })
   end
end

local function playerConsumeItem(eventData)
   local consumable = Data.getConsumableValues(eventData.item.recordId)
   if (consumable) then
      eventData.player:sendEvent("PlayerConsumedFood", {
         thirst = consumable[1],
         hunger = consumable[2],
         exhaustion = consumable[3],
      })
   end
   --seperated check to keep toxicity parameters optional
   local toxicSubstance = Data.getToxicSubstancesValues(eventData.item.recordId)
   if(toxicSubstance) then
	  eventData.player:sendEvent("PlayerConsumedToxicSubstance", {
		 key = toxicSubstance[1],
		 chance = toxicSubstance[2],
	  })
	end
	 
	if(consumable or toxicSubstance) then
		return
	end

   local empty = Data.getEmptyVariantId(eventData.item.recordId)
   if (empty) then
      local playerInventory = types.Actor.inventory(eventData.player)
      world.createObject(empty, 1):moveInto(playerInventory)
      eventData.player:sendEvent("PlayerConsumedFood", {
         thirst = -1000,
         hunger = 0,
         exhaustion = 0,
      })
   end
end



local function checkJailSpell()
   local player = world.players[1]
   if not player then return end

   local isActive = types.Actor.activeSpells(player)
                   :isSpellActive("detd_jailcheck")

   -- ✧ Edge-trigger: fire only when spell just appeared
   if isActive then
      -- Refill once
      player:sendEvent("PlayerConsumedFood", {
         thirst     = -1000,
         hunger     = -1000,
         exhaustion = -1000,
      })
      print("event")
      --types.Actor.spells(player):add("detd_jailtest2")
      -- Clear the marker so it won't trigger again
      --types.Actor.spells(player):remove("detd_jailcheck")
   end

   -- remember for the next tick
   isActive  = false
end

-- Poll every 3 s (or faster if you prefer)
time.runRepeatedly(function ()
   checkJailSpell()
   return true            -- keep the timer alive
end, 3 * time.second)

return {
   eventHandlers = {
      PlayerConsumeItem = playerConsumeItem,
      PlayerFillContainer = playerFillContainer,
   }} 