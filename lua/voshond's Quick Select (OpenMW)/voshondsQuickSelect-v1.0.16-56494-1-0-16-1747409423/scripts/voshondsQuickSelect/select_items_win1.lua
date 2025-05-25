local I = require("openmw.interfaces")
local ambient = require('openmw.ambient')
local async = require("openmw.async")
local core = require("openmw.core")
local self = require("openmw.self")
local ui = require("openmw.ui")
local util = require("openmw.util")
local types = require("openmw.types")
local input = require("openmw.input")
local Debug = require("scripts.voshondsquickselect.qs_debug")
local storage = require('openmw.storage')
local settings = storage.playerSection("SettingsVoshondsQuickSelect")
local textSettings = storage.playerSection("SettingsVoshondsQuickSelectText")

-- Function to get text appearance settings
local function getTextStyles()
    -- Get color settings or use defaults
    local textColor = textSettings:get("slotTextColor") or util.color.rgba(0.792, 0.647, 0.376, 1.0)
    local shadowColor = textSettings:get("slotTextShadowColor") or util.color.rgba(0, 0, 0, 1.0)

    -- Get alpha settings (0-100) and convert to 0-1 range
    local textAlpha = (textSettings:get("slotTextAlpha") or 100) / 100
    local shadowAlpha = (textSettings:get("slotTextShadowAlpha") or 100) / 100

    -- Apply alpha values to colors
    local finalTextColor = util.color.rgba(textColor.r, textColor.g, textColor.b, textAlpha)
    local finalShadowColor = util.color.rgba(shadowColor.r, shadowColor.g, shadowColor.b, shadowAlpha)

    -- Check if shadow is enabled
    local shadowEnabled = textSettings:get("enableTextShadow")
    if shadowEnabled == nil then shadowEnabled = true end -- Default to true if not set

    -- Check if slot numbers and item counts should be shown
    local showSlotNumbers = textSettings:get("showSlotNumbers")
    if showSlotNumbers == nil then showSlotNumbers = true end -- Default to true if not set

    local showItemCounts = textSettings:get("showItemCounts")
    if showItemCounts == nil then showItemCounts = true end -- Default to true if not set

    -- Get text sizes
    local slotNumberTextSize = textSettings:get("slotNumberTextSize") or 14
    local itemCountTextSize = textSettings:get("itemCountTextSize") or 12

    return {
        textColor = finalTextColor,
        shadowColor = finalShadowColor,
        shadowEnabled = shadowEnabled,
        showSlotNumbers = showSlotNumbers,
        showItemCounts = showItemCounts,
        slotNumberTextSize = slotNumberTextSize,
        itemCountTextSize = itemCountTextSize
    }
end

-- Define reusable text style variables
local TEXT_COLORS = {
    itemCount = nil, -- Will be set dynamically
    slotNumber = nil -- Will be set dynamically
}

local TEXT_SHADOWS = {
    enabled = true, -- Will be set dynamically
    color = nil     -- Will be set dynamically
}

-- Function to refresh text style settings
local function refreshTextStyles()
    local styles = getTextStyles()

    TEXT_COLORS.itemCount = styles.textColor
    TEXT_COLORS.slotNumber = styles.textColor

    TEXT_SHADOWS.enabled = styles.shadowEnabled
    TEXT_SHADOWS.color = styles.shadowColor
end

-- Initialize text styles
refreshTextStyles()

