-- floating "+N exp" text that drifts up 50px and fades out

if not expTextSystem then
    expTextSystem = {
        activeTexts = {},
        nextId = 1,
        layerId = ui.layers.indexOf("HUD")
    }
end

local function f1dot(number)
    return string.format("%.1f", number + 0.05)
end

local function createExpText(text, startPos, color, fontSize)
    local id = expTextSystem.nextId
    expTextSystem.nextId = expTextSystem.nextId + 1

    local expText = ui.create({
        type = ui.TYPE.Container,
        layer = "HUD",
        name = "expText_" .. id,
        props = {
            relativePosition = startPos,
            anchor = v2(0.5, 0.5),
            visible = true,
        },
        content = ui.content {
            {
                type = ui.TYPE.Text,
                props = {
                    text = text,
                    textColor = color or morrowindBlue,
                    textShadow = true,
                    textShadowColor = util.color.rgba(0, 0, 0, 0.8),
                    textSize = fontSize or 20,
                    textAlignH = ui.ALIGNMENT.Center,
                    textAlignV = ui.ALIGNMENT.Center,
                    autoSize = true,
                }
            }
        }
    })

    local textData = {
        id = id,
        ui = expText,
        startTime = 0,
        duration = 2.0,
        startPos = v2(0, 0),
        endPos = v2(0, 0 - 50),
        startAlpha = 1.0,
        endAlpha = 0.0,
        isActive = true
    }

    expTextSystem.activeTexts[id] = textData

    return id
end

local function updateExpTexts(dt)
	local dt =  core.getRealFrameDuration()
    for id, textData in pairs(expTextSystem.activeTexts) do
        if textData.isActive then
            textData.startTime = textData.startTime + dt
            local progress = textData.startTime / textData.duration

            if progress >= 1.0 then
                textData.ui:destroy()
                expTextSystem.activeTexts[id] = nil
            else
                -- ease-out
                local easedProgress = 1 - (1 - progress) * (1 - progress)

                local currentPos = v2(
                    textData.startPos.x + (textData.endPos.x - textData.startPos.x) * easedProgress,
                    textData.startPos.y + (textData.endPos.y - textData.startPos.y) * easedProgress
                )

                -- hold 30% then fade
                local alphaProgress = math.max(0, (progress - 0.3) / 0.7)
                local currentAlpha = textData.startAlpha + (textData.endAlpha - textData.startAlpha) * alphaProgress
                currentAlpha = math.min(1, currentAlpha + 0.05)

                textData.ui.layout.props.position = currentPos
                textData.ui.layout.content[1].props.alpha = currentAlpha

                textData.ui:update()
            end
        end
    end
end

function spawnExpText(expAmount, position, textColor, S_FONT_SIZE)
    local text = "+" .. f1dot(expAmount) .. " Exp"
    local color = textColor or morrowindBlue
    local size = S_FONT_SIZE or 20

    return createExpText(text, position, color, size)
end

function clearAllExpTexts()
    for id, textData in pairs(expTextSystem.activeTexts) do
        if textData.ui then
            textData.ui:destroy()
        end
    end
    expTextSystem.activeTexts = {}
end

if onFrameFunctions then
    table.insert(onFrameFunctions, updateExpTexts)
end

return spawnExpText
