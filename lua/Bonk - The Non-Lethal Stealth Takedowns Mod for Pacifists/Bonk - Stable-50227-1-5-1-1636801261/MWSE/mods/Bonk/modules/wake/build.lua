return function(o)
  o.category("Keypress")

  local k = "This option sets the text of the notification for keypress features where the player isn't "

  o.build{
    z = 2,
    t = "Fail via Distance Text (Clean-up/Wake-up)",
    f = "otherMissText",
    d = k .. "in range.",
    v = "You need to move closer to do that."
  }

  o.build{
    z = 2,
    t = "Fail via Not Sneaking Text (Clean-up/Wake-up)",
    f = "otherSeenText",
    d = k .. "sneaking.",
    v = "You can't do that while you're not hidden."
  }

  o.build{
    z                 = 4,
    t                 = "Wake-Up",
    f                 = "wake",
    d                 = "This is the keybind for waking up knocked out targets.\n\nBe careful, they might attack you if they're hostile!",
    v                 = {
      k               = {
        keyCode       = tes3.scanCode.rAlt,
        isShiftDown   = false,
        isControlDown = false,
        isAltDown     = true
      },
      s               = true,
      m               = true,
      t               = "You help them to their feet."
    },
    e                 = "keyDown",
    i                 = 3
  }

  return o
end