-- Create a dedicated tooltip layer on top of everything else
local function initTooltipLayer()
    -- Check if the layer already exists to avoid errors
    local tooltipLayerExists = false
    for i, layer in ipairs(ui.layers) do
        if layer.name == "TooltipLayer" then
            tooltipLayerExists = true
            Debug.log("SelectItemsWin", "TooltipLayer already exists, skipping creation")
            break
        end
    end

    if not tooltipLayerExists then
        -- Instead of trying to insert after a specific layer which may not exist,
        -- we'll try to append it to the end of the layers list which ensures it's on top

        -- Wrap layer creation in pcall to catch errors
        local success, err = pcall(function()
            local layerCount = #ui.layers
            if layerCount > 0 then
                -- Add it after the topmost existing layer
                local topLayerName = ui.layers[layerCount].name
                ui.layers.insertAfter(topLayerName, "TooltipLayer", { interactive = false })
            else
                -- If no layers exist yet (unlikely), create a Windows layer and insert after it
                if not ui.layers.indexOf("Windows") then
                    -- Create a Windows layer first if it doesn't exist
                    ui.layers.insertAfter("HUD", "Windows", { interactive = true })
                end
                ui.layers.insertAfter("Windows", "TooltipLayer", { interactive = false })
            end
        end)

        -- If it failed, the layer might have been created by another script in the meantime
        if not success then
            Debug.warning("SelectItemsWin", "TooltipLayer creation failed: " .. tostring(err))
            -- Let's check if the layer exists now after the error
            for i, layer in ipairs(ui.layers) do
                if layer.name == "TooltipLayer" then
                    -- Layer exists now, we can proceed
                    Debug.log("SelectItemsWin", "TooltipLayer created by another script, continuing")
                    return
                end
            end
            -- If we get here, something else went wrong, but we'll continue without the layer
            Debug.warning("SelectItemsWin", "Continuing without TooltipLayer, will use HUD instead")
        else
            Debug.log("SelectItemsWin", "Successfully created TooltipLayer")
        end
    end
end

-- Comment out the immediate initialization to prevent race conditions with other scripts
-- initTooltipLayer()

-- We'll initialize the tooltip layer in onLoad instead
local utility = require("scripts.voshondsquickselect.qs_utility")
local tooltipData = require("scripts.voshondsquickselect.ci_tooltipgen")
local messageBoxUtil = require("scripts.voshondsquickselect.messagebox")
local QuickSelectWindow
local hoveredOverId
local spellMode = false
local columnsAndRows = {}
local selectedCol = 1
local selectedRow = 1
local startOffset = 0
local maxCount = 0
local num = 1
local scale = 0.8
local tooltip
local lis = {}

local slotToSave

local ICON_SIZE = 40
local ICON_PADDING_MULTIPLIER = 1.2
local ITEMS_PER_ROW = 10

local function mouseMove(mouseEvent, data)
    if tooltip then
        tooltip:destroy()
        tooltip = nil
    end

    -- Choose the layer to use - check if TooltipLayer exists, otherwise fall back to HUD
    local layerToUse = "HUD"
    for i, layer in ipairs(ui.layers) do
        if layer.name == "TooltipLayer" then
            layerToUse = "TooltipLayer"
            break
        end
    end

    if data.data.item then
        tooltip = utility.drawListMenu(tooltipData.genToolTips(data.data.item),
            utility.itemWindowLocs.BottomCenter, nil, layerToUse)
        -- ui.showMessage("Mouse moving over icon" .. data.item.recordId)
    elseif data.data.data.spell then
        local spellRecord = core.magic.spells.records[data.data.data.spell]
        -- Debug.items("Spell data: " .. tostring(data.data.data.spell))
        tooltip = utility.drawListMenu(tooltipData.genToolTips({ spell = spellRecord }),
            utility.itemWindowLocs.BottomCenter, nil, layerToUse)
    end
