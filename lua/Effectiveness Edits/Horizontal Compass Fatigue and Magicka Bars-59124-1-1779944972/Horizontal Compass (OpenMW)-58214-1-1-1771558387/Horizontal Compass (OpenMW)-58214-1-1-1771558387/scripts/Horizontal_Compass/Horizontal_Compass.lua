-- OpenMW 50 --
-- Horizontal Compass --

local ui = require("openmw.ui")
local util = require("openmw.util")
local self = require("openmw.self") 
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local core = require("openmw.core")

local settings = storage.playerSection("Horizontal_Compass_Settings")

-- =====================
-- CONFIG 
-- =====================
local rawScale = settings:get("compassScale") or 100
local SCALE_FACTOR = rawScale / 100

local dynamicTextSize = settings:get("cellTextSize") or 20

local posX = (settings:get("posX") or 50) / 100
local posY = (settings:get("posY") or 5) / 100

local COMPASS_WIDTH, COMPASS_HEIGHT = 420 * SCALE_FACTOR, 28 * SCALE_FACTOR
local TEXTURE_WIDTH = 2048 * SCALE_FACTOR
local OVERLAY_WIDTH, OVERLAY_HEIGHT = 520 * SCALE_FACTOR, 66 * SCALE_FACTOR

local LETTER_COLOR = util.color.rgb(1, 1, 1)
local FRAME_COLOR  = util.color.rgb(1, 0.8, 0.4)
local CELL_FADE_TIME = 6.0


-- =====================
-- STATE
-- =====================
local lastCellName = ""
local cellDisplayStartTime = 0

-- =====================
-- UI CREATION
-- =====================
local function getStylePath(filename)
    local style = tostring(settings:get("stylePath") or "1")
    return "textures/Horizontal_Compass/" .. style .. "/" .. filename
end

local root = ui.create {
    layer = "HUD", 
    type = ui.TYPE.Widget,
    props = { relativeSize = util.vector2(1, 1), mouseTransparent = true },
    content = ui.content {}
}

local cellText = ui.create {
    type = ui.TYPE.Text,
    props = {
        text = "",
        textSize = dynamicTextSize,
        textColor = util.color.rgb(1, 1, 1),
        textShadow = true,
        relativePosition = util.vector2(posX, posY),
        anchor = util.vector2(0.5, 1.8),
        alpha = 0
    }
}
root.layout.content:add(cellText)

local mainContainer = ui.create {
    type = ui.TYPE.Widget,
    props = {
        size = util.vector2(OVERLAY_WIDTH, OVERLAY_HEIGHT),
        relativePosition = util.vector2(posX, posY), 
        anchor = util.vector2(0.5, 0.4),
        visible = true,
    },
    content = ui.content {}
}

mainContainer.layout.content:add(ui.create {
    type = ui.TYPE.Image,
    props = { 
        resource = ui.texture { path = getStylePath("compass_background.png") }, 
        size = util.vector2(OVERLAY_WIDTH, OVERLAY_HEIGHT) 
    }
})

local viewport = ui.create {
    type = ui.TYPE.Widget,
    props = { size = util.vector2(COMPASS_WIDTH, COMPASS_HEIGHT), position = util.vector2((OVERLAY_WIDTH - COMPASS_WIDTH) / 2, (OVERLAY_HEIGHT - COMPASS_HEIGHT) / 2), clip = true },
    content = ui.content {}
}

local strip = ui.create {
    type = ui.TYPE.Widget,
    props = { size = util.vector2(TEXTURE_WIDTH * 3, COMPASS_HEIGHT) },
    content = ui.content {
        ui.create { type = ui.TYPE.Image, props = { resource = ui.texture { path = getStylePath("compass.png") }, color = LETTER_COLOR, size = util.vector2(TEXTURE_WIDTH + 2, COMPASS_HEIGHT), position = util.vector2(0, 0) } },
        ui.create { type = ui.TYPE.Image, props = { resource = ui.texture { path = getStylePath("compass.png") }, color = LETTER_COLOR, size = util.vector2(TEXTURE_WIDTH + 2, COMPASS_HEIGHT), position = util.vector2(TEXTURE_WIDTH - 1, 0) } },
        ui.create { type = ui.TYPE.Image, props = { resource = ui.texture { path = getStylePath("compass.png") }, color = LETTER_COLOR, size = util.vector2(TEXTURE_WIDTH + 2, COMPASS_HEIGHT), position = util.vector2((TEXTURE_WIDTH * 2) - 2, 0) } }
    }
}
viewport.layout.content:add(strip)
mainContainer.layout.content:add(viewport)

mainContainer.layout.content:add(ui.create {
    type = ui.TYPE.Image,
    props = { 
        resource = ui.texture { path = getStylePath("compass_overlay.png") }, 
        color = FRAME_COLOR, 
        size = util.vector2(OVERLAY_WIDTH, OVERLAY_HEIGHT) 
    }
})

root.layout.content:add(mainContainer)

-- =====================
-- UPDATE FUNCTION
-- =====================
local function onFrame()
    local time = core.getSimulationTime()
    
    local isEnabled = settings:get("showCompass")
    local showCellName = settings:get("showCellName")
    local isHudVisible = I.UI.isHudVisible()
    local currentMode = I.UI.getMode()
    
    local shouldShow = isEnabled and not currentMode and isHudVisible

    local currentCell = self.cell.name
    if currentCell ~= lastCellName then
        lastCellName = currentCell
        cellDisplayStartTime = time
        cellText.layout.props.text = currentCell
    end

    local elapsed = time - cellDisplayStartTime
    local alpha = 0
    
    if showCellName and elapsed < CELL_FADE_TIME and shouldShow then
        alpha = math.min(1, (CELL_FADE_TIME - elapsed) / 1.0)
    end

    if cellText.layout.props.alpha ~= alpha then
        cellText.layout.props.alpha = alpha
        cellText:update()
    end

    if mainContainer.layout.props.visible ~= shouldShow then
        mainContainer.layout.props.visible = shouldShow
        mainContainer:update() 
    end

    if not shouldShow then return end

    local yaw = self.rotation:getYaw()
    if not yaw then return end

    local t = (yaw / 6.283185) % 1
    local xOffset = -(t * TEXTURE_WIDTH) - TEXTURE_WIDTH + (COMPASS_WIDTH * 0.5)

    strip.layout.props.position = util.vector2(xOffset, 0)
    strip:update()
    viewport:update()
end

return { engineHandlers = { onFrame = onFrame } }

