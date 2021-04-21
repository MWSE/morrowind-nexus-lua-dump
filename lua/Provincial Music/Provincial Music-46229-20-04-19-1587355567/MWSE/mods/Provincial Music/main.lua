---------------------------
-- Provincial Music by Texafornian
--
-- Main File
--
-- Many thanks to:
-- NullCascade for MWSE v2 and checking region via loaddoor
-- Rytelier for inspiration from his MWSE music mod
-- Merlord for info on Morrowind mp3 music format (constant 128 kb/s, 44.1 kHz)

local config = require("Provincial Music.config")

------------------
-- DECLARATIONS
------------------
local version = "20.04.19"
local provinceNew = "Vanilla"
local provincePrev = "Vanilla"
local trackNumberNew = 1
local trackNumberPrev = 1
local trackPath = ""
local trackType = "explore"

------------------
-- FUNCTIONS
------------------
--[[
Outputs messages to mwse.log if debug level.
]]
local function debugLog(level, string)
    if config.debugLevel <= level then
        mwse.log("[Provincial Music] " .. string)
    end
end

--[[
Check regions table for given region name and associated province.
]]
local function parseRegion(regionName)
    debugLog(0, "parseRegion called: Region = " .. regionName)

    -- Check table for current region. If not present, record error and return vanilla.
    if not config.regions[regionName] then
        debugLog(1, "ERROR: Region " .. regionName .. " not found in config.lua table.")
        return "Vanilla"
    end

    debugLog(0, "parseRegion: Province = " .. config.regions[regionName])
    return config.regions[regionName]
end

--[[
Check doors in interior cell for a loaddoor to determine external region.
Thanks to NullCascade for this solution.
]]
local function parseIntCell(cell)
    debugLog(0, "parseIntCell called")

    -- Iterate through all doors looking for loaddoors
    for ref in cell:iterateReferences(tes3.objectType.door) do
        if (ref.destination) then
            if (ref.destination.cell.region) then
                local exteriorRegion = ref.destination.cell.region
                parseRegion(exteriorRegion)
                break
            end
        end
    end
end

--[[
Play track via its stored path.
]]
local function playTrack()
    debugLog(0, "playTrack called")

    tes3.streamMusic{
        path = trackPath,
        situation = tes3.musicSituation.uninterruptible
    }
end

--[[
Check for music files in province music folders via config.lua paths.
Create and update path table.
]]
local tableFiles = {}

local function populateTables()
    for kType, _ in pairs(config.paths) do
        tableFiles[kType] = {}
        for kProv, vPath in pairs(config.paths[kType]) do
            tableFiles[kType][kProv] = {}
            for file in lfs.dir("data files/music/" .. vPath) do
                if string.endswith(file, ".mp3") then
                    mwse.log("[Provincial Music] " .. kProv .. " " .. kType .. " mp3 Added: " .. file)
                    table.insert(tableFiles[kType][kProv], file)
                end
            end
        end
    end
end

--[[
Choose new, random index from province's table of mp3s.
Ensure that the same track isn't played twice in a row.
]]
local function randomizeTrack(provinceName)
    debugLog(0, "randomizeTrack called")
    math.randomseed(os.time())

    if #tableFiles[trackType][provinceName] > 1 then
        while trackNumberNew == trackNumberPrev do
            trackNumberNew = math.random(1, #tableFiles[trackType][provinceName])
        end
    end

    trackNumberPrev = trackNumberNew
    debugLog(0, "randomizeTrack: TrackNumber = " .. trackNumberNew)
end

--[[
Set path to appropriate province mp3 path.
Delay playing track for one frame then call playing function.
]]
local function prepareTrack()
    local province = provinceNew

    if #tableFiles[trackType][province] == 0 then
        province = "Vanilla"
    end
    randomizeTrack(province)
    trackPath = config.paths[trackType][province] .. tableFiles[trackType][province][trackNumberNew]
    debugLog(0, "prepareTrack called")
	timer.frame.delayOneFrame(playTrack)
end

--[[
Fires when "musicSelectTrack" event occurs.
Prepares path and track info for next song.
]]
local function onTrackSelect()
    debugLog(0, "onTrackSelect event")
    prepareTrack()
end
event.register("musicSelectTrack", onTrackSelect)

--[[
Runs through region and province checks after possible music-changing events.
]]
local function checkRegion(flag)
    debugLog(0, "checkRegion called, trackType = " .. trackType)

    -- Exterior cell: Get region name and check it against table; OR
    -- Interior cell: Figure out the exerior region by checking loaddoors
    if tes3.getRegion().name ~= nil then
        provinceNew = parseRegion(tes3.getRegion().name)
    else
        provinceNew = parseIntCell(tes3.getPlayerCell())
    end

    -- Player is in new province or changing combat state, so force track change; OR
    -- Continue playing current track
    if provinceNew ~= provincePrev or flag == "new" then
        provincePrev = provinceNew
        onTrackSelect()
    else
        debugLog(0, "Continuing current track")
    end
end

--[[
Fires when "initialized" event occurs.
Checks appropriate music folders and populates tables.
]]
local function onInitialized()
    mwse.log("[Provincial Music] Initalized v" .. version)
    populateTables()
end
event.register("initialized", onInitialized)

--[[
Fires when "cellChanged" and "loaded" events occur.
Forces "explore" trackType to account for player teleporting from combat.
Calls function checkRegion.
]]
local function onCellChange(e)
    if e.previousCell ~= nil and e.cell ~= nil then
        local string = "onCellChange event: " .. tostring(e.previousCell) .. " -> " .. tostring(e.cell)
        debugLog(0, string)
    end

    local flag = ""

    if trackType == "battle" and tes3.getMobilePlayer().inCombat == false then
        debugLog(0, "onCellChange event: Player no longer in combat.")
        trackType = "explore"
        flag = "new"
    end

    checkRegion(flag)
end
event.register("cellChanged", onCellChange)
event.register("loaded", onCellChange)

--[[
Fires when player "combatStarted" event occurs.
Calls function checkRegion.
]]
local function onCombatStarted(e)
    if trackType == "explore" and tes3.getMobilePlayer().inCombat == true then
        debugLog(0, "combatStarted event")
        trackType = "battle"
        checkRegion("new")
    end
end
event.register("combatStarted", onCombatStarted)

--[[
Fires when player "combatStopped" event occurs.
Calls function checkRegion.
]]
local function onCombatStopped(e)
    if trackType == "battle" and tes3.getMobilePlayer().inCombat == false then
        debugLog(0, "combatStopped event")
        trackType = "explore"
        checkRegion("new")
    end
end
event.register("combatStopped", onCombatStopped)
