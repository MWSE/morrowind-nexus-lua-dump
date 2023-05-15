-- in-game combat formula
-- https://en.uesp.net/wiki/Morrowind:Combat
-- https://wiki.openmw.org/index.php?title=Research:Common_Terms
-- https://wiki.openmw.org/index.php?title=Research:Combat
-- https://wiki.openmw.org/index.php?title=Research:Magic
---@class CombatFormula
local this = {}

--- https://floating-point-gui.de/errors/comparison/
---@param a number
---@param b number
---@param epsilon number?
function this.NearyEqual(a, b, epsilon)
    local minNormal = 1.175494351e-38
    local maxValue = 3.402823466e+38
    local e = epsilon and epsilon or 0.00001
    local absA = math.abs(a)
    local absB = math.abs(b)
    local diff = math.abs(a - b)
    if a == b then
        -- shortcut, handles infinities
        return true
    elseif a == 0 or b == 0 or (absA + absB < minNormal) then
        -- a or b is zero or both are extremely close to it
        -- relative error is less meaningful here
        return diff < (e * minNormal)
    else
        -- use relative error
        return diff / math.min(absA + absB, maxValue) < e
    end
end

---@param m number
---@return number
function this.Normalize(m)
    return math.max(m, 0) / 100.0
end

---@param m number
---@return number
function this.InverseNormalize(m)
    return math.max(100.0 - m, 0) / 100.0
end

---@param damage number
---@param speed number
---@return number
function this.CalculateDPS(damage, speed)
    return damage * speed
end

---@param weaponDamage number
---@param strengthModifier number
---@param conditionModifier number
---@param criticalHitModifier number
---@return number
function this.CalculateAcculateWeaponDamage(weaponDamage, strengthModifier, conditionModifier, criticalHitModifier)
    return (weaponDamage * strengthModifier * conditionModifier * criticalHitModifier)
end

---@param armorRating number
---@param damage number
---@param fCombatArmorMinMult number fCombatArmorMinMult
---@return number
function this.CalculateDamageReductionFromArmorRating(damage, armorRating, fCombatArmorMinMult)
    return math.max(damage * math.max(damage / (damage + armorRating), fCombatArmorMinMult), 1.0)
end

---@param currentFatigue number
---@param baseFatigue number
---@param fFatigueBase number fFatigueBase
---@param fFatigueMult number fFatigueMult
---@return number
function this.CalculateFatigueTerm(currentFatigue, baseFatigue, fFatigueBase, fFatigueMult)
    return math.max(fFatigueBase - fFatigueMult * math.max(1.0 - currentFatigue / baseFatigue, 0.0), 0.0)
end

---@param weaponSkill number
---@param agility number
---@param luck number
---@param fatigueTerm number
---@param fortifyAttack number
---@param blind number
---@return number
function this.CalculateHitRate(weaponSkill, agility, luck, fatigueTerm, fortifyAttack, blind)
    return this.Normalize((weaponSkill + (agility * 0.2) + (luck * 0.1)) * fatigueTerm + fortifyAttack - blind)
end

---@param agility number
---@param luck number
---@param fatigueTerm number
---@param sanctuary number
---@return number
function this.CalculateEvasion(agility, luck, fatigueTerm, sanctuary)
    return this.Normalize(((agility * 0.2) + (luck * 0.1)) * fatigueTerm + math.min(sanctuary, 100))
end

---@param hitRate number
---@param evation number
---@return number
function this.CalculateChanceToHit(hitRate, evation)
    return math.clamp(hitRate - evation, 0.0, 1.0)
end

---@param difficulty number
---@param fDifficultyMult number
---@return number
function this.CalculateDifficultyMultiplier(difficulty, fDifficultyMult)
    -- only attacker case
    if difficulty > 0 then
        return 1.0 + (-difficulty / fDifficultyMult)
    else
        return 1.0 + (-difficulty * fDifficultyMult)
    end
end

