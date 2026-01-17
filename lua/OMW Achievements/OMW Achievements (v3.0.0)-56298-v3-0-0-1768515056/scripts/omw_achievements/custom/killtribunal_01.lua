local self = require('openmw.self')
local types = require('openmw.types')

local achievements = require('scripts.omw_achievements.achievements.achievements')

local function onActivated(actor)
    for i = 1, #achievements do
        --- Check #2 for unique achievement "Tribunal's Judgment"
        if achievements[i].type == "unique" then
            if achievements[i].id == "killtribunal_01" and self.object.recordId == "vivec_god" then
                if types.Actor.isDead(self.object) == true then
                    actor:sendEvent('vivecIsDead', achievements[i])
                end
            end
        end
    end
end

return {
    engineHandlers = {
        onActivated = onActivated
    }
}