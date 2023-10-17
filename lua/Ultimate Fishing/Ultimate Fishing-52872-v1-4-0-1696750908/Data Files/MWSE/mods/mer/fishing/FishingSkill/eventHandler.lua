local FishingSkill = require("mer.fishing.FishingSkill")
local common = include("mer.fishing.common")
local logger = common.createLogger("FishingSkill")
local SkillsModule = include("SkillsModule")

--INITIALISE SKILLS--
local function onSkillsReady()
    logger:debug("Registering %s skill", FishingSkill.config.id)
    SkillsModule.registerSkill(FishingSkill.config)
    for _, modifier in ipairs(FishingSkill.modifiers) do
        logger:debug("Adding modifier: %s", modifier.class)
        SkillsModule.registerClassModifier{
            skill = FishingSkill.config.id,
            class = modifier.class,
            race = modifier.race,
            amount = modifier.amount
        }
    end
end
onSkillsReady()