local types = require('openmw.types')
local self = require('openmw.self')

local QUEST_DB = {}

-- Any script can call this to add more quests to the list
local function registerQuests(questList)
    if not questList then return end
    print("[Completionist] Registering " .. #questList .. " quests...")
    for _, quest in ipairs(questList) do
        table.insert(QUEST_DB, quest)
    end
    print("[Completionist] Total quests in DB: " .. #QUEST_DB)
end

-- =============================================================================
-- LOGIC
-- =============================================================================
local state = { manualCompletion = {} }

local function checkQuestStatus(questLog, questIdString)
    -- Manual override check takes priority
    if state.manualCompletion[questIdString] then return true end
    if not questLog then return false end

    -- 1. Split by Hyphen (-). Represents OR logic.
    -- If ANY of the groups (segments) here is valid, the function returns true.
    -- Example: "QuestA - QuestB" checks if A is done OR if B is done.
    for group in string.gmatch(questIdString, "([^-]+)") do
        
        local groupIsComplete = true
        local hasIdInGroup = false

        -- 2. Split by Comma (,) within the current group. Represents AND logic.
        -- ALL IDs inside this specific group must be complete.
        for id in string.gmatch(group, "([^,]+)") do
            hasIdInGroup = true
            
            -- Trim leading/trailing whitespace (crucial for "A - B" spacing)
            local cleanId = id:match("^%s*(.-)%s*$") 
            
            local quest = questLog[cleanId]

            -- Check if quest is missing, unfinished, or stage < 100
            if not (quest and (quest.finished or quest.stage >= 100)) then
                groupIsComplete = false
                break -- If one ID fails in this group, the whole group is invalid.
            end
        end

        -- If the group had IDs and passed all checks (AND logic satisfied)
        if hasIdInGroup and groupIsComplete then
            return true -- Found a valid scenario! No need to check other OR-groups.
        end
    end

    -- If all OR-groups failed
    return false
end

local function toggleManualCompletion(questId)
    state.manualCompletion[questId] = not state.manualCompletion[questId]
end

local function getGlobalProgress()
    if not self then return 0, #QUEST_DB, 0 end
    local questLog = types.Player.quests(self)
    local total = #QUEST_DB
    local completed = 0
    for _, q in ipairs(QUEST_DB) do
        if checkQuestStatus(questLog, q.id) then
            completed = completed + 1
        end
    end
    local percent = (total > 0) and math.floor((completed / total) * 100) or 0
    return completed, total, percent
end

local function getCategories()
    print("[Completionist] Getting categories. DB Size: " .. #QUEST_DB) -- [DEBUG]
    local cats = {}
    local seen = {}
    for _, q in ipairs(QUEST_DB) do
        if q.category and not seen[q.category] then
            table.insert(cats, q.category)
            seen[q.category] = true
        end
    end
    table.sort(cats)
    return cats
end

local function getGroupedQuests(category)
    local groups = {}
    local subMap = {}
    for _, q in ipairs(QUEST_DB) do
        if q.category == category then
            local sub = q.subcategory or "General"
            if not subMap[sub] then
                subMap[sub] = { name = sub, quests = {} }
                table.insert(groups, subMap[sub])
            end
            table.insert(subMap[sub].quests, q)
        end
    end
    table.sort(groups, function(a, b) return a.name < b.name end)
    for _, group in ipairs(groups) do
        table.sort(group.quests, function(a, b) return a.name < b.name end)
    end
    return groups
end

return {
    registerQuests = registerQuests,
    QUEST_DB = QUEST_DB,
    checkQuestStatus = checkQuestStatus,
    toggleManualCompletion = toggleManualCompletion,
    getGlobalProgress = getGlobalProgress,
    getCategories = getCategories,
    getGroupedQuests = getGroupedQuests
}