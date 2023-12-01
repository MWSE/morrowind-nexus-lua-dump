local types = require("openmw.types")
local core = require("openmw.core")
local self = require("openmw.self")

local level = types.Actor.stats.level(self)
local skills = setmetatable({}, {
    __index = function(tbl, key)
        return types.NPC.stats.skills[key](self)
    end,
})
local currentLevel = 0
local skillsValueHistory = {}


local function getSkillsValueHistory(skill_id, lvl)
    if skillsValueHistory[lvl] then
        return skillsValueHistory[lvl][skill_id]
    end
    return skillsValueHistory[level.current][skill_id]
end

local function getSkillIncreaseThisLevel(skill_id, lvl)
    if skillsValueHistory[lvl] then
        if lvl == level.current then
            local baseSkillValue = skills[skill_id].base
            return baseSkillValue - skillsValueHistory[lvl][skill_id]
        elseif lvl < level.current then
            if skillsValueHistory[lvl + 1] then
                return skillsValueHistory[lvl + 1][skill_id] - skillsValueHistory[lvl][skill_id]
            else
                return skillsValueHistory[level.current][skill_id] - skillsValueHistory[lvl][skill_id]
            end
        end
    end

    return 0
end

local function getTotalSkillIncreaseThisLevel(lvl)
    local total = 0
    for i, rec in pairs(core.stats.Skill.records) do
        local skill_id = rec.id
        total = total + getSkillIncreaseThisLevel(skill_id, lvl)
    end
    return total
end

local function resetSkillsCounter()
    for lvl = 1, currentLevel do
        if not skillsValueHistory[lvl] then
            skillsValueHistory[lvl] = {}
            for i, rec in pairs(core.stats.Skill.records) do
                local skill_id = rec.id
                skillsValueHistory[lvl][skill_id] = skills[skill_id].base
            end
        end
    end
end

local function clearData()
    skillsValueHistory = {}
    resetSkillsCounter()
    self:sendEvent("SkillProgressRecord_resetSkillsCounter_eqnx")
end

return {
    interfaceName = "SkillProgressRecord_eqnx",
    interface = {
        version = 1,
        getSkillIncreaseThisLevel = getSkillIncreaseThisLevel,
        getTotalSkillIncreaseThisLevel = getTotalSkillIncreaseThisLevel,
        getSkillValueHistory = getSkillsValueHistory,
        getLevel = level,
        clearData = clearData,
    },
    engineHandlers = {
        onLoad = function(data)
            if data then
                skillsValueHistory = data.skillsValueHistory
            end
        end,
        onSave = function()
            return { skillsValueHistory = skillsValueHistory }
        end,
        onFrame = function()
            if currentLevel ~= level.current then
                currentLevel = level.current
                resetSkillsCounter()
                self:sendEvent("SkillProgressRecord_resetSkillsCounter_eqnx")
            end
        end
    }
}
