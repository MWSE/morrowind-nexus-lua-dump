local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local util = require('openmw.util')

local l10n = core.l10n('SkillFramework')

local helpers = require('scripts.SkillFramework.util.helpers')

local API_VERSION = 2

--- @enum (partial) Specialization
local Specialization = {
    Combat = 'combat',
    Magic = 'magic',
    Stealth = 'stealth',
}

--- @enum (partial) SkillIncreaseSource
local SkillIncreaseSource = {
    Book = 'book',
    Jail = 'jail',
    Trainer = 'trainer',
    Usage = 'usage',
}

--- @enum (partial) StatsWindowSubsection
local StatsWindowSubsection = {
    Arts = l10n('StatsWindow_Sub_Arts'),
    Combat = l10n('StatsWindow_Sub_Combat'),
    Crafts = l10n('StatsWindow_Sub_Crafts'),
    Language = l10n('StatsWindow_Sub_Language'),
    Magic = l10n('StatsWindow_Sub_Magic'),
    Misc = l10n('StatsWindow_Sub_Misc'),
    Movement = l10n('StatsWindow_Sub_Movement'),
    Nature = l10n('StatsWindow_Sub_Nature'),
    Social = l10n('StatsWindow_Sub_Social'),
    Theology = l10n('StatsWindow_Sub_Theology'),
}

--- @type table<string, SkillProps>
local customSkills = {}

--- @type table<string, table<string, SkillBookProps>>
local customSkillBooks = {}

--- @type table<string, { race: string, amount: number }[]>
local raceModifiers = {}

--- @type table<string, { class: string, amount: number }[]>
local classModifiers = {}

--- @type table<string, table<string, fun():number|nil>>
local dynamicModifiers = {}

--- @type table<string, table<string, boolean>>
local globalBindings = {}

--- @type table<string, table>
local personalStats = {
    --- @type table<string, SkillStat>
    skills = {},
    --- @type table<string, table<string, boolean>>
    readBooks = {},
    --- @type table<string, boolean>
    initializedSkills = {},
    --- @type table<string, table<string, number?>>
    modifierStates = {},
}

local function warn(msg)
    print('[SkillFramework API] WARNING: ' .. msg)
end

--- @return Specialization
local function getSpecialization()
    return self.type.classes.records[self.type.records[self.recordId].class].specialization
end

local handlers = {
    --- @type SkillRegisteredHandler[]
    skillRegistered = {},
    --- @type SkillUsedHandler[]
    skillUsed = {},
    --- @type SkillLevelUpHandler[]
    skillLevelUp = {},
    --- @type SkillStatChangedHandler[]
    skillStatChanged = {},
}

local function verifySkillStat(id)
    local skillRecord = customSkills[id]
    if not skillRecord then return end

    local stat = personalStats.skills[id] or {}
    if not personalStats.initializedSkills[id] then
        stat = {}
    end
    
    local selfRecord = self.type.records[self.recordId]

    if not stat.base then
        stat.base = skillRecord.startLevel

        -- Apply modifiers
        if raceModifiers[id] then
            local race = selfRecord.race:lower()
            for _, mod in ipairs(raceModifiers[id]) do
                if mod.race == race then
                    local bonus = mod.amount
                    stat.base = stat.base + bonus
                end
            end
        end
        if classModifiers[id] then
            local class = selfRecord.class:lower()
            for _, mod in ipairs(classModifiers[id]) do
                if mod.class == class then
                    local bonus = mod.amount
                    stat.base = stat.base + bonus
                end
            end
        end
    end
    
    stat.modifier = stat.modifier or 0
    stat.progress = stat.progress or 0

    stat.base = math.max(0, stat.base)
    if skillRecord.maxLevel >= 0 and stat.base > skillRecord.maxLevel then
        stat.base = skillRecord.maxLevel
    end

    stat.modified = math.max(0, stat.base + stat.modifier)

    personalStats.skills[id] = stat

    if not personalStats.initializedSkills[id] and (not self.type.isCharGenFinished or self.type.isCharGenFinished(self)) then
        personalStats.initializedSkills[id] = true
    end
end

local _pendingSkillStatChanges = {}

--- The main API module for SkillFramework.
--- Access by: `require('openmw.interfaces').SkillFramework`
--- @class API
local API = {}

--- Get the API version.
--- @return number version The API version
function API.getVersion()
    return API_VERSION
