local content = require('openmw.content')
local core = require('openmw.core')
local markup = require('openmw.markup')

local l10n = core.l10n('WeaponPoisoning')
local data = markup.loadYaml('scripts/WeaponPoisoning/spellInfo.yaml')

local magicEffects = content.magicEffects.records
local potions = content.potions.records
local spells = content.spells.records

local customPoisons = {
    {
        id = 'wp_poison_b',
        name = 'poison_wp_poison_b',
        weight = 1.5,
        value = 5,
        duration = 8,
        magnitude = 2,
        model = 'meshes/m/misc_potion_bargain_01.nif',
        icon = 'icons/m/tx_potion_bargain_01.dds',
    },
    {
        id = 'wp_poison_c',
        name = 'poison_wp_poison_c',
        weight = 1.0,
        value = 15,
        duration = 10,
        magnitude = 3,
        model = 'meshes/m/misc_potion_cheap_01.nif',
        icon = 'icons/m/tx_potion_cheap_01.dds',
    },
    {
        id = 'wp_poison_s',
        name = 'poison_wp_poison_s',
        weight = 0.75,
        value = 35,
        duration = 15,
        magnitude = 4,
        model = 'meshes/m/misc_potion_standard_01.nif',
        icon = 'icons/m/tx_potion_standard_01.dds',
    },
    {
        id = 'wp_poison_q',
        name = 'poison_wp_poison_q',
        weight = 0.5,
        value = 80,
        duration = 20,
        magnitude = 6,
        model = 'meshes/m/misc_potion_quality_01.nif',
        icon = 'icons/m/tx_potion_quality_01.dds',
    },
    {
        id = 'wp_poison_e',
        name = 'poison_wp_poison_e',
        weight = 0.25,
        value = 175,
        duration = 30,
        magnitude = 8,
        model = 'meshes/m/misc_potion_exclusive_01.nif',
        icon = 'icons/m/tx_potion_exclusive_01.dds',
    },
}

for _, effectData in ipairs(data.effects) do
    local id = effectData.id
    local record = effectData.record
    record.name = l10n('effect_' .. id)
    record.description = l10n('effect_' .. id .. '_d')
    record.icon = 'icons/weaponpoisoning/s/' .. id .. '.dds'
    if record.template then
        record.template = magicEffects[record.template]
    end
    magicEffects[id] = record
end

for _, spellData in ipairs(data.spells) do
    local id = spellData.id
    local record = spellData.record
    record.name = l10n('spell_' .. id)
    if record.template then
        record.template = spells[record.template]
    end
    if record.type then
        record.type = content.spells.TYPE[record.type]
    end
    for _, effect in ipairs(record.effects) do
        if effect.range then
            effect.range = content.RANGE[effect.range]
        end
    end
    spells[id] = record
end

for _, poisonData in ipairs(customPoisons) do
    potions[poisonData.id] = {
        name = l10n(poisonData.name),
        model = poisonData.model,
        icon = poisonData.icon,
        weight = poisonData.weight,
        value = poisonData.value,
        isAutocalc = false,
        effects = {
            {
                id = 'Poison',
                range = content.RANGE.Self,
                duration = poisonData.duration,
                magnitudeMin = poisonData.magnitude,
                magnitudeMax = poisonData.magnitude,
            },
        },
    }
end
