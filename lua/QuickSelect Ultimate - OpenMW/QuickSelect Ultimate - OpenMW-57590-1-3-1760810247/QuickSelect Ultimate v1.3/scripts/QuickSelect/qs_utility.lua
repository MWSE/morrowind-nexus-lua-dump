local ui = require("openmw.ui")
local util = require("openmw.util")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local self = require("openmw.self")
local types = require("openmw.types")
local core = require("openmw.core")

local itemWindowLocs = {
    TopLeft = { wx = 0, wy = 0, align = ui.ALIGNMENT.Start, anchor = nil },
    TopRight = { wx = 1, wy = 0, align = ui.ALIGNMENT.End, anchor = util.vector2(1, 0) },
    Right = { wx = 1, wy = 0.5, align = ui.ALIGNMENT.End, anchor = util.vector2(1, 0.5) },
    Left = { wx = 0, wy = 0.5, align = ui.ALIGNMENT.Start, anchor = util.vector2(0, 0.5) },
    BottomLeft = { wx = 0, wy = 1, align = ui.ALIGNMENT.End, anchor = util.vector2(0, 1) },
    BottomRight = { wx = 1, wy = 1, align = ui.ALIGNMENT.Start, anchor = util.vector2(1, 1) },
    BottomCenter = { wx = 0.5, wy = 1, align = ui.ALIGNMENT.End, anchor = util.vector2(0.5, 1) },
    TopCenter = { wx = 0.5, wy = 0, align = ui.ALIGNMENT.End, anchor = util.vector2(0.5, 0) },
    Disabled = { disabled = true }
}

local function lerp(x, x1, x2, y1, y2)
    return y1 + (x - x1) * ((y2 - y1) / (x2 - x1))
end

local function getEnchantment(id)
    if not id then
        return
    end
    return core.magic.enchantments.records[id]
end

local function FindEnchantment(item)
    if (item == nil or item.type == nil or item.type.records[item.recordId] == nil or item.type.records[item.recordId].enchant == nil or item.type.records[item.recordId].enchant == "") then
        return nil
    end
    return getEnchantment(item.type.records[item.recordId].enchant)
end

local function calculateTextScale()
    local screenSize = ui.screenSize()
    local width = screenSize.x
    local scale = lerp(width, 1280, 2560, 1.3, 1.8)
    return scale
end

local scale = 0.8
local iconSize = 30

local function imageContent(resource, size)
    if (size == nil) then
        size = iconSize
    end

    return {
        type = ui.TYPE.Image,
        props = {
            resource = resource,
            size = util.vector2(size, size)
        }
    }
end

local function renderItemWithIcon(item, bold, icon)
    local resource = ui.texture {
        path = icon
    }
    return {
        type = ui.TYPE.Container,
        template = I.MWUI.templates.boxSolid,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    imageContent(resource, calculateTextScale() * 10),
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props = {
                            anchor = util.vector2(0, 0),
                            text = item,
                            textSize = 10 * calculateTextScale(),
                            arrange = ui.ALIGNMENT.Center
                        }
                    }
                }
            }
        }
    }
end

local function scaledVector2(x, y)
    return util.vector2(x * scale, y * scale)
end

local function renderItemX(item, bold, fontSize)
    if not fontSize then
        fontSize = 10
    end
    fontSize = fontSize * calculateTextScale()
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = item,
                            textSize = fontSize,
                            arrange = ui.ALIGNMENT.Center
                        }
                    }
                }
            }
        }
    }
end

local function renderItemChoiceX(itemList, horizontal, vertical, align, anchor, layer, fontSize)
    local content = {}
    for _, item in ipairs(itemList) do
        if type(item) == "string" then
            local itemLayout = renderItemX(item, nil, fontSize)
            itemLayout.template = I.MWUI.templates.padding
            table.insert(content, itemLayout)
        elseif type(item) == "table" then
            local text = item.text
            local icon = item.icon
            local itemLayout = renderItemWithIcon(text, false, icon)
            itemLayout.template = I.MWUI.templates.padding
            table.insert(content, itemLayout)
        end
    end
    
    return ui.create {
        layer = layer or "Windows",
        template = I.MWUI.templates.boxSolid,
        props = {
            anchor = anchor,
            relativePosition = util.vector2(horizontal, vertical),
            arrange = align,
            align = align,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    vertical = true,
                    arrange = ui.ALIGNMENT.Center,
                    align = align,
                }
            }
        }
    }
