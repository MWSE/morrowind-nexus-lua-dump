local MusicService = {}
local config = require('mer.skoomaesthesia.config')
local TripStateService = require('mer.skoomaesthesia.services.TripStateService')

function MusicService.playCreepySounds()
    if TripStateService.isState('beginning') or TripStateService.isState('active') then
        tes3.streamMusic{ path = config.static.musicPath, crossfade = 1 }
    end
    
    -- -- if not config.persistent.previousMusicVolume then
    -- --     config.persistent.previousMusicVolume = tes3.worldController.audioController.volumeMusic
    -- -- end
    -- tes3.streamMusic{ path = config.static.silencePath, crossfade = 0.2 }
    
    -- timer.start{
    --     type = timer.real,
    --     iterations = 1,
    --     duration = 0.5,
    --     callback = function()
    --         if TripStateService.isState('beginning') or TripStateService.isState('active') then
    --             --tes3.worldController.audioController.volumeMusic = 80
    --             tes3.streamMusic{ path = config.static.musicPath, crossfade = 1 }
    --         end
    --     end,
    -- }
end

function MusicService.stopCreepySounds()
    tes3.streamMusic{ path = config.static.silencePath, crossfade = 5 }
    -- if config.persistent.previousMusicVolume then
    --     timer.start{
    --         type = timer.real,
    --         duration = 6,
    --         iterations = 1,
    --         callback = function()
    --             if TripStateService.isState('ending') then
    --                 tes3.worldController.audioController.volumeMusic = config.persistent.previousMusicVolume
    --                 config.persistent.previousMusicVolume = nil
    --             end
    --         end
    --     }
    -- end
end


return MusicService