--[[
ErnGlider for OpenMW.
Copyright (C) 2026 Erin Pentecost

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
local MOD_NAME           = require("scripts.ErnGlider.ns")
local core               = require("openmw.core")
local pself              = require("openmw.self")
local camera             = require('openmw.camera')
local util               = require('openmw.util')
local async              = require("openmw.async")
local types              = require('openmw.types')
local input              = require('openmw.input')
local controls           = require('openmw.interfaces').Controls
local nearby             = require('openmw.nearby')
local animation          = require('openmw.animation')
local ui                 = require('openmw.ui')
local aux_util           = require('openmw_aux.util')
local interfaces         = require("openmw.interfaces")
local settings           = require("scripts.ErnGlider.settings")
local common             = require("scripts.ErnGlider.ui.common")
local bar                = require("scripts.ErnGlider.ui.bar")
local toastcontainer     = require("scripts.ErnGlider.ui.toastcontainer")
local localization       = core.l10n(MOD_NAME)
local uiInterface        = require("openmw.interfaces").UI

---@class DisplayData
---@field dt number
---@field speed number
---@field conditionRatio number
---@field fatigueRatio number
---@field momentumRatio number
---@field points number
---@field newToasts any[]

---@type DisplayData?
local currentDisplayData = nil



local pointsText          = ui.create {
    type = ui.TYPE.Text,
    name = "pointsText",
    props = {
        text = "0",
        textColor = common.configColor("normal"),
        textShadow = true,
        textShadowColor = util.color.rgba(0, 0, 0, 0.9),
        --textAlignV = ui.ALIGNMENT.Start,
        --textAlignH = ui.ALIGNMENT.Start,
        textSize = 18,
        relativePosition = util.vector2(0.5, 0.5),
        --anchor = util.vector2(0.5, 0.5),
    }
}

local kphNormalColor      = common.configColor("normal")
local kphMaxMomentumColor = common.configColor("positive")
local kphText             = ui.create {
    type = ui.TYPE.Text,
    name = "speedText",
    props = {
        text = "0 kph",
        textColor = kphNormalColor,
        textShadow = true,
        textShadowColor = util.color.rgba(0, 0, 0, 0.9),
        textAlignV = ui.ALIGNMENT.Start,
        textAlignH = ui.ALIGNMENT.Start,
        textSize = 18,
        relativePosition = util.vector2(1, 0),
        anchor = util.vector2(1, 0),
    }
}


local function lerpColor(a, b, t)
    return util.color.rgba(
        a.r + (b.r - a.r) * t,
        a.g + (b.g - a.g) * t,
        a.b + (b.b - a.b) * t,
        a.a + (b.a - a.a) * t
    )
end

local fatigueBar    = bar.NewBar(1, common.configColor("fatigue"),
    lerpColor(common.configColor("fatigue"), util.color.rgba(0.9, 0.9, 0.9, 1), 0.7))
local conditionBar  = bar.NewBar(1, common.configColor("weapon_fill"),
    lerpColor(common.configColor("weapon_fill"), util.color.rgba(0.9, 0.9, 0.9, 1), 0.7))
local momentumBar   = bar.NewBar(1, common.configColor("journal_link"),
    lerpColor(common.configColor("journal_topic"), util.color.rgba(0.9, 0.9, 0.9, 1), 0.7))

local toasts        = toastcontainer.NewToastContainer()

local pointsElement = ui.create {
    name = "root",
    layer = 'HUD',
    type = ui.TYPE.Container,
    props = {
        position = util.vector2(10, 10),
        anchor = util.vector2(0, 0),
        visible = false,
        autoSize = true,
    },
    content = ui.content {
        pointsText
    }
}

local statusElement = ui.create {
    name = "root",
    layer = 'HUD',
    type = ui.TYPE.Container,
    --template = interfaces.MWUI.templates.boxTransparentThick,
    props = {
        relativePosition = util.vector2(1, 0.5),
        anchor = util.vector2(1, 0.5),
        visible = false,
        autoSize = true,
    },
    content = ui.content {
        {
            name = 'vFlex',
            type = ui.TYPE.Flex,
            props = {
                horizontal = false,
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content {
                {
                    -- ensures minimum width
                    props = { size = util.vector2(60, 0) },
                },
                kphText,
                {
                    name = 'barFlex',
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = true,
                        autoSize = true,
                    },
                    content = ui.content {
                        { props = { size = util.vector2(4, 0) } },
                        fatigueBar.elem,
                        { props = { size = util.vector2(4, 0) } },
                        conditionBar.elem,
                        { props = { size = util.vector2(4, 0) } },
                        momentumBar.elem,
                    }
                },
            }
        }
    }
}

---@param data DisplayData?
local function display(data)
    if not settings.surf.chimTricky then
        data = nil
    end
    -- handle visibility
    if not data then
        -- newly hidden
        if currentDisplayData then
            settings.debugPrint("Hiding CHIM Tricky UI")
            uiInterface.setHudVisibility(true)
            currentDisplayData = nil
            statusElement.layout.props.visible = false
            statusElement:update()
            pointsElement.layout.props.visible = false
            pointsElement:update()
            toasts:purgeToasts(true)
        end
        return
    else
        -- newly visible
        if not currentDisplayData then
            uiInterface.setHudVisibility(false)
            statusElement.layout.props.visible = true
            pointsElement.layout.props.visible = true
            fatigueBar:reset(data.fatigueRatio or 1)
            conditionBar:reset(data.conditionRatio or 1)
            momentumBar:reset(data.momentumRatio or 0)
        end
    end

    if data.momentumRatio then
        if data.momentumRatio >= 1 then
            kphText.layout.props.textColor = kphMaxMomentumColor
        else
            kphText.layout.props.textColor = kphNormalColor
        end
        -- debug momentum meter
        if settings.main.debugMode then
            momentumBar.elem.layout.props.visible = true
            momentumBar:onUpdate(data.dt, data.momentumRatio)
        else
            momentumBar.elem.layout.props.visible = false
            momentumBar.elem:update()
        end
    end

    if data.speed then
        if currentDisplayData ~= nil and currentDisplayData.speed ~= data.speed then
            kphText.layout.props.text = localization('kph', { value = math.floor(data.speed) })
            kphText:update()
        end
    end

    if data.fatigueRatio then
        fatigueBar:onUpdate(data.dt, data.fatigueRatio)
    end
    if data.conditionRatio then
        conditionBar:onUpdate(data.dt, data.conditionRatio)
    end

    if data.points then
        if currentDisplayData ~= nil and currentDisplayData.points ~= data.points then
            pointsText.layout.props.text = tostring(data.points)
            pointsText:update()
        end
    end

    toasts:update(data.dt, data.newToasts)

    --settings.debugPrint(aux_util.deepToString(data, 3))
    statusElement:update()
    pointsElement:update()
    local oldDT = currentDisplayData and currentDisplayData.dt or 0
    currentDisplayData = data
    currentDisplayData.dt = currentDisplayData.dt + oldDT
end

return {
    display = display,
}
