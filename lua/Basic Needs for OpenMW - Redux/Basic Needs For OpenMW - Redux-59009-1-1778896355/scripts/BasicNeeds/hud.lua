-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/hud.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
-- -----------------------------------------------------------------------------
local ui = require("openmw.ui")
local util = require("openmw.util")

local L = require("openmw.core").l10n("BasicNeeds")

local colors = {
   util.color.rgba(1, 1, 1, 0.10), -- NONE
   util.color.rgba(202 / 255, 165 / 255, 96 / 255, 0.25), -- MILD
   util.color.rgba(202 / 255, 165 / 255, 96 / 255, 0.5),  -- MODERATE
   util.color.rgba(200 / 255, 60 / 255, 30 / 255, 0.75),  -- SEVERE
   util.color.rgba(200 / 255, 60 / 255, 30 / 255, 1),     -- CRITICAL
   util.color.rgba(200 / 255, 60 / 255, 30 / 255, 1),     -- DEATH
}

local OFFSETS = { -0.033, 0.0, 0.033 }

-- -----------------------------------------------------------------------------
-- Widget para necesidades (sed, hambre, exhaustion)
-- -----------------------------------------------------------------------------
local Widget = {}
Widget.__index = Widget

function Widget.create(label, offsetIndex, posX, posY, textSize)
   local self = setmetatable({}, Widget)
   self._offsetIndex = offsetIndex
   self._label = label
   self._currentStatus = 1
   self.element = ui.create {
      layer = "HUD",
      type = ui.TYPE.Text,
      props = {
         relativePosition = util.vector2(posX, posY + OFFSETS[offsetIndex]),
         anchor = util.vector2(1, 0.5),
         text = label,
         textSize = textSize,
         textColor = colors[1],
      },
   }
   return self
end

function Widget:update(status)
   self._currentStatus = status
   self.element.layout.props.textColor = colors[status]
   self.element:update()
end

function Widget:updateLayout(posX, posY, textSize)
   self.element.layout.props.relativePosition = util.vector2(posX, posY + OFFSETS[self._offsetIndex])
   self.element.layout.props.textSize = textSize
   self.element:update()
end

function Widget:setVisible(visible)
   if visible then
      self.element.layout.props.textColor = colors[self._currentStatus]
   else
      self.element.layout.props.textColor = util.color.rgba(0, 0, 0, 0)
   end
   self.element:update()
end

-- -----------------------------------------------------------------------------
-- Widget contextual de agua
-- -----------------------------------------------------------------------------
local WaterPrompt = {}
WaterPrompt.__index = WaterPrompt

function WaterPrompt.create(textSize)
   local self = setmetatable({}, WaterPrompt)
   self._visible = false
   self.element = ui.create {
      layer = "HUD",
      type = ui.TYPE.Text,
      props = {
         relativePosition = util.vector2(0.5, 0.565),
         anchor = util.vector2(0.5, 0.5),
         text = "Water",
         textSize = textSize,
         textColor = util.color.rgba(202 / 255, 165 / 255, 96 / 255, 0),
      },
   }
   return self
end

function WaterPrompt:show()
   if self._visible then return end
   self._visible = true
   self.element.layout.props.textColor = util.color.rgba(202 / 255, 165 / 255, 96 / 255, 1)
   self.element:update()
end

function WaterPrompt:hide()
   if not self._visible then return end
   self._visible = false
   self.element.layout.props.textColor = util.color.rgba(202 / 255, 165 / 255, 96 / 255, 0)
   self.element:update()
end

function WaterPrompt:updateLayout(textSize)
   self.element.layout.props.textSize = textSize
   self.element:update()
end

-- -----------------------------------------------------------------------------
-- HUD module — inicialización y actualización
-- -----------------------------------------------------------------------------
local HUD = {}

local defaults = {
   showNeedsWidgets = true,
   hudTextSize      = 18,
   hudPositionX     = 0.985,
   hudPositionY     = 0.5,
   waterPromptSize  = 18,
}

function HUD.init(settings)
   local s = settings or defaults
   HUD.thirst      = Widget.create(L("thirstWidget"),     1, s.hudPositionX, s.hudPositionY, s.hudTextSize)
   HUD.hunger      = Widget.create(L("hungerWidget"),     2, s.hudPositionX, s.hudPositionY, s.hudTextSize)
   HUD.exhaustion  = Widget.create(L("exhaustionWidget"), 3, s.hudPositionX, s.hudPositionY, s.hudTextSize)
   HUD.waterPrompt = WaterPrompt.create(s.waterPromptSize)

   HUD.thirst:setVisible(s.showNeedsWidgets)
   HUD.hunger:setVisible(s.showNeedsWidgets)
   HUD.exhaustion:setVisible(s.showNeedsWidgets)
end

function HUD.applySettings(settings)
   HUD.thirst:updateLayout(settings.hudPositionX, settings.hudPositionY, settings.hudTextSize)
   HUD.hunger:updateLayout(settings.hudPositionX, settings.hudPositionY, settings.hudTextSize)
   HUD.exhaustion:updateLayout(settings.hudPositionX, settings.hudPositionY, settings.hudTextSize)
   HUD.waterPrompt:updateLayout(settings.waterPromptSize)

   HUD.thirst:setVisible(settings.showNeedsWidgets)
   HUD.hunger:setVisible(settings.showNeedsWidgets)
   HUD.exhaustion:setVisible(settings.showNeedsWidgets)
end

return HUD
