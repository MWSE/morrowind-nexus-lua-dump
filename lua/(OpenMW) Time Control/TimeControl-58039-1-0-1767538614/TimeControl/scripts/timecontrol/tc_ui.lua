--[[
╭──────────────────────────────────────────────────────────────────────╮
│  Time Control - UI Module                                            │
│  Handles the time control UI (slider for GameHour, buttons for       │
│  dayTimeScale/SimulationTimeScale)                                  │
╰──────────────────────────────────────────────────────────────────────╯
]]

local M = {}
M.playerWidget = nil

local input = require('openmw.input')

local playerUpdateJob = nil
local playPauseBtn = nil
local titleText = nil
local progressBar = nil
local modeText = nil

-- Time control state
local currentMode = "sim" -- "day" = dayTimeScale, "sim" = SimulationTimeScale
local dayTimeScale = core.getGameTimeScale()
local simTimeScale = core.getSimulationTimeScale()

local uiSettingsSection = storage.playerSection("SettingsTimeControlUI Settings")
local generalSettingsSection = storage.playerSection("SettingsTimeControlGeneral Settings")

local function clampPosition(pos)
	local layerId = ui.layers.indexOf("HUD")
	local hudSize = ui.layers[layerId].size
	return v2(
		math.max(-PLAYER_WIDTH/3, math.min(pos.x, hudSize.x + PLAYER_WIDTH/3)),
		math.max(0, math.min(pos.y, hudSize.y + PLAYER_HEIGHT/3))
	)
end

local function getGameHour()
	return (core.getGameTime() / 3600) % 24
end

local function setGameHour(hour)
	core.sendGlobalEvent("TimeControl_setGameHour", { hour = hour })
end

local function setDayTimeScale(scale)
	dayTimeScale = math.max(0, scale)
	core.sendGlobalEvent("TimeControl_setDayTimeScale", { scale = dayTimeScale })
end

local function setSimulationTimeScale(scale)
	simTimeScale = math.max(0, scale)
	core.sendGlobalEvent("TimeControl_setSimulationTimeScale", { scale = simTimeScale })
end

local function increaseScale()
	local multiplier = 1
	if input.isCtrlPressed() then
		if currentMode == "day" then
			multiplier = multiplier * 20
		else
			multiplier = multiplier * 5
		end
	end
	if input.isShiftPressed() then
		if currentMode == "day" then
			multiplier = multiplier * 5
		else
			multiplier = multiplier * 2
		end
	end
	if currentMode == "day" then
		dayTimeScale = core.getGameTimeScale()
		local step = 5 * multiplier
		if dayTimeScale >= 1000 and step >= 500 then
			setDayTimeScale(math.floor(dayTimeScale * 1.5))
		else
			setDayTimeScale(dayTimeScale + step)
		end
		if not M.playerWidget then
			messagebox.show(string.format("Day Time Scale: %d", dayTimeScale))
		end
	else
		simTimeScale = core.getSimulationTimeScale()
		if simTimeScale < 1 then
			if simTimeScale == 0 then
				setSimulationTimeScale(0.0625)
			else
				setSimulationTimeScale(math.min(1, simTimeScale * 2))
			end
		else
			local step = 1 * multiplier
			setSimulationTimeScale(simTimeScale + step)
		end
		if not M.playerWidget then
			messagebox.show(string.format("Simulation Time Scale: %g", simTimeScale))
		end
	end
end

local function decreaseScale()
	local multiplier = 1
	if input.isCtrlPressed() then
		if currentMode == "day" then
			multiplier = multiplier * 20
		else
			multiplier = multiplier * 5
		end
	end
	if input.isShiftPressed() then
		if currentMode == "day" then
			multiplier = multiplier * 5
		else
			multiplier = multiplier * 2
		end
	end
	if currentMode == "day" then
		dayTimeScale = core.getGameTimeScale()
		local step = 5 * multiplier
		if dayTimeScale >= 1000 and step >= 500 then
			setDayTimeScale(math.floor(dayTimeScale/1.5))
		else
			setDayTimeScale(math.max(0,  dayTimeScale - step))
		end
		if not M.playerWidget then
			messagebox.show(string.format("Day Time Scale: %d", dayTimeScale))
		end
	else
		simTimeScale = core.getSimulationTimeScale()
		if simTimeScale <= 1 then
			if simTimeScale <= 0.0625 then
				setSimulationTimeScale(0)
			else
				setSimulationTimeScale(core.getSimulationTimeScale() / 2)
			end
		else
			local step = 1 * multiplier
			setSimulationTimeScale(math.max(1, core.getSimulationTimeScale() - step))
		end
		if not M.playerWidget then
			messagebox.show(string.format("Simulation Time Scale: %g", simTimeScale))
		end
	end
