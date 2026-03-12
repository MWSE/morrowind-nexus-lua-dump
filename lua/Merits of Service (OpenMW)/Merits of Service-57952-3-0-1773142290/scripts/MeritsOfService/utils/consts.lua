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
SkillIdToHandler = {
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

SkillIdToName = {
    acrobatics  = "Acrobatics",
    alchemy     = "Alchemy",
    alteration  = "Alteration",
    armorer     = "Armorer",
    athletics   = "Athletics",
    axe         = "Axe",
    block       = "Block",
    bluntweapon = "Blunt Weapon",
    conjuration = "Conjuration",
    destruction = "Destruction",
    enchant     = "Enchant",
    handtohand  = "Hand-to-Hand",
    heavyarmor  = "Heavy Armor",
    illusion    = "Illusion",
    lightarmor  = "Light Armor",
    longblade   = "Long Blade",
    marksman    = "Marksman",
    mediumarmor = "Medium Armor",
    mercantile  = "Mercantile",
    mysticism   = "Mysticism",
    restoration = "Restoration",
    security    = "Security",
    shortblade  = "Short Blade",
    sneak       = "Sneak",
    spear       = "Spear",
    speechcraft = "Speechcraft",
    unarmored   = "Unarmed",
}

---@diagnostic disable-next-line: undefined-field
local attrs = types.NPC.stats.attributes
AttrIdToHandler = {
    strength     = attrs.strength,
    intelligence = attrs.intelligence,
    willpower    = attrs.willpower,
    agility      = attrs.agility,
    speed        = attrs.speed,
    endurance    = attrs.endurance,
    personality  = attrs.personality,
    luck         = attrs.luck,
}

AttrIdToName = {
    strength     = "Strength",
    intelligence = "Intelligence",
    willpower    = "Willpower",
    agility      = "Agility",
    speed        = "Speed",
    endurance    = "Endurance",
    personality  = "Personality",
    luck         = "Luck",
}

RewardTypeToHandler = {
    [SKILL_REWARD]     = SkillIdToHandler,
    [ATTRIBUTE_REWARD] = AttrIdToHandler,
}

LuckRewardTypes = {
    REPLACE = "Replace",
    BONUS   = "Bonus",
}

SwapRewards = {
    [SKILL_REWARD]     = ATTRIBUTE_REWARD,
    [ATTRIBUTE_REWARD] = SKILL_REWARD,
}
