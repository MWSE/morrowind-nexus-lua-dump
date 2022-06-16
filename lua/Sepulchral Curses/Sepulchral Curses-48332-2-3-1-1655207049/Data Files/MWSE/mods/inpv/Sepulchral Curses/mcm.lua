--[[ MCM ]]

local strings = require("inpv.Sepulchral Curses.strings")
local config = require("inpv.Sepulchral Curses.config")

local function registerModConfig()
    local mcm = require("mcm.mcm")

    local sidebarDefault = (
        "Makes robbing tombs and barrows harder by adding a chance of summoning a random angry undead/elemental daedra when opening burial containers."
    )

    local template = mcm.createTemplate("Sepulchral Curses")
    template:saveOnClose(strings.modName, config)

    local page = template:createSideBarPage{
        description = sidebarDefault
    }

    page:createOnOffButton{
        label = "Enable Sepulchral Curses",
        variable = mcm.createTableVariable{
            id = "enabled",
            table = config
        },
        description = "Turn this mod on or off."
    }

    page:createOnOffButton{
      label = "Frost Atronachs on Solstheim",
      variable = mcm.createTableVariable{
          id = "spawnFrostDaedra",
          table = config
      },
      description = "Adds Frost Atronachs to Solstheim barrows."
    }

    page:createOnOffButton{
      label = "Stalhrim mining overhaul",
      variable = mcm.createTableVariable{
          id = "pickEquippedOnly",
          table = config
      },
      description = "Stalhrim deposits can only be mined with pick equipped."
    }

    page:createOnOffButton{
      label = "Include miscellaneous objects",
      variable = mcm.createTableVariable{
          id = "includeMiscObjects",
          table = config
      },
      description = "Whether to include custom non-chest/non-urn activators (defaults to NecroCraft ashpits)."
    }

    page:createOnOffButton{
      label = "Display environmental messages",
      variable = mcm.createTableVariable{
          id = "displayMessages",
          table = config
      },
      description = "Display environmental messages upon triggering tomb traps."
    }

    page:createOnOffButton{
      label = "Easy mode",
      variable = mcm.createTableVariable{
          id = "easyMode",
          table = config
      },
      description = "Toggle easy mode with leveled creatures."
    }

    page:createSlider{
      label = "Safe Chance Lower Border",
      description = "The lower border of the base safe burial container opening chance. Decrease it to increase revenant spawns. Should be strictly lower than the upper value below.",
      min = 1,
      max = 100,
      step = 1,
      jump = 5,
      variable = mcm.createTableVariable{
        id = "lowerBorder",
        table = config
      }
    }

    page:createSlider{
      label = "Safe Chance Upper Border",
      description = "The upper border of the base safe burial container opening chance. Decrease it to increase revenant spawns. Should be strictly higher than the lower value above.",
      min = 1,
      max = 100,
      step = 1,
      jump = 5,
      variable = mcm.createTableVariable{
        id = "upperBorder",
        table = config
      }
    }

    template:register()
end

event.register("modConfigReady", registerModConfig)