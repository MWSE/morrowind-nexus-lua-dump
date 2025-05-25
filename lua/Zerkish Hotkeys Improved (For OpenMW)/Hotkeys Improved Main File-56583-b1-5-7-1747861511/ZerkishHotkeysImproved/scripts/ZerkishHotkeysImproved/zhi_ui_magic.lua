-- Zerkish Improved Hotkeys - zhi_ui_magic.lua
-- Reimplementation of the QuickKey Magic Selection screen

local Actor     = require('openmw.types').Actor
local types     = require('openmw.types')
local core      = require('openmw.core')
local SpellType = require('openmw.core').SpellType
local self      = require('openmw.self')
local I         = require('openmw.interfaces')
local util      = require('openmw.util')
local ui        = require('openmw.ui')
local async     = require('openmw.async')
local input     = require('openmw.input')

local constants = require('scripts.omw.mwui.constants')

local ZHIUI         = require('scripts.ZerkishHotkeysImproved.zhi_ui')
local ZHIUtil       = require('scripts.ZerkishHotkeysImproved.zhi_util')
local ZHIScrollbar  = require('scripts.ZerkishHotkeysImproved.zhi_scrollbar')
local ZHITooltip    = require('scripts.ZerkishHotkeysImproved.zhi_tooltip')

local ZHIUI_MAGIC_CONSTANTS = {
    WindowWidth = 320,
    WindowHeight = 380,

    WindowHeaderHeight = 32,
    HeaderTextSize = 20,

    OuterHPadding = 8,

    ContentPanelWidth = 300,
    ContentPanelHeight = 300,
    ContentItemHeight = 22,

    ContentCategoryTextSize = 18,
    ContentItemTextSize = 18,

    ColorEquipped               = constants.normalColor,
    ColorEquippedHighlight      = constants.headerColor,
    ColorActivated              = util.color.rgb(0.35, 0.35, 0.75),
    ColorActivatedHighlight     = util.color.rgb(0.65, 0.65, 0.95),
    ColorUnequipped             = util.color.rgb(0.7, 0.66, 0.55),
    ColorUnequippedHighlight    = util.color.rgb(0.85, 0.81, 0.70),
    ColorSelectItemUI           = util.color.rgb(0.95, 0.95, 0.95),

    ITEMSELECTION_STATE = {
        Normal = 1,
        Highlight = 2,
        Pressed = 3,
    },

    ITEM_STATE = {
        Normal = 1,
        Equipped = 2,
        Activated = 3,
    },

    RESULT_TYPE = {
        Item = 1,
        PowerOrSpell = 2,
    },

    TooltipMaxHeight = 400,
}

local colorLookupMatrix = {
    -- ITEM_STATE.Normal
    { ZHIUI_MAGIC_CONSTANTS.ColorUnequipped, ZHIUI_MAGIC_CONSTANTS.ColorUnequippedHighlight, ZHIUI_MAGIC_CONSTANTS.ColorSelectItemUI, },
    -- ITEM_STATE.Equipped
    { ZHIUI_MAGIC_CONSTANTS.ColorEquipped, ZHIUI_MAGIC_CONSTANTS.ColorEquippedHighlight, ZHIUI_MAGIC_CONSTANTS.ColorSelectItemUI, },
    -- ITEM_STATE.Activated
    { ZHIUI_MAGIC_CONSTANTS.ColorActivated, ZHIUI_MAGIC_CONSTANTS.ColorActivatedHighlight, ZHIUI_MAGIC_CONSTANTS.ColorSelectItemUI,},
}

local function getColorForLine(isActive, isEquipped, uiItemState)
    if isActive then
        return colorLookupMatrix[ZHIUI_MAGIC_CONSTANTS.ITEM_STATE.Activated][uiItemState]
    elseif isEquipped then
        return colorLookupMatrix[ZHIUI_MAGIC_CONSTANTS.ITEM_STATE.Equipped][uiItemState]
    else
        return colorLookupMatrix[ZHIUI_MAGIC_CONSTANTS.ITEM_STATE.Normal][uiItemState]
    end
end

local function resetSelectableLine(layout)
    if layout == nil then return end
    local text = ZHIUtil.findLayoutByNameRecursive(layout.content, 'text')
    if text then
        text.props.textColor = getColorForLine(layout.userData.isCurrentlyActive, layout.userData.isEquippedItem, ZHIUI_MAGIC_CONSTANTS.ITEMSELECTION_STATE.Normal)
    end
