local core = require('openmw.core')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local input = require('openmw.input')

local l10n = core.l10n('FreeCam')

-- Register settings page
I.Settings.registerPage({
   key = 'FreeCam',
   l10n = 'FreeCam',
   name = 'FreeCam',
   description = 'Free camera for recording showcase and gameplay videos',
})

-- CONTROLS
I.Settings.registerGroup({
   key = "SettingsFreeCamcontrols",
   page = "FreeCam",
   order = 1,
   l10n = "FreeCam",
   name = "Keybindings",
   permanentStorage = true,
   settings = {
      {
         key = "freeHotkey",
         renderer = 'FreeCam/inputKeySelection',
         name = "Toggle Free camera mode",
         description = "Shift + this key = Lock/Unlock camera position.\n\nLocking stores FreeCam's coordinates and locks it in place INDEFINITELY so you can switch between FreeCam and Player view freely without losing the FreeCam's position.\n\nControl your character while locked. Rotate your character with the arrow keys when unlocked.\n\n#ff0000Remember to unlock the camera when you're finished with a locked position!",
         default = input.KEY.F11,
      },
      {
         key = "cameraSensitivityX",
         default = 1.0,
         renderer = "number",
         name = "Horizontal mouse/stick sensitivity",
      },
      {
         key = "cameraSensitivityY",
         default = 1.0,
         renderer = "number",
         name = "Vertical mouse/stick sensitivity",
      },
   },
})

-- FREE CAMERA SETTINGS
I.Settings.registerGroup({
   key = 'SettingsFreeCamfree',
   page = 'FreeCam',
   order = 2,
   l10n = 'FreeCam',
   name = 'Camera Settings',
   permanentStorage = true,
   settings = {
      { key='rotationSmoothness', default=0.7, renderer='number', name='Rotation smoothness', description='Controls how smoothly the camera rotates when you move the mouse.\n#c6b27dRecommended range: 0.0 to 1.0' },
      { key='maxRotation', default=2, renderer='number', name='Rotation limit', description='Maximum rotation speed in full rotations per second. In other words, how far your camera continues rotating after you stop moving the mouse/stick.\n#c6b27dRecommended range: 0.1 to 10+'},
      { key='speedSmoothness', default=0.7, renderer='number', name='Speed smoothness', description='Controls how smoothly the camera accelerates/decelerates when you change speed with CycleWeapon keys bound in the Controls menu.\n#c6b27dRecommended range: 0.0 to 1.0' },
      { key='initialSpeed', default=100, renderer='number', name='Initial speed', description='Starting movement speed (in units) when you activate FreeCam. The camera will always start at this speed. \n#c6b27dRecommended range: 50 to 300+' },
      { key='speedSensitivity', default=50, renderer='number', name='Speed step', description="How much the camera's movement speed changes (in units) when you press or hold the CycleWeapon keys bound in the Controls menu.\n#c6b27dRecommended range: 50 to 200+" },
      { key='directionSmoothness', default=0.7, renderer='number', name='Movement smoothness', description='Controls how smoothly the camera changes direction. In other words, how far your camera continues moving after you stop direction input.\n#c6b27dRecommended range: 0.0 to 0.95' },
   },
})