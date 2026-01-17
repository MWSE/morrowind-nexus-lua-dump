--[[
╭──────────────────────────────────────────────────────────────────────╮
│  Audiobook Player                                                     │
│  Handles playback, UI, bookmarks, and events                          │
╰──────────────────────────────────────────────────────────────────────╯
]]

-- Module table
local M = {}
M.playerWidget = nil

-- UI element references
local playerUpdateJob = nil
local switchBtn = nil
local playPauseBtn = nil
local titleText = nil
local progressBar = nil


-- Playback state
local isPlaying = false
local currentBookName = ""
local currentBookId = ""
local currentAudioFile = ""
local startTime = 0
local pausedTime = 0
local currentOffset = 0
local totalDuration = 0
local currentVolume = 1.0
local lastOpenedBook = nil

-- Pending book
local pendingBook = nil
local switchDelayStart = nil

-- Session play time tracking (time spent playing since createPlayer/doSwitch)
local sessionPlayTime = 0
local sessionPlayStart = nil
local bookPlayTime = 0
local bookPlayLastTick = nil

-- Bookmark storage
local bookmarkSection = storage.playerSection("audiobookBookmarks")

local function saveBookmark(bookId, position)
	if bookId and bookId ~= "" then
		bookmarkSection:set("bookmark_" .. bookId, math.floor(position or 0))
	end
end

local function getBookInfo(book)
	if not book then return nil end
	
	local record = types.Book.record(book)
	local bookId = string.gsub(string.gsub(record.id or "unknown", "%s+", "_"), "[%.']", ""):lower()
	local audioPath = sound_map[bookId]
	
	if not audioPath then
		return nil
	end
	
	local filename = audioPath:match("([^\\]+)%.mp3$")
	local duration = (filename and durations[filename]) or 0
	
	local bookmark = bookmarkSection:get("bookmark_" .. bookId)
	if bookmark and bookmark < 3.5 then
		bookmark = 0
	end
	
	return {
		name = record.name,
		id = bookId,
		audioFile = "Sound\\" .. audioPath,
		duration = duration,
		bookmark = bookmark
	}
end

local generalSettingsSection = storage.playerSection("SettingsAudiobooks2General Settings")
local uiSettingsSection = storage.playerSection("SettingsAudiobooks2UI Settings")

local function clampPosition(pos)
	local layerId = ui.layers.indexOf("HUD")
	local hudSize = ui.layers[layerId].size
	return v2(
		math.max(0, math.min(pos.x, hudSize.x - 50)),
		math.max(0, math.min(pos.y, hudSize.y - 50))
	)
end

local function getCurrentTime()
	if isPlaying then
		return currentOffset + (core.getRealTime() - startTime)
	else
		return pausedTime
	end
end

local function playAudio()
	if currentAudioFile == "" then return end
	if currentOffset > totalDuration then
		currentOffset = 0
	end
	local now = core.getRealTime()
	if sessionPlayStart then
		sessionPlayTime = sessionPlayTime + (now - sessionPlayStart)
	end
	ambient.playSoundFile(currentAudioFile, {
		timeOffset = currentOffset,
		volume = currentVolume,
		pitch = 1.0,
		scale = false,
		loop = false
	})
	startTime = now
	sessionPlayStart = now
	bookPlayLastTick = now
	isPlaying = true
	if M.playerWidget and playPauseBtn then
		playPauseBtn.image.props.resource = getTexture('textures/audiobooks2/pause.png')
		playPauseBtn.applyColor()
	end
end

local function pauseAudio()
	ambient.stopSoundFile(currentAudioFile)
	pausedTime = getCurrentTime()
	currentOffset = pausedTime
	isPlaying = false
	if sessionPlayStart then
		sessionPlayTime = sessionPlayTime + (core.getRealTime() - sessionPlayStart)
		sessionPlayStart = nil
	end
	bookPlayLastTick = nil
	if M.playerWidget and playPauseBtn then
		playPauseBtn.image.props.resource = getTexture('textures/audiobooks2/play.png')
		playPauseBtn.applyColor()
	end
