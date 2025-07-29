if birthsignSelectionDialogue then
	birthsignSelectionDialogue:destroy()
	birthsignSelectionDialogue = nil
end

local makeBorder = require("scripts.Roguelite.ui_makeborder") 
local borderOffset = 1
local borderFile = "thin"

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
local function darkenColor(color, mult)
	return util.color.rgb(color.r*mult, color.g*mult, color.b*mult)
end

local function mixColors(color1, color2)
	return util.color.rgb((color1.r+color2.r)*0.5, (color1.g+color2.g)*0.5, (color1.b+color2.b)*0.5)
end

local darkerFont = getColorFromGameSettings("FontColor_color_normal")--darkenColor(fontColor, 0.7)
local fontSize = 21 --16
local lineHeightMultiplier = 1.9
local background = ui.texture { path = 'black' }
local descriptionWidth = 500 --420

-- Morrowind-inspirierte Farben
local morrowindGold = getColorFromGameSettings("FontColor_color_normal")

local morrowindBlue = util.color.rgb(0.2, 0.3, 0.5)
local morrowindPurple = util.color.rgb(0.4, 0.2, 0.5)
local selectedColor = util.color.rgb(0.6, 0.5, 0.2)
local hoverColor = util.color.rgb(0.3, 0.25, 0.15)

local selectedBirthsign = nil
local birthsignButtonFocus = nil

-- Cache für alle UI-Elemente
local birthsignButtons = {}
local confirmButton = nil
local descriptionText = nil

-- Birthsigns aus dem Spiel laden
local birthsigns = {}
local playerBirthsign = types.Player.getBirthSign(self)


for id, birthsign in pairs(types.Player.birthSigns.records) do
	if birthsign.id ~=playerBirthsign then
		table.insert(birthsigns, birthsign)
	end
end

-- Sortieren nach Name für konsistente Reihenfolge
table.sort(birthsigns, function(a, b) return a.name < b.name end)

local function textElement(str, color)
	return { 
		type = ui.TYPE.Text,
		props = {
			textColor = color or fontColor,
			textShadow = true,
			textShadowColor = util.color.rgba(0,0,0,0.9),
			textAlignV = ui.ALIGNMENT.Center,
			textAlignH = ui.ALIGNMENT.Center,
			text = " "..str.." ",
			textSize = fontSize,
			autoSize = true
		},
	}
end

local function makeBirthsignIcon(birthsign)
    local iconSize = fontSize*lineHeightMultiplier
    local iconBorderTemplate = makeBorder(borderFile, nil, 1, {
        type = ui.TYPE.Image,
        props = {
            relativeSize = v2(1,1),
            alpha = 0.9,
        }
    }).borders
    
    local iconBox = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(iconSize, iconSize),
        },
        content = ui.content {}
    }
    
    -- Icon Background
    iconBox.content:add{
        name = 'iconBackground',
        template = iconBorderTemplate,
        type = ui.TYPE.Image,
        props = {
            relativeSize = v2(1, 1),
            resource = ui.texture { path = 'white' },
            color = morrowindPurple,
            alpha = 0.8,
        },
    }
    
    -- Birthsign Icon
    iconBox.content:add{
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture { path = birthsign.texture },
            relativeSize = v2(1, 1),
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
            alpha = 0.9,
			size = v2(-2,-2)
        }
    }
    
    return iconBox
end

local function updateDescriptionText()
    if selectedBirthsign and descriptionText then
        local birthsign = nil
        for _, bs in ipairs(birthsigns) do
            if bs.id == selectedBirthsign then
                birthsign = bs
                break
            end
        end
        
        if birthsign then
            descriptionText.props.text = birthsign.description
        else
            descriptionText.props.text = "Select a birthsign to see its description."
        end
        birthsignSelectionDialogue:update()
    end
