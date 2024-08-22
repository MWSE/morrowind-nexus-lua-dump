local types = require('openmw.types')
local acti = require("openmw.interfaces").Activation
local world = require('openmw.world')
local time = require('openmw_aux.time')

local isShrinking
local sizeIncrement = 0.01
local maxSize = 1.0
local minSize = 0.1
local status = 0

local function detd_DSS_nearbyItems(data)
local nearbyItems = data.nearbyItems
for index, value in ipairs(nearbyItems) do -- upon cellchange all tiny inventory items will be 0.5 scale again, this sets them back to 0.1
  if value.scale < 0.51 and value.scale > 0.49  then
    value:setScale(0.1)
  end
end
end

local stopFn = time.runRepeatedly(function() 
  local player = world.players[1]
  if player ~= nil then
  local playerSize = player.scale
if types.Actor.activeSpells(player):isSpellActive('detd_shrink_spell') then
isShrinking = 1 --shrinking
else 
isShrinking = 0 -- growing
end
if isShrinking == 0 then
  if playerSize > 1 then
  else
      player:setScale(playerSize + 0.01)
      for index, value in ipairs(types.Actor.inventory(player):getAll()) do
      value:setScale(player.scale)
  end
  end
elseif isShrinking == 1 then
  if playerSize - sizeIncrement < minSize then
  else
    player:setScale(playerSize - 0.01)
    for index2, value2 in ipairs(types.Actor.inventory(player):getAll()) do
     value2:setScale(player.scale)
    end
  end
end
end



end,
0.01 * time.second)  -- print 'Test' every 5 seconds

local function forbidActivate(object, actor)
  local player = world.players[1]
  if player == nil then
    return
  end
    if (player.scale < 0.8) and object.scale > 0.99 then -- if the player is small 
  return false
end
end

  acti.addHandlerForType(types.Miscellaneous, forbidActivate)
  acti.addHandlerForType(types.Potion, forbidActivate)
  acti.addHandlerForType(types.Book, forbidActivate)
  acti.addHandlerForType(types.Clothing, forbidActivate)
  acti.addHandlerForType(types.Container, forbidActivate)
  acti.addHandlerForType(types.Door, forbidActivate)
  acti.addHandlerForType(types.Light, forbidActivate)
  acti.addHandlerForType(types.Weapon, forbidActivate)
  acti.addHandlerForType(types.Armor, forbidActivate)
  acti.addHandlerForType(types.Ingredient, forbidActivate)

               return {
                eventHandlers = {
                  detd_DSS_nearbyItems = detd_DSS_nearbyItems,
                }}