-- Blacklist.lua
-- Centralizes blacklist checks across Sitting, Sleeping, and Conversations for both local and global environments.
local Blacklist = {}

local types = require("openmw.types")
local NPCState = require("scripts.ProceduralChatter.NPCState")
local BlacklistDataLoader = require("scripts.ProceduralChatter.BlacklistDataLoader")
local BlacklistData = BlacklistDataLoader.getData()
local CompanionDialogueLoader = require("scripts.ProceduralChatter.CompanionDialogueLoader")

local function mergeSet(dest, src)
    for key, value in pairs(src or {}) do
        dest[string.lower(tostring(key))] = value == nil and true or value
    end
end

-- =============================================================================
-- Runtime merged sets (behaviour facade)
-- =============================================================================

-- Hardcoded IDs banned from ALL ProceduralChatter systems (sleep, sit, schedule,
-- activities, and conversation). These NPCs are completely untouchable.
-- For finer control, use the JSON categories (conversationTravelBanIds, scheduleBannedIds, etc.).
local BANNED_IDS = {
    ["phane rielle"] = true,
}
mergeSet(BANNED_IDS, BlacklistData.bannedIds)

local CONVERSATION_TRAVEL_BAN_IDS = BlacklistData.normalizedSet(BlacklistData.conversationTravelBanIds)

local SCHEDULE_BANNED_IDS = BlacklistData.normalizedSet(BlacklistData.scheduleBannedIds)

local SIT_BANNED_IDS = BlacklistData.normalizedSet(BlacklistData.sitBannedIds)

local SLEEP_BANNED_IDS = BlacklistData.normalizedSet(BlacklistData.sleepBannedIds)

local EXEMPT_PATTERNS = BlacklistData.exemptPatterns or {}

local EXEMPT_MODS = BlacklistData.normalizedSet(BlacklistData.exemptMods)

local EXEMPT_CLASSES = BlacklistData.normalizedSet(BlacklistData.exemptClasses)

local TRAVEL_CLASSES = BlacklistData.normalizedSet(BlacklistData.travelClasses)

local ALLOWED_ANIMS = BlacklistData.allowedAnimModels or {}

local NAMED_CELL_WHITELIST = BlacklistData.namedCellWhitelist or {}

local NAMED_CELL_WHITELIST_LOWER = {}
for name, _ in pairs(NAMED_CELL_WHITELIST) do
    NAMED_CELL_WHITELIST_LOWER[string.lower(name)] = true
end

local GRID_CELL_WHITELIST = BlacklistData.gridCellWhitelist or {}

local SAFE_PLACE_KEYWORDS = BlacklistData.safeShelterKeywords or {}
local RELIGIOUS_KEYWORDS = BlacklistData.religiousKeywords or {}
local MILITARY_KEYWORDS = BlacklistData.militaryKeywords or {}

local BAD_WEATHER = BlacklistData.badWeatherCodes or {}

local QUEST_EXCEPTIONS = BlacklistData.questExceptions or {}

local SCRIPT_WHITELIST = BlacklistData.normalizedSet(BlacklistData.scriptWhitelist)
local HOSTILE_FIGHT_THRESHOLD = 80

-- Pre-built data-layer exact sets
local DATA_BLACKLISTED_INTERIORS = BlacklistData.normalizedSet(BlacklistData.blacklistedInteriors)
local DATA_SAFE_EXACT = BlacklistData.normalizedSet(BlacklistData.safeShelterExactCells)
local DATA_RELIGIOUS_EXACT = BlacklistData.normalizedSet(BlacklistData.religiousExactCells)
local DATA_TEMPLE_EXACT = BlacklistData.normalizedSet(BlacklistData.templeExactCells)
local DATA_IMPERIAL_EXACT = BlacklistData.normalizedSet(BlacklistData.imperialShrineExactCells)
local DATA_MILITARY_EXACT = BlacklistData.normalizedSet(BlacklistData.militaryExactCells)
local DATA_SHOP_EXACT = BlacklistData.normalizedSet(BlacklistData.shopExactCells)
local DATA_OBJECT_BLACKLIST = BlacklistData.normalizedSet(BlacklistData.objectBlacklistIds)

-- =============================================================================
-- Helpers
-- =============================================================================

local function getRecord(actor)
    if not actor then return nil end
    local ok, rec = pcall(function() return actor.type and actor.type.record and actor.type.record(actor) end)
    if ok and rec then return rec end
    ok, rec = pcall(function() return types and types.NPC.record(actor) end)
    return ok and rec or nil
