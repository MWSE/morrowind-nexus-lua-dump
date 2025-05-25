-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/need.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com> (original author)
-- 2025 -- Modified by DetailDevil for Devilish Needs 
-- -----------------------------------------------------------------------------
local self = require("openmw.self")
local ui = require("openmw.ui")
local util = require("openmw.util")

local hud = require("scripts.BasicNeeds.hud")

local Actor = require("openmw.types").Actor
local L = require("openmw.core").l10n("BasicNeeds")

local STATE = {
   Init     = 0,
   None     = 1,
   Mild     = 2,
   Moderate = 3,
   Severe   = 4,
   Critical = 5,
   Death    = 6,
}

local Need = { STATE = STATE }
Need.__index = Need

function Need.create(key, value)
   local need = setmetatable({}, Need)
   need._enabled = true
   need._value = value
   need._maxValue = 1000
   need._widget = hud[key]
   need._effects = {
      [STATE.Mild]     = "jz_mild_" .. key,
      [STATE.Moderate] = "jz_moderate_" .. key,
      [STATE.Severe]   = "jz_severe_" .. key,
      [STATE.Critical] = "jz_critical_" .. key,
   }
   need._messages = {
      increase = {
         [STATE.Mild]     = L(key .. "IncreaseMild"),
         [STATE.Moderate] = L(key .. "IncreaseModerate"),
         [STATE.Severe]   = L(key .. "IncreaseSevere"),
         [STATE.Critical] = L(key .. "IncreaseCritical"),
         [STATE.Death]    = L(key .. "IncreaseDeath"),
      },
      decrease = {
         [STATE.None]     = L(key .. "DecreaseNone"),
         [STATE.Mild]     = L(key .. "DecreaseMild"),
         [STATE.Moderate] = L(key .. "DecreaseModerate"),
         [STATE.Severe]   = L(key .. "DecreaseSevere"),
         [STATE.Critical] = L(key .. "DecreaseCritical"),
      }
   }
   need:_updateEffects(STATE.Init)
   return need
end

function Need.status(need)
   return 1 + math.floor(need._value / 200)
end

function Need.value(need) return need._value end
function Need.isEnabled(need) return need._enabled end

function Need.setMaxValue(need, maxValue) need._maxValue = maxValue end

function Need.setEnabled(need, enabled)
   -- If setting to disabled, reset need
   if (need._enabled and not enabled) then
      need._value = 0
      need:_updateEffects(STATE.Init)
   end
   need._enabled = enabled
end

function Need.mod(need, change)
   if (not need._enabled or change == 0) then return end

   local prevStatus = need:status()
   need._value = util.clamp(need._value + change, 0, need._maxValue)
   if (change < 0) then
      need:_decreaseMessage()
   end
   need:_updateEffects(prevStatus)
end

function Need._updateEffects(need, prevStatus)
   local status = need:status()
   if (status == prevStatus) then return end

   for _, effect in pairs(need._effects) do
      Actor.spells(self):remove(effect)
   end
   need._widget:update(status)

   if (status == STATE.None) then return end

   if (status > prevStatus and prevStatus ~= STATE.Init) then
      need:_increaseMessage()
   end
   if (status == STATE.Death) then
      local health = Actor.stats.dynamic.health(self)
      health.current = -1000
   else
      Actor.spells(self):add(need._effects[status])
   end
end

function Need._increaseMessage(need)
  -- ui.showMessage(need._messages.increase[need:status()])
end

function Need._decreaseMessage(need)
  -- ui.showMessage(need._messages.decrease[need:status()])
end


return Need
