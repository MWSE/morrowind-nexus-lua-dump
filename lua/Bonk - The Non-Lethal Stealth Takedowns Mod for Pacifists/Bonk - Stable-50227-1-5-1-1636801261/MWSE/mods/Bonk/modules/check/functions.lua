return function(o)
  function o.check(z, r, a)
    if (z == 1 or z == 2 or z == 3 or z == 7) and tes3.mobilePlayer.inCombat then
      o.debug(z, "In combat, aborting")

      return
    end

    if z == 5 then
      o.debug(z, "Check for fatigue level skipped")

    else
      if     (z == 1 or  z == 7) and r.fatigue.current > 0  then
      elseif  Z ~= 1 and z ~= 7  and r.fatigue.current <= 0 then else
        o.debug(z, "Incorrect fatigue level — " .. (r.fatigue.current or "?"))
  
        return
      end
    end

    if (z == 1 or z == 4 or z == 5 or z == 7) and not a then
      o.debug(z, "No attacker")

      return
    end

    if z ~= 1 and z ~= 7 then
      o.debug(z, "Check for attacker skipped")

    else
      if a ~= tes3.player and a ~= tes3.mobilePlayer then
        o.debug(z, "Source of attempted bonk isn't player, aborting")

        return
      end
    end

    local c = (r.object.race and r.object.race.id or "none"):lower():gsub(" ", "")
    local m = (r.object.mesh or                      "none"):lower()

    o.debug(z, "Race is — " .. c)
    o.debug(z, "Mesh is — " .. m)

    if not o.races[c] and not o.meshes[m] then
      o.debug(z, "Not a humanoid/creature")

      return
    end

    if z == 4 or z == 5 then
      o.debug(z, "Checks for stealth/distance skipped")

    elseif tes3.mobilePlayer.isSneaking then
      if tes3ui.findMenu(GUI_Sneak_Multi):findChild(GUI_Sneak_Icon).visible then else
        o.debug(z, "Visible, not sneaking")

        if z == 1 or z == 7 then o.theatrics(0, 6, o.conf.seenText)      else
                                 o.theatrics(0, 6, o.conf.otherSeenText) end

        return
      end

      if tes3.player.position:distance(r.position) <= o.conf.range then else
        o.debug(z, "Not close enough")

        if z == 1 or z == 7 then o.theatrics(0, 6, o.conf.missText)      else
                                 o.theatrics(0, 6, o.conf.otherMissText) end

        return
      end

    else
      o.debug(z, "Player wasn't trying to sneak, aborting at stealth/distance checks")

      return
    end

    if z == 1 or z == 4 or z == 5 then
      local w = tes3.getEquippedItem{actor = a, objectType = tes3.objectType.weapon}

      if w and w.variables.condition <= 0 then
        o.debug(z, "Weapon is broken, aborting")

        if z == 1 and a == tes3.player then o.theatrics(0, 6, o.conf.brokeText) end

        return
      end

      w = w and w.object.type
      w = (w == 3 or w == 4 or w == 5) and "bluntWeapon" or not w and "handToHand" or "invalid"

      o.debug(z, "Readied weapon type — " .. w)

      if w ~= "invalid" then
        o.skill = z == 1 and a == tes3.player and tes3.skill[w] or nil

      else
        o.debug(z, "Incorrect weapon used")

        return
      end

    else
      o.debug(z, "Check for weapon type skipped")
    end

    return true
  end

  return o
end