end

local SERVICE_NAME_MAP = {
    offersBarter = "Barter",
    offersTraining = "Training",
    offersTravel = "Travel",
    offersEnchanting = "Enchanting",
    offersSpellmaking = "Spellmaking",
    offersRepair = "Repair",
}

local function hasService(rec, ...)
    if not rec then return false end
    local services = rec.services
    local offered = rec.servicesOffered
    if not services and not offered then return false end
    for _, svc in ipairs({...}) do
        if services and services[svc] then return true end
        if offered then
            local cap = SERVICE_NAME_MAP[svc]
            if cap and offered[cap] then return true end
        end
    end
    return false
end

local function normalizeCellName(cellName)
    return cellName and string.lower(tostring(cellName)) or ""
end

local function hasKeyword(lower, keywords)
    if lower == "" then return false end
    for _, kw in ipairs(keywords or {}) do
        if lower:find(string.lower(kw), 1, true) then return true end
    end
    return false
end

local function getAiStatBase(actor, statName)
    if not actor or not types.Actor or not types.Actor.stats or not types.Actor.stats.ai then
        return nil
    end
    local statAccessor = types.Actor.stats.ai[statName]
    if type(statAccessor) ~= "function" then return nil end
    local ok, stat = pcall(statAccessor, actor)
    if not ok or not stat then return nil end
    return stat.base or stat.current
end

function Blacklist.isHostileByDefault(actor)
    local rec = getRecord(actor)
    if not rec then return false end
    local fight = getAiStatBase(actor, "fight")
    return fight ~= nil and fight >= HOSTILE_FIGHT_THRESHOLD
end

--- Returns true if this NPC is a declared companion or a live follower of the player.
--- Declared companions come from CompanionDialogue JSON files; live followers are
--- queried through Follower Detection Util by CompanionDialogueLoader.
function Blacklist.isCompanion(actor, _player)
    if not actor then return false end
    local rec = getRecord(actor)
    if not rec then return false end
    local id = string.lower(rec.id or "")
    if id == "" then return false end
    if CompanionDialogueLoader.isLiveFollower(actor) then return true end
    if CompanionDialogueLoader.isDeclaredCompanionCached(id) then return true end
    return false
end

-- =============================================================================
-- Actor blacklists
-- =============================================================================

--- Returns true if this NPC should never be put to bed by the sleep system.
-- Blocks: companions, hostile NPCs, fully-banned IDs (bannedIds), sleepBannedIds,
-- GVRM NPCs, guards, publicans, and service providers (barter/travel).
function Blacklist.isSleepBlacklisted(actor)
    local rec = getRecord(actor)
    if not rec then return true end
    if Blacklist.isCompanion(actor) then return true end
    if Blacklist.isHostileByDefault(actor) then return true end
    local id = string.lower(rec.id or "")
    if BANNED_IDS[id] then return true end
    if SLEEP_BANNED_IDS[id] then return true end
    -- GVRM NPCs (pre-scheduled by an ESP) should not be touched by sleep system
    if id:find("gvrm_", 1, true) == 1 then return true end
    local cls = string.lower(rec.class or "")
    if cls == "guard" or cls == "publican" then return true end
    if hasService(rec, "offersBarter", "offersTravel") then return true end
    return false
end

--- Returns true if this NPC should never be assigned a stool/bench by the sitting system.
-- Blocks: companions, hostile NPCs, fully-banned IDs (bannedIds), sitBannedIds,
-- GVRM NPCs, guards, publicans, trader classes, and service providers (training/barter/travel).
function Blacklist.isSitBlacklisted(actor)
    local rec = getRecord(actor)
    if not rec then return true end
    if Blacklist.isCompanion(actor) then return true end
    if Blacklist.isHostileByDefault(actor) then return true end
    local id = string.lower(rec.id or "")
    if BANNED_IDS[id] then return true end
    if SIT_BANNED_IDS[id] then return true end
    -- GVRM NPCs (pre-scheduled by an ESP) should not be touched by sitting system
    if id:find("gvrm_", 1, true) == 1 then return true end

    local cls = string.lower(rec.class or "")
    if cls == "guard" or cls == "publican" or cls:find("guard") or cls:find("ordinat") or cls:find("trader") then return true end
    if hasService(rec, "offersBarter", "offersTravel", "offersTraining") then return true end
    return false
