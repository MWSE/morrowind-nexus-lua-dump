local types = require('openmw.types')
local util = require('openmw.util')
local ui = require('openmw.ui')
local myConstants = require('scripts.inventoryManager.myLib.myConstants')
-- local g = require('scripts.inventoryManager.myLib')

-- local TEXT_CONT_HEIGHT = 12

---@class NewItemInfo
local newItemInfo = {
        ---@type GameObject
        object = nil,
        ---@type ItemData
        data = {},
        ---@type Record
        record = {},
}

---@class ItemInfo
local ItemInfo = {
        ---@type GameObject
        object = nil,
        ---@type ItemData
        data = {},
        ---@type string
        id = nil,
        ---@type string
        name = nil,
        ---@type string
        icon = nil,
        ---@type number
        value = nil,
        ---@type number
        weight = nil,
        ---@type number
        count = nil,
        ---@type boolean
        equipped = false,
        ---@type boolean
        locked = false,
        type = nil,
}


local columns
columns = {
        {
                key = 'name',
                header = 'Name',
                headerlayout = {
                        external = { grow = 1, stretch = 0 },
                        props = {
                                horizontal = true,
                                align = ui.ALIGNMENT.Start,
                                -- arrange = ui.ALIGNMENT.Center
                        },
                },
                layout = {
                        external = { grow = 1, stretch = 0 },
                        props = {
                                horizontal = true,
                                align = ui.ALIGNMENT.Start,
                                -- arrange = ui.ALIGNMENT.Center
                        },
                },
                sort = {
                        ---@param a ItemInfo
                        ---@param b ItemInfo
                        callback = function(a, b)
                                if columns[1].sort.ascending then
                                        return a.name < b.name
                                else
                                        return a.name > b.name
                                end
                        end,
                        ascending = false
                }
        },
        {
                key = 'count',
                header = 'Count',
                headerlayout = {
                        external = { grow = 0, stretch = 1 },
                        props = {
                                size = util.vector2(50, myConstants.sizes.CONTAINER_SIZE),
                                -- align = ui.ALIGNMENT.Center,
                                arrange = ui.ALIGNMENT.Center,
                        },
                },
                layout = {
                        external = { grow = 0, stretch = 1 },
                        props = {
                                size = util.vector2(50, myConstants.sizes.CONTAINER_SIZE),
                                -- align = ui.ALIGNMENT.End,
                                arrange = ui.ALIGNMENT.End,
                        },
                },
                sort = {
                        ---@param a ItemInfo
                        ---@param b ItemInfo
                        callback = function(a, b)
                                if a.count == b.count then
                                        return a.name < b.name
                                end

                                if columns[2].sort.ascending then
                                        return a.count < b.count
                                else
                                        return a.count > b.count
                                end
                        end,
                        ascending = false
                }
        },
        {
                key = 'weight',
                header = 'Weight',
                headerlayout = {
                        external = { grow = 0, stretch = 1 },
                        props = {
                                size = util.vector2(60, myConstants.sizes.CONTAINER_SIZE),
                                -- align = ui.ALIGNMENT.Center,
                                arrange = ui.ALIGNMENT.Center,

                        },
                },
                layout = {
                        external = { grow = 0, stretch = 1 },

                        props = {
                                size = util.vector2(60, myConstants.sizes.CONTAINER_SIZE),
                                -- align = ui.ALIGNMENT.End,
                                arrange = ui.ALIGNMENT.End,

                        },
                },
                sort = {
                        ---@param a ItemInfo
                        ---@param b ItemInfo
                        callback = function(a, b)
                                if a.weight == b.weight then
                                        return a.name < b.name
                                end

                                if columns[3].sort.ascending then
                                        return a.weight < b.weight
                                else
                                        return a.weight > b.weight
                                end
                        end,
                        ascending = false
                }

        },
        {
                key = 'value',
                header = 'Value',
                headerlayout = {
                        external = { grow = 0, stretch = 1 },
                        props = {
                                size = util.vector2(50, myConstants.sizes.CONTAINER_SIZE),
                                align = ui.ALIGNMENT.Center,
                                arrange = ui.ALIGNMENT.Center,
                        },
                },
                layout = {
                        external = { grow = 0, stretch = 1 },

                        props = {
                                size = util.vector2(50, myConstants.sizes.CONTAINER_SIZE),
                                -- align = ui.ALIGNMENT.End,
                                arrange = ui.ALIGNMENT.End,
                        },
                },
                sort = {
                        ---@param a ItemInfo
                        ---@param b ItemInfo
                        callback = function(a, b)
                                if a.value == b.value then
                                        return a.name < b.name
                                end

                                if columns[4].sort.ascending then
                                        return a.value < b.value
                                else
                                        return a.value > b.value
                                end
                        end,
                        ascending = false
                }

        },
        {
                key = 'locked',
                header = 'Locked',
                headerlayout = {
                        external = { grow = 0, stretch = 1 },
                        props = {
                                size = util.vector2(myConstants.sizes.CONTAINER_SIZE * 2,
                                        myConstants.sizes.CONTAINER_SIZE),
                                arrange = ui.ALIGNMENT.Center,
                                align = ui.ALIGNMENT.Center,
                        },
                },
                layout = {
                        external = { grow = 0, stretch = 1 },
                        props = {
                                size = util.vector2(myConstants.sizes.CONTAINER_SIZE * 2,
                                        myConstants.sizes.CONTAINER_SIZE),
                                arrange = ui.ALIGNMENT.Center,
                                align = ui.ALIGNMENT.Center,
                        },
                },
                sort = {
                        ---@param a ItemInfo
                        ---@param b ItemInfo
                        callback = function(a, b)
                                if a.locked ~= b.locked then
                                        return a.locked and b.locked == ''
                                end

                                if a.equipped ~= b.equipped then
                                        if columns[5].sort.ascending then
                                                return a.equipped
                                        else
                                                return b.equipped
                                        end
                                end

                                if columns[5].sort.ascending then
                                        return a.name < b.name
                                else
                                        return a.name > b.name
                                end
                        end,
                        ascending = false
                }

        },
}







