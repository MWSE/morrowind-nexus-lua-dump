local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')
local async = require('openmw.async')
local storage = require('openmw.storage')
local ambient = require('openmw.ambient')
local I = require('openmw.interfaces')

require('scripts.MostWantedNerevarine.settings')

local ui = require('scripts.MostWantedNerevarine.ui')
local settings = storage.playerSection('SettingsMostWantedNerevarine')

local BOUNTY_LEVEL_SOUND = {
   [ui.BountyLevel.none] = 'item gold down',
   [ui.BountyLevel.criminal] = 'bell1',
   [ui.BountyLevel.arrest] = 'bell3',
   [ui.BountyLevel.attack] = 'bell6',
}

local arrestThreshold = core.getGMST("iCrimeThreshold")
local attackThreshold = core.getGMST("iCrimeThresholdMultiplier") * arrestThreshold

local function getBountyLevel(bounty)
   if bounty <= 0 then
      return ui.BountyLevel.none
   elseif bounty < arrestThreshold then
      return ui.BountyLevel.criminal
   elseif bounty < attackThreshold then
      return ui.BountyLevel.arrest
   else
      return ui.BountyLevel.attack
   end
end

local getCrimeLevel = types.Player.getCrimeLevel

local bounty = getCrimeLevel(self.object)
local bountyLevel = getBountyLevel(bounty)

local function updateBountyLevel()
   local newBountyLevel = getBountyLevel(bounty)
   if newBountyLevel == bountyLevel then return end
   bountyLevel = newBountyLevel
   if settings:get('bountyLevelSound') then
      local sound = BOUNTY_LEVEL_SOUND[bountyLevel]
      ambient.playSound(sound, { scale = false })
   end
end

local SETTING_CHANGE_VISIBLE = 15
local lastSettingChangeTime = core.getRealTime() - SETTING_CHANGE_VISIBLE
local function hasSettingUpdated()
   return (core.getRealTime() - lastSettingChangeTime) < SETTING_CHANGE_VISIBLE
end
local lastWasSettingUpdated = false


local function updateHud()
   local menuMode = I.UI.getMode()

   local hudVisible = I.UI.isHudVisible()
   local inInterface = menuMode == 'Interface'
   local showInMenu = menuMode == nil or (inInterface and not (settings:get('hideInMenu')))
   local showNoBounty = bounty > 0 or not (settings:get('hideNoBounty'))
   local showDetails = not (settings:get('hideDetails'))
   local settingUpdated = menuMode == 'MainMenu' and hasSettingUpdated()

   local showAnything = hudVisible and showNoBounty and showInMenu or settingUpdated
   local showWindow = showAnything and showDetails and inInterface or (settingUpdated and showDetails)
   local showHud = showAnything and not showWindow

   ui.updateHud(showHud, bountyLevel)
   ui.updateWindow(showWindow, bounty, bountyLevel)
end

updateHud()

settings:subscribe(async:callback(function()
   lastSettingChangeTime = core.getRealTime()
   lastWasSettingUpdated = true
   updateHud()
end))

local function update()
   local newBounty = getCrimeLevel(self.object)
   if newBounty == bounty then return end
   bounty = newBounty
   updateBountyLevel()
   updateHud()
end

local lastMenuMode = nil

local function frame()
   if lastMenuMode ~= I.UI.getMode() or lastWasSettingUpdated ~= hasSettingUpdated() then
      updateHud()
      lastMenuMode = I.UI.getMode()
      lastWasSettingUpdated = hasSettingUpdated()
   end
end

return {
   engineHandlers = {
      onUpdate = update,
      onFrame = frame,
   },
}
