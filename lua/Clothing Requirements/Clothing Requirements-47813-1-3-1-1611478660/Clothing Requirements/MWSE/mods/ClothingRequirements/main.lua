local mod = "Clothing Requirements"
local version = "1.2"

local data = require("ClothingRequirements.data")

-- Returns the level requirement for an item.
local function getItemLevelInfo(item)

    -- This is not a clothing item, so no requirement.
    if item.objectType ~= tes3.objectType.clothing then
        return nil
    end

    -- Look up the item in our data table.
    local levelReq = data.clothingReqs[item.id:lower()]

    -- Item is not in our data table, so use a generic formula instead.
    if not levelReq then
        levelReq = ( math.log( item.value + 1 ) * 1.1 + ( item.enchantCapacity / 120 ) ) * 2
        levelReq = math.clamp(levelReq, 1, 60)
    end

    return levelReq
end

-- Adds our custom information to the item tooltip display.
local function reqTooltip(e)
    local levelReq = getItemLevelInfo(e.object)

    -- This is not a clothing item, so do nothing.
    if not levelReq then
        return
    end

    -- Create a block for our info text.
    local block = e.tooltip:createBlock()
    block.minWidth = 1
    block.maxWidth = 230
    block.autoWidth = true
    block.autoHeight = true
    block.paddingAllSides = 6

    local label = block:createLabel{
        text = string.format("Requires Level: %u", levelReq),
    }

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

-- Prevents the player from equipping items with too high a level requirement.
local function onEquip(e)

    -- It's not the player doing the equipping, so bail.
    if e.reference ~= tes3.player then
        return
    end

    local levelReq = getItemLevelInfo(e.item)

    -- Not a clothing item, so bail.
    if not levelReq then
        return
    end

    -- Player's level is too low, so display a message and prevent equip.
    if tes3.player.object.level < levelReq then
        tes3.messageBox("Your level is too low to wear %s.", e.item.name)
        return false
    end
end

local function onInitialized()
    event.register("uiObjectTooltip", reqTooltip)
    event.register("equip", onEquip)

    mwse.log("[%s %s] initialized.", mod, version)
end

event.register("initialized", onInitialized)