end
local function updateDescriptionText()
    if selectedBirthsign and descriptionText then
        local birthsign = nil
        for _, bs in ipairs(birthsigns) do
            if bs.id == selectedBirthsign then
                birthsign = bs
                break
            end
        end
        
        -- Alten Inhalt löschen
        descriptionText.content = ui.content{}
        if birthsign then
			local flavorTextContainer = {
				type = ui.TYPE.Flex,
				props = {
					--size = v2(350, 50),
					 autoSize = true
				},
				content = ui.content {}
			}
			descriptionText.content:add(flavorTextContainer)
			local function addFlavorLine(text)
				flavorTextContainer.content:add{
					type = ui.TYPE.Text,
					props = {
						text = text,
						textColor = morrowindGold,
						textShadow = true,
						textShadowColor = util.color.rgba(0,0,0,1),
						textSize = fontSize - 2,
						textAlignH = ui.ALIGNMENT.Start,
						textAlignV = ui.ALIGNMENT.Start,
					},
				}
			end
			descriptionText.content:add{ props = { size = v2(1, 1) * 10 } }
			local limit = 50
			if #birthsign.description > 50 and #birthsign.description < 80 then
				limit = 40
			end
			local line = ""
			for word in birthsign.description:gmatch("%S+") do
				if #line + #word + 1 > limit then
					addFlavorLine(line)
					line = word
				else
					line = line == "" and word or line .. " " .. word
				end
			end
			if line ~= "" then addFlavorLine(line) end
            
            
            -- Effekte hinzufügen
            if birthsign.spells and #birthsign.spells > 0 then
                -- Spacer
                descriptionText.content:add{ props = { size = v2(1, 1) * 1 } }
                
                -- Effects Titel
                descriptionText.content:add{
                    type = ui.TYPE.Text,
                    props = {
                        text = "Effects:",
                        textColor = fontColor,
                        textShadow = true,
                        textShadowColor = util.color.rgba(0,0,0,1),
                        textSize = fontSize,
                        textAlignH = ui.ALIGNMENT.Start,
                        textAlignV = ui.ALIGNMENT.Start,
                        autoSize = true,
                    },
                }
                
                for _, spellId in ipairs(birthsign.spells) do
                    local spell = core.magic.spells.records[spellId]
                    if spell then
						descriptionText.content:add{ props = { size = v2(1, 1) * 7 } }
                        -- Spell Name
                        descriptionText.content:add{
                            type = ui.TYPE.Text,
                            props = {
                                text = "- " .. spell.name .. ":",
                                textColor = spell.type== core.magic.SPELL_TYPE.Ability and fontColor or mixColors(fontColor, morrowindGold),
                                textShadow = true,
                                textShadowColor = util.color.rgba(0,0,0,1),
                                textSize = fontSize ,
                                textAlignH = ui.ALIGNMENT.Start,
                                textAlignV = ui.ALIGNMENT.Start,
                                autoSize = true,
                            },
                        }
                        descriptionText.content:add{ props = { size = v2(1, 1) * 2 } }
                        if spell.effects and #spell.effects > 0 then
                            for _, effect in ipairs(spell.effects) do
                                -- Effect Container (horizontal: Icon + Text)
                                local effectContainer = {
                                    type = ui.TYPE.Flex,
                                    props = {
                                        autoSize = true,
                                        arrange = ui.ALIGNMENT.Start,
                                        horizontal = true,
                                    },
                                    content = ui.content {}
                                }
                                
                                -- Spacer für Einrückung
                                effectContainer.content:add{ props = { size = v2(16, 1) } }
                                
                                -- Effect Icon
                                if effect.effect.icon then
                                    effectContainer.content:add{
                                        type = ui.TYPE.Image,
                                        props = {
                                            resource = ui.texture { path = effect.effect.icon },
                                            size = v2(16, 16),
                                            alpha = 0.9,
                                        }
                                    }
                                    effectContainer.content:add{ props = { size = v2(8, 1) } }
                                end
                                
                                -- Effect Text
                                local effectText = effect.effect.name.." "
                                if effect.id == core.magic.EFFECT_TYPE.FortifySkill or effect.id == core.magic.EFFECT_TYPE.FortifyAttribute then
									effectText = "+"
								elseif effect.id == core.magic.EFFECT_TYPE.DrainAttribute or effect.id == core.magic.EFFECT_TYPE.DrainSkill then
									effectText = "-"
								end
								local percentEffects = {
									["chameleon"] = true,
									["reflect"] = true,
									["resistblightdisease"] = true,
									["resistcommondisease"] = true,
									["resistcorprusdisease"] = true,
									["resistfire"] = true,
									["resistfrost"] = true,
									["resistmagicka"] = true,
									["resistnormalweapons"] = true,
									["resistparalysis"] = true,
									["resistpoison"] = true,
									["resistshock"] = true,
									["sanctuary"] = true,
									["spellabsorption"] = true,
									["weaknesstoblightdisease"] = true,
									["weaknesstocommondisease"] = true,
									["weaknesstocorprusdisease"] = true,
									["weaknesstofire"] = true,
									["weaknesstofrost"] = true,
									["weaknesstomagicka"] = true,
									["weaknesstonormalweapons"] = true,
									["weaknesstopoison"] = true,
									["weaknesstoshock"] = true,
									["fortifyattack"] = true,
								}
								
                                -- Magnitude hinzufügen
                                if effect.magnitudeMin and effect.magnitudeMax and effect.effect.hasMagnitude then
                                    if effect.magnitudeMin == effect.magnitudeMax then
										if effect.effect.id == "fortifymaximummagicka" then
											effectText = effectText .. "" .. effect.magnitudeMin/10 
										else
											effectText = effectText .. "" .. effect.magnitudeMin.." "
										end
                                    else
                                        effectText = effectText .. "" .. effect.magnitudeMin .. "-" .. effect.magnitudeMax.." "
                                    end
                                end
								
								-- Magnituden suffix
                                if effect.effect.hasMagnitude then
									if effect.id == core.magic.EFFECT_TYPE.FortifySkill or effect.id == core.magic.EFFECT_TYPE.FortifyAttribute or effect.id == core.magic.EFFECT_TYPE.DrainAttribute or effect.id == core.magic.EFFECT_TYPE.DrainSkill then
										-- -
									elseif effect.effect.id == "fortifymaximummagicka" then
										effectText = effectText..""..core.getGMST("sXTimesINT")
									elseif percentEffects[effect.effect.id] then
										effectText = effectText.."% "
									else
										effectText = effectText..core.getGMST("sPoints").." "
									end
								end
								
                                -- Betroffenes Attribut oder Skill hinzufügen
                                if effect.affectedAttribute then
                                    effectText = effectText .. "" .. core.getGMST("sAttribute"..effect.affectedAttribute).." "
                                elseif effect.affectedSkill then
                                    effectText = effectText .. "" .. core.getGMST("sSkill"..effect.affectedSkill).." "
                                end
                                
                                -- Duration hinzufügen
                                if effect.duration and effect.effect.hasDuration and effect.duration > 0 and spell.type~= core.magic.SPELL_TYPE.Ability then
                                    effectText = effectText .. core.getGMST("sfor").." " .. effect.duration .. "s"
                                end
                                
                                -- Range hinzufügen
                                --if effect.range and effect.range > 0 then
                                --    effectText = effectText .. " (Range: " .. effect.range .. ")"
                                --end
                                if effect.range == core.magic.RANGE.Self then
								
								elseif effect.range == core.magic.RANGE.Target then
									effectText = effectText .. " (Target)"
								elseif effect.range == core.magic.RANGE.Touch then
									effectText = effectText .. " (Touch)"
								end
                                effectContainer.content:add{
                                    type = ui.TYPE.Text,
                                    props = {
                                        text = effectText,
                                        textColor = spell.type == core.magic.SPELL_TYPE.Ability and fontColor or morrowindGold,
                                        textShadow = true,
                                        textShadowColor = util.color.rgba(0,0,0,1),
                                        textSize = fontSize - 2,
                                        textAlignH = ui.ALIGNMENT.Start,
                                        textAlignV = ui.ALIGNMENT.Start,
                                        autoSize = true,
                                    },
                                }
                                
                                descriptionText.content:add(effectContainer)
                            end
                        end
                        
                        -- Spacer zwischen Spells
                        descriptionText.content:add{ props = { size = v2(1, 1) * 0.5 } }
                    end
                end
            end
        else
            descriptionText.content:add{
                type = ui.TYPE.Text,
                props = {
                    text = "Select a birthsign to see its description.",
                    textColor = fontColor,
                    textShadow = true,
                    textShadowColor = util.color.rgba(0,0,0,1),
                    textSize = fontSize - 2,
                    textAlignH = ui.ALIGNMENT.Start,
                    textAlignV = ui.ALIGNMENT.Start,
                    autoSize = true,
                },
            }
        end
        birthsignSelectionDialogue:update()
    end
