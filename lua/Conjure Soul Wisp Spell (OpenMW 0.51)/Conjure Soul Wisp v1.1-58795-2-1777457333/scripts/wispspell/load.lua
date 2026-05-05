local content = require('openmw.content')
local common = require('scripts.wispspell.common')

local controlTemplate = content.magicEffects.records.chameleon
    or content.magicEffects.records.sanctuary
    or content.magicEffects.records.summonscamp

content.magicEffects.records[common.effectId] = {
    template = controlTemplate,
    name = 'Conjure Soul Wisp',
    description = 'Summons a Soul Wisp. Effects placed below this effect in the spell are applied by the Wisp. Duration controls lifetime; magnitude controls firing speed.',
    icon = 'icons/wispspell/wisp.dds',
    allowsSpellmaking = true,
    allowsEnchanting = false,
    hasDuration = true,
    hasMagnitude = true,
    hasAttribute = false,
    hasSkill = false,
    onSelf = true,
    onTouch = false,
    onTarget = false,
    harmful = false,
    casterLinked = true,
    school = 'mysticism',
    baseCost = 1,
}

content.spells.records[common.spellId] = {
    name = 'Conjure Soul Wisp',
    type = content.spells.TYPE.Spell,
    cost = 15,
    starterSpellFlag = true,
    isAutocalc = false,
    effects = {
        {
            id = common.effectId,
            range = content.RANGE.Self,
            duration = common.defaultDuration,
            magnitudeMin = common.defaultMagnitude,
            magnitudeMax = common.defaultMagnitude,
        },
    },
}
