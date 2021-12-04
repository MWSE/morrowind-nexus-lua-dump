return function(o)
  local major = "1.3"
  local minor = "1"

  function o.loaded()
    o.go = true
  end

  function o.basics(z, k, r, a, ovr)
    if not o.go then
      o.debug(z, "Game isn't loaded, aborting")

      return
    end

    if k and o.pressed and not o.pressed(z, k) then
      return
    end

    ovr = ovr or {}

    if not ovr.combat and not r and tes3.mobilePlayer.inCombat and o.scan then
      o.debug(z, "Player is in combat, requesting rayscan reference")
      o.scan()
    end

    r = r or o.ref

    if not r then
      o.debug(z, "Entity does not exist, aborting")

      return
    end

    if not ovr.disabled and r.disabled then
      o.debug(z, "Entity is disabled, aborting")

      return
    end

    if not ovr.deleted and r.deleted then
      o.debug(z, "Entity is deleted, aborting")

      return
    end

    if not ovr.health and r.health.current <= 0 then
      o.debug(z, "Entity is dead, aborting")
      return
    end

    local t = r.actorType

    o.debug(z, "Actor is " .. (t == 0 and "creature" or t == 1 and "NPC" or t == 2 and "player" or "nil"))

    if a then
      t = a.actorType

      o.debug(z, "Attacker is " .. (t == 0 and "creature" or t == 1 and "NPC" or t == 2 and "player" or "nil"))
    end

    if not ovr.check and o.check and not o.check(z, r, a) then
      o.debug(z, "Check function returned false, aborting")

      return
    end

    return true
  end

  return o, major, minor
end