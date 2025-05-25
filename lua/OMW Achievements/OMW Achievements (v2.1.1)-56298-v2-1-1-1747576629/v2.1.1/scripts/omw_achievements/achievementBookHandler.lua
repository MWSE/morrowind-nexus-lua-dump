local types = require('openmw.types')
local self = require('openmw.self')
local interfaces = require('openmw.interfaces')

local achievements = require('scripts.omw_achievements.achievements.achievements')
local sk00maUtils = require('scripts.omw_achievements.utils.sk00maUtils')

local function bookRead(data)

    local macData = interfaces.storageUtils.getStorage("counters")

    local bookReadTable = macData:getCopy('bookRead')

    if sk00maUtils.not_contains(bookReadTable, data.id) then
        table.insert(bookReadTable, data.id)
        macData:set('bookRead', bookReadTable)
    end

    --- Check for "read_all" achievements type
    for i = 1, #achievements do
        if achievements[i].type == "read_all" then
            if sk00maUtils.search(bookReadTable, achievements[i].books) then
                self.object:sendEvent('gettingAchievement', {
                    name = achievements[i].name,
                    description = achievements[i].description,
                    icon = achievements[i].icon,
                    id = achievements[i].id,
                    bgColor = achievements[i].bgColor
                })
            end
        end
    end

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

local function UiModeChanged(data)

    if data.newMode == "Book" then
        local book_id = data.arg.recordId
        self.object:sendEvent("bookRead", {
            id = book_id
        })
    end

end

return {
    eventHandlers = {
        UiModeChanged = UiModeChanged,
        bookRead = bookRead
    }
}
