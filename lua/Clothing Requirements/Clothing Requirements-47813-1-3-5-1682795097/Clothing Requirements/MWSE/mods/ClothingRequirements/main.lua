local mod = "Clothing Requirements"
local version = "1.3.4"

local data = require("ClothingRequirements.data")

-- Returns the ID of the base item for a player-created enchanted item (only works if Consistent Enchanting was in use
-- when the item was created).
local function getBaseItemID(itemData)
    local id

    if itemData then
        local luaData = itemData.data

        if luaData then
            id = luaData.ncceEnchantedFrom
        end
    end

    return id
end

-- Returns the level requirement for an item.
local function getItemLevelInfo(item, itemData)
    if item.objectType ~= tes3.objectType.clothing then
        return nil
    end

    local levelReq = data.clothingReqs[item.id:lower()]

    if not levelReq then
        local baseItemID = getBaseItemID(itemData)

        if baseItemID then
            levelReq = data.clothingReqs[baseItemID]
        end

        if levelReq then
            levelReq = levelReq + 5
            levelReq = math.clamp(levelReq, 1, 60)
        end
    end

    -- Item is not in our data table, so use a generic formula instead.
    if not levelReq then
        levelReq = ( math.log(item.value + 1) * 1.1 + (item.enchantCapacity / 120) ) * 2
        levelReq = math.clamp(levelReq, 1, 60)
        levelReq = math.ceil(levelReq)
    end

    if levelReq <= 1 then
        levelReq = -5000
    end

    return levelReq
end

-- Adds our custom information to the item tooltip display.
local function reqTooltip(e)
    local levelReq = getItemLevelInfo(e.object, e.itemData)

    if not levelReq then
        return
    end

    local block = e.tooltip:createBlock()
    block.minWidth = 1
    block.maxWidth = 230
    block.autoWidth = true
    block.autoHeight = true
    block.paddingAllSides = 6
    local label

    if levelReq > 0 then
        label = block:createLabel{
            text = string.format("Requires Level: %u", levelReq),
        }
    else
        label = block:createLabel{
            text = "No Requirement",
        }
    end

    local color

    -- Make the text either red or green depending on whether the player's level is high enough.
    if tes3.player.object.level < levelReq then
        color = tes3ui.getPalette("health_color")
    else
        color = tes3ui.getPalette("fatigue_color")
    end

    label.color = color
    label.wrapText = true
end

local function onEquip(e)
    if e.reference ~= tes3.player then
        return
    end

    local item = e.item
    local levelReq = getItemLevelInfo(item, e.itemData)

    if not levelReq then
        return
    end

    if tes3.player.object.level < levelReq then
        local rationalNames = include("RationalNames.interop")
        local displayName = ( rationalNames and rationalNames.common.getDisplayName(item.id:lower()) ) or item.name
        tes3.messageBox("Your level is too low to wear %s.", displayName)
        return false
    end
end

local function onInitialized()
    event.register("uiObjectTooltip", reqTooltip)
    event.register("equip", onEquip)

    mwse.log("[%s %s] initialized.", mod, version)
end

event.register("initialized", onInitialized)