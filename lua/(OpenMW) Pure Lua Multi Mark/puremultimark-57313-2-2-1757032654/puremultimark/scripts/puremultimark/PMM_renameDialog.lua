-- PMM_renameDialog.lua
-- Rename dialog for Pure Multi Mark mod

local renameDialog = {}

-- Import required modules
local makeBorder = require("scripts.puremultimark.PMM_makeborder")

-- Dialog state
local renameWindow = nil
local textInput = nil
local currentIndex = nil
local onConfirmCallback = nil
local onCancelCallback = nil
local currentTextContent = ""
local creationTime = 0

-- Configuration from main window
local textSize = playerSection:get("FONT_SIZE")
local spacer = 5
local borderOffset = 1
local borderFile = "thin"

-- Colors (should match main window)
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

local function darkenColor(color, mult)
	return util.color.rgb(color.r*mult, color.g*mult, color.b*mult)
end

-- Texture cache
local textureCache = {}
local function getTexture(path)
	if not textureCache[path] then
		textureCache[path] = ui.texture{path = path}
	end
	return textureCache[path]
end

-- Color setup
local textColor = getColorFromGameSettings("fontColor_color_normal_over")
local morrowindGold = getColorFromGameSettings("fontColor_color_normal")
local background = ui.texture { path = 'black' }

-- Border templates
local borderTemplate = makeBorder(borderFile, util.color.rgb(0.5,0.5,0.5), borderOffset, {
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
		alpha = 0.9,
	}
}).borders

