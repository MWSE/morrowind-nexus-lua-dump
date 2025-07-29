-- Animated 3D EXP Text System
-- Erstellt beliebig viele blaue EXP-Texte die in 3D-Welt nach oben scrollen und verblassen

-- Globale Container für aktive EXP-Texte
if not expTextSystem then
    expTextSystem = {
        activeTexts = {},
        nextId = 1,
        layerId = ui.layers.indexOf("HUD") -- Standard Layer
    }
end

-- Farben (basierend auf deinem System)
local function getColorFromGameSettings(colorTag)
    local result = core.getGMST(colorTag)
    if not result then
        return util.color.rgb(0.2, 0.4, 1) -- Fallback Blau
    end
    local rgb = {}
    for color in string.gmatch(result, '(%d+)') do
        table.insert(rgb, tonumber(color))
    end
    if #rgb ~= 3 then
        return util.color.rgb(0.2, 0.4, 1) -- Fallback Blau
    end
    return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end

-- EXP-Text Farben
local expBlue = getColorFromGameSettings("fontColor_color_journal_link") or util.color.rgb(0.2, 0.4, 1)
local expGold = getColorFromGameSettings("FontColor_color_normal") or util.color.rgb(1, 0.8, 0)

-- Hilfsfunktion für Zahlenformatierung
local function f1dot(number)
	return string.format("%.1f",number+0.05)
end

-- 3D Position zu UI-Position konvertieren
local function worldToUIPosition(worldPos)
    local width = ui.layers[expTextSystem.layerId].size.x 
    local screenres = ui.screenSize()
    local uiScale = screenres.x / width
    local cameraPos = camera.getPosition()
    
    -- Prüfen ob vor der Kamera
    local viewportToWorldVector = camera.viewportToWorldVector(v2(0.5, 0.5))
    local toObject = worldPos - cameraPos
    local dotProduct = viewportToWorldVector:dot(toObject)
    
    if dotProduct > 0 then
        local viewPos_XYZ = camera.worldToViewportVector(worldPos)
        local viewpPos = v2(viewPos_XYZ.x/uiScale, viewPos_XYZ.y/uiScale)
        return viewpPos, true -- Position und sichtbar
    else
        return v2(0, 0), false -- Nicht sichtbar
    end
end

-- Einzelnen EXP-Text erstellen
local function createExpText(text, startWorldPos, color, fontSize)
    local id = expTextSystem.nextId
    expTextSystem.nextId = expTextSystem.nextId + 1
    
    local initialUIPos, isVisible = worldToUIPosition(startWorldPos)
    if not isVisible then
        return nil -- Text nicht erstellen wenn nicht sichtbar
    end
    
    local expText = ui.create({
        type = ui.TYPE.Container,
        layer = "HUD",
        name = "expText_" .. id,
        props = {
            position = initialUIPos,
            anchor = v2(0.5, 0.5),
            visible = isVisible,
        },
        content = ui.content {
            {
                type = ui.TYPE.Text,
                props = {
                    text = text,
                    textColor = color or expBlue,
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
    
    -- Animation-Daten
    local textData = {
        id = id,
        ui = expText,
        startTime = 0,
        duration = 2.0, -- 3 Sekunden Animation
        startWorldPos = startWorldPos,
        endWorldPos = startWorldPos + v3(0, 0, 50), -- 150 Units nach oben
        startAlpha = 1.0,
        endAlpha = 0.0,
        isActive = true,
        lastVisible = isVisible
    }
    
    -- Zur aktiven Liste hinzufügen
    expTextSystem.activeTexts[id] = textData
    
    return id
end

-- EXP-Text Animation Update
local function updateExpTexts(dt)
    for id, textData in pairs(expTextSystem.activeTexts) do
        if textData.isActive then
            textData.startTime = textData.startTime + dt
            local progress = textData.startTime / textData.duration
            
            if progress >= 1.0 then
                -- Animation beendet
                textData.ui:destroy()
                expTextSystem.activeTexts[id] = nil
            else
                -- Interpolation für Position und Alpha
                local easedProgress = 1 - (1 - progress) * (1 - progress) -- Ease-out
                
                -- 3D Weltposition interpolieren
                local currentWorldPos = v3(
                    textData.startWorldPos.x + (textData.endWorldPos.x - textData.startWorldPos.x) * easedProgress,
                    textData.startWorldPos.y + (textData.endWorldPos.y - textData.startWorldPos.y) * easedProgress,
                    textData.startWorldPos.z + (textData.endWorldPos.z - textData.startWorldPos.z) * easedProgress
                )
                
                local currentPos, isVisible = worldToUIPosition(currentWorldPos)
                
                -- Alpha interpolieren (später beginnen zu verblassen)
                local alphaProgress = math.max(0, (progress - 0.3) / 0.7) -- Beginnt bei 30% der Animation zu verblassen
                local currentAlpha = textData.startAlpha + (textData.endAlpha - textData.startAlpha) * alphaProgress
				currentAlpha = math.min(1,currentAlpha+0.05)
                -- Sichtbarkeit handhaben
                if isVisible ~= textData.lastVisible then
                    textData.ui.layout.props.visible = isVisible
                    textData.lastVisible = isVisible
                end
                
                if isVisible then
                    -- UI aktualisieren nur wenn sichtbar
                    textData.ui.layout.props.position = currentPos
                    textData.ui.layout.content[1].props.alpha = currentAlpha
                    
                    textData.ui:update()
                end
            end
        end
    end
end

-- Öffentliche Funktionen

-- EXP-Text an 3D-Position spawnen
function spawnExpText3D(expAmount, worldPos, textColor, textSize)
    local text = "+" .. f1dot(expAmount) .. " Exp"
    local color = textColor or expBlue
    local size = textSize or 20
    
    return createExpText(text, worldPos, color, size)
end




-- Alle aktiven EXP-Texte löschen
function clearAllExpTexts()
    for id, textData in pairs(expTextSystem.activeTexts) do
        if textData.ui then
            textData.ui:destroy()
        end
    end
    expTextSystem.activeTexts = {}
end

-- Update-Funktion zu onFrameFunctions hinzufügen
if onFrameFunctions then
    table.insert(onFrameFunctions, updateExpTexts)
end


-- Return für Modul-System
return {
    spawnExpText3D = spawnExpText3D,
    clearAllExpTexts = clearAllExpTexts,
}