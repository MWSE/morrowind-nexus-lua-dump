dofile("colossus.spells.elsweyrPortal")
dofile("colossus.spells.reintegrateArmor")
dofile("colossus.spells.reintegrateWeapon")
dofile("colossus.spells.slowTime")

event.register("loaded", function()
    local spell

    spell = tes3.getObject("ggw_reintegrate")
    if spell then
        spell.effects[1].id = tes3.effect.ggwReintegrateArmor
        spell.effects[2].id = tes3.effect.ggwReintegrateWeapon
    end

    spell = tes3.getObject("ggw_create_portal")
    if spell then
        spell.effects[1].id = tes3.effect.ggwElsweyrPortal
        spell.effects[1].duration = 60
    end

    spell = tes3.getObject("ggw_slow_time")
    if spell then
        spell.effects[1].id = tes3.effect.ggwSlowTime
    end
end)
