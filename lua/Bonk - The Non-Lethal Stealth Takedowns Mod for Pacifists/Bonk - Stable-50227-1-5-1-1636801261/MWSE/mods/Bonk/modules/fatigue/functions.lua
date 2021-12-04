return function(o)
  function o.tick()
    o.skip = (o.skip or 0) + 1

    if o.skip < 3 then return else o.skip = nil end

    for k, v in pairs(o.fdb) do k.fatigue.current = v end

    o[tes3.mobilePlayer.inCombat and "tick" or "handler"]()
  end

  function o.handler(e)
    if not o.conf.regen then return end

    o.debug(5, "St" .. (e and "art" or "opp") .. "ed timer tick")

    o.fdb = e and {} or nil

    if e then o.tick() end
  end

  function o.fatigue(e)
    local r = e.reference.mobile

    if o.conf.fatigue and o.basics(5, nil, r, e.attacker) then
      if not o.fdb then o.handler(true) end

      local d  = e.damage * o.conf.mult
      o.fdb[r] = r ~= tes3.mobilePlayer and r.fatigue.current - d or nil
      e.damage = 0
      e.claim  = o.conf.claim

      o.debug(5, "Damage prevented")
      o.debug(5, "Fatigue damage done — " .. d)

      r:applyFatigueDamage(d)
    end
  end

  return o
end