end

--- Returns true if this NPC should stay in place during conversations.
-- Others may walk to them, but they will not walk to others.
-- Checked via conversationTravelBanIds in the blacklist JSON and service providers (barter/travel).
function Blacklist.isConversationTravelBanned(actor)
    if not actor then return false end
    local rec = getRecord(actor)
    if not rec then return false end
    if Blacklist.isCompanion(actor) then return true end
    if Blacklist.isHostileByDefault(actor) then return true end
    if hasService(rec, "offersBarter", "offersTravel") then return true end
    return CONVERSATION_TRAVEL_BAN_IDS[string.lower(rec.id or "")] == true
end

--- Returns true if this NPC should not initiate walk-to interactions for dialogue.
-- This is broader than conversationTravelBanIds: it also blocks guards,
-- publicans, trainers, finer clothiers, monks, and fully-banned IDs.
function Blacklist.isConversationWalkBlacklisted(actor)
    if not actor then return true end
    if NPCState.isSleeping(actor.id) then return true end

    local rec = getRecord(actor)
    if not rec then return true end
    if Blacklist.isCompanion(actor) then return true end
    if Blacklist.isHostileByDefault(actor) then return true end
    local id = string.lower(rec.id or "")
    if BANNED_IDS[id] then return true end
    -- GVRM NPCs (pre-scheduled by an ESP) should not be pulled into activities
    if id:find("gvrm_", 1, true) == 1 then return true end

    local cls = string.lower(rec.class or "")
    if cls == "publican" or cls == "trainer" or cls == "finer clothier" or cls == "monk" then return true end
    return false
end

--- Returns true if this NPC should not participate in NPC-to-NPC conversations at all.
-- Blocks: companions, hostile NPCs, and fully-banned IDs (bannedIds).
-- For "static but talkative" use conversationTravelBanIds instead.
function Blacklist.isConversationBlacklisted(actor)
    if not actor then return true end
    local rec = getRecord(actor)
    if not rec then return true end
    if Blacklist.isCompanion(actor) then return true end
    if Blacklist.isHostileByDefault(actor) then return true end
    if BANNED_IDS[string.lower(rec.id)] then return true end
    return false
end

--- Generic actor blacklist dispatcher. If context is omitted, use schedule-style
--- conservative handling because movement is the highest-risk behavior.
function Blacklist.isActorBlacklisted(actor, context, player)
    if context == "sleep" then return Blacklist.isSleepBlacklisted(actor) end
    if context == "sit" then return Blacklist.isSitBlacklisted(actor) end
    if context == "conversation" then return Blacklist.isConversationBlacklisted(actor) end
    if context == "conversationWalk" then return Blacklist.isConversationWalkBlacklisted(actor) end
    if context == "activity" then
        return Blacklist.isHostileByDefault(actor) or Blacklist.isCompanion(actor, player)
    end
    return Blacklist.isScheduleBlacklisted(actor, player)
end

-- =============================================================================
-- Schedule blacklist (tiered check used by Scheduler and modules)
-- =============================================================================

--- Returns true if this NPC should never be managed by the schedule system.
-- Tiered: ID -> pattern -> class -> travel class -> mod -> script whitelist -> animation -> quest lock.
-- The player parameter is optional so existing callers can continue pairing this
-- with Blacklist.isQuestLocked(actor, player) explicitly.
function Blacklist.isScheduleBlacklisted(actor, player)
    if not actor then return true end
    local rec = getRecord(actor)
    if not rec then return true end
    if Blacklist.isCompanion(actor, player) then return true end
    if Blacklist.isHostileByDefault(actor) then return true end
    local id = string.lower(rec.id or "")

    -- 1. Hardcoded ID
    if BANNED_IDS[id] then return true end
    if SCHEDULE_BANNED_IDS[id] then return true end

    -- 2. Pattern match on recordId
    for _, p in ipairs(EXEMPT_PATTERNS) do
        if id:find(p, 1, true) then return true end
    end

    -- 3. Class check
    local cls = string.lower(rec.class or "")
    if EXEMPT_CLASSES[cls] then return true end

    -- 4. Travel class (global-safe; does not call .services())
    if TRAVEL_CLASSES[cls] then return true end

    -- 5. Mod source (contentFile)
    local ok, cf = pcall(function() return string.lower(actor.contentFile or "") end)
    if ok and cf and cf ~= "" and EXEMPT_MODS[cf] then return true end

    -- 6. Script whitelist: NPCs with non-whitelisted mwscripts are banned.
    -- This matches Lua NPC Schedule semantics: unknown scripted NPCs can break
    -- custom AI packages, teleport, or move unexpectedly.
    local scriptName = string.lower(rec.script or "")
    if scriptName ~= "" and not SCRIPT_WHITELIST[scriptName] then
        return true
    end

    -- 7. Animation mesh (non-humanoid)
    local ok2, model = pcall(function() return string.lower(rec.model or "") end)
    if ok2 and model and model ~= "" then
        local validAnim = false
        for _, anim in ipairs(ALLOWED_ANIMS) do
            if model:find(anim, 1, true) then validAnim = true; break end
        end
        if not validAnim then return true end
    end

    -- 8. Quest state, when a caller has player context available.
    if player and Blacklist.isQuestLocked(actor, player) then return true end

    return false
