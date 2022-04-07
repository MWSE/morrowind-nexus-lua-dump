--[[
A Maze Inn
by
The Wanderer

This is an Inn on the edge of Pelagiad
Ask the innkeeper about the maze under their Inn.

--]]

mwse.log("[A Maze Inn] Loaded successfully.")

local mazel2

-------------------------------------------------------------------------
local function resetContainers(cell)

  local itemsToTransfer = {}
  for ref in cell:iterateReferences(tes3.objectType.container) do
      itemsToTransfer[ref] = 1 --ref.count
  end  
  
  -- Did we find anything we want to restock?
  if (not table.empty(itemsToTransfer)) then
      for item, count in pairs(itemsToTransfer) do  
          local container = item
          -- Replace original ???
          -- Get current location
          local position = container.position:copy()
          position = {
              position.x,
              position.y,
              position.z,
            }
          -- remove original  
          tes3.setEnabled({ reference = container, enabled = false })
          -- creat new instance - respawn content.
          local container = tes3.createReference{
              object = container.object,
              position = position,
              orientation = container.orientation:copy(),
              cell = tes3.player.cell
          }
      end
  end
end

-------------------------------------------------------------------------
local function resetCreatures(cell)
  
  for ref in cell:iterateReferences(tes3.objectType.creature or tes3.objectType.npc) do
      local creature = ref  --.object
      tes3.runLegacyScript({ command = "resurrect", reference = creature } )   -- it seems this is all that is needed.
      tes3.runLegacyScript({ command = "ra", reference = creature })           -- put them back to their origin
  end
  
end

-------------------------------------------------------------------------
local function ReSetLevel1()
-- reset all L1 on/before leaveing 

  local door = tes3.getReference( "bar_door_maze01" )
-- How to close door fist ???  or does locking it also close it ???
  tes3.lock({ reference = door })
  tes3.setLockLevel({ reference = door, level = 100 })
  
  local cell = tes3.getPlayerCell()
  resetContainers(cell)
  resetCreatures(cell)

end

-------------------------------------------------------------------------
local function ReSetLevel2()
-- reset all L2 on/before leaveing 
  xRef = tes3.getReference( "misc_skull_mazel2_01_act" ) 
  tes3.setEnabled({ reference = xRef, enabled = true })  -- enable key
  xRef = tes3.getReference( "in_maze_walll2_01" ) 
  tes3.setEnabled({ reference = xRef, enabled = true })  -- enable wall    
  
  xRef = tes3.getReference( "misc_skull_mazel2_02_act" ) 
  tes3.setEnabled({ reference = xRef, enabled = true })  -- enable key
  xRef = tes3.getReference( "in_maze_walll2_02" )
  tes3.setEnabled({ reference = xRef, enabled = true })  -- enable wall
  
  xRef = tes3.getReference( "misc_skull_mazel2_03_act" ) 
  tes3.setEnabled({ reference = xRef, enabled = true })  -- enable key
  xRef = tes3.getReference( "in_maze_walll2_03" ) 
  tes3.setEnabled({ reference = xRef, enabled = true })  -- enable wall 
  
  xRef = tes3.getReference( "misc_skull_mazel2_04_act" ) 
  tes3.setEnabled({ reference = xRef, enabled = true })  -- enable key
  xRef = tes3.getReference( "in_maze_walll2_04" ) 
  tes3.setEnabled({ reference = xRef, enabled = true })  -- enable wall 
  
  xRef = tes3.getReference( "misc_skull_mazel2_05_act" ) 
  tes3.setEnabled({ reference = xRef, enabled = true })  -- enable key
  xRef = tes3.getReference( "in_maze_walll2_05" )
  tes3.setEnabled({ reference = xRef, enabled = true })  -- enable wall

  xRef = tes3.getReference( "in_maze_walll2_00" ) 
  tes3.setEnabled({ reference = xRef, enabled = true })  -- enable final wall  
  
  local cell = tes3.getPlayerCell()
  resetContainers(cell)  
  resetCreatures(cell)
  
end

-------------------------------------------------------------------------
local function ReSetLevel3()
-- reset all L3 on/before leaveing 
    xRef = tes3.getReference( "misc_skull_mazel3_01_act" ) 
    tes3.setEnabled({ reference = xRef, enabled = true })  -- enable key
    xRef = tes3.getReference( "in_maze_walll3_01" )
    tes3.setEnabled({ reference = xRef, enabled = true })  -- enable wall

    xRef = tes3.getReference( "misc_skull_mazel3_02_act" ) 
    tes3.setEnabled({ reference = xRef, enabled = true })  -- enable key
    xRef = tes3.getReference( "in_maze_walll3_02" )
    tes3.setEnabled({ reference = xRef, enabled = true })  -- enable wall
    xRef = tes3.getReference( "in_maze_walll3_03" )
    tes3.setEnabled({ reference = xRef, enabled = true })  -- disable wall
    
    xRef = tes3.getReference( "misc_skull_mazel3_03_act" ) 
    tes3.setEnabled({ reference = xRef, enabled = true })  -- disable key
    xRef = tes3.getReference( "in_maze_walll3_04" )
    tes3.setEnabled({ reference = xRef, enabled = true })  -- disable wall
    
  local cell = tes3.getPlayerCell()
  resetContainers(cell)  
  resetCreatures(cell)
  