local function setColumnSizes()
        local columnSizes = {
                -- math.max(myConstants.sizes.LABEL_SIZE, myConstants.sizes.TEXT_SIZE) * 30, --- name
                math.max(myConstants.sizes.LABEL_SIZE, myConstants.sizes.TEXT_SIZE) * 4, --- count
                math.max(myConstants.sizes.LABEL_SIZE, myConstants.sizes.TEXT_SIZE) * 4, --- weight
                math.max(myConstants.sizes.LABEL_SIZE, myConstants.sizes.TEXT_SIZE) * 4, --- value
                math.max(myConstants.sizes.LABEL_SIZE, myConstants.sizes.TEXT_SIZE) * 3  --- locked
        }

        for i = 2, #columns do
                columns[i].layout.props.size = util.vector2(columnSizes[i - 1], 1)
                columns[i].headerlayout.props.size = util.vector2(columnSizes[i - 1], 1)
                -- columns[i].layout.props.size = util.vector2(columnSizes[i], 1)
        end
end



local newType = {
        [types.Miscellaneous] = types.Miscellaneous,
        [types.Light] = types.Miscellaneous,
        [types.Apparatus] = 'Tool',
        [types.Lockpick] = 'Tool',
        [types.Repair] = 'Tool',
        [types.Probe] = 'Tool',
}

local filterButtons = {
        {
                key = 'All',
                name = 'All',
                callback = function(entry) return true end
        },
        {
                key = types.Weapon,
                name = 'Weapon',
                callback = function(entry) return entry.layout.userData.type == types.Weapon end
        },
        {
                key = types.Armor,
                name = 'Armor',
                callback = function(entry) return entry.layout.userData.type == types.Armor end
        },
        {
                key = types.Clothing,
                name = 'Cloth',
                callback = function(entry) return entry.layout.userData.type == types.Clothing end
        },
        {
                key = types.Potion,
                name = 'Potion',
                callback = function(entry) return entry.layout.userData.type == types.Potion end
        },
        {
                key = types.Ingredient,
                name = 'Ingredient',
                callback = function(entry) return entry.layout.userData.type == types.Ingredient end
        },
        {
                key = types.Book,
                name = 'Book',
                callback = function(entry) return entry.layout.userData.type == types.Book end
        },
        {
                key = 'Paper',
                name = 'Paper',
                callback = function(entry) return entry.layout.userData.type == 'Paper' end
        },
        {
                key = types.Miscellaneous,
                name = 'Misc',
                callback = function(entry) return entry.layout.userData.type == types.Miscellaneous end
        },
        {
                key = 'Tool',
                name = 'Tool',
                callback = function(entry) return entry.layout.userData.type == 'Tool' end
        },

}



