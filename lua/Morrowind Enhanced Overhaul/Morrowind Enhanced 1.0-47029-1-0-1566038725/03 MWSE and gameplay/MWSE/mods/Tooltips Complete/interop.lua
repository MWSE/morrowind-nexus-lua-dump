local tooltipData = require("Tooltips Complete.data")

local this = {}
local tables = {
-- Custom itemTypes
key = tooltipData.keyTable,
quest = tooltipData.questTable,
unique = tooltipData.uniqueTable,
artifact = tooltipData.artifactTable,
tool = tooltipData.toolTable,
soulGem = tooltipData.soulgemTable,
ingredients = tooltipData.ingredientTable,
scroll = tooltipData.scrollTable,
-- Tes3.objectType
alchemy = tooltipData.potionTable,
ammunition = tooltipData.weaponTable,
apparatus = tooltipData.toolTable,
armor = tooltipData.armorTable,
book = tooltipData.bookTable,
clothing = tooltipData.clothingTable,
creature = tooltipData.filledTable,
ingredient = tooltipData.ingredientTable,
light = tooltipData.lightTable,
lockpick = tooltipData.toolTable,
miscItem = tooltipData.miscTable,
probe = tooltipData.toolTable,
repairItem = tooltipData.toolTable,
weapon = tooltipData.weaponTable,
}

function this.addTooltip(id, description, itemType)
    itemType = itemType or table.find(tes3.objectType, tes3.getObject(id).objectType)
    tables[itemType][id] = description
    mwse.log("%s added to tooltips", id)
end
return this

--[[ 
Format for Mods:

local tooltipsComplete = include("Tooltips Complete.interop")
local tooltipData = {
    { id = "___", description = "___" },
    { id = "___", description = "___", itemType = "___" }
}
local function initialized()
    if tooltipsComplete then
        for _, data in ipairs(tooltipData) do
            tooltipsComplete.addTooltip(data.id, data.description, data.itemType)
        end
    end
end
event.register("initialized", initialized)

- ID can be for any obtainable item or creature capable of being soul-trapped.
- Define your itemType if you wish so it's properly sorted, for instance 'itemType = quest'.
- Any objects not defined by itemType will be sorted by their tes3.objectTypes.

Item Types Guide:
key - Generic keys or other objects used to unlock or activate objects, such as Propylon Indices. Lockpicks do NOT fall under this category.
quest - Items required for the completion of a quest.
unique - Notable items which may only be found once or rewarded once after a quest, generally have the same appearance as other generic items.
artifact - Objects with a unique appearance and lore significance, such as Daedric and Aedric objects.
armor - Regular and generic enchanted armor and shields.
weapon - Regular and generic enchanted weapons and ammunition.
tool - Objects centered around a game mechanic such as alchemical apparatus, lockpicks, probes, and repair hammers.
soulGem - Empty gems or similar added object capable of holding a soul.
creature - Any creature which might have its soul trapped, descriptions should generally be about the creature in question.
misc - Clutter, coins, decorative objects, and any other items that don't fall into another category.
light - Objects that emit light and may be picked up and/or equipped by the player.
book - Books, notes, and any other readable object the player may acquire.
clothing - Regular and generic enchanted clothing and jewelry.
alchemy - Magical potions that are pre-made or otherwise have unique IDs, beverages like Sujamma do NOT fall under this category.
ingredients - Any items that may be used to brew potions or poisons, as well as beverages like Sujamma.
scroll - Enchanted scrolls used to cast magical spells.
]]