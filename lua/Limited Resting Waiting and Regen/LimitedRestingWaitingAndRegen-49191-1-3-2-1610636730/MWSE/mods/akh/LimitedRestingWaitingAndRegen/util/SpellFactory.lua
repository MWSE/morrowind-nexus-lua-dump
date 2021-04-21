local spellFactory = {}

function spellFactory.createStuntedStatSpell(id, name)

    local stuntedStatSpell = tes3spell.create(id, name)
    if (stuntedStatSpell == nil) then
        stuntedStatSpell = tes3.getObject(id)
    end
    
    stuntedStatSpell.magickaCost = 0
    stuntedStatSpell.castType = tes3.spellType.ability
    stuntedStatSpell.effects[1].id = tes3.effect.eXTRASPELL
    stuntedStatSpell.effects[1].rangeType = tes3.effectRange.self
    stuntedStatSpell.effects[1].min = 0
    stuntedStatSpell.effects[1].max = 0
    stuntedStatSpell.effects[1].duration = 0
    stuntedStatSpell.effects[1].radius = 0
    stuntedStatSpell.effects[1].skill = nil
    stuntedStatSpell.effects[1].attribute = nil

end

return spellFactory