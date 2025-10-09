local function getDifficultyColor(difficulty)
    if difficulty == "Easy" then
        return morrowindGreen
    elseif difficulty == "Medium" then
        return morrowindGold
    elseif difficulty == "Hard" then
        return morrowindRed
    elseif difficulty == "Extreme" then
        return util.color.rgb(0.8, 0.1, 0.8)
    else
        return fontColor
    end
end

if challengeDialogue then
	challengeDialogue:destroy()
	challengeDialogue = nil
end

local makeBorder = require("scripts.Roguelite.ui_makeborder") 
local borderOffset = 1
local borderFile = "thin"

local countChallenges = 0
for _ in pairs(challengeData) do
	countChallenges = countChallenges + 1
end

-- Konfiguration für Multi-Challenge Selection
local REQUIRED_CHALLENGES = math.min(countChallenges,math.max(playerSection:get("CHALLENGES_TARGET"),playerSection:get("SELECTABLE_CHALLENGES")))

local selectedChallenges = {}  -- Speichert die ausgewählten Challenges als Set
if countChallenges == REQUIRED_CHALLENGES then
	for challengeId in pairs(challengeData) do
		selectedChallenges[challengeId] = true
	end
end
local challengeButtonFocus = nil
local challengeButtons = {}  -- Speichert die Button-Referenzen

local function getColorFromGameSettings(colorTag)
    local result = core.getGMST(colorTag)
	if not result then
		return util.color.rgb(1,1,1)
	end
    local rgb = {}
    for color in string.gmatch(result, '(%d+)') do
        table.insert(rgb, tonumber(color))
    end
    if #rgb ~= 3 then
        print("UNEXPECTED COLOR: rgb of size=", #rgb)
        return util.color.rgb(1, 1, 1)
    end
    return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end

local fontColor = getColorFromGameSettings("FontColor_color_normal_over")
local darkerFont = util.color.rgb(fontColor.r*0.7,fontColor.g*0.7,fontColor.b*0.7)
local fontSize = 21
local background = ui.texture { path = 'black' }

-- Morrowind-inspirierte Farben
local morrowindGold = util.color.rgb(0.8, 0.7, 0.3)
local morrowindBrown = util.color.rgb(0.4, 0.3, 0.2)
local morrowindRed = util.color.rgb(0.6, 0.2, 0.1)
local morrowindBlue = util.color.rgb(0.2, 0.3, 0.5)
local morrowindGreen = util.color.rgb(0.2, 0.5, 0.3)
local selectedColor = util.color.rgb(0.6, 0.5, 0.2)
local hoverColor = util.color.rgb(0.3, 0.25, 0.15)

-- Hilfsfunktionen für Challenge-Set
local function isSelected(challengeId)
    return selectedChallenges[challengeId] ~= nil
end

local function getSelectedCount()
    local count = 0
    for _ in pairs(selectedChallenges) do
        count = count + 1
    end
    return count
end

local function toggleChallenge(challengeId)
    if isSelected(challengeId) then
        selectedChallenges[challengeId] = nil
    else
        -- Nur hinzufügen wenn noch nicht genug ausgewählt
        if getSelectedCount() < REQUIRED_CHALLENGES then
            selectedChallenges[challengeId] = true
        elseif REQUIRED_CHALLENGES == 1 then
			for a,b in pairs(selectedChallenges) do
				selectedChallenges[a] = nil
			end
			selectedChallenges[challengeId] = true
		end
    end
end

local function textElement(str, color, fs)
	return { 
		type = ui.TYPE.Text,
		props = {
			textColor = color or fontColor,
			textShadow = true,
			textShadowColor = util.color.rgba(0,0,0,0.9),
			textAlignV = ui.ALIGNMENT.Center,
			textAlignH = ui.ALIGNMENT.Center,
			text = " "..str.." ",
			textSize = fs or fontSize,
			autoSize = true
		},
	}
end

local layerId = ui.layers.indexOf("HUD")
local screenSize = ui.layers[layerId].size

local borderTemplate = makeBorder(borderFile, fontColor, borderOffset, {
	type = ui.TYPE.Image,
	props = {
		resource = background,
		relativeSize  = v2(1,1),
		alpha = 0.5,
	}
}).borders

-- Status Text Element (wird später referenziert)
local statusText = nil

--root
challengeDialogue = ui.create({
	type = ui.TYPE.Container,
	layer = 'Modal',
	name = "challengeDialogue",
	template = borderTemplate,
	props = {
		relativePosition = v2(0.5,0.5),
		anchor = v2(0.5,0.5),
	},
	content = ui.content {
	}
})

local flex = {
	type = ui.TYPE.Flex,
	layer = 'HUD',
	name = 'mainFlex',
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Center,
	},
	content = ui.content {
	}
}
challengeDialogue.layout.content:add(flex)

