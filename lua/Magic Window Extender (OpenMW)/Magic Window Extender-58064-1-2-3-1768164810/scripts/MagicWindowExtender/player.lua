local I = require('openmw.interfaces')
local self = require('openmw.self')
local core = require('openmw.core')
local input = require('openmw.input')
local async = require('openmw.async')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local types = require('openmw.types')

local util = require('openmw.util')
local auxUtil = require('openmw_aux.util')
local v2 = util.vector2

local API = I.MagicWindow

local configPlayer = require('scripts.MagicWindowExtender.config.player')
local helpers = require('scripts.MagicWindowExtender.util.helpers')

local lastSelectedCastable = nil
local lastEquipment = nil

local function init()
    if not I.GamepadControls.isControllerMenusEnabled or not I.GamepadControls.isControllerMenusEnabled() then
        if configPlayer.window.b_ReplaceVanillaWindow then
            I.UI.registerWindow('Magic', API.show, API.hide)
        end
    elseif configPlayer.misc.b_ShowControllerWarning then
        storage.playerSection('Settings/MagicWindowExtender/5_Misc'):set('b_ShowControllerWarning', false)
        local msg = 'NOTICE:\nMagic Window Extender\'s window replacer is not compatible with controller menus. You will need to bind a button in the script settings to toggle the extended window manually.\nThis message will only appear once.'
        if I.UI.showInteractiveMessage then -- OpenMW 0.50+
            I.UI.showInteractiveMessage(msg, {})
        else
            ui.showMessage(msg)
        end
    end
    local actionCallback = async:callback(function(e)
        if e then
            I.MagicWindow.toggle(true)
        end
    end)
    input.registerActionHandler('MWE_ToggleMagicWindow1', actionCallback)
    input.registerActionHandler('MWE_ToggleMagicWindow2', actionCallback)

    local function cycleSpell(direction)
        API.setDirtyDelayed()
        if not configPlayer.tweaks.b_SmartSpellCycling then
            return
        end

        local order, lookup = helpers.getSpellListOrder()
        local lastPos = lastSelectedCastable and lookup[lastSelectedCastable.id] or 0
        local nextPos
        if direction == 'left' then
            nextPos = lastPos > 1 and lastPos - 1 or #order
        else
            nextPos = lastPos < #order and lastPos + 1 or 1
        end
        local nextId = order[nextPos]
        if nextId then
            local selectedItem = self.type.getSelectedEnchantedItem(self)
            if selectedItem then
                local equipment = self.type.getEquipment(self)
                for slot, item in pairs(equipment) do
                    if item.id == selectedItem.id then
                        equipment[slot] = lastEquipment and lastEquipment[slot] or nil
                        break
                    end
                end
                self.type.setEquipment(self, equipment)
            end

            if core.magic.spells.records[nextId] then
                self.type.setSelectedSpell(self, core.magic.spells.records[nextId])
            else
                local items = self.type.inventory(self):getAll()
                for _, item in ipairs(items) do
                    if item.id == nextId then
                        self.type.setSelectedEnchantedItem(self, item)
                        break
                    end
                end
            end
        end
    end

    input.registerTriggerHandler('CycleSpellLeft', async:callback(function()
        cycleSpell('left')
    end))
    input.registerTriggerHandler('CycleSpellRight', async:callback(function()
        cycleSpell('right')
    end))
end

local C = API.Constants

-- Default boxes
API.addBoxToPane(C.DefaultBoxes.TOP_BAR, C.Panes.MAIN, {
    placement = {
        type = C.Placement.TOP,
    },
    padding = 0,
    border = false,
    fixedHeight = API.Templates.MAGIC.LINE_HEIGHT + 2 * API.Templates.MAGIC.BORDER_THICKNESS,
})

API.addBoxToPane(C.DefaultBoxes.MAGIC, C.Panes.MAIN, {
    placement = {
        type = C.Placement.AFTER,
        target = C.DefaultBoxes.TOP_BAR,
    },
    padding = API.Templates.MAGIC.BOX_INNER_PADDING * 2,
    scrollable = true,
    showWhenEmpty = true,
})

API.addBoxToPane(C.DefaultBoxes.BOTTOM_BAR, C.Panes.MAIN, {
    placement = {
        type = C.Placement.AFTER,
        target = configPlayer.tweaks.b_SearchBarOnTop and C.DefaultBoxes.TOP_BAR or C.DefaultBoxes.MAGIC,
    },
    padding = 0,
    border = false,
    fixedHeight = API.Templates.MAGIC.LINE_HEIGHT + 2 * API.Templates.MAGIC.BORDER_THICKNESS,
})

