local SkillService = include("mer.joyOfPainting.services.SkillService")
local common = include("mer.joyOfPainting.common")
local config = include("mer.joyOfPainting.config")
local logger = common.createLogger("InitSkills")
--[[
    Skills
]]
local skillModule = include("OtherSkills.skillModule")

--INITIALISE SKILLS--
local function onSkillsReady()
    for skill, data in pairs(config.skills) do
        data = table.deepcopy(data)
        logger:debug("Registering %s skill", skill)
        skillModule.registerSkill(data.id, data)
        SkillService.skills[skill] = skillModule.getSkill(data.id)
    end
    logger:info("JoyOfPainting skills registered")
end
event.register("OtherSkills:Ready", onSkillsReady)