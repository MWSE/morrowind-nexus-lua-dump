return function(o)
  local major = "1.4"
  local minor = "0"

  o.theatricsTypes = {
    text           = 0,
    sound          = 1,
    both           = 2
  }

  function o.theatrics(z, f, m, p, r)
    z = type(z) == "string" and o.theatricsTypes[z] or z

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

  return o, major, minor
end