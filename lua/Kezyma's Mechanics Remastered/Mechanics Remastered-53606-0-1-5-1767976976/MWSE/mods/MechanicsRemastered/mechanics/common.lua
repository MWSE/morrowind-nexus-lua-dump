
local K = {
    config = require('MechanicsRemastered.config')
}

function K.limitToRange(val, min, max)
    if (val > max) then
        val = max
    elseif (val < min) then
        val = min
    end
    return val
end

function K.healthPerSecond(endurance)
    local rps = (0.1 * endurance) / 60 / 60
    return rps * K.config.HealthRegenSpeed
end

function K.healthRegenCalculation(endurance)
    local rps = K.healthPerSecond(endurance)
    local ts = tes3.findGlobal("timescale").value
    return rps * ts
end

function K.magickaPerSecond(int)
    local mult = tes3.findGMST(tes3.gmst.fRestMagicMult).value
    local rps = (mult * int) / 60 / 60
    return rps * K.config.MagickaRegenSpeed
end

function K.magickaRegenCalculation(int)
    local rps = K.magickaPerSecond(int)
    local ts = tes3.findGlobal("timescale").value
    return rps * ts
end

function K.spellSuccessChance(skill, willpower, luck, cost, sound, fatigue, maxFatigue)
    local chance = ((skill * 2) + (willpower / 5) + (luck / 10) - cost - sound) * (0.75 + (0.5 * (fatigue / maxFatigue)))
    chance = K.limitToRange(chance, 0, 100)
    return chance
end

function K.schoolToSkill(school)
    if (school == tes3.magicSchool.alteration) then
        return tes3.skill.alteration
    end
    if (school == tes3.magicSchool.conjuration) then
        return tes3.skill.conjuration
    end
    if (school == tes3.magicSchool.destruction) then
        return tes3.skill.destruction
    end
    if (school == tes3.magicSchool.illusion) then
        return tes3.skill.illusion
    end
    if (school == tes3.magicSchool.mysticism) then
        return tes3.skill.mysticism
    end
    if (school == tes3.magicSchool.restoration) then
        return tes3.skill.restoration
    end
    if (school == tes3.magicSchool.none) then
        return -1
    end
end

function K.spellChanceForMobileActor(spell, caster)
    local spellSchool = spell:getLeastProficientSchool(caster)
    if (spellSchool >= 0) then
        local spellSkill = K.schoolToSkill(spellSchool)
        
        -- Calculate everything to determine the chance of success.
        local skill = caster:getSkillValue(spellSkill)
        local willpower = caster.willpower.current
        local luck = caster.luck.current
        local fatigue = caster.fatigue.current
        local maxFatigue = caster.fatigue.base
        local sound = caster.sound
        local spellCost = spell.magickaCost
        local successChance = K.spellSuccessChance(skill, willpower, luck, spellCost, sound, fatigue, maxFatigue)

        return successChance
    end
    return nil
end

return K