end
local function mouseClick(mouseEvent, data)
    local id = data.id
    if data.props.spellData or data.spellData then
        local spell = data.props.spellData

        if not spell.id then
            -- Debug.items("No id found")
        end
        if spell.enchant then
            I.QuickSelect_Storage.saveStoredEnchantData(spell.enchant, spell.id, slotToSave)
            --   ui.showMessage("Saved enchant to slot " .. slotToSave)
        else
            I.QuickSelect_Storage.saveStoredSpellData(spell.id, "Spell", slotToSave)

            --  ui.showMessage("Saved spell to slot " .. slotToSave)
        end
        if QuickSelectWindow then
            QuickSelectWindow:destroy()
            QuickSelectWindow = nil
        end
        if tooltip then
            tooltip:destroy()
            tooltip = nil
        end
        I.UI.setMode()
        slotToSave = nil
        return
    else
    end
    if tooltip then
        tooltip:destroy()
        tooltip = nil
    end
    if data.data then
        if not slotToSave then
            messageBoxUtil.showMessageBox(nil, { core.getGMST("sQuickMenu1") },
                { core.getGMST("sQuickMenu2"), core.getGMST("sQuickMenu3"), core.getGMST("sQuickMenu4"), core.getGMST(
                    "sCancel") })
            -- ui.showMessage("Mouse moving over icon" .. data.item.recordId)
            if QuickSelectWindow then
                QuickSelectWindow:destroy()
                QuickSelectWindow = nil
            end
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            slotToSave = data.data.num
        elseif data.data.item then
            I.QuickSelect_Storage.saveStoredItemData(data.data.item.recordId, slotToSave)
            if QuickSelectWindow then
                QuickSelectWindow:destroy()
                QuickSelectWindow = nil
            end
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            I.UI.setMode()
            slotToSave = nil
        end
    end
end
local function mouseMoveButton(event, data)
    if not QuickSelectWindow.layout.content[1].content[3].content[1].content[1].content then
        return
    end
    local sdata = data.props.spellData

    if tooltip then
        tooltip:destroy()
        tooltip = nil
    end

    -- Choose the layer to use - check if TooltipLayer exists, otherwise fall back to HUD
    local layerToUse = "HUD"
    for i, layer in ipairs(ui.layers) do
        if layer.name == "TooltipLayer" then
            layerToUse = "TooltipLayer"
            break
        end
    end

    if sdata.id and sdata.enchant then
        local item = types.Actor.inventory(self):find(sdata.id)
        -- print(item)
        -- Debug.items("Item: " .. tostring(item))
        tooltip = utility.drawListMenu(tooltipData.genToolTips(item),
            utility.itemWindowLocs.BottomCenter, nil, layerToUse)
        -- ui.showMessage("Mouse moving over icon" .. data.item.recordId)
    elseif sdata.id then
        local spellRecord = core.magic.spells.records[sdata.id]
        -- Debug.items("Spell data: " .. tostring(data.data.data.spell))
        tooltip = utility.drawListMenu(tooltipData.genToolTips({ spell = spellRecord }),
            utility.itemWindowLocs.BottomCenter, nil, layerToUse)
    end
    for index, value in ipairs(QuickSelectWindow.layout.content[1].content[3].content[1].content[1].content) do
        local sdata = QuickSelectWindow.layout.content[1].content[3].content[1].content[1].content[index].content[1]
            .content[1].props.spellData
        if not sdata or not sdata.bold then
            QuickSelectWindow.layout.content[1].content[3].content[1].content[1].content[index].content[1].content[1].template =
                I.MWUI.templates.textNormal
        end
    end
    data.template = I.MWUI.templates.textHeader

    QuickSelectWindow:update()
end
local function renderButton(text)
    local itemTemplate
    itemTemplate = I.MWUI.templates.borders

    return {
        type = ui.TYPE.Container,
        --  events = {},
        template = itemTemplate,
        content = ui.content { utility.renderItemBold(text) },
    }
end
local function getSkillBase(skillID, actor)
    return types.NPC.stats.skills[skillID:lower()](actor).base
end

