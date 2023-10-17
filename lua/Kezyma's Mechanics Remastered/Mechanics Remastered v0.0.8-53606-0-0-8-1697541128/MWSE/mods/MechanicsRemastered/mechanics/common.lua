local K = {}

function K.spellSuccessChance(skill, willpower, luck, cost, sound, fatigue, maxFatigue)
    return ((skill * 2) + (willpower / 5) + (luck / 10) - cost - sound) * (0.75 + (0.5 * (fatigue / maxFatigue)))
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

        -- Limit the success chance from 0 - 100
        if (successChance > 100) then
            successChance = 100
        end
        if (successChance < 0) then
            successChance = 0
        end

        return successChance
    end
    return nil
end

return K