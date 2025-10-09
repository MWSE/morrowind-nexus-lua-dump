require 'doc.s3maphoreTypes'

local core = require 'openmw.core'
local nearby = require 'openmw.nearby'
local types = require 'openmw.types'

local HUGE = math.huge

--- https://gitlab.com/OpenMW/openmw/-/merge_requests/4334
--- https://gitlab.com/OpenMW/openmw/-/blob/96d0d1fa7cd83e41853061cca68f612b7eb9c834/CMakeLists.txt#L85
local onHitAPIRevision = 85
local MyLevel, Quests

---@class PlaylistRules helper functions for running playlist behaviors
---@field state PlaylistState
local PlaylistRules = {
    ---@type S3maphoreCacheKey
    combatTargetCacheKey = nil,
}

--- Stores playlist rule lookups according to whatever is most relevant for that particular type,
--- allowing rules to only execute once per a given context.
--- This cache has the same lifetime as the game session itself, so long sessions with no reloads
--- could potentially see a relatively large cache build up over time.
---@type table<string, any>
local S3maphoreGlobalCache = {}

--- Table of IDs mapped to target levels
---@type table<string, userdata>
local combatTargetLevelCache = {}

--- Clear target-specific caches, used either when they exit combat or are hit
---@param removedTargetId string
function PlaylistRules.clearPerTargetCaches(removedTargetId)
    S3maphoreGlobalCache[removedTargetId] = nil
    combatTargetLevelCache[removedTargetId] = nil
end

function PlaylistRules.clearGlobalCombatTargetCache()
    if not PlaylistRules.combatTargetCacheKey then return end
    S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey] = nil
end

--- When a target dies or is otherwised removed from the combat targets table, remove
--- references to the old cache and any userdata objects cached for memory saving purposes
---@param removedTargetId string
function PlaylistRules.clearCombatCaches(removedTargetId)
    PlaylistRules.clearGlobalCombatTargetCache()
    PlaylistRules.clearPerTargetCaches(removedTargetId)
end

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

    return result
end

local validCreatureTypes = {
    [0] = 'creatures',
    [1] = 'daedra',
    [2] = 'undead',
    [3] = 'humanoid',
}

--- Rule for checking whether combat targets match a specific type. This can be for NPCs, or specific subtypes of creatures, such as undead, or daedric.
--- Valid values are listed under the TargetType enum.
--- NOTE: These are hashsets and only `true` is a valid value.
--- Inputs must always be lowercased. Yes, really.
---
--- Example Usage:
---
--- playlistRules.combatTargetType { ['npc'] = true }
--- playlistRules.combatTargetType { ['undead'] = true }
---@param targetTypeRules CombatTargetTypeMatches
---@return boolean
function PlaylistRules.combatTargetType(targetTypeRules)
    if not PlaylistRules.state.isInCombat then return false end

    if not S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey] then S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey] = {} end

    local currentCombatTargetsCache = S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey]

    if currentCombatTargetsCache and currentCombatTargetsCache[targetTypeRules] ~= nil then
        return currentCombatTargetsCache[targetTypeRules]
    end

    local result = false

    for _, actor in pairs(PlaylistRules.state.combatTargets) do
        local targetIsNPC = types.NPC.objectIsInstance(actor)
        if targetIsNPC then
            result = targetTypeRules.npc ~= nil

            if not result then goto FAILED end
        else
            local creatureRecord = actor.type.records[actor.recordId]
            local creatureType = validCreatureTypes[creatureRecord.type]
            result = targetTypeRules[creatureType] ~= nil

            if not result then goto FAILED end
        end
    end

    ::FAILED::

    currentCombatTargetsCache[targetTypeRules] = result

    return result
end

--- Checks whether any combat target's classes matches one of a hashset
--- ALWAYS LOWERCASE YOUR INPUTS!
---
--- Example Usage:
---
--- playlistRules.combatTargetClasses { ['guard'] = true, ['acrobat'] = true }
---@param classes IDPresenceMap
---@return boolean
function PlaylistRules.combatTargetClass(classes)
    if not PlaylistRules.state.isInCombat then return false end

    if not S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey] then S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey] = {} end

    local currentCombatTargetsCache = S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey]

    if currentCombatTargetsCache and currentCombatTargetsCache[classes] ~= nil then
        return currentCombatTargetsCache[classes]
    end

    local result = false

    for _, actor in pairs(PlaylistRules.state.combatTargets) do
        local targetIsNPC = types.NPC.objectIsInstance(actor)
        if not targetIsNPC then goto CONTINUE end
        local targetRecord = actor.type.records[actor.recordId]

        if classes[targetRecord.class] then
            result = true
            break
        end

        ::CONTINUE::
    end

    currentCombatTargetsCache[classes] = result

    return result
end