end

local function createSelectableLine(lineText, isCurrentlyActive, isEquippedItem, callbacks)

    local lineLayout = {
        type = ui.TYPE.Flex,
        props = {
            propagateEvents = false,
            autoSize = false,
            size = util.vector2(ZHIUI_MAGIC_CONSTANTS.ContentPanelWidth, ZHIUI_MAGIC_CONSTANTS.ContentItemHeight),
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content({
            -- Text
            {
                type = ui.TYPE.Text,
                name = 'text',
                props = {
                    propagateEvents = true,
                    --propagateEvents = true,
                    text = lineText,
                    textSize = ZHIUI_MAGIC_CONSTANTS.ContentItemTextSize,
                    textColor = getColorForLine(isCurrentlyActive, isEquippedItem, ZHIUI_MAGIC_CONSTANTS.ITEMSELECTION_STATE.Normal),
                },
            },
        }),
    }

    local textHandle = ZHIUtil.findLayoutByNameRecursive(lineLayout.content, 'text')
    local hasFocus = false

    local function onMouseMove(evt, layout)
        if callbacks and callbacks.onMouseMove then
            callbacks.onMouseMove(evt, lineLayout)
        end
    end

    local function onMousePress(evt)
        if textHandle then
            textHandle.props.textColor = getColorForLine(isCurrentlyActive, isEquippedItem, ZHIUI_MAGIC_CONSTANTS.ITEMSELECTION_STATE.Pressed)
            I.ZHI.updateUI()
        end
        I.ZHI.playSound(ZHIUI.ZHIUI_CONSTANTS.MenuClickSound)
        return false
    end

    local function onMouseRelease(evt)
        if textHandle then
            if hasFocus then
                textHandle.props.textColor = getColorForLine(isCurrentlyActive, isEquippedItem, ZHIUI_MAGIC_CONSTANTS.ITEMSELECTION_STATE.Highlight)
            else
                textHandle.props.textColor = getColorForLine(isCurrentlyActive, isEquippedItem, ZHIUI_MAGIC_CONSTANTS.ITEMSELECTION_STATE.Normal)
            end

            -- Check that we're in bounds after releasing the button.
            if (evt.offset.x >= 0 and evt.offset.x <= ZHIUI_MAGIC_CONSTANTS.ContentPanelWidth) and
                (evt.offset.y >= 0 and evt.offset.y <= ZHIUI_MAGIC_CONSTANTS.ContentItemTextSize) then                
                if callbacks and callbacks.onSelectItem then callbacks.onSelectItem(lineLayout.userData) end
            end

            I.ZHI.updateUI()
        end
        return true
    end

    local function onFocusGain()
        hasFocus = true
        if textHandle then
            textHandle.props.textColor = getColorForLine(isCurrentlyActive, isEquippedItem, ZHIUI_MAGIC_CONSTANTS.ITEMSELECTION_STATE.Highlight)
            if callbacks and callbacks.onFocusItem then callbacks.onFocusItem(lineLayout) end
            I.ZHI.updateUI()
        end
        return false
    end

    local function onFocusLoss()
        hasFocus = false
        if textHandle then
            textHandle.props.textColor = getColorForLine(isCurrentlyActive, isEquippedItem, ZHIUI_MAGIC_CONSTANTS.ITEMSELECTION_STATE.Normal)
            if callbacks and callbacks.onFocusLossItem then callbacks.onFocusLossItem(lineLayout) end
            I.ZHI.updateUI()
        end
        return false
    end

    lineLayout.userData = {
        onResetItem = resetSelectableLine,
        isCurrentlyActive = isCurrentlyActive,
        isEquippedItem = isEquippedItem,
    }

    lineLayout.events = {
        mousePress = async:callback(onMousePress),
        mouseRelease = async:callback(onMouseRelease),
        focusGain = async:callback(onFocusGain),
        focusLoss = async:callback(onFocusLoss),
        mouseMove = async:callback(onMouseMove),
    }

    return lineLayout
end

local function isSpellSelected(spell)
    local selectedSpell = Actor.getSelectedSpell(self.object)
    if selectedSpell == nil then return false end

    return selectedSpell.id == spell.id
end

local function addGreaterPowers(items, callbacks)
    local actorSpells = Actor.spells(self.object)

    local temp = {}

    for i=1, #actorSpells do
        if actorSpells[i].type == core.magic.SPELL_TYPE.Power then

            -- local nCallback = ZHIUtil.bindFunction(callback, {
            --     resultType = ZHIUI_MAGIC_CONSTANTS.RESULT_TYPE.PowerOrSpell,
            --     spell = actorSpells[i],
            -- })

            local line = createSelectableLine(actorSpells[i].name, isSpellSelected(actorSpells[i]), true, callbacks)
            line.userData.resultType = ZHIUI_MAGIC_CONSTANTS.RESULT_TYPE.PowerOrSpell
            line.userData.spell = actorSpells[i]
            table.insert(temp, line)
        end
    end
    if #temp > 0 then
        table.sort(temp, function (a, b) 
            return a.content[1].props.text < b.content[1].props.text
        end)
        table.move(temp, 1, #temp, #items + 1, items)
    end
end

local function addKnownSpells(items, callbacks)
    local actorSpells = Actor.spells(self.object)

    local temp = {}

    for i=1, #actorSpells do
        if actorSpells[i].type == core.magic.SPELL_TYPE.Spell then
            
            -- local nCallback = ZHIUtil.bindFunction(callback, {
            --     resultType = ZHIUI_MAGIC_CONSTANTS.RESULT_TYPE.PowerOrSpell,
            --     spell = actorSpells[i],
            -- })
            local line = createSelectableLine(actorSpells[i].name, isSpellSelected(actorSpells[i]), true, callbacks)
            line.userData.resultType = ZHIUI_MAGIC_CONSTANTS.RESULT_TYPE.PowerOrSpell
            line.userData.spell = actorSpells[i]

            table.insert(temp, line)
        end
    end

    if #temp > 0 then
        table.sort(temp, function (a, b) 
            return a.content[1].props.text < b.content[1].props.text
        end)
        table.move(temp, 1, #temp, #items + 1, items)
    end
end

local function isEnchantmentRecordCastable(record) 
    return record.type == core.magic.ENCHANTMENT_TYPE.CastOnUse or record.type == core.magic.ENCHANTMENT_TYPE.CastOnce
end

local function addSpellsFromItems(items, callbacks)
    local inventory = Actor.inventory(self.object)
    
    local allItems = inventory:getAll()

    local temp = {}

    for i=1, #allItems do
        local item = allItems[i]
        local record = item.type.records[item.recordId]

        if record and record.enchant then
            local isEquipped = Actor.hasEquipped(self.object, item)
            local enchantmentRecord = core.magic.enchantments.records[record.enchant]
            local isCastable = isEnchantmentRecordCastable(enchantmentRecord)

            --local selectedSpell = Actor.getSelectedSpell(self.object)
            local selectedEnchantedItem = Actor.getSelectedEnchantedItem(self.object)
            local isActive = false
            if selectedEnchantedItem then
                isActive = selectedEnchantedItem.id == item.id
            end

            if isCastable then
                -- local nCallback = ZHIUtil.bindFunction(callback, {
                --     resultType = ZHIUI_MAGIC_CONSTANTS.RESULT_TYPE.Item,
                --     item = item,
                -- })
                local text = record.name
                if item.count > 1 then
                    text = string.format("%s (%d)", text, item.count)
                end
                local line = createSelectableLine(text, isActive, isEquipped, callbacks)
                line.userData.resultType = ZHIUI_MAGIC_CONSTANTS.RESULT_TYPE.Item
                line.userData.item= item
                table.insert(temp, line)
            end
        end
    end

    if #temp > 0 then
        table.sort(temp, function (a, b) 
            return a.content[1].props.text < b.content[1].props.text
        end)
        table.move(temp, 1, #temp, #items + 1, items)
    end
end

local function addSpellCategoryHeader(items, name)
    table.insert(items, {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            size = util.vector2(ZHIUI_MAGIC_CONSTANTS.ContentPanelWidth, ZHIUI_MAGIC_CONSTANTS.ContentItemHeight),
            align = ui.ALIGNMENT.End,
        },
        content = ui.content({
            {
                type = ui.TYPE.Text,
                props = {
                    text = name,
                    textSize = ZHIUI_MAGIC_CONSTANTS.ContentCategoryTextSize,
                    textColor = constants.headerColor,
                }
            }
        })
    })
end

local function addSpellCategorySpacer(items)

    local padding = ZHIUI_MAGIC_CONSTANTS.ContentItemHeight - constants.border
    local padTop = padding * 0.5
    local padBottom = padding * 0.5

    --local lineSize = util.vector2(ZHI_UIM_CONSTANTS.ContentPanelWidth - ZHI_UIM_CONSTANTS.OuterHPadding * 2, constants.border)
    local lineSize = util.vector2(100, constants.border)

    table.insert(items, {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            size = util.vector2(ZHIUI_MAGIC_CONSTANTS.ContentPanelWidth - constants.thickBorder * 2, ZHIUI_MAGIC_CONSTANTS.ContentItemHeight),
        },
        content = ui.content({
            -- Padding Above
            {
                type = ui.TYPE.Flex,
                props = { autoSize = false, size = util.vector2(ZHIUI_MAGIC_CONSTANTS.ContentPanelWidth, padTop) }
            },
            {
                template = I.MWUI.templates.horizontalLine,
                type = ui.TYPE.Image,
                props = {
                    autoSize = false,
                    size = lineSize,
                }
            },
            -- Padding Below
            {
                type = ui.TYPE.Flex,
                props = { autoSize = false, size = util.vector2(ZHIUI_MAGIC_CONSTANTS.ContentPanelWidth, padBottom) }
            },
        })
    })
end

local function createSpellList(callbacks)
    local spellPlaceholders = {}

    addSpellCategoryHeader(spellPlaceholders, 'Powers')
    addGreaterPowers(spellPlaceholders, callbacks)
    addSpellCategorySpacer(spellPlaceholders)
    addSpellCategoryHeader(spellPlaceholders, 'Spells')
    addKnownSpells(spellPlaceholders, callbacks)
    addSpellCategorySpacer(spellPlaceholders)
    addSpellCategoryHeader(spellPlaceholders, 'Magical Items')
    addSpellsFromItems(spellPlaceholders, callbacks)

    return spellPlaceholders
end

return {

    RESULT_TYPE = ZHIUI_MAGIC_CONSTANTS.RESULT_TYPE,

    -- resultCallback is called with either:
    -- nil (canceled)
    -- table { 
    --     resultType : RESULT_TYPE
    --      
    --      -- if resultType is Item
    --      item : openmw.types.Item
    --      -- if resultType is PowerOrSpell
    --      spell : openmw.core.magic.Spell
    -- }
    createMagicSelectionWindow = function(callbacks)

        local header = {
            type = ui.TYPE.Flex,

            props = {
                autoSize = false,
                size = util.vector2(ZHIUI_MAGIC_CONSTANTS.WindowWidth, ZHIUI_MAGIC_CONSTANTS.WindowHeaderHeight),  --ZHI_UIM_CONSTANTS.SelectorHeaderSize,
                align = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Center,
            },

            content = ui.content({
                {
                    type = ui.TYPE.Text,
                    props = {
                        textSize = ZHIUI_MAGIC_CONSTANTS.HeaderTextSize,
                        textColor = constants.normalColor,
                        text = 'Select a Magic to Quick key.'
                    },
                }
            })
        }

        local spellItems = createSpellList(callbacks)

        local lineSize = util.vector2(ZHIUI_MAGIC_CONSTANTS.ContentPanelWidth, ZHIUI_MAGIC_CONSTANTS.ContentItemHeight)
        local scrollContent = ZHIUI.createVerticalScrollPane(spellItems, lineSize, util.vector2(ZHIUI_MAGIC_CONSTANTS.ContentPanelWidth, ZHIUI_MAGIC_CONSTANTS.ContentPanelHeight))

        scrollContent.name = 'ms_scrollcontent'

        local scrollbar = ZHIUtil.findLayoutByNameRecursive(scrollContent.content, 'vpane_scrollbar')
        scrollContent.userData = {
            scrollbar = scrollbar,
        }

        local vpaneContent = ZHIUtil.findLayoutByNameRecursive(scrollContent.content, 'outerContent')

        local contentContainer = {
            template = I.MWUI.templates.boxSolid,
            type = ui.TYPE.Container,
            props = {
                position = util.vector2(ZHIUI_MAGIC_CONSTANTS.OuterHPadding, ZHIUI_MAGIC_CONSTANTS.WindowHeaderHeight),
                --relativePosition = util.vector2(0.5, 0),
            },

            content = ui.content({
                scrollContent,
            })
        }

        local footer = {
            type = ui.TYPE.Flex,

            props = {
                autoSize = false,
                horizontal = true,
                size = util.vector2(ZHIUI_MAGIC_CONSTANTS.WindowWidth, ZHIUI_MAGIC_CONSTANTS.WindowHeaderHeight), --ZHI_UIM_CONSTANTS.SelectorHeaderSize,
                align = ui.ALIGNMENT.End,
                arrange = ui.ALIGNMENT.End,
            },

            content = ui.content({
                ZHIUI.createTextButton('Cancel', callbacks.onSelectItem),
                {
                    props = {
                        position = util.vector2(ZHIUI_MAGIC_CONSTANTS.OuterHPadding, 1);
                        size = util.vector2(ZHIUI_MAGIC_CONSTANTS.OuterHPadding, 1),
                        relativePosition = util.vector2(1, 1),
                    }
                }
            })
        }
        

        local fullContent = {
            type = ui.TYPE.Flex,
            props = {
                autoSize = false,
                size = util.vector2(ZHIUI_MAGIC_CONSTANTS.WindowWidth, ZHIUI_MAGIC_CONSTANTS.WindowHeight),
                alignment = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Center,
            },

            content = ui.content({
                header,
                contentContainer,
                footer,
            })
        }

        local rootWindow = {
            template = I.MWUI.templates.boxSolidThick,
            type = ui.TYPE.Container,
            layer = I.ZHI.getPopupLayer(),
            props = {
                anchor = util.vector2(0.5, 0.5),
                relativePosition = I.ZHI.getWindowAnchor(),
            },
            userData = {
                scrollbar = scrollbar,
                content = vpaneContent,
            },
            content = ui.content({
                fullContent,
            })
        }

        return ui.create(rootWindow)
    end,

    scrollContent = function(msWindow, vWheelInput)
        if (math.abs(vWheelInput) == 0) then
            return
        end

        if not (msWindow and msWindow.layout.userData and msWindow.layout.userData.scrollbar) then
            return
        end

        local content, scrollbar = msWindow.layout.userData.content, msWindow.layout.userData.scrollbar

        local dir = vWheelInput / math.abs(vWheelInput)

        ZHIUI.vScrollPaneMoveScrollbarByItems(content, scrollbar, -dir * 2)
        ZHIUI.vScrollpaneSetContentPositionFromScrollbarPosition(content, scrollbar)
        I.ZHI.updateUI()
    end,

    showTooltip = function(msWindow, lineLayout, position)
        --local tooltipPane = msWindow.layout.userData.tooltipPane

        local data = {}

        if lineLayout.userData.resultType == ZHIUI_MAGIC_CONSTANTS.RESULT_TYPE.PowerOrSpell then
            data.spell = lineLayout.userData.spell
        elseif lineLayout.userData.resultType == ZHIUI_MAGIC_CONSTANTS.RESULT_TYPE.Item then
            data.item = {
                itemId = lineLayout.userData.item.id,
                recordId = lineLayout.userData.item.recordId,
                itemType = lineLayout.userData.item.type,
            }
        end

        ZHITooltip.updateTooltip(position, data)


        -- if #tooltipPane.content > 0 then
        --     ZHITooltip.setTooltipData(tooltipPane.content[1], data)
        --     tooltipPane.content[1].props.visible = true
        -- else
        --     local tooltip = ZHITooltip.createTooltip(data)
        --     tooltip.props.anchor = util.vector2(0.5, 0.0)
        --     tooltip.props.relativePosition = util.vector2(0.5, 0.0)
        --     tooltipPane.content = ui.content({tooltip})
        -- end
    end,

    hideTooltip = function(msWindow, lineLayout)
        -- local tooltipPane = msWindow.layout.userData.tooltipPane
        -- if #tooltipPane.content > 0 then
        --     tooltipPane.content[1].props.visible = false
        -- end

        ZHITooltip.updateTooltip(nil, nil)
    end
}
