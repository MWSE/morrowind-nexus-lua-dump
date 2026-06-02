if repairButton then
	repairButton:destroy()
	repairButton = nil
end
if craftingButtonDragHandle then
	craftingButtonDragHandle:destroy()
	craftingButtonDragHandle = nil
end

local makeBorder = require("scripts.CraftingFramework.ui_makeborder")
local borderOffset = 1
local borderFile = "thin"
local textSize = 21
local hasEntropy = core.contentFiles.has("entropy.omwscripts")
local buttonWidth = 200
local buttonHeight = textSize * 1.5
local handleSize = buttonHeight / 2

local borderTemplate = makeBorder(borderFile, nil, borderOffset, {
	type = ui.TYPE.Image,
	props = {
		resource = background,
		relativeSize = v2(1, 1),
		alpha = 0.8,
	}
}).borders

local uniqueButtonId = "repairButton_" .. math.random()
local buttonFocus = nil

-- -------------------------------------------------- position storage --------------------------------------------------

-- drag offset on top of centered base
local settingsSection = storage.playerSection("craftingFrameworkButton")
local layerId = ui.layers.indexOf("Modal")
local layerSize = ui.layers[layerId].size

-- keep button reachable on screen
local function clampOffset(off)
	local maxX = layerSize.x / 2
	local maxY = layerSize.y / 2
	return v2(
		math.max(-maxX, math.min(off.x, maxX)),
		math.max(-maxY, math.min(off.y, maxY))
	)
end

local defaultOffset = v2(0, hasEntropy and 90 or 190)
local savedX = settingsSection:get("CRAFTING_BUTTON_X_OFFSET")
local savedY = settingsSection:get("CRAFTING_BUTTON_Y_OFFSET")
local offset = (savedX and savedY) and v2(savedX, savedY) or defaultOffset
offset = clampOffset(offset)

-- handle top right of button
local function handleOffsetFor(buttonOffset)
	return buttonOffset + v2(buttonWidth / 2, 0)
end

-- -------------------------------------------------- root button --------------------------------------------------

repairButton = ui.create({
	type = ui.TYPE.Widget,
	layer = 'Modal',
	name = "repairButton",
	template = borderTemplate,
	props = {
		relativePosition = v2(0.5, 0.5),
		anchor = v2(0.5, 0),
		size = v2(buttonWidth, buttonHeight),
		position = offset,
	},
	content = ui.content {}
})

-- background
local background = {
	name = 'background',
	type = ui.TYPE.Image,
	props = {
		relativeSize = v2(1, 1),
		resource = getTexture('white'),
		color = util.color.rgb(0, 0, 0),
		alpha = 0.7,
	},
}
repairButton.layout.content:add(background)

-- label
repairButton.layout.content:add({
	name = 'text',
	type = ui.TYPE.Text,
	props = {
		relativePosition = v2(0.5, 0.5),
		anchor = v2(0.5, 0.5),
		text = "Crafting UI",
		textColor = textColor,
		textShadow = true,
		textShadowColor = util.color.rgb(0, 0, 0),
		textSize = textSize,
		textAlignH = ui.ALIGNMENT.Center,
		textAlignV = ui.ALIGNMENT.Center,
	},
})

-- -------------------------------------------------- hover state --------------------------------------------------

local hoverState = {
	button = false,
	handle = false,
}

local function updateHandleVisibility()
	if not craftingButtonDragHandle then return end
	craftingButtonDragHandle.layout.props.alpha = (hoverState.button or hoverState.handle) and 0.7 or 0
	craftingButtonDragHandle:update()
end

-- one-frame delay so a transition button -> handle does not flicker
local function scheduleVisibilityCheck()
	onFrameFunctions["repairButtonHandleVis"] = function()
		onFrameFunctions["repairButtonHandleVis"] = nil
		updateHandleVisibility()
	end
end

-- -------------------------------------------------- button color --------------------------------------------------

