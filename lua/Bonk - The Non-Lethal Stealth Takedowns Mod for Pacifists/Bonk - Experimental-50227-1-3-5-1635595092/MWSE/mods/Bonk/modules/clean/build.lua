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

  o.data[14]          = {
    z                 = 4,
    t                 = "Clean-Up",
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
    d                 = 2
  }

  return o
end