-- layout:
--   mainFlex (v)
--     topBar          [filter] [touches...] [profession] [clearqueue] [x]
--     contentFlex (h)
--       leftColumnWrapper (v)  leftBox (recipeList + scrollbar)  + searchRow
--       rightPanel (v)         containerContainer -> infoScroller -> infoContent
--                              craftingButtonFlex [craft 1] [craft all]

self:sendEvent("FUJI_destroyUI")
skillValueCache = {}

-- global element table; destroyCraftingWindow wipes it
WINDOW = WINDOW or {}

destroyCraftingWindow()
updateRecipeAvailability()

-- config
borderOffset = 1
borderFile = "thin"
lineHeightMultiplier = 1.3
spacer = 5
listBorders = false
-- pre-rounded; avoids per-row floor gap
rowHeight = math.ceil(S_FONT_SIZE * lineHeightMultiplier)

-- non-element state globals (UI elements live in WINDOW)
recipeButtonFocus = nil
recipeButtons = {}
infoScrollOffset = 0
infoHasFocus = false
-- set by measureInfoHeight
infoContentHeight = 0
infoScrollable = false

-- search/filter/collapse state
searchText = searchText or ""
collapsedCategories = collapsedCategories or {}
selectedHeader = selectedHeader or nil
selectedHeader = nil
pendingHoverKey = nil
hoveredBackground = nil

-- border templates
borderTemplate = makeBorder(borderFile, nil, borderOffset, {
	type = ui.TYPE.Image,
	props = {
		relativeSize = v2(1, 1),
		alpha = 0.3,
	}
}).borders

local panelBorderTemplate = makeBorder(borderFile, util.color.rgb(0.5, 0.5, 0.5), borderOffset, {
	type = ui.TYPE.Image,
	props = {
		relativeSize = v2(1, 1),
		alpha = 0.3,
	}
}).borders

local rootBorderTemplate = makeBorder(borderFile, nil, borderOffset, {
	type = ui.TYPE.Image,
	props = {
		resource = background,
		relativeSize = v2(1, 1),
		alpha = 0.8,
	}
}).borders

function getSelectedRecipe()
	for _, category in ipairs(professions[currentProfessionName]) do
		for _, r in pairs(category.recipes) do
			if (r.uid) == selectedRecipe then
				return r
			end
		end
	end
	return nil
end

function updateAllRecipeButtons()
	for _, buttonData in pairs(recipeButtons) do
		if not selectedHeader and (buttonData.recipe.uid) == selectedRecipe then
			buttonData.background.props.color = selectedColor
			buttonData.background.props.alpha = 0.8
		elseif buttonData.background == hoveredBackground then
			-- preserve hover highlight
		else
			buttonData.background.props.color = darkenColor(textColor, 0.05)
			buttonData.background.props.alpha = 0
		end
	end
	WINDOW.leftBox:update()
end

------------------------------ ui ------------------------------

local layerId = ui.layers.indexOf("HUD")
local screenSize = ui.layers[layerId].size

WINDOW.craftingWindow = ui.create({
	type = ui.TYPE.Container,
	layer = 'Modal',
	name = "craftingWindow",
	template = rootBorderTemplate,
	props = {
		relativePosition = v2(0.5, 0.45),
		anchor = v2(0.5, 0.5),
		position = windowPos,
	},
	content = ui.content {}
})

WINDOW.mainFlex = {
	type = ui.TYPE.Flex,
	name = 'mainFlex',
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Start,
		horizontal = false,
	},
	content = ui.content {}
}
WINDOW.craftingWindow.layout.content:add(WINDOW.mainFlex)

------------------------------ top bar ------------------------------

WINDOW.topBar = {
	type = ui.TYPE.Widget,
	name = 'topBar',
	props = {
		size = v2(S_DESCRIPTION_WIDTH + S_LIST_WIDTH + spacer * 2 + 1, S_FONT_SIZE * 1.4),
	},
	content = ui.content {}
}
WINDOW.mainFlex.content:add(WINDOW.topBar)

WINDOW.topBarBackground = {
	type = ui.TYPE.Image,
	name = 'topBarBackground',
	props = {
		resource = getTexture('white'),
		alpha = 0,
		color = morrowindGold,
		relativeSize = v2(1, 1),
	},
}
WINDOW.topBar.content:add(WINDOW.topBarBackground)

WINDOW.topBar.events = {
	mousePress = async:callback(function(data, elem)
		if data.button == 1 then
			if not elem.userData then
				elem.userData = {}
			end
			elem.userData.isDragging = true
			elem.userData.lastMousePos = data.position
		end
		WINDOW.topBarBackground.props.alpha = 0.2
		WINDOW.craftingWindow:update()
	end),

	mouseRelease = async:callback(function(data, elem)
		if elem.userData then
			elem.userData.isDragging = false
		end
		WINDOW.topBarBackground.props.alpha = 0.1
		WINDOW.craftingWindow:update()
	end),

	mouseMove = async:callback(function(data, elem)
		if elem.userData and elem.userData.isDragging then
			local delta = data.position - elem.userData.lastMousePos
			elem.userData.lastMousePos = data.position
			local newPosition = (WINDOW.craftingWindow.layout.props.position or v2(0, 0)) + delta
			windowPos = newPosition
			WINDOW.craftingWindow.layout.props.position = newPosition
			WINDOW.craftingWindow:update()
		end
	end),

	focusGain = async:callback(function(_, elem)
		WINDOW.topBarBackground.props.alpha = 0.1
		WINDOW.craftingWindow:update()
		if WINDOW.professionDropdown then
			WINDOW.professionDropdown:destroy()
			WINDOW.professionDropdown = nil
		end
	end),

	focusLoss = async:callback(function(_, elem)
		if elem.userData then
			elem.userData.isDragging = false
		end
		WINDOW.topBarBackground.props.alpha = 0
		WINDOW.craftingWindow:update()
	end)
}

-- top bar buttons
WINDOW.filterButton = makeButton("Filter", v2(S_FONT_SIZE * 3.5, S_FONT_SIZE * 1), function(elem)
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
	WINDOW.filterButton.content.background.props.color = morrowindGold
	WINDOW.filterButton.content.clickbox.userData.customColor = morrowindGold
end
WINDOW.filterButton.props.position = v2(spacer, 0)
WINDOW.filterButton.props.relativePosition = v2(0, 0.5)
WINDOW.filterButton.props.anchor = v2(0, 0.5)
WINDOW.topBar.content:add(WINDOW.filterButton)

WINDOW.xButton = makeIconButton("textures/CraftingFramework/x.png", v2(S_FONT_SIZE * 1, S_FONT_SIZE * 1), function()
	destroyCraftingWindow()
	-- nothing left to show, exit the mode
	if S_HIDE_VANILLA_WINDOWS then
		I.UI.setMode(nil)
	else
		I.UI.setMode('Interface', { windows = { 'Map', 'Stats', 'Magic', 'Inventory' } })
	end
end)
WINDOW.xButton.props.relativePosition = v2(1, 0.5)
WINDOW.xButton.props.position = v2(-spacer, 0)
WINDOW.xButton.props.anchor = v2(1, 0.5)
WINDOW.topBar.content:add(WINDOW.xButton)

WINDOW.clearQueueButton = makeButton("Clear Queue", v2(S_FONT_SIZE * 6, S_FONT_SIZE * 1), function()
	clearCraftingQueue()
	refreshRecipeList()
	updateinfoContent()
end)
WINDOW.clearQueueButton.props.position = v2(-S_FONT_SIZE - spacer - 3, 0)
WINDOW.clearQueueButton.props.relativePosition = v2(1, 0.5)
WINDOW.clearQueueButton.props.anchor = v2(1, 0.5)
WINDOW.topBar.content:add(WINDOW.clearQueueButton)

-- flex slot for touch buttons; mods add their own via registerWindowBuilder
WINDOW.topBarButtonFlex = {
	type = ui.TYPE.Flex,
	name = 'topBarButtonFlex',
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Center,
		horizontal = true,
		position = v2(S_FONT_SIZE * 3.5 + 8, 0),
		relativePosition = v2(0, 0.5),
		anchor = v2(0, 0.5),
	},
	content = ui.content {}
}
WINDOW.topBar.content:add(WINDOW.topBarButtonFlex)

------------------------------ profession bar + dropdown ------------------------------

local profBarWidth = S_FONT_SIZE * 8
local profBarHeight = S_FONT_SIZE * 1.2
local subBarHeight = 3

-- progress bar
WINDOW.progressBar = {
	template = borderTemplate,
	type = ui.TYPE.Widget,
	name = 'progressBar',
	props = {
		size = v2(profBarWidth, profBarHeight),
		anchor = v2(0.5, 0.5),
		relativePosition = v2(0.5, 0.5),
	},
	content = ui.content {}
}
WINDOW.topBar.content:add(WINDOW.progressBar)

-- dark bg
WINDOW.progressBar.content:add {
	type = ui.TYPE.Image,
	name = 'progressBarBg',
	props = {
		resource = background,
		tileH = false,
		tileV = false,
		relativeSize = v2(1, 1),
		alpha = 0.3,
	}
}

-- main fill: overall skill (level / 100)
local usedSkillId = getProfessionSkill(currentProfessionName)
WINDOW.profMainFill = {
	type = ui.TYPE.Image,
	name = 'profMainFill',
	props = {
		resource = getTexture('white'),
		tileH = false,
		tileV = false,
		relativeSize = v2(math.min(1, math.floor(getBaseSkill(usedSkillId)) / 100), 1),
		relativePosition = v2(0, 0),
		alpha = 0.6,
		color = morrowindBlue,
	}
}
WINDOW.progressBar.content:add(WINDOW.profMainFill)

-- sub bar: current-level progress
WINDOW.profSubFill = {
	type = ui.TYPE.Image,
	name = 'profSubFill',
	props = {
		resource = getTexture('white'),
		tileH = false,
		tileV = false,
		size = v2(0, subBarHeight),
		relativeSize = v2(getSkillProgress(usedSkillId), 0),
		relativePosition = v2(0, 1),
		anchor = v2(0, 1),
		alpha = 1,
		color = morrowindBlue2,
	}
}
WINDOW.progressBar.content:add(WINDOW.profSubFill)

-- label like "Crafting (33)"
WINDOW.profLabel = {
	type = ui.TYPE.Text,
	name = 'profLabel',
	props = {
		text = currentProfessionName .. " (" .. math.floor(getModifiedSkill(usedSkillId)) .. ")",
		textSize = S_FONT_SIZE * 0.8,
		relativeSize = v2(0, 1),
		relativePosition = v2(0.5, 0.5),
		anchor = v2(0.5, 0.5),
		textAlignH = ui.ALIGNMENT.Center,
		textColor = lightText,
		textShadow = true,
		textShadowColor = util.color.rgba(0, 0, 0, 1),
	},
}
WINDOW.progressBar.content:add(WINDOW.profLabel)

