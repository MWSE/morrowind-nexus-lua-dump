-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--[[            _         __     __         _                   _ _ 
     /\        | |        \ \   / /        | |            /\   | | |
    /  \  _   _| |_ ___    \ \_/ /__  ___  | |_ ___      /  \  | | |
   / /\ \| | | | __/ _ \    \   / _ \/ __| | __/ _ \    / /\ \ | | |
  / ____ \ |_| | || (_) |    | |  __/\__ \ | || (_) |  / ____ \| | |
 /_/    \_\__,_|\__\___/     |_|\___||___/  \__\___/  /_/    \_\_|_|

-- by svengineer99
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  _______ _                 _                          _  
 |__   __| |               | |                        | | 
    | |  | |__   __ _ _ __ | | _____    __ _ _ __   __| | 
    | |  | '_ \ / _` | '_ \| |/ / __|  / _` | '_ \ / _` | 
    | |  | | | | (_| | | | |   <\__ \ | (_| | | | | (_| | 
    |_|  |_| |_|\__,_|_| |_|_|\_\___/  \__,_|_| |_|\__,_|
   _____              _ _ _     _            
  / ____|            | (_) |   | |         _ 
 | |     _ __ ___  __| |_| |_  | |_ ___   (_)
 | |    | '__/ _ \/ _` | | __| | __/ _ \     
 | |____| | |  __/ (_| | | |_  | || (_) |  _ 
  \_____|_|  \___|\__,_|_|\__|  \__\___/  (_)
  
  Hrnchamd for UI Inspector, MGE-XE Yes to All, ..
  NullCascade, Greatness7 and team for MWSE lua scripting development and docs
  NullCascode, Greatness7, Merlord, Petethegoat, Mort, Remiros, Abot, ... for
     Released and unreleased lua scripting references
     Morrowind Discord #MWSE channel chat discussion, help, ...

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
 __          __              _                               _ 
 \ \        / /             (_)                             | |
  \ \  /\  / /_ _ _ __ _ __  _ _ __   __ _    __ _ _ __   __| |
   \ \/  \/ / _` | '__| '_ \| | '_ \ / _` |  / _` | '_ \ / _` |
    \  /\  / (_| | |  | | | | | | | | (_| | | (_| | | | | (_| |
     \/  \/ \__,_|_|  |_| |_|_|_| |_|\__, |  \__,_|_| |_|\__,_|
                                      __/ |                    
  _____  _          _       _        |___/                     
 |  __ \(_)        | |     (_)                      _ 
 | |  | |_ ___  ___| | __ _ _ _ __ ___   ___ _ __  (_)
 | |  | | / __|/ __| |/ _` | | '_ ` _ \ / _ \ '__|     
 | |__| | \__ \ (__| | (_| | | | | | | |  __/ |     _ 
 |_____/|_|___/\___|_|\__,_|_|_| |_| |_|\___|_|    (_)
                                                                 
  Not well optimized, organized, commented; sometimes hacky scripting.

  No reflection of MWSE devs and other scripters superior example and practice.

  Not recommended as a reference unless no other can be found.

]]--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

   local config -- config settings
   local loadState = nil -- nil:1st load, false:pre-load after 1st, true:ready to load >1st
   local loadInProgress = false -- flag if load is in progress or not to determine prompt list
   local clearMessagesFlag = false -- true:clear messages after first load on keypress
   local combinedList = {} -- combined Load and Game Settings lists..
   	 	       	   -- because some load messages can pop up durning gameplay
			   -- such as missing meshes, etc.
   
   local function onUIActivatedMenuMessage(e)
      --mwse.log("uiActivated, e.element.name:" ..tostring(e.element.name))
      local subStringList = nil
      if config.autoYesToAllGamePrompts and config.autoYesToAllLoadErrors then
      	 subStringList = combinedList
      elseif config.autoYesToAllLoadErrors then
      	 subStringList = config.loadErrorTextSubStrings
      elseif not loadInProgress and config.autoYesToAllGamePrompts then
      	 subStringList = config.gamePromptTextSubStrings
      else
         return
      end
      local element = e.element:findChild(tes3ui.registerID("MenuMessage_message"))
      if element == nil or element.text == nil then return end
      --mwse.log("MenuMessage_message.text:" .. element.text)
      local button_layout = e.element:findChild(tes3ui.registerID("MenuMessage_button_layout"))
      for subString,enabled in pairs(subStringList) do
         subString = subString:gsub("%%[sid]",".*")
	 --mwse.log("errorMessageSubString:%s, enabled:%s", subString, tostring(enabled))
         if not enabled or subString == nil or subString == "" then
	 --mwse.log("Loading Error or Game Prompt Message nil or empty.. skipping")
         elseif string.find(element.text, subString) ~= nil then
	 --mwse.log("Loading Error or Game Prompt Message identified: " .. subString)

	    local cocInProgress = false
	    --mwse.log("loadInProgress:" .. tostring(loadInProgress))	    
	    if not loadInProgress then
	       -- check for coc or other load in progress type error state
	       for subString,enabled in pairs(config.loadErrorTextSubStrings) do
	       --mwse.log("cocInprogress check %s,%s", subString, tostring(enabled))	       
                  subString = subString:gsub("%%[sid]",".*")
         	  if not enabled or subString == nil or subString == "" then
         	  elseif string.find(element.text, subString) ~= nil then
		     cocInProgress = true
		     --mwse.log("cocInProgress = true")		     
		     break
		  end
	       end
	    end
	    
            if loadState == nil
	    or loadInProgress
	    or cocInProgress then
	    -- sizing shenanigans related to cursor centering not reliable on first load.. it just works?
	       e.element.autoWidth = false
	       e.element.autoHeight = false
	       e.element.width = e.element.parent.width / 2
	       e.element.height = e.element.parent.height
	       e.element:getContentElement().autoWidth = false
	       e.element:getContentElement().width = e.element.parent.width / 2
	       e.element:getContentElement().autoHeight = false
	       e.element:getContentElement().height = e.element.parent.height
	       e.element:updateLayout()
	    end

	    local function pushButtonWithText(button_block, matchString)
	       local buttons = button_block.children
	       for j = 1, #buttons do
	          --mwse.log("buttons[%d].text = %s.. check matchString = %s", j, tostring(buttons[j].text), matchString)
       	       	  if buttons[j].text ~= nil and string.find(buttons[j].text, matchString) ~= nil then
		     --mwse.log(matchString .. " found... trigerEvent mouseClick")
		     if config.displayMessages == true then
		     	-- replace message without buttons:
		    	local messageNoButtons = element.text:gsub("\n[^\n]*?", "") -- strip "Do you wish to continue?"
	       	     	messageNoButtons = messageNoButtons:gsub("[\n%s]*$", "")
			if config.acceptMessageTrailer ~= nil and config.acceptMessageTrailer ~= "" then
			   messageNoButtons = messageNoButtons .. "\n" .. config.acceptMessageTrailer:gsub("%^buttonText", buttons[j].text)
			end
		     	tes3.messageBox(messageNoButtons)
			if loadState == nil then clearMessagesFlag = true end
		     end
	      	     buttons[j]:triggerEvent("mouseClick")
		     --mwse.log("tes3.messageBox(%s)", messageNoButtons)
		     return true
		  end
	       end
	       return false
	    end
	    -- just clicking the button hangs but somehow mouseOver trigger seems to work, provided the cursor is centered..
            if tes3ui.findMenu(tes3ui.registerID("MenuMessage")) == nil then return end
	    if loadInProgress or cocInProgress then
	       --mwse.log("register mouseOver...")
               e.element:getContentElement():register("mouseOver", function()
	          if tes3ui.findMenu(tes3ui.registerID("MenuMessage")) == nil then return end
	          local done = pushButtonWithText(button_layout, tes3.findGMST("sYes").value .. ".*" .. tes3.findGMST("sAllTab").value)
	       	  if not done then pushButtonWithText(button_layout, tes3.findGMST("sYes").value) end
	       end)
	    else
	       --mwse.log("timer.frame.delayOneFrame...")
	       timer.frame.delayOneFrame(function()
	          if tes3ui.findMenu(tes3ui.registerID("MenuMessage")) == nil then return end
	          local done = pushButtonWithText(button_layout, tes3.findGMST("sYes").value .. ".*" .. tes3.findGMST("sAllTab").value)
	          if not done then pushButtonWithText(button_layout, tes3.findGMST("sYes").value) end
	       end)
	    end
	    break
	 end
      end
   end
   
   local function clearMessages(e)
      if e.isAltDown then return end -- don't fire under alt-tab
      tes3.messageBox(".")
      tes3.messageBox(".")
      tes3.messageBox(".")
      event.unregister("keyDown", clearMessages)
      event.unregister("mouseAxis", clearMessages)
   end
   
   local function onLoaded()
      loadState = false
      loadInProgress = false
      --mwse.log("onLoaded loadState:%s, clearMessagesFlag:%s", tostring(loadState), tostring(clearMessagesFlag))
      if clearMessagesFlag == true then
      --[[ the idea here was to destroy() the lingering messageBoxes, but they aren't found?      
      	 local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
      	 local menuList = menu.parent.children
      	 for i = 1, #menuList do
      	     --mwse.log("onLoaded menuList[%d].name = %s", i, tostring(menuList[i].name))
	     --destroy messages with text including config.acceptMessageTrailer
      	 end
      ]]--
         event.register("keyDown", clearMessages)
         event.register("mouseAxis", clearMessages)
      end
   end

   local function onLoad(e)
      loadInProgress = true
      if clearMessagesFlag == true then
         event.unregister("keyDown", clearMessages)
         event.unregister("mouseAxis", clearMessages)
      	 clearMessagesFlag = false
      end
      
      if loadState ~= nil then
	 if loadState == false then -- re-center cursor for mouse-over detection, not needed on first load
            -- center the cursor so mouseOver triggers thanks to G7/discord 13Oct2019 entry      
      	    local cursorPosition = tes3.getCursorPosition()
      	    local mouseState = tes3.worldController.inputController.mouseState
      	    mouseState.x = -cursorPosition.x
      	    mouseState.y = cursorPosition.y
	    -- requires one frame to work so..
      	    if not e.newGame then
	       timer.frame.delayOneFrame(function() tes3.loadGame(e.filename) end)
	    else
	       timer.frame.delayOneFrame(function() tes3.newGame() end)
	    end
	    loadState = true 
	    return false
         else
            loadState = false
         end
      end
   end

   local function refreshCombinedList()
         for key,value in pairs(config.loadErrorTextSubStrings) do
	    combinedList[key] = value
	    --mwse.log("combinedList[%s] = %s", key, value)	    
	 end
         for key,value in pairs(config.gamePromptTextSubStrings) do
	    combinedList[key] = value
	    --mwse.log("combinedList[%s] = %s", key, value)	    
	 end
   end
   
   local function onUIActivatedMenuOptions(e)
   --mwse.log("auto yes to all options menu activated")
   -- update every time options menu is closed (first load or possible MCM update)
      local element = e.element:getContentElement()
      element = element:createBlock{ id = tes3ui.registerID("sve auto yes to all options menu destroy detection invisible element")}
      element.visible = false
      element:register("destroy", function ()
      --mwse.log("auto yes to all options menu activated destroyed")
         refreshCombinedList()
      end)
   end

   local function onInitialized()
      config = require("sve.auto yes to all.config")
      refreshCombinedList()	 
      event.register("uiActivated", onUIActivatedMenuMessage, { filter = "MenuMessage" } )
      event.register("uiActivated", onUIActivatedMenuOptions, { filter = "MenuOptions" } )
      event.register("loaded", onLoaded)
      event.register("load", onLoad, { priority = -1000 }) -- only after other potential load blocking mods
      mwse.log("[Auto Yes to All] Initialized")
   end
event.register("initialized", onInitialized)

local function registerModConfig()
	local easyMCM = include("easyMCM.modConfig")
	if (easyMCM) then
		easyMCM.registerMCM(require("sve.auto yes to all.mcm"))
	end
end
event.register("modConfigReady", registerModConfig)


