local core = require('openmw.core')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')
local poisonTooltip = require('scripts.WeaponPoisoning.poisonTooltip')

local STATUS_EFFECT_ID = 'wp_poisoned_weapon'

local l10n = core.l10n('WeaponPoisoning')

local MWE = {}
local tooltipRegistered = false
local tooltipWrapped = false

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

local function addStatusTooltip(effectId, layout, state)
    if state.enabled and not state.enabled() then
        return layout
    end
    if effectId ~= STATUS_EFFECT_ID then
        return layout
    end
    layout.userData = layout.userData or {}
    if layout.userData.WeaponPoisoningStatusTooltip then
        return layout
    end

    local innerContent = getTooltipInnerContent(layout)
    if not innerContent then
        return layout
    end
    layout.userData.WeaponPoisoningStatusTooltip = true

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

    poisonTooltip.addPoisonEffectRows(innerContent, state.poisonRecord and state.poisonRecord())

    local weaponName = state.weaponName and state.weaponName()
    if weaponName then
        innerContent:add({
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {
                text = l10n('BuffWeaponTooltip', { weapon = weaponName }),
                autoSize = true,
            },
        })
    end

    return layout
end

local function registerTooltip(state)
    if tooltipRegistered or not I.MagicWindow or not I.MagicWindow.Tooltips or not I.MagicWindow.Constants then
        return
    end
    local tooltipType = I.MagicWindow.Constants.TooltipType
    if not tooltipType or not tooltipType.ACTIVE_EFFECT then
        return
    end
    I.MagicWindow.Tooltips.registerModifier(tooltipType.ACTIVE_EFFECT, 'WeaponPoisoningStatusTooltip', function(
        effectId,
        layout
    )
        return addStatusTooltip(effectId, layout, state)
    end)
    tooltipRegistered = true
end

local function wrapActiveEffectTooltip(state)
    if tooltipWrapped or not I.MagicWindow or not I.MagicWindow.Templates or not I.MagicWindow.Templates.MAGIC then
        return
    end
    local magicTemplates = I.MagicWindow.Templates.MAGIC
    if type(magicTemplates.activeEffectTooltip) ~= 'function' then
        return
    end

    local baseActiveEffectTooltip = magicTemplates.activeEffectTooltip
    magicTemplates.activeEffectTooltip = function(effectId)
        return addStatusTooltip(effectId, baseActiveEffectTooltip(effectId), state)
    end
    tooltipWrapped = true
end

function MWE.init(state)
    registerTooltip(state)
    wrapActiveEffectTooltip(state)
    return tooltipRegistered or tooltipWrapped
end

return MWE