-- Add a helper function to create custom icon content with our fixed size
local function createCustomIcon(item, xicon, num, prefix)
    local icon

    if item and not xicon then
        -- Create a custom item icon with fixed size
        local record = item.type.records[item.recordId]
        local itemIcon = ui.texture({ path = record.icon })

        -- Check if item has an enchantment and add magic background
        local hasEnchantment = false
        local magicBgIcon = nil

        if record.enchant and record.enchant ~= "" then
            hasEnchantment = true
            magicBgIcon = ui.texture({ path = "textures/menu_icon_magic_mini.dds" })
        end

        local content = {
            type = ui.TYPE.Image,
            props = {
                resource = itemIcon,
                size = util.vector2(ICON_SIZE, ICON_SIZE),
                arrange = ui.ALIGNMENT.Center,
                align = ui.ALIGNMENT.Center
            }
        }

        -- Build the content with magic background if needed
        local iconContent = {}

        if hasEnchantment then
            table.insert(iconContent, {
                type = ui.TYPE.Image,
                props = {
                    resource = magicBgIcon,
                    size = util.vector2(ICON_SIZE, ICON_SIZE),
                    alpha = 0.3, -- Match the opacity used in the hotbar
                    arrange = ui.ALIGNMENT.Center,
                    align = ui.ALIGNMENT.Center
                }
            })
        end

        table.insert(iconContent, content)

        -- Include count text if applicable and enabled
        local styles = getTextStyles()
        if item.count > 1 and styles.showItemCounts then
            icon = ui.content(iconContent)

            -- Refresh text styles to ensure we have the latest settings
            refreshTextStyles()

            table.insert(icon, {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textHeader,
                props = {
                    text = tostring(item.count),
                    textSize = styles.itemCountTextSize,
                    relativePosition = util.vector2(0.1, 0.1),
                    anchor = util.vector2(0.1, 0.1),
                    arrange = ui.ALIGNMENT.Start,
                    align = ui.ALIGNMENT.Start,
                    textShadow = TEXT_SHADOWS.enabled,
                    textShadowColor = TEXT_SHADOWS.color,
                    textColor = TEXT_COLORS.itemCount
                }
            })
        else
            icon = ui.content(iconContent)
        end
    elseif xicon then
        -- Create a custom spell icon with fixed size
        local iconTexture = ui.texture({ path = xicon })

        icon = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = iconTexture,
                    size = util.vector2(ICON_SIZE - 4, ICON_SIZE - 4), -- -4 due to padding
                    arrange = ui.ALIGNMENT.Center,
                    align = ui.ALIGNMENT.Center
                }
            }
        }
    end

    return icon
end

local function createHotbarItem(item, xicon, num, data)
    local icon
    local prefix = ""
    local displayNum = num

    -- Adjust display number for different hotbars
    if num > 20 then
        -- Ctrl hotbar (3rd hotbar)
        prefix = "c"
        displayNum = num - 20
    elseif num > 10 then
        -- Shift hotbar (2nd hotbar)
        prefix = "s"
        displayNum = num - 10
    end

    -- Convert 10 to 0 for display
    if displayNum == 10 then displayNum = 0 end

    if item and not xicon then
        icon = createCustomIcon(item, nil, num, prefix)
    elseif xicon then
        icon = createCustomIcon(nil, xicon, num, prefix)
    elseif num then
        -- Only create number text if slot numbers are enabled
        local styles = getTextStyles()
        if styles.showSlotNumbers then
            icon = ui.content {
                {
                    type = ui.TYPE.Text,
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = prefix .. tostring(displayNum),
                        textSize = styles.slotNumberTextSize,
                        relativePosition = util.vector2(0.85, 0.9),
                        anchor = util.vector2(0.85, 0.9),
                        arrange = ui.ALIGNMENT.End,
                        align = ui.ALIGNMENT.End,
                        textShadow = TEXT_SHADOWS.enabled,
                        textShadowColor = TEXT_SHADOWS.color,
                        textColor = TEXT_COLORS.slotNumber
                    },
                    item = item,
                    num = num,
                    events = {
                        --          mouseMove = async:callback(mouseMove),
                    },
                }
            }
        else
            -- Create empty content if slot numbers are disabled
            icon = ui.content {}
        end
    end

    -- Use fixed icon size
    local iconSize = ICON_SIZE

    local boxedIcon = utility.renderItemBoxed(icon, util.vector2(iconSize, iconSize), nil,
        util.vector2(0.5, 0.5),
        { item = item, num = num, data = data }, {
            mouseMove = async:callback(mouseMove),
            mouseClick = async:callback(mouseClick),
        })

    local padding = utility.renderItemBoxed(ui.content { boxedIcon },
        util.vector2(iconSize * ICON_PADDING_MULTIPLIER, iconSize * ICON_PADDING_MULTIPLIER),
        I.MWUI.templates.padding)
    return padding
