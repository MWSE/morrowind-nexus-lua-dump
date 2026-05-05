local ui      = require("openmw.ui")
local util    = require("openmw.util")
local self    = require("openmw.self")
local types   = require("openmw.types")
local storage = require("openmw.storage")
local async   = require("openmw.async")
local I       = require("openmw.interfaces")

local shared   = require("scripts.hud_shared")
local DEFAULTS = shared.DEFAULTS

local BAR_W      = 200
local BAR_H      = 12
local HALF       = BAR_W / 2
local FRAME_W    = math.floor(BAR_W * 1.193)
local FRAME_H    = math.floor(BAR_H * 3.778)
local BAR_GAP    = 2
local SIDE_PAD   = 10
local SUB_H      = 8
local SUB_HF      = 10

-- encumbrance horizontal sub-bar
local ESUB_GAP    = -12
local ESUB_W      = math.floor(BAR_W * 0.98)
-- frame extends around the bar
local ESUB_FR_PADX = math.floor(ESUB_W * (1.193 - 1) / 2)
local ESUB_FR_PADY = math.floor((SUB_H * 3.778 - SUB_H) / 2)
local ESUB_FR_W    = ESUB_W + 2 * ESUB_FR_PADX
local ESUB_FR_H    = SUB_H  + 2 * ESUB_FR_PADY

-- encumbrance vertical bar
local EVBAR_W       = 10
local EVBAR_GAP     = 2
-- same frame proportions as horizontal but rotated
local EVBAR_FR_PADX = math.floor(EVBAR_W * (3.778 - 1) / 2)

local UPDATE_RATE     = 0.05
local HUD_CHECK_RATE  = 0.25

local TEX_BG         = "textures/Horizontal_Compass/background.png"
local TEX_FILL       = "textures/Horizontal_Compass/health_bar.png"
local TEX_FRAME      = "textures/Horizontal_Compass/frame.png"
local TEX_ENC_FRAME  = "textures/Horizontal_Compass/compass_overlay.png"
local TEX_ENC_FRAMEV = "textures/Horizontal_Compass/compass_overlay1.png"

local COLOR_FRAME = util.color.rgb(1, 0.8, 0.4)

local togglesSection = storage.playerSection("SettingsHudToggles")
local colorsSection  = storage.playerSection("SettingsHudColors")

local function getToggle(key)
    local v = togglesSection:get(key)
    if v == nil then return DEFAULTS[key] end
    return v
end

local function readColor(rKey, gKey, bKey)
    local r = colorsSection:get(rKey); if r == nil then r = DEFAULTS[rKey] end
    local g = colorsSection:get(gKey); if g == nil then g = DEFAULTS[gKey] end
    local b = colorsSection:get(bKey); if b == nil then b = DEFAULTS[bKey] end
    return util.color.rgb(r, g, b)
end

local COLOR_HP          = readColor("COLOR_HP_R", "COLOR_HP_G", "COLOR_HP_B")
local COLOR_FATIGUE     = readColor("COLOR_FATIGUE_R", "COLOR_FATIGUE_G", "COLOR_FATIGUE_B")
local COLOR_MAGICKA     = readColor("COLOR_MAGICKA_R", "COLOR_MAGICKA_G", "COLOR_MAGICKA_B")
local COLOR_ENCUMBRANCE = readColor("COLOR_ENCUMBRANCE_R", "COLOR_ENCUMBRANCE_G", "COLOR_ENCUMBRANCE_B")

local iconsBelowBars = getToggle("ICONS_BELOW_BARS")
local showEncumb     = getToggle("SHOW_ENCUMBRANCE")
local BOTTOM_PAD     = iconsBelowBars and 42 or 25

local texCache = {}
local function tex(path)
    if not texCache[path] then texCache[path] = ui.texture { path = path } end
    return texCache[path]
end

local rHp, rFat, rMag, rEnc          = 1, 1, 1, 0
local prevRHp, prevRFat, prevRMag, prevREnc = 1, 1, 1, 0
local lastFillHp, lastFillFat, lastFillMag = -1, -1, -1
local lastFillEncH, lastFillEncV           = -1, -1

local timer         = 0
local hudCheckTimer = 0
local animating     = true
local hudVisible    = true

local root = ui.create {
    layer = "HUD",
    type  = ui.TYPE.Widget,
    props = { relativeSize = util.vector2(1, 1) },
    content = ui.content {}
}

