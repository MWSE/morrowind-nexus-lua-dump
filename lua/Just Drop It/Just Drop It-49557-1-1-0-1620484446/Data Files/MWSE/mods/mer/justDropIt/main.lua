local config = require('mer.justDropIt.config')
local orient = require("mer.justDropIt.orient")
local modName = config.modName

local deathAnimations = {
    [tes3.animationGroup.deathKnockDown] = true,
    [tes3.animationGroup.deathKnockOut] = true,
    [tes3.animationGroup.death1] = true,
    [tes3.animationGroup.death2] = true,
    [tes3.animationGroup.death3] = true,
    [tes3.animationGroup.death4] = true,
    [tes3.animationGroup.death5] = true,
}

--Initialisation
local function onItemDrop(e)
    if config.mcmConfig.enabled then
        orient.orientRefToGround{ ref = e.reference }
    end
end
event.register("itemDropped", onItemDrop)

local function onNPCDying(e)
    if config.mcmConfig.enabled and config.mcmConfig.orientOnDeath then
        if deathAnimations[e.group] then
            local result = orient.getGroundBelowRef({ref = e.reference})
            if result then
                orient.orientRef(e.reference, result)
            end
        end
    end
end

event.register("playGroup", onNPCDying)

--MCM MENU
local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = modName }
    template:saveOnClose(modName, config.mcmConfig)
    template:register()

    local settings = template:createSideBarPage("Settings")
    settings.description = config.modDescription

    settings:createOnOffButton{
        label = string.format("Enable %s", modName),
        description = "Turn the mod on or off.",
        variable = mwse.mcm.createTableVariable{id = "enabled", table = config.mcmConfig}
    }

    settings:createOnOffButton{
        label = "Orient Corpses on Death",
        description = "Orients the corpses of creatures and NPCs when they die. Death animations are extremely buggy in Morrowind, and this setting doesn't fix all the bugginess. So don't come complaining to me when a cliff racer falls through a rock or a guar hovers 3 feet over one. These are vanilla bugs and there's only so much I can do!",
        variable = mwse.mcm.createTableVariable{id = "orientOnDeath", table = config.mcmConfig}
    }

    settings:createOnOffButton{
        label = string.format("Ignore Non-Static Ground Orientation"),
        description = "If this is enabled, items will remain upright when placed on a non-static mesh. Default: Off",
        variable = mwse.mcm.createTableVariable{id = "noOrientNonStatic", table = config.mcmConfig}
    }

    settings:createSlider{
        label = "Max Orientation Steepness for Flat Objects",
        description = "Determines how many degrees an object will be rotated to orient with the ground it's being placed on. This is for objects whose height is smaller than its width and depth. Recommended: 40",
        variable = mwse.mcm.createTableVariable{ id = "maxSteepnessFlat", table = config.mcmConfig},
        max = 180
    }

    settings:createSlider{
        label = "Max Orientation Steepness for Tall Objects",
        description = "Determines how many degrees an object will be rotated to orient with the ground it's being placed on. This is for objects whose height is larger than its width or depth. Recommended: 5",
        variable = mwse.mcm.createTableVariable{ id = "maxSteepnessTall", table = config.mcmConfig},
        max = 180
    }


    template:createExclusionsPage{
        label = "Mod Blacklist",
        descirption = "Add plugins to the blacklist, so any items added by the mod are not affected. ",
        variable = mwse.mcm.createTableVariable{ id = "blacklist", table = config.mcmConfig},
        filters = {
            {
                label = "Plugins",
                type = "Plugin"
            }
        }
    }
end
event.register("modConfigReady", registerModConfig)
