local inMemConfig

local this = {}

--Static Config (stored right here)
this.static = {
    modName = "Каталог предметов",
    modDescription =
    [[Каталог предметов позволяет просматривать все игровые предметы, отсортированные по принадлежности к моду, и добавлять их в инвентарь.]],
    categories = {
        {
            name = "Болты\\Стрелы",
            objectTypes = {
                [tes3.objectType.ammunition] = true
            },
            resultAmount = 10
        },
        {
            name = "Устройства",
            objectTypes = {
                [tes3.objectType.apparatus] = true
            },
        },
        {
            name = "Броня",
            objectTypes ={
                [tes3.objectType.armor] = true
            },
        },
        {
            name = "Книги",
            objectTypes = {
                [tes3.objectType.book] = true
            },
            requiredFields = { type = tes3.bookType.book}
        },
        {
            name = "Одежда",
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
            name = "Ингредиенты",
            objectTypes = {
                [tes3.objectType.ingredient] = true
            },
        },
        {
            name = "Светильники",
            objectTypes = {
                [tes3.objectType.light] = true
            },
            requiredFields = { canCarry = true}
        },
        {
            name = "Отмычки/Щупы",
            objectTypes = {
                [tes3.objectType.probe] = true,

                [tes3.objectType.lockpick] = true
            },
        },
        {
            name = "Разное",
            objectTypes = {
                [tes3.objectType.miscItem] = true
            },
        },
        {
            name = "Зелья",
            objectTypes = {
                [tes3.objectType.alchemy] = true
            },
            resultAmount = 10
        },
        {
            name = "Инструменты для ремонта",
            objectTypes = {
                [tes3.objectType.repairItem] = true
            },
            resultAmount = 1,
        },
        {
            name = "Кольца\\Амулеты",
            objectTypes = {
                [tes3.objectType.clothing] = true
            },
            slots = {
                [tes3.clothingSlot.ring] = true,
                [tes3.clothingSlot.amulet] = true,
            }
        },
        {
            name = "Документы\\записки\\бумаги",
            objectTypes = {
                [tes3.objectType.book] = true
            },
            enchanted = false,
            requiredFields = { type = tes3.bookType.scroll}
        },
        {
            name = "Свитки (Магические)",
            objectTypes = {
                [tes3.objectType.book] = true
            },
            enchanted = true,
            requiredFields = { type = tes3.bookType.scroll }
        },
        {
            name = "Оружие",
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