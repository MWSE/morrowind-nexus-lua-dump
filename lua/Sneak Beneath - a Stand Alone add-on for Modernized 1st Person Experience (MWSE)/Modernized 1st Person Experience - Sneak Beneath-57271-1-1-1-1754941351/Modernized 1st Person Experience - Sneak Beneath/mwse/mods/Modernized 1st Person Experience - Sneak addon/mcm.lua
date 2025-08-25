--[[
	Mod:Sneak Beneath ( Modernized 1st Person Experience - Sneak addon )
	Author: rhjelte
	Version: 1.1.1
]]--


local EasyMCM = require ("easyMCM.EasyMCM")
local config = require("Modernized 1st Person Experience - Sneak addon.config").loaded
local defaultConfig = require("Modernized 1st Person Experience - Sneak addon.config").default

local modName = ("Modernized 1st Person Experience - Sneak addon")
local template = EasyMCM.createTemplate(modName)
template:saveOnClose(modName, config)
template:register()

local page = template:createSideBarPage({
    label = "Main Settings",
    description = "Finally sneak under things where it feels intuitive to do so when in 1st person mode!\n\nHighly recommended to use with: Modernized 1st Person Experience\n\nDoing so will add some functionality: \n- Slight animation to trying to stand up when not enough space. \n- Smooth camera transition in and out from sneak camera. \n- Adjustable camera height. \n\nWhen you stand up again, the mod will check if there is space for you to stand. This extends to switching to 3rd person cameras, as technically I am scaling the player down, and you would see a tiny version of your character unless I blocked that. When there is enough space, you can both switch camera and stand up again.",
    showReset = true
})

------------------------------------------------------------------------------------------------------------------------------- Main tweaks
local settings = page:createCategory ("Modernized 1st Person Experience - Sneak Beneath")

settings:createOnOffButton{
    label = "Enable Mod",
    description = "Turn this mod on or off.",
    defaultSetting = defaultConfig.modEnabled,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "modEnabled",
        table = config
    }
}

settings:createSlider{
    label = "Vertical padding",
    description ="Checks this much more upwards than the character bounds to see if ther is enough space. Just checking the character bounds is not enough for all situations, and the physics engine will move the character around. To avoid this, we check with a bit of padding so we have ample space to stand.\n\nThis value lets you change how much this padding is.",
    defaultSetting = defaultConfig.verticalPadding,
    showDefaultSetting = true,
    max = 30,
    min = 0,
    step = 1,
    jump = 5,
    variable = mwse.mcm.createTableVariable{
        id = "verticalPadding",
        table = config
    }
}

settings:createSlider{
    label = "Horizontal padding",
    description ="This value can be used to balance how likely the character is to be allowed to stand up in tight spaces. A low value is more allowing but may cause more weird collisions when standing up after sneaking. From a technical standpoint a higher value checks further out than the actual character hitbox, a lower value checks closer to the character than the scaled up character hitbox.",
    defaultSetting = defaultConfig.horizontalPadding,
    showDefaultSetting = true,
    max = 25,
    min = -25,
    step = 1,
    jump = 5,
    variable = mwse.mcm.createTableVariable{
        id = "horizontalPadding",
        table = config
    }
}

settings:createSlider{
    label = "Message cooldown in seconds",
    description ="Amount of seconds needs to pass before the mod will send another message about the space being too tight to stand up.",
    defaultSetting = defaultConfig.messageCooldown,
    showDefaultSetting = true,
    max = 2,
    min = 0.1,
    step = 0.1,
    decimalPlaces = 1,
    variable = mwse.mcm.createTableVariable{
        id = "messageCooldown",
        table = config
    }
}

settings:createDropdown{
    label = "First or third person messages.",
    description = [[Decides if the messages that are shown in game when you try to stand are presented as first person messages ("Too tight. I can't stand up.") or third person ("There is not enough space to stand up.").]],
    options = {
        { label = "First person", value = true },
        { label = "Third person", value = false}
    },
    defaultValue = defaultConfig.firstPersonMessages,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "firstPersonMessages",
        table = config
    }

}