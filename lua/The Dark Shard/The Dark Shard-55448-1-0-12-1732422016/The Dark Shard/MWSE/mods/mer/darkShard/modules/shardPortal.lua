local common = require("mer.darkShard.common")
local Quest = require("mer.darkShard.components.Quest")
local logger = common.createLogger("shardPortal")
local Teleporter = require("mer.darkShard.components.Teleporter")
local Scream = require("mer.darkShard.components.Scream")
local portalId = "afq_portal_down"

---@param e activateEventData
event.register("activate", function(e)
    if e.target.id:lower() == portalId then
        if Quest.quests.afq_main:isFinished() then
            logger:debug("Teleporting to shard")
            Teleporter.teleportToDestination{
                forceAirborn = true,
                callback = function()
                    timer.start{
                        duration = 0.2,
                        callback = function()
                            Scream.play()
                        end
                    }
                end
            }
        else
            logger:debug("Main quest not finished, preventing activate")
            return false
        end
    end
end)