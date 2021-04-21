local config = require("sve.mcm quick keys.config")

local function saveConfig()
	mwse.saveConfig("mcm quick keys", config)
end

local function GetTextEnDis(self)
    local text = (
        self.variable.value and
--        tes3.findGMST("sOn").value or 
--        tes3.findGMST("sOff").value
	"Enabled" or
	"Disabled"
    )
    return text
end

local function nextSiblingIndentAndHide(state, labelText, indent)
    -- timer to run after MCM page is constructed
    timer.start({duration=0.01, type=timer.real, callback = function()
       local menuMCM = tes3ui.findMenu(tes3ui.registerID("MWSE:ModConfigMenu"))
       local contents = menuMCM:findChild(tes3ui.registerID(labelText))
       if contents ~= nil then
       	  contents = contents.parent.parent.parent
	  local index = 1
	  while contents.parent.children[index] ~= nil and contents.parent.children[index] ~= contents do
	     index = index + 1
	  end
	  if contents.parent.children[index+1] ~= nil then
       	     contents.parent.children[index+1].visible = state
 	     contents.parent.children[index+1].borderLeft = indent
	  end
       end
       menuMCM:updateLayout()
    end } )
end

local function GetText1(self)
   nextSiblingIndentAndHide(self.variable.value, "Label: MCM Quick Keys (this Mod)", 20)
   return GetTextEnDis(self)
end


local function GetText2(self)
   nextSiblingIndentAndHide(not self.variable.value, "Label:  ", 20)
   return GetTextEnDis(self)
end

