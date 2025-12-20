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
types = require('openmw.types')
self = require("openmw.self")
-- ambient = require("openmw.ambient")
-- vfs = require('openmw.vfs')
-- camera = require('openmw.camera')
-- debug = require('openmw.debug')
-- nearby = require('openmw.nearby')
-- animation = require('openmw.animation')

MODNAME = "TimeHUD"

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
		return util.color.rgb(1, 1, 1)
	end
	return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end

uiSection = storage.playerSection('Settings'..MODNAME.."Time and Date")
require('scripts.timehud.TH_settings')

timeHud = nil
timeText = nil

local stopTimerFn = nil
local lastMinute = -1  -- Performance optimization: prevents unnecessary updates if timer is < 1 Game minute

function updateTimeDisplay(force)
	if not timeText then return end
	
	local gameTime = calendar.gameTime() + saveData.dayOffset * time.day
	local currentMinute = math.floor(gameTime / time.minute)
	local nextUpdate = math.floor(lastMinute / CLOCK_INTERVAL) * CLOCK_INTERVAL + CLOCK_INTERVAL
	
	if I.SunsDusk or force or currentMinute >= nextUpdate or currentMinute < lastMinute then -- Sun's Dusk setting to update more frequently
		local multiplier = math.floor(gameTime / (CLOCK_INTERVAL * 60))
		local timeString
		if CLOCK_FORMAT == "Normal" then
            timeString = calendar.formatGameTime("%H:%M", multiplier * (CLOCK_INTERVAL * 60))
		elseif CLOCK_FORMAT == "Text" then
			local hour = tonumber(calendar.formatGameTime("%H", gameTime))
			timeString="?????"
			--5am - 7am -- dawn 
			if 5 <= hour and hour < 7 then timeString = "Dawn" end
			--7am - 11am -- morning
			if 7 <= hour and hour < 11 then timeString = "Morning" end
			--11am - 1 pm -- noon or Midday
			if 11 <= hour and hour < 13 then timeString = "Noon" end
			--1pm - 4 pm -- afternoon
			if 13 <= hour and hour < 16 then timeString = "Afternoon" end
			--4pm - 6pm -- evening
			if 16 <= hour and hour < 18 then timeString = "Evening" end
			--6pm-8pm -- dusk
			if 18 <= hour and hour < 20 then timeString = "Dusk" end
			--8pm-11pm -- night
			if 20 <= hour and hour < 23 then timeString = "Night" end
			--11pm - 1 am -- midnight
			if 23 <= hour or hour < 1 then timeString = "Midnight" end
			--1am - 4am -- night
			if 1 <= hour and hour < 4 then timeString = "Night" end
		else
            timeString = calendar.formatGameTime("%I:%M %p", multiplier * (CLOCK_INTERVAL * 60))
            timeString = timeString:gsub("a%.m%.", "am")
            timeString = timeString:gsub("p%.m%.", "pm")
        end
		-- Sun's Dusk temperature display
		-- print(SD_TEMP,I.SunsDusk)
		local tempText = ""		
		local tempState = ""
		if SD_TEMP ~= "Hidden" and I.SunsDusk then
			if SD_TEMP == "External Temp" and self.cell.isExterior then
				tempText = ". "..I.SunsDusk.getTrueExternalTemperature()
			elseif SD_TEMP == "Player Temp" then
				tempText = ". "..I.SunsDusk.getPlayerCurrentTemperature()
			elseif SD_TEMP == "Current > Target" then	
				tempText = ". "..I.SunsDusk.getPlayerCurrentTemperature()..">"..I.SunsDusk.getPlayerTargetTemperature()
			end		
		end
		if SD_TEMP_STATE and I.SunsDusk then
			tempState = ", "..I.SunsDusk.getPlayerTemperatureBuff()	-- attempt to index I.SunsDusk (a nil value)
		end		
		timeText.props.text = timeString..tempText..tempState				
		timeText.props.textColor = TEXT_COLOR
		-- date display
		if dateText then
			local day = tonumber(calendar.formatGameTime("%d", gameTime))
            local month = tonumber(calendar.formatGameTime("%m", gameTime))
            local year = tonumber(calendar.formatGameTime("%Y", gameTime))
            local weekday = tonumber(calendar.formatGameTime("%w", gameTime))
            local monthName = calendar.monthName(month)
            local weekdayName = calendar.weekdayName(weekday)
			-- print(day,month,year,weekday,monthName,weekdayName)
			
			if SHOW_DATE=="Morndas" then
				dateText.props.text = weekdayName
			elseif SHOW_DATE=="Morndas, 20." then
				dateText.props.text = weekdayName..", "..day.."."
			elseif SHOW_DATE=="Heartfire" then
				dateText.props.text = monthName
			elseif SHOW_DATE=="Morndas, Heartfire" then
				dateText.props.text = weekdayName..", "..monthName	
			elseif SHOW_DATE=="Morndas, 20. Heartfire" then
				dateText.props.text = weekdayName..", "..day..". "..monthName
			elseif SHOW_DATE=="Morndas, 20.9.427" then
				dateText.props.text =  weekdayName..", "..day.."."..month.."."..year--.." ("..monthName..")"
			end
			
			if TEXT_ALIGNMENT=="Left" then --start
				timeFlex.props.arrange = ui.ALIGNMENT.Start
			elseif TEXT_ALIGNMENT=="Center" then --center
				timeFlex.props.arrange = ui.ALIGNMENT.Center
			elseif TEXT_ALIGNMENT=="Right" then --end
				timeFlex.props.arrange = ui.ALIGNMENT.End
			end
				
			dateText.props.textColor = TEXT_COLOR
		end
		--timeHud:update() -- in refreshUiVisibility()
		lastMinute = currentMinute
	end
	refreshUiVisibility()
