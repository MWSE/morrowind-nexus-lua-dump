local ambient = require('openmw.ambient')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local playbackSettings = storage.playerSection('SongsOfTheAshenWind_playback')

local isPlaying = nil

return {
   engineHandlers = {
      onFrame = function()
         if isPlaying then
            if not ambient.isMusicPlaying() then
               print('Stopped playing', isPlaying)
               isPlaying = nil
            elseif playbackSettings:get('stopOnClose') and I.UI.getMode() ~= 'Book' then
               ambient.stopMusic()
               isPlaying = nil
            end
         end
      end,
   },
   eventHandlers = {
      urm_SotAW_play = function(path)
         if not playbackSettings:get('playOnRead') then return end
         ambient.streamMusic(path)
         isPlaying = path
      end,
   },
}