end

local layerId = ui.layers.indexOf("HUD")
local screenSize = ui.layers[layerId].size

local borderTemplate = makeBorder(borderFile, nil, borderOffset, {
	type = ui.TYPE.Image,
	props = {
		resource = background,
		relativeSize  = v2(1,1),
		alpha = 0.8,
	}
}).borders

--root
birthsignSelectionDialogue = ui.create({
	type = ui.TYPE.Container,
	layer = 'Modal',
	name = "birthsignSelectionDialogue",
	template = borderTemplate,
	props = {
		relativePosition = v2(0.5,0.5),
		anchor = v2(0.5,0.5),
	},
	content = ui.content {{
			name = 'background',
			type = ui.TYPE.Image,
			props = {
				--resource = background,
				--tileH = true,
				--tileV = true,
				--color = morrowindBrown,
				--alpha = 0.9,
			},
		},
	}
})

local mainFlex = {
	type = ui.TYPE.Flex,
	layer = 'HUD',
	name = 'mainFlex',
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Start,
		horizontal = false,
	},
	content = ui.content {
	}
}
birthsignSelectionDialogue.layout.content:add(mainFlex)

-- Titel
mainFlex.content:add{ props = { size = v2(1, 1) * 1 } }
mainFlex.content:add(textElement("Choose your Birthsign:", fontColor))
mainFlex.content:add{ props = { size = v2(1, 1) * 1 } }

