return function(o)
  o.category("Knockout")

  local n = " when you try to knock out an opponent, this is the notification that will be shown."
  local s = "successfully knock out your opponent"
  local k = " a successful knockout."

  o.build{
    z = 0,
    t = "Disable Knockout Functionality",
    d = "If you turn this option on, you won't be able to use attacks to knockout foes anymore. Pretty self-explanatory.",
    f = "disable",
    v = false
  }

  o.build{
    z = 0,
    t = "Exit Combat on Successful Knockout",
    d = "If you manage to " .. s .. " with this option on, you won't enter into combat.",
    f = "exit",
    v = true
  }

  o.build{
    z   = 5,
    t   = "Knockout",
    d   = {
      s = "This option toggles playing a sound for successful knockouts.",
      m = "This option toggles whether a notification is shown to indicate" .. k,
      t = "Here you can customise the notification shown upon" .. k
    },
    f   = "bonk",
    v   = {
      s = true,
      m = true,
      t = "Bonk!"
    },
    e   = "calcHitChance",
    i   = 1
  }

  o.build{
    z = 2,
    t = "Fail via Helm Resist Text",
    d = "If armour resists the blow" .. n,
    f = "knockText",
    v = "Their armor absorbed the impact!"
  }

  o.build{
    z = 2,
    t = "Fail via Broken Weapon",
    d = "If your weapon is broken" .. n,
    f = "brokeText",
    v = "Your weapon is too flimsy!"
  }

  o.build{
    z = 2,
    t = "Fail via Distance Text (Bonk)",
    d = "If you're too far away" .. n,
    f = "missText",
    v = "You're too far away, you miss!"
  }

  o.build{
    z = 2,
    t = "Fail via Not Sneaking Text (Bonk)",
    d = "If you were seen" .. n,
    f = "seenText",
    v = "You were seen, you miss!"
  }

  o.build{
    z = 3,
    t = "Combat skill gained (tenth of amount shown)",
    d = "This is the amount of hand-to-hand/blunt weapon skill (respectively) you gain when you " .. s .. ".",
    f = "gain",
    v = 5
  }

  o.build{
    z = 3,
    t = "Fraction of player's luck",
    d = "The fraction of a player's luck used to help determine" .. k,
    f = "fraction",
    v = 4,
    m = 2
  }

  o.build{
    z = 3,
    t = "Fatigue damage amount",
    d = "This is the amount of fatigue damage done to a foe upon" .. k,
    f = "amount",
    v = 1000,
    m = 0,
    x = 1000,
    s = 100
  }

  o.build{
    z = 3,
    t = "Max range from target",
    d = "This is the range you need to be in for" .. k,
    f = "range",
    v = 120,
    m = 0,
    x = 500
  }

  o.build{
    z = 3,
    t = "Base success for light helms",
    d = "The per centage required (out of a hundred) versus light armour helms for" .. k,
    f = "light",
    v = 25,
    m = 1,
    x = 100
  }

  o.build{
    z = 3,
    t = "Base success for medium helms",
    d = "The per centage required (out of a hundred) versus medium armour helms for" .. k,
    f = "medium",
    v = 50,
    m = 1,
    x = 100
  }

  o.build{
    z = 3,
    t = "Base success for heavy helms",
    d = "The per centage required (out of a hundred) versus heavy armour helms for" .. k,
    f = "heavy",
    v = 75,
    m = 1,
    x = 100
  }

  return o
end