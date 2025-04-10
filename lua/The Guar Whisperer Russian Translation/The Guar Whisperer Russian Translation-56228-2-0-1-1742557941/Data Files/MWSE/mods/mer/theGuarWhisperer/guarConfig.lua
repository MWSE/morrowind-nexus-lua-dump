---@class GuarWhisperer.AnimalConfig
local this = {}

this.idles = {
        idle = "idle",
        happy = "idle5",
        eat = "idle4",
        pet = "idle6",
        fetch = "idle6",
        sad = "idle3"
}

---@class GuarWhisperer.AnimalType.lvl
---@field fetchProgress number
---@field attackProgress number

---@class GuarWhisperer.AnimalType.hunger
---@field changePerHour number

---@class GuarWhisperer.AnimalType.play
---@field changePerHour number
---@field fetchValue number
---@field greetValue number

---@class GuarWhisperer.AnimalType.affection
---@field changePerHour number
---@field petValue number

---@class GuarWhisperer.AnimalType.trust
---@field changePerHour number
---@field babyLevel number

---@class GuarWhisperer.AnimalType.reqs
---@field pack number
---@field follow number

---@class GuarWhisperer.AnimalType
---@field type string
---@field mutation number
---@field birthIntervalHours number
---@field babyScale number
---@field hoursToMature number
---@field lvl GuarWhisperer.AnimalType.lvl
---@field hunger GuarWhisperer.AnimalType.hunger
---@field play GuarWhisperer.AnimalType.play
---@field affection GuarWhisperer.AnimalType.affection
---@field trust GuarWhisperer.AnimalType.trust
---@field reqs GuarWhisperer.AnimalType.reqs
---@field breedable boolean
---@field tameable boolean
---@field foodList table<string, number|boolean>

---@type table<string, GuarWhisperer.AnimalType>
this.animals = {
    guar = {
        type = "guar",
        mutation = 10,
        birthIntervalHours = 24 * 3,
        babyScale = 0.5,
        hoursToMature = 24 * 4,
        lvl = {
            fetchProgress = 4,
            attackProgress = 1
        },
        hunger = {
            changePerHour = 1.0,
        },
        play = {
            changePerHour = -0.5,
            fetchValue = 60,
            greetValue = 40
        },
        affection = {
            changePerHour = -3.0,
            petValue = 60
        },
        trust = {
            changePerHour = 5,
            babyLevel = 50,
        },
        reqs = {
            pack = 90,
            follow = 40
        },
        breedable = true,
        tameable = true,
        foodList = {
            ["ingred_corkbulb_root_01"] = 70,
            ["ingred_chokeweed_01"] = 60,
            ["ingred_kresh_fiber_01"] = 60,
            ["ingred_marshmerrow_01"] = 55,
            ["ingred_saltrice_01"] = 55,
            ["ingred_wickwheat_01"] = 55,
            ["ingred_comberry_01"] = 45,
            ["ingred_scathecraw_01"] = 60,
            --containers
            ["flora_corkbulb"] = true,
            ["flora_chokeweed_02"] = true,
            ["flora_kreshweed_01"] = true,
            ["flora_kreshweed_02"] = true,
            ["flora_kreshweed_03"] = true,
            ["flora_marshmerrow_01"] = true,
            ["flora_marshmerrow_02"] = true,
            ["flora_marshmerrow_03"] = true,
            ["flora_saltrice_01"] = true,
            ["flora_saltrice_02"] = true,
            ["flora_wickwheat_01"] = true,
            ["flora_wickwheat_02"] = true,
            ["flora_wickwheat_03"] = true,
            ["flora_wickwheat_04"] = true,
            ["flora_comberry_01"] = true,
            ["flora_rm_scathecraw_01"] = true,
            ["flora_rm_scathecraw_02"] = true,
        },
    },
}

---A list of meshes that can be greeted as a fellow guar
this.greetableGuars = {
    ["mdfg\\fabricant_guar.nif"] = true,
    ["r\\guar.nif"] = true,
    ["r\\guar_withpack.nif"] = true,
    ["r\\guar_white.nif"] = true,
    ["mer_tgw\\guar_tame.nif"] = true,
    ["mer_tgw\\guar_tame_w.nif"] = true
}

---@class GuarWhisperer.ConvertConfig.extra
---@field hasPack boolean
---@field canHavePack boolean
---@field color "standard" | "white"

---@class GuarWhisperer.ConvertConfig.statOverrides
---@field attributes? table<GuarWhisperer.Stats.AttributeName, number>
---@field attackMin? number
---@field attackMax? number

---@class GuarWhisperer.ConvertConfig
---@field name string? The default name of hte converted guar
---@field mesh string? The mesh of the converted guar
---@field type string The type of the converted guar
---@field extra GuarWhisperer.ConvertConfig.extra Extra data for the converted guar
---@field statOverrides GuarWhisperer.ConvertConfig.statOverrides? Overrides for the converted guar's stats
---@field transferInventory boolean? Whether to transfer inventory from the old guar to the new guar

--Meshes to allow to turn into switch guar
---@type table<string, GuarWhisperer.ConvertConfig>
this.convertConfigs = {
    guar = {
        name = "Прирученный гуар",
        mesh = "mer_tgw\\guar_tame.nif",
        type = "guar",
        extra = {
            hasPack = false,
            canHavePack = true,
            color = "standard"
        },
        statOverrides = {
            attributes = {
                strength = 50,
                speed = 70,
            },
        }
    },
    whiteGuar = {
        name = "Прирученный белый гуар",
        mesh = "mer_tgw\\guar_tame_w.nif",
        type = "guar",
        extra = {
            hasPack = false,
            canHavePack = true,
            color = "white"
        },
        statOverrides = {
            attributes = {
                strength = 60,
                speed = 60,
            },
        }
    },
}

---@type table<string, GuarWhisperer.ConvertConfig>
this.meshToConvertConfig = {
    ["r\\guar.nif"] = this.convertConfigs.guar,
    ["r\\guar_white.nif"] = this.convertConfigs.whiteGuar
}

---@type table<string, GuarWhisperer.ConvertConfig>
this.legacyGuarToConvertConfig = {
    mer_tgw_guar = this.convertConfigs.guar,
    mer_tgw_guar_w = this.convertConfigs.whiteGuar
}

return this