end
local function getHotbarItems()
    local items = {}
    local inv = types.Actor.inventory(self):getAll()
    local count = num + 10
    while num < count do
        local data = I.QuickSelect_Storage.getFavoriteItemData(num)
        local item
        local effect
        local icon
        if data.item then
            item = types.Actor.inventory(self):find(data.item)
        elseif data.spell or data.enchantId or (data.spellType and data.spellType:lower() == "enchant") then
            if data.spellType:lower() == "spell" then
                local spell = types.Actor.spells(self)[data.spell]
                if spell then
                    effect = spell.effects[1]
                    icon = effect.effect.icon
                    --    ----print("Spell" .. data.spell)
                end
            elseif data.spellType:lower() == "enchant" then
                local enchant = utility.getEnchantment(data.enchantId)
                if enchant then
                    effect = enchant.effects[1]
                    icon = effect.effect.icon
                end
                item = types.Actor.inventory(self):find(data.itemId)
                -- print(item)
            elseif data.itemId then
                item = types.Actor.inventory(self):find(data.itemId)
            end
        end
        table.insert(items, createHotbarItem(item, icon, num, data))
        num = num + 1
    end
    return items
end
local function createItemIcon(item, spell, num)
    local icon
    if item and not spell then
        icon = createCustomIcon(item, nil, num)
    else
        return {}
    end

    -- Use fixed icon size
    local iconSize = ICON_SIZE

    local boxedIcon = utility.renderItemBoxed(icon, util.vector2(iconSize, iconSize), nil,
        util.vector2(0.5, 0.5),
        { item = item, num = num }, {
            mouseMove = async:callback(mouseMove),
            mouseClick = async:callback(mouseClick),
        })

    local padding = utility.renderItemBoxed(ui.content { boxedIcon },
        util.vector2(iconSize * ICON_PADDING_MULTIPLIER, iconSize * ICON_PADDING_MULTIPLIER),
        I.MWUI.templates.padding)
    return padding
end

local function getItemRow()
    local items = {}
    local inv = types.Actor.inventory(self):getAll()
    local count = num + 10

    maxCount = #inv
    while num < count do
        table.insert(items, createItemIcon(inv[num], nil, num))
        num = num + 1
    end
    return items
end

