local config = require("sve.main menu quick keys.config")

local function saveConfig()
	mwse.saveConfig("main menu quick keys", config)
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

    local keyBindsMCMtable = {}
    for setting, info in pairs(config) do
	if type(info) == "table" and info.keyCode ~= nil then
	   table.insert(keyBindsMCMtable, {
	   index = info.index,
	   label = info.text,
           class = "KeyBinder",
	   description = "Main Menu " .. info.text .. " Quick Key Combo.",
	   variable = {
	   	      id = setting,
		      class = "TableVariable",
		      table = config,
		      },
	   })
       end
    end
    table.sort(keyBindsMCMtable, function(a,b) return a.index < b.index end)

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
    end } )       
end

local function GetText1(self)
   nextSiblingIndentAndHide(self.variable.value, "Label: Main Menu Quick Keys (this Mod)", 20)
   return GetTextEnDis(self)
end
local easyMCMConfig = {
	name = "Main Menu Quick Keys",
	template = "Template",
	pages = {
		{
			label = "SideBar Page",
			class = "SideBarPage",
			components = {
				{
					label = "Main Menu Quick Keys (this Mod)",
					class = "OnOffButton",
					description = "Enable or Disable Main Menu Quick Keys (this Mod).",
					variable = {
						id = "mainMenuQuickKeysEnabled",
						class = "TableVariable",
						table = config,
					},
                   			postCreate = GetText1,
                   			getText = GetText1,
				},
               			{
					class = "Category",
               				label = nil,
               				components = keyBindsMCMtable,

				},
			},
            sidebarComponents = {
				{
			class = "Info",
					text = "Supports Quick Keys for Main Menu buttons, such as 'm' to open the MCM, 'e' or 'x' to Exit, etc.\n\nCombine with Auto Yes to All for single key tap Exit, etc.",
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
