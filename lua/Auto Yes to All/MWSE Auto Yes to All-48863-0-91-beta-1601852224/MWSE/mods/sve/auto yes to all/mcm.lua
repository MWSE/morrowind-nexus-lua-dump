local config = require("sve.auto yes to all.config")

local function saveConfig()
	mwse.saveConfig("auto yes to all", config)
end

local expandPerMessageTable = { ["autoYesToAllLoadErrors"] = false, ["autoYesToAllGamePrompts"] = false }

local function GetTextEnDis(self)
    local text = (
        self.variable.value and
        tes3.findGMST("sOn").value or 
        tes3.findGMST("sOff").value
--	"Enabled" or
--	"Disabled"
    )
    return text
end

local function GetTextShowHide(self)
    local text = (
        self.variable.value and 
        tes3.findGMST("sClose").value or 
        tes3.findGMST("sEffectOpen").value
--        "Hide" or 
--        "Show"
    )
    return text
end

local loadErrorMCMTable = {}
    for text,_ in pairs(config.loadErrorTextSubStrings) do
    table.insert(loadErrorMCMTable,	{
					label = ( text == ".*" ) and "!! ALL LOAD ERROR AND WARNING PROMPTS with \"Yes\" or \"Yes to All\" buttons" or text:gsub("\r*\n%s*","  "),
					class = "OnOffButton",
					description = "If enabled, " .. ( ( text == ".*" ) and "\n\nALL LOAD ERROR AND WARNING PROMPTS" or "load error and warning prompts containing text:\n\n\"" .. text:gsub("\r*\n%s*","  ") .."\"" ) .. "\n\nwith \"Yes\" and/or \"Yes to All\" buttons will be automatically accepted.",
					variable = {
						id = text,
						class = "TableVariable",
						table = config.loadErrorTextSubStrings,
					},
                   			postCreate = GetTextEnDis,
                   			getText = GetTextEnDis,
				})
    end
    table.sort(loadErrorMCMTable, function(a,b) return a.label < b.label end )

local gamePromptMCMTable = {}
    for text,_ in pairs(config.gamePromptTextSubStrings) do
    table.insert(gamePromptMCMTable,	{
					label = ( text == ".*" ) and "!! ALL GAME PLAY PROMPTS with \"Yes\" or \"Yes to All\" buttons" or text:gsub("\r*\n%s*","  "),
					class = "OnOffButton",
					description = "If enabled, " .. ( ( text == ".*" ) and "\n\nALL GAME PLAY PROMPTS" or "game play prompts including text:\n\n\"" .. text:gsub("\r*\n%s*","  ") .. "\"" ) .. "\n\nwith \"Yes\" and/or \"Yes to All\" buttons will be automatically accepted.\n\n\n\nNote:\n\nThis list was compiled based largely on visual inspection of GMSTs that could possibly prompt for acceptance during game play; as such, many likely don't include a prompt and could be deleted or commented out by direclty editing config file.  Additionally, new prompt strings or sub-strings could be added in this manner, if something is found missing.\n\nTo add, remove or modify items from the list, use a text editor to open and edit the Data Files\\MWSE\\config\\auto yes to all.json file \"gamePromptTextSubStrings\" section, save and then restart Morrowind to load the changes from file.\n\nShould this .json file become corrupted due to editing, such that the mod stops working as expected, delete the .json file and restart Morrowind to regenerate the config file with default values.",
					variable = {
						id = text,
						class = "TableVariable",
						table = config.gamePromptTextSubStrings,
					},
                   			postCreate = GetTextEnDis,
                   			getText = GetTextEnDis,
				})
    end
    table.sort(gamePromptMCMTable, function(a,b) return a.label < b.label end )

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

local function GetText01(self)
   nextSiblingIndentAndHide(self.variable.value, "Label: Auto Yes to Load Error and Warning Prompts", 10)
   if expandPerMessageTable["autoYesToAllLoadErrors"] == true  then
      nextSiblingIndentAndHide(self.variable.value, "Label: List of Load Errors and Warnings", 20)
   end
   return GetTextEnDis(self)
end

local function GetText1(self)
   nextSiblingIndentAndHide(self.variable.value, "Label: List of Load Errors and Warnings", 20)
   return GetTextShowHide(self)
end

local function GetText02(self)
   nextSiblingIndentAndHide(self.variable.value, "Label: Auto Yes to Game Play Prompts", 10)
   if expandPerMessageTable["autoYesToAllGamePrompts"] == true  then
      nextSiblingIndentAndHide(self.variable.value, "Label: List of Game Play Prompts", 20)
   end
   return GetTextEnDis(self)
end

local function GetText2(self)
   nextSiblingIndentAndHide(self.variable.value, "Label: List of Game Play Prompts", 20)
   return GetTextShowHide(self)
end


local function GetText3(self)
   nextSiblingIndentAndHide(self.variable.value, "Label: Display Messages", 10)
   return GetTextEnDis(self)
end

