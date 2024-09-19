local SkillModifier = require("OtherSkills.components.SkillModifier")
local util = require("OtherSkills.util")
local config = require("OtherSkills.config")
local logger = util.createLogger("Skill")

---@class SkillsModule.Skill.constructorParams
---@field id string The unique ID of the skill
---@field name string The name of the skill
---@field maxLevel? number `Default: 100` The maximum value of the skill. The maximum value of the skill. Set to -1 for no cap
---@field icon? string `Default: "Icons/OtherSkills/default.dds"` The path to the icon of the skill
---@field description? string The description of the skill
---@field specialization? tes3.specialization The specialization of the skill
---@field value? number `Default: 5` The starting value of the skill
---@field apiVersion? number The API Version of the skill. This is automatically set depending on which API you use, so you don't need to provide this.

---@alias SkillsModule.Skill.active
---| "'active'" The skill is active
---| "'inactive'" The skill is inactive

local SPECIALIZATION_MULTI = 1.25
--Keys of values that are stored on player.data
local PERSISTENT_KEYS = {
    value = true,
    progress = true,
    active = true,
}

---The skill data stored on the reference
---@class SkillsModule.Skill.data
---@field value number The raw value of the skill
---@field progress number The current progress of the skill
---@field active SkillsModule.Skill.active Whether the skill is active or not
---@field attribute? tes3.attribute (Deprecated) The attribute of the skill
---@field apiVersion? number The API version of the skill

---@class SkillsModule.Skill : SkillsModule.Skill.constructorParams
---@field id string The unique ID of the skill
---@field name string The name of the skill
---@field private raw number The raw value stored on the reference.data. This should only ever be modified by the skill itself
---@field base number The base value of the skill, calculated by adding all base modifiers to the raw value
---@field current number The current value of the skill, calculated by adding all fortify/drain effects to the base value
---@field maxLevel number The maximum value of the skill. If set to -1, there is no cap
---@field icon string The path to the icon of the skill
---@field description string The description of the skill
---@field specialization tes3.specialization The specialization of the skill
---@field private apiVersion number The API version of the skill
---@field private persistentDefaults SkillsModule.Skill.data Data to be added to player.data.otherSkills
---@field private owner? tes3reference The NPC the skill is attached to. Defaults to the player
---@field private active SkillsModule.Skill.active Whether the skill is active or not
local Skill = {
    ---@deprecated Use skill.base or skill.current
    value = nil,

    DEFAULT_VALUES = {
        value = 5,
        progress = 0,
        active = "active",
        maxLevel = 100,
        icon = "Icons/OtherSkills/default.dds",
        description = "",
        apiVersion = 1
    },
}

local registeredSkills = {}

--- Constructor
---@param e SkillsModule.Skill.constructorParams
---@return SkillsModule.Skill|nil
function Skill:new(e)
    local params = table.copy(e)
    --Fill in defaults
    table.copymissing(params, Skill.DEFAULT_VALUES)
    --Make sure starting value is an integer
    params.value = math.round(params.value)
    --Validate params
    logger:assert(type(params) == "table", "Skill:new: data must be a table")
    logger:assert(type(params.id) == "string", "Skill:new: data.id is required")
    logger:assert(type(params.name) == "string", "Skill:new: data.name is required")

    --Data to be added to player.data.otherSkills
    params.persistentDefaults = {}
    for k, v in pairs(params) do
        if PERSISTENT_KEYS[k] then
            params.persistentDefaults[k] = v
        end
    end
    ---@type SkillsModule.Skill
    local skill = setmetatable({}, {
        ---@diagnostic disable: invisible
        ---@param tSkill SkillsModule.Skill
        __index = function(tSkill, key)
            if key == "base" then
                return tSkill:getBase()
            end
            if key == "value" or key == "current" then
                return tSkill:getCurrent()
            end
            --Get from class
            if Skill[key] ~= nil then
                return Skill[key]
            end
            --"raw" points to the data.value on the reference
            if key == "raw" then
                key = "value"
            end
            if PERSISTENT_KEYS[key] then
                tSkill:initialiseData()
                local v = config.playerData[params.id][key]
                if v ~= nil then return v end
            end
            --get from table
            return params[key]
        end,
        __newindex = function(tSkill, key, val)
            --Legacy: if ""base", then modify the raw value by the difference between the base and the new base
            if key == "base" then
                local base = tSkill:getBase()
                local diff = val - base
                tSkill.raw = tSkill.raw + diff
                return
            end
            --if value" or "current", then modify raw by difference between current and new current
            if key == "value" or key == "current" then
                local current = tSkill:getCurrent()
                local diff = val - current
                local previous = tSkill:getBase()
                tSkill.raw = tSkill.raw + diff
                return
            end
            -- "raw" points to the data.value on the reference
            if key == "raw" then
                key = "value"
            end
            -- Get from reference.data
            if PERSISTENT_KEYS[key] then
                tSkill:initialiseData()
                local skillData = config.playerData[params.id]
                skillData[key] = val
            end
            params[key] = val
            --Update UI
            if tes3ui.menuMode() then
                event.trigger("SkillsModule:UpdateSkillsList")
            end
        end,
        __tostring = function (t)
            return string.format("Skill: %s (%s) v%d", t.name, t.id, t.apiVersion)
        end
        ---@diagnostic disable: invisible
    })
    registeredSkills[params.id] = skill
    logger:debug("Registered %s", string.format("Skill: %s (%s) v%d", params.name, params.id, params.apiVersion))
    return skill
