local core = require('openmw.core')
local self = require('openmw.self')
local UI = require('openmw.interfaces').UI
local configPlayer = require('scripts.clickToCloseMenu.config.player')
local l10n = core.l10n('clickToCloseMenu')

local function onMouseButtonPress(button)   
   local clickNameForClosingWindow = l10n(configPlayer.options.s_Click)
   local clickIdEquivalent
   
   if clickNameForClosingWindow == "Left" then
      clickIdEquivalent = 1
   elseif clickNameForClosingWindow == "Middle" then
      clickIdEquivalent = 2
   elseif clickNameForClosingWindow == "Right" then
      clickIdEquivalent = 3
   else
      return
   end

   local currentMode = UI.getMode()
   if button == clickIdEquivalent and currentMode ~= nil and currentMode ~= "Dialogue" then
      self:sendEvent('SetUiMode', {})
   end      
end

return {
   engineHandlers = {
      onMouseButtonPress = onMouseButtonPress
   }
}