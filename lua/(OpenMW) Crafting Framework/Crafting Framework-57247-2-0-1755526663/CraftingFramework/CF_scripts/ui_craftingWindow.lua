-- Cleanup und Initialisierung
destroyCraftingWindow()
updateRecipeAvailability()
--print("recreate")

-- Konfiguration
borderOffset = 1
borderFile = "thin"
lineHeightMultiplier = 1.3
spacer = 5
listBorders = false

-- Globale UI Variablen
recipeButtonFocus = nil
recipeButtons = {}
infoContent = nil
scrollbarBackground = nil
scrollbarThumb = nil
topBarBackground = nil
xButton = nil

-- Border Templates
borderTemplate = makeBorder(borderFile, nil, borderOffset, {
	type = ui.TYPE.Image,
	props = {
		relativeSize = v2(1,1),
		alpha = 0.3,
	}
}).borders

local panelBorderTemplate = makeBorder(borderFile, util.color.rgb(0.5,0.5,0.5), borderOffset, {
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

-- Hilfsfunktionen
function getSelectedRecipe()
	for _, category in ipairs(profession.categories) do
		for _, r in pairs(category.recipes) do
			if (r.name or r.id) == selectedRecipe then
				return r
			end
		end
	end
	return nil
end

function updateAllRecipeButtons()
	for _, buttonData in pairs(recipeButtons) do
		if (buttonData.recipe.name or buttonData.recipe.id) == selectedRecipe then
			buttonData.background.props.color = selectedColor
			buttonData.background.props.alpha = 0.8
		else
			buttonData.background.props.color = darkenColor(textColor,0.05)
			buttonData.background.props.alpha = 0
		end
	end
	leftBox:update()
end

-- ============== UI ERSTELLUNG ==============

-- Hauptfenster erstellen
local layerId = ui.layers.indexOf("HUD")
local screenSize = ui.layers[layerId].size

craftingWindow = ui.create({
	type = ui.TYPE.Container,
	layer = 'Modal',
	name = "craftingWindow",
	template = rootBorderTemplate,
	props = {
		relativePosition = v2(0.5,0.45),
		anchor = v2(0.5,0.5),
		position = windowPos,
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
craftingWindow.layout.content:add(mainFlex)

-- ============== TOP BAR ==============

local topBar = {
	type = ui.TYPE.Widget,
	props = {
		size = v2(descriptionWidth + listWidth + spacer*2+1, textSize*1.4),
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
			elem.userData.windowStartPosition = craftingWindow.layout.props.position or v2(0, 0)
		end
		topBarBackground.props.alpha = 0.2
		craftingWindow:update()
	end),
	
	mouseRelease = async:callback(function(data, elem)
		if elem.userData then
			elem.userData.isDragging = false
		end
		topBarBackground.props.alpha = 0.1
		craftingWindow:update()
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
			craftingWindow.layout.props.position = newPosition
			craftingWindow:update()
		end
	end),
	
	focusGain = async:callback(function(_, elem)
		topBarBackground.props.alpha = 0.1
		craftingWindow:update()
	end),
	
	focusLoss = async:callback(function(_, elem)
		if elem.userData then
			elem.userData.isDragging = false
		end
		topBarBackground.props.alpha = 0
		craftingWindow:update()
	end)
}

-- Top Bar Buttons
local filterButton = makeButton("Filter Recipes", v2(textSize*8, textSize*1), function(elem) 
	filterRecipes = not filterRecipes
	if filterRecipes then
		elem.userData.customColor = morrowindGold
	else
		elem.userData.customColor = nil
	end
	updateRecipeAvailability(true)
	refreshRecipeList()
end)

if filterRecipes then
	filterButton.content.background.props.color = morrowindGold
	filterButton.content.clickbox.userData.customColor = morrowindGold
end	
filterButton.props.position = v2(spacer,0)
filterButton.props.relativePosition = v2(0,0.5)
filterButton.props.anchor = v2(0,0.5)
topBar.content:add(filterButton)

xButton = makeButton("X", v2(textSize*1, textSize*1), function() 
	destroyCraftingWindow()
	I.UI.setMode('Interface', {windows = {'Map', 'Stats', 'Magic', 'Inventory'}})
end)
xButton.props.relativePosition = v2(1,0.5)
xButton.props.position = v2(-spacer,0)
xButton.props.anchor = v2(1,0.5)
topBar.content:add(xButton)

local clearQueueButton = makeButton("Clear Queue", v2(textSize*6, textSize*1), function() 
	clearCraftingQueue()
	refreshRecipeList()
	updateinfoContent()
end)
clearQueueButton.props.position = v2(-textSize-spacer-3,0)
clearQueueButton.props.relativePosition = v2(1,0.5)
clearQueueButton.props.anchor = v2(1,0.5)
topBar.content:add(clearQueueButton)

local touchButton = makeButton("Artisan's touch", v2(textSize*8, textSize*1), function(elem) 
	artisansTouch = not artisansTouch
	if artisansTouch then
		elem.userData.customColor = morrowindGold
	else
		elem.userData.customColor = nil
	end
	if filterRecipes then
		updateRecipeAvailability(true)
	end
	refreshRecipeList()
	updateinfoContent()
	craftingWindow:update()
end)

touchButton.props.relativePosition = v2(0.5,0.5)
touchButton.props.anchor = v2(0.5,0.5)

if artisansTouch then
	touchButton.content.background.props.color = morrowindGold
	touchButton.content.clickbox.userData.customColor = morrowindGold
end	
topBar.content:add(touchButton)

-- ============== CONTENT AREA ==============

local contentFlex = {
	type = ui.TYPE.Flex,
	name = 'contentFlex',
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Start,
		horizontal = true,
	},
	content = ui.content {}
}
mainFlex.content:add(contentFlex)
contentFlex.content:add{ props = { size = v2(1, 1) * spacer } }

-- Linke Seite: Recipe Liste
leftBox = ui.create {
	type = ui.TYPE.Flex,
	template = panelBorderTemplate,
	name = 'leftBox',
	props = {
		autoSize = false,
		arrange = ui.ALIGNMENT.Start,
		horizontal = true,
		size = v2(listWidth, maxRecipes * textSize * lineHeightMultiplier),
	},
	content = ui.content {}
}
contentFlex.content:add(leftBox)

local recipeList = {
	type = ui.TYPE.Flex,
	name = 'recipeList',
	props = {
		arrange = ui.ALIGNMENT.Start,
		horizontal = false,
		autoSize = false,
	},
	content = ui.content {}
}
leftBox.layout.content:add(recipeList)

-- ============== SCROLLBAR ==============

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
				local scrollContainerHeight = maxRecipes * textSize * lineHeightMultiplier
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
				
				local newScrollPosition = math.max(0, math.min(1, newThumbY / availableScrollDistance))
				local newSubcategory, newIndex = calculateListPositionFromScrollbar(newScrollPosition, profession, maxRecipes)
				
				currentSubcategory = newSubcategory
				currentIndex = newIndex
				refreshRecipeList()
			end
		end),
				
		focusGain = async:callback(function(_, elem)
			elem.props.alpha = 0.1
			elem.props.color = morrowindGold
			leftBox:update()
		end),
		
		focusLoss = async:callback(function(_, elem)
			elem.props.alpha = 0.625
			elem.props.color = util.color.rgb(0,0,0)
			leftBox:update()
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
				
				-- Berechne aktuelle Scroll-Position
				local visibleRecipes = 0
				local absolutePosition = 0
				local foundCurrentPosition = false
				
				for categoryIndex, category in ipairs(profession.categories) do
					local categoryRecipes = 0
					for _, recipe in ipairs(category.recipes) do
						if not recipe.hidden then
							categoryRecipes = categoryRecipes + 1
						end
					end
					
					if categoryRecipes > 0 then
						if not foundCurrentPosition and currentSubcategory ~= nil then
							if category.categoryName ~= currentSubcategory then
								absolutePosition = absolutePosition + categoryRecipes + 1
							else
								absolutePosition = absolutePosition + (currentIndex or 0)
								foundCurrentPosition = true
							end
						end
						visibleRecipes = visibleRecipes + categoryRecipes + 1
					end
				end
				
				if not foundCurrentPosition then
					absolutePosition = 0
				end
				
				if visibleRecipes > maxRecipes then
					local maxScrollPosition = visibleRecipes - maxRecipes
					elem.userData.dragStartScrollPosition = absolutePosition / maxScrollPosition
				else
					elem.userData.dragStartScrollPosition = 0
				end
				
				elem.userData.dragStartThumbY = elem.props.relativePosition.y * (maxRecipes * textSize * lineHeightMultiplier)
			end
		end),
		
		mouseMove = async:callback(function(data, elem)
			if elem.userData and elem.userData.isDragging then
				local scrollContainerHeight = maxRecipes * textSize * lineHeightMultiplier
				local thumbHeight = elem.props.relativeSize.y * scrollContainerHeight
				local availableScrollDistance = scrollContainerHeight - thumbHeight
				
				if availableScrollDistance > 0 then
					local deltaY = data.position.y - elem.userData.dragStartY
					local newThumbY = math.max(0, math.min(availableScrollDistance, elem.userData.dragStartThumbY + deltaY))
					
					local newScrollPosition = math.max(0, math.min(1, newThumbY / availableScrollDistance))
					local newSubcategory, newIndex = calculateListPositionFromScrollbar(newScrollPosition, profession, maxRecipes)
					
					if newSubcategory ~= currentSubcategory or newIndex ~= currentIndex then
						currentSubcategory = newSubcategory
						currentIndex = newIndex
						refreshRecipeList()
					end
				end
			end
		end),
		
		focusGain = async:callback(function(_, elem)
			elem.props.alpha = 0.8
			leftBox:update()
		end),
		
		focusLoss = async:callback(function(_, elem)
			elem.props.alpha = 0.4
			leftBox:update()
		end),
	}
}

scrollbarContainer.content:add(scrollbarBackground)
scrollbarContainer.content:add(scrollbarThumb)
leftBox.layout.content:add(scrollbarContainer)

contentFlex.content:add{ props = { size = v2(1, 1) * spacer*2 } }

-- ============== RECHTE SEITE: INFO PANEL ==============

local rightPanel = {
	type = ui.TYPE.Flex,
	name = 'rightPanel',
	props = {
		relativeSize = v2(0, 1),
		size = v2(descriptionWidth,0),
		arrange = ui.ALIGNMENT.Start,
		horizontal = false,
	},
	content = ui.content {}
}
contentFlex.content:add(rightPanel)

local infoContainer = {
	type = ui.TYPE.Widget,
	template = panelBorderTemplate,
	props = {
		size = v2(descriptionWidth-8, (maxRecipes-1) * textSize * lineHeightMultiplier),
	},
	content = ui.content {}
}
rightPanel.content:add(infoContainer)

infoContent = ui.create {
	type = ui.TYPE.Flex,
	props = {
		relativeSize = v2(1, 1),
		position = v2(spacer, 0),
		anchor = v2(0, 0),
		size = v2(descriptionWidth,500),
		text = "Select a recipe to see its description.",
		textColor = textColor,
		textShadow = true,
		textShadowColor = util.color.rgba(0,0,0,1),
		textSize = textSize - 2,
		textAlignH = ui.ALIGNMENT.Start,
		textAlignV = ui.ALIGNMENT.Start,
		multiline = true,
		wordWrap = true,
	},
}
infoContainer.content:add(infoContent)

-- Crafting Buttons
local craftingButtonFlex = {
	type = ui.TYPE.Flex,
	name = 'craftingButtonFlex',
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Start,
		horizontal = true,
	},
	content = ui.content {}
}
rightPanel.content:add(craftingButtonFlex)

