return function(o)
  function o.spell(e)
    if o.conf.disableSpell then return end

    local c    = e.caster.mobile
    local s, z = e.source

    for i = 1, #s.effects do
      z = o.effects[s.effects[i].id]

      if z then break end
    end

    if o.basics(7, nil, o.ref, c) and z then
      local pw = c.willpower.current
      local fw = o.ref.willpower.current
      local pr = pw + math.random(o.conf.playerRand)
      local fr = fw + math.random(o.conf.foeRand)
      o.gmst   = tes3.findGMST("sMagicSkillFail").value

      if pw > fw then
        o.debug(7, "Knockout succeeded")

        if o.conf.exit then
          tes3.findGMST("sMagicSkillFail").value = o.conf.spellSucceedText

        else
          o.theatrics(0, 7, o.conf.spellSucceedText)
        end

        if o.conf.gain > 0 then
          o.debug(7, "Gained " .. o.conf.gain/10 .. " skill points")

          tes3.mobilePlayer:exerciseSkill(tes3.magicSchoolSkill[e.expGainSchool], o.conf.gain/10)
        end

        e.castChance          = o.conf.exit and 0 or 100
        o.ref.fatigue.current = 0 - o.conf.amount

        event.trigger("Pickpocket:ShowFullMenu")
        o.debug(7, "Pickpocket menu shown")

      else
        o.debug(7, "Knockout failed")

        if o.conf.exit then
          tes3.findGMST("sMagicSkillFail").value = o.conf.spellFailText

        else
          o.theatrics(0, 7, o.conf.spellFailText)
        end
      end
    end
  end

  function o.spellFail()
    if o.gmst then
      tes3.findGMST("sMagicSkillFail").value = o.gmst
      o.gmst                                 = nil
    end
  end

  return o
end