local function makeBar(color)
    local container = ui.create {
        type = ui.TYPE.Widget,
        props = {
            size             = util.vector2(FRAME_W, FRAME_H),
            relativePosition = util.vector2(0.0, 1.0),
            anchor           = util.vector2(0.0, 1.0),
            position         = util.vector2(SIDE_PAD, 0),
            alpha            = 1,
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

local cHp,  fillHL, fillHR = makeBar(COLOR_HP)
local cMag, fillML, fillMR = makeBar(COLOR_MAGICKA)
local cFat, fillFL, fillFR = makeBar(COLOR_FATIGUE)

root.layout.content:add(cHp)
root.layout.content:add(cMag)
root.layout.content:add(cFat)

-- encumbrance horizontal
local encHcontainer = ui.create {
    type = ui.TYPE.Widget,
    props = {
        size             = util.vector2(ESUB_FR_W, ESUB_FR_H),
        relativePosition = util.vector2(0.0, 1.0),
        anchor           = util.vector2(0.0, 1.0),
        position         = util.vector2(0, 0),
        visible          = false,
    },
    content = ui.content {}
}
local encHcx = ESUB_FR_W / 2
local encHcy = ESUB_FR_H / 2
local encHbg = ui.create {
    type = ui.TYPE.Image,
    props = { resource = tex(TEX_BG), size = util.vector2(ESUB_W, SUB_H), position = util.vector2(encHcx, encHcy), anchor = util.vector2(0.5, 0.5) }
}
local encHfill = ui.create {
    type = ui.TYPE.Image,
    props = { resource = tex(TEX_FILL), size = util.vector2(0, SUB_H), position = util.vector2(ESUB_FR_PADX, encHcy), anchor = util.vector2(0, 0.5), color = COLOR_ENCUMBRANCE }
}
local encHframe = ui.create {
    type = ui.TYPE.Image,
    props = { resource = tex(TEX_ENC_FRAME), size = util.vector2(ESUB_FR_W, ESUB_FR_H), color = COLOR_FRAME }
}
encHcontainer.layout.content:add(encHbg)
encHcontainer.layout.content:add(encHfill)
encHcontainer.layout.content:add(encHframe)

-- encumbrance vertical
local encVcontainer = ui.create {
    type = ui.TYPE.Widget,
    props = {
        size             = util.vector2(EVBAR_W + 2 * EVBAR_FR_PADX, 0),
        relativePosition = util.vector2(0.0, 1.0),
        anchor           = util.vector2(0.0, 1.0),
        position         = util.vector2(0, 0),
        visible          = false,
    },
    content = ui.content {}
}
local encVbg = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource         = tex(TEX_BG),
        size             = util.vector2(EVBAR_W, 0),
        relativePosition = util.vector2(0.5, 0.5),
        anchor           = util.vector2(0.5, 0.5),
        position         = util.vector2(0, 0),
    }
}
local encVfill = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource         = tex(TEX_FILL),
        size             = util.vector2(EVBAR_W, 0),
        relativePosition = util.vector2(0.5, 1),
        anchor           = util.vector2(0.5, 1),
        position         = util.vector2(0, 0),
        color            = COLOR_ENCUMBRANCE,
    }
}
local encVframe = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = tex(TEX_ENC_FRAMEV),
        size     = util.vector2(EVBAR_W + 2 * EVBAR_FR_PADX, 0),
        position = util.vector2(0, 0),
        anchor   = util.vector2(0, 0),
        color    = COLOR_FRAME,
    }
}
encVcontainer.layout.content:add(encVbg)
encVcontainer.layout.content:add(encVfill)
encVcontainer.layout.content:add(encVframe)

root.layout.content:add(encHcontainer)
root.layout.content:add(encVcontainer)

-- layout positioning
local vRangeH = 0

local function applyLayout()
    local STEP  = FRAME_H + BAR_GAP
    local yBase = -(BOTTOM_PAD + SUB_HF / 2 + (FRAME_H - BAR_H) / 2)
    local yHp   = yBase - STEP * 2
    local yMag  = yBase - STEP
    local yFat  = yBase

    cHp.layout.props.position  = util.vector2(SIDE_PAD, yHp)
    cMag.layout.props.position = util.vector2(SIDE_PAD, yMag)
    cFat.layout.props.position = util.vector2(SIDE_PAD, yFat)
    cHp:update();  cMag:update();  cFat:update()

    if showEncumb then
        if not iconsBelowBars then
            -- horizontal sub-bar under fatigue, single fill, anchored left
            local subTopY = yFat + FRAME_H + ESUB_GAP
            local subX    = SIDE_PAD + (FRAME_W - ESUB_FR_W) / 2
            encHcontainer.layout.props.position = util.vector2(subX, subTopY)
            encHcontainer.layout.props.visible  = true
            encVcontainer.layout.props.visible  = false
            vRangeH = 0
        else
            local topY    = yHp - FRAME_H + SUB_HF
            local bottomY = yFat + FRAME_H
            local height  = bottomY - topY
            local padY    = math.floor(height * (1.193 - 1) / 2)
            local frH     = height + 2 * padY
            local frW     = EVBAR_W + 2 * EVBAR_FR_PADX
            local vX      = SIDE_PAD + FRAME_W + EVBAR_GAP - EVBAR_FR_PADX
            encVcontainer.layout.props.position = util.vector2(vX, bottomY + padY)
            encVcontainer.layout.props.size     = util.vector2(frW, frH)
            encVcontainer.layout.props.visible  = true
            encVbg.layout.props.size            = util.vector2(EVBAR_W, height)
            encVfill.layout.props.position      = util.vector2(0, -padY)
            encVframe.layout.props.size         = util.vector2(frW, frH)
            encHcontainer.layout.props.visible  = false
            vRangeH = height
        end
    else
        encHcontainer.layout.props.visible = false
        encVcontainer.layout.props.visible = false
        vRangeH = 0
    end
    encHcontainer:update()
    encVcontainer:update()

    lastFillEncH = -1
    lastFillEncV = -1
    animating    = true
