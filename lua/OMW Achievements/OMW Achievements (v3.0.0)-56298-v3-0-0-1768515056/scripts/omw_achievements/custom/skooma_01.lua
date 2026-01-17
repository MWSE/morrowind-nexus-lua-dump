local self = require('openmw.self')
local interfaces = require('openmw.interfaces')

local sk00maUtils = require('scripts.omw_achievements.utils.sk00maUtils')
local achievements = require('scripts.omw_achievements.achievements.achievements')

local function onConsume(item)
    
    local macData = interfaces.storageUtils.getStorage("counters")
    local skoomaBottlesCounter = macData:get("skoomaBottles")

    --- Check for unique achievement "Vaba Maaszi Lhajiito, So-Sura"
    if skoomaBottlesCounter ~= nil then
        if item.recordId == "potion_skooma_01" then
            macData:set("skoomaBottles", skoomaBottlesCounter + 1)
            if skoomaBottlesCounter >= 99 then
                self.object:sendEvent('gettingAchievement', sk00maUtils.getAchievementById(achievements, "skooma_01"))
            end
        end
    end

end

return {
    engineHandlers = {
        onConsume = onConsume
    }
}