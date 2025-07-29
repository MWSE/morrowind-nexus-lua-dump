local world = require("openmw.world")
local core = require('openmw.core')
local types = require('openmw.types')
local Utils = require('scripts.DynamicSounds.Utils')
local SettingsManager = require('scripts.DynamicSounds.SettingsManager')

local _framesSkip = 60 -- only do stuff every 60 frames
local _currentFrameCount = 0

local _loadedCell = nil
local _currentObjectSounds = {} -- {cellObject, soundListToPlay}
local _currentAmbientSounds = {}

local _player = world.players[1]

--- Stops all invalid ambient sounds for the new cell. Do not stop prev sounds the new cell still requires
---@param newCellAmbientSounds any new cell ambient sounds
local function stopPrevCellSounds(newCellAmbientSounds)
	-- ambient cell loop sounds
	
	for _, sound in ipairs(_currentAmbientSounds) do
		if not Utils.soundListContains(newCellAmbientSounds, sound) then
			--Utils.WriteLog("Stopping ambient sound " .. Utils.dump(sound) .. " on player")
			_player:sendEvent('stopAmbientLoopSound', sound.soundPath)
			sound.loaded = false
		else
			--Utils.WriteLog("Ambient sound " .. Utils.dump(sound) .. " will not be unloaded")
			Utils.getSound(newCellAmbientSounds, sound).loaded = true
		end
	end

	-- loop sounds assigned to objects
	for _, objectInfo in ipairs(_currentObjectSounds) do
		for _, soundInfo in ipairs(objectInfo[2]) do
			-- if core.sound.isSoundFilePlaying(soundInfo.soundPath, objectInfo[1]) then
			--Utils.WriteLog("Stopping object sound " .. soundInfo.soundPath .. " on " .. objectInfo[1].recordId )
			core.sound.stopSound3d(soundInfo.soundPath, objectInfo[1]);
			--end
		end
	end

end

