local self = require('openmw.self')
local core = require('openmw.core')
local UI = require('openmw.interfaces').UI
local types = require('openmw.types')
local configPlayer = require('scripts.clickToPrepareWeapon.config.player')
local l10n = core.l10n('clickToPrepareWeapon')

local selfObject = self

local function handleWeaponIsPossible()
   local currentMode = UI.getMode()   
   return currentMode == nil
end

local function onMouseButtonPress(button)
   
   if not handleWeaponIsPossible() then return end

   if types.Actor.getStance(selfObject) == types.Player.STANCE.Nothing then
      local clickNameForPreparingWeapon = l10n(configPlayer.options.s_ClickPrepare)            
      local clickIdEquivalentPrepare
      if clickNameForPreparingWeapon == "Left" then
         clickIdEquivalentPrepare = 1
      elseif clickNameForPreparingWeapon == "Middle" then
         clickIdEquivalentPrepare = 2
      elseif clickNameForPreparingWeapon == "Right" then
         clickIdEquivalentPrepare = 3
      else
         return
      end      
      if button == clickIdEquivalentPrepare then
         types.Actor.setStance(self, types.Player.STANCE.Weapon)
      end
   end
   
   if types.Actor.getStance(selfObject) == types.Player.STANCE.Weapon then
      local clickNameForSheathingWeapon = l10n(configPlayer.options.s_ClickSheath)
      local clickIdEquivalentSheath
      if clickNameForSheathingWeapon == "Left" then
         clickIdEquivalentSheath = 1
      elseif clickNameForSheathingWeapon == "Middle" then
         clickIdEquivalentSheath = 2
      elseif clickNameForSheathingWeapon == "Right" then
         clickIdEquivalentSheath = 3
      else
         return
      end
   
      if button == clickIdEquivalentSheath then
         types.Actor.setStance(self, types.Player.STANCE.Nothing)
      end   
   end

end

return {
   engineHandlers = {
      onMouseButtonPress = onMouseButtonPress
   }
}