end

local function seekTo(time)
	time = math.max(0, time)
	if totalDuration > 0 then
		time = math.min(time, totalDuration)
	end
	local wasPlaying = isPlaying
	if wasPlaying then
		pauseAudio()
	end
	currentOffset = time
	pausedTime = time
	if wasPlaying then
		playAudio()
	end
end

local function setVolume(vol)
	currentVolume = math.max(0, math.min(1, vol))
	generalSettingsSection:set("PLAYER_VOLUME", currentVolume * 100)
	if isPlaying then
		pauseAudio()
		playAudio()
	end
end

local function stop()
	if not M.playerWidget then return end
	local wasPlaying = isPlaying
	if wasPlaying then
		pauseAudio()
	end
	currentOffset = 0
	pausedTime = 0
	if wasPlaying and not REWIND_STOPS then
		playAudio()
	end
end

local function togglePlayPause()
	if not M.playerWidget then return end
	if isPlaying then
		pauseAudio()
	else
		playAudio()
	end
end

-- Forward declarations
local rebuildPlayer
local destroyPlayer

local function setPendingBook(book)
	local info = getBookInfo(book)
	if not info then return false end
	
	pendingBook = {
		name = info.name,
		audioFile = info.audioFile,
		duration = info.duration,
		bookId = info.id,
		startOffset = info.bookmark or 0
	}
	rebuildPlayer()
	return true
end

local function doSwitch()
	if not M.playerWidget then return end
	lastOpenedBook = nil
	if not pendingBook then return end
	
	switchDelayStart = nil
	
	if currentBookId ~= "" then
		saveBookmark(currentBookId, getCurrentTime())
	end
	bookPlayTime = 0
	bookPlayLastTick = nil
	ambient.stopSoundFile(currentAudioFile)
	
	local newName = pendingBook.name
	local newId = pendingBook.bookId
	local newFile = pendingBook.audioFile
	local newDuration = pendingBook.duration or 0
	local newOffset = pendingBook.startOffset or 0
	
	pendingBook = nil
	currentBookName = newName
	currentBookId = newId
	currentAudioFile = newFile
	totalDuration = newDuration
	currentOffset = newOffset
	pausedTime = newOffset
	
	rebuildPlayer()
	playAudio()
end

destroyPlayer = function()
	if playerUpdateJob then
		G_onFrameJobs["playerUpdateJob"] = nil
	end
	if currentAudioFile ~= "" then
		ambient.stopSoundFile(currentAudioFile)
	end
	if M.playerWidget then
		M.playerWidget:destroy()
		M.playerWidget = nil
	end
	switchBtn = nil
	playPauseBtn = nil
	progressBar = nil
	titleText = nil
	isPlaying = false
	currentBookName = ""
	currentBookId = ""
	currentAudioFile = ""
	startTime = 0
	pausedTime = 0
	currentOffset = 0
	totalDuration = 0
	pendingBook = nil
	bookPlayTime = 0
	bookPlayLastTick = nil
end

