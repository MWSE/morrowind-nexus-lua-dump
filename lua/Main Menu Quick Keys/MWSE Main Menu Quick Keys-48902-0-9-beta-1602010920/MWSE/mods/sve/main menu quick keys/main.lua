-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--[[
  __  __       _         __  __                  
 |  \/  |     (_)       |  \/  |                 
 | \  / | __ _ _ _ __   | \  / | ___ _ __  _   _ 
 | |\/| |/ _` | | '_ \  | |\/| |/ _ \ '_ \| | | |
 | |  | | (_| | | | | | | |  | |  __/ | | | |_| |
 |_|__|_|\__,_|_|_| |_| |_|  |_|\___|_| |_|\__,_|
  / __ \      (_)    | |    | |/ /               
 | |  | |_   _ _  ___| | __ | ' / ___ _   _ ___  
 | |  | | | | | |/ __| |/ / |  < / _ \ | | / __| 
 | |__| | |_| | | (__|   <  | . \  __/ |_| \__ \ 
  \___\_\\__,_|_|\___|_|\_\ |_|\_\___|\__, |___/ 
                                       __/ |     
                                      |___/      
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

local function onUIActivatedMenuOptions(e)
	local mainMenu = e.element
	local function onKeyDown(e)
		if not config.mainMenuQuickKeysEnabled then return end
		if mainMenu.visible == false then return end
		for _, keyBind in pairs(config) do
			if type(keyBind) == "table" and keyBind.keyCode == e.keyCode then
					local button = mainMenu:findChild(tes3ui.registerID(keyBind.container))
					if button == nil then return end
					button:triggerEvent("mouseClick")
				break
			end
		end
	end
	
	event.register("keyDown", onKeyDown)
	
	local element = mainMenu:getContentElement()
	element = element:createBlock{ id = tes3ui.registerID("sve main menu quick keys destroy detection invisible element")}
	element.visible = false
	element:register("destroy", function()
		event.unregister("keyDown", onKeyDown)
	end)
end

local function onInitialized()
	config = require("sve.main menu quick keys.config")
	event.register("uiActivated", onUIActivatedMenuOptions, { filter = "MenuOptions" } )
	mwse.log("[Main Menu Key Binds Initialized")
end
event.register("initialized", onInitialized)

local function registerModConfig()
	local easyMCM = include("easyMCM.modConfig")
	if (easyMCM) then
		easyMCM.registerMCM(require("sve.main menu quick keys.mcm"))
	end
end
event.register("modConfigReady", registerModConfig)

