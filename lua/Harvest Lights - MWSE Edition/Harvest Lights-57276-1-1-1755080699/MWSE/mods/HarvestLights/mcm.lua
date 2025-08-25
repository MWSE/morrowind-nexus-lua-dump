

local configLua = require("HarvestLights.config")
local config = configLua.settings
local configDefault = configLua.defaultConfig

----------------------
-- MCM Template --
----------------------

local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = "Harvest Lights"}
    template:saveOnClose("HarvestLights", config)

    -- Preferences Page
    local preferences = template:createSideBarPage{
        label = "Settings",
        noScroll = true,
    }
    preferences.sidebar:createCategory{ label = "Harvest Lights" }
    preferences.sidebar:createInfo{ text = "Disables nearby lights when containers are harvested and re-enables them once they have grown back. Sets of containers and the lights that they disable can be edited in the containers and lights page." }

    -- Feature Toggles
    local settings = preferences:createCategory{}
    settings:createOnOffButton{
        label = "Enabled",
        description = "Enables or disables the mod. Disabling the mod will also prevent disabled lights from being re-enabled normally.\nRequires Restart.\n\nDefault: On",
        variable = mwse.mcm.createTableVariable{
            id = "enabled",
            table = config,
            restartRequired = true
        },
    }

    settings:createSlider{
        label = "Light Distance",
        description = "The maximum distance that a light can be from a harvested container to be removed. The light must also be at least this far away from other suitable containers to be removed." ..
                        " Increasing this value will prevent lights that were placed further away from their containers from being ignored by this addon, but will also require more distant containers to be harvested for a light to be disabled." ..
                        "\nRequires Reload.\n\nDefault: 160",
        min = 96,
        max = 256,
        variable = mwse.mcm.createTableVariable{ id = "singleDistance", table = config }
    }

    local containerLightPage = template:createPage{
        label= "Containers and Lights",
        noScroll = true
    }

    containerLightPage:createInfo({ text = "The field below lists the sets of containers and the lights that they can disable when being harvested. Sets can be added, edited, or removed as you wish." .. 
                                            " The two kinds of sets are separated by a semicolon on each line, with container IDs (or distinct parts of container IDs) listed on the left and light IDs listed on the right." ..
                                            " Each ID must be surrounded by double quotation marks and be separated from others in the same set with commas and each ID should only appear once in the entire field. Do not forget to press enter to save your changes." ..
                                            "\nMake sure that mwse.log has no instances of \"[Harvest Lights] Error\" when loading a game after changing this field.\nRequires Reload.", })

    containerLightPage:createButton{
        label = "Reset to Default",
        callback = function()
            tes3.messageBox({ message = "Are you sure that you want to return to the default settings for containers and lights?",
            buttons = { "Yes", "No" },
            callback = function(e)
                if e.button == 0 then
	                config.containerLights = configDefault.containerLights
                    tes3.messageBox({ message = "Changes to the field won't be displayed until this page is re-opened." })
                end
            end })
        end
    }

    containerLightPage:createParagraphField{
        sNewValue = "Containers and lights saved",
        variable = mwse.mcm.createTableVariable{ id = "containerLights", table = config },
        height = 500,
        postCreate = function(component)
            component.elements.inputField.widget.lengthLimit = 99999
        end
    }

    local debugPage = template:createSideBarPage{
        label= "Debug Options",
        noScroll = true
    }
    preferences.sidebar:createInfo{"Harvest Lights v1.1"}

    debugPage:createOnOffButton{
        label = "Debug Mode",
        description = "Prints information on the container and light sets and the lights that are being disabled/enabled to mwse.log.\n\nDefault: Off",
        variable = mwse.mcm.createTableVariable{
            id = "debug",
            table = config,
        },
    }

    debugPage:createButton{
        buttonText = "Get Closest Light",
        description = "Prints the ID of the closest enabled light to mwse.log so that making or expanding the sets of containers and lights is more convenient.",
        inGameOnly = true,
        callback = function()
            local closestLight
            local closestLightPosition = math.huge
            for _,cell in pairs(tes3.getActiveCells()) do
                for light in cell:iterateReferences(tes3.objectType.light) do
                    if not light.disabled then
                        if not closestLight or light.position:distance(tes3.player.position) < closestLightPosition then
                            closestLight = light
                        end
                    end
                end
            end

            if closestLight then mwse.log(closestLight.baseObject.id) end
        end
    }

    debugPage:createButton{
        buttonText = "Re-enable Lights",
        description = "Re-enables all lights that have been disabled by this addon. This may be desirable if you are removing container and light sets or uninstalling the mod.",
        inGameOnly = true,
        callback = function()
            for _,cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
                for light in cell:iterateReferences(tes3.objectType.light) do
                    if light.data.harvestDisabled then
                        light:enable()
                        light.data.harvestDisabled = nil
                    end
                end
            end
        end
    }

    template:register()
end

event.register(tes3.event.modConfigReady, registerModConfig)