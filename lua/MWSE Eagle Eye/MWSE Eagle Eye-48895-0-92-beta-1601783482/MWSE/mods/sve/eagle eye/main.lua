--[[---------------------------------------------------------------------------
-------------------------------------------------------------------------------
  ______            _        ______           
 |  ____|          | |      |  ____|          
 | |__   __ _  __ _| | ___  | |__  _   _  ___ 
 |  __| / _` |/ _` | |/ _ \ |  __|| | | |/ _ \
 | |___| (_| | (_| | |  __/ | |___| |_| |  __/
 |______\__,_|\__, |_|\___| |______\__, |\___|
               __/ |                __/ |     
              |___/                |___/      

    by Svengineer99

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
  
  Hrnchamd for tes3.mobilePlayer.mouseLookDisabled tip
  NullCascade and team for MWSE lua scripting development and docs
  NullCascade, Greatness7, Merlord, Petethegoat, Mort, ... for
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
                                                                 
  Not well optimized, organized, commented; sometimes hacky scripting below.
  No reflection of MWSE devs and other scripters superior example and practice.
  Not recommended as a reference unless no other can be found.

]]------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local config
local configQL

local cursorPositionX = nil
local cursorPositionY = nil

local mouseLookDisabled = 0
local tooltipObject = nil
local tooltipLastObject = nil
local tooltipLockSkips = 0
local tooltipReference = nil
local tooltipRegistered = false
local lockOnBindKeyDown = false

local function distanceToPlayer(targetRef)
   local distance = nil
   local hitResult = tes3.rayTest({position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = {tes3.player} })
   local hitReference = hitResult and hitResult.reference
   if hitReference ~= nil and hitReference == targetRef then
      distance = hitResult.distance
   end
   --mwse.log("rayTest distance = %s", tostring(distance))
   if distance == nil then
      distance = mwscript.getDistance({reference = tes3.player, targetRef = targetRef})
      --mwse.log("mwscript distance = %s", tostring(distance))
   end
   return distance
end

local function onEnterFrameHoldCursorPosition()
   local cursorPosition = tes3.getCursorPosition()
   if cursorPositionX == nil then
      cursorPositionX = cursorPosition.x
      cursorPositionY = cursorPosition.y
--mwse.log("onEnterFrameHoldCursorPosition Initiated(%s) x,y:%s,%s", tostring(tooltipObject and tooltipObject.id), tostring(cursorPositionX), tostring(cursorPositionY))      
   end
   local mouseState = tes3.worldController.inputController.mouseState
   mouseState.x = -cursorPosition.x + cursorPositionX
   mouseState.y = cursorPosition.y - cursorPositionY
end

local function isItem(object)
   local baseObject = object.baseObject or object
   local objectType = baseObject.objectType
   return objectType == tes3.objectType.alchemy
       or objectType == tes3.objectType.ammunition
       or objectType == tes3.objectType.apparatus
       or objectType == tes3.objectType.armor
       or objectType == tes3.objectType.book
       or objectType == tes3.objectType.clothing
       or objectType == tes3.objectType.ingredient
       or objectType == tes3.objectType.light
       or objectType == tes3.objectType.lockpick
       or objectType == tes3.objectType.miscItem
       or objectType == tes3.objectType.probe
       or objectType == tes3.objectType.repairItem
       or objectType == tes3.objectType.weapon
end

local function isObject(object)
   local baseObject = object.baseObject or object
   local objectType = baseObject.objectType
   return objectType == tes3.objectType.activator
       or objectType == tes3.objectType.container
       or objectType == tes3.objectType.door
end

local function isActor(object)
   local baseObject = object.baseObject or object
   local objectType = baseObject.objectType
   return objectType == tes3.objectType.npc
       or objectType == tes3.objectType.creature
end       

local function onTooltip(e)
--mwse.log("onTooltip e.object.id:%s, e.reference.object.objectType:%s", tostring(e.object.id), e.reference and e.object.id)

   if e.tooltip == nil then
      e.tooltip = tes3ui.findHelpLayerMenu(tes3ui.registerID("HelpMenu"))
      if e.tooltip == nil then return end
   end
   
   if config.tigerEyeEnabled
   and ( ( not tes3ui.menuMode() ) or config.tigerEyeInventoryItemsEnabled )
   and ( not tooltipRegistered or lockOnBindKeyDown)
   and ( config.tigerEyeEnabledWalking or not tes3.mobilePlayer.isWalking )
   and ( config.tigerEyeEnabledRunning or not tes3.mobilePlayer.isRunning )
   and ( config.tigerEyeEnabledJumping or not tes3.mobilePlayer.isJumping )
   and ( config.tigerEyeEnabledSwimming or not tes3.mobilePlayer.isSwimming ) then
--mwse.log("echo1")
      lockOnBindKeyDown = false
      local inputController = tes3.worldController.inputController
      if inputController:isKeyDown(config.tigerEyeKeyInfo.keyCode) then
--mwse.log("echo2")   
      -- lock the cursor if hotkey pressed on small object
         local ratio = 1
      	 local distance = -1
      	 local boxMinLength = 0
      	 if e.reference then
      	    distance = distanceToPlayer(e.reference)
      	    if distance == nil or distance == 0 then distance = -1 end
      	    boxMinLength = (e.object.boundingBox.min * e.reference.scale):length()
      	    ratio = boxMinLength / distance
      	 end
--mwse.log("%s distance/box.min/ratio = %.1f/%.1f/%.3f", e.object.id, distance, boxMinLength, ratio)
	 --mwse.log("telekinesis:" .. tes3.mobilePlayer.telekinesis)
         if ((config.tigerEyeBoundingBoxMinToDistRatio
      	   and ratio < config.tigerEyeBoundingBoxMinToDistRatio / 100 )
      	 or ( config.tigerEyeBoundingBoxMinLength
	    and boxMinLength < config.tigerEyeBoundingBoxMinLength )
	 or ( config.tigerEyeDistanceItem and isItem(e.object)
	   and distance > config.tigerEyeDistanceItem )
	 or ( config.tigerEyeDistanceActor and isActor(e.object)
	   and distance > config.tigerEyeDistanceActor )
	 or ( config.tigerEyeDistanceObject and isObject(e.object)
	   and distance > config.tigerEyeDistanceObject )) then
--mwse.log("skip if %s==%s and %s>0", tostring(e.object and e.object.id), tostring(tooltipLastObject and tooltipLastObject.id), tooltipLockSkips)
            if e.object == tooltipLastObject and tooltipLockSkips > 0 then
      	      -- skip locking config.skipRepetitiveLocks (1 by default) times in a row
            else
	       tooltipLockSkips = config.skipRepetitiveLocks + 1
      	       if tes3ui.menuMode() and cursorPositionX == nil
	       and e.referenece == nil then -- only lock on inventory items
--mwse.log("event.register enterFrame :" .. tostring(config.tigerEyeInventoryItemsEnabled))	    
	          event.register("enterFrame", onEnterFrameHoldCursorPosition)
	       elseif not tes3ui.menuMode()
	       and mouseLookDisabled == 0 then
	          if tes3.mobilePlayer.mouseLookDisabled == true then
      	       	     mouseLookDisabled = 2
      	          else
      	             tes3.mobilePlayer.mouseLookDisabled = true
	       	     mouseLookDisabled = 1
      	       	  end
      	       end
      	    end
      	 end
      end
   end

   tooltipReference = e.reference
   tooltipLastObject = tooltipObject
   tooltipObject = e.object   		   
   if tooltipRegistered == false then
      tooltipRegistered = true
      e.tooltip:getContentElement().children[1]:register("destroy", function()
         if cursorPositionX ~= nil then
	    event.unregister("enterFrame", onEnterFrameHoldCursorPosition)
	    cursorPositionX = nil
	 elseif mouseLookDisabled ~= 0 then
            if mouseLookDisabled == 1 then       
      	       tes3.mobilePlayer.mouseLookDisabled = false
      	    end
      	    mouseLookDisabled = 0
	 end
      	 tooltipRegistered = false
      end)
   end

   -- eagle eye restore tooltip if quickloot hid it
   if config.eagleEyeEnabled
   and tes3.findGMST("iMaxActivateDist").value == config.eagleEyeDistance
   and configQL.modDisabled == false then
      timer.delayOneFrame(function()
	 local quickLootMenu = tes3ui.findMenu(tes3ui.registerID("QuickLoot:Menu"))
	 if quickLootMenu == nil or quickLootMenu.visible == false or quickLootMenu:getContentElement().visible == false then
            local helpMenu = tes3ui.findHelpLayerMenu(tes3ui.registerID("HelpMenu"))
            if helpMenu ~= nil then
      	       helpMenu.maxWidth = helpMenu.parent.width
      	       helpMenu.maxHeight = helpMenu.parent.height
               helpMenu.autoWidth = true
               helpMenu.autoHeight = true
	       helpMenu:updateLayout()
            end
         end
      end)
   end
end

local function onActivateAndTargetChanged(e)
   if not config.eagleEyeEnabled then return end
   local target = e.target
   local activator = e.activator
   if e.target == nil then -- onActivationTargetChanged
      target = e.current
      activator = tes3.player
   end
   if activator == tes3.player
   and tes3.findGMST("iMaxActivateDist").value == config.eagleEyeDistance then
       local distance = distanceToPlayer(target)
       if e.target then tooltipLockSkips = 0 end -- activation event
       if distance == nil or distance < 0 then
       	  return false -- block related functions
       elseif distance > ( tes3.mobilePlayer.telekinesis + config.normalActivationDistance ) then
       	  if config.exceedsActivationDistanceMessage ~= "" and e.target ~= nil then
	     tes3.messageBox(config.exceedsActivationDistanceMessage)       
       	  end
       	  return false -- block related functions
       end
   end
end

local function onKeyUp(e)
   if config.eagleEyeEnabled and not config.eagleEyeAlwaysEnabled
   and e.keyCode == config.eagleEyeKeyInfo.keyCode then
      tes3.findGMST("iMaxActivateDist").value = config.normalActivationDistance
   end
   if config.tigerEyeEnabled and e.keyCode == config.tigerEyeKeyInfo.keyCode then
      if cursorPositionX then
	 event.unregister("enterFrame", onEnterFrameHoldCursorPosition)
      	 cursorPositionX = nil
      elseif mouseLookDisabled ~= 0 then
         if mouseLookDisabled == 1 then       
      	    tes3.mobilePlayer.mouseLookDisabled = false
      	 end
      	 mouseLookDisabled = 0
      end
   end
end

local function onKeyDown(e)

   tooltipLockSkips = tooltipLockSkips - 1
   
   if config.eagleEyeEnabled
   and not config.eagleEyeAlwaysEnabled
   -- and not tes3ui.menuMode()
   and e.keyCode == config.eagleEyeKeyInfo.keyCode then
      tes3.findGMST("iMaxActivateDist").value = config.eagleEyeDistance
   end

   if config.tigerEyeEnabled
   and mouseLookDisabled > 0
   and e.keyCode ~= config.tigerEyeKeyInfo.keyCode then
      if mouseLookDisabled == 1 then
      	 tes3.mobilePlayer.mouseLookDisabled = false
      end
      mouseLookDisabled = 0
   end

   if config.tigerEyeEnabled
   and tooltipRegistered
   and config.lockOnBindKeyDown
   and e.keyCode == config.tigerEyeKeyInfo.keyCode
   and ( ( mouseLookDisabled == 0 and not tes3ui.menuMode() )
      or ( not cursorPositionX and tes3ui.menuMode() ) )
   and tes3ui.findHelpLayerMenu(tes3ui.registerID("HelpMenu")) then
--mwse.log("config.lockOnBindKeyDown = " .. tostring(config.lockOnBindKeyDown))
--      timer.delayOneFrame(function()
         lockOnBindKeyDown = true
         onTooltip( {
	 	    tooltip = tes3ui.findHelpLayerMenu(tes3ui.registerID("HelpMenu")),
		    object = tooltipObject,
		    reference = tooltipReference, } )
--      end)
   end

end

local function onUiActivated(e)
   -- update every time options menu is closed (first load or possible MCM update)
--mwse.log("eagle eye options menu activated")
--   e.element:getContentElement():register("destroy", function ()
-- seems like when an element is destroyed it only triggers the last registed "destroy" event..
-- so create a unique element to detect when the options menu is destroyed
   local element = e.element:getContentElement()
   element = element:createBlock{ id = tes3ui.registerID("sve eagle eye options menu destroy detection invisible element")}
   element.visible = false
   element:register("destroy", function ()
   --mwse.log("eagle eye options menu destroyed")
      tes3.findGMST("iMaxActivateDist").value = config.eagleEyeAlwaysEnabled and
         config.eagleEyeDistance or config.normalActivationDistance
      configQL = mwse.loadConfig("Quick Loot")
      if configQL == nil then
      	 if lfs.attributes("Data Files\\MWSE\\mods\\Quickloot\\main.lua") ~= nil then
     	    configQL = { -- installed but no saved config file
     	      	     modDisabled = false,
	    	     }
         else -- not installed
    	    configQL = {
    	       	     modDisabled = true,
	       	     }
         end
      end
   end)
end

local function onInitialized()
   config = require("sve.eagle eye.config")
   
   event.register("uiObjectTooltip", onTooltip, { priority = -1000 } )  -- after Quickloot
   event.register("keyUp", onKeyUp)
   event.register("menuEnter", onKeyUp)
   event.register("menuExit", onKeyUp)
   event.register("keyDown", onKeyDown)
   event.register("activate", onActivateAndTargetChanged, { priority = 10000 } ) -- before QuickLoot, etc.
   event.register("activationTargetChanged", onActivateAndTargetChanged, { priority = 10000 } ) -- before QuickLoot, etc.
   event.register("uiActivated", onUiActivated, { filter = "MenuOptions" } )
   event.register("onLoaded", function() tes3.mobilePlayer.mouseLookDisabled = false end)

end
event.register("initialized", onInitialized)

local function registerModConfig()
    local easyMCM = include("easyMCM.modConfig")

    local mcmData = require("sve.eagle eye.mcm")
    local modData = easyMCM and easyMCM.registerModData(mcmData)
    mwse.registerModConfig(mcmData.name, modData)
end
event.register("modConfigReady", registerModConfig)

