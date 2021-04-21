local configTable = require("sve.journal.config")
local config = configTable[1]

local function saveConfig()
    mwse.saveConfig("journal search and edit", config)
----mwse.log("mwse.saveConfig(\"journal search and edit\", config)")
end

local function setSliderLabelAsPercentage(self)
    local newValue = ""

    if self.elements.slider then
        newValue = self.elements.slider.widget.current + self.min
    end
  
    self.elements.label.text = self.label .. ": " .. newValue .. "%"

end

local function setSliderLabelAsTenthPercentage(self)
    local newValue = ""

    if self.elements.slider then
        newValue = tostring( tonumber( self.elements.slider.widget.current + self.min ) / 10 )
    end
  
    self.elements.label.text = self.label .. ": " .. newValue .. "%"

end

local function enabledGetText(self)
    local text = (
        self.variable.value and 
        "Enabled" or 
        "Disabled"
    )
    -- one frame timer to run after MCM page is constructed
    local state = self.variable.value
    timer.start({duration=0.01, type=timer.real, callback = function()
       local menuMCM = tes3ui.findMenu(tes3ui.registerID("MWSE:ModConfigMenu"))
       local contents = menuMCM:findChild(tes3ui.registerID("Label: Mod Config Options"))
       if contents ~= nil then
       	  contents.parent.parent.visible = state
       end
    end } )       
    return text
end

local function restoreGetText(self)
   return "Restore"
end

local function restoreDefaults()
--mwse.log("restore config = configTable[2] ...")
   for key, value in pairs(configTable[2]) do
      if type(value) == "table" then
         for key2,value2 in pairs(value) do
            config[key][key2]=value2
--mwse.log("config[%s][%s]=%s", tostring(key), tostring(key2), tostring(value2))
         end
      else
         config[key] = value
--mwse.log("config[%s]=%s", tostring(key), tostring(value))
      end
    end
    local menuMCM = tes3ui.findMenu(tes3ui.registerID("MWSE:ModConfigMenu"))
    local contents = menuMCM:findChild(tes3ui.registerID("PartDragMenu_main"))
    local children = contents:findChild(tes3ui.registerID("PartScrollPane_pane")).children
    for i = 1, #children do
       if children[i].text == "Journal Search And Edit" then
          children[i]:triggerEvent("mouseClick")
       end
    end
end

local function registerRestoreDefaultsButton()
   local menuMCM = tes3ui.findMenu(tes3ui.registerID("MWSE:ModConfigMenu"))
   local label = menuMCM:findChild(tes3ui.registerID("Label: Default Settings"))
   label.parent.parent.children[1]:register("mouseClick", restoreDefaults)
end    

local function padOptionsBottom(self)
    local menuMCM = tes3ui.findMenu(tes3ui.registerID("MWSE:ModConfigMenu"))
    local contents = menuMCM:findChild(tes3ui.registerID("Label: Mod Config Options"))
    if contents ~= nil then
       contents.parent.paddingBottom = 5
    end
end