-- hover overlay
WINDOW.profHover = {
	type = ui.TYPE.Image,
	name = 'profHover',
	props = {
		resource = getTexture('white'),
		relativeSize = v2(1, 1),
		color = morrowindGold,
		alpha = 0,
	}
}
WINDOW.progressBar.content:add(WINDOW.profHover)

-- clickbox; mousePress is swallowed so it doesn't trigger WINDOW.topBar drag
WINDOW.progressBar.content:add {
	name = 'professionClickbox',
	props = { relativeSize = v2(1, 1) },
	events = {
		mousePress = async:callback(function()
		end),
		mouseRelease = async:callback(function()
			
			if WINDOW.professionDropdown then
				WINDOW.professionDropdown:destroy()
				WINDOW.professionDropdown = nil
			end

			local screenSize = ui.layers[ui.layers.indexOf("Modal")].size
			local windowRelPos = WINDOW.craftingWindow.layout.props.relativePosition or v2(0.5, 0.45)
			local windowAnchor = WINDOW.craftingWindow.layout.props.anchor or v2(0.5, 0.5)
			local windowOffset = WINDOW.craftingWindow.layout.props.position or v2(0, 0)
			local totalWidth = S_DESCRIPTION_WIDTH + S_LIST_WIDTH + spacer * 2 + 1
			local totalHeight = S_FONT_SIZE * 1.4 + S_MAX_RECIPES * rowHeight + spacer + S_FONT_SIZE * 1.4

			local dropdownX = screenSize.x * windowRelPos.x + windowOffset.x
				- windowAnchor.x * totalWidth + totalWidth / 2 - profBarWidth / 2
			local dropdownY = screenSize.y * windowRelPos.y + windowOffset.y
				- windowAnchor.y * totalHeight + S_FONT_SIZE * 1.4

			local dropdownContent = ui.content {}
			-- snapshot + sort by priority, then case-insensitive name
			local profNames = {}
			for name, visible in pairs(getProfessionList()) do
				if visible then profNames[#profNames + 1] = name end
			end
			table.sort(profNames, compareProfessions)

			for _, name in ipairs(profNames) do
				local isActive = (name == currentProfessionName)
				local skillId = getProfessionSkill(name)
				local base = getBaseSkill(skillId)
				local modified = getModifiedSkill(skillId)
				local progress = getSkillProgress(skillId)

				local row = {
					type = ui.TYPE.Widget,
					props = {
						size = v2(profBarWidth, profBarHeight),
					},
					content = ui.content {}
				}

				local rowBg = {
					type = ui.TYPE.Image,
					name = 'rowBg',
					props = {
						resource = background,
						alpha = 0.8,
						relativeSize = v2(1, 1),
					},
				}
				row.content:add(rowBg)

				-- main fill
				row.content:add {
					type = ui.TYPE.Image,
					name = 'mainFill',
					props = {
						resource = getTexture('white'),
						color = isActive and morrowindBlue3 or morrowindBlue,
						alpha = 0.5,
						relativeSize = v2(math.min(1, math.floor(base) / 100), 1),
					},
				}

				-- sub bar
				row.content:add {
					type = ui.TYPE.Image,
					name = 'subFill',
					props = {
						resource = getTexture('white'),
						color = morrowindBlue2,
						alpha = 0.8,
						size = v2(0, subBarHeight),
						relativeSize = v2(progress, 0),
						relativePosition = v2(0, 1),
						anchor = v2(0, 1),
					},
				}

				row.content:add {
					type = ui.TYPE.Text,
					name = 'label',
					props = {
						text = name .. " (" .. math.floor(modified) .. ")",
						textColor = isActive and morrowindGold or lightText,
						textShadow = true,
						textShadowColor = util.color.rgba(0, 0, 0, 1),
						textSize = S_FONT_SIZE * 0.8,
						textAlignH = ui.ALIGNMENT.Center,
						relativeSize = v2(0, 1),
						relativePosition = v2(0.5, 0.5),
						anchor = v2(0.5, 0.5),
					},
				}

				local rowHover = {
					type = ui.TYPE.Image,
					name = 'rowHover',
					props = {
						resource = getTexture('white'),
						relativeSize = v2(1, 1),
						color = morrowindGold,
						alpha = 0,
					}
				}
				row.content:add(rowHover)

				local capturedName = name
				local capturedRowHover = rowHover
				row.content:add {
					name = 'clickbox',
					props = { relativeSize = v2(1, 1) },
					events = {
						mouseRelease = async:callback(function()
							if capturedName ~= currentProfessionName then
								setProfession(capturedName)
								updateProfessionProgressBar()
								if filterRecipes then
									updateRecipeAvailability(true)
								end
								refreshRecipeList()
								updateinfoContent()
								WINDOW.craftingWindow:update()
							end
							if WINDOW.professionDropdown then
								WINDOW.professionDropdown:destroy()
								WINDOW.professionDropdown = nil
							end
						end),
						focusGain = async:callback(function()
							if WINDOW.professionDropdown then
								capturedRowHover.props.alpha = 0.15
								WINDOW.professionDropdown:update()
							end
						end),
						focusLoss = async:callback(function()
							if WINDOW.professionDropdown then
								capturedRowHover.props.alpha = 0
								WINDOW.professionDropdown:update()
							end
						end),
					},
				}

				dropdownContent:add(row)
				dropdownContent:add { props = { size = v2(1, 1) } }
			end

			WINDOW.professionDropdown = ui.create {
				type = ui.TYPE.Flex,
				layer = 'Modal',
				props = {
					position = v2(dropdownX, dropdownY-1),
					autoSize = true,
				},
				content = dropdownContent,
			}
		end),
		focusGain = async:callback(function()
			WINDOW.profHover.props.alpha = 0.1
			WINDOW.craftingWindow:update()
		end),
		focusLoss = async:callback(function()
			WINDOW.profHover.props.alpha = 0
			WINDOW.craftingWindow:update()
		end),
	},
}

-- call after switching profession or after crafting
function updateProfessionProgressBar()
	if not WINDOW.craftingWindow then return end
	local skillId = getProfessionSkill(currentProfessionName)
	local base = getBaseSkill(skillId)
	local modified = getModifiedSkill(skillId)
	local progress = getSkillProgress(skillId)
	WINDOW.profMainFill.props.relativeSize = v2(math.min(1, math.floor(base) / 100), 1)
	WINDOW.profSubFill.props.relativeSize = v2(progress, 0)
	WINDOW.profLabel.props.text = currentProfessionName .. " (" .. math.floor(modified) .. ")"
	WINDOW.craftingWindow:update()
end

------------------------------ search bar ------------------------------

local collapseButtonWidth = S_FONT_SIZE * 1.4
local searchBarWidth = S_LIST_WIDTH - collapseButtonWidth - 2

WINDOW.searchBarWidget = {
	type = ui.TYPE.Widget,
	name = 'searchBarWidget',
	props = {
		size = v2(searchBarWidth, S_FONT_SIZE * 1.4),
	},
	content = ui.content {}
}


-- recreated on focusLoss so the input unfocuses cleanly
function createSearchInput()
	if WINDOW.searchInputElement then
		WINDOW.searchInputElement:destroy()
		WINDOW.searchPlaceholder:destroy()
		WINDOW.searchBarWidget.content = ui.content{}
	end
	local searchBoxBg = {
		type = ui.TYPE.Image,
		name = 'searchBoxBg',
		props = {
			resource = getTexture('white'),
			color = util.color.rgb(0, 0, 0),
			alpha = 0,
			size = v2(searchBarWidth, S_FONT_SIZE * 1.2),
			position = v2(0, 0),
			relativePosition = v2(0, 0.5),
			anchor = v2(0, 0.5),
		},
	}
	WINDOW.searchBarWidget.content:add(searchBoxBg)

	WINDOW.searchInputElement = ui.create {
		name = "searchEdit",
		type = ui.TYPE.TextEdit,
		props = {
			size = v2(searchBarWidth, S_FONT_SIZE * 1.2),
			position = v2(2, 0),
			relativePosition = v2(0, 0.5),
			anchor = v2(0, 0.5),
			textSize = S_FONT_SIZE,
			textColor = textColor,
			textAlignV = ui.ALIGNMENT.Center,
			multiline = false,
			text = searchText,
		},
		content = ui.content{}
	}
	WINDOW.searchInputElement.layout.events = {
		textChanged = async:callback(function(s)
			searchText = s or ""
			WINDOW.searchPlaceholder.layout.props.text = ""
			WINDOW.searchPlaceholder:update()
			refreshRecipeList()
			WINDOW.craftingWindow:update()
		end),
		focusGain = async:callback(function()
			searchBoxBg.props.color = morrowindGold
			searchBoxBg.props.alpha = 0.1
			if WINDOW.searchPlaceholder then
				WINDOW.searchPlaceholder.layout.props.text = ""
				WINDOW.searchPlaceholder:update()
			end
			WINDOW.craftingWindow:update()
		end),
		focusLoss = async:callback(function()
			searchBoxBg.props.alpha = 0
			if WINDOW.searchPlaceholder and searchText == "" then
				WINDOW.searchPlaceholder.layout.props.text = "Search..."
				WINDOW.searchPlaceholder:update()
			end
			-- recreate to avoid "destroyed element as layout child" error
			createSearchInput()
			WINDOW.craftingWindow:update()
		end),
		mousePress = async:callback(function()
			searchBoxBg.props.color = morrowindGold
			searchBoxBg.props.alpha = 0.05
			WINDOW.craftingWindow:update()
		end),
	}
	WINDOW.searchBarWidget.content:add(WINDOW.searchInputElement)
	-- placeholder is its own element so it can sit over the input
	WINDOW.searchPlaceholder = ui.create {
		name = "searchHint",
		type = ui.TYPE.Text,
		props = {
			text = (searchText == "") and "Search..." or "",
			textColor = darkenColor(textColor, 0.4),
			textSize = S_FONT_SIZE,
			textShadow = true,
			textShadowColor = util.color.rgba(0, 0, 0, 0.5),
			position = v2(0, 0),
			size = v2(searchBarWidth, S_FONT_SIZE * 1.2),
			relativePosition = v2(0, 0.5),
			anchor = v2(0, 0.5),
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
		},
	}
	WINDOW.searchInputElement.layout.content:add(WINDOW.searchPlaceholder)
end

createSearchInput()

------------------------------ content area ------------------------------

WINDOW.contentFlex = {
	name = 'contentFlex',
	type = ui.TYPE.Flex,
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Start,
		horizontal = true,
	},
	content = ui.content {}
}
WINDOW.mainFlex.content:add(WINDOW.contentFlex)
WINDOW.contentFlex.content:add { props = { size = v2(1, 1) * spacer } }

