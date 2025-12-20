-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/hud.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com> (original author)
-- 2025 -- Modified by DetailDevil for Devilish Needs 

local ui = require("openmw.ui")
local util = require("openmw.util")
local settings = require("scripts.BasicNeeds.settings")

local L = require("openmw.core").l10n("BasicNeeds")

local colors = {
   util.color.rgba(202 / 255, 165 / 255, 96 / 255, 0),    -- NONE
   util.color.rgba(202 / 255, 165 / 255, 96 / 255, 0), -- MILD
   util.color.rgba(202 / 255, 165 / 255, 96 / 255, 0),  -- MODERATE
   util.color.rgba(202 / 255, 165 / 255, 96 / 255, 0),  -- SEVERE
   util.color.rgba(202 / 255, 165 / 255, 96 / 255, 0),     -- CRITICAL
   util.color.rgba(202 / 255, 165 / 255, 96 / 255, 0),     -- DEATH
}

local Widget = {}
Widget.__index = Widget

function Widget.create(label, offset)
   local self = setmetatable({}, Widget)
   self.element = ui.create {
      layer = "HUD",
      type = ui.TYPE.Text,
      props = {
         relativePosition = util.vector2(0.985, 0.5 + offset),
         anchor = util.vector2(1, 0.5),
         text = label,
         textSize = 16,
         textColor = colors[1],
      },
   }
   return self
end

function Widget:update(status)
   self.element.layout.props.textColor = colors[status]
   self.element:update()
   local config = settings.getValues(settings.group)
   local iconBaseX = config.alternativeHud
end

return {
   thirst = Widget.create(L("thirstWidget"), -0.033),
   hunger = Widget.create(L("hungerWidget"), 0.0),
   exhaustion = Widget.create(L("exhaustionWidget"), 0.033),
   coldness = Widget.create(L("coldnessWidget"), 0.066),
   wet = Widget.create(L("wetWidget"), 0.099),
}
