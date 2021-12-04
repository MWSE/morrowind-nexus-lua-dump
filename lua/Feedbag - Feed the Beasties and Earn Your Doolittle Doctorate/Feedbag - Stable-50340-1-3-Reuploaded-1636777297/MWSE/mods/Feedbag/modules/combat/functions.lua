return function(o)
  function o.endCombat()
    local d = o.info[o.cid]

    if o.ref.fight > 0 then
      o.debug(2, "Fight stat still > 0, combat continues")

      o.message = o.message .. " " .. o.conf.sickText

    elseif d.trust then
      o.debug(2, "This shouldn't happen. The " .. d.name:lower() .. "'s trust flag is set but they're still in combat. Let's take them out of combat")
      o.ref:stopCombat(true)

    elseif not d.trust then
      local r = math.random(100)
      local l = math.floor(tes3.mobilePlayer.luck.current        / o.conf.luck)
      local p = math.floor(tes3.mobilePlayer.personality.current / o.conf.personality)
      r       = r + l + p

      if r > o.conf.base then
        o.ref:stopCombat(true)

        o.debug(2, "Combat stopped and trust flag set")

        d.trust   = true
        o.message = o.message .. " " .. o.conf.combatText

        if o.conf.gain > 0 then
          o.debug(2, "Gained " .. o.conf.gain/10 .. " skill points for ending combat")

          tes3.mobilePlayer:exerciseSkill(tes3.skill.speechcraft, o.conf.gain/10)
        end

      else
        o.debug(2, "Failed attribute test, combat continues")
      end
    end
  end

  function o.combatHandler(e)
    if not o.basics(5, nil, e.actor) then
      return
    end

    local d = o.info[o.cid]

    if d.trust then
      o.debug(5, "This " .. d.name:lower() .. " is a naughty critter who tried to enter combat when they shouldn't")

      return false
    end
  end

  function o.attackCheck(e)
    if not o.basics(6, nil, e.targetMobile, e.attacker) then
      return
    end

    local d = o.info[o.cid]
    local s = o.stats[o.cid]

    if o.conf.halt and e.attacker == tes3.player and d.trust then
      e.targetMobile.fight = s.fight
      e.targetMobile.flee  = s.flee
      d.trust              = nil

      o.debug(6, "Player attacked the " .. d.name:lower() .. ", so their stats were reset")
    end
  end

  return o
end