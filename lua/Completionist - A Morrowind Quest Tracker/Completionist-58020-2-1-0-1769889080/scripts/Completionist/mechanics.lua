local types = require('openmw.types')
local self = require('openmw.self')

-- =============================================================================
-- DATA STORAGE & INDEXING
-- =============================================================================
local QUEST_DB = {}             -- Linear list of all quests
local CATEGORY_INDEX = {}       -- Map: Category Name -> List of Quest Objects
local ALL_CATEGORIES = {}       -- Sorted list of all unique category names

local MASTERS_LIST = {}         -- Sorted list of unique Master names
local MASTER_TO_CATEGORIES = {} -- Map: Master Name -> List of Category Names

local state = {
    manualCompletion = {}
}

-- =============================================================================
-- LOGIC PARSING
-- =============================================================================

-- Parses complex ID strings into a structured logic table.
-- Format: "ID1, ID2 - ID3" means (ID1 AND ID2) OR ID3
local function parseQuestLogic(logicString)
    local logicGroups = {}
    -- Split by "OR" (-)
    for groupStr in string.gmatch(logicString, "([^-]+)") do
        local requiredIds = {}
        -- Split by "AND" (,)
        for id in string.gmatch(groupStr, "([^,]+)") do
            local cleanId = id:match("^%s*(.-)%s*$")
            if cleanId and cleanId ~= "" then
                table.insert(requiredIds, cleanId)
            end
        end
        if #requiredIds > 0 then
            table.insert(logicGroups, requiredIds)
        end
    end
    return logicGroups
end

-- Sorts all cached lists for consistent UI display
local function sortDataStructures()
    table.sort(ALL_CATEGORIES)
    table.sort(MASTERS_LIST)
    
    for _, catList in pairs(MASTER_TO_CATEGORIES) do
        table.sort(catList)
    end

    -- Sort quests within categories by subcategory, then by name
    for _, list in pairs(CATEGORY_INDEX) do
        table.sort(list, function(a, b) 
            if a.subcategory == b.subcategory then
                return a.name < b.name
            end
            return a.subcategory < b.subcategory
        end)
    end
end

-- =============================================================================
-- PUBLIC API
-- =============================================================================

local function registerQuests(questList)
    if not questList then return end
    print("[Completionist] Registering " .. #questList .. " quests...")
    
    local masterSet = {}
    local masterCategorySet = {} 

    for _, quest in ipairs(questList) do
        if quest.id and quest.category then
            -- Pre-compile logic for fast status checking
            quest._logicCache = parseQuestLogic(quest.id)
            
            -- Defaults
            quest.master = quest.master or "Morrowind"
            quest.subcategory = quest.subcategory or "General"

            -- 1. Global Category Indexing
            if not CATEGORY_INDEX[quest.category] then
                CATEGORY_INDEX[quest.category] = {}
                table.insert(ALL_CATEGORIES, quest.category)
            end
            table.insert(CATEGORY_INDEX[quest.category], quest)

            -- 2. Master Indexing
            if not masterSet[quest.master] then
                masterSet[quest.master] = true
                table.insert(MASTERS_LIST, quest.master)
                MASTER_TO_CATEGORIES[quest.master] = {}
                masterCategorySet[quest.master] = {}
            end

            -- 3. Master -> Category Mapping
            if not masterCategorySet[quest.master][quest.category] then
                masterCategorySet[quest.master][quest.category] = true
                table.insert(MASTER_TO_CATEGORIES[quest.master], quest.category)
            end

            table.insert(QUEST_DB, quest)
        end
    end
    
    sortDataStructures()
end

local function checkQuestStatus(questLog, questObj)
    if state.manualCompletion[questObj.id] then return true end
    if not questLog then return false end

    -- Iterate over pre-compiled logic groups
    for _, group in ipairs(questObj._logicCache) do
        local groupIsComplete = true
        for _, id in ipairs(group) do
            local logEntry = questLog[id]
            -- Quest is incomplete if entry doesn't exist, isn't finished, or stage < 100
            if not (logEntry and (logEntry.finished or logEntry.stage >= 100)) then
                groupIsComplete = false
                break
            end
        end
        if groupIsComplete then return true end
    end
    return false
end

local function toggleManualCompletion(questId)
    state.manualCompletion[questId] = not state.manualCompletion[questId]
    if not state.manualCompletion[questId] then
        state.manualCompletion[questId] = nil -- Keep state clean
    end
end

local function getGlobalProgress(masterFilter)
    if not self then return 0, #QUEST_DB, 0 end
    local questLog = types.Player.quests(self)
    
    local total = 0
    local completed = 0
    
    for _, q in ipairs(QUEST_DB) do
        if not masterFilter or q.master == masterFilter then
            total = total + 1
            if checkQuestStatus(questLog, q) then
                completed = completed + 1
            end
        end
    end
    
    local percent = (total > 0) and math.floor((completed / total) * 100) or 0
    return completed, total, percent
end

-- Returns categories belonging to a specific Master (or all if no filter)
local function getCategories(masterFilter)
    if masterFilter then
        return MASTER_TO_CATEGORIES[masterFilter] or {}
    end
    return ALL_CATEGORIES
end

local function getMasters()
    return MASTERS_LIST
end

-- Returns quests for a specific category, strictly filtered by Master
local function getGroupedQuests(category, masterFilter)
    local groups = {}
    if not category or not CATEGORY_INDEX[category] then return groups end
    
    local rawList = CATEGORY_INDEX[category]
    local currentSub = nil
    local currentGroup = nil
    
    for _, q in ipairs(rawList) do
        -- Strict filter: Ensure quest belongs to the selected Master
        if not masterFilter or q.master == masterFilter then
            if q.subcategory ~= currentSub then
                currentSub = q.subcategory
                currentGroup = { name = currentSub, quests = {} }
                table.insert(groups, currentGroup)
            end
            table.insert(currentGroup.quests, q)
        end
    end
    
    return groups
end

-- =============================================================================
-- PERSISTENCE
-- =============================================================================

local function onSave()
    return { manualCompletion = state.manualCompletion }
end

local function onLoad(data)
    if data then
        state.manualCompletion = data.manualCompletion or {}
    end
    print("[Completionist] State loaded.")
end

return {
    registerQuests = registerQuests,
    checkQuestStatus = checkQuestStatus,
    toggleManualCompletion = toggleManualCompletion,
    getGlobalProgress = getGlobalProgress,
    getCategories = getCategories,
    getMasters = getMasters,
    getGroupedQuests = getGroupedQuests,
    onSave = onSave,
    onLoad = onLoad
}