-- left column: bordered recipe list + unbordered search bar below
WINDOW.leftColumnWrapper = {
	name = 'leftColumnWrapper',
	type = ui.TYPE.Flex,
	props = {
		autoSize = false,
		arrange = ui.ALIGNMENT.Start,
		horizontal = false,
		size = v2(S_LIST_WIDTH, S_MAX_RECIPES * rowHeight + spacer + S_FONT_SIZE * 1.4),
	},
	content = ui.content {}
}
WINDOW.contentFlex.content:add(WINDOW.leftColumnWrapper)

-- recipe list; widget for overlay positioning
WINDOW.leftBox = ui.create {
	name = 'leftBox',
	type = ui.TYPE.Widget,
	template = panelBorderTemplate,
	props = {
		size = v2(S_LIST_WIDTH, S_MAX_RECIPES * rowHeight + 2),
	},
	content = ui.content {}
}
WINDOW.leftColumnWrapper.content:add(WINDOW.leftBox)

WINDOW.leftColumnWrapper.content:add { props = { size = v2(1, 1) } }

-- search row: collapse/expand button + search bar

local function areAllCollapsed()
	for _, category in ipairs(professions[currentProfessionName]) do
		if not collapsedCategories[category.categoryName] then
			return false
		end
	end
	return true
end

local function updateCollapseIcon()
	if WINDOW.collapseAllButton then
		WINDOW.collapseAllButton.content.icon.props.resource = areAllCollapsed()
			and getTexture('textures/CraftingFramework/tri_right.png')
			or getTexture('textures/CraftingFramework/tri_down.png')
	end
end

local function toggleCollapseAll()
	if areAllCollapsed() then
		for _, category in ipairs(professions[currentProfessionName]) do
			collapsedCategories[category.categoryName] = nil
		end
	else
		for _, category in ipairs(professions[currentProfessionName]) do
			collapsedCategories[category.categoryName] = true
		end
	end
	updateCollapseIcon()
	refreshRecipeList()
	WINDOW.craftingWindow:update()
end

WINDOW.collapseAllButton = makeIconButton(
	areAllCollapsed()
		and 'textures/CraftingFramework/tri_right.png'
		or 'textures/CraftingFramework/tri_down.png',
	v2(collapseButtonWidth, S_FONT_SIZE * 1),
	toggleCollapseAll
)

WINDOW.searchRow = {
	name = 'searchRow',
	type = ui.TYPE.Flex,
	props = {
		autoSize = false,
		arrange = ui.ALIGNMENT.Center,
		horizontal = true,
		size = v2(S_LIST_WIDTH, S_FONT_SIZE * 1.4),
	},
	content = ui.content {}
}
WINDOW.searchRow.content:add(WINDOW.collapseAllButton)
WINDOW.searchRow.content:add { props = { size = v2(2, 1) } }
WINDOW.searchRow.content:add(WINDOW.searchBarWidget)

WINDOW.leftColumnWrapper.content:add(WINDOW.searchRow)

WINDOW.recipeList = {
	name = 'recipeList',
	type = ui.TYPE.Flex,
	props = {
		arrange = ui.ALIGNMENT.Start,
		horizontal = false,
		autoSize = false,
		relativeSize = v2(1,0),
	},
	content = ui.content {}
}
WINDOW.leftBox.layout.content:add(WINDOW.recipeList)

------------------------------ scrollbar ------------------------------

WINDOW.scrollbarContainer = {
	name = 'scrollbarContainer',
	type = ui.TYPE.Widget,
	props = {
		size = v2(0, 0),
		relativeSize = v2(0, 1),
	},
	content = ui.content {}
}

WINDOW.scrollbarBackground = {
	name = 'scrollbarBackground',
	type = ui.TYPE.Image,
	props = {
		resource = getTexture('white'),
		tileH = false,
		tileV = false,
		relativePosition = v2(0, 0),
		relativeSize = v2(1, 1),
		alpha = 0.625,
		color = util.color.rgb(0, 0, 0),
	},

	events = {
		mousePress = async:callback(function(data, elem)
			local thumbIsDragging = WINDOW.scrollbarThumb.userData and WINDOW.scrollbarThumb.userData.isDragging

			if not thumbIsDragging and data.button == 1 then
				local scrollContainerHeight = S_MAX_RECIPES * rowHeight
				local thumbHeight = WINDOW.scrollbarThumb.props.relativeSize.y * scrollContainerHeight
				local currentThumbY = WINDOW.scrollbarThumb.props.relativePosition.y * scrollContainerHeight
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
				local newSubcategory, newIndex = calculateListPositionFromScrollbar(newScrollPosition, profession, S_MAX_RECIPES)

				currentSubcategory = newSubcategory
				currentIndex = newIndex
				refreshRecipeList()
			end
		end),

		focusGain = async:callback(function(_, elem)
			elem.props.alpha = 0.1
			elem.props.color = morrowindGold
			WINDOW.leftBox:update()
		end),

		focusLoss = async:callback(function(_, elem)
			elem.props.alpha = 0.625
			elem.props.color = util.color.rgb(0, 0, 0)
			WINDOW.leftBox:update()
		end),
	}
}

WINDOW.scrollbarThumb = {
	name = 'scrollbarThumb',
	type = ui.TYPE.Image,
	props = {
		resource = getTexture('white'),
		relativePosition = v2(0, 0),
		relativeSize = v2(1, 0),
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

				local list = buildVisibleList()
				local visibleRecipes = #list
				local absolutePosition = 0

				if currentSubcategory then
					for i, item in ipairs(list) do
						if item.categoryName == currentSubcategory and item.categoryIndex == (currentIndex or 0) then
							absolutePosition = i - 1
							break
						end
					end
				end

				if visibleRecipes > S_MAX_RECIPES then
					local maxScrollPosition = visibleRecipes - S_MAX_RECIPES
					elem.userData.dragStartScrollPosition = absolutePosition / maxScrollPosition
				else
					elem.userData.dragStartScrollPosition = 0
				end

				elem.userData.dragStartThumbY = elem.props.relativePosition.y * (S_MAX_RECIPES * rowHeight)
			end
		end),

		mouseMove = async:callback(function(data, elem)
			if elem.userData and elem.userData.isDragging then
				local scrollContainerHeight = S_MAX_RECIPES * rowHeight
				local thumbHeight = elem.props.relativeSize.y * scrollContainerHeight
				local availableScrollDistance = scrollContainerHeight - thumbHeight

				if availableScrollDistance > 0 then
					local deltaY = data.position.y - elem.userData.dragStartY
					local newThumbY = math.max(0, math.min(availableScrollDistance, elem.userData.dragStartThumbY + deltaY))

					local newScrollPosition = math.max(0, math.min(1, newThumbY / availableScrollDistance))
					local newSubcategory, newIndex = calculateListPositionFromScrollbar(newScrollPosition, profession, S_MAX_RECIPES)

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
			WINDOW.leftBox:update()
			if WINDOW.professionDropdown then
				WINDOW.professionDropdown:destroy()
				WINDOW.professionDropdown = nil
			end
		end),

		focusLoss = async:callback(function(_, elem)
			elem.props.alpha = 0.4
			WINDOW.leftBox:update()
		end),
	}
}

WINDOW.scrollbarContainer.content:add(WINDOW.scrollbarBackground)
WINDOW.scrollbarContainer.content:add(WINDOW.scrollbarThumb)
-- pin scrollbar to right edge
WINDOW.scrollbarContainer.props.relativePosition = v2(1, 0)
WINDOW.scrollbarContainer.props.anchor = v2(1, 0)
WINDOW.leftBox.layout.content:add(WINDOW.scrollbarContainer)

-- edge bump flashes; pulsed by scrollCraftingWindow
WINDOW.listBumpFlashTop = ui.create {
	name = 'listBumpFlashTop',
	type = ui.TYPE.Image,
	props = {
		resource = getTexture('white'),
		color = goldenMix,
		alpha = 0,
		relativeSize = v2(1, 0),
		size = v2(-14, 2),
		relativePosition = v2(0, 0),
		anchor = v2(0, 0),
	},
}
WINDOW.leftBox.layout.content:add(WINDOW.listBumpFlashTop)

WINDOW.listBumpFlashBottom = ui.create {
	name = 'listBumpFlashBottom',
	type = ui.TYPE.Image,
	props = {
		resource = getTexture('white'),
		color = goldenMix,
		alpha = 0,
		relativeSize = v2(1, 0),
		size = v2(-14, 2),
		relativePosition = v2(0, 1),
		anchor = v2(0, 1),
	},
}
WINDOW.leftBox.layout.content:add(WINDOW.listBumpFlashBottom)

WINDOW.contentFlex.content:add { props = { size = v2(1, 1) * spacer * 2 } }

------------------------------ right side: info panel ------------------------------

WINDOW.rightPanel = {
	type = ui.TYPE.Flex,
	name = 'rightPanel',
	props = {
		relativeSize = v2(0, 1),
		size = v2(S_DESCRIPTION_WIDTH, 0),
		arrange = ui.ALIGNMENT.Start,
		horizontal = false,
	},
	content = ui.content {},
	events = {
		focusGain = async:callback(function(_, elem)
			-- gate on measured overflow
			infoHasFocus = infoScrollable
			if WINDOW.professionDropdown then
				WINDOW.professionDropdown:destroy()
				WINDOW.professionDropdown = nil
			end
		end),
		focusLoss = async:callback(function(_, elem)
			infoHasFocus = false
		end),
	}
}
WINDOW.contentFlex.content:add(WINDOW.rightPanel)

local infoContainerHeight = S_MAX_RECIPES * rowHeight

-- outer clip container
WINDOW.containerContainer = {
	name = 'containerContainer',
	type = ui.TYPE.Widget,
	template = panelBorderTemplate,
	props = {
		size = v2(S_DESCRIPTION_WIDTH - 8, infoContainerHeight),
	},
	content = ui.content {}
}
WINDOW.rightPanel.content:add(WINDOW.containerContainer)

-- scrollable inner
WINDOW.infoScroller = ui.create {
	name = 'infoScroller',
	type = ui.TYPE.Widget,
	props = {
		size = v2(S_DESCRIPTION_WIDTH - 8, 9999),
		position = v2(0, 0),
	},
	content = ui.content {}
}
WINDOW.containerContainer.content:add(WINDOW.infoScroller)

WINDOW.infoContent = ui.create {
	name = 'infoContent',
	type = ui.TYPE.Flex,
	props = {
		position = v2(spacer, 0),
		anchor = v2(0, 0),
		size = v2(S_DESCRIPTION_WIDTH - spacer * 2, 9999),
	},
}
WINDOW.infoScroller.layout.content:add(WINDOW.infoContent)

