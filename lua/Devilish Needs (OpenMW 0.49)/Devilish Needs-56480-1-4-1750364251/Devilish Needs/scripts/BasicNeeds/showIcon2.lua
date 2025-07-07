-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/ShowIcon2.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com> (original author)
-- 2025 -- Modified by DetailDevil for Devilish Needs 
-- -----------------------------------------------------------------------------

local ui     = require("openmw.ui")
local util   = require("openmw.util")
local self   = require("openmw.self")
local types  = require("openmw.types")
local settings = require("scripts.BasicNeeds.settings")

-- Store created UI image element and current thirst state
local thirstImageElement = nil
local currentThirstStatus = -1

-- Determine the current thirst level and associated texture path
local function getThirstStatus()
    local spells = types.Actor.activeSpells(self)
    if spells:isSpellActive("jz_critical_thirst") then return 4, "icons/detd_thirst_starving.dds" end
    if spells:isSpellActive("jz_severe_thirst")   then return 3, "icons/detd_thirst_famished.dds" end
    if spells:isSpellActive("jz_moderate_thirst") then return 2, "icons/detd_thirst_hungry.dds" end
    if spells:isSpellActive("jz_mild_thirst")     then return 1, "icons/detd_thirst_slightly.dds" end
    return 0, "icons/detd_thirst_empty.dds"
end

-- Create the thirst icon image layout
local function createImage(texturePath, config)
    local iconBaseX  = config.alternativeHud
    local hudOffsetX = config.hudOffsetX
    local hudOffsetY = config.hudOffsetY

    return ui.create {
        layer = "HUD",
        type  = ui.TYPE.Image,
        props = {
            resource         = ui.texture { path = texturePath, offset = util.vector2(0,0), size = util.vector2(32,32) },
            relativePosition = iconBaseX and util.vector2(1,1) or util.vector2(1,0.5),
            anchor           = iconBaseX and util.vector2(1,1) or util.vector2(1,0.5),
            position         = iconBaseX
                and util.vector2(-158 + hudOffsetX, -38 - hudOffsetY)
                or  util.vector2(-16  + hudOffsetX, -10 - hudOffsetY),
            size             = util.vector2(32,32),
        }
    }
end

-- Main function to show or update the thirst icon
local function showThirstImage()
    local status, texturePath = getThirstStatus()
    local config = settings.getValues(settings.group)

    -- recreate on status change
    if status ~= currentThirstStatus then
        currentThirstStatus = status
        if thirstImageElement then thirstImageElement:destroy() end
        thirstImageElement = createImage(texturePath, config)
    end

    -- always recalc position from settings
    do
        local cfg = config
        local newPos = util.vector2(
            (cfg.alternativeHud and -158 or -16) + cfg.hudOffsetX,
            (cfg.alternativeHud and -38  or -10) - cfg.hudOffsetY
        )
        thirstImageElement.layout.props.position = newPos
            -- hide the icon whenever the HUD itself is hidden:
        thirstImageElement.layout.props.visible = require("openmw.interfaces").UI.isHudVisible()
        thirstImageElement:update()
    end

    ui.updateAll()
end

-- Return the updater
return showThirstImage