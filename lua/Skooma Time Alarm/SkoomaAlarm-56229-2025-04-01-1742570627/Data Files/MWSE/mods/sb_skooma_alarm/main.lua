local alarmEnabled = false
local hasTakenSkooma = false

local times = {
    6, 10.5, 15, 19
}
local currentTime

--- @param e simulateEventData
local function simulateCallback(e)
    for _, time in ipairs(times) do
        if (alarmEnabled == false and (tes3.worldController.hour.value >= time and tes3.worldController.hour.value < time + 1)) then
            alarmEnabled = true
            hasTakenSkooma = false
            currentTime = time
            tes3.playSound{
                sound = "EAS",
                loop = true
            }
            break
        end
    end
    if (alarmEnabled and tes3.worldController.hour.value >= currentTime + 1) then
        alarmEnabled = false
        if (hasTakenSkooma == false) then
            tes3.triggerCrime{
                value = 500,
                forceDetection = true
            }
        end
        tes3.removeSound{
            sound = "EAS"
        }
    end
end
event.register(tes3.event.simulate, simulateCallback)

--- @param e equipEventData
local function equipCallback(e)
    if (alarmEnabled) then
        if (e.item.id == "potion_skooma_01") then
            hasTakenSkooma = true
            tes3.removeSound{
                sound = "EAS"
            }
        end
    end
end
event.register(tes3.event.equip, equipCallback)