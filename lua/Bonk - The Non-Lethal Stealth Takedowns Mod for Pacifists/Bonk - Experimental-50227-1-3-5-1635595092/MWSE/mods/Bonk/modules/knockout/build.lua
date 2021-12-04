return function(o)
  o.data[1] = {
    z       = 0,
    t       = "Disable Bonk",
    f       = "disable",
    v       = false
  }

  o.data[2] = {
    z       = 0,
    t       = "Exit Combat on Successful Knockout",
    f       = "exit",
    v       = true
  }

  o.data[6] = {
    z       = 5,
    t       = "Knockout",
    f       = "bonk",
    v       = {
      s     = true,
      m     = true,
      t     = "Bonk!"
    },
    e       = "calcHitChance",
    d       = 1
  }

  o.data[8] = {
    z       = 2,
    t       = "Fail via Helm Resist Text",
    f       = "knockText",
    v       = "Their armor absorbed the impact!"
  }

  o.data[9] = {
    z       = 2,
    t       = "Fail via Broken Weapon",
    f       = "brokeText",
    v       = "Your weapon is too flimsy!"
  }

  o.data[10] = {
    z        = 2,
    t        = "Fail via Distance Text (Bonk)",
    f        = "missText",
    v        = "You're too far away, you miss!"
  }

  o.data[11] = {
    z        = 2,
    t        = "Fail via Not Sneaking Text (Bonk)",
    f        = "seenText",
    v        = "You were seen, you miss!"
  }

  o.data[16] = {
    z        = 3,
    t        = "Combat skill amount gained for a successful knockout (tenth of amount shown)",
    f        = "gain",
    v        = 5
  }

  o.data[17] = {
    z        = 3,
    t        = "Fraction of player's luck used in checks",
    f        = "fraction",
    v        = 4,
    m        = 2
  }

  o.data[18] = {
    z        = 3,
    t        = "Amount of fatigue damage done on knockout",
    f        = "amount",
    v        = 1000,
    m        = 0,
    x        = 1000,
    s        = 100
  }

  o.data[19] = {
    z        = 3,
    t        = "Max range from target",
    f        = "range",
    v        = 120,
    m        = 0,
    x        = 500
  }

  o.data[20] = {
    z        = 3,
    t        = "Base success (of 100) required for light helms",
    f        = "light",
    v        = 25,
    m        = 1,
    x        = 100
  }

  o.data[21] = {
    z        = 3,
    t        = "Base success (of 100) required for medium helms",
    f        = "medium",
    m        = 50,
    x        = 1,
    s        = 100
  }

  o.data[22] = {
    z        = 3,
    t        = "Base success (of 100) required for heavy helms",
    f        = "heavy",
    v        = 75,
    m        = 1,
    x        = 100
  }

  return o
end