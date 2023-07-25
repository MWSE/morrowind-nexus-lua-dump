local SkillService = require("mer.joyOfPainting.services.SkillService")
event.register("UIEXP:sandboxConsole", function(e)
    e.sandbox.jop = {
        skills = SkillService.skills
    }

end)