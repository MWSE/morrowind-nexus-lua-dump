-- Globale Hilfsfunktionen für das Crafting UI

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

function makeIcon(icon, size, text, textColor)
	local iconBox = {
		type = ui.TYPE.Widget,
		props = {
			size = v2(size, size),
		},
		content = ui.content {}
	}
	
	iconBox.content:add{
		name = 'iconBackground',
		template = borderTemplate,
		type = ui.TYPE.Image,
		props = {
			relativeSize = v2(1, 1),
			resource = getTexture('white'),
			color = darkenColor(morrowindGold, 0.1),
			alpha = 0.8,
		},
	}
	
	if icon then
		iconBox.content:add{
			type = ui.TYPE.Image,
			props = {
				resource = getTexture(icon),
				relativeSize = v2(1, 1),
				relativePosition = v2(0.5, 0.5),
				anchor = v2(0.5, 0.5),
				alpha = 0.9,
				size = v2(-2,-2)
			}
		}
	end
	
	if text then
		iconBox.content:add{
			name = 'text',
			type = ui.TYPE.Text,
			props = {
				relativePosition = v2(0.5,0.5),
				anchor = v2(0.5,0.5),
				text = tostring(text),
				textColor = textColor or lightText,
				textShadow = true,
				textShadowColor = util.color.rgb(0,0,0),
				textSize = size*2/3,
				textAlignH = ui.ALIGNMENT.Center,
				textAlignV = ui.ALIGNMENT.Center,
			},
		}
	end
	return iconBox
end

