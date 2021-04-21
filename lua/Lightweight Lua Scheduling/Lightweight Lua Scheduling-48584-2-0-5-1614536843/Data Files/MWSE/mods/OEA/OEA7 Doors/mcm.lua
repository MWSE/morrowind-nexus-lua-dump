local config = require("OEA.OEA7 Doors.config")

local template = mwse.mcm.createTemplate({ name = "Lightweight Lua Scheduling" })
template:saveOnClose("Lightweight_Lua_Scheduling", config)

local page = template:createPage()
page.label = "Buttons"
page.noScroll = true
page.indent = 0
page.postCreate = function(self)
    self.elements.innerContainer.paddingAllSides = 10
end

local sign = page:createYesNoButton{
    label = "Lock doors and containers at night?",
    variable = mwse.mcm:createTableVariable{
        id = "Lock",
        table = config
    }
}

local banner = page:createYesNoButton{
    label = "Disable non-Guard NPCs at night?",
    variable = mwse.mcm:createTableVariable{
        id = "Person",
        table = config
    }
}

local banner2 = page:createYesNoButton{
    label = "Prevent dialogue in interiors at night?",
    variable = mwse.mcm:createTableVariable{
        id = "Crime",
        table = config
    }
}

local bann2 = page:createYesNoButton{
    label = "Disable non-Blacklisted NPCs during inclement weather?",
    variable = mwse.mcm:createTableVariable{
        id = "Rain",
        table = config
    }
}

page:createDropdown({
    label = "Inclement weather is defined as this number and greater:",
    options = {
        {label = "1 Clear", value = tes3.weather.clear},
        {label = "2 Cloudy", value = tes3.weather.cloudy},
        {label = "3 Foggy", value = tes3.weather.foggy},
        {label = "4 Overcast", value = tes3.weather.overcast},
        {label = "5 Rain", value = tes3.weather.rain},
        {label = "6 Thunderstorm", value = tes3.weather.thunder},
        {label = "7 Ashstorm", value = tes3.weather.ash},
        {label = "8 Blight", value = tes3.weather.blight},
        {label = "9 Snow", value = tes3.weather.snow},
        {label = "10 Blizzard", value = tes3.weather.blizzard}
    },
    defaultSetting = tes3.weather.rain,
    variable = mwse.mcm:createTableVariable({id = "worstWeather", table = config})
})

local hotkey2 = page:createKeyBinder{
    label = "This key allows you to instantly trigger the cell-change event, thereby causing disabling etc.",
    allowCombinations = true,
    variable = mwse.mcm:createTableVariable{
        id = "Button",
        table = config,
    }
}

local bann = page:createYesNoButton{
    label = "Show a message when using the above button?",
    variable = mwse.mcm:createTableVariable{
        id = "Message",
        table = config
    }
}

local bann69 = page:createYesNoButton{
    label = "Have aforementioned cell-change event also fire on a timer (must restart to apply change)?",
    variable = mwse.mcm:createTableVariable{
        id = "Timing",
        table = config
    }
}

local Z = page:createSlider{
    label = "Lockdown Start Hour",
    variable = mwse.mcm:createTableVariable{
    id = "Start", 
    table = config
},
min = 0,
max = 23,
step = 1,
jump = 5
}

local ZZ = page:createSlider{
    label = "Lockdown End Hour",
    variable = mwse.mcm:createTableVariable{
    id = "End", 
    table = config
},
min = 0,
max = 23,
step = 1,
jump = 5
}

local hotkey = template:createExclusionsPage{
    label = "Blacklists",
    description = ("NPCs on the Blacklist will not disappear, and will be not be made unavailible to talk to if indoors. "..
        "Interior Cells on the Blacklist will not have the doors to them locked, and their NPCs will not be made non-conversational. ".. 
	"Exterior cells will have neither doors nor NPCs in them affected. "..
        "For Plugins, all of the above applies to all applicable data from the mod, except cells. "..
        "One final note is that many exterior cells have the same name, and so you will need to use trial and error to disable the correct ones."
    ),
    showAllBlocked = false,
    variable = mwse.mcm:createTableVariable{
        id = "IsBlocked",
        table = config,
    },

    filters = {
        {
            label = "Plugins",
            type = "Plugin",
        },
        {
            label = "NPCs",
            type = "Object",
            objectType = tes3.objectType.npc
        },
        {
            label = "Cells",
            callback = (
                function(self)
                    local CellNames = {}
                    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
                        table.insert(CellNames, cell.id:lower())
                    end
                    return CellNames
                end
            )
        }
    }
}


mwse.mcm.register(template)