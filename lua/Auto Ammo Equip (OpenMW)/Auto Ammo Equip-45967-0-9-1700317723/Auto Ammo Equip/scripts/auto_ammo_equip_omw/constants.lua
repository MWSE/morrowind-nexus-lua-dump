-- do not modify anything here unless you really know what youre doing
local types = require("openmw.types")
local this = {}
local getRecord = types.Weapon.record

this.ammoType = {
    [types.Weapon.TYPE.MarksmanBow] = types.Weapon.TYPE.Arrow,
    [types.Weapon.TYPE.MarksmanCrossbow] = types.Weapon.TYPE.Bolt,
}

local function getAverageAmmoDamage(ammo)
    -- marksman weapons uses chop, chop, chop attack
    local record = getRecord(ammo)
    local averageDmg = (record.chopMaxDamage + record.chopMinDamage) / 2
    return averageDmg
end

local function compEnch(a, b, negate)
    -- apparently record.enchant returns an empty string for unenchanted objects
    return (getRecord(a).enchant:len() < getRecord(b).enchant:len()) == negate
end

local function compVal(a, b, negate)
    return (getRecord(a).value < getRecord(b).value) == negate
end

local function compDmg(a, b, negate)
    return (getAverageAmmoDamage(a) <
        getAverageAmmoDamage(b)) == negate
end

this.defCompOrder = {
    compEnch,
    compVal,
    compDmg
}
this.comp = {
    compEnch,
    compVal,
    compDmg,
    true,
    true,
    true,
}

-- stable sort
this.sort = function(list, comp)
    local function less_than_comp(a, b)
        return a < b
    end
    local comp = comp or less_than_comp

    local num = 0
    for k, v in ipairs(list) do
        num = num + 1
    end

    if num <= 1 then
        return
    end

    local sorted = false
    local n = num
    while not sorted do
        sorted = true
        for i = 1, n - 1 do
            if comp(list[i + 1], list[i]) then
                local tmp = list[i]
                list[i] = list[i + 1]
                list[i + 1] = tmp

                sorted = false
            end
        end
        n = n - 1
    end
end


return this
