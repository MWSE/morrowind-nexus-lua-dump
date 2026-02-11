local types = require('openmw.types')
local self = require('openmw.self')

-- =============================================================================
-- CONSTANTS & CONFIG
-- =============================================================================

local UPDATE_INTERVAL = 1.0 

-- =============================================================================
-- STATE & DATA STRUCTURES
-- =============================================================================

local SKILL_DB = {}         
local ATTRIBUTE_INDEX = {}  
local ALL_ATTRIBUTES = {}   
local ATTRIBUTE_NAMES = {}  

local classConfig = { major = {}, minor = {}, loaded = false }
local timeSinceLastUpdate = 0

local state = {
    currentLevel = 1,
    startSkills = {} 
}

-- =============================================================================
-- PRIVATE HELPERS
-- =============================================================================

local function getBaseSkill(skillId)
    if not self then return 0 end
    local skillStat = types.NPC.stats.skills[skillId]
    if skillStat then
        return skillStat(self).base
    end
    return 0
end

local function isCharGenFinished()
    if not types.Player or not types.Player.quests then 
        return true 
    end
    
    -- "a1_1_findspymaster" begins immediately after receiving the papers
    -- and exiting the Census and Excise Office.
    local quests = types.Player.quests(self)
    local mainQuest = quests['a1_1_findspymaster']
    
    if mainQuest and mainQuest.stage >= 1 then
        return true
    end
    
    return false
end

local function calculateMultiplier(count)
    if count <= 0 then return 1 end
    if count >= 1 and count <= 4 then return 2 end
    if count >= 5 and count <= 7 then return 3 end
    if count >= 8 and count <= 9 then return 4 end
    return 5 
end

local function sortAttributeLists()
    table.sort(ALL_ATTRIBUTES)
    for _, list in pairs(ATTRIBUTE_INDEX) do
        table.sort(list, function(a, b) return a.name < b.name end)
    end
end

local function loadClassData()
    if classConfig.loaded then return end
    if not self then return end

    local record = types.NPC.record(self)
    local classId = record.class
    local classData = nil

    if types.NPC.classes then
        pcall(function() classData = types.NPC.classes.record(classId) end)
    end

    if classData then
        classConfig.major = {}
        classConfig.minor = {}
        
        for _, s in ipairs(classData.majorSkills or {}) do
            classConfig.major[string.lower(s)] = true
        end
        for _, s in ipairs(classData.minorSkills or {}) do
            classConfig.minor[string.lower(s)] = true
        end
        
        classConfig.loaded = true
    end
end

local function resetTrackers(newLevel)
    state.currentLevel = newLevel
    for _, skill in ipairs(SKILL_DB) do
        state.startSkills[skill.id] = getBaseSkill(skill.id)
    end
end

-- =============================================================================
-- CORE LOGIC
-- =============================================================================

local function checkLevelUp()
    if not self then return end
    local currentLevel = types.Actor.stats.level(self).current
    
    if currentLevel > state.currentLevel then
        resetTrackers(currentLevel)
    elseif currentLevel < state.currentLevel then
        -- Handle rare edge cases where level might decrease
        state.currentLevel = currentLevel
    end
end

local function getAttributeProgress(attributeKey)
    if not classConfig.loaded then loadClassData() end

    local totalUps = 0
    local skillDetails = {}
    
    if ATTRIBUTE_INDEX[attributeKey] then
        for _, skill in ipairs(ATTRIBUTE_INDEX[attributeKey]) do
            local currentVal = getBaseSkill(skill.id)
            local startVal = state.startSkills[skill.id] or currentVal
            local diff = math.max(0, currentVal - startVal)
            
            if diff > 0 then
                totalUps = totalUps + diff
            end
            
            local sId = string.lower(skill.id)
            local isClass = classConfig.major[sId] or classConfig.minor[sId]

            table.insert(skillDetails, {
                id = skill.id,
                name = skill.name,
                start = startVal,
                current = currentVal,
                diff = diff,
                isClassSkill = isClass
            })
        end
    end
    return totalUps, skillDetails
end

local function getLevelProgress()
    if not classConfig.loaded then loadClassData() end
    
    local progress = 0
    for _, skill in ipairs(SKILL_DB) do
        local id = string.lower(skill.id)
        if classConfig.major[id] or classConfig.minor[id] then
            local current = getBaseSkill(skill.id)
            local start = state.startSkills[skill.id] or current
            local diff = math.max(0, current - start)
            progress = progress + diff
        end
    end
    return math.min(10, progress)
end

-- =============================================================================
-- PUBLIC API & HANDLERS
-- =============================================================================

local function registerData(data)
    if not data or not data.skills then return end

    -- Check if this is a fresh start (no saved data)
    local isNewGame = (next(state.startSkills) == nil)

    ATTRIBUTE_NAMES = data.attributes or {}
    
    for _, skill in ipairs(data.skills) do
        if not ATTRIBUTE_INDEX[skill.attribute] then
            ATTRIBUTE_INDEX[skill.attribute] = {}
            table.insert(ALL_ATTRIBUTES, skill.attribute)
        end
        table.insert(ATTRIBUTE_INDEX[skill.attribute], skill)
        table.insert(SKILL_DB, skill)
        
        -- Initialize start skill only if not present (preserve save data)
        if state.startSkills[skill.id] == nil then
            state.startSkills[skill.id] = getBaseSkill(skill.id)
        end
    end
    
    if self then
        local lvl = types.Actor.stats.level(self).current
        
        -- Force reset if:
        -- 1. It is a new game at level 1 (ignores partial progress from char creation)
        -- 2. Character generation is not yet finished (quest stage check)
        if (lvl == 1 and isNewGame) or not isCharGenFinished() then
            resetTrackers(lvl)
        elseif lvl > state.currentLevel then 
            -- Update tracker if installing mid-playthrough
            state.currentLevel = lvl 
        end
    end
    
    sortAttributeLists()
    loadClassData() 
end

local function onUpdate(dt)
    timeSinceLastUpdate = timeSinceLastUpdate + dt
    if timeSinceLastUpdate >= UPDATE_INTERVAL then
        
        if not isCharGenFinished() then
            -- During character generation, constantly synchronize trackers
            -- to absorb race/class bonuses into the base "start" value.
            resetTrackers(state.currentLevel)
        elseif #SKILL_DB > 0 then 
            -- Normal gameplay loop
            checkLevelUp() 
        end
        
        timeSinceLastUpdate = 0
    end
end

local function onSave()
    return { currentLevel = state.currentLevel, startSkills = state.startSkills }
end

local function onLoad(data)
    if data then
        state.currentLevel = data.currentLevel or 1
        state.startSkills = data.startSkills or {}
    end
end

return {
    registerData = registerData,
    getAttributeProgress = getAttributeProgress,
    getLevelProgress = getLevelProgress, 
    getMultiplier = calculateMultiplier, 
    getAttributes = function() return ALL_ATTRIBUTES end,
    getAttributeName = function(key) return ATTRIBUTE_NAMES[key] or key end,
    onSave = onSave,
    onLoad = onLoad,
    onUpdate = onUpdate
}