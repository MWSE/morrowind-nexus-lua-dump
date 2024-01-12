local SkillsModule = include("SkillsModule")
if SkillsModule and SkillsModule.registerFortifyEffect then
    SkillsModule.registerFortifyEffect{
        id = "CursedArtistry",
        skill = "painting",
        callback = function()
            local global = tes3.findGlobal("detd_Dressed_Like_Veradul")
            if global then
                if global.value == 1 then
                    return 50
                end
            end
        end
    }
end