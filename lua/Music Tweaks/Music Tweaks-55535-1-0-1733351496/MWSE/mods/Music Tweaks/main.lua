local peacefulInteriors = require('Music Tweaks.peaceful-interiors')

---- Mod Config Menu Setup

local defaultConfig = {
	enablePauseBetweenExploreTracks = true,
	minPause = 60,
	maxPause = 120,
	enableNoExploreMusicInDungeons = true,
	enableNoCombatMusicForLowLevelEnemies = true,
}
local configPath = 'Music Tweaks'
local config = mwse.loadConfig(configPath, defaultConfig)

local function validateMinPauseAndMaxPause()
	if config.maxPause < config.minPause then
		config.maxPause = config.minPause
	end
end

local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = 'Music Tweaks', config = config, defaultConfig = defaultConfig })
	template:register()
	template:saveOnClose(configPath, config)

	local page = template:createPage()

	page:createCategory('Pause between explore tracks')

	page:createYesNoButton({ label = 'Enable pause between explore tracks', configKey = 'enablePauseBetweenExploreTracks' })

	page:createSlider({
		label = 'Mimimal pause between tracks in seconds. Cannot be larger than maximal',
		configKey = 'minPause',
		min = '0',
		max = '300',
		callback = validateMinPauseAndMaxPause,
	})

	page:createSlider({
		label = 'Maximal pause between tracks in seconds. Cannot be smaller than minimal',
		configKey = 'maxPause',
		min = '0',
		max = '300',
		callback = validateMinPauseAndMaxPause,
	})

	page:createCategory('No explore music in dungeons')

	page:createYesNoButton({ label = 'Enable no explore music in dungeons', configKey = 'enableNoExploreMusicInDungeons' })

	page:createCategory('No combat music for low level enemies')

	page:createYesNoButton({
		label = 'Enable no combat music for low level enemies',
		configKey = 'enableNoCombatMusicForLowLevelEnemies',
	})
end

---- Tracking music state

-- States

local UNINTERRUPTIBLE = 0
local EXPLORE = 1
local EXPLORE_IN_DUNGEON = 2
local COMBAT = 3
local COMBAT_LOW_LEVEL = 4
local COMBAT_LOW_LEVEL_IN_DUNGEON = 5

local musicState = UNINTERRUPTIBLE

-- Transitions

local NO_CHANGE = 0
local BLOCK = 1
local PLAY_EXPLORE = 2
local PLAY_SILENCE = 3
local PLAY_EXPLORE_WITH_PAUSE = 4
local IMPOSSIBLE = 666

local TRANSITIONS = {
	[UNINTERRUPTIBLE] = {
		[UNINTERRUPTIBLE] = NO_CHANGE,
		[EXPLORE] = NO_CHANGE,
		[EXPLORE_IN_DUNGEON] = PLAY_SILENCE,
		[COMBAT] = NO_CHANGE,
		[COMBAT_LOW_LEVEL] = PLAY_EXPLORE,
		[COMBAT_LOW_LEVEL_IN_DUNGEON] = PLAY_SILENCE,
	},
	[EXPLORE] = {
		[UNINTERRUPTIBLE] = NO_CHANGE,
		[EXPLORE] = PLAY_EXPLORE_WITH_PAUSE,
		[EXPLORE_IN_DUNGEON] = PLAY_SILENCE,
		[COMBAT] = NO_CHANGE,
		[COMBAT_LOW_LEVEL] = BLOCK,
		[COMBAT_LOW_LEVEL_IN_DUNGEON] = PLAY_SILENCE,
	},
	[EXPLORE_IN_DUNGEON] = {
		[UNINTERRUPTIBLE] = NO_CHANGE,
		[EXPLORE] = PLAY_EXPLORE,
		[EXPLORE_IN_DUNGEON] = PLAY_SILENCE,
		[COMBAT] = NO_CHANGE,
		[COMBAT_LOW_LEVEL] = IMPOSSIBLE,
		[COMBAT_LOW_LEVEL_IN_DUNGEON] = PLAY_SILENCE,
	},
	[COMBAT] = {
		[UNINTERRUPTIBLE] = NO_CHANGE,
		[EXPLORE] = NO_CHANGE,
		[EXPLORE_IN_DUNGEON] = PLAY_SILENCE,
		[COMBAT] = NO_CHANGE,
		[COMBAT_LOW_LEVEL] = IMPOSSIBLE,
		[COMBAT_LOW_LEVEL_IN_DUNGEON] = IMPOSSIBLE,
	},
	[COMBAT_LOW_LEVEL] = {
		[UNINTERRUPTIBLE] = NO_CHANGE,
		[EXPLORE] = BLOCK,
		[EXPLORE_IN_DUNGEON] = PLAY_SILENCE,
		[COMBAT] = NO_CHANGE,
		[COMBAT_LOW_LEVEL] = PLAY_EXPLORE_WITH_PAUSE,
		[COMBAT_LOW_LEVEL_IN_DUNGEON] = PLAY_SILENCE,
	},
	[COMBAT_LOW_LEVEL_IN_DUNGEON] = {
		[UNINTERRUPTIBLE] = NO_CHANGE,
		[EXPLORE] = PLAY_EXPLORE,
		[EXPLORE_IN_DUNGEON] = PLAY_SILENCE,
		[COMBAT] = NO_CHANGE,
		[COMBAT_LOW_LEVEL] = PLAY_EXPLORE,
		[COMBAT_LOW_LEVEL_IN_DUNGEON] = PLAY_SILENCE,
	},
}

