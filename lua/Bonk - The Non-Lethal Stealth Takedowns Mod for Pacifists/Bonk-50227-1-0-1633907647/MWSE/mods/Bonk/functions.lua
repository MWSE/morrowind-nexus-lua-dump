local o = require("Bonk.tables")

function o.check(z, r, a)
  if (z == 1 or z == 2 or z == 3) and tes3.mobilePlayer.inCombat then
    o.debug(z, "In combat, aborting")

    return
  end

  if z == 5 then
    o.debug(z, "Check for fatigue level skipped")

  else
    if     z == 1 and r.fatigue.current > 0  then
    elseif z ~= 1 and r.fatigue.current <= 0 then else
      o.debug(z, "Incorrect fatigue level — " .. (r.fatigue.current or "?"))

      return
    end
  end

  if z ~= 1 then
    o.debug(z, "Check for attacker skipped")

  else
    if a ~= tes3.player then
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

      if z == 1 then o.theatrics(0, 6, o.conf.seenText)      else
                     o.theatrics(0, 6, o.conf.otherSeenText) end

      return
    end

    if tes3.player.position:distance(r.position) <= o.conf.range then else
      o.debug(z, "Not close enough")

      if z == 1 then o.theatrics(0, 6, o.conf.missText)      else
                     o.theatrics(0, 6, o.conf.otherMissText) end

      return
    end

  else
    o.debug(z, "Player wasn't trying to sneak, aborting at stealth/distance checks")

    return
  end

  if z == 1 or z == 4 or z == 5 then
    if not a then
      o.debug(z, "No attacker")

      return

    elseif o.types[a.readiedWeapon] then
      o.debug(z, "Blunt weapon readied")

      o.skill = z == 1 and a == tes3.player and tes3.skill.bluntWeapon or nil

    elseif not a.readiedWeapon then
      o.debug(z, "Hand-to-hand readied")

      o.skill = z == 1 and a == tes3.player and tes3.skill.handToHand or nil

    else
      o.debug(z, "Incorrect weapon used")

      return
    end

  else
    o.debug(z, "Check for weapon type skipped")
  end

  return true
end

function o.wake(e)
  if not o.basics(3, e) then
    return
  end

  o.theatrics(2, 3)
  o.debug(3, "Restoring target fatigue")

  event.trigger("Pickpocket:HideMenu")

  o.debug(3, "Pickpocket menu hidden")

  o.ref.fatigue.current = 10
end

function o.clean(e)
  if not o.basics(2, e) then
    return
  end

  o.theatrics(2, 2)

  local r = o.ref

  if not o.conf.exit then
    o.debug(2, "Combat halted")

    r:stopCombat(true)
  end

  tes3.runLegacyScript{command = "DisablePlayerControls"}
  tes3.fadeOut{duration = 0.5}

  r.health.current = -5

  o.debug(2, "Target dismissed. Health — " .. r.health.current)

  timer.start{
    duration   = 2,
    iterations = 1,
    type       = timer.real,
    callback   = function()
      mwscript.disable{reference   = r.object.reference}
      mwscript.setDelete{reference = r.object.reference, delete = true}

      o.debug(2, "Body removed")

      tes3.fadeIn{duration = 0.5}
      tes3.runLegacyScript{command = "EnablePlayerControls"}
    end
  }
end

function o.bonk(e)
  if not o.basics(1, nil, e.targetMobile, e.attacker) then
    return
  end

  local k
  local h = tes3.getEquippedItem{actor = e.targetMobile, objectType = tes3.objectType.armor, slot = tes3.helmet}
  local w = h and h.object.weightClass
  local r = math.random(100)
  local l = math.floor(tes3.mobilePlayer.luck.current / o.conf.fraction)
  r       = r + l

  if not h then
    o.debug(1, "Helm check passed. No helm")

    k = true

  else
    w = w == 0 and "light" or w == 1 and "medium" or w == 2 and "heavy" or "?"
    k = r > o.conf[w]

    o.debug(1, "Helm check " .. (k and "passed" or "failed") .. ". Helm weight class is " .. w .. ", base requirement of " .. o.conf[w] .. ", random of " .. r)
  end

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

    if not o.unsafe then
      o.debug(4, "No actors left in combat, so exiting player from combat too")
    end

    e.reference.mobile.fatigue.current = 0 - o.conf.amount
    e.damage                           = 0
    tes3.mobilePlayer.inCombat         = o.unsafe
    o.unsafe                           = nil
  end
end

function o.fatigue(e)
  if o.conf.fatigue and o.basics(5, nil, e.reference.mobile, e.attacker) then
    o.debug(5, "Damage prevented")

    e.reference.mobile.fatigue.current = e.reference.mobile.fatigue.current - e.damage
    e.damage                           = 0
  end
end

return o