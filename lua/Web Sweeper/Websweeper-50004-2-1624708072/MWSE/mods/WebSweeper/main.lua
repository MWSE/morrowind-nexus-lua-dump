local respawnChance = 10
local function myRayTest()
  local hitResult = tes3.rayTest({
    position = tes3.getPlayerEyePosition(),
    direction = tes3.getPlayerEyeVector(),
    maxDistance = 188
  })
  local hitReference = hitResult and hitResult.reference
  if (hitReference == nil) then
      return
  end
  if (hitReference.id == "furn_web00") or (hitReference.id == "furn_web10") then
    mwscript.disable {reference = hitReference}
    if tes3.isModActive("SpiderSilk.ESP") then
      tes3.addItem{reference = tes3.mobilePlayer, item = "0s_ing_spidersilk"}
    end
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
        if rng < respawnChance then
          mwscript.enable{reference = ref}
        end
      end
    end
  end
end
event.register("cellChanged", onCellChange)
event.register("attack", onAttack)