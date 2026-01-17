---@class SoundOptions
---@field timeOffset number|nil Time offset in seconds to start playing from (Default: 0)
---@field volume number|nil Volume of the sound (Default: 1.0)
---@field pitch number|nil Pitch of the sound (Default: 1.0)
---@field loop boolean|nil Whether to loop the sound (Default: false)

---@class AmbientData
---@field soundFile string|nil VFS path to a sound file to play
---@field soundRecord string|nil string ID of a sound record to play
---@field options SoundOptions|nil Options for the sound to play