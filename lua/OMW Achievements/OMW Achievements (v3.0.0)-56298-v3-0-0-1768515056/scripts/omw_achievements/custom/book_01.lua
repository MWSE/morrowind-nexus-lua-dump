local self = require('openmw.self')
local interfaces = require('openmw.interfaces')
local achievements = require('scripts.omw_achievements.achievements.achievements')
local sk00maUtils = require('scripts.omw_achievements.utils.sk00maUtils')

local function bookRead(data)
    local macData = interfaces.storageUtils.getStorage("counters")
    local bookReadTable = macData:getCopy('bookRead')

    --- Check for unique achievement "Lost In A Book"
    if #bookReadTable == 101 then
        local bookAchievement = sk00maUtils.getAchievementById(achievements, "book_01")
        self.object:sendEvent('gettingAchievement', {
            name = bookAchievement.name,
            description = bookAchievement.description,
            icon = bookAchievement.icon,
            id = bookAchievement.id,
            bgColor = bookAchievement.bgColor
        })
    end
end

return {
    eventHandlers = {
        bookRead = bookRead
    }
}