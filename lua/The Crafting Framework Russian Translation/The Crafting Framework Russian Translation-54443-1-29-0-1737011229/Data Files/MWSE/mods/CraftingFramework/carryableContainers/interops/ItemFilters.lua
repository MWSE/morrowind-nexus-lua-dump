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
        name = "Устройства",
        objectTypes = {
            [tes3.objectType.apparatus] = true
        },
    },
    {
        id = "armor",
        name = "Доспехи",
        objectTypes = {
            [tes3.objectType.armor] = true
        }
    },
    {
        id = "books",
        name = "Книги",
        objectTypes = {
            [tes3.objectType.book] = true
        }
    },
    {
        id = "magicScrolls",
        name = "Свитки (магические)",

        isValidItem = function(item, itemData)
            item = item --[[@as tes3book]]
            return item.objectType == tes3.objectType.book
                and item.type == tes3.bookType.scroll
                and item.enchantment ~= nil
        end
    },
    {
        id = "nonMagicScrolls",
        name = "Свитки (немагические)",
        isValidItem = function(item, itemData)
            item = item --[[@as tes3book]]
            return item.objectType == tes3.objectType.book
                and item.type == tes3.bookType.scroll
                and item.enchantment == nil
        end
    },
    {
        id = "allScrolls",
        name = "Свитки (все)",
        isValidItem = function(item, itemData)
            item = item --[[@as tes3book]]
            return item.objectType == tes3.objectType.book
                and item.type == tes3.bookType.scroll
        end
    },
    {
        id = "clothing",
        name = "Одежда",
        objectTypes = {
            [tes3.objectType.clothing] = true
        }
    },
    {
        id = "ingredients",
        name = "Ингредиенты",
        objectTypes = {
            [tes3.objectType.ingredient] = true
        }
    },
    {
        id = "lights",
        name = "Светильники",
        objectTypes = {
            [tes3.objectType.light] = true
        }
    },
    {
        id = "thiefTools",
        name = "Воровские инструменты",
        objectTypes = {
            [tes3.objectType.lockpick] = true,
            [tes3.objectType.probe] = true

        }
    },
    {
        id = "miscellanous",
        name = "Разное",
        objectTypes = {
            [tes3.objectType.miscItem] = true
        }
    },
    {
        id = "potions",
        name = "Зелья",
        objectTypes = {
            [tes3.objectType.alchemy] = true
        }
    },
    {
        id = "repairItems",
        name = "Предметы для ремонта",
        objectTypes = {
            [tes3.objectType.repairItem] = true
        }
    },
    {
        id = "weapons",
        name = "Оружие",
        objectTypes = {
            [tes3.objectType.weapon] = true
        }
    },
    {
        id = "attire",
        name = "Наряд",
        objectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.clothing] = true,
        }
    },
    {
        id = "equipment",
        name = "Экипировка",
        objectTypes = {
            [tes3.objectType.armor] = true,
            [tes3.objectType.weapon] = true
        }
    },
    {
        id = "jewelry",
        name = "Ювелирные изделия",
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
        name = "Камни душ",
        isValidItem = function(item, itemData)
            item = item --[[@as tes3misc]]
            return item.isSoulGem == true
        end
    }
}

for _, itemFilter in ipairs(itemFilters) do
    ItemFilter.register(itemFilter)
end