-- Hauptcontainer (horizontal: Liste links, Beschreibung rechts)
local contentFlex = {
	type = ui.TYPE.Flex,
	layer = 'HUD',
	name = 'contentFlex',
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Start,
		horizontal = true,
	},
	content = ui.content {
	}
}
mainFlex.content:add(contentFlex)

-- Linke Seite: Birthsign-Liste
local leftPanel = {
	type = ui.TYPE.Flex,
	layer = 'HUD',
	name = 'leftPanel',
	props = {
		relativeSize = v2(0, 1),
		size = v2(220,0),
		arrange = ui.ALIGNMENT.Start,
		horizontal = false,
	},
	content = ui.content {
	}
}
contentFlex.content:add(leftPanel)

-- Scrollbare Liste für Birthsigns
local birthsignList = {
	type = ui.TYPE.Flex,
	layer = 'HUD',
	name = 'birthsignList',
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Start,
		horizontal = false,
	},
	content = ui.content {
	}
}
leftPanel.content:add(birthsignList)

contentFlex.content:add{ props = { size = v2(1, 1) * 5 } }

-- Rechte Seite: Beschreibung
local rightPanel = {
	type = ui.TYPE.Flex,
	layer = 'HUD',
	name = 'rightPanel',
	props = {
		relativeSize = v2(0, 1),
		size = v2(descriptionWidth,0),
		arrange = ui.ALIGNMENT.Start,
		horizontal = false,
	},
	content = ui.content {
	}
}
contentFlex.content:add(rightPanel)

-- Beschreibungs-Titel
rightPanel.content:add{ props = { size = v2(1, 1) * 1 } }
rightPanel.content:add(textElement("Description:", fontColor))
rightPanel.content:add{ props = { size = v2(1, 1) * 1 } }