--- Rule used to check if a nearby merchant does, or doesn't, offer a specific service.
--- Works on all nearby actors, and bails and returns true for the first actor whom matches all provided rules.
--- Works best in locations where a single merchant is present - for cells where multiple actors may potentially offer the same service, like The Abecette,
--- a cellNameMatch or cellNameExact rule may be more appropriate.
--- Only accepts a limited range of inputs as defined by the `ServicesOffered` type.
---
--- Example Usage:
---
--- local services = { ["Armor"] = true, ['Repair'] = true, }
--- playlistRules.localMerchantType(services)
---@param services ServicesOffered
---@return boolean
function PlaylistRules.localMerchantType(services)
    if PlaylistRules.state.isInCombat then return false end

    local cellName = PlaylistRules.state.cellName
    if not S3maphoreGlobalCache[cellName] then S3maphoreGlobalCache[cellName] = {} end

    local currentCellCache = S3maphoreGlobalCache[cellName]

    if currentCellCache[services] ~= nil then
        return currentCellCache[services]
    end

    local result = false

    for _, actor in pairs(nearby.actors) do
        local targetRecord = actor.type.records[actor.recordId]
        local targetServices = targetRecord.servicesOffered

        local maybeMatchedAll = true
        for serviceName, offered in pairs(services) do
            if targetServices[serviceName] ~= offered then
                maybeMatchedAll = false
                break
            end
        end

        if maybeMatchedAll then
            result = true
            break
        end
    end

    currentCellCache[services] = result

    return result
end

--- Rule for checking the rank of a target in the specified faction.
--- Like any rule utilizing a LevelDifferenceMap, either min or max are optional, but *one* of the two is required.
---
--- Example usage:
---
--- playlistRules.combatTargetFaction { hlaalu = { min = 1 } }
---@param factionRules NumericPresenceMap
function PlaylistRules.combatTargetFaction(factionRules)
    if not PlaylistRules.state.isInCombat then return false end

    if not S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey] then S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey] = {} end

    local currentCombatTargetsCache = S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey]

    if currentCombatTargetsCache and currentCombatTargetsCache[factionRules] ~= nil then
        return currentCombatTargetsCache[factionRules]
    end

    local FightingActors = PlaylistRules.state.combatTargets

    local result = false
    for _, actor in pairs(FightingActors) do
        local getFactionRank = actor.type.getFactionRank
        if getFactionRank == nil then goto SKIPTARGET end

        for factionName, rankRange in pairs(factionRules) do
            local targetFactionRank = getFactionRank(actor, factionName)

            if targetFactionRank <= (rankRange.max or HUGE) and targetFactionRank >= (rankRange.min or 1) then
                result = true
                goto MATCHED
            end
        end

        ::SKIPTARGET::
    end

    ::MATCHED::

    currentCombatTargetsCache[factionRules] = result

    return result
end

--- Sets a relative or absolute limit on combat target levels for triggering combat music.
---
--- levelDifference rules may be relative or absolute, eg a multplier of the player's level or the actual difference in level.
--- They may have a minimum and maximum threshold, although either is optional.
--- Negative values indicate the player is stronger, whereas positive ones indicate the target is stronger.
---
--- Example usage:
---
--- This rule plays if the target's level is equal to or up to five levels bove the player's
--- playlistRules.combatTargetLevelDifference { absolute = { min = 0, max = 5 } }
---
--- This rule is valid if the target's level is within half or twice the player's level. EG if you're level 20, and the target is level 10, this rule matches.
--- playlistRules.combatTargetLevelDifference { relative = { min = 0.5, max = 2.0 } }
---@param levelRule LevelDifferenceMap
function PlaylistRules.combatTargetLevelDifference(levelRule)
    if not PlaylistRules.state.isInCombat then return false end

    if not S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey] then S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey] = {} end

    local currentCombatTargetsCache = S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey]

    if currentCombatTargetsCache and currentCombatTargetsCache[levelRule] ~= nil then
        return currentCombatTargetsCache[levelRule]
    end

    local result, levelDifference, levelScale = false, nil, nil
    for _, actor in pairs(PlaylistRules.state.combatTargets) do
        local targetLevel = combatTargetLevelCache[actor.id] or actor.type.stats.level(actor)
        if not combatTargetLevelCache[actor.id] then combatTargetLevelCache[actor.id] = level end

        if levelRule.absolute then
            levelDifference = targetLevel.current - MyLevel.current
            levelScale = levelRule.absolute
        elseif levelRule.relative then
            levelDifference = targetLevel.current / MyLevel.current
            levelScale = levelRule.relative
        else
            error(
                StaticStrings.InvalidLevelDifferenceRule:format(levelRule)
            )
        end

        if levelDifference <= levelScale.max and levelDifference >= levelScale.min then
            result = true
            break
        end
    end

    currentCombatTargetsCache[levelRule] = result

    return result
end

