local core = require('openmw.core')
local async = require('openmw.async')
local input = require('openmw.input')
local types = require('openmw.types')
local self = require('openmw.self')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local configPlayer = require('scripts.smartInterfaceMenuOpening.config.player')
local ui = require('openmw.ui')
local settings = storage.playerSection('SettingsOMWControls')

local letters_key_code = {20,5,6,7,8,9,10,11,12,13,14,15,51,17,18,19,4,21,22,23,24,25,29,27,28,26}
local menu_opened = false
local menus_opened = {}
local interface_menus_requiring_pause = {}
local other_modes_menus_requiring_pause = {}

local autoMove = false
local attemptToJump = false
local alwaysRun = settings:get('alwaysRun')
local toggleSneak = settings:get('toggleSneak')

local function menuAlreadyOpened(menusOpened, menusToOpen)
   for opened_key,opened_value in pairs(menusOpened) do
      for to_open_key,to_open_value in pairs(menusToOpen) do
         if opened_value == to_open_value then
            return true
         end
      end
   end
   return false
end

local function isDisplayMenuAuthorized()
   if I.UI.getMode() ~= nil and I.UI.getMode() ~= I.UI.MODE.Interface  then
      return false
   end
   return true
end

local function sendMenuEvent(menus_to_open)
   if not menu_opened or not menuAlreadyOpened(menus_opened, menus_to_open) then
      self:sendEvent('AddUiMode', {mode = I.UI.MODE.Interface, windows = menus_to_open})
   else
      self:sendEvent('SetUiMode', {})
   end
end

local function detectInterfaceMenusPauseSettings()
   interface_menus_requiring_pause = {}
   interface_menus_requiring_pause[I.UI.WINDOW.Inventory] = configPlayer.options_pauses.b_Pause_Inventory
   interface_menus_requiring_pause[I.UI.WINDOW.Map] = configPlayer.options_pauses.b_Pause_Map
   interface_menus_requiring_pause[I.UI.WINDOW.Magic] = configPlayer.options_pauses.b_Pause_Magic
   interface_menus_requiring_pause[I.UI.WINDOW.Stats] = configPlayer.options_pauses.b_Pause_Stats   
end

local function detectOtherModesMenusPauseSettings()
   other_modes_menus_requiring_pause = {}
   other_modes_menus_requiring_pause[I.UI.WINDOW.Journal] = configPlayer.options_pauses.b_Pause_Journal
   other_modes_menus_requiring_pause[I.UI.WINDOW.Book] = configPlayer.options_pauses.b_Pause_Book
   other_modes_menus_requiring_pause[I.UI.WINDOW.Scroll] = configPlayer.options_pauses.b_Pause_Scroll
   other_modes_menus_requiring_pause[I.UI.WINDOW.Alchemy] = configPlayer.options_pauses.b_Pause_Alchemy
   other_modes_menus_requiring_pause[I.UI.WINDOW.QuickKeys] = configPlayer.options_pauses.b_Pause_QuickKeysMenu
   other_modes_menus_requiring_pause[I.UI.WINDOW.Repair] = configPlayer.options_pauses.b_Pause_Repair
end

local function handlePauseForMenusToOpen(menus_to_open)
   I.UI.setPauseOnMode(I.UI.MODE.Interface, false)
   for key,value in pairs(menus_to_open) do
      if interface_menus_requiring_pause[value] then
         I.UI.setPauseOnMode(I.UI.MODE.Interface, true)
         return      
      end
   end
end

local function handlePauseForModes()
   I.UI.setPauseOnMode(I.UI.MODE.Journal, other_modes_menus_requiring_pause[I.UI.WINDOW.Journal])
   I.UI.setPauseOnMode(I.UI.MODE.Book, other_modes_menus_requiring_pause[I.UI.WINDOW.Book])
   I.UI.setPauseOnMode(I.UI.MODE.Scroll, other_modes_menus_requiring_pause[I.UI.WINDOW.Scroll])
   I.UI.setPauseOnMode(I.UI.MODE.Alchemy, other_modes_menus_requiring_pause[I.UI.WINDOW.Alchemy])
   I.UI.setPauseOnMode(I.UI.MODE.QuickKeysMenu, other_modes_menus_requiring_pause[I.UI.WINDOW.QuickKeys])
   I.UI.setPauseOnMode(I.UI.MODE.Repair, other_modes_menus_requiring_pause[I.UI.WINDOW.Repair])
end

