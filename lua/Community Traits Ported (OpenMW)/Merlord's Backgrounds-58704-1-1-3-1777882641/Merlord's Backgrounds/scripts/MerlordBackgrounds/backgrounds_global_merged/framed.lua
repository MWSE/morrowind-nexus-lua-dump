local time = require("openmw_aux.time")
local async = require("openmw.async")
local storage = require("openmw.storage")

local settings = storage.globalSection("SettingsMerlordBackgrounds_framed")

local timerCallback

local function checkBounty(player)
    local currBounty = player.type.getCrimeLevel(player)

    if currBounty < settings:get("bountyLimit") then
        local bountyBonus = math.random(
            settings:get("minBounty"),
            settings:get("maxBounty")
        )
        player.type.setCrimeLevel(player, currBounty + bountyBonus)
    end

    time.newSimulationTimer(
        math.random(
            settings:get("minInterval") * time.day,
            settings:get("maxInterval") * time.day
        ),
        timerCallback,
        player
    )
end

timerCallback = async:registerTimerCallback(
    "checkCrime",
    checkBounty
)

return {
    eventHandlers = {
        MerlordsTraits_registerFramed = function(player)
            time.newSimulationTimer(
                math.random(time.hour, time.day),
                timerCallback,
                player
            )
        end
    }
}