local pauseTimer = nil
local function cancelPauseTimer()
	if pauseTimer then
		pauseTimer:cancel()
	end
end

local function getCurrentMusicSituation()
	if tes3.mobilePlayer.inCombat then
		return tes3.musicSituation.combat
	end

	return tes3.musicSituation.explore
end

local isInDungeon = false
local isEnemyLowLevel = true

-- `situation` is required argument, `music` is optional
local function updateMusicState(situation, music)
	local newMusicState = nil

	if situation == tes3.musicSituation.uninterruptible then
		newMusicState = UNINTERRUPTIBLE
	elseif situation == tes3.musicSituation.explore then
		if isInDungeon then
			newMusicState = EXPLORE_IN_DUNGEON
		else
			newMusicState = EXPLORE
		end
	else -- elseif situation == tes3.musicSituation.combat then
		if isEnemyLowLevel == false then
			newMusicState = COMBAT
		elseif isInDungeon then
			newMusicState = COMBAT_LOW_LEVEL_IN_DUNGEON
		else
			newMusicState = COMBAT_LOW_LEVEL
		end
	end

	local transition = TRANSITIONS[musicState][newMusicState]
	musicState = newMusicState

	if transition == NO_CHANGE then
		if music then
			tes3.streamMusic({ path = music, situation = situation })
		else
			tes3.skipToNextMusicTrack({ situation = situation })
		end
		cancelPauseTimer()
	elseif transition == BLOCK then
		return
	elseif transition == PLAY_EXPLORE then
		tes3.skipToNextMusicTrack({ situation = tes3.musicSituation.explore })
		cancelPauseTimer()
	elseif transition == PLAY_SILENCE then
		tes3.streamMusic({ path = 'silence.mp3', situation = situation })
		cancelPauseTimer()
	elseif transition == PLAY_EXPLORE_WITH_PAUSE then
		local playMusicFunction = function()
			tes3.skipToNextMusicTrack({ situation = getCurrentMusicSituation() })
		end

		if situation == tes3.musicSituation.explore and music then
			playMusicFunction = function()
				tes3.streamMusic({ path = music, situation = getCurrentMusicSituation() })
			end
		end

		if config.enablePauseBetweenExploreTracks == false then
			playMusicFunction()
			return
		end

		local duration = math.random(config.minPause, config.maxPause)

		if duration == 0 or config.enablePauseBetweenExploreTracks == false then
			playMusicFunction()
			return
		end

		tes3.streamMusic({ path = 'silence.mp3', situation = situation })
		pauseTimer = timer.start({ duration = duration, callback = playMusicFunction, type = timer.real })
	end
end

local function musicChangeTrackCallback(e)
	if e.context == 'lua' then
		return
	end

	-- `sub(18)` to remove "data files/music/"
	updateMusicState(e.situation, e.music:sub(18))
	return false
end

---- Maintaining `isInDungeon` value

local function cellChangedCallback(e)
	if config.enableNoExploreMusicInDungeons == false then
		return
	end

	if e.cell.isOrBehavesAsExterior then
		if isInDungeon then
			isInDungeon = false
			updateMusicState(tes3.musicSituation.explore)
		end

		return
	end

	for _, peacefulInterior in ipairs(peacefulInteriors) do
		if e.cell.editorName:sub(1, #peacefulInterior) == peacefulInterior then
			if isInDungeon then
				isInDungeon = false
				updateMusicState(tes3.musicSituation.explore)
			end

			return
		end
	end

	isInDungeon = true
	updateMusicState(tes3.musicSituation.explore)
end

---- Maintaining `isEnemyLowLevel` value

local function combatStartCallback(e)
	if config.enableNoCombatMusicForLowLevelEnemies == false or e.target.reference ~= tes3.player then
		return
	end

	local enemy = e.actor.reference.object

	if enemy.level * 2 > tes3.player.object.level and (enemy.objectType ~= tes3.objectType.creature or enemy.level > 2) then
		isEnemyLowLevel = false
		if musicState == COMBAT_LOW_LEVEL or musicState == COMBAT_LOW_LEVEL_IN_DUNGEON then
			updateMusicState(tes3.musicSituation.combat)
		end
	elseif tes3.mobilePlayer.inCombat == false then
		isEnemyLowLevel = true
	end
end

---- Maintaining `justLoadedIntoTheGame` value

local function loadCallback()
	-- Not like any music plays during load, this is just resetting the state
	musicState = UNINTERRUPTIBLE
end

---- Initialization

local function initialized()
	event.register(tes3.event.musicChangeTrack, musicChangeTrackCallback)
	event.register(tes3.event.cellChanged, cellChangedCallback)
	event.register(tes3.event.combatStarted, combatStartCallback)
	event.register(tes3.event.load, loadCallback)

	print('[Music Tweaks: INFO] Music Tweaks Initialized')
end

event.register(tes3.event.modConfigReady, registerModConfig)
event.register(tes3.event.initialized, initialized)
