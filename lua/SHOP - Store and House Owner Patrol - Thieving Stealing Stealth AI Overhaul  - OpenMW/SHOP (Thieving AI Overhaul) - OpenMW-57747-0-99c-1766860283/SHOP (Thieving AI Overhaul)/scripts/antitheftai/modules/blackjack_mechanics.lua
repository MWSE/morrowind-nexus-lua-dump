local types = require('openmw.types')
local core = require('openmw.core')

local mechanics = {}

-- Constant penalties per armor piece
-- Weight Classes: 0=Light, 1=Medium, 2=Heavy
local ARMOR_WEIGHT_LIGHT = 0
local ARMOR_WEIGHT_MEDIUM = 1
local ARMOR_WEIGHT_HEAVY = 2

local PENALTIES_BY_SLOT = {
    [types.Actor.EQUIPMENT_SLOT.Helmet] = {
        [ARMOR_WEIGHT_LIGHT] = 5,
        [ARMOR_WEIGHT_MEDIUM] = 10,
        [ARMOR_WEIGHT_HEAVY] = 15
    },
    [types.Actor.EQUIPMENT_SLOT.Cuirass] = {
        [ARMOR_WEIGHT_LIGHT] = 5,
        [ARMOR_WEIGHT_MEDIUM] = 10,
        [ARMOR_WEIGHT_HEAVY] = 15
    }
}

-- List of weighted blackjacks for stun duration bonus
local WEIGHTED_BLACKJACKS = {
    ['blackjack-wooden-weighted'] = true,
    ['blackjack-iron-weighted'] = true,
    ['blackjack-imperial-weighted'] = true,
    ['blackjack-dwemer-weighted'] = true
}

-- Calculate stun chance based on attacker stats and victim/armor
function mechanics.calculateStunChance(attacker, victim, levelDiffPenalty)
    if not attacker or not victim then return 0 end

    -- 1. Base Stats (Average of Strength, Sneak, and Blunt/Hand-to-Hand)
    local str = types.Actor.stats.attributes.strength(attacker).modified
    
    -- Check if attacker has a weapon equipped
    local hasWeapon = false
    if types.Actor.getEquipment then
        local equipment = types.Actor.getEquipment(attacker)
        hasWeapon = equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight] ~= nil
    end
    
    -- Using skills for Player or NPC
    local sneak, blunt
    if attacker.type == types.Player then
        sneak = types.Player.stats.skills.sneak(attacker).modified
        -- Use hand-to-hand if no weapon equipped, otherwise use blunt weapon
        if hasWeapon then
            blunt = types.Player.stats.skills.bluntweapon(attacker).modified
        else
            blunt = types.Player.stats.skills.handtohand(attacker).modified
        end
    else
        sneak = types.NPC.stats.skills.sneak(attacker).modified
        -- Use hand-to-hand if no weapon equipped, otherwise use blunt weapon
        if hasWeapon then
            blunt = types.NPC.stats.skills.bluntweapon(attacker).modified
        else
            blunt = types.NPC.stats.skills.handtohand(attacker).modified
        end
    end
    
    -- Formula: Average of the three stats
    -- Max possible average is 100 (if all are 100)
    local baseChance = (str + sneak + blunt) / 2

    -- 2. Level Difference Penalty
    -- User: each level NPC is higher than player reduces chance by 1%
    local PenaltyLevel = 0
    local attackerLevel = types.Actor.stats.level(attacker).current
    local victimLevel = types.Actor.stats.level(victim).current
    if victimLevel > attackerLevel then
        PenaltyLevel = (victimLevel - attackerLevel) * 1  -- 1% per level
    end

    -- 3. Armor Penalties
    local PenaltyArmor = 0
    if types.Actor.getEquipment then 
        local equipment = types.Actor.getEquipment(victim)
        
        -- Check specific slots we care about
        for slot, penalties in pairs(PENALTIES_BY_SLOT) do
            local item = equipment[slot]
            if item and item.type == types.Armor then
                local record = types.Armor.record(item)
                if record then
                    local weightClass = record.weightClass -- 0, 1, 2
                    if penalties[weightClass] then
                        PenaltyArmor = PenaltyArmor + penalties[weightClass]
                    end
                end
            end
        end
    end

    -- 4. Final Calculation
    local finalChance = baseChance - PenaltyLevel - PenaltyArmor
    
    -- Clamp 0-100
    if finalChance < 0 then finalChance = 0 end
    if finalChance > 100 then finalChance = 100 end

    return finalChance
end

-- Calculate duration based on stats
-- Max amount reached upon getting 100 stats
-- Base max is 100s/units? User said "max amount is reached upon... 100... make it so max value equals 100 or more"
-- Original script had : (Str + Sneak + Blunt) * 0.1 +/- 15%. Max (100+100+100)*0.1 = 30s.
-- User wants "max value equals 100 or more".
-- Let's change multiplier to 0.334? (300 * x = 100 => x = 0.333)
-- So (Sum of Stats) / 3 = Average.
-- If Average is 100, Duration is 100.
-- If Average is 100, Duration is 100.
function mechanics.calculateDuration(attacker, weaponId, maxDuration)
    local str = types.Actor.stats.attributes.strength(attacker).modified
    
    -- Check if attacker has a weapon equipped
    local hasWeapon = false
    if types.Actor.getEquipment then
        local equipment = types.Actor.getEquipment(attacker)
        hasWeapon = equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight] ~= nil
    end
    
    local sneak, blunt
    if attacker.type == types.Player then
        sneak = types.Player.stats.skills.sneak(attacker).modified
        -- Use hand-to-hand if no weapon equipped, otherwise use blunt weapon
        if hasWeapon then
            blunt = types.Player.stats.skills.bluntweapon(attacker).modified
        else
            blunt = types.Player.stats.skills.handtohand(attacker).modified
        end
    else
        sneak = types.NPC.stats.skills.sneak(attacker).modified
        -- Use hand-to-hand if no weapon equipped, otherwise use blunt weapon
        if hasWeapon then
            blunt = types.NPC.stats.skills.bluntweapon(attacker).modified
        else
            blunt = types.NPC.stats.skills.handtohand(attacker).modified
        end
    end

    -- Formula: Average of stats = Duration in seconds
    -- If all 100 -> 100/3 * 3 = 100? No, just Sum/3.
    local baseDuration = (str + sneak + blunt) / 3

    -- Apply Random Variance (+/- 15%)
    local variance = (math.random() * 0.30) - 0.15 -- -0.15 to +0.15
    local duration = baseDuration * (1.0 + variance)

    -- Apply Weighted Bonus (+15%)
    if weaponId and WEIGHTED_BLACKJACKS[weaponId] then
        duration = duration * 1.15
    end
    
    -- Ensure maxDuration is valid number (default 45 if nil)
    local cap = maxDuration or 45

    if duration < 0 then duration = 0 end
    if duration > cap then duration = cap end
    
    return duration
end

return mechanics
