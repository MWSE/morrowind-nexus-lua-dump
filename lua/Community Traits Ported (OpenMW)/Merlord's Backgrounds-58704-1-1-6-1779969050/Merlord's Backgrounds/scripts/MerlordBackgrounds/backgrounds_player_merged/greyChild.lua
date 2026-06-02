local I = require("openmw.interfaces")
local self = require("openmw.self")
local time = require("openmw_aux.time")
local core = require("openmw.core")

local traitType = require("scripts.MerlordBackgrounds.utils.traitTypes").background
local period = 1
local nightPoint = 18 * time.hour
local dayPoint = 6 * time.hour

local function getClockTime()
    return math.fmod(core.getGameTime(), time.day)
end

local isNight = dayPoint > getClockTime() or getClockTime() >= nightPoint

local function changeStats()
    local skills = self.type.stats.skills
    local attrs = self.type.stats.attributes
    local direction = isNight and 1 or -1

    skills.sneak(self).base = skills.sneak(self).base + 5 * direction
    skills.athletics(self).base = skills.athletics(self).base + 5 * direction
    skills.mysticism(self).base = skills.mysticism(self).base + 5 * direction
    skills.illusion(self).base = skills.illusion(self).base + 5 * direction
    skills.destruction(self).base = skills.destruction(self).base + 5 * direction

    attrs.endurance(self).base = attrs.endurance(self).base - 10 * direction
    attrs.willpower(self).base = attrs.willpower(self).base - 10 * direction
end

local function checkTime()
    if (dayPoint > getClockTime() or getClockTime() >= nightPoint) == isNight then return end

    isNight = not isNight
    changeStats()
end

I.CharacterTraits.addTrait {
    id = "greyOne",
    type = traitType,
    name = "Grey Child",
    description = (
        "You were born with a pale complexion and strangely sharp teeth. " ..
        "Animals are uneasy around you, and sunlight makes your skin tingle. " ..
        "Were you cursed? Perhaps your mother or father was a vampire? " ..
        "Regardless, you feel most at home in the cold and dark.\n" ..
        "\n" ..
        "> During the night (18:00-6:00)\n" ..
        "+5 Sneak, Athletics, Acrobatics, Mysticism, Illusion, and Destruction\n" ..
        "> During the day:\n" ..
        "-10 Endurance and Willpower"
    ),
    doOnce = function()
        changeStats()
    end,
    onLoad = function()
        time.runRepeatedly(checkTime, period)
    end,
}