flex.content:add{ props = { size = v2(1, 1) * 1 } }
flex.content:add(textElement("Choose your Destiny:", fontColor))
flex.content:add{ props = { size = v2(1, 1) * 1 } }

-- Status Text für Auswahl-Fortschritt
statusText = {
    type = ui.TYPE.Text,
    props = {
        textColor = morrowindGold,
        textShadow = true,
        textShadowColor = util.color.rgba(0,0,0,0.9),
        textAlignV = ui.ALIGNMENT.Center,
        textAlignH = ui.ALIGNMENT.Center,
		text = REQUIRED_CHALLENGES > 1 and "Select " .. REQUIRED_CHALLENGES .. " challenges (" .. getSelectedCount() .. "/" .. REQUIRED_CHALLENGES .. ")"
			or "Select " .. REQUIRED_CHALLENGES .. " challenge",
        textSize = fontSize * 1.1,
        autoSize = true
    },
}
flex.content:add(statusText)

flex.content:add{ props = { size = v2(1, 1) * 1 } }
if playerSection:get("PENALTY_PER_DEATH") then
	flex.content:add(textElement("Challenge requirements will increase by "..playerSection:get("DYING_PENALTY").."% every time you die", darkerFont, fontSize*0.8))
else
	flex.content:add(textElement("Challenge requirements will increase by "..playerSection:get("DYING_PENALTY").."% when you die the first time", darkerFont, fontSize*0.8))
end
flex.content:add{ props = { size = v2(1, 1) * 2 } }

-- challenge-Buttons Container
local challengeGrid = {
	type = ui.TYPE.Flex,
	layer = 'HUD',
	name = 'challengeGrid',
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Start,
		horizontal = false,
	},
	content = ui.content {
	}
}
flex.content:add(challengeGrid)

-- Funktion um Status Text zu aktualisieren
local function updateStatusText()
    local selected = getSelectedCount()
    local color = morrowindGold
    
    if selected == REQUIRED_CHALLENGES then
        color = morrowindGreen
    elseif selected > REQUIRED_CHALLENGES then
        color = morrowindRed
    end
    
    statusText.props.textColor = color

    statusText.props.text = REQUIRED_CHALLENGES > 1 and "Select " .. REQUIRED_CHALLENGES .. " challenges (" .. getSelectedCount() .. "/" .. REQUIRED_CHALLENGES .. ")"
			or "Select " .. REQUIRED_CHALLENGES .. " challenge",
    challengeDialogue:update()
end