local function updateButtonColor(elem)
	if repairButton then
		if elem.userData.focus == 2 then
			background.props.color = textColor
		elseif elem.userData.focus == 1 then
			background.props.color = morrowindGold
		else
			background.props.color = util.color.rgb(0, 0, 0)
		end
		repairButton:update()
	end
end

-- -------------------------------------------------- clickbox --------------------------------------------------

repairButton.layout.content:add({
	name = 'clickbox',
	props = {
		relativeSize = v2(1, 1),
		relativePosition = v2(0, 0),
		anchor = v2(0, 0),
	},
	userData = {
		focus = 0
	},
	events = {
		mouseRelease = async:callback(function(_, elem)
			elem.userData.focus = elem.userData.focus - 1
			if buttonFocus == uniqueButtonId then
				onFrameFunctions[uniqueButtonId] = function()
					if repairButton and buttonFocus == uniqueButtonId then
						openCraftingWindow()
						updateButtonColor(elem)
					end
					onFrameFunctions[uniqueButtonId] = nil
				end
			end
		end),
		mousePress = async:callback(function(_, elem)
			elem.userData.focus = elem.userData.focus + 1
			updateButtonColor(elem)
		end),
		focusGain = async:callback(function(_, elem)
			buttonFocus = uniqueButtonId
			elem.userData.focus = elem.userData.focus + 1
			hoverState.button = true
			updateHandleVisibility()
			updateButtonColor(elem)
		end),
		focusLoss = async:callback(function(_, elem)
			buttonFocus = nil
			elem.userData.focus = 0
			hoverState.button = false
			scheduleVisibilityCheck()
			updateButtonColor(elem)
		end),
	}
})

-- -------------------------------------------------- drag handle --------------------------------------------------

-- separate widget so it can render outside button bounds
craftingButtonDragHandle = ui.create({
	type = ui.TYPE.Flex,
	layer = 'Modal',
	name = "craftingButtonDragHandle",
	props = {
		relativePosition = v2(0.5, 0.5),
		anchor = v2(0, 0.0),
		position = handleOffsetFor(offset),
		alpha = 0,
		horizontal = true,
	},
	content = ui.content {
		-- spacer
		{
			props = {
				size = v2(4, 4),
			},
		},
		-- drag icon
		{
			type = ui.TYPE.Image,
			props = {
				resource = getTexture("textures/CraftingFramework/drag.png"),
				size = v2(handleSize,handleSize),
				alpha = 0.9,
				color = textColor,
			},
		},
	},
	userData = {
		isDragging = false,
		lastMousePos = v2(0, 0),
	},
	events = {
		focusGain = async:callback(function()
			hoverState.handle = true
			updateHandleVisibility()
		end),
		focusLoss = async:callback(function()
			hoverState.handle = false
			scheduleVisibilityCheck()
		end),
		mousePress = async:callback(function(data, elem)
			if data.button == 1 then
				elem.userData.isDragging = true
				elem.userData.lastMousePos = data.position
			end
		end),
		mouseRelease = async:callback(function(_, elem)
			if elem.userData.isDragging then
				elem.userData.isDragging = false
				local newOffset = clampOffset(repairButton.layout.props.position)
				settingsSection:set("CRAFTING_BUTTON_X_OFFSET", math.floor(newOffset.x))
				settingsSection:set("CRAFTING_BUTTON_Y_OFFSET", math.floor(newOffset.y))
				repairButton.layout.props.position = newOffset
				craftingButtonDragHandle.layout.props.position = handleOffsetFor(newOffset)
				repairButton:update()
				craftingButtonDragHandle:update()
			end
		end),
		mouseMove = async:callback(function(data, elem)
			if elem.userData.isDragging then
				local delta = data.position - elem.userData.lastMousePos
				elem.userData.lastMousePos = data.position
				local newOffset = clampOffset((repairButton.layout.props.position or v2(0, 0)) + delta)
				repairButton.layout.props.position = newOffset
				craftingButtonDragHandle.layout.props.position = handleOffsetFor(newOffset)
				repairButton:update()
				craftingButtonDragHandle:update()
			end
		end),
	},
})
