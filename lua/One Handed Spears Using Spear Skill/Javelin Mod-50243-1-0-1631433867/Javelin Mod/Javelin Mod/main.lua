local weaponType = false

local javelinIDs = { "chitin javelin", "steel javelin", "silver javelin", "dwarven javelin", "ebony javelin", "deadric javelin", "iron javelin" }

local function findMatchesInArray(j)

    for _,i in pairs(javelinIDs) do
        if i == j then
            return true
        end
    end
end

local function checkEquipmentOnWeaponReadied(e)

    if (e.reference ~= tes3.player) then
        return
        --print("not you")
    end

    --print("it is you")

    local weaponStack = e.weaponStack

    if (weaponStack and weaponStack.object.isOneHanded) then
        if findMatchesInArray(weaponStack.object.id) then
            weaponType = true
            --print("weapon is a javelin")
        else
            weaponType = false
            --print("weapon is not a javelin")
        end
    else
        weaponType = false
        --print("weapon is not one handed")
    end
end

--in game events
local function onExerciseSkill(e) -- exercise spear skill instead of long blade for javelins

    if ( weaponType and e.skill == 5 ) then
        --print("weapon recognized")
        tes3.mobilePlayer:exerciseSkill(7, 2)
        return false
    end
    --print("not the right skill. This is " .. tostring(e.skill) )
end

local function onCalcHitChance(e) -- calculating the hit chance based on new skill

    local playerHitChance
    local targetEvasionChance

    local function calcPlayerHitChance()
        local playerLuck = tes3.mobilePlayer.luck.current
        local playerAgility = tes3.mobilePlayer.agility.current
        local weaponSkill = tes3.mobilePlayer.spear.current
        local playerFatigueCurrent = tes3.mobilePlayer.fatigue.current
        local playerFatigueMax = tes3.mobilePlayer.fatigue.base
        local fortifyAttackValue = tes3.getEffectMagnitude{reference = tes3.mobilePlayer, effect = tes3.effect.fortifyAttack}
        local blindValue = tes3.getEffectMagnitude{reference = tes3.mobilePlayer, effect = tes3.effect.blind}
        playerHitChance = (weaponSkill + (playerAgility / 5) + (playerLuck / 10)) * (0.75 + (0.5 * (playerFatigueCurrent / playerFatigueMax))) + fortifyAttackValue - blindValue

        return playerHitChance
    end

    local function calcTargetEvasionChance()

        local actorLuck = e.targetMobile.luck.current
        local actorAgility = e.targetMobile.agility.current
        local actorFatigueCurrent = e.targetMobile.fatigue.current
        local actorFatigueMax = e.targetMobile.fatigue.base
        local actorSanctuaryValue = tes3.getEffectMagnitude{reference = e.targetMobile, effect = tes3.effect.sanctuary}
        targetEvasionChance = (actorAgility / 5) + (actorLuck / 10) * (0.75 + (0.5 * (actorFatigueCurrent / actorFatigueMax))) + actorSanctuaryValue

        return targetEvasionChance
    end

    if weaponType then
        if e.targetMobile ~= nil and e.attackerMobile == tes3.mobilePlayer then
            e.hitChance = calcPlayerHitChance() - calcTargetEvasionChance()
        end
    end
end

local function onInitialized()
        
    print("initialized successfully - Javelin")
    event.register("weaponReadied", checkEquipmentOnWeaponReadied)
    event.register("exerciseSkill", onExerciseSkill)
    event.register("calcHitChance", onCalcHitChance)
end

event.register("initialized", onInitialized)