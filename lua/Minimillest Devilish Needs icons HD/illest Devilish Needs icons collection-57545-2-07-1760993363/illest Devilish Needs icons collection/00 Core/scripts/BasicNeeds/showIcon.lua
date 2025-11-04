-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/MyShowImage.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com> (original author)
-- 2025 -- Modified by DetailDevil for Devilish Needs 
-- -----------------------------------------------------------------------------

local ui       = require("openmw.ui")
local util     = require("openmw.util")
local self     = require("openmw.self")
local types    = require("openmw.types")

local settings = require("scripts.BasicNeeds.settings")

local hungerImageElement    = nil
local currentHungerStatus   = -1

local function getHungerStatus()
    local spells = types.Actor.activeSpells(self)
    if spells:isSpellActive("jz_critical_hunger") then return 4, "icons/detd_hunger_starving.dds" end
    if spells:isSpellActive("jz_severe_hunger")   then return 3, "icons/detd_hunger_famished.dds" end
    if spells:isSpellActive("jz_moderate_hunger") then return 2, "icons/detd_hunger_hungry.dds" end
    if spells:isSpellActive("jz_mild_hunger")     then return 1, "icons/detd_hunger_slightly.dds" end
    return 0, "icons/detd_hunger_full.dds"
end

local function createImage(texturePath, config)
    return ui.create {
        layer = "HUD", type = ui.TYPE.Image,
        props = {
            resource         = ui.texture { path = texturePath, offset = util.vector2(0,0), size = util.vector2(64,64) },
            relativePosition = config.alternativeHud and util.vector2(1,1) or util.vector2(1,0.5),
            anchor           = config.alternativeHud and util.vector2(1,1) or util.vector2(1,0.5),
            position         = config.alternativeHud
                and util.vector2(-196 + config.hudOffsetX, -38 - config.hudOffsetY)
                or  util.vector2(-16  + config.hudOffsetX, -48 - config.hudOffsetY),
            size             = util.vector2(32,32),
        }
    }
end

local function showImage()
    local status, path = getHungerStatus()
    local config = settings.getValues(settings.group)

    if status ~= currentHungerStatus then
        currentHungerStatus = status
        if hungerImageElement then
            hungerImageElement:destroy()
        end
        hungerImageElement = createImage(path, config)
    end

    -- recalc & apply latest position & visibility
    local newPos = util.vector2(
        (config.alternativeHud and -196 or -16) + config.hudOffsetX,
        (config.alternativeHud and -38  or -48) - config.hudOffsetY
    )
    hungerImageElement.layout.props.position = newPos
    -- **hide/show based on HUD visibility**
    hungerImageElement.layout.props.visible = require("openmw.interfaces").UI.isHudVisible()
    hungerImageElement:update()

    --ui.updateAll()
end

return showImage