-- makeButton v4.0
local function makeButton(label, props, func, highlightColor, parent)
	local uniqueButtonId = ""..math.random()
	local box = {
		name = uniqueButtonId,
		type = ui.TYPE.Widget,
		props = props,
		content = ui.content {}
	}
	
	local buttonBackground = {
		name = 'background',
		template = borderTemplate,
		type = ui.TYPE.Image,
		props = {
			relativeSize = v2(1, 1),
			resource = getTexture('white'),
			color = util.color.rgb(0,0,0),
			alpha = 0.75,
		},
	}
	box.content:add(buttonBackground)
	
	--- any content here
	local text = {
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
	box.content:add(text)
	
	local clickbox = {
		name = 'clickbox',
		props = {
			relativeSize = v2(1, 1),
		},
		userData = {
			focus = false,
			pressed = false,
			--applyColor = func
		},
	}
	
	local function applyColor(elem)
		elem = elem or clickbox
		if renameWindow then -- HARDCODED
			if elem.userData.pressed then
				buttonBackground.props.color = highlightColor or morrowindGold
			elseif elem.userData.focus then
				buttonBackground.props.color = darkenColor(highlightColor or morrowindGold, 0.7)
			else
				buttonBackground.props.color = util.color.rgb(0,0,0)
			end
			parent:update()
		end
	end
	clickbox.userData.applyColor = applyColor
	
	clickbox.events = {
		mouseRelease = async:callback(function(_, elem)
			elem.userData.pressed = false
			onFrameFunctions[uniqueButtonId] = function()
				if renameWindow then
					if elem.userData.focus and core.getRealTime() > creationTime + 0.4 then
						func(elem)
					end
					applyColor(elem)
				end
				onFrameFunctions[uniqueButtonId] = nil
			end
		end),
		focusGain = async:callback(function(_, elem)
			elem.userData.focus = true
			applyColor(elem)
		end),
		focusLoss = async:callback(function(_, elem)
			elem.userData.focus = false
			elem.userData.pressed = false -- ????
			applyColor(elem)
		end),
		mousePress = async:callback(function(_, elem)
			elem.userData.focus = true
			elem.userData.pressed = true
			applyColor(elem)
		end),
	}
	box.content:add(clickbox)
	return box
end

-- Function to destroy the rename dialog
local function destroyRenameDialog()
	if renameWindow then
		renameWindow:destroy()
		renameWindow = nil
		textInput = nil
		currentIndex = nil
		onConfirmCallback = nil
		onCancelCallback = nil
		currentTextContent = ""
	end
end

-- Function to show the rename dialog
function renameDialog.show(locationIndex, currentName, onConfirm, onCancel)
	-- Clean up any existing dialog
	destroyRenameDialog()
	
	-- Store parameters
	currentIndex = locationIndex
	onConfirmCallback = onConfirm
	onCancelCallback = onCancel
	currentTextContent = currentName or ""
	creationTime = core.getRealTime()
	
	-- Dialog dimensions
	local dialogWidth = math.floor(350/23*textSize*playerSection:get("WIDTH_MULT"))
	local dialogHeight = textSize * 8
	
	-- Create the main dialog window
	renameWindow = ui.create({
		type = ui.TYPE.Container,
		layer = 'Modal',
		name = "renameDialog",
		template = rootBorderTemplate,
		props = {
			relativePosition = v2(0.5, 0.5),
			anchor = v2(0.5, 0.5),
			size = v2(dialogWidth + spacer*2, dialogHeight + spacer*2),
		},
		content = ui.content {}
	})
	
	-- Main flex container
	local mainFlex = {
		type = ui.TYPE.Flex,
		name = 'mainFlex',
		props = {
			relativeSize = v2(1, 1),
			arrange = ui.ALIGNMENT.Start,
			horizontal = false,
		},
		content = ui.content {}
	}
	renameWindow.layout.content:add(mainFlex)
	
	-- Add top spacing
	mainFlex.content:add{ props = { size = v2(1, spacer) } }
	
	-- Title
	local titleContainer = {
		type = ui.TYPE.Widget,
		props = {
			size = v2(dialogWidth, textSize * 1.5),
		},
		content = ui.content {}
	}
	
	local titleText = {
		type = ui.TYPE.Text,
		props = {
			relativePosition = v2(0.5, 0.5),
			anchor = v2(0.5, 0.5),
			text = "Rename Location",
			textColor = textColor,
			textShadow = true,
			textShadowColor = util.color.rgb(0,0,0),
			textSize = textSize * 1.2,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
		}
	}
	titleContainer.content:add(titleText)
	mainFlex.content:add(titleContainer)
	
	-- Add spacing
	mainFlex.content:add{ props = { size = v2(1, spacer) } }
	
	-- Text input container
	local inputContainer = {
		type = ui.TYPE.Widget,
		props = {
			size = v2(dialogWidth, textSize * 2),
		},
		content = ui.content {}
	}
	
	-- Text input background
	local inputBackground = {
		name = 'inputBackground',
		template = borderTemplate,
		type = ui.TYPE.Image,
		props = {
			relativeSize = v2(1, 1),
			resource = getTexture('white'),
			color = util.color.rgb(0.03, 0.03, 0.03),
			alpha = 0.9,
		},
	}
	inputContainer.content:add(inputBackground)
	
	-- Text input widget
	textInput = {
		type = ui.TYPE.TextEdit,
		props = {
			relativeSize = v2(1, 1),
			relativePosition = v2(0, 0),
			text = currentTextContent,
			textSize = textSize,
			textColor = textColor,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
			multiline = false,
			wordWrap = false,
			autoSize = false,
		},
		events = {
			keyPress = async:callback(function(data, elem)
				if data.code == input.KEY.Enter or data.code == input.KEY.NP_Enter then
					-- Confirm rename
					local newName = currentTextContent
					if newName and newName:match("^%s*(.-)%s*$") ~= "" then
						if onConfirmCallback then
							onConfirmCallback(currentIndex, newName:match("^%s*(.-)%s*$"))
						end
						destroyRenameDialog()
					end
				elseif data.code == input.KEY.Escape then
					-- Cancel rename
					if onCancelCallback then
						onCancelCallback()
					end
					destroyRenameDialog()
				end
			end),
			textChanged = async:callback(function(newText, elem)
				-- Store the current text content and update the widget props
				currentTextContent = newText
				elem.props.text = newText
			end),
			focusGain = async:callback(function(_, elem)
				inputBackground.props.color = util.color.rgb(0.05, 0.05, 0.05)
				-- Preserve text before update
				elem.props.text = currentTextContent
				renameWindow:update()
			end),
			focusLoss = async:callback(function(_, elem)
				if renameWindow then
					inputBackground.props.color = util.color.rgb(0.03, 0.03, 0.03)
					-- Preserve text before update
					elem.props.text = currentTextContent
					renameWindow:update()
				end
			end),
		}
	}
	inputContainer.content:add(textInput)
	mainFlex.content:add(inputContainer)
	
	-- Add spacing
	mainFlex.content:add{ props = { size = v2(1, spacer) } }
	
	-- Button container
	local buttonContainer = {
		type = ui.TYPE.Flex,
		props = {
			size = v2(dialogWidth, textSize * 2),
			arrange = ui.ALIGNMENT.Center,
			horizontal = true,
		},
		content = ui.content {}
	}
	
	-- Confirm button
	local confirmButton = makeButton("Confirm", {size = v2(textSize * 4, textSize * 1.5)}, function()
		local newName = currentTextContent
		if newName and newName:match("^%s*(.-)%s*$") ~= "" then
			if onConfirmCallback then
				onConfirmCallback(currentIndex, newName:match("^%s*(.-)%s*$"))
			end
			destroyRenameDialog()
		end
	end, util.color.rgb(0.2, 0.6, 0.2), renameWindow)
	buttonContainer.content:add(confirmButton)
	
	-- Add spacing between buttons
	buttonContainer.content:add{ props = { size = v2(spacer * 2, 1) } }
	
	-- Cancel button
	local cancelButton = makeButton("Cancel", {size = v2(textSize * 4, textSize * 1.5)}, function()
		if onCancelCallback then
			onCancelCallback()
		end
		destroyRenameDialog()
	end, util.color.rgb(0.6, 0.2, 0.2), renameWindow)
	buttonContainer.content:add(cancelButton)
	
	mainFlex.content:add(buttonContainer)
	
	-- Add bottom spacing
	mainFlex.content:add{ props = { size = v2(1, spacer) } }
	
	-- Focus the text input immediately using UI events
	--onFrameFunctions["focusTextInput"] = function()
	--	if textInput and renameWindow then
	--		-- The TextEdit widget should automatically receive focus when created
	--	end
	--	onFrameFunctions["focusTextInput"] = nil
	--end
end

-- Function to check if dialog is open
function renameDialog.isOpen()
	return renameWindow ~= nil
end

-- Function to force close dialog
function renameDialog.close()
	destroyRenameDialog()
end

return renameDialog