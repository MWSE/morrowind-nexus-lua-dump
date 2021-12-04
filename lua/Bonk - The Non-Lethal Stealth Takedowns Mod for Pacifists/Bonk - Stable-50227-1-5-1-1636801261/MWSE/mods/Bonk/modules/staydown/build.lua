return function(o)
  o.category("Combat")

  o.build{
    z = 0,
    t = "Stay Down",
    d = "With this option enabled, whenever you hit an enemy while they're down, they'll stay knocked out for quite some time.\n\nThis is to solve the problem of enemies bouncing back up right after their fatigue is depleted.",
    f = "down",
    v = true,
    e = "damage",
    i = 4,
    o = 3
  }

  return o
end