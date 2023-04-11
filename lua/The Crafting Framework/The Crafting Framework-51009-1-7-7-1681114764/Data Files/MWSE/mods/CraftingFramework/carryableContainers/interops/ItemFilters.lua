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
    }
}

for _, itemFilter in ipairs(itemFilters) do
    ItemFilter.register(itemFilter)
end