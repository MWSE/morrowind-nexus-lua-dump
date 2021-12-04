local o = require("Feedbag.common")

function o.mcm()
  o.setup()

  o.batch(1, "Feed",                                                                     "feed")
  o.batch(0, "Crouch to Feed",                                                           "crouch")
  o.batch(0, "End Combat on Successful Feed",                                            "halt")
  o.batch(0, "Allow Overfeeding (Where Feeding Has No Effect)",                          "overfeed")
  o.batch(0, "Show Notification for Feeding",                                            "feedMessage")
  o.batch(2, "Notification Text for Feeding (CRITTER Represents the Animal's Name)",     "feedText")
  o.batch(2, "Appended Text for Ending Combat",                                          "combatText")
  o.batch(2, "Appended Text for Refusing to End Combat",                                 "sickText")
  o.batch(0, "Show Notification for Overfeeding",                                        "overfedMessage")
  o.batch(2, "Notification Text for Overfeeding (CRITTER Represents the Animal's Name)", "overfedText")
  o.batch(3, "Speechcraft amount gained for ending combat (tenth of value shown)",       "gain")
  o.batch(3, "Fight stat points reduced by feeding",                                     "fight",       5, 100, 5)
  o.batch(3, "Flee stat points reduced by feeding",                                      "flee",        5, 100, 5)
  o.batch(3, "Fraction of player's luck used in checks",                                 "luck",        2)
  o.batch(3, "Fraction of player's personality used in checks",                          "personality", 2)
  o.batch(3, "Base success (out of 100) needed to end combat",                           "base",        1, 100)
  o.batch(0, "Debug Log",                                                                "debug")
end

return o