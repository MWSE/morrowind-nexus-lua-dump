
local common = require("mer.chargenScenarios.common")
local logger = common.createLogger("Feature:StartDate")
local ExtraFeatures = require("mer.chargenScenarios.component.ExtraFeatures")

local function getMonthName(monthIndex)
    local months = {
        [0] = "Morning Star",
        [1] = "Sun's Dawn",
        [2] = "First Seed",
        [3] = "Rain's Hand",
        [4] = "Second Seed",
        [5] = "Mid Year",
        [6] = "Sun's Height",
        [7] = "Last Seed",
        [8] = "Hearthfire",
        [9] = "Frostfall",
        [10] = "Sun's Dusk",
        [11] = "Evening Star",
    }
    return months[monthIndex] or "Morning Star"
end

---@return { daysPassed: number, timeHours: number, isSet: boolean? }
local function getSavedDateTime()
    tes3.player.tempData.ChargenScenarios_startDate = tes3.player.tempData.ChargenScenarios_startDate or {}
    local dateTime = tes3.player.tempData.ChargenScenarios_startDate
    dateTime.daysPassed = dateTime.daysPassed or 228
    dateTime.timeHours = dateTime.timeHours or 9
    return tes3.player.tempData.ChargenScenarios_startDate
end

local function getMonthDay(daysPassed)
    local month = 0
    for monthIndex = 0, 12 do
        local daysInMonth = tes3.getCumulativeDaysForMonth(monthIndex)
        if daysPassed < daysInMonth then
            month = monthIndex - 1
            break
        end
    end
    local day = daysPassed - tes3.getCumulativeDaysForMonth(month)
    return month, day
end

local function createStartDateMenu(e)
    local menu = tes3ui.createMenu{ id = "ChargenScenarios:StartDateMenu", fixedFrame = true }
    menu.minWidth = 400
    menu:updateLayout()

    local dateTime = getSavedDateTime()

    local block = menu:createBlock()
    block.widthProportional = 1.0
    block.autoHeight = true
    block.flowDirection = "top_to_bottom"
    block.childAlignX = 0.5

    local header = block:createLabel{ text = "Select the Start Date/Time:" }
    header.color = tes3ui.getPalette("header_color")
    header.autoHeight = true
    header.widthProportional = 1.0
    header.borderBottom = 10
    header.justifyText = "center"
    header.wrapText = true

    --Date
    local dateSlider = mwse.mcm.createSlider(block, {
        label = "Start Date: %s",
        min = 0,
        max = 364,
        variable = mwse.mcm.createTableVariable{
            id = "daysPassed",
            table = dateTime,
        },
        convertToLabelValue = function(_, value)
            value = value or 0
            local month, day = getMonthDay(value)
            return string.format("%d %s", day+1, getMonthName(month))
        end
    })

    --Time
    local timeSlider = mwse.mcm.createSlider(block, {
        label = "Start Time: %s",
        min = 0,
        max = 23,
        variable = mwse.mcm.createTableVariable{
            id = "timeHours",
            table = dateTime,
        },
        convertToLabelValue = function(_, value)
            value = value or 0
            return string.format("%02d:00", value)
        end
    })

    local buttonBlock = block:createBlock()
    buttonBlock.widthProportional = 1.0
    buttonBlock.autoHeight = true
    buttonBlock.flowDirection = "left_to_right"
    buttonBlock.childAlignX = 1.0


    local randomButton = buttonBlock:createButton{ text = "Random" }
    randomButton:register("mouseClick", function()
        dateSlider:setVariableValue(math.random(0, 364))
        timeSlider:setVariableValue(math.random(0, 23))
    end)

    --cancel - delete the temp data so it doesn't reset time
    local cancelButton = buttonBlock:createButton{ text = "Reset" }
    cancelButton:register("mouseClick", function()
        dateSlider:setVariableValue(228)
        timeSlider:setVariableValue(9)
    end)

    local okButton = buttonBlock:createButton{ text = "Confirm" }
    okButton:register("mouseClick", function()
        menu:destroy()
        e.okCallback()
    end)

    menu:updateLayout()
end

local function isSet()
    local dateTime = getSavedDateTime()
    return not (dateTime.daysPassed == 228 and dateTime.timeHours == 9)
end

---@type ChargenScenarios.ExtraFeature
local feature = {
    id = "startDate",
    name = "Date/Time",
    callback = function(e)
        createStartDateMenu{
            okCallback = function()
                e.goBack()
            end,
        }
    end,
    onStart = function()
        local dateTime = getSavedDateTime()
        if isSet() then
            mwse.log("ChargenScenarios: Start Date set to %s", dateTime.daysPassed)
            local month, day = getMonthDay(dateTime.daysPassed)
            tes3.worldController.month.value = month
            tes3.worldController.day.value = day+1
            mwse.log("ChargenScenarios: Start Time set to %s", dateTime.timeHours)
            tes3.worldController.hour.value = dateTime.timeHours
        end
    end,
    getTooltip = function()
        local dateTime = getSavedDateTime()
        if isSet() then
            local month, day = getMonthDay(dateTime.daysPassed)
            return string.format("Start Date: %d %s, %02d:00", day+1, getMonthName(month), dateTime.timeHours or 0)
        end
    end,
    isActive = function()
        return isSet()
    end,
}

ExtraFeatures.registerFeature(feature)