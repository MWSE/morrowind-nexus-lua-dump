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
    starterSpellFlag = false,
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

local sourceTome = content.books.records[common.tomeSourceBookId]
local tomeText = [[<DIV ALIGN="CENTER">Fragment: On Artaeum</DIV><BR>
The Old Ways are not dead. They sleep in careful margins and in the hands of mages who know how to read between schools.<BR><BR>
A soul may be given a lantern, and a spell may be given a soul. Draw the wisp close, bind it to your will, and let the lesser working beneath it become its errand. The wisp carries the spell outward as a moth carries flame.<BR><BR>
This is not conjuration in the crude sense. It is a Mysticism of paths: the mage, the wisp, the chosen target, and the thread between them.]]

if sourceTome then
    local baseText = sourceTome.text or ''
    if baseText ~= '' then
        tomeText = baseText .. [[<BR><BR><DIV ALIGN="CENTER">Marginalia in violet ink</DIV><BR>]] .. tomeText
    end

    content.books.records[common.tomeId] = {
        template = sourceTome,
        name = 'Fragment: On Artaeum',
        text = tomeText,
        value = 35,
    }
end

