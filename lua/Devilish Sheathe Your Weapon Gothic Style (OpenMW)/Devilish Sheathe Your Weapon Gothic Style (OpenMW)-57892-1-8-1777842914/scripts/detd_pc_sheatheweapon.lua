local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')

local prevStance = nil
local prevCarriedRight = nil
local prevSneakOverride = nil

local function isWeaponDrawn(stance, carriedRight)
    if stance ~= types.Actor.STANCE.Weapon then
        return 0
    end
    if carriedRight and carriedRight.type == types.Weapon then
        return 1
    end
    return 0
end

local function isSneakInterfaceSaysSneaking()
    local sneakInterface = I.SneakIsGoodNow
    if not sneakInterface then
        return false
    end

    local ps = sneakInterface.playerState
    if not ps then
        return false
    end

    return ps.isSneaking == true
end

local function onUpdate()
    local stance = types.Actor.getStance(self)
    local carriedRight = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight) or nil
    local sneakOverride = isSneakInterfaceSaysSneaking()

    if stance ~= prevStance
        or carriedRight ~= prevCarriedRight
        or sneakOverride ~= prevSneakOverride then

        local weaponDrawn = isWeaponDrawn(stance, carriedRight)

        if sneakOverride then
            weaponDrawn = 0
        end

       -- print("PLAYER | stance changed or sneak changed | sent =", weaponDrawn, "| sneakOverride =", sneakOverride)
        core.sendGlobalEvent("pcWeaponDrawn", weaponDrawn)
    end

    prevStance = stance
    prevCarriedRight = carriedRight
    prevSneakOverride = sneakOverride
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    }
}