return function(o)
  local major = "1.3"
  local minor = "0"

  function o.pressed(z, k)
    if not z or not k then return end

    local e = o.conf[o.funcs[z].f .. "Key"]

    if k.keyCode == e.keyCode and k.isShiftDown == e.isShiftDown and k.isAltDown == e.isAltDown and k.isControlDown == e.isControlDown then
      o.debug(z, "Key pressed")

      return true
    end
  end

  return o, major, minor
end