-- Default sections

API.addSectionToBox(C.DefaultSections.TOP_BAR, C.DefaultBoxes.TOP_BAR, {
    horizontal = true,
})

API.addSectionToBox(C.DefaultSections.POWERS, C.DefaultBoxes.MAGIC, {
    header = {
        label = C.Strings.POWERS
    },
    indent = false,
    sort = C.Sort.LABEL_ASC,
})

API.addSectionToBox(C.DefaultSections.SPELLS, C.DefaultBoxes.MAGIC, {
    header = {
        label = C.Strings.SPELLS,
        value = function()
            return { string = C.Strings.COST_CHANCE, color = C.Colors.DEFAULT_LIGHT }
        end,
    },
    indent = false,
    sort = C.Sort.LABEL_ASC,
})

API.addSectionToBox(C.DefaultSections.MAGIC_ITEMS, C.DefaultBoxes.MAGIC, {
    header = {
        label = C.Strings.MAGIC_ITEMS,
        value = function()
            return { string = C.Strings.COST_CHARGE, color = C.Colors.DEFAULT_LIGHT }
        end,
    },
    indent = false,
    sort = C.Sort.LABEL_ASC,
})

API.addSectionToBox(C.DefaultSections.BOTTOM_BAR, C.DefaultBoxes.BOTTOM_BAR, {
    horizontal = true,
})

-- Default lines

API.addLineToSection(C.DefaultLines.ACTIVE_SPELLS, C.DefaultSections.TOP_BAR, {
    type = C.LineType.CUSTOM,
    layoutFn = function() 
        local layout = API.Templates.MAGIC.activeSpells()
        return {
            template = I.MWUI.templates.borders,
            props = {
                autoSize = false,
                size = v2(0, API.Templates.MAGIC.LINE_HEIGHT + 2 * API.Templates.MAGIC.BORDER_THICKNESS),
            },
            external = { grow = 1 },
            content = ui.content { layout }
        }
    end,
    height = API.Templates.MAGIC.LINE_HEIGHT + 2 * API.Templates.MAGIC.BORDER_THICKNESS,
    grow = true,
})

API.addLineToSection(C.DefaultLines.EDIT_MODE_BUTTON, C.DefaultSections.TOP_BAR, {
    type = C.LineType.CUSTOM,
    layoutFn = function() 
        if not configPlayer.tweaks.b_ListEditing then
            return {}
        end
        return API.Templates.MAGIC.interactive({
                onClick = function() 
                    API.setStat(C.TrackedStats.EDIT_MODE, not API.getStat(C.TrackedStats.EDIT_MODE))
                end,
                name = 'editModeButton',
            }, 
            API.Templates.BASE.imageButton('textures/MagicWindowExtender/edit_mode.dds', v2(API.Templates.MAGIC.LINE_HEIGHT - 2 * API.Templates.MAGIC.BORDER_THICKNESS, API.Templates.MAGIC.LINE_HEIGHT - 2 * API.Templates.MAGIC.BORDER_THICKNESS)).layout)
    end,
    visibleFn = function()
        return configPlayer.tweaks.b_ListEditing
    end,
    active = function()
        return API.getStat(C.TrackedStats.EDIT_MODE)
    end,
    staticLayout = true,
})

-- Section builders

local trackedStatsBase = {
    [C.TrackedStats.SEARCH_FILTER] = true,
    [C.TrackedStats.SCHOOL_FILTER] = true,
    [C.TrackedStats.EDIT_MODE] = true,
    [C.TrackedStats.PINNED] = true,
    [C.TrackedStats.HIDDEN] = true,
    [C.TrackedStats.EFFECT_OVERRIDES] = true,
    [C.TrackedStats.SPELL_OVERRIDES] = true,
}

