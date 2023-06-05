local FishingSkill = require("mer.fishing.FishingSkill")
local common = include("mer.fishing.common")
local logger = common.createLogger("FishingSkill")
local skillModule = include("OtherSkills.skillModule")

--INITIALISE SKILLS--
local function onSkillsReady()
    logger:debug("Registering %s skill", FishingSkill.config.id)
    skillModule.registerSkill(FishingSkill.config.id, FishingSkill.config)
end
event.register("OtherSkills:Ready", onSkillsReady)