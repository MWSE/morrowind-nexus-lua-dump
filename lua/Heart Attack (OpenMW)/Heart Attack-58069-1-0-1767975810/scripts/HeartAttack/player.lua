local storage = require('openmw.storage')
local ambient = require("openmw.ambient")
local time = require('openmw_aux.time')
local self = require("openmw.self")

local settings = storage.playerSection('SettingsHeartAttack_settings')

local function heartbeat()
    local deathChance = settings:get("deathChance")

    if deathChance == 0 then return end

    if math.random(deathChance) == deathChance then
        self.type.stats.dynamic.health(self).current = 0
        self:sendEvent("ShowMessage", { message = "Tough luck." })
        ambient.playSound("sixth_bell")
    end
end

time.runRepeatedly(heartbeat, 1 * time.minute)
