local core = require('openmw.core')
local self = require('openmw.self')
local util = require('openmw.util')
local ui = require('openmw.ui')
local types = require('openmw.types')
local storage = require('openmw.storage')
local input = require('openmw.input')

local helpers = require('scripts.MagicWindowExtender.util.helpers')
local constants = require('scripts.MagicWindowExtender.util.constants')

local magicWindow = require('scripts.MagicWindowExtender.ui.magicWindow')
local magic = require("scripts.MagicWindowExtender.ui.templates.magic")

local configPlayer = require('scripts.MagicWindowExtender.config.player')

local l10n = core.l10n('MagicWindowExtender')

local API = {}

API.VERSION = 1

API.Constants = constants

API.Templates = {
    BASE = require('scripts.MagicWindowExtender.ui.templates.base'),
    MAGIC = require('scripts.MagicWindowExtender.ui.templates.magic'),
}

API.TooltipBuilders = {
    TEXT = function(params)
        return API.Templates.MAGIC.tooltip(4, ui.content {
            {
                template = API.Templates.BASE.textParagraph,
                props = {
                    size = util.vector2(params.width or 300, 0),
                    text = params.text or '',
                    autoSize = true,
                }
            }
        })
    end,
    ACTIVE_EFFECT = function(effectId)
        return API.Templates.MAGIC.activeEffectTooltip(effectId)
    end,
    SPELL = function(spellId)
        return API.Templates.MAGIC.spellTooltip(spellId)
    end,
    ITEM = function(item)
        return API.Templates.MAGIC.itemTooltip(item)
    end,
}

API.LineBuilders = {
    POWER = function(powerId, editMode)
        local powerRecord = core.magic.spells.records[powerId]
        local override = API.Spells.getCustomSpell(powerId)
        local pinned = API.getStat(API.Constants.TrackedStats.PINNED) or {}
        return {
            id = powerId,
            icon = function()
                if configPlayer.tweaks.b_SpellIcons then
                    return (override and override.effects and override.effects[1].effect.icon) or powerRecord.effects[1].effect.icon
                elseif configPlayer.tweaks.b_PinnedSpellIcons and pinned['powers'] and pinned['powers'][powerId] and not editMode then
                    return 'textures/MagicWindowExtender/pinned_true.dds'
                else
                    return nil
                end
            end,
            label = override and override.name or powerRecord.name,
            value = function()
                if configPlayer.tweaks.b_MarkUsedPowers and not self.type.spells(self):canUsePower(powerId) then
                    return { string = ' ' ..l10n('PowerUsed'), color = API.Constants.Colors.DAMAGED }
                else
                    return { string = '' }
                end
            end,
            active = function()
                local selectedSpell = self.type.getSelectedSpell(self)
                return selectedSpell and selectedSpell.id == powerId
            end,
            disabled = function()
                return configPlayer.tweaks.b_MarkUsedPowers and not self.type.spells(self):canUsePower(powerId)
            end,
            onClick = function()
                if input.isShiftPressed() then
                    API.Templates.MAGIC.tryDelete(powerId)
                    return
                end
                self.type.setSelectedSpell(self, powerRecord)
                API.setDirtyDelayed()
            end,
            tooltip = function()
                return API.TooltipBuilders.SPELL(powerId)
            end,
            editInfo = {
                id = powerId,
                type = 'powers',
                editing = editMode == true,
            }
        }
    end,
    SPELL = function(spellId, editMode)
        local spellRecord = core.magic.spells.records[spellId]
        local override = API.Spells.getCustomSpell(spellId)
        local pinned = API.getStat(API.Constants.TrackedStats.PINNED) or {}
        return {
            id = spellId,
            icon = function()
                if configPlayer.tweaks.b_SpellIcons then
                    return (override and override.effects and override.effects[1].effect.icon) or spellRecord.effects[1].effect.icon
                elseif configPlayer.tweaks.b_PinnedSpellIcons and pinned['spells'] and pinned['spells'][spellId] and not editMode then
                    return 'textures/MagicWindowExtender/pinned_true.dds'
                else
                    return nil
                end
            end,
            label = override and override.name or spellRecord.name,
            value = function()
                local cost, chance = helpers.getModifiedSpellCost(spellId, false), helpers.getSpellCastChance(spellId)
                return { string = tostring(' ' ..util.round(cost)) .. '/' .. tostring(chance) }
            end,
            active = function()
                local selectedSpell = self.type.getSelectedSpell(self)
                return selectedSpell and selectedSpell.id == spellId
            end,
            onClick = function()
                if input.isShiftPressed() then
                    API.Templates.MAGIC.tryDelete(spellId)
                    return
                end
                self.type.setSelectedSpell(self, spellRecord)
                API.setDirtyDelayed()
            end,
            tooltip = function()
                return API.TooltipBuilders.SPELL(spellId)
            end,
            editInfo = {
                id = spellId,
                type = 'spells',
                editing = editMode == true,
            },
        }
    end,
    MAGIC_ITEM = function(item, editMode)
        local itemRecord = item.type.records[item.recordId]
        local label = itemRecord.name
        if item.count and item.count > 1 then
            label = label .. ' (' .. tostring(item.count) .. ')'
        end
        local pinned = API.getStat(API.Constants.TrackedStats.PINNED) or {}
        return {
            id = item.id,
            icon = function()
                if configPlayer.tweaks.b_SpellIcons then
                    local record = API.Spells.getCustomSpell(itemRecord.enchant) or core.magic.enchantments.records[itemRecord.enchant]
                    return record.effects[1].effect.icon
                elseif configPlayer.tweaks.b_PinnedSpellIcons and pinned['magicItems'] and pinned['magicItems'][item.id] and not editMode then
                    return 'textures/MagicWindowExtender/pinned_true.dds'
                else
                    return nil
                end
            end,
            label = label,
            value = function()
                local cost, charge
                if core.magic.enchantments.records[itemRecord.enchant].type == core.magic.ENCHANTMENT_TYPE.CastOnce then
                    cost, charge = 100, 100
                else
                    cost, charge = helpers.getModifiedSpellCost(itemRecord.enchant, true), math.floor(types.Item.itemData(item).enchantmentCharge)
                end
                return { string = tostring(' ' ..util.round(cost)) .. '/' .. tostring(charge) }
            end,
            active = function()
                local selectedItem = self.type.getSelectedEnchantedItem(self)
                return selectedItem and selectedItem.id == item.id
            end,
            disabled = function()
                return not self.type.hasEquipped(self, item)
            end,
            onClick = function()
                self.type.setSelectedEnchantedItem(self, item)
                API.setDirtyDelayed()
            end,
            tooltip = function()
                return API.TooltipBuilders.ITEM(item)
            end,
            editInfo = {
                id = item.id,
                type = 'magicItems',
                editing = editMode == true,
            },
        }
    end,
}