API.modifySection(C.DefaultSections.POWERS, {
    trackedStats = helpers.mergeTables(trackedStatsBase, {
        [C.TrackedStats.POWERS] = true,
    }),
    builder = function()
        local searchFilter = API.getStat(C.TrackedStats.SEARCH_FILTER)
        local schoolFilter = API.getStat(C.TrackedStats.SCHOOL_FILTER)
        local editMode = API.getStat(C.TrackedStats.EDIT_MODE)
        for _, spell in ipairs(API.getStat(C.TrackedStats.POWERS) or {}) do
            local override = API.Spells.getCustomSpell(spell.id)
            local effects = override and override.effects or spell.effects
            if ((not searchFilter or searchFilter == '') or 
                spell.name:lower():find(searchFilter:lower(), 1, true) or 
                helpers.effectListContainsString(effects, searchFilter)) and
                ((not schoolFilter or schoolFilter == '') or
                helpers.effectListContainsSchool(effects, schoolFilter))
            then
                API.addLineToSection(spell.id, C.DefaultSections.POWERS, API.LineBuilders.POWER(spell.id, editMode))
            end
        end
    end,
})

API.modifySection(C.DefaultSections.SPELLS, {
    trackedStats = helpers.mergeTables(trackedStatsBase, {
        [C.TrackedStats.SPELLS] = true,
    }),
    builder = function()
        local searchFilter = API.getStat(C.TrackedStats.SEARCH_FILTER)
        local schoolFilter = API.getStat(C.TrackedStats.SCHOOL_FILTER)
        local editMode = API.getStat(C.TrackedStats.EDIT_MODE)
        for _, spell in ipairs(API.getStat(C.TrackedStats.SPELLS) or {}) do
            local override = API.Spells.getCustomSpell(spell.id)
            local effects = override and override.effects or spell.effects
            if ((not searchFilter or searchFilter == '') or 
                spell.name:lower():find(searchFilter:lower(), 1, true) or 
                helpers.effectListContainsString(effects, searchFilter)) and
                ((not schoolFilter or schoolFilter == '') or
                helpers.effectListContainsSchool(effects, schoolFilter))
            then
                API.addLineToSection(spell.id, C.DefaultSections.SPELLS, API.LineBuilders.SPELL(spell.id, editMode))
            end
        end
    end,
})

API.modifySection(C.DefaultSections.MAGIC_ITEMS, {
    trackedStats = helpers.mergeTables(trackedStatsBase, {
        [C.TrackedStats.MAGIC_ITEMS] = true,
    }),
    builder = function()
        local searchFilter = API.getStat(C.TrackedStats.SEARCH_FILTER)
        local schoolFilter = API.getStat(C.TrackedStats.SCHOOL_FILTER)
        local editMode = API.getStat(C.TrackedStats.EDIT_MODE)
        for _, item in ipairs(API.getStat(C.TrackedStats.MAGIC_ITEMS) or {}) do
            local enchantRecord = core.magic.enchantments.records[item.type.record(item).enchant]
            local override = API.Spells.getCustomSpell(item.type.record(item).enchant)
            local effects = override and override.effects or enchantRecord.effects
            if ((not searchFilter or searchFilter == '') or 
                item.type.record(item).name:lower():find(searchFilter:lower(), 1, true) or 
                helpers.effectListContainsString(effects, searchFilter)) and
                ((not schoolFilter or schoolFilter == '') or
                helpers.effectListContainsSchool(effects, schoolFilter))
            then
                API.addLineToSection(item.id, C.DefaultSections.MAGIC_ITEMS, API.LineBuilders.MAGIC_ITEM(item, editMode))
            end
        end
    end,
})

local bottomBarBuilder = function()
    API.addLineToSection(C.DefaultLines.SEARCH_BAR, C.DefaultSections.BOTTOM_BAR, {
        type = C.LineType.CUSTOM,
        layoutFn = function() 
            return {
                template = I.MWUI.templates.borders,
                props = {
                    autoSize = false,
                    size = v2(0, API.Templates.MAGIC.LINE_HEIGHT + 2 * API.Templates.MAGIC.BORDER_THICKNESS),
                },
                external = { grow = 1 },
                content = ui.content {
                    {
                        template = API.Templates.BASE.textEditLine,
                        props = {
                            text = API.getStat(C.TrackedStats.SEARCH_FILTER) or '',
                            relativeSize = v2(1, 1),
                        },
                        events = {
                            textChanged = async:callback(function(text)
                                API.setStat(C.TrackedStats.SEARCH_FILTER, text)
                            end),
                        }
                    }
                },
            }
        end,
        height = API.Templates.MAGIC.LINE_HEIGHT + 2 * API.Templates.MAGIC.BORDER_THICKNESS,
        grow = true,
        noUpdate = true,
    })

    API.addLineToSection(C.DefaultLines.SCHOOL_FILTER, C.DefaultSections.BOTTOM_BAR, {
        type = C.LineType.CUSTOM,
        layoutFn = function()
            if not configPlayer.tweaks.b_SchoolFilter then
                return {}
            end
            local layout = API.Templates.MAGIC.schoolFilter()
            return {
                template = I.MWUI.templates.borders,
                props = {
                    autoSize = true,
                    size = v2(layout.props.size.x + 2 * API.Templates.MAGIC.BORDER_THICKNESS, API.Templates.MAGIC.LINE_HEIGHT + 2 * API.Templates.MAGIC.BORDER_THICKNESS),
                },
                content = ui.content {
                    layout,
                }
            }
        end,
        visibleFn = function()
            return configPlayer.tweaks.b_SchoolFilter
        end,
        staticLayout = true,
    })

    API.addLineToSection(C.DefaultLines.DELETE_BUTTON, C.DefaultSections.BOTTOM_BAR, {
        type = C.LineType.CUSTOM,
        layoutFn = function() 
            return API.Templates.MAGIC.deleteButton()
        end,
        noUpdate = true,
    })
