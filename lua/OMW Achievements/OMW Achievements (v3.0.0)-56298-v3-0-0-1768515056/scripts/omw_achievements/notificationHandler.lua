local storage = require('openmw.storage')
local self = require('openmw.self')
local interfaces = require('openmw.interfaces')
local core = require('openmw.core')

local notification = require('scripts.omw_achievements.ui.createNotification')
local playerSettings = storage.playerSection('Settings/OmwAchievements/Options')

achievementQueue = {}
isNotificationShowable = false
frameDuration = 0
frameCount = 0

local function showNextAchievement()
    if #achievementQueue > 0 then
        local nextAchievement = table.remove(achievementQueue, 1)
        notification.createNotification(nextAchievement.icon, nextAchievement.name, nextAchievement.description, nextAchievement.bg)
        isNotificationShowable = true
    end
end

local function gettingAchievement(data)

    local macData = interfaces.storageUtils.getStorage("achievements")

    if macData:get(data.id) == false then

        macData:set(data.id, true)

        if isNotificationShowable == true then
            table.insert(achievementQueue, data)
        else
            local icon = data.icon
            local name = data.name
            local description = data.description
            local bg = data.bgColor
            notification.createNotification(icon, name, description, bg)
            frameDuration = core.getRealFrameDuration()
            isNotificationShowable = true
        end
    end

end

function onFrame(dt)
    notificationDuration = playerSettings:get('notification_duration')
    framesNumber = math.floor((notificationDuration / frameDuration) + 0.5)

    if isNotificationShowable == true then
        frameCount = frameCount + 1
        if frameCount == framesNumber then
            isNotificationShowable = false
            achievementNotification:destroy()
            frameCount = 0
            showNextAchievement()
        end
    end
end

return {
    eventHandlers = {
        gettingAchievement = gettingAchievement
    },
    engineHandlers = {
        onFrame = onFrame
    }
}