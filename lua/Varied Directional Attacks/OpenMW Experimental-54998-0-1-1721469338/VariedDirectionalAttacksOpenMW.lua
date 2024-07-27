-- Varied Directional Attacks (OpenMW Version)
local name = "Varied Directional Attacks"

local defaults = {
    randomAttack = true,
    bestAttack = true,
    spearAlwaysThrust = false
}

local configFile = string.format("%s/My Games/OpenMW/config/%s.cfg", os.getenv("USERPROFILE"), name)
local config = mwscript.loadConfig(configFile, defaults)

local lastAttack

local function selectAttackType(weapon)
    mwscript.log("Debug: selectAttackType called")  -- Start of function logging

    local attackTypes = {
        { type = tes3.attackType.chop,   damage = weapon.chopMin + weapon.chopMax },
        { type = tes3.attackType.slash,  damage = weapon.slashMin + weapon.slashMax },
        { type = tes3.attackType.thrust, damage = weapon.thrustMin + weapon.thrustMax }
    }

    -- Special handling for spears
    local weaponType = weapon.object.type
    mwscript.log(string.format("Debug: Weapon type is %s", weaponType))

    if weaponType == tes3.weaponType.spear then
        mwscript.log("Debug: Spear weapon detected")
        if config.spearAlwaysThrust or lastAttack ~= tes3.attackType.thrust then
            mwscript.log("Debug: Returning thrust attack for spear")
            return tes3.attackType.thrust
        end
    end

    -- Remove invalid attacks based on weapon type
    if weaponType == tes3.weaponType.axe or weaponType == tes3.weaponType.bluntWeapon then
        mwscript.log("Debug: Removing thrust attack for axe or blunt weapon")
        attackTypes[3] = nil
    elseif weaponType == tes3.weaponType.spear then
        mwscript.log("Debug: Removing chop and slash attacks for spear")
        attackTypes[1] = nil
        attackTypes[2] = nil
    end

    -- ... (the rest of the attack selection logic remains the same, but you can add more logs if needed)
end

local function onAttackStart(e)
    mwscript.log("Debug: onAttackStart called")
    if config.randomAttack and e.attacker == tes3.player and e.attacker.weapon then
        mwscript.log("Debug: Random attack enabled")
        e.attackType = selectAttackType(e.attacker.weapon)
        lastAttack = e.attackType
        mwscript.log(string.format("Debug: Attack type set to %s", e.attackType))
    end
end

local function onAttackHit(e)
    mwscript.log("Debug: onAttackHit called")
    -- ... (the rest of this function remains the same, but you can add logs as needed)
end

mwscript.registerEvent(tes3.event.attack, onAttackStart, {filter = "start"})
mwscript.registerEvent(tes3.event.attack, onAttackHit, {filter = "hit"})