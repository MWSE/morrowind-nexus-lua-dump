function getColorFromGameSettings(colorTag)
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

function mixColors(color1, color2, mult)
	local mult = mult or 0.5
	return util.color.rgb(color1.r*mult+color2.r*(1-mult), color1.g*mult+color2.g*(1-mult), color1.b*mult+color2.b*(1-mult))
end

function darkenColor(color, mult)
	return util.color.rgb(color.r*mult, color.g*mult, color.b*mult)
end
textureCache = {}
function getTexture(path)
	if not textureCache[path] then
		textureCache[path] = ui.texture{path = path}
	end
	return textureCache[path]
end
SORT_DIRECTION = playerSection:get("SORT_DIRECTION")
textSize = playerSection:get("FONT_SIZE")
textColor = getColorFromGameSettings("fontColor_color_normal_over")
lightText = util.color.rgb(textColor.r^0.5,textColor.g^0.5,textColor.b^0.5)
morrowindGold = getColorFromGameSettings("fontColor_color_normal")
goldenMix =  mixColors(textColor, morrowindGold)
goldenMix2 =  mixColors(textColor, morrowindGold, 0.3)
darkerFont = getColorFromGameSettings("fontColor_color_normal")
selectedColor = util.color.rgb(0.6, 0.5, 0.2)
hoverColor = util.color.rgb(0.3, 0.25, 0.15)
morrowindBlue = getColorFromGameSettings("fontColor_color_journal_link")
morrowindBlue2 = getColorFromGameSettings("fontColor_color_journal_link_over")
morrowindBlue3 = getColorFromGameSettings("fontColor_color_journal_link_pressed")
background = ui.texture { path = 'black' }
makeBorder = require("scripts.puremultimark.PMM_makeborder")




-- Cleanup Funktion
function destroyTeleportWindow()
    if teleportWindow then
        teleportWindow:destroy()
        teleportWindow = nil
    end
    
    if renameDialog.isOpen() then
        renameDialog.close()
    end
end

destroyTeleportWindow()

teleportLocations = saveData.locations or {}


-- Konfiguration
borderOffset = 1
borderFile = "thin"
lineHeightMultiplier = 1.3
lineHeight2 = playerSection:get("LINE_HEIGHT")
spacer = 5
listBorders = false
listWidth = math.floor(430/23*textSize*playerSection:get("WIDTH_MULT"))
listHeight = LIST_ENTRIES * math.floor(textSize * lineHeightMultiplier)
local RENAME_ICON = playerSection:get("RENAME_ICON")
local TEXT_ALIGNMENT = playerSection:get("TEXT_ALIGNMENT")

if #teleportLocations > LIST_ENTRIES then
	listHeight = listHeight + math.floor(textSize * lineHeightMultiplier)/2
end


-- Globale UI Variablen
teleportButtonFocus = nil
teleportButtons = {}
scrollbarBackground = nil
scrollbarThumb = nil
topBarBackground = nil
xButton = nil
currentScrollbarWidth = 0
creationTime = core.getRealTime()
TEXT_ALIGNMENT_LOCATIONS = {
	["Start"] = v2(0,0.5),
	["Center"] = v2(0.5,0.5),
	["End"] = v2(1,0.5)
}

