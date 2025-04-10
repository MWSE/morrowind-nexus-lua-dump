local function onDamage(e)
    

    -- Check if the damage was caused by an attack
    if e.source ~= tes3.damageSource.attack then
        
        return
    end

 

    -- Adjust damage based on armor rating

    e.damage = e.damage - e.mobile.armorRating

    if e.damage < 1 then
        e.damage = 1
      
        
    end


end

event.register(tes3.event.damage, onDamage)
