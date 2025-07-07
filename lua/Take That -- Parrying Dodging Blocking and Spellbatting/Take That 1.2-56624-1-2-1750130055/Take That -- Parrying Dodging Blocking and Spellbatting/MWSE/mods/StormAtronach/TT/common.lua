local common = {}

common.slowedActors = {} -- the key should be a reference, and the fields startTime, duration, typeSlow (1 25% speed reduction, 2 50% speed reduction, 3 75% speed reduction, 4 full stop)
common.parryingActors = {} -- The key should be a reference, and the fields startTime and parry window
common.attacksCounter = {} -- The key should be the os.clock() of the attack. The value should be the reduction factor per instance.
common.config = require("StormAtronach.TT.config")
-- Logging stuff
local log = mwse.Logger.new({
	name = common.config.name,
	level = common.config.log_level,
})

--  Weapon Types
--  These values are available in Lua by their index in the tes3.weaponType table. For example, tes3.weaponType.bluntOneHand has a value of 3.
-- Index	            Value	Description
-- shortBladeOneHand	0	    Short Blade, One Handed
-- longBladeOneHand	    1	    Long Blade, One Handed
-- longBladeTwoClose	2	    Lon Blade, Two Handed
-- bluntOneHand	        3	    Blunt Weapon, One Handed
-- bluntTwoClose	    4   	Blunt Weapon, Two Handed (Warhammers)
-- bluntTwoWide	        5   	Blunt Weapon, Two Handed (Staffs)
-- spearTwoWide	        6   	Spear, Two Handed
-- axeOneHand	        7   	Axe, One Handed
-- axeTwoHand	        8	    Axe, Two Handed
-- marksmanBow	        9	    Marksman, Bows
-- marksmanCrossbow	    10	    Marksman, Crossbow
-- marksmanThrown	    11	    Marksman, Thrown
-- arrow	            12  	Arrows
-- bolt	            13	    Bolts

common.oneHandedWeaponTable = {
       [tes3.weaponType.shortBladeOneHand]  = true,
       [tes3.weaponType.longBladeOneHand]   = true,
       [tes3.weaponType.longBladeTwoClose]  = false,
       [tes3.weaponType.bluntOneHand]       = true,
       [tes3.weaponType.bluntTwoClose]      = false,
       [tes3.weaponType.bluntTwoWide]       = false,
       [tes3.weaponType.spearTwoWide]       = false,
       [tes3.weaponType.axeOneHand]         = true,
       [tes3.weaponType.axeTwoHand]         = false,
       [tes3.weaponType.marksmanBow]        = false,
       [tes3.weaponType.marksmanCrossbow]   = false,
       [tes3.weaponType.marksmanThrown]     = false,
       [tes3.weaponType.arrow]              = false,
       [tes3.weaponType.bolt]               = false,
       ["kungFu"]                           = false,
    }

-- Roll a D20! Well, no, but the same thing. We check the skill level of the equipped weapon or hand to hand
function common.weaponSkillCheck(data)
    -- data.thisMobileActor     : Well, a mobileActor
    -- data.weapon              : And its weapon. Hopefully, a tes3weapon.type. Should be nil if nothing is equipped.
    -- data.valueToCheckAgainst : Pretty self explanatory. Optional
    -- Look, an initialization! How rare to find one in the wild:
    local skillLevel = 0
    local skillDC    = data.valueToCheckAgainst or 0
    local skillList = {
       [tes3.weaponType.shortBladeOneHand]  = tes3.skill.shortBlade,
       [tes3.weaponType.longBladeOneHand]   = tes3.skill.longBlade,
       [tes3.weaponType.longBladeTwoClose]  = tes3.skill.longBlade,
       [tes3.weaponType.bluntOneHand]       = tes3.skill.bluntWeapon,
       [tes3.weaponType.bluntTwoClose]      = tes3.skill.bluntWeapon,
       [tes3.weaponType.bluntTwoWide]       = tes3.skill.bluntWeapon,
       [tes3.weaponType.spearTwoWide]       = tes3.skill.spear,
       [tes3.weaponType.axeOneHand]         = tes3.skill.axe,
       [tes3.weaponType.axeTwoHand]         = tes3.skill.axe,
       [tes3.weaponType.marksmanBow]        = tes3.skill.handToHand,
       [tes3.weaponType.marksmanCrossbow]   = tes3.skill.handToHand,
       [tes3.weaponType.marksmanThrown]     = tes3.skill.handToHand,
       [tes3.weaponType.arrow]              = tes3.skill.handToHand,
       [tes3.weaponType.bolt]               = tes3.skill.handToHand,
       ["kungFu"]                           = tes3.skill.handToHand,
    }
    local weaponType = data.weapon or "kungFu"
    local skillID    = skillList[weaponType] or tes3.skill.handToHand 
    skillLevel = data.thisMobileActor:getSkillValue(skillID)
    log:trace(string.format("Executed weapon skill check: Skill %s, skillDC %s ", skillLevel, skillDC))
    
    local output = {weaponSkill = skillLevel, check = skillLevel >= skillDC, skillID = skillID}

    return output
end



return common