end

local function drawListMenu(buttonTable, winLoc, prevWindow, layer, fontSize, extraContent)
    if (prevWindow) then
        prevWindow:destroy()
        prevWindow = nil
    end
    
    local wx = 0
    local wy = 0
    local align = nil
    local anchor = nil
    local config = itemWindowLocs[winLoc] or winLoc

    if not config or config.disabled then
        return
    else
        wx = config.wx
        wy = config.wy
        align = config.align
        anchor = config.anchor
    end
    
    return renderItemChoiceX(buttonTable, wx, wy, align, anchor, layer, fontSize)
end

local savedTextures = {}
local function getTexture(path)
    if not savedTextures[path] and path then
        savedTextures[path] = ui.texture({ path = path })
    end
    return savedTextures[path]
end

-- Prebuilt caches for fast lookups
local nameToSpellRecord = {}
local idToItemRecord = {}
local nameToItemRecord = {}

local function initCaches()
    -- Cache spells by name
    for id, spellRecord in pairs(core.magic.spells.records) do
        nameToSpellRecord[spellRecord.name] = spellRecord
    end

    -- Cache items by ID and name
    local itemTypes = {
        types.Apparatus,
        types.Armor,
        types.Book,
        types.Clothing,
        types.Ingredient,
        types.Light,
        types.Lockpick,
        types.Miscellaneous,
        types.Potion,
        types.Probe,
        types.Repair,
        types.Weapon
    }
    for _, itemType in ipairs(itemTypes) do
        if itemType and itemType.records then
            for id, record in pairs(itemType.records) do
                idToItemRecord[id] = record
                nameToItemRecord[record.name] = record  -- Assumes unique names; last one wins if not
            end
        end
    end
end

local function findSpellByName(name)
    if not name then return nil end
    local spellRecord = nameToSpellRecord[name]
    if spellRecord then
        return spellRecord
    end
    return nil
end

local function getItemRecord(id)
    local record = idToItemRecord[id]
    if record then
        return record
    end
    return nil
end

local function findItemByName(name)
    local record = nameToItemRecord[name]
    if record then
        return record
    end
    return nil
end

-- Modified to accept isHovered parameter and fix effects access
local function renderItemBold(item, bold, id, tooltipData, isSpell, spellData, events, isSelected, isHovered)
    if not id then id = item end  -- Fallback if id nil, but we'll handle search below
