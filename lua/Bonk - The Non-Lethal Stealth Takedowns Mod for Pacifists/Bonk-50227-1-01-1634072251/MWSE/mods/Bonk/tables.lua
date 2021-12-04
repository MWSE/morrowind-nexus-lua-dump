local o = require("Bonk.mcm")

o.funcs = {
  {f = "bonk",    e = "calcHitChance", n = "Knockout"},
  {f = "clean",   e = "keyDown",       n = "Clean-up"},
  {f = "wake",    e = "keyDown",       n = "Wake-up"},
  {f = "down",    e = "damage",        n = "Stay Down"},
  {f = "fatigue", e = "damage",        n = "Fatigue Damage Only"},
  {f = "fail",                         n = "Fail"}
}

o.types = {
  tes3.weaponType.bluntOneHand,
  tes3.weaponType.bluntTwoClose,
  tes3.weaponType.bluntTwoWide
}

o.races        = {
  darkelf      = true,
  highelf      = true,
  breton       = true,
  woodelf      = true,
  redguard     = true,
  orc          = true,
  nord         = true,
  imperial     = true,
  khajiit      = true,
  blackkhajiit = true,
  argonian     = true
}

o.meshes                           = {
  ["r\\duskyalit.nif"]             = true,
  ["oaab\\r\\bat.nif"]             = true,
  ["r\\cave rat.nif"]              = true,
  ["r\\cliffracer.nif"]            = true,
  ["r\\durzog.nif"]                = true,
  ["r\\durzog_collar.nif"]         = true,
  ["r\\guar.nif"]                  = true,
  ["r\\guar_white.nif"]            = true,
  ["r\\guar_withpack.nif"]         = true,
  ["r\\kwama forager.nif"]         = true,
  ["r\\kwama queen.nif"]           = true,
  ["r\\kwama warior.nif"]          = true,
  ["r\\kwama worker.nif"]          = true,
  ["oaab\\r\\kwama grubber.nif"]   = true,
  ["r\\leastkagouti.nif"]          = true,
  ["r\\cavemudcrab.nif"]           = true,
  ["r\\mushroomcrab.nif"]          = true,
  ["r\\tr_molecrab_vo.nif"]        = true,
  ["r\\netch_betty.nif"]           = true,
  ["r\\netch_bull.nif"]            = true,
  ["r\\nixhound.nif"]              = true,
  ["r\\shalk.nif"]                 = true,
  ["oaab\\r\\lidicus_cspider.nif"] = true,
  ["r\\packrat.nif"]               = true,
  ["r\\rust rat.nif"]              = true,
  ["r\\minescrib.nif"]             = true,
  ["oaab\\r\\r0_s-fish_blind.nif"] = true,
  ["r\\slaughterfish.nif"]         = true,
  ["r\\babelfish.nif"]             = true
}

return o