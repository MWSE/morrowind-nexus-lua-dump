local o = require("Feedbag.config")

function o.setup(name, db)
  name       = name or o.mod
  db         = db or o.mod
  o.title    = name .. " v" .. o.version
  o.template = mwse.mcm.createTemplate(name)
  o.page     = o.template:createPage()

  o.page:createCategory(o.title)
  o.template:register()
  o.template:saveOnClose(db, o.conf)
end

function o.batch(z, t, f, m, x, s)
  if z == 0 then
    o.page:createYesNoButton{
      label          = t,
      variable       = mwse.mcm.createTableVariable{
        id           = f,
        table        = o.conf
      },
      defaultSetting = o.defaults[f]
    }
  end

  if z == 1 or z == 4 then
    o.page:createKeyBinder{
      label             = t .. " Keybind",
      allowCombinations = true,
      variable          = mwse.mcm.createTableVariable{
        id              = f .. "Key",
        table           = o.conf
      },
      defaultSetting    = o.defaults[f .. "Key"]
    }
  end

  if z == 2 then
    o.page:createTextField{
      label          = t,
      variable       = mwse.mcm.createTableVariable{
        id           = f,
        table        = o.conf
      },
      defaultSetting = o.defaults[f]
    }
  end

  if z == 3 then
    o.page:createSlider{
      label          = t,
      variable       = mwse.mcm.createTableVariable{
        id           = f,
        table        = o.conf
      },
      min            = m or 0,
      max            = x or 10,
      step           = s or 1,
      defaultSetting = o.defaults[f]
    }
  end

  if z == 4 or z == 5 then
    o.page:createYesNoButton{
      label          = "Play " .. t .. " Sound",
      variable       = mwse.mcm.createTableVariable{
        id           = f,
        table        = o.conf
      },
      defaultSetting = o.defaults[f .. "Sound"]
    }

    o.page:createYesNoButton{
      label          = "Show " .. t .. " Notification",
      variable       = mwse.mcm.createTableVariable{
        id           = f .. "Message",
        table        = o.conf
      },
      defaultSetting = o.defaults[f .. "Message"]
    }

    o.page:createTextField{
      label          = t .. " Message Text",
      variable       = mwse.mcm.createTableVariable{
        id           = f .. "Text",
        table        = o.conf
      },
      defaultSetting = o.defaults[f .. "Text"]
    }
  end
end

function o.theatrics(z, f, m, p, r)
  if not z or not f then return end

  f = o.funcs[f].f

  if (z == 1 or z == 2) and o.conf[f .. "Sound"] then
    tes3.playSound{
      soundPath = o.mod:lower() .. "\\" .. f .. ".wav",
      reference = tes3.player
    }
  end

  if (z == 0 or z == 2) and o.conf[f .. "Message"] then
    f = m or o.conf[f .. "Text"] or "?"

    tes3.messageBox(p and r and f:gsub(p, r) or f or "?")
  end
end

function o.debug(z, msg, i)
  if o.conf.debug then
    mwse.log("[" .. (o.title or "?") .. "] (" .. (i or z and o.funcs[z].n or "?") .. ") Debug: " .. (msg or "?") .. ".")
  end
end

function o.pressed(z, k)
  if not z or not k then return end

  local e = o.conf[o.funcs[z].f .. "Key"]

  if k.keyCode == e.keyCode and k.isShiftDown == e.isShiftDown and k.isAltDown == e.isAltDown and k.isControlDown == e.isControlDown then
    o.debug(z, "Key pressed")

    return true
  end
end

function o.basics(z, k, r, a)
  if not o.go then
    o.debug(z, "Game isn't loaded, aborting")

    return
  end

  if k and not o.pressed(z, k) then
    return
  end

  if tes3.mobilePlayer.inCombat then
    o.debug(z, "Player is in combat, requesting rayscan reference")
    o.scan()
  end

  r = r or o.ref

  if not r then
    o.debug(z, "Entity does not exist, aborting")

    return
  end

  if r.disabled then
    o.debug(z, "Entity is disabled, aborting")

    return
  end

  if r.deleted then
    o.debug(z, "Entity is deleted, aborting")

    return
  end

  if r.health.current <= 0 then
    o.debug(z, "Entity is dead, aborting")

    return
  end

  local t = r.actorType

  o.debug(z, "Actor is " .. (t == 0 and "creature" or t == 1 and "NPC" or t == 2 and "player" or "nil"))

  if a then
    t = a.actorType

    o.debug(z, "Attacker is " .. (t == 0 and "creature" or t == 1 and "NPC" or t == 2 and "player" or "nil"))
  end

  if o.check then
    if not o.check(z, r, a) then
      o.debug(z, "Check function returned false, aborting")

      return
    end
  end

  return true
end

function o.scan(e)
  if not e then
    e = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = {tes3.player}}
  end

  if not e then return end

  e     = e and (e.current or e.reference)
  o.ref = e and e.mobile or nil

  o.debug(nil, "Reference " .. (o.ref and "stored" or "cleared"), "Scan")
end

function o.init()
  mwse.log("[" .. (o.title or "?") .. "] Initialized.")
end

function o.loaded()
  o.go = true
end

function o.run()
  if o.process then o.process() end

  event.register("initialized",             o.init)
  event.register("modConfigReady",          o.mcm)
  event.register("activationTargetChanged", o.scan)
  event.register("loaded",                  o.loaded)

  for _, d in pairs(o.funcs) do
    if d.e then event.register(d.e, o[d.f]) end
  end
end

return o