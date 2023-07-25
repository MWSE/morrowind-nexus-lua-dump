-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/need.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
-- -----------------------------------------------------------------------------
local core = require("openmw.core")
local ui = require("openmw.ui")
local util = require("openmw.util")

local hud = require("scripts.BasicNeeds.hud")

local Actor = require("openmw.types").Actor
local L = core.l10n("BasicNeeds")

local Need = {}
Need.__index = Need

local STATE = {
   Init     = 0,
   None     = 1,
   Mild     = 2,
   Moderate = 3,
   Severe   = 4,
   Critical = 5,
   Death    = 6,
}

function Need.create(key, actor, value)
   local self = setmetatable({}, Need)
   self.STATE = STATE
   self.enabled = true
   self.actor = actor
   self.value = value
   self.maxValue = 1000
   self.widget = hud[key]
   self.effects = {
      [STATE.Mild]     = "jz_mild_" .. key,
      [STATE.Moderate] = "jz_moderate_" .. key,
      [STATE.Severe]   = "jz_severe_" .. key,
      [STATE.Critical] = "jz_critical_" .. key,
   }
   self.messages = {
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
   return self
end

function Need:status()
   return 1 + math.floor(self.value / 200)
end

function Need:increaseMessage()
   ui.showMessage(self.messages.increase[self:status()])
end

function Need:decreaseMessage()
   ui.showMessage(self.messages.decrease[self:status()])
end

function Need:isEnabled()
   return self.enabled
end

function Need:setEnabled(enabled)
   -- If setting to disabled, reset need
   if (self.enabled and not enabled) then
      self.value = 0
      self:updateEffects(STATE.Init)
   end
   self.enabled = enabled
end

function Need:setMaxValue(maxValue)
   self.maxValue = maxValue
end

function Need:updateEffects(prevStatus)
   local status = self:status()
   if (status ~= prevStatus) then
      for _, effect in pairs(self.effects) do
         Actor.spells(self.actor):remove(effect)
      end
      if (status == STATE.Death) then
         local health = Actor.stats.dynamic.health(self.actor)
         health.current = -1000
      elseif (status > STATE.None) then
         if (status > prevStatus and prevStatus ~= STATE.Init) then
            self:increaseMessage()
         end
         Actor.spells(self.actor):add(self.effects[status])
      end
      self.widget.layout.props.textColor = hud.colors[status]
      self.widget:update()
   end
end

function Need:mod(change)
   if (not self.enabled or change == 0) then return end

   local prevStatus = self:status()
   self.value = util.clamp(self.value + change, 0, self.maxValue)
   if (change < 0) then
      self:decreaseMessage()
   end
   self:updateEffects(prevStatus)
end

return {
   STATE = STATE,
   create = Need.create,
}
