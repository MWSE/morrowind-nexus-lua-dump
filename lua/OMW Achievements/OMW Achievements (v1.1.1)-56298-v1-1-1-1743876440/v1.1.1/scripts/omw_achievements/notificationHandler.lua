local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local async = require('openmw.async')
local storage = require('openmw.storage')
local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local interfaces = require('openmw.interfaces')

local v2 = util.vector2
local notification = require('scripts.omw_achievements.ui.createnotification')
local achievements = require('scripts.omw_achievements.achievements.achievements')

achievementQueue = {}
isNotificationShowable = false
frameCount = 0

local function showNextAchievement()
    if #achievementQueue > 0 then
        local nextAchievement = table.remove(achievementQueue, 1)
        notification.createnotification(nextAchievement.icon, nextAchievement.name, nextAchievement.description)
        isNotificationShowable = true
    end
end

local function gettingAchievement(data)

    local macData = interfaces.storageUtils.getStorage()

    if macData:get(data.id) == false then

        macData:set(data.id, true)

        if isNotificationShowable == true then
            table.insert(achievementQueue, data)
        else
            local icon = data.icon
            local name = data.name
            local description = data.description
            local bg = data.bgColor
            notification.createnotification(icon, name, description, bg)
            isNotificationShowable = true
        end
    end

end

local function not_contains(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return false
        end
    end
    return true
end

local function getBookAchievement()

    for i = 1, #achievements do
        if achievements[i].id == "book_01" then
            return achievements[i]
        end
    end

end

local function bookRead(data)

    local macData = interfaces.storageUtils.getStorage()

    local bookReadTable = macData:getCopy('bookRead')

    if not_contains(bookReadTable, data.id) then
        table.insert(bookReadTable, data.id)
        macData:set('bookRead', bookReadTable)
    end

    if #bookReadTable == 51 then
        local bookAchievement = getBookAchievement()
        self.object:sendEvent('gettingAchievement', {
            name = bookAchievement.name,
            description = bookAchievement.description,
            icon = bookAchievement.icon,
            id = bookAchievement.id,
            bgColor = bookAchievement.bgColor
        })
    end
    
end

local function vivecIsDead(data)

    local macData = interfaces.storageUtils.getStorage()
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

local function daysPassed()
    for i = 1, #achievements do
        if achievements[i].type == "unique" and achievements[i].id == "dayspassed_01" then
            if types.Player.quests(self.object)["a1_1_findspymaster"].stage < 14 then
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
end

function onFrame(dt)
    if isNotificationShowable == true then
        frameCount = frameCount + 1
        if frameCount == 150 then
            isNotificationShowable = false
            achievementNotification:destroy()
            frameCount = 0
            showNextAchievement()
        end
    end
end

return {
    eventHandlers = {
        gettingAchievement = gettingAchievement,
        bookRead = bookRead,
        vivecIsDead = vivecIsDead,
        daysPassed = daysPassed
    },
    engineHandlers = {
        onFrame = onFrame
    }
}