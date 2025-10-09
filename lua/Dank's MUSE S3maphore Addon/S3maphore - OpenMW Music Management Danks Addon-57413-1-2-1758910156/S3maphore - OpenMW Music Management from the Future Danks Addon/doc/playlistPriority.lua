---@meta

--- Playlist Priority Guide
---
--- Lower numbers mean higher priority, and will potentially override earlier ones in the list.
--- Playlists with equivalent priority will be used according to the order in which they were registered, which occurs in the alphabetical order of the contents of the VFS directory playlists/ and then according to the exact sequence in each playlist file.
---
--- Some general suggestions for setting priority:
--- 1. Priority numbers should generally go from less to more specific. A playlist with 1 region should have a lower priority number than one with 10.
--- Builtin modules populate around the edges to give space for everyone in the middle.
--- 2. Where possible, slot vanilla playlists above DLC or other modded regional/etc playlists in the priority chain
--- 3. Remember to take advantage of the rules set forth by other playlists. Your position in the chain also implies what conditions have already been checked - for example, priority numbers below 200 can generally assume the player is in combat already.

---@class PlaylistPriority
--- Battle music. Below this tier, the player can generally be assumed to be in combat.
---@field Battle integer
--- Exploration music, default for most situations. The exploration playlist's priority should generally be considered the upper limit of playlist priorities.
---@field Explore integer
--- City music
---@field City integer
--- Fuzzy-matched cells
---@field CellMatch integer
--- Faction-based rules such as great houses or guilds
---@field Factional integer
--- Rules based on time of day
---@field TimeOfDay integer
--- Exact cell names
---@field CellExact integer
--- Rules based on static sets/names
---@field Tileset integer
--- Regional music
---@field Region integer
--- Special event or reserved slots, for unique scripted elements.
---@field Special integer

local PlaylistPriority = {
    Explore = 1000,
    -- Reserve the upper 100 slots, so TR doesn't get all the first dibs - We need vanilla playlists, too!

    -- Regional
    Region = 900,

    -- City
    City = 800,

    -- Cell matches
    CellMatch = 700,

    -- Tileset-based
    Tileset = 600,
    -- Exact cells
    CellExact = 500,
    -- Starwind playlists

    Faction = 400,
    -- -- Times of day
    TimeOfDay = 300,
    -- Combat Playlists
    BattleVanilla = 200,
    BattleMod = 190,
    Special = 50,
}

return PlaylistPriority
