-- QSU_scenarioChoice.lua
-- Scenario choice window for Quickstart Unchained mod

local scenarioChoice = {}

local ui = require('openmw.ui')
local util = require('openmw.util')
local core = require('openmw.core')
local async = require('openmw.async')
local v2 = util.vector2

-- Window state
local choiceWindow = nil
local creationTime = 0
local onScenarioSelectedCallback = nil

-- Configuration
local textSize = 18
local spacer = 5
local listWidth = 300


local textColor = getColorFromGameSettings("fontColor_color_normal_over")
local morrowindGold = getColorFromGameSettings("fontColor_color_normal")


-- Show the scenario choice window
function scenarioChoice.show(onSelected)
	-- Destroy existing window
	if choiceWindow then
		choiceWindow:destroy()
		choiceWindow = nil
	end
	if mouseTooltip then
		mouseTooltip:destroy()
		mouseTooltip = nil
	end
	onScenarioSelectedCallback = onSelected
	creationTime = core.getRealTime()
	
	local lineHeight = textSize * 1.4
	local listHeight = #scenarioOrder * lineHeight + spacer * 2
	local dialogHeight = listHeight + textSize * 2 + spacer * 4
	
	choiceWindow = ui.create({
		type = ui.TYPE.Container,
		layer = 'Modal',
		template = I.MWUI.templates.boxTransparent,
		name = "scenarioChoiceWindow",
		props = {
			relativePosition = v2(0.5, 0.5),
			anchor = v2(0.5, 0.5),
			size = v2(listWidth + spacer * 2, dialogHeight),
		},
		content = ui.content {}
	})
	
	-- Main flex container
	local mainFlex = {
		type = ui.TYPE.Flex,
		name = 'mainFlex',
		props = {
			relativeSize = v2(1, 1),
			arrange = ui.ALIGNMENT.Center,
			horizontal = false,
		},
		content = ui.content {}
	}
	choiceWindow.layout.content:add(mainFlex)
	
	-- Top spacing
	mainFlex.content:add{ props = { size = v2(1, spacer) } }
	
	-- Title row with close button
	local titleRow = {
		type = ui.TYPE.Widget,
		props = { size = v2(listWidth, textSize * 1.5) },
		content = ui.content {
			{
				type = ui.TYPE.Text,
				props = {
					relativePosition = v2(0.5, 0.5),
					anchor = v2(0.5, 0.5),
					text = "Choose Scenario",
					textColor = morrowindGold,
					textShadow = true,
					textShadowColor = util.color.rgb(0, 0, 0),
					textSize = textSize * 1.1,
					textAlignH = ui.ALIGNMENT.Center,
					textAlignV = ui.ALIGNMENT.Center,
				}
			}
		}
	}
	
	-- Close button
	local closeButtonSize = textSize * 1.2
	
	local closeButtonBg = {
		name = 'closeButtonBg',
		type = ui.TYPE.Image,
		props = {
			resource = getTexture('white'),
			color = util.color.rgb(0.02, 0.02, 0.02),
			alpha = 0.8,
			size = v2(closeButtonSize, closeButtonSize),
		},
	}
	
	local closeButton = {
		name = 'closeButton',
		template = I.MWUI.templates.borders,
		type = ui.TYPE.Container,
		props = {
			relativePosition = v2(1, 0.5),
			anchor = v2(1, 0.5),
			position = v2(-spacer, 0),
			size = v2(closeButtonSize, closeButtonSize),
		},
		content = ui.content {}
	}
	closeButton.content:add(closeButtonBg)
	closeButton.content:add({
		name = 'closeIcon',
		type = ui.TYPE.Image,
		props = {
			oposition = v2(2,2),
			resource = getTexture('textures/QuickstartUnchained/x.png'),
			size = v2(closeButtonSize - 4, closeButtonSize - 4),
			color = morrowindGold,
		},
	})
	closeButton.content:add({
		name = 'closeClickbox',
		props = {
			size = v2(closeButtonSize, closeButtonSize),
		},
		userData = { focus = false, pressed = false },
		events = {
			mouseRelease = async:callback(function(_, elem)
				elem.userData.pressed = false
				if choiceWindow and elem.userData.focus and core.getRealTime() > creationTime + 0.3 then
					if onScenarioSelectedCallback then
						onScenarioSelectedCallback(-1)
					end
					if choiceWindow then
						choiceWindow:destroy()
						choiceWindow = nil
					end
					if mouseTooltip then
						mouseTooltip:destroy()
						mouseTooltip = nil
					end
					return
				end
				if choiceWindow then
					closeButtonBg.props.color = elem.userData.focus 
						and util.color.rgb(morrowindGold.r * 0.7, morrowindGold.g * 0.7, morrowindGold.b * 0.7)
						or util.color.rgb(0.02, 0.02, 0.02)
					choiceWindow:update()
				end
			end),
			focusGain = async:callback(function(_, elem)
				elem.userData.focus = true
				if choiceWindow then
					closeButtonBg.props.color = util.color.rgb(morrowindGold.r * 0.7, morrowindGold.g * 0.7, morrowindGold.b * 0.7)
					choiceWindow:update()
				end
			end),
			focusLoss = async:callback(function(_, elem)
				elem.userData.focus = false
				elem.userData.pressed = false
				if choiceWindow then
					closeButtonBg.props.color = util.color.rgb(0.02, 0.02, 0.02)
					choiceWindow:update()
				end
			end),
			mousePress = async:callback(function(_, elem)
				elem.userData.focus = true
				elem.userData.pressed = true
				if choiceWindow then
					closeButtonBg.props.color = morrowindGold
					choiceWindow:update()
				end
			end),
		}
	})
	titleRow.content:add(closeButton)
	mainFlex.content:add(titleRow)
	
	-- Spacing
	mainFlex.content:add{ props = { size = v2(1, spacer) } }
	
	-- Scenario buttons container
	local scenariosFlex = {
		type = ui.TYPE.Flex,
		props = {
			size = v2(listWidth, listHeight),
			arrange = ui.ALIGNMENT.Center,
			horizontal = false,
		},
		content = ui.content {}
	}
	
	-- Add scenario buttons
	for i, scenarioName in ipairs(scenarioOrder) do
		local scenario = scenarios[scenarioName]
		local highlightColor = morrowindGold
		
		local buttonBackground = {
			name = 'background',
			type = ui.TYPE.Image,
			props = {
				resource = getTexture('white'),
				color = util.color.rgb(0.02, 0.02, 0.02),
				alpha = 0.8,
				size = v2(listWidth - spacer * 2, lineHeight),
				autoSize = false
			},
		}
		
		local box = {
			name = 'btn' .. i,
			template = I.MWUI.templates.borders,
			type = ui.TYPE.Container,
			props = { 
				size = v2(listWidth - spacer * 2, lineHeight),
				autoSize = false
			},
			content = ui.content {}
		}
		box.content:add(buttonBackground)
		box.content:add({
			name = 'text',
			type = ui.TYPE.Text,
			props = {
				--relativePosition = v2(0.5, 0.5),
				--anchor = v2(0.5, 0.5),
				text = scenario.name,
				textColor = textColor,
				textShadow = true,
				textShadowColor = util.color.rgb(0, 0, 0),
				textSize = textSize,
				textAlignH = ui.ALIGNMENT.Center,
				textAlignV = ui.ALIGNMENT.Center,
				size = v2(listWidth - spacer * 2, lineHeight - 2),
				autoSize = false
			},
		})
		
		local clickbox = {
			name = 'clickbox',
			props = { size = v2(listWidth - spacer * 2, lineHeight),
				autoSize = false },
			userData = { focus = false, pressed = false },
			events = {
				mouseRelease = async:callback(function(_, elem)
					if onScenarioSelectedCallback then
						onScenarioSelectedCallback(scenarioName, scenario)
					end
					elem.userData.pressed = false
					elem.userData.focus = false
					if choiceWindow then
						choiceWindow:destroy()
						choiceWindow = nil
					end
					if mouseTooltip then
						mouseTooltip:destroy()
						mouseTooltip = nil
					end
				end),
				focusGain = async:callback(function(_, elem)
					elem.userData.focus = true
					if choiceWindow then
						buttonBackground.props.color = util.color.rgb(highlightColor.r * 0.7, highlightColor.g * 0.7, highlightColor.b * 0.7)
						choiceWindow:update()
					end
				end),
				focusLoss = async:callback(function(_, elem)
					elem.userData.focus = false
					elem.userData.pressed = false
					if choiceWindow then
						buttonBackground.props.color = util.color.rgb(0.02, 0.02, 0.02)
						choiceWindow:update()
					end
					if mouseTooltip then
						mouseTooltip:destroy()
						mouseTooltip = nil
					end
				end),
				mousePress = async:callback(function(_, elem)
					elem.userData.focus = true
					elem.userData.pressed = true
					if choiceWindow then
						buttonBackground.props.color = highlightColor
						choiceWindow:update()
					end
				end),
			}
		}
		if scenario.description then
			addTooltip(clickbox, scenario.description)
		end
		box.content:add(clickbox)
		
		scenariosFlex.content:add(box)
		scenariosFlex.content:add{ props = { size = v2(1, 2) } }
	end
	
	mainFlex.content:add(scenariosFlex)
	mainFlex.content:add{ props = { size = v2(1, spacer) } }
end

function scenarioChoice.isOpen()
	return choiceWindow ~= nil
end

function scenarioChoice.close()
	if choiceWindow then
		choiceWindow:destroy()
		choiceWindow = nil
		onScenarioSelectedCallback = nil
	end
	if mouseTooltip then
		mouseTooltip:destroy()
		mouseTooltip = nil
	end
end

function scenarioChoice.getScenarios()
	return scenarios
end

function scenarioChoice.getScenarioOrder()
	return scenarioOrder
end

function scenarioChoice.addScenario(name, cell, position, rotation)
	scenarios[name] = {
		name = name,
		cell = cell,
		position = position,
		rotation = rotation or util.transform.rotateZ(math.rad(0)),
	}
	table.insert(scenarioOrder, name)
end

return scenarioChoice