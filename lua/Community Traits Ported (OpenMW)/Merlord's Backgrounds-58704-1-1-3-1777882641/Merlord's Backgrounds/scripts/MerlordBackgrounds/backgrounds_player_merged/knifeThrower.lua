local I = require("openmw.interfaces")
local self = require("openmw.self")
local time = require("openmw_aux.time")
local types = require("openmw.types")

local traitType = require("scripts.MerlordBackgrounds.utils.traitTypes").background

local period = 1
local rightHandItem = self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.CarriedRight)
local throwingWeaponEquipped = rightHandItem
    and rightHandItem.type == types.Weapon
    and rightHandItem.type.records[rightHandItem.recordId].type == rightHandItem.type.TYPE.MarksmanThrown

local function updateMarksman(amount)
    local marksman = self.type.stats.skills.marksman(self)
    local direction = throwingWeaponEquipped and 1 or -1
    marksman.base = marksman.base + amount * direction
end

local function checkWeapon()
    rightHandItem = self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.CarriedRight)
    local currStatus = rightHandItem
        and rightHandItem.type == types.Weapon
        and rightHandItem.type.records[rightHandItem.recordId].type == rightHandItem.type.TYPE.MarksmanThrown

    if currStatus == throwingWeaponEquipped then return end

    throwingWeaponEquipped = not throwingWeaponEquipped
    updateMarksman(10)
end

I.CharacterTraits.addTrait {
    id = "knifeThrower",
    type = traitType,
    name = "Knife Thrower",
    description = (
        "You spent your formative years as a knife thrower at the circus.\n" ..
        "\n" ..
        "+10 Marksman when throwing weapon is equipped"
    ),
    doOnce = function ()
        if throwingWeaponEquipped then
            updateMarksman(10)
        end
    end,
    onLoad = function()
        time.runRepeatedly(checkWeapon, period)
    end
}
