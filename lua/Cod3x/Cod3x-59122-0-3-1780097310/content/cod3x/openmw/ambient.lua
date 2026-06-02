---@meta

-- This file was mechanically drafted from files/lua_api/openmw/ambient.lua.
-- It uses LuaLS/LLS annotations and stub bodies only; runtime behavior is provided by OpenMW.
-- OpenMW script contexts: menu|player

---Controls background 2D sounds specific to a given player.
---@class openmw.ambient
local ambient = {}

---@class openmw.ambient.Sound
local Sound = {}


---Play a 2D sound
---};
---ambient.playSound("shock bolt", params)
---@param soundId string ID of Sound record to play
---@param options? table An optional table with additional optional arguments. Can contain: * `timeOffset` - a floating point number >= 0, to skip some time (in seconds) from the beginning of the sound (default: 0); * `volume` - a floating point number >= 0, to set the sound's volume (default: 1); * `pitch` - a floating point number >= 0, to set the sound's pitch (default: 1); * `scale` - a boolean, to set if the sound's pitch should be scaled by simulation time scaling (default: true); * `loop` - a boolean, to set if the sound should be repeated when it ends (default: false);
function ambient.playSound(soundId, options) end

---Play a 2D sound file
---};
---ambient.playSoundFile("Sound\\test.mp3", params)
---@param fileName string Path to a sound file in VFS
---@param options? table An optional table with additional optional arguments. Can contain: * `timeOffset` - a floating point number >= 0, to skip some time (in seconds) from the beginning of the sound file (default: 0); * `volume` - a floating point number >= 0, to set the sound's volume (default: 1); * `pitch` - a floating point number >= 0, to set the sound's pitch (default: 1); * `scale` - a boolean, to set if the sound's pitch should be scaled by simulation time scaling (default: true); * `loop` - a boolean, to set if the sound should be repeated when it ends (default: false);
function ambient.playSoundFile(fileName, options) end

---Stop a sound
---@param soundId string ID of Sound record to stop
function ambient.stopSound(soundId) end

---Stop a sound file
---@param fileName string Path to a sound file in VFS
function ambient.stopSoundFile(fileName) end

---Check if a sound is playing
---@param soundId string ID of Sound record to check
---@return boolean
function ambient.isSoundPlaying(soundId) end

---Check if a sound file is playing
---@param fileName string Path to a sound file in VFS
---@return boolean
function ambient.isSoundFilePlaying(fileName) end

---Play a sound file as a music track
---};
---ambient.streamMusic("Music\\Test\\Test.mp3", params)
---@param fileName string Path to a file in VFS
---@param options? table An optional table with additional optional arguments. Can contain: * `fadeOut` - a floating point number >= 0, time (in seconds) to fade out the current track before playing this one (default 1.0);
function ambient.streamMusic(fileName, options) end

---Stop the currently playing music
function ambient.stopMusic() end

---Check if music is playing
---@return boolean
function ambient.isMusicPlaying() end

---Play an ambient voiceover.
---ambient.say("Sound\\Vo\\Misc\\voice.mp3", "Subtitle text")
---ambient.say("Sound\\Vo\\Misc\\voice.mp3")
---@param fileName string Path to a sound file in VFS
---@param text? string Subtitle text (optional)
function ambient.say(fileName, text) end

---Stop an ambient voiceover
---@param fileName string Path to a sound file in VFS
function ambient.stopSay(fileName) end

---Check if an ambient voiceover is playing
---@return boolean
function Sound.isSayActive() end

return ambient
