local config = require("WebSweeper.config")
local function myRayTest()
  local hitResult = tes3.rayTest({
    position = tes3.getPlayerEyePosition(),
    direction = tes3.getPlayerEyeVector(),
    maxDistance = config.dist
  })
  local hitReference = hitResult and hitResult.reference
  if (hitReference == nil) then
      return
  end
  if (hitReference.id == "furn_web00") or (hitReference.id == "furn_web10") then
    local delay = (config.delay * 0.1)
    timer.start({
      type = timer.simulate,
      iterations = 1,
      duration = delay,
      callback = function()
        mwscript.disable {reference = hitReference}
        if tes3.isModActive("SpiderSilk.ESP") then
          tes3.addItem{reference = tes3.mobilePlayer, item = "0s_ing_spidersilk"}
        end
      end
    })
  end
end
local function onAttack(e)
  if e.mobile.reference == tes3.player then
    myRayTest()
  end
end
local function onCellChange()
  for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.static) do
    if ref.disabled then
      if (ref.object.id == "furn_web00") or (ref.object.id == "furn_web10") then
        local rng = math.random(100)
        if rng < config.respawnChance then
          mwscript.enable{reference = ref}
        end
      end
    end
  end
end
event.register("cellChanged", onCellChange)
event.register("attack", onAttack)
local function registerModConfig()
	require("WebSweeper.mcm")
end
event.register("modConfigReady", registerModConfig)