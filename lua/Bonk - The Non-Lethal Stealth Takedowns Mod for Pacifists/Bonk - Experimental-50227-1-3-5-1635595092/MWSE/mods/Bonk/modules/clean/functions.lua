return function(o)
  function o.clean(e)
    if not o.basics(2, e) then
      return
    end

    o.theatrics(2, 2)

    local r = o.ref

    if not o.conf.exit then
      o.debug(2, "Combat halted")

      r:stopCombat(true)
    end

    tes3.runLegacyScript{command = "DisablePlayerControls"}
    tes3.fadeOut{duration = 0.5}

    r.health.current = -5

    o.debug(2, "Target dismissed. Health — " .. r.health.current)

    timer.start{
      duration   = 2,
      iterations = 1,
      type       = timer.real,
      callback   = function()
        mwscript.disable{reference   = r.object.reference}
        mwscript.setDelete{reference = r.object.reference, delete = true}

        o.debug(2, "Body removed")

        tes3.fadeIn{duration = 0.5}
        tes3.runLegacyScript{command = "EnablePlayerControls"}
      end
    }
  end

  return o
end