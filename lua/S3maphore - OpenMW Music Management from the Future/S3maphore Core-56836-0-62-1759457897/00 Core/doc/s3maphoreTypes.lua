---@meta

---@class CellMatchPatterns
---@field disallowed string[]
---@field allowed string[]

---@class CombatTargetChangedData
---@field actor GameObject? Don't think this should ever be nil, but the `actor` field represents whomever has entered or exited combat
---@field targets GameObject[] List of targets whom this actor is in combat with. If the array is empty, the target has left combat for one or another reason.

---@alias CombatTargetTypeMatches table<TargetType, true>

--- Alias for defining S3maphore rules for object record ids allowing or disallowing playlist selection
---@alias IDPresenceMap table<string, boolean>

--- Describes either the relative or absolute level difference between the player and a given target.
--- Both fields are technically optional, but one of the two must exist.
--- Negative level differences indicate the player is a higher level than the target,
--- whereas a positive one indicates the target is a higher level than the player
---@class LevelDifferenceMap
---@field absolute NumericPresenceMapData?
---@field relative NumericPresenceMapData?

---@alias NumericPresenceMap table<string, NumericPresenceMapData>

---@class NumericPresenceMapData
---@field min integer? if omitted, uses 0.0
---@field max integer? If omitted, then math.huge is used

--- Data type used to bridge one playlist into another, or to extend
---@class PlaylistFallback
---@field playlistChance number? optional float between 1 and 0 indicating the chance for a fallback playlist to be selected. If not present, the chance is always 50%
---@field playlists string[]? array of fallback playlists from which to select tracks. No default values and not required.
---@field tracks string[]? tracks to manually add to a given playlist. Used for folder-based playlists; not necessary for any others

---@class PlaylistSilenceParams
---@field min integer minimum possible duration for this silence track
---@field max integer maximum possible duration for this silence track
---@field chance number probablility that this playlist will use silence between tracks

---@class QueuedEvent
---@field name string the name of the event to send
---@field data any the data to send with the event

--- Player cell name/id mapped to the memory address of the table being looked up. Only used in the most expensive rulesets
---@alias S3maphoreCacheKey string

--- Event data transmitted back to the player when they change cells.
---@class S3maphoreCellChangeData
---@field staticList StaticList
---@field hasCombatTargets boolean
---@field nearestRegion string? Defines the nearest (or current) region to the player's current cell. If one cannot be found, the previous region will be used.

--- Special class for handling exterior grids.
--- Used for special circumstances in which playlists should only run in *particular* exterior cells
---@class S3maphoreCellGrid
---@field x integer
---@field y integer

--- Lookup table for storing the results of location-based matches
---@alias S3maphoreMatchCache table<string, boolean>

---@class S3maphorePlaylist
---@field id string name of the playlist
---@field priority number priority of the playlist, lower value means higher priority
---@field tracks string[]? list of tracks in the playlist. If not provided, tracks will be loaded from the music/ subdirectory with the same name as the playlist ID.
---@field randomize boolean? if true, tracks will be played in random order. Defaults to false.
---@field active boolean? if true, the playlist is active and will be played. Defaults to false
---@field cycleTracks boolean? if true, the playlist will cycle through tracks. Defaults to true
---@field playOneTrack boolean? if true, the playlist will play only one track and then deactivate. Defaults to false
---@field registrationOrder number? the order in which the playlist was registered, used for sorting playlists by priority. Do not provide in the playlist definition, it will be assigned automatically.
---@field deactivateAfterEnd boolean? if true, the playlist will be deactivated after the current track ends. Defaults to false.
---@field interruptMode InterruptMode? whether a given playlist should be interrupted by others or interrupt others. By default, Explore playlists can be interrupted, battle playlists will interrupt other playlists, and Special playlists will never be interrupted.
---@field isValidCallback ValidPlaylistCallback? The function used to determine whether or not a playlist should execute on this particular frame. NOTE: This field is only optional in the event that the playlist's priority is NOT `PlaylistPriority.Never`
---@field fallback PlaylistFallback?
---@field fadeOut number? Optional duration supplied by a playlist which indicates how long the fadeout between tracks should be. If not present then the global fadeOut setting is used.
---@field silenceBetweenTracks PlaylistSilenceParams?
---@field exclusions S3maphorePlaylistExclusions?

---@class S3maphorePlaylistExclusions
---@field playlists string[]? list of subdirectories to ignore when constructing a playlist. the `music/` prefix is inferred, so this field works the same way as playlist IDs.
---@field tracks string[]? explicit list of tracks to ignore when constructing a playlist. the `music/` prefix is inferred, so this field works the same way as playlist IDs.

---@class S3maphoreStateChangeEventData
---@field playlistId string
---@field trackName string VFS path of the track being played
---@field reason S3maphoreStateChangeReason

---@alias ServicesOffered table<ServiceType, boolean>

---@alias ServiceType
---| 'Apparatus'
---| 'Armor'
---| 'Barter'
---| 'Books'
---| 'Clothing'
---| 'Enchanting'
---| 'Ingredients'
---| 'Lights'
---| 'Misc'
---| 'MagicItems'
---| 'Repair'
---| 'RepairItem'
---| 'Spellmaking'
---| 'Spells'
---| 'Training'
---| 'Travel'
---| 'Picks'
---| 'Potions'
---| 'Probes'
---| 'Weapon'

---@class StaticList
---@field recordIds string[] array of all unique static record ids in the current cell
---@field contentFiles string[] array of all unique content files which placed statics in this cell

---@class StatThresholdMap
---@field health NumericPresenceMapData?
---@field magicka NumericPresenceMapData?
---@field fatigue NumericPresenceMapData?

---@alias TargetType
---| 'npc'
---| 'humanoid'
---| 'undead'
---| 'daedra'
---| 'creatues'

---@alias ValidPlaylistCallback fun(playback: Playback?): boolean? a function that returns true if the playlist is valid for the current context. If not provided, the playlist will always be valid.

---@alias VampireType
---| 'quarra'
---| 'aundae'
---| 'berne'

---@alias VampireTypes VampireType[]
