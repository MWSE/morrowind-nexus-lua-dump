--[[

The Dressing Room 
by
The wanderer

A walk-in wardrobe travel to via a key - return to where you came from with the same key.
Clousd stroage compatible

--]]
mwse.log("[Dressing Room] Loaded successfully.")

local function setDoOnce(ref,Var)
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.tw_wardrobe = refData.tw_wardrobe or {} -- Force initializing the parent table.
    refData.tw_wardrobe.doOnce = Var -- Actually set your value.
end

local function getDoOnce(ref)
    local refData = ref.data
    return refData.tw_wardrobe and refData.tw_wardrobe.doOnce
end
-------------------------------------------------------------------------
local function onLoadDressingRoom(e)

--Only give them the teleportation key once.
  if getDoOnce(e.reference) ~= true then
    setDoOnce(e.reference, true)
    mwscript.addItem({ reference = tes3.player, item = "tw_dressing_room_key", count = 1 })
    tes3.messageBox("You have been given the key to your new Dressing Room." )
  end

end
event.register("loaded", onLoadDressingRoom)

----------------------------------------------------------------------------------------------------
local function setMark()
   
    local eRef = tes3.player
    -- save current location when key is equiped to return to 
    local refData = eRef.data -- Crossing the C-Lua border result is usually not a bad idea.                   
    local p = tes3.player.position
    local r = tes3.player.orientation
    refData.tw_wardrobe = { 
        cell = tes3.player.cell.id,
        pos  = {p.x, p.y, p.z},
        rot  = {r.x, r.y, r.z},
    }                      
                                       
end

----------------------------------------------------------------------------------------------------
local function onActivateDressingRoom(e)
  

if (e.item.id:lower() == "tw_dressing_room_key") then
  
    tes3.playSound{ reference = tes3.player, sound = "mysticism hit"}   
       
    local eRef = tes3.player
    local cell = tes3.getPlayerCell()
    if cell.id == "tw_wardrobe" then
    -- to send them back from wence they came....    
      local lcell = eRef.data.tw_wardrobe.cell
      local lpos  = eRef.data.tw_wardrobe.pos
      local lrot  = eRef.data.tw_wardrobe.rot
      
       -- Send them back
       tes3.positionCell({ reference = tes3.player, 
                           cell = lcell, 
                           position = lpos, 
                           orientation = lrot, 
                           forceCellChange = false, 
                           suppressFader = false, 
                           teleportCompanions = false })      
    
  else    
    

      -- send them to the Dressing Room and register where they come from      
       setMark()
       tes3.positionCell({ reference = tes3.player, 
                           cell = "tw_wardrobe", 
                           position = { 44, -218, 60 }, 
                           orientation = {0,0,0}, 
                           forceCellChange = false, 
                           suppressFader = false, 
                           teleportCompanions = false })
       
    end
end

end
event.register("equip", onActivateDressingRoom, { filter = tes3.getObject("tw_dressing_room_key") })