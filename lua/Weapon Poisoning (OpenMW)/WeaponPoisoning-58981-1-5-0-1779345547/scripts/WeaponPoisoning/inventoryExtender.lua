local core = require('openmw.core')
local I = require('openmw.interfaces')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local poisonTooltip = require('scripts.WeaponPoisoning.poisonTooltip')

local l10n = core.l10n('WeaponPoisoning')

local POISON_ICON = 'icons/weaponpoisoning/s/wp_poisoned_weapon.dds'

local InventoryExtender = {}
local tooltipRegistered = false

local function getTooltipInnerContent(layout)
    local paddedTooltip = layout
        and layout.content
        and layout.content.padding
        and layout.content.padding.content
        and layout.content.padding.content.tooltip
    if paddedTooltip then
        return layout.content.padding.content.tooltip.content
    end
    local nestedTooltip = layout
        and layout.content
        and layout.content[1]
        and layout.content[1].content
        and layout.content[1].content[1]
    if nestedTooltip then
        return layout.content[1].content[1].content
    end
    return nil
end

local function hasOnlyHarmfulEffects(potionRecord)
    if not potionRecord or not potionRecord.effects or #potionRecord.effects == 0 then
        return false
    end
    for _, effect in ipairs(potionRecord.effects) do
        local magicEffect = core.magic.effects.records[effect.id]
        if not magicEffect or magicEffect.harmful ~= true then
            return false
        end
    end
    return true
end

local function addPoisonPotionTooltip(item, layout)
    if not item or item.type ~= types.Potion then
        return layout
    end

    local potionRecord = types.Potion.record(item)
    if not hasOnlyHarmfulEffects(potionRecord) then
        return layout
    end

    local innerContent = getTooltipInnerContent(layout)
    if not innerContent then
        return layout
    end

    innerContent:add({
        template = I.MWUI.templates.interval,
    })
    innerContent:add({
        template = I.MWUI.templates.horizontalLine,
        props = { size = util.vector2(0, 2) },
        external = { stretch = 1 },
    })
    innerContent:add({
        template = I.MWUI.templates.interval,
    })
    innerContent:add({
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = true,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    size = util.vector2(16, 16),
                    resource = ui.texture { path = POISON_ICON },
                },
            },
            {
                template = I.MWUI.templates.interval,
            },
            {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textHeader,
                props = {
                    text = l10n('PoisonPotionTooltip'),
                    autoSize = true,
                },
            },
        },
    })

    return layout
end

local function addPoisonTooltip(item, layout, state)
    if state.enabled and not state.enabled() then
        return layout
    end
    if item and item.type == types.Potion then
        return addPoisonPotionTooltip(item, layout)
    end
    if not item or item.type ~= types.Weapon then
        return layout
    end

    local poisonRecord = state.poisonRecordForWeapon and state.poisonRecordForWeapon(item)
    if not poisonRecord then
        return layout
    end

    local innerContent = getTooltipInnerContent(layout)
    if not innerContent then
        return layout
    end

    innerContent:add({
        template = I.MWUI.templates.interval,
    })
    innerContent:add({
        template = I.MWUI.templates.horizontalLine,
        props = { size = util.vector2(0, 2) },
        external = { stretch = 1 },
    })
    innerContent:add({
        template = I.MWUI.templates.interval,
    })

    innerContent:add({
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textHeader,
        props = {
            text = l10n('effect_wp_poisoned_weapon'),
            autoSize = true,
        },
    })

    poisonTooltip.addPoisonEffectRows(innerContent, poisonRecord)

    return layout
end

function InventoryExtender.init(state)
    local registerTooltipModifier = I.InventoryExtender and I.InventoryExtender.registerTooltipModifier
    if tooltipRegistered or type(registerTooltipModifier) ~= 'function' then
        return
    end

    registerTooltipModifier('WeaponPoisoningWeaponTooltip', function(item, layout)
        return addPoisonTooltip(item, layout, state)
    end)
    tooltipRegistered = true
    return true
end

return InventoryExtender
