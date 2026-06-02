local ui = require('openmw.ui')
local util = require('openmw.util')
local core = require('openmw.core')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local v2 = util.vector2

local welcomeData = storage.playerSection("SkyrimCompass_Welcome")
local settingsData = storage.playerSection("SkyrimCompass_Settings")

local whiteTex = ui.texture { path = "textures/icons/skyrim_compass/bar_white.dds" }
local questTex = ui.texture { path = "textures/icons/skyrim_compass/quest_marker.dds" }
local doorTex  = ui.texture { path = "textures/icons/skyrim_compass/quest_door.dds" }
local compassBarTex = ui.texture { path = "textures/icons/skyrim_compass/compass_bar.dds" }

local borderTopTex    = ui.texture { path = 'textures/menu_thin_border_top.dds' }
local borderBottomTex = ui.texture { path = 'textures/menu_thin_border_bottom.dds' }
local borderLeftTex   = ui.texture { path = 'textures/menu_thin_border_left.dds' }
local borderRightTex  = ui.texture { path = 'textures/menu_thin_border_right.dds' }
local borderTLTex     = ui.texture { path = 'textures/menu_thin_border_top_left_corner.dds' }
local borderTRTex     = ui.texture { path = 'textures/menu_thin_border_top_right_corner.dds' }
local borderBLTex     = ui.texture { path = 'textures/menu_thin_border_bottom_left_corner.dds' }
local borderBRTex     = ui.texture { path = 'textures/menu_thin_border_bottom_right_corner.dds' }

local GOLD        = util.color.rgb(0.88, 0.78, 0.55)
local GOLD_BRIGHT = util.color.rgb(0.96, 0.88, 0.65)
local GOLD_DIM    = util.color.rgb(0.65, 0.58, 0.40)
local TEXT_CLR    = util.color.rgb(0.82, 0.78, 0.68)
local HEADER_CLR  = util.color.rgb(0.92, 0.82, 0.58)
local PANEL_BG    = util.color.rgb(0.04, 0.035, 0.025)
local SEP_CLR     = util.color.rgb(0.42, 0.36, 0.22)
local SHADOW      = util.color.rgb(0, 0, 0)
local HINT_CLR    = util.color.rgb(0.55, 0.50, 0.40)

local B = 2

local popupElement = nil
local dismissed = false
local startTime = nil
local fadeAlpha = 0

local SHOW_DELAY = 3.0
local FADE_IN = 0.8
local HOLD_TIME = 30.0
local FADE_OUT = 1.2

local state = "waiting"
local stateTimer = 0

local function getScreenSize()
    local ok, result = pcall(function()
        local layerId = ui.layers.indexOf("HUD")
        local w = ui.layers[layerId].size.x
        local ss = ui.screenSize()
        local scale = ss.x / w
        return ss:ediv(v2(scale, scale))
    end)
    if ok then return result end
    return ui.screenSize()
end

local function destroyPopup()
    if popupElement then
        popupElement:destroy()
        popupElement = nil
    end
end

local function dismiss()
    if dismissed then return end
    dismissed = true
    welcomeData:set("shown", true)
    pcall(function() settingsData:set("showWelcomeAgain", false) end)
    state = "fadeout"
    stateTimer = 0
end

local function centered(text, size, color)
    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            autoSize = true,
        },
        content = ui.content {
            { type = ui.TYPE.Text, props = {
                text = text,
                textSize = size,
                textColor = color or TEXT_CLR,
                textShadow = true,
                textShadowColor = SHADOW,
            }},
        },
    }
end

local function bullet(text, size, icon)
    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            autoSize = true,
        },
        content = ui.content {
            { type = ui.TYPE.Image, props = {
                resource = icon or questTex,
                size = v2(size * 0.8, size * 0.8),
                color = GOLD,
                alpha = 0.5,
            }},
            { type = ui.TYPE.Widget, props = { size = v2(12, 1) } },
            { type = ui.TYPE.Text, props = {
                text = text,
                textSize = size,
                textColor = TEXT_CLR,
                textShadow = true,
                textShadowColor = SHADOW,
            }},
        },
    }
end

local function gap(h)
    return { type = ui.TYPE.Widget, props = { size = v2(0, h) } }
end