--- Rule for checking if the player is fighting vampires of any type, or clan.
--- To check specific vampire clans, use the faction rule.
---@return boolean
function PlaylistRules.fightingVampires()
    if not PlaylistRules.state.isInCombat or core.API_REVISION < onHitAPIRevision then return false end

    if not S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey] then S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey] = {} end

    local currentCombatTargetsCache = S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey]

    if currentCombatTargetsCache and currentCombatTargetsCache.vampires ~= nil then
        return currentCombatTargetsCache.vampires
    end

    local result = false
    for _, actor in pairs(PlaylistRules.state.combatTargets) do
        local actorStatCache = S3maphoreGlobalCache[actor.id] or {}
        if not S3maphoreGlobalCache[actor.id] then S3maphoreGlobalCache[actor.id] = actorStatCache end

        local activeEffects = actorStatCache.effects or actor.type.activeEffects(actor)
        if not actorStatCache.effects then actorStatCache.effects = activeEffects end

        if activeEffects:getEffect(core.magic.EFFECT_TYPE.Vampirism).magnitude > 0 then
            result = true
            goto MATCHED
        end
    end

    ::MATCHED::

    currentCombatTargetsCache.vampires = result

    return result
end

--- Checks whether or not an actor meets a specific threshold for any of the three dynamic stats - health, fatigue, or magicka.
--- Any combination of the three will work, and one may use a maximum and/or a minimum threshold
---
--- Example usage:
---
--- Rule is valid if an actor has MORE than 25% health
--- playlistRules.dynamicStatThreshold { health = { min = 0.25 } }
---
--- Rule is valid is an actor has LESS THAN 75% magicka.
--- playlistRules.dynamicStatThreshold { magicka = { max = 0.75 } }
---@param statThreshold StatThresholdMap decimal number encompassing how much health the target should have left in order for this playlist to be considered valid
---@return boolean
function PlaylistRules.dynamicStatThreshold(statThreshold)
    if not PlaylistRules.state.isInCombat or core.API_REVISION < onHitAPIRevision then return false end

    if not S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey] then S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey] = {} end

    local currentCombatTargetsCache = S3maphoreGlobalCache[PlaylistRules.combatTargetCacheKey]

    if currentCombatTargetsCache and currentCombatTargetsCache[statThreshold] ~= nil then
        return currentCombatTargetsCache[statThreshold]
    end

    --- Iterate every actor
    --- Confirm all of them fall within the threshold
    --- if any one of them does not pass, then, bail on the whole thing
    local result = false
    for _, actor in pairs(PlaylistRules.state.combatTargets) do
        local actorStatCache = S3maphoreGlobalCache[actor.id] or {}
        if not S3maphoreGlobalCache[actor.id] then S3maphoreGlobalCache[actor.id] = actorStatCache end

        for statName, range in pairs(statThreshold) do
            local stat = actorStatCache[statName] or actor.type.stats.dynamic[statName](actor)
            if not actorStatCache[statName] then actorStatCache[statName] = stat end

            local normalizedStat = stat.current / stat.base

            if normalizedStat < (range.min or 0.0) or normalizedStat > (range.max or HUGE) then
                PlaylistRules.state.isInCombat = false
                goto FAILED
            end
        end
    end

    result = true

    ::FAILED::

    currentCombatTargetsCache[statThreshold] = result

    return result
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
            if static:find(pattern, 1, true) then
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
--- Starts at the minHour, and ends at the maxHour.
--- The below example using 8 and 12, will start at 8 am and end at 12 PM.
---
--- Example usage:
---
--- playlistRules.timeOfDay(8, 12)
---@param minHour integer
---@param maxHour integer
---@return boolean
function PlaylistRules.timeOfDay(minHour, maxHour)
    local gameHour = math.floor(core.getGameTime() / 3600) % 24
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
    local currentRegion = PlaylistRules.state.nearestRegion

    return currentRegion ~= nil
        and currentRegion ~= ''
        and regionNames[currentRegion] or false
end

--- Returns whether the current exterior cell is on a particular node of the grid
---
--- Example usage:
---
--- playlistRules.exteriorGrid { { x = -2, y = -3 } }
---@param gridRules S3maphoreCellGrid[]
function PlaylistRules.exteriorGrid(gridRules)
    local currentGrid = PlaylistRules.state.currentGrid
    if not currentGrid then return false end

    local exteriorGridCache = S3maphoreGlobalCache[PlaylistRules.state.cellId]
    if exteriorGridCache ~= nil then
        return exteriorGridCache
    end

    local result = false
    for _, gridRule in ipairs(gridRules) do
        if gridRule.x == currentGrid.x and gridRule.y == currentGrid.y then
            result = true
            break
        end
    end

    S3maphoreGlobalCache[PlaylistRules.state.cellId] = result

    return result
end

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
---@param journalDataMap NumericPresenceMap
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

            if questState <= (questRange.max or HUGE) and questState >= questRange.min then
                result = true
                break
            end
        end
    end

    S3maphoreGlobalCache[journalDataMap] = result

    return result
end

---@param playlistState PlaylistState A long-living reference to the playlist state table. To aggressively minimize new allocations, this table is created once when the core initializes and is continually updated througout the lifetime of the script.
---@param staticStrings S3maphoreStaticStrings
return function(playlistState, staticStrings)
    assert(playlistState)
    assert(staticStrings)

    PlaylistRules.state = playlistState

    Quests = playlistState.self.type.quests(playlistState.self)
    MyLevel = playlistState.self.type.stats.level(playlistState.self)
    StaticStrings = staticStrings
    assert(Quests)

    return PlaylistRules
end
