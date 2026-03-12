local core = require('openmw.core')
local ui = require('openmw.ui')
local nearby = require('openmw.nearby')
local ambient = require('openmw.ambient')

local function isMaterial(materials,item_id)
  for id,material in pairs(materials) do
    if id == item_id then
--      print("[DEBUG] Found material:",id)
      return true
    end
  end
  return false
end

local function handleSound(data)
  ambient.playSound(data.name)
end

local function handleMessage(data)
  --print("[ArmorUpgrade] Msg event recieved.")
  if data.text ~= nil then
	ui.showMessage(data.text)
  end
end

local function getMaterials(data)
	local materials_nearby = {}
	local items = nearby.items
	for _,item in pairs(items) do
		--print(item.recordId,item.count)
		if isMaterial(data.materials,item.recordId) then
		  local distance = (data.object.position - item.position):length()
		  if distance < 101 then
		    table.insert(materials_nearby,{item=item,distance=distance})
		  end
		end
	end
	
	table.sort(materials_nearby,function(a,b) return a.distance < b.distance end)
	
	core.sendGlobalEvent("NearbyMaterials",{list = materials_nearby,object = data.object, actor=data.actor})
end


return{
	eventHandlers = 
		{GetNearbyMaterials = getMaterials,
		PlaySound = handleSound,
		ShowMessage = handleMessage},
}