end

---Get a skill by its ID
---@param id string The unique ID of the skill
---@param owner? tes3reference The owner of the skill, defaults to the player
---@return SkillsModule.Skill|nil
function Skill.get(id, owner)
    local skill = registeredSkills[id]
    Skill.owner = owner
    return skill
end

function Skill:getApiVersion()
    return self.apiVersion or 1
end

---Get all registered skills
---@param owner nil|tes3reference
---@return table<string, SkillsModule.Skill>
function Skill.getAll(owner)
    if owner then
        Skill.owner = owner
    end
    return registeredSkills
end

function Skill.getSorted(owner)
    local skills = Skill.getAll(owner)
    local sortedSkills = table.values(skills)
    table.sort(sortedSkills, function(a, b) return a.name < b.name end)
    return sortedSkills
end

function Skill.hasActiveSkills()
    local skills = Skill.getAll()
    for _, skill in pairs(skills) do
        if skill:isActive() then
            return true
        end
    end
    return false
end

function Skill.hasActiveClassModifiers()
    local classIDs = {}
    for _, class in ipairs(tes3.dataHandler.nonDynamicData.classes) do
        classIDs[class.id:lower()] = true
    end
    for skillId, classModifiers in pairs(SkillModifier.classModifiers) do
        local skill = Skill.get(skillId)
        if skill and skill:isActive() then
            for classId, _ in pairs(classModifiers) do
                if classIDs[classId] then
                    return true
                end
            end
        end
    end
end

----------------------------------------------
-- Instance Methods
----------------------------------------------




---Exercise the skill and level up if applicable
---@param progressAmount number The amount of progress to add to the skill
---@return boolean Whether the skill levelled up or not
function Skill:exercise(progressAmount)
    logger:debug("Exercising %s skill by %s", self.name, progressAmount)
    ---@type SkillsModule.exerciseSkillEventData
    local exerciseSkillEventData = {
        skill = self,
        progress = progressAmount,
        claim = false,
        block = false,
    }
    ---@type SkillsModule.exerciseSkillEventData
    local payload = event.trigger("SkillsModule:exerciseSkill", exerciseSkillEventData, { filter = self.id })
    if payload.block then
        logger:debug("'%s' exercise blocked by event callback", self)
        return false
    end
    logger:debug("Progress increase after skill events: %s", payload.progress)
    progressAmount = payload.progress

    --Add specialization bonus
    if self.specialization == tes3.player.object.class.specialization then
        progressAmount = progressAmount * SPECIALIZATION_MULTI
        logger:debug("Specialization bonus applied, new progress increase: %s", progressAmount)
    end
    --Add progress
    self.progress = self.progress + progressAmount
    logger:debug("New Progress: %s", self.progress)

    --Level up if needed
    local progressRequirement = self:getProgressRequirement()
    logger:debug("Requires %s progress to level up", progressRequirement)
    if self.progress >= progressRequirement then
        logger:debug("Progress requirement met")
        self:levelUp()
        return true
    end
    return false
end

---Level up the skill
---@param numLevels number|nil `Default: 1` The number of levels to level up the skill
---@param source tes3.skillRaiseSource|nil `Default: tes3.skillRaiseSource.leveling` The source of the skill raise
function Skill:levelUp(numLevels, source)
    numLevels = numLevels or 1
    if self.maxLevel > 0 and self.base >= self.maxLevel then
        self.base = self.maxLevel
        self.progress = 0
        return
    end
    self.raw = self.raw + numLevels
    self.progress = 0
    tes3.playSound{ reference = tes3.player, sound = "skillraise" }
    local message = string.format( tes3.findGMST(tes3.gmst.sNotifyMessage39).value, self.name, self.base )
    tes3.messageBox( message )--"Your %s skill increased to %d."
    logger:debug("Leveled up %s skill to %s", self.name, self.base)

    ---@type SkillsModule.skillRaisedEventData
    local eventData = {
        skill = self,
        level = self.base,
        source = source or tes3.skillRaiseSource.leveling,
        claim = false,
    }
    event.trigger("SkillsModule:skillRaised", eventData, { filter = self.id })

    ---Deprecated
    event.trigger("SkillsModule:LevelUp", { skill = self, numLevels = numLevels }, { filter = self.id })
