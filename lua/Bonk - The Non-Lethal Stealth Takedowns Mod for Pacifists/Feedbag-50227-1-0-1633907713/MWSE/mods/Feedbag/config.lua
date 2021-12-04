local o = require("Feedbag.interop")

o.defaults        = {
  halt            = true,
  debug           = false,
  crouch          = false,
  feedMessage     = true,
  overfedMessage  = true,
  overfeed        = false,
  feedText        = "You fed the CRITTER.",
  sickText        = "But they look too frenzied to be placated.",
  combatText      = "They seem calm and docile.",
  overfedText     = "The CRITTER looks calm, sedated, and uninterested in more food.",
  flee            = 25,
  fight           = 25,
  gain            = 5,
  base            = 40,
  luck            = 4,
  personality     = 2,
  feedKey         = {
    keyCode       = tes3.scanCode.lShift,
    isShiftDown   = true,
    isControlDown = false,
    isAltDown     = false
  }
}

o.conf = mwse.loadConfig("Feedbag") or o.defaults

return o