---@param self CombatFormula
---@param unitwind MyUnitWind
function this.RunTest(self, unitwind)
    unitwind:start("DPSTooltips.combat")

    unitwind:test("Normalize", function()
        unitwind:approxExpect(self.Normalize(100)).toBe(1.0) -- edge
        unitwind:approxExpect(self.Normalize(0)).toBe(0.0)   -- edge
        unitwind:approxExpect(self.Normalize(110)).toBe(1.1) -- over
        unitwind:approxExpect(self.Normalize(-50)).toBe(0.0) -- capped
    end)
    unitwind:test("InverseNormalize", function()
        unitwind:approxExpect(self.InverseNormalize(100)).toBe(0.0) -- edge
        unitwind:approxExpect(self.InverseNormalize(0)).toBe(1.0)   -- edge
        unitwind:approxExpect(self.InverseNormalize(110)).toBe(0.0) -- capped
        unitwind:approxExpect(self.InverseNormalize(-50)).toBe(1.5) -- over
    end)
    unitwind:test("CalculateDPS", function()
        unitwind:approxExpect(self.CalculateDPS(100, 2)).toBe(200) -- normal
        unitwind:approxExpect(self.CalculateDPS(100, 0)).toBe(0)   -- zero
    end)
    unitwind:test("CalculateAcculateWeaponDamage", function()
        unitwind:approxExpect(self.CalculateAcculateWeaponDamage(100, 2, 0.75, 1)).toBe(150) -- normal
        unitwind:approxExpect(self.CalculateAcculateWeaponDamage(100, 0, 0.75, 1)).toBe(0)   -- zero
    end)
    unitwind:test("CalculateDamageReductionFromArmorRating", function()
        unitwind:approxExpect(self.CalculateDamageReductionFromArmorRating(90, 10, 0.25)).toBe(81) -- normal
        unitwind:approxExpect(self.CalculateDamageReductionFromArmorRating(5, 10, 0.5)).toBe(2.5)  -- min mult
        unitwind:approxExpect(self.CalculateDamageReductionFromArmorRating(2, 20, 0.25)).toBe(1)   -- less than 1.0
    end)
    unitwind:test("CalculateFatigueTerm", function()
        unitwind:approxExpect(self.CalculateFatigueTerm(100, 100, 0.5, 0.5)).toBe(0.5)
    end)
    unitwind:test("CalculateHitRate", function()
        unitwind:approxExpect(self.CalculateHitRate(50, 50, 50, 0.5, 20, 10)).toBe(0.425)  -- fixed blind
        unitwind:approxExpect(self.CalculateHitRate(50, 50, 50, 0.5, 20, -10)).toBe(0.625) -- unfixed blind
        unitwind:approxExpect(self.CalculateHitRate(100, 100, 100, 1.0, 0, 0)).toBe(1.3) -- over
        unitwind:approxExpect(self.CalculateHitRate(0, 0, 0, 1.0, 0, 100)).toBe(0.0) -- capped
    end)
    unitwind:test("CalculateEvasion", function()
        unitwind:approxExpect(self.CalculateEvasion(50, 50, 0.5, 10)).toBe(0.175)   -- noraml
        unitwind:approxExpect(self.CalculateEvasion(50, 50, 0.5, 110)).toBe(1.075) -- capped
    end)
    unitwind:test("CalculateChanceToHit", function()
        unitwind:approxExpect(self.CalculateChanceToHit(0.7, 0.3)).toBe(0.4) -- normal
        unitwind:approxExpect(self.CalculateChanceToHit(2.0, 0.5)).toBe(1.0) -- capped
        unitwind:approxExpect(self.CalculateChanceToHit(0.2, 0.7)).toBe(0.0) -- capped
    end)
    unitwind:test("CalculateDifficultyMultiplier", function()
        unitwind:approxExpect(self.CalculateDifficultyMultiplier(0, 5)).toBe(1.0)
        unitwind:approxExpect(self.CalculateDifficultyMultiplier(1.0, 5)).toBe(0.8)
        unitwind:approxExpect(self.CalculateDifficultyMultiplier(0.5, 5)).toBe(0.9)
        unitwind:approxExpect(self.CalculateDifficultyMultiplier(-1.0, 5)).toBe(6.0)
        unitwind:approxExpect(self.CalculateDifficultyMultiplier(-0.5, 5)).toBe(3.5)
    end)

    unitwind:finish()
end

return this
