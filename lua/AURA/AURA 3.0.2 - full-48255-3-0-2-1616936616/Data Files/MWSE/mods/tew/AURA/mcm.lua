local configPath = "AURA"
local config = require("tew.AURA.config")
mwse.loadConfig("AURA")
local modversion = require("tew.AURA.version")
local version = modversion.version

local function registerVariable(id)
    return mwse.mcm.createTableVariable{
        id = id,
        table = config
    }
end

local template = mwse.mcm.createTemplate{
    name="AURA",
    headerImagePath="\\Textures\\tew\\AURA\\AURA_logo.tga"}

    local page = template:createPage{label="Main Settings", noScroll=true}
    page:createCategory{
        label = "AURA "..version.." by tewlwolow.\nLua-based sound overhaul.\n\nSettings:",
    }
    page:createYesNoButton{
        label = "Enable debug mode?",
        variable = registerVariable("debugLogOn"),
        restartRequired=true
    }
    page:createYesNoButton{
        label = "Enable Outdoor Ambient module?",
        variable = registerVariable("moduleAmbientOutdoor"),
        restartRequired=true
    }
    page:createYesNoButton{
        label = "Enable Interior Ambient module?",
        variable = registerVariable("moduleAmbientInterior"),
        restartRequired=true
    }
    page:createYesNoButton{
        label = "Enable Populated Ambient module?",
        variable = registerVariable("moduleAmbientPopulated"),
        restartRequired=true
    }
    page:createYesNoButton{
        label = "Enable Interior Weather module?",
        variable = registerVariable("moduleInteriorWeather"),
        restartRequired=true
    }
    page:createYesNoButton{
        label = "Enable Service Voices module?",
        variable = registerVariable("moduleServiceVoices"),
        restartRequired=true
    }
    page:createYesNoButton{
        label = "Enable UI module?",
        variable = registerVariable("moduleUI"),
        restartRequired=true
    }
    page:createYesNoButton{
        label = "Enable Containers module?",
        variable = registerVariable("moduleContainers"),
        restartRequired=true
    }
    page:createYesNoButton{
        label = "Enable PC module?",
        variable = registerVariable("modulePC"),
        restartRequired=true
    }
    page:createYesNoButton{
        label = "Enable Misc module?",
        variable = registerVariable("moduleMisc"),
        restartRequired=true
    }

    local pageOA = template:createPage{label="Outdoor Ambient"}
    pageOA:createCategory{
        label = "Plays ambient sounds in accordance with local climate, weather, player position, and time.\n\nSettings:"
    }
    pageOA:createSlider{
        label = "Changes % volume for Outdoor Ambient module. Default = 100%.\nRequires restart. Volume %",
        min = 0,
        max = 200,
        step = 1,
        jump = 10,
        variable=registerVariable("OAvol")
    }
    pageOA:createSlider{
        label = "Changes % chance for a calm track to play instead of the regular one. Default = 30%.\nRequires restart. Chance %",
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable=registerVariable("calmChance")
    }
    pageOA:createYesNoButton{
        label = "Enable exterior ambient sounds in interiors? This means the last exterior loop will play on each interior door leading to an exterior. The sound will stop if you're far enough from such door.",
        variable = registerVariable("playInteriorAmbient"),
        restartRequired=true
    }
    pageOA:createYesNoButton{
        label = "Enable additional wind tracks in bad weather (overcast, rain, thunder, snow)?",
        variable = registerVariable("playWindy"),
        restartRequired=true
    }
    pageOA:createYesNoButton{
        label = "Enable transition sounds?",
        variable = registerVariable("playTransSounds"),
        restartRequired=true
    }

    local pageIA = template:createPage{label="Interior Ambient"}
    pageIA:createCategory{
        label = "Plays ambient sounds in accordance with interior type. Includes taverns, guilds, shops, libraries, tombs, caves, and ruins.\n\nSettings:"
    }
    pageIA:createSlider{
        label = "Changes % volume for Interior Ambient module. Default = 150%.\nRequires restart. Volume %",
        min = 0,
        max = 200,
        step = 1,
        jump = 10,
        variable=registerVariable("intVol")
    }
    pageIA:createYesNoButton{
        label = "Enable natural, native music in taverns? Note that this works best if you have empty explore/battle folders and use no music mod. Requires restart.",
        variable = registerVariable("interiorMusic"),
        restartRequired=true
    }

    local pagePA = template:createPage{label="Populated Ambient"}
    pagePA:createCategory{
        label = "Plays ambient sounds in populated areas, like towns and villages.\n\nSettings:"
    }
    pagePA:createSlider{
        label = "Changes % volume for Populated Ambient module. Default = 100%.\nRequires restart. Volume %",
        min = 0,
        max = 200,
        step = 1,
        jump = 10,
        variable=registerVariable("popVol")
    }

    local pageIW = template:createPage{label="Interior Weather"}
    pageIW:createCategory{
        label = "Plays weather sounds in interiors.\n\nSettings:"
    }
    pageIW:createSlider{
        label = "Changes % volume for Interior Weather module. Default = 150%.\nRequires restart.\nVolume %",
        min = 0,
        max = 200,
        step = 1,
        jump = 10,
        variable=registerVariable("IWvol")
    }

    local pageSV = template:createPage{label="Service Voices"}
    pageSV:createCategory{
        label = "Plays appropriate voice comments on service usage.\n\nSettings:"
    }
    pageSV:createYesNoButton{
        label = "Enable voice comments on repair service?",
        variable = registerVariable("serviceRepair"),
    }
    pageSV:createYesNoButton{
        label = "Enable voice comments on spells vendor service?",
        variable = registerVariable("serviceSpells"),
    }
    pageSV:createYesNoButton{
        label = "Enable voice comments on training service?",
        variable = registerVariable("serviceTraining"),
    }
    pageSV:createYesNoButton{
        label = "Enable voice comments on spellmaking service?",
        variable = registerVariable("serviceSpellmaking"),
    }
    pageSV:createYesNoButton{
        label = "Enable voice comments on enchanting service?",
        variable = registerVariable("serviceEnchantment"),
    }
    pageSV:createYesNoButton{
        label = "Enable voice comments on travel service?",
        variable = registerVariable("serviceTravel"),
    }
    pageSV:createYesNoButton{
        label = "Enable voice comments on barter service?",
        variable = registerVariable("serviceBarter"),
    }
    pageSV:createSlider{
        label = "Changes % volume for Service Voices module. Default = 200%.\nRequires restart.\nVolume %",
        min = 0,
        max = 200,
        step = 1,
        jump = 10,
        variable=registerVariable("SVvol")
    }

    local pagePC = template:createPage{label="PC"}
    pagePC:createCategory{
        label = "Plays sounds related to the player character.\n\nSettings:"
    }
    pagePC:createYesNoButton{
        label = "Enable low health sounds?",
        variable = registerVariable("PChealth"),
    }
    pagePC:createYesNoButton{
        label = "Enable low fatigue sounds?",
        variable = registerVariable("PCfatigue"),
    }
    pagePC:createYesNoButton{
        label = "Enable low magicka sounds?",
        variable = registerVariable("PCmagicka"),
    }
    pagePC:createYesNoButton{
        label = "Enable diseased sounds?",
        variable = registerVariable("PCDisease"),
    }
    pagePC:createYesNoButton{
        label = "Enable blighted sounds?",
        variable = registerVariable("PCBlight"),
    }
    pagePC:createYesNoButton{
        label = "Enable player combat taunts?",
        variable = registerVariable("PCtaunts"),
    }
    pagePC:createSlider{
        label = "Changes % volume for vital signs (health, fatigue, magicka, disease, blight). Default = 200%.\nRequires restart. Volume %",
        min = 0,
        max = 200,
        step = 1,
        jump = 10,
        variable=registerVariable("vsVol")
    }
    pagePC:createSlider{
        label = "Changes % chance for a battle taunt to play. Default = 100%.\nRequires restart. Chance %",
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable=registerVariable("tauntChance")
    }
    pagePC:createSlider{
        label = "Changes % volume for player battle taunts. Default = 200%.\nRequires restart. Volume %",
        min = 0,
        max = 200,
        step = 1,
        jump = 10,
        variable=registerVariable("tVol")
    }

    local pageC = template:createPage{label="Containers"}
    pageC:createCategory{
        label = "Plays container sound on open/close.\n\nSettings:"
    }
    pageC:createSlider{
        label = "Changes % volume for Containers module. Default = 120%.\nRequires restart. Volume %",
        min = 0,
        max = 200,
        step = 1,
        jump = 10,
        variable=registerVariable("Cvol")
    }

    local pageUI = template:createPage{label="UI"}
    pageUI:createCategory{
        label = "Additional immersive UI sounds.\n\nSettings:"
    }
    pageUI:createYesNoButton{
        label = "Enable training menu sounds?",
        variable = registerVariable("UITraining"),
    }
    pageUI:createYesNoButton{
        label = "Enable travel menu sounds?",
        variable = registerVariable("UITravel"),
    }
    pageUI:createYesNoButton{
        label = "Enable spell menu sounds?",
        variable = registerVariable("UISpells"),
    }
    pageUI:createYesNoButton{
        label = "Enable barter menu sounds?",
        variable = registerVariable("UIBarter"),
    }
    pageUI:createYesNoButton{
        label = "Enable eating sound for ingredients in inventory menu?",
        variable = registerVariable("UIEating"),
    }
    pageUI:createSlider{
        label = "Changes % volume for UI module. Default = 200%.\nVolume %",
        min = 0,
        max = 200,
        step = 1,
        jump = 10,
        variable=registerVariable("UIvol")
    }

    local pageMisc = template:createPage{label="Misc", noScroll=true}
    pageMisc:createCategory{
        label = "Plays various miscellaneous sounds.\n\nSettings:"
    }
    pageMisc:createYesNoButton{
        label = "Enable splash sounds when going underwater and back to surface?",
        variable = registerVariable("playSplash"),
    }
    pageMisc:createSlider{
        label = "Changes % volume for splash sounds. Default = 200%.\nRequires restart. Volume %",
        min = 0,
        max = 200,
        step = 1,
        jump = 10,
        variable=registerVariable("splashVol")
    }
    pageMisc:createYesNoButton{
        label = "Enable door sounds for yurts and pelt entrances?",
        variable = registerVariable("playYurtFlap"),
    }
    pageMisc:createSlider{
        label = "Changes % volume for yurt flaps. Default = 200%.\nRequires restart. Volume %",
        min = 0,
        max = 200,
        step = 1,
        jump = 10,
        variable=registerVariable("yurtVol")
    }

template:saveOnClose(configPath, config)
mwse.mcm.register(template)
