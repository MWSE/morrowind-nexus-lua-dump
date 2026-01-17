local core = require('openmw.core')
local self = require('openmw.self')
local storage = require 'openmw.storage'
local ui = require('openmw.ui')

--- [[
--- FIX LIST:
--- 1. Double-firing, use animation cancelling
--- 2. Validation functions for Camera, Shoot, and Input settings
--- 3. Break lock-on when LOS is broken
--- 4. Better default values for blaster settings
--- 5. Implement menus on the doors
--- 6. Make mousing to the edges of the screen turn the camera
--- 7. Make the portraits!
--- 8. Make cursor icons, and remake the crosshair icons at 128x128
--- ]]

require 'Scripts.SW4.input.actionRegistrations'

local I = require('openmw.interfaces')

local CamHelper = require 'Scripts.SW4.helper.cameraHelper'
local ModInfo = require('scripts.sw4.modinfo')

local CoreGroup = storage.globalSection('SettingsGlobal' .. ModInfo.name .. 'CoreGroup')

--- System handlers added by SW4
---@class ManagementStore
local Managers = {
  MountFunctions = require('scripts.sw4.player.mountfunctions'),
}

---@type CameraManager
Managers.Camera = require 'Scripts.SW4.player.cameraManager' (Managers)
---@type LockOnManager
Managers.LockOn = require 'Scripts.SW4.player.lockOnManager' (Managers)
---@type ShootManager
Managers.Shoot = require 'scripts.sw4.player.shootHandler' (Managers)
---@type InputManager
Managers.Input = require 'Scripts.SW4.player.inputController' (Managers)
---@type CursorController
Managers.Cursor = require 'Scripts.SW4.player.cursorController' (Managers)
---@type CrosshairManager
Managers.Crosshair = require 'Scripts.SW4.player.crosshairManager' (Managers)
---@type QuickCastManager
Managers.Quick = require 'Scripts.SW4.player.quickCastManager' (Managers)
---@type QuickAttackManager
Managers.AttackQuick = require 'Scripts.SW4.player.quickAttackManager' (Managers)

local ShowMessage = ui.showMessage

I.AnimationController.addTextKeyHandler("", function(group, key)
  -- print(group, key)
end)

I.AnimationController.addTextKeyHandler("spellcast", function(group, key)
  for _, spellcastHandler in ipairs { Managers.MountFunctions.handleMountCast, } do
    if spellcastHandler(group, key) then break end
  end
end)

local OnFrameExecutionOrder = {
  Managers.Cursor,
  Managers.Camera,
  Managers.Input,
  Managers.Shoot,
  Managers.LockOn,
  Managers.Crosshair,
  Managers.AttackQuick,
  Managers.Quick,
}

---@enum FrameHandlerType
local FrameHandlerType = {
  Early = 'onFrameEarly',
  Begin = 'onFrameBegin',
  Middle = 'onFrame',
  End = 'onFrameEnd',
  Late = 'onFrameLate',
}

---@param frameHandlerType FrameHandlerType
local function onFrameSubsystems(frameHandlerType, dt)
  for _, subsystem in ipairs(OnFrameExecutionOrder) do
    if subsystem[frameHandlerType] then
      subsystem[frameHandlerType](subsystem, dt, Managers)
    end
  end
end

return {
  interfaceName = ModInfo.name .. "_PlayerController",
  interface = {
    CamHelper = CamHelper,
    Subsystems = Managers
  },
  engineHandlers = {
    onFrame = function(dt)
      onFrameSubsystems(FrameHandlerType.Early, dt)
      onFrameSubsystems(FrameHandlerType.Begin, dt)
      onFrameSubsystems(FrameHandlerType.Middle, dt)
      onFrameSubsystems(FrameHandlerType.End, dt)
      onFrameSubsystems(FrameHandlerType.Late, dt)
    end,
    onUpdate = function(dt)
      Managers.MountFunctions.onUpdate(dt)
    end,
    onTeleported = function()
      if not self.cell then return end

      core.sendGlobalEvent('SW4_PlayerCellChanged', { player = self.object, prevCell = self.cell.name })
    end,
    onSave = function()
      return {
        mountState = {
          prevGauntlet = Managers.MountFunctions.SavedState.prevGauntlet,
          prevSpellOrEnchantedItem = Managers.MountFunctions.SavedState.prevSpellOrEnchantedItem,
          currentMountSpell = Managers.MountFunctions.SavedState.currentMountSpell,
          equipState = Managers.MountFunctions.SavedState.equipState,
        },
        mountActionQueue = Managers.MountFunctions.ActionQueue,
      }
    end,
    onLoad = function(data)
      Managers.MountFunctions.ActionQueue = data.mountActionQueue or {}

      if data.mountState then
        Managers.MountFunctions.SavedState.prevGauntlet = data.mountState.prevGauntlet
        Managers.MountFunctions.SavedState.prevSpellOrEnchantedItem = data.mountState.prevSpellOrEnchantedItem
        Managers.MountFunctions.SavedState.currentMountSpell = data.mountState.currentMountSpell
        Managers.MountFunctions.SavedState.equipState = data.mountState.equipState
      end
    end,
    onMouseButtonPress = function(button)
      if button == 3
          and I.UI.getMode()
          and CoreGroup:get('RightClickExit')
      then
        I.UI.setMode()
      end
    end,
  },
  eventHandlers = {
    --- Plays ambient sound records or arbitrary sound files from other contexts using provided options
    SW4_AmbientEvent = require('scripts.sw4.player.ambientevent'),
    SW4_UIMessage = ShowMessage,
    --- Logs a message to the console using the success color
    ---@param message string The message to log
    SW4_LogMessage = function(message)
      ui.printToConsole(message, ui.CONSOLE_COLOR.Success)
    end,
  }
}