function makeButton(label, size, func)
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
	
	box.content:add{
		name = 'text',
		type = ui.TYPE.Text,
		props = {
			relativePosition = v2(0.5,0.5),
			anchor = v2(0.5,0.5),
			text = tostring(label),
			textColor = textColor,
			textShadow = true,
			textShadowColor = util.color.rgb(0,0,0),
			textSize = textSize,
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
			focus = 0,
			customColor = nil
		},
	}
	
	local function applyColor(elem)
		if craftingWindow then
			if elem.userData.customColor then
				background.props.color = elem.userData.customColor
			elseif elem.userData.focus == 2 then
				background.props.color = morrowindGold
			elseif elem.userData.focus == 1 then
				background.props.color = darkenColor(morrowindGold,0.7)
			else
				background.props.color = util.color.rgb(0,0,0)
			end
			craftingWindow:update()
		end
	end
	
	clickbox.events = {
		mouseRelease = async:callback(function(_, elem)
			elem.userData.focus = elem.userData.focus - 1
			if recipeButtonFocus == uniqueButtonId then
				onFrameFunctions[uniqueButtonId] = function()
					if craftingWindow and recipeButtonFocus == uniqueButtonId then
						func(elem)
						applyColor(elem)
					end
					onFrameFunctions[uniqueButtonId] = nil
				end
			end
		end),
		focusGain = async:callback(function(_, elem)
			recipeButtonFocus = uniqueButtonId
			elem.userData.focus = elem.userData.focus + 1
			applyColor(elem)
		end),
		focusLoss = async:callback(function(_, elem)
			recipeButtonFocus = nil
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

function calculateListPositionFromScrollbar(scrollBarPosition, profession, maxRecipes)
	-- Calculate total visible recipes first
	local visibleRecipes = 0
	local categoryData = {}
	
	for categoryIndex, category in ipairs(profession.categories) do
		local categoryRecipes = 0
		for _, recipe in ipairs(category.recipes) do
			if not recipe.hidden then
				categoryRecipes = categoryRecipes + 1
			end
		end
		
		if categoryRecipes > 0 then
			table.insert(categoryData, {
				categoryName = category.categoryName,
				recipeCount = categoryRecipes,
				startPosition = visibleRecipes,
				endPosition = visibleRecipes + categoryRecipes
			})
			visibleRecipes = visibleRecipes + categoryRecipes + 1
		end
	end
	
	if visibleRecipes <= maxRecipes then
		if #categoryData > 0 then
			return categoryData[1].categoryName, 0
		else
			return nil, 0
		end
	end
	
	scrollBarPosition = math.max(0, math.min(1, scrollBarPosition))
	local maxScrollPosition = visibleRecipes - maxRecipes
	local absolutePosition = math.floor(scrollBarPosition * maxScrollPosition + 0.5)
	
	local currentPosition = 0
	for _, categoryInfo in ipairs(categoryData) do
		if absolutePosition == currentPosition then
			return categoryInfo.categoryName, 0
		end
		currentPosition = currentPosition + 1
		
		if absolutePosition < currentPosition + categoryInfo.recipeCount then
			local indexInCategory = absolutePosition - currentPosition + 1
			return categoryInfo.categoryName, indexInCategory
		end
		
		currentPosition = currentPosition + categoryInfo.recipeCount
	end
	
	if #categoryData > 0 then
		local lastCategory = categoryData[#categoryData]
		return lastCategory.categoryName, lastCategory.recipeCount
	end
	
	return nil, 0
end

function moveSelection(direction, wrap)
	if not craftingWindow then return end
	if mouseTooltip then
		mouseTooltip:destroy()
		mouseTooltip = nil
	end
	
	local allVisibleRecipes = {}
	local currentSelectedIndex = nil
	
	for categoryIndex, category in ipairs(profession.categories) do
		for _, recipe in pairs(category.recipes) do
			if not recipe.hidden then
				table.insert(allVisibleRecipes, {
					recipe = recipe,
					categoryName = category.categoryName
				})
				
				if (recipe.name or recipe.id) == selectedRecipe then
					currentSelectedIndex = #allVisibleRecipes
				end
			end
		end
	end
	
	if not currentSelectedIndex and #allVisibleRecipes > 0 then
		currentSelectedIndex = 0
	end
	
	local newSelectedIndex = (currentSelectedIndex or 0) + direction
	newSelectedIndex = math.max(1, math.min(#allVisibleRecipes, newSelectedIndex))
	
	if wrap and newSelectedIndex == currentSelectedIndex then
		if newSelectedIndex == #allVisibleRecipes then
			newSelectedIndex = 1
		elseif newSelectedIndex == 1 then
			newSelectedIndex = #allVisibleRecipes
		end
	end
	
	if newSelectedIndex ~= currentSelectedIndex and allVisibleRecipes[newSelectedIndex] then
		local newSelectedRecipe = allVisibleRecipes[newSelectedIndex]
		selectedRecipe = (newSelectedRecipe.recipe.name or newSelectedRecipe.recipe.id)
		
		-- Calculate scroll position for new recipe
		local targetAbsolutePosition = 0
		local found = false
		
		for categoryIndex, category in ipairs(profession.categories) do
			local categoryRecipes = 0
			for _, recipe in ipairs(category.recipes) do
				if not recipe.hidden then
					categoryRecipes = categoryRecipes + 1
				end
			end
			
			if categoryRecipes > 0 then
				if category.categoryName == newSelectedRecipe.categoryName then
					local positionInCategory = 1
					for _, recipe in pairs(category.recipes) do
						if not recipe.hidden then
							if (recipe.name or recipe.id) == selectedRecipe then
								targetAbsolutePosition = targetAbsolutePosition + positionInCategory
								found = true
								break
							end
							positionInCategory = positionInCategory + 1
						end
					end
					break
				else
					targetAbsolutePosition = targetAbsolutePosition + categoryRecipes + 1
				end
			end
		end
		
		-- Calculate current scroll position
		local currentScrollStart = 0
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
						currentScrollStart = currentScrollStart + categoryRecipes + 1
					else
						currentScrollStart = currentScrollStart + (currentIndex or 0)
						foundCurrentPosition = true
					end
				end
			end
		end
		
		-- Check if scrolling is needed
		local scrollEnd = currentScrollStart + maxRecipes - 1
		local needsScroll = false
		local newScrollPosition = currentScrollStart
		
		if targetAbsolutePosition < currentScrollStart then
			newScrollPosition = targetAbsolutePosition
			needsScroll = true
		elseif targetAbsolutePosition > scrollEnd then
			newScrollPosition = targetAbsolutePosition - maxRecipes + 1
			needsScroll = true
		end
		
		-- Apply scrolling if needed
		if needsScroll then
			local totalVisibleRecipes = 0
			for categoryIndex, category in ipairs(profession.categories) do
				local categoryRecipes = 0
				for _, recipe in ipairs(category.recipes) do
					if not recipe.hidden then
						categoryRecipes = categoryRecipes + 1
					end
				end
				if categoryRecipes > 0 then
					totalVisibleRecipes = totalVisibleRecipes + categoryRecipes + 1
				end
			end
			
			local maxScrollPosition = math.max(0, totalVisibleRecipes - maxRecipes)
			newScrollPosition = math.max(0, math.min(maxScrollPosition, newScrollPosition))
			
			-- Convert back to category/index
			local runningTotal = 0
			currentSubcategory = nil
			currentIndex = nil
			
			for categoryIndex, category in ipairs(profession.categories) do
				local categoryRecipes = 0
				for _, recipe in ipairs(category.recipes) do
					if not recipe.hidden then
						categoryRecipes = categoryRecipes + 1
					end
				end
				
				if categoryRecipes > 0 then
					local categoryTotal = categoryRecipes + 1
					if newScrollPosition < runningTotal + categoryTotal then
						currentSubcategory = category.categoryName
						currentIndex = newScrollPosition - runningTotal
						break
					end
					runningTotal = runningTotal + categoryTotal
				end
			end
		end
		
		refreshRecipeList()
		updateinfoContent()
	end
end

function scrollCraftingWindow(vertical)
	updateRecipeAvailability()
	if mouseTooltip then
		mouseTooltip:destroy()
		mouseTooltip = nil
	end
	
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
	
	if visibleRecipes > 0 then
		local oldAbsolutePosition = absolutePosition
		local newAbsolutePosition = oldAbsolutePosition - vertical
		
		local maxScrollPosition = math.max(0, visibleRecipes - maxRecipes)
		newAbsolutePosition = math.max(0, math.min(maxScrollPosition, newAbsolutePosition))
		
		if newAbsolutePosition == oldAbsolutePosition then
			if newAbsolutePosition == 0 then
				newAbsolutePosition = maxScrollPosition
			else
				newAbsolutePosition = 0
			end
		end
		
		if newAbsolutePosition ~= oldAbsolutePosition then
			local runningTotal = 0
			currentSubcategory = nil
			currentIndex = nil
			
			for categoryIndex, category in ipairs(profession.categories) do
				local categoryRecipes = 0
				for _, recipe in ipairs(category.recipes) do
					if not recipe.hidden then
						categoryRecipes = categoryRecipes + 1
					end
				end
				
				if categoryRecipes > 0 then
					local categoryTotal = categoryRecipes + 1
					if newAbsolutePosition < runningTotal + categoryTotal then
						currentSubcategory = category.categoryName
						currentIndex = newAbsolutePosition - runningTotal
						break
					end
					runningTotal = runningTotal + categoryTotal
				end
			end
			refreshRecipeList()
		end
	end
end

function destroyCraftingWindow()
	if craftingWindow then
		leftBox:destroy()
		leftBox = nil
		infoContent:destroy()
		infoContent = nil
		craftingWindow:destroy()
		craftingWindow = nil
		if mouseTooltip then
			mouseTooltip:destroy()
			mouseTooltip = nil
		end
	end
end