local easyMCMConfig = {
	name = "Auto Yes to All",
	template = "Template",
	pages = {
		{
			label = "SideBar Page",
			class = "SideBarPage",
			components = {
				{
					label = "Auto Yes to Load Error and Warning Prompts",
					class = "OnOffButton",
					description = "If enabled, select Load Error and Warning pop up messages with \"Yes\" and/or \"Yes to All\" buttons will be automatically accepted.",
					variable = {
						id = "autoYesToAllLoadErrors",
						class = "TableVariable",
						table = config,
					},
                   			postCreate = GetText01,
                   			getText = GetText01,
				},
				{
					label = "List of Load Errors and Warnings",
					class = "YesNoButton",
					description = "Opens the list of Load Error and Warning Prompt messages that can be selected or desletected to trigger Auto Yes or Yes to All.",
					variable = {
						id = "autoYesToAllLoadErrors",
						class = "TableVariable",
						table = expandPerMessageTable,
					},
                   			postCreate = GetText1,
                   			getText = GetText1,
				},
               			{
					class = "Category",
               				label = nil,
               				components = loadErrorMCMTable,

				},
				{
					label = "Auto Yes to Game Play Prompts",
					class = "OnOffButton",
					description = "If enabled, Game Play Prompt pop up messages with \"Yes\" and/or \"Yes to All\" buttons will be automatically accepted.",
					variable = {
						id = "autoYesToAllGamePrompts",
						class = "TableVariable",
						table = config,
					},
                   			postCreate = GetText02,
                   			getText = GetText02,
				},
				{
					label = "List of Game Play Prompts",
					class = "YesNoButton",
					description = "Opens the list of Game Play Prompt messages that will trigger Auto Yes or Yes to All.",
					variable = {
						id = "autoYesToAllGamePrompts",
						class = "TableVariable",
						table = expandPerMessageTable,
					},
                   			postCreate = GetText2,
                   			getText = GetText2,
				},
               			{
					class = "Category",
               				label = nil,
               				components = gamePromptMCMTable,

				},
				{
					label = "Display Messages",
					class = "OnOffButton",
					description = "If enabled, the original pop up message will be replaced with a new one, without \"Yes\" and/or \"Yes to All\" buttons.\n\nNote: In some cases, the original pop up message with \"Yes\" and/or \"Yes to All\" buttons may still transiently flash on screen, and/or the replacement messages may only be visible in a short flash, or not at all, depending on the related game function.",
					variable = {
						id = "displayMessages",
						class = "TableVariable",
						table = config,
					},
                   			postCreate = GetText3,
                   			getText = GetText3,
				},
                   		{
					label = "Displayed Message Trailer:",
                   			class = "TextField", 
                   			description = "With Display Messages enabled, this text is appended to the displayed messages.\n\n^buttonText will be replaced by the specific message prompt button text, for English language that would be \"Yes\" or \"Yes to All\"\n\nEnter to save the edit.",
                   			sNewValue = "Displayed Message Trailer:%s",
                   			variable = {
                                		 id = "acceptMessageTrailer",                                
                                		 class = "TableVariable",
                                		 table = config,
                                		 defaultSetting = "Auto ^buttonText",
                     			},
                   		},
			},
			sidebarComponents = {
				{
					label = "Auto Yes (to All) Mod Description",
					class = "Info",
					text = "This mod automatically accepts select Load Error and Warning Prompts and Game Play Prompts with \"Yes\" and/or \"Yes to All\" button options.\n\n" ..
					       "Relevant standard Game Settings (GMST) defined prompts, plus a few non-GMST defined ones (such as \"Could not locate global script..\"), are included in the default configuration.  These may be selectively disabled or blanket accepted by opening and toggeling the related list items on/off.\n\n" ..
					       "Alternative method to remove, modify or add a messages to the auto-accept lists: open, modify and save the Data Files\\MWSE\\config\\auto yes to all.json file \"loadErrorTextSubStrings\" and/or \"gamePromptTextSubStrings\" sections, using a text editor, save and re-start the game to load in the updaed config file.\n\n" ..
					       "Should the Data Files\\MWSE\\config\\auto yes to all.json file become somehow corrupted during editing, delete the file and it will be regenerated to default values on re-start",
				},
			},
		},
	},
	postCreate = function()
	   local function recursiveUnWrapText(contents)
	      if contents.text ~= nil then
	         contents.wrapText = false
		 if string.find(contents.text,"^!! ALL") ~= nil then contents.color = tes3ui.getPalette("header_color") end
	      end
	      for i = 1, #contents.children do
		 recursiveUnWrapText(contents.children[i])
	      end
           end
	   local menuMCM = tes3ui.findMenu(tes3ui.registerID("MWSE:ModConfigMenu"))
	   local contents = menuMCM:findChild(tes3ui.registerID("Label: List of Load Errors and Warnings"))
	   contents = contents.parent.parent.parent
	   local index = 1
	   while contents.parent.children[index] ~= nil and contents.parent.children[index] ~= contents do
	      index = index + 1
	   end
	   if contents.parent.children[index+1] ~= nil then
	      recursiveUnWrapText(contents.parent.children[index+1])
	   end
	   contents = menuMCM:findChild(tes3ui.registerID("Label: List of Game Play Prompts"))
	   contents = contents.parent.parent.parent
	   index = 1
	   while contents.parent.children[index] ~= nil and contents.parent.children[index] ~= contents do
	      index = index + 1
	   end
	   if contents.parent.children[index+1] ~= nil then
	      recursiveUnWrapText(contents.parent.children[index+1])
	   end
	end,
	onClose = saveConfig,
}

return easyMCMConfig
