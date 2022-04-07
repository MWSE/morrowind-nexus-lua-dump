local function exerciseSkillCallback(e)
    e.progress = e.progress * 7000
end
event.register(tes3.event.exerciseSkill, exerciseSkillCallback)
