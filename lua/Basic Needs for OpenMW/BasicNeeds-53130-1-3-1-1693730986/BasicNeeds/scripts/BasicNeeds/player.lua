-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/player.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
-- -----------------------------------------------------------------------------
local async = require("openmw.async")
local core = require("openmw.core")
local self = require("openmw.self")
local ui = require("openmw.ui")
local time = require("openmw_aux.time")

local bed = require("scripts.BasicNeeds.bed")
local settings = require("scripts.BasicNeeds.settings")
local State = require("scripts.BasicNeeds.state")

local Actor = require("openmw.types").Actor
local ACTION = require("openmw.input").ACTION
local L = core.l10n("BasicNeeds")

-- -----------------------------------------------------------------------------
-- Initialization
-- -----------------------------------------------------------------------------
local UPDATE_INTERVAL = time.second * 10

local state = State.new({
   previousTime = core.getGameTime(),
   previousCell = self.object.cell,
   wellRestedTime = nil,
   thirst = 0,
   hunger = 0,
   exhaustion = 0,
}, settings.getValues(settings.group))

local function onSettingsUpdate()
   state:setSettings(settings.getValues(settings.group))
end

local function onUpdate()
   state:update(core.getGameTime(), self.object.cell)
end

settings.group:subscribe(async:callback(onSettingsUpdate))
time.runRepeatedly(onUpdate, UPDATE_INTERVAL, { type = time.GameTime })

-- -----------------------------------------------------------------------------
-- Engine/event handlers
-- -----------------------------------------------------------------------------
local function onLoad(data)
   state = State.deserialize(data, settings.getValues(settings.group))
   ui.updateAll()
   -- FIXME: For some reason, on loading game, dynamically created potions are
   -- left in some limbo state where they can be used, but don't result in
   -- correct 'onConsume' events. By running `getAll()` on player inventory,
   -- the potions get normalized. Made issue #7448 about this.
   Actor.inventory(self):getAll()
end

local function onSave() return state:serialize() end

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
   if (state.thirst:isEnabled() and action == ACTION.Sneak and Actor.isSwimming(self)) then
      core.sendGlobalEvent("PlayerFillContainer", {
         player = self,
      })
   end
   -- TODO: Hacky workaround for checking beds. Activation handlers on activators
   -- (i.e. beds) don't seem to do anything yet on OpenMW. Fix this when possible.
   if (state.exhaustion:isEnabled() and action == ACTION.Activate) then
      state:setSleepingInBed(bed.tryFindBed(self))
   end
end

local function playerConsumedFood(eventData)
   state.thirst:mod(eventData.thirst)
   state.hunger:mod(eventData.hunger)
   state.exhaustion:mod(eventData.exhaustion)
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
         return state.thirst:status()
      end,
      getHungerStatus = function()
         return state.hunger:status()
      end,
      getExhaustionStatus = function()
         return state.exhaustion:status()
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
