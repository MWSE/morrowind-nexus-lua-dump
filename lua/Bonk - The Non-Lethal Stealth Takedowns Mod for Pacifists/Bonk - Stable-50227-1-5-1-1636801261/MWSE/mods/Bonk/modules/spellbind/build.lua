return function(o)
  o.category("Spellbinder")

  local s = "The text for the notification informing you that your spell knockout attempt was "
  local w = "This defines a random amount to sit atop the "

  o.build{
    z = 0,
    t = "Disable Knockout Functionality",
    d = "If you turn this option on, you won't be able to use spells to knockout foes anymore. Pretty self-explanatory.",
    f = "disableSpell",
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
    z = 2,
    t = "Successful Spell Knockout Text",
    d = s .. "successful.",
    f = "spellSucceedText",
    v = "Sapped!"
  }

  o.build{
    z = 2,
    t = "Unsuccessful Spell Knockout Text",
    d = s .. "unsuccessful.",
    f = "spellFailText",
    v = "Their will was too strong!"
  }

  o.build{
    z = 3,
    t = "Buffer for Player Will",
    d = w .. "player's will to signify the power of your attempt.",
    f = "playerRand",
    v = 50,
    x = 100
  }

  o.build{
    z = 3,
    t = "Buffer for Foe Will",
    d = "foe's will to signify their resistance against your attempt.",
    f = "foeRand",
    v = 40,
    x = 100
  }

  o.build{
    f = "spellMessage",
    v = true
  }

  o.build{
    f = "spell",
    t = "Spellbinder",
    e = "spellCast",
    i = 7
  }

  o.build{
    f = "spellFail",
    e = "spellCastedFailure"
  }

  return o
end