-- expected exp, pinned to the panel's top-right corner. sits on
-- containerContainer (not the scroller) so it never scrolls away.
WINDOW.infoExp = ui.create {
	name = 'infoExp',
	type = ui.TYPE.Text,
	props = {
		text = "",
		textColor = morrowindBlue2,
		textShadow = true,
		textShadowColor = util.color.rgba(0, 0, 0, 1),
		textSize = S_FONT_SIZE,
		textAlignH = ui.ALIGNMENT.End,
		textAlignV = ui.ALIGNMENT.Start,
		autoSize = true,
		relativePosition = v2(1, 0),
		anchor = v2(1, 0),
		position = v2(-spacer - 2, spacer),
	}
}
WINDOW.containerContainer.content:add(WINDOW.infoExp)

-- per-skill exp breakdown
addTooltip(WINDOW.infoExp, function()
	local recipe = getSelectedRecipe()
	if not recipe then return nil end
	local expBySkill = calculateRecipeExp(recipe, getActiveTouches(recipe), nil, nil, true)
	local goldTag = "#" .. morrowindGold:asHex()
	local blueTag = "#" .. morrowindBlue2:asHex()
	local lines = {}
	for skillId, expValue in pairs(expBySkill) do
		table.insert(lines, goldTag .. getSkillName(skillId) .. ": " .. blueTag .. "+" .. f1dot(expValue) .. " Exp")
	end
	return table.concat(lines, "\n")
end)

-- bottom fade hint; shown when content extends past clip
WINDOW.infoBottomFade = ui.create {
	name = 'infoBottomFade',
	type = ui.TYPE.Image,
	props = {
		resource = getTexture('textures/CraftingFramework/gradientV.png'),
		color = util.color.rgb(0, 0, 0),
		alpha = 0,
		relativePosition = v2(0, 1),
		relativeSize = v2(1, 0),
		anchor = v2(0, 1),
		size = v2(0, S_FONT_SIZE * 2),
	},
}
WINDOW.containerContainer.content:add(WINDOW.infoBottomFade)

function scrollInfoPanel(vertical)
	local step = S_FONT_SIZE * lineHeightMultiplier
	-- fix gap between thumb and border
	local bottomPad = S_FONT_SIZE * lineHeightMultiplier
	local maxOffset = math.max(0, infoContentHeight - infoContainerHeight + bottomPad)
	infoScrollOffset = math.max(0, infoScrollOffset - vertical * step)
	infoScrollOffset = math.min(maxOffset, infoScrollOffset)
	WINDOW.infoScroller.layout.props.position = v2(0, -infoScrollOffset)
	WINDOW.infoScroller:update()
	-- gradient visible when info too long
	WINDOW.infoBottomFade.layout.props.alpha = (infoScrollOffset + infoContainerHeight < infoContentHeight) and 1 or 0
	WINDOW.infoBottomFade:update()
end

-- crafting buttons
WINDOW.craftingButtonFlex = {
	name = 'craftingButtonFlex',
	type = ui.TYPE.Flex,
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Start,
		horizontal = true,
	},
	content = ui.content {}
}
WINDOW.rightPanel.content:add(WINDOW.craftingButtonFlex)

