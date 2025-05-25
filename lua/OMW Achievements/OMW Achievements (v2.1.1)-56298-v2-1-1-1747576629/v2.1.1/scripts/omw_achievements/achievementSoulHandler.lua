local types = require('openmw.types')
local self = require('openmw.self')
local ui = require('openmw.ui')

local sk00maUtils = require('scripts.omw_achievements.utils.sk00maUtils')
local achievements = require('scripts.omw_achievements.achievements.achievements')

local function checkInventory()

    --- Check for unique achievement "Big Soul Hunter"
    local playerInventory = types.Actor.inventory(self.object)
    for _, item in ipairs(playerInventory:findAll('misc_soulgem_azura')) do 
        if types.Item.itemData(item).soul == "vivec_god" or types.Item.itemData(item).soul == "almalexia" or types.Item.itemData(item).soul == "almalexia_warrior" then
            azuraAchievement = sk00maUtils.getAchievementById(achievements, "azurastar_01")
            self.object:sendEvent('gettingAchievement', azuraAchievement)
        end
    end
    
end

return {
    engineHandlers = {
        onFrame = checkInventory
    }
}