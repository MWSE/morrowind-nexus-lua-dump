if blessingSelectionDialogue then
	blessingSelectionDialogue:destroy()
	blessingSelectionDialogue = nil
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
local darkerFont = util.color.rgb(fontColor.r*0.7,fontColor.g*0.7,fontColor.b*0.7)
local fontSize = 21
local background = ui.texture { path = 'black' }

-- Morrowind-inspirierte Farben
local morrowindGold = util.color.rgb(0.8, 0.7, 0.3)
local morrowindBrown = util.color.rgb(0.4, 0.3, 0.2)
local morrowindRed = util.color.rgb(0.6, 0.2, 0.1)
local morrowindBlue = util.color.rgb(0.2, 0.3, 0.5)
local selectedColor = util.color.rgb(0.6, 0.5, 0.2)
local hoverColor = util.color.rgb(0.3, 0.25, 0.15)

-- Konfiguration für Boni
local maxSelections = (runDB:get("UNLOCKED_BLESSINGS") or 0) + playerSection:get("EXTRA_BLESSINGS")
local selectedBlessings = {}
local blessingButtonFocus = nil

-- Morrowind-Boni mit coolen Namen
local availableBlessings = {
	{id = "intellect", name = "Arcane Reservoir", description = "Magicka Bonus 1.0x INT"},
	{id = "hitchance", name = "Warrior's Precision", description = "+20% hit chance"},
	{id = "feather", name = "Windwalker's Blessing", description = "150 Feather"},
	{id = "sanctuary", name = "Ghostly Shroud", description = "+25% sanctuary"},
	{id = "jack", name = "Jack of 10 trades", description = "+8-9 to utility skills"},
	{id = "teleportation", name = "Teleportation expert", description = "Start with all teleportation spells"},
	{id = "attribute", name = "Blessed by Azura", description = "One attribute starts at 80 but levels slowly"},
	{id = "skillup", name = "Divine Inspiration", description = "Skill-up: chance +1 rnd attribute (50% / 25% / 12.5%)"},
	{id = "maxgains", name = "Perfect Growth", description = "Always maximum attribute gains on level up"},
	{id = "scholar", name = "Lorekeeper's Gift", description = "Skill books grant 5 skill points"},
	{id = "birthsign", name = "Stellar Alignment", description = "Additional birthsign"},
	{id = "sneak", name = "Shadow Dancer", description = "Sneak faster, +5 Sneak and Chameleon"},
	{id = "slumber", name = "Slumber's Charm", description = "Find companions when resting"},
	{id = "disposition", name = "Beloved by All", description = "100 base dispositions + 20 mercantile + calm power"},
	{id = "alchemist", name = "Cauldron's Wisdom", description = "Potions: 40% chance of double effects, sometimes free"},
	{id = "soulstone", name = "Soul Hunter", description = "20% + 0.03% soulValue chance for soulstone on kill"},
	{id = "resurgence", name = "Erin's Resurgence", description = "Buffs get re-applied once (except restore effects)"},
	{id = "arcaneforce", name = "Arcane Force", description = "Boost castchance by using more magicka"},
	{id = "blooddividend", name = "Blood Dividend", description = "Receive Gold on kill"},
}
if I.HUDMarkers and I.HUDMarkers.version >=6 then
	table.insert(availableBlessings,{id = "herbalist", name = "Green Thumb", description = "Detect ingredients from 90 ft away (via HUDMarkers)"})
end

-- paralysis and knockdown immune above 50% fatigue
-- weightless armor
-- 25% elemental resistances
-- can move when overencumbered, but slower
-- jump without fatigue loss
-- damage from all sources decreased by 20% (script)
-- half of damage taken gets restored over 30 seconds
-- kills grant 50-100 septims 


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

local function isSelected(blessingId)
	for _, selectedId in ipairs(selectedBlessings) do
		if selectedId == blessingId then
			return true
		end
	end
	return false
end

local function toggleSelection(blessingId)
	if isSelected(blessingId) then
		-- Entfernen
		for i, selectedId in ipairs(selectedBlessings) do
			if selectedId == blessingId then
				table.remove(selectedBlessings, i)
				break
			end
		end
	else
		-- Hinzufügen (nur wenn Limit nicht erreicht)
		if #selectedBlessings < maxSelections then
			table.insert(selectedBlessings, blessingId)
		end
	end
end

local function canSelect(blessingId)
	return isSelected(blessingId) or #selectedBlessings < maxSelections
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

--root
blessingSelectionDialogue = ui.create({
	type = ui.TYPE.Container,
	layer = 'Modal',
	name = "blessingSelectionDialogue",
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
blessingSelectionDialogue.layout.content:add(flex)

flex.content:add{ props = { size = v2(1, 1) * 1 } }
flex.content:add(textElement("Choose your blessings:", fontColor))
flex.content:add{ props = { size = v2(1, 1) * 2 } }

-- Counter für ausgewählte Boni
local counterElement = textElement("Selected: 0/" .. maxSelections, morrowindGold)
flex.content:add(counterElement)
flex.content:add{ props = { size = v2(1, 1) * 2 } }

-- Two-Column Blessing Container
local blessingContainer = {
	type = ui.TYPE.Flex,
	layer = 'HUD',
	name = 'blessingContainer',
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Start,
		horizontal = true,
	},
	content = ui.content {
	}
}
flex.content:add(blessingContainer)

-- Left Column
local leftColumn = {
	type = ui.TYPE.Flex,
	layer = 'HUD',
	name = 'leftColumn',
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Start,
		align = ui.ALIGNMENT.Start,
		horizontal = false,
	},
	content = ui.content {
	}
}
blessingContainer.content:add(leftColumn)