end

--- A read-only table of valid specializations.
--- @enum (partial) Specialization
API.SPECIALIZATION = util.makeReadOnly(Specialization)

--- A read-only table of valid skill increase sources.
--- @enum (partial) SkillIncreaseSource
API.SKILL_INCREASE_SOURCES = util.makeReadOnly(SkillIncreaseSource)

--- A read-only table of pre-defined stats window subsections.
--- 
--- Note that these are just suggestions meant for consistency between mods; custom subsections can be used by providing any localized string.
--- @enum (partial) StatsWindowSubsection
API.STATS_WINDOW_SUBSECTIONS = util.makeReadOnly(StatsWindowSubsection)

--- Register a new custom skill.
--- Only the name property is required; other properties will be set to defaults if not provided.
--- @param id string unique case-insensitive identifier for this skill
--- @param props SkillProps a table of skill properties
function API.registerSkill(id, props)
    id = string.lower(id)

    if not props or not props.name then
        warn('Attempted to register skill with ID "' .. id .. '" without a name. Registration aborted.')
        return
    end

    if customSkills[id] then
        warn('Skill with ID "' .. id .. '" is already registered. Overwriting.')
    end

    props.icon = props.icon or {}
    props.icon.bgr = props.icon.bgr or ('icons/SkillFramework/' .. (props.specialization or 'default') .. '_blank.dds')
    props.icon.bgrColor = props.icon.bgrColor or util.color.rgb(1, 1, 1)
    props.icon.fgr = props.icon.fgr or ('icons/SkillFramework/default.dds')
    props.icon.fgrColor = props.icon.fgrColor or util.color.rgb(1, 1, 1)

    props.skillGain = props.skillGain or {}
    props.startLevel = props.startLevel or 5
    props.maxLevel = props.maxLevel or 100
    props.xpCurve = props.xpCurve or function(currentLevel)
        return (currentLevel + 1) * core.getGMST('fMiscSkillBonus')
    end

    props.statsWindowProps = props.statsWindowProps or {}
    props.statsWindowProps.visible = props.statsWindowProps.visible == nil and true or props.statsWindowProps.visible

    customSkills[id] = props

    helpers.callEventHandlers(handlers.skillRegistered, id, API.getSkillRecord(id))
end

--- Modify a custom skill's properties.
--- Only the properties provided will be modified; other properties will remain unchanged.
--- @param id string The ID of the skill
--- @param props SkillProps A table of valid skill properties
function API.modifySkill(id, props)
    id = string.lower(id)

    if not customSkills[id] then
        warn('Attempted to modify unregistered skill with ID "' .. id .. '".')
        return
    end

    for key, value in pairs(props) do
        customSkills[id][key] = value
    end
end

--- Register a new skill book for a custom skill.
--- 
--- Multiple skills can be registered for the same book by calling this function with different `skillId`s.
--- @param bookId string the record ID of the book
--- @param skillId string the ID of the skill this book increases
--- @param props? SkillBookProps a table of skill book properties
function API.registerSkillBook(bookId, skillId, props)
    bookId = string.lower(bookId)
    skillId = string.lower(skillId)

    customSkillBooks[bookId] = customSkillBooks[bookId] or {}
    
    if customSkillBooks[bookId][skillId] then
        warn('Skill book with ID "' .. bookId .. '" is already registered for skill "' .. skillId .. '". Overwriting.')
    end

    props = props or {}
    props.skillIncrease = props.skillIncrease or 1
    props.grantSkill = (props.grantSkill == nil) and true or props.grantSkill

    customSkillBooks[bookId][skillId] = props
end

--- Registers a base modifier that is automatically applied ONCE
--- when a skill is first initialized for an actor of a specific race.
--- @param skillId string The ID of the skill
--- @param raceId string The (case-insensitive) ID of the race
--- @param amount number The amount to add to the base skill
function API.registerRaceModifier(skillId, raceId, amount)
    skillId = string.lower(skillId)
    raceId = string.lower(raceId)
    raceModifiers[skillId] = raceModifiers[skillId] or {}
    table.insert(raceModifiers[skillId], { race = raceId, amount = amount })
end

