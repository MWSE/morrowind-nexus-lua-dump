-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/state.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
-- -----------------------------------------------------------------------------
local self = require("openmw.self")
local time = require("openmw_aux.time")
local ui = require("openmw.ui")

local Actor = require("openmw.types").Actor
local L = require("openmw.core").l10n("BasicNeeds")

local Need = require("scripts.BasicNeeds.need")
local HUD = require("scripts.BasicNeeds.hud")

local State = {}
State.__index = State

local FRAME_STATUS = {
   None = 0,
   FastTravel = 1,
}

function State.new(values, settings)
   local state = setmetatable({}, State)
   state._previousTime = values.previousTime
   state._previousCell = values.previousCell
   state._wellRestedTime = values.wellRestedTime

   state.thirst     = Need.create("thirst",    values.thirst,     HUD.thirst,     "jz_well_hydrated")
   state.hunger     = Need.create("hunger",    values.hunger,     HUD.hunger,     "jz_well_satisfied")
   state.exhaustion = Need.create("exhaustion", values.exhaustion, HUD.exhaustion)

   state:setSettings(settings)
   return state
end

function State.setSettings(state, settings)
   state.thirst:setEnabled(settings.enableThirst)
   state.hunger:setEnabled(settings.enableHunger)
   state.exhaustion:setEnabled(settings.enableExhaustion)
   if not settings.enableExhaustion then
      Actor.spells(self):remove("jz_well_rested")
   end

   state.thirst:setMaxValue(settings.maxValue)
   state.hunger:setMaxValue(settings.maxValue)
   state.exhaustion:setMaxValue(settings.maxValue)

   state._thirstRate             = settings.thirstRate
   state._hungerRate             = settings.hungerRate
   state._exhaustionRate         = settings.exhaustionRate
   state._exhaustionRecoveryRate = settings.exhaustionRecoveryRate
   state._sleepNeedsMultiplier   = settings.sleepNeedsMultiplier
   state._wellRestedDuration     = settings.wellRestedDuration
end

local function fastTravelMult(passedTime)
   local decay = -0.025
   local value = 1.0 * math.exp(decay * (passedTime / time.hour))
   if value > 1.0 then
      value = 0.0
   end
   return value
end

function State.update(state, nextTime, currentCell)
   local passedTime = nextTime - state._previousTime
   local status = state:_frameStatus(currentCell, passedTime)

   if status == FRAME_STATUS.FastTravel then
      local travelMult = fastTravelMult(passedTime) * passedTime
      state.thirst:mod(state._thirstRate * travelMult)
      state.hunger:mod(state._hungerRate * travelMult)
      state.exhaustion:mod(state._exhaustionRate * travelMult)
   else
      state.thirst:mod(state._thirstRate * passedTime)
      state.hunger:mod(state._hungerRate * passedTime)
      state.exhaustion:mod(state._exhaustionRate * passedTime)
   end

   local wellRestedTime = state._wellRestedTime
   if wellRestedTime and nextTime - wellRestedTime >= time.hour * state._wellRestedDuration then
      Actor.spells(self):remove("jz_well_rested")
      ui.showMessage(L("exhaustionLoseWellRested"))
      state._wellRestedTime = nil
   end

   state._previousTime = nextTime
   state._previousCell = currentCell
end

function State.applySleep(state, hoursPassed, nextTime)
   local seconds = hoursPassed * time.hour
   state.thirst:mod(state._thirstRate * seconds * state._sleepNeedsMultiplier)
   state.hunger:mod(state._hungerRate * seconds * state._sleepNeedsMultiplier)
   state.exhaustion:mod(state._exhaustionRecoveryRate * seconds)
   state._previousTime = nextTime

   if state.exhaustion:value() <= 0 then
      state._wellRestedTime = nextTime
      Actor.spells(self):add("jz_well_rested")
      ui.showMessage(L("exhaustionGainWellRested"))
   end
end

function State.applyWait(state, hoursPassed, nextTime)
   local seconds = hoursPassed * time.hour
   state.thirst:mod(state._thirstRate * seconds)
   state.hunger:mod(state._hungerRate * seconds)
   state.exhaustion:mod(state._exhaustionRate * seconds)
   state._previousTime = nextTime
end

function State.deserialize(data, settings)
   return State.new({
      previousTime   = data.previousTime,
      previousCell   = self.object.cell,
      wellRestedTime = data.wellRestedTime,
      thirst         = data.thirst,
      hunger         = data.hunger,
      exhaustion     = data.exhaustion,
   }, settings)
end

function State.serialize(state)
   return {
      previousTime   = state._previousTime,
      wellRestedTime = state._wellRestedTime,
      thirst         = state.thirst:value(),
      hunger         = state.hunger:value(),
      exhaustion     = state.exhaustion:value(),
   }
end

function State._frameStatus(state, currentCell, passedTime)
   if passedTime >= time.hour and state._previousCell ~= currentCell then
      return FRAME_STATUS.FastTravel
   end
   return FRAME_STATUS.None
end

return State