local textTemplate = I.MWUI.templates.textNormal
    -- Apply highlighting for bold, selected, or hovered items
    if bold or (spellData and spellData.bold) or isSelected or isHovered then
        textTemplate = I.MWUI.templates.textHeader
    end
    local containerTemplate = nil
    if isSelected then
        containerTemplate = I.MWUI.templates.boxSolid
    end

    local iconPath = nil

    -- Check if this is likely a scroll (by name) and skip spell lookup if so
    local isScroll = item:match("^Scroll of") ~= nil

    if isSpell and not isScroll and id then
        local spellRecord = core.magic.spells.records[id]

        if not spellRecord then
            -- Fallback search by name if direct ID lookup fails
            spellRecord = findSpellByName(item)
        end
        -- FIX: Access first effect in array
        if spellRecord and spellRecord.effects and spellRecord.effects[1] then
            iconPath = spellRecord.effects[1].effect.icon
        end
    end

    -- If no icon found (e.g., not a spell or is a scroll), fallback to checking if it's an enchanted item
    if not iconPath then
        -- Skip if it's clearly a header (contains colon)
        if id and id:match("_") then -- Changed from '_' to ':' for headers like " Spells:"
        else
            -- Always attempt direct ID lookup first
            local itemRecord = getItemRecord(id)

            if not itemRecord then
                -- Fallback to name search if direct ID lookup fails
                itemRecord = findItemByName(item)
            end

            if itemRecord then
                if itemRecord.enchant then
                    local enchantRecord = core.magic.enchantments.records[itemRecord.enchant]
                    -- FIX: Access first effect in array
                    if enchantRecord and enchantRecord.effects and enchantRecord.effects[1] then
                        -- Filter for on-cast types using correct numeric values (0 = CastOnce, 2 = CastWhenUsed)
                        if enchantRecord.type == 2 or enchantRecord.type == 0 then
                            iconPath = enchantRecord.effects[1].effect.icon
                        end
                    end
                end
            end
        end
    end

    local innerContent = {
        {
            type = ui.TYPE.Text,
            template = textTemplate,
            props = {
                text = item,
                textSize = 20 * scale,
                relativePosition = util.vector2(0.5, 0.5),
                arrange = ui.ALIGNMENT.Start,
                align = ui.ALIGNMENT.Start,
                spellData = spellData,
                spellIndex = spellData and spellData.spellIndex,  -- Pass through spellIndex for hover tracking
            },
        }
    }

    if iconPath then
        innerContent = {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = getTexture(iconPath),
                    size = util.vector2(20, 20),
                }
            },
            {
                type = ui.TYPE.Widget,
                props = {
                    size = util.vector2(5, 1),
                }
            },
            innerContent[1]
        }
    end

    return {
        id = id,
        type = ui.TYPE.Container,
        template = containerTemplate,
        tooltipData = tooltipData,
        data = spellData,
        props = {
            align = ui.ALIGNMENT.Start,
            relativePosition = util.vector2(0.5, 0.5),
            arrange = ui.ALIGNMENT.Start,
            spellData = spellData,
            spellIndex = spellData and spellData.spellIndex,  -- Pass through for hover tracking
        },
        events = { mouseMove = events and events.mouseMove, mouseClick = events and events.mouseClick },
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Start,
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            align = ui.ALIGNMENT.Start,
                        },
                        content = ui.content(innerContent)
                    }
                }
            }
        }
    }
end

local function flexedItems(content, horizontal, anchor)
    if not horizontal then
        horizontal = false
    end
    local arrange = horizontal and ui.ALIGNMENT.Center or ui.ALIGNMENT.Start
    return ui.content {
        {
            id = "flexeditems",
            type = ui.TYPE.Flex,
            content = ui.content(content),
            props = {
                horizontal = horizontal,
                align = ui.ALIGNMENT.Start,
                arrange = arrange,
                autosize = true,
                relativePosition = anchor,
                anchor = anchor
            }
        }
    }
end

local function renderItemBoxed(content, size, itemTemplate, relativePosition, data, events)


    if data then
    end
    
    if not size then
        size = scaledVector2(90, 100)
    end
    
    if not itemTemplate then
        itemTemplate = I.MWUI.templates.borders
    end

    return {
        id = "itemBoxed",
        type = ui.TYPE.Container,
        template = itemTemplate,
        content = ui.content {
            {
                props = {
                    size = size,
                    relativePosition = relativePosition
                },
                content = content
            },
        },
        data = data,
        props = {
            relativePosition = relativePosition,
            anchor = relativePosition
        },
        events = events,
    }
end

