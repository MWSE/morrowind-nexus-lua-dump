function onLoaded(e)
local camera = tes3.worldController.worldCamera.camera
local weaponOut = tes3.mobilePlayer.readiedweapon
   if weaponOut ~= nil  then 
     if tes3.is3rdPerson then
       camera.translation = tes3vector3.new(-18, -130, 0)
     end
   else
     if tes3.is3rdPerson then
       camera.translation = tes3vector3.new(15, -40, 5)
     end
   end
end
event.register("loaded", onLoaded)

function onWeaponReadied(e)
local camera = tes3.worldController.worldCamera.camera
  if e.reference == tes3.player and tes3.is3rdPerson then
    camera.translation = tes3vector3.new(-18, -130, 0)
  end
end
event.register("weaponReadied", onWeaponReadied)

function onWeaponUnreadied(e)
local camera = tes3.worldController.worldCamera.camera
  if e.reference == tes3.player and tes3.is3rdPerson then
    camera.translation = tes3vector3.new(15, -40, 5)
  end
end
event.register("weaponUnreadied", onWeaponUnreadied)
