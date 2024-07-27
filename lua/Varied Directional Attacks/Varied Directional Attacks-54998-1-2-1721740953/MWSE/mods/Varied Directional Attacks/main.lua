local name = "Varied Directional Attacks"


local defaults = {
    randomAttack = true,
    bestAttack = true,
    spearAlwaysThrust = false
}
local config = mwse.loadConfig(name, defaults)

event.register(tes3.event.modConfigReady, function()
    local template = mwse.mcm.createTemplate({
        name = name,
        config = config
    })
    template:register()
    template:saveOnClose(name, config)

    local page = template:createPage({ label = "Settings" })
    page:createYesNoButton({ label = "Random directional attacks", configKey = "randomAttack" })
    page:createYesNoButton({ label = "Damage as if using best attack", configKey = "bestAttack" })
    page:createYesNoButton({ label = "Always thrust with spears", configKey = "spearAlwaysThrust" })
end)

local lastAttack

local function selectAttackType(weapon)
    local attackTypes = {
        { type = tes3.physicalAttackType.chop,   damage = weapon.chopMin + weapon.chopMax },
        { type = tes3.physicalAttackType.slash,  damage = weapon.slashMin + weapon.slashMax },
        { type = tes3.physicalAttackType.thrust, damage = weapon.thrustMin + weapon.thrustMax }
    }
    if string.find(weapon.typeName, "Spear") then
        if config.spearAlwaysThrust or lastAttack ~= tes3.physicalAttackType.thrust then
            return tes3.physicalAttackType.thrust
        end
    end

    if string.find(weapon.typeName, "Axe") or string.find(weapon.typeName, "Blunt") then
        attackTypes[3] = nil -- Remove thrust for Axe and Blunt weapons
    end

    local totalDamage = 0
    for _, attack in pairs(attackTypes) do
        if attack and lastAttack ~= attack.type then
            totalDamage = totalDamage + attack.damage
        end
    end

    local randomValue = math.random() * totalDamage
    for _, attack in pairs(attackTypes) do
        if attack and lastAttack ~= attack.type then
            randomValue = randomValue - attack.damage
            if randomValue <= 0 then
                return attack.type
            end
        end
    end
end

event.register(tes3.event.attackStart, function(event)
    if config.randomAttack and event.reference == tes3.player and event.mobile.readiedWeapon and event.mobile.readiedWeapon.object.isMelee then
        event.attackType = selectAttackType(event.mobile.readiedWeapon.object)
        lastAttack = event.attackType
        mwse.log(event.attackType)
    end
end)

event.register(tes3.event.attackHit, function(event)
    if config.bestAttack and event.mobile == tes3.player and event.mobile.readiedWeapon and event.mobile.readiedWeapon.object.isMelee then
        local weapon = event.mobile.readiedWeapon.object
        local chopDamage = weapon.chopMin + weapon.chopMax
        local slashDamage = weapon.slashMin + weapon.slashMax
        local thrustDamage = weapon.thrustMin + weapon.thrustMax

        if chopDamage > slashDamage and chopDamage > thrustDamage then
            event.mobile.actionData.physicalAttackType = tes3.physicalAttackType.chop
        elseif slashDamage > thrustDamage then
            event.mobile.actionData.physicalAttackType = tes3.physicalAttackType.slash
        else
            event.mobile.actionData.physicalAttackType = tes3.physicalAttackType.thrust
        end
        mwse.log(event.mobile.actionData.physicalAttackType)
    end
end)