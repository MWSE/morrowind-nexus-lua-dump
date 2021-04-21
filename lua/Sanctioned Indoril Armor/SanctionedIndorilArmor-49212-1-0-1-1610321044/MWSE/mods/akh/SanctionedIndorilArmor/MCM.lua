local constants = require('akh.SanctionedIndorilArmor.Constants')
local modInfo = require('akh.SanctionedIndorilArmor.ModInfo')
local config = require("akh.SanctionedIndorilArmor.Config")

local function triggerConfigChangedEvent()
    event.trigger(constants.event.CONFIG_CHANGED)
end

local function registerModConfig()

    local template = mwse.mcm.createTemplate{
        name = modInfo.modName,
        headerImagePath="\\Textures\\akh\\SanctionedIndorilArmor\\logo.tga"
    }
    template:saveOnClose(modInfo.modName, config)
    template:register()

    local settings = template:createSideBarPage("Settings")
    settings.description = modInfo.modDescription

    settings:createDropdown{
        label = "Temple Rank Requirement",
        description = "Temple rank required to be able to wear the armor freely.",
        options = {
            { label = "None", value = -1},
            { label = "0 - Layman", value = 0},
            { label = "1 - Novice", value = 1},
            { label = "2 - Initiate", value = 2},
            { label = "3 - Acolyte", value = 3},
            { label = "4 - Adept", value = 4},
            { label = "5 - Curate", value = 5},
            { label = "6 - Disciple", value = 6},
            { label = "7 - Diviner", value = 7},
            { label = "8 - Master", value = 8},
            { label = "9 - Patriarch", value = 9}
        },
        variable = mwse.mcm.createTableVariable{
            id = "requiredTempleRank",
            table = config
        },
        callback = triggerConfigChangedEvent
    }

    settings:createDropdown{
        label = "Quest Completion Requirement",
        description = "Quest required to complete to be able to wear the armor freely.",
        options = {
            { label = "None", value = nil},
            { label = "Mysterious Killings in Vivec", value = "town_Vivec=50" },
            { label = "Hortator and Nerevarine (Accepted Wraithguard)", value = "B8_MeetVivec=50" }
        },
        variable = mwse.mcm.createTableVariable{
            id = "requiredQuestCompletion",
            table = config
        },
        callback = triggerConfigChangedEvent
    }

    settings:createOnOffButton{
        label = "Inconspicuous Robes",
        description = "When enabled, Ordinators won't notice the cuirass when wearing a robe on top of it.",
        variable = mwse.mcm.createTableVariable{
            id = "inconspicuousRobes",
            table = config
        },
        callback = triggerConfigChangedEvent
    }

    settings:createOnOffButton{
        label = "Cautious Merchants",
        description = "When enabled, merchants won't buy Indoril armor pieces due to fear of persecution.",
        variable = mwse.mcm.createTableVariable{
            id = "cautiousMerchants",
            table = config
        },
        callback = triggerConfigChangedEvent
    }

end

event.register("modConfigReady", registerModConfig)