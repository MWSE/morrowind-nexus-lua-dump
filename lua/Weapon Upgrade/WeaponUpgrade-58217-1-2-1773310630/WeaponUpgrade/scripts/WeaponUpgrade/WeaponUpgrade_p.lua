local core = require('openmw.core')
local ui = require('openmw.ui')
local nearby = require('openmw.nearby')
local ambient = require('openmw.ambient')
local types = require('openmw.types')
local storage = require('openmw.storage')

--local function isMaterial(materials,item_id)
--  for id,material in pairs(materials) do
--    if id == item_id then
----      print("[DEBUG] Found material:",id)
--      return true
--    end
--  end
--  return false
--end

local modSettings = storage.globalSection("SettingsWeaponUpgrade")

local function isMaterial(materials,item_id,object)
  for id,material in pairs(materials) do
    if id == item_id then
      if modSettings:get("MaterialMatching") then
        local weaponName = types.Weapon.record(object).name
        for _,match in ipairs(material.matches) do
--          print("[WeaponUpgrade] Checking match for: "..weaponName..", matching: "..match)
          if match == "ALL" then return true end
          if string.find(weaponName:lower(),match:lower()) then
            print("[WeaponUpgrade] Match found for: "..weaponName..", match: "..match)
            return true
          end
        end
      else
        return true
      end
    end
  end
  return false
end

local function handleSound(data)
  ambient.playSound(data.name)
end

local function getMaterials(data)
	local materials_nearby = {}
	local items = nearby.items
	for _,item in pairs(items) do
		if isMaterial(data.materials,item.recordId,data.object) then
		  local distance = (data.object.position - item.position):length()
		  if distance < 101 then
		    table.insert(materials_nearby,{item=item,distance=distance})
		  end
		end
	end
	
	table.sort(materials_nearby,function(a,b) return a.distance < b.distance end)
	
	core.sendGlobalEvent("NearbyWeaponMaterials",{list = materials_nearby,object = data.object, actor=data.actor})
end


return{
	eventHandlers = 
		{GetNearbyWeaponMaterials = getMaterials,
		PlaySound = handleSound},
}