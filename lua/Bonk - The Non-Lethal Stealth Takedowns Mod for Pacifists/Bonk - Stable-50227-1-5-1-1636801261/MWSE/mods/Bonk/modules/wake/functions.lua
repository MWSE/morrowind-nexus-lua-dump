return function(o)
  function o.wake(e)
    if not o.basics(3, e) then
      return
    end

    o.theatrics(2, 3)
    o.debug(3, "Restoring target fatigue")

    event.trigger("Pickpocket:HideMenu")
    o.debug(3, "Pickpocket menu hidden")

    o.ref.fatigue.current = 10
  end

  return o
end