-- shared crafting ui helpers

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
			textSize = S_FONT_SIZE,
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

	if icon then
		iconBox.content:add{
			type = ui.TYPE.Image,
			props = {
				resource = getTexture(icon),
				relativeSize = v2(1.25, 1.25),
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
			textSize = S_FONT_SIZE,
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
		if WINDOW.craftingWindow then
			if elem.userData.customColor then
				background.props.color = elem.userData.customColor
			elseif elem.userData.focus == 2 then
				background.props.color = morrowindGold
			elseif elem.userData.focus == 1 then
				background.props.color = darkenColor(morrowindGold,0.7)
			else
				background.props.color = util.color.rgb(0,0,0)
			end
			WINDOW.craftingWindow:update()
		end
	end
	
	clickbox.events = {
		mouseRelease = async:callback(function(_, elem)
			elem.userData.focus = elem.userData.focus - 1
			if recipeButtonFocus == uniqueButtonId then
				onFrameFunctions[uniqueButtonId] = function()
					if WINDOW.craftingWindow and recipeButtonFocus == uniqueButtonId then
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

function makeIconButton(iconPath, size, func, iconSize, name)
	local uniqueButtonId = ""..math.random()
	iconSize = iconSize or (math.min(size.x, size.y) * 0.8)
	local box = {
		name = name or uniqueButtonId,
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
			resource = getTexture('white'),
			color = util.color.rgb(0, 0, 0),
			alpha = 0.75,
		},
	}
	box.content:add(background)

	local icon = {
		name = 'icon',
		type = ui.TYPE.Image,
		props = {
			resource = getTexture(iconPath),
			size = v2(iconSize, iconSize),
			relativePosition = v2(0.5, 0.5),
			anchor = v2(0.5, 0.5),
			color = textColor,
		},
	}
	box.content:add(icon)

	local clickbox = {
		name = 'clickbox',
		props = {
			relativeSize = util.vector2(1, 1),
			relativePosition = v2(0, 0),
			anchor = v2(0, 0),
		},
		userData = {
			focus = 0,
			customColor = nil
		},
	}

	local function applyColor(elem)
		if WINDOW.craftingWindow then
			if elem.userData.customColor then
				background.props.color = elem.userData.customColor
			elseif elem.userData.focus == 2 then
				background.props.color = morrowindGold
			elseif elem.userData.focus == 1 then
				background.props.color = darkenColor(morrowindGold, 0.7)
			else
				background.props.color = util.color.rgb(0, 0, 0)
			end
			WINDOW.craftingWindow:update()
		end
	end

	clickbox.events = {
		mouseRelease = async:callback(function(_, elem)
			elem.userData.focus = elem.userData.focus - 1
			if recipeButtonFocus == uniqueButtonId then
				onFrameFunctions[uniqueButtonId] = function()
					if WINDOW.craftingWindow and recipeButtonFocus == uniqueButtonId then
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

-- flat list of visible navigable items (headers + recipes)
-- entry: {type="header"|"recipe", categoryName, categoryIndex, recipe?}
-- categoryIndex: 0 for header, 1..N for recipes
-- TODO: cache and invalidate list, saves 0.5-2 ms each mouseMove
function buildVisibleList()
	local list = {}
	local query = searchEngine.parse(searchText or "")
	for _, category in ipairs(professions[currentProfessionName]) do
		local passesCategory = not activeCategoryFilter or category.categoryName == activeCategoryFilter
		if passesCategory then
			local filteredRecipes = {}
			for _, recipe in ipairs(category.recipes) do
				if recipe.visible and searchEngine.matches(recipe, category.categoryName, query) then
					table.insert(filteredRecipes, recipe)
				end
			end

			if #filteredRecipes > 0 then
				local craftableCount = 0
				for _, recipe in ipairs(filteredRecipes) do
					if not recipe.disabled then
						craftableCount = craftableCount + 1
					end
				end
				table.insert(list, {
					type = "header",
					categoryName = category.categoryName,
					categoryIndex = 0,
					craftableCount = craftableCount,
					recipeCount = #filteredRecipes,
				})

				if not collapsedCategories[category.categoryName] then
					for idx, recipe in ipairs(filteredRecipes) do
						table.insert(list, {
							type = "recipe",
							recipe = recipe,
							categoryName = category.categoryName,
							categoryIndex = idx,
						})
					end
				end
			end
		end
	end
	return list
end

function calculateListPositionFromScrollbar(scrollBarPosition, profession, S_MAX_RECIPES)
	local list = buildVisibleList()

	if #list <= S_MAX_RECIPES then
		if #list > 0 then
			return list[1].categoryName, list[1].categoryIndex
		else
			return nil, 0
		end
	end

	scrollBarPosition = math.max(0, math.min(1, scrollBarPosition))
	local maxScrollPosition = #list - S_MAX_RECIPES
	local absolutePosition = math.floor(scrollBarPosition * maxScrollPosition + 0.5)
	absolutePosition = math.max(1, math.min(#list, absolutePosition + 1))

	local item = list[absolutePosition]
	if item then
		return item.categoryName, item.categoryIndex
	end
	return nil, 0
end

function moveSelection(direction, wrap)
	if not WINDOW.craftingWindow then return end
	if WINDOW.mouseTooltip then
		WINDOW.mouseTooltip:destroy()
		WINDOW.mouseTooltip = nil
	end

	local list = buildVisibleList()
	if #list == 0 then return end

	local currentIdx = nil
	for i, item in ipairs(list) do
		if item.type == "header" and selectedHeader == item.categoryName then
			currentIdx = i
			break
		elseif item.type == "recipe" and item.recipe.uid == selectedRecipe then
			currentIdx = i
			break
		end
	end

	if not currentIdx then
		currentIdx = direction > 0 and 0 or (#list + 1)
	end

	local newIdx = currentIdx + direction
	-- flash before wrap/clamp
	if newIdx < 1 then
		triggerBumpFlash("listBumpFlashTop")
	elseif newIdx > #list then
		triggerBumpFlash("listBumpFlashBottom")
	end
	if wrap then
		if newIdx < 1 then
			newIdx = #list
		elseif newIdx > #list then
			newIdx = 1
		end
	else
		newIdx = math.max(1, math.min(#list, newIdx))
	end

	if newIdx == currentIdx then return end

	local newItem = list[newIdx]
	if not newItem then return end

	if newItem.type == "header" then
		selectedHeader = newItem.categoryName
		selectedRecipe = nil
	else
		selectedRecipe = newItem.recipe.uid
		selectedHeader = nil
	end

	-- keep newIdx visible inside the scroll window
	local currentScrollStart = 0
	local foundScrollPos = false

	if currentSubcategory then
		for i, item in ipairs(list) do
			if item.categoryName == currentSubcategory and item.categoryIndex == (currentIndex or 0) then
				currentScrollStart = i - 1
				foundScrollPos = true
				break
			end
		end
	end
	if not foundScrollPos then
		currentScrollStart = 0
	end

	local scrollEnd = currentScrollStart + S_MAX_RECIPES
	local targetPos = newIdx - 1

	local needsScroll = false
	local newScrollPos = currentScrollStart

	if targetPos < currentScrollStart then
		newScrollPos = targetPos
		needsScroll = true
	elseif targetPos >= scrollEnd then
		newScrollPos = targetPos - S_MAX_RECIPES + 1
		needsScroll = true
	end

	if needsScroll then
		local maxScroll = math.max(0, #list - S_MAX_RECIPES)
		newScrollPos = math.max(0, math.min(maxScroll, newScrollPos))

		local scrollItem = list[newScrollPos + 1]
		if scrollItem then
			currentSubcategory = scrollItem.categoryName
			currentIndex = scrollItem.categoryIndex
		else
			currentSubcategory = nil
			currentIndex = nil
		end
	end

	refreshRecipeList()
	updateinfoContent()
end

-- wraparound gate
local SCROLL_BLOCK_DURATION = 0.28
local SCROLL_BLOCK_REFRESH = 0.15
local SCROLL_FREE_DURATION = 1.1
local scrollBlockUntil = 0
local scrollFreeUntil = 0
local lastEdge = -1

-- pulse to peak, fade via onFrameFunctions; element key doubles as onFrame key
local FLASH_PEAK_ALPHA = 0.7
local FLASH_DURATION = 0.25 -- overwritten by the latest offender

triggerBumpFlash = function(elementKey)
	if not (WINDOW and WINDOW[elementKey]) then return end
	WINDOW[elementKey].layout.props.alpha = FLASH_PEAK_ALPHA
	WINDOW[elementKey]:update()
	onFrameFunctions[elementKey] = function()
		if not (WINDOW and WINDOW[elementKey]) then
			onFrameFunctions[elementKey] = nil
			return
		end
		-- scale by peak so duration is constant
		local newAlpha = WINDOW[elementKey].layout.props.alpha - FLASH_PEAK_ALPHA * core.getRealFrameDuration() / FLASH_DURATION
		if newAlpha <= 0 then
			WINDOW[elementKey].layout.props.alpha = 0
			onFrameFunctions[elementKey] = nil
		else
			WINDOW[elementKey].layout.props.alpha = newAlpha
		end
		WINDOW[elementKey]:update()
	end
end

function scrollCraftingWindow(vertical, isMouse)
	updateRecipeAvailability()
	if WINDOW.mouseTooltip then
		WINDOW.mouseTooltip:destroy()
		WINDOW.mouseTooltip = nil
	end

	local list = buildVisibleList()
	if #list == 0 then return end

	if isMouse then
		vertical = vertical *  math.floor(1.5 + #list/120)
	end

	local currentScrollStart = 0
	if currentSubcategory then
		for i, item in ipairs(list) do
			if item.categoryName == currentSubcategory and item.categoryIndex == (currentIndex or 0) then
				currentScrollStart = i - 1
				break
			end
		end
	end

	local oldAbsolutePosition = currentScrollStart
	local newAbsolutePosition = oldAbsolutePosition - vertical

	local maxScrollPosition = math.max(0, #list - S_MAX_RECIPES)
	newAbsolutePosition = math.max(0, math.min(maxScrollPosition, newAbsolutePosition))

	if isMouse then
		local now = core.getRealTime()
		local wouldWrap = (newAbsolutePosition == oldAbsolutePosition)
		local newAtEdge = (newAbsolutePosition == 0 or newAbsolutePosition == maxScrollPosition)
		local oldAtEdge = (oldAbsolutePosition == 0 or oldAbsolutePosition == maxScrollPosition)
		local sessionActive = now < scrollFreeUntil
		local doWrap = false

		-- handle wrap modes: Free, Resistance, None
		if S_SCROLL_WRAP_MODE == "None" then
			-- no wrapping at all
			doWrap = false
		elseif S_SCROLL_WRAP_MODE == "Free" then
			-- instant wrap
			doWrap = wouldWrap
		else
			-- Resistance mode: gate-based wrapping
			if sessionActive and wouldWrap then
				-- free-roam ping-pong
				doWrap = true
			elseif wouldWrap and now >= scrollBlockUntil then
				-- gate satisfied or never armed
				doWrap = true
			elseif wouldWrap then
				-- gate active, spam-scroll extends it (never shrinks)
				scrollBlockUntil = math.max(scrollBlockUntil, now + SCROLL_BLOCK_REFRESH)
				FLASH_DURATION = math.max(scrollBlockUntil - now, SCROLL_BLOCK_REFRESH)
			end
		end

		if doWrap then
			newAbsolutePosition = (newAbsolutePosition == 0) and maxScrollPosition or 0
			lastEdge = newAbsolutePosition
			-- every wrap extends the allowance
			scrollFreeUntil = math.max(scrollFreeUntil, now + SCROLL_FREE_DURATION*3/4)
		elseif not wouldWrap and newAtEdge then
			if not (sessionActive and lastEdge == newAbsolutePosition) then
				-- arrived at a different edge, or allowance expired
				scrollFreeUntil = 0
				scrollBlockUntil = now + SCROLL_BLOCK_DURATION
				FLASH_DURATION = SCROLL_BLOCK_DURATION
			end
			lastEdge = newAbsolutePosition
		elseif oldAtEdge and not newAtEdge then
			-- left an edge without wrapping: half-duration allowance to return
			scrollFreeUntil = math.max(scrollFreeUntil, now + SCROLL_FREE_DURATION / 3)
			lastEdge = oldAbsolutePosition
		end
	else
		if S_SCROLL_WRAP_MODE == "None" then
			-- no wrapping for keyboard either
		elseif S_SCROLL_WRAP_MODE == "Free" then
			-- keyboard always wraps instantly
			if newAbsolutePosition == oldAbsolutePosition then
				if newAbsolutePosition == 0 then
					newAbsolutePosition = maxScrollPosition
				else
					newAbsolutePosition = 0
				end
			end
		else
			-- Resistance: keyboard wraps instantly (no gate for keyboard)
			if newAbsolutePosition == oldAbsolutePosition then
				if newAbsolutePosition == 0 then
					newAbsolutePosition = maxScrollPosition
				else
					newAbsolutePosition = 0
				end
			end
		end
	end

	-- edge bump: tried past edge with wrap blocked
	if maxScrollPosition > 0 and newAbsolutePosition == oldAbsolutePosition then
		if oldAbsolutePosition == maxScrollPosition then
			triggerBumpFlash("listBumpFlashBottom")
		elseif oldAbsolutePosition == 0 then
			triggerBumpFlash("listBumpFlashTop")
		end
	end

	if newAbsolutePosition ~= oldAbsolutePosition then
		local scrollItem = list[newAbsolutePosition + 1]
		if scrollItem then
			currentSubcategory = scrollItem.categoryName
			currentIndex = scrollItem.categoryIndex
		else
			currentSubcategory = nil
			currentIndex = nil
		end
		refreshRecipeList()
	end
end

function destroyCraftingWindow()
	if WINDOW and WINDOW.craftingWindow then
		WINDOW.searchInputElement:destroy()
		WINDOW.searchPlaceholder:destroy()
		WINDOW.leftBox:destroy()
		WINDOW.infoContent:destroy()
		WINDOW.infoScroller:destroy()
		WINDOW.infoExp:destroy()
		if WINDOW.infoBottomFade then WINDOW.infoBottomFade:destroy() end
		if WINDOW.listBumpFlashTop then WINDOW.listBumpFlashTop:destroy() end
		if WINDOW.listBumpFlashBottom then WINDOW.listBumpFlashBottom:destroy() end
		WINDOW.craftingWindow:destroy()
		if WINDOW.mouseTooltip then
			WINDOW.mouseTooltip:destroy()
		end
		if WINDOW.professionDropdown then
			WINDOW.professionDropdown:destroy()
		end
		-- drop in-flight fades
		onFrameFunctions["listBumpFlashTop"] = nil
		onFrameFunctions["listBumpFlashBottom"] = nil
		-- wipe the whole element table
		WINDOW = {}
		selectedHeader = nil
		-- release externally-invoked hidden/solo profession state
		unlockedHidden = {}
		soloProfession = nil
		scrollBlockUntil = 0
		scrollFreeUntil = 0
		lastEdge = -1
		self:sendEvent("CraftingFramework_windowClosed")
	end
end
-- public alias
API.closeCraftingWindow = destroyCraftingWindow -- bare-used internally (CF_p, ui_craftingWindow)