local easyMCMConfig = {
	name = "MCM Quick Keys",
	template = "Template",
	pages = {
		{
			label = "SideBar Page",
			class = "SideBarPage",
			components = {
				{
					label = "MCM Quick Keys (this Mod)",
					class = "OnOffButton",
					description = "Enable or Disable MCM Quick Keys (this Mod).",
					variable = {
						id = "MCMquickKeysEnabled",
						class = "TableVariable",
						table = config,
					},
                   			postCreate = GetText1,
                   			getText = GetText1,
				},
               			{
					class = "Category",
               				label = nil,
               				components = {
					{
					class = "Category",
               				label = "Select by First Letter Combo Key(s)",
               				components = {
					{
						label = "Shift Key Down Required",
						class = "OnOffButton",
						description = "Requires the Shift Key be held doown to select a mod name from the MCM left side bar list by first letter.\n\nTap Shift-{a-z} to select the next mod on the list starting with that letter.",
						variable = {
							id = "selectModRequiresShiftKey",
							class = "TableVariable",
							table = config,
						},
					},
					{
						label = "Alt Key Down Required",
						class = "OnOffButton",
						description = "Requires the Alt Key be held doown to select a mod name from the MCM left side bar list by first letter.\n\nTap Alt-{a-z} to select the next mod on the list starting with that letter.",
						variable = {
							id = "selectModRequiresAltKey",
							class = "TableVariable",
							table = config,
						},
					},
					{
						label = "Ctrl Key Down Required",
						class = "OnOffButton",
						description = "Requires the Ctrl Key be held doown to select a mod name from the MCM left side bar list by first letter.\n\nTap Ctrl-{a-z} to select the next mod on the list starting with that letter.",
						variable = {
							id = "selectModRequiresCtrlKey",
							class = "TableVariable",
							table = config,
						},
					},
					},
					},
					{
					class = "Category",
               				label = "Select Prev/Next Mod Key Combos",
               				components = {
						{
						class = "KeyBinder",
						description = "Bind Key or Alt/Shft/Ctrl-Key Combo to select the previous mod on the MCM left side bar list.",
						variable = {
							id = "selectPrevModKeyInfo",
							class = "TableVariable",
							table = config,
						},
					},
						{
						class = "KeyBinder",
						description = "Bind Key or Alt/Shft/Ctrl-Key Combo to select the next mod on the MCM left side bar list.",
						variable = {
							id = "selectNextModKeyInfo",
							class = "TableVariable",
							table = config,
						},
					},
					},
					},
					{
					class = "Category",
               				label = "Mouse Wheel Up/Down Control",
               				components = {
				{
					class = "OnOffButton",
					description = "Allows scrolling the mouse wheel up/down to select the prev/next mod on the MCM left side bar list.\n\nShift/Alt/Control requirement defined by the above 2 Prev/Next Mod Key Combos.",
					variable = {
						id = "enableMouseScrollWheelAsArrowKeys",
						class = "TableVariable",
						table = config,
					},
                   			postCreate = GetTextEnDis,
                   			getText = GetTextEnDis,
				},
					},
					},
					{
					class = "Category",
               				label = "Open Mod MCM Pages as Selected",
               				components = {
				{
					class = "OnOffButton",
               				label = " ",
					description = "Open Mod MCM Pages as Selected by Quick Keys.\n\nNote: if not using Alt or Ctrl binding for quick keys, this could interfere with MCM page bind key, text entry, or any thing else using the keyboard.",
					variable = {
						id = "autoOpenAsSelected",
						class = "TableVariable",
						table = config,
					},
                   			postCreate = GetText2,
                   			getText = GetText2,
				},
					{
					class = "Category",
               				label = "Key Combo to Open the Selected Mod MCM Page",
               				components = {
						{
						class = "KeyBinder",
						description = "Bind Key or Alt/Shft/Ctrl-Key Combo to open the selected mod MCM page on the MCM left side bar list.",
						variable = {
							id = "openSelectedModMCMkeyInfo",
							class = "TableVariable",
							table = config,
						},
					},
					},
					},
					},
					},
					{
					class = "Category",
               				label = "Open Last Mod MCM Page Visited",
               				components = {
				{
					class = "OnOffButton",
					description = "On opening the Mod Configuration Menu, automatically open the last visited Mod MCM page.",
					variable = {
						id = "autoOpenLastPage",
						class = "TableVariable",
						table = config,
					},
                   			postCreate = GetTextEnDis,
                   			getText = GetTextEnDis,
				},
				},
				},
					},

				},
			},
            sidebarComponents = {
				{
			class = "Info",
					text = "Supports quick keys for selecting and opening mods from Mod Configuration Menu (MCM) left side bar.\n\nWhile holding a combination of Shift, Alt and/or Ctrl keys down, tap any a-z key to select the next mod in the list starting with that letter, or tap the up/down arrow keys to select the prev/next mod in the list.  Follow up with the open menu key-combo (default Shift-enter) to open the selected mod MCM page.",
			},
                {
                    class = "Category",
                    label = "By:",
                    components = {
                        {
                            class = "Hyperlink",
                            text = "Svengineer99",
                            exec = "start https://www.nexusmods.com/morrowind/users/1121630?tab=user+files",
                        },
                     },
                },
                {
                    class = "Category",
                    label = "Credit and Thanks to:",
                    components = {
                        {
                            class = "Hyperlink",
                            text = "Hrnchamd",
                            exec = "start https://www.nexusmods.com/morrowind/users/843673?tab=user+files",
                        },
                        {
                            class = "Hyperlink",
                            text = "NullCascade",
                            exec = "start https://www.nexusmods.com/morrowind/users/26153919?tab=user+files",
                        },
                        {
                            class = "Hyperlink",
                            text = "Greatness7",
                            exec = "start https://www.nexusmods.com/morrowind/users/64030?tab=user+files",
                        },
                        {
                            class = "Hyperlink",
                            text = "Merlord",
                            exec = "start https://www.nexusmods.com/morrowind/users/3040468?tab=user+files",
                        },
                        {
                            class = "Hyperlink",
                            text = "Petethegoat",
                            exec = "start https://www.nexusmods.com/morrowind/users/45692?tab=user+files",
                        },
                    },
                },
            },
        },
    },
	onClose = saveConfig,
}

return easyMCMConfig
