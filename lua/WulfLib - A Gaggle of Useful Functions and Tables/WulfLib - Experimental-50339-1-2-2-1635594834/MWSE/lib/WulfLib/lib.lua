return function(o)
  o         = require("WulfLib.tables")(o)
  local ver = "1.2.2 (Experimental)"
  o.checked = ver == (o.libReq or 0)

  if not o.checked then
    event.register("initialized", function()
      tes3.messageBox("WulfLib version incorrect for mod " .. o.mod .. ". Requires version " .. o.libReq .. ", version loaded is " .. ver .. ".")
    end)

    return
  end

  function o.inc(f)
    return include(f) or function(o) return o end
  end

  function o.batch(z, t, f, v, m, x, s)
    if z == 0 then
      o.page:createYesNoButton{
        label          = t,
        variable       = mwse.mcm.createTableVariable{
          id           = f,
          table        = o.conf
        },
        defaultSetting = v
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
        defaultSetting    = z == 4 and v.k or v
      }
    end

    if z == 2 then
      o.page:createTextField{
        label          = t,
        variable       = mwse.mcm.createTableVariable{
          id           = f,
          table        = o.conf
        },
        defaultSetting = v
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
        defaultSetting = v
      }
    end

    if z == 4 or z == 5 then
      o.page:createYesNoButton{
        label          = "Play " .. t .. " Sound",
        variable       = mwse.mcm.createTableVariable{
          id           = f .. "Sound",
          table        = o.conf
        },
        defaultSetting = v.s
      }

      o.page:createYesNoButton{
        label          = "Show " .. t .. " Notification",
        variable       = mwse.mcm.createTableVariable{
          id           = f .. "Message",
          table        = o.conf
        },
        defaultSetting = v.m
      }

      o.page:createTextField{
        label          = t .. " Message Text",
        variable       = mwse.mcm.createTableVariable{
          id           = f .. "Text",
          table        = o.conf
        },
        defaultSetting = v.t
      }
    end
  end

  function o.theatrics(z, f, m, p, r)
    if not z or not f then return end

    f = o.funcs[f] and o.funcs[f].f

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

  function o.debug(z, m, i)
    if o.conf.debug then
      mwse.log("[" .. (o.title or "?") .. "] (" .. (i or z and o.funcs[z].n or "?") .. ") Debug: " .. (m or "?") .. ".")
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

    if o.check and not o.check(z, r, a) then
      o.debug(z, "Check function returned false, aborting")

      return
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

  function o.concat(t, s, m, d, r)
    local c = {}
    local n = 1

    for k, v in pairs(t) do
      if k ~= d and v then
        k    = m and k:match(m) or k
        c[n] = not r:find(k) and k or nil
        n    = c[n] and n + 1 or n
      end
    end

    return table.concat(c, (s or ", "))
  end

  function o.longest(t)
    local l = 0

    for k in pairs(t) do
      l = k:len() > l and k:len() or l
    end

    return l
  end

  function o.sort(t)
    local keys = {}
    local i    = 0

    for k in pairs(t) do keys[#keys + 1] = k end

    table.sort(keys)

    return function()
      i = i + 1

      if keys[i] then return keys[i], t[keys[i]] end
    end
  end

  function o.init()
    mwse.log("[" .. (o.title or "?") .. "] Initialized.")

    if not o.conf.debug then return end

    o.debug(nil, "Loaded configuration..", "Settings")

    local l, c = o.longest(o.conf)

    for k, v in o.sort(o.conf) do
      c = type(v) == "table" and v.keyCode and o.concat(v, " + ", "is(.*)Down", "keyCode", o.keys[v.keyCode]) or nil
      v = (type(v) == "string" and "\"" .. v .. "\"") or (v == true and "On" or not v and "Off") or (c and (c ~= "" and c .. " + " or "")  .. o.keys[v.keyCode]:gsub("^%l", string.upper)) or tostring(v)

      o.debug(nil, "~ " .. ("%-" .. l .. "s"):format(k) .. " — " .. v, "Settings")
    end
  end

  function o.loaded()
    o.go = true
  end

  function o.set(z, f, v)
    if z == 0 or z == 2 or z == 3 then
      o.defaults[f] = v
    end

    if z == 1 or z == 4 then
      o.defaults[f .. "Key"] = z == 4 and v.k or v
    end

    if z == 4 or z == 5 then
      o.defaults[f .. "Sound"]   = v.s
      o.defaults[f .. "Message"] = v.m
      o.defaults[f .. "Text"]    = v.t
    end
  end

  function o.count(t)
    local l

    for k in pairs(t) do
      l = k > (l or 0) and k or l
    end

    return l
  end

  function o.build()
    local n    = o.name or o.mod
    local db   =           o.mod
    o.title    = n .. " v" .. o.version
    o.template = mwse.mcm.createTemplate(n)
    o.page     = o.template:createPage()

    o.page:createCategory(o.title)
    o.template:register()
    o.template:saveOnClose(db, o.conf)

    for i = 1, o.iter do
      local d = o.data[i]

      if d then
        if d.e then event.register(d.e, o[d.f])       end

        o.batch(d.z, d.t, d.f, d.v, d.m, d.x, d.s)
      end
    end
  end

  function o.run()
    o.iter = o.count(o.data)

    for i = 1, o.iter do
      local d = o.data[i]

      if d then
        o.set(d.z, d.f, d.v)

        if d.d then o.funcs[d.d] = {f = d.f, n = d.t} end
      end
    end

    o.conf = mwse.loadConfig(o.mod) or o.defaults

    if o.process then o.process() end

    event.register("initialized",             o.init)
    event.register("modConfigReady",          o.build)
    event.register("activationTargetChanged", o.scan)
    event.register("loaded",                  o.loaded)
  end

  return o
end