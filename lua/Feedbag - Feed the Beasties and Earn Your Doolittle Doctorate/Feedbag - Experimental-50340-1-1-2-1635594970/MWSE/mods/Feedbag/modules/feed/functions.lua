return function(o)
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

    local s     = o.stats[o.cid]
    local n     = o.info[o.cid].name:lower()
    o.message   = o.conf.feedText:gsub("CRITTER", n)
    o.ref.fight = math.max(o.ref.fight - o.conf.fight, 0)
    o.ref.flee  = math.max(o.ref.flee  - o.conf.flee,  0)

    o.debug(3, "Fed critter with ID "    .. o.cid)
    o.debug(3, "~ Critter name       — " .. n)
    o.debug(3, "~ Food ID            — " .. o.fid(e))
    o.debug(3, "~ Current fight Stat — " .. o.ref.fight .. "/" .. s.fight)
    o.debug(3, "~ Current flee Stat  — " .. o.ref.flee  .. "/" .. s.flee)

    if o.conf.halt and o.ref.inCombat then
      o.debug(2, "Attempting to stop combat..")
      o.endCombat()
    end

    o.theatrics(0, 1, o.message)

    o.message = nil
  end

  function o.feed(e)
    if not o.basics(1, e) then
      return
    end

    local d = o.info[o.cid]

    if o.ref.fight == 0 and o.ref.flee == 0 and not o.ref.inCombat then
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
      title         = "Feed " .. d.name .. ":",
      noResultsText = "You have no appropriate food.",
      filter        = o.filter,
      callback      = o.handler
    }
  end

  return o
end