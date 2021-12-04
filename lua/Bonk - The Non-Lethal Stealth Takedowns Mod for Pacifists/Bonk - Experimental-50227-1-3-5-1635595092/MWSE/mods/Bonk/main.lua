local o   = include("WulfLib.lib"){
  mod     = "Bonk",
  name    = "Bonk!",
  libReq  = "1.2.2 (Experimental)",
  version = "1.3.5 (Experimental)"
}

if not o then return end

o = o.inc("Bonk.modules.check.build"       )(o)
o = o.inc("Bonk.modules.check.functions"   )(o)
o = o.inc("Bonk.modules.check.tables"      )(o)
o = o.inc("Bonk.modules.clean.build"       )(o)
o = o.inc("Bonk.modules.clean.functions"   )(o)
o = o.inc("Bonk.modules.debug.build"       )(o)
o = o.inc("Bonk.modules.fatigue.build"     )(o)
o = o.inc("Bonk.modules.fatigue.functions" )(o)
o = o.inc("Bonk.modules.knockout.build"    )(o)
o = o.inc("Bonk.modules.knockout.functions")(o)
o = o.inc("Bonk.modules.staydown.build"    )(o)
o = o.inc("Bonk.modules.staydown.functions")(o)
o = o.inc("Bonk.modules.wake.build"        )(o)
o = o.inc("Bonk.modules.wake.functions"    )(o)

o.run()

return o