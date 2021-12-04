local o   = include("WulfLib.main"){
  mod     = "Bonk",
  name    = "Bonk!",
  desc    = "Bonk is a mod that's all about providing non-lethal means of playing the game and completing quests.\n\nFrom stealthy takedowns to fatigue only damage for blunt weapons, Bonk has you covered.",
  pic     = "header",
  version = "1.5"
}

if not o then return end

o = o:inc("core",      "1.4")
o = o:inc("keys",      "1.3")
o = o:inc("init",      "1.4")
o = o:inc("check",     "1.3")
o = o:inc("theatrics", "1.4")
o = o:inc("mcm",       "1.4")
o = o:inc("keypress",  "1.3")
o = o:inc("scan",      "1.4")
o = o:inc("critters",  "1.3")

o = o:inc("knockout")
o = o:inc("spellbind")
o = o:inc("clean")
o = o:inc("wake")
o = o:inc("check")
o = o:inc("fatigue")
o = o:inc("staydown")
o = o:inc("debug")

o.run()

return o