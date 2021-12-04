return function(o)
  o.category("Feeding")

  local k = ".\n\nThe uppercase instance of CRITTER represents the critter's name and thus should be present."
  local n = "This is the text shown as the notification for "
  local t = "This toggles whether a notification is shown "
  local p = "This is the amount of points reduced by feeding.\n\n"
  local s = "This is the amount of the player's "
  local w = " that's used to weight the chance of ending combat successfully.",


  o.build{
    z               = 1,
    t               = "Feed",
    d               = "This is the keybind you press for feeding critters.\n\nYou can even bind it to space to function like activation if you want, and it even works in combat.",
    f               = "feed",
    v               = {
      keyCode       = tes3.scanCode.lShift,
      isShiftDown   = true,
      isControlDown = false,
      isAltDown     = false
    },
    e               = "keyDown",
    i               = 1
  }

  o.build{
    z = 0,
    t = "Crouch to Feed",
    d = "This one's pretty self-explanatory. With this option enabled, you'll have to crouch in order to feed critters.",
    f = "crouch",
    v = false
  }

  o.build{
    z = 0,
    t = "Allow Overfeeding",
    d = "Overfeeding has no effect on an critter's stats and doesn't really do anything, it's purely a cosmetic option if you prefer it that way.\n\nI'd recommend leaving this one off, but it's here if you want it.",
    f = "overfeed",
    v = false
  }

  o.build{
    z = 0,
    t = "Show Notification for Feeding",
    d = t .. "upon feeding an critter.",
    f = "feedMessage",
    v = true
  }

  o.build{
    z = 2,
    t = "Notification Text for Feeding",
    d = n .. "a successful feeding" .. k,
    f = "feedText",
    v = "You fed the CRITTER."
  }

  o.build{
    z = 0,
    t = "Show Notification for Overfeeding",
    d = t .. "that informs you when an critter no longer needs any more food.",
    f = "overfedMessage",
    v = true
  }

  o.build{
    z = 2,
    t = "Notification Text for Overfeeding",
    d = n .. "when an critter is full of food" .. k,
    f = "overfedText",
    v = "The CRITTER looks calm, sedated, and uninterested in more food."
  }

  o.build{
    z = 3,
    t = "Speechcraft amount gained (tenth of value shown)",
    d = "This is the amount of speechcraft gained when you've fully fed a critter and combat is ended.",
    f = "gain",
    v = 5
  }

  o.build{
    z = 3,
    t = "Fight stat points reduced",
    d = p .. "The fight stat indicates a critter's aggressiveness and willingness to enter combat.",
    f = "fight",
    v = 25,
    m = 5,
    x = 100,
    s = 5
  }

  o.build{
    z = 3,
    t = "Flee stat points reduced by feeding",
    d = p .. "The flee stat indicates how flighty a critter is, feeding a critter reduces their flightiness.",
    f = "flee",
    v = 25,
    m = 5,
    x = 100,
    s = 5
  }

  o.build{
    z = 3,
    t = "Fraction of player's luck used",
    d = s .. "luck" .. w,
    f = "luck",
    v = 4,
    m = 2
  }

  o.build{
    z = 3,
    t = "Fraction of player's personality",
    d = s .. "personality" .. w,
    f = "personality",
    v = 2,
    m = 2
  }

  o.build{
    f = "handler",
    t = "Handler",
    i = 3
  }

  o.build{
    f = "overfed",
    t = "Overfed",
    i = 4
  }

  return o
end