local inMemConfig

local this = {}

--Static Config (stored right here)
this.static = {
    modName = "Item Browser",
    modDescription =
    [[Item Browser allows you to browse all items in the game, sorted by which mod added them, and add them to your inventory.]],
    categories = {
        {
            name = "Ammunition",
            objectTypes = {
                [tes3.objectType.ammunition] = true
            },
            resultAmount = 10
        },
        {
            name = "Apparatus",
            objectTypes = {
                [tes3.objectType.apparatus] = true
            },
        },
        {
            name = "Armor",
            objectTypes ={
                [tes3.objectType.armor] = true
            },
        },
        {
            name = "Books",
            objectTypes = {
                [tes3.objectType.book] = true
            },
            requiredFields = { type = tes3.bookType.book}
        },
        {
            name = "Clothing",
            objectTypes = {
                [tes3.objectType.clothing] = true
            },
            slots = {
                [tes3.clothingSlot.pants] = true,
                [tes3.clothingSlot.shoes] = true,
                [tes3.clothingSlot.shirt] = true,
                [tes3.clothingSlot.belt] = true,
                [tes3.clothingSlot.robe] = true,
                [tes3.clothingSlot.rightGlove] = true,
                [tes3.clothingSlot.leftGlove] = true,
                [tes3.clothingSlot.skirt] = true,
            }
        },
        {
            name = "Ingredients",
            objectTypes = {
                [tes3.objectType.ingredient] = true
            },
        },
        {
            name = "Lights",
            objectTypes = {
                [tes3.objectType.light] = true
            },
            requiredFields = { canCarry = true}
        },
        {
            name = "Lockpicks/Probes",
            objectTypes = {
                [tes3.objectType.probe] = true,

                [tes3.objectType.lockpick] = true
            },
        },
        {
            name = "Misc",
            objectTypes = {
                [tes3.objectType.miscItem] = true
            },
        },
        {
            name = "Potions",
            objectTypes = {
                [tes3.objectType.alchemy] = true
            },
            resultAmount = 10
        },
        {
            name = "Repair Tools",
            objectTypes = {
                [tes3.objectType.repairItem] = true
            },
            resultAmount = 1,
        },
        {
            name = "Rings",
            objectTypes = {
                [tes3.objectType.clothing] = true
            },
            slots = {
                [tes3.clothingSlot.ring] = true,
                [tes3.clothingSlot.amulet] = true,
            }
        },
        {
            name = "Scrolls (Non-Magic)",
            objectTypes = {
                [tes3.objectType.book] = true
            },
            enchanted = false,
            requiredFields = { type = tes3.bookType.scroll}
        },
        {
            name = "Scrolls (Magic)",
            objectTypes = {
                [tes3.objectType.book] = true
            },
            enchanted = true,
            requiredFields = { type = tes3.bookType.scroll }
        },
        {
            name = "Weapons",
            objectTypes = {
                [tes3.objectType.weapon] = true
            },
        },
    }
}

--MCM Config (stored as JSON)
this.configPath = "itemBrowser"
this.mcmDefault = {
    enabled = true,
    logLevel = "INFO",
    hotKey = {
        enabled = true,
        keyCode = tes3.scanCode.b,
        isAltDown = true
    },
}

this.save = function(newConfig)
    inMemConfig = newConfig
    mwse.saveConfig(this.configPath, inMemConfig)
end

this.mcm = setmetatable({}, {
    __index = function(_, key)
        inMemConfig = inMemConfig or mwse.loadConfig(this.configPath, this.mcmDefault)
        return inMemConfig[key]
    end,
    __newindex = function(_, key, value)
        inMemConfig = inMemConfig or mwse.loadConfig(this.configPath, this.mcmDefault)
        inMemConfig[key] = value
        mwse.saveConfig(this.configPath, inMemConfig)
    end
})

return this