end

local function createTimeHud()
	--Clean up existing HUD if it exists
	if timeHud then
		timeHud:destroy()
		timeHud = nil
		timeText = nil
	end
	
	local template = {
		content = ui.content{}
	}
	
	timeHudBackground = {
		type = ui.TYPE.Image,
		name = "timeHudBackground",
		props = {
			resource = ui.texture { path = 'black' },
			relativeSize = v2(1,1),
			alpha = BACKGROUND_ALPHA
		}
	}
	template.content:add(timeHudBackground)

	timeHud = ui.create({
		type = ui.TYPE.Container,
		layer = HUD_LOCK and 'Scene' or 'Modal',
		name = "timeHud",
		template = template,
		props = {
			position = v2(HUD_X_POS, HUD_Y_POS),
			autoSize = true,
		},
		content = ui.content {},
		userData = {
			windowStartPosition = v2(HUD_X_POS, HUD_Y_POS),
		}
	})
	
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
				uiSection:set("HUD_X_POS", math.floor(newPosition.x))
				uiSection:set("HUD_Y_POS", math.floor(newPosition.y))
				--saveData.windowPos = newPosition
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
			size = v2(1,1),
			arrange = ui.ALIGNMENT.Start
		},
		content = ui.content{}
	}
	timeHud.layout.content:add(timeFlex)
	
	timeText = {
		type = ui.TYPE.Text,
		name = "timeText",
		props = {
			text = "",  
			textColor = TEXT_COLOR,
			textShadow = true,
			textShadowColor = util.color.rgba(0,0,0,0.9),
			textAlignV = ui.ALIGNMENT.Start, 
			textAlignH = ui.ALIGNMENT.Start, 
			textSize = FONT_SIZE,
		},
	}
	
	timeFlex.content:add(timeText)
	
	if SHOW_DATE ~= "Off" then
		dateText = {
			type = ui.TYPE.Text,
			name = "dateText",
			props = {
				text = "",
				textColor = TEXT_COLOR,
				textShadow = true,
				textShadowColor = util.color.rgba(0,0,0,0.9),
				textAlignV = ui.ALIGNMENT.Start,
				textAlignH = ui.ALIGNMENT.Start,
				textSize = math.floor(FONT_SIZE * 0.9),
			}, 
		}
		if DATE_ON_TOP then
			timeFlex.content:insert(1, dateText)
		else
			timeFlex.content:add(dateText)
		end
	end
	-- Update Text element immediately (true = force update, even if minute isnt divisible by CLOCK_INTERVAL)
	updateTimeDisplay(true)
