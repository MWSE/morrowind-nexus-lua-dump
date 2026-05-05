local I = require("openmw.interfaces")
local self = require("openmw.self")
local time = require("openmw_aux.time")

local traitType = require("scripts.MerlordBackgrounds.utils.traitTypes").background
local absVisible = not self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.Cuirass)
    and not self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.Shirt)
    and not self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.Robe)
local period = 1

local function updateAllStats(amount)
    local personality = self.type.stats.attributes.personality(self)
    local direction = absVisible and -1 or 1
    personality.base = personality.base + amount * direction
end

local function checkAbs()
    local currAbsVisibility = not self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.Cuirass)
        and not self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.Shirt)
        and not self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.Robe)
    if absVisible == currAbsVisibility then return end

    absVisible = not absVisible
    updateAllStats(20)
end

I.CharacterTraits.addTrait {
    id = "bodyBuilder",
    type = traitType,
    name = "Bodybuilder",
    description = (
        "You have an incredible body. When you show it off, people can't help but swoon. " ..
        "Unfortunately, your body is the most interesting thing about you, and when not " ..
        "mesmerized by your good looks, people quickly realize how boring you are.\n" ..
        "\n" ..
        "+10 Personality when your chest is visible\n" ..
        "-10 Perosnality otherwise"
    ),
    doOnce = function()
        updateAllStats(10)
    end,
    onLoad = function()
        time.runRepeatedly(checkAbs, period)
    end
}