local function drawItemSelect()
    if QuickSelectWindow then
        QuickSelectWindow:destroy()
    end
    local xContent       = {}
    local content        = {}
    num                  = 1 + startOffset

    -- Calculate container width based on icon size
    -- Each row has 10 items plus some padding
    local containerWidth = ICON_SIZE * ICON_PADDING_MULTIPLIER * ITEMS_PER_ROW * 1.35

    table.insert(content, utility.renderItemBold(core.getGMST("sQuickMenu6")))
    table.insert(content, utility.renderItemBold("(Use mouse wheel to scroll)", nil, nil, nil, true))

    table.insert(content,
        utility.renderItemBoxed(utility.flexedItems(getItemRow(), true),
            utility.scaledVector2(containerWidth, ICON_SIZE * 1.5),
            I.MWUI.templates.padding,
            util.vector2(0.5, 0.5)))
    table.insert(content,
        utility.renderItemBoxed(utility.flexedItems(getItemRow(), true),
            utility.scaledVector2(containerWidth, ICON_SIZE * 1.5),
            I.MWUI.templates.padding,
            util.vector2(0.5, 0.5)))
    table.insert(content,
        utility.renderItemBoxed(utility.flexedItems(getItemRow(), true),
            utility.scaledVector2(containerWidth, ICON_SIZE * 1.5),
            I.MWUI.templates.padding,
            util.vector2(0.5, 0.5)))
    table.insert(content,
        utility.renderItemBoxed(utility.flexedItems(getItemRow(), true),
            utility.scaledVector2(containerWidth, ICON_SIZE * 1.5),
            I.MWUI.templates.padding,
            util.vector2(0.5, 0.5)))
    table.insert(content,
        utility.renderItemBoxed(utility.flexedItems(getItemRow(), true),
            utility.scaledVector2(containerWidth, ICON_SIZE * 1.5),
            I.MWUI.templates.padding,
            util.vector2(0.5, 0.5)))
    table.insert(content,
        utility.renderItemBoxed(utility.flexedItems(getItemRow(), true),
            utility.scaledVector2(containerWidth, ICON_SIZE * 1.5),
            I.MWUI.templates.padding,
            util.vector2(0.5, 0.5)))

    content = ui.content(content)
    QuickSelectWindow = ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = content,
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                }
            }
        }
    }
end
local function getAllEnchantments(actorInv, onlyCastable)
    local ret = {}
    for index, value in ipairs(actorInv:getAll()) do
        local ench = utility.FindEnchantment(value)
        if (ench and not onlyCastable) then
            table.insert(ret, { enchantment = ench, item = value })
        elseif ench and onlyCastable and (ench.type == core.magic.ENCHANTMENT_TYPE.CastOnUse or ench.type == core.magic.ENCHANTMENT_TYPE.CastOnce) then
            table.insert(ret, { enchantment = ench, item = value })
        end
    end
    return ret
end
local function compareNames(a, b)
    return a.name < b.name
end

local function drawSpellSelect()
    if QuickSelectWindow then
        QuickSelectWindow:destroy()
    end
    local xContent = {}
    local content  = {}
    num            = 1
    --local trainerRow = utility.renderItemBoxed({}, util.vector2((160 * scale) * 7, 400 * scale),
    ---    I.MWUI.templates.padding)

    table.insert(content, utility.renderItemBold(core.getGMST("sMagicSelectTitle")))
    table.insert(content, utility.renderItemBold("(Use mouse wheel to scroll)", nil, nil, nil, true))
    local spellsAndIds = {}
    local spellList = {}
    table.insert(spellsAndIds, { name = " Spells:", type = "", bold = true })
    for index, spell in ipairs(types.Actor.spells(self)) do
        if spell.type == core.magic.SPELL_TYPE.Power or spell.type == core.magic.SPELL_TYPE.Spell then
            table.insert(spellList, { id = spell.id, name = spell.name, type = "Spell" })
        end
    end
    table.sort(spellList, compareNames)
    for index, value in ipairs(spellList) do
        table.insert(spellsAndIds, value)
    end
    local enchL = getAllEnchantments(types.Actor.inventory(self), true)
    table.insert(spellsAndIds, { name = "Enchantments:", type = "", bold = true })

    local enchantList = {}
    for index, ench in ipairs(enchL) do
        -- if index > startOffset then
        table.insert(enchantList,
            {
                id = ench.item.recordId,
                name = ench.item.type.record(ench.item).name,
                type = "Enchant",
                enchant = ench
                    .item.type.record(ench.item).enchant
            })
        -- Debug.items("Enchantment name: " .. ench.item.type.record(ench.item).name)
        -- end
    end
    table.sort(enchantList, compareNames)
    for index, value in ipairs(enchantList) do
        table.insert(spellsAndIds, value)
    end
    maxCount = #spellsAndIds
    for i = 1, 30, 1 do
        local entry = spellsAndIds[i + startOffset]
        if entry then
            -- Fallback logic: use .name, then .id, then a placeholder
            local label = entry.name or entry.id or "<unnamed>"
            -- Only render if we have something to show
            if label and label ~= "" then
                table.insert(xContent,
                    utility.renderItemBold(label, nil, nil, nil, true,
                        entry, {
                            mouseMove = async:callback(mouseMoveButton),
                            mousePress = async:callback(mouseClick)
                        }))
            end
        end
    end
    table.insert(content,
        utility.renderItemBoxed(utility.flexedItems(xContent, false), utility.scaledVector2(400, 800),
            I.MWUI.templates.borders,
            util.vector2(0.5, 0.5)))
    content = ui.content(content)
    QuickSelectWindow = ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick
        ,
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = content,
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                    --    size = util.vector2(0, 0),
                }
            }
        }
    }
