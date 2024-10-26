local Interface = require("openmw.interfaces")

local nonPausingModes = {
  "Container", "Barter", "MerchantRepair", "Companion",
  "Interface", "Book", "Scroll", "Journal", "Alchemy", "Enchanting",
  "Recharge", "SpellCreation", "Eating", "Drinking", "EquipmentChange",
  "LightSource", "Lockpicking", "Sneaking", "Swimming", "Climbing",
  "WeaponSharpening", "ArmorAdjusting"
}

local function unpauseMenus()
  for _, mode in ipairs(nonPausingModes) do
    Interface.UI.setPauseOnMode(mode, false)
  end
end

local function initialize()
  unpauseMenus()
end

return {
  engineHandlers = {
    onActive = initialize
  }
}