---@param item GameObject
---@return string|{}
local function getType(item)
        if item.type == types.Book and types.Book.records[item.recordId].isScroll then
                return 'Paper'
        else
                return newType[item.type] or item.type
        end
end


local SLOTS = {
        Helmet = 0,
        Cuirass = 1,
        Greaves = 2,
        LeftPauldron = 3,
        RightPauldron = 4,
        LeftGauntlet = 5,
        RightGauntlet = 6,
        Boots = 7,
        Shirt = 8,
        Pants = 9,
        Skirt = 10,
        Robe = 11,
        LeftRing = 12,
        RightRing = 13,
        Amulet = 14,
        Belt = 15,
        CarriedRight = 16,
        CarriedLeft = 17,
        Ammunition = 18,
}

local ARMOR_TYPE = {
        [0] = SLOTS.Helmet,
        [1] = SLOTS.Cuirass,
        [2] = SLOTS.LeftPauldron,
        [3] = SLOTS.RightPauldron,
        [4] = SLOTS.Greaves,
        [5] = SLOTS.Boots,
        [6] = SLOTS.LeftGauntlet,
        [7] = SLOTS.RightGauntlet,
        [8] = SLOTS.CarriedLeft,
        [9] = SLOTS.LeftGauntlet,
        [10] = SLOTS.RightGauntlet,
}

local CLOTHING_TYPE = {
        [0] = SLOTS.Pants,
        [1] = SLOTS.Boots,
        [2] = SLOTS.Shirt,
        [3] = SLOTS.Belt,
        [4] = SLOTS.Robe,
        [5] = SLOTS.RightGauntlet,
        [6] = SLOTS.LeftGauntlet,
        [7] = SLOTS.Skirt,
        -- Ring = nil,
        [9] = SLOTS.Amulet,
}


local WEAPON_TYPE = {
        ShortBladeOneHand = 0,
        LongBladeOneHand = 1,
        LongBladeTwoHand = 2,
        BluntOneHand = 3,
        BluntTwoClose = 4,
        BluntTwoWide = 5,
        SpearTwoWide = 6,
        AxeOneHand = 7,
        AxeTwoHand = 8,
        MarksmanBow = 9,
        MarksmanCrossbow = 10,
        MarksmanThrown = 11,
        Arrow = 12,
        Bolt = 13,
}


local RANGED_AMMO = {
        [WEAPON_TYPE.Arrow] = true,
        [WEAPON_TYPE.Bolt] = true
}


local RANGED_WEAPON = {
        [WEAPON_TYPE.MarksmanBow] = true,
        [WEAPON_TYPE.MarksmanCrossbow] = true,
        [WEAPON_TYPE.MarksmanThrown] = true
}



-- local CLOTHING_TYPE = {
--         Pants = 0,
--         Shoes = 1,
--         Shirt = 2,
--         Belt = 3,
--         Robe = 4,
--         RGlove = 5,
--         LGlove = 6,
--         Skirt = 7,
--         Ring = 8,
--         Amulet = 9,
-- }

-- local ARMOR_TYPE = {
--         Helmet = 0,
--         Cuirass = 1,
--         LPauldron = 2,
--         RPauldron = 3,
--         Greaves = 4,
--         Boots = 5,
--         LGauntlet = 6,
--         RGauntlet = 7,
--         Shield = 8,
--         LBracer = 9,
--         RBracer = 10,
-- }



---@type {items: table<string, boolean>}
local lockedStuff = {
        items = {},
}




return {
        filterButtons = filterButtons,
        columns = columns,
        newType = newType,
        getType = getType,
        ARMOR_TYPE = ARMOR_TYPE,
        CLOTHING_TYPE = CLOTHING_TYPE,
        lockedStuff = lockedStuff,
        SLOTS = SLOTS,
        setColumnSizes = setColumnSizes,
        RANGED_AMMO = RANGED_AMMO,
        RANGED_WEAPON = RANGED_WEAPON
}
