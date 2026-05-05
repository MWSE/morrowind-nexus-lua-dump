local I = require("openmw.interfaces")
local self = require("openmw.self")
local time = require("openmw_aux.time")
local core = require("openmw.core")

local traitType = require("scripts.MerlordBackgrounds.utils.traitTypes").background
local period = 1
local nightPoint = 18 * time.hour
local dayPoint = 6 * time.hour
local weatherBuffs = {
    clear = 50,
    cloudy = 25,
}

local function getClockTime()
    return math.fmod(core.getGameTime(), time.day)
end

local isNight = dayPoint > getClockTime() or getClockTime() >= nightPoint
local isOutside = self.cell
    and (self.cell.isExterior or self.cell.isQuasiExterior)
local isOutsideAndNight = isNight and isOutside
local lastWeather = self.cell
    and core.weather.getCurrent(self.cell)
    and core.weather.getCurrent(self.cell).recordId
local currLuckBuff = 0
if isOutsideAndNight then
    currLuckBuff = weatherBuffs[lastWeather] or 0
end

local function changeStats(amount)
    local luck = self.type.stats.attributes.luck(self)

    luck.base = luck.base - currLuckBuff
    if isOutsideAndNight then
        luck.base = luck.base + amount
    end
    currLuckBuff = amount
end

local function checkSurroundings()
    local currIsNight = dayPoint > getClockTime() or getClockTime() >= nightPoint
    local currIsOutside = self.cell
        and (self.cell.isExterior or self.cell.isQuasiExterior)
    local currIsOutsideAndNight = currIsNight and currIsOutside
    local currWeather = self.cell
        and core.weather.getCurrent(self.cell)
        and core.weather.getCurrent(self.cell).recordId

    if currIsOutsideAndNight == isOutsideAndNight
        and currWeather == lastWeather
    then
        return
    end

    local newLuckBuff = 0
    if currIsOutsideAndNight then
        newLuckBuff = weatherBuffs[lastWeather] or 0
    end

    isOutsideAndNight = currIsOutsideAndNight
    lastWeather = currIsOutsideAndNight and currWeather or lastWeather
    changeStats(newLuckBuff)
end

I.CharacterTraits.addTrait {
    id = "starChild",
    type = traitType,
    name = "Star Child",
    description = (
        "You were born under starlight, and have gained the favor of the Celestials.\n" ..
        "\n" ..
        "> When outdoors at night:\n" ..
        "+50 Luck in clear weather\n" ..
        "+25 Luck in cloudy weather"
    ),
    doOnce = function()
        changeStats(currLuckBuff)
    end,
    onLoad = function()
        time.runRepeatedly(checkSurroundings, period)
    end,
}
