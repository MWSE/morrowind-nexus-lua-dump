local EasyMCM = require("easyMCM.EasyMCM")
local config  = require("Krimson.Secret Masters House.config")

local template = EasyMCM.createTemplate("Secret Master's House")
template:saveOnClose("Krimson.Secret Masters House", config)
template:register()

local page = template:createSideBarPage({
    label = "Sorter Settings",
})

local settings = page:createCategory("Toggle Item Types From Main Sorter")

settings:createOnOffButton({
    label = "Sort Ammunition On/Off",
    description = "Toggles the sorting of Ammunition with the Main Sorter.\n\nIndividual sorter will still work with this OFF.\n\nDefault: On\n\n",
    variable = EasyMCM.createTableVariable {
    id = "sortammunition",
    table = config
  }
})

settings:createOnOffButton({
    label = "Sort Apparatuses On/Off",
    description = "Toggles the sorting of Apparatuses with the Main Sorter.\n\nIndividual sorter will still work with this OFF.\n\nDefault: On\n\n",
    variable = EasyMCM.createTableVariable {
    id = "sortapparatus",
    table = config
  }
})

settings:createOnOffButton({
    label = "Sort Armor On/Off",
    description = "Toggles the sorting of Armor with the Main Sorter.\n\nIndividual sorter will still work with this OFF.\n\nDefault: On\n\n",
    variable = EasyMCM.createTableVariable {
    id = "sortarmor",
    table = config
  }
})

settings:createOnOffButton({
    label = "Sort Books and Scrolls On/Off",
    description = "Toggles the sorting of Books and Scrolls with the Main Sorter.\n\nIndividual sorter will still work with this OFF.\n\nDefault: On\n\n",
    variable = EasyMCM.createTableVariable {
    id = "sortbook",
    table = config
  }
})

settings:createOnOffButton({
    label = "Sort Clothing On/Off",
    description = "Toggles the sorting of Clothing with the Main Sorter.\n\nIndividual sorter will still work with this OFF.\n\nDefault: On\n\n",
    variable = EasyMCM.createTableVariable {
    id = "sortclothing",
    table = config
  }
})

settings:createOnOffButton({
    label = "Sort Ingredients On/Off",
    description = "Toggles the sorting of Ingredients with the Main Sorter.\n\nIndividual sorter will still work with this OFF.\n\nDefault: On\n\n",
    variable = EasyMCM.createTableVariable {
    id = "sortingredient",
    table = config
  }
})

settings:createOnOffButton({
    label = "Sort Lights On/Off",
    description = "Toggles the sorting of Lights with the Main Sorter.\n\nIndividual sorter will still work with this OFF.\n\nDefault: On\n\n",
    variable = EasyMCM.createTableVariable {
    id = "sortlight",
    table = config
  }
})

settings:createOnOffButton({
    label = "Sort Lockpicks On/Off",
    description = "Toggles the sorting of Lockpicks with the Main Sorter.\n\nIndividual sorter will still work with this OFF.\n\nDefault: On\n\n",
    variable = EasyMCM.createTableVariable {
    id = "sortlockpick",
    table = config
  }
})

settings:createOnOffButton({
    label = "Sort Other Misc Items On/Off",
    description = "Toggles the sorting of Other Misc Items with the Main Sorter.\n\nIndividual sorter will still work with this OFF.\n\nDefault: On\n\n",
    variable = EasyMCM.createTableVariable {
    id = "sortmiscItem",
    table = config
  }
})

settings:createOnOffButton({
  label = "Sort Potions On/Off",
  description = "Toggles the sorting of Potions with the Main Sorter.\n\nIndividual sorter will still work with this OFF.\n\nDefault: On\n\n",
  variable = EasyMCM.createTableVariable {
  id = "sortalchemy",
  table = config
}
})

settings:createOnOffButton({
    label = "Sort Probes On/Off",
    description = "Toggles the sorting of Probes with the Main Sorter.\n\nIndividual sorter will still work with this OFF.\n\nDefault: On\n\n",
    variable = EasyMCM.createTableVariable {
    id = "sortprobe",
    table = config
  }
})

settings:createOnOffButton({
    label = "Sort Repair Hammers On/Off",
    description = "Toggles the sorting of Repair Hammers with the Main Sorter.\n\nIndividual sorter will still work with this OFF.\n\nDefault: On\n\n",
    variable = EasyMCM.createTableVariable {
    id = "sortrepairItem",
    table = config
  }
})

settings:createOnOffButton({
    label = "Sort Weapons On/Off",
    description = "Toggles the sorting of Weapons with the Main Sorter.\n\nIndividual sorter will still work with this OFF.\n\nDefault: On\n\n",
    variable = EasyMCM.createTableVariable {
    id = "sortweapon",
    table = config
  }
})

local page2 = template:createSideBarPage({
  label = "Other Settings",
})

local settings2 = page2:createCategory("Toggle Other Functions")

settings2:createOnOffButton({
  label = "Lock Chest On/Off",
  description = "Toggles the locking of the training chest.\n\nActivating while sneaking will set a lock depending on your Security skill.\n\nDefault: On\n\n",
  variable = EasyMCM.createTableVariable {
  id = "lockChest",
  table = config
}
})

settings2:createOnOffButton({
  label = "Trap Chest On/Off",
  description = "Toggles the trapping of the training chest.\n\nActivating while sneaking will set a silence trap.\n\nDefault: On\n\n",
  variable = EasyMCM.createTableVariable {
  id = "trapChest",
  table = config
}
})

settings2:createOnOffButton({
  label = "Alchemy Station On/Off",
  description = "Toggles automatically using Secret Master's alchemy equipment when activating the Alchemy Station.\n\nIf ON you cannot keep any Secret Master's alchemy equipment in your inventory.\n\nDefault: On\n\n",
  variable = EasyMCM.createTableVariable {
  id = "alchemyStation",
  table = config
}
})