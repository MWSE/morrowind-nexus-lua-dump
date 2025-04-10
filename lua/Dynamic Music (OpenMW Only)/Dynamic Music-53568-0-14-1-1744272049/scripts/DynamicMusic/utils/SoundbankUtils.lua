local vfs = require('openmw.vfs')

local Log = require('scripts.DynamicMusic.core.Logger')
local Soundbank = require('scripts.DynamicMusic.models.Soundbank')
local StringUtils = require('scripts.DynamicMusic.utils.StringUtils')


--- @class SoundbankUtils
local SoundbankUtils = {}

--Collects the soundbanks from the soundbanks folder.
---@param soundbankDirectory string Path to a directory with soundbank files
---@return table<Soundbank> soundbanks The collected soundbanks.
function SoundbankUtils.collectSoundbanks(soundbankDirectory)
    Log.info("collecting soundbanks from: " .. soundbankDirectory)

    local soundbanks = {}
    for file in vfs.pathsWithPrefix(soundbankDirectory) do
        if not string.match(file, "%.lua$") then
            Log.info("skipping non lua file " ..file)
            goto continue
        end

        file = string.gsub(file, ".lua", "")
        local soundbank = SoundbankUtils.loadSoundbank(file)

        if soundbank:countAvailableTracks() > 0 then
            table.insert(soundbanks, soundbank)
            Log.info("soundbank loaded: " .. file)
        else
            Log.info('no tracks available: ' .. file)
        end

        ::continue::
    end

    return soundbanks
end

--- Loads a soundbank
--- @param file (string) Path to a file containing a soundbank definition.
--- @return Soundbank soundbank  
function SoundbankUtils.loadSoundbank(file)
    local soundbank = require(file)

    if soundbank.id ~= "DEFAULT" then
        local lastCharIndex = StringUtils.findLastIndex(file, "/")

        if not lastCharIndex then
            error("unable to locate last slash in filepath " ..file,2)
        end

        local fileName = string.sub(file, lastCharIndex +1, string.len(file))
        soundbank.id = fileName
    end

    soundbank = Soundbank.Decoder.fromTable(soundbank)
    return soundbank
end

return SoundbankUtils