--[[
-- Vanish From Sight
-- by inpv, 2022
]]

local configPath = "VanishFromSight"
local config = mwse.loadConfig(configPath)

if (config == nil) then
	config = {
    enabled = true,
    fightValueThreshold = 30
  }
end

local function onSimulate()

  if not config.enabled then return end

  local cell = tes3.getPlayerCell()
  local player = tes3.mobilePlayer

  for ref in cell:iterateReferences({tes3.objectType.npc, tes3.objectType.creature}) do
    if ref.mobile ~= nil then
      if ref.mobile.fight > config.fightValueThreshold then
        if player.invisibility > 0 then
          mwscript.stopCombat{reference=ref, target=player}
        end
      end
    end
  end
end

event.register(tes3.event.simulate, onSimulate)


local function registerModConfig()
  local mcm = require("mcm.mcm")

  local sidebarDefault = (
      "As long as the player is invisible, all hostiles located in the current cell stop combat."
  )

  local template = mcm.createTemplate("Vanish From Sight")
  template:saveOnClose(config.configPath, config)

  local page = template:createSideBarPage{
      description = sidebarDefault
  }

  page:createOnOffButton{
    label = "Enable Vanish From Sight",
    variable = mcm.createTableVariable{
        id = "enabled",
        table = config
    },
    description = "Turn this mod on or off."
}

  page:createSlider{
    label = "Fight Value Threshold",
    description = "The minimum fight value of the hostiles you wish to evade.",
    min = 0,
    max = 100,
    step = 1,
    jump = 5,
    variable = mcm.createTableVariable{
      id = "fightValueThreshold",
      table = config
    }
  }

  template:register()
end

event.register("modConfigReady", registerModConfig)