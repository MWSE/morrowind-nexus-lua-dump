-- PLAYER script: settings UI, tutorial message, balance on load / option changes.

local core = require('openmw.core')
local ui = require('openmw.ui')
local storage = require('openmw.storage')
local async = require('openmw.async')
local self = require('openmw.self')

local l10n = core.l10n('AncestorGhost')
local config = require('scripts.ancestor_ghost.config')
local settings = require('scripts.ancestor_ghost.settings')
local balance = require('scripts.ancestor_ghost.balance')
local undeadFriendly = require('scripts.ancestor_ghost.undead_friendly_player')

pcall(settings.registerPage)
pcall(settings.registerGroup)

local playerStore = storage.playerSection('AncestorGhost')
local STORE_TUTORIAL = 'ag_tutorial_shown'
local tutorialShown = false
local settingsSubscribed = false
local balanceSynced = false

local function applyBalance(notify)
  if not balance.applyToPlayer(self) then return false end
  balanceSynced = true
  if notify then
    ui.showMessage(l10n('optionsApplied'))
  end
  return true
end

local function ensureSettingsSubscription()
  if settingsSubscribed then return end
  settingsSubscribed = true
  local modSettings = storage.playerSection(config.settingsGroupKey)
  modSettings:subscribe(async:callback(function(_section, _key)
    applyBalance(true)
    undeadFriendly.syncToGlobal()
  end))
end

local function trySyncBalance(notify)
  ensureSettingsSubscription()
  applyBalance(notify)
end

return {
  engineHandlers = {
    -- New saves call onInit (not onLoad). onActive fires when the player is in the world.
    onInit = function()
      trySyncBalance(false)
      undeadFriendly.syncToGlobal()
    end,

    onLoad = function()
      tutorialShown = playerStore:get(STORE_TUTORIAL) or false
      trySyncBalance(false)
      undeadFriendly.syncToGlobal()
    end,

    onActive = function()
      balanceSynced = false
      trySyncBalance(false)
      undeadFriendly.syncToGlobal()
    end,

    onFrame = function()
      if not balanceSynced then
        trySyncBalance(false)
      end
    end,
  },

  eventHandlers = {
    AG_EquipBlocked = function(_data)
      if tutorialShown then return end
      tutorialShown = true
      playerStore:set(STORE_TUTORIAL, true)
      ui.showMessage(l10n('equipBlocked'))
    end,
  },
}
