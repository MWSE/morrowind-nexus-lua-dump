local twoHandedWeapons = {
	[tes3.weaponType.longBladeTwoClose] = true,
	[tes3.weaponType.bluntTwoClose] = true,
	[tes3.weaponType.bluntTwoWide] = true,
	[tes3.weaponType.spearTwoWide] = true,
	[tes3.weaponType.axeTwoHand] = true,
	[tes3.weaponType.marksmanBow] = true,
	[tes3.weaponType.marksmanCrossbow] = true,
}

local function onDamage(e)

  if not e.projectile then
    return
  end

  if e.mobile.actorType < 1 then
    return
  end

  if not e.mobile.weaponDrawn then
    return
  end

  if not e.projectile.reference.object.objectType == tes3.objectType.weapon then
    return
  end

  if e.mobile.readiedWeapon == nil then

    local eAgility = e.mobile.agility.current

    local catchRNG = math.random(100)

    if catchRNG < eAgility then

      local eProjectile = e.projectile.reference.object.id

      tes3.addItem { reference = e.mobile, item = eProjectile }

    end

  else

    local eShield = tes3.getEquippedItem({
      actor = e.mobile,
      objectType = tes3.objectType.armor,
      slot = tes3.armorSlot.shield
    })

    if not eShield then
      return
    end

    if e.mobile.readiedWeapon == twoHandedWeapons then
      return
    end

    local eAgility = e.mobile.agility.current

    local blockRNG = math.random(100)

    if blockRNG < eAgility then

      local eProjectile = e.projectile.reference.object.id

      tes3.addItem { reference = e.mobile, item = eProjectile }

      tes3.dropItem { reference = e.mobile, item = eProjectile }

    end

  end

  e.damage = 0

  return false

end

event.register("damage", onDamage)