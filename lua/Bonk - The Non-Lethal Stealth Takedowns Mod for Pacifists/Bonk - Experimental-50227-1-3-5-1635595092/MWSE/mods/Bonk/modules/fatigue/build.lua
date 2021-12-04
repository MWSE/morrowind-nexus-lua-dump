return function(o)
  o.data[4] = {
    z       = 0,
    t       = "Fatigue Damage Only",
    f       = "fatigue",
    v       = false,
    e       = "damage",
    d       = 5
  }

  o.data[5] = {
    z       = 0,
    t       = "Disable Enemy Fatigue Regen",
    f       = "regen",
    v       = false
  }

  o.data[23] = {
    z        = 3,
    t        = "Times Multiplier for Fatigue Damage Only",
    f        = "mult",
    v        = 3
  }

  o.data[24] = {
    z        = 0,
    t        = "Claim Damage Event",
    f        = "claim",
    v        = false
  }

  o.data[28] = {
    f        = "handler",
    d        = 6
  }

  return o
end