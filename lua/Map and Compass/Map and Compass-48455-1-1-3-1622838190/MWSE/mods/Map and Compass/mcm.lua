local config = require("Map and Compass.config")

local template = mwse.mcm.createTemplate("Map and Compass")
template.headerImagePath = "MWSE/mods/Map and Compass/Map and Compass Logo.tga"
template:saveOnClose("Map and Compass", config)

template.onClose = function()
                        mwse.saveConfig("Map and Compass", config)
                        event.trigger("jaceyS_MaC_MCM_Closed")
                    end

local generalPage = template:createSidebarPage({
    label = "General Settings",
    description = "General settings for Map and Compass, v1.1.1",
})

local installedMapPacks = generalPage:createCategory({
    label = "Installed Map Packs",
    descrption = "Map packs that have been detected by Map and Compass. See the readme for instructions on adding additional map packs."
})
for _, mapPack in pairs(config.mapPacks) do
    installedMapPacks:createCategory({label = mapPack})
end
local reloadMessage = "Please load a game from save (or start a new one), in order for this setting to change."
generalPage:createYesNoButton({
    label = "World Map",
    description = "Enable or disable the availability of the World Map from the base game.",
    variable = mwse.mcm.createTableVariable({id = "worldMap", table = config})
})
generalPage:createYesNoButton({
    label = "Local Map",
    description = "Enable or disable the availability of the Local Map from the base game.",
    variable = mwse.mcm.createTableVariable({id = "localMap", table = config})
})
generalPage:createYesNoButton({
    label = "Hide Map Title",
    description = "Hides the title block at the top of the map menu.",
    variable = mwse.mcm.createTableVariable({id = "hideMapTitle", table = config})
})
generalPage:createYesNoButton({
    label = "Hide Map Notification",
    description = "Hides the text that shows up over the minimap when you change cells.",
    variable = mwse.mcm.createTableVariable({id = "hideMapNotification", table = config})
})
generalPage:createYesNoButton({
    label = "Selection Dropdown",
    description = "Replaces the Switch button on the map with a dropdown menu for selection.",
    variable = mwse.mcm.createTableVariable({id = "selectionDropdown", table = config}),
})
generalPage:createYesNoButton({
    label = "Hide Switch",
    description = "The selection Dropdown automatically hides the Switch button, but if you don't want to use that, and don't want the switch button, enable this setting.",
    variable = mwse.mcm.createTableVariable({id = "hideSwitch", table = config}),
})
generalPage:createSlider({
    label = "Max Zoom Magnification",
    description = "How much you can magnify the map by zooming in.",
    step = 1,
    min = 1,
    max = 10,
    jump = 1,
    variable = mwse.mcm.createTableVariable({id = "maxScale", table = config})
})
generalPage:createKeyBinder({
    label = "Note Modifier",
    description = "The key you hold down while clicking a custom map to make a note.",
    allowCombinations = false,
    variable = mwse.mcm.createTableVariable({id = "noteKey", table = config})
})

local compassOptions = {{label = "Minimap", value = false}}
for _, value in pairs(config.compasses) do
    table.insert(compassOptions, {label = value, value = value})
end
local compass = generalPage:createDropdown({
    label = "Compass",
    description = "Choose whether to use the default minimap, or replace it with one of the installed compasses.",
    options = compassOptions,
    variable = mwse.mcm.createTableVariable({id = "compass", table = config}),
})


for _, mapPack in pairs(config.mapPacks) do
    local packPage = template:createSidebarPage({
        label = mapPack,
        description = "Map selection page for ".. mapPack
    })
    local maps = require("Map and Compass."..mapPack..".maps")
    if (not maps) then
        local string = "Map and Compass, Error: MaC was expecting to find a list of maps present in " .. mapPack .. ", but did not. Please make sure you have correctly installed your map packs."
        packPage:createCategory({label = string})
    else
        for map, value in pairs(maps) do
            local category = packPage:createCategory({label = map})
            local displayName = category:createCategory({label = "Default Display Name: ".. value.name})
            displayName:createTextField({
                description = "Use this field to change the display name used for this map. Needed if you want to use two maps with the same default name.",
                variable = mwse.mcm.createTableVariable({id = "name", table = config[mapPack][map]})
            })
            displayName:createButton({buttonText = "Reset", callback = function() config[mapPack][map].name = nil end})
            category:createYesNoButton({
                label = "Enable",
                description = "Adds this map to the available map selection.",
                variable = mwse.mcm.createTableVariable({id = "enabled", table = config[mapPack][map]}),
            })
            category:createButton({inGameOnly = true, label = "Make this map your currently selected map.", buttonText = "Select", callback =
                function()
                    if(not tes3.player.data.JaceyS) then
                        tes3.player.data.JaceyS = {}
                    end
                    if(not tes3.player.data.JaceyS.MaC) then
                        tes3.player.data.JaceyS.MaC = {}
                    end
                    if (config[mapPack][map].enabled ~= true) then
                        tes3.messageBox "You must enable a map before setting it as your current map."
                        return
                    end
                    tes3.player.data.JaceyS.MaC.currentMap = mapPack .."-".. map
                end
            })
            category:createButton({inGameOnly = true, label = "Delete all notes on this map.", buttonText = "Delete", callback =
                function()
                    if(tes3.player and tes3.player.data.JaceyS and tes3.player.data.JaceyS.MaC and
                    tes3.player.data.JaceyS.MaC[mapPack] and tes3.player.data.JaceyS.MaC[mapPack][map] and
                    tes3.player.data.JaceyS.MaC[mapPack][map].notes) then
                        tes3.player.data.JaceyS.MaC[mapPack][map].notes = nil
                    end
                end
            })
        end
    end
end
mwse.mcm.register(template)