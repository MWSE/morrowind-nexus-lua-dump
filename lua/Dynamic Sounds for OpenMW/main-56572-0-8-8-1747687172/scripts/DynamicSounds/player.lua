local ambient = require('openmw.ambient')
--local Utils = require('scripts.DynamicSounds.Utils')

local function stopAmbientLoopSound(soundPath)

	if soundPath == nil then return end

	--print("stopAmbientLoopSound: " .. soundPath)
	ambient.stopSoundFile(soundPath)

end

local function playAmbientLoopSound(sound)

	--print("playAmbientLoopSound: " .. sound.path .. " at volume " .. sound.volume)

	if ambient.isSoundPlaying(sound.path) then
		return
	end

	local params = {
		volume=sound.volume,
		loop=true
	 }

	 ambient.playSoundFile(sound.path, params)
end




return {
    eventHandlers  = {
		stopAmbientLoopSound = stopAmbientLoopSound,
		playAmbientLoopSound = playAmbientLoopSound
    }
}