end

local function applyColors()
    fillHL.layout.props.color   = COLOR_HP
    fillHR.layout.props.color   = COLOR_HP
    fillML.layout.props.color   = COLOR_MAGICKA
    fillMR.layout.props.color   = COLOR_MAGICKA
    fillFL.layout.props.color   = COLOR_FATIGUE
    fillFR.layout.props.color   = COLOR_FATIGUE
    encHfill.layout.props.color = COLOR_ENCUMBRANCE
    encVfill.layout.props.color = COLOR_ENCUMBRANCE
    fillHL:update();   fillHR:update()
    fillML:update();   fillMR:update()
    fillFL:update();   fillFR:update()
    encHfill:update(); encVfill:update()
    lastFillHp   = -1
    lastFillFat  = -1
    lastFillMag  = -1
    lastFillEncH = -1
    lastFillEncV = -1
    animating    = true
end

applyLayout()


colorsSection:subscribe(async:callback(function(_, key)
    if key == nil or key:find("^COLOR_HP_") then
        COLOR_HP = readColor("COLOR_HP_R", "COLOR_HP_G", "COLOR_HP_B")
    end
    if key == nil or key:find("^COLOR_FATIGUE_") then
        COLOR_FATIGUE = readColor("COLOR_FATIGUE_R", "COLOR_FATIGUE_G", "COLOR_FATIGUE_B")
    end
    if key == nil or key:find("^COLOR_MAGICKA_") then
        COLOR_MAGICKA = readColor("COLOR_MAGICKA_R", "COLOR_MAGICKA_G", "COLOR_MAGICKA_B")
    end
    if key == nil or key:find("^COLOR_ENCUMBRANCE_") then
        COLOR_ENCUMBRANCE = readColor("COLOR_ENCUMBRANCE_R", "COLOR_ENCUMBRANCE_G", "COLOR_ENCUMBRANCE_B")
    end
    applyColors()
end))

togglesSection:subscribe(async:callback(function(_, key)
    if key == nil or key == "ICONS_BELOW_BARS" then
        iconsBelowBars = getToggle("ICONS_BELOW_BARS")
        BOTTOM_PAD     = iconsBelowBars and 42 or 25
    end
    if key == nil or key == "SHOW_ENCUMBRANCE" then
        showEncumb = getToggle("SHOW_ENCUMBRANCE")
    end
    applyLayout()
end))

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

local function updateEncH(ratio)
    local iFill = math.floor(ESUB_W * ratio)
    if iFill == lastFillEncH then return false end
    encHfill.layout.props.size = util.vector2(iFill, SUB_HF)
    encHfill:update()
    encHcontainer:update()
    lastFillEncH = iFill
    return true
end

local function updateEncV(ratio)
    local iFill = math.floor(vRangeH * ratio)
    if iFill == lastFillEncV then return false end
    encVfill.layout.props.size = util.vector2(EVBAR_W, iFill)
    encVfill:update()
    encVcontainer:update()
    lastFillEncV = iFill
    return true
end

local function computeEncumbRatio()
    local cur = types.Actor.getEncumbrance(self.object)
    local cap = types.Actor.getCapacity(self.object)
    if not cap or cap <= 0 then return 0 end
    return math.max(0, math.min(1, cur / cap))
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
        local newEnc = showEncumb and computeEncumbRatio() or 0
        if newHp ~= prevRHp or newFat ~= prevRFat or newMag ~= prevRMag or newEnc ~= prevREnc then
            rHp, rFat, rMag, rEnc = newHp, newFat, newMag, newEnc
            prevRHp, prevRFat, prevRMag, prevREnc = newHp, newFat, newMag, newEnc
            animating = true
        end
    end

    if not animating then return end

    local ch1, ch2, ch3
    lastFillHp,  ch1 = updateBar(fillHL, fillHR, cHp,  HALF * rHp,  lastFillHp)
    lastFillFat, ch2 = updateBar(fillFL, fillFR, cFat, HALF * rFat, lastFillFat)
    lastFillMag, ch3 = updateBar(fillML, fillMR, cMag, HALF * rMag, lastFillMag)

    local ch4 = false
    if showEncumb then
        if iconsBelowBars then
            ch4 = updateEncV(rEnc)
        else
            ch4 = updateEncH(rEnc)
        end
    end

    if not ch1 and not ch2 and not ch3 and not ch4 then
        animating = false
    end
end

return { engineHandlers = { onFrame = onFrame } }