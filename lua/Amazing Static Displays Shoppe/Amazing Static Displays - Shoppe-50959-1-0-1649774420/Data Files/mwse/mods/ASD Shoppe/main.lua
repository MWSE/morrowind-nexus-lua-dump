--[[
Amazing Static Display Shoppe
by 
The Wanderer

Requires:
tw_asd_01.esp
tw_asd_general_cont.esp
tw_asd_armor_cont.esp
tw_asd_crates_cont.esp
tw_asd_library_cont.esp
tw_asd_clothing.esp   -- Bob's
tw_asd_weapons.esp    -- Bob's

local modList = tes3.getModList()
if ( modlist[ "tw_asd_general_cont.esp" ] )
mwse.log("*** general_cont")
end
-]]

local messageBox = require("tw.asditems") 
local messageBox = require("tw.MessageBox")

mwse.log("[Amazing Static Display, Shoppe] Loaded successfully.")

----------------------------------------------------------------------------------------------------
local function ASDStoreSet(e)
  
-- Get the original misc display and create the container replacement  
  local cell     = e.target.cell
  local position = e.target.position:copy()
  local rotation = e.target.sceneNode.rotation:copy()
  local scale    = e.target.scale
  
  local container = string.sub( e.target.id,  1, -5 )   -- misc
  if ( string.sub( e.target.id, 1, -8 ) == "tw_clothing_" ) then --containe
    container = string.format("%s%s", container, "containe" )
  else
    container = string.format("%s%s", container, "cont" )
  end
mwse.log("*** container = %s", container )

  local ContRef  = tes3.createReference{ 
                        object   = tes3.getReference(container).object,
                        position = position,
                        cell = cell
                       }
  ContRef.orientation = rotation
  ContRef.scale = scale
 
 tes3.setEnabled({ reference = e.target, enabled = false })  --- disable misc item 
  
end

----------------------------------------------------------------------------------------------------
local function ASDPlaceholder(target)

local item
local itemlist
local misc

  --if target.activator == tes3.player then - can it ever be anyone else !?!?!?
  if ( string.sub( target:lower(), -3 ) == "act" ) then
     item = string.sub( target:lower(),  1, -4 )
     itemlist = dofile("tw.asditems")
    
  elseif  ( string.sub( target:lower(), -9 ) == "activator" ) then  
     item = string.sub( target:lower(),  1, -10)
     itemlist = dofile("tw.asditems")
    
  end
  
  mwse.log("*** item = %s", item)
  if ( item ~= nil ) then
    if itemlist[ item:lower() ] then -- string.sub("%s%s", e.target.id:lower() ) then  -- , "act") ] then
    
      misc = string.format("%s%s", item, "misc")
      misc = tes3.getReference( misc )
 
  
      if ( misc ) then     
          tes3.messageBox("You have been given placeholder %s", misc )
          --Add placeholder to the player's inventory manually.
          tes3.addItem({
            reference = tes3.player,
            item = misc.id,
            count = 1,
            playSound = true,
          })
         
         return false
      end
    end
    
  elseif ( string.sub( target:lower(), -4 ) == "misc" ) then
    local item = string.sub( target:lower(),  1, -4 )
    if itemlist[ item ] then
      return
    end
  end
end

----------------------------------------------------------------------------------------------------
local function onStorePickup(e  )--, target)
  
  tes3.setEnabled({ reference = e.target, enabled = false })  --- disable misc item
  local misc = e.target   ---string.format("%s%s", e.target, "misc" )
  
  if ( misc ~= nil ) then
    tes3.addItem({
          reference = tes3.player,
          item = misc.id,
          count = 1,
          playSound = true,
        })
  end      
end

----------------------------------------------------------------------------------------------------
local function ASD_Activate(e)

    local cell =  e.target.cell.id  -- filter for our shoppe and activator 
    if ( string.sub(cell,  1, 4 ):lower() == "asd," ) then
    --if ( cell == "ASD" ) then  -- this should pick all the different cels ?!?!     
      if ( string.sub( e.target.id, -3 ) == "act" ) or
         ( string.sub( e.target.id, -9 ) == "activator" ) then
           
        ASDPlaceholder(e.target.id)  
        
        return
      end  
    end    
       
    if ( string.sub( e.target.id, -4 ) == "misc" ) then  -- filter for misc items.
      local itemlist = dofile("tw.asditems")
      local item = string.sub( e.target.id,  1, -5 )   
      if itemlist[ item:lower() ] then      -- is it one of ours ?
          messageBox {
            message = "What do you want to do?",
            buttons = {
                { text = "Set"    , callback = function() ASDStoreSet(e)   end },
                { text = "Pick-up", callback = function() onStorePickup(e) end }
               } }
        
         return false
         
      end
      
      return
      
    end   

end
event.register( "activate", ASD_Activate )

----------------------------------------------------------------------------------------------------
