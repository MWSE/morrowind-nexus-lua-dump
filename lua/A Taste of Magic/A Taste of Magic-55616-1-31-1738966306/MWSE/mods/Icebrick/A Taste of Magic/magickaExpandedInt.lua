local framework = include("OperatorJack.MagickaExpanded")
if framework == nil then
    return
end

local function registerSpells (e)
    -- Flame Cloak (Fire Aura) to Marayn Dren.
    local flameCloak = tes3.createObject({ objectType = tes3.objectType.spell }) --[[@as tes3spell]]
    tes3.setSourceless(flameCloak)
    flameCloak.name = "Flame Cloak"
    flameCloak.magickaCost = 45

    local effect = flameCloak.effects[1]
    effect.id = tes3.effect.fireAura
    effect.rangeType = tes3.effectRange.self
    effect.min = 10
    effect.max = 20
    effect.duration = 10
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    -- Charge Item to Arielle Phiencel
    local spell2 = tes3.createObject({ objectType = tes3.objectType.spell }) --[[@as tes3spell]]
    tes3.setSourceless(spell2)
    spell2.name = "Charge Item"
    spell2.magickaCost = 25

    local effect = spell2.effects[1]
    effect.id = tes3.effect.chargeItem
    effect.rangeType = tes3.effectRange.self
    effect.min = 5
    effect.max = 5
    effect.duration = 5
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    -- Charge Weapon to Arielle Phiencel
    local spell3 = tes3.createObject({ objectType = tes3.objectType.spell }) --[[@as tes3spell]]
    tes3.setSourceless(spell3)
    spell3.name = "Charge Weapon"
    spell3.magickaCost = 48

    local effect = spell3.effects[1]
    effect.id = tes3.effect.chargeWeapon
    effect.rangeType = tes3.effectRange.self
    effect.min = 15
    effect.max = 20
    effect.duration = 2
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    -- Piercing Poison to Arielle Phiencel
    local spell4 = tes3.createObject({ objectType = tes3.objectType.spell }) --[[@as tes3spell]]
    tes3.setSourceless(spell4)
    spell4.name = "Inexorable Venom"
    spell4.magickaCost = 90

    local effect = spell4.effects[1]
    effect.id = tes3.effect.poison
    effect.rangeType = tes3.effectRange.touch
    effect.min = 15
    effect.max = 20
    effect.duration = 10
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    local effect = spell4.effects[2]
    effect.id = tes3.effect.pierce
    effect.rangeType = tes3.effectRange.touch
    effect.min = 100
    effect.max = 100
    effect.duration = 1
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    -- Nightblade's Bolt to Orrent Geontene
    local spell5 = tes3.createObject({ objectType = tes3.objectType.spell }) --[[@as tes3spell]]
    tes3.setSourceless(spell5)
    spell5.name = "Nightblade's Bolt"
    spell5.magickaCost = 19

    -- Cost of damage health is 15, cost of Quicken is 11

    local effect = spell5.effects[1]
    effect.id = tes3.effect.damageHealth
    effect.rangeType = tes3.effectRange.target
    effect.min = 10
    effect.max = 15
    effect.duration = 1
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    local effect = spell5.effects[2]
    effect.id = tes3.effect.quicken
    effect.rangeType = tes3.effectRange.target
    effect.min = 35
    effect.max = 35
    effect.duration = 1
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    -- Adds Expose to Orrent Geontene

    local spell6 = tes3.createObject({ objectType = tes3.objectType.spell }) --[[@as tes3spell]]
    tes3.setSourceless(spell6)
    spell6.name = "Expose"
    spell6.magickaCost = 25

    local effect = spell6.effects[1]
    effect.id = tes3.effect.drainDodge
    effect.rangeType = tes3.effectRange.target
    effect.min = 25
    effect.max = 50
    effect.duration = 10
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    -- Adds Long Arm to Heem-La

    local spell7 = tes3.createObject({ objectType = tes3.objectType.spell }) --[[@as tes3spell]]
    tes3.setSourceless(spell7)
    spell7.name = "Long Arm"
    spell7.magickaCost = 20

    local effect = spell7.effects[1]
    effect.id = tes3.effect.extendWeapon
    effect.rangeType = tes3.effectRange.self
    effect.min = 35
    effect.max = 35
    effect.duration = 10
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    -- Adds Swift Arm to Heem-La

    local spell8 = tes3.createObject({ objectType = tes3.objectType.spell }) --[[@as tes3spell]]
    tes3.setSourceless(spell8)
    spell8.name = "Swift Arm"
    spell8.magickaCost = 160

    local effect = spell8.effects[1]
    effect.id = tes3.effect.haste
    effect.rangeType = tes3.effectRange.self
    effect.min = 45
    effect.max = 45
    effect.duration = 10
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    -- Adds Mend Weapon to Sharn gra-Muzgob

    local spell9 = tes3.createObject({ objectType = tes3.objectType.spell }) --[[@as tes3spell]]
    tes3.setSourceless(spell9)
    spell9.name = "Mend Weapon"
    spell9.magickaCost = 50

    local effect = spell9.effects[1]
    effect.id = tes3.effect.repairWeapon
    effect.rangeType = tes3.effectRange.self
    effect.min = 20
    effect.max = 20
    effect.duration = 10
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    -- Adds Reinforce Weapon to Sharn gra-Muzgob

    local spell10 = tes3.createObject({ objectType = tes3.objectType.spell }) --[[@as tes3spell]]
    tes3.setSourceless(spell10)
    spell10.name = "Reinforce Weapon"
    spell10.magickaCost = 35

    local effect = spell10.effects[1]
    effect.id = tes3.effect.unbreakableWeapon
    effect.rangeType = tes3.effectRange.self
    effect.min = 1
    effect.max = 1
    effect.duration = 30
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    -- Frost Cloak to Marayn Dren.
    local spell11 = tes3.createObject({ objectType = tes3.objectType.spell }) --[[@as tes3spell]]
    tes3.setSourceless(spell11)
    spell11.name = "Frost Cloak"
    spell11.magickaCost = 45

    local effect = spell11.effects[1]
    effect.id = tes3.effect.frostAura
    effect.rangeType = tes3.effectRange.self
    effect.min = 10
    effect.max = 20
    effect.duration = 10
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    -- Lightning Cloak to Marayn Dren.
    local spell12 = tes3.createObject({ objectType = tes3.objectType.spell }) --[[@as tes3spell]]
    tes3.setSourceless(spell12)
    spell12.name = "Lightning Cloak"
    spell12.magickaCost = 50

    local effect = spell12.effects[1]
    effect.id = tes3.effect.shockAura
    effect.rangeType = tes3.effectRange.self
    effect.min = 10
    effect.max = 20
    effect.duration = 10
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1

    -- Weakness to Bludgeoning to Eraamion
    local spell13 = tes3.createObject({ objectType = tes3.objectType.spell }) --[[@as tes3spell]]
    tes3.setSourceless(spell13)
    spell13.name = "Dire Weakness to Bludgeoning"
    spell13.magickaCost = 47
        
    local effect = spell13.effects[1]
    effect.id = tes3.effect.weaknessToBludgeoning
    effect.rangeType = tes3.effectRange.target
    effect.min = 2
    effect.max = 60
    effect.duration = 10
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1
        
    -- Weakness to Cutting to Eraamion
    local spell14 = tes3.createObject({ objectType = tes3.objectType.spell }) --[[@as tes3spell]]
    tes3.setSourceless(spell14)
    spell14.name = "Dire Weakness to Cutting"
    spell14.magickaCost = 47
        
    local effect = spell14.effects[1]
    effect.id = tes3.effect.weaknessToCutting
    effect.rangeType = tes3.effectRange.target
    effect.min = 2
    effect.max = 60
    effect.duration = 10
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1
        
    -- Weakness to Piercing to Eraamion
    local spell15 = tes3.createObject({ objectType = tes3.objectType.spell }) --[[@as tes3spell]]
    tes3.setSourceless(spell15)
    spell15.name = "Dire Weakness to Piercing"
    spell15.magickaCost = 47
        
    local effect = spell15.effects[1]
    effect.id = tes3.effect.weaknessToPiercing
    effect.rangeType = tes3.effectRange.target
    effect.min = 2
    effect.max = 60
    effect.duration = 10
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1
        
    -- Strong Resist Bludgeoning to Sharn gra-Muzgob
    local spell16 = tes3.createObject({ objectType = tes3.objectType.spell }) --[[@as tes3spell]]
    tes3.setSourceless(spell16)
    spell16.name = "Strong Resist Bludgeoning"
    spell16.magickaCost = 20
        
    local effect = spell16.effects[1]
    effect.id = tes3.effect.resistBludgeoning
    effect.rangeType = tes3.effectRange.self
    effect.min = 20
    effect.max = 20
    effect.duration = 10
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1
        
    -- Strong Resist Cutting to Sharn gra-Muzgob
    local spell17 = tes3.createObject({ objectType = tes3.objectType.spell }) --[[@as tes3spell]]
    tes3.setSourceless(spell17)
    spell17.name = "Strong Resist Cutting"
    spell17.magickaCost = 20
        
    local effect = spell17.effects[1]
    effect.id = tes3.effect.resistCutting
    effect.rangeType = tes3.effectRange.self
    effect.min = 20
    effect.max = 20
    effect.duration = 10
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1
        
    -- Strong Resist Piercing to Sharn gra-Muzgob
    local spell18 = tes3.createObject({ objectType = tes3.objectType.spell }) --[[@as tes3spell]]
    tes3.setSourceless(spell18)
    spell18.name = "Strong Resist Piercing"
    spell18.magickaCost = 20
        
    local effect = spell18.effects[1]
    effect.id = tes3.effect.resistPiercing
    effect.rangeType = tes3.effectRange.target
    effect.min = 20
    effect.max = 20
    effect.duration = 10
    effect.radius = 0
    effect.skill = -1
    effect.attribute = -1
    
    --MagickaExpanded Integration
    local common = include("OperatorJack.MagickaExpanded.common")
    if common ~= nil then
        --Dumb way to do this but I am LAZY.
        common.addSpellToSpellsList(flameCloak)
        common.addSpellToDistributionList(flameCloak)
        common.addSpellToSpellsList(spell2)
        common.addSpellToDistributionList(spell2)
        common.addSpellToSpellsList(spell3)
        common.addSpellToDistributionList(spell3)
        common.addSpellToSpellsList(spell4)
        common.addSpellToDistributionList(spell4)
        common.addSpellToSpellsList(spell5)
        common.addSpellToDistributionList(spell5)
        common.addSpellToSpellsList(spell6)
        common.addSpellToDistributionList(spell6)
        common.addSpellToSpellsList(spell7)
        common.addSpellToDistributionList(spell7)
        common.addSpellToSpellsList(spell8)
        common.addSpellToDistributionList(spell8)
        common.addSpellToSpellsList(spell9)
        common.addSpellToDistributionList(spell9)
        common.addSpellToSpellsList(spell10)
        common.addSpellToDistributionList(spell10)
        common.addSpellToSpellsList(spell11)
        common.addSpellToDistributionList(spell11)
        common.addSpellToSpellsList(spell12)
        common.addSpellToDistributionList(spell12)
        common.addSpellToSpellsList(spell13)
        common.addSpellToDistributionList(spell13)
        common.addSpellToSpellsList(spell14)
        common.addSpellToDistributionList(spell14)
        common.addSpellToSpellsList(spell15)
        common.addSpellToDistributionList(spell15)
        common.addSpellToSpellsList(spell16)
        common.addSpellToDistributionList(spell16)
        common.addSpellToSpellsList(spell17)
        common.addSpellToDistributionList(spell17)
        common.addSpellToSpellsList(spell18)
        common.addSpellToDistributionList(spell18)
    end
end

event.register("MagickaExpanded:Register", registerSpells)