local function closeMenus()
   menu_opened = false
   menus_opened = {}
end

local function getMenusForSwitch()
   menus_for_switch = {}
   switch_menus_order_str = configPlayer.options_switch.s_Switch_Order
   for menu_name in string.gmatch(switch_menus_order_str, "([^-]+)") do
      if menu_name ==  I.UI.WINDOW.Inventory then
         table.insert(menus_for_switch, I.UI.WINDOW.Inventory)
      elseif menu_name ==  I.UI.WINDOW.Map then
         table.insert(menus_for_switch, I.UI.WINDOW.Map)
      elseif menu_name ==  I.UI.WINDOW.Magic then
         table.insert(menus_for_switch, I.UI.WINDOW.Magic)
      elseif menu_name ==  I.UI.WINDOW.Stats then
         table.insert(menus_for_switch, I.UI.WINDOW.Stats)
      else
         ui.showMessage(menu_name .. " is not a Menu")
      end
   end

   return menus_for_switch
end

local function switchBetweenMenusAndGetNewOne()
   menus_for_switch = getMenusForSwitch()

   nb_menus_for_switch = #menus_for_switch
   
   if nb_menus_for_switch == 0 then
      return
   end
   
   if menus_opened[1] == nil then
      index_menu_to_open = 1
   else      
      modulo = nb_menus_for_switch + 1
      index_menu_to_open = ((index_menu_to_open + 1) % modulo)
   end
   
   if index_menu_to_open == 0 then
      loop_enabled = configPlayer.options_switch.b_Switch_Loop
      if loop_enabled then
         index_menu_to_open = 1
      else
         return
      end
   end
   return menus_for_switch[index_menu_to_open]


end

local function checkIsLetterKey(code)
   for key,value in pairs(letters_key_code) do
      if value == code then
         return true
      end
   end
   return false
end

local function openNewMenu(menus_to_open, new_menu)
   table.insert(menus_to_open, new_menu)
   sendMenuEvent(menus_to_open)
   handlePauseForMenusToOpen(menus_to_open)
end

local function checkEntryAndHandleMenuOpening(code_binding)
   
   is_inventory_opened = false
   for key,value in pairs(menus_opened) do
      if value == I.UI.WINDOW.Inventory then
         is_inventory_opened = true
      end
   end   
   letter_key_has_been_pressed = checkIsLetterKey(code_binding)
   
   print(configPlayer.options_atoms.b_Show_Warning)

   if letter_key_has_been_pressed and is_inventory_opened then
      if configPlayer.options_atoms.b_Show_Warning then
         if code_binding == configPlayer.options_switch.s_Key_Switch 
         or code_binding == configPlayer.options_atoms.s_Key_Inventory 
         or code_binding == configPlayer.options_atoms.s_Key_Inventory 
         or code_binding == configPlayer.options_atoms.s_Key_Map 
         or code_binding == configPlayer.options_atoms.s_Key_Magic 
         or code_binding == configPlayer.options_atoms.s_Key_Stats 
         then
            ui.showMessage("Shortcut (letter) not available. Priority to search bar :)")
         end
      end
   else
      if code_binding == configPlayer.options_switch.s_Key_Switch then
         menu_to_open = switchBetweenMenusAndGetNewOne()
         if menu_to_open == nil then
            self:sendEvent('SetUiMode', {})
            return
         end
         openNewMenu(menus_to_open, menu_to_open)                  
      end
      if code_binding == configPlayer.options_atoms.s_Key_Inventory then
         openNewMenu(menus_to_open, I.UI.WINDOW.Inventory)
      end
   
      if code_binding == configPlayer.options_atoms.s_Key_Inventory then
         openNewMenu(menus_to_open, I.UI.WINDOW.Inventory)
      end
   
      if code_binding == configPlayer.options_atoms.s_Key_Map then
         openNewMenu(menus_to_open, I.UI.WINDOW.Map)
      end
   
      if code_binding == configPlayer.options_atoms.s_Key_Magic then
         openNewMenu(menus_to_open, I.UI.WINDOW.Magic)
      end
   
      if code_binding == configPlayer.options_atoms.s_Key_Stats then
         openNewMenu(menus_to_open, I.UI.WINDOW.Stats)
      end
   end

end

local function onKeyRelease(key)         
   detectInterfaceMenusPauseSettings()
   detectOtherModesMenusPauseSettings()
      
   if key.code == input.KEY.Escape then
      closeMenus()
   end

   if not isDisplayMenuAuthorized() then
      return
   end

   handlePauseForModes()

   menus_to_open = {}
   checkEntryAndHandleMenuOpening(key.code)   
