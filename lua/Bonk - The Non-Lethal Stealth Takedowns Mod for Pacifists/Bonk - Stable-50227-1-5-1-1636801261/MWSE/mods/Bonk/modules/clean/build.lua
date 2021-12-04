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
    t                 = "Clean-Up",
    d                 = "This is the keybind for hiding the unconscious bodies of foes after they've been knocked out.\n\nHiding foes completes quests (counts as kills for quests).",
    f                 = "clean",
    v                 = {
      k               = {
        keyCode       = tes3.scanCode.lShift,
        isShiftDown   = true,
        isControlDown = false,
        isAltDown     = false
      },
      s               = true,
      m               = true,
      t               = "You tie them up and shunt them off to a dark corner."
    },
    e                 = "keyDown",
    i                 = 2
  }

  return o
end