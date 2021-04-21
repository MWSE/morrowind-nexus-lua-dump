local configPath = 'love_pillow_hunt_config'
local config = mwse.loadConfig(configPath)
if not config then
    config = {
        enabled = true,
        buffDuration = 2
    }
    mwse.saveConfig( configPath, config)
end

local function modConfigReady()
    local sideBarDefault = (
        "We all know Drarayne Thelas has a pillow fetish, but is it possible for her to take her pillow fetish too far? Yes.\n\n" ..

        "Eighteen body pillows are hidden across the world and are yours for the taking (they have no ownership because no one will admit the body pillows belong to them). " ..
        "No hints, only being aghast to learn how gross your favorite Morrowind characters are when they think no one's looking. " ..
        "The obvious body pillows are there, of course, and hopefully a few slightly less obvious ones.\n\n" ..

        "This mod has a PG-13 rating, with fully clothed pillows (except for Caius and Jiub and Dagoth Ur's rock-hard abs because mmm...) because otherwise ew.\n\n" ..

        "The base mod is unscripted, because I wasn't going to waste my time on vanilla scripts for this. " ..
        "Instead Merlord wasted gobloads of time scripting it with lua so you sickos can do the following horrible things:\n\n" ..

        "- Buff yourself by cuddling with the pillow. You get a different buff for every pillow, and you can specify how many hours before your sick needs need fulfilling again in the MCM\n" ..
        "- Flip the pillow over like a shameless perv\n" ..
        "- Clean your gross pillow by submerging it in water. Don't forget to wash the legs!\n" ..
        "- Turn off all the features in the Mod config Menu, for when you've been made throroughly sick of your sick self and need an intervention"
    )
    local function addSideBar(component)
        component.sidebar:createInfo{ text = sideBarDefault}
        local hyperlink = component.sidebar:createCategory('Credits (Click to open Nexus Page): ')
        hyperlink:createHyperLink {
            text = 'Lewd scripts written by Merlord',
            exec = 'start https://www.nexusmods.com/users/3040468?tab=user+files'
        }
        hyperlink:createHyperLink {
            text = 'Models shamefully made by Stuporstar',
            exec = 'start https://www.nexusmods.com/morrowind/users/526886?tab=user+files'
        }
        hyperlink:createHyperLink {
            text = 'Vivec Pose by Aleist3r',
            exec = 'start https://www.nexusmods.com/morrowind/mods/46745'
        }
    end

    local template = mwse.mcm.createTemplate('The Great Love Pillow Hunt')
    template:saveOnClose(configPath, config)
    template:register()

    local page = template:createSideBarPage()
    addSideBar(page)

    page:createYesNoButton {
        label = 'Enable Pillow Menu',
        description = (
            "Enable the menu that allows you to cuddle, wash and flip over your love pillow."
        ),
        variable = mwse.mcm.createTableVariable {id = 'enabled', table = config}
    }

    page:createSlider {
        label = 'Buff duration: %s hours',
        description = 'How long (in game time) the buff gained from making out with a pillow lasts.',
        variable = mwse.mcm.createTableVariable {id = 'buffDuration', table = config},
        min = 1,
        max = 24
    }
end

event.register('modConfigReady', modConfigReady)
