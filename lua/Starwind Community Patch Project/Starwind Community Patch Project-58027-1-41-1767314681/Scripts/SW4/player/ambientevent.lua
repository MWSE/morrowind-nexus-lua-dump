local Ambient = require('openmw.ambient')

--- Searches for either a sound file or record, throwing if it doesn't exist,
--- and playing is using provided options if it does
---@param ambientData AmbientData
return function(ambientData)
    local soundFile = ambientData.soundFile
    local soundRecord = ambientData.soundRecord
    if soundFile then
        if Ambient.isSoundFilePlaying(soundFile) then
            Ambient.stopSoundFile(soundFile)
        end
        Ambient.playSoundFile(soundFile, ambientData.options)
    elseif soundRecord then
        if Ambient.isSoundPlaying(soundRecord) then
            Ambient.stopSound(soundRecord)
        end
        Ambient.playSound(soundRecord, ambientData.options)
    elseif not soundRecord and not soundFile then
        error("Invalid sound information provided to SW4_AmbientEvent!")
    end
end
