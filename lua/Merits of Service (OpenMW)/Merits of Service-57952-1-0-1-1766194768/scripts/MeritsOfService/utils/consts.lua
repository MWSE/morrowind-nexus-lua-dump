local types = require("openmw.types")

SKILL_REWARD = "skills"
ATTRIBUTE_REWARD = "attributes"

CompletedQuests = {
    -- factionName = {
    --     count = 0,
    --     quests = {
    --         questId_1 = true,
    --         questId_2 = true,
    --     }
    -- }
}

local skills = types.NPC.stats.skills
-- use it as a skill names reference for guild yamls
SkillNameToHandler = {
    acrobatics  = skills.acrobatics,
    alchemy     = skills.alchemy,
    alteration  = skills.alteration,
    armorer     = skills.armorer,
    athletics   = skills.athletics,
    axe         = skills.axe,
    block       = skills.block,
    bluntweapon = skills.bluntweapon,
    conjuration = skills.conjuration,
    destruction = skills.destruction,
    enchant     = skills.enchant,
    handtohand  = skills.handtohand,
    heavyarmor  = skills.heavyarmor,
    illusion    = skills.illusion,
    lightarmor  = skills.lightarmor,
    longblade   = skills.longblade,
    marksman    = skills.marksman,
    mediumarmor = skills.mediumarmor,
    mercantile  = skills.mercantile,
    mysticism   = skills.mysticism,
    restoration = skills.restoration,
    security    = skills.security,
    shortblade  = skills.shortblade,
    sneak       = skills.sneak,
    spear       = skills.spear,
    speechcraft = skills.speechcraft,
    unarmored   = skills.unarmored,
}

local attrs = types.NPC.stats.attributes
AttrNameToHandler = {
    strength     = attrs.strength,
    intelligence = attrs.intelligence,
    willpower    = attrs.willpower,
    agility      = attrs.agility,
    speed        = attrs.speed,
    endurance    = attrs.endurance,
    personality  = attrs.personality,
    luck         = attrs.luck,
}

RewardTypeToHandler = {
    [SKILL_REWARD]     = SkillNameToHandler,
    [ATTRIBUTE_REWARD] = AttrNameToHandler,
}

LuckRewardTypes = {
    REPLACE = "Replace",
    BONUS   = "Bonus",
}