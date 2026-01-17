local self = require('openmw.self')
local core = require('openmw.core')
local interfaces = require('openmw.interfaces')
local types = require('openmw.types')
local achievements = require('scripts.omw_achievements.achievements.achievements')
local ui = require('openmw.ui')

local sk00maUtils = require('scripts.omw_achievements.utils.sk00maUtils')

local slot = types.Actor.EQUIPMENT_SLOT

local frameCount = 0
local updateCount = 0

local function checkEquipment()
    --- Check for "equipment" type achievement
    local macData = interfaces.storageUtils.getStorage("achievements")

    for i = 1, #achievements do
        if macData:get(achievements[i].id) == false then
            if achievements[i].type == "equipment" then
                local equipmentTable = achievements[i].equipment
                local allMatched = true

                for slotKey, expected in pairs(equipmentTable) do
                    local equippedItem = types.Actor.getEquipment(self.object, slotKey)

                    if not equippedItem then
                        allMatched = false
                        break
                    end

                    local recordId = equippedItem.recordId

                    if type(expected) == "string" then
                        if recordId ~= expected then
                            allMatched = false
                            break
                        end
                    elseif type(expected) == "table" then
                        if sk00maUtils.not_contains(expected, recordId) then
                            allMatched = false
                            break
                        end
                    else
                        allMatched = false
                        break
                    end
                end

                if allMatched then
                    self.object:sendEvent('gettingAchievement', {
                        id = achievements[i].id,
                        icon = achievements[i].icon,
                        bgColor = achievements[i].bgColor,
                        name = achievements[i].name,
                        description = achievements[i].description
                    })
                end
            end
        end
    end
end

local function onFrame()
    frameCount = frameCount + 1
    if frameCount > 10 then
        checkEquipment()
    end
end

return {
    engineHandlers = {
        onFrame = onFrame
    }
}