return function(o)
  local major = "1.4"
  local minor = "1"
  o.title     = o.title or (o.name or o.mod) .. " v" .. (o.version or "?")
  o.mcmTypes  = {
    toggle    = 0,
    bind      = 1,
    text      = 2,
    slider    = 3,
    keymulti  = 4,
    multi     = 5,
    info      = 6
  }
  o.mcmInv    = {
    [0]       = "YesNoButton",
    [1]       = "KeyBinder",
    [2]       = "TextField",
    [3]       = "Slider",
    [6]       = "Info"
  }

  function o.category(v)
    if v and type(v) == "string" then
      o.page = v

    elseif v and type(v) == "table" then
      if (#v or 0) > 0 then
        for i = 1, #v do
          if o.data[v[i]] then
            o.page = v[i]

            break
          end

          if i == #v then o.page = v[i] end
        end
      end
    end
  end

  function o.pager(p)
    if p and not o["page" .. p] then
      local z = "page" .. p
      local s = p      .. " Settings"
      s       = o.conf.singlePane and o.title .. " - " .. s or s
      local t = o.conf.singlePane and "createPage"          or "createSideBarPage"
      local i = o.template

      o[z]          = i[t](i, {
        label       = p,
        description = o.desc and not o.conf.singlePane and o.title .. "\n\n" .. o.desc
      })

      o[z]:createCategory(s)
    end
  end

  function o.opt(z, p, t, d, f, v, m, x, s)
    if not z or not p then return end

    z = z == type(string) and o.mcmTypes[z] or z
    z = z == 4 and 3 or z ~= 5 and z or nil
    p = o["page" .. p]

    if not z or not p then return end

    p["create" .. o.mcmInv[z]](p, {
      label          = z ~= 6 and t,
      text           = z == 6 and t,
      description    = d,
      variable       = z ~= 6 and mwse.mcm.createTableVariable{
        id           = f,
        table        = o.conf
      },
      min            = m,
      max            = x,
      step           = s,
      defaultSetting = v
    })
  end

  function o.compile()
    local h = o.pic and not o.conf.noHeader and "/Textures/" .. o.mod .. "/" .. o.pic .. ".tga"

    if h and not lfs.fileexists("Data Files" .. h) then
      h = nil

      if o.debug then
        o.debug(nil, "The " .. o.pic .. ".tga header file is missing from /Textures/" .. o.mod .. "/, reverting to headerless menu.", "MCM")
      end
    end

    o.template        = mwse.mcm.createTemplate{
      name            = o.name or o.mod,
      headerImagePath = h
    }

    o.template:register()
    o.template:saveOnClose(o.mod, o.conf)

    local t = o.order

    if (#t or 0) > 0 then
      for z = 1, #t do
        if o.data[t[z]] and next(o.data[t[z]]) then
          for i = 1, #o.data[t[z]] do
            local d = o.data[t[z]][i]

            o.pager(t[z])
            o.opt(d.z, t[z], d.t, d.d, d.f, d.v, d.m, d.x, d.s)

            if d.z == 4 or d.z == 5 then
              o.opt(0, t[z], "Play " .. d.t .. " Sound",        d.d and d.d.s, d.f .. "Sound",   d.v.s)
              o.opt(0, t[z], "Show " .. d.t .. " Notification", d.d and d.d.m, d.f .. "Message", d.v.m)
              o.opt(2, t[z], d.t .. " Message Text",            d.d and d.d.t, d.f .. "Text",    d.v.t)
            end
          end
        end
      end
    end

    if o.pic or o.desc then
      o.pager("Menu")
      o.opt(6,
            "Menu",
            "These options require a restart of the game.")
    end

    if o.pic then
        o.opt(0,
              "Menu",
              "Disable Header",
              "This option toggles the menu's header image.",
              "noHeader",
              false)
    end

    if o.desc then
        o.opt(0,
              "Menu",
              "Single Pane",
              "This option toggles whether the menu uses the double or single pane view.",
              "singlePane",
              false)
    end

    o.order = nil
    o.meta  = nil
    o.data  = nil
    o.page  = nil
    o.desc  = nil
  end

  return o, major, minor
end