end

local function onMouseButtonPress(button)
   detectInterfaceMenusPauseSettings()
   detectOtherModesMenusPauseSettings()
      

   if not isDisplayMenuAuthorized() then
      return
   end

   handlePauseForModes()

   menus_to_open = {}
   checkEntryAndHandleMenuOpening(button)   
end

local function onSave()
   settings:set('alwaysRun', alwaysRun)
   settings:set('toggleSneak', toggleSneak)
end

local function addUiMode(options)
   menu_opened = true
   menus_opened = options.windows
end

local function setUiMode(options)
   closeMenus()
end

local function resetInventoryForContainer(data)
   if menus_opened[I.UI.WINDOW.Inventory] == nil and data.newMode == I.UI.MODE.Container then
      menus_opened = {I.UI.WINDOW.Inventory, I.UI.WINDOW.Container}
      self:sendEvent('SetUiMode', {mode = I.UI.MODE.Container, windows = menus_opened})
   end
end

local function resetMenuForInterface(data)
   if data.oldMode ~= nil and data.oldMode ~= I.UI.MODE.Interface and data.newMode == I.UI.MODE.Interface then
      self:sendEvent('AddUiMode', {mode = I.UI.MODE.Interface, windows = menus_opened})
   end
end

local function uiModeChanged(data)
   resetInventoryForContainer(data)
   resetMenuForInterface(data)
end

-- code adapted from the open mw playercontrols.lua
local function controlsAllowed()   
   mode = I.UI.getMode()   
   isModeAllowed = 
   mode == nil or
   mode == I.UI.MODE.Interface or
   mode == I.UI.MODE.Journal or
   mode == I.UI.MODE.Book or
   mode == I.UI.MODE.Scroll or
   mode == I.UI.MODE.Alchemy or
   mode == I.UI.MODE.QuickKeysMenu or
   mode == I.UI.MODE.Repair

   return not core.isWorldPaused()
      and types.Player.getControlSwitch(self, types.Player.CONTROL_SWITCH.Controls)
      and isModeAllowed
end

-- code adapted from the open mw playercontrols.lua
local function movementAllowed()   
   return controlsAllowed() and not movementControlsOverridden
end

if configPlayer.options_movements.b_Movements_Allowed then
   -- code adapted from the open mw playercontrols.lua
   input.registerTriggerHandler('AutoMove', async:callback(function()
      if not movementAllowed() then return end
      autoMove = not autoMove
   end))
   
   -- code adapted from the open mw playercontrols.lua
   input.registerTriggerHandler('Jump', async:callback(function()
      if not movementAllowed() then return end
      attemptToJump = types.Player.getControlSwitch(self, types.Player.CONTROL_SWITCH.Jumping)
   end))

   -- code adapted from the open mw playercontrols.lua   
   input.registerTriggerHandler('ToggleSneak', async:callback(function()
      if not movementAllowed() then return end
      toggleSneak = not toggleSneak
   end))

   -- code adapted from the open mw playercontrols.lua
   input.registerTriggerHandler('AlwaysRun', async:callback(function()
      if not movementAllowed() then return end
      alwaysRun = not alwaysRun
   end))
end

-- code adapted from the open mw playercontrols.lua
local function handleMovement()
   
   if not movementAllowed() or not configPlayer.options_movements.b_Movements_Allowed then return end

   local movement = input.getRangeActionValue('MoveForward') - input.getRangeActionValue('MoveBackward')
   local sideMovement = input.getRangeActionValue('MoveRight') - input.getRangeActionValue('MoveLeft')
   local run = input.getBooleanActionValue('Run') ~= alwaysRun

   if movement ~= 0 then
      autoMove = false
   elseif autoMove then
      movement = 1
   end

   self.controls.movement = movement
   self.controls.sideMovement = sideMovement
   self.controls.run = run
   self.controls.jump = attemptToJump
   self.controls.sneak = toggleSneak

   attemptToJump = false
end

return {
   engineHandlers = {
      onKeyRelease = onKeyRelease,
      onMouseButtonPress = onMouseButtonPress,
      onFrame = handleMovement,
      onSave = onSave
   },
   eventHandlers = {      
      AddUiMode = addUiMode,
      SetUiMode = setUiMode,
      UiModeChanged = uiModeChanged
   }
}
