local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')

if not types.Actor.isDead or not core.stats.Attribute.record or not core.stats.Skill.record('block').attribute then
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

local function onKill(data)
    totalXP = totalXP + data.xp
    local level = types.Actor.stats.level(self).current
    local requiredXP = getRequiredExperience(level)
    if totalXP >= requiredXP then
        ui.showMessage(l10n('canLevelUp'))
        core.sendGlobalEvent('EE_MLua_InitLevel', { player = self.object })
    else
        ui.showMessage(l10n('gainedXP', { gained = data.xp, required = requiredXP - totalXP }))
    end
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

return {
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