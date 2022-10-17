--[[
Mirador Castle Mod
by
The Wanderer and DietBob
--]]
----------------------------------------------------------------------------------------------------
mwse.log("[Mirador Castle Schedule] Loaded successfully.")

local locations = {}
local vamipres = {}
local finale
local doOnce
local doOnceFin
local DeadCount
local oldTime
local NowTime
local FinalBossBattle

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
local VampRoyal = {
{ id = 0, npc = "MC_Maggard_Anaedore", name = "Master Maggard Anaedore", class = "Battlemage", race = "High Elf", isDead = false, -- Throne only after 5 or more of family are dead
  morning = {125, 192, 0}    , mrot = {0, 0, 225}, cellm = "Mirador Castle, Ancients Chamber.",     -- bedroom"
  lunch   = { 1009, 0, 4 }   , lrot = {0, 0, -1} , celll = "Mirador Castle, holding.",    -- lunch
  even    = { -152, -180, 4 }, erot = {0, 0, 0}  , celle = "Mirador Castle, holding.",    -- evening
  night   = { -152, -180, 4 }, nrot = {0, 0, 0}  , celln = "Mirador Castle, holding.",    -- "night"
  after   = { -152, -180, 4 }, arot = {0, 0, 0}  , cella = "Mirador Castle, holding.",    -- "after" 
  final   = { 1104, 7, 4 }   , rot  = {0, 0, -1 }, cell = "Mirador Castle, Great Hall.", 
},
{ id = 1, npc = "mc_Nikolas_Anaedore", name = "Lord Nikolas Anaedore", class = "Knight", race = "Breton", isDead = false,  -- Throne a
  morning = { -364, -1239, 787 }, mrot = {0,0,0}    , cellm = "Mirador Castle, Living Quarters.",
  lunch   = { -148, -68, 4 }    , lrot = {0, 0, 0}  , celll = "Mirador Castle, holding.",
  even    = { 1126, -128, 2 }   , erot = {0, 0, -1 }, celle = "Mirador Castle, Great Hall.",
  night   = { 642, -569, 293}   , nrot = {0, 0, 0}  , celln = "Mirador Castle, Living Quarters.",    -- by blood fountain
  after   = { -148, -68, 4 }    , arot = {0, 0, 0}  , cella = "Mirador Castle, holding.",    -- "after" 
  final   = { 1126, -128, 2 }   , rot = {0, 0, -1 } , cell = "Mirador Castle, Great Hall.",
},
{ id = 2, npc = "mc_Petra Anaedore", name = "Lady Petra Anaedore", class = "Witch", race = "High Elf", isDead = false,  -- Throne b  
  morning = { -62, -117, 795 }, mrot = {0,0,0}    , cellm = "Mirador Castle, Living Quarters.", 
  lunch   = { -152, 60, 4 }   , lrot = {0, 0, 0}  , celll = "Mirador Castle, holding.",
  even    = { 1101, -205, 2 } , erot = {0, 0, -1 }, celle = "Mirador Castle, Great Hall.",
  night   = { -152, 60, 4 }   , nrot = {0, 0, 0}  , celln = "Mirador Castle, holding.",    -- "night"
  after   = { 642, -569, 293} , arot = {0, 0, 0}  , cella = "Mirador Castle, Living Quarters.",    -- by blood fountain
  final   = { 1101, -205, 2 } , rot = {0, 0, -1 } , cell = "Mirador Castle, Great Hall.",
},
{ id = 3, npc = "mc_Merle Anaedore", name = "Lady Merle Anaedore", class = "Sorcerer", race = "Breton", isDead = false,  -- Throne c
  morning = { -145, -1217, 796 }, mrot = {0,0,0}    , cellm = "Mirador Castle, Living Quarters.",
  lunch   = { 1128, 163, 2 }    , lrot = {0, 0, -2 }, celll = "Mirador Castle, Great Hall.",
  even    = { -148, 148, 4 }    , erot = {0, 0, 0}  , celle = "Mirador Castle, holding.",
  night   = { 249, -5, 4 }      , nrot = {0, 0, 0}  , celln = "Mirador Castle, Kitchens.",    -- "night"    -- kitchen
  after   = { -148, 148, 4 }    , arot = {0, 0, 0}  , cella = "Mirador Castle, holding.",    -- "after" 
  final   = { 1128, 163, 2 }    , rot = {0, 0, -2 } , cell = "Mirador Castle, Great Hall.",
}
}
-- =-=-=-=-=     
local VampCommon = {
{ id = 1, npc = "mc_Thaddeus", name = "Thaddeus", class = "Barbarian", race = "Nord", isDead = false,
  morning = { -220, -1323, 543 }, mrot = { 0,0,0 } , cellm = "Mirador Castle, Living Quarters.", 
  lunch   = { 712, 390, 2 }     , lrot = {0, 0, 3 }, celll = "Mirador Castle, Great Hall.",
  even    = { 152, -60, 4 }     , erot = {0, 0, 0} , celle = "Mirador Castle, holding.",
  night   = { 526, -666, 391 }  , nrot = {0, 0, 0} , celln = "Mirador Castle, Barracks.",    -- "night"  -- barracks cellar
  after   = { 152, -60, 4 }     , arot = {0, 0, 0} , cella = "Mirador Castle, holding.",     -- "after"  - off grid
  final   = { 712, 390, 2 }     , rot = {0, 0, 3 } , cell = "Mirador Castle, Great Hall.",
},
{ id = 2, npc = "mc_Adriana", name = "Adriana", class = "Champion", race = "High Elf", isDead = false,
  morning = { 123, -1186, 794 }, mrot = { 0,0,0 }  , cellm = "Mirador Castle, Living Quarters.",
  lunch   = { 64, -64, 4 }     , lrot = {0, 0, 0}  , celll = "Mirador Castle, holding.",
  even    = { 338, 210, 2 }    , erot = {0, 0, 1 } , celle = "Mirador Castle, Great Hall.",
  night   = { 64, -64, 4 }     , nrot = {0, 0, 0}  , celln = "Mirador Castle, holding.",    -- "night"   
  after   = { 592, -460, 280}  , arot = {0, 0, 0}  , cella = "Mirador Castle, Living Quarters.",    -- by blood fountain
  final   = { 338, 210, 2 }    , rot = {0, 0, 1 }  , cell = "Mirador Castle, Great Hall.",
},
{ id = 3, npc = "mc_Alaric", name = "Alaric", class = "Smith", race = "Nord", isDead = false,
  morning = { 414, -1188, 539 }, mrot = { 0,0,0 } , cellm = "Mirador Castle, Living Quarters.",
  lunch   = { 870, 157, 2 }    , lrot = {0, 0, 0 }, celll = "Mirador Castle, Great Hall.",
  even    = { -60, -72, 4 }    , erot = {0, 0, 0} , celle = "Mirador Castle, holding.",
  night   = { -60, -72, 4 }    , nrot = {0, 0, 0} , celln = "Mirador Castle, holding.",    -- "night"
  after   = { -265, -191, 1 }  , arot = {0, 0, 0} , cella = "Mirador Castle, Kitchens.",    -- "after"    -- kitchen
  final   = { 870, 157, 2 }    , rot = {0, 0, 0 } , cell = "Mirador Castle, Great Hall.",
},
{ id = 4, npc = "mc_Sapphira", name = "Sapphira", class = "Mage", race = "Wood Elf", isDead = false,
  morning = { 138, -156, 1110 }, mrot = { 0,0,270 }, cellm = "Mirador Castle, Wizards Tower.",   --- wizards tower
  lunch   = { 60, -26, 529 }   , lrot = {0, 0, 0}  , celll = "Mirador Castle, holding.",
  even    = { 1005, -208, 2 }  , erot = {0, 0, -2 }, celle = "Mirador Castle, Great Hall.",
  night   = { 60, -26, 529 }   , nrot = {0, 0, 0}  , celln = "Mirador Castle, holding.",    -- "night"  - off grid
  after   = { -228, -156, 4 }  , arot = {0, 0, 0}  , cella = "Mirador Castle, Wizards Tower.",    -- Wizads tower bottom.
  final   = { 1005, -208, 2 }  , rot = {0, 0, -2 } , cell = "Mirador Castle, Great Hall.",
},
{ id = 5, npc = "mc_Lucian", name = "Lucian", class = "Assassin", race = "Breton", isDead = false, 
  morning = { 130, -1303, 537 }, mrot = { 0,0,0 } , cellm = "Mirador Castle, Living Quarters.",
  lunch   = { 335, -249, 2 }   , lrot = {0, 0, 0 }, celll = "Mirador Castle, Great Hall.",
  even    = { 335, -249, 2 }   , erot = {0, 0, 0 }, celle = "Mirador Castle, Great Hall.",
  night   = { -228, -156, 4 }  , nrot = {0, 0, 0} , celln = "Mirador Castle, Wizards Tower.",    -- Wizads tower bottom.
  after   = { 68, -180, 4 }    , arot = {0, 0, 0} , cella = "Mirador Castle, holding.",    -- "after"  - off grid
  final   = { 335, -249, 2 }   , rot = {0, 0, 0 } , cell = "Mirador Castle, Great Hall.",
},
{ id = 6, npc = "mc_Seain", name = "Seain", class = "Champion", race = "Orc", isDead = false,
  morning = { -50, 1114, 538 }, mrot = { 0,0,270 }, cellm = "Mirador Castle, Living Quarters.",
  lunch   = { 516, -442, 2 }  , lrot = {0, 0, 0 } , celll = "Mirador Castle, Great Hall.",
  even    = { 68, -180, 4 }   , erot = {0, 0, 0}  , celle = "Mirador Castle, holding.",
  night   = { 144, 68, 4 }    , nrot = {0, 0, 0}  , celln = "Mirador Castle, holding.",    -- "night"
  after   = { 526, -666, 391 }, arot = {0, 0, 0}  , cella = "Mirador Castle, Barracks.",    -- "night"  -- barracks cellar  
  final   = { 516, -442, 2 }  , rot = {0, 0, 0 }  , cell = "Mirador Castle, Great Hall.",
},
{ id = 7, npc = "mc_Kalonice", name = "Kalonice", class = "Savant", race = "Breton", isDead = false,
  morning = { 455, -1173, 798 }, mrot = { 0,0,0 }  , cellm = "Mirador Castle, Living Quarters.",
  lunch   = { -68, -176, 4 }   , lrot = {0, 0, 0}  , celll = "Mirador Castle, holding.",
  even    = { 984, -346, 2 }   , erot = {0, 0, -1 }, celle = "Mirador Castle, Great Hall.",
  night   = { -68, -176, 4 }   , nrot = {0, 0, 0}  , celln = "Mirador Castle, holding.",   -- "night" - off grid
  after   = { 249, -5, 4 }     , arot = {0, 0, 0}  , cella = "Mirador Castle, Kitchens.",    -- "after"    -- kitchen
  final   = { 984, -346, 2 }   , rot = {0, 0, -1 } , cell = "Mirador Castle, Great Hall.",
}
}

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
local function SetScheduleCommon(nowTime)
local npc
local ref
local cell
local pos
local rot
local isDead

  for _, id in pairs(VampCommon) do
    if ( id.isDead ) then
    -- do nothing they're dead!

  else
    
      if ( nowTime and nowTime == 1 ) then  -- 10pm to 6am  = 8hrs - mixed locations ???
        cell = id.celln
        pos  = id.night
        rot  = id.nrot     
        
      elseif ( nowTime and nowTime == 2 ) then  -- 6am to 12am  = 6hrs  - all in bedrooms.
        cell = id.cellm
        pos  = id.morning
        rot  = id.mrot     
        
      elseif (nowTime and nowTime == 3 ) then    -- 12am to 2pm  = 2hrs - All in Greathall - 7 from 16 random spots ???
        cell = id.celll
        pos  = id.lunch
        rot  = id.lrot     
        
      elseif ( nowTime and nowTime == 4 ) then	  -- 2pm to 6pm   = 4hrs - Where ?!?!?
        cell = id.cella
        pos  = id.after
        rot  = id.arot     
        
      elseif ( nowTime and nowTime == 5 ) then	    -- 6pm to 10pm  = 4hrs  - All in Greathall
        cell = id.celle
        pos  = id.even
        rot  = id.erot     

      end
      tes3.positionCell({ reference  = id.npc, 
                  cell               = cell, 
                  position           = pos,
                  orientation        = rot,  
                  forceCellChange    = false,    --- hmmm.....
                  suppressFader      = true,     -- false, 
                  teleportCompanions = false })  --  not need here

    end
  end  
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
local function SetScheduleRoyal(nowTime)
local npc
local ref
local cell
local pos
local rot
local isDead

  for _, id in pairs(VampRoyal) do
    if ( id.id > 0 ) then
      if ( id.isDead ) then
      -- do nothing they're dead!
    else      
        
        if ( nowTime and nowTime == 1 ) then  -- 10pm to 6am  = 8hrs - mixed locations ???
          cell = id.celln
          pos  = id.night
          rot  = id.nrot     
          
        elseif ( nowTime and nowTime == 2 ) then  -- 6am to 12am  = 6hrs  - all in bedrooms.
          cell = id.cellm
          pos  = id.morning
          rot  = id.mrot     
          
        elseif ( nowTime and nowTime == 3 ) then    -- 12am to 2pm  = 2hrs - All in Greathall - 7 from 16 random spots ???
          cell = id.celll
          pos  = id.lunch
          rot  = id.lrot     
          
        elseif ( nowTime and nowTime == 4 ) then	  -- 2pm to 6pm   = 4hrs - Where ?!?!?
          cell = id.cella
          pos  = id.after
          rot  = id.arot     
          
        elseif ( nowTime and nowTime == 5 ) then	    -- 6pm to 10pm  = 4hrs  - All in Greathall
          cell = id.celle
          pos  = id.even
          rot  = id.erot     
        end
        
        tes3.positionCell({ reference  = id.npc, 
                    cell               = cell, 
                    position           = pos,
                    orientation        = rot,  
                    forceCellChange    = false,    --- hmmm.....
                    suppressFader      = true,     -- false, 
                    teleportCompanions = false })  --  not need here

      end
    end
  end  
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
local function SetScheduleFinal()
-- Put anyone still alive in the Great Hall and wait for the player.
local npc
local ref
local cell
local pos
local rot
local isDead
local notDead = 0

