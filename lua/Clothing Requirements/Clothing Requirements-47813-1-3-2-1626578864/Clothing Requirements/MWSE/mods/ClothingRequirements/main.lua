local mod = "Clothing Requirements"
local version = "1.3.2"

local data = require("ClothingRequirements.data")

-- Returns the level requirement for an item.
local function getItemLevelInfo(item)
    if item.objectType ~= tes3.objectType.clothing then
        return nil
    end

    local levelReq = data.clothingReqs[item.id:lower()]

    -- Item is not in our data table, so use a generic formula instead.
    if not levelReq then
        levelReq = ( math.log( item.value + 1 ) * 1.1 + ( item.enchantCapacity / 120 ) ) * 2
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
    local levelReq = getItemLevelInfo(e.object)

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

    local levelReq = getItemLevelInfo(e.item)

    if not levelReq then
        return
    end

    if tes3.player.object.level < levelReq then
        local rationalNames = include("RationalNames.data")
        local fullName

        if rationalNames then
            fullName = rationalNames.fullNamesList[e.item.id:lower()]
        end

        local name = fullName or e.item.name
        tes3.messageBox("Your level is too low to wear %s.", name)
        return false
    end
end

local function onInitialized()
    event.register("uiObjectTooltip", reqTooltip)
    event.register("equip", onEquip)

    mwse.log("[%s %s] initialized.", mod, version)
end

event.register("initialized", onInitialized)