end
local function drawQuickSelect()
    if QuickSelectWindow then
        QuickSelectWindow:destroy()
    end
    local xContent       = {}
    local content        = {}
    num                  = 1

    -- Calculate container width based on icon size
    -- Each hotbar has 10 items plus some padding
    local containerWidth = ICON_SIZE * ICON_PADDING_MULTIPLIER * ITEMS_PER_ROW * 1.35

    table.insert(content, utility.renderItemBold(core.getGMST("sQuickMenuTitle")))
    table.insert(content, utility.renderItemBold(core.getGMST("sQuickMenuInstruc")))

    table.insert(content, utility.renderItemLeft("Hotbar 1 (1-0)"))
    table.insert(content,
        utility.renderItemBoxed(utility.flexedItems(getHotbarItems(), true),
            utility.scaledVector2(containerWidth, ICON_SIZE * 1.5),
            I.MWUI.templates.padding,
            util.vector2(0.5, 0.5)))

    table.insert(content, utility.renderItemLeft("Hotbar 2 (Shift 1-0)"))
    table.insert(content,
        utility.renderItemBoxed(utility.flexedItems(getHotbarItems(), true),
            utility.scaledVector2(containerWidth, ICON_SIZE * 1.5),
            I.MWUI.templates.padding,
            util.vector2(0.5, 0.5)))

    table.insert(content, utility.renderItemLeft("Hotbar 3 (Ctrl 1-0)"))
    table.insert(content,
        utility.renderItemBoxed(utility.flexedItems(getHotbarItems(), true),
            utility.scaledVector2(containerWidth, ICON_SIZE * 1.5),
            I.MWUI.templates.padding,
            util.vector2(0.5, 0.5)))

    content = ui.content(content)
    QuickSelectWindow = ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = content,
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                }
            }
        }
    }
end

local function openQuickSelect()
    --I.UI.setMode("Interface", { windows = {} })
    drawQuickSelect()
end

local function UiModeChanged(data)
    if not data.newMode then
        if QuickSelectWindow then
            QuickSelectWindow:destroy()
            QuickSelectWindow = nil
        end
        if tooltip then
            tooltip:destroy()
            tooltip = nil
        end
        if I.QuickSelect_Hotbar then
            I.QuickSelect_Hotbar.drawHotbar()
        else
            -- If QuickSelect_Hotbar is not available, log a message
            -- This prevents the error without breaking other functionality
            Debug.error("select_items_win1", "QuickSelect_Hotbar interface not available")
        end
        slotToSave = nil
    end
end

local function onKeyPress(key)
    if not QuickSelectWindow then return end

    local nextCol = selectedCol
    local nextRow = selectedRow
    if key.code == input.KEY.LeftArrow then
        nextCol = nextCol - 1
    elseif key.code == input.KEY.RightArrow then
        nextCol = nextCol + 1
    elseif key.code == input.KEY.DownArrow then
        nextRow = nextRow + 1
    elseif key.code == input.KEY.UpArrow then
        nextRow = nextRow - 1
    end
    if not columnsAndRows[nextCol] or not columnsAndRows[nextCol][nextRow] then

    else
        hoveredOverId = columnsAndRows[nextCol][nextRow]
        selectedCol = nextCol
        selectedRow = nextRow
        drawQuickSelect()
    end
