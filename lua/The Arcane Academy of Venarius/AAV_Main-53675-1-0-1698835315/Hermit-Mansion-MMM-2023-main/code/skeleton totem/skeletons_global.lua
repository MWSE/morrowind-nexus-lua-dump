local world = require('openmw.world')
local types = require('openmw.types')
local core = require('openmw.core')

local skels

local function onObjectActive(object)
  if object.recordId == string.lower("AAV_T_Imp_Set_Shrine_Shor") then 
    if object:hasScript("skeleton totem/skeletons_totem.lua") == false then -- not sure if needed
      object:addScript("skeleton totem/skeletons_totem.lua") -- add the totem script
    end
  end
end

local function funcname1(var1)
   if skels == nil then -- initialize skels variable and don't touch again
       skels = 0
   end

   if skels <= 5 then -- if fewer or 5, summons six skeletons       
     local skeleton = world.createObject ("AAV_skeleton_warrior", 1) -- the summoned skeleton
      
     skeleton:teleport("The Arcane Academy of Venarius, Training Room", var1.creatureself.position ) -- the cell and enemy
     skeleton:addScript("skeleton totem/skeletons_skeletons.lua")
     
     --skeleton:sendEvent('StartAIPackage', {type='Follow', target=player, sideWithTarget = true } )
                -- another way to do the AI set     
     
     skels = skels + 1  -- increment the amount of skeletons up                    
   end

end

local function funcname2(var2)
 
      skels = skels - 1 -- increment the amount of skeletons down
      var2.skel:remove()
 
      --print("remove")
      
      --world.createObject("AB_Fx_LavaBubbles",1):teleport("The Arcane Academy of Venarius, Training Room",var2.skel.position)
        -- object to teleport in place of death
      
end

return { eventHandlers = { madgodmissingmarbles_addskel = funcname1, madgodmissingmarbles_removeskel = funcname2 },
         engineHandlers = { onObjectActive = onObjectActive } } 
         