end

-------------------------------------------------------------------------
local function ReSetLevel4()
-- reset all L4 on/before leaveing 
  local cell = tes3.getPlayerCell()
  resetContainers(cell)  
  resetCreatures(cell)
  
end

-------------------------------------------------------------------------
local function ReSetLevel5()
-- reset all L5 on/before leaveing 
  local cell = tes3.getPlayerCell()
  resetContainers(cell)  
  resetCreatures(cell)

end

-------------------------------------------------------------------------
-- Control the teleporting and disabling of all walls in the Maze
local function onActivateMaze(e)
local xRef = nil

  local cell = tes3.getPlayerCell()
  if ( string.sub(cell.id:lower(), 1, 6 ):lower() == "a maze" ) then -- only if it's one of mine.
    if (e.target.id == "maze_key_l1_act") then
      mazel2 = 0
      ReSetLevel1()
      --Player->PositionCell -34, -721, 80, 0, "a maze, l2" -- put them at the start of Level two
      tes3.playSound{ reference = tes3.player, sound = "blackoutin" } 
      tes3.positionCell({ reference = tes3.player, 
                      cell = "a maze, l2", 
                      position = { -34, -721, 80 }, 
                      orientation = {0,0,0}, 
                      forceCellChange = false, 
                      suppressFader = false, 
                      teleportCompanions = false })
                          
    elseif (e.target.id == "maze_key_l2_act") then
      mazel2 = 0  -- reset count
      ReSetLevel2()
      tes3.playSound{ reference = tes3.player, sound = "blackoutin" }    
      --Player->PositionCell 16, 16, 80, 0, "a maze, l3" -- put them at the start of Level three
      tes3.positionCell({ reference = tes3.player, 
                  cell = "a maze, l3", 
                  position = { 16, 16, 80 }, 
                  orientation = {0,0,0}, 
                  forceCellChange = false, 
                  suppressFader = false, 
                  teleportCompanions = false })
      
    elseif (e.target.id == "misc_skull_mazel2_01_act") then
      xRef = tes3.getReference( "misc_skull_mazel2_01_act" ) 
      tes3.setEnabled({ reference = xRef, enabled = false })  -- disable key
      xRef = tes3.getReference( "in_maze_walll2_01" ) 
      tes3.setEnabled({ reference = xRef, enabled = false })  -- disable wall 
      tes3.playSound{ reference = tes3.player, sound = "Door Stone open" }  -- blackoutin
      
      mazel2 = mazel2 + 1
      tes3.messageBox("Found %s of 4 skull keys", mazel2 )
      if ( mazel2 >= 4 ) then
        tes3.messageBox("The way out is now clear.")
        xRef = tes3.getReference( "in_maze_walll2_00" ) 
        tes3.setEnabled({ reference = xRef, enabled = false })  -- disable final wall 
            tes3.playSound{ reference = tes3.player, sound = "Door Stone open" }
      end

    elseif (e.target.id == "misc_skull_mazel2_02_act") then
      xRef = tes3.getReference( "misc_skull_mazel2_02_act" ) 
      tes3.setEnabled({ reference = xRef, enabled = false })  -- disable key
      xRef = tes3.getReference( "in_maze_walll2_02" ) 
      tes3.setEnabled({ reference = xRef, enabled = false })  -- disable wall  
      tes3.playSound{ reference = tes3.player, sound = "Door Stone open" }
      
      mazel2 = mazel2 + 1
      tes3.messageBox("Found %s of 4 skull keys", mazel2 )
      if ( mazel2 >= 4 ) then
        tes3.messageBox("The way out is now clear.")
        xRef = tes3.getReference( "in_maze_walll2_00" ) 
        tes3.setEnabled({ reference = xRef, enabled = false })  -- disable final wall 
        tes3.playSound{ reference = tes3.player, sound = "Door Stone open" }
      end

    elseif (e.target.id == "misc_skull_mazel2_03_act") then
      xRef = tes3.getReference( "misc_skull_mazel2_03_act" ) 
      tes3.setEnabled({ reference = xRef, enabled = false })  -- disable key
      xRef = tes3.getReference( "in_maze_walll2_03" ) 
      tes3.setEnabled({ reference = xRef, enabled = false })  -- disable wall 
      tes3.playSound{ reference = tes3.player, sound = "Door Stone open" }
      
      mazel2 = mazel2 + 1
      tes3.messageBox("Found %s of 4 skull keys", mazel2 )
      if ( mazel2 >= 4 ) then
        tes3.messageBox("The way out is now clear.")
        xRef = tes3.getReference( "in_maze_walll2_00" ) 
        tes3.setEnabled({ reference = xRef, enabled = false })  -- disable final wall
        tes3.playSound{ reference = tes3.player, sound = "Door Stone open" }
      end

    elseif (e.target.id == "misc_skull_mazel2_04_act") then
      xRef = tes3.getReference( "misc_skull_mazel2_04_act" ) 
      tes3.setEnabled({ reference = xRef, enabled = false })  -- disable key
      xRef = tes3.getReference( "in_maze_walll2_04" ) 
      tes3.setEnabled({ reference = xRef, enabled = false })  -- disable wall 
      tes3.playSound{ reference = tes3.player, sound = "Door Stone open" }
      
      mazel2 = mazel2 + 1
      tes3.messageBox("Found %s of 4 skull keys", mazel2 )
      if ( mazel2 >= 4 ) then
        tes3.messageBox("The way out is now clear.")
        xRef = tes3.getReference( "in_maze_walll2_00" ) 
        tes3.setEnabled({ reference = xRef, enabled = false })  -- disable final wall 
        tes3.playSound{ reference = tes3.player, sound = "Door Stone open" }
      end
    
    elseif (e.target.id == "misc_skull_mazel2_05_act") then
      xRef = tes3.getReference( "misc_skull_mazel2_05_act" ) 
      tes3.setEnabled({ reference = xRef, enabled = false })  -- disable key
      xRef = tes3.getReference( "in_maze_walll2_05" )
      tes3.setEnabled({ reference = xRef, enabled = false })  -- disable wall
      tes3.playSound{ reference = tes3.player, sound = "Door Stone open" }
      
  --  elseif ( string.sub(container.id:lower(), 1, 17 ) == "misc_skull_mazel3" )  -- Level Three 
    elseif (e.target.id == "misc_skull_mazel3_01_act") then
      xRef = tes3.getReference( "misc_skull_mazel3_01_act" ) 
      tes3.setEnabled({ reference = xRef, enabled = false })  -- disable key
      xRef = tes3.getReference( "in_maze_walll3_01" )
      tes3.setEnabled({ reference = xRef, enabled = false })  -- disable wall
      tes3.playSound{ reference = tes3.player, sound = "Door Stone open" }

    elseif (e.target.id == "misc_skull_mazel3_02_act") then
      xRef = tes3.getReference( "misc_skull_mazel3_02_act" ) 
      tes3.setEnabled({ reference = xRef, enabled = false })  -- disable key
      xRef = tes3.getReference( "in_maze_walll3_02" )
      tes3.setEnabled({ reference = xRef, enabled = false })  -- disable wall
      -- open two walls here - maybe confuse them.
      xRef = tes3.getReference( "in_maze_walll3_03" )
      tes3.setEnabled({ reference = xRef, enabled = false })  -- disable wall
      tes3.playSound{ reference = tes3.player, sound = "Door Stone open" }
          
    elseif (e.target.id == "misc_skull_mazel3_03_act") then
      xRef = tes3.getReference( "misc_skull_mazel3_03_act" ) 
      tes3.setEnabled({ reference = xRef, enabled = false })  -- disable key
      xRef = tes3.getReference( "in_maze_walll3_04" )
      tes3.setEnabled({ reference = xRef, enabled = false })  -- disable wall
      tes3.playSound{ reference = tes3.player, sound = "Door Stone open" }
      
    elseif (e.target.id == "maze_key_l3_act") then
      ReSetLevel3()
      tes3.playSound{ reference = tes3.player, sound = "blackoutin" }    
      --Player->PositionCell -1568, 1040, 80, 5130, "a maze, l4" -- put them at the start of Level four
      tes3.positionCell({ reference = tes3.player, 
                  cell = "a maze, l4", 
                  position = { -1568, 1040, 80 }, 
                  orientation = {0,0,0}, 
                  forceCellChange = false, 
                  suppressFader = false, 
                  teleportCompanions = false })
      
    elseif (e.target.id == "maze_key_l4_act") then
      ReSetLevel4()
      tes3.playSound{ reference = tes3.player, sound = "blackoutin" }    
      --Player->PositionCell -126, -39, 80, 0, "a maze, l5"
      tes3.positionCell({ reference = tes3.player, 
                  cell = "a maze, l5", 
                  position = { -126, -39, 80 }, 
                  orientation = {0,0,0}, 
                  forceCellChange = false, 
                  suppressFader = false, 
                  teleportCompanions = false })
              
    elseif (e.target.id == "maze_key_l5_act") then
      ReSetLevel5()    
      --"in_maze_walll5_01"->disable
      xRef = tes3.getReference( "in_maze_walll5_01" )
      tes3.setEnabled({ reference = xRef, enabled = true })  -- enable wall
      tes3.playSound{ reference = tes3.player, sound = "blackoutin" }    
      -- Player->PositionCell -2424, -266, 366, 270, "a maze, inn" ????
      tes3.positionCell({ reference = tes3.player, 
                  cell = "A Maze, Inn", 
                  position = { -2032, -80, 624 }, 
                  orientation = {0,0,90}, 
                  forceCellChange = false, 
                  suppressFader = false, 
                  teleportCompanions = false })
    end
  end
end
event.register("activate", onActivateMaze)
