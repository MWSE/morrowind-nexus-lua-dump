-- Animated 3D Scrolling Icon Text System
-- Erstellt beliebig viele Icon-Texte die in 3D-Welt nach oben scrollen und verblassen
-- Ideal für Loot-Anzeigen und ähnliche Notifications

-- Globale Container für aktive Icon-Texte
if not scrollingIconTextSystem then
    scrollingIconTextSystem = {
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
local textBlue = getColorFromGameSettings("fontColor_color_journal_link") or util.color.rgb(0.2, 0.4, 1)
local textGold = getColorFromGameSettings("FontColor_color_normal") or util.color.rgb(1, 0.8, 0)



-- 3D Position zu UI-Position konvertieren
local function worldToUIPosition(worldPos)
    local width = ui.layers[scrollingIconTextSystem.layerId].size.x 
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

-- Einzelnen Icon-Text erstellen
local function createIconText(text, startWorldPos, color, fontSize, iconPath, iconSize)
    local id = scrollingIconTextSystem.nextId
    scrollingIconTextSystem.nextId = scrollingIconTextSystem.nextId + 1
    
    local initialUIPos, isVisible = worldToUIPosition(startWorldPos)
    if not isVisible then
        return nil -- Text nicht erstellen wenn nicht sichtbar
    end
    
    -- Hauptcontainer für Icon + Text
    local titleContainer = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            arrange = ui.ALIGNMENT.Center,
            horizontal = true,
        },
        content = ui.content {}
    }
    
    -- Icon hinzufügen (falls vorhanden)
    if iconPath then
        titleContainer.content:add{
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture { path = iconPath },
                size = v2(iconSize or (fontSize + 5), iconSize or (fontSize + 5)),
            }
        }
        -- Kleiner Spacer zwischen Icon und Text
        titleContainer.content:add{ 
            type = ui.TYPE.Container,
            props = { size = v2(3, 1) } 
        }
    end
    
    -- Text hinzufügen
    titleContainer.content:add{
        type = ui.TYPE.Text,
        props = {
            text = tostring(text),
            textColor = color or textBlue,
            textShadow = true,
            textShadowColor = util.color.rgba(0, 0, 0, 0.8),
            textSize = fontSize or 20,
            textAlignH = ui.ALIGNMENT.Start,
            textAlignV = ui.ALIGNMENT.Center,
            autoSize = true,
        },
    }
    
    local iconText = ui.create({
        type = ui.TYPE.Container,
        layer = "HUD",
        name = "iconText_" .. id,
        props = {
            position = initialUIPos,
            anchor = v2(0.5, 0.5),
            visible = isVisible,
            alpha = 1.0,
        },
        content = ui.content { titleContainer }
    })
    
    -- Animation-Daten
    local textData = {
        id = id,
        ui = iconText,
        startTime = 0,
        duration = 2.0, -- 2 Sekunden Animation
        startWorldPos = startWorldPos,
        endWorldPos = startWorldPos + v3(0, 0, 50), -- 50 Units nach oben
        startAlpha = 1.0,
        endAlpha = 0.0,
        isActive = true,
        lastVisible = isVisible,
        hasIcon = iconPath ~= nil
    }
    
    -- Zur aktiven Liste hinzufügen
    scrollingIconTextSystem.activeTexts[id] = textData
    
    return id
end

-- Icon-Text Animation Update
local function updateIconTexts(dt)
    for id, textData in pairs(scrollingIconTextSystem.activeTexts) do
        if textData.isActive then
            textData.startTime = textData.startTime + dt
            local progress = textData.startTime / textData.duration
            
            if progress >= 1.0 then
                -- Animation beendet
                textData.ui:destroy()
                scrollingIconTextSystem.activeTexts[id] = nil
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
                currentAlpha = math.min(1, currentAlpha + 0.05)
                
                -- Sichtbarkeit handhaben
                if isVisible ~= textData.lastVisible then
                    textData.ui.layout.props.visible = isVisible
                    textData.lastVisible = isVisible
                end
                
                if isVisible then
                    -- UI aktualisieren nur wenn sichtbar
                    textData.ui.layout.props.position = currentPos
                    textData.ui.layout.props.alpha = currentAlpha
                    
                    textData.ui:update()
                end
            end
        end
    end
end

-- Öffentliche Funktionen

-- Generische Text mit Icon Funktion
function spawnIconText3D(worldPos, iconPath, text, textColor, textSize, iconSize)
    local color = textColor or textGold
    local size = textSize or 28
    local iconSize = (textSize or 28)*1.33
    
    return createIconText(text, worldPos, color, size, iconPath, iconSize)
end

-- Alle aktiven Icon-Texte löschen
function clearAllIconTexts()
    for id, textData in pairs(scrollingIconTextSystem.activeTexts) do
        if textData.ui then
            textData.ui:destroy()
        end
    end
    scrollingIconTextSystem.activeTexts = {}
end

-- Update-Funktion zu onFrameFunctions hinzufügen
if onFrameFunctions then
    table.insert(onFrameFunctions, updateIconTexts)
end

-- Return für Modul-System
return {
    spawnIconText3D = spawnIconText3D,
    clearAllIconTexts = clearAllIconTexts,
}