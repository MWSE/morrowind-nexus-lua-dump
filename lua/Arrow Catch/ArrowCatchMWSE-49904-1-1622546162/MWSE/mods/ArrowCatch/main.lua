local function onDamage(e)

  if e.reference ~= tes3.player then
    return
  end

  if not e.projectile then
    return
  end

  if (e.projectile.reference.object.objectType == tes3.objectType.ammunition) then

    local pShield = tes3.getEquippedItem({
      actor = tes3.player,
      objectType = tes3.objectType.armor,
      slot = tes3.armorSlot.shield
    })

    local pLight = tes3.getEquippedItem({
      actor = tes3.player,
      objectType = tes3.objectType.light
    })

    local pWeapon = tes3.getEquippedItem({
      actor = tes3.player,
      objectType = tes3.objectType.weapon
    })

    if (pShield or pLight or pWeapon) then
      return
    end

    local pAgility = tes3.mobilePlayer.agility.current

    local catchRNG = math.random(100)

    if catchRNG < pAgility then

      local ammo = e.projectile.reference.object.id

      tes3.addItem { reference = tes3.player, item = ammo }

      e.damage = 0

      return false

    end

  end

end
event.register("damage", onDamage)