local function ornSep(w)
    local lineW = math.floor(w * 0.36)
    return {
        type = ui.TYPE.Flex,
        props = { horizontal = true, arrange = ui.ALIGNMENT.Center, align = ui.ALIGNMENT.Center, autoSize = true },
        content = ui.content {
            { type = ui.TYPE.Image, props = {
                resource = whiteTex, size = v2(lineW, 1), color = SEP_CLR, alpha = 0.4,
            }},
            { type = ui.TYPE.Widget, props = { size = v2(14, 1) } },
            { type = ui.TYPE.Image, props = {
                resource = questTex, size = v2(20, 20), color = SEP_CLR, alpha = 0.45,
            }},
            { type = ui.TYPE.Widget, props = { size = v2(14, 1) } },
            { type = ui.TYPE.Image, props = {
                resource = whiteTex, size = v2(lineW, 1), color = SEP_CLR, alpha = 0.4,
            }},
        },
    }
end

local function thinSep(w)
    return {
        type = ui.TYPE.Flex,
        props = { horizontal = true, arrange = ui.ALIGNMENT.Center, autoSize = true },
        content = ui.content {
            { type = ui.TYPE.Image, props = {
                resource = whiteTex, size = v2(w, 1), color = SEP_CLR, alpha = 0.3,
            }},
        },
    }
end

local function addBorders(tbl)
    tbl[#tbl+1] = { type = ui.TYPE.Image, props = {
        resource = borderTopTex, tileH = true, tileV = false,
        relativePosition = v2(0, 0), position = v2(B*2, 0),
        relativeSize = v2(1, 0), size = v2(-B*4, B),
    }}
    tbl[#tbl+1] = { type = ui.TYPE.Image, props = {
        resource = borderBottomTex, tileH = true, tileV = false,
        relativePosition = v2(0, 1), position = v2(B*2, -B),
        relativeSize = v2(1, 0), size = v2(-B*4, B),
    }}
    tbl[#tbl+1] = { type = ui.TYPE.Image, props = {
        resource = borderLeftTex, tileH = false, tileV = true,
        relativePosition = v2(0, 0), position = v2(0, B*2),
        relativeSize = v2(0, 1), size = v2(B, -B*4),
    }}
    tbl[#tbl+1] = { type = ui.TYPE.Image, props = {
        resource = borderRightTex, tileH = false, tileV = true,
        relativePosition = v2(1, 0), position = v2(-B, B*2),
        relativeSize = v2(0, 1), size = v2(B, -B*4),
    }}
    tbl[#tbl+1] = { type = ui.TYPE.Image, props = {
        resource = borderTLTex,
        relativePosition = v2(0, 0), size = v2(B*2, B*2),
    }}
    tbl[#tbl+1] = { type = ui.TYPE.Image, props = {
        resource = borderTRTex,
        relativePosition = v2(1, 0), position = v2(-B*2, 0), size = v2(B*2, B*2),
    }}
    tbl[#tbl+1] = { type = ui.TYPE.Image, props = {
        resource = borderBLTex,
        relativePosition = v2(0, 1), position = v2(0, -B*2), size = v2(B*2, B*2),
    }}
    tbl[#tbl+1] = { type = ui.TYPE.Image, props = {
        resource = borderBRTex,
        relativePosition = v2(1, 1), position = v2(-B*2, -B*2), size = v2(B*2, B*2),
    }}
end

