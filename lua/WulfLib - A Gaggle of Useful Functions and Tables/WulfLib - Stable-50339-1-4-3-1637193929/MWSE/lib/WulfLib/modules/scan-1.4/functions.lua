return function(o)
  local major = "1.4"
  local minor = "0"

  function o.scan(e)
    if not e then
      e = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = {tes3.player}, useModelBounds = true}
    end

    if not e then return end

    e     = e and (e.current or e.reference)
    o.ref = e and e.mobile or nil

    o.debug(nil, "Reference " .. (o.ref and "stored" or "cleared"), "Scan")
  end

  return o, major, minor
end