end
local function onControllerButtonPress(id)
    if not QuickSelectWindow then return end

    local nextCol = selectedCol
    local nextRow = selectedRow
    if id == input.CONTROLLER_BUTTON.DPadLeft then
        nextCol = nextCol - 1
    elseif id == input.CONTROLLER_BUTTON.DPadRight then
        nextCol = nextCol + 1
    elseif id == input.CONTROLLER_BUTTON.DPadDown then
        nextRow = nextRow + 1
    elseif id == input.CONTROLLER_BUTTON.DPadUp then
        nextRow = nextRow - 1
    end
    if not columnsAndRows[nextCol] or not columnsAndRows[nextCol][nextRow] then

    else
        hoveredOverId = columnsAndRows[nextCol][nextRow]
        selectedCol = nextCol
        selectedRow = nextRow
        drawQuickSelect()
    end
end
I.UI.registerWindow(I.UI.WINDOW.QuickKeys, drawQuickSelect, function() --
    if QuickSelectWindow then
        QuickSelectWindow:destroy()
        QuickSelectWindow = nil
    end
    if tooltip then
        tooltip:destroy()
        tooltip = nil
    end
end)
local function ButtonClicked(data)
    local text = data.text
    num = 1
    if text == core.getGMST("sQuickMenu2") then
        spellMode = false
        drawItemSelect()
    elseif text == core.getGMST("sQuickMenu3") then
        spellMode = true
        drawSpellSelect()
    elseif text == core.getGMST("sQuickMenu4") then
        --delete
        I.QuickSelect_Storage.deleteStoredItemData(slotToSave)
        if QuickSelectWindow then
            QuickSelectWindow:destroy()
            QuickSelectWindow = nil
        end
        I.UI.setMode()
    elseif text == core.getGMST(
            "sCancel") then
        if QuickSelectWindow then
            QuickSelectWindow:destroy()
            QuickSelectWindow = nil
        end
        I.UI.setMode()
    end
end

return {

    interfaceName = "QuickSelect_Win1",
    interface = {
        drawQuickSelect = drawQuickSelect,
        openQuickSelect = openQuickSelect,
        getQuickSelectWindow = function()
            return QuickSelectWindow
        end,
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged,
        drawQuickSelect = drawQuickSelect,
        openQuickSelect = openQuickSelect,
        ButtonClicked = ButtonClicked,
    },
    engineHandlers = {
        onLoad = function()
            -- Initialize TooltipLayer with a slight delay to avoid race conditions
            -- with other scripts that might also be creating it
            Debug.log("SelectItemsWin", "Waiting before initializing TooltipLayer")
            async:newUnsavableSimulationTimer(0.5, function()
                local success, err = pcall(function()
                    initTooltipLayer()
                end)
                if not success then
                    Debug.warning("SelectItemsWin", "Failed to initialize TooltipLayer: " .. tostring(err))
                end
            end)
        end,
        onKeyPress = onKeyPress,
        onControllerButtonPress = onControllerButtonPress,
        onMouseWheel = function(vert)
            if not QuickSelectWindow then return end
            local modifer = 10

            if spellMode then
                modifer = 1
            end
            if vert > 0 then
                startOffset = startOffset - modifer
            elseif startOffset + modifer < maxCount then
                startOffset = startOffset + modifer
            end
            Debug.items("Scroll offset: " .. startOffset)
            if startOffset < 0 then
                startOffset = 0
            end
            if spellMode then
                drawSpellSelect()
            else
                drawItemSelect()
            end
        end
    }
}
