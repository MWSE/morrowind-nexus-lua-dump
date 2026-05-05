local I = require("openmw.interfaces")
local self = require("openmw.self")
local time = require("openmw_aux.time")

local traitType = require("scripts.WretchedAndWeird.utils.traitTypes").background

local period = 1
local eqSlot = self.type.EQUIPMENT_SLOT
local realClothesSlots = {
    eqSlot.Cuirass,
    eqSlot.Greaves,
    eqSlot.Helmet,
    eqSlot.Pants,
    eqSlot.LeftPauldron,
    eqSlot.RightPauldron,
    eqSlot.Shirt,
}
local isNaked

local function checkNudes()
    local eq = self.type.getEquipment(self)
    for _, slot in ipairs(realClothesSlots) do
        if eq[slot] then
            return false
        end
    end
    return true
end

local function grantDynamicStats(direction)
    local agility = self.type.stats.attributes.agility(self)
    agility.base = agility.base + 30 * direction
    local personality = self.type.stats.attributes.personality(self)
    personality.base = personality.base + 30 * direction
    local speed = self.type.stats.attributes.speed(self)
    speed.base = speed.base + 30 * direction
end

I.CharacterTraits.addTrait {
    id = "nudist",
    type = traitType,
    name = "Nudist",
    description = (
        "It is natural! You've always found clothing and armor stifling, and for most of your life you've avoided wearing clothing unless absolutely necessary. " ..
        "Your lack of attire makes you extremely light on your feet, but most clothing makes you feel unbearably  " ..
        "You do, however, tolerate footwear at times where terrain is too rough to go barefoot, and sometimes you adorn your bare form with tasteful accessories.\n" ..
        "\n" ..
        "+30 Unarmored\n" ..
        "-30 Agility, Personality and Speed when clothed\n" ..
        "> Shoes, boots, skirts, gloves, belts and jewelry do not trigger the debuff"
    ),
    doOnce = function()
        local unarmored = self.type.stats.skills.unarmored(self)
        unarmored.base = unarmored.base + 30

        isNaked = checkNudes()
        if not isNaked then
            grantDynamicStats(-1)
        end
    end,
    onLoad = function()
        isNaked = checkNudes()
        time.runRepeatedly(
            function()
                print(checkNudes(), isNaked)
                if checkNudes() ~= isNaked then
                    isNaked = not isNaked
                    grantDynamicStats(isNaked and 1 or -1)
                end
            end,
            period
        )
    end
}
