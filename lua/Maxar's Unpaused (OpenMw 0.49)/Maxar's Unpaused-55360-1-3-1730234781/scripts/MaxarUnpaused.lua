local Interface = require("openmw.interfaces")
local Storage = require('openmw.storage')
local Async = require('openmw.async')

local function contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

Interface.Settings.registerPage({
  key = 'MaxarUnpaused',
  l10n = 'MaxarUnpaused',
  name = "Maxar's Unpaused",
  description = 'You can configure which situations you want to unpause the game in by going to the "What to unpause" section.\n\nYes means the game will be unpaused in that situation, No means the game will be paused in that situation.',
})

Interface.Settings.registerGroup({
  key = 'Settings_MaxarUnpaused',
  page = 'MaxarUnpaused',
  l10n = 'MaxarUnpaused',
  name = 'What to unpause',
  permanentStorage = true,
  settings = {
    {
      key = 'isSlowTimeMode',
      default = false,
      renderer = 'checkbox',
      name = 'Slow Time Mode',
      description = 'When enabled, the game will be slowed down when in interface.'
    },
    {
      key = 'slowTimeScale',
      default = 0.5,
      renderer = 'number',
      name = 'Slow Time Scale',
      description = 'The time scale when in interface.',
      args = { min = 0.1, max = 1, integer = false}
    },
    {
      key = 'isInInterface',
      default = true,
      renderer = 'checkbox',
      name = 'Inventory',
      description = ''
    },
    {
      key = 'isInContainer',
      default = true,
      renderer = 'checkbox',
      name = 'Container',
      description = ''
    },
    {
      key = 'isBartering',
      default = true,
      renderer = 'checkbox',
      name = 'Barter',
      description = ''
    },
    {
      key = 'isMerchantRepairing',
      default = true,
      renderer = 'checkbox',
      name = 'Merchant Repair',
      description = ''
    },
    {
      key = 'isReadingBook',
      default = true,
      renderer = 'checkbox',
      name = 'Book Reading',
      description = ''
    },
    {
      key = 'isReadingScroll',
      default = true,
      renderer = 'checkbox',
      name = 'Scroll Reading',
      description = ''
    },
    {
      key = 'isReadingJournal',
      default = true,
      renderer = 'checkbox',
      name = 'Journal',
      description = ''
    },
    {
      key = 'isAlchemyActive',
      default = true,
      renderer = 'checkbox',
      name = 'Alchemy',
      description = ''
    },
    {
      key = 'isEnchanting',
      default = true,
      renderer = 'checkbox',
      name = 'Enchanting',
      description = ''
    },
    {
      key = 'isRecharging',
      default = true,
      renderer = 'checkbox',
      name = 'Recharge',
      description = ''
    },
    {
      key = 'isCreatingSpell',
      default = true,
      renderer = 'checkbox',
      name = 'Spell Creation',
      description = ''
    },
    {
      key = 'isWithCompanion',
      default = true,
      renderer = 'checkbox',
      name = 'Companion?',
      description = ''
    }
  }
})
local settingsGroup = Storage.playerSection('Settings_MaxarUnpaused')

local settingsToMenuNames = {
  isInContainer = "Container",
  isBartering = "Barter",
  isMerchantRepairing = "MerchantRepair",
  isWithCompanion = "Companion",
  isInInterface = "Interface",
  isReadingBook = "Book",
  isReadingScroll = "Scroll",
  isReadingJournal = "Journal",
  isAlchemyActive = "Alchemy",
  isEnchanting = "Enchanting",
  isRecharging = "Recharge",
  isCreatingSpell = "SpellCreation",
}
local function getSettingKeyFromMenuName(menuName)
  if menuName == nil then
    return false
  end

  for settingKey, name in pairs(settingsToMenuNames) do
    if name == menuName then
      local result = settingsGroup:get(settingKey)
      if result == nil or not result then
        return false
      else
        return true
      end
    end
  end
end

local isSlowTimeMode = false
local slowTimeScale = 0.5
local current_scale = 1.0
local function updateSettingsFromStorage()
  isSlowTimeMode = settingsGroup:get('isSlowTimeMode')
  slowTimeScale = settingsGroup:get('slowTimeScale')

  for settingKey, menuName in pairs(settingsToMenuNames) do
      local isPaused = not settingsGroup:get(settingKey)
      Interface.UI.setPauseOnMode(menuName, isPaused)
  end
end

settingsGroup:subscribe(Async:callback(updateSettingsFromStorage))

local Core = require('openmw.core')
local function sendEventTimescale(scale)
  if current_scale == scale then
    return
  end
  
  Core.sendGlobalEvent("ChangeTimeScale", {timeScale = scale})
  current_scale = scale
end

local function update()
  if not isSlowTimeMode then
    return
  end

  local current_mode = Interface.UI.getMode()
  local isSettingOn = getSettingKeyFromMenuName(current_mode)

  if current_mode and isSettingOn and contains(settingsToMenuNames, current_mode) then
    sendEventTimescale(slowTimeScale)
  else
    sendEventTimescale(1)
  end
  
end
local function initialize()
  updateSettingsFromStorage()
  sendEventTimescale(1)
end

return {
  engineHandlers = {
    onActive = initialize,
    onFrame = update
  }
}