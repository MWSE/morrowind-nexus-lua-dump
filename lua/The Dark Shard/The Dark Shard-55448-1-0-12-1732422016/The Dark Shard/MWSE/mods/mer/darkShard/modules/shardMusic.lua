--Makes sure the boss music is always playing on the shard

local common = require("mer.darkShard.common")
local logger = common.createLogger("shardMusic")
local ShardCell = require("mer.darkShard.components.ShardCell")

local MUSIC_PATH = "Whispers of the Abyss.mp3"


local function play()
    logger:debug("Playing Shard music")
    tes3.streamMusic{ path = MUSIC_PATH }
end

local function stop()
    logger:debug("Stopping music")
    tes3.skipToNextMusicTrack({ force = true })
end

---@param e cellChangedEventData
event.register("cellChanged", function(e)
    if e.previousCell and e.previousCell.id:lower() == ShardCell.cellId then
        stop()
    end
    if e.cell.id:lower() == ShardCell.cellId then
        play()
    end
end)

---@param e loadedEventData
event.register("loaded", function(e)
    if ShardCell.isOnShard() then
        play()
    end
end)

---@param e musicSelectTrackEventData
event.register(tes3.event.musicSelectTrack, function(e)
    if ShardCell.isOnShard() then
        logger:debug("On Shard, forcing shard music")
        e.music = MUSIC_PATH
        e.claim = true
    end
end, {priority = 50})