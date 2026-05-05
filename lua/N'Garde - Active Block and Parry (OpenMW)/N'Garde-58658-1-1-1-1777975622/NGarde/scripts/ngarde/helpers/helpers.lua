local logging = require('scripts.ngarde.helpers.logger').new()
logging:setLoglevel(logging.LOG_LEVELS.OFF)
local util  = require('openmw.util')
local core  = require("openmw.core")
local types = require("openmw.types")
Helpers     = {}

local max   = math.max
local modf  = math.modf
local floor = math.floor


function Helpers.sum(array)
    local sum = 0
    for i=1, #array do
        sum = sum + array[i]
    end
    return sum
end

function Helpers.getAttackDetails(attack)
        local isH2HAttack = false
        local isThrown = false
        if attack.weapon then
            isThrown = (attack.weapon.id == "@0x0") -- weapon is a null pointer, not even a proper nil - the weapon is likely thrown
        end
        local attackerRecord = types.NPC.record(attack.attacker.recordId) or
            types.Creature.record(attack.attacker.recordId)
        ---@diagnostic disable-next-line undefined-fields
        local attackerIsCreature = (attack.attacker.type == types.Creature and not attackerRecord.canUseWeapons)
        logging:debug("attackerIsCreature:" .. tostring(attackerIsCreature))
        logging:debug("attack.attacker.type:" .. tostring(attack.attacker.type))
        ---@diagnostic disable-next-line undefined-fields
        local attackerIsWeaponUser = ((attack.attacker.type == types.NPC or attack.attacker.type == types.Player) or (attack.attacker.type == types.Creature and attackerRecord.canUseWeapons))
        logging:debug("Attacker Is Weapon User:" .. tostring(attackerIsWeaponUser))
        if not (attackerIsCreature or (attackerIsWeaponUser and attack.weapon)) then
            isH2HAttack = true
        end
        isH2HAttack = not (attackerIsCreature or (attackerIsWeaponUser and attack.weapon))
        logging:debug("isH2HAttack:" .. tostring(isH2HAttack))
        logging:debug("successful:" .. tostring(attack.successful))
        return isH2HAttack, isThrown, attackerIsCreature, attackerIsWeaponUser, attackerRecord.name
end

function Helpers.roundTo(number, decimalPlaces)
    local places = decimalPlaces or 0
    local integral, fractional = math.modf(number)

    fractional = fractional * (10 ^ places)
    fractional = math.floor(fractional) / (10 ^ places)

    return integral + fractional
end

function Helpers.rollNdM(self, number, dSides, difficulty)
    local successes = 0
    for i=1, number do
        if math.random(1,dSides) > difficulty then
            successes = successes +1
        end
    end
    return successes
end


function Helpers.tableContains(t, obj)
    for k, v in pairs(t) do
        if v == obj then return true end
    end
    return false
end

function Helpers.arrayContains(t, obj)
    for i=1, #t do
        if t[i] == obj then return true end
    end
    return false
end

function Helpers.getArmorCategory(ArmorRecord)
    local reference = {
        [types.Armor.TYPE.Boots] = 'iBootsWeight',
        [types.Armor.TYPE.Helmet] = 'iHelmWeight',
        [types.Armor.TYPE.Cuirass] = 'iCuirassWeight',
        [types.Armor.TYPE.Greaves] = 'iGreavesWeight',
        [types.Armor.TYPE.LBracer] = 'iGauntletWeight',
        [types.Armor.TYPE.RBracer] = 'iGauntletWeight',
        [types.Armor.TYPE.LGauntlet] = 'iGauntletWeight',
        [types.Armor.TYPE.RGauntlet] = 'iGauntletWeight',
        [types.Armor.TYPE.LPauldron] = 'iPauldronWeight',
        [types.Armor.TYPE.RPauldron] = 'iPauldronWeight',
        [types.Armor.TYPE.Shield] = 'iShieldWeight',
    }

    local iWeight = core.getGMST(reference[ArmorRecord.type])
    local epsilon = 0.0005

    if ArmorRecord.weight <= iWeight * core.getGMST("fLightMaxMod") + epsilon then
        return "LightArmor"
    elseif ArmorRecord.weight <= iWeight * core.getGMST("fMedMaxMod") + epsilon then
        return "MediumArmor"
    else
        return "HeavyArmor"
    end
end

function Helpers.isTargetingPlayer(t)
    for i=1, #t do
        if t[i].recordId == "player" then return true end
    end
    return false
end

function Helpers.decimalShiftToIntCommonFactor(numbers)
    local factor = 1
    local tailLens = {}
    local result = {}
    for i=1, #numbers do
        table.insert(tailLens, max(#tostring(select(2, modf(numbers[i]))) - 2, 0))
    end
    table.sort(tailLens)
    if tailLens[#tailLens] > 0 then -- largest(last) len is > 0 so at least one number had a decimal component
        factor = (10 ^ max(unpack(tailLens)))
    end
    for i=1, #numbers do
        table.insert(result, numbers[i] * factor)
    end
    return factor, result
end

function Helpers.decimalShiftToInt(number)
    local decimaltailLen = max(#tostring(select(2, modf(number))) - 2, 0)
    local factor = 1
    if decimaltailLen > 0 then
        factor = 10 ^ decimaltailLen
    end
    local ret = number * factor
    return factor, ret
end

function Helpers.tableShallowCopy(t)
    local t2 = {}
    for k, v in pairs(t) do t2[k] = v end
    return t2
end

function Helpers.tableDeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Helpers.tableDeepCopy(orig_key)] = Helpers.tableDeepCopy(orig_value)
        end
        setmetatable(copy, Helpers.tableDeepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function Helpers.tableRecursivePrint(table)
    for k, v in pairs(table) do
        print(k .. ":" .. tostring(v))
        if type(v) == "table" then
            Helpers.tableRecursivePrint(v)
        end
    end
end

return Helpers

