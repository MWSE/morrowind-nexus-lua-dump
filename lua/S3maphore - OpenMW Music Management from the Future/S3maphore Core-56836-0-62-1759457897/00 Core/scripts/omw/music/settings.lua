local async = require 'openmw.async'
local storage = require 'openmw.storage'
local vfs = require 'openmw.vfs'

local I = require('openmw.interfaces')

local PlaylistFileNames = {}
for fileName in vfs.pathsWithPrefix('playlists/') do
    if fileName:find('%.lua$') then
        table.insert(PlaylistFileNames, fileName)
    end
end

local playlistIds = { 'Explore', 'Battle', }
for _, file in ipairs(PlaylistFileNames) do
    local ok, playlists = pcall(require, file:gsub("%.lua$", ""))
    if ok and type(playlists) == "table" then
        for _, playlist in ipairs(playlists) do
            playlistIds[#playlistIds + 1] = playlist.id
        end
    end
end

local function getMaxLength(arr)
    local max = 0
    for _, str in ipairs(arr) do
        if #str > max then max = #str end
    end
    return max + 8
end

local function padStrings(arr)
    local maxLen = getMaxLength(arr)
    local padded = {}
    for i, str in ipairs(arr) do
        local totalPad = maxLen - #str
        local leftPad = math.floor(totalPad / 2)
        local rightPad = totalPad - leftPad
        padded[i] = string.rep(" ", leftPad) .. str .. string.rep(" ", rightPad)
    end
    return padded
end

local function stripWhitespace(str)
    return str:match("^%s*(.-)%s*$")
end

local playlistIds = padStrings(playlistIds)

I.Settings.registerPage({
    key = 'S3Music',
    l10n = 'S3Music',
    name = 'Music',
    description = 'settingsPageDescription',
})

I.Settings.registerGroup({
    key = "SettingsS3Music",
    page = 'S3Music',
    l10n = 'S3Music',
    name = 'musicSettings',
    permanentStorage = true,
    order = 0,
    settings = {
        {
            key = 'DebugEnable',
            renderer = 'checkbox',
            name = 'DebugEnabled',
            description = 'DebugEnabledDescription',
            default = false,
        },
        {
            key = 'MusicEnabled',
            renderer = 'checkbox',
            name = 'MusicEnabled',
            description = 'MusicEnabledDescription',
            default = true,
        },
        {
            key = 'BattleEnabled',
            renderer = 'checkbox',
            name = 'BattleEnabled',
            description = 'BattleEnabledDescription',
            default = true,
        },
        {
            key = 'BannerEnabled',
            renderer = 'checkbox',
            name = 'BannerEnabled',
            description = 'BannerEnabledDescription',
            default = false,
        },
        {
            key = 'ForceFinishTrack',
            renderer = 'checkbox',
            name = 'NoInterrupt',
            description = 'NoInterruptDescription',
            default = true,
        },
        {
            key = 'ForcePlaylistChangeOnFriendlyExteriorTransition',
            renderer = 'checkbox',
            name = 'ForcePlaylistChangeOnFriendlyExteriorTransition',
            description = 'ForcePlaylistChangeOnFriendlyExteriorTransitionDescription',
            default = false,
        },
        {
            key = 'ForcePlaylistChangeOnHostileExteriorTransition',
            renderer = 'checkbox',
            name = 'ForcePlaylistChangeOnHostileExteriorTransition',
            description = 'ForcePlaylistChangeOnHostileExteriorTransitionDescription',
            default = true,
        },
        {
            key = 'ForcePlaylistChangeOnOverworldTransition',
            renderer = 'checkbox',
            name = 'ForcePlaylistChangeOnOverworldTransition',
            description = 'ForcePlaylistChangeOnOverworldTransitionDescription',
            default = false,
        },
        {
            key = 'FadeOutDuration',
            renderer = 'number',
            name = 'FadeOutDuration',
            description = 'FadeOutDurationDescription',
            argument = { min = 0.0, max = 30.0, integer = false },
            default = 1.0,
        },
    },
})

I.Settings.registerGroup({
    key = 'SettingsS3MusicPlaylistSelection',
    page = 'S3Music',
    l10n = 'S3Music',
    name = 'PlaylistSelection',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'PlaylistActiveCurrentSelection',
            renderer = 'select',
            argument = { items = playlistIds, l10n = 'S3Music', },
            name = 'CurrentPlaylistSelection',
            description = 'CurrentPlaylistSelectionDescription',
            default = playlistIds[1],
        },
        {
            key = 'ResetAllPlaylists',
            renderer = 'checkbox',
            name = 'ResetAllPlaylists',
            argument = { trueLabel = 'ResetButtonLabel', falseLabel = 'ResetButtonLabel', l10n = 'S3Music' },
            description = 'ResetAllPlaylistsDescription',
            default = false,
        },
    }
})

local musicSettings = storage.playerSection('SettingsS3MusicPlaylistSelection')
local activePlaylistSettings = storage.playerSection('SettingsS3MusicPlaylistActivity')
local activePlaylistState = storage.playerSection('S3maphoreActivePlaylistSettings')

