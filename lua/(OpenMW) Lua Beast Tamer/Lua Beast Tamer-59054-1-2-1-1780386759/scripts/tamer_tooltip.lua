local types = require("openmw.types")
local ui    = require("openmw.ui")
local util  = require("openmw.util")
local I     = require("openmw.interfaces")

local TITLE_COLOR = util.color.rgb(0.78, 0.66, 0.32)
local TEXT_COLOR  = util.color.rgb(0.875, 0.788, 0.624)
local LOW_COLOR   = util.color.rgb(0.90, 0.35, 0.25)
local WAIT_COLOR   = util.color.rgb(0.792, 0.647, 0.376)
local FOLLOW_COLOR = util.color.rgb(0.875, 0.788, 0.624)
local PET_COLOR    = util.color.rgb(0.875, 0.788, 0.624)

local FONT_SIZE = 16
local PAD_V     = 6

local element = nil

local function destroyWidget()
    if element then
        element:destroy()
        element = nil
    end
end

local function statRow(label, cur, max, low)
    local color = low and LOW_COLOR or TEXT_COLOR
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text       = string.format("  %s  %d / %d  ", label, cur, max),
            textSize   = FONT_SIZE,
            textColor  = color,
            textAlignH = ui.ALIGNMENT.Center,
        },
    }
end

local function buildWidget(info)
    local rows = {}

    rows[#rows + 1] = { props = { size = util.vector2(0, PAD_V) } }

    rows[#rows + 1] = {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text       = string.format("  %s  (Level %d)  ", info.name, info.level),
            textSize   = FONT_SIZE,
            textColor  = TITLE_COLOR,
            textAlignH = ui.ALIGNMENT.Center,
        },
    }
    rows[#rows + 1] = statRow("Health",  info.health,  info.maxHealth,
                              info.maxHealth  > 0 and info.health  / info.maxHealth  < 0.34)
    rows[#rows + 1] = statRow("Magicka", info.magicka, info.maxMagicka, false)
    rows[#rows + 1] = statRow("Fatigue", info.fatigue, info.maxFatigue,
                              info.maxFatigue > 0 and info.fatigue / info.maxFatigue < 0.34)

    if info.minDamage or info.maxDamage then
        local lo = math.floor((info.minDamage or info.maxDamage or 0) + 0.5)
        local hi = math.floor((info.maxDamage or info.minDamage or 0) + 0.5)
        rows[#rows + 1] = {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {
                text       = string.format("  Attack  %d - %d  ", lo, hi),
                textSize   = FONT_SIZE,
                textColor  = TEXT_COLOR,
                textAlignH = ui.ALIGNMENT.Center,
            },
        }
    end

    local isSwapped = I.Tamer and I.Tamer.swapActions and I.Tamer.swapActions()
    local waitPrompt = isSwapped and "Run" or "Activate"
    local petPrompt  = isSwapped and "Activate" or "Run"

    if I.Tamer and I.Tamer.allowWait() then
        local promptText = info.waiting and "Waiting" or "Following"
        local promptColor = info.waiting and WAIT_COLOR or FOLLOW_COLOR
        rows[#rows + 1] = {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {
                text       = string.format("  [Press %s] %s  ", waitPrompt, promptText),
                textSize   = FONT_SIZE,
                textColor  = promptColor,
                textAlignH = ui.ALIGNMENT.Center,
            },
        }
    end

    rows[#rows + 1] = {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text       = string.format("  [Press %s] Pet  ", petPrompt),
            textSize   = FONT_SIZE,
            textColor  = PET_COLOR,
            textAlignH = ui.ALIGNMENT.Center,
        },
    }

    rows[#rows + 1] = { props = { size = util.vector2(0, PAD_V) } }

    element = ui.create {
        layer = "HUD",
        template = I.MWUI.templates.boxTransparent,
        props = {
            relativePosition = util.vector2(0.5, 0.5),
            anchor           = util.vector2(0.5, 0),
            position         = util.vector2(0, 24),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = { arrange = ui.ALIGNMENT.Center },
                content = ui.content(rows),
            },
        },
    }
end

local CHECK_INTERVAL = 0.25
local timer = 0

local function onFrame(dt)
    -- gated by the Tamer interface
    if not I.Tamer or not I.Tamer.modEnabled() or not I.Tamer.tooltipEnabled() then
        destroyWidget()
        return
    end

    timer = timer + dt
    if timer < CHECK_INTERVAL then return end
    timer = 0

    if not I.SharedRay then
        destroyWidget()
        return
    end
    if I.UI.getMode() ~= nil then
        destroyWidget()
        return
    end

    local ray = I.SharedRay.get()
    local obj = ray and ray.hitObject

    if not obj or not obj:isValid() or not types.Creature.objectIsInstance(obj) then
        destroyWidget()
        return
    end

    local info = I.Tamer.getInfo(obj)
    if not info then
        destroyWidget()
        return
    end

    -- rebuilt every interval so the stats stay live
    destroyWidget()
    buildWidget(info)
end

return {
    engineHandlers = {
        onFrame = onFrame,
    },
}