local config = require("sve.eagle eye.config")

local function saveConfig()
	mwse.saveConfig("eagle eye", config)
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

--[[ not used begin
local function setSliderLabelAsPercentage(self)
    local newValue = ""

    if self.elements.slider then
        newValue = self.elements.slider.widget.current + self.min
    end
  
    self.elements.label.text = self.label .. ": " .. newValue .. "%"

end
]]-- not used end

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
   nextSiblingIndentAndHide(self.variable.value, "Label: Extended Range for Object Tooltip Info", 20)
   return GetTextEnDis(self)
end

local function GetText1b(self)
   nextSiblingIndentAndHide(not self.variable.value, "Label: Mode of Operation", 20)
   local text = (
        self.variable.value and
--        tes3.findGMST("sOn").value or 
--        tes3.findGMST("sOff").value
	"Always Enabled" or
	"Bind Key Enabled"
    )
    return text
end

local function GetText2(self)
   nextSiblingIndentAndHide(self.variable.value, "Label: Cursor Lock on Object Target", 20)
   return GetTextEnDis(self)
end

local easyMCMConfig = {
	name = "Eagle Eye",
	template = "Template",
	pages = {
		{
			label = "SideBar Page",
			class = "SideBarPage",
			components = {
				{
					label = "Extended Range for Object Tooltip Info",
					class = "OnOffButton",
					description = "Object tooltips are visible beyond the normal activation/info distance.\n\nNice to not have run right up to things to see what (or who) they are.",
					variable = {
						id = "eagleEyeEnabled",
						class = "TableVariable",
						table = config,
					},
                   			postCreate = GetText1,
                   			getText = GetText1,
				},
               			{
					class = "Category",
               				components = { 
				{
					label = "Mode of Operation",
                   			description = "Sets the mode of operation for this functionality, either always enabled or enabled by holding the below defined bind key down.\n\nNice to not have run right up to things to see what (or who) they are, without another bind key to manage.",
					class = "OnOffButton",
					variable = {
						id = "eagleEyeAlwaysEnabled",
						class = "TableVariable",
						table = config,
					},
                   			postCreate = GetText1b,
                   			getText = GetText1b,
				},
	           {
                   class = "KeyBinder",
                   description = "Bind key for extended object tooltip info range.\n\nRelease the key to restore normal game behavior.\n\nNice to not have run right up to things to see what (or who) they are.",
		   label = "Bind Key",
                   variable = {
                                id = "eagleEyeKeyInfo",
                                class = "TableVariable",
                                table = config,
                     },
		   },
                   {
		   label = "Info Range",
                   class = "Slider",
                   description = "Maximum Distance in Game Units that Object Tooltips will Pop Up in with the extended info range bind key held down.\n\n128 Game Units ~6feet (2 meters)\nNormal Activation Distance = 192 Game Units.",
		   min = 192,
		   max = 8192,
		   step = 32,
		   jump = 192,
                   variable = {
                                id = "eagleEyeDistance",
                                class = "TableVariable",
                                table = config,
                              },
                   },
                   {
		   label = "Activation Range",
                   class = "Slider",
                   description = "Maximum Distance in Game Units that Object can be Activated with the extended object tooltip info range bind key held down.\n\n128 Game Units ~6feet (2 meters)\nNormal Activation Distance = 192 Game Units.",
		   min = 192,
		   max = 8192,
		   step = 64,
		   jump = 192,
                   variable = {
                                id = "normalActivationDistance",
                                class = "TableVariable",
                                table = config,
                              },
                   },
                   		{
					label = "Activator out of Range Message",
                   			class = "TextField", 
                   			description = "Activator out of Range Message.\n\nDelete (backspace out) for no messaging.",
                   			sNewValue = "Activator out of Range Message:%s",
                   			variable = {
                                		 id = "exceedsActivationDistanceMessage",                                
                                		 class = "TableVariable",
                                		 table = config,
                                		 defaultSetting = "Too far away.",
                     			},
                   		},
                   		},
                   		},
				{
					label = "Cursor Lock on Object Target",
					class = "OnOffButton",
					description = "With the bind key held down, the cursor will \"lock\" or \"freeze\" on the next object targeted\n\nUseful for focussing on small objects.",
					variable = {
						id = "tigerEyeEnabled",
						class = "TableVariable",
						table = config,
					},
                   			postCreate = GetText2,
                   			getText = GetText2,
				},
               			{
					class = "Category",
               				components = { 
	           {
                   class = "KeyBinder",
		   label = "Bind Key",
                   description = "Bind key for cursor lock/freeze on next object targeted.\n\nRelease the key to unlock/unfreeze the cursor.\n\nUseful for focussing on small objects.",
                   variable = {
                                id = "tigerEyeKeyInfo",
                                class = "TableVariable",
                                table = config,
                     },
                     },
                   {
		   label = "Item Distance Threshold",
                   class = "Slider",
                   description = "Distance to player in game units beyond which inventory Items will trigger cursor lock when targeted with the bind key held down.\n\n128 Game Units ~6feet (2 meters)\nNormal Activation Distance = 192 Game Units.",
		   min = 0,
		   max = 8192,
		   step = 16,
		   jump = 64,
                   variable = {
                                id = "tigerEyeDistanceItem",
                                class = "TableVariable",
                                table = config,
                              },
                   },
                   {
		   label = "Actor Distance Threshold",
                   class = "Slider",
                   description = "Distance to player in game units beyond which actors (NPCs and Creatures) will trigger cursor lock when targeted with the bind key held down.\n\n128 Game Units ~6feet (2 meters)\nNormal Activation Distance = 192 Game Units.",
		   min = 0,
		   max = 8192,
		   step = 16,
		   jump = 64,
                   variable = {
                                id = "tigerEyeDistanceActor",
                                class = "TableVariable",
                                table = config,
                              },
                   },
                   {
		   label = "Door, Container and Activator Distance Threshold",
                   class = "Slider",
                   description = "Distance to player in game units beyond which Fixed Position Objects (Containers, Doors, Activators) will trigger cursor lock when targeted with the bind key held down.\n\n128 Game Units ~6feet (2 meters)\nNormal Game Activation Distance = 192 Game Units.",
		   min = 0,
		   max = 8192,
		   step = 16,
		   jump = 64,
                   variable = {
                                id = "tigerEyeDistanceObject",
                                class = "TableVariable",
                                table = config,
                              },
                   },
--[[ hard coded always disable while running, walking, jumping, swimming
				{
					label = "With Player Running",
					class = "OnOffButton",
					description = "Disable With Player Running if using this mod feature default Left Shift bind key (where Left Shift forces running).",
					variable = {
						id = "tigerEyeEnabledRunning",
						class = "TableVariable",
						table = config,
					},
                   			postCreate = GetTextEnDis,
                   			getText = GetTextEnDis,
				},
				{
					label = "With Player Walking",
					class = "OnOffButton",
					description = "Disable With Player Walking if using this mod feature default Left Shift bind key with auto-run mode default running (where Left Shift forces walking).",
					variable = {
						id = "tigerEyeEnabledWalking",
						class = "TableVariable",
						table = config,
					},
                   			postCreate = GetTextEnDis,
                   			getText = GetTextEnDis,
				},
]]-- end hard coded
--[[ obsolete boudning box threshold checks
                   {
		   label = "Bounding Box Size Threshold",
                   class = "Slider",
                   description = "Objects with bounding box size (min vector length in game units) less than or equal to this value will trigger cursor lock when targeted with the bind key held down.\n\nIncrease/decrease to make more distant/close up objects able to trigger cursor lock.\n\nWorks independently to Bounding Box Size/Distanc Ratio Threshold (exceeding either will trigger cursor lock)",
		   min = 1,
		   max = 20,
		   step = 1,
		   jump = 2,
                   variable = {
                                id = "tigerEyeBoundingBoxMinLength",
                                class = "TableVariable",
                                table = config,
                              },
                   },
                   {
		   label = "Bounding Box Size/Distance Ratio Threshold",
                   class = "Slider",
                   description = "Objects with bounding box size (min vector length in game units) larger than this %% distance to the player will trigger cursor lock when targeted with the bind key held down.\n\nIncrease/decrease to make more distant/close up objects able to trigger cursor lock.\n\nWorks independently to Bounding Box Size Threshold (exceeding either will trigger cursor lock)",
		   min = 1,
		   max = 100,
		   step = 5,
		   jump = 20,
                   variable = {
                                id = "tigerEyeBoundingBoxMinToDistRatio",
                                class = "TableVariable",
                                table = config,
                              },
                   postCreate = setSliderLabelAsPercentage,
                   updateValueLabel = setSliderLabelAsPercentage,
                   },
]]-- obsolete end
				{
					label = "Inventory Item Cursor Lock",
					class = "OnOffButton",
					description = "Enable/disable cursor lock for inventory item tiles",
					variable = {
						id = "tigerEyeInventoryItemsEnabled",
						class = "TableVariable",
						table = config,
					},
                   			postCreate = GetTextEnDis,
                   			getText = GetTextEnDis,
				},
				{
					label = "Cursor Lock on Key Down",
					class = "OnOffButton",
					description = "When an object tooltip is already visible, enable/disable cursor lock when the bind key is pressed.\n\nFor example, if enabled, when a tooltip is visible and the cursor lock bind key is pressed, the cursor will lock on it",
					variable = {
						id = "lockOnBindKeyDown",
						class = "TableVariable",
						table = config,
					},
                   			postCreate = GetTextEnDis,
                   			getText = GetTextEnDis,
				},

                   {
		   label = "Skip Cursor Re-Locking on Same Object",
                   class = "Slider",
                   description = "When moving the cursor with locking among multiple objects, skip re-locking on the same object or identical object this many times.  For instance, if looking amoung several common rings and one exquisite ring then after locking on the first common ring then a setting of 1 will skip locking on another common ring next.\n\nTap the bind key a second time to re-set the feature and lock on the next object regardless if it's the same as the prior one.",
		   min = 0,
		   max = 2,
		   step = 1,
		   jump = 1,
                   variable = {
                                id = "skipRepetitiveLocks",
                                class = "TableVariable",
                                table = config,
                              },
                   },
                     },
		   },
                   		},
            sidebarComponents = {
				{
			class = "Info",
			text = "This mod adds 2 independently customizable game play features.\n\n1) Increase the distance that object tooltips display at.\n\nNice to not have run right up to things to see what (or who) they are.\n\n2) a bind key to lock the cursor on to objects when their tooltip pops up.\nUseful for focussing on small objects.\n\nRelease the associated bind key to restore normal functionality.\n\nAssign both functions to the same bind key for combied utilty.\n\nOnly works outside menu mode when the player is stationary, not walking, running, swimming or jumping.",
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
