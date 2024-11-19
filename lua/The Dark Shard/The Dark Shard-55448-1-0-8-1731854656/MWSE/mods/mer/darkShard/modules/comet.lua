local common = require("mer.darkShard.common")
local logger = common.createLogger("comet")
local Comet = require("mer.darkShard.components.Comet")
local Quest = require("mer.darkShard.components.Quest")
local mainQuest = Quest.quests.afq_main
local Sky = require("mer.darkShard.components.Sky")
local Telescope = require("mer.darkShard.components.Telescope")
local ShardCell = require("mer.darkShard.components.ShardCell")
--[[
The comet is visible while the main quest is active,
while looking through a telescope
]]
local function enableOrDisableComet()
    logger:debug("Enabling or disabling comet")
    local hasSeenComet = mainQuest:isAfter(mainQuest.stages.seesComet)
    local lookingThroughTelescope = Telescope.isActive()
    local onShard = ShardCell.isOnShard()
    local doEnable = Sky.isEnabled()
        and mainQuest:isActive()
        and (lookingThroughTelescope or hasSeenComet)
        and (not onShard)
    if doEnable then
        Comet.enable()
    else
        Comet.disable()
    end

end

event.register("cellChanged", enableOrDisableComet)
event.register("loaded", function()
    timer.start({
        duration = 1,
        iterations = -1,
        callback = enableOrDisableComet
    })
end)
event.register("DarkShard:EnableOrDisableComet", enableOrDisableComet)
