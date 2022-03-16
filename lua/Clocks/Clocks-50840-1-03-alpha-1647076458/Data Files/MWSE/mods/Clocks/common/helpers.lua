local constants = require("Clocks.common.constants")

local availableUISetups = constants.availableUISetups

local this = {}

-- Helper Functions --

function this.getTime(timestamp, optionalParameters)

    inUTCTime    = optionalParameters.inUTCTime or false
    inTwelveHour = optionalParameters.inTwelveHour or false

    local localTimePrefix = ""
    if not inUTCTime then
        localTimePrefix = "!"
    end

    if not inTwelveHour then
        return os.date(localTimePrefix .. "%H:%M", timestamp)
    else
        local dateTable = os.date(localTimePrefix .. "*t", timestamp)

        if dateTable.min == 0 then

            if dateTable.hour == 0 then
                return "Midnight"
            end

            if dateTable.hour == 12 then
                return "Noon"
            end

        end

        local hourInTwelveHour = dateTable.hour
        if hourInTwelveHour == 0 then
            hourInTwelveHour = 12
        elseif hourInTwelveHour > 12 then
            hourInTwelveHour = hourInTwelveHour - 12
        end

        local dayPeriod
        if dateTable.hour < 12 then
            dayPeriod = "am"
        else
            dayPeriod = "pm"
        end

        return string.format("%u:%02u %s", hourInTwelveHour, dateTable.min, dayPeriod)
    end
end

function this.getActiveUISetupID(config)

    for setupID, setup in ipairs(availableUISetups) do
        if config.showGameTime == setup.showGameTime and config.showRealTime == setup.showRealTime then
            return setupID
        end
    end

    return nil

end

function this.compareInputKeys(key1, key2)

    for _, parameter in ipairs{"keyCode", "isShiftDown", "isAltDown", "isControlDown"} do
        if key1[parameter] ~= key2[parameter] then
            return false
        end
    end

    return true

end

return this