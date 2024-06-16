local formulas = require("Equipment and Items Requirements Overhaul.helpers.formulas")

local typeToFormula = {
    LongBladeOneHand = formulas.LongBladeOneHand,
    LongBladeTwoClose = formulas.LongBladeTwoClose,
    MarksmanThrown = formulas.MarksmanThrown,
    MarksmanBow = formulas.MarksmanBow,
    MarksmanCrossbow = formulas.MarksmanCrossbow,
    BluntOneHand = formulas.BluntOneHand,
    BluntTwoClose = formulas.BluntTwoClose,
    BluntTwoWide = formulas.BluntTwoWide,
    ShortBladeOneHand = formulas.ShortBladeOneHand,
    SpearTwoWide = formulas.SpearTwoWide,
    AxeOneHand = formulas.AxeOneHand,
    AxeTwoClose = formulas.AxeTwoClose,
    Arrow = formulas.Arrow,
    Bolt = formulas.Bolt,
    lightArmor = formulas.lightArmor,
    mediumArmor = formulas.mediumArmor,
    heavyArmor = formulas.heavyArmor,
    --other Items:
    clothing = formulas.clothing,
    alchemy = formulas.alchemy,
    book = formulas.book,
    lockpick = formulas.lockpick,
    probe = formulas.probe,
    apparatus = formulas.apparatus,
    spell = formulas.spell,
    repairItem = formulas.repairItem,
    -- Ensure any other missing mappings are added here
    enchantment = formulas.enchanted,
}

local attributeSkillMapping = {
    Strength = function() return tes3.mobilePlayer.strength and tes3.mobilePlayer.strength.current or 0 end,
    Intelligence = function() return tes3.mobilePlayer.intelligence and tes3.mobilePlayer.intelligence.current or 0 end,
    Willpower = function() return tes3.mobilePlayer.willpower and tes3.mobilePlayer.willpower.current or 0 end,
    Agility = function() return tes3.mobilePlayer.agility and tes3.mobilePlayer.agility.current or 0 end,
    Speed = function() return tes3.mobilePlayer.speed and tes3.mobilePlayer.speed.current or 0 end,
    Endurance = function() return tes3.mobilePlayer.endurance and tes3.mobilePlayer.endurance.current or 0 end,
    Personality = function() return tes3.mobilePlayer.personality and tes3.mobilePlayer.personality.current or 0 end,
    Luck = function() return tes3.mobilePlayer.luck and tes3.mobilePlayer.luck.current or 0 end,

    -- Skills
    ["Long Blade"] = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.longBlade) or 0 end,
    Marksman = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.marksman) or 0 end,
    ["Blunt Weapon"] = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.bluntWeapon) or 0 end,
    ["Heavy Armor"] = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.heavyArmor) or 0 end,
    ["Medium Armor"] = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.mediumArmor) or 0 end,
    ["Spear"] = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.spear) or 0 end,
    Axe = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.axe) or 0 end,
    Block = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.block) or 0 end,
    Armorer = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.armorer) or 0 end,
    Athletics = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.athletics) or 0 end,
    Acrobatics = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.acrobatics) or 0 end,
    ["Light Armor"] = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.lightArmor) or 0 end,
    ["Short Blade"] = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.shortBlade) or 0 end,
    Sneak = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.sneak) or 0 end,
    ["Hand-to-hand"] = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.handToHand) or 0 end,
    Security = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.security) or 0 end,
    Mercantile = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.mercantile) or 0 end,
    Speechcraft = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.speechcraft) or 0 end,
    Alchemy = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.alchemy) or 0 end,
    Alteration = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.alteration) or 0 end,
    Conjuration = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.conjuration) or 0 end,
    Destruction = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.destruction) or 0 end,
    Enchant = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.enchant) or 0 end,
    Illusion = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.illusion) or 0 end,
    Mysticism = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.mysticism) or 0 end,
    Restoration = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.restoration) or 0 end,
    ["Unarmored"] = function() return tes3.mobilePlayer:getSkillValue(tes3.skill.unarmored) or 0 end,
}


return {
    attributeSkillMapping = attributeSkillMapping,
    typeToFormula = typeToFormula
}
