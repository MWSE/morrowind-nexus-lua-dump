local this = {}

function this.playerUnequipWeapons(target)
    tes3.mobilePlayer:unequip({type=tes3.objectType.weapon})
end

function this.exerciseSkill(name, progress)
    local skill = table.find(tes3.skillName, name)
    if skill then
        tes3.mobilePlayer:exerciseSkill(skill, progress)
        tes3.messageBox("Your %s skill has progressed.", name)
    end
end

event.register("dialogueEnvironmentCreated", function(e)
    this.env = e.environment
    e.environment.bdc = this
end)
