return function(o)
  function o.check(z, r, a)
    if z == 1 and o.conf.crouch and not tes3.mobilePlayer.isSneaking then
      o.debug(z, "Crouch option is selected and the player isn't crouching, aborting")

      return
    end

    if r.actorType ~= 0 then
      o.debug(z, "Target isn't a critter")

      return
    end

    if r.fatigue.current <= 0 then
      o.debug(z, "Target is unconscious")

      return
    end

    if z == 6 and not a then
      o.debug(z, "No attacker")

      return
    end

    o.cid = r.object.id

    o.debug(z, o.cid and "Creating entries for ID " .. o.cid or "Entity has no ID")

    if not o.cid then return end

    if not o.info[o.cid] then
      local m = (r.object.mesh or "none"):lower()
      local n = r.object.name:lower()
      local t = o.meshes[m]

      o.debug(z, "~ Name — " .. n or "nil")
      o.debug(z, "~ Mesh — " .. m or "nil")
      o.debug(z, "~ Type — " .. t or "invalid")

      if not n or not m or not t then return end

      o.info[o.cid] = {
        name        = n,
        type        = t
      }

      o.debug(z, "Created new critter info entry")

    else
      o.debug(z, "Using existing critter info entry")
    end

    local fi = r.fight

    if not o.stats[o.cid] then
      local fl = r.flee

      o.debug(z, "~ Fight - " .. fi or "nil")
      o.debug(z, "~ Flee  - " .. fl or "nil")

      if not fi or not fl then return end

      o.stats[o.cid] = {
        fight        = fi,
        flee         = fl
      }

      mwse.saveConfig("FeedbagData", o.stats)

      o.debug(z, "Created new critter stats entry")

    else
      o.debug(z, "Using existing critter stats entry")
    end

    o.info[o.cid].trust = fi == 0

    return true
  end

  return o
end