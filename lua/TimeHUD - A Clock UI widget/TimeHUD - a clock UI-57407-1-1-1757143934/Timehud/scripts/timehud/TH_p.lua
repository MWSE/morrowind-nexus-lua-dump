ui = require('openmw.ui')
util = require('openmw.util')
core = require('openmw.core')
calendar = require('openmw_aux.calendar')
time = require('openmw_aux.time')
async = require('openmw.async')
v2 = util.vector2
I = require('openmw.interfaces')
storage = require('openmw.storage')
input = require('openmw.input')
MODNAME = "TimeHUD"
settingsSection = storage.playerSection('Settings'..MODNAME)
require('scripts.timehud.TH_settings')

timeHud = nil
timeText = nil

local stopTimerFn = nil
local lastMinute = -1  -- Performance optimization: prevents unnecessary updates if timer is < 1 Game minute
local layerId = ui.layers.indexOf("HUD")
local hudLayerSize = ui.layers[layerId].size

-- Parse color strings from game settings (format: "255,255,255")
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
		return util.color.rgb(1, 1, 1)
	end
	-- Convert from 0-255 range to OpenMW's 0-1 range
	return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end

fontColor = getColorFromGameSettings("FontColor_color_normal")

function updateTimeDisplay(force)
	if not timeText then return end
	
	local gameTime = calendar.gameTime()
	local currentMinute = math.floor(gameTime / time.minute)
	
	-- Only update when minute changes and matches our update interval
	if force or currentMinute ~= lastMinute and currentMinute % CLOCK_INTERVAL == 0 then
		-- format ingame time using the engine's api https://openmw.readthedocs.io/en/latest/reference/lua-scripting/openmw_aux_calendar.html##(calendar).formatGameTime
		local multiplier = math.floor(gameTime / (CLOCK_INTERVAL * 60))
		local timeString = calendar.formatGameTime("%H:%M", multiplier * (CLOCK_INTERVAL * 60))
		-- change the text at the ui element
		timeText.props.text = timeString
		if dateText then
			-- add date here
			local day = tonumber(calendar.formatGameTime("%d", gameTime))
            local month = tonumber(calendar.formatGameTime("%m", gameTime))
            local year = tonumber(calendar.formatGameTime("%Y", gameTime))
            local weekday = tonumber(calendar.formatGameTime("%w", gameTime))
            local monthName = calendar.monthName(month)
            local weekdayName = calendar.weekdayName(weekday)
			print(day,month,year,weekday,monthName,weekdayName)
			
			if SHOW_DATE=="Morndas" then
				dateText.props.text = weekdayName
			elseif SHOW_DATE=="Morndas, 20." then
				dateText.props.text = weekdayName..", "..day.."."
			elseif SHOW_DATE=="Heartfire" then
				dateText.props.text = monthName
			elseif SHOW_DATE=="Morndas, 20. Heartfire" then
				dateText.props.text = weekdayName..", "..day..". "..monthName
			end
			
		    -- items = {"Off", "Morndas", "Morndas, 20.", "Heartfire", "Morndas, 20. Heartfire"}

		end
		-- always remember to update the root
		timeHud:update()
		-- unnecessary since the timer runs only every ingame minute, but if the timer was 30 ingame seconds this would prevent double updates:
		lastMinute = currentMinute
		
	end
end