-- Beschreibungstext
local descriptionContainer = {
	type = ui.TYPE.Widget,
	props = {
		size = v2(descriptionWidth-8, fontSize*18),
		
	},
	content = ui.content {}
}
rightPanel.content:add(descriptionContainer)

-- Beschreibungs-Hintergrund
local descBorderTemplate = makeBorder(borderFile, morrowindGold, 1, {
	type = ui.TYPE.Image,
	props = {
		relativeSize = v2(1,1),
		alpha = 0.3,
	}
}).borders

descriptionContainer.content:add{
	name = 'descBackground',
	template = descBorderTemplate,
	type = ui.TYPE.Image,
	props = {
		relativeSize = v2(1, 1),
		resource = ui.texture { path = 'white' },
		color = util.color.rgb(0, 0, 0),
		alpha = 0.2,
	},
}

descriptionText = {
	type = ui.TYPE.Flex,
	props = {
		relativeSize = v2(1, 1),
		relativePosition = v2(0.01, 0),
		anchor = v2(0, 0),
		size = v2(descriptionWidth,500),
		text = "Select a birthsign to see its description.",
		textColor = fontColor,
		textShadow = true,
		textShadowColor = util.color.rgba(0,0,0,1),
		textSize = fontSize - 2,
		textAlignH = ui.ALIGNMENT.Start,
		textAlignV = ui.ALIGNMENT.Start,
		multiline = true,
		wordWrap = true,
	},
}
descriptionContainer.content:add(descriptionText)

local function updateAllBirthsignButtons()
    for _, buttonData in pairs(birthsignButtons) do
        if buttonData.birthsign.id == selectedBirthsign then
            buttonData.background.props.color = selectedColor
        else
            buttonData.background.props.color = darkenColor(fontColor,0.05)
        end
    end
    updateDescriptionText()
    birthsignSelectionDialogue:update()
end

local function makeBirthsignButton(birthsign)
    local borderTemplate = makeBorder(borderFile, nil, borderOffset, {
        type = ui.TYPE.Image,
        props = {
            relativeSize = v2(1,1),
            alpha = 0.3,
        }
    }).borders
    
    local box = {
        name = birthsign.id .. "Button",
        type = ui.TYPE.Widget,
        props = {
            size = v2(220, fontSize* 1.9),
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
            color = darkenColor(fontColor,0.05),
            alpha = 0.8,
        },
    }
    box.content:add(background)
    
    -- Content Container (horizontal flex)
    local contentFlex = {
        type = ui.TYPE.Flex,
        props = {
            relativeSize = v2(1, 1),
            arrange = ui.ALIGNMENT.Center,
            horizontal = true,
        },
        content = ui.content {}
    }
    box.content:add(contentFlex)
    
    -- Icon
    contentFlex.content:add{ props = { size = v2(1, 1) * 1 } }
    contentFlex.content:add(makeBirthsignIcon(birthsign))
    contentFlex.content:add{ props = { size = v2(1, 1) * 2 } }
    
    -- Birthsign Name
    contentFlex.content:add{
        type = ui.TYPE.Text,
        props = {
            text = birthsign.name,
            textColor = mixColors(fontColor, morrowindGold),
            textShadow = true,
            textShadowColor = util.color.rgba(0,0,0,1),
            textSize = fontSize,
            textAlignH = ui.ALIGNMENT.Start,
            textAlignV = ui.ALIGNMENT.Center,
            autoSize = true,
        },
    }
    
    contentFlex.content:add{ props = { size = v2(1, 1) * 1 } }
    
    -- Button-Data im Cache speichern
    birthsignButtons[birthsign.id] = {
        box = box,
        background = background,
        birthsign = birthsign
    }
    
    local clickbox = {
        name = 'clickbox',
        props = {
            relativeSize = util.vector2(1, 1),
            relativePosition = v2(0,0),
            anchor = v2(0,0),
        },
        userData = {
            birthsignId = birthsign.id
        },
    }
    
    clickbox.events = {
        mouseRelease = async:callback(function(_, elem)
            if birthsignButtonFocus == elem.userData.birthsignId then
                selectedBirthsign = elem.userData.birthsignId
                updateAllBirthsignButtons()
            end
        end),
        focusGain = async:callback(function(_, elem)
            birthsignButtonFocus = elem.userData.birthsignId
            if selectedBirthsign ~= elem.userData.birthsignId then
                background.props.color = hoverColor
                birthsignSelectionDialogue:update()
            end
        end),
        focusLoss = async:callback(function(_, elem)
            birthsignButtonFocus = nil
            if selectedBirthsign == elem.userData.birthsignId then
                background.props.color = selectedColor
            else
                background.props.color = darkenColor(fontColor,0.05)
            end
            birthsignSelectionDialogue:update()
        end),
    }
    
    box.content:add(clickbox)
    return box