function updateCraftingButtonFlex()
	WINDOW.craftingButtonFlex.content = ui.content {}

	WINDOW.craftingButtonFlex.content:add(makeButton("Craft 1", v2(S_FONT_SIZE * 4, S_FONT_SIZE * lineHeightMultiplier), function()
		local recipe = getSelectedRecipe()
		if recipe and checkIngredientsWithQueue(recipe, #craftingQueue) >= 1 and not recipe.disabled then
			addToCraftingQueue(recipe, 1, input.isShiftPressed())
		end
	end))

	WINDOW.craftingButtonFlex.content:add { props = { size = v2(4, 1) } }

	WINDOW.craftingButtonFlex.content:add(makeButton("Craft All", v2(S_FONT_SIZE * 5, S_FONT_SIZE * lineHeightMultiplier), function()
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

------------------------------ recipe button ------------------------------

function makeRecipeButton(recipe)
	local box = {
		name = (recipe.uid) .. "Button",
		type = ui.TYPE.Widget,
		props = {
			size = v2(0, rowHeight),
			relativeSize = v2(1, 0)
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
			color = darkenColor(textColor, 0.1),
			alpha = 0,
		},
	}
	box.content:add(background)

	local buttonContentFlex = {
		name = 'contentFlex',
		type = ui.TYPE.Flex,
		props = {
			relativeSize = v2(1, 1),
			arrange = ui.ALIGNMENT.Center,
			horizontal = true,
		},
		content = ui.content {}
	}
	box.content:add(buttonContentFlex)

	-- result icon: resultFunc recipes swap dynamically, the rest resolve once and cache
	local icon = recipe.icon
	if not icon then
		if recipe.resultFunc then
			local rid, rtype = resolveResultItem(recipe, getActiveTouches(recipe), true)
			local rec = rtype and types[rtype] and rid and types[rtype].records[rid]
			icon = rec and rec.icon
		else
			if recipe._listIcon == nil then
				local rid, rtype = resolveResultItem(recipe, getActiveTouches(recipe), true)
				local rec = rtype and types[rtype] and rid and types[rtype].records[rid]
				recipe._listIcon = (rec and rec.icon) or false
			end
			icon = recipe._listIcon or nil
		end
	end

	buttonContentFlex.content:add { props = { size = v2(1, 1) * 1 } }
	local iconSize = S_FONT_SIZE * lineHeightMultiplier
	buttonContentFlex.content:add(makeIcon(icon, iconSize, recipe.level, checkSkill(recipe) < 0 and util.color.rgb(1, 0, 0) or nil))
	buttonContentFlex.content:add { props = { size = v2(1, 1) * 2 } }

	local nameText = recipe.displayName
	local textColor = recipe.textColor or goldenMix
	local maxCount = checkIngredientsWithQueue(recipe, #craftingQueue)
	if maxCount > 0 then
		nameText = nameText .. " [" .. maxCount .. "]"
	end

	buttonContentFlex.content:add {
		name = 'nameLabel',
		type = ui.TYPE.Text,
		props = {
			text = tostring(nameText),
			textColor = textColor,
			textShadow = true,
			textShadowColor = util.color.rgba(0, 0, 0, 1),
			textSize = S_FONT_SIZE,
			textAlignH = ui.ALIGNMENT.Start,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = true,
		},
	}

	buttonContentFlex.content:add { props = { size = v2(1, 1) * 1 } }

	recipeButtons[recipe.uid] = {
		box = box,
		background = background,
		recipe = recipe
	}

	-- restore hover highlight from before a refresh
	if pendingHoverKey == "recipe:" .. (recipe.uid) then
		background.props.color = hoverColor
		background.props.alpha = 0.8
		hoveredBackground = background
	end

	local clickbox = {
		name = 'clickbox',
		props = {
			relativeSize = util.vector2(1, 1),
			relativePosition = v2(0, 0),
			anchor = v2(0, 0),
		},
		userData = {
			recipe = recipe
		},
	}

	clickbox.events = {
		mouseRelease = async:callback(function(_, elem)
			if recipeButtonFocus == (elem.userData.recipe.uid) then
				selectedRecipe = (elem.userData.recipe.uid)
				if infoScrollOffset ~= 0 then
					infoScrollOffset = 0
					WINDOW.infoScroller.layout.props.position = v2(0, -infoScrollOffset)
					WINDOW.infoScroller:update()
				end
				updateAllRecipeButtons()
				updateinfoContent()
			end
		end),
		focusGain = async:callback(function(_, elem)
			if WINDOW.professionDropdown then
				WINDOW.professionDropdown:destroy()
				WINDOW.professionDropdown = nil
			end
			if hoveredBackground and hoveredBackground ~= background then
				hoveredBackground.props.alpha = 0
				hoveredBackground = nil
			end
			recipeButtonFocus = (elem.userData.recipe.uid)
			pendingHoverKey = "recipe:" .. recipeButtonFocus
			if selectedRecipe ~= (elem.userData.recipe.uid) then
				background.props.color = hoverColor
				background.props.alpha = 0.8
				WINDOW.leftBox:update()
			end
			if not WINDOW.mouseTooltip then
				local r = elem.userData.recipe
				local rid, rtype = resolveResultItem(r, getActiveTouches(r), true)
				if types[rtype] then
					local q = calculateQuality(r, getActiveTouches(r), true)
					WINDOW.mouseTooltip = makeMouseTooltip({
						record = types[rtype].records[rid],
						qualityMult = q,
						stats = computeCraftedStats(r, { recordType = rtype, recordId = rid, qualityMult = q, touches = getActiveTouches(r), isPreview = true }),
						enchantment = computeCraftedEnchantment(r, { recordType = rtype, recordId = rid, qualityMult = q, touches = getActiveTouches(r), isPreview = true }),
						value = calculateResultValue(r, getActiveTouches(r), q, true),
						customName = resolveRecipeName(r, getActiveTouches(r), q, true),
						recipe = r,
					})
				end
			end
		end),
		focusLoss = async:callback(function(_, elem)
			if hoveredBackground == background then
				hoveredBackground = nil
			end
			recipeButtonFocus = nil
			pendingHoverKey = nil
			if selectedRecipe == (elem.userData.recipe.uid) then
				background.props.color = selectedColor
				background.props.alpha = 0.8
			else
				background.props.color = darkenColor(textColor, 0.05)
				background.props.alpha = 0
			end
			if WINDOW.mouseTooltip then
				WINDOW.mouseTooltip:destroy()
				WINDOW.mouseTooltip = nil
			end
			WINDOW.leftBox:update()
		end),
		mouseMove = async:callback(function(data, elem)
			if not WINDOW.mouseTooltip then
				local r = elem.userData.recipe
				local rid, rtype = resolveResultItem(r, getActiveTouches(r), true)
				if types[rtype] then
					local q = calculateQuality(r, getActiveTouches(r), true)
					WINDOW.mouseTooltip = makeMouseTooltip({
						record = types[rtype].records[rid],
						qualityMult = q,
						stats = computeCraftedStats(r, { recordType = rtype, recordId = rid, qualityMult = q, touches = getActiveTouches(r), isPreview = true }),
						enchantment = computeCraftedEnchantment(r, { recordType = rtype, recordId = rid, qualityMult = q, touches = getActiveTouches(r), isPreview = true }),
						value = calculateResultValue(r, getActiveTouches(r), q, true),
						customName = resolveRecipeName(r, getActiveTouches(r), q, true),
						recipe = r,
					})
				end
			end
			if WINDOW.mouseTooltip then
				lastTooltipPos = v2(data.position.x + 13, data.position.y + 25)
				WINDOW.mouseTooltip.layout.props.position = lastTooltipPos
				WINDOW.mouseTooltip:update()
			end
		end),
	}

	box.content:add(clickbox)
	return box
end

------------------------------ info content ------------------------------

-- wildcard cycle handler. preference store is pool-keyed; only handlers
-- write it, never render. left-click: A -> 1 -> ... -> N -> A. right-click
-- -> A. items is the render-time qualifying list, keeping N stable with the
-- label; func/strict drive the post-change tooltip's effective item.
local function wildcardCycle(wildcardId, func, strict, items, wildcardLine, recipe)
	return async:callback(function(data, elem)
		if not items or #items < 2 then return end
		if data.button == 2 then
			wildcardPreferences[wildcardId] = nil
		elseif data.button == 1 then
			local pref = wildcardPreferences[wildcardId]
			local pos = nil
			for i, item in ipairs(items) do
				if getItemKey(item) == pref then
					pos = i
					break
				end
			end
			local nextPos
			if pos == nil then
				nextPos = 1
			elseif pos >= #items then
				nextPos = nil
			else
				nextPos = pos + 1
			end
			wildcardPreferences[wildcardId] = nextPos and getItemKey(items[nextPos]) or nil
		else
			return
		end
		-- retarget the tooltip to the new effective item
		if WINDOW.mouseTooltip then
			WINDOW.mouseTooltip:destroy()
			WINDOW.mouseTooltip = nil
		end
		local effKey = resolveWildcardKey(wildcardPool(func), wildcardPreferences[wildcardId], strict)
		local shown
		for _, item in ipairs(items) do
			if getItemKey(item) == effKey then
				shown = item
				break
			end
		end
		shown = shown or items[1]
		if shown and shown:isValid() then
			WINDOW.mouseTooltip = makeMouseTooltip({ record = shown.type.record(shown), item = shown, customName = true, customLine = wildcardLine, recipe = recipe })
			lastTooltipPos = v2(data.position.x + 13, data.position.y + 25)
			WINDOW.mouseTooltip.layout.props.position = lastTooltipPos
			WINDOW.mouseTooltip:update()
		end
		invalidateInventoryCache()
		updateinfoContent()
	end)
end

---@param recipe Recipe
local function AddIngredientsUI(recipe)
	-- snapshot so virtuals get counts
	createTempInventory()

	WINDOW.infoContent.layout.content:add {
		type = ui.TYPE.Text,
		props = {
			text = "Reagents:",
			textColor = textColor,
			textShadow = true,
			textShadowColor = util.color.rgba(0, 0, 0, 1),
			textSize = S_FONT_SIZE,
			textAlignH = ui.ALIGNMENT.Start,
			textAlignV = ui.ALIGNMENT.Start,
			autoSize = true,
		}
	}

	WINDOW.infoContent.layout.content:add { props = { size = v2(1, 8) } }

	for _, ingredient in ipairs(getIngredients(recipe, getActiveTouches(recipe))) do

		-- virtuals have no engine record
		local isVirtual = ingredient.type == "virtual"
		local virtualDef = isVirtual and virtuals[ingredient.virtualId] or nil
		local virtualSnap = isVirtual and tempInventoryVirtual and tempInventoryVirtual[ingredient.virtualId] or nil

		local ingredientRecord, adjustedCount
		if isVirtual then
			ingredientRecord = nil
			adjustedCount = virtualSnap and math.max(0, virtualSnap.count) or 0
		else
			ingredientRecord, adjustedCount = checkIngredientWithQueue(ingredient)
		end

		local isWildcard = ingredient.type == "wildcard"
		local qualifyingItems = nil
		local selectedPos = nil -- nil = auto (A); else index into qualifyingItems
		local selectedItem = nil
		if isWildcard then
			qualifyingItems = ingredient.func()
			if qualifyingItems and #qualifyingItems > 0 then
				createTempInventory()
				local pool = wildcardPool(ingredient.func, tempInventory)
				local pref = wildcardPreferences[ingredient.wildcardId]

				-- explicit pick only if still in the pool; else show auto.
				-- render never writes the preference back.
				if pref then
					for i, item in ipairs(qualifyingItems) do
						if getItemKey(item) == pref then
							selectedPos = i
							selectedItem = item
							break
						end
					end
				end
				if not selectedItem then
					local effKey = resolveWildcardKey(pool, nil, ingredient.strict)
					for i, item in ipairs(qualifyingItems) do
						if getItemKey(item) == effKey then
							selectedItem = item
							break
						end
					end
					selectedItem = selectedItem or qualifyingItems[1]
				end

				local itemKey = getItemKey(selectedItem)
				adjustedCount = tempInventory[itemKey] and math.max(0, tempInventory[itemKey].count) or 0
				ingredientRecord = selectedItem.type.record(selectedItem)
			end
		end

		local icon = ingredient.icon
			or (isVirtual and virtualIcon(virtualDef, adjustedCount, ingredient.count))
			or (ingredientRecord and ingredientRecord.icon)
		local nameText
		if isVirtual then
			nameText = virtualName(virtualDef, adjustedCount, ingredient.count) or ("ERROR: virtual " .. (ingredient.virtualId or "?"))
		elseif isWildcard then
			nameText = ingredient.name
		else
			nameText = (ingredientRecord and ingredientRecord.name) or ("ERROR: " .. (ingredient.id or "no id"))
		end
		
		-- wildcard label includes cycle hint and (soul, if any)
		if isWildcard and ingredientRecord and qualifyingItems then
			nameText = ingredientRecord.name
			if selectedItem and selectedItem:isValid() then
				local soul = types.Item.itemData(selectedItem).soul
				if soul then
					local creature = types.Creature.records[soul]
					if creature then
						nameText = nameText .. " (" .. creature.name .. ")"
					end
				end
			end
			nameText = nameText .. " (" .. (selectedPos or "A") .. "/" .. #qualifyingItems .. ")"
		end

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
			name = 'iconContainer',
			type = ui.TYPE.Widget,
			props = {
				size = v2(S_FONT_SIZE * 2, S_FONT_SIZE * 2),
			},
			content = ui.content {}
		}
		
		local iconClickbox = {
			name = 'clickbox',
			props = {
				relativeSize = v2(1, 1),
			},
			userData = {
				focus = false,
				pressed = false,
				selected = false,
				highlightAlpha = 0,
			},
		}
		-- closure captures
		local capturedQualifyingItems = qualifyingItems
		local capturedItem = selectedItem
		local wildcardLine = isWildcard and "["..ingredient.name.."]" or nil

		if isVirtual and virtualDef then
			-- virtual: custom tooltip, no cycle
			local capturedDef = virtualDef
			local capturedAvail = adjustedCount
			local capturedNeed = ingredient.count
			iconClickbox.events = {
				focusGain = async:callback(function(_, elem)
					if not WINDOW.mouseTooltip then
						WINDOW.mouseTooltip = makeVirtualTooltip(
							capturedDef,
							formatVirtualCount(capturedDef, capturedAvail),
							formatVirtualCount(capturedDef, capturedNeed),
							capturedAvail,
							capturedNeed
						)
					end
				end),
				focusLoss = async:callback(function(_, elem)
					if WINDOW.mouseTooltip then
						WINDOW.mouseTooltip:destroy()
						WINDOW.mouseTooltip = nil
					end
					WINDOW.leftBox:update()
				end),
				mouseMove = async:callback(function(data, elem)
					if WINDOW.mouseTooltip then
						lastTooltipPos = v2(data.position.x + 13, data.position.y + 25)
						WINDOW.mouseTooltip.layout.props.position = lastTooltipPos
						WINDOW.mouseTooltip:update()
					end
				end),
			}
		elseif ingredientRecord then
			iconClickbox.events = {
				focusGain = async:callback(function(data, elem)
					if not WINDOW.mouseTooltip then
						WINDOW.mouseTooltip = makeMouseTooltip({ record = ingredientRecord, item = capturedItem, customName = true, customLine = wildcardLine, recipe = recipe })
					end
					if ingredient.wildcardId then
						rightClickHook = function()
							wildcardPreferences[ingredient.wildcardId] = nil
							if WINDOW.mouseTooltip then
								WINDOW.mouseTooltip:destroy()
								WINDOW.mouseTooltip = nil
							end
							local shown = capturedQualifyingItems[1]
							if shown and shown:isValid() then
								WINDOW.mouseTooltip = makeMouseTooltip({ record = shown.type.record(shown), item = shown, customName = true, customLine = wildcardLine, recipe = recipe })
								WINDOW.mouseTooltip.layout.props.position = lastTooltipPos
								WINDOW.mouseTooltip:update()
							end
							invalidateInventoryCache()
							updateinfoContent()
							I.UI.setMode('Interface', { windows = S_HIDE_VANILLA_WINDOWS and {} or { 'Map', 'Stats', 'Magic', 'Inventory' } })
						end
					end
				end),
				focusLoss = async:callback(function(_, elem)
					if WINDOW.mouseTooltip then
						WINDOW.mouseTooltip:destroy()
						WINDOW.mouseTooltip = nil
					end
					rightClickHook = nil
					WINDOW.leftBox:update()
				end),
				mouseMove = async:callback(function(data, elem)
					if WINDOW.mouseTooltip then
						lastTooltipPos = v2(data.position.x + 13, data.position.y + 25)
						WINDOW.mouseTooltip.layout.props.position = lastTooltipPos
						WINDOW.mouseTooltip:update()
					end
				end),
				-- left-click cycles A/1..N, right-click resets to auto
				mouseRelease = isWildcard and wildcardCycle(ingredient.wildcardId, ingredient.func, ingredient.strict, capturedQualifyingItems, wildcardLine, recipe) or nil,
			}
		elseif isWildcard then
			-- no record yet, but cycling still works
			iconClickbox.events = {
				mouseRelease = wildcardCycle(ingredient.wildcardId, ingredient.func, ingredient.strict, capturedQualifyingItems, wildcardLine, recipe),
			}
		end

		iconContainer.content:add(makeIcon(icon, S_FONT_SIZE * 2))

		local countColor = adjustedCount >= ingredient.count and util.color.rgb(1, 1, 1) or
			util.color.rgb(1, 0.2, 0.2)
		local countText
		if isVirtual and virtualDef then
			countText = virtualLabel(virtualDef, adjustedCount, ingredient.count)
				or (formatVirtualCount(virtualDef, adjustedCount) .. "/" .. formatVirtualCount(virtualDef, ingredient.count))
		else
			countText = adjustedCount .. "/" .. ingredient.count
		end
		local textShadowColor = util.color.rgba(0, 0, 0, 1)
		local finalTextColor = adjustedCount >= ingredient.count and textColor or util.color.rgb(1, 0.5, 0.5)

		-- shrink font past ~5 chars
		local countSize = S_FONT_SIZE - 2
		if #countText > 5 then
			countSize = math.max(8, math.floor(countSize * 5 / #countText))
		end

		iconContainer.content:add {
			name = 'countLabel',
			type = ui.TYPE.Text,
			props = {
				text = countText,
				textColor = countColor,
				textShadow = true,
				textShadowColor = textShadowColor,
				textSize = countSize,
				textAlignH = ui.ALIGNMENT.End,
				textAlignV = ui.ALIGNMENT.End,
				relativePosition = v2(1, 1),
				anchor = v2(1, 1),
			}
		}
		iconContainer.content:add(iconClickbox)
		
		ingredientRow.content:add(iconContainer)
		ingredientRow.content:add { props = { size = v2(8, 1) } }
		ingredientRow.content:add {
			name = 'nameLabel',
			type = ui.TYPE.Text,
			props = {
				text = tostring(nameText),
				textColor = finalTextColor,
				textShadow = true,
				textShadowColor = textShadowColor,
				textSize = S_FONT_SIZE + 1,
				textAlignH = ui.ALIGNMENT.Start,
				textAlignV = ui.ALIGNMENT.Center,
				autoSize = true,
			}
		}

		WINDOW.infoContent.layout.content:add(ingredientRow)
		WINDOW.infoContent.layout.content:add { props = { size = v2(1, 4) } }

	end
end

---@param recipe Recipe
local function AddToolsUI(recipe)
	if not recipe.tools or #recipe.tools == 0 then return end
	
	WINDOW.infoContent.layout.content:add {
		type = ui.TYPE.Text,
		props = {
			text = "Tools (not consumed):",
			textColor = textColor,
			textShadow = true,
			textShadowColor = util.color.rgba(0, 0, 0, 1),
			textSize = S_FONT_SIZE,
			textAlignH = ui.ALIGNMENT.Start,
			textAlignV = ui.ALIGNMENT.Start,
			autoSize = true,
		}
	}
	WINDOW.infoContent.layout.content:add { props = { size = v2(1, 8) } }
	
	for _, tool in ipairs(recipe.tools) do
		local checkTool = {
			type = tool.type,
			id = tool.id,
			func = tool.func,
			name = tool.name,
			count = 1,
		}
		local toolRecord, adjustedCount = checkIngredientWithQueue(checkTool)
		local icon = tool.icon or (toolRecord and toolRecord.icon)
		local nameText = tool.type == "wildcard" and tool.name or
			(toolRecord and toolRecord.name) or ("ERROR: " .. (tool.id or "no id"))

		-- wildcard resolution (mirrors ingredient; tools never consumed)
		local isWildcard = tool.type == "wildcard"
		local qualifyingItems = nil
		local selectedPos = nil -- nil = auto (A); else index into qualifyingItems
		local selectedItem = nil
		if isWildcard then
			qualifyingItems = tool.func()
			if qualifyingItems and #qualifyingItems > 0 then
				local pool = wildcardPool(tool.func)
				local pref = wildcardPreferences[tool.wildcardId]

				if pref then
					for i, item in ipairs(qualifyingItems) do
						if getItemKey(item) == pref then
							selectedPos = i
							selectedItem = item
							break
						end
					end
				end
				if not selectedItem then
					local effKey = resolveWildcardKey(pool, nil, false)
					for i, item in ipairs(qualifyingItems) do
						if getItemKey(item) == effKey then
							selectedItem = item
							break
						end
					end
					selectedItem = selectedItem or qualifyingItems[1]
				end

				adjustedCount = selectedItem.count > 0 and 1 or 0
				toolRecord = selectedItem.type.record(selectedItem)
				icon = toolRecord and toolRecord.icon
			end
		end

		-- wildcard label includes cycle hint
		if isWildcard and toolRecord and qualifyingItems then
			nameText = toolRecord.name .. " (" .. (selectedPos or "A") .. "/" .. #qualifyingItems .. ")"
		end

		local ingredientRow = {
			type = ui.TYPE.Flex,
			props = {
				autoSize = true,
				arrange = ui.ALIGNMENT.Center,
				horizontal = true,
			},
			content = ui.content {}
		}
		-- icon container
		local iconContainer = {
			name = 'iconContainer',
			type = ui.TYPE.Widget,
			props = {
				size = v2(S_FONT_SIZE * 2, S_FONT_SIZE * 2),
			},
			content = ui.content {}
		}
		
		-- clickbox
		local iconClickbox = {
			name = 'clickbox',
			props = {
				relativeSize = v2(1, 1),
			},
			userData = {
				focus = false,
				pressed = false,
				selected = false,
				highlightAlpha = 0,
			},
		}
		-- closure captures
		local capturedQualifyingItems = qualifyingItems
		local capturedItem = selectedItem
		local wildcardLine = isWildcard and "["..tool.name.."]" or nil

		if toolRecord then
			iconClickbox.events = {
				focusGain = async:callback(function(_, elem)
					if not WINDOW.mouseTooltip then
						WINDOW.mouseTooltip = makeMouseTooltip({ record = toolRecord, item = capturedItem, customName = true, customLine = wildcardLine, recipe = recipe })
					end
				end),
				focusLoss = async:callback(function(_, elem)
					if WINDOW.mouseTooltip then
						WINDOW.mouseTooltip:destroy()
						WINDOW.mouseTooltip = nil
					end
					WINDOW.leftBox:update()
				end),
				mouseMove = async:callback(function(data, elem)
					if WINDOW.mouseTooltip then
						lastTooltipPos = v2(data.position.x + 13, data.position.y + 25)
						WINDOW.mouseTooltip.layout.props.position = lastTooltipPos
						WINDOW.mouseTooltip:update()
					end
				end),
				-- left-click cycles A/1..N, right-click resets to auto
				mouseRelease = isWildcard and wildcardCycle(tool.wildcardId, tool.func, false, capturedQualifyingItems, wildcardLine, recipe) or nil,
			}
		elseif isWildcard then
			-- no record yet, but cycling still works
			iconClickbox.events = {
				mouseRelease = wildcardCycle(tool.wildcardId, tool.func, false, capturedQualifyingItems, wildcardLine, recipe),
			}
		end
		
		iconContainer.content:add(makeIcon(icon, S_FONT_SIZE * 2))
		
		local hasTool = adjustedCount >= 1
		-- background
		local bg = {
			type = ui.TYPE.Image,
			name = 'background',
			props = {
				resource = getTexture('white'),
				alpha = 0.1,
				color = hasTool and GREEN or util.color.rgb(1, 0.2, 0.2),
				anchor = v2(0, 0),
				relativePosition = v2(0, 0),
				relativeSize = v2(1, 1),
			},
		}
		iconContainer.content:add(bg)
		
		local countColor = hasTool and util.color.rgb(1, 1, 1) or util.color.rgb(1, 0.2, 0.2)
		local countText = hasTool and "" or "?"
		local textShadowColor = util.color.rgba(0, 0, 0, 1)
		local finalTextColor = hasTool and textColor or util.color.rgb(1, 0.5, 0.5)
		
		iconContainer.content:add {
			name = 'countLabel',
			type = ui.TYPE.Text,
			props = {
				text = countText,
				textColor = countColor,
				textShadow = true,
				textShadowColor = textShadowColor,
				textSize = S_FONT_SIZE - 2,
				textAlignH = ui.ALIGNMENT.End,
				textAlignV = ui.ALIGNMENT.End,
				relativePosition = v2(1, 1),
				anchor = v2(1, 1),
			}
		}
		iconContainer.content:add(iconClickbox)
		ingredientRow.content:add(iconContainer)
		ingredientRow.content:add { props = { size = v2(8, 1) } }
		ingredientRow.content:add {
			name = 'nameLabel',
			type = ui.TYPE.Text,
			props = {
				text = tostring(nameText),
				textColor = finalTextColor,
				textShadow = true,
				textShadowColor = textShadowColor,
				textSize = S_FONT_SIZE + 1,
				textAlignH = ui.ALIGNMENT.Start,
				textAlignV = ui.ALIGNMENT.Center,
				autoSize = true,
			}
		}
		WINDOW.infoContent.layout.content:add(ingredientRow)
		WINDOW.infoContent.layout.content:add { props = { size = v2(1, 4) } }
	end
end

local function AddStationsUI(recipe)
    if not recipe.stations or #recipe.stations == 0 then return end

    WINDOW.infoContent.layout.content:add {
        type = ui.TYPE.Text,
        props = {
            text = "Stations (nearby):",
            textColor = textColor,
            textShadow = true,
            textShadowColor = util.color.rgba(0, 0, 0, 1),
            textSize = S_FONT_SIZE,
            textAlignH = ui.ALIGNMENT.Start,
            textAlignV = ui.ALIGNMENT.Start,
            autoSize = true,
        }
    }
    WINDOW.infoContent.layout.content:add { props = { size = v2(1, 8) } }

    -- station rows start in "not found" state; onFrame job flips them green if present
    local pendingStations = {}

    for _, station in ipairs(recipe.stations) do
        local stationRecord = nil
        if station.id then
            local stationType = types[station.type]
            stationRecord = stationType and stationType.records[station.id]
        end

        local icon = stationIconFuncs[station.name] and stationIconFuncs[station.name]() or stationIcons[station.name] or nil
        local nameText = stationNames[station.name] or station.name or (stationRecord and stationRecord.name) or ("ERROR: " .. (station.id or "no id"))

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
            name = 'iconContainer',
            type = ui.TYPE.Widget,
            props = {
                size = v2(S_FONT_SIZE * 2, S_FONT_SIZE * 2),
            },
            content = ui.content {}
        }
        if stationRecord then
            iconContainer.events = {
                focusGain = async:callback(function(_, elem)
                    if not WINDOW.mouseTooltip then
                        WINDOW.mouseTooltip = makeMouseTooltip(stationRecord, nil, true)
                    end
                end),
                focusLoss = async:callback(function(_, elem)
                    if WINDOW.mouseTooltip then
                        WINDOW.mouseTooltip:destroy()
                        WINDOW.mouseTooltip = nil
                    end
                    WINDOW.leftBox:update()
                end),
                mouseMove = async:callback(function(data, elem)
                    if WINDOW.mouseTooltip then
                        lastTooltipPos = v2(data.position.x + 13, data.position.y + 25)
                        WINDOW.mouseTooltip.layout.props.position = lastTooltipPos
                        WINDOW.mouseTooltip:update()
                    end
                end),
            }
        end
        if icon then
            iconContainer.content:add(makeIcon(icon, S_FONT_SIZE * 2))
        end

        local countLabel = {
            name = 'countLabel',
            type = ui.TYPE.Text,
            props = {
                text = "?",
                textColor = util.color.rgb(1, 0.2, 0.2),
                textShadow = true,
                textShadowColor = util.color.rgba(0, 0, 0, 1),
                textSize = S_FONT_SIZE - 2,
                textAlignH = ui.ALIGNMENT.End,
                textAlignV = ui.ALIGNMENT.End,
                relativePosition = v2(1, 1),
                anchor = v2(1, 1),
            }
        }
        iconContainer.content:add(countLabel)

        local bg = {
            type = ui.TYPE.Image,
			name = 'background',
            props = {
                resource = getTexture('white'),
                alpha = 0.1,
                color = util.color.rgb(1, 0.2, 0.2),
                anchor = v2(0, 0),
                relativePosition = v2(0, 0),
                relativeSize = v2(1, 1),
            },
        }
        iconContainer.content:add(bg)

        local nameLabel = {
            name = 'nameLabel',
            type = ui.TYPE.Text,
            props = {
                text = tostring(nameText),
                textColor = util.color.rgb(1, 0.5, 0.5),
                textShadow = true,
                textShadowColor = util.color.rgba(0, 0, 0, 1),
                textSize = S_FONT_SIZE + 1,
                textAlignH = ui.ALIGNMENT.Start,
                textAlignV = ui.ALIGNMENT.Center,
                autoSize = true,
            }
        }

        ingredientRow.content:add(iconContainer)
        ingredientRow.content:add { props = { size = v2(8, 1) } }
        ingredientRow.content:add(nameLabel)
        WINDOW.infoContent.layout.content:add(ingredientRow)
        WINDOW.infoContent.layout.content:add { props = { size = v2(1, 4) } }

        table.insert(pendingStations, {
            station = station,
            stationRecord = stationRecord,
            countLabel = countLabel,
            bg = bg,
            nameLabel = nameLabel,
            iconContainer = iconContainer,
        })
    end

    -- one-shot: check each station, update row
    local jobKey = "stationCheck"
    onFrameFunctions[jobKey] = function()
        onFrameFunctions[jobKey] = nil

        for _, entry in ipairs(pendingStations) do
            -- station.func returns: bool or (countStr?, nameStr?)
            local r1, r2
            if entry.station.func then r1, r2 = entry.station.func() end
            local present = r1 ~= false and r1 ~= nil

            if present then
                entry.countLabel.props.text = type(r1) == "string" and r1 or ""
                entry.countLabel.props.textColor = util.color.rgb(1, 1, 1)
                entry.bg.props.color = GREEN
                entry.nameLabel.props.textColor = textColor
                if type(r2) == "string" then
                    entry.nameLabel.props.text = r2
                end
            end
        end

        WINDOW.infoContent:update()
        if WINDOW.infoScroller then WINDOW.infoScroller:update() end
    end
end


------------------------------ info-panel height measurement ------------------------------

-- recursive pixel height for layout tree; widgets are leaves, 9999 = sentinel
local function measureInfoHeight(layout)
	if not layout then return 0 end
	local props = layout.props or {}
	local elemType = layout.type
	-- horizontal flex: max child
	if elemType == ui.TYPE.Flex and props.horizontal then
		local maxH = 0
		if layout.content then
			for _, child in ipairs(layout.content) do
				local h = measureInfoHeight(child)
				if h > maxH then maxH = h end
			end
		end
		return maxH
	end
	-- vertical flex/container: sum
	if elemType == ui.TYPE.Flex or elemType == ui.TYPE.Container then
		local total = 0
		if layout.content then
			for _, child in ipairs(layout.content) do
				total = total + measureInfoHeight(child)
			end
		end
		return total
	end
	-- leaf: size, then text, then default
	if props.size and props.size.y and props.size.y > 0 and props.size.y < 9999 then
		return props.size.y
	end
	local fontSize = props.textSize or S_FONT_SIZE
	return fontSize * lineHeightMultiplier
end

function updateinfoContent()
	-- cancel any pending station check from previous recipe
	onFrameFunctions["stationCheck"] = nil
	if selectedRecipe then
		local recipe = getSelectedRecipe()
		WINDOW.infoContent.layout.content = ui.content {}

		if recipe then
			WINDOW.infoContent.layout.content:add { props = { size = v2(1, 1) * 3 } }

			-- expected exp (both skills summed for dual-skill recipes)
			local expSum = 0
			for _, v in pairs(calculateRecipeExp(recipe, getActiveTouches(recipe), nil, nil, true)) do
				expSum = expSum + v
			end
			WINDOW.infoExp.layout.props.text = "+" .. f1dot(expSum) .. " Exp"

			-- preview-time result swap (wildcard-driven recipes)
			local resultId, resultType = resolveResultItem(recipe, getActiveTouches(recipe), true)
			local resultCount = resolveResultCount(recipe, getActiveTouches(recipe), true, nil, nil, resultId, resultType)
			local resultRecord
			if resultType and types[resultType] and resultId then
				resultRecord = types[resultType].records[resultId]
			end

			-- hoisted; shared with downstream
			local previewQuality = calculateQuality(recipe, getActiveTouches(recipe), true)

			-- swap-aware title: name modifier wins over nameOpt/displayName
			local resolvedName = resolveRecipeName(recipe, getActiveTouches(recipe), previewQuality, true)

			if recipe.additionalProducts and #recipe.additionalProducts > 0 then
				-- multi-product recipe
				local titleText = resolvedName or recipe.displayName
				if recipe.level then
					titleText = titleText .. " [lvl " .. recipe.level .. "]"
				end
				WINDOW.infoContent.layout.content:add {
					type = ui.TYPE.Text,
					props = {
						text = tostring(titleText),
						textColor = recipe.textColor or goldenMix,
						textShadow = true,
						textShadowColor = util.color.rgba(0, 0, 0, 1),
						textSize = S_FONT_SIZE * 1.1,
						textAlignH = ui.ALIGNMENT.Start,
						textAlignV = ui.ALIGNMENT.Center,
						autoSize = true,
					}
				}
				WINDOW.infoContent.layout.content:add { props = { size = v2(1, 8) } }

				local allProducts = {}
				table.insert(allProducts, { id = resultId, type = resultType, count = resultCount })
				for _, p in ipairs(recipe.additionalProducts) do
					table.insert(allProducts, p)
				end

				for _, product in ipairs(allProducts) do
					local productRecord = types[product.type] and types[product.type].records[product.id]
					local pIcon = productRecord and productRecord.icon
					local pName = productRecord and productRecord.name or product.id
					if product.count and product.count ~= 1 then
						if product.count < 1 then
							pName = pName .. " (" .. math.floor(product.count * 100) .. "%)"
						else
							pName = pName .. " x" .. product.count
						end
					end

					local productRow = {
						type = ui.TYPE.Flex,
						props = {
							autoSize = true,
							arrange = ui.ALIGNMENT.Center,
							horizontal = true,
						},
						content = ui.content {}
					}

					local iconContainer = {
						name = 'iconContainer',
						type = ui.TYPE.Widget,
						props = {
							size = v2(S_FONT_SIZE * 2, S_FONT_SIZE * 2),
						},
						content = ui.content {}
					}
					if productRecord then
						iconContainer.events = {
							focusGain = async:callback(function(_, elem)
								if not WINDOW.mouseTooltip then
									-- preview only; spawned raw via preserveRecordId, unmodified stats
									local q = calculateQuality(recipe, getActiveTouches(recipe), true)
									WINDOW.mouseTooltip = makeMouseTooltip({
										record = productRecord,
										customName = true,
										qualityMult = q,
										stats = computeCraftedStats(recipe, { record = productRecord, recordType = product.type, qualityMult = q, touches = getActiveTouches(recipe), isPreview = true }),
										enchantment = computeCraftedEnchantment(recipe, { record = productRecord, recordType = product.type, qualityMult = q, touches = getActiveTouches(recipe), isPreview = true }),
										recipe = recipe,
									})
								end
							end),
							focusLoss = async:callback(function(_, elem)
								if WINDOW.mouseTooltip then
									WINDOW.mouseTooltip:destroy()
									WINDOW.mouseTooltip = nil
								end
								WINDOW.leftBox:update()
							end),
							mouseMove = async:callback(function(data, elem)
								if WINDOW.mouseTooltip then
									lastTooltipPos = v2(data.position.x + 13, data.position.y + 25)
									WINDOW.mouseTooltip.layout.props.position = lastTooltipPos
									WINDOW.mouseTooltip:update()
								end
							end),
						}
					end
					iconContainer.content:add(makeIcon(pIcon, S_FONT_SIZE * 2))

					productRow.content:add(iconContainer)
					productRow.content:add { props = { size = v2(8, 1) } }
					productRow.content:add {
						name = 'nameLabel',
						type = ui.TYPE.Text,
						props = {
							text = tostring(pName),
							textColor = textColor,
							textShadow = true,
							textShadowColor = util.color.rgba(0, 0, 0, 1),
							textSize = S_FONT_SIZE + 1,
							textAlignH = ui.ALIGNMENT.Start,
							textAlignV = ui.ALIGNMENT.Center,
							autoSize = true,
						}
					}

					WINDOW.infoContent.layout.content:add(productRow)
					WINDOW.infoContent.layout.content:add { props = { size = v2(1, 4) } }
				end

				WINDOW.infoContent.layout.content:add { props = { size = v2(8, 4) } }
			else
				-- single-product recipe
				local recipeHeader = {
					name = 'recipeHeader',
					type = ui.TYPE.Flex,
					props = {
						autoSize = true,
						arrange = ui.ALIGNMENT.Start,
						horizontal = true,
					},
					content = ui.content {}
				}

				local icon = recipe.icon or (resultRecord and resultRecord.icon)
				local nameText = resolvedName or recipe.displayName

				if resultCount and resultCount ~= 1 then
					if resultCount < 1 then
						nameText = nameText .. " (" .. math.floor(resultCount * 100) .. "%)"
					else
						nameText = nameText .. " x" .. resultCount
					end
				end

				recipeHeader.content:add(makeIcon(icon, S_FONT_SIZE * 2))
				recipeHeader.content:add { props = { size = v2(8, 1) } }

				local nameFlex = {
					name = 'nameFlex',
					type = ui.TYPE.Flex,
					props = {
						autoSize = true,
						arrange = ui.ALIGNMENT.Start,
					},
					content = ui.content {}
				}
				recipeHeader.content:add(nameFlex)

				nameFlex.content:add {
					name = 'nameLabel',
					type = ui.TYPE.Text,
					props = {
						text = tostring(nameText),
						textColor = recipe.textColor or goldenMix,
						textShadow = true,
						textShadowColor = util.color.rgba(0, 0, 0, 1),
						textSize = S_FONT_SIZE * 1.1,
						textAlignH = ui.ALIGNMENT.Start,
						textAlignV = ui.ALIGNMENT.Center,
						autoSize = true,
					}
				}

				if types[resultType] then
					-- customName nil here: nameFlex already shows the title above
					nameFlex.content:add(makeDescriptionTooltip({
						record = types[resultType].records[resultId],
						qualityMult = previewQuality,
						stats = computeCraftedStats(recipe, { recordType = resultType, recordId = resultId, qualityMult = previewQuality, touches = getActiveTouches(recipe), isPreview = true }),
						enchantment = computeCraftedEnchantment(recipe, { recordType = resultType, recordId = resultId, qualityMult = previewQuality, touches = getActiveTouches(recipe), isPreview = true }),
						value = calculateResultValue(recipe, getActiveTouches(recipe), previewQuality, true),
						recipe = recipe,
					}))
				end
				WINDOW.infoContent.layout.content:add(recipeHeader)
				WINDOW.infoContent.layout.content:add { props = { size = v2(8, 8) } }
			end

			selectedCount = math.max(1, selectedCount)
			selectedCount = math.min(checkIngredientsWithQueue(recipe, #craftingQueue), selectedCount)

			-- description
			local flavorTextContainer = {
				type = ui.TYPE.Flex,
				props = {
					autoSize = true
				},
				content = ui.content {}
			}
			WINDOW.infoContent.layout.content:add(flavorTextContainer)

			local function addFlavorLine(text, color)
				flavorTextContainer.content:add {
					type = ui.TYPE.Text,
					props = {
						text = tostring(text),
						textColor = color or morrowindGold,
						textShadow = true,
						textShadowColor = util.color.rgba(0, 0, 0, 1),
						textSize = S_FONT_SIZE - 2,
						textAlignH = ui.ALIGNMENT.Start,
						textAlignV = ui.ALIGNMENT.Start,
					},
				}
			end

			WINDOW.infoContent.layout.content:add { props = { size = v2(1, 1) * 10 } }
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

			-- parse warnings
			if recipe.warnings then
				local warningColor = util.color.rgb(200/255, 60/255, 30/255)
				for _, message in ipairs(recipe.warnings) do
					addFlavorLine(message, warningColor)
				end
			end

			-- ingredients
			WINDOW.infoContent.layout.content:add { props = { size = v2(1, 16) } }
			AddIngredientsUI(recipe)
			-- tools
			WINDOW.infoContent.layout.content:add { props = { size = v2(1, 16) } }
			AddToolsUI(recipe)
            -- stations
            WINDOW.infoContent.layout.content:add { props = { size = v2(1, 16) } }
            AddStationsUI(recipe)
		else
			WINDOW.infoContent.layout.content:add {
				type = ui.TYPE.Text,
				props = {
					text = "Select a recipe to see its description.",
					textColor = textColor,
					textShadow = true,
					textShadowColor = util.color.rgba(0, 0, 0, 1),
					textSize = S_FONT_SIZE - 2,
					textAlignH = ui.ALIGNMENT.Start,
					textAlignV = ui.ALIGNMENT.Start,
					autoSize = true,
				},
			}
			WINDOW.infoExp.layout.props.text = ""
		end

		-- measure content; sets scroll-enable, cap, reclamp
		local total = 0
		for _, child in ipairs(WINDOW.infoContent.layout.content) do
			total = total + measureInfoHeight(child)
		end
		infoContentHeight = total
		infoScrollable = total > infoContainerHeight
		local bottomPad = S_FONT_SIZE * lineHeightMultiplier
		local maxOffset = math.max(0, infoContentHeight - infoContainerHeight + bottomPad)
		if infoScrollOffset > maxOffset then
			infoScrollOffset = maxOffset
			WINDOW.infoScroller.layout.props.position = v2(0, -infoScrollOffset)
		end
		-- gradient visible when info too long
		WINDOW.infoBottomFade.layout.props.alpha = (infoScrollOffset + infoContainerHeight < infoContentHeight) and 1 or 0
		WINDOW.infoBottomFade:update()

		WINDOW.infoContent:update()
		WINDOW.infoExp:update()
		if WINDOW.infoScroller then WINDOW.infoScroller:update() end
	end
end

-- ============== recipe list refresh ==============

function refreshRecipeList()
	recipeButtons = {}
	WINDOW.recipeList.content = ui.content {}

	-- shared flat list drives positions
	local items = buildVisibleList()
	local totalItems = #items

	local absolutePosition = 0
	if currentSubcategory then
		for i, item in ipairs(items) do
			if item.categoryName == currentSubcategory and item.categoryIndex == (currentIndex or 0) then
				absolutePosition = i - 1
				break
			end
		end
	end
	absolutePosition = math.max(0, math.min(absolutePosition, totalItems - S_MAX_RECIPES))

	local scrollBarStart = totalItems > 0 and (absolutePosition / totalItems) or 0
	local scrollBarEnd = totalItems > 0 and math.min(1, (absolutePosition + S_MAX_RECIPES) / totalItems) or 0
	local scrollBarLength = math.min(1, scrollBarEnd - scrollBarStart)

	if totalItems > S_MAX_RECIPES then
		WINDOW.scrollbarThumb.props.relativePosition = v2(0, scrollBarStart)
		WINDOW.scrollbarThumb.props.relativeSize = v2(1, scrollBarLength)
		local atBottom = absolutePosition + S_MAX_RECIPES >= totalItems
		WINDOW.scrollbarThumb.props.size = v2(0, atBottom and 1 or 0)
		WINDOW.scrollbarContainer.props.size = v2(14, 0)
		WINDOW.recipeList.props.size = v2(-14, S_MAX_RECIPES * rowHeight)
	else
		WINDOW.scrollbarThumb.props.relativePosition = v2(0, 0)
		WINDOW.scrollbarThumb.props.relativeSize = v2(1, 0)
		WINDOW.scrollbarThumb.props.size = v2(0, 0)
		WINDOW.scrollbarContainer.props.size = v2(0, 0)
		WINDOW.recipeList.props.size = v2(0, S_MAX_RECIPES * rowHeight)
	end

	-- draw visible window
	local drawnButtons = 0
	local startIdx = absolutePosition + 1

	for idx = startIdx, #items do
		if drawnButtons >= S_MAX_RECIPES then break end
		local item = items[idx]

		if item.type == "header" then
			local isCollapsed = collapsedCategories[item.categoryName] or false
			local isSelectedHdr = (selectedHeader == item.categoryName)

			local categoryLabel = {
				type = ui.TYPE.Widget,
				props = {
					size = v2(0, rowHeight),
					relativeSize = v2(1, 0),
				},
				content = ui.content {}
			}

			local catBackground = {
				name = 'background',
				type = ui.TYPE.Image,
				props = {
					relativeSize = v2(1, 1),
					resource = getTexture('white'),
					color = isSelectedHdr and selectedColor or darkenColor(textColor, 0.05),
					alpha = isSelectedHdr and 0.8 or 0,
				},
			}
			categoryLabel.content:add(catBackground)

			-- restore hover from click that triggered the rebuild
			if pendingHoverKey == "cat:" .. item.categoryName then
				catBackground.props.alpha = 0.15
				catBackground.props.color = morrowindGold
				hoveredBackground = catBackground
			end

			-- arrow icon
			local arrowSize = S_FONT_SIZE * 0.8
			local arrowTexture = isCollapsed
				and getTexture('textures/CraftingFramework/tri_right.png')
				or getTexture('textures/CraftingFramework/tri_down.png')
			categoryLabel.content:add {
				name = 'arrow',
				type = ui.TYPE.Image,
				props = {
					resource = arrowTexture,
					size = v2(arrowSize, arrowSize),
					position = v2(S_FONT_SIZE * lineHeightMultiplier/2, 4),
					relativePosition = v2(0, 0.5),
					anchor = v2(0.5, 0.5),
					color = (item.craftableCount and item.craftableCount == 0) and util.color.rgb(1, 0, 0) or textColor,
				},
			}

			local headerTextColor = (item.craftableCount and item.craftableCount == 0) and util.color.rgb(1, 0, 0) or textColor
			categoryLabel.content:add {
				name = 'label',
				type = ui.TYPE.Text,
				props = {
					textColor = headerTextColor,
					textShadow = true,
					textShadowColor = util.color.rgba(0, 0, 0, 0.9),
					textAlignV = ui.ALIGNMENT.End,
					textAlignH = ui.ALIGNMENT.Start,
					text = "" .. (item.categoryName or ""),
					textSize = S_FONT_SIZE,
					autoSize = false,
					size = v2(0, rowHeight),
					relativeSize = v2(1, 0),
					position = v2(S_FONT_SIZE * lineHeightMultiplier, 0),
				},
			}

			-- collapse toggle
			local capturedCategoryName = item.categoryName
			local catClickbox = {
				name = 'clickbox',
				props = {
					relativeSize = v2(1, 1),
				},
				events = {
					mouseRelease = async:callback(function()
						collapsedCategories[capturedCategoryName] = not collapsedCategories[capturedCategoryName]
						refreshRecipeList()
					end),
					focusGain = async:callback(function()
						if WINDOW.professionDropdown then
							WINDOW.professionDropdown:destroy()
							WINDOW.professionDropdown = nil
						end
						if hoveredBackground and hoveredBackground ~= catBackground then
							hoveredBackground.props.alpha = 0
							hoveredBackground = nil
						end
						pendingHoverKey = "cat:" .. capturedCategoryName
						catBackground.props.alpha = 0.15
						catBackground.props.color = morrowindGold
						WINDOW.leftBox:update()
					end),
					focusLoss = async:callback(function()
						if hoveredBackground == catBackground then
							hoveredBackground = nil
						end
						pendingHoverKey = nil
						if selectedHeader == capturedCategoryName then
							catBackground.props.color = selectedColor
							catBackground.props.alpha = 0.8
						else
							catBackground.props.alpha = 0
						end
						WINDOW.leftBox:update()
					end),
				},
			}
			categoryLabel.content:add(catClickbox)

			WINDOW.recipeList.content:add(categoryLabel)
			drawnButtons = drawnButtons + 1
		else
			WINDOW.recipeList.content:add(makeRecipeButton(item.recipe))
			drawnButtons = drawnButtons + 1
		end
	end
	updateCollapseIcon()
	updateAllRecipeButtons()
	WINDOW.craftingWindow:update()
end

-- ============== init ==============

-- run mod builders before initial refresh so injected ui rides the first frame
-- ctx is WINDOW itself; `window` is a back-compat alias for `craftingWindow`
WINDOW.window = WINDOW.craftingWindow
for _, entry in ipairs(windowBuilders) do
	entry.func(WINDOW)
end

refreshRecipeList()
updateinfoContent()