end

function onMouseWheel(vertical)
	if timeHud.layout.userData.isDragging then
		if input.isShiftPressed() then
			uiSection:set("BACKGROUND_ALPHA", math.min(1, math.max(0, BACKGROUND_ALPHA + vertical/10)))
		else
			uiSection:set("FONT_SIZE", math.max(5, FONT_SIZE + vertical)) -- minimum 5 to keep readable
		end
	end
end

function chargenFinished()
	if saveData.chargenFinished then
		return true
	end
	if types.Player.getBirthSign(self) ~= "" then
		saveData.chargenFinished = true
		return true
	end
	if types.Player.isCharGenFinished(self) then
		saveData.chargenFinished = true
		return true
	end
	playerItems = types.Container.inventory(self):getAll()
	for a,b in pairs(playerItems) do
		if b.recordId == "chargen statssheet" then
			saveData.chargenFinished = true
			return true
		end
	end
	return false
end

function onLoad(data)
	saveData = data or {}
	if not saveData.dayOffset then
		saveData.dayOffset = 0
	end
	
	local layerId = ui.layers.indexOf("HUD")
	local hudLayerSize = ui.layers[layerId].size
	
	uiSection:set("HUD_X_POS", math.floor(math.max(0, math.min(HUD_X_POS, hudLayerSize.x - FONT_SIZE*2))))
	uiSection:set("HUD_Y_POS", math.floor(math.max(0, math.min(HUD_Y_POS, hudLayerSize.y - FONT_SIZE))))
	
	createTimeHud()
	
	stopTimerFn = time.runRepeatedly(updateTimeDisplay, 60 * time.second, {
		type = time.GameTime,  -- pauses with game
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

function refreshUiVisibility()
	-- if HUD_EXTERIOR setting is enabled and (your character is in an exterior or quasi exterior) or not HUD_EXTERIOR
	if chargenFinished() and I.UI.isHudVisible() and ( not HUD_EXTERIOR or (self.cell:hasTag("QuasiExterior") or self.cell.isExterior)) then-- if not HUD_EXTERIOR and self.cell.isExterior then
		if HUD_DISPLAY == "Always" then
			timeHud.layout.props.visible = true
			timeHud:update()
		elseif HUD_DISPLAY == "Never" then
			timeHud.layout.props.visible = false
			timeHud:update()
		elseif HUD_DISPLAY == "Interface Only" then
			timeHud.layout.props.visible = currentUiMode == "Interface"
			timeHud:update()
		elseif HUD_DISPLAY == "Hide on Interface" then
			timeHud.layout.props.visible = currentUiMode == nil
			timeHud:update()
		else--if HUD_DISPLAY == "Hide on Dialogue Only" then
			timeHud.layout.props.visible = currentUiMode ~= "Dialogue" and currentUiMode ~= "Barter"
			timeHud:update()
		end
	else
		timeHud.layout.props.visible = false
		timeHud:update()
	end
end

function UiModeChanged(data)
	if not timeHud then return end
-- print('UiModeChanged from', data.oldMode , 'to', data.newMode, '('..tostring(data.arg)..')')
	currentUiMode = data.newMode
	refreshUiVisibility()
	shouldRefreshUiVisibility = 3

	if data.oldMode == "Rest" then
		--print("upd after rest")
		updateTimeDisplay()
	end
end

local function onFrame()
	if shouldRefreshUiVisibility then
		shouldRefreshUiVisibility = shouldRefreshUiVisibility - 1
		if shouldRefreshUiVisibility == 0 then
			shouldRefreshUiVisibility = nil
			refreshUiVisibility()
		end
	end

end

local function receiveDayOffset(offset)
	saveData.dayOffset = offset
end

return {
	engineHandlers = {
		onInit = onLoad,
		onLoad = onLoad,
		onSave = onSave,
		onMouseWheel = onMouseWheel,
		onFrame = onFrame,
	},
	eventHandlers = {
		UiModeChanged = UiModeChanged,
		timeHud_receiveDayOffset = receiveDayOffset,
	}
}