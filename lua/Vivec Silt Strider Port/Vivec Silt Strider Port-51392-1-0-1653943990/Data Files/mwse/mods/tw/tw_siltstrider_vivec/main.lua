--[[
Silt Strider Port - Vivec
by
The Wanderer
--]]
----------------------------------------------------------------------------------------------------

mwse.log("[Silt Strider Schedule] Loaded successfully.")

----------------------------------------------------------------------------------------------------
local function moveNPC()
  
    local region = tes3.getRegion()
    local weather = region.weather.index
    local time = math.round(tes3.worldController.hour.value)

    local position
    local rotation
    
    if ( time >= 12 and time < 14 ) or
      ( time >= 17 and time < 19 ) or
      ( time >= 22) or
      ( time <= 7 ) or
      ( weather > 3 ) then
    
      position = {31160, -72239, 866}
      rotation = {0,0,2}  
    
    else 
      --Day <= 07:00 –  >= 22:00
      position = {32391,-72175,927}
      rotation = {0,0,-2}
    
    end

    tes3.positionCell({ reference = tes3.getReference("Adondasi Sadalvel"), 
                      cell = "Vivec", 
                      position    = position, 
                      orientation = rotation,
                      forceCellChange = false,  
                   })
    -- Seem to get a problem with position so have to do it twice ???
    tes3.positionCell({ reference = tes3.getReference("Adondasi Sadalvel"), 
                      cell = "Vivec", 
                      position    = position, 
                      orientation = rotation,
                      forceCellChange = false,  
                   })    
                 
end                 
----------------------------------------------------------------------------------------------------
local function onCellChangeSSPort(e)

  local cell = tes3.getPlayerCell()  

  if ( cell.id == "Vivec" ) then 
      
      moveNPC()

  end
end
event.register("cellChanged", onCellChangeSSPort)
