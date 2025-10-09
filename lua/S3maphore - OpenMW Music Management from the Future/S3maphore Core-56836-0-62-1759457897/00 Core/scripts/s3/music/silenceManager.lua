local async = require 'openmw.async'
local storage = require 'openmw.storage'

local helpers, INTERRUPT

local silenceSettingNames, SilenceGroup = {
    'GlobalSilenceToggle',
    'GlobalSilenceChance',
    'ExploreSilenceMin',
    'ExploreSilenceMax',
    'BattleSilenceMin',
    'BattleSilenceMax',
}, storage.playerSection('SettingsS3MusicSilenceConfig')

---@class SilenceData
---@field GlobalSilenceToggle boolean whether or not silence "tracks" are used
---@field GlobalSilenceChance number player-configured chance for a silence track to play between each track
---@field ExploreSilenceMin integer minimum duration of silence tracks for explore playlists
---@field ExploreSilenceMax integer maximum duration of silence tracks for explore playlists
---@field BattleSilenceMin integer minimum duration of silence tracks for battle playlists
---@field BattleSilenceMax integer maximum duration of silence tracks for battle playlists
---@field time number current remaining duration for silence
local silenceData = {
    time = 0
}

local function updateSilenceSettings()
    for _, settingName in ipairs(silenceSettingNames) do
        silenceData[settingName] = SilenceGroup:get(settingName)
    end
end

updateSilenceSettings()

SilenceGroup:subscribe(
    async:callback(
        updateSilenceSettings
    )
)

--- Given the currently-running playlist and settings,
--- determine whether there should be a silence played
--- according to, in order:
--- 1. Whether silence between tracks is enabled at all
--- 2. What silence range the playlist defines
--- 3. What silence range/chance the player's settings define
---@param newPlaylist S3maphorePlaylist
function silenceData.updateSilenceParams(newPlaylist)
    local silenceParams = newPlaylist.silenceBetweenTracks

    if not silenceData.GlobalSilenceToggle then
        silenceData.time = 0
    elseif silenceParams and math.random() <= (silenceParams.chance or 1) then
        if type(silenceParams) == 'table' then
            silenceData.time = math.random(silenceParams.min or 0, silenceParams.max or 30)
        else
            error(
                ('Invalid silence parameters on playlist %s, given silence parameter %s'):format(newPlaylist.id,
                    silenceParams)
            )
        end
    elseif math.random() <= (silenceData.GlobalSilenceChance or 1) then
        local playlistArchetype = newPlaylist.interruptMode

        if playlistArchetype == INTERRUPT.Me then
            silenceData.time = math.random(
                silenceData.ExploreSilenceMin,
                silenceData.ExploreSilenceMax
            )
        elseif playlistArchetype == INTERRUPT.Other then
            silenceData.time = math.random(
                silenceData.BattleSilenceMin,
                silenceData.BattleSilenceMax
            )
        else
            -- Special playlists must always define their own silence parameters
            silenceData.time = 0
        end

        helpers.debugLog('archetypal silence time is...', silenceData.time)
    else
        silenceData.time = 0
    end
end

---@param interrupt InterruptMode
---@param staticStrings S3maphoreStaticStrings
---@param playlistHelpers table<string, function>
return function(interrupt, staticStrings, playlistHelpers)
    assert(interrupt, staticStrings.InterruptModeNotProvided)
    assert(playlistHelpers)

    INTERRUPT = interrupt
    helpers = playlistHelpers

    return silenceData
end
