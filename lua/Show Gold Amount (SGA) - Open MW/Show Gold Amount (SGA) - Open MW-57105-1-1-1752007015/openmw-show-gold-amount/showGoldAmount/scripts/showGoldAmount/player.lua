local ui = require('openmw.ui')
local self = require('openmw.self')
local core = require('openmw.core')
local types = require('openmw.types')
local util = require("openmw.util")
local I = require('openmw.interfaces')
local configPlayer = require('scripts.showGoldAmount.config.player')
local l10n = core.l10n('showGoldAmount')


local selfObject = self
local element = nil
local NONE_L10N_ENTRY = "None"
local GOLD_L10N_ENTRY = "Gold"

local function generateAmountText()
   local playerInventory = types.Actor.inventory(self.object)
   local goldAmount = playerInventory:countOf('gold_001')
   local goldName = l10n(configPlayer.options.s_GoldName)
   local amountText = tostring(goldAmount)   
   
   if goldName == l10n(NONE_L10N_ENTRY) then
      return amountText
   end

   amountText = amountText .. " " .. goldName
   
   if goldName == l10n(GOLD_L10N_ENTRY) then return amountText end

   return goldAmount > 1 and amountText .. "s" or amountText
end

local function renderGoldAmountUI()

   element = ui.create({
      template = I.MWUI.templates.textNormal,
      layer = "Windows",
      type = ui.TYPE.Text,
      props = {
         text = generateAmountText(),         
         textSize = configPlayer.options.n_TextSize,
         relativePosition = util.vector2(configPlayer.options.n_InfoWindowOffsetXRelative, configPlayer.options.n_InfoWindowOffsetYRelative),         
         visible = true,
      },
   })
end

local function onFrame(dt)
   if element ~= nil then
      element:destroy()
   end
   local gameInPause = core.isWorldPaused()
   local hudVisible = I.UI.isHudVisible()
   local shouldDisplayOnPause = configPlayer.options.b_ShowGoldAmountOnGamePaused
   
   if not hudVisible then return end
   if gameInPause then
      if shouldDisplayOnPause then
         renderGoldAmountUI()
      end
   else
      renderGoldAmountUI()
   end
end

return {
   engineHandlers = {
      onFrame = onFrame
   }
}
