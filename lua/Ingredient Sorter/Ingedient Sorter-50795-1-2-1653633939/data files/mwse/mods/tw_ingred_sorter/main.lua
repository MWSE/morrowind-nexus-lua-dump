--[[
Ingredient Sorter
by
The Wanderer

This is an ingredient sorter for my Ingredient Boxes.
--]]

local messageBox = require("tw.boxes") 

mwse.log("[Ingredient boxes sorter] Loaded successfully.")

----------------------------------------------------------------------------------------------------
local function recoverIngredients(e)  
  
  if ( e.source.id == "tw_ingredrecover" ) then  -- only if it's my spell
  --mwse.log("** recover **" )

    local boxes = dofile("tw.boxes")
    local cell = tes3.player.cell
    
    for container in cell:iterateReferences(tes3.objectType.container) do  -- check all containers in cell.
        if ( string.sub(container.id:lower(), 1, 5 ) == "ss_a_" ) or
           ( string.sub(container.id:lower(), 1, 7 ) == "rrfm_z_" ) or -- then   -- River Rock Falls boxes
           ( string.sub(container.id:lower(), 1, 5 ) == "ss_z_" ) then
          local ref = tes3.getReference(container.id)    
          for i, stack in pairs(ref.object.inventory) do
              --tes3.transferItem{from=ref, to=tes3.player, item=stack.object, count=stack.count, playSound=true}

              tes3.transferItem({
                    from = ref,
                    to = tes3.player,
                    item = stack.object,
                    count = stack.count,
                    limitCapacity = false,
                    playSound = true,
                    updateGUI = false,
              })
          end   
        end
    end
    -- Be sure to update the player/target GUIs since we were doing batching earlier.
    tes3.updateInventoryGUI({ reference = tes3.player })
    tes3.updateMagicGUI({ reference = tes3.player })
    tes3.updateInventoryGUI({ reference = target })
    tes3.updateMagicGUI({ reference = target })
    
    tes3.messageBox("All your ingredients have been returned.")
  
  end
end
 
----------------------------------------------------------------------------------------------------
local function StoreIngredients(e) 
   
if ( e.source.id == "tw_ingredSort" ) then   -- only if it's my spell
     
    local itemsToTransfer = {} ---@type table<tes3item, number>

    for _, stack in pairs(tes3.player.object.inventory) do
      
        if (stack.object.objectType == tes3.objectType.ingredient) then
            -- Queue our transfer until we're done searching the inventory.    
            if stack.count >= 1 then
               itemsToTransfer[stack.object] = stack.count  

            end
        end
    end

    -- Did we find any ingredients to transfer?
    if (table.empty(itemsToTransfer)) then
        tes3.messageBox("No ingredients found to transfer.")  
    else
      -- are there my ingredient boxes in this cell.
      local cell = tes3.player.cell
      -- get master list from tw.lib.boxes.lua
      local boxes = dofile("tw.boxes")   
      local addbox 
      local foundBox = false
      
      for container in cell:iterateReferences(tes3.objectType.container) do  -- check all containers in cell.
        usebox= 0
        if container ~= nil then
          if ( string.sub(container.id:lower(), 1, 5 ) == "ss_a_" ) then 
              usebox = 1
          elseif ( string.sub(container.id:lower(), 1, 7 ) == "rrfm_z_" ) then   --or
             usebox = 2
          elseif ( string.sub(container.id:lower(), 1, 5 ) == "ss_z_" ) then   --or
             usebox = 3
          end
          
          if usebox ~= 0 then
            foundBox = true  -- we found at least one box in the cell.
            -- this should now be one of my ingredient boxes.
            for item, count in pairs(itemsToTransfer) do  
                if boxes[ item.id:lower() ] then
                  local boxData = boxes[item.id:lower()]
                  if boxData then
                      if usebox == 1 then
                         addbox = boxData.box 
                      elseif usebox == 2 then
                         addbox = boxData.box2
                      elseif usebox == 3 then
                         addbox = boxData.box3
                      end
                         
                      if tes3.getReference(addbox) ~= nil then
                        --tes3.transferItem( {from = tes3.player, to = addbox, item = item, count = count, playSound = true} )
                       
                        tes3.transferItem({
                              from = tes3.player,
                              to = addbox,
                              item = item,
                              count = count,
                              limitCapacity = false,
                              playSound = true,
                              updateGUI = false,
                        })
                     end
                  end
                end
            end
          end
        end
      end
      -- Be sure to update the player/target GUIs since we were doing batching earlier.
      tes3.updateInventoryGUI({ reference = tes3.player })
      tes3.updateMagicGUI({ reference = tes3.player })
      tes3.updateInventoryGUI({ reference = target })
      tes3.updateMagicGUI({ reference = target })
    end  
  end 
  
e.castchance = 100   -- doesn't appear to work spell can still report failure to cast :(

end  

----------------------------------------------------------------------------------------------------
local function onLoadIngred()
  
  local hasSpell = tes3.getObject("tw_ingredSort")
  
  if hasSpell ~= true then
    local params = { id = "tw_ingredSort", name = "Sort Ingredients" } 
    local spell = tes3.getObject(params.id) or tes3spell.create(params.id, params.name )
    
    if spell ~= nil then  -- this for some reason now returns nil everytime !!!
    
      spell.magickaCost = 0
      --spell.castchance = 100   -- doesn't appear to do anything :(
      local effect = spell.effects[1]
      effect.id = 59   -- 126 EXTRASPELL - Conjuration
      effect.rangeType = tes3.effectRange.self
      effect.min = 0
      effect.max = 0
      effect.duration = 0
      -- give them the spell if they don't have it 
      mwscript.addSpell({reference = tes3.player, spell = spell})
      
    end
  end     
  
--=-=-=-=-=  
  hasSpell = tes3.getObject("tw_ingredrecover")
  if hasSpell ~= true then

    local params = { id = "tw_ingredrecover", name = "Recover Ingredients" } 
    local spell = tes3.getObject(params.id) or tes3spell.create(params.id, params.name ) 
    
    if spell ~= nil then
    
      spell.magickaCost = 0
      --spell.castchance = 100   -- doesn't appear to do anything :(
      local effect = spell.effects[1]
      effect.id = 59   -- 126 EXTRASPELL - Conjuration
      effect.rangeType = tes3.effectRange.self
      effect.min = 0
      effect.max = 0
      effect.duration = 0
      -- give them the spell if they don't have it 
      mwscript.addSpell({reference = tes3.player, spell = spell})
      
    end
  end   
end
event.register("loaded", onLoadIngred)    

local function onInitialized(e)
  
    event.register("spellCast", recoverIngredients )      
    event.register("spellCast", StoreIngredients   )  

end
event.register(tes3.event.initialized, onInitialized)


    
