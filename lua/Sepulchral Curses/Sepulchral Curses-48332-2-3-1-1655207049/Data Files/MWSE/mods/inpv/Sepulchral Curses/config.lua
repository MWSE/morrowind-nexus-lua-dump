local strings = require("inpv.Sepulchral Curses.strings")

local defaultConfig = {
  enabled = true,
  spawnFrostDaedra = false,
  pickEquippedOnly = true,
  displayMessages = true,
  includeMiscObjects = true,
  easyMode = false,
  lowerBorder = 70,
  upperBorder = 75
}

local config = mwse.loadConfig(strings.modName, defaultConfig)

return config
