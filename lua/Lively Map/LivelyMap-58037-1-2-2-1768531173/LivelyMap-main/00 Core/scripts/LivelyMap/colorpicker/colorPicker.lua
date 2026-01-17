--- This is from NitroInferno: https://gitlab.com/OpenMW/openmw/-/merge_requests/5010
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local auxUi = require('openmw_aux.ui')
local input = require('openmw.input')
local M = {}
local boxOffset = 25
local displayArea = ui.layers[1].size
local boxWidth = 600
local boxHeight = 500

local colorBoxElement = nil

-- =========================================================
-- Helper Functions
-- =========================================================

local function hsvToRgb(h, s, v)
    s = s / 100
    v = v / 100

    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c

    local r1, g1, b1

    if h < 60 then
        r1, g1, b1 = c, x, 0
    elseif h < 120 then
        r1, g1, b1 = x, c, 0
    elseif h < 180 then
        r1, g1, b1 = 0, c, x
    elseif h < 240 then
        r1, g1, b1 = 0, x, c
    elseif h < 300 then
        r1, g1, b1 = x, 0, c
    else
        r1, g1, b1 = c, 0, x
    end

    return
        math.floor((r1 + m) * 255),
        math.floor((g1 + m) * 255),
        math.floor((b1 + m) * 255)
end

local function rgbToHsv(r, g, b)
    -- Use floats in [0,1] for exact inversion
    r, g, b = r / 255, g / 255, b / 255

    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local delta = max - min

    local h = 0
    if delta == 0 then
        h = 0
    elseif max == r then
        h = 60 * (((g - b) / delta) % 6)
    elseif max == g then
        h = 60 * (((b - r) / delta) + 2)
    elseif max == b then
        h = 60 * (((r - g) / delta) + 4)
    end

    local s = 0
    if max ~= 0 then
        s = delta / max
    end

    local v = max

    -- scale S and V to 0-100 like your hsvToRgb
    s = s * 100
    v = v * 100

    return h, s, v
end

-- The function to unmap a color to x, y, z positions
local function unmapColorToPositions(color)
    -- accept either util.color userdata or table {r,g,b}
    local r, g, b = util.round(color.r * 255), util.round(color.g * 255), util.round(color.b * 255)

    -- Convert RGB to HSV
    local h, s, v = rgbToHsv(r, g, b)

    -- Remap HSV back to coordinates
    local x = util.round(util.remap(h, 0, 360, 0, 256))
    local y = util.round(util.remap(s, 100, 0, 0, 256)) -- notice S was inverted
    local z = util.round(util.remap(v, 100, 0, 0, 236)) -- V was ScrollButton.y

    return x, y, z
end

local function resetState(element, s)
    if element then
        element:destroy()
        element = nil
    end
    if s then
        s.confirmed = false
        s.capturedButton = nil
        s.capturedKey = nil
    end
end

local function transparentBorders(layout)
    for _, child in ipairs(layout.content or {}) do
        if child.template and child.template.props then
            child.template.props.alpha = 0
        end
    end
end

-- Create invisible border by copying thin box and hiding all border images
local invisibleBox = auxUi.deepLayoutCopy(I.MWUI.templates.box)
transparentBorders(invisibleBox)

local function makeLabelBox(name, text)
    return {
        template = invisibleBox,
        --type = ui.TYPE.Container,
        name = name .. "LabelBox",
        props = {},
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                name = name .. "LabelPad",
                props = {},
                content = ui.content {
                    {
                        template = I.MWUI.templates.textNormal,
                        name = name .. "Label",
                        props = {
                            text = text,
                            textAlignH = ui.ALIGNMENT.Start,
                            textAlignV = ui.ALIGNMENT.Center,
                        },
                        content = ui.content {},
                    },
                },
            },
        },
    }
end

