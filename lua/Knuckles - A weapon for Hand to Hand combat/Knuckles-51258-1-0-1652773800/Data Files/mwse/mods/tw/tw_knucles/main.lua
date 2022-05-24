--- @param e damagedHandToHandEventData
local function tw_damagedHandToHandCallback(e)
    -- Someone other than the player is attacking.
    if (e.reference ~= tes3.player) then       
        return
    end
    
    local equipped = tes3.getEquippedItem({ actor = tes3.player, type = tes3.objectType.weapon })
    if ( equipped ~= nil ) then
      -- if not nil then they are using a weapon ???
      -- it seems handtohand is called even if not just in handtohand !!!
        if ( equipped.object == tes3.objectType.weapon ) then
          -- it also appears can also return none weapon types... i.e. has returned on a common belt!!!
            return
        end
    end
    
    if (e.reference ~= nil) then
      local damage = e.fatigueDamage
      
      if mwscript.hasItemEquipped({reference = tes3.player, item = "tw_knuckle_iron" }) then         
          damage = damage *0.90
        
      elseif mwscript.hasItemEquipped({reference = tes3.player, item = "tw_knuckle_brass" }) then         
          damage = damage * 0.70
          
      else mwscript.hasItemEquipped({reference = tes3.player, item = "tw_knuckle_silver" })        
        -- Make sure that only undead are extra affected.
        local reference = e.attacker
        local mobile = e.mobile
        if (mobile.actorType ~= tes3.actorType.creature or reference.baseObject.type ~= tes3.creatureType.undead) then
          --mwse.log("Not undead....")
          damage = damage * 0.80  
        else
          --mwse.log("Undead....")
          damage = damage * 1.5
        end

      end
      --mwse.log("health before = %s",e.attacker.health.current)
      --damage = math.round(damage,0) -- do we need this ???
      tes3.modStatistic({
          reference = e.attacker,
          name      = "health",
          current   = -damage
      })      
      --mwse.log("health before = %s",e.attacker.health.current)
    end
  --mwse.log(" %s ** %s ** %s ** %s", e.attacker.id, e.fatigueDamage, e.reference.id, e.mobile )
  
end
event.register("damagedHandToHand", tw_damagedHandToHandCallback)
