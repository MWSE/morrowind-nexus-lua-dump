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

local playerSettings = storage.playerSection('Settings/OmwAchievements/Options')

local sk00maUtils = require('scripts.omw_achievements.utils.sk00maUtils')

achievementQueue = {}
isNotificationShowable = false
frameCount = 0

local function showNextAchievement()
    if #achievementQueue > 0 then
        local nextAchievement = table.remove(achievementQueue, 1)
        notification.createnotification(nextAchievement.icon, nextAchievement.name, nextAchievement.description, nextAchievement.bg)
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
            notification.createnotification(icon, name, description, bg)
            isNotificationShowable = true
        end
    end

end

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

local function daysPassed(data)
    for i = 1, #achievements do

        --- Check for unique achievement "What Main Quest?"
        if achievements[i].type == "unique" and achievements[i].id == "dayspassed_01" and data.days >= 60 then
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

        --- Check for unique achievement "Still a Stranger"
        if achievements[i].type == "unique" and achievements[i].id == "dayspassed_02" and data.days >= 365 then
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

function onFrame(dt)
    if isNotificationShowable == true then
        notificationDuration = playerSettings:get('notification_duration')
        frameCount = frameCount + 1
        if frameCount == (notificationDuration * 60) then
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
        vivecIsDead = vivecIsDead,
        daysPassed = daysPassed
    },
    engineHandlers = {
        onFrame = onFrame
    }
}