return {
    name = "Journal Search And Edit",
    pages = {
        {
            label = "Preferences",
            class = "SideBarPage",
            components = {
               {
               class = "Category",
               label = "MWSE Journal Search And Edit",
               components = {
	           {
                   class = "YesNoButton",
                   description = "Enable or Disable This Mod",
                   variable = {
                                id = "enabled",
                                class = "TableVariable",
                                table = config,
                     },
                   postCreate = enabledGetText,
                   getText = enabledGetText,
                   },
		   },
	       },
	       {
               class = "Category",
               label = "Mod Config Options",
	       postCreate = padOptionsBottom,
               components = {
               {
               class = "Category",
               label = "Hot Keys",
               components = {
	           {
                   class = "KeyBinder",
               	   label = "Close Journal",
                   description = "Bind Key to close the Journal, replaces the defalt \"J\" hot key.",
                   variable = {
                                id = "closeKeyInfo",
                                class = "TableVariable",
                                table = config,
                              },
                   },
	           {
                   class = "KeyBinder",
               	   label = "Continue Search Forward",
                   description = "Bind Key to search for the next match in the forward direction.\n\nTap to advance to next match.\nHold to advance pages to the next match.",
                   variable = {
                                id = "nextMatchKeyInfo",
                                class = "TableVariable",
                                table = config,
                              },
                   },
	           {
                   class = "KeyBinder",
               	   label = "Continue Search Backward",
                   description = "Bind Key to search for the next match in the backward direction.\n\nTap to advance to next match.\nHold to advance pages to the next match.",
                   variable = {
                                id = "prevMatchKeyInfo",
                                class = "TableVariable",
                                table = config,
                              },
                   },
	           {
                   class = "KeyBinder",
               	   label = "Continue Search",
                   description = "Bind Key to Continue searching for the next match in the last search direction, default backward on opening the Journal; same function as Continue Search Forward/Backward key bindings.\n\nTap to advance to next match.\nHold to advance pages to the next match.",
                   variable = {
                                id = "contMatchKeyInfo",
                                class = "TableVariable",
                                table = config,
                              },
                   },
	           {
                   class = "KeyBinder",
               	   label = "Select Edit Down",
                   description = "Bind Key to select the first or next journal entry for editing.\n\nExits edit mode when descending on the last visible entry.",
                   variable = {
                                id = "selectEditDownKeyInfo",
                                class = "TableVariable",
                                table = config,
                              },
                   },
	           {
                   class = "KeyBinder",
               	   label = "Select Edit Up",
                   description = "Bind Key to select the last or prior journal entry for editing.\n\nExits edit mode when ascending on the first visible entry.",
                   variable = {
                                id = "selectEditUpKeyInfo",
                                class = "TableVariable",
                                table = config,
                              },
                   },
	           {
                   class = "KeyBinder",
               	   label = "Insert Page",
                   description = "Bind Key to Insert a New Page.",
                   variable = {
                                id = "newPageInsertKeyInfo",
                                class = "TableVariable",
                                table = config,
                              },
                   },
	           {
                   class = "KeyBinder",
               	   label = "Delete Word",
                   description = "Bind Key to delete the word at or before the cursor.\n\nSide effect will move the cursor to the end of the entry.",
                   variable = {
                                id = "deleteWordKeyInfo",
                                class = "TableVariable",
                                table = config,
                              },
                   },
	           {
                   class = "KeyBinder",
               	   label = "Delete Entry",
                   description = "Bind Key to delete the entire text entry being edited.",
                   variable = {
                                id = "deleteEntryKeyInfo",
                                class = "TableVariable",
                                table = config,
                              },
                   },
	           {
               	   label = "Save and Exit Editing Mode",
                   class = "KeyBinder",
                   description = "Bind Key to save edit and exit editing mode.",
                   variable = {
                                id = "saveEditKeyInfo",
                                class = "TableVariable",
                                table = config,
                              },
                   },
	           {
                   class = "KeyBinder",
               	   label = "Exit Search or Edit Mode",
                   description = "Bind Key to exit search or edit mode, without saving.",
                   variable = {
                                id = "exitKeyInfo",
                                class = "TableVariable",
                                table = config,
                              },
                   },
	           {
                   class = "KeyBinder",
               	   label = "Flip Page Forward",
                   description = "Bind key to turn the page forward.  Tap to turns to the next page; hold to continue flipping pages forward.",
                   variable = {
                                id = "nextPageKeyInfo",
                                class = "TableVariable",
                                table = config,
                              },
                   },
	           {
                   class = "KeyBinder",
               	   label = "Flip Page Backwards",
                   description = "Bind key to turn the page backward.  Tap to turns to the prior page; hold to continue flipping pages backward.",
                   variable = {
                                id = "prevPageKeyInfo",
                                class = "TableVariable",
                                table = config,
                              },
                   },
	           {
                   class = "KeyBinder",
               	   label = "Insert next image",
                   description = "Bind Key to Insert the next image, recorded from books you have read.\n\nWorks for inserted pages, after entering edit mode, one image per page.",
                   variable = {
                                id = "nextImageKeyInfo",
                                class = "TableVariable",
                                table = config,
                              },
                   },
	           {
                   class = "KeyBinder",
               	   label = "Insert previous image",
                   description = "Bind Key to Insert the previous image, recorded from books you have read.\n\nWorks for inserted pages, after entering edit mode, one image per page.",
                   variable = {
                                id = "prevImageKeyInfo",
                                class = "TableVariable",
                                table = config,
                              },
                   },
                   {
		   label = "Image scale adjust increment",
                   class = "Slider",
                   description = "Percent increment in image scale increase or decrease",
		   min = 1,
		   max = 25,
		   step = 1,
		   jump = 5,
                   variable = {
                                id = "incrImageScaleStep",
                                class = "TableVariable",
                                table = config,
                              },
                   postCreate = setSliderLabelAsPercentage,
                   updateValueLabel = setSliderLabelAsPercentage,
                   },
	           {
                   class = "KeyBinder",
               	   label = "Increase Image Scale",
                   description = "Bind Key to Increase the visible image scale.",
                   variable = {
                                id = "incrImageScaleKeyInfo",
                                class = "TableVariable",
                                table = config,
                              },
                   },
	           {
                   class = "KeyBinder",
               	   label = "Decrease Image Scale",
                   description = "Bind Key to Decrease the visible image scale.",
                   variable = {
                                id = "decrImageScaleKeyInfo",
                                class = "TableVariable",
                                table = config,
                              },
                   },
                   {
                   label = "Image Fine Scale Adjust Increment",
                   class = "Slider",
                   description = "Percent increment in image fine scale increase or decrease",
		   min = 1,
		   max = 25,
		   step = 1,
		   jump = 5,
                   variable = {
                                id = "incrImageFineScaleStep",
                                class = "TableVariable",
                                table = config,
                              },
                   postCreate = setSliderLabelAsTenthPercentage,
                   updateValueLabel = setSliderLabelAsTenthPercentage,
                   },
	           {
                   class = "KeyBinder",
               	   label = "Increase Image Fine Scale",
                   description = "Bind Key to Increase the visible image fine scale.",
                   variable = {
                                id = "incrImageFineScaleKeyInfo",
                                class = "TableVariable",
                                table = config,
                              },
                   },
	           {
                   class = "KeyBinder",
               	   label = "Decrease Image Fine Scale",
                   description = "Bind Key to Decrease the visible image fine scale.",
                   variable = {
                                id = "decrImageFineScaleKeyInfo",
                                class = "TableVariable",
                                table = config,
                              },
                   },
		 },
	       },
	       {
               class = "Category",
               label = "Language Compatiblity and Preference",
               components = {
	           {
                   label = "No Book Art Message",
                   class = "TextField", 
                   description = "Message displayed when no book art is available for image insertion.\n\nThat is before any book or scroll has including an image has been opened in game.", 
                   sNewValue = "No Book Art Message:%s",
                   variable = {
                                id = "messageNoBookArt",                                
                                class = "TableVariable",
                                table = config,
                                defaultSetting = "Find images in books to trace innto your journal.",
                              },
                   },
	           {
                   label = "New Book Art Message",
                   class = "TextField", 
                   description = "Message displayed when a new book image has been viewed and is available for journal insertion.", 
                   sNewValue = "New Book Art Message:%s",
                   variable = {
                                id = "messageNewBookArt",                                
                                class = "TableVariable",
                                table = config,
                                defaultSetting = "You found a new image to trace into your journal.",
                              },
                   },
	           {
                   label = "New Book Art Messages",
                   class = "TextField", 
                   description = "Message displayed when multiple new book images have been viewed and are available for journal insertion.", 
                   sNewValue = "New Book Art Message:%s",
                   variable = {
                                id = "messageNewBookArts",                                
                                class = "TableVariable",
                                table = config,
                                defaultSetting = "You found new images to trace into your journal.",
                              },
                   },
                 },
	       },
	       {
               class = "Category",
               label = "Visual and Timing",
	       postCreate = padOptionsBottom,
               components = {
               {
               class = "Category",
               components = {
	           {
                   label = "New Text Section Marker",
                   class = "TextField", 
                   description = "Character(s) marking new text section(s).\n\nFor visual clue where text entry may be started in edit mode.\n\nEmpty string is OK.", 
                   sNewValue = "New Text Section Marker:%s",
                   variable = {
                                id = "newTextLine",                                
                                class = "TableVariable",
                                table = config,
                                defaultSetting = ">",
                              },
                    },
                        {
                            label = "Edit Mode Arrow Up/Down Key Cursor Characters Jumped",
                            class = "Slider",
                            description = "In edit mode, the ~number of characters jumped backward/forward using the arrow up/down keys.\nIncrease to jump more characters, decrease to jump fewer",
				min = 5,
				max = 100,
				step = 1,
				jump = 5,
                            variable = {
                                id = "cursorUpDownJumpChar",
                                class = "TableVariable",
                                table = config,
                            },
                        },
                        {
                            label = "Hide Redundant Date Headers",
                            class = "YesNoButton",
                            description = "Enable to hide the 2nd, 3rd, .. redundant (same date) header on each page, to open up more space for editing.",
                            variable = {
                                id = "hideRedundantDateHeaders",
                                class = "TableVariable",
                                table = config,
                            },
                        },
                        {
                            label = "Topic Space Compression",
                            class = "Slider",
                            description = "Percentage of standard space between topics.  Decrease for less space between topics, more space for editing.",
                            variable = {
                                id = "topicSpaceCompression",
                                class = "TableVariable",
                                table = config,
                            },
                            postCreate = setSliderLabelAsPercentage,
                            updateValueLabel = setSliderLabelAsPercentage,
                        },
                        {
                            label = "Page Turning Delay (milliseconds)",
                            class = "Slider",
                            description = "Delay between pages turning when holding Next/Prev Page or Next/Forward/Backward Search hot keys.  Typical engine latency was ~100ms in limited testing.  Decrease to turn pages faster, increase if page turning stops working.",
				min = 100,
				max = 1000,
				step = 5,
				jump = 50,
                            variable = {
                                id = "pageTurnDelay",
                                class = "TableVariable",
                                table = config,
                            },
                        },
                        {
                            label = "UI Latency (milliseconds)",
                            class = "Slider",
                            description = "Delay used to capture UI updates after mouse clicks or key presses.  20-100milliseconds range worked in limited testing.  Increase if journal functionality becomes unresponsive.",
				step = 5,
				jump = 10,
				min = 10,
				max = 200,
                            variable = {
                                id = "uiLatency",
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
               label = "Default Mod Configuration",
               components = {
	           {
                      class = "YesNoButton",
                      description = "Restore Default Settings",
		      label = "Default Settings",
                      variable = {
                                   id = "restoreDefaults",
                                   class = "TableVariable",
                                   table = config,
                        },
                        getText = restoreGetText,
		        postCreate = registerRestoreDefaultsButton,
                     },
                  },
               },
            },
            },
	    },
            sidebarComponents = {
                {
                    class = "MouseOverInfo",
                    text = "MWSE Journal Search And Edit 1.0.\n\nTo search:\nSimply start typing a search string.\nTap hot keys to find the next/prev match on open pages.\nHold hot keys to find matches on subsequent/prior pages.\n\nTo edit, navigate journal entries with hot keys (default shift cursor-up/down) and make changes.\n\nSee the hot key descriptions for more features and details."
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
                            text = "Petethegoat",
                            exec = "start https://www.nexusmods.com/morrowind/users/45692?tab=user+files",
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
                            text = "Danae",
                            exec = "start https://www.nexusmods.com/morrowind/users/1233897?tab=user+files",
                        },
                    },
                },
            },
        },
    },
    onClose = saveConfig,
}

