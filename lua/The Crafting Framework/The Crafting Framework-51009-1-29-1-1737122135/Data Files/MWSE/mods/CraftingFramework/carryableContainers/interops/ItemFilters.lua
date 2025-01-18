local ItemFilter = require("CraftingFramework.carryableContainers.components.ItemFilter")

---@alias CarryableContainers.DefaultItemFilter
---| '"apparatus"'
---| '"armor"'
---| '"books"'
---| '"clothing"'
---| '"ingredients"'
---| '"lights"'
---| '"thiefTools"'
---| '"miscellanous"'
---| '"potions"'
---| '"repairItems"'
---| '"weapons"'
---| '"attire"'
---| '"equipment"'
---| '"jewelry"'
---| '"magicScrolls"'
---| '"nonMagicScrolls"'
---| '"allScrolls"'

---@type CarryableContainers.ItemFilter.new.data[]
local itemFilters = {
    --For each tes3.objectType
    {
        id = "apparatus",
        name = "Apparatus",
        objectTypes = {
            [tes3.objectType.apparatus] = true
        },
    },
    {
        id = "armor",
        name = "Armor",
        objectTypes = {
            [tes3.objectType.armor] = true
        }
    },
    {
        id = "books",
        name = "Books",
        objectTypes = {
            [tes3.objectType.book] = true
        }
    },
    {
        id = "magicScrolls",
        name = "Scrolls (Magic)",

        isValidItem = function(item, itemData)
            item = item --[[@as tes3book]]
            return item.objectType == tes3.objectType.book
                and item.type == tes3.bookType.scroll
                and item.enchantment ~= nil
        end
    },
    {
        id = "nonMagicScrolls",
        name = "Scrolls (Non-Magic)",
        isValidItem = function(item, itemData)
            item = item --[[@as tes3book]]
            return item.objectType == tes3.objectType.book
                and item.type == tes3.bookType.scroll
                and item.enchantment == nil
        end
    },
    {
        id = "allScrolls",
        name = "Scrolls (All)",
        isValidItem = function(item, itemData)
            item = item --[[@as tes3book]]
            return item.objectType == tes3.objectType.book
                and item.type == tes3.bookType.scroll
        end
    },
    {
        id = "clothing",
        name = "Clothing",
        objectTypes = {
            [tes3.objectType.clothing] = true
        }
    },
    {
        id = "ingredients",
        name = "Ingredients",
        objectTypes = {
            [tes3.objectType.ingredient] = true
        }
    },
    {
        id = "lights",
        name = "Lights",
        objectTypes = {
            [tes3.objectType.light] = true
        }
    },
    {
        id = "thiefTools",
        name = "Thief Tools",
        objectTypes = {
            [tes3.objectType.lockpick] = true,
            [tes3.objectType.probe] = true

        }
    },
    {
        id = "miscellanous",
        name = "Miscellaneous",
        objectTypes = {
            [tes3.objectType.miscItem] = true
        }
    },
    {
        id = "potions",
        name = "Potions",
        objectTypes = {
            [tes3.objectType.alchemy] = true
        }
    },
    {
        id = "repairItems",
        name = "Repair Items",
        objectTypes = {
            [tes3.objectType.repairItem] = true
        }
    },
    {
        id = "weapons",
        name = "Weapons",
        objectTypes = {
            [tes3.objectType.weapon] = true
        }
    },
    {
        id = "attire",
        name = "Attire",
        objectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        }
    },
    {
        id = "equipment",
        name = "Equipment",
        objectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.weapon] = true
        }
    },
    {
        id = "jewelry",
        name = "Jewelry",
        isValidItem = function(item, itemData)
            ---@cast item tes3clothing
            local isClothing = item.objectType == tes3.objectType.clothing
            local isRing = item.slot == tes3.clothingSlot.ring
            local isAmulet = item.slot == tes3.clothingSlot.amulet
            return isClothing and (isRing or isAmulet)
        end,
    },
    {
        id = "soulGems",
        name = "Soul Gems",
        isValidItem = function(item, itemData)
            item = item --[[@as tes3misc]]
            return item.isSoulGem == true
        end
    }
}

for _, itemFilter in ipairs(itemFilters) do
    ItemFilter.register(itemFilter)
end