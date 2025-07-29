local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local animation = require('openmw.animation')
local CreatureUtils = require('scripts.DynamicSounds.CreatureUtils')

-- from settings (via global script)
local _settings = { enableCreatureComponent = true, creatureDistanceToPlayer = 3500,  }

-- from global script 
local _playerPosition = nil


local _creatureIsActive = false
--local _previousStance = types.Actor.STANCE.Nothing
local _previousStance = types.Actor.getStance(self)

local _framesSkip = 10 -- only do stuff every 10 frames
local _currentFrameCount = 0



local function removeCreatureSounds()
	
	local soundsToRemove = CreatureUtils.getCreatureSoundbank().removeSounds

	if (soundsToRemove ~= nil and soundsToRemove ~= "") then
		
		for _, soundId in pairs(CreatureUtils.stringSplit(soundsToRemove)) do
			if core.sound.isSoundPlaying(soundId, self) then
				CreatureUtils.stopSound(soundId, self) 
			end 
		end 
	end

end

local function playSoundbankSoundsV2()
	
	local loopSoundsPlaying = {}

	for _, sound in pairs(CreatureUtils.getAllSoundsFromCurrentAnimation(self)) do
		
		-- not replacements
		if CreatureUtils.stringIsNullOrEmpty(sound.replaceOriginalSound) then

			if sound.loopSound 	then
				
				if not core.sound.isSoundFilePlaying(sound.animSound, self)  then
					CreatureUtils.playSound(sound.animSound, self,
				{
					loop = sound.loopSound,
					volume = sound.volume or 1,
					timeOffset = sound.timeOffset or 0,
				})
				end
			

				table.insert(loopSoundsPlaying, sound.animSound)
				--CreatureUtils.WriteLog("loopSoundsPlaying after insert:" .. CreatureUtils.dump(loopSoundsPlaying))						
			end

			if not sound.loopSound then

				--CreatureUtils.WriteLog("anim time:" .. tostring(animation.getCurrentTime(self, CreatureUtils.getCurrentAnimationGroups(self).LowerBody)))

				if animation.getCurrentTime(self, CreatureUtils.getCurrentAnimationGroups(self).LowerBody) < _framesSkip+10
					and animation.getCurrentTime(self, CreatureUtils.getCurrentAnimationGroups(self).LowerBody) >= 0
					and not core.sound.isSoundFilePlaying(sound.animSound, self)
				then

					CreatureUtils.playSound(sound.animSound, self,
					{
						loop = false,
						volume = sound.volume or 1,
						timeOffset = sound.timeOffset or 0,
					})						
				end	
			end

		-- replacemnts	
		else

			--CreatureUtils.WriteLog("loopSoundsPlaying inside replacement:" .. CreatureUtils.dump(loopSoundsPlaying))						
			-- CreatureUtils.WriteLog("sound " .. sound.replaceOriginalSound .. " is playing? " .. 
			-- 	tostring(core.sound.isSoundPlaying(sound.replaceOriginalSound, self)))	
			
			if core.sound.isSoundPlaying(sound.replaceOriginalSound, self) then
				CreatureUtils.replacePlayingSound(sound.replaceOriginalSound, sound.animSound, self, 
				{
					loop = false, -- replacements don't loop
					volume = sound.volume or 1,
					timeOffset = sound.timeOffset or 0,
				})			
			end

		end

	end

	--CreatureUtils.WriteLog("loopsounds playing:" .. CreatureUtils.dump(loopSoundsPlaying))

	-- stop loop sounds not belonging to the active animation group
	-- that may still be playing
	for _, inactiveSound in pairs(CreatureUtils.getAllSoundsFromInactiveAnimations(self)) do
		
		if inactiveSound.loopSound and not CreatureUtils.tableContains(loopSoundsPlaying, inactiveSound.animSound) 
		  and core.sound.isSoundFilePlaying(inactiveSound.animSound, self)	then
			
			--CreatureUtils.WriteLog("stopping loop sound: " .. inactiveSound.animSound)
			CreatureUtils.stopSound(inactiveSound.animSound, self)
		end

	end

end