local function configArea()
	local currentCell = _player.cell
	local newCellAmbientSounds = {}
	local newCellObjectSounds = {}

	-- player did not changed cell. Do nothing
	if _loadedCell == currentCell then
		return
	end

	Utils.WriteLog("Loading cell or region " .. Utils.getCellNameOrRegion(currentCell), true)

	_loadedCell = currentCell

	local areaSettings = Utils.getConfigSectionForCell(_player.cell)

	if areaSettings == nil then
		return
	end

	if Utils.debugMode() then
		Utils.WriteLog("Area config settings: " .. Utils.dump(areaSettings))
	end

	newCellAmbientSounds = Utils.getAmbientLoopSounds(areaSettings)

	--Utils.WriteLog("newCellAmbientSounds:" .. Utils.dump(newCellAmbientSounds) )

	-- for each object on the config, gets the matching cell objects and set their sounds
	for _, cellObjectSettings in ipairs(areaSettings.objects) do
		local cellObjects = Utils.getCellObjectsByObjectSettings(_player.cell, cellObjectSettings)

		for index, cellObject in ipairs(cellObjects) do
			table.insert(newCellObjectSounds, { cellObject, Utils.getSoundsForCell(cellObjectSettings) })
		end
	end

	stopPrevCellSounds(newCellAmbientSounds)

	_currentAmbientSounds = newCellAmbientSounds
	_currentObjectSounds = newCellObjectSounds

	--Utils.WriteLog("_currentAmbientSounds:" .. Utils.dump(_currentAmbientSounds))

	Utils.WriteLog("Cell loaded with " .. tostring(#_currentObjectSounds) .. " objects and " ..
		tostring(#_currentAmbientSounds) .. " ambient sounds", true)
end


-- objectInfo[1] is the cell object; objectInfo[2] has the list of sounds to play
local function playObjectSounds()
	-- non ambient sounds have a chance of playing, except loop sounds that play immediately
	
	--Utils.WriteLog("_currentObjectSounds: " .. Utils.dump(_currentObjectSounds))
	
	for _, objectInfo in ipairs(_currentObjectSounds) do
		local soundToPlay = Utils.pickRandomValidObjectSoundFromConfig(objectInfo)

		--Utils.WriteLog("soundToPlay:" .. Utils.dump(soundToPlay))

		if soundToPlay == nil then goto continue end

		--if it's a door and have invalid withDestCell section, skip it
		if Utils.ObjectIsDoor(objectInfo[1])
			and not Utils.doorShouldPlaySound(objectInfo[1], soundToPlay) then
			goto continue
		else
			--Utils.WriteLog(objectInfo[1].recordId .. " will play " .. soundToPlay.soundPath)
		end


		-- if the soundToPlay can only be played once on the cell
		if (soundToPlay.onePerCell ~= nil and soundToPlay.onePerCell == true and
				Utils.SoundAlreadyPlayingOnCell(_currentObjectSounds, soundToPlay.soundPath)) then
			return
		end

		local params = {
			volume = (soundToPlay.volume ~= nil and soundToPlay.volume or 1),
			loop = (soundToPlay.loop ~= nil and soundToPlay.loop or false),
		}

		-- is a loop sound. Play immediately if not already loaded
		if soundToPlay.loop == true and not Utils.objectIsPlayingSound(objectInfo[1], soundToPlay.soundPath) then
			Utils.WriteLog("Playing loop object sound " .. soundToPlay.soundPath .. " on " .. objectInfo[1].recordId)
			core.sound.playSoundFile3d(soundToPlay.soundPath, objectInfo[1], params)
		end

		-- not a loop sound. Random chance of playing
		if soundToPlay.loop == false then
			if Utils.shouldPlaySound(soundToPlay, objectInfo[1].recordId, _currentObjectSounds) then
					Utils.WriteLog("Playing non loop object sound " ..
					soundToPlay.soundPath .. " on " .. objectInfo[1].recordId)
					core.sound.playSoundFile3d(soundToPlay.soundPath, objectInfo[1], params)
			end
		end

		-- finally stops any invalid active loop sounds
		for _, sound in ipairs(objectInfo[2]) do
			if sound.loop and Utils.objectIsPlayingSound(objectInfo[1], sound.soundPath) 
			   and Utils.isInvalidSound(sound)  then
					core.sound.stopSound3d(sound.soundPath, objectInfo[1]);
			end
		end

		::continue::
	end
end


local function playAmbientLoopSounds()

	--Utils.WriteLog("** _currentAmbientSounds: " .. Utils.dump(_currentAmbientSounds))

	for _, sound in ipairs(_currentAmbientSounds) do
		if sound.loop == nil or sound.loop == false then goto continue end

		-- enable loop sounds if not loaded
		if (not sound.loaded and not Utils.isInvalidSound(sound)) then
			local eventArgs = {
				path = sound.soundPath,
				volume = (sound.volume ~= nil and sound.volume or 1)
			}

			if Utils.debugMode() then
				Utils.WriteLog("sending event playAmbientLoopSound with args: " .. Utils.dump(eventArgs))
			end
			_player:sendEvent('playAmbientLoopSound', eventArgs)
			sound.loaded = true
		end

		-- stops any invalid active loop sounds
		if sound.loaded and Utils.isInvalidSound(sound) then
			if sound.loop and sound.loaded and Utils.isInvalidSound(sound) then
				if Utils.debugMode() then
					Utils.WriteLog("Stopping ambient sound " .. Utils.dump(sound) .. " on player")
				end
				_player:sendEvent('stopAmbientLoopSound', sound.soundPath)
				sound.loaded = false
			end
		end

		::continue::
	end

	--Utils.WriteLog("** _currentAmbientSounds_end: " .. Utils.dump(_currentAmbientSounds))

end

local function playAmbientNonLoopSounds()
	local selectedSound = Utils.pickRandomValidAmbientSoundFromConfig(_currentAmbientSounds)

	if selectedSound ~= nil then
		local params = {
			volume = (selectedSound.volume ~= nil and selectedSound.volume or 1),
			loop = (selectedSound.loop ~= nil and selectedSound.loop or false),
		}

		if Utils.shouldPlayNonLoopAmbientSound(selectedSound) and
			not core.sound.isSoundFilePlaying(selectedSound.soundPath, _player) then
			Utils.WriteLog("Playing non loop ambient sound " .. selectedSound.soundPath .. " on player")
			core.sound.playSoundFile3d(selectedSound.soundPath, _player, params)
		end
	end
end


-- plays the sounds assigned to objects
local function playAllSounds()
	if _currentFrameCount == 0 then
		playAmbientLoopSounds()
		playAmbientNonLoopSounds()
		playObjectSounds()
		_currentFrameCount = _framesSkip
	else
		_currentFrameCount = _currentFrameCount - 1
	end
end


local function sendPlayerPosToCreatures()
	if _currentFrameCount == 0 and SettingsManager.currentSettings().enableCreatureComponent then
		
		for _, actor in ipairs(world.activeActors)
		do
			if actor ~= nil and actor.type == types.Creature
			then
				actor:sendEvent('sendPlayerPositionToCreature', _player.position)
			end
		end
	end
end


-- sends to every creature if their script should be enabled or disabled 
local function sendCreatureComponentSettings()
		
		for _, actor in ipairs(world.activeActors)
		do
			if actor ~= nil and actor.type == types.Creature
			then
				actor:sendEvent('creatureComponentSettingsChanged', { 
					enableCreatureComponent = SettingsManager.currentSettings().enableCreatureComponent,
					creatureDistanceToPlayer = SettingsManager.currentSettings().creatureDistanceToPlayer,
				})
			end
		end
end

-- runs each frame
local function onUpdate()
	if SettingsManager.currentSettings().enableMod then
		configArea()
		playAllSounds()
		sendPlayerPosToCreatures()
	end
end


local function onPlayerAdded(data)
	if SettingsManager.currentSettings().enableMod then
		Utils.loadSoundBanks()
	end
end

-- This runs every time an item is activated (ex: dropped from the inv to the game area).
-- Needed, otherwise dropped items didn't load their sounds 
local function onItemActivated(cellObject)
	local areaSettings = Utils.getConfigSectionForCell(_player.cell)

	for _, cellObjectSettings in ipairs(areaSettings.objects) do
		if Utils.StringContains(cellObject.recordId, cellObjectSettings[1]) then
			table.insert(_currentObjectSounds, { cellObject, Utils.getSoundsForCell(cellObjectSettings) })
		end			
	end
end

local function setUserSettings(data)
	SettingsManager.setSettings(data)
	Utils.setSettings(data)
	sendCreatureComponentSettings()
end



return {
	engineHandlers = {
		onPlayerAdded = onPlayerAdded(data),
		onUpdate = onUpdate,
	},
    eventHandlers  = {
		setUserSettings = setUserSettings,
		onItemActivated = onItemActivated,
    }	

}