-- Spacer between columns
blessingContainer.content:add{ props = { size = v2(10, 1) } }

-- Right Column
local rightColumn = {
	type = ui.TYPE.Flex,
	layer = 'HUD',
	name = 'rightColumn',
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Start,
		align = ui.ALIGNMENT.Start,
		horizontal = false,
	},
	content = ui.content {
	}
}
blessingContainer.content:add(rightColumn)

local function updateCounter()
	counterElement.props.text = "Selected: " .. #selectedBlessings .. "/" .. maxSelections
	if #selectedBlessings >= maxSelections then
		counterElement.props.textColor = util.color.rgb(0.5, 1, 0.5)
	else
		counterElement.props.textColor = morrowindGold
	end
	blessingSelectionDialogue:update()
end

local function makeBlessingButton(blessing)
	local borderTemplate = makeBorder(borderFile, fontColor, borderOffset
	).borders
	
	local box = {
		name = blessing.id .. "Button",
		type = ui.TYPE.Widget,
		props = {
			size = v2(fontSize*25, fontSize*3),
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
			alpha = 0.5,
		},
	}
	box.content:add(background)
	
	-- blessing Name
	box.content:add{
		name = 'blessingName',
		type = ui.TYPE.Text,
		props = {
			relativePosition = v2(0.05, 0.1),
			anchor = v2(0, 0),
			text = blessing.name,
			textColor = fontColor,
			textShadow = true,
			textShadowColor = util.color.rgba(0,0,0,1),
			textSize = fontSize,
			textAlignH = ui.ALIGNMENT.Start,
			textAlignV = ui.ALIGNMENT.Center,
		},
	}
	
	-- blessing Description
	box.content:add{
		name = 'blessingDesc',
		type = ui.TYPE.Text,
		props = {
			relativePosition = v2(0.05, 0.55),
			anchor = v2(0, 0),
			text = blessing.description,
			textColor = util.color.rgb(0.9, 0.9, 0.9),
			textShadow = true,
			textShadowColor = util.color.rgba(0,0,0,1),
			textSize = fontSize - 1,
			textAlignH = ui.ALIGNMENT.Start,
			textAlignV = ui.ALIGNMENT.Center,
		},
	}
	
	local function updateButtonAppearance()
		if isSelected(blessing.id) then
			background.props.color = darkerFont
		else
			background.props.color = util.color.rgb(0,0,0)
		end
		blessingSelectionDialogue:update()
	end
	
	local clickbox = {
		name = 'clickbox',
		props = {
			relativeSize = util.vector2(1, 1),
			relativePosition = v2(0,0),
			anchor = v2(0,0),
		},
		userData = {
			blessingId = blessing.id
		},
	}
	
	clickbox.events = {
		mouseRelease = async:callback(function(_, elem)
			if blessingButtonFocus == elem.userData.blessingId and canSelect(elem.userData.blessingId) then
				toggleSelection(elem.userData.blessingId)
				updateButtonAppearance()
				updateCounter()
			end
		end),
		focusGain = async:callback(function(_, elem)
			blessingButtonFocus = elem.userData.blessingId
			if not isSelected(elem.userData.blessingId) then
				if canSelect(elem.userData.blessingId) then
					background.props.color = hoverColor
				else
					background.props.color = util.color.rgb(0.3, 0.2, 0.2)  -- Rötlich für nicht auswählbar
				end
				blessingSelectionDialogue:update()
			end
		end),
		focusLoss = async:callback(function(_, elem)
			blessingButtonFocus = nil
			updateButtonAppearance()
		end),
	}
	
	box.content:add(clickbox)
	updateButtonAppearance()
	return box
end

-- Create blessing buttons in two columns
for i, blessing in ipairs(availableBlessings) do
	local button = makeBlessingButton(blessing)
	
	-- Distribute blessings between left and right columns
	if i % 2 == 1 then
		-- Odd index goes to left column
		leftColumn.content:add(button)
		leftColumn.content:add{ props = { size = v2(1, 1) * 1 } }
	else
		-- Even index goes to right column
		rightColumn.content:add(button)
		rightColumn.content:add{ props = { size = v2(1, 1) * 1 } }
	end
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
			color = util.color.rgb(0,0,0),
			alpha = 0.6,
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
			textShadowColor = util.color.rgba(0,0,0,1),
			textSize = fontSize,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
		},
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
		if elem.userData.focus == 2 then
			background.props.color = fontColor  -- Hellblau für Hover
		elseif elem.userData.focus == 1 then
			background.props.color = darkerFont
		else
			background.props.color = util.color.rgb(0,0,0)
		end
		blessingSelectionDialogue:update()
	end
	
	clickbox.events = {
		mouseRelease = async:callback(function(_, elem)
			elem.userData.focus = elem.userData.focus - 1
			if blessingButtonFocus == "confirmButton" then
				onFrameFunctions["confirmButton"] = function()
					if blessingSelectionDialogue and blessingButtonFocus == "confirmButton" then
						applyColor(elem)
						blessingSelectionDialogue:destroy()
						blessingSelectionDialogue = nil
						blessingSelectionReturn(selectedBlessings) -- Callback mit den ausgewählten Boni
					end
					onFrameFunctions["confirmButton"] = nil
				end
			end
		end),
		focusGain = async:callback(function(_, elem)
			blessingButtonFocus = "confirmButton"
			elem.userData.focus = elem.userData.focus + 1
			applyColor(elem)
		end),
		focusLoss = async:callback(function(_, elem)
			blessingButtonFocus = nil
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

flex.content:add(makeConfirmButton())
flex.content:add{ props = { size = v2(1, 1) * 2 } }