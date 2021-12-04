return function(o)
  o.data[1]         = {
    z               = 1,
    t               = "Feed",
    f               = "feed",
    v               = {
      keyCode       = tes3.scanCode.lShift,
      isShiftDown   = true,
      isControlDown = false,
      isAltDown     = false
    },
    e               = "keyDown",
    d               = 1
  }


  o.data[2] = {
    z       = 0,
    t       = "Crouch to Feed",
    f       = "crouch",
    v       = false
  }

  o.data[4] = {
    z       = 0,
    t       = "Allow Overfeeding (Where Feeding Has No Effect)",
    f       = "overfeed",
    v       = false
  }

  o.data[5] = {
    z       = 0,
    t       = "Show Notification for Feeding",
    f       = "feedMessage",
    v       = true
  }


  o.data[6] = {
    z       = 2,
    t       = "Notification Text for Feeding (CRITTER Represents the Animal's Name)",
    f       = "feedText",
    v       = "You fed the CRITTER."
  }

  o.data[9] = {
    z       = 0,
    t       = "Show Notification for Overfeeding",
    f       = "overfedMessage",
    v       = true
  }

  o.data[10] = {
    z        = 2,
    t        = "Notification Text for Overfeeding (CRITTER Represents the Animal's Name)",
    f        = "overfedText",
    v        = "The CRITTER looks calm, sedated, and uninterested in more food."
  }

  o.data[11] = {
    z        = 3,
    t        = "Speechcraft amount gained for ending combat (tenth of value shown)",
    f        = "gain",
    v        = 5
  }

  o.data[12] = {
    z        = 3,
    t        = "Fight stat points reduced by feeding",
    f        = "fight",
    v        = 25,
    m        = 5,
    x        = 100,
    s        = 5
  }

  o.data[13] = {
    z        = 3,
    t        = "Flee stat points reduced by feeding",
    f        = "flee",
    v        = 25,
    m        = 5,
    x        = 100,
    s        = 5
  }

  o.data[14] = {
    z        = 3,
    t        = "Fraction of player's luck used in checks",
    f        = "luck",
    v        = 4,
    m        = 2
  }

  o.data[15] = {
    z        = 3,
    t        = "Fraction of player's personality used in checks",
    f        = "personality",
    v        = 2,
    m        = 2
  }

  o.data[18] = {
    f        = "handler",
    t        = "Handler",
    d        = 3
  }

  o.data[19] = {
    f        = "overfed",
    t        = "Overfed",
    d        = 4
  }

  return o
end