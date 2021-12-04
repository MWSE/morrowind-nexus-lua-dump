local o = require("Feedbag.tables")

function o.process()
  o.stats = mwse.loadConfig("FeedbagData") or {}

  for animal in pairs(o.food) do
    for food in pairs(o.food[animal]) do
      if o[food] then
        for i = 1, #o[food] do
          o.food[animal][o[food][i]] = true
        end

        o.food[animal][food] = nil
      end
    end
  end
end

function o.fid(e)
  return e and e.item and e.item.id and e.item.id:lower() or "?"
end

function o.filter(e)
  return (e.item.objectType == tes3.objectType.ingredient) and (o.food[o.info[o.cid].type][o.fid(e)] == true)
end

function o.endCombat()
  local d = o.info[o.cid]

  if o.ref.fight > 0 then
    o.debug(2, "Fight stat still > 0, combat continues")

    o.message = o.message .. " " .. o.conf.sickText

  elseif d.trust and o.ref.inCombat then
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

function o.handler(e)
  if e and e.item then else
    o.debug(3, "No data for handler, most likely menu closed")

    return
  end

  tes3.player.object.inventory:removeItem{
    mobile   = tes3.mobilePlayer,
    item     = e.item,
    itemData = e.itemData
  }

  tes3ui.forcePlayerInventoryUpdate()

  local n     = o.info[o.cid].name:lower()
  o.message   = o.conf.feedText:gsub("CRITTER", n)
  o.ref.fight = math.max(o.ref.fight - o.conf.fight, 0)
  o.ref.flee  = math.max(o.ref.flee  - o.conf.flee,  0)

  o.debug(3, "Critter fed — "        .. n)
  o.debug(3, "Food chosen — "        .. o.fid(e))
  o.debug(3, "Current fight Stat — " .. o.ref.fight)
  o.debug(3, "Current flee Stat — "  .. o.ref.flee)

  if o.conf.halt and o.ref.inCombat then
    o.debug(2, "Attempting to stop combat..")
    o.endCombat()
  end

  o.theatrics(0, 1, o.message)

  o.message = nil
end

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

  if not o.cid then
    o.debug(z, "Entity has no ID")

    return
  end

  local fi = r.fight

  if not o.info[o.cid] then
    local m  = (r.object.mesh or "none"):lower()
    local n  = r.object.name
    local t  = o.meshes[m]

    if not n then
      o.debug(z, "Entity has no name")

      return
    end

    if not m then
      o.debug(z, "Entity has no mesh")

      return
    end

    if not t then
      o.debug(z, "Entity is not a valid type of critter")

      return
    end

    o.info[o.cid] = {
      name        = n,
      type        = t
    }

    o.debug(z, "Created new critter info entry")
    o.debug(z, "~ ID   — " .. o.cid)
    o.debug(z, "~ Name — " .. n)
    o.debug(z, "~ Mesh — " .. m)
    o.debug(z, "~ Type — " .. t)

  else
    o.debug(z, "Using existing critter info entry for " .. o.cid)
  end

  if not o.stats[o.cid] then
    local fl = r.flee

    if not fi then
      o.debug(z, "Entity has no fight stat")

     return
    end

    if not fl then
      o.debug(z, "Entity has no flee stat")

      return
    end

    o.stats[o.cid] = {
      fight        = fi,
      flee         = fl
    }

    o.debug(z, "Created new critter stats entry")
    o.debug(z, "~ ID    — " .. o.cid)
    o.debug(z, "~ Fight - " .. fi)
    o.debug(z, "~ Flee  - " .. fl)

    mwse.saveConfig("FeedbagData", o.stats)

  else
    o.debug(z, "Using existing critter stats entry for " .. o.cid)
  end

  o.info[o.cid].trust = fi == 0

  return true
end

function o.feed(e)
  if not o.basics(1, e) then
    return
  end

  local d = o.info[o.cid]

  if o.ref.fight == 0 and o.ref.flee == 0 and o.ref.inCombat == false then
    o.debug(1, "There's no reason to feed the critter")

    if o.conf.overfeed then
      o.debug(1, "Overfeeding is permittted, so continuing..")

    else
      o.theatrics(0, 4, nil, "CRITTER", d.name:lower())

      return
    end
  end

  o.debug(1, "Showing feeding menu")

  tes3ui.showInventorySelectMenu{
    title         = "Feed " .. d.name,
    noResultsText = "You have no appropriate food.",
    filter        = o.filter,
    callback      = o.handler
  }
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