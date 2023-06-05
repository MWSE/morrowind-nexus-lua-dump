local util = require("openmw.util")
local core = require("openmw.core")
local self = require("openmw.self")
local types = require("openmw.types")
local nearby = require("openmw.nearby")
local inv = nil

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


local function onActive()
   if(self.type == types.Container) then
      if(types.Container.capacity(self) == 0) then
         return--if capacity is 0, than this is a plant and shouldn't have any keys.
      end
      inv = types.Container.content(self)
   elseif(self.type == types.Actor) then
      inv = types.Actor.inventory(self)
   elseif(self.type == types.NPC) then
      inv = types.Actor.inventory(self)
   end

   if(inv) then
      if(inv.find == nil ) then

         for i, actor in ipairs(nearby.actors) do
            if (actor.type == types.Player ) then
               actor:sendEvent("ZHAC_ShowMessage","The activation library couldn't be found for FindAllKeys, this indicates that you're using a version older than what this mod requires. Please update to the newest OpenMW build.")
         return

            end

         end

      end
     local itemcheck = inv:find("ZHAC_PlaceholderKey")
      if(itemcheck == nil) then
         local miscItems = inv:getAll(types.Miscellaneous)
         for i, item in ipairs(miscItems) do
            if(checkIsKey(types.Miscellaneous.record(item))) then
               core.sendGlobalEvent("addKeyToInventory",self)
            end
         end
      end
   end
end



local function onActivated(actor)
   for i, actor in ipairs(nearby.actors) do
      if (actor.type == types.Player and self.type == types.Container) then
         core.sendGlobalEvent("removeKeyFromInventory",{cont = self,player = actor})

      end

   end
end
return {
   eventHandlers = {
      sendMessage = sendMessage,
      returnActivators = returnActivators,
      recieveActivators = recieveActivators,

   },
   engineHandlers = {
      onActive = onActive,
      onUpdate = onUpdate,
      onActivated = onActivated,
   }
}