local function buildPopup()
    local ss = getScreenSize()
    local panelW = math.min(960, math.floor(ss.x * 0.88))
    local panelH = math.min(1020, math.floor(ss.y * 0.94))
    local panelX = math.floor((ss.x - panelW) / 2)
    local panelY = math.floor((ss.y - panelH) / 2)
    local contentW = panelW - 80
    local iconS = 50

    local panelChildren = {
        { type = ui.TYPE.Image, props = {
            position = v2(0, 0), size = v2(panelW, panelH),
            resource = whiteTex, color = PANEL_BG,
        }},
        { type = ui.TYPE.Image, props = {
            position = v2(0, 0), size = v2(panelW, 6),
            resource = compassBarTex, alpha = 0.15,
        }},
        { type = ui.TYPE.Image, props = {
            position = v2(0, panelH - 6), size = v2(panelW, 6),
            resource = compassBarTex, alpha = 0.15,
        }},
        { type = ui.TYPE.Flex, props = {
            position = v2(40, 0),
            size = v2(contentW, panelH),
            horizontal = false,
            align = ui.ALIGNMENT.Center,
        }, content = ui.content {
            gap(38),

            { type = ui.TYPE.Flex, props = {
                horizontal = true, arrange = ui.ALIGNMENT.Center,
                align = ui.ALIGNMENT.Center, autoSize = true,
            }, content = ui.content {
                { type = ui.TYPE.Image, props = {
                    resource = questTex, size = v2(iconS, iconS), color = GOLD, alpha = 0.8,
                }},
                { type = ui.TYPE.Widget, props = { size = v2(18, 1) } },
                { type = ui.TYPE.Text, props = {
                    text = "QUEST MARKERS PLUS",
                    textSize = 52, textColor = GOLD_BRIGHT,
                    textShadow = true, textShadowColor = SHADOW,
                }},
                { type = ui.TYPE.Widget, props = { size = v2(18, 1) } },
                { type = ui.TYPE.Image, props = {
                    resource = questTex, size = v2(iconS, iconS), color = GOLD, alpha = 0.8,
                }},
            }},
            gap(4),
            centered("OpenMW", 34, GOLD_DIM),

            gap(14),
            thinSep(contentW),
            gap(18),

            centered("Thanks for downloading!", 44, GOLD),
            gap(8),
            centered("Adds a compass bar with quest markers,", 30, TEXT_CLR),
            gap(2),
            centered("city icons, and points of interest to your HUD.", 30, TEXT_CLR),

            gap(16),
            ornSep(contentW),
            gap(16),

            centered("WHAT'S INCLUDED", 40, HEADER_CLR),
            gap(12),
            bullet("Compass bar with directions and nearby cities", 30),
            gap(8),
            bullet("Quest markers on the compass and world map", 30),
            gap(8),
            bullet("Pop-up when you enter a new area", 30),
            gap(8),
            bullet("Custom colors, size, and position", 30),
            gap(8),
            bullet("Press [ O ] to toggle everything on/off", 30, doorTex),

            gap(16),
            ornSep(contentW),
            gap(16),

            centered("HOW TO CUSTOMIZE", 40, HEADER_CLR),
            gap(12),
            centered("Escape > Options > Scripts > Quest Markers Plus", 30, TEXT_CLR),

            gap(10),
            centered("Marker color changes need a save reload to show", 22, HINT_CLR),
            centered("on floating icons above quest objects.", 22, HINT_CLR),

            gap(16),
            ornSep(contentW),
            gap(14),

            centered("If you like it, drop an endorsement", 30, GOLD_DIM),
            gap(2),
            centered("on Nexus - it really helps!", 30, GOLD_DIM),

            gap(16),
            thinSep(contentW * 0.35),
            gap(14),

            centered("Press any key to close", 34, GOLD),
            gap(32),
        }},
    }

    addBorders(panelChildren)

    popupElement = ui.create({
        layer = "HUD",
        type = ui.TYPE.Widget,
        props = {
            position = v2(panelX, panelY),
            size = v2(panelW, panelH),
            visible = true,
            alpha = 0,
        },
        content = ui.content(panelChildren),
    })
end

local function shouldShow()
    local showAgain = settingsData:get("showWelcomeAgain")
    if showAgain then return true end
    if not welcomeData:get("shown") then return true end
    return false
end

local function resetAndShow()
    dismissed = false
    destroyPopup()
    buildPopup()
    state = "fadein"
    stateTimer = 0
end

return {
    engineHandlers = {
        onFrame = function(dt)
            if state == "done" then
                if shouldShow() then
                    if I.UI.getMode() == nil then
                        resetAndShow()
                    end
                end
                return
            end

            if state == "waiting" then
                if not shouldShow() then
                    state = "done"
                    return
                end

                if I.UI.getMode() ~= nil then return end

                if not startTime then startTime = core.getRealTime() end
                if core.getRealTime() - startTime < SHOW_DELAY then return end

                buildPopup()
                state = "fadein"
                stateTimer = 0
                return
            end

            if state == "fadein" then
                stateTimer = stateTimer + dt
                fadeAlpha = math.min(1, stateTimer / FADE_IN)
                if popupElement then
                    popupElement.layout.props.alpha = fadeAlpha
                    popupElement:update()
                end
                if stateTimer >= FADE_IN then
                    state = "hold"
                    stateTimer = 0
                end
                return
            end

            if state == "hold" then
                stateTimer = stateTimer + dt
                if stateTimer >= HOLD_TIME then
                    dismiss()
                end
                return
            end

            if state == "fadeout" then
                stateTimer = stateTimer + dt
                fadeAlpha = math.max(0, 1 - stateTimer / FADE_OUT)
                if popupElement then
                    popupElement.layout.props.alpha = fadeAlpha
                    popupElement:update()
                end
                if stateTimer >= FADE_OUT then
                    destroyPopup()
                    state = "done"
                end
                return
            end
        end,

        onInputAction = function(id)
            if state == "hold" or state == "fadein" then
                dismiss()
            end
        end,
    },
}