--- Registers a base modifier that is automatically applied ONCE
--- when a skill is first initialized for an actor of a specific class.
--- @param skillId string The ID of the skill
--- @param classId string The (case-insensitive) ID of the class
--- @param amount number The amount to add to the base skill
function API.registerClassModifier(skillId, classId, amount)
    skillId = string.lower(skillId)
    classId = string.lower(classId)
    classModifiers[skillId] = classModifiers[skillId] or {}
    table.insert(classModifiers[skillId], { class = classId, amount = amount })
end

--- Registers a dynamic modifier that is checked and applied every frame.
--- 
--- The callback function should return the amount to modify the skill by, or nil.
--- This amount will be added to the skill's modifier when first valid, and removed when no longer valid.
--- @param skillId string The ID of the skill to modify
--- @param modifierId string A unique ID for this modifier (used for tracking)
--- @param callback fun():number|nil A function that returns the modifier amount (nil = 0 modifier)
function API.registerDynamicModifier(skillId, modifierId, callback)
    skillId = string.lower(skillId)
    modifierId = string.lower(modifierId)

    dynamicModifiers[skillId] = dynamicModifiers[skillId] or {}

    if dynamicModifiers[skillId][modifierId] then
        warn('Dynamic modifier with ID "' .. modifierId .. '" is already registered for skill "' .. skillId .. '". Overwriting.')
    end
    dynamicModifiers[skillId][modifierId] = callback
end

--- Unregister a previously registered dynamic modifier.
--- @param skillId string the ID of the skill the modifier is for
--- @param modifierId string The ID of the modifier to unregister
function API.unregisterDynamicModifier(skillId, modifierId)
    skillId = string.lower(skillId)
    modifierId = string.lower(modifierId)

    if dynamicModifiers[skillId] then
        dynamicModifiers[skillId][modifierId] = nil
    end
end

--- Register a handler function to be called when a new skill is registered.
--- @param handler SkillRegisteredHandler Handler function
function API.addSkillRegisteredHandler(handler)
    table.insert(handlers.skillRegistered, handler)
end