local function playSoundbankSounds()

	local _activeAnimationLoopSounds = {}

	for _, sound in pairs(CreatureUtils.getCreatureSoundbank().sounds) do
		
		-- sounds applied independently of the animation (as long as not in the anim exception list)
		if (sound.animGroupName == "*" 
			and not CreatureUtils.currentAnimationIsOnTheList(sound.exceptAnimGroups, self))
		then

			-- sounds that are a replacement to the originals
			if sound.replaceOriginalSound ~= nil and sound.replaceOriginalSound ~= "" 
				and core.sound.isSoundPlaying(sound.replaceOriginalSound, self)
			then
				CreatureUtils.replacePlayingSound(sound.replaceOriginalSound, sound.animSound, self, 
				{
					loop = sound.loopSound,
					volume = sound.volume or 1,
					timeOffset = sound.timeOffset or 0,
				})
			-- not a replacement to the originals. Just play
			else if sound.replaceOriginalSound == nil or sound.replaceOriginalSound == "" 
				and not core.sound.isSoundPlaying(sound.animSound, self)
				then
					CreatureUtils.playSound(sound.animSound, self,
						{
							loop = sound.loopSound,
							volume = sound.volume or 1,
							timeOffset = sound.timeOffset or 0,
						})	 
				end				
			end	
				
			if (sound.loopSound) then
				table.insert(_activeAnimationLoopSounds, sound.animSound)
				CreatureUtils.WriteLog("_activeAnimationLoopSounds: " .. CreatureUtils.dump(_activeAnimationLoopSounds))
			end

		-- animation is playing	
		elseif CreatureUtils.isPlayingAnim(self, sound.animGroupName)
		then
			-- if the sound to play is a replacement of an original sound,
			-- stop the original and play the new one
			if sound.replaceOriginalSound ~= nil and sound.replaceOriginalSound ~= "" and
				core.sound.isSoundPlaying(sound.replaceOriginalSound, self) then
				
					CreatureUtils.replacePlayingSound(sound.replaceOriginalSound, sound.animSound, self, 
					{
						loop = sound.loopSound,
						volume = sound.volume or 1,
						timeOffset = sound.timeOffset or 0,
					})
		
			-- if the sound is not a replacement, just play the sound if it is not already playing			
			else
				if not core.sound.isSoundFilePlaying(sound.animSound, self)
				then
					CreatureUtils.playSound(sound.animSound, self,
						{
							loop = sound.loopSound,
							volume = sound.volume or 1,
							timeOffset = sound.timeOffset or 0,
						})	 
				end
			end

			if (sound.loopSound) then
				table.insert(_activeAnimationLoopSounds, sound.animSound)
				CreatureUtils.WriteLog("_activeAnimationLoopSounds: " .. CreatureUtils.dump(_activeAnimationLoopSounds))
			end

		-- inactive animations: disable their sounds if they are loop sounds
		-- and the sound file is not beeing played by the active animation	
		else
			if sound.loopSound and core.sound.isSoundFilePlaying(sound.animSound, self) 
				  and not CreatureUtils.tableContains(_activeAnimationLoopSounds, sound.animSound)
			then
				-- CreatureUtils.WriteLog(sound.animSound .. " is loop sound? " .. tostring(sound.loopSound))
				-- CreatureUtils.WriteLog("active loop sounds:" .. CreatureUtils.dump(_activeAnimationLoopSounds))
				
				 CreatureUtils.WriteLog("inactive animation sound detected - stopping it " .. sound.animSound)
				 CreatureUtils.stopSound(sound.animSound, self)
			end
		end



	end
end

local function playAwareSound()
	if CreatureUtils.getCreatureSoundbank().aware == nil then return end

	local currentStance = types.Actor.getStance(self)

	-- CreatureUtils.WriteLog("prev stance: " .. _previousStance)
	-- CreatureUtils.WriteLog("current stance: " .. currentStance)

	if _previousStance ~= currentStance and 
		(_previousStance ~= types.Actor.STANCE.Spell or _previousStance ~= types.Actor.STANCE.Weapon) and
		(currentStance == types.Actor.STANCE.Spell or currentStance == types.Actor.STANCE.Weapon) then

		if not core.sound.isSoundFilePlaying(CreatureUtils.getCreatureSoundbank().aware.sound, self) then
			CreatureUtils.playSound(CreatureUtils.getCreatureSoundbank().aware.sound, self, {
				loop = false,
				volume = CreatureUtils.getCreatureSoundbank().aware.volume or 1,
				timeOffset = CreatureUtils.getCreatureSoundbank().aware.timeOffset or 0,
			})
		end
	end

	_previousStance = currentStance
end

local function RemoveAllActiveSounds()
	
	--CreatureUtils.WriteLog("removing all active sounds")

	if CreatureUtils.getCreatureSoundbank() == nil 
	 or not CreatureUtils.isCreatureCloseEnoughToPlayerToEnableScript(_playerPosition, self) then return end

	for _, sound in pairs(CreatureUtils.getCreatureSoundbank().sounds) do
		if core.sound.isSoundFilePlaying(sound.animSound, self) then
			CreatureUtils.stopSound(sound.animSound, self)
		end
	end

end

-- runs each frame
local function onUpdate()

	if not _settings.enableCreatureComponent then return end

	if _currentFrameCount == 0 then

	--CreatureUtils.WriteLog(types.Creature.record(self).id)

		if _creatureIsActive and CreatureUtils.getCreatureSoundbank() ~= nil and
			CreatureUtils.getCreatureSoundbank().sounds ~= nil 
			and CreatureUtils.isCreatureCloseEnoughToPlayerToEnableScript(_playerPosition, self, _settings.creatureDistanceToPlayer)  then
		
			-- CreatureUtils.WriteLog("player distance: " .. CreatureUtils.distanceToPlayer(_playerPosition, self) )	

			-- removeCreatureSounds()
			  playSoundbankSoundsV2()
			  playAwareSound()

			-- if CreatureUtils.StringContains(types.Creature.record(self).id, "cliff racer")
			-- then
			-- 	CreatureUtils.WriteLog(CreatureUtils.dump(CreatureUtils.getCurrentAnimationGroups(self).LowerBody))
			-- 	CreatureUtils.WriteLog("player distance: " .. CreatureUtils.distanceToPlayer(_playerPosition, self) )	

			-- 	removeCreatureSounds()
			-- 	playSoundbankSoundsV2()
			-- 	playAwareSound()
			-- end		

		end

		_currentFrameCount = _framesSkip
	else
		_currentFrameCount = _currentFrameCount - 1
	end




end

local function sendPlayerPositionToCreature(pos)
	_playerPosition = pos
end

local function creatureComponentSettingsChanged(settings)
	_settings = settings
end

local function onActive()
	_creatureIsActive = true
	CreatureUtils.loadCreatureSoundbank(types.Creature.record(self).id)
end

local function onInactive()
	_creatureIsActive = false
	--RemoveAllActiveSounds()
end
         

return {
	engineHandlers = {
		onUpdate = onUpdate,
		onActive = onActive,
		onInactive = onInactive
	},
	eventHandlers  = {
		sendPlayerPositionToCreature = sendPlayerPositionToCreature,
		creatureComponentSettingsChanged = creatureComponentSettingsChanged
    }


}
