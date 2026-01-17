local I = require("openmw.interfaces")
local ambient = require('openmw.ambient')
local async = require("openmw.async")
local core = require("openmw.core")
local self = require("openmw.self")
local ui = require("openmw.ui")
local util = require("openmw.util")
local types = require("openmw.types")
local v2 = util.vector2
local backgroundElement
local currentAlpha = 1
local fadeIn = 0
local fadeInTime = 0
local fadeOutTime = 0
local fadeOut = 0
local fadeDelay = 0
local delta = 0.01
ui.layers.insertAfter("HUD", "Background_QT", { interactive = false })
local function showFade()
    local resource = ui.texture { -- texture in the top left corner of the atlas
        path = "icons/quicktrain/A_black_image.jpg"

    }


    local win = ui.create {
        layer = "Windows",

        props = {
            anchor = util.vector2(0.5, 0.5),
            -- relativePosition = util.vector2(0.5, 0.5),
            -- arrange = ui.ALIGNMENT.Center,
            --align = ui.ALIGNMENT.Center,
            size = ui.screenSize(),
        },
        content =

            ui.content {
                type = ui.TYPE.Image,
                props = {
                    resource = resource,
                    size = ui.screenSize(),
                    --  relativeSize = util.vector2(0.2, 0.2)
                }
            },


    }
    return win
end

local function showFade(opacity)
    local relativeSize = v2(1, 1)
    local relativePosition = v2(0.5, 0.5)
    local anchor = v2(0.5, 0.5)

    if backgroundElement then
        backgroundElement:destroy()
        backgroundElement = nil
    end
    backgroundElement = ui.create {
        layer = "Background_QT",
        type = ui.TYPE.Image,
        props = {
            relativeSize = relativeSize,
            relativePosition = relativePosition,
            anchor = anchor,
            resource = ui.texture { path = 'white' },
            color = util.color.rgb(0, 0, 0),
            alpha = opacity or 0.1,
        }
    }
end
local function setAlpha(val)
    if val <= 0 then
        if backgroundElement then
            backgroundElement:destroy()
            backgroundElement = nil
        end
        return
    end
    if val > 1 then
        val = 1
    end
    currentAlpha = val
    if not backgroundElement then
        showFade(val)
        return
    end
    backgroundElement.layout.props.alpha = val
    backgroundElement:update()
end
local function getElement()
    return backgroundElement
end
local function onFrame(dt)
    local frameTime = core.getRealFrameDuration()
    if fadeOut > 0 then
        -- Increase alpha to 1 during fade-out (fully faded)
        currentAlpha = math.min(1, currentAlpha + frameTime / fadeOutTime)
        fadeOut = fadeOut - frameTime
       -- --print("Fading out: alpha =", currentAlpha)
    elseif fadeDelay > 0 then
        -- Pause during fade delay
        fadeDelay = fadeDelay - frameTime
        ----print("Fade delay")
    elseif fadeIn > 0 then
        -- Decrease alpha to 0 during fade-in
        currentAlpha = math.max(0, currentAlpha - frameTime / fadeInTime)
        fadeIn = fadeIn - frameTime
       -- --print("Fading in: alpha =", currentAlpha)
    end
    if backgroundElement then
        --   --print(currentAlpha)
        setAlpha(currentAlpha)
    end
end
return {
    interfaceName = "QT_Fade",
    interface = {
        showFade = showFade,
        setAlpha = setAlpha,
        getElement = getElement,
        fade = function(fin, fo, del)
            currentAlpha = 0
            fadeIn = fin
            fadeInTime = fin
            fadeOut = fo
            fadeOutTime = fo
            fadeDelay = del
            setAlpha(delta)
        end
    },
    engineHandlers = {
        onFrame = onFrame
    }
}
