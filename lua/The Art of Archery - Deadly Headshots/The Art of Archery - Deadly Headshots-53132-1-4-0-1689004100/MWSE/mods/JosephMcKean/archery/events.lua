-- This is where we define all our events.
event.register(tes3.event.loaded, require("JosephMcKean.archery.controllers.arrowCounter"))

event.register(tes3.event.attackHit, require("JosephMcKean.archery.controllers.attackHit"))
event.register(tes3.event.damage, require("JosephMcKean.archery.controllers.damage"))
event.register(tes3.event.projectileHitActor, require("JosephMcKean.archery.controllers.headshot"), { priority = 36 }) -- before Pincushion