if ( doOnceFin == 1 ) then
-- keep count of dead
  for _, id in pairs(VampCommon) do
    if ( tes3.getReference(id.npc).isDead ) then
    else
      notDead = notDead + 1
    end
  end
  for _, id in pairs(VampRoyal) do
    if ( tes3.getReference(id.npc).isDead  ) then
    else
      notDead = notDead + 1
    end
  end
mwse.log("notDead = %s",notDead)  
  if ( notDead <= 0 ) then
    tes3.updateJournal({ id = "MC_P01", index = 100 }) --, speaker = tes3.player, showMessage = false })
    doOnceFin = 2
  end

else

  doOnceFin = 1     
  
  for _, id in pairs(VampRoyal) do
     if ( id.isDead ) then
     -- do nothing they're dead!
   else       
       cell = "Mirador Castle, Great Hall."
       pos  = id.final
       rot  = id.rot       
       tes3.positionCell({ reference  = id.npc, 
                 cell               = cell, 
                 position           = pos,
                 orientation        = rot })         
    end
                
  end
  for _, id in pairs(VampCommon) do
    if ( id.isDead ) then
     -- do nothing they're dead! 
    else  
       cell = id.celll
       pos  = id.lunch
       rot  = id.lrot               
       tes3.positionCell({ reference  = id.npc, 
                 cell               = cell, 
                 position           = pos,
                 orientation        = rot  })                
    end
  end
  
  ref = "Bshan_thrall_wander_day"
  if ( tes3.worldController.hour.value >= 20 ) then
    ref = "Bshan_thrall_wander_nite" 
  elseif ( tes3.worldController.hour.value <= 8 ) then
    ref = "Bshan_thrall_wander_nite"
  end  
  local Thralls = {
  { pos = { 180, -524, 4 }, rot = {0, 0, 0 }  }, -- cell = "Mirador Castle, Great Hall.",
  { pos = { 796, -556, 4 }, rot = {0, 0, 0 }  }, -- cell = "Mirador Castle, Great Hall.",
  --{ pos = { 1164, -644, 4 }, rot = {0, 0, 0 } }, -- cell = "Mirador Castle, Great Hall.",
  --{ pos = { 1136, 620, 4 }, rot = {0, 0, 180 }}, -- cell = "Mirador Castle, Great Hall.",
  { pos = { 744, 540, 4 }, rot = {0, 0, 180 } }, -- cell = "Mirador Castle, Great Hall.",
  { pos = { 124, 608, 4 }, rot = {0, 0, 180 } }, -- cell = "Mirador Castle, Great Hall.",
}    
  cell = "Mirador Castle, Great Hall."
  for _, id in pairs(Thralls) do
    pos  = id.pos
    rot  = id.rot      
    -- Put random Thralls in the Great Hall
    tes3.createReference({ object = tes3.getObject(ref):pickFrom(), position = pos, orientation = rot, cell = cell })
  end  
