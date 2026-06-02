-- FailureXPBonus/local.lua
--
-- Attached to every NPC and creature (see FailureXPBonus.omwscripts).
-- When the player attacks this actor and misses, send a 'FailureXPBonus_Miss'
-- event back to the player so the player's script can award skill XP.
--
-- Why a per-actor script?  The engine fires the 'Hit' event (with
-- successful=false on a miss) on the *defender*, not the attacker, so the
-- player has no direct way to learn its own attack missed.  We listen on
-- every potential defender and forward the result.

local I     = require('openmw.interfaces')
local types = require('openmw.types')

-- Map ESM weapon TYPE constants to the OpenMW Lua skill ids (lowercase).
local WEAPON_SKILL = {
    [types.Weapon.TYPE.ShortBladeOneHand] = 'shortblade',
    [types.Weapon.TYPE.LongBladeOneHand]  = 'longblade',
    [types.Weapon.TYPE.LongBladeTwoHand]  = 'longblade',
    [types.Weapon.TYPE.BluntOneHand]      = 'bluntweapon',
    [types.Weapon.TYPE.BluntTwoClose]     = 'bluntweapon',
    [types.Weapon.TYPE.BluntTwoWide]      = 'bluntweapon',
    [types.Weapon.TYPE.SpearTwoWide]      = 'spear',
    [types.Weapon.TYPE.AxeOneHand]        = 'axe',
    [types.Weapon.TYPE.AxeTwoHand]        = 'axe',
    [types.Weapon.TYPE.MarksmanBow]       = 'marksman',
    [types.Weapon.TYPE.MarksmanCrossbow]  = 'marksman',
    [types.Weapon.TYPE.MarksmanThrown]    = 'marksman',
}

local function attackerSkill(attack)
    if attack.weapon then
        local rec = types.Weapon.record(attack.weapon)
        return WEAPON_SKILL[rec.type]
    end
    -- No weapon = unarmed.  Only meaningful for melee; ranged unarmed isn't a
    -- thing in vanilla.
    if attack.sourceType == 'melee' then
        return 'handtohand'
    end
    return nil
end

I.Combat.addOnHitHandler(function(attack)
    -- Need a real attacker, and only the player counts for XP.
    if not attack.attacker then return end
    if attack.attacker.type ~= types.Player then return end

    -- Successes already grant XP through the normal path; we only care about
    -- whiffs.
    if attack.successful then return end

    -- Only weapon misses (melee + ranged).  Magic failures fire elsewhere
    -- and would need a separate hook.
    if attack.sourceType ~= 'melee' and attack.sourceType ~= 'ranged' then
        return
    end

    local skill = attackerSkill(attack)
    if not skill then return end

    attack.attacker:sendEvent('FailureXPBonus_Miss', {
        skill      = skill,
        sourceType = attack.sourceType,
    })
end)
