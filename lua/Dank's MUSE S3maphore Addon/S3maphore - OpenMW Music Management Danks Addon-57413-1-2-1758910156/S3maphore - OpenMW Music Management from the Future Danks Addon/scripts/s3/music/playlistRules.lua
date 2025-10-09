local core = require 'openmw.core'

--- Alias for defining S3maphore rules for object record ids allowing or disallowing playlist selection
---@alias IDPresenceMap table<string, boolean>

---@class CellMatchPatterns
---@field disallowed string[]
---@field allowed string[]

---@class PlaylistRules helper functions for running playlist behaviors
---@field state PlaylistState
local PlaylistRules = {
    ---@type S3maphoreCacheKey
    combatTargetCacheKey = nil,
}

--- Lookup table for storing the results of location-based matches
---@alias S3maphoreMatchCache table<string, boolean>

local S3maphoreGlobalCache = {}

--- Player cell name/id mapped to the memory address of the table being looked up. Only used in the most expensive rulesets
---@alias S3maphoreCacheKey string

--- Returns whether the current cell name matches a pattern rule. Checks disallowed patterns first
---
--- Example usage:
---
--- playlistRules.cellNameMatch { allowed = { 'mages', 'south wall', }, disallowed = { 'fighters', } }
---@param patterns CellMatchPatterns
function PlaylistRules.cellNameMatch(patterns)
    local cellName = PlaylistRules.state.cellName

    if S3maphoreGlobalCache[cellName]
        and S3maphoreGlobalCache[cellName][patterns] ~= nil then
        return S3maphoreGlobalCache[cellName][patterns]
    end

    local result, found = false, false

    for _, pattern in ipairs(patterns.disallowed or {}) do
        if cellName:find(pattern, 1, true) then
            found = true
            break
        end
    end

    if not found then
        for _, pattern in ipairs(patterns.allowed or {}) do
            if cellName:find(pattern, 1, true) then
                result = true
                break
            end
        end
    end

    if S3maphoreGlobalCache[cellName] == nil then S3maphoreGlobalCache[cellName] = {} end
    S3maphoreGlobalCache[cellName][patterns] = result

    return result
end

--- Returns whether or not the current cell exists in the cellNames map
---
--- Example usage:
---
--- playlistRules.cellNameExact { 'balmora, caius cosades\'s house' = true, 'balmora, guild of mages' = true, }
---@param cellNames IDPresenceMap
---@return boolean
function PlaylistRules.cellNameExact(cellNames)
    return cellNames[PlaylistRules.state.cellName]
end

--- Returns whether the player is currently in combat with any actor out of the input set
--- the playlistState provided to each `isValidCallback` includes a `combatTargets` field which is meant to be used as the first argument
---
--- Exmple usage:
---
--- playlistRules.combatTarget { 'caius cosades' = true, }
---@param validTargets IDPresenceMap
---@return boolean
function PlaylistRules.combatTargetExact(validTargets)
    if not PlaylistRules.state.isInCombat then return false end

    if not S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey] then S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey] = {} end

    local currentCombatTargetsCache = S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey]

    if currentCombatTargetsCache and currentCombatTargetsCache[validTargets] ~= nil then
        return currentCombatTargetsCache[validTargets]
    end

    local FightingActors = PlaylistRules.state.combatTargets

    local result = false
    for _, actor in pairs(FightingActors) do
        local actorName = actor.type.records[actor.recordId].name:lower()

        if validTargets[actorName] then
            result = true
            break
        end
    end

    currentCombatTargetsCache[validTargets] = result

    return false
end

--- Finds any nearby combat target whose name matches any one string of a set
---
--- Example usage:
---
--- playlist.rules.combatTargetMatch { 'jedi', 'sith', }
---@param validTargetPatterns string[]
---@return boolean
function PlaylistRules.combatTargetMatch(validTargetPatterns)
    if not PlaylistRules.state.isInCombat then return false end

    if not S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey] then S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey] = {} end

    local currentCombatTargetsCache = S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey]

    if currentCombatTargetsCache and currentCombatTargetsCache[validTargetPatterns] ~= nil then
        return currentCombatTargetsCache[validTargetPatterns]
    end

    local combatTargets = PlaylistRules.state.combatTargets

    local result = false

    for _, actor in pairs(combatTargets) do
        if S3maphoreGlobalCache[actor.recordId] == nil then S3maphoreGlobalCache[actor.recordId] = {} end

        local cachedResult = S3maphoreGlobalCache[actor.recordId][validTargetPatterns]

        if cachedResult ~= nil then
            if cachedResult then
                result = true
                break
            else
                goto continue
            end
        end

        local actorName = actor.type.records[actor.recordId].name:lower()

        local result = false
        for _, pattern in ipairs(validTargetPatterns) do
            if actorName:find(pattern, 1, true) ~= nil then
                result = true
                break
            end
        end

        S3maphoreGlobalCache[actor.recordId][validTargetPatterns] = result

        if result then break end

        ::continue::
    end

    currentCombatTargetsCache[validTargetPatterns] = result

    return result
end

