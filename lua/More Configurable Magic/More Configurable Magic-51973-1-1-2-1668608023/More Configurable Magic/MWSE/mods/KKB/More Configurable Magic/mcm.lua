local config = require("KKB.More Configurable Magic.config")

local function saveConfig()
	mwse.saveConfig("KKB.More Configurable Magic", config)
end


local easyMCMConfig = {
	name = "More Configurable Magic",
	template = "Template",
    pages = {
        {
            label = "Base Settings",
            class = "SideBarPage",
            components = {
                {
                    label = "Magnitude",
                    class="TextField",
                    description = "Max allowed value for effect magnitude.",
                    variable = {
                        id = "mag",
                        class = "TableVariable",
                        numbersOnly=true,
                        table = config
                    }
                },
                {
                    label = "Duration",
                    class="TextField",
                    description = "Max allowed value for effect duration.",
                    variable = {
                        id = "duration",
                        class = "TableVariable",
                        numbersOnly=true,
                        table = config
                    }
                },
                {
                    label = "Area",
                    class="TextField",
                    description = "Max allowed value for effect area.",
                    variable = {
                        id = "area",
                        class = "TableVariable",
                        numbersOnly=true,
                        table = config
                    }
                },
                {
                    label = "Magnitude jump",
                    class="TextField",
                    description = "Slider jump value (clicking on slider but not arrows) for magnitude.",
                    variable = {
                        id = "magJump",
                        class = "TableVariable",
                        numbersOnly=true,
                        table = config
                    }
                },
                {
                    label = "Duration jump",
                    class="TextField",
                    description = "Slider jump value (clicking on slider but not arrows) for duration.",
                    variable = {
                        id = "durJump",
                        class = "TableVariable",
                        numbersOnly=true,
                        table = config
                    }
                },
                {
                    label = "Area jump",
                    class="TextField",
                    description = "Slider jump value (clicking on slider but not arrows) for area.",
                    variable = {
                        id = "areaJump",
                        class = "TableVariable",
                        numbersOnly=true,
                        table = config
                    }
                },
                {
                    label = "Text field inputs?",
                    class = "OnOffButton",
                    description = "Replace sliders with input fields, for those of us who hate clicking.",
                    variable = {
                        id = "inputField",
                        class = "TableVariable",
                        table = config,
                    },
                },
                {
                    label = "Copy/paste buttons",
                    class = "OnOffButton",
                    description = "Add buttons to copy and paste effect values. CTRL-click Paste to paste without closing the effect maker window.",
                    variable = {
                        id = "copyPaste",
                        class = "TableVariable",
                        table = config,
                    },
                },
                {
                    label = "Keyboard shortcuts",
                    class = "OnOffButton",
                    description = "TAB/SHIFT-TAB to cycle back and forth between input fields. ENTER to press OK. DELETE to press Delete. CTRL-C/V for copy/paste buttons.",
                    variable = {
                        id = "keyboardShortcuts",
                        class = "TableVariable",
                        table = config,
                    },
                },
                {
                    label = "Copy stats?",
                    class = "OnOffButton",
                    description = "When copy/pasting effects that affect specific skills or attributes, select whether to also paste the stat in question. CTRL-Copy does not copy the stat.",
                    variable = {
                        id = "copyStatIds",
                        class = "TableVariable",
                        table = config,
                    },
                },
            },
            sidebarComponents = {
                {
                    label = "More Configurable Magic",
                    class = "Info",
                    text = "Tweaks for spellmaking and enchanting effect creation menus."},
            },
        }
    },
	onClose = saveConfig,
}

return easyMCMConfig
