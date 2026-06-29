-- BlacklistDataLoader.lua
-- Runtime loader for blacklist JSON files under data/Blacklists/.
-- Merges all BlacklistData.* keys with appropriate strategies per key type.

local JsonMergeLoader = require("scripts.ProceduralChatter.JsonMergeLoader")

local BlacklistDataLoader = {}

local PREFIX = "scripts/proceduralchatter/data/blacklists/"

local loaded = false
local BlacklistData = {}

local function normalizeSet(set)
    local out = {}
    for key, value in pairs(set or {}) do
        if type(key) == "string" then
            out[string.lower(key)] = value == nil and true or value
        else
            out[key] = value
        end
    end
    return out
end

BlacklistData.normalizedSet = normalizeSet

local MERGE_RULES = {
    bannedIds               = "mapMerge",
    sitBannedIds            = "mapMerge",
    sleepBannedIds          = "mapMerge",
    conversationTravelBanIds= "mapMerge",
    objectBlacklistIds      = "mapMerge",
    blacklistedInteriors    = "mapMerge",
    safeShelterExactCells   = "mapMerge",
    safeShelterKeywords     = "arrayConcat",
    religiousExactCells     = "mapMerge",
    templeExactCells        = "mapMerge",
    imperialShrineExactCells= "mapMerge",
    religiousKeywords       = "arrayConcat",
    militaryExactCells      = "mapMerge",
    militaryKeywords        = "arrayConcat",
    shopExactCells          = "mapMerge",
    shopKeywords            = "arrayConcat",
    shopNpcIds              = "mapMerge",
    doorOverrides           = "deepMerge",
    doorOverridesBcom       = "deepMerge",
    scheduleBannedIds       = "mapMerge",
    exemptPatterns          = "arrayConcat",
    exemptMods              = "mapMerge",
    exemptClasses           = "mapMerge",
    travelClasses           = "mapMerge",
    allowedAnimModels       = "arrayConcat",
    namedCellWhitelist      = "mapMerge",
    gridCellWhitelist       = "arrayConcat",
    scriptWhitelist         = "mapMerge",
    questExceptions         = "deepMerge",
    cityCells               = "mapMerge",
    mournholdInteriors      = "mapMerge",
    badWeatherCodes         = "mapMerge",
}

local function mergeFile(data, path)
    for key, value in pairs(data) do
        local rule = MERGE_RULES[key]
        if rule == "mapMerge" then
            if not BlacklistData[key] then BlacklistData[key] = {} end
            JsonMergeLoader.mapMerge(BlacklistData[key], value)
        elseif rule == "arrayConcat" then
            if not BlacklistData[key] then BlacklistData[key] = {} end
            JsonMergeLoader.arrayConcat(BlacklistData[key], value)
        elseif rule == "deepMerge" then
            if not BlacklistData[key] then BlacklistData[key] = {} end
            JsonMergeLoader.deepMerge(BlacklistData[key], value)
        else
            -- Unknown key: heuristic — array-like tables concat, map-like tables merge.
            if type(value) == "table" then
                if #value > 0 then
                    if not BlacklistData[key] then BlacklistData[key] = {} end
                    JsonMergeLoader.arrayConcat(BlacklistData[key], value)
                else
                    if not BlacklistData[key] then BlacklistData[key] = {} end
                    JsonMergeLoader.mapMerge(BlacklistData[key], value)
                end
            else
                BlacklistData[key] = value
            end
        end
    end
end

function BlacklistDataLoader.ensureLoaded()
    if loaded then return end
    loaded = true

    local count = JsonMergeLoader.scan(PREFIX, mergeFile)

    print(string.format("[BlacklistDataLoader] Scan complete: %d json file(s)", count))
end

function BlacklistDataLoader.getData()
    BlacklistDataLoader.ensureLoaded()
    return BlacklistData
end

return BlacklistDataLoader