function updateCraftingButtonFlex()
	craftingButtonFlex.content = ui.content{}
	
	craftingButtonFlex.content:add(makeButton("Craft 1", v2(textSize*4, textSize*lineHeightMultiplier), function() 
		local recipe = getSelectedRecipe()
		if recipe and checkIngredientsWithQueue(recipe, #craftingQueue) >= 1 and not recipe.disabled then
			addToCraftingQueue(recipe, 1)
		end
	end))
	
	craftingButtonFlex.content:add{ props = { size = v2(4, 1) } }
	
	craftingButtonFlex.content:add(makeButton("Craft All", v2(textSize*5, textSize*lineHeightMultiplier), function() 
		local recipe = getSelectedRecipe()
		if recipe then
			local maxCraft = checkIngredientsWithQueue(recipe, #craftingQueue)
			if maxCraft > 0 and not recipe.disabled then
				addToCraftingQueue(recipe, maxCraft)
			end
		end
	end))
end

updateCraftingButtonFlex()
mainFlex.content:add{ props = { size = v2(0, 1) * spacer } }

-- ============== RECIPE BUTTON ERSTELLUNG ==============

function makeRecipeButton(recipe)   
	local box = {
		name = (recipe.name or recipe.id) .. "Button",
		type = ui.TYPE.Widget,
		props = {
			size = v2(0, textSize* lineHeightMultiplier),
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
	
	local resultRecord
	if recipe.type and types[recipe.type] and recipe.id then
		resultRecord = types[recipe.type].records[recipe.id]
	end
	
	contentFlex.content:add{ props = { size = v2(1, 1) * 1 } }
	local icon = recipe.icon or (resultRecord and resultRecord.icon)
	local iconSize = textSize*lineHeightMultiplier
	contentFlex.content:add(makeIcon(icon, iconSize, recipe.level, checkSkill(recipe) < 0 and util.color.rgb(1,0,0) or nil))
	contentFlex.content:add{ props = { size = v2(1, 1) * 2 } }
	
	local nameText = recipe.name or (resultRecord and resultRecord.name) or ("ERROR: "..(recipe.id or "no id"))
	local textColor = recipe.textColor or goldenMix
	local maxCount = checkIngredientsWithQueue(recipe, #craftingQueue)
	if maxCount > 0 then
		nameText = nameText.." ["..maxCount.."]"
	end
	
	contentFlex.content:add{
		type = ui.TYPE.Text,
		props = {
			text = tostring(nameText),
			textColor = textColor,
			textShadow = true,
			textShadowColor = util.color.rgba(0,0,0,1),
			textSize = textSize,
			textAlignH = ui.ALIGNMENT.Start,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = true,
		},
	}
	
	contentFlex.content:add{ props = { size = v2(1, 1) * 1 } }
	
	recipeButtons[(recipe.name or recipe.id)] = {
		box = box,
		background = background,
		recipe = recipe
	}
	
	local clickbox = {
		name = 'clickbox',
		props = {
			relativeSize = util.vector2(1, 1),
			relativePosition = v2(0,0),
			anchor = v2(0,0),
		},
		userData = {
			recipe = recipe
		},
	}
	
	clickbox.events = {
		mouseRelease = async:callback(function(_, elem)
			if recipeButtonFocus == (elem.userData.recipe.name or elem.userData.recipe.id) then
				selectedRecipe = (elem.userData.recipe.name or elem.userData.recipe.id)
				updateAllRecipeButtons()
				updateinfoContent()
			end
		end),
		focusGain = async:callback(function(_, elem)
			recipeButtonFocus = (elem.userData.recipe.name or elem.userData.recipe.id)
			if selectedRecipe ~= (elem.userData.recipe.name or elem.userData.recipe.id) then
				background.props.color = hoverColor
				background.props.alpha = 0.8
				leftBox:update()
			end
			if not mouseTooltip then
				if types[elem.userData.recipe.type] then
					mouseTooltip = makeMouseTooltip(types[elem.userData.recipe.type].records[elem.userData.recipe.id], calculateResultValue(elem.userData.recipe, artisansTouch), elem.userData.recipe.name, calculateQuality(elem.userData.recipe, artisansTouch))
				end
			end
		end),
		focusLoss = async:callback(function(_, elem)
			recipeButtonFocus = nil
			if selectedRecipe == (elem.userData.recipe.name or elem.userData.recipe.id) then
				background.props.color = selectedColor
				background.props.alpha = 0.8
			else
				background.props.color = darkenColor(textColor,0.05)
				background.props.alpha = 0
			end
			if mouseTooltip then
				mouseTooltip:destroy()
				mouseTooltip = nil
			end
			leftBox:update()
		end),
		mouseMove = async:callback(function(data, elem)
			if not mouseTooltip then
				if types[elem.userData.recipe.type] then
					mouseTooltip = makeMouseTooltip(types[elem.userData.recipe.type].records[elem.userData.recipe.id], calculateResultValue(elem.userData.recipe, artisansTouch), elem.userData.recipe.name, calculateQuality(elem.userData.recipe, artisansTouch))
				end
			end
			if mouseTooltip then
				mouseTooltip.layout.props.position = v2(data.position.x+13,data.position.y+25)
				mouseTooltip:update()
			end
		end),
	}
	
	box.content:add(clickbox)
	return box
end

-- ============== INFO CONTENT UPDATE ==============

function updateinfoContent()
	if selectedRecipe then
		local recipe = getSelectedRecipe()
		infoContent.layout.content = ui.content{}
		
		if recipe then
			infoContent.layout.content:add{ props = { size = v2(1, 1) * 3 } }
			
			-- Recipe Header
			local recipeHeader = {
				type = ui.TYPE.Flex,
				props = {
					autoSize = true,
					arrange = ui.ALIGNMENT.Start,
					horizontal = true,
				},
				content = ui.content {}
			}
			
			local resultRecord
			if recipe.type and types[recipe.type] and recipe.id then
				resultRecord = types[recipe.type].records[recipe.id]
			end
			
			local icon = recipe.icon or (resultRecord and resultRecord.icon)
			local nameText = recipe.name or (resultRecord and resultRecord.name) or ("ERROR: "..(recipe.id or "no id"))
			
			if recipe.count and recipe.count ~= 1 then
				nameText = nameText.." x"..recipe.count
			end
			if recipe.level then
				nameText = nameText.." [lvl "..recipe.level.."]"
			end
			
			recipeHeader.content:add(makeIcon(icon, textSize*2))
			recipeHeader.content:add{ props = { size = v2(8, 1) } }
			
			local nameFlex = {
				type = ui.TYPE.Flex,
				props = {
					autoSize = true,
					arrange = ui.ALIGNMENT.Start,
				},
				content = ui.content {}
			}
			recipeHeader.content:add(nameFlex)
			
			nameFlex.content:add{
				type = ui.TYPE.Text,
				props = {
					text = tostring(nameText),
					textColor = recipe.textColor or goldenMix,
					textShadow = true,
					textShadowColor = util.color.rgba(0,0,0,1),
					textSize = textSize*1.1,
					textAlignH = ui.ALIGNMENT.Start,
					textAlignV = ui.ALIGNMENT.Center,
					autoSize = true,
				}
			}
			
			--local qualityMult
			--if artisansTouch then
			--	local armorerSkill = types.NPC.stats.skills.armorer(self).modified
			--	qualityMult = 1 + ( math.floor(armorerSkill/2)*2 - recipe.level)/200 + 0.05
			--end
			if types[recipe.type] then
				nameFlex.content:add(makeDescriptionTooltip(types[recipe.type].records[recipe.id], calculateResultValue(recipe, artisansTouch), nil, calculateQuality(recipe, artisansTouch)))
			end
			infoContent.layout.content:add(recipeHeader)
			infoContent.layout.content:add{ props = { size = v2(8, 8) } }
			
			selectedCount = math.max(1, selectedCount)
			selectedCount = math.min(checkIngredientsWithQueue(recipe, #craftingQueue), selectedCount)
		
			-- Description
			local flavorTextContainer = {
				type = ui.TYPE.Flex,
				props = {
					autoSize = true
				},
				content = ui.content {}
			}
			infoContent.layout.content:add(flavorTextContainer)
			
			local function addFlavorLine(text)
				flavorTextContainer.content:add{
					type = ui.TYPE.Text,
					props = {
						text = tostring(text),
						textColor = morrowindGold,
						textShadow = true,
						textShadowColor = util.color.rgba(0,0,0,1),
						textSize = textSize - 2,
						textAlignH = ui.ALIGNMENT.Start,
						textAlignV = ui.ALIGNMENT.Start,
					},
				}
			end
			
			infoContent.layout.content:add{ props = { size = v2(1, 1) * 10 } }
			local recipeDescription = recipe.description or ""
			local limit = #recipeDescription > 50 and #recipeDescription < 80 and 40 or 50
			local line = ""
			for word in recipeDescription:gmatch("%S+") do
				if #line + #word + 1 > limit then
					addFlavorLine(line)
					line = word
				else
					line = line == "" and word or line .. " " .. word
				end
			end
			if line ~= "" then addFlavorLine(line) end
			
			infoContent.layout.content:add{ props = { size = v2(1, 16) } }
			
			-- Ingredients
			infoContent.layout.content:add{
				type = ui.TYPE.Text,
				props = {
					text = "Reagents:",
					textColor = textColor,
					textShadow = true,
					textShadowColor = util.color.rgba(0,0,0,1),
					textSize = textSize,
					textAlignH = ui.ALIGNMENT.Start,
					textAlignV = ui.ALIGNMENT.Start,
					autoSize = true,
				}
			}
			
			infoContent.layout.content:add{ props = { size = v2(1, 8) } }
			
			for _, ingredient in ipairs(getIngredients(recipe, artisansTouch)) do
				local ingredientRecord, adjustedCount = checkIngredientWithQueue(ingredient)
				
				local icon = ingredient.icon or (ingredientRecord and ingredientRecord.icon)
				local nameText = ingredient.type == "wildcard" and ingredient.name or (ingredientRecord and ingredientRecord.name) or ("ERROR: "..(ingredient.id or "no id"))
				
				local ingredientRow = {
					type = ui.TYPE.Flex,
					props = {
						autoSize = true,
						arrange = ui.ALIGNMENT.Center,
						horizontal = true,
					},
					content = ui.content {}
				}
				
				local iconContainer = {
					type = ui.TYPE.Widget,
					props = {
						size = v2(textSize*2, textSize*2),
					},
					content = ui.content {}
				}
				if ingredientRecord then
					iconContainer.events = {
						focusGain = async:callback(function(_, elem)
							if not mouseTooltip then
								--local qualityMult
								--if artisansTouch then
								--	local armorerSkill = types.NPC.stats.skills.armorer(self).modified
								--	qualityMult = 1 + ( math.floor(armorerSkill/2)*2 - recipe.level)/200 + 0.05
								--end
								mouseTooltip = makeMouseTooltip(ingredientRecord, nil, true)
							end
						end),
						focusLoss = async:callback(function(_, elem)
							if mouseTooltip then
								mouseTooltip:destroy()
								mouseTooltip = nil
							end
							leftBox:update()
						end),
						mouseMove = async:callback(function(data, elem)
							if mouseTooltip then
								mouseTooltip.layout.props.position = v2(data.position.x+13,data.position.y+25)
								mouseTooltip:update()
							end
						end),
					}
				end
				
				iconContainer.content:add(makeIcon(icon, textSize*2))
				
				local countColor = adjustedCount >= ingredient.count and util.color.rgb(1, 1, 1) or util.color.rgb(1, 0.2, 0.2)
				local countText = adjustedCount .. "/" .. ingredient.count
				
				iconContainer.content:add{
					type = ui.TYPE.Text,
					props = {
						text = countText,
						textColor = countColor,
						textShadow = true,
						textShadowColor = util.color.rgba(0,0,0,1),
						textSize = textSize - 2,
						textAlignH = ui.ALIGNMENT.End,
						textAlignV = ui.ALIGNMENT.End,
						relativePosition = v2(1, 1),
						anchor = v2(1, 1),
					}
				}
				
				ingredientRow.content:add(iconContainer)
				ingredientRow.content:add{ props = { size = v2(8, 1) } }
				ingredientRow.content:add{
					type = ui.TYPE.Text,
					props = {
						text = tostring(nameText),
						textColor = adjustedCount >= ingredient.count and textColor or util.color.rgb(1, 0.5, 0.5),
						textShadow = true,
						textShadowColor = util.color.rgba(0,0,0,1),
						textSize = textSize +1,
						textAlignH = ui.ALIGNMENT.Start,
						textAlignV = ui.ALIGNMENT.Center,
						autoSize = true,
					}
				}
				
				infoContent.layout.content:add(ingredientRow)
				infoContent.layout.content:add{ props = { size = v2(1, 4) } }
			end

		else
			infoContent.layout.content:add{
				type = ui.TYPE.Text,
				props = {
					text = "Select a recipe to see its description.",
					textColor = textColor,
					textShadow = true,
					textShadowColor = util.color.rgba(0,0,0,1),
					textSize = textSize - 2,
					textAlignH = ui.ALIGNMENT.Start,
					textAlignV = ui.ALIGNMENT.Start,
					autoSize = true,
				},
			}
		end
		infoContent:update()
	end
end

-- ============== RECIPE LIST REFRESH ==============

function refreshRecipeList()
	--armorerSkill = types.NPC.stats.skills.armorer(self).modified
	recipeButtons = {}
	recipeList.content = ui.content{}

	-- Calculate visible recipes and scroll position
	local visibleRecipes = 0
	local absolutePosition = 0
	local foundCurrentPosition = false
	
	for categoryIndex, category in ipairs(profession.categories) do
		local categoryRecipes = 0
		for _, recipe in ipairs(category.recipes) do
			if not recipe.hidden then
				categoryRecipes = categoryRecipes + 1
			end
		end
		
		if categoryRecipes > 0 then
			if not foundCurrentPosition and currentSubcategory ~= nil then
				if category.categoryName ~= currentSubcategory then
					absolutePosition = absolutePosition + categoryRecipes + 1
				else
					absolutePosition = absolutePosition + (currentIndex or 0)
					foundCurrentPosition = true
				end
			end
			visibleRecipes = visibleRecipes + categoryRecipes + 1
		end
	end
	
	if not foundCurrentPosition then
		--absolutePosition = 0
		--currentSubcategory = nil
		--currentIndex = nil
	end
	absolutePosition = math.min(absolutePosition, visibleRecipes-maxRecipes)
	-- Update scrollbar
	local scrollBarStart = absolutePosition / visibleRecipes
	local scrollBarEnd = math.min(1, (absolutePosition + maxRecipes) / visibleRecipes)
	local scrollBarLength = math.min(1, scrollBarEnd - scrollBarStart)
	
	if visibleRecipes > maxRecipes then
		scrollbarThumb.props.relativePosition = v2(0,scrollBarStart)
		scrollbarThumb.props.relativeSize = v2(1,scrollBarLength)
		scrollbarContainer.props.size = v2(14,0)
		recipeList.props.size = v2(listWidth-14, maxRecipes * textSize * lineHeightMultiplier)
	else
		scrollbarThumb.props.relativePosition = v2(0,0)
		scrollbarThumb.props.relativeSize = v2(1,0)
		scrollbarContainer.props.size = v2(0,0)
		recipeList.props.size = v2(listWidth, maxRecipes * textSize * lineHeightMultiplier)
	end
	
	
	-- Build recipe list
	local drawnButtons = 0
	local foundStartingPoint = not currentSubcategory
	local absPos = 0
	for _, category in ipairs(profession.categories) do
		local i = 0
		if category.categoryName == currentSubcategory and currentIndex == i then
			foundStartingPoint = true
		end
		
		if foundStartingPoint then
			if drawnButtons >= maxRecipes then break end
			
			local recipesInThisCategory = 0
			local craftableRecipes = 0
			for _, recipe in pairs(category.recipes) do
				if not recipe.hidden then
					recipesInThisCategory = recipesInThisCategory + 1
					if not recipe.disabled then
						craftableRecipes = craftableRecipes + 1
					end
				end
			end
			
			if recipesInThisCategory > 0 then
				local categoryLabel = { 
					type = ui.TYPE.Text,
					props = {
						textColor = craftableRecipes == 0 and util.color.rgb(1,0,0) or textColor,
						textShadow = true,
						textShadowColor = util.color.rgba(0,0,0,0.9),
						textAlignV = ui.ALIGNMENT.End,
						textAlignH = ui.ALIGNMENT.Start,
						text = category.categoryName and " "..category.categoryName or "",
						textSize = textSize,
						autoSize = false,
						size = v2(0, textSize* lineHeightMultiplier),
						relativeSize=v2(1,0),
					},
				}
				recipeList.content:add(categoryLabel)
				drawnButtons = drawnButtons + 1
			end
		end
		
		for _, recipe in pairs(category.recipes) do
			if not recipe.hidden then
				if i==0 then
					absPos = absPos + 1
				end
				i = i + 1
				absPos = absPos + 1
				if category.categoryName == currentSubcategory and currentIndex == i or absPos > absolutePosition then
					foundStartingPoint = true
				end
				if foundStartingPoint then
					if drawnButtons >= maxRecipes then break end
					recipeList.content:add(makeRecipeButton(recipe))
					recipeList.content:add{ props = { size = v2(1, 1) * 0.5 } }
					drawnButtons = drawnButtons + 1
				end
			end
		end 
		if drawnButtons >= maxRecipes then break end
	end
	updateAllRecipeButtons()
end

-- ============== INITIALISIERUNG ==============

refreshRecipeList()
updateinfoContent()