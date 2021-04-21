
local dummyIds = {
    ["ss20_practice_dummy"] = true
}
local soundIds = {
    projectile = "ss20_dummyhit",
    h2h = "ss20_dummyhit",
    hit = "ss20_dummyhit",
    miss = "ss20_dummyhit"
}

local weaponToSkillMapping = {
    [tes3.weaponType.shortBladeOneHand] = tes3.skill.shortBlade,
    [tes3.weaponType.longBladeOneHand] = tes3.skill.longBlade,
    [tes3.weaponType.longBladeTwoClose] = tes3.skill.longBlade,
    [tes3.weaponType.bluntOneHand] = tes3.skill.blunt,
    [tes3.weaponType.bluntTwoClose] = tes3.skill.blunt,
    [tes3.weaponType.bluntTwoWide] = tes3.skill.blunt,
    [tes3.weaponType.spearTwoWide] = tes3.skill.spear,
    [tes3.weaponType.axeOneHand] = tes3.skill.axe,
    [tes3.weaponType.axeTwoHand] = tes3.skill.axe,
}

local function isDummy(reference)
    local id = reference.baseObject.id
    if dummyIds[id:lower()] then
        return true
    end
end

local function isPlayerLookingAtDummy()
    local target = tes3.getPlayerTarget()
    return  target and isDummy(target)
    -- local result = tes3.rayTest({
    --     position = tes3.getPlayerEyePosition(),
    --     direction = tes3.getPlayerEyeVector(),
    --     ignore = { tes3.player },
    --     maxDistance = 300
    -- })
    -- if result and result.reference then
    --     return isDummy(result.reference)
    -- end
    -- return false
end

local function getCurrentMeleeSkill()
    local skillIndex
    local weapon = tes3.mobilePlayer.readiedWeapon
    if not weapon then
        skillIndex = tes3.skill.handToHand
    else
        skillIndex = weaponToSkillMapping[weapon.object.type]
    end
    if skillIndex then
        return tes3.getSkill(skillIndex)
    end
    --false for marksman
    return false
end

local function getHitSuccess(skill)
    --fatigue term
    local fFatigueBase = tes3.findGMST(tes3.gmst.fFatigueBase).value
    local fFatigueMult = tes3.findGMST(tes3.gmst.fFatigueMult).value
    local playerFatigue = tes3.mobilePlayer.fatigue
    local normalisedFatigue = playerFatigue.base / playerFatigue.current
    local fatigueTerm = fFatigueBase - fFatigueMult*(1 - normalisedFatigue)
    --attack term
    local agility = tes3.mobilePlayer.agility.current
    local luck = tes3.mobilePlayer.luck.current
    local attackTerm = ( tes3.mobilePlayer.skills[skill.id + 1].current +  0.2 * agility + 0.1 * luck ) * fatigueTerm
    attackTerm = attackTerm + tes3.mobilePlayer.attackBonus
    attackTerm = attackTerm - tes3.mobilePlayer.blind
    --roll for hit
    local rand = math.random(100)
    local didHit = ( attackTerm > 0 and rand < attackTerm )
    return didHit
end

local function getSkillExperienceBonus(thisSkill)
    local function getGmstForSkill()
        for _, skillId in pairs(tes3.skill) do
            local gmstName = 'fMiscSkillBonus'
            if table.find(tes3.player.object.class.majorSkills, skillId) then
                gmstName = 'fMajorSkillBonus'
            elseif  table.find(tes3.player.object.class.minorSkills, skillId) then
                gmstName = 'fMinorSkillBonus'
            end
            if skillId == thisSkill.id then
                return tes3.findGMST(tes3.gmst[gmstName])
            end
        end
    end
    local gmst = getGmstForSkill()
    return gmst and gmst.value or 1.0
end

local function exerciseWeaponSkill(skill)
    local baseExperience = skill.actions[1]
    local skillBonus = getSkillExperienceBonus(skill)
    local experience = baseExperience * skillBonus
    tes3.mobilePlayer:exerciseSkill(skill.id, experience)
end


--Melee Attacks
local function onAttack(e)
    if e.reference == tes3.player then
        if isPlayerLookingAtDummy() then
            local meleeSkill = getCurrentMeleeSkill()
            if meleeSkill then
                if getHitSuccess(meleeSkill) then
                    exerciseWeaponSkill(meleeSkill)
                    tes3.playSound{ sound = soundIds.hit}
                else
                    tes3.playSound{ sound = soundIds.miss}
                end
            end
        end
    end
end
event.register("attack", onAttack )

--Projectiles
local function onProjectileHitObject(e)
    if e.firingReference == tes3.player then
        if isDummy(e.target) then
            local skill = tes3.getSkill(tes3.skill.marksman)
            if getHitSuccess(skill) then
                exerciseWeaponSkill(skill)
                tes3.playSound{ reference = e.mobile, sound = soundIds.projectile}
            end
        end
    end
end
event.register("projectileHitObject", onProjectileHitObject)