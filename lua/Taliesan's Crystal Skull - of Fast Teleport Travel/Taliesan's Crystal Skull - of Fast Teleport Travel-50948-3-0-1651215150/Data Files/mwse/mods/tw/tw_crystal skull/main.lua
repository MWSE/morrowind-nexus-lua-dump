--[[
Taliesan's Crystal Skull - of Fast Teleport Travel
by
The Wanderer

Taliesan's Crystal Skull - of Fast Teleport Travel <link> https://www.nexusmods.com/morrowind/mods/50948

 The number of destinations available is directly linked to:
 'PC level', 'PC Reputation' and certain 'Magic Skills'.
 LikePC levels
 0 'Get lost you're not worthy...'
 1 "Teleport to where?", "Towns"
 2 "Teleport to where?", "Towns" "Strongholds"
 3 "Teleport to where?", "Towns" "Strongholds" "Camps"
 4 "Teleport to where?", "Towns" "Strongholds" "Camps" "Great House Stronghold" "Misc"
 5 "Teleport to where?", "Towns" "Strongholds" "Camps" "Great House Stronghold" "Misc" "Secret Masters"
 6 "Teleport to where?", "Towns" "Strongholds" "Camps" "Great House Stronghold" "Misc" "Secret Masters" "Shrines"
 7 "Teleport to where?", "Towns" "Strongholds" "Camps" "Great House Stronghold" "Misc" "Secret Masters" "Shrines" "Ruins" "Custom"
 8 "Teleport to where?", "Towns" "Strongholds" "Camps" "Great House Stronghold" "Misc" "Secret Masters" "Shrines" "Ruins" "Custom" "Extreme Menu"
 
 "Mournhold" and "Solstheim" locations will be found under "Misc"
 
 Just give yourself the skull if you don't want to return to Seyda Neen tto pick it up.
 player->additem tw_crystalskull_misc 1

--]]

mwse.log("[Taliesan's Crystal Skull of Travel] Loaded successfully.")
local messageBox = require("tw.tw_crystal skull.buttons")
local buttons = dofile("tw.tw_crystal skull.buttons")   -- menu

local messageBox = require("tw.tw_crystal skull.locations")
local locations = dofile("tw.tw_crystal skull.locations")

local messageBox = require("tw.textedit")
local textedit = dofile("tw.textedit")

local messageBox = require("tw.MessageBox")



local LikePC     -- override menu settings
local lCell, lPos, lRot

local skull = {}

local config = mwse.loadConfig("Taliesan's Crystal Skull", {
    combatEnabled = true, -- Use in combat
    jailEnabled = true,   -- Ignore crime
    WolfEnabled = true,   -- Use in jail
    VampEnabled = true,   -- Allow use by Vampires
    crimeEnabled = true,  -- and when in Werewolf form
    setCrime     = 500,   -- Set crime level
    compEnabled  = false, -- Transport with companions
    setlikeLv    = 0,     -- Menu level                
})

local lTeleport = config.compEnabled

