if require('openmw.core').API_REVISION < 22 then
    error('This mod requires a newer version of OpenMW, please update.')
end

local self = require('openmw.self')
local async = require('openmw.async')
local nearby = require('openmw.nearby')
local time = require('openmw_aux.time')
local ai = require('openmw.interfaces').AI
local types = require('openmw.types')
local aux_util = require('openmw_aux.util')

local function searchForTarget()
    if not types.Actor.canMove(self) then return end
    local newTarget, targetDist = aux_util.findMinScore(nearby.actors, function(actor)
        return types.NPC.objectIsInstance(actor) and (actor.position - self.position):length()
    end)
    local currentTarget = ai.getActiveTarget('Combat')
    if newTarget and currentTarget ~= newTarget and targetDist < 800 then
        print(string.format('%s attacks %s, dist = %f', self.recordId, newTarget, targetDist))
        ai.removePackages('Combat')
        ai.startPackage({type = 'Combat', target = newTarget})
    else
        if currentTarget and (currentTarget.position - self.position):length() > 1500 then
            print('Stop combat, dist > 1500')
            ai.removePackages('Combat')
        end
    end
end

print('Man hunting started: ' .. tostring(self.object))
time.runRepeatedly(searchForTarget, 4 * time.second)

return {}

