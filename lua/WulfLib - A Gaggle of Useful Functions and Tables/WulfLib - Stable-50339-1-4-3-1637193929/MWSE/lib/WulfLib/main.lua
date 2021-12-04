return function(o)
  o.mod         = o.mod or "?"
  o.warnings    = {}
  o.libModules  = {}
  o.modsModules = {}

  function o.warn(f, t, libMajorReq, libMajorVer, libMinorReq, libMinorVer)
    local m = "WulfLib's " .. (f or "?") .. "-"
    m       = libMajorVer
              and m .. (t or "?") .. "-" .. libMajorVer .. (libMinorReq and libMinorVer and "-" .. libMinorVer or "") .. " module file has the incorrect version, the requested version is " .. (libMajorReq or "?") .. (libMinorReq and "-" .. LibMinorReq or "")
              or  m .. libMajorReq                                                                                    .. " module folder is missing"

    o.warnings[#o.warnings + 1] = m
  end

  function o.inc(m, f, libMajorReq, libMinorReq)
    local x = ".lua"
    local i = libMajorReq and "WulfLib" or o.mod
    local l = libMajorReq and "lib"     or "mods"
    local p = "Data Files/MWSE/" .. l .. "/" .. i .. "/modules/" .. f .. (libMajorReq and "-" .. libMajorReq or "")
    l       = l .. "Modules"

    if not lfs.directoryexists(p) then
      o.warn(f, nil, libMajorReq)

      return m
    end

    for t in lfs.dir(p) do
      local a    = lfs.attributes(p .. "/" .. t)
      local t, c = t:gsub(x, "")

      if a and a.mode == "file" and (c or 0) > 0 then
        local m, mjv, mnv = loadfile(p .. "/" .. t .. x)()(m)
        o[l][#o[l] + 1] = {t = t, f = f, v = mjv and mjv .. "-" .. mnv}

        if (libMajorReq and mjv ~= libMajorReq) or (libMinorReq and mnv ~= libMinorReq) then o.warn(f, t, libMajorReq, mjv, libMinorReq, mnv) end
      end
    end

    return m
  end

  event.register("initialized", function()
    if not o.noInit and o.init then o.init() end

    local t = o.warnings

    if (#t or 0) > 0 then
      for i = 1, #t do
        tes3.messageBox("[" .. o.mod .. "] " .. t[i])

        if o.debug then o.debug(nil, t[i], "Loader") end
      end
    end

    o.warnings = nil
  end)

  return o
end