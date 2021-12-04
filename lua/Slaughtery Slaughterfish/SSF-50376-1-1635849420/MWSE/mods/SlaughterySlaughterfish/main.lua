local config = require("SlaughterySlaughterfish.config")

local function slaughter()
  local playerCell = tes3.getPlayerCell()
  for ref in playerCell:iterateReferences(tes3.objectType.creature) do
    if ref.baseObject.id == "slaughterfish" or ref.baseObject.id == "Slaughterfish_Small" then
      local mobileList = tes3.findActorsInProximity{
        reference = ref,
        range = config.detectRange
      }
      for _, mobile in ipairs(mobileList) do
        if mobile.object.objectType == tes3.objectType.npc and mobile.isSwimming then
          mwscript.startCombat({
            reference = ref,
            target = mobile
          })
        end
      end
    end
  end
end

local function onLoaded()
  timer.start({iterations = -1, duration = config.detectRate, callback = slaughter, type = timer.simulate })
end
event.register("loaded", onLoaded)

local function registerModConfig()
	require("SlaughterySlaughterfish.mcm")
end
event.register("modConfigReady", registerModConfig)