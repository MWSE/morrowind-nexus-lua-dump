-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/hud.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
-- -----------------------------------------------------------------------------
local ui = require("openmw.ui")
local util = require("openmw.util")

local L = require("openmw.core").l10n("BasicNeeds")

local colors = {
   util.color.rgba(202 / 255, 165 / 255, 96 / 255, 0),    -- NONE
   util.color.rgba(202 / 255, 165 / 255, 96 / 255, 0.25), -- MILD
   util.color.rgba(202 / 255, 165 / 255, 96 / 255, 0.5),  -- MODERATE
   util.color.rgba(200 / 255, 60 / 255, 30 / 255, 0.75),  -- SEVERE
   util.color.rgba(200 / 255, 60 / 255, 30 / 255, 1),     -- CRITICAL
   util.color.rgba(200 / 255, 60 / 255, 30 / 255, 1),     -- DEATH
}

local function createWidget(label, offset)
   return ui.create {
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
end

return {
   colors = colors,
   thirst = createWidget(L("thirstWidget"), -0.033),
   hunger = createWidget(L("hungerWidget"), 0.0),
   exhaustion = createWidget(L("exhaustionWidget"), 0.033),
}