local function makechallengeButton(challenge)
    local borderTemplate = makeBorder(borderFile, fontColor, borderOffset, {
        type = ui.TYPE.Image,
        props = {
           -- relativeSize = v2(1,1),
           -- alpha = 0.3,
        }
    }).borders
    
    local box = {
        name = challenge.id .. "Button",
        type = ui.TYPE.Widget,
        props = {
            size = v2(fontSize*30, fontSize*3.5), 
        },
        content = ui.content {}
    }
    
    local background = {
        name = 'background',
        template = borderTemplate,
        type = ui.TYPE.Image,
        props = {
            relativeSize = util.vector2(1, 1),
            resource = ui.texture { path = 'white' },
            color = util.color.rgba(0, 0, 0, 0.3),
            alpha = 0.2,
			size = v2(-6,0),
			position = v2(2,0),
        },
    }
    box.content:add(background)
    
    -- Icon on the left side
    local challengeIcon = {
        name = 'challengeIcon',
        type = ui.TYPE.Image,
        props = {
            relativePosition = v2(0, 0.5),
			position = v2(5,0),
            anchor = v2(0, 0.5),
            resource = ui.texture { path = challenge.icon },
			size = v2(fontSize*3,fontSize*3),
			alpha = 0.5, -- Half transparent by default
        },
    }
    box.content:add(challengeIcon)
    -- challenge Name (moved to account for icon on left)
    box.content:add{
        name = 'challengeName',
        type = ui.TYPE.Text,
        props = {
            relativePosition = v2(0, 0.2),
			position = v2(fontSize*3+10,0),
            anchor = v2(0, 0),
            text = challenge.name,
            textColor = fontColor,
            textShadow = true,
            textShadowColor = util.color.rgba(0,0,0,1),
            textSize = fontSize ,
            textAlignH = ui.ALIGNMENT.Start,
            textAlignV = ui.ALIGNMENT.Center,
        },
    }
    
    -- challenge Description (moved to account for icon on left)
    box.content:add{
        name = 'challengeDesc',
        type = ui.TYPE.Text,
        props = {
            relativePosition = v2(0, 0.55),
			position = v2(fontSize*3+10,0),
            anchor = v2(0, 0),
            text = challenge.description,
            textColor = util.color.rgb(0.9, 0.9, 0.9),
            textShadow = true,
            textShadowColor = util.color.rgba(0,0,0,1),
            textSize = fontSize*0.9,
            textAlignH = ui.ALIGNMENT.Start,
            textAlignV = ui.ALIGNMENT.Center,
        },
    }
    
    local function updateButtonAppearance()
        if isSelected(challenge.id) then
            background.props.color = selectedColor
            background.props.alpha = 0.6
            challengeIcon.props.alpha = 1 -- Full opacity when selected
        else
            background.props.color = util.color.rgba(0, 0, 0, 0.3)
            background.props.alpha = 0.2
            challengeIcon.props.alpha = 0.5 -- Half transparent when not selected
        end
        challengeDialogue:update()
    end
    
    local clickbox = {
        name = 'clickbox',
        props = {
            relativeSize = util.vector2(1, 1),
            relativePosition = v2(0,0),
            anchor = v2(0,0),
        },
        userData = {
            challengeId = challenge.id
        },
    }
    
    clickbox.events = {
        mouseRelease = async:callback(function(_, elem)
            if challengeButtonFocus == elem.userData.challengeId then
                toggleChallenge(elem.userData.challengeId)
                updateAllButtonAppearances()
                updateStatusText()
				updateButtonAppearance()
				if not selectedChallenges[elem.userData.challengeId] and getSelectedCount()<REQUIRED_CHALLENGES then
					background.props.color = hoverColor
				end
            end
        end),
        focusGain = async:callback(function(_, elem)
            challengeButtonFocus = elem.userData.challengeId
            if not isSelected(elem.userData.challengeId) and (getSelectedCount()<REQUIRED_CHALLENGES or REQUIRED_CHALLENGES == 1) then
                background.props.color = hoverColor
                challengeDialogue:update()
            end
        end),
        focusLoss = async:callback(function(_, elem)
            challengeButtonFocus = nil
            updateButtonAppearance()
        end),
    }
    
    box.content:add(clickbox)
    updateButtonAppearance()
    
    -- Button für spätere Aktualisierung speichern
    challengeButtons[challenge.id] = {
        background = background,
        challengeIcon = challengeIcon,
        updateAppearance = updateButtonAppearance
    }
    
    return box
end

-- Funktion um alle Button-Erscheinungen zu aktualisieren
function updateAllButtonAppearances()
    for challengeId, button in pairs(challengeButtons) do
        if isSelected(challengeId) then
			button.background.props.color = selectedColor
            button.background.props.alpha = 0.6
            button.challengeIcon.props.alpha = 1 -- Full opacity when selected
        else
            button.background.props.color = util.color.rgba(0, 0, 0, 0.3)
            button.background.props.alpha = 0.2
            button.challengeIcon.props.alpha = 0.5 -- Half transparent when not selected
        end
    end
    challengeDialogue:update()
end

local challeng

-- challenges alphabetisch sortieren (reihenfolge erstmal egal, hauptsache es ist jedes mal gleich)
local sortedIds = {}
for challengeId, _ in pairs(challengeData) do
    table.insert(sortedIds, challengeId)
end
table.sort(sortedIds)

-- challenge-Buttons erstellen
for _, challengeId in ipairs(sortedIds) do
    local challenge = challengeData[challengeId]
    challengeGrid.content:add(makechallengeButton(challenge))
    challengeGrid.content:add{ props = { size = v2(1, 1) * 1 } }
end

flex.content:add{ props = { size = v2(1, 1) * 3 } }

