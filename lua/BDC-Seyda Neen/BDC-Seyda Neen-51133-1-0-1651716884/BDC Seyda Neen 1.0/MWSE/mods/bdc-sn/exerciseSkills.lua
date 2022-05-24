mwse.overrideScript("ek_bdc_exercise_skills", function(e)
    for name, skill in pairs(tes3.skill) do
        local value = e.script.context[name]
        if not math.isclose(value, 0.0) then
            tes3.mobilePlayer:exerciseSkill(skill, value)
            tes3.messageBox("%s progress gained", tes3.skillName[skill])
            e.script.context[name] = 0.0
        end
    end
    mwscript.stopScript{script="ek_bdc_exercise_skills"}
end)