local function createTimeHud()
	-- Clean up existing HUD if it exists
	if timeHud then
		timeHud:destroy()
		timeHud = nil
		timeText = nil
	end
	
	-- Auto scaling backgrounds can only be made by doing it with a template
	local template = {
		content = ui.content{}
	}
	
	-- The background is in the template, but still referenced through the variable:
	timeHudBackground = {
		type = ui.TYPE.Image,
		name = "timeHudBackground",
		props = {
			resource = ui.texture { path = 'black' },
			relativeSize = v2(1,1),  -- Fill entire container
			alpha = BACKGROUND_ALPHA
		}
	}
	template.content:add(timeHudBackground)
	
	-- Main container for the entire HUD
	timeHud = ui.create({
		type = ui.TYPE.Container,
		layer = 'Modal',  -- Appears above game UI
		name = "timeHud",
		template = template, -- Our background is in the template
		props = {
			position = saveData.windowPos,
			autoSize = true,  -- Size automatically based on content
		},
		content = ui.content {},
		userData = {
			windowStartPosition = saveData.windowPos,
		}
	})
	
	-- Set up mouse drag functionality
	timeHud.layout.events = {
		mousePress = async:callback(function(data, elem)
			if data.button == 1 then  -- Left mouse button
				if not elem.userData then
					elem.userData = {}
				end
				elem.userData.isDragging = true
				elem.userData.dragStartPosition = data.position
				elem.userData.windowStartPosition = timeHud.layout.props.position or v2(0, 0)
			end
			timeHud:update()
		end),
		
		mouseRelease = async:callback(function(data, elem)
			if elem.userData then
				elem.userData.isDragging = false
			end
			timeHud:update()
		end),
		
		mouseMove = async:callback(function(data, elem)
			if elem.userData and elem.userData.isDragging then
				-- Calculate new position based on mouse movement
				local deltaX = data.position.x - elem.userData.dragStartPosition.x
				local deltaY = data.position.y - elem.userData.dragStartPosition.y
				local newPosition = v2(
					elem.userData.windowStartPosition.x + deltaX,
					elem.userData.windowStartPosition.y + deltaY
				)
				saveData.windowPos = newPosition
				timeHud.layout.props.position = newPosition
				timeHud:update()
			end
		end),
	}
	timeFlex =  {
		type = ui.TYPE.Flex,
		name = "timeFlex",
		props = {
			horizontal = false,
			autoSize = true,
			size = v2(1,1)
		},
		content = ui.content{}
	}
	timeHud.layout.content:add(timeFlex)
	
	-- Text element that displays the actual time
	timeText = {
		type = ui.TYPE.Text,
		name = "timeText",
		props = {
			text = "",  -- Will be set by updateTimeDisplay
			textColor = fontColor,
			textShadow = true,
			textShadowColor = util.color.rgba(0,0,0,0.9),
			textAlignV = ui.ALIGNMENT.Center,
			textAlignH = ui.ALIGNMENT.Center,
			textSize = FONT_SIZE,
		},
	}
	timeFlex.content:add(timeText)
	if SHOW_DATE ~= "Off" then
		dateText = {
			type = ui.TYPE.Text,
			name = "dateText",
			props = {
				text = "",  -- Will be set by updateTimeDisplay
				textColor = fontColor,
				textShadow = true,
				textShadowColor = util.color.rgba(0,0,0,0.9),
				textAlignV = ui.ALIGNMENT.Center,
				textAlignH = ui.ALIGNMENT.Center,
				textSize = math.floor(FONT_SIZE * 0.9),

			},
		}		
		timeFlex.content:add(dateText)
	end
	-- Update Text element immediately (true = force update, even if minute isnt divisible by CLOCK_INTERVAL)
	updateTimeDisplay(true)
end

function onMouseWheel(vertical)
	if timeHud.layout.userData.isDragging then
		-- this will trigger updateSettings and update the element:
		if input.isShiftPressed() then
			-- Adjust background transparency
			settingsSection:set("BACKGROUND_ALPHA", math.max(0, BACKGROUND_ALPHA + vertical/10))
		else
			-- Adjust font size (minimum 5 to keep readable)
			settingsSection:set("FONT_SIZE", math.max(5, FONT_SIZE + vertical))
		end
	end
end

function onLoad(data) -- also onInit
	saveData = data or {}
	-- configure initial window pos
	if not saveData.windowPos then 
		saveData.windowPos = v2(hudLayerSize.x*0.01, hudLayerSize.y*0.925)
	end
	-- make sure window pos isn't outside of the screen
	saveData.windowPos = v2(
		math.max(0, math.min(saveData.windowPos.x, hudLayerSize.x - FONT_SIZE*2)), 
		math.max(0, math.min(saveData.windowPos.y, hudLayerSize.y - FONT_SIZE))
	)
	
	-- ui creation
	createTimeHud()
	
	
	-- Set up timer to check for updates
	-- Check every ingame minute
	stopTimerFn = time.runRepeatedly(updateTimeDisplay, 60 * time.second, {
		type = time.GameTime,  -- Uses game time (pauses with game)
		initialDelay = 0
	})
end

input.registerTriggerHandler("ToggleHUD", async:callback(function()
    timeHud.layout.props.visible = I.UI.isHudVisible()
    timeHud:update()
end))

function onSave()
	return saveData
end

return {
	engineHandlers = {
		onLoad = createTimeHud,
		onInit = createTimeHud,
		onInit = onLoad,
		onLoad = onLoad,
		onSave = onSave,
		onMouseWheel = onMouseWheel,
	}
}