end

local function toggleMode()
	if currentMode == "day" then
		currentMode = "sim"
		if not M.playerWidget then
			messagebox.show("Mode: Simulation Time Scale")
		end
	else
		currentMode = "day"
		if not M.playerWidget then
			messagebox.show("Mode: Day Time Scale")
		end
	end
	if M.playerWidget then
		M.rebuildPlayer()
	end
end

local function formatTime(hour)
	local h = math.floor(hour)
	local m = math.floor((hour - h) * 60)
	return string.format("%02d:%02d", h, m)
end

local rebuildPlayer
local destroyPlayer

destroyPlayer = function()
	if playerUpdateJob then
		G_onFrameJobs["playerUpdateJob"] = nil
	end
	if M.playerWidget then
		M.playerWidget:destroy()
		M.playerWidget = nil
	end
	playPauseBtn = nil
	progressBar = nil
	titleText = nil
	modeText = nil
end


local function formatTimeScale(simTimeScale)
local display
if simTimeScale == 0 then
    display = "0x"
elseif simTimeScale >= 0.5 then
    display = string.format("%.1fx", simTimeScale)
else
    local step = (math.log(simTimeScale) / math.log(2) + 5) / 10
    display = string.format("%.1fx", step)
end
return display
end

rebuildPlayer = function()
	local SPACER = 2
	local BAR_WIDTH = PLAYER_WIDTH
	local innerHeight = (SHOW_TITLE == "Inside Player") and PLAYER_HEIGHT or (PLAYER_HEIGHT - TEXT_SIZE)
	local insideTitleHeight = (SHOW_TITLE == "Inside Player") and TEXT_SIZE or 0
	local BUTTON_SIZE = math.min(math.floor(BAR_WIDTH/4 - SPACER), math.floor((innerHeight - insideTitleHeight)*3/4))-1
	local PROGRESS_HEIGHT = math.floor(innerHeight - insideTitleHeight - BUTTON_SIZE)
	
	if M.playerWidget then
		if playerUpdateJob then
			G_onFrameJobs["playerUpdateJob"] = nil
		end
		M.playerWidget:destroy()
		M.playerWidget = nil
	end
	
	local savedX = uiSettingsSection:get("HUD_X_POS")
	local savedY = uiSettingsSection:get("HUD_Y_POS")
	local position
	if savedX and savedY then
		position = v2(savedX, savedY)
	else
		local layerId = ui.layers.indexOf("HUD")
		local hudSize = ui.layers[layerId].size
		position = v2(hudSize.x / 2 - PLAYER_WIDTH / 2, hudSize.y - PLAYER_HEIGHT)
	end
	position = clampPosition(position)
	
	local background = getTexture('black')
	local borderTemplate = makeBorder("thin", THEME_COLOR, 1, {
		type = ui.TYPE.Image,
		props = {
			resource = background,
			relativeSize = v2(1, 1),
			alpha = BACKGROUND_ALPHA,
		}
	}).borders
	
	local buttonContent = ui.content{}
	
	-- Decrease scale button (previous)
	local decreaseBtn = makeButton("", {
		size = v2(BUTTON_SIZE, BUTTON_SIZE),
	}, function()
		decreaseScale()
	end, THEME_COLOR, nil, getTexture('textures/timecontrol/minus.png'), nil, nil, THEME_COLOR)
	buttonContent:add(decreaseBtn.box)
	
	buttonContent:add({ type = ui.TYPE.Widget, props = { size = v2(SPACER, BUTTON_SIZE) } })
	
	-- Toggle mode button (play/pause position)
	local modeIcon = currentMode == "day" and 'textures/timecontrol/clock.png' or 'textures/timecontrol/hourglass.png'
	playPauseBtn = makeButton("", {
		size = v2(BUTTON_SIZE, BUTTON_SIZE),
	}, function()
		toggleMode()
	end, THEME_COLOR, nil, getTexture(modeIcon), nil, nil, THEME_COLOR)
	buttonContent:add(playPauseBtn.box)
	
	buttonContent:add({ type = ui.TYPE.Widget, props = { size = v2(SPACER, BUTTON_SIZE) } })
	
	-- Increase scale button (next)
	local increaseBtn = makeButton("", {
		size = v2(BUTTON_SIZE, BUTTON_SIZE),
	}, function()
		increaseScale()
	end, THEME_COLOR, nil, getTexture('textures/timecontrol/plus.png'), nil, nil, THEME_COLOR)
	buttonContent:add(increaseBtn.box)
	
	buttonContent:add({ type = ui.TYPE.Widget, props = { size = v2(SPACER, BUTTON_SIZE) } })
	
	-- Close button
	local closeBtn = makeButton("", {
		size = v2(BUTTON_SIZE, BUTTON_SIZE),
	}, function()
		M.hide()
	end, util.color.rgb(0.7, 0.3, 0.3), nil, getTexture('textures/timecontrol/x.png'), nil, nil, THEME_COLOR)
	buttonContent:add(closeBtn.box)
	
	-- Progress bar (time of day slider)
	local currentHour = getGameHour()
	local initialProgress = currentHour / 24
	local h, s, v, a = rgbToHsv(THEME_COLOR)
	s = s * 0.3
	v = v * 0.3
	local r, g, b, alpha = hsvToRgb(h, s, v, a)
	local barBackgroundColor = util.color.rgba(r, g, b, alpha)
	
	progressBar = {
		name = "progressBar",
		type = ui.TYPE.Widget,
		props = {
			size = v2(BAR_WIDTH, PROGRESS_HEIGHT-1),
			position = v2(0, BUTTON_SIZE + insideTitleHeight + 1),
		},
		content = ui.content{
			{
				type = ui.TYPE.Image,
				props = {
					resource = getTexture('white'),
					relativeSize = v2(1, 1),
					color = barBackgroundColor,
					alpha = 0.9,
				}
			},
			{
				name = "progressFill",
				type = ui.TYPE.Image,
				props = {
					resource = getTexture('white'),
					size = v2(BAR_WIDTH * initialProgress, PROGRESS_HEIGHT),
					color = THEME_COLOR,
					alpha = 0.9,
				}
			}
		},
		userData = { isDragging = false },
		events = {
			mousePress = async:callback(function(data, elem)
				if data.button == 1 then
					elem.userData.isDragging = true
					local progress = math.max(0, math.min(1, data.offset.x / BAR_WIDTH))
					setGameHour(progress * 24)
				end
			end),
			mouseRelease = async:callback(function(data, elem)
				elem.userData.isDragging = false
				self:sendEvent("timeHud_refreshTime")
			end),
			mouseMove = async:callback(function(data, elem)
				if elem.userData.isDragging then
					local progress = math.max(0, math.min(1, data.offset.x / BAR_WIDTH))
					setGameHour(progress * 24)
					self:sendEvent("timeHud_refreshTime")
				end
			end),
		}
	}
	
	local dragEvents = {
		mousePress = async:callback(function(data, elem)
			if data.button == 1 then
				elem.userData.isDragging = true
				elem.userData.dragStart = data.position
				elem.userData.posStart = M.playerWidget.layout.props.position
			elseif data.button == 3 then
				toggleMode()
			end
		end),
		mouseRelease = async:callback(function(data, elem)
			elem.userData.isDragging = false
		end),
		mouseMove = async:callback(function(data, elem)
			if elem.userData.isDragging then
				local delta = data.position - elem.userData.dragStart
				local pos = clampPosition(elem.userData.posStart + delta)
				uiSettingsSection:set("HUD_X_POS", math.floor(pos.x))
				uiSettingsSection:set("HUD_Y_POS", math.floor(pos.y))
			end
		end),
		focusGain = async:callback(function(data, elem)
			elem.userData.isFocussed = true
			if titleText and SHOW_TITLE == "Hidden" then
				titleText.props.visible = true
			end
		end),
		focusLoss = async:callback(function(data, elem)
			if not elem.userData.isDragging then
				elem.userData.isFocussed = false
			end
			if titleText and SHOW_TITLE == "Hidden" then
				titleText.props.visible = false
			end
		end),
	}
	
	local playerContent = ui.content{
		{
			type = ui.TYPE.Flex,
			props = {
				horizontal = true,
				autoSize = false,
				size = v2(BAR_WIDTH, BUTTON_SIZE),
				arrange = ui.ALIGNMENT.Center,
				align = ui.ALIGNMENT.Center,
				position = v2(0, insideTitleHeight),
			},
			content = buttonContent
		},
		progressBar
	}
	
	-- Build title text showing current time and mode
	local titleString = formatTime(currentHour) .. " | " .. (currentMode == "day" and "Day:" .. string.format("%.1fx", dayTimeScale) or "Sim:" .. formatTimeScale(simTimeScale))
	
	if SHOW_TITLE == "Inside Player" then
		titleText = {
			name = 'text',
			type = ui.TYPE.Text,
			props = {
				text = titleString,
				textColor = TEXT_COLOR,
				textShadow = true,
				textShadowColor = util.color.rgb(0,0,0),
				textSize = TEXT_SIZE,
				textAlignH = ui.ALIGNMENT.Center,
				textAlignV = ui.ALIGNMENT.Center,
				size = v2(math.floor(BAR_WIDTH), TEXT_SIZE),
				anchor = v2(0.5, 0),
				position = v2(math.floor(BAR_WIDTH/2), 0),
				autoSize = false,
			},
		}
		playerContent:add(titleText)
	end
	
	if SHOW_TITLE ~= "Inside Player" then
		titleText = {
			name = 'text',
			type = ui.TYPE.Text,
			props = {
				text = titleString,
				textColor = TEXT_COLOR,
				textShadow = true,
				textShadowColor = util.color.rgb(0,0,0),
				textSize = TEXT_SIZE,
				textAlignH = ui.ALIGNMENT.Center,
				textAlignV = ui.ALIGNMENT.Center,
				autoSize = true,
				visible = SHOW_TITLE == "Above Player",
			},
		}
	
		M.playerWidget = ui.create({
			type = ui.TYPE.Flex,
			layer = 'Modal',
			props = {
				horizontal = false,
				position = position,
				size = v2(PLAYER_WIDTH, PLAYER_HEIGHT),
				anchor = v2(0.5, 0.5),
				arrange = ui.ALIGNMENT.Center,
				align = ui.ALIGNMENT.Center,
				propagateEvents = false,
			},
			userData = {
				isDragging = false,
				isFocussed = false
			},
			events = dragEvents,
			content = ui.content{
				titleText,
				{
					name = 'playerContainer',
					type = ui.TYPE.Widget,
					template = borderTemplate,
					props = {
						size = v2(PLAYER_WIDTH, innerHeight),
					},
					content = playerContent
				}
			}
		})
	else
		M.playerWidget = ui.create({
			type = ui.TYPE.Widget,
			layer = 'Modal',
			template = borderTemplate,
			props = {
				position = position,
				size = v2(PLAYER_WIDTH, innerHeight),
				anchor = v2(0.5, 0.5),
				propagateEvents = false,
			},
			userData = {
				isDragging = false,
				isFocussed = false
			},
			events = dragEvents,
			content = playerContent
		})
	end
	
	-- Update loop
	playerUpdateJob = true
	G_onFrameJobs["playerUpdateJob"] = function(dt)
		if not M.playerWidget then return end
		local currentHour = getGameHour()
		local progress = currentHour / 24
		local progressFill = progressBar.content[2]
		if progressFill then
			progressFill.props.size = v2(BAR_WIDTH * progress, PROGRESS_HEIGHT)
		end
		if titleText then
			local titleString = formatTime(currentHour) .. " | " .. (currentMode == "day" and "Day: " .. string.format("%ix", core.getGameTimeScale()) or "Sim: " .. formatTimeScale(core.getSimulationTimeScale()))
			titleText.props.text = titleString
		end
		M.playerWidget:update()
	end
end

local function show()
	if not M.playerWidget then
		dayTimeScale = core.getGameTimeScale()
		simTimeScale = core.getSimulationTimeScale()
		rebuildPlayer()
	end
end

local function hide()
	destroyPlayer()
end

local function toggle()
	if M.playerWidget then
		hide()
	else
		show()
	end
end

local function updatePosition()
	if not M.playerWidget then return end
	local x = uiSettingsSection:get("HUD_X_POS") or 0
	local y = uiSettingsSection:get("HUD_Y_POS") or 0
	M.playerWidget.layout.props.position = clampPosition(v2(x, y))
	M.playerWidget:update()
end

local function onMouseWheel(dir)
	if not M.playerWidget or not M.playerWidget.layout.userData.isFocussed then return end
	if dir > 0 then
		increaseScale()
	else
		decreaseScale()
	end
end

M.show = show
M.hide = hide
M.toggle = toggle
M.rebuildPlayer = rebuildPlayer
M.updatePosition = updatePosition
M.onMouseWheel = onMouseWheel
M.increaseScale = increaseScale
M.decreaseScale = decreaseScale
M.toggleMode = toggleMode

return M