------------------------------------------------------------------------------------------------------
 function skull.travelTownBalmora(button)  -- +1`
 -- Balmora  
 if (button == 0 ) then  -- "Back..."
   skull.travel(0)   -- towns
 else
      lCell = nil
      lPos  = {}
      lRot  = {}

      local mapcoord = buttons.Balmora()
      for _, loc in pairs(mapcoord) do  
        if ( loc.id == button ) then   
            lCell = loc.cell
            lPos  = loc.pos
            lRot  = loc.rot
          
        end
      end
    
     if ( lCell ~= nil ) then   -- just in case.
       tes3.positionCell({ reference = tes3.player, 
                         cell               = lCell, 
                         position           = lPos,
                         orientation        = lRot,  
                         forceCellChange    = false,    --- hmmm.....
                         suppressFader      = true,     -- false, 
                         teleportCompanions = lTeleport })  
     end 
 end  
end

------------------------------------------------------------------------------------------------------
function skull.travelTownVivec(button)
  -- Vivec 
if (button == 0 ) then  -- "Back..."
   --skull.showTravelMenu()
   skull.travel(0)   -- towns
 else  
      lCell = nil
      lPos  = {}
      lRot  = {}

      local mapcoord = buttons.Vivec()
      for _, loc in pairs(mapcoord) do  
        if ( loc.id == button ) then   
            lCell = loc.cell
            lPos  = loc.pos
            lRot  = loc.rot
          
        end
      end
    
     if ( lCell ~= nil ) then   -- just in case.
       tes3.positionCell({ reference = tes3.player, 
                         cell = lCell, 
                         position           = lPos,
                         orientation        = lRot,  
                         forceCellChange    = false,    --- hmmm.....
                         suppressFader      = true,     -- false, 
                         teleportCompanions = lTeleport })  
     end
  end 
  
end

------------------------------------------------------------------------------------------------------
function skull.travelVivec()  
-- Vivec
local butt
local mess
local nID  
local buttons = buttons.mainmenu()

    for _, id in pairs(buttons) do
      if ( id.id == 122 ) then
          butt = id.butt
          mess = id.mess
          nID = id.id
      end
    end
    if ( nID ) then
        tes3.messageBox{
            message  = mess,
            buttons  = butt,   
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelTownVivec(e.button) end )
                       end
                  }                                                           
    end
end

------------------------------------------------------------------------------------------------------  
function skull.travelTownMore(button)  
  if ( button == 200 ) then
     --tes3.messageBox( "Teleporting you to Ald Redaynia..." )
    lCell =  "Ald Redaynia"
    lPos  =  { -28137, 179528, 1566 }
    lRot  =  { 0, 0, 280 }
 
 elseif ( button == 201 ) then
     --tes3.messageBox( "Teleporting you to Ald Velothi..." )
    lCell =  "Ald Velothi"
    lPos  =  { -86075, 126253, 519 }
    lRot  =  { 0, 0, 350 }
    
  elseif ( button == 202 ) then
    -- tes3.messageBox( "Teleporting you to Maar Gan..." )
    lCell =  "Maar Gan"
    lPos  =  { -24096, 101097, 1640 }
    lRot  =  { 0, 0, 90 }
    
  elseif ( button == 203 ) then
     --tes3.messageBox( "Teleporting you to Tel Aruhn..." )
    lCell =  "Azura's Coast Region"
    lPos  =  { 122566, 44925, 885 }
    lRot  =  { 0, 0, 60 }
    
  elseif ( button == 204 ) then
    -- tes3.messageBox( "Teleporting you to Tel Branora..." )
    lCell =  "Tel Branora"
    lPos  =  { 119153, -102116, 160 }
    lRot  =  { 0, 0, 160 }
    
  elseif ( button == 205 ) then
    -- tes3.messageBox( "Teleporting you to Tel Mora..." )
    lCell =  "Tel Mora"
    lPos  =  { 106925, 117169, 264 }
    lRot  =  { 0, 0, 0 }
    
  elseif ( button == 206 ) then
    -- tes3.messageBox( "Teleporting you to Tel Fyr..." )
    lCell =  "Tel Fyr"
    lPos  =  { 126002, 15210, 169 }
    lRot  =  { 0, 0, 220 }
 
  elseif ( button == 207 ) then
    -- cancel
     return
     
  end
 
   if ( lCell ~= nil ) then   -- just in case.
     tes3.positionCell({ reference = tes3.player, 
                       cell = lCell, 
                       position           = lPos,
                       orientation        = lRot,  
                       forceCellChange    = false,    --- hmmm.....
                       suppressFader      = true,     -- false, 
                       teleportCompanions = lTeleport }) 
  end   
  
end

------------------------------------------------------------------------------------------------------
function skull.travelMore(NumId)  
local butt
local mess
local nID
local buttons = buttons.mainmenu()

  if ( NumId == 1 ) then  -- more towns
    for _, id in pairs(buttons) do
      if ( id.id == 120 ) then
          --NumId == 1 id = 120 , "Ebonheart", "Dagon Fel", "Gnaar Mok", "Khuul", "Molag Mar", "Pelagiad", "Sadrith Mora", "Vivec", "Cancel"
          butt = id.butt
          mess = id.mess
          nID  = id.id
      end
    end    
    if ( nID ) then
      tes3.messageBox{
          message  = mess,
          buttons  = butt,   
          callback = function(e)
                        timer.delayOneFrame( function() skull.travelTownMore(e.button + 101) end )
                    end
                }                                                           
      end    
  elseif ( NumId == 2 ) then 
      for _, id in pairs(buttons) do
        if ( id.id == 22 ) then
          -- {NumId = 2  , butt = {"Andasreth", "Marandus", "Indoranyon", "Rotheran", "Valenvaryon",  "Back", "Cancel }  
          butt = id.butt
          mess = id.mess
          nID  = id.id
        end
     end    
     if ( nID ) then
       tes3.messageBox{
            message  = mess,
            buttons  = butt,   
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelStronghold(e.button, nID ) end ) 
                      end
                  }                                                           
    end   
    
  elseif ( NumId == 3 ) then 
      --skull.travelMournhold()
      for _, id in pairs(buttons) do
        if ( id.id == 51 ) then
          butt = id.butt
          mess = id.mess
          nID  = id.id
        end
     end    
     if ( nID ) then
       tes3.messageBox{
            message  = mess,
            buttons  = butt,   
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelMournhold(e.button) end )  
                      end
                  }                                                           
     end        
    
  elseif ( NumId == 4 ) then 
      --skull.travelSolstheim()
      for _, id in pairs(buttons) do
        if ( id.id == 52 ) then
          butt = id.butt
          mess = id.mess
          nID  = id.id
        end
     end    
     if ( nID ) then
       tes3.messageBox{
            message  = mess,
            buttons  = butt,   
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelSolstheim(e.button) end ) 
                      end
                  }                                                           
     end      
  elseif ( NumId == 5 ) then       
    for _, id in pairs(buttons) do
        if ( id.id == 53 ) then
          butt = id.butt
          mess = id.mess
          nID  = id.id
        end
       if ( nID ) then
         tes3.messageBox{
              message  = mess,
              buttons  = butt,   
              callback = function(e)
                            timer.delayOneFrame( function() skull.travelTownMore(e.button + 200) end ) 
                        end
                    }                                                           
        end         
      end
  elseif ( NumId == 6 ) then 
      --skull.travelMore( 6 ) - next menu
    for _, id in pairs(buttons) do
         if ( id.id == 61 ) then
                butt = id.butt
                mess = id.mess
                nID  = id.id
        end
    end
    if ( nID ) then
        tes3.messageBox{
            message  = mess,
            buttons  = butt,   
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelMasters(e.button,nID) end )
                       end
                  }                                                           
    end   
  elseif ( NumId == 7 ) then 
      --skull.travelMore( 7 ) - next menu
    for _, id in pairs(buttons) do
         if ( id.id == 62 ) then
                butt = id.butt
                mess = id.mess
                nID  = id.id
        end
    end
    if ( nID ) then
        tes3.messageBox{
            message  = mess,
            buttons  = butt,   
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelMasters(e.button,nID) end )
                       end
                  }                                                           
    end
  elseif ( NumId == 8 ) then 
      --skull.travelMore( 8 ) - next menu  
    for _, id in pairs(buttons) do
         if ( id.id == 63 ) then
                butt = id.butt
                mess = id.mess
                nID  = id.id
        end
    end
    if ( nID ) then     
        tes3.messageBox{
            message  = mess,
            buttons  = butt,   
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelMasters(e.button,nID) end )
                       end
                  }                                                           
    end 
  elseif ( NumId == 9 ) then 
    for _, id in pairs(buttons) do
         if ( id.id == 81 ) then
                butt = id.butt
                mess = id.mess
                nID  = id.id
        end
    end
    if ( nID ) then
        tes3.messageBox{
            message  = mess,
            buttons  = butt,   
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelRuins(e.button,nID) end )
                       end
                  }                                                           
    end 
  elseif ( NumId == 10 ) then     
    for _, id in pairs(buttons) do
         if ( id.id == 82 ) then
                butt = id.butt
                mess = id.mess
                nID  = id.id
        end
    end
    if ( nID ) then
        tes3.messageBox{
            message  = mess,
            buttons  = butt,   
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelRuins(e.button,nID) end )
                       end
                  }                                                           
    end     
  else  
    return
  end
end

------------------------------------------------------------------------------------------------------
function skull.travelBalmora()
-- Balmora
local butt
local mess
local nID
local buttons = buttons.mainmenu()

    for _, id in pairs(buttons) do
      if ( id.id == 111 ) then
          butt = id.butt
          mess = id.mess
          nID  = id.id
      end
    end
    if ( nID ) then
      tes3.messageBox{
          message  = mess,
          buttons  = butt,   
          callback = function(e)
                        timer.delayOneFrame( function() skull.travelTownBalmora( (e.button ) ) end ) 
                    end
                }                                                           
    end
end

------------------------------------------------------------------------------------------------------
function skull.travelTown(button)
--{"Back...", "Ald'Ruhn", "Balmora", "Caldera", "Dagon Fel", "Ebonheart", "Gnaar Mok", "Gnisis", "Hla Oad", "Khuul", "Molag Mar", "Pelagiad", "Seyda Neen", "Sadrith Mora", "Suran", "Vivec", "Cancel"}, status = 110, mess = "Teleport to Towns..." },
  -- Actual travel locations
  lCell = nil
  lPos  = {}
  lRot  = {}

  if ( button == 0 ) then  
      -- BACK BUTTON
      skull.showTravelMenu()
      
  else
    if (button == 2) then   -- handle specials
      if ( LikePC == 1 ) then
          -- tes3.messageBox( "Teleporting you to Balmora..." )
          lCell =  "Balmora"
          lPos  =  { -22187, -18633, 357 }
          lRot  =  { 0, 0, 0 }
      else  
          skull.travelBalmora()
      end
    elseif (button == 15) then
      if (LikePC == 1 ) then
          lCell =  "Vivec"
          lPos  =  { 30646, -74586 ,567 }
          lRot  =  { 0, 0, 180 }
      else
          skull.travelVivec()
      end
    else  
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=   
      local mapcoord = buttons.Towns()
      for _, loc in pairs(mapcoord) do  
        if ( loc.id == button ) then   
            lCell = loc.cell
            lPos  = loc.pos
            lRot  = loc.rot
          
        end 
      end  
      if ( lCell ~= nil ) then   -- just in case.
         tes3.positionCell({ reference = tes3.player, 
                           cell = lCell, 
                           position           = lPos,
                           orientation        = lRot,  
                           forceCellChange    = false,    --- hmmm.....
                           suppressFader      = true,     -- false, 
                           teleportCompanions = lTeleport }) 
      end 
    end  
  end

end

------------------------------------------------------------------------------------------------------
function skull.travelStronghold(button,nID)
lCell = nil
lPos  = {}
lRot  = {}
  
  if ( button == 0 ) then  
      -- BACK BUTTON
      skull.showTravelMenu()
  else 
    local mapcoord = buttons.Strongholds(nID)
    
    for _, loc in pairs(mapcoord) do  
      if ( loc.id == button ) then   
          lCell = loc.cell
          lPos  = loc.pos
          lRot  = loc.rot
        
      end
    end     
    
    if ( lCell ~= nil ) then   -- just in case.
        tes3.positionCell({ reference = tes3.player, 
                          cell = lCell, 
                          position           = lPos,
                          orientation        = lRot,  
                          forceCellChange    = false,    --- hmmm.....
                          suppressFader      = true,     -- false, 
                          teleportCompanions = lTeleport }) 
     end
  end
   
end

------------------------------------------------------------------------------------------------------
function skull.travelCamps(button)
  
lCell = nil
lPos  = {}
lRot  = {}
  
  if ( button == 0 ) then  
      -- BACK BUTTON
      skull.showTravelMenu()
  else  
    local mapcoord = buttons.Camps()
    
    for _, loc in pairs(mapcoord) do  
      if ( loc.id == button ) then   
          lCell = loc.cell
          lPos  = loc.pos
          lRot  = loc.rot
        
      end
    end     
    
    if ( lCell ~= nil ) then   -- just in case.
        tes3.positionCell({ reference = tes3.player, 
                          cell = lCell, 
                          position           = lPos,
                          orientation        = lRot,  
                          forceCellChange    = false,    --- hmmm.....
                          suppressFader      = true,     -- false, 
                          teleportCompanions = lTeleport }) 
     end 
  end
    
end

------------------------------------------------------------------------------------------------------
function skull.travelGreatHouse(button)
-- Special handleing do not put in menu table file
lCell = nil
lPos  = {}
lRot  = {}

  
if ( button == 0 ) then  
    -- BACK BUTTON
    skull.showTravelMenu()
    
else  
  local HH = tes3.getFaction("Hlaalu").playerJoined
  local HR = tes3.getFaction("Redoran" ).playerJoined
  local HT = tes3.getFaction("Telvanni" ).playerJoined
  local HHindex = tes3.getJournalIndex({ id = "HH_Stronghold" })
  local HRindex = tes3.getJournalIndex({ id = "HRStronghold" })
  local HTindex = tes3.getJournalIndex({ id = "HT_Stronghold" })

-- Requires extra proccessing so not in locations file
  if ( button == 1 ) then
       if ( HH and (HHindex >= 300) ) then
        --tes3.messageBox("Teleporting you to Rethan Manor." )
         lCell =  "Rethan Manor"    
         lPos  =  { -422, 23, 1466 }
         lRot  =  { 0, 0, 0 }
       else   
        --tes3.messageBox("Teleporting you to Odai Plateau." )
         lCell = "Odai Plateau"
         lPos  =  { -35555, -37052, 1906 }
         lRot  =  { 0, 0, 0 }
       end
  elseif ( button == 2 ) then
     if ( HT and (HTindex >= 300) ) then
        --tes3.messageBox("Teleporting you to Uvirith Tower." )
       lCell =  "Uvirith, Tower Lower"
       lPos  =  { 175, 8, 25 }
       lRot  =  { 0, 0, 720 }
     else
        --tes3.messageBox("Teleporting you to Uvirith's Grave." )
       lCell =  "Uvirith's Grave"
       lPos  =  { 85814, 11267, 1896  }
       lRot  =  { 0, 0, 132 }
     end     
  elseif ( button == 3 ) then
    if ( HR and (HRindex >= 300)) then
        --tes3.messageBox("Teleporting you to Indarys Manor." )
       lCell =  "Indarys Manor"
       lPos  =  { 139, -701, -1260 }
       lRot  =  { 0, 0, 0 }
    else
        --tes3.messageBox("Teleporting you to Bal Isra." )
       lCell =  "Bal Isra"
       lPos  =  { -35684, 79406, 1783 }
       lRot  =  { 0, 0, 50 }
    end    
  end
  if ( lCell ~= nil ) then   -- just in case.
     tes3.positionCell({ reference = tes3.player, 
                       cell = lCell, 
                       position           = lPos,
                       orientation        = lRot,  
                       forceCellChange    = false,    --- hmmm.....
                       suppressFader      = true,     -- false, 
                       teleportCompanions = lTeleport })  
  end 
end
end
------------------------------------------------------------------------------------------------------
function skull.travelMisc(button)
  
if ( button == 0 ) then  
    -- BACK BUTTON
    skull.showTravelMenu()
    
else  
    if ( button == 5 ) then
        skull.travelMore( 3 )
        -- "Mournhold"  -- "Godsreach" "Great Bazaar" "Palace" "Temple" "Main Menu" "Cancel"
    elseif ( button == 6 ) then
         skull.travelMore( 4 )
         --  "Solstheim"  --  "Fort Frostmouth" "Skaal Village" "Thirsk" "Raven Rock" "Main Menu" "Cancel"
    else

      lCell = nil
      lPos  = {}
      lRot  = {}

      local mapcoord = buttons.Misc()

      for _, loc in pairs(mapcoord) do  
        if ( loc.id == button ) then   
            lCell = loc.cell
            lPos  = loc.pos
            lRot  = loc.rot
          
        end
      end

      if ( lCell ~= nil ) then   -- just in case.
         tes3.positionCell({ reference = tes3.player, 
                           cell = lCell, 
                           position           = lPos,
                           orientation        = lRot,  
                           forceCellChange    = false,    --- hmmm.....
                           suppressFader      = true,     -- false, 
                           teleportCompanions = lTeleport })  
      end 
  end
end
end

------------------------------------------------------------------------------------------------------
function skull.travelMasters(button,nID)
  
  if ( button == 0 ) then  
      -- BACK BUTTON
      skull.showTravelMenu()
      
  elseif ( nID == 60 and button == 15 ) then -- more masters   
      skull.travelMore( 7 )

  else 
 
    local mapcoord = {}
    if ( nID == 60 ) then
        mapcoord = buttons.Master1() --(1)

    elseif (nID == 62 ) then 
        mapcoord = buttons.Master2()  --(2)
      
    end

    lCell = nil
    lPos  = {}
    lRot  = {}
  
    for _, loc in pairs(mapcoord) do  
      if ( loc.id == button ) then   
          lCell = loc.cell
          lPos  = loc.pos
          lRot  = loc.rot
        
      end
    end

    if ( lCell ~= nil ) then   -- just in case.
       tes3.positionCell({ reference = tes3.player, 
                         cell = lCell, 
                         position           = lPos,
                         orientation        = lRot,  
                         forceCellChange    = false,    --- hmmm.....
                         suppressFader      = true,     -- false, 
                         teleportCompanions = lTeleport })  
    end 
  end
end

------------------------------------------------------------------------------------------------------
function skull.travelShrines(button)
  --    {id = 70 , butt = {"Back...", "Azura", "Boethiah", "Clavicus Vile", "Malacath", "Madrunes Dagon", "Mephaia", "Molag Bal", "Sheogorath", "Cancel"}, status = 600  , mess = "Teleport to Shrine of..." }, 
lCell = nil
lPos  = {}
lRot  = {}

 if ( button == 0 ) then  
      -- BACK BUTTON
      skull.showTravelMenu()
      
 else
    local mapcoord = buttons.Shrines()

    for _, loc in pairs(mapcoord) do  
      if ( loc.id == button ) then   
          lCell = loc.cell
          lPos  = loc.pos
          lRot  = loc.rot
        
      end
    end

    if ( lCell ~= nil ) then   -- just in case.
       tes3.positionCell({ reference = tes3.player, 
                         cell = lCell, 
                         position           = lPos,
                         orientation        = lRot,  
                         forceCellChange    = false,    --- hmmm.....
                         suppressFader      = true,     -- false, 
                         teleportCompanions = lTeleport })   
    end 
  end
end

-------------------------------------------------------------------------------------------------------
function skull.travelSecret(button)  -- may add another 1/200+ !!!

  if ( button == 0 ) then
      -- back menu
        skull.travelSecret(9)
        
  else
    
      local menu = locations.mainmenu()

      for _, id in pairs(menu) do      
        if ( id.id == 0 ) then        -- first menu
            butt = id.butt
        end
      end
   
      --if ( nID ) then  -- and ( nID < 8  ) then
              tes3.messageBox({
                  message  = "Ultimate menu",
                  buttons  = butt,
                  callback = function(e)
                                timer.delayOneFrame( function() skull.travel(e.button+100) end )
                             end,
                        })                                                          
      --end
  end    
end  
  
-------------------------------------------------------------------------------------------------------
function skull.travelMournhold(button)
 
 if (button == 0 ) then  -- "Back..."
   --skull.showTravelMenu()
   skull.travel(4)   -- towns
 else
      lCell = nil
      lPos  = {}
      lRot  = {}

      local mapcoord = buttons.Mournhold()

      for _, loc in pairs(mapcoord) do  
        if ( loc.id == button ) then   
            lCell = loc.cell
            lPos  = loc.pos
            lRot  = loc.rot
          
        end
      end


      if ( lCell ~= nil ) then   -- just in case.
         tes3.positionCell({ reference = tes3.player, 
                           cell = lCell, 
                           position           = lPos,
                           orientation        = lRot,  
                           forceCellChange    = false,    --- hmmm.....
                           suppressFader      = true,     -- false, 
                           teleportCompanions = lTeleport })  
      end     
   end 
end
------------------------------------------------------------------------------------------------------
function skull.travelSolstheim(button)
 
 if (button == 0 ) then  -- "Back..."
   --skull.showTravelMenu()
   skull.travel(4)   -- towns
 else
      lCell = nil
      lPos  = {}
      lRot  = {}

      local mapcoord = buttons.Solstheim()

      for _, loc in pairs(mapcoord) do  
        if ( loc.id == button ) then   
            lCell = loc.cell
            lPos  = loc.pos
            lRot  = loc.rot
          
        end
      end
      
    if ( lCell ~= nil ) then   -- just in case.
       tes3.positionCell({ reference = tes3.player, 
                         cell = lCell, 
                         position           = lPos,
                         orientation        = lRot,  
                         forceCellChange    = false,    --- hmmm.....
                         suppressFader      = true,     -- false, 
                         teleportCompanions = lTeleport }) 
    end  
  end 
end

-----------------------------------------------------------------------------------------------------
function skull.travelRuins(button,ID)
lCell = nil
lPos  = {}
lRot  = {}

  if (button == 0 ) then  -- "Back..."
    skull.showTravelMenu()
  elseif (button == 13 and ID == 80 ) then
    skull.travelMore(10)
  else
 
    local mapcoord = {}
    if ( ID == 80 ) then
        mapcoord = buttons.Ruins(1)
    elseif ( ID == 82 ) then
        mapcoord = buttons.Ruins(2)
    end
    
    for _, loc in pairs(mapcoord) do  
      if ( loc.id == button ) then   
          lCell = loc.cell
          lPos  = loc.pos
          lRot  = loc.rot
        
      end
    end

    if ( lCell ~= nil ) then   -- just in case.
       tes3.positionCell({ reference = tes3.player, 
                         cell = lCell, 
                         position           = lPos,
                         orientation        = lRot,  
                         forceCellChange    = false,    --- hmmm.....
                         suppressFader      = true,     -- false, 
                         teleportCompanions = lTeleport })  
    end  
  end  
end
----------------------------------------------------------------------------------------------------

function skull.travelMoreCamps(button)
lCell = nil
lPos  = {}
lRot  = {}

  if ( button == 0 ) then  
      skull.travelSecret(0)
      
  else
    local mapcoord = locations.MoreCamps()

    for _, loc in pairs(mapcoord) do  
      if ( loc.id == button ) then   
          lCell = loc.cell
          lPos  = loc.pos
          lRot  = loc.rot
        
      end
    end
    
    if ( lCell ~= nil ) then   -- just in case.
       tes3.positionCell({ reference = tes3.player, 
                         cell               = lCell, 
                         position           = lPos,
                         orientation        = lRot,  
                         forceCellChange    = false,    --- hmmm.....
                         suppressFader      = true,     -- false, 
                         teleportCompanions = lTeleport }) 
    end 
  end 
end
----------------------------------------------------------------------------------------------------
function skull.travelLandmarks(button)
  if ( button == 0 ) then  
      skull.travelSecret(0)
      
  else
    
    local mapcoord = locations.Landmarks()
    for _, loc in pairs(mapcoord) do  
      if ( loc.id == button ) then   
          lCell = loc.cell
          lPos  = loc.pos
          lRot  = loc.rot
        
      end
    end
    if ( lCell ~= nil ) then   -- just in case.
       tes3.positionCell({ reference = tes3.player, 
                         cell               = lCell, 
                         position           = lPos,
                         orientation        = lRot,  
                         forceCellChange    = false,    --- hmmm.....
                         suppressFader      = true,     -- false, 
                         teleportCompanions = lTeleport })  
    end 
  end 
end
----------------------------------------------------------------------------------------------------
function skull.travelGrottos(button)
  if ( button == 0 ) then  
      skull.travelSecret(0)
      
  else

    local mapcoord = locations.Grottos()
    for _, loc in pairs(mapcoord) do  
      if ( loc.id == button ) then   
          lCell = loc.cell
          lPos  = loc.pos
          lRot  = loc.rot
        
      end
    end
    
    if ( lCell ~= nil ) then   -- just in case.
       tes3.positionCell({ reference = tes3.player, 
                         cell               = lCell, 
                         position           = lPos,
                         orientation        = lRot,  
                         forceCellChange    = false,    --- hmmm.....
                         suppressFader      = true,     -- false, 
                         teleportCompanions = lTeleport })  
    end 
  end
end
----------------------------------------------------------------------------------------------------
function skull.travelMines(button)  
--[[   
    20 Ebony Mines
    21 Glass Mines
    22 Diamond Mine
    23 Egg Mines 1 
    24 Egg Mines 2
--]]    
    local buttons = {}
    
if ( button == 0 ) then
    -- back menu
      skull.travelSecret(0)
      
else
    if ( button == 1 ) then
        buttons = locations.mainmenu()
        button  = 25

    elseif ( button == 2 ) then
        buttons = locations.mainmenu()
        button  = 26

    elseif ( button == 3 ) then
        buttons = locations.mainmenu()
        button  = 27

    elseif ( button == 4 ) then
        buttons = locations.mainmenu()
        button  = 23

    elseif ( button == 5 ) then 
         buttons = locations.mainmenu()
         button  = 24    

    end

    for _, id in pairs(buttons) do  
        if ( id.id == button ) then   
            butt = id.butt
            mess = "Select a Mine."   --id.mess
        end
    end

    --if ( nID ) then
        tes3.messageBox({
            message  = mess,
            buttons  = butt,
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelMoreMines(e.button,button) end )
                       end,
                  })                                                          
    --end
end
end

----------------------------------------------------------------------------------------------------
function skull.travelMoreMines(button,menu)
     
  if ( button == 0 ) then
    -- back menu
      skull.showMines(4)
  
  elseif (menu == 23 and button == 17 ) then
        -- more
          skull.travelMines(5)         
        
  else
    
    local mapcoord = {} 
     
    if (menu == 23 ) then 
      mapcoord = locations.minesEgg(1)
 
    elseif (menu == 24 ) then 
      mapcoord = locations.minesEgg(2)
 
     elseif( menu == 25 ) then   -- Ebony
       mapcoord = locations.minesEbony()
       
     elseif ( menu == 26 ) then   -- Glass
       mapcoord = locations.minesGlass()
       
     elseif ( menu == 27 ) then   -- Diamond
       mapcoord = locations.minesDiamond()
       
     end
     
      for _, loc in pairs(mapcoord) do  
        if ( loc.id == button ) then   
            lCell = loc.cell
            lPos  = loc.pos
            lRot  = loc.rot
          
        end
      end
      
      if ( lCell ~= nil ) then   -- just in case.
         tes3.positionCell({ reference = tes3.player, 
                           cell               = lCell, 
                           position           = lPos,
                           orientation        = lRot,  
                           forceCellChange    = false,    --- hmmm.....
                           suppressFader      = true,     -- false, 
                           teleportCompanions = lTeleport })  
      end 
  end
end
----------------------------------------------------------------------------------------------------
function skull.travelTowers(button)
  if ( button == 0 ) then
      -- back menu
        skull.travelSecret(0)

  else     
    local mapcoord = locations.Towers()
    
    for _, loc in pairs(mapcoord) do  
      if ( loc.id == button ) then   
          lCell = loc.cell
          lPos  = loc.pos
          lRot  = loc.rot
        
      end
    end  
    if ( lCell ~= nil ) then   -- just in case.
       tes3.positionCell({ reference = tes3.player, 
                         cell               = lCell, 
                         position           = lPos,
                         orientation        = lRot,  
                         forceCellChange    = false,    --- hmmm.....
                         suppressFader      = true,     -- false, 
                         teleportCompanions = lTeleport })  
    end 
  end  
end

----------------------------------------------------------------------------------------------------
function skull.travelCave(button)
 
  if ( button == 0 ) then
      -- back menu
      skull.travelSecret(0)
        
  else 
 
      local buttons = locations.mainmenu()
      
      if ( button == 1 ) then   
         button  = 30    --"Bandit1"
         
      elseif ( button == 2 ) then
          button  = 31    --"Bandit2"
          
      elseif ( button == 3 ) then
        button  = 32       --"6th House"
        
      elseif ( button == 4 ) then
        button  = 33       --"Slaver"
      
      elseif ( button == 5 ) then
         return
      end

        for _, id in pairs(buttons) do  
            if ( id.id == button ) then   
                butt = id.butt
                mess = "Select a Mine."   --id.mess
            end
        end

        --if ( nID ) then
            tes3.messageBox({
                message  = mess,
                buttons  = butt,
                callback = function(e)
                              timer.delayOneFrame( function() skull.travelMoreCaves(e.button,button) end )
                           end,
                      })                                                          
        --end
  end  
end   

----------------------------------------------------------------------------------------------------
function skull.travelMoreCaves(button,buttons)
--  local locations
 
  if ( button == 0 ) then
      -- back menu
      skull.showCaves(6)
  else

    local mapcoord = {} 
     
    if ( buttons == 30 ) then
      mapcoord = locations.travelCaves1()  --(1)     --"Bandit1"
        
    elseif ( buttons == 31 ) then
      mapcoord = locations.travelCaves2()  --(2)     --"Bandit2"
        
    elseif ( buttons == 32 ) then
      mapcoord = locations.travelCaves3()  --(3)       --"6th House"
      
    elseif ( buttons == 33 ) then
      mapcoord = locations.travelCaves4()  --(4)       --"Slaver"
      
    end

    for _, loc in pairs(mapcoord) do  
      if ( loc.id == button ) then   
          lCell = loc.cell
          lPos  = loc.pos
          lRot  = loc.rot
        
      end
    end
    
    if ( lCell ~= nil ) then   -- just in case.
       tes3.positionCell({ reference = tes3.player, 
                         cell               = lCell, 
                         position           = lPos,
                         orientation        = lRot,  
                         forceCellChange    = false,    --- hmmm.....
                         suppressFader      = true,     -- false, 
                         teleportCompanions = lTeleport })  
    end  
  end
end

----------------------------------------------------------------------------------------------------
function skull.travelShips(button)
    
  if ( button == 0 ) then
      -- back menu
        skull.travelSecret(7)        
        
  else
      
    local buttons = locations.mainmenu()
    
    if ( button == 1 ) then   
       button  = 40    --"Full Ships"
       
    elseif ( button == 2 ) then
        button  = 41    --"Shipwrecks A-N"
        
    elseif ( button == 3 ) then
        button  = 42    --"Shipwrecks N-Z"
    
    end
   
      for _, id in pairs(buttons) do  
          if ( id.id == button ) then   
              butt = id.butt
              mess = "Select a Ship."   --id.mess
          end
      end

      --if ( nID ) then
          tes3.messageBox({
              message  = mess,
              buttons  = butt,
              callback = function(e)
                            timer.delayOneFrame( function() skull.travelMoreShips(e.button,button) end )
                         end,
                    })                                                          
      --end
  end  
end

----------------------------------------------------------------------------------------------------
function skull.travelMoreShips(button,buttons)
 
  if ( button == 0 ) then
      -- back menu
      skull.showShips(7)
  else

    local mapcoord = {}
    
     if ( buttons == 40) then
        mapcoord = locations.travelShips(1)     --"Full Ship"
        
    elseif ( buttons == 41 ) then
        mapcoord = locations.travelShips(2)     --"Shipwrecks A-N"
    
    elseif ( buttons == 42 ) then
        mapcoord = locations.travelShips(3)     --"Shipwrecks N-Z"
    
    end

    for _, loc in pairs(mapcoord) do  
      if ( loc.id == button ) then   
          lCell = loc.cell
          lPos  = loc.pos
          lRot  = loc.rot
        
      end
    end
    
    if ( lCell ~= nil ) then   -- just in case.
       tes3.positionCell({ reference = tes3.player, 
                         cell               = lCell, 
                         position           = lPos,
                         orientation        = lRot,  
                         forceCellChange    = false,    --- hmmm.....
                         suppressFader      = true,     -- false, 
                         teleportCompanions = lTeleport })  
    end 
  end
end

----------------------------------------------------------------------------------------------------
function skull.travelTaverns(button,buttons)
    
  if ( button == 0 ) then
      -- back menu
        skull.travelSecret(8)
  else

     local buttons = locations.mainmenu()
      
      if ( button == 1 ) then
         button = 50
         
      elseif ( button == 2 ) then
         button = 51
             
      end
     
        for _, id in pairs(buttons) do  
            if ( id.id == button ) then   
                butt = id.butt
                mess = "Select a Tavern."   --id.mess
            end
        end

        --if ( nID ) then
            tes3.messageBox({
                message  = mess,
                buttons  = butt,
                callback = function(e)
                              timer.delayOneFrame( function() skull.travelMoreTaverns(e.button,button) end )
                           end,
                      })                                                          
        --end
  end  
end

----------------------------------------------------------------------------------------------------
function skull.travelMoreTaverns(button,buttons)  
 
  if ( button == 0 ) then
      -- back menu
      skull.showTaverns(8)
        
  else
   
    local mapcoord = {}
    
    if ( buttons == 50 ) then
       mapcoord = locations.Taverns(1)
       
    elseif ( buttons == 51 ) then

       mapcoord = locations.Taverns(2)
           
    end

    for _, loc in pairs(mapcoord) do  
      if ( loc.id == button ) then   
          lCell = loc.cell
          lPos  = loc.pos
          lRot  = loc.rot
        
      end
    end
    
    if ( lCell ~= nil ) then   -- just in case.
       tes3.positionCell({ reference = tes3.player, 
                         cell               = lCell, 
                         position           = lPos,
                         orientation        = lRot,  
                         forceCellChange    = false,    --- hmmm.....
                         suppressFader      = true,     -- false, 
                         teleportCompanions = lTeleport }) 
    end 
  end  
end

----------------------------------------------------------------------------------------------------
function skull.travelGuilds(button,buttons)   
    
  if ( button == 0 ) then
      -- back menu
        skull.travelSecret(0)
        
  else 
   
    local buttons = locations.mainmenu()

    if ( button == 1 ) then
       button = 60
       
    elseif ( button == 2 ) then
       button = 61
           
    end
   
   
      for _, id in pairs(buttons) do  
          if ( id.id == button ) then   
              butt = id.butt
              mess = "Select a Guild."   --id.mess
          end
      end

      --if ( nID ) then
          tes3.messageBox({
              message  = mess,
              buttons  = butt,
              callback = function(e)
                            timer.delayOneFrame( function() skull.travelMoreGuilds(e.button,button) end )
                         end,
                    })                                                          
      --end
  end  
end
----------------------------------------------------------------------------------------------------
function skull.travelMoreGuilds(button,buttons)  
  
  if ( button == 0 ) then
      -- back menu
        skull.showGuilds(9)
        
  else
    
    local mapcoord = {}    
    if ( buttons == 60 ) then
       mapcoord = locations.Guilds(1)
       
    elseif ( buttons == 61 ) then
       mapcoord = locations.Guilds(2)
           
    end

    for _, loc in pairs(mapcoord) do  
      if ( loc.id == button ) then   
          lCell = loc.cell
          lPos  = loc.pos
          lRot  = loc.rot
        
      end
    end

    if ( lCell ~= nil ) then   -- just in case.
       tes3.positionCell({ reference = tes3.player, 
                         cell               = lCell, 
                         position           = lPos,
                         orientation        = lRot,  
                         forceCellChange    = false,    --- hmmm.....
                         suppressFader      = true,     -- false, 
                         teleportCompanions = lTeleport }) 
    end 
  end  
end

----------------------------------------------------------------------------------------------------
function skull.travelBarrows(button)
    
  if ( button == 0 ) then
      -- back menu
      skull.travelSecret(0)
  else
    
    local mapcoord = locations.Barrows()
    for _, loc in pairs(mapcoord) do  
      if ( loc.id == button ) then   
          lCell = loc.cell
          lPos  = loc.pos
          lRot  = loc.rot
        
      end
    end  
    if ( lCell ~= nil ) then   -- just in case.
       tes3.positionCell({ reference = tes3.player, 
                         cell               = lCell, 
                         position           = lPos,
                         orientation        = lRot,  
                         forceCellChange    = false,    --- hmmm.....
                         suppressFader      = true,     -- false, 
                         teleportCompanions = lTeleport }) 
    end 
  end  
  
end
--[[
----------------------------------------------------------------------------------------------------
function skull.travelBack()
lCell = nil
lPos  = {}
lRot  = {}

end
--]]
------------------------------------------------------------------------------------------------------
function skull.showMoreCamps(button)

local buttons = locations.mainmenu()  --MoreCamps()
    for _, id in pairs(buttons) do  
        if ( id.id == button ) then   
            butt = id.butt
            mess = "Select a camp."   --id.mess
        end
    end

    --if ( nID ) then
        tes3.messageBox({
            message  = mess,
            buttons  = butt,
            callback = function(e)                             
                          timer.delayOneFrame( function() skull.travelMoreCamps(e.button) end )
                       end,
                  })                                                          
    --end

end
------------------------------------------------------------------------------------------------------
function skull.showLandmarks(button)
    local buttons = locations.mainmenu()

    for _, id in pairs(buttons) do  
        if ( id.id == button ) then   
            butt = id.butt
            mess = "Select a Landmark."  --id.mess
        end
    end

    --if ( nID ) then
        tes3.messageBox({
            message  = mess,
            buttons  = butt,
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelLandmarks(e.button) end )
                       end,
                  })                                                          
    --end

end

------------------------------------------------------------------------------------------------------
function skull.showGrottos(button)
local buttons = locations.mainmenu()

    for _, id in pairs(buttons) do  
        if ( id.id == button ) then   
            butt = id.butt
            mess = "Select a Grotto."  --id.mess
        end
    end

    --if ( nID ) then
        tes3.messageBox({
            message  = mess,
            buttons  = butt,
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelGrottos(e.button) end )
                       end,
                  })                                                          
    --end
end
------------------------------------------------------------------------------------------------------
function skull.showMines(button)  -- {4 == "Back..." "Ebony", "Glass", "Diamond", "Egg", "Cancel"}
local buttons = locations.mainmenu()

    for _, id in pairs(buttons) do  
        if ( id.id == button ) then   
            butt = id.butt
            mess = "Select a Mine type."  --id.mess
        end
    end

    --if ( nID ) then
        tes3.messageBox({
            message  = mess,
            buttons  = butt,
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelMines(e.button) end )
                       end,
                  })                                                          
    --end
end

------------------------------------------------------------------------------------------------------
function skull.showTowers(button)
  
 local buttons = locations.mainmenu()

    for _, id in pairs(buttons) do  
        if ( id.id == button ) then   
            butt = id.butt
            mess = "Select a tower."  --id.mess
        end
    end
    
    --if ( nID ) then
        tes3.messageBox({
            message  = mess,
            buttons  = butt,
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelTowers(e.button) end )
                       end,
                  })                                                          
    --end
 
end

--[[
------------------------------------------------------------------------------------------------------
function skull.showAncestral()
  local buttons = locations.mainmenu()

    for _, id in pairs(buttons) do  
        if ( id.id == 6 ) then   
            butt = id.butt
            mess = "Select a Ancestral Tomb."  --id.mess
        end
    end

    --if ( nID ) then
        tes3.messageBox({
            message  = mess,
            buttons  = butt,
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelAncestral(e.button+10) end )
                       end,
                  })                                                          
    --end

end 
--]]  
------------------------------------------------------------------------------------------------------
function skull.showCaves(button)
if ( button == 0 ) then
    -- back menu
      skull.travelSecret(0)
else
    local buttons = locations.mainmenu()
   
      for _, id in pairs(buttons) do  
          if ( id.id == button ) then   
              butt = id.butt
              mess = "Select a Cave."  --id.mess
          end
      end

      --if ( nID ) then
          tes3.messageBox({
              message  = mess,
              buttons  = butt,
              callback = function(e)
                            timer.delayOneFrame( function() skull.travelCave(e.button) end )
                         end,
                    })                                                          
      --end
  end  
end 

------------------------------------------------------------------------------------------------------
function skull.showShips(button)
  local buttons = locations.mainmenu()
  
    for _, id in pairs(buttons) do  
        if ( id.id == button ) then   
            butt = id.butt
            mess = "Select a Ship."  --id.mess
        end
    end

    --if ( nID ) then
        tes3.messageBox({
            message  = mess,
            buttons  = butt,
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelShips(e.button) end )
                       end,
                  })                                                          
    --end
    
end 

------------------------------------------------------------------------------------------------------
function skull.showTaverns(button)
  local buttons = locations.mainmenu()
    
    for _, id in pairs(buttons) do  
        if ( id.id == button ) then   
            butt = id.butt
            mess = "Select a Tavern."  --id.mess
        end
    end

    --if ( nID ) then
        tes3.messageBox({
            message  = mess,
            buttons  = butt,
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelTaverns(e.button,button) end )
                       end,
                  })                                                          
    --end
    
end 

------------------------------------------------------------------------------------------------------
function skull.showGuilds(button)
  
  if ( button == 0 ) then
      -- back menu
        skull.travelSecret(0)
  else
    
      local buttons = locations.mainmenu()

      for _, id in pairs(buttons) do  
          if ( id.id == button ) then   
              butt = id.butt
              mess = "Select a Guild."  --id.mess
          end
      end

      --if ( nID ) then
          tes3.messageBox({
              message  = mess,
              buttons  = butt,
              callback = function(e)
                            timer.delayOneFrame( function() skull.travelGuilds(e.button,button) end )
                         end,
                    })                                                          
      --end
  end      
end

------------------------------------------------------------------------------------------------------
function skull.showBarrows(button)

 local buttons = locations.mainmenu()

    for _, id in pairs(buttons) do  
        if ( id.id == button ) then   
            butt = id.butt
            mess = "Select a Barrow."  --id.mess
        end
    end
    

    --if ( nID ) then
        tes3.messageBox({
            message  = mess,
            buttons  = butt,
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelBarrows(e.button) end )
                       end,
                  })                                                          
    --end
 
end

------------------------------------------------------------------------------------------------------
function skull.travelCustom(e)

local t = mwse.loadConfig("CrystalSkullMenu")  
local t2 = t[e+1]

  if ( t2 ) then
 
      tes3.positionCell({ reference = tes3.player, 
                      cell               = t2.cell, 
                      position           = {t2.posx, t2.posy, t2.posz},
                      orientation        = {0,0,t2.rotz},  
                      forceCellChange    = false,    --- hmmm.....
                      suppressFader      = true,     -- false, 
                      teleportCompanions = lTeleport })    
      
  end
end

------------------------------------------------------------------------------------------------------
function skull.OpenCustom(e)

 local buttons = mwse.loadConfig("CrystalSkullMenu")

    local size = table.size(buttons)
    local butt = {size}
    for i, id in pairs(buttons) do  
        butt[i] = id.mess            
    end
    butt[size+1] = "Cancel" 
       
    tes3.messageBox({
        message  = "Select a custom location.",
        buttons  = butt,
        callback = function(e)
                   timer.delayOneFrame( function() skull.travelCustom(e.button) end )
                   end,
              })           

end

------------------------------------------------------------------------------------------------------
function skull.SetName()  
  
  local name = textedit.name
      
  local p = tes3.player.position
  local r = tes3.player.orientation
  local location = { 
      cell = tes3.player.cell.id,
      posx = math.round(p.x,0), 
      posy = math.round(p.y,0), 
      posz = math.round(p.z,0),
      rotz = math.round(r.z,0),
      mess = name
  }       
  
  local t = mwse.loadConfig("CrystalSkullMenu")
  if ( t ) then        
 
     table.insert(t, location )
     mwse.saveConfig("CrystalSkullMenu", t )

  else
     local new = {location}
     mwse.saveConfig("CrystalSkullMenu", new )

  end
end
  

------------------------------------------------------------------------------------------------------
function skull.AddCustom(e)
  
  timer.delayOneFrame( function() textedit.createWindow(e); timer.delayOneFrame( function() skull.SetName() end ) end )

end

------------------------------------------------------------------------------------------------------
function skull.RemoveCustom(button)
  
  local t = mwse.loadConfig("CrystalSkullMenu")

  table.remove(t,button+1)
  mwse.saveConfig("CrystalSkullMenu", t )
  
end

------------------------------------------------------------------------------------------------------
function skull.DelCustom(e)

 local buttons = mwse.loadConfig("CrystalSkullMenu")
    
    local size = table.size(buttons)
    local butt = {size+1}
    for i, id in pairs(buttons) do  
        butt[i] = id.mess      
    end
    butt[size+1] = "Cancel"    
        
    tes3.messageBox({
        message  = "Select a location to remove.",
        buttons  = butt,
        callback = function(e)
                   timer.delayOneFrame( function() skull.RemoveCustom(e.button) end )
                   end,
              })             

end

------------------------------------------------------------------------------------------------------
function skull.travel(button)
-- Secondary menu according to choice from first menu.
--[[
id = 1,  butt = {"Towns", "Cancel"}                                                                                                
id = 2,  butt = {"Towns", "Strongholds", "Cancel"}                                                                                   
id = 3,  butt = {"Towns", "Strongholds", "Camps", "Cancel"}                                                                          
id = 4,  butt = {"Towns", "Strongholds", "Camps", "Great House Stronghold", "Misc", "Custom", "Cancel"}                                        
id = 5,  butt = {"Towns", "Strongholds", "Camps", "Great House Stronghold", "Misc", "Custom", "Secret Masters", "Cancel"}                      
id = 6,  butt = {"Towns", "Strongholds", "Camps", "Great House Stronghold", "Misc", "Custom", "Secret Masters", "Shrines", "Cancel"}           
id = 7,  butt = {"Towns", "Strongholds", "Camps", "Great House Stronghold", "Misc", "Custom", "Secret Masters", "Shrines", "Ruins", "Cancel"}    
id = 8,  butt = {"Towns", "Strongholds", "Camps", "Great House Stronghold", "Misc", "Custom", "Secret Masters", "Shrines", "Ruins", "Ultimate", "Cancel"}  
                    0           1           2             3                    4        5             6            7        8          9         10
--]]  
  
  if (LikePC == 0) then
      -- just in case
     return
  end
  if ( LikePC == 1 and button == 1 ) or
     ( LikePC == 2 and button == 2 ) or 
     ( LikePC == 3 and button == 3 ) or 
     ( LikePC == 4 and button == 6 ) or 
     ( LikePC == 5 and button == 7 ) or 
     ( LikePC == 6 and button == 8 ) or 
     ( LikePC == 7 and button == 9 ) or
     ( LikePC == 8 and button == 10 ) then   -- ( LikePC == 8 and button == 9 ) then 
    
    return  -- these are the cancel buttons depending on LikePC menus
    
  end
  
  local butt 
  local mess 
  --local nID 
  local buttons = buttons.mainmenu()
mwse.log("*** button = %s", button)  
  if (button == 0) then         -- "Towns"
     if (LikePC == 1) then
        button = 10
     elseif (LikePC >= 2) then  
        button = 110 
     end

     for _, id in pairs(buttons) do  
        if ( id.id == button ) then   
            butt = id.butt
            mess = id.mess
            nID  = id.id
        end
    end

    if ( nID ) then
        tes3.messageBox({
            message  = mess,
            buttons  = butt,
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelTown(e.button) end )
                       end,
                  })                                                          
    end

  elseif (button == 1) then     -- "Strongholds"
      if (LikePC < 2 ) then
         -- just in case
         return
      elseif (LikePC == 2) then  
          for _, id in pairs(buttons) do
              if ( id.id == 20 ) then
                butt = id.butt
                mess = id.mess
                nID  = id.id
             end
          end
      elseif (LikePC >= 3) then  
          for _, id in pairs(buttons) do
              if ( id.id == 21 ) then
                butt = id.butt
                mess = id.mess
                nID  = id.id
             end
          end
      end 
      
      if ( nID ) then
        tes3.messageBox{
            message  = mess,
            buttons  = butt,   
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelStronghold(e.button,nID) end )
                       end
                  }                                                           
      end

  elseif (button == 2) then     -- "Camps"
    for _, id in pairs(buttons) do
         if ( id.id == 30 ) then
                butt = id.butt
                mess = id.mess
                nID  = id.id
        end

    end
   if ( nID ) then
        tes3.messageBox{
            message  = mess,
            buttons  = butt,   
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelCamps(e.button) end )
                       end
                  }                                                           
    end 
					
  elseif (button == 3) then     -- "Great House Stronghold"
    for _, id in pairs(buttons) do
         if ( id.id == 40 ) then
                butt = id.butt
                mess = id.mess
                nID  = id.id
        end

    end
    if ( nID ) then
        tes3.messageBox{
            message  = mess,
            buttons  = butt,   
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelGreatHouse(e.button) end )
                       end
                  }                                                           
    end 
					
  elseif (button == 4) then     -- "Misc"
    for _, id in pairs(buttons) do
         if ( id.id == 50 ) then
                butt = id.butt
                mess = id.mess
                nID  = id.id
        end

    end
    if ( nID ) then
        tes3.messageBox{
            message  = mess,
            buttons  = butt,   
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelMisc(e.button) end )
                       end
                  }                                                           
    end 
    
-- [[
  elseif ( button == 5 ) then   -- custom
        messageBox{
            message = "What do you want to do?",
            buttons = {{ text = "Menu",   callback = function() timer.delayOneFrame( function() skull.OpenCustom(e) end ) end  },            
                       { text = "New",    callback = function() timer.delayOneFrame( function() skull.AddCustom(e) end  ) end  }, 
                       { text = "Remove", callback = function() timer.delayOneFrame( function() skull.DelCustom(e) end  ) end  }, 
                       { text = "Cancel", callback = function() return end}  }                
                  }

--]]
					
  elseif (button == 6) then     -- "Secret Masters"
    for _, id in pairs(buttons) do
         if ( id.id == 60 ) then
                butt = id.butt
                mess = id.mess
                nID  = id.id
        end

    end
    if ( nID ) then
        tes3.messageBox{
            message  = mess,
            buttons  = butt,   
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelMasters(e.button,nID) end )
                       end
                  }                                                           
    end 
					
  elseif (button == 7) then     -- "Shrines"
    for _, id in pairs(buttons) do
         if ( id.id == 70 ) then
                butt = id.butt
                mess = id.mess
                nID  = id.id
        end

    end
    if ( nID ) then
        tes3.messageBox{
            message  = mess,
            buttons  = butt,   
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelShrines(e.button) end )
                       end
                  }                                                           
    end 
					
  elseif (button == 8) then     -- "Ruins"
    for _, id in pairs(buttons) do
         if ( id.id == 80 ) then
                butt = id.butt
                mess = id.mess
                nID  = id.id
        end
     end   
     if ( nID ) then
        tes3.messageBox{
            message  = mess,
            buttons  = butt,   
            callback = function(e)
                          timer.delayOneFrame( function() skull.travelRuins(e.button,nID) end )
                       end
                  }                                                           
      end 
--[[      
  elseif ( button == 8 ) then   -- custom
        messageBox{
            message = "What do you want to do?",
            buttons = {{ text = "Menu",   callback = function() timer.delayOneFrame( function() skull.OpenCustom(e) end ) end  },            
                       { text = "New",    callback = function() timer.delayOneFrame( function() skull.AddCustom(e) end  ) end  }, 
                       { text = "Remove", callback = function() timer.delayOneFrame( function() skull.DelCustom(e) end  ) end  }, 
                       { text = "Cancel", callback = function() return end}  }                
                  }
--]]
        
  elseif (button == 9) then     -- "Secret" -- currently have no idea what/where this could lead ???
      skull.travelSecret()
  
  elseif (button == 100) then     -- "More Camps"
    skull.showMoreCamps(1)
  
  elseif (button == 101) then     -- "Landmarks"
    skull.showLandmarks(2)
    
  elseif (button == 102) then     -- "Grottos"
    skull.showGrottos(3)
    
  elseif (button == 103) then     -- "Mines"
    skull.showMines(4)
    
  elseif (button == 104) then     -- "Velothi Towers"
    skull.showTowers(5)
    
  elseif (button == 105) then     -- "Caves"
    skull.showCaves(6)
    
  elseif (button == 106) then     -- "Ships"
    skull.showShips(7)
    
  elseif (button == 107) then     -- "Taverns"
    skull.showTaverns(8)
    
  elseif (button == 108) then     -- "Guilds"
    skull.showGuilds(9)

  elseif (button == 109) then     -- "Barrows"
    skull.showBarrows(10)

  elseif (button == 999) then     -- "Cancel"
					
  end
  
end

------------------------------------------------------------------------------------------------------
function skull.showTravelMenu()
-- This is the initial menu set according to LikePC level.
local buttons = buttons.mainmenu()
local butt
local mess
          
tes3ui.leaveMenuMode()
--menu:destroy()

    for _, id in pairs(buttons) do      
      if ( id.id == LikePC ) then        
          butt = id.butt
          mess = id.mess
          nID  = id.id
      end
    end
 
    if ( nID ) then  -- and ( nID < 8  ) then
            tes3.messageBox({
                message  = mess,
                buttons  = butt,
                callback = function(e)
                              timer.delayOneFrame( function() AllowActivate = true; skull.travel(e.button) end )
                           end,
                      })                                                          
    end
end

------------------------------------------------------------------------------------------------------
local function onEquipSkull(e)   
-- Set skull access level via MCM ????.
local lLike, lComp, lVamp, lWolf, lCombat, lCrime, lJail, lBounty = false
 --[[
MCM - cheat options:
-----------
lCombat = Aloww use during combat
lCrime  = Ignore crime
lJail   = Allow use from in jail
lVamp   = Allow use by Vampires
lWolf   = Allow use while Werewolf form
lLike   = Set LikePC level - remove global var
lComp   = Transport with companions - remove global var
lBounty = ignore all bounty 
    combatEnabled = true,
    jailEnabled = true,
    WolfEnabled = true,
    VampEnabled = true,
    crimeEnabled = true,
    setCrime = 500,
    compEnabled = true,
    setlikeLv = 0,
--]]

if (e.item.id:lower() == "tw_crystalskull_misc" ) then
    LikePC = 0    -- Apparently it can be NIL !!!
    
    local ref = tes3.mobilePlayer  --tes3.player
    --lTeleport = tes3.getGlobal("tw_Teleport")   -- option for compainion teleporting - default 0 now MCM
  
    local isVampiric = tes3.player.bodyPartManager:getActiveBodyPart(tes3.activeBodyPartLayer.base, tes3.activeBodyPart.head).bodyPart.vampiric
      
    if ( ref.inCombat and config.combatEnabled ) then
         tes3.messageBox("You cannot use me during combat. Destroy your enemy.")
         return
    end
    
    if ( ref.inJail and config.jailEnabled ) then    
        tes3.messageBox("You are not worthy, criminal. Do your time.")
        LikePC = 0
        return
    end
    
   if ( ref.bounty > config.setCrime and config.crimeEnabled ) then
        tes3.messageBox("You are not worthy, criminal. Pay your fines.")
        LikePC = 0
        return
    end
    
    if ( ref.werewolf and config.WolfEnabled ) then
        tes3.messageBox("You are not worthy of me monster.")
        LikePC = 0
        return
    end
    
    if  ( isVampiric  and config.VampEnabled ) then
        tes3.messageBox("You are not worthy of me foul creature.")
        LikePC = 0
        return
    end
    
    --reputation
    local nRep  = tes3.player.object.reputation
    local nMyst = ref.mysticism.current
    local nInt  = ref.intelligence.current
    local nIll  = ref.illusion.current
    if ( nRep >= 90 ) then
      LikePC = 7   -- everywhere.
    elseif ( nRep >= 60 ) then
      LikePC = 6
    elseif ( nRep >= 15 ) then
      if ( nIll >= 60 ) then
         LikePC = 6
      else
         if ( nMyst >= 55 ) then
            LikePC = 5
         else
            LikePC = 4
         end
      end
    elseif ( nRep >= 5 ) then
      if ( nMyst >= 55 ) then
         LikePC = 4
      else
         LikePC = 3
      end
    else
      if ( nInt >= 60  ) then
         LikePC = 2  -- a bit more
      elseif ( nInt >= 53 ) then
         LikePc = 1   -- only bacic 
      else
        if ( config.setlikeLv == 0 ) then
          tes3.messageBox("You are not yet worthy of me. But don't give up.")            
          LikePC = 0
        end
      end
    end
    
    local nLv = config.setLikeLv    
    if ( nLv and nLv > LikePC ) then LikePC = nLv  end  
    local GlobLike = tes3.getGlobal("tw_LikePC")    
    if ( GlobLike > LikePC ) then LikePC = GlobLike end
    if ( GlobLike == 911 ) then  -- a fairly worldwide used emergancy number
        LikePC = 8
    elseif ( LikePC > 7 ) then   -- someone is bound to try - maybe they think there maybe a secrete level - teehehe
      LikePC = 7 
    end
    if ( LikePC == 0 ) then
      -- catch all probably not needed.
       return
    elseif ( LikePC > 0 ) then
        skull.showTravelMenu()
    end
  end 
end
event.register("equip", onEquipSkull)

------------------------------------------------------------------------------------------------------
local function onActivateSkull(e)
  if (e.target.id:lower() == "tw_crystalskull_act") then
    
      tes3.addItem({
        reference = tes3.player,
        item = "tw_crystalskull_misc",
        count = 1,
        playSound = true,
      })
      
      tes3.setEnabled({ reference = e.target, enabled = false })  -- disable skull activator
  
  end
  
end
event.register("activate", onActivateSkull)

------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------

local function registerConfig()

    local template = mwse.mcm.createTemplate("Taliesan's Crystal Skull")
    template:saveOnClose("Taliesan's Crystal Skull", config)
    template:register()

    local page = template:createSideBarPage({
        label = "Taliesan's Crystal Skull",
    })

    local settings = page:createCategory("Taliesan's Crystal Skull Settings\n\n\n\nCombat")

    settings:createOnOffButton({
        label = "Disable teleporting during combat",
        description = "ON disables use while in combat.\n\nDefault: ON\n\n",
        variable = mwse.mcm.createTableVariable {id = "combatEnabled", table = config}
    })

    local settings1 = page:createCategory("Jail")

    settings1:createOnOffButton({
        label = "Disable teleporting if in Jail",
        description = "ON disables use while in jail.\n\nDefault: ON\n\n",
        variable = mwse.mcm.createTableVariable {id = "jailEnabled", table = config}
    })

   local settings1 = page:createCategory("Werewolf form")

    settings1:createOnOffButton({
        label = "Disable teleporting when in Werewolf form",
        description = "ON disables use while in Werewolf form.\n\nDefault: ON\n\n",
        variable = mwse.mcm.createTableVariable {id = "WolfEnabled", table = config}
    })

  local settings1 = page:createCategory("Vampire")

    settings1:createOnOffButton({
        label = "Disable teleporting when a Vampire",
        description = "ON disables use if Vampire.\n\nDefault: ON\n\n",
        variable = mwse.mcm.createTableVariable {id = "VampEnabled", table = config}
    })

    local settings2 = page:createCategory("Crime")

    settings2:createOnOffButton({
        label = "Disable teleporting if you have a bounty",
        description = "ON disables use while you have a bounty.\n\nBounty amount is set with slider below.\n\nDefault: ON\n\n",
        variable = mwse.mcm.createTableVariable {id = "crimeEnabled", table = config}
    })

    settings2:createSlider({
        label = "Bounty amount to disable teleporting",
        description = "Sets bounty amount to disable teleporting.\n\nNo effect if above button for Bounty is OFF.\n\nDefault: 500\n\n",
        min = 0,
        max = 2000,
        step = 10,
        jump = 100,
        variable = mwse.mcm.createTableVariable{id = "setCrime", table = config}
    })
  
    local settings1 = page:createCategory("Companion travel")

    settings1:createOnOffButton({
        label = "Disable teleporting of Companions",
        description = "ON enables teleporting of Companions.\n\nDefault: OFF\n\n",
        variable = mwse.mcm.createTableVariable {id = "compEnabled", table = config}
    })

    local settings2 = page:createCategory("Menu level")
    
    settings2:createSlider({
        label = "Set the menu level",
        description = "Sets the menu level. 0 - 7.\n\nDefault: 0\n\n",
        min = 0,
        max = 7,
        step = 1,
        jump = 1,
        variable = mwse.mcm.createTableVariable{id = "setLikeLv", table = config}
    })
  
end
event.register("modConfigReady", registerConfig)


--[[  MCM key binding eg.
keyBind = {keyCode = tes3.scanCode.n, isShiftDown = false, isAltDown = false, isControlDown = false},
    
    local settings3 = page:createCategory("Keybind to open menu")
    settings3:createKeyBinder{
        label = "You will need to restart the game for the changes to apply.",
        description = "Changes the keys to open the teleport menu\n\nDefault: N\n\n",
        allowCombinations = true,
        variable = mwse.mcm.createTableVariable{id = "keyBind", table = config, defaultSetting = {keyCode = tes3.scanCode.n, isShiftDown = false, isAltDown = false, isControlDown = false}}
    }

local function modInitialized()
    event.register("keyDown", openMenu, {filter = config.keyBind.keyCode})
end
event.register("initialized", modInitialized)
--]]