end
API.modifySection(C.DefaultSections.BOTTOM_BAR, {
    trackedStats = {
        [C.TrackedStats.SCHOOL_FILTER] = true,
    },
    builder = bottomBarBuilder,
})
bottomBarBuilder()

API.trackStat(C.TrackedStats.ACTIVE_SPELLS, function()
    local active = {}
    for id, params in pairs(self.type.activeSpells(self)) do
        active[id] = tostring(params)
    end
    return active
end)

API.trackStat(C.TrackedStats.POWERS, function()
    local allSpells = self.type.spells(self)
    return auxUtil.mapFilter(allSpells, function(spell)
        return spell.type == core.magic.SPELL_TYPE.Power
    end)
end)

API.trackStat(C.TrackedStats.SPELLS, function()
    local allSpells = self.type.spells(self)
    return auxUtil.mapFilter(allSpells, function(spell)
        return spell.type == core.magic.SPELL_TYPE.Spell
    end)
end)

API.trackStat(C.TrackedStats.MAGIC_ITEMS, function()
    local allItems = self.type.inventory(self):getAll()
    return auxUtil.mapFilter(allItems, function(item)
        local enchantId = item.type.record(item).enchant
        local enchant = enchantId and core.magic.enchantments.records[enchantId]
        return enchant ~= nil and enchant.type ~= core.magic.ENCHANTMENT_TYPE.ConstantEffect and enchant.type ~= core.magic.ENCHANTMENT_TYPE.CastOnStrike
    end)
end)

API.setStat(C.TrackedStats.EDIT_MODE, false)
API.setStat(C.TrackedStats.SEARCH_FILTER, '')
API.setStat(C.TrackedStats.SCHOOL_FILTER, nil)
API.setStat(C.TrackedStats.PINNED, {})
API.setStat(C.TrackedStats.HIDDEN, {})

return {
    engineHandlers = {
        onInit = init,
        onLoad = function(data)
            init()
            if data then
                API.setStat(C.TrackedStats.PINNED, data.pinned or {})
                API.setStat(C.TrackedStats.HIDDEN, data.hidden or {})
                API.setStat(C.TrackedStats.DELETED_SPELLS, data.deletedSpells or {})
            end
            
            local deletedSpells = API.getStat(C.TrackedStats.DELETED_SPELLS) or {}
            for spellId,_ in pairs(deletedSpells) do
                self.type.spells(self):remove(spellId)
                if self.type.getSelectedSpell(self) and self.type.getSelectedSpell(self).id == spellId then
                    self.type.clearSelectedCastable(self)
                end
            end
            API.setDirtyDelayed()
        end,
        onSave = function()
            return {
                pinned = API.getStat(C.TrackedStats.PINNED) or {},
                hidden = API.getStat(C.TrackedStats.HIDDEN) or {},
                deletedSpells = API.getStat(C.TrackedStats.DELETED_SPELLS) or {},
            }
        end,
        onFrame = function()
            API.onFrame()
            lastSelectedCastable = self.type.getSelectedSpell(self) or self.type.getSelectedEnchantedItem(self)
            lastEquipment = self.type.getEquipment(self)
        end,
        onMouseWheel = function(v, h)
            API.onMouseWheel(v, h)
        end,
    },
}