function API.show(staticMode)
    magicWindow.show(staticMode)
end

function API.hide(force)
    magicWindow.hide(force)
end

function API.toggle(staticMode)
    magicWindow.toggle(staticMode)
end

function API.isVisible()
    return magicWindow.isVisible()
end

function API.isPinned()
    return magicWindow.isPinned()
end

function API.onFrame()
    magicWindow.onFrame()
end

function API.onMouseWheel(v, h)
    magicWindow.onMouseWheel(v, h)
end

function API.update()
    magicWindow.update()
end

function API.trackStat(statId, getter)
    magicWindow.trackStat(statId, getter)
end

function API.untrackStat(statId)
    magicWindow.untrackStat(statId)
end

function API.setStat(statId, value, forceUpdate)
    if forceUpdate or not helpers.tableEquals(value, magicWindow.stats[statId]) then
        magicWindow.changedStats[statId] = true
        magicWindow.stats[statId] = value
        magicWindow.updateTrackedSections()
    end
end

function API.getStat(statId)
    return magicWindow.stats[statId]
end

function API.addBoxToPane(boxId, paneId, params)
    magicWindow.addBoxToPane(boxId, paneId, params)
end

function API.addSectionToBox(sectionId, boxId, params)
    magicWindow.addSectionToBox(sectionId, boxId, params)
end

function API.addSectionToSection(sectionId, parentSectionId, params)
    magicWindow.addSectionToSection(sectionId, parentSectionId, params)
end

function API.addLineToSection(lineId, sectionId, params)
    magicWindow.addLineToSection(lineId, sectionId, params)
end

function API.moveSectionToBox(sectionId, boxId)
    magicWindow.moveSectionToBox(sectionId, boxId)
end

function API.modifyBox(boxId, params)
    magicWindow.modifyBox(boxId, params)
end

function API.modifySection(sectionId, params)
    magicWindow.modifySection(sectionId, params)
end

function API.modifyLine(lineId, params)
    magicWindow.modifyLine(lineId, params)
end

function API.overrideLineBuilder(type, newDef)
    API.LineBuilders[type] = newDef
end

function API.overrideTooltipBuilder(type, newDef)
    API.TooltipBuilders[type] = newDef
end

function API.setDirty()
    magicWindow.needsRedraw = true
end

function API.setDirtyDelayed()
    magicWindow.needsRedrawDelayed = true
end

function API.getPanes()
    return magicWindow.panes
end

function API.getPane(paneId)
    return magicWindow.getPane(paneId)
end

function API.getBox(boxId)
    local box, parentPaneId = magicWindow.getBox(boxId)
    return box, parentPaneId
end

function API.getSection(sectionId)
    local section, parentBox, parentPaneId = magicWindow.getSection(sectionId)
    return section, parentBox, parentPaneId
end

function API.getLine(lineId)
    local line, parentSection, parentBox, parentPaneId = magicWindow.getLine(lineId)
    return line, parentSection, parentBox, parentPaneId
end

function API.getWindowElement()
    return magicWindow.element
end

-- ============= CUSTOM SPELLS ============= --
API.Spells = {}

local customEffectRegistry = {}
local customSpellRegistry = {}

function API.Spells.registerEffect(effectDef)
    if not effectDef then
        error("Custom effect definition is nil.")
    end
    if not effectDef.id then
        error("Custom effect definition is missing 'id' field.")
    end
    customEffectRegistry[effectDef.id:lower()] = effectDef
    API.setStat(constants.TrackedStats.EFFECT_OVERRIDES, customEffectRegistry, true)
    return effectDef
end

function API.Spells.registerSpell(spellDef)
    if not spellDef then
        error("Custom spell definition is nil.")
    end
    if not spellDef.id then
        error("Custom spell definition is missing 'id' field.")
    end
    customSpellRegistry[spellDef.id:lower()] = spellDef
    API.setStat(constants.TrackedStats.SPELL_OVERRIDES, customSpellRegistry, true)
    return spellDef
end

function API.Spells.getCustomEffect(effectId)
    return customEffectRegistry[effectId:lower()]
end

function API.Spells.getCustomSpell(spellId)
    return customSpellRegistry[spellId:lower()]
end

return {
    interfaceName = 'MagicWindow',
    interface = API,
    eventHandlers = {
        UiModeChanged = function(data)
            magicWindow.onUiModeChanged(data.oldMode, data.newMode)
        end,
    },
}