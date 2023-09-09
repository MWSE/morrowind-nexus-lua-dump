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

local State = {}
State.__index = State

local FRAME_STATUS = {
   None = 0,
   RestOrWait = 1,
   FastTravel = 2,
}

function State.new(values, settings)
   local state = setmetatable({}, State)
   state._previousTime = values.previousTime
   state._previousCell = values.previousCell
   state._wellRestedTime = values.wellRestedTime
   state._sleepingInBed = false

   state.thirst = Need.create("thirst", values.thirst)
   state.hunger = Need.create("hunger", values.hunger)
   state.exhaustion = Need.create("exhaustion", values.exhaustion)

   state:setSettings(settings)
   return state
end

function State.setSettings(state, settings)
   state.thirst:setEnabled(settings.enableThirst)
   state.hunger:setEnabled(settings.enableHunger)
   state.exhaustion:setEnabled(settings.enableExhaustion)
   if (not settings.enableExhaustion) then
      -- TODO: Once we can cast regular spells on Actors with Lua, this cleanup
      -- can be removed, as then Well Rested would just expire on its own
      Actor.spells(self):remove("jz_well_rested")
   end

   state.thirst:setMaxValue(settings.maxValue)
   state.hunger:setMaxValue(settings.maxValue)
   state.exhaustion:setMaxValue(settings.maxValue)

   state._thirstRate = settings.thirstRate
   state._hungerRate = settings.hungerRate
   state._exhaustionRate = settings.exhaustionRate
   state._exhaustionRecoveryRate = settings.exhaustionRecoveryRate
end

function State.setSleepingInBed(state, sleepingInBed)
   state._sleepingInBed = sleepingInBed
end

function State.update(state, nextTime, currentCell)
   local passedTime = nextTime - state._previousTime
   local status = state:_frameStatus(currentCell, passedTime)
   if (status == FRAME_STATUS.RestOrWait) then
      local restMult = 0.5 * passedTime
      if (state._sleepingInBed) then
         restMult = 1.0 * passedTime
         if (passedTime >= time.hour * 7) then
            -- Add Well Rested if rested at least 7 hours in bed
            state._wellRestedTime = nextTime
            Actor.spells(self):add("jz_well_rested")
            ui.showMessage(L("exhaustionGainWellRested"))
         end
      end
      state.thirst:mod(state._thirstRate * passedTime)
      state.hunger:mod(state._hungerRate * passedTime)
      state.exhaustion:mod(state._exhaustionRecoveryRate * restMult)
   elseif (status == FRAME_STATUS.FastTravel) then
      local travelMult = state._fastTravelMult(passedTime) * passedTime
      state.thirst:mod(state._thirstRate * travelMult)
      state.hunger:mod(state._hungerRate * travelMult)
      state.exhaustion:mod(state._exhaustionRate * travelMult)
   else
      state.thirst:mod(state._thirstRate * passedTime)
      state.hunger:mod(state._hungerRate * passedTime)
      state.exhaustion:mod(state._exhaustionRate * passedTime)
   end

   -- Remove Well Rested if 8 hours have passed
   local wellRestedTime = state._wellRestedTime
   if (wellRestedTime and nextTime - wellRestedTime >= time.hour * 8) then
      -- TODO: Once we can cast regular spells on Actors with Lua, this cleanup
      -- can be removed, as then Well Rested would just expire on its own
      Actor.spells(self):remove("jz_well_rested")
      ui.showMessage(L("exhaustionLoseWellRested"))
      state._wellRestedTime = nil
   end

   state._previousTime = nextTime
   state._previousCell = currentCell
   state._sleepingInBed = false
end

function State.deserialize(data, settings)
   return State.new({
      previousTime = data.previousTime,
      previousCell = self.object.cell,
      wellRestedTime = data.wellRestedTime,
      thirst = data.thirst,
      hunger = data.hunger,
      exhaustion = data.exhaustion,
   }, settings)
end

function State.serialize(state)
   return {
      previousTime = state._previousTime,
      wellRestedTime = state._wellRestedTime,
      thirst = state.thirst:value(),
      hunger = state.hunger:value(),
      exhaustion = state.exhaustion:value(),
   }
end

function State._frameStatus(state, currentCell, passedTime)
   if (passedTime >= time.hour) then
      if (state._previousCell == currentCell) then
         return FRAME_STATUS.RestOrWait
      else
         return FRAME_STATUS.FastTravel
      end
   end
   return FRAME_STATUS.None
end

function State._fastTravelMult(passedTime)
   -- Decays from 1.0 towards 0.0 relative to passed time, so longer trips
   -- will accumulate needs relatively less than short trips.

   -- Some examples at default settings:
   -- 0.93 at 3 hours  (Seyda Need -> Balmora)
   -- 0.84 at 7 hours  (Gnaar Mok  -> Khuul)
   -- 0.76 at 11 hours (Ebonheart  -> Sadrith Mora)
   -- 0.23 at 58 hours (Dagon Fel  -> Karthwasten)  (SHotN)
   -- 0.16 at 73 hours (Stirk      -> Ebonheart)    (Project Cyrodiil)

   local decay = -0.025
   local value = 1.0 * math.exp(decay * (passedTime / time.hour))
   if (value > 1.0) then
      value = 0.0
   end
   return value
end

return State
