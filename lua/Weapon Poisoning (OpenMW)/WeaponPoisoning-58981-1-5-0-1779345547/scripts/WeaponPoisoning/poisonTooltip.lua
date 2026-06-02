local core = require('openmw.core')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')

local l10n = core.l10n('WeaponPoisoning')

local PoisonTooltip = {}

local function affectedStatName(effect)
    if effect.affectedAttribute then
        local record = core.stats.Attribute.records[effect.affectedAttribute]
        return record and record.name or tostring(effect.affectedAttribute)
    elseif effect.affectedSkill then
        local record = core.stats.Skill.records[effect.affectedSkill]
        return record and record.name or tostring(effect.affectedSkill)
    end
    return nil
end

local function formatMagnitude(effect)
    local minMagnitude = effect.magnitudeMin or effect.magnitude or effect.magnitudeMax
    local maxMagnitude = effect.magnitudeMax or effect.magnitude or effect.magnitudeMin
    if not minMagnitude and not maxMagnitude then
        return nil
    end
    if minMagnitude == maxMagnitude then
        return tostring(minMagnitude)
    end
    return tostring(minMagnitude or 0) .. '-' .. tostring(maxMagnitude or 0)
end

function PoisonTooltip.formatPoisonEffect(effect)
    local effectRecord = core.magic.effects.records[effect.id]
    local effectName = effectRecord and effectRecord.name or tostring(effect.id)
    local statName = affectedStatName(effect)
    local text = statName and (effectName .. ' ' .. statName) or effectName

    local magnitude = formatMagnitude(effect)
    if magnitude then
        text = text .. ': ' .. magnitude
    end

    if effect.duration and effect.duration > 0 then
        text = text .. ' ' .. l10n('PoisonEffectDuration', { duration = effect.duration })
    end

    return text
end

function PoisonTooltip.addPoisonEffectRows(innerContent, poisonRecord)
    if not poisonRecord or not poisonRecord.effects then
        return
    end

    innerContent:add({
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textHeader,
        props = {
            text = poisonRecord.name,
            autoSize = true,
        },
    })

    for _, effect in ipairs(poisonRecord.effects) do
        local effectRecord = core.magic.effects.records[effect.id]
        innerContent:add({
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                autoSize = true,
            },
            content = ui.content {
                effectRecord and {
                    type = ui.TYPE.Image,
                    props = {
                        size = util.vector2(16, 16),
                        resource = ui.texture { path = effectRecord.icon },
                    },
                } or {},
                effectRecord and { template = I.MWUI.templates.interval } or {},
                {
                    type = ui.TYPE.Text,
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = PoisonTooltip.formatPoisonEffect(effect),
                        autoSize = true,
                    },
                },
            },
        })
    end
end

return PoisonTooltip
