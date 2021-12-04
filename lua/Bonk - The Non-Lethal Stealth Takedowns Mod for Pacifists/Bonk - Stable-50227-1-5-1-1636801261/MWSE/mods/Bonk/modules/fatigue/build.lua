return function(o)
  o.category("Combat")

  o.build{
    z = 0,
    t = "Fatigue Damage Only",
    d = "When this option is enabled, blunt weapons will only do fatigue damage. (It isn't needed for hand-to-hand, as that already does only fatigue damage.)",
    f = "fatigue",
    v = false,
    e = "damage",
    i = 5
  }

  o.build{
    z = 0,
    t = "Disable Enemy Fatigue Regen",
    d = "When this option is toggled on, enemies will no longer be able to regenerate fatigue in combat.",
    f = "regen",
    v = false
  }

  o.build{
    z = 3,
    t = "Times Multiplier",
    d = "This multiplies the amount of fatigue damage done when Fatigue Damage Only is enabled.",
    f = "mult",
    v = 3
  }

  o.build{
    z = 0,
    t = "Claim Damage Event",
    d = "If the Fatigue Damage Only feature doesn't seem to be working for you, try turning this option on and see if it helps. Otherwise, leave it off.",
    f = "claim",
    v = false
  }

  return o
end