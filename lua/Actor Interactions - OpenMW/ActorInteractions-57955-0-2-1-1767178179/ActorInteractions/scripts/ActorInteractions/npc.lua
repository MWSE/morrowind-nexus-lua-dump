local self = require('openmw.self')
local types = require('openmw.types')
local events = require('scripts.ActorInteractions.events')
local AI = require('openmw.interfaces').AI

return {

        eventHandlers = {
                [events.trainNPCSkill] = function(data)
                        local skillStat = types.NPC.stats.skills[data.skill](self)
                        skillStat.base = skillStat.base + 1
                end,
                [events.checkIfFollower] = function(data)
                        local isFollower
                        AI.forEachPackage(function(package)
                                -- print(package.type, package.target)
                                if package.type == 'Follow' and package.target == data.actor then
                                        isFollower = true
                                end
                        end)

                        data.actor:sendEvent(events.isFollower, { actor = self, isFollower = isFollower })
                end
        }
}
