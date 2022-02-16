--[[
Self swap dressing mannequins

by

The Wanderer
--]]

local messageBox = require("tw.MessageBox")

----------------------------------------------------------------------------------------------------
local function swapDress(e)
--[[
This will swap what the player is wearing with what the mannequin is wearing and vis versa
It will also transfer anything else that was manually added to the mannequin to the player.

If mod is installed ALL mannequins will become my swap ones

--]] 

 local chest = tes3.getReference("tw_selfdressing_cont")
 local ref = e.target.id:lower()

        local itemsToTransfer = {}
        
        for _, stack in pairs(tes3.player.object.inventory) do
            -- Queue our transfer until we're done searching the inventory.    
            if mwscript.hasItemEquipped({reference = tes3.player, item = stack.object }) then  
               if (stack.object.objectType == tes3.objectType.armor) or
                  (stack.object.objectType == tes3.objectType.clothing ) then
                  --( stack.object.type == "weapon" ) then -- can be added manually.
                  -- we only want the stuff the player is wearing it
                  itemsToTransfer[stack.object] = 1 --stack.count
               end
            end      
        end
        
        -- Did we find anything we want to transfer? Yes put it in the dressing chest
        if (not table.empty(itemsToTransfer)) then
           for item, count in pairs(itemsToTransfer) do        
               if count >= 1 then  -- it is what they where wareing so should only ever be one !!!!
                   tes3.transferItem({ from = tes3.player, to = chest, item = item, count = count })
               end
           end
        end          
  
 
-- Tranfer everything on or in the mannequin to player 
  itemsToTransfer = {}
  local obj = e.target.object
  local ref = tes3.getReference(obj.id) -- this should now be the mannequin. 
  
  for item, stack in pairs(ref.object.inventory) do
      -- Queue our transfer until we're done searching the inventory.    
      itemsToTransfer[stack.object] = stack.count
  end            
  if (not table.empty(itemsToTransfer)) then
     for item, stack in pairs(itemsToTransfer) do        
        if stack > 0 then
            tes3.transferItem{from=ref, to=tes3.player, item=item, count=stack}
            -- Doesn't appear to detect gold ???
            -- or enchanted ring
            if (item.objectType == tes3.objectType.armor) or
               (item.objectType == tes3.objectType.clothing ) then
               -- force equip-player
               mwscript.equip{ reference = tes3.player, item = item }
            end
        end
     end
     -- Manneqin should now be empty.
  end

-- Transfer dressing chest content to manniquin. Should only be equipable items.
  for i, stack in pairs(chest.object.inventory) do
      --tes3.transferItem{from = chest, to = ref, item = stack.object, count = stack.count } --, playSound=true}
      mwscript.equip{ reference = ref, item = stack.object }
      mwscript.removeItem{ reference = chest, item = stack.object, count = stack.count }
  end
end

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
local function onActivateMannequins(e)
  
    if not (e.activator == tes3.player) then -- Just in case.
          return
    end
   
  local short = dofile("tw.mannequins")
  
  if short[string.sub(e.target.id:lower(), 1, 10)] then
            local data = e.target.id:lower()  --short[e.target.id:lower()]
            local xRef = tes3.getReference( data ) --eitem.id )
                 
      if AllowActivate then
         AllowActivate = false
      else
          -- This is not genaric and would need further work to make it so.
          messageBox{
                message = "What do you want to do?",
                buttons = {{ text = "Swap",   callback = function() swapDress(e)    end },
                           { text = "Open",   callback = function() AllowActivate = true; tes3.player:activate(e.target) end }, 
                           { text = "Cancel", callback = function() return false    end }}              
                    }
          
          return false
      end         
  end
  
end
event.register("activate", onActivateMannequins)

----------------------------------------------------------------------------------------------------