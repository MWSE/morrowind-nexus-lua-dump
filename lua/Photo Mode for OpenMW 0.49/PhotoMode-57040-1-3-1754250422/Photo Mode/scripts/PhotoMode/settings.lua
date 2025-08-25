local storage = require('openmw.storage')
local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')
local ModInfo = require('scripts.PhotoMode.ModInfo')

I.Settings.registerPage {
   key = ModInfo.name,
   l10n = ModInfo.l10nName,
   name = "Photo Mode",
   description =
   "by TrackpadTimmy v" .. ModInfo.version .. "\n\n"
   .. "IMPORTANT: You MUST set all keybinds below manually for the mod to work. "
   .. "Follow the recommended keys or choose your own.\n\n"
   .. "Press [F11] to disable the HUD for taking screenshots. Press [F2] to change the DoF shader settings.\n\n"
   .. "Hold [Shift] or Right Trigger for faster freecam controls, "
   .. "and [Alt] or Left Trigger for more precise controls. "
   .. "This effects movement, zooming, and tilting.\n\n"
}

-- enable the mod
I.Settings.registerGroup {
   key = 'Settings/' .. ModInfo.name .. '/Enable',
   page = ModInfo.name,
   l10n = ModInfo.l10nName,
   name = 'Mod Settings',
   description = 'Type \'reloadlua\' into console to apply changes.',
   permanentStorage = true,
   order = 0,
   settings = {
      {
         key = 'enableMod',
         renderer = 'checkbox',
         name = 'Enable Photo Mode',
         description = 'Enables the mod.',
         default = false
      }
   }
}

-- keybind settings
I.Settings.registerGroup {
   key = 'Settings/' .. ModInfo.name .. '/Keybinds',
   page = ModInfo.name,
   l10n = ModInfo.l10nName,
   name = 'Keybinds',
   permanentStorage = true,
   order = 1,
   settings = {
      {
         key = "photoModeBinding2",
         default = 'U',
         renderer = 'inputBinding',
         argument = {
            key = 'photoModeAction',
            type = "action"
         },
         name = 'Photo Mode Toggle',
         description = 'Toggle Photo Mode on/off.\nRecommended: U\nController: Back',
      },
      {
         key = "freezeTimeBinding3",
         default = 'I',
         renderer = 'inputBinding',
         argument = {
            key = 'freezeTimeAction',
            type = "action"
         },
         name = 'Freeze Time Toggle',
         description = 'Freeze/unfreeze time in Photo Mode.\nRecommended: I\nController: D-pad Right',
      },
      {
         key = "dofBinding",
         default = 'L',
         renderer = 'inputBinding',
         argument = {
            key = 'dofAction',
            type = "action"
         },
         name = 'Depth of Field Toggle',
         description = 'Toggle the Depth of Field shader effect.\nRecommended: V\nController: Y',
      },
      {
         key = "resetCameraBinding",
         default = 'Slash',
         renderer = 'inputBinding',
         argument = {
            key = 'resetCameraAction',
            type = "action"
         },
         name = 'Reset Camera Tilt and Zoom',
         description = 'Reset camera tilt and zoom back to defaults.\nRecommended: /\nController: D-pad Left',
      },
      {
         key = "moveUpBinding",
         default = 'Space',
         renderer = 'inputBinding',
         argument = {
            key = 'moveUpAction',
            type = "action"
         },
         name = 'Move Camera Up',
         description = 'Recommended: Space\nController: A',
      },
      {
         key = "moveDownBinding",
         default = 'LeftCtrl',
         renderer = 'inputBinding',
         argument = {
            key = 'moveDownAction',
            type = "action"
         },
         name = 'Move Camera Down',
         description = 'Recommended: Ctrl\nController: B',
      },
      {
         key = "tiltLeftBinding",
         default = 'LeftArrow',
         renderer = 'inputBinding',
         argument = {
            key = 'rollLeftAction',
            type = "action"
         },
         name = 'Tilt Camera Left',
         description = 'Recommended: Left Arrow\nController: LB',
      },
      {
         key = "tiltRightBinding",
         default = 'RightArrow',
         renderer = 'inputBinding',
         argument = {
            key = 'rollRightAction',
            type = "action"
         },
         name = 'Tilt Camera Right',
         description = 'Recommended: Right Arrow\nController: RB',
      },
      {
         key = "zoomInBinding",
         default = 'UpArrow',
         renderer = 'inputBinding',
         argument = {
            key = 'zoomInAction',
            type = "action"
         },
         name = 'Zoom Camera In',
         description = 'Recommended: Up Arrow\nController: D-pad Up',
      },
      {
         key = "zoomOutBinding",
         default = 'DownArrow',
         renderer = 'inputBinding',
         argument = {
            key = 'zoomOutAction',
            type = "action"
         },
         name = 'Zoom Camera Out',
         description = 'Recommended: Down Arrow\nController: D-pad Down',
      },
   },
}

-- general number settings
I.Settings.registerGroup {
   key = 'Settings/' .. ModInfo.name .. '/General',
   page = ModInfo.name,
   l10n = ModInfo.l10nName,
   name = 'General',
   description = 'Type \'reloadlua\' into console to apply changes.',
   permanentStorage = true,
   order = 2,
   settings = {
      {
         key = 'movementSpeed',
         default = 150, -- Default value directly here
         renderer = 'number',
         name = 'Camera Movement Speed',
         description = 'Speed of the camera. 1-1000\nDefault: 150',
         argument = { integer = true, min = 1, max = 1000 }
      },
      {
         key = 'tiltSpeed',
         default = 10,
         renderer = 'number',
         name = 'Camera Tilt Speed',
         description = 'Speed of the camera tilting. 1-100\nDefault: 50',
         argument = { integer = true, min = 1, max = 100 }
      },
      {
         key = 'zoomStep',
         default = 5,
         renderer = 'number',
         name = 'Camera Zoom Speed',
         description = 'Speed of the camera zooming. 1-100\nDefault: 30',
         argument = { integer = true, min = 1, max = 100 }
      },
      {
         key = 'freezeTimeDefault',
         renderer = 'checkbox',
         name = 'Freeze Time Automatically',
         description = 'Freeze time when entering photo mode.\nDefault: Yes',
         default = true
      },
      {
         key = 'dofPhotoModeOnly',
         renderer = 'checkbox',
         name = 'DoF Photo Mode Restriction',
         description = 'Restrict the DoF toggle key to only be active in photo mode.\nDisable if you want to toggle it during normal gameplay.\nDefault: Yes',
         default = true
      },
      {
         key = 'deadzoneRight',
         default = 0.1,
         renderer = 'number',
         name = 'Gamepad Deadzone Right Stick',
         description = 'Increase this slowly if you have problems with stick drift. 0.01-0.5\nDefault: 0.1',
         argument = { min = 0.01, max = 0.5 }
      },
      {
         key = 'deadzoneLeft',
         default = 0.1,
         renderer = 'number',
         name = 'Gamepad Deadzone Left Stick',
         description = 'Increase this slowly if you have problems with stick drift. 0.01-0.5\nDefault: 0.1',
         argument = { min = 0.01, max = 0.5 }
      },
   }
}

