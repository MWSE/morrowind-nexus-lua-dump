return function(o)
  local major = "1.4"
  local minor = "0"

  o.data  = {}
  o.order = {}
  o.meta  = {}
  o.reps  = {}

  setmetatable(o.meta, {__newindex = function(_, k, v)
    if not o.data[v] then
      o.order[k] = v
    end
  end})

  function o.debug(z, m, i)
    if o.conf.debug then
      mwse.log("[" .. (o.title or "?") .. "] (" .. (i or z and o.funcs[z].n or "?") .. "): " .. (m or "?") .. ".")
    end
  end

  function o.build(t)
    if o.reps[t.f] then return end

    local p      = o.page or "Misc"
    local d      = o.desc or "?"
    local n      = #o.order + 1
    o.reps[t.f]  = true
    o.meta[n]    = p
    o.data[p]    = o.data[p] or {}
    n            = t.o or #o.data[p] + 1

    table.insert(o.data[p], n, t)
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

  function o.run()
    o.funcs    = {}
    o.defaults = {}

    if next(o.data) then
      for _, v in pairs(o.data) do
        if next(v) then
          for _, d in pairs(v) do
            if d and d.f then
              if d.z and d.v then
                o.set(d.z, d.f, d.v)
              end

              if d.i and d.t then
                o.funcs[d.i] = {f = d.f, n = d.t}
              end

              if d.e then
                event.register(d.e, o[d.f])
              end
            end
          end
        end
      end
    end

    o.conf = mwse.loadConfig(o.mod) or o.defaults

    if not o.init then
      o.libModules = nil
      o.modModules = nil
    end

    if not o.compile then
      o.order = nil
      o.meta  = nil
      o.data  = nil
      o.page  = nil
      o.desc  = nil
    end

    o.reps = nil

    if o.process then o.process()                                          end
    if o.scan    then event.register("activationTargetChanged", o.scan)    end
    if o.loaded  then event.register("loaded",                  o.loaded)  end
    if o.compile then event.register("modConfigReady",          o.compile) end
  end

  return o, major, minor
end