end

--- Returns true if the cell name is in the schedule whitelist.
-- Also returns true for interior sub-cells of a whitelisted city
-- (e.g. "Seyda Neen, Some House" when "Seyda Neen" is whitelisted).
function Blacklist.isCellWhitelisted(cellName)
    if not cellName then return false end
    local lower = cellName:lower()
    if NAMED_CELL_WHITELIST_LOWER[lower] == true then
        return true
    end
    -- Check if this is an interior sub-cell of a whitelisted city.
    -- Format is typically "City Name, Interior Name".
    local cityPrefix = lower:match("^(.-),%s")
    if cityPrefix then
        return NAMED_CELL_WHITELIST_LOWER[cityPrefix] == true
    end
    return false
end

--- Returns true if a cell object is whitelisted (named or grid coordinates).
function Blacklist.isCellWhitelistedObj(cell)
    if not cell then return false end
    if cell.isExterior and (not cell.name or cell.name == "") then
        local gx = cell.gridX
        local gy = cell.gridY
        for _, g in ipairs(GRID_CELL_WHITELIST) do
            if g.x == gx and g.y == gy then return true end
        end
        return false
    end
    return Blacklist.isCellWhitelisted(cell.name)
end

--- Returns true if the cell is a named city where scheduling is active.
function Blacklist.isInCity(cellName)
    if not cellName then return false end
    local lower = cellName:lower()
    return BlacklistData.cityCells[lower] == true
end

--- Returns true for Mournhold/Vivec interiors treated as exteriors by the scheduler.
function Blacklist.isOutdoorCell(cellName)
    if not cellName then return false end
    local lower = cellName:lower()
    return BlacklistData.mournholdInteriors[lower] == true
end

--- Classify an interior destination without changing current dispatch behaviour.
function Blacklist.classifyDestination(cellName)
    local lower = normalizeCellName(cellName)
    local info = {
        safe = false,
        religious = false,
        military = false,
        shop = false,
        temple = false,
        imperialShrine = false,
        blacklisted = false,
    }
    if lower == "" then return info end

    if DATA_BLACKLISTED_INTERIORS[lower] then
        info.blacklisted = true
        return info
    end

    info.temple = DATA_TEMPLE_EXACT[lower] == true
    info.imperialShrine = DATA_IMPERIAL_EXACT[lower] == true
    info.religious = DATA_RELIGIOUS_EXACT[lower] == true
        or info.temple
        or info.imperialShrine
        or hasKeyword(lower, RELIGIOUS_KEYWORDS)
        or hasKeyword(lower, BlacklistData.religiousKeywords)
    info.military = DATA_MILITARY_EXACT[lower] == true
        or hasKeyword(lower, MILITARY_KEYWORDS)
        or hasKeyword(lower, BlacklistData.militaryKeywords)
    info.shop = DATA_SHOP_EXACT[lower] == true
        or hasKeyword(lower, BlacklistData.shopKeywords)

    info.safe = DATA_SAFE_EXACT[lower] == true
        or hasKeyword(lower, SAFE_PLACE_KEYWORDS)
        or hasKeyword(lower, BlacklistData.safeShelterKeywords)

    -- Military locations are a separate category, not generic tavern/shelter.
    if info.military and not DATA_SAFE_EXACT[lower] then
        info.safe = false
    end

    return info
end

function Blacklist.isDestinationBlacklisted(cellName, context)
    local class = Blacklist.classifyDestination(cellName)
    return class.blacklisted == true
end

