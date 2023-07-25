-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/player.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
-- -----------------------------------------------------------------------------
local async = require("openmw.async")
local core = require("openmw.core")
local input = require("openmw.input")
local self = require("openmw.self")
local ui = require("openmw.ui")
local time = require("openmw_aux.time")

local Actor = require("openmw.types").Actor

local settings = require("scripts.BasicNeeds.settings")
local bed = require("scripts.BasicNeeds.bed")
local Need = require("scripts.BasicNeeds.need")

local STATE = Need.STATE

local L = core.l10n("BasicNeeds")

-- -----------------------------------------------------------------------------
-- Script state
-- -----------------------------------------------------------------------------
local UPDATE_INTERVAL = time.second * 10

local thirst = Need.create("thirst", self, 0)
local hunger = Need.create("hunger", self, 0)
local exhaustion = Need.create("exhaustion", self, 0)

local previousTime = nil
local previousCell = nil

local wellRestedTime = nil
local sleepingInBed = false

local thirstRate = nil
local hungerRate = nil
local exhaustionRate = nil
local exhaustionRecoveryRate = nil

local function rested(currentCell, passedTime, nextTime)
   if (not exhaustion:isEnabled()) then return false end
   if (passedTime >= time.hour and previousCell == currentCell) then
      local restMult = (sleepingInBed and 1.0 or 0.5)
      if (sleepingInBed and passedTime >= time.hour * 7) then
         -- Add Well Rested if rested at least 7 hours in bed
         wellRestedTime = nextTime
         Actor.spells(self):add("jz_well_rested")
         ui.showMessage(L("exhaustionGainWellRested"))
      end
      exhaustion:mod(exhaustionRecoveryRate * restMult * passedTime)
      return true
   end

   -- Remove Well Rested if 8 hours have passed
   if (wellRestedTime and nextTime - wellRestedTime >= time.hour * 8) then
      -- TODO: Once we can cast regular spells on Actors with Lua, this cleanup
      -- can be removed, as then Well Rested would just expire on its own
      Actor.spells(self):remove("jz_well_rested")
      ui.showMessage(L("exhaustionLoseWellRested"))
      wellRestedTime = nil
   end
   return false
end

local function updateNeeds()
   local nextTime = core.getGameTime()
   local passedTime = nextTime - previousTime
   local currentCell = self.object.cell

   thirst:mod(thirstRate * passedTime)
   hunger:mod(hungerRate * passedTime)
   if (not rested(currentCell, passedTime, nextTime)) then
      exhaustion:mod(exhaustionRate * passedTime)
   end

   previousTime = nextTime
   previousCell = currentCell
   sleepingInBed = false
end

-- -----------------------------------------------------------------------------
-- Initialization
-- -----------------------------------------------------------------------------
local function loadSettings()
   local SETTING = settings.SETTING
   local group = settings.group

   -- Enable / Disable needs
   thirst:setEnabled(group:get(SETTING.EnableThirst))
   hunger:setEnabled(group:get(SETTING.EnableHunger))
   local enableExhaustion = group:get(SETTING.EnableExhaustion)
   if (not enableExhaustion) then
      -- TODO: Once we can cast regular spells on Actors with Lua, this cleanup
      -- can be removed, as then Well Rested would just expire on its own
      Actor.spells(self):remove("jz_well_rested")
   end
   exhaustion:setEnabled(enableExhaustion)

   -- If death is disabled, simply limit values to 999
   local maxValue = group:get(SETTING.EnableDeath) and 1000 or 999
   thirst:setMaxValue(maxValue)
   hunger:setMaxValue(maxValue)
   exhaustion:setMaxValue(maxValue)

   -- All rates are configured as per hour values, so we first convert them to
   -- per second values
   thirstRate = group:get(SETTING.ThirstRate) / time.hour
   hungerRate = group:get(SETTING.HungerRate) / time.hour
   exhaustionRate = group:get(SETTING.ExhaustionRate) / time.hour
   exhaustionRecoveryRate = -(group:get(SETTING.ExhaustionRecoveryRate) / time.hour)
end

local function initialize(startTime)
   previousTime = startTime
   previousCell = self.object.cell
   loadSettings()
   -- Force update effects on initialize
   thirst:updateEffects(STATE.Init)
   hunger:updateEffects(STATE.Init)
   exhaustion:updateEffects(STATE.Init)
end

initialize(core.getGameTime())
settings.group:subscribe(async:callback(loadSettings))
time.runRepeatedly(updateNeeds, UPDATE_INTERVAL, { type = time.GameTime })

-- -----------------------------------------------------------------------------
-- Engine/event handlers
-- -----------------------------------------------------------------------------
local function onLoad(data)
   thirst = Need.create("thirst", self, data.thirst)
   hunger = Need.create("hunger", self, data.hunger)
   exhaustion = Need.create("exhaustion", self, data.exhaustion)
   wellRestedTime = data.wellRestedTime
   initialize(data.previousTime)
   ui.updateAll()
   -- FIXME: For some reason, on loading game, dynamically created potions are
   -- left in some limbo state where they can be used, but don't result in
   -- correct 'onConsume' events. By running `getAll()` on player inventory,
   -- the potions get normalized. Made issue #7448 about this.
   Actor.inventory(self):getAll()
end

local function onSave()
   return {
      thirst = thirst.value,
      hunger = hunger.value,
      exhaustion = exhaustion.value,
      previousTime = previousTime,
      wellRestedTime = wellRestedTime,
   }
end

local function onConsume(item)
   core.sendGlobalEvent("PlayerConsumeItem", {
      player = self,
      item = item,
   })
end

local function onInputAction(action)
   if (core.isWorldPaused()) then return end
   -- TODO: Using Sneak as hotkey is a workaround. Re-examine this if/when
   -- OpenMW Lua makes running on-use scripts on miscellaneous items possible
   if (thirst:isEnabled() and action == input.ACTION.Sneak and Actor.isSwimming(self)) then
      core.sendGlobalEvent("PlayerFillContainer", {
         player = self,
      })
   end
   -- TODO: Hacky workaround for checking beds. Activation handlers on activators
   -- (i.e. beds) don't seem to do anything yet on OpenMW. Fix this when possible.
   if (exhaustion:isEnabled() and action == input.ACTION.Activate) then
      sleepingInBed = bed.tryFindBed(self)
   end
end

local function playerConsumedFood(eventData)
   thirst:mod(eventData.thirst)
   hunger:mod(eventData.hunger)
   exhaustion:mod(eventData.exhaustion)
end

local function playerFilledContainer(eventData)
   if (eventData.containerName) then
      ui.showMessage(L("filledContainer", { item = eventData.containerName }))
   else
      ui.showMessage(L("noContainers"))
   end
end

return {
   interfaceName = "BasicNeeds",
   interface = {
      version = 1,
      getThirstStatus = function()
         return thirst:status()
      end,
      getHungerStatus = function()
         return hunger:status()
      end,
      getExhaustionStatus = function()
         return exhaustion:status()
      end,
   },
   engineHandlers = {
      onLoad = onLoad,
      onSave = onSave,
      onConsume = onConsume,
      onInputAction = onInputAction,
   },
   eventHandlers = {
      PlayerConsumedFood = playerConsumedFood,
      PlayerFilledContainer = playerFilledContainer,
   },
}
