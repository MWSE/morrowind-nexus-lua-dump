local common = require("tamrielData.common")
local config = require("tamrielData.config")

----------------------
-- MCM Template --
----------------------

local function registerModConfig()

    local template = mwse.mcm.createTemplate{name=common.i18n("mcm.name")}
    template:saveOnClose("tamrielData", config)

    -- Preferences Page
    local preferences = template:createSideBarPage{label=common.i18n("mcm.preferences")}
    preferences.sidebar:createInfo{text=common.i18n("mcm.preferencesInfo")}

    -- Sidebar Credits
    local credits = preferences.sidebar:createCategory{label=common.i18n("mcm.credits")}
    credits:createHyperlink{
        text = common.i18n("mcm.Kynesifnar"),
        url = "https://www.nexusmods.com/users/56893332?tab=user+files",
    }
    credits:createHyperlink{
        text = common.i18n("mcm.mort"),
        url = "https://www.nexusmods.com/morrowind/users/4138441/?tab=user+files",
    }
    credits:createInfo{
        text = common.i18n("mcm.Rakanishu")
    }
    credits:createHyperlink{
        text = common.i18n("mcm.chef"),
        url = "https://github.com/cheflul/Chefmod",
    }
    credits:createHyperlink{
        text = common.i18n("mcm.Cicero"),
        url = "https://www.nexusmods.com/morrowind/users/64610026?tab=user+files",
    }
    credits:createHyperlink{
        text = common.i18n("mcm.NullCascade"),
        url = "https://www.nexusmods.com/morrowind/users/26153919?tab=user+files",
    }
    credits:createHyperlink{
        text = common.i18n("mcm.Hrnchamd"),
        url = "https://www.nexusmods.com/morrowind/users/843673?tab=user+files",
    }

    -- Feature Toggles
    local toggles = preferences:createCategory{label = common.i18n("mcm.settings")}
    toggles:createOnOffButton{
        label = common.i18n("mcm.summonSpellsLabel"),
        description = common.i18n("mcm.summonSpellsDescription"),
        variable = mwse.mcm.createTableVariable{
            id = "summoningSpells",
            table = config,
        },
    }
    toggles:createOnOffButton{
        label = common.i18n("mcm.boundSpellsLabel"),
        description = common.i18n("mcm.boundSpellsDescription"),
        variable = mwse.mcm.createTableVariable{
            id = "boundSpells",
            table = config,
        },
    }
    toggles:createOnOffButton{
        label = common.i18n("mcm.interventionSpellsLabel"),
        description = common.i18n("mcm.interventionSpellsDescription"),
        variable = mwse.mcm.createTableVariable{
            id = "interventionSpells",
            table = config,
        },
    }
    toggles:createOnOffButton{
        label = common.i18n("mcm.miscSpellsLabel"),
        description = common.i18n("mcm.miscSpellsDescription"),
        variable = mwse.mcm.createTableVariable{
            id = "miscSpells",
            table = config,
        },
    }
    toggles:createOnOffButton{
        label = common.i18n("mcm.passwallAlterationLabel"),
        description = common.i18n("mcm.passwallAlterationDescription"),
        variable = mwse.mcm.createTableVariable{
            id = "passwallAlteration",
            table = config,
        },
    }
    toggles:createOnOffButton{
        label = common.i18n("mcm.magickaExpandedLabel"),
        description = common.i18n("mcm.magickaExpandedDescription"),
        variable = mwse.mcm.createTableVariable{
            id = "overwriteMagickaExpanded",
            table = config,
        },
    }
    toggles:createOnOffButton{
        label = common.i18n("mcm.provincialReputationLabel"),
        description = common.i18n("mcm.provincialReputationDescription"),
        variable = mwse.mcm.createTableVariable{
            id = "provincialReputation",
            table = config,
        },
    }
    toggles:createOnOffButton{
        label = common.i18n("mcm.provincialFactionsUI"),
        description = common.i18n("mcm.provincialFactionsUIDescription"),
        variable = mwse.mcm.createTableVariable{
            id = "provincialFactionUI",
            table = config,
        },
    }
    toggles:createOnOffButton{
        label = common.i18n("mcm.weatherChangesLabel"),
        description = common.i18n("mcm.weatherChangesDescription"),
        variable = mwse.mcm.createTableVariable{
            id = "weatherChanges",
            table = config,
        },
    }
    toggles:createOnOffButton{
        label = common.i18n("mcm.hatsLabel"),
        description = common.i18n("mcm.hatsDescription"),
        variable = mwse.mcm.createTableVariable{
            id = "hats",
            table = config,
        },
    }
    toggles:createOnOffButton{
        label = common.i18n("mcm.creatureBehaviorsLabel"),
        description = common.i18n("mcm.creatureBehaviorsDescription"),
        variable = mwse.mcm.createTableVariable{
            id = "creatureBehaviors",
            table = config,
        },
    }
    toggles:createOnOffButton{
        label = common.i18n("mcm.animationFixLabel"),
        description = common.i18n("mcm.animationFixDescription"),
        variable = mwse.mcm.createTableVariable{
            id = "fixPlayerRaceAnimations",
            table = config,
        },
    }
    toggles:createOnOffButton{
        label = common.i18n("mcm.restrictEquipmentLabel"),
        description = common.i18n("mcm.restrictEquipmentDescription"),
        variable = mwse.mcm.createTableVariable{
            id = "restrictEquipment",
            table = config,
        },
    }
    toggles:createOnOffButton{
        label = common.i18n("mcm.fixVampireLabel"),
        description = common.i18n("mcm.fixVampireDescription"),
        variable = mwse.mcm.createTableVariable{
            id = "fixVampireHeads",
            table = config,
        },
    }
    toggles:createOnOffButton{
        label = common.i18n("mcm.itemSoundsLabel"),
        description = common.i18n("mcm.itemSoundsDescription"),
        variable = mwse.mcm.createTableVariable{
            id = "improveItemSounds",
            table = config,
        },
    }
    toggles:createOnOffButton{
        label = common.i18n("mcm.travelPricesLabel"),
        description = common.i18n("mcm.travelPricesDescription"),
        variable = mwse.mcm.createTableVariable{
            id = "adjustTravelPrices",
            table = config,
        },
    }
    toggles:createOnOffButton{
        label = common.i18n("mcm.khajiitFormCharacterCreationLabel"),
        description = common.i18n("mcm.khajiitFormCharacterCreationDescription"),
        variable = mwse.mcm.createTableVariable{
            id = "khajiitFormCharCreation",
            table = config,
        },
    }
    toggles:createOnOffButton{
        label = common.i18n("mcm.butterflyMothTooltipLabel"),
        description = common.i18n("mcm.butterflyMothTooltipDescription"),
        variable = mwse.mcm.createTableVariable{
            id = "butterflyMothTooltip",
            table = config,
        },
    }
    toggles:createOnOffButton{
        label = common.i18n("mcm.interventionRangeLabel"),
        description = common.i18n("mcm.interventionRangeDescription"),
        variable = mwse.mcm.createTableVariable{
            id = "limitIntervention",
            table = config,
        },
    }

    template:register()
end

event.register(tes3.event.modConfigReady, registerModConfig)