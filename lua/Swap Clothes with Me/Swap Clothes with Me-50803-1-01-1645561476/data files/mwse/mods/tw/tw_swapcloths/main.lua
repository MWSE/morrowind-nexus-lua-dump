--[[

This will probably be classed as a huge cheat... you have been warned

This will swap your clothes with the close of the NPC you are looking at.
If you don't want them to have your clothes then just remove them first.. .this of course will leave them naked.

Swap Clothes
by 
The Wanderer
--]]

mwse.log("[Swap clothes - cheat] Loaded successfully.")

----------------------------------------------------------------------------------------------------
local function tempchest()
  
  local position = tes3.player.position:copy()
    position = {
        position.x,
        position.y,
        position.z + -500 ,
        }
    local container = tes3.createReference{
        object = "chest_small_01",
        position = position,
        orientation = tes3.player.orientation:copy(),
        cell = tes3.player.cell
    }
  
  return container
    
end

----------------------------------------------------------------------------------------------------
local function swapall(target)

 local chest = tempchest()    --tes3.getReference("tw_selfdressing_cont")
 
 local ref = target.id:lower()

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
  local obj = target.object
  local ref = tes3.getReference(obj.id) -- this should now be the npc
  
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
  
  if (chest ~= nil ) then
     -- remove chest
     tes3.setEnabled({ reference = chest, enabled = false })    
  end
  
end

----------------------------------------------------------------------------------------------------
local function SwapClotheswithNPC(e)
  
if ( e.source.id == "tw_swapclothes" ) then  -- is it my spell ?!?!?
  
-- Get the player's target.
	local target = tes3.getPlayerTarget()
	if (target == nil) then
      return
	elseif ( target.object.objectType == tes3.objectType.npc ) then
      swapall(target)      
  end
end  
end

----------------------------------------------------------------------------------------------------
local function onLoadSwap()
  
  local hasSpell = tes3.getObject("tw_swapclothes")
  if hasSpell ~= true then
    local params = { id = "tw_swapclothes", name = "Swap Clothes" }
    local spell = tes3.getObject(params.id) or tes3spell.create(params.id, params.name )
    
    if spell ~= nil then    
      spell.magickaCost = 0
      --spell.castchance = 100   -- doesn't appear to do anything :(
      local effect = spell.effects[1]
      effect.id = 59   -- 126 EXTRASPELL - Conjuration
      effect.rangeType = tes3.effectRange.target
      effect.min = 0
      effect.max = 0
      effect.duration = 0
      -- give them the spell if they don't have it 
      mwscript.addSpell({reference = tes3.player, spell = spell})
      
    end
  end  
end  
event.register("loaded", onLoadSwap)    

local function onInitialized(e)
  
    event.register("spellCast", SwapClotheswithNPC )  --, {filter = tes3.getObject("tw_swapclothes")} )    

end
event.register(tes3.event.initialized, onInitialized)  
