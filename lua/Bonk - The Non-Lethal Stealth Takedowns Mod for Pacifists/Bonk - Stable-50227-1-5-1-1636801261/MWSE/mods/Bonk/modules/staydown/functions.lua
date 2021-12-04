return function(o)
  function o.down(e)
    if o.conf.down and o.basics(4, nil, e.reference.mobile, e.attacker) then
      o.debug(4, "Invoked successfully")

      e.reference.mobile.inCombat = false

      for actor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
        o.unsafe = actor.inCombat

        if o.unsafe then break end
      end

      for actor in tes3.iterate(tes3.mobilePlayer.hostileActors) do
        o.unsafe = actor.inCombat

        if o.unsafe then break end
      end

      o.debug(4, (o.unsafe and "Some" or "No") .. " actors remain in combat, so player " .. (o.unsafe and "stays in" or "leaves") .. " combat")

      e.reference.mobile.fatigue.current = 0 - o.conf.amount
      e.damage                           = 0
      tes3.mobilePlayer.inCombat         = o.unsafe
      o.unsafe                           = nil
    end
  end

  return o
end