--- Checks the current cell's static list for whether
--- an allowed static is present, or a disallowed one is present.
--- Example usage:
---
--- playlistRules.staticExact { 'furn_de_ex_bench_01' = true, 'ex_ashl_tent_01' = false, }
---@param staticRules IDPresenceMap
---@return boolean?
function PlaylistRules.staticExact(staticRules)
    local localStatics = PlaylistRules.state.staticList
    if not localStatics or next(localStatics) == nil then return end

    local cellName = PlaylistRules.state.cellName

    if S3maphoreGlobalCache[cellName] == nil then S3maphoreGlobalCache[cellName] = {} end

    if S3maphoreGlobalCache[cellName][staticRules] ~= nil then
        return S3maphoreGlobalCache[cellName][staticRules]
    end

    local result = false

    for _, recordId in ipairs(localStatics.recordIds) do
        local staticRule = staticRules[recordId]

        if staticRule ~= nil then
            result = staticRule
            break
        end
    end

    S3maphoreGlobalCache[cellName][staticRules] = result

    return result
end

--- Checks the current cell's static list to see if it contains any object matching any of the input patterns
--- WARNING: This is the most expensive possible playlist filter. It is only available in interior cells as S3maphore will not track statics in exterior cells.
---
--- Example usage:
---
--- playlistRules.staticMatch { 'cave', 'py', }
---
---@param patterns string[]
---@return boolean?
function PlaylistRules.staticMatch(patterns)
    local localStatics = PlaylistRules.state.staticList
    if not localStatics or next(localStatics) == nil then return end

    local cellName = PlaylistRules.state.cellName

    if S3maphoreGlobalCache[cellName] == nil then S3maphoreGlobalCache[cellName] = {} end

    if S3maphoreGlobalCache[cellName][patterns] ~= nil then
        return S3maphoreGlobalCache[cellName][patterns]
    end

    local result = false

    for _, static in ipairs(localStatics.recordIds) do
        for _, pattern in ipairs(patterns) do
            if static.recordId:find(pattern) then
                result = true
                goto matchBreak
            end
        end
    end

    ::matchBreak::

    S3maphoreGlobalCache[cellName][patterns] = result

    return result
end

--- Returns whether or not a given cell contains statics matching the given content file array
--- Automatically lowercases all input content file names!
---
--- Example usage:
---
--- playback.rules.staticContentFile { ['starwind enhanced.esm'] = true, }
---@param contentFiles  IDPresenceMap
---@return boolean
function PlaylistRules.staticContentFile(contentFiles)
    local localStatics = PlaylistRules.state.staticList
    if not localStatics or next(localStatics) == nil then return false end
    local cellName = PlaylistRules.state.cellName

    if S3maphoreGlobalCache[cellName] == nil then S3maphoreGlobalCache[cellName] = {} end

    if S3maphoreGlobalCache[cellName][contentFiles] ~= nil then
        return S3maphoreGlobalCache[cellName][contentFiles]
    end

    local result = false

    for _, contentFile in ipairs(localStatics.contentFiles) do
        if contentFiles[contentFile] ~= nil then
            result = true
            break
        end
    end

    S3maphoreGlobalCache[cellName][contentFiles] = result

    return result
end

--- Checks whether the current gameHour matches a certain time of day or not
---
--- Example usage:
---
--- playlistRules.timeOfDay(8, 12)
---@param minHour integer
---@param maxHour integer
---@return boolean
function PlaylistRules.timeOfDay(minHour, maxHour)
    local gameHour = math.floor(core.getGameTime() / 3600)
    return gameHour < maxHour and gameHour >= minHour
end

--- Return whether the current region matches a set
---
--- Example usage:
---
--- playlistRules.region { 'azura\'s coast region' = true, 'sheogorad region' = true, }
---@param regionNames IDPresenceMap
---@return boolean
function PlaylistRules.region(regionNames)
    local currentRegion = PlaylistRules.state.self.cell.region

    return currentRegion ~= nil
        and currentRegion ~= ''
        and regionNames[currentRegion] or false
end

---@class NumericPresenceMapData
---@field min integer
---@field max integer

---@alias NumericPresneceMap table<string, NumericPresenceMapData>

local Quests
local S3maphoreJournalCache = {}

---@private
---Clear the journal cache when a player gets a journal update
function PlaylistRules.clearJournalCache()
    S3maphoreJournalCache = {}
end

--- Playlist rule for checking a specific journal state
---
--- Example usage:
---
--- playback.rules.journal { A1_V_VivecInformants = { min = 50, max = 55, }, }
---@param journalDataMap NumericPresneceMap
---@return boolean
function PlaylistRules.journal(journalDataMap)
    local cachedResult = S3maphoreJournalCache[journalDataMap]

    if cachedResult ~= nil then
        return cachedResult
    end

    local result = false

    for questName, questRange in pairs(journalDataMap) do
        local quest = Quests[questName]

        if quest then
            local questState = quest.stage

            if questState <= questRange.max and questState >= questRange.min then
                result = true
                break
            end
        end
    end

    S3maphoreGlobalCache[journalDataMap] = result

    return result
end

---@param playlistState PlaylistState A long-living reference to the playlist state table. To aggressively minimize new allocations, this table is created once when the core initializes and is continually updated througout the lifetime of the script.
return function(playlistState)
    assert(playlistState)

    PlaylistRules.state = playlistState

    Quests = playlistState.self.type.quests(playlistState.self)
    assert(Quests)

    return PlaylistRules
end
