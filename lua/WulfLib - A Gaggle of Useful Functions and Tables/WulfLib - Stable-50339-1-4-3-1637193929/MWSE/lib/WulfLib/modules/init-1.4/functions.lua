return function(o)
  local major = "1.4"
  local minor = "1"

  function o.concat(t, s, m, d, r)
    if t and next(t) then
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

    return "?"
  end

  function o.longest(t, s)
    if t and next(t) then
      local l = 0
      local p = {}

      for k, v in pairs(t) do
        local i = s and v[s] or k

        if i and not p[i] then
          p[i] = true
          i    = i:len()
          l    = i > l and i or l
        end
      end

      return l
    end

    return 0
  end

  function o.sort(t)
    if t and next(t) then
      local keys = {}
      local i    = 0

      for k in pairs(t) do keys[#keys + 1] = k end

      table.sort(keys)

      return function()
        i = i + 1

        if keys[i] then return keys[i], t[keys[i]] end
      end
    end

    return function() end
  end

  function o.loader(z)
    local t = o[z .. "Modules"]
    local m = z == "lib" and "WulfLib" or o.mod

    if (#t or 0) > 0 then
      local lf =                o.longest(t, "f")
      local lt = z == "lib" and o.longest(t, "t") or nil

      o.debug(nil, "Imported " .. m ..  " modules..", "Loader")

      for i = 1, #t do
        o.debug(nil, "~ " .. ("%-" .. lf .. "s"):format(t[i].f) .. " - " .. (lt and ("%-" .. lt .. "s"):format(t[i].t) .. " - " .. t[i].v or t[i].t), "Loader")
      end

    else o.debug(nil, m .. " modules table missing", "Loader") end
  end

  function o.values(t)
    if next(t) then
      o.debug(nil, "Loaded configuration..", "Settings")

      local l, c = o.longest(t)

      for k, v in o.sort(t) do
        c = type(v) == "table" and v.keyCode and o.keys and o.concat(v, " + ", "is(.*)Down", "keyCode", o.keys[v.keyCode]) or nil
        v = (type(v) == "string" and "\"" .. v .. "\"") or (v == true and "On" or not v and "Off") or (c and (c ~= "" and c .. " + " or "")  .. o.keys[v.keyCode]:gsub("^%l", string.upper)) or tostring(v)

        o.debug(nil, "~ " .. ("%-" .. l .. "s"):format(k) .. " — " .. v, "Settings")
      end

    else o.debug(nil, "Configuration table missing", "Settings") end    
  end

  function o.init()
    mwse.log("[" .. (o.title or "?") .. "] Initialised.")

    if not o.conf or not o.conf.debug then return end

    o.loader("lib")
    o.loader("mods")
    o.values(o.conf)

    o.libModules  = nil
    o.modsModules = nil
  end

  return o, major, minor
end