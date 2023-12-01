--[[
Format for Mods:
- ID can be for any soundID, mesh filepath, or texture filepath. Must be lowercase.
- Category hooks into the tables above, so the first value will be the name of the desired table, and the second the desired value within it.
    Anything getting added to ignoreList must have an empty category of: ""
    Anything getting added to corpseMapping must have a category of: "Body"
- Define your soundType so it's properly sorted, for instance 'soundType = land' to specify texture material type.
--]]

local function initialized()
    local cso = include("Character Sound Overhaul.interop")
    if cso == nil then return end
    local soundData = {
        -- Land, Stone:
        { id = "bw\\suran\\tx_whitesuran_atlas", category = cso.landTypes.stone, soundType = "land" },
        { id = "bw\\suran\\bw_tx_stone_hlaalu_floor", category = cso.landTypes.stone, soundType = "land" },
        { id = "bw\\bw_ws_cobblestones_01", category = cso.landTypes.stone, soundType = "land" },
        { id = "bw\\bw_ws_road_01", category = cso.landTypes.stone, soundType = "land" },

    }
    for _, data in ipairs(soundData) do
        cso.addSoundData(data.id, data.category, data.soundType)
    end
end
event.register("initialized", initialized)