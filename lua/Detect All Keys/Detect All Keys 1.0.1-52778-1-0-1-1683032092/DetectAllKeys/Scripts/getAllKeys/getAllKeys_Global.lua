local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local async = require('openmw.async')

local acti = require("openmw.interfaces").Activation
local checkPlaced = false
local player = nil
local function checkIsKey(record)
   if record.isKey == true then
      return false -- it is a key, but already tracked so we don't need to add a new itemcheck
   end

   local icon = record.icon:lower()
   local model = record.model:lower()
   local name = record.name:lower()
   local id = record.id:lower()

   if string.find(icon, "key") or string.find(model, "key") or string.find(name, "key") or string.find(id, "key") then
      return true -- record contains the word "key"
   end

   return false -- record does not contain the word "key"
end

local function findAllKeys()
   local miscitems = types.Miscellaneous.records
   for i, record in ipairs(miscitems) do
      if(checkIsKey(record)) then
         print(record.id)
      end
   end

end
local function addKeyToInventory(inv)
   local keyItem = world.createObject("ZHAC_PlaceholderKey")
   local targetInv = nil
   if(inv.type == types.Container) then
      targetInv = types.Container.content(inv)
   elseif(inv.type == types.Actor) then
      targetInv = types.Actor.inventory(inv)
   elseif(inv.type == types.NPC) then
      targetInv = types.Actor.inventory(inv)
   end
   keyItem:moveInto(targetInv)
   --print("Added to " .. inv.recordId)

end
local function addKeyToWorld(object)
   local keyItem = world.createObject("ZHAC_PlaceholderKey")
   keyItem:teleport(object.cell,util.vector3(object.position.x,object.position.y,object.position.z ))
  -- print("Placed Key")
end
local function removeKeyFromInventory(data)

   object = data.cont
   player = data.player
   if(object.type == types.Container) then
      inv = types.Container.content(object)
   elseif(object.type == types.Actor) then
      inv = types.Actor.inventory(object)
   elseif(object.type == types.NPC) then
      inv = types.Actor.inventory(object	)
   end


   local itemcheck = inv:find("ZHAC_PlaceholderKey")
   if(itemcheck ~= nil ) then
      itemcheck:remove()
      -- object:activateBy(player)
     -- print("Removed from " .. object.recordId)
   end
end
local function onItemActive(item)

   if(item.type == types.Miscellaneous) then
      if(checkIsKey(types.Miscellaneous.record(item))) then
         addKeyToWorld(item)
      end
   end

end

local function NPCActivate(object, actor)
   removeKeyFromInventory({cont = object, player = actor})
   --return false
end
local function onLoad(data)
if(acti == nil ) then
          for i, actor in ipairs(world.activeActors) do
      actor:sendEvent("ZHAC_ShowMessage","The activation library couldn't be found for FindAllKeys, this indicates that you're using a version older than what this mod requires. Please update to the newest OpenMW build.")
end
return
else

acti.addHandlerForType(types.NPC, NPCActivate)
end
   if(data) then
      checkPlaced = data
   end


end
local function onSave()
   return checkPlaced

end
local function sendToMWScript(xplayer)
   if(checkPlaced == false) then
      local sccellitems = world.getCellByName("ToddTest"):getAll(types.Miscellaneous)
      if(sccellitems == nil ) then
        -- print("Cell is nil")
         return
      end
      local keyItem = nil 
      for i, item in ipairs(sccellitems) do
         if(item.recordId == "zhac_scriptchecker") then
            keyItem = item
         end
      end
      if(keyItem == nil ) then
        -- print("Cell is nil")
         return
      end
      if(xplayer) then

         keyItem:teleport(xplayer.cell,xplayer.position)
         checkPlaced = true
         return
      end
      if(activeActors == nil ) then
        -- print("activeActors is nil")
         return
      end
      for i, actor in ipairs(world.activeActors) do
         if (actor.type == types.Player  and keyItem) then
            keyItem:teleport(actor.cell,actor.position)
         end

      end
    --  print("Sent to MWScript")
      checkPlaced = true
   end

end
local function contentFileCheck(xplayer)
if(acti == nil ) then
      for i, actor in ipairs(world.activeActors) do
      actor:sendEvent("ZHAC_ShowMessage","The activation library couldn't be found for FindAllKeys, this indicates that you're using a version older than what this mod requires. Please update to the newest OpenMW build.")
end
return
else

acti.addHandlerForType(types.NPC, NPCActivate)
end
   player = xplayer
   local miscitems = types.Miscellaneous.records
   for i, record in ipairs(miscitems) do
      if(record.id == "zhac_placeholderkey") then
        -- print("Found record")
         sendToMWScript(xplayer)
         return true
      end
   end

   if(player ~= nil ) then
      player:sendEvent("ZHAC_ShowMessage","You do not have the DetectAllKeys OmwAddon checked! The mod will not work.")
   else
      for i, actor in ipairs(world.activeActors) do
         if (actor.type == types.Player  ) then
            actor:sendEvent("ZHAC_ShowMessage","You do not have the DetectAllKeys OmwAddon checked! The mod will not work.")

         end

      end
   end

   return false
end
local function onInit()
if(acti == nil ) then
 for i, actor in ipairs(world.activeActors) do
         if (actor.type == types.Player  ) then
            actor:sendEvent("ZHAC_ShowMessage","The activation library couldn't be found, this indicates that you're using a version older than what this mod requires. Please update to the newest OpenMW build.")

         end

      end
return
else

acti.addHandlerForType(types.NPC, NPCActivate)
end
   sendToMWScript()

end
local function onActivate(object,actor)
   itemlist = actor.cell:getAll(types.Miscellaneous)
   for i, item in ipairs(itemlist) do
      if(item.recordId == "zhac_placeholderkey" and item.position == object.position) then
         item:remove()
        -- print("Removed found item")
      end
   end
end
return {
   eventHandlers = {
      addKeyToInventory = addKeyToInventory,
      removeKeyFromInventory = removeKeyFromInventory,
      findAllKeys = findAllKeys,
      sendToMWScript = sendToMWScript,
   },
   engineHandlers = {
      onActivate = onActivate,
      onItemActive = onItemActive,
      onInit = contentFileCheck,
      onLoad = onSave,
      onLoad = onLoad,
      onPlayerAdded = contentFileCheck,
   }
}