end

function Skill:getProgressAsPercentage()
    local progress = self.progress
    local progressRequirement = self:getProgressRequirement()
    return math.floor((progress / progressRequirement) * 100)
end

---@return boolean Whether the skill is active or not
function Skill:isActive()
    return self.active == "active"
end

---@param isActive boolean
function Skill:setActive(isActive)
    self.active = isActive and "active" or "inactive"
    ---@type SkillsModule.skillActiveChangedEventData
    local eventData = {
        skill = self,
        isActive = isActive,
    }
    event.trigger("SkillsModule:SkillActiveChanged", eventData, { filter = self.id })
end

---------------------------------------
-- Private functions
---------------------------------------


---@private
---@return tes3reference
function Skill:getOwner()
    return Skill.owner or tes3.player
end

---@private
---@return table<string, SkillsModule.Skill.data>|nil
function Skill:getOwnerData()
    local owner = self:getOwner()
    if not owner then
        logger:error("Tried to access `tes3.player.data.otherSkills` before tes3.player was loaded")
        return
    end
    owner.data.otherSkills = owner.data.otherSkills or {}
    return owner.data.otherSkills
end

---@private
---@param skillData SkillsModule.Skill.data
---@param newApiVersion number
function Skill:scaleProgressForV2(skillData, newApiVersion)
    local currentProgress = skillData.progress or 0
    local currentRatio = currentProgress / 100
    local currentSkillLevel = skillData.value
    local progressRequirement = (1 + currentSkillLevel) * config.mcm.fOtherSkillBonus
    local newProgress = math.floor(progressRequirement * currentRatio)
    skillData.progress = newProgress
    logger:warn("'%s' has been updated to API version %s, progress has been scaled to %s",
        self, newApiVersion, newProgress)
end

---Initialise the persistent data on the reference.data table
---@private
function Skill:initialiseData()
    local ownerData = self:getOwnerData()
    if not ownerData then
        logger:error("Unable to initialise data for %s, ownerData is nil", self.name)
        return
    end
    if ownerData[self.id] == nil then
        --initialise default values to player.data
        ownerData[self.id] = table.copy(self.persistentDefaults)
        return
    end
    ---@type SkillsModule.Skill.data
    local skillData = ownerData[self.id]
    local newApiVersion = self.apiVersion or 1
    local needsUpgradeCheck = skillData.progress > 0
        and skillData.apiVersion == nil
    if needsUpgradeCheck then
        local currentApiVersion = skillData.apiVersion or 1
        local needsUpgrade = newApiVersion > 1 and currentApiVersion == 1
        if needsUpgrade then
            self:scaleProgressForV2(skillData, newApiVersion)
        end
    end
    skillData.apiVersion = newApiVersion
end

---@private
function Skill:getProgressRequirement()
    logger:trace("Getting progress requirement for %s skill", self.name)
    if self.apiVersion == 1 then
        -- Legacy calculation had a flat progression rate
        return 100
    end
    if self.apiVersion >= 2 then
        --[[
            New calculation based on vanilla skills,
            progress needed to level up is
            1 + the current skill level
        ]]

        local progressRequirement = math.floor((1 + self.base) * config.mcm.fOtherSkillBonus)
        logger:trace("Progress requirement: %s", progressRequirement)
        return progressRequirement
    end
    logger:error("no api version set")
end

--- Use `skill.base` instead.
---@private
function Skill:getBase()
    return math.round(self.raw + SkillModifier.calculateBaseModification(self))
end

--- Use `skill.current` instead.
---@private
function Skill:getCurrent()
    logger:trace("Getting current value of %s skill", self.name)
    --Calculate modifiers and add to base value
    local fortifyEffect = SkillModifier.calculateFortifyEffect(self)
    logger:trace("fortifyEffect: %s", fortifyEffect)
    local current = self.base + fortifyEffect
    logger:trace("Current: %s", current)
    return math.round(math.max(current, 0))
end

-------------------------------------
-- Legacy functions
-------------------------------------

---@deprecated
function Skill:levelUpSkill(value)
    self:levelUp(value)
end

---@deprecated
function Skill:progressSkill(value)
    self:exercise(value)
end

---@deprecated Skill values can now be modified directly
function Skill:updateSkill(skillVals)
    local validUpdateFields = {
        name = "string",
        maxLevel = "number",
        icon = "string",
        description = "string",
        specialization = "number",
        active = "string",
    }
    for k, v in pairs(skillVals) do
        if validUpdateFields[k] then
            if type(v) == validUpdateFields[k] then
                self[k] = v
            else
                logger:error("Skill:updateSkill: %s must be a %s", k, validUpdateFields[k])
            end
        end
    end
end

return Skill