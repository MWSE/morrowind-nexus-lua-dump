local I = require('openmw.interfaces')
local core = require('openmw.core')
local self = require('openmw.self')
local ui = require('openmw.ui')
local types = require('openmw.types')
local util = require('openmw.util')

local helpers_p = require('scripts.niftyspellpack.util.helpers_p')
local helpers = require('scripts.niftyspellpack.util.helpers')
local uiState = require('scripts.niftyspellpack.ui.state')
local Widgets = require('scripts.niftyspellpack.ui.widgets')
local constants = require("scripts.niftyspellpack.ui.constants")
local config = require('scripts.niftyspellpack.config.global')

local l10n = core.l10n('NiftySpellPack')

local activePocket = nil
local choiceModal, confirmModal

local linkedPockets = {} -- synced from global, used to show info in MWE tooltips

local function initMWETooltips()
    if I.MagicWindow and I.MagicWindow.Tooltips then
        local Type = I.MagicWindow.Constants.TooltipType
        local BASE = I.MagicWindow.Templates.BASE

        local modifierId = 'nsp_pocket'

        local baseFn = function(spellOrItemId, layout)
            if not linkedPockets[spellOrItemId] and config.pocket.i_MaxPockets == 0 then return end

            local innerContent = layout.content.padding.content.tooltip.content

            innerContent:add(BASE.intervalV(8))
            innerContent:add({
                template = I.MWUI.templates.horizontalLine,
                props = {
                    size = util.vector2(0, 2),
                },
                external = {
                    stretch = 1,
                }
            })
            innerContent:add(BASE.intervalV(8))

            local text
            if linkedPockets[spellOrItemId] then
                text = l10n('UI_Pocket_Tooltip_Active', { encumbrance = linkedPockets[spellOrItemId].encumbrance, capacity = linkedPockets[spellOrItemId].capacity })
            elseif config.pocket.i_MaxPockets > 0 then
                text = l10n('UI_Pocket_Tooltip_Inactive', { free = config.pocket.i_MaxPockets - helpers.getSize(linkedPockets) })
            end
            innerContent:add({
                template = I.MWUI.templates.textNormal,
                props = {
                    text = text,
                    textColor = constants.uiColors.CONJURATION,
                    alpha = linkedPockets[spellOrItemId] and 1 or 0.5,
                },
            })
        end

        I.MagicWindow.Tooltips.registerModifier(Type.SPELL, modifierId, function(spellId, layout)
            local spell = core.magic.spells.records[spellId]
            for _, effect in ipairs(spell.effects) do
                if effect.id == 'nsp_pocket' then
                    baseFn(spellId, layout)
                    break
                end
            end
        end)
        I.MagicWindow.Tooltips.registerModifier(Type.MAGIC_ITEM, modifierId, function(item, layout)
            local enchantId = item.type.record(item).enchant
            if enchantId then
                local enchant = core.magic.enchantments.records[enchantId]
                for _, effect in ipairs(enchant.effects) do
                    if effect.id == 'nsp_pocket' then
                        baseFn(item.recordId, layout)
                        break
                    end
                end
            end
        end)
    end
end

local function createCollapseChoiceModal(linkedPockets)
    local choices = {}
    for id, data in pairs(linkedPockets) do
        local record = types.Container.record(data.recordId)
        table.insert(choices, {
            text = l10n('UI_Pocket_Collapse_Choice', { name = record.name, encumbrance = data.encumbrance, capacity = data.capacity }),
            callback = function()
                confirmModal = ui.create(Widgets.confirmModal(function()
                    if choiceModal then
                        choiceModal:destroy()
                    end
                    if confirmModal then
                        confirmModal:destroy()
                    end
                    uiState.modalElement = nil
                    I.UI.removeMode('Interface')
                    core.sendGlobalEvent('NSP_EffectEvent', { type = 'onCollapseChoice', effectId = 'nsp_pocket', target = self, ctx = { toCollapse = id } })
                end, function()
                    if confirmModal then
                        confirmModal:destroy()
                        confirmModal = nil
                    end
                    if choiceModal then
                        choiceModal.layout.props.relativeSize = util.vector2(1, 1)
                        choiceModal:update()
                    end
                end, l10n('UI_Pocket_Collapse_Confirm', { name = record.name })))
                if choiceModal then
                    choiceModal.layout.props.relativeSize = util.vector2(0, 0)
                    choiceModal:update()
                    confirmModal:update()
                end
            end
        })
    end
    table.sort(choices, function(a, b) return a.text < b.text end)

    table.insert(choices, {
        text = l10n('UI_Cancel'),
        callback = function()
            if choiceModal or confirmModal then
                if choiceModal then
                    choiceModal:destroy()
                    choiceModal = nil
                end
                if confirmModal then
                    confirmModal:destroy()
                    confirmModal = nil
                end
                uiState.modalElement = nil
                I.UI.removeMode('Interface')
                helpers_p.removeSpellsByEffectId('nsp_pocket', true)
            end
        end
    })

    if uiState.modalElement then
        uiState.modalElement:destroy()
    end

    choiceModal = ui.create(Widgets.choiceModal(l10n('UI_Pocket_NoCapacity'), choices))

    uiState.modalElement = choiceModal
    
    I.UI.addMode('Interface', {windows = {}})
end

return {
    onTrigger = function(ctx)
        if ctx.linkedPockets then
            linkedPockets = ctx.linkedPockets
        end
        if ctx.container then
            I.UI.addMode('Container', { target = ctx.container })
            activePocket = ctx.container
        end
        helpers_p.removeSpellsByEffectId('nsp_pocket', true)
    end,
    onFail = function(ctx)
        if ctx.linkedPockets then
            linkedPockets = ctx.linkedPockets  
            createCollapseChoiceModal(ctx.linkedPockets)
        end
    end,
    onUiModeChanged = function(oldMode)
        if oldMode == 'Interface' then
            if choiceModal or confirmModal then
                if choiceModal then
                    choiceModal:destroy()
                    choiceModal = nil
                end
                if confirmModal then
                    confirmModal:destroy()
                    confirmModal = nil
                end
                uiState.modalElement = nil
                helpers_p.removeSpellsByEffectId('nsp_pocket', true)
            end
        end
        if oldMode == 'Container' then
            if activePocket then
                core.sendGlobalEvent('NSP_EffectEvent', { type = 'onContainerClosed', effectId = 'nsp_pocket', target = self, ctx = { container = activePocket } })
            end
            activePocket = nil 
        end
    end,
    onContainerClosed = function(ctx)
        linkedPockets = ctx.linkedPockets
    end,
    onLoad = function(save)
        if save then
            linkedPockets = save.linkedPockets or {}
        end
    end,
    onSave = function()
        return {
            linkedPockets = linkedPockets,
        }
    end,
    onActive = function()
        initMWETooltips()
    end,
}