end
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
local function checkSchedule(cellID)

--local cellName = string.sub(cellID, 14, string.len(cellID))

if ( FinalBossBattle ) then
  
  SetScheduleFinal()
  
else    

    if ( tes3.worldController.hour.value >= 22 or -- AT NIGHT  - random locations ???
         tes3.worldController.hour.value < 7 ) then
        nowTime = 1
        
    elseif ( tes3.worldController.hour.value > 6 and -- DAY - All in bedrooms
             tes3.worldController.hour.value < 12 ) then
        nowTime = 2  --"morning"
        
    elseif ( tes3.worldController.hour.value >= 12 and -- AT LUNCH  - All in Greathall
             tes3.worldController.hour.value < 15  ) then
      nowTime = 3  --"lunch"
        
    elseif ( tes3.worldController.hour.value >= 15 and -- AFTERNOON  - random locations ???
             tes3.worldController.hour.value < 19  ) then
      nowTime = 4  --"after"

    elseif ( tes3.worldController.hour.value >= 19 and -- EVENING   - All in Greathall
         tes3.worldController.hour.value < 22  ) then
      nowTime = 5  --"even"
    
    else  -- fall back default just in case
      nowTime = 6  -- "unknown"

    end
  --else
    local npc
    DeadCount = 0
    for _, id in pairs(VampRoyal) do
        if ( tes3.getReference(id.npc).isDead ) then
            id.isDead = true
            DeadCount = DeadCount + 1                                 
        end        
    end
    
    for _, id in pairs(VampCommon) do
        if ( tes3.getReference(id.npc).isDead ) then
            id.isDead = true
            DeadCount = DeadCount + 1                         
      end
    end      
    
    if( oldTime and oldTime == nowTime ) then    
      if ( DeadCount < 6 ) then
          return
      else
          oldTime = nowTime
      end
    end  
      
    if ( DeadCount > 5 ) then 
 
