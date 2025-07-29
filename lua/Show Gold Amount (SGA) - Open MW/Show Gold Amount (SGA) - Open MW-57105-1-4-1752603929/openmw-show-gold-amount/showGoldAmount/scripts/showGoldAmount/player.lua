local ui = require('openmw.ui')
local self = require('openmw.self')
local core = require('openmw.core')
local types = require('openmw.types')
local storage = require('openmw.storage')
local util = require("openmw.util")
local I = require('openmw.interfaces')
local async = require('openmw.async')
local configPlayer = require('scripts.showGoldAmount.config.player')
local l10n = core.l10n('showGoldAmount')

local element = nil
local goldMenu = nil
local NONE_L10N_ENTRY = "None"
local GOLD_L10N_ENTRY = "Gold"
local edition_mode = false

local mainWindow = nil
local screenSize = ui.screenSize()
local width_ratio = 0.15
local height_ratio = 0.05
local widget_width = screenSize.x * width_ratio
local widget_height = screenSize.y * height_ratio
local menu_block_width = widget_width * 0.30
local windows_opened = {}

local modData = storage.playerSection('showGoldAmountInterface')
modData:set("pos_x", modData:get("pos_x") or screenSize.x /2)
modData:set("pos_y", modData:get("pos_y") or screenSize.y /2)

local function generateAmountText()
   local playerInventory = types.Actor.inventory(self.object)
   local goldAmount = playerInventory:countOf('gold_001')
   local goldName = l10n(configPlayer.hudOptions.s_GoldName)
   local amountText = tostring(goldAmount)   
   
   if goldName == l10n(NONE_L10N_ENTRY) then
      return amountText
   end

   amountText = amountText .. " " .. goldName
   
   if goldName == l10n(GOLD_L10N_ENTRY) then return amountText end

   return goldAmount > 1 and amountText .. "s" or amountText
end

local function renderGoldAmountHUD()

   element = ui.create({
      template = I.MWUI.templates.textNormal,
      layer = "HUD",
      type = ui.TYPE.Text,
      props = {
         text = generateAmountText(),         
         textSize = configPlayer.hudOptions.TextSize,
         relativePosition = util.vector2(configPlayer.hudOptions.OffsetX, configPlayer.hudOptions.OffsetY),         
         visible = true,
      },
   })
end

local function handleMouseMove(MouseEvent)
   if edition_mode then
      mouse_position_x = MouseEvent.position.x
      mouse_position_y = MouseEvent.position.y
      
      modData:set("pos_x", mouse_position_x)
      modData:set("pos_y", mouse_position_y)
   end
end

local function handleMousePress(MouseEvent)
   edition_mode = not edition_mode
   ui.showMessage(edition_mode and "Enter edition mode" or "Leaving edition mode")
end


local function createGoldMenu()

   mainWindow = {
      type = ui.TYPE.Text,
      layer = "Windows",
      template = I.MWUI.templates.textNormal,             
      props = {
         name = "mainWindow",
         position = util.vector2(modData:get("pos_x"), modData:get("pos_y")),
         anchor= util.vector2(.5, .5),
         text = generateAmountText(),
         textSize = configPlayer.interfaceOptions.TextSize,                          
      },
      events = {
         mousePress = async:callback(handleMousePress),
         mouseMove = async:callback(handleMouseMove)
      } 
   }

   goldMenu = ui.create(mainWindow)
end

local function interfaceRequiredIsVisible()
   if configPlayer.interfaceOptions.s_Interface == "All" then
      if I.UI.getMode() == "Interface" then
         return true
      end
   else
      if windows_opened ~= nil then
         for key,value in pairs(windows_opened) do      
            if value == configPlayer.interfaceOptions.s_Interface then
               return true and I.UI.getMode() == "Interface"
            end
         end
      end
   end

   return false
end

local function destroyUiElements()
   if goldMenu ~= nil then         
      goldMenu:destroy()
   end
   
   if element ~= nil then
      element:destroy()
   end
end

local function onFrame(dt)
   
   destroyUiElements()

   if interfaceRequiredIsVisible() and configPlayer.interfaceOptions.b_FlagInterface then
      createGoldMenu()   
   end
   
   if configPlayer.hudOptions.b_FlagHUD and I.UI.isHudVisible() then
      renderGoldAmountHUD()
   end

end

local function addUiMode(options)
   windows_opened = options.windows
end

local function setUiMode(options)
   windows_opened = options.windows
end

local function uiModeChanged(data)
   if data.newMode == nil then
      windows_opened = {}
   end
end

return {
   engineHandlers = {
      onFrame = onFrame,      
   },
   eventHandlers = {      
      AddUiMode = addUiMode,
      SetUiMode = setUiMode,
      UiModeChanged = uiModeChanged
   },
}
