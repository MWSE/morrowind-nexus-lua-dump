local I = require("openmw.interfaces")
local self = require("openmw.self")
local time = require("openmw_aux.time")
local types = require("openmw.types")

local traitType = require("scripts.MerlordBackgrounds.utils.traitTypes").background

local period = 1
local rightHandItem = self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.CarriedRight)
local inFencingStance = rightHandItem
    and rightHandItem.type == types.Weapon
    and rightHandItem.type.records[rightHandItem.recordId].type == rightHandItem.type.TYPE.LongBladeOneHand
    and not self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.CarriedLeft)

local function updateLongBlade(amount)
    local longBlade = self.type.stats.skills.longblade(self)
    local direction = inFencingStance and 1 or -1
    longBlade.base = longBlade.base + amount * direction
end

local function checkOffHand()
    rightHandItem = self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.CarriedRight)
    local currStance = rightHandItem
        and rightHandItem.type == types.Weapon
        and rightHandItem.type.records[rightHandItem.recordId].type == rightHandItem.type.TYPE.LongBladeOneHand
        and not self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.CarriedLeft)

    if currStance == inFencingStance then return end

    inFencingStance = not inFencingStance
    updateLongBlade(20)
end

I.CharacterTraits.addTrait {
    id = "fencer",
    type = traitType,
    name = "Fencing Master",
    description = (
        "You have dedicated your life to the art of fencing.\n" ..
        "\n" ..
        "+20 Long Blade if your off-hand is free"
    ),
    doOnce = function ()
        if inFencingStance then
            updateLongBlade(20)
        end
    end,
    onLoad = function()
        time.runRepeatedly(checkOffHand, period)
    end
}