if ( cellID == "Mirador Castle, Great Hall." ) then  
  return  -- wait until there are somewhere else
end   
      tes3.updateJournal({ id = "MC_P01", index = 90, showMessage = true }) --, speaker = tes3.player, showMessage = false })
      tes3.playSound({ 
          reference = tes3.player, 
          soundPath = "mc_mastervamp.wav",
          }) --, loop = ..., mixChannel = ..., volume = ..., pitch = ..., soundPath = ... })
      
      FinalBossBattle = true   -- put anyone left in the great hall... including some thralls?
                               
    else
      SetScheduleCommon(nowTime)
      SetScheduleRoyal(nowTime)
    
    end   
  end

end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
local function initNPCs()
  -- new lua code should negate this.

  if ( doOnce == 0 or doOnce == nil ) then
        doOnce = 1
     -- move them all.
     local cell, pos, rot
     local InitVamp = {
      { npc = "MC_Maggard_Anaedore", pos = { -152, -180, 4 }}, -- rot = {0, 0, 0} },  -- , cell = "Mirador Castle, holding.",
      { npc = "mc_Nikolas_Anaedore", pos = { -148, -68, 4 } }, -- rot = {0, 0, 0} },  -- , cell = "Mirador Castle, holding."
      { npc = "mc_Petra Anaedore"  , pos = { -152, 60, 4 }  }, -- rot = {0, 0, 0} },  -- , cell = "Mirador Castle, holding."
      { npc = "mc_Merle Anaedore"  , pos = { -148, 148, 4 } }, -- rot = {0, 0, 0} },  -- , cell = "Mirador Castle, holding."
      { npc = "mc_Thaddeus"        , pos = { 152, -60, 4 }  }, -- rot = {0, 0, 0} },  -- , cell = "Mirador Castle, holding."
      { npc = "mc_Adriana"         , pos = { 64, -64, 4 }   }, -- rot = {0, 0, 0} },  -- , cell = "Mirador Castle, holding."
      { npc = "mc_Alaric"          , pos = { -60, -72, 4 }  }, -- rot = {0, 0, 0} },  -- , cell = "Mirador Castle, holding."
      { npc = "mc_Sapphira"        , pos = { 60, -26, 529 } }, -- rot = {0, 0, 0} },  -- , cell = "Mirador Castle, holding."
      { npc = "mc_Lucian"          , pos = { 68, -180, 4 }  }, -- rot = {0, 0, 0} },  -- , cell = "Mirador Castle, holding."
      { npc = "mc_Seain"           , pos = { 68, -180, 4 }  }, -- rot = {0, 0, 0} },  -- , cell = "Mirador Castle, holding."
      { npc = "mc_Kalonice"        , pos = { -68, -176, 4 } }, -- rot = {0, 0, 0} },  -- , cell = "Mirador Castle, holding."
      }  

    for _, id in pairs(InitVamp) do
       cell = tes3.player.cell.id
       tes3.positionCell({ reference = id.npc, position = {0, 0, -5000}, cell = cell })
  
       cell = "Mirador Castle, holding."
       pos  = id.pos
       rot  = {0, 0, 0}            
      
       tes3.positionCell({ reference = id.npc, 
                 cell               = cell, 
                 position           = pos,
                 orientation        = rot,  
                 forceCellChange    = false,  
                 suppressFader      = true,   
                 teleportCompanions = false })
    end
  end
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
local function startHiringStaff()

    -- First thing is to hire a Steward.
    -- tes3.updateJournal({ id = "MC_P02, index = 10 }) --, speaker = tes3.player, showMessage = true })
    --[[
        journal MC_P02 10 "Now that I own this large castle I am certainly going to need help to run it. I should let it be known I an looking for a steward."
        -- a few day later...
        journal MC_P02 20 "I have recieved several communications about the post of steward... I have narrowed it down to 2 possibles. I should go visit each before I make a final decision."
        player->additem mc_steward_scroll_01 i
        player->additem mc_steward_scroll_02 i
        
    --]]
    
    
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
local function cellChangedMC(e)
local doOnce
-- Check schedual on cell change anywhere in or around Mirador Castle
local cellID = e.cell.displayName
local cellName = string.sub(cellID, 1, 14)
  if ( cellName == "Mirador Castle" ) then    -- Mirador Castle Region, Mirador Castle, Great Hall, Mirador Castle, Great Hall, Mirador Castle, Wizards Tower

--if  ( tes3.getJournalIndex({ id = "MC_P01" }) < 100 ) then

    --if ( FinalBossBattle ) then
      -- once boss fight has started no more schedules to run
    --  return
    --end

    initNPCs()
    checkSchedule(cellID)
    
--else
  
  --if ( doOnce == 0 ) then
  --  doOnce = 1
  --  mwse.log("This should be the start of the rebuild....Phase 2")
    --startHiringStaff()
  --end
--end

  end
  
end
event.register("cellChanged", cellChangedMC)
