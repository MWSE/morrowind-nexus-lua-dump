local o = require("Bonk.common")

function o.mcm()
  o.setup("Bonk!")

  o.batch(0, "Disable Bonk",                                                                 "disable")
  o.batch(0, "Exit Combat on Successful Knockout",                                           "exit")
  o.batch(0, "Stay Down",                                                                    "down")
  o.batch(0, "Fatigue Damage Only",                                                          "fatigue")
  o.batch(5, "Successful Bonk",                                                              "bonk")
  o.batch(0, "Fail Messages",                                                                "failMessage")
  o.batch(2, "Fail via Helm Resist Text",                                                    "knockText")
  o.batch(2, "Fail via Distance Text (Bonk)",                                                "missText")
  o.batch(2, "Fail via Not Sneaking Text (Bonk)",                                            "seenText")
  o.batch(2, "Fail via Distance Text (Clean-up/Wake-up)",                                    "otherMissText")
  o.batch(2, "Fail via Not Sneaking Text (Clean-up/Wake-up)",                                "otherSeenText")
  o.batch(4, "Clean-Up",                                                                     "clean")
  o.batch(4, "Wake-Up",                                                                      "wake")
  o.batch(3, "Combat skill amount gained for a successful knockout (tenth of amount shown)", "gain")
  o.batch(3, "Fraction of player's luck used in checks",                                     "fraction", 2)
  o.batch(3, "Amount of fatigue damage done on knockout",                                    "amount",   0, 1000, 100)
  o.batch(3, "Max range from target",                                                        "range",    0, 500)
  o.batch(3, "Base success (of 100) required for light helms",                               "light",    1, 100)
  o.batch(3, "Base success (of 100) required for medium helms",                              "medium",   1, 100)
  o.batch(3, "Base success (of 100) required for heavy helms",                               "heavy",    1, 100)
  o.batch(0, "Debug Log",                                                                    "debug")
end

return o