-- Confirm Button
local function makeConfirmButton()
    local borderTemplate = makeBorder(borderFile, fontColor, borderOffset, {
        type = ui.TYPE.Image,
        props = {
            relativeSize = v2(1,1),
            alpha = 0.3,
        }
    }).borders
    
    local box = {
        name = "confirmButton",
        type = ui.TYPE.Widget,
        props = {
            size = v2(200, fontSize*2),
        },
        content = ui.content {}
    }
    
    local background = {
        name = 'background',
        template = borderTemplate,
        type = ui.TYPE.Image,
        props = {
            relativeSize = util.vector2(1, 1),
            resource = ui.texture { path = 'white' },
            color = util.color.rgb(0, 0, 0),
            alpha = 0.6,
        },
    }
    box.content:add(background)
    
    local confirmText = {
        name = 'text',
        type = ui.TYPE.Text,
        props = {
            relativePosition = v2(0.5,0.5),
            anchor = v2(0.5,0.5),
            text = "Accept challenges",
            textColor = fontColor,
            textShadow = true,
            textShadowColor = util.color.rgba(0,0,0,1),
            textSize = fontSize,
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
        },
    }
    box.content:add(confirmText)
    
    local clickbox = {
        name = 'clickbox',
        props = {
            relativeSize = util.vector2(1, 1),
            relativePosition = v2(0,0),
            anchor = v2(0,0),
        },
        userData = {
            focus = 0
        },
    }
    
    local function updateConfirmButton()
        local selectedCount = getSelectedCount()
        local canConfirm = selectedCount == REQUIRED_CHALLENGES
        
        if canConfirm then
            confirmText.props.textColor = fontColor
            confirmText.props.text = REQUIRED_CHALLENGES > 1 and "Accept challenges" or "Accept challenge"
        else
            confirmText.props.textColor = darkerFont
            confirmText.props.text = REQUIRED_CHALLENGES > 1 and "Select " .. (REQUIRED_CHALLENGES - selectedCount) .. " more" or "Select a challenge"
        end
        
        challengeDialogue:update()
    end
    
    local function applyColor(elem)
        local canConfirm = getSelectedCount() == REQUIRED_CHALLENGES
        
        if not canConfirm then
            background.props.color = util.color.rgb(0, 0, 0)
            return
        end
        
        if elem.userData.focus == 2 then
            background.props.color = fontColor
        elseif elem.userData.focus == 1 then
            background.props.color = darkerFont
        else
            background.props.color = util.color.rgb(0, 0, 0)
        end
        challengeDialogue:update()
    end
    
    clickbox.events = {
        mouseRelease = async:callback(function(_, elem)
            elem.userData.focus = elem.userData.focus - 1
            if challengeButtonFocus == "confirmButton" and getSelectedCount() == REQUIRED_CHALLENGES then
                onFrameFunctions["confirmButton"] = function()
                    if challengeDialogue and challengeButtonFocus == "confirmButton" then
						applyColor(elem)
                        challengeDialogue:destroy()
                        challengeDialogue = nil
                        -- Konvertiere selectedChallenges Set zu Array
                        local selectedArray = {}
                        for challengeId, _ in pairs(selectedChallenges) do
                            table.insert(selectedArray, challengeId)
                        end
                        challengeSelectionReturn(selectedArray) -- Callback mit Array der ausgewählten Challenges
                    end
                    onFrameFunctions["confirmButton"] = nil
                end
            end
        end),
        focusGain = async:callback(function(_, elem)
            challengeButtonFocus = "confirmButton"
            elem.userData.focus = elem.userData.focus + 1
            applyColor(elem)
        end),
        focusLoss = async:callback(function(_, elem)
            challengeButtonFocus = nil
            elem.userData.focus = 0
            applyColor(elem)
        end),
        mousePress = async:callback(function(_, elem)
            if getSelectedCount() == REQUIRED_CHALLENGES then
                elem.userData.focus = elem.userData.focus + 1
                applyColor(elem)
            end
        end),
    }
    
    box.content:add(clickbox)
    
    -- Initial state setzen
    updateConfirmButton()
    
    -- Funktion für externe Updates verfügbar machen
    box.updateConfirmButton = updateConfirmButton
    
    return box
end

local confirmButton = makeConfirmButton()
flex.content:add(confirmButton)

-- Status Text initial aktualisieren
updateStatusText()

-- Confirm Button bei Änderungen aktualisieren
local originalUpdateStatusText = updateStatusText
updateStatusText = function()
    originalUpdateStatusText()
    confirmButton.updateConfirmButton()
end

flex.content:add{ props = { size = v2(1, 1) * 2 } }