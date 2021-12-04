return function(o)
  o.data[3] = {
    z       = 0,
    t       = "End Combat",
    f       = "halt",
    v       = true,
    d       = 2
  }

  o.data[7] = {
    z       = 2,
    t       = "Appended Text for Ending Combat",
    f       = "combatText",
    v       = "They seem calm and docile."
  }

  o.data[8] = {
    z       = 2,
    t       = "Appended Text for Refusing to End Combat",
    f       = "sickText",
    v       = "But they look too frenzied to be placated."
  }

  o.data[16] = {
    z        = 3,
    t        = "Base success (out of 100) needed to end combat",
    f        = "base",
    v        = 40,
    m        = 1,
    x        = 100
  }

  o.data[20] = {
    f        = "combatHandler",
    t        = "Combat Handler",
    e        = "combatStart",
    d        = 5
  }

  o.data[21] = {
    f        = "attackCheck",
    t        = "Attack Check",
    e        = "calcHitChance",
    d        = 6
  }

  return o
end