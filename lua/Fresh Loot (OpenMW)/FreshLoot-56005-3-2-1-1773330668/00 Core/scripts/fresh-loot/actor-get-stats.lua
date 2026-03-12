local core = require("openmw.core")
local self = require("openmw.self")
local ai = require('openmw.interfaces').AI

local mDef = require("scripts.fresh-loot.config.definition")
local mT = require("scripts.fresh-loot.config.types")
local mObj = require("scripts.fresh-loot.util.objects")

local function getActorStats()
    local package = ai.getActivePackage()
    return mT.new.actorStats(self, package and package.type or "Wander", package and package.distance or 0)
end

return {
    eventHandlers = {
        [mDef.events.getActorStats] = function(responseEvent)
            mObj.answerRequestEvent(responseEvent, getActorStats())
            core.sendGlobalEvent(mDef.events.detachScript, { object = self, scriptPath = mDef.scripts.actorGetStats })
        end,
    }
}