end

-- Birthsign-Buttons erstellen
for _, birthsign in ipairs(birthsigns) do
    birthsignList.content:add(makeBirthsignButton(birthsign))
    birthsignList.content:add{ props = { size = v2(1, 1) * 0.5 } }
end

-- Bottom Panel für Confirm Button
local bottomPanel = {
	type = ui.TYPE.Flex,
	layer = 'HUD',
	name = 'bottomPanel',
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Center,
		--horizontal = true,
		relativeSize=v2(1,0),
		size = v2(descriptionWidth+220,0)
	},
	content = ui.content {
	}
}
mainFlex.content:add(bottomPanel)

-- Confirm Button
local function makeConfirmButton()
    local borderTemplate = makeBorder(borderFile, nil, borderOffset, {
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
            size = v2(fontSize*10, fontSize*lineHeightMultiplier),
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
            color = util.color.rgb(0,0,0),
            alpha = 0.75,
        },
    }
    box.content:add(background)
    
    box.content:add{
        name = 'text',
        type = ui.TYPE.Text,
        props = {
            relativePosition = v2(0.5,0.5),
            anchor = v2(0.5,0.5),
            text = "Confirm Selection",
            textColor = fontColor,
            textShadow = true,
            textShadowColor = util.color.rgb(0,0,0),
            textSize = fontSize,
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
        },
    }
    
    -- Confirm Button im Cache speichern
    confirmButton = {
        box = box,
        background = background
    }
    
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
    
    local function applyColor(elem)
        if not selectedBirthsign then
            background.props.color = util.color.rgb(0, 0, 0)
            return
        end
        
        if elem.userData.focus == 2 then
            background.props.color = morrowindGold
        elseif elem.userData.focus == 1 then
            background.props.color = darkenColor(morrowindGold,0.7)
        else
            background.props.color = util.color.rgb(0,0,0)
        end
        birthsignSelectionDialogue:update()
    end
    
    clickbox.events = {
        mouseRelease = async:callback(function(_, elem)
            elem.userData.focus = elem.userData.focus - 1
            if birthsignButtonFocus == "confirmButton" and selectedBirthsign then
                onFrameFunctions["confirmBirthsignButton"] = function()
                    if birthsignSelectionDialogue and birthsignButtonFocus == "confirmButton" then
						applyColor(elem)
                        birthsignSelectionDialogue:destroy()
                        birthsignSelectionDialogue = nil
                        birthsignSelectionReturn(selectedBirthsign) -- Callback mit dem ausgewählten Birthsign
                    end
                    onFrameFunctions["confirmBirthsignButton"] = nil
                end
            end
        end),
        focusGain = async:callback(function(_, elem)
            birthsignButtonFocus = "confirmButton"
            elem.userData.focus = elem.userData.focus + 1
            applyColor(elem)
        end),
        focusLoss = async:callback(function(_, elem)
            birthsignButtonFocus = nil
            elem.userData.focus = 0
            applyColor(elem)
        end),
        mousePress = async:callback(function(_, elem)
            elem.userData.focus = elem.userData.focus + 1
            applyColor(elem)
        end),
    }
    
    box.content:add(clickbox)
    
    
    return box
end

bottomPanel.content:add(makeConfirmButton())