-- NEW: Preload all relevant icons in the background at module load
local function preloadIcons()
    local iconPaths = {}

    -- Collect spell effect icons
    for id, spell in pairs(core.magic.spells.records) do
        -- FIX: Access first effect in array
        if spell.effects and spell.effects[1] then
            local path = spell.effects[1].effect.icon
            if path then iconPaths[path] = true end
        end
    end

    -- Collect enchantment effect icons
    for id, enchant in pairs(core.magic.enchantments.records) do
        -- FIX: Access first effect in array
        if enchant.effects and enchant.effects[1] then
            local path = enchant.effects[1].effect.icon
            if path then iconPaths[path] = true end
        end
    end

    -- Collect item icons from all item types
    local itemTypes = {
        types.Apparatus,
        types.Armor,
        types.Book,
        types.Clothing,
        types.Ingredient,
        types.Light,
        types.Lockpick,
        types.Miscellaneous,
        types.Potion,
        types.Probe,
        types.Repair,
        types.Weapon
    }
    for _, itemType in ipairs(itemTypes) do
        for id, record in pairs(itemType.records or {}) do
            if record.icon then
                iconPaths[record.icon] = true
            end
        end
    end

    -- Preload all unique textures
    local count = 0
    for path in pairs(iconPaths) do
        getTexture(path)
        count = count + 1
    end
end

-- Initialize caches and preload icons
initCaches()
preloadIcons()

return {
    imageContent = imageContent,
    scaledVector2 = scaledVector2,
    renderItemX = renderItemX,
    renderItemChoiceX = renderItemChoiceX,
    drawListMenu = drawListMenu,
    renderItemBoxed = renderItemBoxed,
    renderItemWithIcon = renderItemWithIcon,
    renderItemBold = renderItemBold,
    getEnchantment = getEnchantment,
    FindEnchantment = FindEnchantment,
    calculateTextScale = calculateTextScale,
    scale = scale,
    iconSize = iconSize,
    flexedItems = flexedItems,
    itemWindowLocs = itemWindowLocs,
    findSlot = function (item)
        if (item == nil) then
            return
        end
        if item.type == types.Armor then
            if (types.Armor.records[item.recordId].type == types.Armor.TYPE.RGauntlet) then
                return types.Actor.EQUIPMENT_SLOT.RightGauntlet
            elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.LGauntlet) then
                return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
            elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.Boots) then
                return types.Actor.EQUIPMENT_SLOT.Boots
            elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.Cuirass) then
                return types.Actor.EQUIPMENT_SLOT.Cuirass
            elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.Greaves) then
                return types.Actor.EQUIPMENT_SLOT.Greaves
            elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.LBracer) then
                return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
            elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.RBracer) then
                return types.Actor.EQUIPMENT_SLOT.RightGauntlet
            elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.RPauldron) then
                return types.Actor.EQUIPMENT_SLOT.RightPauldron
            elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.LPauldron) then
                return types.Actor.EQUIPMENT_SLOT.LeftPauldron
            elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.Helmet) then
                return types.Actor.EQUIPMENT_SLOT.Helmet
            elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.Shield) then
                return types.Actor.EQUIPMENT_SLOT.CarriedLeft
            end
        elseif item.type == types.Clothing then
            if (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Amulet) then
                return types.Actor.EQUIPMENT_SLOT.Amulet
            elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Belt) then
                return types.Actor.EQUIPMENT_SLOT.Belt
            elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.LGlove) then
                return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
            elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.RGlove) then
                return types.Actor.EQUIPMENT_SLOT.RightGauntlet
            elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Ring) then
                                return types.Actor.EQUIPMENT_SLOT.RightRing
                elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Skirt) then
                return types.Actor.EQUIPMENT_SLOT.Skirt
            elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Shirt) then
                return types.Actor.EQUIPMENT_SLOT.Shirt
            elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Shoes) then
                return types.Actor.EQUIPMENT_SLOT.Boots
            elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Robe) then
                return types.Actor.EQUIPMENT_SLOT.Robe
            elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Pants) then
                return types.Actor.EQUIPMENT_SLOT.Pants
            end
        elseif item.type == types.Weapon then
            if (types.Weapon.records[item.recordId].type == types.Weapon.TYPE.Arrow or types.Weapon.records[item.recordId].type == types.Weapon.TYPE.Bolt) then
                return types.Actor.EQUIPMENT_SLOT.Ammunition
            end
            return types.Actor.EQUIPMENT_SLOT.CarriedRight
        elseif item.type == types.Light then
            return types.Actor.EQUIPMENT_SLOT.CarriedLeft
        end
        return nil
    end
}