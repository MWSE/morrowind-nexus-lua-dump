local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("SoundType")

---@class CraftingFramework.SoundType.params
---@field id string The id of the sound type
---@field soundPaths string[] list of sound paths, relative to `Data Files\\Sound`


---@class CraftingFramework.RegisteredSoundType
---@field id string The id of the sound type
---@field soundPaths table<string, boolean> A dictionary of registered sound paths

---@class CraftingFramework.SoundType
local SoundType = {
    ---@type table<string, CraftingFramework.RegisteredSoundType>
    registeredSoundTypes = {}
}

---@param e CraftingFramework.SoundType.params
function SoundType.register(e)
    logger:assert(type(e.id) == "string", "id must be a string")
    logger:assert(type(e.soundPaths) == "table", "soundPaths must be a table")
    for _, soundPath in ipairs(e.soundPaths) do
        logger:assert(type(soundPath) == "string", "soundPaths must be a table of strings")
        --check ends in .wav
        logger:assert(string.sub(soundPath, -4) == ".wav", "soundPaths be wav files")
    end
    if not SoundType.registeredSoundTypes[e.id] then
        SoundType.registeredSoundTypes[e.id] = {
            id = e.id,
            soundPaths = {}
        }
    else
        logger:warn("SoundType %s already registered, merging soundPaths", e.id)
    end
    for _, soundPath in ipairs(e.soundPaths) do
        SoundType.registeredSoundTypes[e.id].soundPaths[soundPath] = true
    end
    logger:debug("Registered SoundType %s with %d sounds", e.id, #e.soundPaths)
end


---Play a random sound of the given sound type
function SoundType.play(id)
    local soundType = SoundType.registeredSoundTypes[id]
    if soundType then
        local soundPath = table.choice(table.keys(soundType.soundPaths))
        tes3.playSound{soundPath = soundPath}
    else
        logger:warn("SoundType %s not found", id)
    end
end

return SoundType