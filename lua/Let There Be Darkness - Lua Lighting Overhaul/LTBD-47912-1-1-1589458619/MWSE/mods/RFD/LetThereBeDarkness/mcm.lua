local config = require("RFD.LetThereBeDarkness.config")

local function getCells()
    local temp = {}
    local cells = tes3.dataHandler.nonDynamicData.cells

    for i=1, #cells do
		if (cells[i].isInterior == true) then
       		temp[cells[i].id:lower()] = true
		end
    end
    local list = {}
    for name in pairs(temp) do
        list[#list+1] = name
    end
    table.sort(list)
    return list
end

local function createCellPage(template)
    local page = template:createPage{
        label = "General and Cell Settings",
    }

    page:createInfo{
		text = "It's generally recommended that the adjustment values for all three components (red, green, blue) of each color are the same. Changing them individually may be used to give the interiors a different mood, for example by adding a green tint."
    }

    page:createSlider{
		label = "Ambient color adjustment (RED)",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "ambientColorR",
            table = config
        }
    }
    page:createSlider{
		label = "Ambient color adjustment (GREEN)",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "ambientColorG",
            table = config
        }
    }
    page:createSlider{
		label = "Ambient color adjustment (BLUE)",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "ambientColorB",
            table = config
        }
    }

	page:createSlider{
		label = "Fog color adjustment (RED)",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "fogColorR",
            table = config
        }
    }
	page:createSlider{
		label = "Fog color adjustment (GREEN)",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "fogColorG",
            table = config
        }
    }
	page:createSlider{
		label = "Fog color adjustment (BLUE)",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "fogColorB",
            table = config
        }
    }

	page:createSlider{
		label = "Sun color adjustment (RED)",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "sunColorR",
            table = config
        }
    }
	page:createSlider{
		label = "Sun color adjustment (GREEN)",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "sunColorG",
            table = config
        }
    }
	page:createSlider{
		label = "Sun color adjustment (BLUE)",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "sunColorB",
            table = config
        }
    }

	page:createOnOffButton{
    label = "Apply lighting changes only to whitelisted cells? This applies to both interior (lighting values and light objects) and exterior cells (light objects only).\nBy default, all vanilla interior cells are whitelisted, except of test cells.",
    variable = mwse.mcm.createTableVariable{
            id = "useWhitelisted",
            table = config
        }
	}
	page:createDropdown{
	label = "Cell lighting value overrides. The override values are read from overrides.lua, and can be different for each cell.",
	options = {
		{ label = "NONE", value = nil},
		{ label = "True Lights and Darkness", value = "TLaD"},
		{ label = "di.Still.ed Lights", value = "DL"},
	},
	variable = mwse.mcm.createTableVariable{
            id = "useOverrides",
            table = config
        }
	}

	page:createOnOffButton{
    label = "Use debug mode?\nThis allows you to view lighting values and other debug messages on-screen and in the MWSE log.",
    variable = mwse.mcm.createTableVariable{
            id = "debugMode",
            table = config
        }
	}

	--[[page:createKeyBinder{
    label = "Assign light settings preview key (allows for editing each color value separately, \nuseful for finding appropriate values during level design)",
    allowCombinations = false,
    variable = mwse.mcm.createTableVariable{
        id = "hotkeyPreview",
        table = config,
		}
	}]]

    return page
end

local function createLightPage(template)
    local page = template:createPage{
        label = "Light Settings",
    }
	page:createInfo{
		text = "Changing any of these settings REQUIRES GAME RESTART."
	}

	page:createInfo{
		text = "If you disable all light flickering, including fire flickering, it's recommended that you set radius scaling to around 80%."
    }

	page:createSlider{
		label = "Light radius scaling [recommended values are 80 - 120%]",
        min = 25,
        max = 300,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "scaleLightRadius",
            table = config
        }
    }

	page:createSlider{
		label = "Light radius scaling cutoff [lights with a radius bigger than this won't be scaled]",
        min = 64,
        max = 4096,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "scaleCutoff",
            table = config
        }
    }

	page:createOnOffButton{
    label = "Disable lights without a mesh?",
	restartRequired = true,
    variable = mwse.mcm.createTableVariable{
            id = "disableLights",
            table = config
        }
	}
	page:createOnOffButton{
    label = "Disable only blacklisted lights without a mesh? This option is relevant only if the previous one is turned on",
	restartRequired = true,
    variable = mwse.mcm.createTableVariable{
            id = "blacklistLights",
            table = config
        }
	}
	page:createOnOffButton{
    label = "Disable dark (negative) lights?",
	restartRequired = true,
    variable = mwse.mcm.createTableVariable{
            id = "nukeDarkLights",
            table = config
        }
	}
	page:createOnOffButton{
    label = "Disable light flickering? This does not apply to fire: torches, braziers, etc.",
	restartRequired = true,
    variable = mwse.mcm.createTableVariable{
            id = "noFlicker",
            table = config
        }
	}
	page:createOnOffButton{
    label = "Apply flicker removal to fire, too? This takes effect only if [disable light flickering] is enabled.",
	restartRequired = true,
    variable = mwse.mcm.createTableVariable{
            id = "noFireFlicker",
            table = config
        }
	}
	page:createOnOffButton{
    label = "Use TLaD overrides for radius and color of light sources?",
	restartRequired = true,
    variable = mwse.mcm.createTableVariable{
            id = "lightOverride",
            table = config
        }
	}
	page:createOnOffButton{
    label = "Use True Skyrimized Torches overrides for lights that can be carried? This setting overwrites TLaD radius settings, but preserves the color.",
	restartRequired = true,
    variable = mwse.mcm.createTableVariable{
            id = "torchOverride",
            table = config
        }
	}

    return page
end

local function createCellWhitelist(template)
    template:createExclusionsPage{
        label = "Whitelist cells",
        description = "Choose cells which are affected by lighting changes if [only whitelisted cells] is enabled.",
        leftListLabel = "Whitelisted cells",
        rightListLabel = "Cells",
        variable = mwse.mcm.createTableVariable{
            id = "affectedCells",
            table = config,
        },
        filters = {
            {callback = getCells},
        },
    }
end

local function createLightBlacklist(template)
    template:createExclusionsPage{
        label = "Blacklist lights",
        description = "These lights are disabled if [disable lights] and [disable only blacklisted lights] are enabled.\nNote: if you remove any lights from the blacklist, you will need to restart the game to see the change. If you add lights to the blacklist, the change to your current cell will be applied once you reenter it.",
        leftListLabel = "Blacklisted lights",
        rightListLabel = "Lights without a visible mesh",
        variable = mwse.mcm.createTableVariable{
            id = "lightBlacklist",
            table = config,
        },
        filters = {
        	{
            label = "Lights",
            type = "Object",
            objectType = tes3.objectType.light,
			objectFilters = {
                mesh = "",
			},
        },
        },
    }
end

local template = mwse.mcm.createTemplate("Let There Be Darkness")
template:saveOnClose("Let There Be Darkness", config)

createCellPage(template)
createLightPage(template)
createCellWhitelist(template)
createLightBlacklist(template)

mwse.mcm.register(template)