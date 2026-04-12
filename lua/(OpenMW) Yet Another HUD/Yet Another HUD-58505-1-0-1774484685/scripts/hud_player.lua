
local ui    = require("openmw.ui")
local util  = require("openmw.util")
local self  = require("openmw.self")
local types = require("openmw.types")
local I     = require("openmw.interfaces")

local BAR_W      = 200
local BAR_H      = 12
local HALF       = BAR_W / 2
local FRAME_W    = math.floor(BAR_W * 1.193)
local FRAME_H    = math.floor(BAR_H * 3.778)
local BAR_GAP    = 2
local BOTTOM_PAD = 25
local SIDE_PAD   = 10
local SUB_H      = 5

local UPDATE_RATE     = 0.05
local HUD_CHECK_RATE  = 0.25

local TEX_BG    = "textures/Horizontal_Compass/background.png"
local TEX_FILL  = "textures/Horizontal_Compass/health_bar.png"
local TEX_FRAME = "textures/Horizontal_Compass/frame.png"

local COLOR_HP      = util.color.rgb(0.75, 0.05, 0.15)
local COLOR_FATIGUE = util.color.rgb(0.15, 0.65, 0.15)
local COLOR_MAGICKA = util.color.rgb(0.10, 0.25, 0.80)
local COLOR_FRAME   = util.color.rgb(1, 0.8, 0.4)

local texCache = {}
local function tex(path)
    if not texCache[path] then texCache[path] = ui.texture { path = path } end
    return texCache[path]
end

local rHp  = 1
local rFat = 1
local rMag = 1

local prevRHp  = 1
local prevRFat = 1
local prevRMag = 1

local lastFillHp  = -1
local lastFillFat = -1
local lastFillMag = -1

local timer         = 0
local hudCheckTimer = 0
local animating     = true
local hudVisible    = true

local root = ui.create {
    layer = "HUD",
    type  = ui.TYPE.Widget,
    props = { relativeSize = util.vector2(1, 1), mouseTransparent = true },
    content = ui.content {}
}

local STEP  = FRAME_H + BAR_GAP
local yBase = -(BOTTOM_PAD + SUB_H + (FRAME_H - BAR_H) / 2)

local function makeBar(yOffset, color)
    local container = ui.create {
        type = ui.TYPE.Widget,
        props = {
            size             = util.vector2(FRAME_W, FRAME_H),
            relativePosition = util.vector2(0.0, 1.0),
            anchor           = util.vector2(0.0, 1.0),
            position         = util.vector2(SIDE_PAD, yBase - yOffset),
            alpha            = 1,
            mouseTransparent = true,
        },
        content = ui.content {}
    }
    local cx = FRAME_W / 2
    local cy = FRAME_H / 2
    local bg = ui.create {
        type = ui.TYPE.Image,
        props = { resource = tex(TEX_BG), size = util.vector2(BAR_W, BAR_H), position = util.vector2(cx, cy), anchor = util.vector2(0.5, 0.5) }
    }
    local fillL = ui.create {
        type = ui.TYPE.Image,
        props = { resource = tex(TEX_FILL), size = util.vector2(HALF, BAR_H), position = util.vector2(cx, cy), anchor = util.vector2(1, 0.5), color = color }
    }
    local fillR = ui.create {
        type = ui.TYPE.Image,
        props = { resource = tex(TEX_FILL), size = util.vector2(HALF, BAR_H), position = util.vector2(cx, cy), anchor = util.vector2(0, 0.5), color = color }
    }
    local frame = ui.create {
        type = ui.TYPE.Image,
        props = { resource = tex(TEX_FRAME), size = util.vector2(FRAME_W, FRAME_H), color = COLOR_FRAME }
    }
    container.layout.content:add(bg)
    container.layout.content:add(fillL)
    container.layout.content:add(fillR)
    container.layout.content:add(frame)
    return container, fillL, fillR
end

local cHp,  fillHL, fillHR = makeBar(STEP * 2, COLOR_HP)
local cMag, fillML, fillMR = makeBar(STEP,     COLOR_MAGICKA)
local cFat, fillFL, fillFR = makeBar(0,        COLOR_FATIGUE)

root.layout.content:add(cHp)
root.layout.content:add(cMag)
root.layout.content:add(cFat)

local function updateBar(fillL, fillR, container, fillW, lastFill)
    local iFill = math.floor(fillW)
    if iFill == lastFill then return lastFill, false end
    fillL.layout.props.size = util.vector2(iFill, BAR_H)
    fillR.layout.props.size = util.vector2(iFill, BAR_H)
    fillL:update()
    fillR:update()
    container:update()
    return iFill, true
end

local function onFrame(dt)
    hudCheckTimer = hudCheckTimer + dt
    if hudCheckTimer >= HUD_CHECK_RATE then
        hudCheckTimer = 0
        local newHudVisible = I.UI.isHudVisible()
        if newHudVisible ~= hudVisible then
            hudVisible = newHudVisible
            root.layout.props.visible = hudVisible
            root:update()
        end
    end
    if not hudVisible then return end

    timer = timer + dt
    if timer >= UPDATE_RATE then
        timer = 0
        local stats   = types.Actor.stats.dynamic
        local hp      = stats.health(self.object)
        local fatigue = stats.fatigue(self.object)
        local magicka = stats.magicka(self.object)
        local newHp  = hp      and math.max(0, math.min(1, hp.current      / hp.base))      or 1
        local newFat = fatigue and math.max(0, math.min(1, fatigue.current  / fatigue.base)) or 1
        local newMag = magicka and math.max(0, math.min(1, magicka.current  / magicka.base)) or 1
        if newHp ~= prevRHp or newFat ~= prevRFat or newMag ~= prevRMag then
            rHp, rFat, rMag = newHp, newFat, newMag
            prevRHp, prevRFat, prevRMag = newHp, newFat, newMag
            animating = true
        end
    end

    if not animating then return end

    local ch1, ch2, ch3
    lastFillHp,  ch1 = updateBar(fillHL, fillHR, cHp,  HALF * rHp,  lastFillHp)
    lastFillFat, ch2 = updateBar(fillFL, fillFR, cFat, HALF * rFat, lastFillFat)
    lastFillMag, ch3 = updateBar(fillML, fillMR, cMag, HALF * rMag, lastFillMag)

    if not ch1 and not ch2 and not ch3 then
        animating = false
    end
end

return { engineHandlers = { onFrame = onFrame } }