controllerRow = math.min(#teleportLocations,controllerRow)
currentScrollPos = math.max(1, math.min(#teleportLocations - LIST_ENTRIES+1, currentScrollPos))

-- button borders
borderTemplate = makeBorder(borderFile, util.color.rgb(0.5,0.5,0.5), borderOffset, {
	type = ui.TYPE.Image,
	props = {
		relativeSize = v2(1,1),
		alpha = 0.3,
	}
}).borders

local rootBorderTemplate = makeBorder(borderFile, nil, borderOffset, {
	type = ui.TYPE.Image,
	props = {
		resource = background,
		relativeSize = v2(1,1),
		alpha = 0.8,
	}
}).borders



function textElement(str, color)
	return { 
		type = ui.TYPE.Text,
		props = {
			textColor = color or textColor,
			textShadow = true,
			textShadowColor = util.color.rgba(0,0,0,0.9),
			textAlignV = ui.ALIGNMENT.Center,
			textAlignH = ui.ALIGNMENT.Center,
			text = " "..str.." ",
			textSize = textSize,
			autoSize = true
		},
	}
end
-- mb 3.0
function mb(content, size, func, highlightColor, parent)
	local uniqueButtonId = ""..math.random()
	local box = {
		name = uniqueButtonId,
		type = ui.TYPE.Widget,
		props = {
			size = size,
		},
		content = ui.content {}
	}
	
	local background = {
		name = 'background',
		template = borderTemplate,
		type = ui.TYPE.Image,
		props = {
			relativeSize = util.vector2(1, 1),
			resource = getTexture('white' ),
			color = util.color.rgb(0,0,0),
			alpha = 0.75,
		},
	}
	box.content:add(background)
	
	box.content:add(content)
	

	
	local clickbox = {
		name = 'clickbox',
		props = {
			relativeSize = util.vector2(1, 1),
			relativePosition = v2(0,0),
			anchor = v2(0,0),
		},
		userData = {
			focus = 0,
			customColor = nil
		},
	}
	
	local function applyColor(elem)
		elem = elem or clickbox
		if teleportWindow then
			if elem.userData.customColor then
				background.props.color = elem.userData.customColor
			elseif elem.userData.focus == 2 then
				background.props.color = highlightColor or morrowindGold
			elseif elem.userData.focus == 1 then
				background.props.color = darkenColor(highlightColor or morrowindGold,0.7)
			else
				background.props.color = util.color.rgb(0,0,0)
			end
			parent:update()
		end
	end
	clickbox.userData.applyColor = applyColor
	
	
	clickbox.events = {
		mouseRelease = async:callback(function(_, elem)
			elem.userData.focus = elem.userData.focus - 1
			if teleportButtonFocus == uniqueButtonId or elem.userData.focus <=0 then
				onFrameFunctions[uniqueButtonId] = function()
					if teleportWindow and teleportButtonFocus == uniqueButtonId then
						if core.getRealTime() > creationTime + 0.4 and not DEMO_MODE then
							func(elem)
						end
						applyColor(elem)
					end
					onFrameFunctions[uniqueButtonId] = nil
				end
			end
		end),
		focusGain = async:callback(function(_, elem)
			teleportButtonFocus = uniqueButtonId
			elem.userData.focus = 1
			applyColor(elem)
		end),
		focusLoss = async:callback(function(_, elem)
			teleportButtonFocus = nil
			elem.userData.focus = 0
			applyColor(elem)
		end),
		mousePress = async:callback(function(_, elem)
			teleportButtonFocus = uniqueButtonId
			elem.userData.focus = 2
			applyColor(elem)
		end),
	}
	
	box.content:add(clickbox)
	return box
end

function makeButton(label, size, func, highlightColor, parent, alignment)
	alignment = alignment or "Center"
return mb({
		name = 'text',
		type = ui.TYPE.Text,
		props = {
			relativePosition = TEXT_ALIGNMENT_LOCATIONS[alignment],
			anchor = TEXT_ALIGNMENT_LOCATIONS[alignment],
			text = tostring(label),
			textColor = textColor,
			textShadow = true,
			textShadowColor = util.color.rgb(0,0,0),
			textSize = textSize,
			textAlignH = ui.ALIGNMENT[alignment],
			textAlignV = ui.ALIGNMENT.Center,
		},
	}, size, func, highlightColor, parent)
end

function makeIconButton(icon, size, func, highlightColor, parent)
return mb({
	type = ui.TYPE.Image,
	props = {
		resource = getTexture(icon),
		--alpha = 1,
		color = goldenMix2,
		relativeSize = v2(1,1),
	}}, size, func, highlightColor, parent)
end

function makeIconButton2(icon, size, func, highlightColor, parent)
return mb({
	type = ui.TYPE.Image,
	props = {
		resource = getTexture(icon),
		--alpha = 1,
		color = goldenMix2,
		relativePosition = v2(0.5,0.5),
		anchor = v2(0.5,0.5),
		relativeSize = v2(0.9,0.9),
	}}, size, func, highlightColor, parent)
end

-- ============================================================================================================================== BUTTON FUNCTIONS ==============================================================================================================================

function deleteLocation(index)
	if index > 0 and index <= #teleportLocations then
		local locationName = teleportLocations[index].name
		table.remove(teleportLocations, index)
		refreshTeleportList()
		titleText.props.text = ""..#teleportLocations.."/"..getMaxMarks().." Marks"
		teleportWindow:update()
	end
end

function moveLocationToTop(index)
	if index > 1 and index <= #teleportLocations then
		local location = teleportLocations[index]
		table.remove(teleportLocations, index)
		table.insert(teleportLocations, 1, location)
		refreshTeleportList()
	end
end

function moveLocationUp(index)
	if index > 1 and index <= #teleportLocations then
		local location = teleportLocations[index]
		teleportLocations[index] = teleportLocations[index - 1]
		teleportLocations[index - 1] = location
		refreshTeleportList()
	end
end

function moveLocationToBottom(index)
	if index > 0 and index <= #teleportLocations then
		local location = teleportLocations[index]
		table.remove(teleportLocations, index)
		table.insert(teleportLocations, location)
		refreshTeleportList()
	end
end

function moveLocationDown(index)
	if index > 0 and index < #teleportLocations then
		local location = teleportLocations[index]
		teleportLocations[index] = teleportLocations[index + 1]
		teleportLocations[index + 1] = location
		refreshTeleportList()
	end
end

-- Replace the existing renameLocation function with:
function renameLocation(index)
    if index > 0 and index <= #teleportLocations then
        local currentName = teleportLocations[index].name
        
        renameDialog.show(index, currentName, 
            -- onConfirm callback
            function(locationIndex, newName)
                if locationIndex > 0 and locationIndex <= #teleportLocations then
                    teleportLocations[locationIndex].name = newName
                    -- Save the data
                    saveData.locations = teleportLocations
                    -- Refresh the list to show the new name
                    refreshTeleportList()
                    --teleportWindow:update()
                    print("Location renamed to: " .. newName)
                end
            end,
            -- onCancel callback
            function()
                print("Rename cancelled")
            end
        )
    end
end



-- ============================================================================================================================== UI ROOT ==============================================================================================================================

local layerId = ui.layers.indexOf("HUD")
local screenSize = ui.layers[layerId].size

teleportWindow = ui.create({
	type = ui.TYPE.Container,
	layer = 'Modal',
	name = "teleportWindow",
	template = rootBorderTemplate,
	props = {
		relativePosition = v2(0.5,0.45),
		anchor = v2(0.5,0.5),
		position = windowPos or v2(0,0),
	},
	content = ui.content {}
})

local mainFlex = {
	type = ui.TYPE.Flex,
	name = 'mainFlex',
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Start,
		horizontal = false,
	},
	content = ui.content {}
}
teleportWindow.layout.content:add(mainFlex)

-- ============================================================================================================================== TOP BAR ==============================================================================================================================

local topBar = {
	type = ui.TYPE.Widget,
	props = {
		size = v2(listWidth + spacer*2, textSize*1.4),
	},
	content = ui.content {}
}
mainFlex.content:add(topBar)

topBarBackground = {
	type = ui.TYPE.Image,
	props = {
		resource = getTexture('white'),
		alpha = 0,
		color = morrowindGold,
		relativeSize = v2(1,1),
	},
}
topBar.content:add(topBarBackground)

-- Drag & Drop Events für Top Bar
topBar.events = {
	mousePress = async:callback(function(data, elem)
		if data.button == 1 then
			if not elem.userData then
				elem.userData = {}
			end
			elem.userData.isDragging = true
			elem.userData.dragStartPosition = data.position
			elem.userData.windowStartPosition = teleportWindow.layout.props.position or v2(0, 0)
		end
		topBarBackground.props.alpha = 0.2
		teleportWindow:update()
	end),
	
	mouseRelease = async:callback(function(data, elem)
		if elem.userData then
			elem.userData.isDragging = false
		end
		topBarBackground.props.alpha = 0.1
		teleportWindow:update()
	end),
	
	mouseMove = async:callback(function(data, elem)
		if elem.userData and elem.userData.isDragging then
			local deltaX = data.position.x - elem.userData.dragStartPosition.x
			local deltaY = data.position.y - elem.userData.dragStartPosition.y
			local newPosition = v2(
				elem.userData.windowStartPosition.x + deltaX,
				elem.userData.windowStartPosition.y + deltaY
			)
			windowPos = newPosition
			teleportWindow.layout.props.position = newPosition
			teleportWindow:update()
		end
	end),
	
	focusGain = async:callback(function(_, elem)
		topBarBackground.props.alpha = 0.1
		teleportWindow:update()
	end),
	
	focusLoss = async:callback(function(_, elem)
		if elem.userData then
			elem.userData.isDragging = false
		end
		topBarBackground.props.alpha = 0
		teleportWindow:update()
	end)
}

-- Top Bar Title
titleText = {
	type = ui.TYPE.Text,
	props = {
		relativePosition = v2(0.5, 0.5),
		anchor = v2(0.5, 0.5),
		text = ""..#teleportLocations.."/"..getMaxMarks().." Marks",
		textColor = textColor,
		textShadow = true,
		textShadowColor = util.color.rgb(0,0,0),
		textSize = textSize,
		textAlignH = ui.ALIGNMENT.Center,
		textAlignV = ui.ALIGNMENT.Center,
	}
}
topBar.content:add(titleText)

-- Close Button
xButton = makeIconButton("textures/puremultimark/x.png", v2(textSize*1.2, textSize*1.2), function() 
	destroyTeleportWindow()
	cancelCasting()
end,nil,teleportWindow)


xButton.props.relativePosition = v2(1,0.5)
xButton.props.position = v2(-spacer,0)
xButton.props.anchor = v2(1,0.5)
topBar.content:add(xButton)

-- Skip Button
local skipButton = makeButton("Latest", v2(textSize*3.5, textSize*1.2), function()
	destroyTeleportWindow()
	selectedMark(0)
end,nil,teleportWindow)
skipButton.props.relativePosition = v2(0,0.5)
skipButton.props.position = v2(spacer,0)
skipButton.props.anchor = v2(0,0.5)
topBar.content:add(skipButton)

-- ============================================================================================================================== CONTENT ==============================================================================================================================

local contentContainer = {
	type = ui.TYPE.Widget,
	props = {
		size = v2(listWidth + spacer*2, listHeight),
	},
	content = ui.content {}
}
mainFlex.content:add(contentContainer)

-- Linke Seite: Teleport Liste
listBox = ui.create {
	type = ui.TYPE.Flex,
	template = nil,
	name = 'listBox',
	props = {
		autoSize = false,
		arrange = ui.ALIGNMENT.Start,
		horizontal = true,
		size = v2(listWidth + spacer*2, listHeight),
		position = v2(0, 0),
	},
	content = ui.content {}
}
contentContainer.content:add(listBox)
listBox.layout.content:add{ props = { size = v2(1, 1) * spacer*1 } }


local teleportList = {
	type = ui.TYPE.Flex,
	name = 'teleportList',
	props = {
		arrange = ui.ALIGNMENT.Start,
		horizontal = false,
		autoSize = false,
	},
	content = ui.content {}
}
listBox.layout.content:add(teleportList)

-- ============================================================================================================================== SCROLLBAR ==============================================================================================================================

local scrollbarContainer = {
	type = ui.TYPE.Widget,
	props = {
		size = v2(0,0),
		relativeSize = v2(0,1),
	},
	content = ui.content {}
}

scrollbarBackground = {
	type = ui.TYPE.Image,
	props = {
		resource = getTexture('white'),
		tileH = false,
		tileV = false,
		relativePosition = v2(0,0),
		relativeSize = v2(1,1),
		alpha = 0.625,
		color = util.color.rgb(0,0,0),
	},
	
	events = {
		mousePress = async:callback(function(data, elem)
			local thumbIsDragging = scrollbarThumb.userData and scrollbarThumb.userData.isDragging
			
			if not thumbIsDragging and data.button == 1 then
				local scrollContainerHeight = listHeight
				local thumbHeight = scrollbarThumb.props.relativeSize.y * scrollContainerHeight
				local currentThumbY = scrollbarThumb.props.relativePosition.y * scrollContainerHeight
				local clickY = data.offset.y
				
				local newThumbY
				if clickY < currentThumbY then
					newThumbY = currentThumbY - thumbHeight
				else
					newThumbY = currentThumbY + thumbHeight
				end
				
				local availableScrollDistance = scrollContainerHeight - thumbHeight
				newThumbY = math.max(0, math.min(availableScrollDistance, newThumbY))
				
				if availableScrollDistance > 0 then
					local newScrollPosition = newThumbY / availableScrollDistance
					local totalLocations = #teleportLocations
					local maxScrollIndex = math.max(1, totalLocations - LIST_ENTRIES + 1)
					currentScrollPos = math.floor(newScrollPosition * (maxScrollIndex - 1)) + 1
					refreshTeleportList()
				end
			end
		end),
		
		focusGain = async:callback(function(_, elem)
			elem.props.alpha = 0.1
			elem.props.color = morrowindGold
			listBox:update()
		end),
		
		focusLoss = async:callback(function(_, elem)
			elem.props.alpha = 0.625
			elem.props.color = util.color.rgb(0,0,0)
			listBox:update()
		end),
	}
}

scrollbarThumb = {
	type = ui.TYPE.Image,
	props = {
		resource = getTexture('white'),
		relativePosition = v2(0,0),
		relativeSize = v2(1,0),
		alpha = 0.4,
		color = morrowindGold,
	},

	events = {
		mouseRelease = async:callback(function(data, elem)
			if elem.userData then
				elem.userData.isDragging = false
			end
		end),
		
		mousePress = async:callback(function(data, elem)
			if data.button == 1 then
				if not elem.userData then
					elem.userData = {}
				end
				
				elem.userData.isDragging = true
				elem.userData.dragStartY = data.position.y
				
				-- Berechne aktuelle Scroll-Position exakt wie im Original
				local visibleLocations = 0
				local absolutePosition = 0
				local foundCurrentPosition = false
				
				for i = 1, #teleportLocations do
					visibleLocations = visibleLocations + 1
					if not foundCurrentPosition then
						if i - 1 ~= currentScrollPos then
							absolutePosition = absolutePosition + 1
						else
							foundCurrentPosition = true
						end
					end
				end
				
				if not foundCurrentPosition then
					absolutePosition = 0
				end
				
				if visibleLocations > LIST_ENTRIES then
					local maxScrollPosition = visibleLocations - LIST_ENTRIES
					elem.userData.dragStartScrollPosition = absolutePosition / maxScrollPosition
				else
					elem.userData.dragStartScrollPosition = 0
				end
				
				elem.userData.dragStartThumbY = elem.props.relativePosition.y * listHeight
			end
		end),
		
		mouseMove = async:callback(function(data, elem)
			if elem.userData and elem.userData.isDragging then
				local scrollContainerHeight = listHeight
				local thumbHeight = elem.props.relativeSize.y * scrollContainerHeight
				local availableScrollDistance = scrollContainerHeight - thumbHeight
				
				if availableScrollDistance > 0 then
					local deltaY = data.position.y - elem.userData.dragStartY
					local newThumbY = math.max(0, math.min(availableScrollDistance, elem.userData.dragStartThumbY + deltaY))
					
					local newScrollPosition = math.max(0, math.min(1, newThumbY / availableScrollDistance))
					local maxScrollPosition = math.max(1, #teleportLocations - LIST_ENTRIES + 1)
					local newIndex = math.floor(newScrollPosition * (maxScrollPosition - 1)+0.5) + 1
					
					if newIndex ~= currentScrollPos then
						currentScrollPos = newIndex
						refreshTeleportList()
					end
				end
			end
		end),
		
		focusGain = async:callback(function(_, elem)
			elem.props.alpha = 0.8
			listBox:update()
		end),
		
		focusLoss = async:callback(function(_, elem)
			elem.props.alpha = 0.4
			listBox:update()
		end),
	}
}

scrollbarContainer.content:add(scrollbarBackground)
scrollbarContainer.content:add(scrollbarThumb)
listBox.layout.content:add(scrollbarContainer)

-- ============================================================================================================================== TELEPORT BUTTONS ==============================================================================================================================

function makeTeleportButton(location, index, showEntryAbove)   
	local box = {
		name = location.name .. "Button",
		type = ui.TYPE.Widget,
		props = {
			size = v2(0, textSize * lineHeightMultiplier),
			relativeSize = v2(1,0)
		},
		content = ui.content {}
	}
	
	local background = {
		name = 'background',
		template = listBorders and borderTemplate or nil,
		type = ui.TYPE.Image,
		props = {
			relativeSize = util.vector2(1, 1),
			resource = getTexture('white'),
			color = darkenColor(textColor,0.1),
			alpha = 0,
		},
	}
	box.content:add(background)
	
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
	
	
	-- Location Name (clickable for teleport)
	local nameButton = makeButton(" "..location.name.." ", v2(listWidth - math.floor(textSize * lineHeightMultiplier * lineHeight2)*3-4-2-currentScrollbarWidth, textSize * lineHeightMultiplier * lineHeight2), function()
		selectedMark(index)
		destroyTeleportWindow()
	end, nil, listBox, TEXT_ALIGNMENT)
	if index == controllerRow and controllerColumn == 1 then
		if controllerConfirmDown then
			nameButton.content.clickbox.userData.focus = 2
		else
			nameButton.content.clickbox.userData.focus = 1
		end
		nameButton.content.clickbox.userData.applyColor()
	end
	contentFlex.content:add(nameButton)
	
	contentFlex.content:add{ props = { size = v2(4, 1) } }
	
	---- Rename Button
	--local renameButton = makeButton("R", v2(textSize * lineHeightMultiplier * lineHeight2, textSize * lineHeightMultiplier * lineHeight2), function()
	--	renameLocation(index)
	--end,nil,listBox)
	--contentFlex.content:add(renameButton)
	--
	--contentFlex.content:add{ props = { size = v2(2, 1) } }
	
	-- Rename Button
	local renameButton = makeIconButton2("textures/puremultimark/"..RENAME_ICON..".png", v2(textSize * lineHeightMultiplier * lineHeight2, textSize * lineHeightMultiplier * lineHeight2), function()
		renameLocation(index)
	end,nil,listBox)
	contentFlex.content:add(renameButton)
	
	-- Sort Button
	local sortButton
	if (SORT_DIRECTION == "Down" or index == 1) and index < #teleportLocations then
		sortButton = makeIconButton("textures/puremultimark/down.png", v2(textSize * lineHeightMultiplier * lineHeight2, textSize * lineHeightMultiplier * lineHeight2), function()
			if input.isShiftPressed() then
				moveLocationToBottom(index)
			else
				moveLocationDown(index)
			end
		end, nil, listBox)
	else
		sortButton = makeIconButton("textures/puremultimark/up.png", v2(textSize * lineHeightMultiplier * lineHeight2, textSize * lineHeightMultiplier * lineHeight2), function()
			if input.isShiftPressed() then
				moveLocationToTop(index)
			else
				moveLocationUp(index)
			end
		end, nil, listBox)
	end
	if index == controllerRow and controllerColumn == 2 then
		if controllerConfirmDown then
			sortButton.content.clickbox.userData.focus = 2
		else
			sortButton.content.clickbox.userData.focus = 1
		end
		sortButton.content.clickbox.userData.applyColor()
	end
	contentFlex.content:add(sortButton)
	
	-- Delete Button
	local deleteButton = makeIconButton("textures/puremultimark/x.png", v2(textSize * lineHeightMultiplier * lineHeight2, textSize * lineHeightMultiplier * lineHeight2), function()
		deleteLocation(index)
	end, util.color.rgb(1,0,0), listBox)
	if index == controllerRow and controllerColumn == 3 then
		if controllerConfirmDown then
			deleteButton.content.clickbox.userData.focus = 2
		else
			deleteButton.content.clickbox.userData.focus = 1
		end
		deleteButton.content.clickbox.userData.applyColor()
	end
	contentFlex.content:add(deleteButton)
	
	contentFlex.content:add{ props = { size = v2(4, 1) } }
	
	teleportButtons[location.name] = {
		box = box,
		background = background,
		location = location,
		index = index
	}
	if showEntryAbove then
		contentFlex.props.position = v2(0,-box.props.size.y*(1-showEntryAbove))
		box.props.size = v2(box.props.size.x,box.props.size.y*(showEntryAbove))
	end
	return box
end

-- ================================================ LIST REFRESH ================================================

function refreshTeleportList()
	teleportButtons = {}
	teleportList.content = ui.content{}

	-- Calculate scroll position and update scrollbar
	local totalLocations = #teleportLocations
	local scrollPosition = 0
	local scrollBarLength = 1
	local thumbHeight = 0
	local maxScrollIndex = totalLocations - LIST_ENTRIES +1
	if totalLocations > LIST_ENTRIES then
		thumbHeight = LIST_ENTRIES / totalLocations
		scrollPosition = (1-thumbHeight) * (currentScrollPos-1) / (maxScrollIndex-1)
	end

	if totalLocations > LIST_ENTRIES then
		scrollbarThumb.props.relativePosition = v2(0, scrollPosition)
		scrollbarThumb.props.relativeSize = v2(1, thumbHeight)
		scrollbarContainer.props.size = v2(14, 0)
		teleportList.props.size = v2(listWidth - 14, listHeight)
		currentScrollbarWidth = 14
	else
		scrollbarThumb.props.relativePosition = v2(0, 0)
		scrollbarThumb.props.relativeSize = v2(1, 0)
		scrollbarContainer.props.size = v2(0, 0)
		teleportList.props.size = v2(listWidth, listHeight)
		currentScrollbarWidth = 0
	end
	
	-- Build teleport list
	local startIndex = currentScrollPos
	local endIndex = math.min(startIndex + LIST_ENTRIES-1, totalLocations)
	local showEntryAbove = false
	if startIndex > 1 then
		if endIndex<totalLocations then
			showEntryAbove = 0.25
		else
			showEntryAbove = 0.5
		end
		startIndex = startIndex -1
	end
	for i = startIndex, math.min(totalLocations, endIndex+1) do
		local location = teleportLocations[i]
		teleportList.content:add(makeTeleportButton(location, i, showEntryAbove))
		showEntryAbove = false
		--if i < endIndex then
		--	teleportList.content:add{ props = { size = v2(1, 1) * 1 } }
		--end
	end
	
	listBox:update()
end


mainFlex.content:add{ props = { size = v2(1, 1) * spacer } }
-- ============== INITIALISIERUNG ==============

refreshTeleportList()