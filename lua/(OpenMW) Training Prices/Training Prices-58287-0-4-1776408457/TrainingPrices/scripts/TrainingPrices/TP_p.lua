local self = require('openmw.self')
local core = require('openmw.core')
local types = require('openmw.types')
local storage = require('openmw.storage')
local async = require('openmw.async')
local I = require('openmw.interfaces')

local MODNAME = 'TrainingPrices'

---------------------------------------------------------------------------------- Settings ----------------------------------------------------------------------------------

I.Settings.registerPage {
    key = MODNAME,
    l10n = 'none',
    name = 'Training Prices',
    description = 'Enforce minimum training costs by manipulating the players skill',
}

I.Settings.registerGroup {
    key = 'Settings' .. MODNAME,
    page = MODNAME,
    l10n = 'none',
    name = 'General',
    permanentStorage = true,
    settings = {
        {
            key = 'MIN_PRICE',
            name = 'Minimum price',
            description = 'Base minimum gold cost for training',
            renderer = 'number',
            default = 100,
            argument = { min = 0, max = 100000 },
        },
        {
            key = 'PRICE_PER_LEVEL',
            name = 'Price per player level',
            description = 'Additional minimum cost per player skill level',
            renderer = 'number',
            default = 3,
            argument = { min = 0, max = 10000 },
        },
    },
}

local section = storage.playerSection('Settings' .. MODNAME)

---------------------------------------------------------------------------------- Training ----------------------------------------------------------------------------------

local iTrainingMod = core.getGMST('iTrainingMod')

local savedBases = {}
local trainCounts = {}
local boosted = false

I.SkillProgression.addSkillLevelUpHandler(function(skillid, source)
    if source == I.SkillProgression.SKILL_INCREASE_SOURCES.Trainer and boosted then
        trainCounts[skillid] = (trainCounts[skillid] or 0) + 1
    end
end)

local function onUiModeChanged(data)
    if data.newMode == 'Dialogue' and data.arg and not boosted then
        local record = types.NPC.record(data.arg)
        if not record.servicesOffered.Training then return end

        local minPriceBase = section:get('MIN_PRICE')
        local pricePerLevel = section:get('PRICE_PER_LEVEL')

        boosted = true
        trainCounts = {}
        savedBases = {}
        local picked = {}
        for i = 1, 3 do
            local bestId, bestVal = nil, -1
            for _, skill in pairs(core.stats.Skill.records) do
                if not picked[skill.id] then
                    local value = types.NPC.stats.skills[skill.id](data.arg).base
                    if value > bestVal then
                        bestId = skill.id
                        bestVal = value
                    end
                end
            end
            if not bestId then break end
            picked[bestId] = true
            local stat = types.NPC.stats.skills[bestId](self)
            savedBases[bestId] = stat.base
            local minPrice = minPriceBase + pricePerLevel * stat.base
            if minPrice > 0 then
                local minBase = math.ceil(minPrice / iTrainingMod)
                if stat.base < minBase then
                    stat.base = minBase
                end
            end
        end

    elseif (data.oldMode == 'Training' or data.oldMode == 'Dialogue') and data.newMode == nil and boosted then
        for id, originalBase in pairs(savedBases) do
            local stat = types.NPC.stats.skills[id](self)
            stat.base = originalBase + (trainCounts[id] or 0)
        end
        savedBases = {}
        trainCounts = {}
        boosted = false
    end
end

return {
    eventHandlers = {
        UiModeChanged = onUiModeChanged,
    },
}