rebuildPlayer = function()
	-- UI constants
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
	
	-- Load position from settings or use default
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
	
	-- Border template
	local background = getTexture( 'black' )
	local borderTemplate = makeBorder("thin", THEME_COLOR, 1, {
		type = ui.TYPE.Image,
		props = {
			resource = background,
			relativeSize = v2(1, 1),
			alpha = BACKGROUND_ALPHA,
		}
	}).borders
	
	-- Button row content
	local buttonContent = ui.content{}
	
	
	-- Reset button
	local resetBtn = makeButton("", {
		size = v2(BUTTON_SIZE, BUTTON_SIZE),
	}, function()
		stop()
		--M.playerWidget:update()
	end, THEME_COLOR, nil, getTexture( 'textures/audiobooks2/previous.png' ), nil, nil, THEME_COLOR)
	buttonContent:add(resetBtn.box)
	
	buttonContent:add({ type = ui.TYPE.Widget, props = { size = v2(SPACER, BUTTON_SIZE) } }, nil, nil, THEME_COLOR)
	
	
	
	-- Play/Pause button
	playPauseBtn = makeButton("", {
		size = v2(BUTTON_SIZE, BUTTON_SIZE),
	}, function()
		if isPlaying then
			pauseAudio()
		else
			playAudio()
		end
		M.playerWidget:update()
	end, THEME_COLOR, nil, getTexture( isPlaying and 'textures/audiobooks2/pause.png' or 'textures/audiobooks2/play.png' ), nil, nil, THEME_COLOR)
	buttonContent:add(playPauseBtn.box)
	
	buttonContent:add({ type = ui.TYPE.Widget, props = { size = v2(SPACER, BUTTON_SIZE) } })
	
	
	
	-- Switch button (greyed out if no pending book)
	local switchColor = pendingBook and THEME_COLOR or util.color.rgb(0.1, 0.1, 0.1)
	switchBtn = makeButton("", {
		size = v2(BUTTON_SIZE, BUTTON_SIZE),
	}, function(button)
		if button == 1 then
			if pendingBook then
				doSwitch()
			end
		end
		if pendingBook and button == 3 then
			pendingBook = nil
			rebuildPlayer()
		elseif not pendingBook and lastOpenedBook then
			setPendingBook(lastOpenedBook)
			rebuildPlayer()
		end
	end, switchColor, nil, getTexture( 'textures/audiobooks2/next.png' ), nil, nil, THEME_COLOR)
	if not pendingBook then
		switchBtn.box.layout.props.alpha = 0.4
	end
	buttonContent:add(switchBtn.box)
	
	buttonContent:add({ type = ui.TYPE.Widget, props = { size = v2(SPACER, BUTTON_SIZE) } })
	
	-- Close button
	local closeBtn = makeButton("", {
		size = v2(BUTTON_SIZE, BUTTON_SIZE),
	}, function()
		saveBookmark(currentBookId, getCurrentTime())
		destroyPlayer()
	end, util.color.rgb(0.7, 0.3, 0.3), nil, getTexture( 'textures/audiobooks2/x.png' ), nil, nil, THEME_COLOR)
	buttonContent:add(closeBtn.box)
	
	-- Progress bar
	local initialProgress = (totalDuration > 0) and (currentOffset / totalDuration) or 0
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
					resource = getTexture( 'white' ),
					relativeSize = v2(1, 1),
					color = barBackgroundColor,
					alpha = 0.9,
				}
			},
			{
				name = "progressFill",
				type = ui.TYPE.Image,
				props = {
					resource = getTexture( 'white' ),
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
					if totalDuration > 0 then
						seekTo(progress * totalDuration)
					end
				end
			end),
			mouseRelease = async:callback(function(data, elem)
				elem.userData.isDragging = false
			end),
			mouseMove = async:callback(function(data, elem)
				if elem.userData.isDragging then
					local progress = math.max(0, math.min(1, data.offset.x / BAR_WIDTH))
					if totalDuration > 0 then
						seekTo(progress * totalDuration)
					end
				end
			end),
		}
	}
	
	-- Drag/focus event handlers
	local dragEvents = {
		mousePress = async:callback(function(data, elem)
			if data.button == 1 then
				elem.userData.isDragging = true
				elem.userData.dragStart = data.position
				elem.userData.posStart = M.playerWidget.layout.props.position
			elseif data.button == 3 then
				togglePlayPause()
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
	
	-- Player container content (buttons + progress bar + optional inside title)
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
	
	-- Add inside title if needed
	if SHOW_TITLE == "Inside Player" then
		titleText = {
			name = 'text',
			type = ui.TYPE.Text,
			props = {
				text = tostring(currentBookName),
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
	
	-- Main layout
	if SHOW_TITLE ~= "Inside Player" then
		titleText =	{
			name = 'text',
			type = ui.TYPE.Text,
			props = {
				text = tostring(currentBookName),
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
	
		-- Outer flex with title above, then bordered container
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
		-- Bordered container only (Inside Player or Hidden)
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
	
	-- Update timer
	playerUpdateJob = true
	G_onFrameJobs["playerUpdateJob"] = function(dt)
		if not M.playerWidget then return end
		local currentTime = getCurrentTime()
		if totalDuration > 0 then
			local progress = math.min(1, currentTime / totalDuration)
			local progressFill = progressBar.content[2]
			if progressFill then
				progressFill.props.size = v2(BAR_WIDTH * progress, PROGRESS_HEIGHT)
			end
			local now = core.getRealTime()
			if currentTime > totalDuration then
				if pendingBook and AUTO_PLAY_NEXT then
					if not switchDelayStart then
						pauseAudio()
						switchDelayStart = now
					elseif now - switchDelayStart > 1.5 then
						switchDelayStart = nil
						doSwitch()
					end
				else
					pauseAudio()
				end
			else
				M.playerWidget:update()
			end
			if bookPlayLastTick then
				bookPlayTime = bookPlayTime + now - bookPlayLastTick
				bookPlayLastTick = now
				if bookPlayTime > 1 then
					bookPlayTime = bookPlayTime -1
					self:sendEvent("Audiobooks2_listenedOneSecond", {currentBookId, currentTime, totalDuration})
				end
			end
		end
	end
end

local function createPlayer(book)
	local info = getBookInfo(book)
	if not info then return false end
	
	if M.playerWidget then
		destroyPlayer()
	end
	
	currentBookName = info.name
	currentBookId = info.id
	currentAudioFile = info.audioFile
	totalDuration = info.duration
	currentOffset = info.bookmark or 0
	pausedTime = currentOffset
	pendingBook = nil
	currentVolume = (generalSettingsSection:get("PLAYER_VOLUME") or 100)/100
	sessionPlayTime = 0
	sessionPlayStart = nil
	
	rebuildPlayer()
	if generalSettingsSection:get("AUTOPLAY") ~= false then
		playAudio()
	end
	return true
end

local function openBook(book)
	local info = getBookInfo(book)
	if not info then return false end
	
	if M.playerWidget then
		if currentBookId == info.id then
			return false
		else
			lastOpenedBook = book
			if QUEUE_BOOKS then
				return setPendingBook(book)
			end
		end
	else
		return createPlayer(book)
	end
end

local function getSessionPlayTime()
	if isPlaying and sessionPlayStart then
		return sessionPlayTime + (core.getRealTime() - sessionPlayStart)
	end
	return sessionPlayTime
end

local function tryAutoClose()
	if not M.playerWidget then return end
	local threshold = AUTO_CLOSE_THRESHOLD or 0
	if getSessionPlayTime() < threshold then
		destroyPlayer()
	end
	lastOpenedBook = nil
end

local function onSave()
	if M.playerWidget then
		saveBookmark(currentBookId, getCurrentTime())
	end
end

local function onMouseWheel(dir)
	if not M.playerWidget or not M.playerWidget.layout.userData.isFocussed then return end
	local delta = dir > 0 and 0.1 or -0.1
	setVolume(currentVolume + delta)
	ui.showMessage(string.format("Volume: %d%%", math.floor(currentVolume * 100)))
end

local function updatePosition()
	if not M.playerWidget then return end
	local x = uiSettingsSection:get("HUD_X_POS") or 0
	local y = uiSettingsSection:get("HUD_Y_POS") or 0
	M.playerWidget.layout.props.position = clampPosition(v2(x, y))
	M.playerWidget:update()
end

local function playNext()
	if not pendingBook and lastOpenedBook then
		setPendingBook(lastOpenedBook)
		rebuildPlayer()
	else
		doSwitch()
	end
end
M.openBook = openBook
M.tryAutoClose = tryAutoClose
M.onSave = onSave
M.rebuildPlayer = rebuildPlayer
M.updatePosition = updatePosition
M.onMouseWheel = onMouseWheel
M.togglePlayPause = togglePlayPause
M.stop = stop
M.playNext = playNext
return M