local types = require('openmw.types')
local interfaces = require('openmw.interfaces')
local self = require('openmw.self')

local function vivecIsDead(data)

    --- Check #1 for unique achievement "Tribunal's Judgment"
    local macData = interfaces.storageUtils.getStorage("counters")
    macData:set('vivecIsDead', true)

    if types.Player.quests(self.object)['tr_sothasil'].stage >= 100 then
        self.object:sendEvent('gettingAchievement', {
            name = data.name,
            description = data.description,
            icon = data.icon,
            id = data.id,
            bgColor = data.bgColor
        })
    end

end

return {
    eventHandlers = {
        vivecIsDead = vivecIsDead,
    }
}