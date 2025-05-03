local core = require('openmw.core')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')

if core.API_REVISION < 71 then
    ui.showMessage('Morrowland Uncapped Attributes is incompatible with this version of OpenMW')
    return
end

local l10n = core.l10n('eemlua')
local registerLevelUp = require('scripts.eemlua.ui').registerLevelUp

local totalXP = 0
local enduranceMult = core.getGMST('fLevelUpHealthEndMult')

local function getRequiredExperience(level)
    if level < 1 then
        return 0
    end
    return (50 * level + 150) * level
end

local function canLevelUp()
    local level = types.Actor.stats.level(self).current
    local requiredXP = getRequiredExperience(level)
    return totalXP >= requiredXP
end

local function onInit()
    local level = types.Actor.stats.level(self).current
    local minXP = getRequiredExperience(level - 1)
    totalXP = math.max(totalXP, minXP)
end

local function levelUp(attributes, skills)
    local stats = types.Player.stats

    for id, increase in pairs(attributes) do
        local stat = stats.attributes[id](self)
        stat.base = stat.base + increase
    end

    for id, increase in pairs(skills) do
        local stat = stats.skills[id](self)
        stat.base = stat.base + increase
    end

    local health = stats.dynamic.health(self)
    local percentage = health.current / health.base
    local bonus = enduranceMult * stats.attributes.endurance(self).base
    health.base = health.base + bonus
    health.current = health.base * percentage

    local level = stats.level(self)
    level.current = level.current + 1
end

registerLevelUp(self, canLevelUp, levelUp)

-- Block skill progression
I.SkillProgression.addSkillUsedHandler(function(skillid, options)
    return false
end)

local blacklist = {}

local function blacklistHandler(actor, xp)
    if blacklist[actor.recordId] then
        return false
    end
    return xp
end

local function getExperience(actor, xp)
    if xp ~= nil then
        return xp
    end
    if types.Creature.objectIsInstance(actor) then
        local health = types.Actor.stats.dynamic.health(actor).base
        if health >= 2 then
            return math.floor(health / 2)
        end
        local level = types.Actor.stats.level(actor).current
        return 5 * level
    end
    local level = types.Actor.stats.level(actor).current
    return 5 * level + 15
end

local actorHandlers = {
    getExperience,
    blacklistHandler
}

local function onKill(data)
    if not data.actor:isValid() then
        print('Killed invalid actor', data.actor)
        return
    end
    local xp = nil
    for i = #actorHandlers, 1, -1 do
        xp = actorHandlers[i](data.actor, xp)
        if xp == false then
            return
        end
    end
    if xp == nil then
        return
    end
    totalXP = totalXP + xp
    local level = types.Actor.stats.level(self).current
    local requiredXP = getRequiredExperience(level)
    if totalXP >= requiredXP then
        ui.showMessage(l10n('canLevelUp'))
        core.sendGlobalEvent('EE_MLua_InitLevel', { player = self.object })
    else
        ui.showMessage(l10n('gainedXP', { gained = xp, required = requiredXP - totalXP }))
    end
end

return {
    interfaceName = 'EE_MLUA',
    interface = {
        version = 1,
        --- Add the given record ID to the blacklist.
        -- By default, no experience will be awarded for blacklisted actors.
        -- @function addToBlacklist
        -- @param #string recordId The record ID
        addToBlacklist = function(recordId)
            blacklist[recordId] = true
        end,
        --- Remove the given record ID from the blacklist.
        -- @function removeFromBlacklist
        -- @param #string recordId The record ID
        removeFromBlacklist = function(recordId)
            blacklist[recordId] = nil
        end,
        --- Add a custom experience calculator.
        -- If `calculator(actor, xp)` return `false`, no further calculator will be invoked and the player will not receive any experience.
        -- `calculator(actor, xp)` should return the amount of experience to award the player for the given actor.
        -- The `xp` parameter is the output of the any previous calculations.
        -- @function addExperienceCalculator
        -- @param #function calculator The experience calculator
        addExperienceCalculator = function(calculator)
            table.insert(actorHandlers, calculator)
        end
    },
    engineHandlers = {
        onSave = function()
            return {
                xp = totalXP
            }
        end,
        onLoad = function(data)
            if data ~= nil and data.xp ~= nil then
                totalXP = data.xp
            end
            onInit()
        end,
        onInit = onInit
    },
    eventHandlers = {
        EE_MLua_Kill = onKill
    }
}