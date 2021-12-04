local o   = include("WulfLib.main"){
  mod     = "Feedbag",
  desc    = "Feedbag is a mod for those tired of having to brutally murder animals for the terrible sin of merely being hungry. No more! Now you can finally feed those poor critters.",
  pic     = "header",
  version = "1.3"
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

o = o:inc("check")
o = o:inc("feed")
o = o:inc("combat")
o = o:inc("debug")

o.run()

return o