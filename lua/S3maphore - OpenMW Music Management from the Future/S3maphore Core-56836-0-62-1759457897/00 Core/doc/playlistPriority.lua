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
local PlaylistPriority = {
    Never = math.huge,
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
    Class = 375,
    MerchantType = 350,
    -- -- Times of day
    TimeOfDay = 300,
    -- Combat Playlists
    BattleVanilla = 200,
    BattleMod = 190,
    Special = 50,
}

return PlaylistPriority
