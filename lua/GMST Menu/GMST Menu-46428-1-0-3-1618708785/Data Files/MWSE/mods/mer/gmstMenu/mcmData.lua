
local path = "custom_gmsts"

local beforeHalf = "K"
local halfway = "L"

local function getGMSTs()
    local gmstLists = {
        floats = {},
        integers = {},
        string1 = {},
        string2 = {}
    }

    for name, index in pairs(tes3.gmst) do
        local value = tes3.findGMST(index).value
        if name and value and tes3.findGMST(name) then
            local thisTable
            local class
            local sliderMax = 1
            local numbersOnly = false

            if string.find(name, "^f") then
                class = "TextField"
                numbersOnly = true
                thisTable = gmstLists.floats
            elseif string.find(name, "^i") then
                class = "TextField"
                numbersOnly = true
                while value * 2 > sliderMax do
                    sliderMax = sliderMax * 10    
                end
                thisTable = gmstLists.integers
            elseif string.find(name, "^s") then
                class = "TextField"
                if string.sub(name, 2,2) < halfway then
                    thisTable = gmstLists.string1
                else
                    thisTable = gmstLists.string2
                end
            end
            
            local setting = {
                label = name,
                class = class,
                max = sliderMax,
                variable = {
                    class = "ConfigVariable",
                    id = name,
                    numbersOnly = numbersOnly,
                    path = path,
                    get = (
                        function(self)
                            local config = mwse.loadConfig(self.path)
                            --initialise config file if doesn't exist
                            if not config then
                                mwse.log("[GMST Menu] Config file '%s' does not exist. Creating new file", self.path)
                                config = {}
                                mwse.saveConfig(self.path, config)
                            end
                            return config[self.id] or tes3.findGMST(self.id).value
                        end
                    ),
                    set = (
                        function(self, newVal)
                            local config = mwse.loadConfig(self.path)
                            config[self.id] = newVal
                            mwse.saveConfig(self.path, config)
                            tes3.findGMST(self.id).value = (numbersOnly and tonumber(newVal) or newVal)
                        end
                    ),
                },
                formattedMessage = (
                    function(self)
                        self.label.wrapText = false
                    end
                )
            }
            
            table.insert(thisTable, setting)
        end
    end
    for listName, list in pairs(gmstLists) do
        table.sort(list, function(a, b)
            return a.label < b.label
        end)
    end
    return gmstLists
end


local gmsts = getGMSTs()

local function messageBox(params)

    local message = params.message
    local buttons = params.buttons

    local function callback(e)
        --get button from 0-indexed MW param
        local button = buttons[e.button+1]
        if button.callback then
            button.callback()
        end
    end

    --Make list of strings to insert into buttons
    local buttonStrings = {}
    for _, button in ipairs(buttons) do
        table.insert(buttonStrings, button.text)
    end

    tes3.messageBox({
        message = message,
        buttons = buttonStrings,
        callback = callback
    })
end

local sidebar = {
    {
        class = "Category",
        label = "Welcome to the GMST Menu!",
        components = {
            {
                class = "MouseOverInfo",
                text = ( 
                    "This menu allows you to change any GMST in Morrowind. " ..
                    "GMST changes are instantaneous, but restoring to their default values requires a restart of the game."
                ),
            },
            {
                class = "Button",
                buttonText = "Restore all GMSTs to default values",
                callback = (
                    function(self)
        
                        local sOk = tes3.findGMST(tes3.gmst.sOK).value
                        local sYes = tes3.findGMST(tes3.gmst.sYes).value
                        local sCancel = tes3.findGMST(tes3.gmst.sCancel).value
        
                        local function reset(e)
                            tes3.messageBox{
                                message = "Default values have been restored.",
                                buttons = { sOk }
                            }
                            mwse.saveConfig(path, {})
                        end
        
                        messageBox{
                            message = "Reset all GMSTs to their default values? The game must be restarted before this change will come into effect.",
                            buttons = { {text = sYes, callback = reset} , { text = sCancel } },
                        }
                    end
                ),
                postCreate = (
                    function(self)
                        self.elements.innerContainer.alignX = 0.5
                    end
                ),
            },--//button
        }
    },
    {
        class = "Hyperlink",
        text = "Made by Merlord",
        exec = "start https://www.nexusmods.com/users/3040468?tab=user+files",
        postCreate = (
            function(self)
                self.elements.outerContainer.alignY = 1.0
                self.elements.outerContainer.layoutHeightFraction = 1.0
                self.elements.info.layoutOriginFractionX = 0.5
            end
        ),
    },

}

local mcmData = {
    name = "GMST Menu",
    pages = {
        {
            label = "Integers",
            class = "FilterPage",
            components = gmsts.integers,
            sidebarComponents = sidebar
        },
        {
            label = "Floats",
            class = "FilterPage",
            components = gmsts.floats,
            sidebarComponents = sidebar
        },
        {
            label = string.format("Strings 0 to %s", beforeHalf),
            class = "FilterPage",
            components = gmsts.string1,
            sidebarComponents = sidebar
        },
        {
            label = string.format("Strings %s to Z", halfway),
            class = "FilterPage",
            components = gmsts.string2,
            sidebarComponents = sidebar
        },
    }
}

return mcmData