local common = require("OperatorJack.SimpleCombatMechanics.common")
local config = require("OperatorJack.SimpleCombatMechanics.config")


local function getOrientation() 
    local x = math.rad(math.random(75, 100))
    local y = math.rad(math.random(0, 360))
    local z = math.rad(math.random(0, 15))
    if (math.random() > 0.5) then
        z = math.rad(math.random(350, 360))
    end
    return tes3vector3.new(x,y,z)
end

local function getRandomizedPosition(position, isShort)  
    local x = math.random(position.x - 20, position.x + 20)
    local y = math.random(position.y - 20, position.y + 20)
    local z = math.random(position.z + 25, position.z + 40)
    if (isShort == true) then
        z = math.random(position.z + 5, position.z + 10)
    end
    return tes3vector3.new(x,y,z)
end

local function disarmHandToHand(attackerMobile, targetMobile) 
    local weapon = targetMobile.readiedWeapon

    if (weapon == nil) then
        return
    end

    local weaponObject = weapon.object
    local weaponItemData = weapon.itemData


    -- Add reference to target.
    tes3.addItem({
        reference = attackerMobile,
        item = weaponObject,
        itemData = weaponItemData,
        count = 1,
        playSound = false
    })

    targetMobile:unequip(weaponObject)

    -- Remove weapon.
    tes3.removeItem({
        reference = targetMobile,
        item = weaponObject,
        itemData = weaponItemData,
        count = 1,
        playSound = false
    })

    -- Redraw equipment.
    if (attackerMobile ~= tes3.mobilePlayer) then
        attackerMobile.reference:updateEquipment()
    end
    if (targetMobile ~= tes3.mobilePlayer) then
        targetMobile.reference:updateEquipment()
    end
end


local function disarmWeapon(targetMobile) 
    local weapon = targetMobile.readiedWeapon

    if (weapon == nil) then
        return
    end

    local weaponObject = weapon.object
    local weaponItemData = weapon.itemData
    local isShortWeapon = false
    if (weapon.object.type == tes3.weaponType.shortBladeOneHand) then
        isShortWeapon = true
    end
    
    -- Spawn reference nearby.
    local ref = tes3.createReference({
        object  = weaponObject,
        position = getRandomizedPosition(targetMobile.reference.position, isShortWeapon),
        orientation  = getOrientation(),
        cell  = targetMobile.reference.cell,
    })
    ref.itemData = weaponItemData

    targetMobile:unequip(weaponObject)

    -- Remove weapon.
    tes3.removeItem({
        reference = targetMobile,
        item = weaponObject,
        itemData = weaponItemData,
        count = 1,
        playSound = false,
        deleteItemData = false
    })

    -- Redraw equipment.
    if (targetMobile ~= tes3.mobilePlayer) then
        targetMobile.reference:updateEquipment()
    end
end

local function disarm(attackerMobile, targetMobile, attackerHasWeapon) 
    if (attackerHasWeapon) then
        disarmWeapon(targetMobile)
    else
        disarmHandToHand(attackerMobile, targetMobile)
    end
end

local function onAttack(e)
    if (config.enableDisarmament == false) then
        return
    end
    
    -- Ignore swings with no target.
    if (e.targetReference == nil) then
        return
    end

    if (e.targetMobile.readiedWeapon == nil) then
        return
    end

    if (e.targetReference.position:distance(e.reference.position) > config.disarmamentSearchDistance) then
        return
    end

    if (e.mobile.actorType == tes3.actorType.creature) then
        return
    end

    if (e.targetMobile.actorType == tes3.actorType.creature) then
        return
    end

    local attackerMobile = e.mobile
    local targetMobile = e.targetMobile
    local speed = 0
    
    local attackerHasWeapon = true
    if (attackerMobile.readiedWeapon == nil) then
        attackerHasWeapon = false
    end
    
    local targetWeapon = targetMobile.readiedWeapon
    local targetWeaponType = targetWeapon.object.type

    if (common.weaponTypeBlacklist[targetWeaponType]) then
        return
    end

    local targetSkill = attackerMobile[common.skillMappings[targetWeaponType]].current
    local attackerSkill
    if (attackerHasWeapon == true) then
        -- Weapon chance logic.
        local attackerWeapon = attackerMobile.readiedWeapon
        local attackerWeaponType = attackerWeapon.object.type

        if (common.weaponTypeBlacklist[attackerWeaponType]) then
            return
        end

        attackerSkill = attackerMobile[common.skillMappings[targetWeaponType]].current
        speed = attackerWeapon.object.speed
    else
        -- Hand to hand chance logic.
        attackerSkill = attackerMobile.handToHand.current
        speed = 1
    end

    -- Base chance of 5% used for example below.
    local baseChance = config.disarmamentBaseChance
    -- Skill ration based on attacker vs target skill levels. 
    -- Ex: Target with 100 long blade vs Attacker with 25 axe = 4.0 ratio.
    local skillRatio = attackerSkill / targetSkill * 1.0


    -- Calculate modified base chance of disarm. 5% * 4.0 = 20% chance. Possible scenarios:
    -- Attacker | Target | Ratio | Chance
    -- 100    | 5        | 20    | 100
    -- 75     | 25       | 3     | 15
    -- 50     | 50       | 1     | 5
    -- 25     | 75       | .33   | 5 * .33 ~= 1
    -- 20     | 100      | .2    | 1
    local modifiedBaseChance = math.floor(baseChance * skillRatio)

    -- Calculate chance. Caps at 60%.
    local chance = math.min(modifiedBaseChance, config.disarmamentMaxChance)

    common.debug(string.format("Target skill: %s, Attacker Skill: %s, Ratio: %s, Chance: %s", targetSkill, attackerSkill, skillRatio, chance))

    if (math.random(100) > chance) then
        return
    end

    -- We hit someone!
    local duration = 2 * speed
    timer.start({
        duration = duration,
        callback = function()
            disarm(attackerMobile, targetMobile, attackerHasWeapon)
        end
    })
end
event.register("attack", onAttack)