--- Returns true if a door's destination cell name matches a safe-place keyword.
function Blacklist.isSafePlaceDestination(cellName)
    local class = Blacklist.classifyDestination(cellName)
    return class.safe == true and not class.blacklisted
end

--- Returns true if a door's destination cell name matches a religious hub keyword.
function Blacklist.isReligiousDestination(cellName)
    local class = Blacklist.classifyDestination(cellName)
    return class.religious == true and not class.blacklisted
end

--- Returns true if a door's destination cell name matches a military keyword.
function Blacklist.isMilitaryDestination(cellName)
    local class = Blacklist.classifyDestination(cellName)
    return class.military == true and not class.blacklisted
end

function Blacklist.isShopDestination(cellName)
    local class = Blacklist.classifyDestination(cellName)
    return class.shop == true and not class.blacklisted
end

function Blacklist.isTempleDestination(cellName)
    local class = Blacklist.classifyDestination(cellName)
    return class.temple == true and not class.blacklisted
end

function Blacklist.isImperialShrineDestination(cellName)
    local class = Blacklist.classifyDestination(cellName)
    return class.imperialShrine == true and not class.blacklisted
end

function Blacklist.getDoorOverride(cellName, npcRecordId, contentFlags)
    local lowerCell = normalizeCellName(cellName)
    local lowerNpc = npcRecordId and string.lower(tostring(npcRecordId)) or nil

    local source = nil
    if contentFlags and contentFlags.bcom then
        source = BlacklistData.doorOverridesBcom
    else
        source = BlacklistData.doorOverrides
    end
    if not source then return nil end

    if lowerNpc and source.npc and source.npc[lowerNpc] then
        return source.npc[lowerNpc][lowerCell]
    end
    return source[lowerCell]
end

function Blacklist.isObjectBlacklisted(recordId, model)
    local rid = recordId and string.lower(tostring(recordId)) or ""
    local mdl = model and string.lower(tostring(model)) or ""
    if rid ~= "" and DATA_OBJECT_BLACKLIST[rid] then return true end
    if mdl ~= "" and DATA_OBJECT_BLACKLIST[mdl] then return true end
    return false
end

--- Returns true if the given weather code triggers the "bad weather" go-home condition.
function Blacklist.isWeatherTrigger(weatherCode)
    return BAD_WEATHER[weatherCode] == true
end

-- =============================================================================
-- Quest lock (dynamic — requires player object)
-- =============================================================================

-- Cache: { [npcId] = { result=bool, expiry=simulationTime } }
local _questLockCache = {}
local QUEST_LOCK_TTL = 60.0  -- seconds before re-evaluating

--- Returns true if this NPC is in an active quest stage and must not be moved.
-- actor: the NPC object
-- player: the player object (needed for quest stage access)
-- Returns false (safe to move) if quest data is unreadable.
function Blacklist.isQuestLocked(actor, player)
    if not actor or not player then return false end
    local rec = getRecord(actor)
    if not rec then return false end
    local id = string.lower(rec.id or "")

    local exceptions = QUEST_EXCEPTIONS[id]
    if not exceptions then return false end

    -- Check cache
    local now = 0
    pcall(function()
        local core = require('openmw.core')
        now = core.getSimulationTime()
    end)
    local cached = _questLockCache[id]
    if cached and cached.expiry > now then
        return cached.result
    end

    -- Evaluate all exception entries for this NPC
    local locked = false
    for _, ex in ipairs(exceptions) do
        local questOk, stage, finished = pcall(function()
            local quests = nil
            if types.Player and types.Player.quests then
                quests = types.Player.quests(player)
            end
            if not quests and player.type and player.type.quests then
                quests = player.type.quests(player)
            end
            local q = quests and quests[ex.quest]
            return q and q.stage or 0, q and q.finished == true
        end)
        if questOk and not finished then
            if stage >= ex.before and stage < ex.after then
                locked = true
                break
            end
        end
    end

    -- Cache result
    _questLockCache[id] = { result = locked, expiry = now + QUEST_LOCK_TTL }
    return locked
end

--- Invalidate the quest lock cache for a specific NPC (call on quest update events).
function Blacklist.invalidateQuestLock(npcId)
    _questLockCache[npcId] = nil
end

--- Invalidate the entire quest lock cache (call when any quest updates —
--- we don't know which NPCs are affected so wipe all cached results).
function Blacklist.invalidateAllQuestLocks()
    _questLockCache = {}
end

return Blacklist
