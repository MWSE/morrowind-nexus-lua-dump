---@type S3maphorePlaylistEnv
_ENV = _ENV

local TimeSunrise = 6

local TimeSunset = 20

---@type IDPresenceMap
local SolstheimWildernessRegions = {
	['moesring mountains region'] = true,
	['isinfier plains region'] = true,
	['hirstaang forest region'] = true,
    ['brodir grove region'] = true,
	['felsaad coast region'] = true,
    ['thirsk region'] = true,
}

---@type IDPresenceMap
local SolstheimRegionsExclusionCells = {
    ['fort frostmoth'] = true,
}

---@type CellMatchPatterns
local SkaalCells = {
    allowed = {
		'skaal',
    },
    disallowed = {}
}

---@type CellMatchPatterns
local ThirskCells = {
    allowed = {
		'thirsk',
    },
    disallowed = {}
}

local function SolstheimWildernessDayRule()
    return Playback.state.cellIsExterior
        and Playback.rules.region(SolstheimWildernessRegions)
		and Playback.rules.timeOfDay(TimeSunrise, TimeSunset)
		and not Playback.rules.cellNameExact(SolstheimRegionsExclusionCells)
end

local function SolstheimWildernessNightClearRule()
    return Playback.state.cellIsExterior
        and Playback.rules.region(SolstheimWildernessRegions)
		and Playback.state.weather == 'clear'
		and not Playback.rules.timeOfDay(TimeSunrise, TimeSunset)
		and not Playback.rules.cellNameExact(SolstheimRegionsExclusionCells)
end

local function SolstheimWildernessNightNotClearRule()
    return Playback.state.cellIsExterior
        and Playback.rules.region(SolstheimWildernessRegions)
		and not Playback.state.weather == 'clear'
		and not Playback.rules.timeOfDay(TimeSunrise, TimeSunset)
		and not Playback.rules.cellNameExact(SolstheimRegionsExclusionCells)
end

---@type ValidPlaylistCallback
local function SkaalCellNightRule()
    return Playback.rules.cellNameMatch(SkaalCells)
		and not Playback.rules.timeOfDay(TimeSunrise, TimeSunset)
end

---@type ValidPlaylistCallback
local function SkaalCellDayRule()
    return Playback.rules.cellNameMatch(SkaalCells)
		and Playback.rules.timeOfDay(TimeSunrise, TimeSunset)
end

---@type ValidPlaylistCallback
local function ThirskCellDayRule()
    return not Playback.state.cellIsExterior 
		and Playback.rules.timeOfDay(TimeSunrise, TimeSunset)
		and Playback.rules.cellNameMatch(ThirskCells)
end

---@type ValidPlaylistCallback
local function ThirskCellNightRule()
    return not Playback.state.cellIsExterior 
		and not Playback.rules.timeOfDay(TimeSunrise, TimeSunset)
		and Playback.rules.cellNameMatch(ThirskCells)
end

--Playback.State.weather == 'Clear'


---@type S3maphorePlaylist[]
return {
    {
        id = 'Solstheim Wilderness Day',
        tracks = {
			'music/MS/region/Solstheim pack/nd1_njol.mp3',
			'music/MS/region/Solstheim pack/nd3_draumr.mp3',
			'music/MS/region/Solstheim pack/nd7_jafnan.mp3',
        },
        priority = PlaylistPriority.Region,
        randomize = true,
		cycleTracks = true,
		playOneTrack = false,
        isValidCallback = SolstheimWildernessDayRule,
		fallback = {
            playlistChance = 0.50,
            playlists = {
                'Explore'
            },
			tracks = {
				'explore',
			},
        },
    },
	{
        id = 'Solstheim Wilderness Night Clear',
        tracks = {
			'music/MS/region/Solstheim pack/nd5_ginnung01.mp3',
        },
        priority = PlaylistPriority.Region,
        randomize = true,
		cycleTracks = true,
		playOneTrack = false,
        isValidCallback = SolstheimWildernessNightClearRule,
    },
	{
        id = 'Solstheim Wilderness Night Not Clear',
        tracks = {
			'music/MS/region/Solstheim pack/nd6_ginnung02.mp3',
        },
        priority = PlaylistPriority.Region,
        randomize = true,
		cycleTracks = true,
		playOneTrack = false,
        isValidCallback = SolstheimWildernessNightNotClearRule,
		fallback = {
            playlistChance = 0.50,
            playlists = {
                'Explore'
            },
			tracks = {
				'explore',
			},
        },
    },
	{
        id = 'Skaal Day Playlist',
		tracks = {
			'music/MS/region/Solstheim pack/nd2_utanlands.mp3',
			'music/MS/region/Solstheim pack/nd9_ek_elska_thik.mp3',
		},
        priority = PlaylistPriority.CellMatch,
        randomize = true,
		cycleTracks = true,
		playOneTrack = false,
        isValidCallback = SkaalCellDayRule,
    },
	{
        id = 'Skaal Night Playlist',
		tracks = {
			'music/MS/region/Solstheim pack/nd4_jata.mp3',
			'music/MS/region/Solstheim pack/nd10_himinbjörg.mp3',
		},
        priority = PlaylistPriority.CellMatch,
        randomize = true,
		cycleTracks = true,
		playOneTrack = false,
        isValidCallback = SkaalCellNightRule,
    },
    {
        id = 'Thirsk Day Playlist',
		tracks = {
			'music/MS/region/Solstheim pack/nd2_utanlands.mp3',
			'music/MS/region/Solstheim pack/nd9_ek_elska_thik.mp3',
		},
        priority = PlaylistPriority.CellMatch,
        randomize = true,
		cycleTracks = true,
		playOneTrack = false,
        isValidCallback = ThirskCellDayRule,
    },
	{
        id = 'Thirsk Night Playlist',
		tracks = {
			'music/MS/region/Solstheim pack/nd4_jata.mp3',
			'music/MS/region/Solstheim pack/nd10_himinbjörg.mp3',
		},
        priority = PlaylistPriority.CellMatch,
        randomize = true,
		cycleTracks = true,
		playOneTrack = false,
        isValidCallback = ThirskCellNightRule,
    },
}
