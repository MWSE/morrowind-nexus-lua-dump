local o = require("Bonk.interop")

o.defaults        = {
  disable         = false,
  exit            = true,
  down            = true,
  fatigue         = false,
  bonkSound       = true,
  bonkMessage     = true,
  bonkText        = "Bonk!",
  failMessage     = true,
  knockText       = "Their armor absorbed the impact!",
  missText        = "You're too far away, you miss!",
  seenText        = "You were seen, you miss!",
  otherMissText   = "You need to move closer to do that.",
  otherSeenText   = "You can't do that while you're not hidden.",
  cleanText       = "You tie them up and shunt them off to a dark corner.",
  cleanSound      = true,
  cleanMessage    = true,
  wakeText        = "You help them to their feet.",
  wakeSound       = true,
  wakeMessage     = true,
  debug           = false,
  gain            = 5,
  fraction        = 4,
  light           = 25,
  medium          = 50,
  heavy           = 75,
  amount          = 1000,
  range           = 120,
  cleanKey        = {
    keyCode       = tes3.scanCode.lShift,
    isShiftDown   = true,
    isControlDown = false,
    isAltDown     = false
  },
  wakeKey         = {
    keyCode       = tes3.scanCode.rAlt,
    isShiftDown   = false,
    isControlDown = false,
    isAltDown     = true
  }
}

o.conf = mwse.loadConfig("Bonk") or o.defaults

return o