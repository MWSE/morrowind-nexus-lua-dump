return function(o)
  o.data[12] = {
    z        = 2,
    t        = "Fail via Distance Text (Clean-up/Wake-up)",
    f        = "otherMissText",
    v        = "You need to move closer to do that."
  }

  o.data[13] = {
    z        = 2,
    t        = "Fail via Not Sneaking Text (Clean-up/Wake-up)",
    f        = "otherSeenText",
    v        = "You can't do that while you're not hidden."
  }

  o.data[15]          = {
    z                 = 4,
    t                 = "Wake-Up",
    f                 = "wake",
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
    d                 = 3
  }

  return o
end