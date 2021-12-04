return function(o)
  function o.bonk(e)
    if o.basics(1, nil, e.targetMobile, e.attacker) then
      local h       = tes3.getEquippedItem{actor = e.targetMobile, objectType = tes3.objectType.armor, slot = tes3.helmet}
      local k, w, r = not h

      if h then
        w = h.object.weightClass
        w = w == 0 and "light" or w == 1 and "medium" or w == 2 and "heavy" or "?"
        r = math.random(100) + math.floor(tes3.mobilePlayer.luck.current / o.conf.fraction)
        k = r > o.conf[w]
      end

      o.debug(1, "Helm check " .. (k and "passed" or "failed") .. (h and ". Helm weight class is " .. w .. ", base requirement of " .. o.conf[w] .. ", random of " .. r or ""))

      if k then
        o.debug(1, "Knockout succeeded")

        o.theatrics(2, 1)

        if o.conf.gain > 0 then
          o.debug(1, "Gained " .. o.conf.gain/10 .. " skill points")

          tes3.mobilePlayer:exerciseSkill(o.skill, o.conf.gain/10)
        end

        o.skill                        = nil
        e.hitChance                    = 0
        e.targetMobile.fatigue.current = 0 - o.conf.amount

        if o.conf.exit then
          o.debug(1, "Combat halted")

          for actor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
            actor:stopCombat(true)
          end

          for actor in tes3.iterate(tes3.mobilePlayer.hostileActors) do
            actor:stopCombat(true)
          end
        end

        event.trigger("Pickpocket:ShowFullMenu")
        o.debug(1, "Pickpocket menu shown")

      else
        o.debug(1, "Knockout failed")

        o.theatrics(0, 6, o.conf.knockText)
      end
    end
  end

  return o
end