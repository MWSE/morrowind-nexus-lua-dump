return function(o)
  o.category("Combat")

  local c = "This is the text appended to the notification when "

  o.build{
    z = 0,
    t = "End Combat",
    d = "This option toggles the mod's feature to end combat upon filling up a critter with food.",
    f = "halt",
    v = true,
    i = 2
  }

  o.build{
    z = 2,
    t = "Appended Text",
    d = c .. "combat is successfully ended.",
    f = "combatText",
    v = "They seem calm and docile."
  }

  o.build{
    z = 2,
    t = "Appended Text for Refusing to End Combat",
    d = c .. "the player fails to bring the critter out of combat.",
    f = "sickText",
    v = "But they look too frenzied to be placated."
  }

  o.build{
    z = 3,
    t = "Base success needed",
    d = "This is the base chance amount (out of 100 per cent) required to end combat.",
    f = "base",
    v = 40,
    m = 1,
    x = 100
  }

  o.build{
    f = "combatHandler",
    t = "Combat Handler",
    e = "combatStart",
    i = 5
  }

  o.build{
    f = "attackCheck",
    t = "Attack Check",
    e = "calcHitChance",
    i = 6
  }

  return o
end