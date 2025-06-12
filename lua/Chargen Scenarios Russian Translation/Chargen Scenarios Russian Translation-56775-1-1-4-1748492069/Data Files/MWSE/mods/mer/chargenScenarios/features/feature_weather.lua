local common = require("mer.chargenScenarios.common")
local logger = common.createLogger("Feature:Weather")
local ExtraFeatures = require("mer.chargenScenarios.component.ExtraFeatures")
--[[
    Feature that lets you pick from any of the weather types in the game.
]]

---@class ChargenScenarios.WeatherFeature : ChargenScenarios.ExtraFeature
---@field selectedWeather string The currently selected weather type
local WeatherFeature = {
    id = "weather",
    name = "Погода",
}

local weatherTranslations = {
    clear = "Ясно",
    cloudy = "Облачно",
    foggy = "Туманно",
    overcast = "Пасмурно",
    rain = "Дождь",
    thunder = "Гроза",
    ash = "Пепельная буря",
    blight = "Моровая буря",
    snow = "Снег",
    blizzard = "Метель"
}

--Clear selection on load
event.register("loaded", function()
    WeatherFeature.selectedWeather = nil
end)

function WeatherFeature.getTooltip()
    local weather = WeatherFeature.selectedWeather
    if weather then
        return "Погода: " .. WeatherFeature.getWeatherName(weather)
    end
end

function WeatherFeature.getWeatherName(weatherId)
    --capitalise first letter of id
    --return string.gsub(weatherId, "^%l", string.upper)
    return weatherTranslations[weatherId] or string.gsub(weatherId, "^%l", string.upper)
end


--Populate weather buttons
function WeatherFeature.populateWeather(parent)
    parent:destroyChildren()
    local weatherTypes = table.invert(tes3.weather)
    for _, weatherId in ipairs(weatherTypes) do
        local weatherName = WeatherFeature.getWeatherName(weatherId)
        local button = parent:createTextSelect{ text = weatherName }
        button:register("mouseClick", function()
            logger:debug("Clicked on weather: %s", weatherName)
            WeatherFeature.selectedWeather = weatherId
            WeatherFeature.populateWeather(parent)
        end)
        button.widget.state = WeatherFeature.selectedWeather == weatherId and tes3.uiState.active or tes3.uiState.normal
    end
    parent:getTopLevelMenu():updateLayout()
end

---@param e ChargenScenarios.ExtraFeature.callbackParams
function WeatherFeature.callback(e)
    local menu = tes3ui.createMenu{ id = "ChargenScenarios:WeatherMenu", fixedFrame = true }
    menu.minWidth = 400
    menu:updateLayout()

    local block = menu:createBlock()
    block.widthProportional = 1.0
    block.autoHeight = true
    block.flowDirection = "top_to_bottom"
    block.childAlignX = 0.5

    local header = block:createLabel{ text = "Выберите погоду:" }
    header.color = tes3ui.getPalette("header_color")

    local description = block:createLabel{
        text = "Примечание: эта опция переопределит любые настройки погоды в сценарии.",
    }
    description.autoHeight = true
    description.widthProportional = 1.0
    description.borderAllSides = 10
    description.justifyText = "center"
    description.wrapText = true

    local weatherBlock = block:createThinBorder()
    weatherBlock.autoWidth = true
    weatherBlock.autoHeight = true
    weatherBlock.flowDirection = "top_to_bottom"
    weatherBlock.childAlignX = 0.5
    weatherBlock.minWidth = 100
    weatherBlock.paddingAllSides = 10

    WeatherFeature.populateWeather(weatherBlock)

    local buttonsBlock = block:createBlock()
    buttonsBlock.autoWidth = true
    buttonsBlock.autoHeight = true

        ---Random button
    ---  Pick a number between 1 and the number of available spells
    ---  Select that many spells randomly from the available spells
    local randomButton = buttonsBlock:createButton{ text = "Случайная" }
    randomButton:register("mouseClick", function()
        local _, choice = table.choice(tes3.weather)
        WeatherFeature.selectedWeather = choice
        WeatherFeature.populateWeather(weatherBlock)
        menu:updateLayout()
    end)

    --Add reset button
    local resetButton = buttonsBlock:createButton{ text = "Сброс" }
    resetButton:register("mouseClick", function()
        WeatherFeature.selectedWeather = nil
        WeatherFeature.populateWeather(weatherBlock)
    end)

    -- Add a button to finalize the selection
    local finalizeButton = buttonsBlock:createButton{ text = "Подтвердить" }
    finalizeButton:register("mouseClick", function()
        menu:destroy()
        e.goBack()
    end)

    menu:updateLayout()
end

function WeatherFeature.isActive()
    return WeatherFeature.selectedWeather ~= nil
end

function WeatherFeature.onStart()
    logger:debug("WeatherFeature.onStart()")
    local selectedWeather = WeatherFeature.selectedWeather
    if selectedWeather then
        if tes3.player.cell.isInterior then
            local exteriorPosition = tes3.getClosestExteriorPosition{
                 reference = tes3.player
            }
            local cell = tes3.getCell{
                position = exteriorPosition
            }
            cell.region:changeWeather(tes3.weather[selectedWeather])
            logger:debug("Interior, found exterior region %s, setting weather to %s", cell.region.name, selectedWeather)
        else
            logger:debug("Exterior cell, immediately setting weather to %s", selectedWeather)
            tes3.changeWeather{
                immediate = true,
                id = tes3.weather[selectedWeather],
            }
        end
    end
end



ExtraFeatures.registerFeature(WeatherFeature)