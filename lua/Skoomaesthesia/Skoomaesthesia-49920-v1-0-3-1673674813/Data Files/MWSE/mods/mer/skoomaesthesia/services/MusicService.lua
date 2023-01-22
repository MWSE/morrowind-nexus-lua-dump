local MusicService = {}
local common = require('mer.skoomaesthesia.common')
local logger = common.createLogger('MusicService')
local config = require('mer.skoomaesthesia.config')
local TripStateService = require('mer.skoomaesthesia.services.TripStateService')

function MusicService.playCreepySounds()
    if TripStateService.isState('beginning') or TripStateService.isState('active') then
        logger:debug('Playing creepy sounds')
        tes3.streamMusic{ path = config.static.musicPath, crossfade = 1 }
    end
end

function MusicService.stopCreepySounds()
    logger:debug('Stopping creepy sounds')
    tes3.streamMusic{ path = config.static.silencePath, crossfade = 5 }
end


return MusicService