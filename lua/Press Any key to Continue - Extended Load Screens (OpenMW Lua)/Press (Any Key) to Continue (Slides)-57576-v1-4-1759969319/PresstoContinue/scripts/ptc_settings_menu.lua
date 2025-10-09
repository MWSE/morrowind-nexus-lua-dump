-- Press-to-Continue — Settings Registrar (MENU) for OpenMW 0.49
-- Registers an in-game settings page that persists to PLAYER permanent storage (universal across saves).

local I = require('openmw.interfaces')

local L10N      = 'PressToContinue'
local PAGE_KEY  = 'PressToContinue'
local GROUP_KEY = 'SettingsGlobalPressToContinue' -- key for storage.playerSection(GROUP_KEY)

local DEFAULT_SWITCH_SECONDS = 5
local DEFAULT_ASPECT_KEY     = '16:9'
local DEFAULT_SCALE_MODE     = 'contain'

local ASPECT_ITEMS = { '16:9', '4:3', '1:1', '21:9' }
local SCALE_ITEMS  = { 'contain', 'cover' }

local function register()
  I.Settings.registerPage {
    key = PAGE_KEY, l10n = L10N, name = 'pageName', description = 'pageDesc',
  }

  -- Because this runs under [menu], permanentStorage=true persists to PLAYER storage (permanent, not per-save).
  I.Settings.registerGroup {
    key = GROUP_KEY, page = PAGE_KEY, l10n = L10N,
    name = 'groupName', description = 'groupDesc',
    permanentStorage = true,
    settings = {
      {
        key='SwitchSeconds', renderer='number',
        name='switchSeconds', description='switchSeconds.desc',
        default=DEFAULT_SWITCH_SECONDS, argument={ min=0.1, max=600 },
      },
      {
        key='SlideAspect', renderer='select',
        name='slideAspect', description='slideAspect.desc',
        default=DEFAULT_ASPECT_KEY, argument={ l10n=L10N, items=ASPECT_ITEMS },
      },
      {
        key='ScaleMode', renderer='select',
        name='scaleMode', description='scaleMode.desc',
        default=DEFAULT_SCALE_MODE, argument={ l10n=L10N, items=SCALE_ITEMS },
      },
    },
  }
end

return {
  engineHandlers = {
    onInit = function()
      register()
      print('[PTC][MENU] Settings page/group registered → PLAYER permanent storage')
    end,
  },
}