--- Register a handler function to be called when a skill is used via [`skillUsed`](#apiskillused).
---
--- * Called BEFORE [`skillLevelUp`](#apiaddskillleveluphandler) and [`skillStatChanged`](#apiaddskillstatchangedhandler) handlers.
--- * Returning `false` from the handler will prevent the skill use and stop further handlers from being called.
--- @param handler SkillUsedHandler Handler function
function API.addSkillUsedHandler(handler)
    table.insert(handlers.skillUsed, handler)
end

--- Register a handler function to be called when a skill would level up via [`skillUsed`](#apiskillused) or [`skillLevelUp`](#apiskilllevelup).
---
--- * Called AFTER [`skillUsed`](#apiaddskillusedhandler) handlers but BEFORE [`skillStatChanged`](#apiaddskillstatchangedhandler) handlers.
--- * Returning `false` from the handler will prevent the level up and stop further handlers from being called.
--- @param handler SkillLevelUpHandler Handler function
function API.addSkillLevelUpHandler(handler)
    table.insert(handlers.skillLevelUp, handler)
end

--- Register a handler function to be called when a skill's stat changes by any means, including direct modification.
---
--- * Called AFTER [`skillUsed`](#apiaddskillusedhandler) and [`skillLevelUp`](#apiaddskillleveluphandler) handlers.
--- * This handler is called during `onUpdate` after the stat change occurs.
--- * Any stat changes made during the handler will trigger the handler again on the next update tick.
--- 
--- #### Warning
--- It is possible to create feedback loops if the handler modifies the skill stat unconditionally.
--- ```lua
--- API.addSkillStatChangedHandler(function(skillId)
---     if skillId == 'my_awesome_skill' then
---         API.getSkillStat(skillId).modifier = 0 -- BAD: will re-trigger handler every frame
--- 
---         -- Instead, only modify conditionally
---         local stat = API.getSkillStat(skillId)
---         if stat.modifier ~= 0 then -- GOOD: only re-trigger if modifier is not already 0
---             stat.modifier = 0
---         end
---     end
--- end)
--- ```
--- @param handler SkillStatChangedHandler Handler function
function API.addSkillStatChangedHandler(handler)
    table.insert(handlers.skillStatChanged, handler)
end

--- Get all registered custom skills.
--- @return table<string, SkillProps> records A table of read-only registered custom skill records, indexed by ID
function API.getSkillRecords()
    local records = {}
    for id, props in pairs(customSkills) do
        records[id] = helpers.makeReadOnly(props, {})
    end
    return records
end

--- Get the record for a specific custom skill.
--- @param id string The ID of the skill
--- @return SkillProps|nil record The skill's read-only record, or nil if not found
function API.getSkillRecord(id)
    id = string.lower(id)
    return customSkills[id] and helpers.makeReadOnly(customSkills[id], {}) or nil
end

--- Get all registered skill books.
--- @return table<string, table<string, SkillBookProps>> records A table of read-only registered skill book records, indexed by book ID and skill ID
function API.getSkillBookRecords()
    local records = {}
    for bookId, skillTable in pairs(customSkillBooks) do
        records[bookId] = {}
        for skillId, props in pairs(skillTable) do
            records[bookId][skillId] = helpers.makeReadOnly(props, {})
        end
    end
    return records
end

--- Get the record for a specific skill book.
--- @param bookId string The record ID of the book
--- @return table<string, SkillBookProps>|nil record A table of the book's read-only skill records, indexed by skill ID, or nil if not found
function API.getSkillBookRecord(bookId)
    bookId = string.lower(bookId)
    if not customSkillBooks[bookId] then
        return nil
    end

    local records = {}
    for skillId, props in pairs(customSkillBooks[bookId]) do
        records[skillId] = helpers.makeReadOnly(props, {})
    end
    return records
end

--- Checks if this actor has read a specific skill book for a specific skill.
--- @param bookId string The record ID of the book
--- @param skillId string The ID of the skill
--- @return boolean isRead True if the book has been read for this skill, false otherwise
function API.isSkillBookRead(bookId, skillId)
    bookId = string.lower(bookId)
    skillId = string.lower(skillId)
    return personalStats.readBooks[bookId] and personalStats.readBooks[bookId][skillId] or false
end

--- Sets the read state for a specific skill book on this actor.
--- This will not trigger a skill level up; it is for manually setting flags.
--- @param bookId string The record ID of the book
--- @param skillId string The ID of the skill
--- @param isRead? boolean True to mark as read, false or nil to mark as unread
function API.setSkillBookReadState(bookId, skillId, isRead)
    bookId = string.lower(bookId)
    skillId = string.lower(skillId)

    if isRead then
        personalStats.readBooks[bookId] = personalStats.readBooks[bookId] or {}
        personalStats.readBooks[bookId][skillId] = true
    elseif personalStats.readBooks[bookId] then
        personalStats.readBooks[bookId][skillId] = nil
        -- Clean up empty book entries
        if not next(personalStats.readBooks[bookId]) then
            personalStats.readBooks[bookId] = nil
        end
    end
end

--- Get this actor's current stat in a custom skill.
--- 
--- The returned stat table's `base`, `modifier`, and `progress` fields
--- can be modified directly. The `modified` field is read-only and will be recalculated 
--- automatically.
--- 
--- Direct modification will not trigger `skillUsed` or `skillLevelUp` handlers, but will trigger `skillStatChanged` handlers on the next update tick.
--- @param id string The ID of the skill
--- @return SkillStat|nil statInfo A table containing the skill's current stat info, or nil if the skill is not registered
function API.getSkillStat(id)
    id = string.lower(id)
    if not customSkills[id] then
        warn('Attempted to get stat of unregistered skill with ID "' .. id .. '".')
        return nil
    end
    verifySkillStat(id)
    return helpers.makeReadOnly(personalStats.skills[id], nil, { modified = true }, function(old, new)
        verifySkillStat(id)
        new = helpers.deepCopy(personalStats.skills[id])
        if not _pendingSkillStatChanges[id] then -- only trigger handler once per update if multiple fields change
            _pendingSkillStatChanges[id] = { old = old, new = new }
        else
            _pendingSkillStatChanges[id].new = new
        end 
    end)
end

--- Get the amount of XP required for this actor to level up in a custom skill.
--- @param id string The ID of the skill
--- @return number|nil xp The amount of XP required to level up, or nil if the skill is not registered
function API.getSkillProgressRequirement(id)
    id = string.lower(id)
    if not customSkills[id] then
        warn('Attempted to get level requirement of unregistered skill with ID "' .. id .. '".')
        return nil
    end
    verifySkillStat(id)
    local req = customSkills[id].xpCurve(personalStats.skills[id].base)
    if customSkills[id].specialization and getSpecialization() == customSkills[id].specialization then
        req = req * core.getGMST('fSpecialSkillBonus')
    end
    return req
end

--- Notify the API that this actor has used a custom skill.
--- @param id string The ID of the skill
--- @param options SkillUseOptions A table of options
function API.skillUsed(id, options)
    if #handlers.skillUsed == 0 then
        return
    end

    id = string.lower(id)
    local skillRecord = API.getSkillRecord(id)
    if not skillRecord then
        warn('Attempted to use unregistered skill with ID "' .. id .. '".')
        return
    end
    verifySkillStat(id)

    options = helpers.shallowCopy(options or {})
    if options.useType and not skillRecord.skillGain[options.useType] then
        warn('Attempted to use skill "' .. id .. '" with invalid useType: ' .. tostring(options.useType))
        return
    end

    if not options.skillGain then
        if not options.useType then
            warn('Attempted to use skill "' .. id .. '" without skillGain or useType.')
            return
        end
        options.skillGain = skillRecord.skillGain[options.useType]
        
        if options.scale then
            options.skillGain = options.skillGain * options.scale
        end
    end

    helpers.callEventHandlers(handlers.skillUsed, id, options)
end

--- Force this actor to level up in a custom skill.
--- @param id string The ID of the skill
--- @param source SkillIncreaseSource The source of the skill increase
--- @param amount? number The amount to increase the skill by (default: 1)
function API.skillLevelUp(id, source, amount)
    if #handlers.skillLevelUp == 0 then
        return
    end

    id = string.lower(id)
    local skillRecord = API.getSkillRecord(id)
    if not skillRecord then
        warn('Attempted to level up unregistered skill with ID "' .. id .. '".')
        return
    end
    verifySkillStat(id)

    local levelUpProgress = 0
    local levelUpAttributeIncreaseValue = core.getGMST('iLevelupMiscMultAttriubte') -- yes, that's the actual GMST name, don't fix typo

    amount = amount or 1

    local options = {}
    if source == SkillIncreaseSource.Jail then
        options.skillIncreaseValue = -amount
    else
        options.skillIncreaseValue = amount
        options.levelUpProgress = levelUpProgress * amount
        options.levelUpAttribute = skillRecord.attribute
        options.levelUpAttributeIncreaseValue = levelUpAttributeIncreaseValue * amount
        options.levelUpSpecialization = skillRecord.specialization
        options.levelUpSpecializationIncreaseValue = core.getGMST('iLevelupSpecialization') * amount
    end

    helpers.callEventHandlers(handlers.skillLevelUp, id, source, options)
end

--- Helper function to calculate the stat factor for a custom skill, based on level, attribute, and luck.
--- 
--- Based on Morrowind's default skill factor calculation:
--- `factor = skill + (attribute * 0.2) + (luck * 0.1)`
--- @param id string The ID of the skill
--- @param attribute? string The attribute to consider for the calculation (if different from the skill's governing attribute). Set to `false` to ignore attribute bonus.
--- @return number? factor The stat factor, or nil if the skill is not registered
function API.calcStatFactor(id, attribute)
    id = string.lower(id)
    local skillRecord = API.getSkillRecord(id)
    if not skillRecord then
        warn('Attempted to calculate stat factor of unregistered skill with ID "' .. id .. '".')
        return nil
    end
    verifySkillStat(id)

    if attribute == nil then
        attribute = skillRecord.attribute
    end

    local factor = personalStats.skills[id].modified

    if attribute then
        local attrValue = self.type.stats.attributes[attribute](self).modified
        factor = factor + attrValue * 0.2
    end

    factor = factor + self.type.stats.attributes.luck(self).modified * 0.1

    return factor
end

local FATIGUE_BASE = core.getGMST('fFatigueBase')
local FATIGUE_MULT = core.getGMST('fFatigueMult')
local FATIGUE_STAT = self.type.stats.dynamic.fatigue(self)
--- Helper function to calculate the fatigue factor for this actor.
--- 
--- Based on Morrowind's default fatigue factor calculation:
--- `factor = fFatigueBase - fFatigueMult * (1 - (currentFatigue / baseFatigue))`
---
--- Example usage:
--- ```lua
--- local statFactor = API.calcStatFactor('mySkill')
--- local fatigueFactor = API.calcFatigueFactor()
--- local taskDifficulty = 30
--- local successChance = statFactor * fatigueFactor - taskDifficulty
--- ```
--- @return number factor The fatigue factor
function API.calcFatigueFactor()
    local normalizedFatigue
    if FATIGUE_STAT.base == 0 then
        normalizedFatigue = 1
    else
        normalizedFatigue = math.max(0, FATIGUE_STAT.current / FATIGUE_STAT.base)
    end

    return FATIGUE_BASE - FATIGUE_MULT * (1 - normalizedFatigue)
end

local function updateGlobal(globalId, value)
    core.sendGlobalEvent('SF_UpdateGlobal', {
        player = self,
        global = globalId,
        value = value,
    })
end

--- Bind an MWScript global variable to the modified value of a custom skill for this actor (players only).
--- 
--- The global variable will be updated automatically whenever the skill's modified value changes.
--- @param globalId string The ID of the global variable to bind
--- @param skillId string The ID of the skill to bind to
function API.bindGlobal(globalId, skillId)
    if self.type ~= types.Player then return end

    globalId = string.lower(globalId)
    skillId = string.lower(skillId)

    -- Check if this global is already bound to a different skill and remove the old binding
    for sId, gTable in pairs(globalBindings) do
        if gTable[globalId] and sId ~= skillId then
            warn('Global variable "' .. globalId .. '" is already bound to skill "' .. sId .. '". Overwriting.')
            gTable[globalId] = nil
        end
    end

    globalBindings[skillId] = globalBindings[skillId] or {}
    globalBindings[skillId][globalId] = true

    local stat = API.getSkillStat(skillId)
    if stat then
        updateGlobal(globalId, stat.modified)
    end
end

--- Unbind an MWScript global variable.
--- This will also set the global's value to 0.
--- @param globalId string The ID of the global variable to unbind
function API.unbindGlobal(globalId)
    if self.type ~= types.Player then return end

    globalId = string.lower(globalId)

    local found = false
    for skillId, gTable in pairs(globalBindings) do
        if gTable[globalId] then
            gTable[globalId] = nil
            found = true
            
            if not next(gTable) then
                globalBindings[skillId] = nil
            end
        end
    end

    if found then
        updateGlobal(globalId, 0)
    end
end

API.addSkillStatChangedHandler(function(skillId, _, newStat)
    if globalBindings[skillId] then
        for globalId in pairs(globalBindings[skillId]) do
            updateGlobal(globalId, newStat.modified)
        end
    end
end)

local function onSave()
    return {
        personalStats = personalStats,
    }
end

local function onLoad(data)
    if data.personalStats then
        personalStats = data.personalStats
        personalStats.skills = personalStats.skills or {}
        personalStats.readBooks = personalStats.readBooks or {}
        personalStats.initializedSkills = personalStats.initializedSkills or {}
        personalStats.modifierStates = personalStats.modifierStates or {}
    end
end

local function onUpdate()
    local changesToProcess = _pendingSkillStatChanges
    _pendingSkillStatChanges = {}

    for id, change in pairs(changesToProcess) do
        helpers.callEventHandlers(handlers.skillStatChanged, id, change.old, change.new)
    end

    personalStats.modifierStates = personalStats.modifierStates or {}

    for skillId, callbacks in pairs(dynamicModifiers) do
        local stat = API.getSkillStat(skillId)
        if not stat then goto continue end

        personalStats.modifierStates[skillId] = personalStats.modifierStates[skillId] or {}
        
        for modId, callback in pairs(callbacks) do
            local newValue = callback() or 0
            local oldValue = personalStats.modifierStates[skillId][modId] or 0

            if newValue ~= oldValue then
                local delta = newValue - oldValue
                stat.modifier = stat.modifier + delta
                personalStats.modifierStates[skillId][modId] = newValue
            end
        end

        ::continue::
    end

    for skillId, states in pairs(personalStats.modifierStates) do
        local stat = API.getSkillStat(skillId)
        if not stat then goto continue end

        for modId, state in pairs(states) do
            if not dynamicModifiers[skillId] or not dynamicModifiers[skillId][modId] then
                stat.modifier = stat.modifier - (state or 0)
                personalStats.modifierStates[skillId][modId] = nil
            end
        end

        ::continue::
    end
end

return {
    interface = API,
    onSave = onSave,
    onLoad = onLoad,
    onUpdate = onUpdate,
}