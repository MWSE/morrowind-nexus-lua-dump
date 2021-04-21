-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--[[
  __  __  _____ __  __    ____        _      _      _  __              
 |  \/  |/ ____|  \/  |  / __ \      (_)    | |    | |/ /              
 | \  / | |    | \  / | | |  | |_   _ _  ___| | __ | ' / ___ _   _ ___ 
 | |\/| | |    | |\/| | | |  | | | | | |/ __| |/ / |  < / _ \ | | / __|
 | |  | | |____| |  | | | |__| | |_| | | (__|   <  | . \  __/ |_| \__ \
 |_|  |_|\_____|_|  |_|  \___\_\\__,_|_|\___|_|\_\ |_|\_\___|\__, |___/
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

	if not config.MCMquickKeysEnabled then return end

	local mainMenu = e.element

	local newInfoLinkReady = false
	local modLinkInfoList = {}
	local modLinkInfoListIndex = 0

	local function refreshModLinkInfoList()
		local menu = tes3ui.findMenu(tes3ui.registerID("MWSE:ModConfigMenu"))
		if menu == nil then return end
		menu = menu:findChild(tes3ui.registerID("PartDragMenu_main"))
		if menu == nil then return end
		local pane = menu:findChild(tes3ui.registerID("PartScrollPane_pane"))
		if pane == nil or pane.parent.parent.parent.parent ~= menu then return end
		for i = 1, #pane.children do
		    if pane.children[i].text ~= nil then
		    table.insert(modLinkInfoList, { text = pane.children[i].text,
		    			      	    link = pane.children[i],
					      })
		    end
		end
		local element = menu:createBlock{ id = tes3ui.registerID("sve mcm destroy detection invisible element")}
		element.visible = false
		element:register("destroy", function()
			for i,_ in ipairs(modLinkInfoList) do modLinkInfoList[i] = nil end
			modLinkInfoList = {}
		end)
	end

	local MCMregistered = false
	local retryCount = 0
	local function registerMCM()
	   timer.start({duration=0.01, type=timer.real, callback = function()
		if MCMregistered then return end
		local menu = tes3ui.findMenu(tes3ui.registerID("MWSE:ModConfigMenu"))
		if menu == nil then
			if retryCount < 3 then
				retryCount = retryCount + 1
				registerMCM()
				return
			end
			retryCount = 0
			return
		end
		retryCount = 0
		local title = menu:findChild(tes3ui.registerID("PartDragMenu_title"))
		if title ~= nil and title.text ~= nil then
			MCMregistered = true
			title:register("destroy", function()
				local modName = title.text:gsub(".-%- ", "")
				if modName ~= title.text then
					config.lastMCMpageVisited = modName
					mwse.saveConfig("mcm quick keys", config)
				end
				MCMregistered = false
			end)
			if next(modLinkInfoList) == nil then refreshModLinkInfoList() end
			if config.lastMCMpageVisited == nil then return end
			for count,info in ipairs(modLinkInfoList) do
				if string.find(info.text,config.lastMCMpageVisited) ~= nil then
					modLinkInfoListIndex = count
					modLinkInfoList[modLinkInfoListIndex].link.color =  tes3ui.getPalette("link_color")
					menu:updateLayout()
					if config.autoOpenLastPage then
						info.link:triggerEvent("mouseClick")
					else
						newInfoLinkReady = true
					end
				end
			end
		end
		
	   end})
	end
	
	local function onKeyDownMCM(e)
		local menu = tes3ui.findMenu(tes3ui.registerID("MWSE:ModConfigMenu"))
		if menu == nil then return end

		local function isKeyComboDown(keyInfo, k)
	      		return ( k.keyCode == keyInfo.keyCode
				and k.isShiftDown == keyInfo.isShiftDown
				and k.isAltDown == keyInfo.isAltDown
				and k.isControlDown == keyInfo.isControlDown )
		end

		local k = nil
		if e.delta == nil then
			k = { keyCode = e.keyCode,
				isShiftDown = e.isShiftDown,
				isAltDown = e.isAltDown,
				isControlDown = e.isControlDown }
		elseif config.enableMouseScrollWheelAsArrowKeys then
			local inputController = tes3.worldController.inputController
			k = { keyCode = ( e.delta > 0 ) and config.selectPrevModKeyInfo.keyCode or config.selectNextModKeyInfo.keyCode,
				isShiftDown = e.isShiftDown or inputController:isKeyDown(tes3.scanCode.lShift) or inputController:isKeyDown(tes3.scanCode.rShift),
				isAltDown = e.isAltDown,
				isControlDown = e.isControlDown }
		else return end

		if isKeyComboDown(config.openSelectedModMCMkeyInfo,k) then
			if modLinkInfoListIndex > 0 and newInfoLinkReady then
				modLinkInfoList[modLinkInfoListIndex].link:triggerEvent("mouseClick")
			end
			return
		end
		if  ( ( ( k.isShiftDown or not config.selectModRequiresShiftKey )
		    and ( k.isAltDown or not config.selectModRequiresAltKey )
		    and ( k.isControlDown or not config.selectModRequiresCtrlKey ) )
		    or isKeyComboDown(config.selectNextModKeyInfo,k)
		    or isKeyComboDown(config.selectPrevModKeyInfo,k) ) then
			local matchIndex = 0
			if next(modLinkInfoList) == nil then refreshModLinkInfoList() end
			if isKeyComboDown(config.selectNextModKeyInfo,k) then
				matchIndex = modLinkInfoListIndex + 1
				if matchIndex > #modLinkInfoList then
					matchIndex = 1
				end
			elseif isKeyComboDown(config.selectPrevModKeyInfo,k) then
				matchIndex = modLinkInfoListIndex - 1
				if matchIndex < 1 then
					matchIndex = #modLinkInfoList
				end
			else
				local matchPattern = ""
				for str,code in pairs(tes3.scanCode) do
					if k.keyCode == code then
						if string.len(str) == 1 then
							matchPattern = "^" .. string.lower(str)
							break
						end
					end
				end
				if matchPattern == "" then return end
				local matchInfo = nil
				for count,info in ipairs(modLinkInfoList) do
					if string.find(string.lower(info.text),matchPattern) ~= nil then
						if matchInfo == nil
						or count == modLinkInfoListIndex + 1 then
							matchInfo = info
							matchIndex = count
						end
					end
				end
				if matchIndex == 0 or matchInfo == nil then return end
				--mwse.log("MCM match %s in %s", matchPattern, matchInfo.text)
			end
			if modLinkInfoListIndex ~= 0 then
				modLinkInfoList[modLinkInfoListIndex].link.color = tes3ui.getPalette("normal_color")
			end
			modLinkInfoListIndex = matchIndex
			modLinkInfoList[modLinkInfoListIndex].link.color =  tes3ui.getPalette("link_color")
			menu:updateLayout()
			if config.autoOpenAsSelected then
				modLinkInfoList[modLinkInfoListIndex].link:triggerEvent("mouseClick")
			else
				newInfoLinkReady = true
			end
			return
		end
		newInfoLinkReady = false
		if modLinkInfoListIndex ~= 0 then
			modLinkInfoList[modLinkInfoListIndex].link.color = tes3ui.getPalette("normal_color")
		end
	end
	
	event.register("keyDown", onKeyDownMCM)
	event.register("mouseWheel", onKeyDownMCM)

	-- can't seem to find UI event for MCM window created so..
	event.register("mouseButtonUp", registerMCM)
	event.register("keyUp", registerMCM)
	
	local element = mainMenu:getContentElement()
	element = element:createBlock{ id = tes3ui.registerID("sve MCM quick keys destroy detection invisible element")}
	element.visible = false
	element:register("destroy", function()
		event.unregister("keyDown", onKeyDownMCM)
		event.unregister("mouseButtonUp", registerMCM)
		event.unregister("keyUp", registerMCM)
	end)
end

local function onInitialized()
	config = require("sve.mcm quick keys.config")
	event.register("uiActivated", onUIActivatedMenuOptions, { filter = "MenuOptions" } )
	mwse.log("[Main Menu Key Binds Initialized")
end
event.register("initialized", onInitialized)


local function registerModConfig()
	local easyMCM = include("easyMCM.modConfig")
	if (easyMCM) then
		easyMCM.registerMCM(require("sve.mcm quick keys.mcm"))
	end
end
event.register("modConfigReady", registerModConfig)