--- Creates colorPicker msg box
local function makeColorPickerBox(value, set)
    -- ==== CONSTANTS & INITIAL COLOR ====
    local rsvMap       = ui.texture { path = 'textures/LivelyMap/HSV.dds' }
    local crossHairTex = ui.texture { path = 'textures/LivelyMap/stamps/circle-stroked.png' }
    local btnHeight    = 20
    local rr           = util.round(value.r * 255)
    local gg           = util.round(value.g * 255)
    local bb           = util.round(value.b * 255)
    local T_rgb        = { rr, gg, bb }
    -- current working color
    local newColor     = value

    -- text input buffers
    local lastRGBInput = nil
    local lastHexInput = nil

    -- widget references
    local hexInput, hexText, rgbText, crossHair, scrollButton, displayColorBox

    -- simple registry for RGB inputs
    local inputs       = {}

    -- initial picker positions from starting color
    local x, y, h      = unmapColorToPositions(value)

    ----------------------------------------------------------------
    -- HELPERS (use shared locals above)
    ----------------------------------------------------------------

    -- update hex/R/G/B displays + text labels + preview color box
    local function updateUIFromColor()
        local c = newColor or value
        local r = util.round(c.r * 255)
        local g = util.round(c.g * 255)
        local b = util.round(c.b * 255)
        local hex = c:asHex():upper()

        if hexInput then
            hexInput.props.text = hex
        end

        if inputs.R then inputs.R.props.text = tostring(r) end
        if inputs.G then inputs.G.props.text = tostring(g) end
        if inputs.B then inputs.B.props.text = tostring(b) end

        if hexText then
            hexText.props.text = "Hex: ##" .. hex
        end

        if rgbText then
            rgbText.props.text = string.format("R:%d G: %d B:%d", r, g, b)
        end

        if displayColorBox and displayColorBox.content and displayColorBox.content[1] then
            displayColorBox.content[1].props.color = c
        end

        if colorBoxElement then
            colorBoxElement:update()
        end
    end

    local function onRGBTextChanged(text)
        lastRGBInput = text
    end

    local function makeOnRGBFocusLoss(component) -- "R", "G", or "B"
        return function()
            if not lastRGBInput then return end
            local ok, parsed = pcall(function()
                return tonumber(lastRGBInput)
            end)

            local baseColor = newColor or value

            -- invalid input -> restore old value
            if not ok or not parsed then
                local key = string.lower(component) -- "r", "g", "b"
                local fallback = util.round(baseColor[key] * 255)
                if inputs[component] then
                    inputs[component].props.text = tostring(fallback)
                end
                lastRGBInput = nil
                if colorBoxElement then colorBoxElement:update() end
                return
            end

            parsed = util.round(util.clamp(parsed, 0, 255))

            -- update just this component
            local r = baseColor.r
            local g = baseColor.g
            local b = baseColor.b

            if component == "R" then
                r = parsed / 255
            elseif component == "G" then
                g = parsed / 255
            elseif component == "B" then
                b = parsed / 255
            end

            newColor = util.color.rgb(r, g, b)

            -- update text boxes + labels + preview
            if inputs[component] then
                inputs[component].props.text = tostring(parsed)
            end

            -- reposition crosshair + scrollButton based on new color
            local px, py, ph = unmapColorToPositions(newColor)
            if crossHair then
                crossHair.props.position = util.vector2(px, py)
            end
            if scrollButton then
                scrollButton.props.position = util.vector2(266, ph)
            end

            updateUIFromColor()
            lastRGBInput = nil
        end
    end

    local function onHexTextChanged(text)
        lastHexInput = text
    end

    local function onHexFocusLoss()
        if not lastHexInput then return end
        -- Try parsing exactly what the user typed
        local ok, parsedColor = pcall(util.color.hex, lastHexInput)

        if not ok or not parsedColor then
            -- Revert to existing color
            local c = newColor or value
            if hexInput then
                hexInput.props.text = c:asHex() -- returns uppercase without '#'
            end
            lastHexInput = nil
            if colorBoxElement then colorBoxElement:update() end
            return
        end
        -- Apply new color
        newColor = parsedColor
        -- Update UI handles
        local px, py, ph = unmapColorToPositions(newColor)

        if crossHair then
            crossHair.props.position = util.vector2(px, py)
        end
        if scrollButton then
            scrollButton.props.position = util.vector2(266, ph)
        end

        updateUIFromColor()
        lastHexInput = nil
    end

    ----------------------------------------------------------------
    -- NEW: INPUT BOX CONSTRUCTOR
    ----------------------------------------------------------------
    local function makeInputBox(i, letter, currColor)
        local upper = string.upper(letter)
        local inputWidget = {
            template = I.MWUI.templates.textEditLine,
            name = upper,
            props = {
                text = tostring(currColor),
                size = util.vector2(65, 0),
                textAlignH = ui.ALIGNMENT.Center,
                textAlignV = ui.ALIGNMENT.Center,
            },
            content = ui.content {},
        }
        inputWidget.events = {
            textChanged = async:callback(onRGBTextChanged),
            focusLoss   = async:callback(makeOnRGBFocusLoss(upper)),
        }
        local box = {
            template = I.MWUI.templates.box,
            name = upper .. "Box",
            props = {
                position = util.vector2(45, 60 + boxOffset * i),
                relativePosition = util.vector2(0.55, 0.05),
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.padding,
                    name = upper .. "Pad",
                    content = ui.content { inputWidget },
                }
            }
        }
        return inputWidget, box
    end

    ----------------------------------------------------------------
    -- BLOCKER
    ----------------------------------------------------------------
    local blocker = {
        name = 'Blocker',
        type = ui.TYPE.Widget,
        props = {
            size = displayArea,
        },
        content = ui.content {},
        events = {
            mousePress = async:callback(function()
                if colorBoxElement then
                    colorBoxElement:destroy()
                    colorBoxElement = nil
                end
                newColor = nil
            end),
        },
    }

    ----------------------------------------------------------------
    -- OK / CANCEL BUTTONS
    ----------------------------------------------------------------
    local okBtn = {
        template = I.MWUI.templates.boxSolid,
        name = nil,
        props = {
            size = util.vector2(120, 40),
            position = nil,
            relativePosition = util.vector2(0.75, 0.88),
            anchor = util.vector2(0.5, 0.5),
        },
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                props = {},
                content = ui.content {
                    {
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = "  OK  ",
                            size = util.vector2(120, 40),
                            textAlignH = ui.ALIGNMENT.Center,
                            textAlignV = ui.ALIGNMENT.Center,
                        },
                        content = ui.content {},
                    },
                },
            },
        },
        events = {
            mousePress = async:callback(function()
                if newColor then
                    set(newColor)
                end
                resetState(colorBoxElement)
                colorBoxElement = nil
            end),
        },
    }

    local cancelBtn = {
        template = I.MWUI.templates.boxSolid,
        name = nil,
        props = {
            size = util.vector2(120, 40),
            position = nil,
            relativePosition = util.vector2(0.25, 0.88),
            anchor = util.vector2(0.5, 0.5),
        },
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                props = {},
                content = ui.content {
                    {
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = "Cancel",
                            size = util.vector2(120, 40),
                            textAlignH = ui.ALIGNMENT.Center,
                            textAlignV = ui.ALIGNMENT.Center,
                        },
                        content = ui.content {},
                    },
                },
            },
        },
        events = {
            mousePress = async:callback(function()
                resetState(colorBoxElement)
                colorBoxElement = nil
                newColor = nil
            end),
        },
    }

    ----------------------------------------------------------------
    -- HSV MAP IMAGE
    ----------------------------------------------------------------
    local rsvMapImage = {
        type = ui.TYPE.Image,
        name = 'rsvMap',
        props = {
            size = util.vector2(256, 256),
            position = util.vector2(0, 0),
            relativePosition = util.vector2(0.05, 0.05),
            anchor = nil,
            visible = true,
            alpha = 1.0,
            inheritAlpha = false,
            resource = rsvMap,
            color = util.color.rgb(1, 1, 1),
        },
        content = ui.content {},
        userData = {
            doDrag = false,
            lastMousePos = nil,
            truePosition = nil,
        },
        events = {
            mousePress = async:callback(function(coord, layout)
                layout.userData.lastMousePos = coord.offset
                if layout.userData.doDrag then return end

                local mx = coord.offset.x
                local my = coord.offset.y

                if mx < 0 then mx = 0 elseif mx > 256 then mx = 256 end
                if my < 0 then my = 0 elseif my > 256 then my = 256 end

                if crossHair then
                    crossHair.props.position = util.vector2(mx, my)
                end

                local h = util.round(util.remap(mx, 0, 256, 0, 360))
                local s = util.round(util.remap(my, 0, 256, 100, 0))
                local v = scrollButton and scrollButton.props.position.y or h
                v = util.round(util.remap(v, 0, 236, 100, 0))

                local r, g, b = hsvToRgb(h, s, v)
                newColor = util.color.rgb(r / 255, g / 255, b / 255)

                updateUIFromColor()
                layout.userData.doDrag = true
            end),

            mouseRelease = async:callback(function(_, layout)
                layout.userData.doDrag = false
            end),

            mouseMove = async:callback(function(coord, layout)
                if not layout.userData.doDrag then return end

                local mx = coord.offset.x
                local my = coord.offset.y

                if mx < 0 then mx = 0 elseif mx > 256 then mx = 256 end
                if my < 0 then my = 0 elseif my > 256 then my = 256 end

                if crossHair then
                    crossHair.props.position = util.vector2(mx, my)
                end

                layout.userData.lastMousePos = coord.offset

                local h = util.round(util.remap(mx, 0, 256, 0, 360))
                local s = util.round(util.remap(my, 0, 256, 100, 0))
                local v = scrollButton and scrollButton.props.position.y or h
                v = util.round(util.remap(v, 0, 236, 100, 0))

                local r, g, b = hsvToRgb(h, s, v)
                newColor = util.color.rgb(r / 255, g / 255, b / 255)

                updateUIFromColor()
            end),
        },
    }

    ----------------------------------------------------------------
    -- CROSSHAIR
    ----------------------------------------------------------------
    crossHair = {
        type = ui.TYPE.Image,
        name = "crossHair",
        props = {
            size = util.vector2(20, 20),
            position = util.vector2(x, y),
            relativePosition = util.vector2(0.05, 0.05),
            anchor = util.vector2(0.5, 0.5),
            visible = true,
            alpha = 1.0,
            inheritAlpha = false,
            resource = crossHairTex,
            color = util.color.rgb(0, 0, 0),
        },
        content = ui.content {},
        userData = {
            doDrag = false,
            lastMousePos = nil,
            truePosition = nil,
            oneShot = nil,
        },
        events = {
            mousePress = async:callback(function(coord, layout)
                layout.userData.doDrag = true
                layout.userData.lastMousePos = coord.position
                layout.userData.oneShot = nil
            end),

            mouseRelease = async:callback(function(_, layout)
                layout.userData.doDrag = false
                layout.userData.oneShot = nil
            end),

            mouseMove = async:callback(function(coord, layout)
                if not layout.userData.doDrag then return end

                local props = layout.props
                local dxy = coord.position - layout.userData.lastMousePos

                if not layout.userData.oneShot then -- Required to init truePosition correctly
                    layout.userData.oneShot = true
                    layout.userData.truePosition = props.position
                end

                layout.userData.truePosition = layout.userData.truePosition + dxy

                local mx = layout.userData.truePosition.x
                local my = layout.userData.truePosition.y

                if mx < 0 then mx = 0 elseif mx > 256 then mx = 256 end
                if my < 0 then my = 0 elseif my > 256 then my = 256 end

                props.position = util.vector2(mx, my)
                layout.userData.lastMousePos = coord.position

                local h = util.round(util.remap(mx, 0, 256, 0, 360))
                local s = util.round(util.remap(my, 0, 256, 100, 0))
                local v = scrollButton and scrollButton.props.position.y or h
                v = util.round(util.remap(v, 0, 236, 100, 0))

                local r, g, b = hsvToRgb(h, s, v)
                newColor = util.color.rgb(r / 255, g / 255, b / 255)

                updateUIFromColor()
            end),
        },
    }

    ----------------------------------------------------------------
    -- SCROLL TRACK & BUTTON
    ----------------------------------------------------------------
    local scrollTrack = {
        type = ui.TYPE.Image,
        name = "ScrollTrack",
        props = {
            size = util.vector2(10, 256),
            position = util.vector2(266, 0),
            relativePosition = util.vector2(0.05, 0.05),
            anchor = util.vector2(0, 0),
            visible = true,
            alpha = 1.0,
            inheritAlpha = false,
            resource = ui.texture { path = 'white' },
            color = util.color.rgb(52 / 255, 52 / 255, 52 / 255),
        },
        content = ui.content {},
    }

    scrollButton = {
        type = ui.TYPE.Image,
        name = "ScrollButton",
        props = {
            size = util.vector2(10, btnHeight),
            position = util.vector2(266, h),
            relativePosition = util.vector2(0.05, 0.05),
            anchor = util.vector2(0, 0),
            visible = true,
            alpha = 1.0,
            inheritAlpha = false,
            resource = ui.texture { path = 'white' },
            color = util.color.rgb(203 / 255, 182 / 255, 140 / 255),
        },
        content = ui.content {},
        userData = {
            doDrag = false,
            lastMousePos = nil,
        },
        events = {
            mousePress = async:callback(function(coord, layout)
                layout.userData.doDrag = true
                layout.userData.lastMousePos = coord.position
            end),

            mouseRelease = async:callback(function(_, layout)
                layout.userData.doDrag = false
            end),

            mouseMove = async:callback(function(coord, layout)
                if not layout.userData.doDrag then return end

                local props = layout.props
                local dy = coord.position.y - layout.userData.lastMousePos.y
                props.position = props.position + util.vector2(0, dy)
                props.position = util.vector2(props.position.x, util.clamp(props.position.y, 0, 236))
                layout.userData.lastMousePos = coord.position

                local mx = crossHair and crossHair.props.position.x or 0
                local my = crossHair and crossHair.props.position.y or 0

                local h = util.round(util.remap(mx, 0, 256, 0, 360))
                local s = util.round(util.remap(my, 0, 256, 100, 0))
                local v = props.position.y
                v = util.round(util.remap(v, 0, 236, 100, 0))

                local r, g, b = hsvToRgb(h, s, v)
                newColor = util.color.rgb(r / 255, g / 255, b / 255)

                updateUIFromColor()
            end),
        },
    }

    ----------------------------------------------------------------
    -- DISPLAY COLOR BOX
    ----------------------------------------------------------------
    displayColorBox = {
        template = I.MWUI.templates.boxThick,
        name = "displayColorBox",
        props = {
            size = util.vector2(30, 30),
            position = util.vector2(0, 0),
            relativePosition = util.vector2(0.55, 0.05),
            anchor = util.vector2(0, 0),
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                name = "displayColor",
                props = {
                    size = util.vector2(30, 30),
                    position = util.vector2(0, 0),
                    relativePosition = util.vector2(0.55, 0.05),
                    anchor = util.vector2(0, 0),
                    visible = true,
                    alpha = 1.0,
                    inheritAlpha = false,
                    resource = ui.texture { path = 'white' },
                    color = value,
                },
                content = ui.content {},
            },
        },
    }

    ----------------------------------------------------------------
    -- HEX / RGB TEXT LABELS
    ----------------------------------------------------------------
    hexText = {
        template = I.MWUI.templates.textNormal,
        name = "hexText",
        props = {
            position = util.vector2(45, 0),
            relativePosition = util.vector2(0.55, 0.05),
            anchor = util.vector2(0, -0.5),
            text = "Hex: ##" .. value:asHex():upper(),
        },
        content = ui.content {},
    }

    rgbText = {
        template = I.MWUI.templates.textNormal,
        name = "rgbText",
        props = {
            position = util.vector2(45, 15),
            relativePosition = util.vector2(0.55, 0.05),
            anchor = util.vector2(0, -0.5),
            text = string.format("R:%d G: %d B:%d", rr, gg, bb),
        },
        content = ui.content {},
    }

    ----------------------------------------------------------------
    -- HEX / R / G / B EDIT LINES
    ----------------------------------------------------------------
    hexInput = {
        template = I.MWUI.templates.textEditLine,
        name = "hexEditLine",
        props = {
            text = value:asHex(),
            size = util.vector2(65, 0),
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
        },
        content = ui.content {},
    }

    local hexEditLineBox = {
        template = I.MWUI.templates.box,
        name = "hexEditLineBox",
        props = {
            position = util.vector2(45, 60),
            relativePosition = util.vector2(0.55, 0.05),
        },
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                name = "hexEditLinePad",
                props = {},
                content = ui.content { hexInput },
            },
        },
    }
    ----------------------------------------------------------------
    -- NEW: BUILD R/G/B INPUT BOXES USING LOOP
    ----------------------------------------------------------------
    local T_inputBoxes = {}

    for i, letter in ipairs { 'R', 'G', 'B' } do
        local inp, box = makeInputBox(i, letter, T_rgb[i])
        inputs[letter] = inp -- fill inputs registry
        T_inputBoxes[letter] = box
    end

    -- label boxes
    local labels            = {
        R   = "R:",
        G   = "G:",
        B   = "B:",
        Hex = "Hex ##:",
    }

    local RLabelBox         = makeLabelBox("R", labels.R)
    local GLabelBox         = makeLabelBox("G", labels.G)
    local BLabelBox         = makeLabelBox("B", labels.B)
    local HexLabelBox       = makeLabelBox("Hex", labels.Hex)

    local labelsColumn      = {
        type = ui.TYPE.Flex,
        name = "labelsColumn",
        props = {
            horizontal = false,
            align = ui.ALIGNMENT.Start,
            arrange = ui.ALIGNMENT.End,
        },
        content = ui.content {
            RLabelBox,
            GLabelBox,
            BLabelBox,
            HexLabelBox,
        },
    }

    local inputsColumn      = {
        type = ui.TYPE.Flex,
        name = "inputsColumn",
        props = {
            horizontal = false,
            align = ui.ALIGNMENT.Start,
            arrange = ui.ALIGNMENT.Start,
        },
        content = ui.content {
            T_inputBoxes['R'],
            T_inputBoxes['G'],
            T_inputBoxes['B'],
            hexEditLineBox,
        },
    }

    local colorValueColumns = {
        type = ui.TYPE.Flex,
        name = "colorValueColumns",
        props = {
            horizontal = true,
            align = ui.ALIGNMENT.Start,
            arrange = ui.ALIGNMENT.Center,
            position = util.vector2(0, 0),
            relativePosition = util.vector2(0.55, 0.15),
        },
        content = ui.content {
            labelsColumn,
            I.MWUI.templates.interval,
            inputsColumn,
        },
    }

    ----------------------------------------------------------------
    -- ATTACH EVENTS TO INPUT WIDGETS
    ----------------------------------------------------------------
    hexInput.events         = {
        textChanged = async:callback(onHexTextChanged),
        focusLoss   = async:callback(onHexFocusLoss),
    }

    ----------------------------------------------------------------
    -- MAIN COLOR PICKER BOX
    ----------------------------------------------------------------
    local colorPickerBox    = {
        template = I.MWUI.templates.boxSolidThick,
        name = "colorPickerBox",
        props = {
            relativePosition = util.vector2(0.5, 0.5),
            anchor = util.vector2(0.5, 0.5),
            position = util.vector2(0, 0),
        },
        content = ui.content {
            {
                type = ui.TYPE.Widget,
                name = "sizeWrapper",
                props = {
                    size = util.vector2(boxWidth, boxHeight),
                },
                content = ui.content {
                    okBtn,
                    cancelBtn,
                    rsvMapImage,
                    crossHair,
                    scrollTrack,
                    scrollButton,
                    displayColorBox,
                    hexText,
                    rgbText,
                    colorValueColumns,
                },
            },
        },
    }

    ----------------------------------------------------------------
    -- ROOT LAYOUT
    ----------------------------------------------------------------
    local combinedLayout    = {
        name = 'MAIN',
        layer = "Settings",
        type = ui.TYPE.Text, -- Must be text widget to capture key events
        props = {
            size = displayArea,
            autoSize = false,
        },
        content = ui.content { blocker, colorPickerBox },
        events = {
            keyPress = async:callback(function(e, layout)
                if e.code == input.KEY.Escape then
                    resetState(colorBoxElement)
                    colorBoxElement = nil
                    newColor = nil
                    return
                end
            end),
        },
    }

    -- ensure UI is in sync with starting color
    newColor                = value
    updateUIFromColor()

    return combinedLayout
end

----------------------------------------------------------------
-- PUBLIC ENTRY POINT
----------------------------------------------------------------
function M.open(set, value)
    colorBoxElement = ui.create(makeColorPickerBox(value, set))
end

function M.close()
    if colorBoxElement then
        colorBoxElement:destroy()
        colorBoxElement = nil
    end
end

return M
