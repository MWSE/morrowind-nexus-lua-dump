local o   = include("WulfLib.lib"){
  mod     = "Feedbag",
  libReq  = "1.2.2 (Experimental)",
  version = "1.1.2 (Experimental)"
}

if not o then return end

o = o.inc("Feedbag.modules.check.functions" )(o)
o = o.inc("Feedbag.modules.debug.build"     )(o)
o = o.inc("Feedbag.modules.feed.build"      )(o)
o = o.inc("Feedbag.modules.feed.functions"  )(o)
o = o.inc("Feedbag.modules.feed.tables"     )(o)
o = o.inc("Feedbag.modules.combat.build"    )(o)
o = o.inc("Feedbag.modules.combat.functions")(o)

o.run()

return o