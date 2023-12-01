local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local Events = require('scripts.AttendMe.events')

I.Settings.registerGroup({
   key = 'SettingsAttendMeMechanics',
   page = 'AttendMe',
   l10n = 'AttendMe_GameplaySettings',
   name = "group_name",
   permanentStorage = false,
   settings = {
      {
         key = 'teleportFollowers',
         name = "teleportFollowers_name",
         default = true,
         renderer = 'checkbox',
      },
      {
         key = 'checkFollowersEvery',
         name = 'checkFollowersEvery_name',
         description = 'checkFollowersEvery_description',
         default = 0.2,
         renderer = 'number',
         argument = {
            min = 0,
            max = 1,
         },
      },
   },
})

local mechanicSettings = storage.globalSection('SettingsAttendMeMechanics')

return {
   eventHandlers = {
      AttendMeTeleport = function(e)
         if mechanicSettings:get('teleportFollowers') then
            e.actor:teleport(e.cellName, e.position)
         end
      end,
   },
}
