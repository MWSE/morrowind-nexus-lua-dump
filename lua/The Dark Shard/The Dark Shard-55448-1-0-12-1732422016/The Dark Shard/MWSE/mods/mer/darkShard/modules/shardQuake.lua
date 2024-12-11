local common = require("mer.darkShard.common")
local logger = common.createLogger("shardQuake")
local QuakeShader = require("mer.darkShard.shaders.quake")
local Quest = require("mer.darkShard.components.Quest")
local ShardCell = require("mer.darkShard.components.ShardCell")

local sound = "afq_quake"
local range = 20
local speed = 1

local function doQuake()
    local mainQuest = Quest.quests.afq_main
    local questFinished = mainQuest:isFinished()
    local onShard = ShardCell.isOnShard()
    return questFinished and onShard
end

local function startShake()
    logger:debug("Starting shake")
    QuakeShader.enabled = true
    QuakeShader.Range = range
    QuakeShader.Speed = speed
    tes3.playSound{
        reference = tes3.player,
        sound = sound,
        loop = true
    }
end

local function stopShake()
    logger:debug("Stopping shake")
    QuakeShader.enabled = false
    tes3.removeSound{
        reference = tes3.player,
        sound = sound
    }
end

---@param e journalEventData
event.register("journal", function(e)
    local mainQuest = Quest.quests.afq_main
    local isQuest = e.topic.id == mainQuest.id
    if isQuest and doQuake() then
        startShake()
    end
end)

event.register("cellChanged", function(e)
    if not doQuake() then
        stopShake()
    end
end)

event.register("loaded", function()
    if doQuake() then
        startShake()
    end
end)