musicSettings:subscribe(
    async:callback(
        function(_, key)
            if not key or key == 'ResetAllPlaylists' then
                for _, file in ipairs(PlaylistFileNames) do
                    local ok, playlists = pcall(require, file:gsub("%.lua$", ""))

                    if ok and type(playlists) == "table" then
                        for _, playlist in ipairs(playlists) do
                            activePlaylistState:set(playlist.id .. 'Active', playlist.active or true)
                            activePlaylistSettings:set('PlaylistActiveState', playlist.active or true)
                        end
                    end
                end
                return
            end

            local targetPlaylist = stripWhitespace(
                musicSettings:get('PlaylistActiveCurrentSelection')
            )

            if not targetPlaylist then return end

            local currentState = activePlaylistState:get(targetPlaylist .. 'Active')
            local noTracks = currentState == -1

            activePlaylistSettings:set('PlaylistActiveState', noTracks and false or currentState)

            I.Settings.updateRendererArgument('SettingsS3MusicPlaylistActivity', 'PlaylistActiveState',
                { disabled = noTracks })
        end
    )
)

I.Settings.registerGroup({
    key = 'SettingsS3MusicPlaylistActivity',
    page = 'S3Music',
    l10n = 'S3Music',
    name = 'PlaylistActivity',
    permanentStorage = true,
    order = 2,
    settings = {
        {
            key = 'PlaylistActiveState',
            renderer = 'checkbox',
            argument = {},
            name = 'PlaylistActiveState',
            description = 'PlaylistActiveStateDescription',
            default = true,
        }
    }

})

activePlaylistSettings:subscribe(
    async:callback(
        function(_, key)
            if not key then return end
            local targetPlaylist = stripWhitespace(musicSettings:get('PlaylistActiveCurrentSelection'))
            local state = activePlaylistSettings:get('PlaylistActiveState')
            activePlaylistState:set(targetPlaylist .. 'Active', state)
        end
    )
)

local HUGE = math.huge

I.Settings.registerGroup {
    key = 'SettingsS3MusicSilenceConfig',
    page = 'S3Music',
    l10n = 'S3Music',
    name = 'SilenceConfiguration',
    permanentStorage = true,
    order = 3,
    settings = {
        {
            key = 'GlobalSilenceToggle',
            renderer = 'checkbox',
            argument = {},
            name = 'GlobalSilenceToggle',
            description = 'GlobalSilenceToggleDesc',
            default = true,
        },
        {
            key = 'GlobalSilenceChance',
            renderer = 'number',
            argument = { min = 0.0, max = 1.0, integer = false },
            name = 'GlobalSilenceChanceName',
            description = 'GlobalSilenceChanceDesc',
            default = 0.15,
        },
        {
            key = 'ExploreSilenceMin',
            renderer = 'number',
            argument = { min = 0, max = 119, integer = true, },
            name = 'ExploreSilenceMinDuration',
            description = 'ExploreSilenceMinDesc',
            default = 0,
        },
        {
            key = 'ExploreSilenceMax',
            renderer = 'number',
            argument = { min = 0, max = HUGE, integer = true, },
            name = 'ExploreSilenceMaxDuration',
            description = 'ExploreSilenceMaxDesc',
            default = 120,
        },
        {
            key = 'BattleSilenceMin',
            renderer = 'number',
            argument = { min = 0, max = HUGE, integer = true, },
            name = 'BattleSilenceMinDuration',
            description = 'BattleSilenceMinDesc',
            default = 0,
        },
        {
            key = 'BattleSilenceMax',
            renderer = 'number',
            argument = { min = 0, max = HUGE, integer = true, },
            name = 'BattleSilenceMaxDuration',
            description = 'BattleSilenceMaxDesc',
            default = 120,
        },
    }
}

local SilenceGroup = storage.playerSection('SettingsS3MusicSilenceConfig')
SilenceGroup:subscribe(
    async:callback(
        function(groupName, _)
            local exploreSilenceMin, exploreSilenceMax = SilenceGroup:get('ExploreSilenceMin'),
                SilenceGroup:get('ExploreSilenceMax')

            local battleSilenceMin, battleSilenceMax = SilenceGroup:get('BattleSilenceMin'),
                SilenceGroup:get('BattleSilenceMax')

            local disabled = not SilenceGroup:get('GlobalSilenceToggle')

            I.Settings.updateRendererArgument(groupName, 'GlobalSilenceChance',
                {
                    disabled = disabled,
                }
            )

            I.Settings.updateRendererArgument(groupName, 'ExploreSilenceMin',
                {
                    max = exploreSilenceMax - 1,
                    disabled = disabled,
                }
            )

            I.Settings.updateRendererArgument(groupName, 'ExploreSilenceMax',
                {
                    min = exploreSilenceMin + 1,
                    disabled = disabled,
                }
            )

            I.Settings.updateRendererArgument(groupName, 'BattleSilenceMin',
                {
                    max = battleSilenceMax - 1,
                    disabled = disabled,
                }
            )

            I.Settings.updateRendererArgument(groupName, 'BattleSilenceMax',
                {
                    min = battleSilenceMin + 1,
                    disabled = disabled,
                }
            )
        end
    )
)
