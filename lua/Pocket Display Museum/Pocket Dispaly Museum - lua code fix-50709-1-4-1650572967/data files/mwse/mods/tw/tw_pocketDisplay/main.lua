--[[
Pocket Display Museum
by
the Wanderer

--]]
----------------------------------------------------------------------------------------------------

local messageBox = require("tw.tw_pocketDisplay.stuff")
local messageBox = require("tw.tw_pocketDisplay.info") -- to come v2 ???
local messageBox = require("tw.MessageBox")


mwse.log("[Pocket Display Museum] Loaded successfully.")

-- array of display misc/act items
local MiscDisplays =  dofile("tw.tw_pocketDisplay.stuff")

local doOnce3

local function setDoOnce(ref,Var)
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.tw_pocketDisplay = refData.tw_pocketDisplay or {} -- Force initializing the parent table.
    refData.tw_pocketDisplay.doOnce1 = Var -- Actually set your value.
end

local function getDoOnce(ref)
    local refData = ref.data
    return refData.tw_pocketDisplay and refData.tw_pocketDisplay.doOnce1
end

local function setDoOnce2(ref,Var)
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.tw_pocketDisplay = refData.tw_pocketDisplay or {} -- Force initializing the parent table.
    refData.tw_pocketDisplay.doOnce2 = Var -- Actually set your value.
end

local function getDoOnce2(ref)
    local refData = ref.data
    return refData.tw_pocketDisplay and refData.tw_pocketDisplay.doOnce2
end

----------------------------------------------------------------------------------------------------
local function OnCloseChest()
  
-- run script to check display content
  local cell = tes3.player.cell
  local container = tes3.getReference("tw_safe_store_treasure")
  
      for eitem in cell:iterateReferences(tes3.objectType.activator) do  -- check all misc objects in museum.

          if MiscDisplays[eitem.id:lower()] then
            local data = MiscDisplays[eitem.id] --:lower()]
            local xRef = tes3.getReference( eitem.id )
            --mwse.log("***  item = %s  **  %s", data.item, tes3.getObject(data.item))       
            if (tes3.getObject(data.item)) then 
                if ( tes3.getItemCount({ reference = container, item = data.item }) >= 1 ) then  
                  
                  tes3.setEnabled({ reference = xRef, enabled = true })
                else
                  tes3.setEnabled({ reference = xRef, enabled = false })
                end
            else
              tes3.setEnabled({ reference = xRef, enabled = false })
                        
            end            
          end        
      end
end

----------------------------------------------------------------------------------------------------
local function setSwitch3(ref, Var)   -- Library fire switch
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.tw_firelighter_01 = tw_firelighter_01 or {} -- Force initializing the parent table.
    refData.tw_firelighter_01.switch = Var -- Actually set your value.
end

local function getSwitch3(ref)
    local refData = ref.data
    return refData.tw_firelighter_01 and refData.tw_firelighter_01.switch
end
         
----------------------------------------------------------------------------------------------------
local function turnLightsOn3()  -- Light the fire
    
    tes3.playSound{ reference = tes3.player, sound = "tw_pd_matchstrike"  }
     
    --if (tes3.getReference("tw_logfire_01").disabled == true ) then              
    tes3.setEnabled({ reference = tes3.getReference("tw_logfire_01"),  enabled = true })
    tes3.setEnabled({ reference = tes3.getReference("tw_logpile_out"), enabled = false })
    --end
end

local function turnLightsOff3(lSwitch)  -- dowse the fire
  
    --if (tes3.getReference("tw_logfire_01").disabled == false ) then
    tes3.setEnabled({ reference = tes3.getReference("tw_logfire_01"),  enabled = false })
    tes3.setEnabled({ reference = tes3.getReference("tw_logpile_out"), enabled = true })    
    --end          
end

----------------------------------------------------------------------------------------------------
local function setSwitch2(ref,Var)   -- Library lights switch
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.tw_lightswitch_02 = tw_lightswitch_02 or {} -- Force initializing the parent table.
    refData.tw_lightswitch_02.switch = Var -- Actually set your value.
end

local function getSwitch2(ref)
    local refData = ref.data
    return refData.tw_lightswitch_02 and refData.tw_lightswitch_02.switch
end

----------------------------------------------------------------------------------------------------
local function turnLightsOn2()  -- Library lights
    
    local cell = tes3.getPlayerCell()
    
    local ref = tes3.getReference("tw_lightSwitch_02")
    tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})

    --if (tes3.getReference("tw_chandelier_light_01").disabled == true ) then
    for item in cell:iterateReferences(tes3.objectType.light) do
      if (item.baseObject.id:lower() == "tw_chandelier_light_01") then   
         tes3.setEnabled({ reference = item, enabled = true })  
         --tes3.setEnabled({ reference = tes3.getReference("tw_chandelier_light_01"), enabled = true })
      end
    end
end

local function turnLightsOff2(lSwitch)
    
    local cell = tes3.getPlayerCell()
    
    local ref = tes3.getReference("tw_lightSwitch_02")
    tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})
    
   for item in cell:iterateReferences(tes3.objectType.light) do
      if (item.baseObject.id:lower() == "tw_chandelier_light_01") then   
         tes3.setEnabled({ reference = item, enabled = false })  
         --tes3.setEnabled({ reference = tes3.getReference("tw_chandelier_light_01"), enabled = true })
      end
    end
end

----------------------------------------------------------------------------------------------------
local function setSwitch4(ref,Var)   -- Daedric display room/gate  switch
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.tw_lightswitch_03 = tw_lightswitch_03 or {} -- Force initializing the parent table.
    refData.tw_lightswitch_03.switch = Var -- Actually set your value.
end

local function getSwitch4(ref)
    local refData = ref.data
    return refData.tw_lightswitch_03 and refData.tw_lightswitch_03.switch
end

----------------------------------------------------------------------------------------------------
local function turnLightsOn4()  -- Daedric lights
    
    local cell = tes3.getPlayerCell()
    
    local ref = tes3.getReference("tw_lightSwitch_03")
    tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})

    tes3.playSound{ reference = tes3.player, sound = "Door Stone Open" }
    
    for item in cell:iterateReferences(tes3.objectType.light) do
      if (item.baseObject.id:lower() == "tw_light_01r") then   
         tes3.setEnabled({ reference = item, enabled = true })  
         
         local ref = tes3.getReference("tw_portcullis_01")
         --LoopGroup Idle1 0 1
	       --Set timer to 1.25
         tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})
         
      end
    end
end

local function turnLightsOff4(lSwitch)
    
    local cell = tes3.getPlayerCell()
    
    if lSwitch then
      local ref = tes3.getReference("tw_lightSwitch_03")
      tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})

      tes3.playSound{ reference = tes3.player, sound = "Door Stone Close" }
      
    end  
    for item in cell:iterateReferences(tes3.objectType.light) do
      if (item.baseObject.id:lower() == "tw_light_01r") then   
         tes3.setEnabled({ reference = item, enabled = false })  
         
         local ref = tes3.getReference("tw_portcullis_01")
         --LoopGroup Idle1 0 1
	       --Set timer to 1.25
         tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle3, loopCount = 0})
         
      end
    end
end

----------------------------------------------------------------------------------------------------
local function setSwitch5(ref,Var)   -- Dwemer display room/gate  switch
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.tw_lightswitch_04 = tw_lightswitch_04 or {} -- Force initializing the parent table.
    refData.tw_lightswitch_04.switch = Var -- Actually set your value.
end

local function getSwitch5(ref)
    local refData = ref.data
    return refData.tw_lightswitch_04 and refData.tw_lightswitch_04.switch
end

----------------------------------------------------------------------------------------------------
local function turnLightsOn5()  -- Dwemer lights
    
    local cell = tes3.getPlayerCell()
    
    local ref = tes3.getReference("tw_lightSwitch_04")
    tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})

    tes3.playSound{ reference = tes3.player, sound = "tw_pd_dwemerlight_on" }
    
    for item in cell:iterateReferences(tes3.objectType.light) do
      if (item.baseObject.id:lower() == "tw_dwrv_neon01") or
         (item.baseObject.id:lower() == "tw_yellow_01") then 
         tes3.setEnabled({ reference = item, enabled = true })  
         
        
      end
    end
end

local function turnLightsOff5(lSwitch)
    
    local cell = tes3.getPlayerCell()
    
    if lSwitch then
        local ref = tes3.getReference("tw_lightSwitch_04")
        tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})
      
    end  
    for item in cell:iterateReferences(tes3.objectType.light) do
      if (item.baseObject.id:lower() == "tw_dwrv_neon01") or
         (item.baseObject.id:lower() == "tw_yellow_01") then   
         tes3.setEnabled({ reference = item, enabled = false })  
         
      end
    end
end

----------------------------------------------------------------------------------------------------
local function setSwitch6(ref,Var)   -- guar display room/gate  switch
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.tw_lightswitch_05 = tw_lightswitch_05 or {} -- Force initializing the parent table.
    refData.tw_lightswitch_05.switch = Var -- Actually set your value.
end

local function getSwitch6(ref)
    local refData = ref.data
    return refData.tw_lightswitch_05 and refData.tw_lightswitch_05.switch
end

local function turnLightsOn6()  -- Guar display lights
    
    local cell = tes3.getPlayerCell()
    
    local ref = tes3.getReference("tw_lightSwitch_05")
    tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})
    
    for item in cell:iterateReferences(tes3.objectType.light) do
      if (item.baseObject.id:lower() == "tw_white_01") or
         (item.baseObject.id:lower() == "tw_sunlight_01") then   
           
         tes3.setEnabled({ reference = item, enabled = true })  
         
      end
    end
    
end

local function turnLightsOff6(lSwitch)
    
    local cell = tes3.getPlayerCell()
    
    if lSwitch then
      
        local ref = tes3.getReference("tw_lightSwitch_05")
        tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})
      
      
    end  
      
    for item in cell:iterateReferences(tes3.objectType.light) do
      if (item.baseObject.id:lower() == "tw_white_01") or
         (item.baseObject.id:lower() == "tw_sunlight_01") then  
           
         tes3.setEnabled({ reference = item, enabled = false })  

      end
    end
end

----------------------------------------------------------------------------------------------------
local function setSwitch7(ref,Var)   -- guar display room/gate  switch
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.tw_lightswitch_06 = tw_lightswitch_06 or {} -- Force initializing the parent table.
    refData.tw_lightswitch_06.switch = Var -- Actually set your value.
end

local function getSwitch7(ref)
    local refData = ref.data
    return refData.tw_lightswitch_06 and refData.tw_lightswitch_06.switch
end
----------------------------------------------------------------------------------------------------
local function turnLightsOn7()  -- Guar display lights
    
    local cell = tes3.getPlayerCell()
    
    local ref = tes3.getReference("tw_lightSwitch_06")
    tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})
  
    for item in cell:iterateReferences(tes3.objectType.light) do
      if (item.baseObject.id:lower() == "tw_light_03") then  --or
         --(item.baseObject.id:lower() == "tw_sunlight_01") then   
           
         tes3.setEnabled({ reference = item, enabled = true })  
         
      end
    end
    
end

local function turnLightsOff7(lSwitch)
    
    local cell = tes3.getPlayerCell()
    
    if lSwitch then
      
        local ref = tes3.getReference("tw_lightSwitch_06")
        tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})
      
      
    end  
    
    for item in cell:iterateReferences(tes3.objectType.light) do
      if (item.baseObject.id:lower() == "tw_light_03")  then   --or
         --(item.baseObject.id:lower() == "tw_sunlight_01") then  
           
         tes3.setEnabled({ reference = item, enabled = false })  

      end
    end
    
end
----------------------------------------------------------------------------------------------------
local function setSwitch8(ref,Var)   --  display room/gate  switch
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.tw_lightswitch_07 = tw_lightswitch_07 or {} -- Force initializing the parent table.
    refData.tw_lightswitch_07.switch = Var -- Actually set your value.
end

local function getSwitch8(ref)
    local refData = ref.data
    return refData.tw_lightswitch_07 and refData.tw_lightswitch_07.switch
end

local function turnLightsOn8()  --  display lights
    
    local cell = tes3.getPlayerCell()
    
    local ref = tes3.getReference("tw_lightSwitch_07")
    tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})

    for item in cell:iterateReferences(tes3.objectType.light) do
      if (item.baseObject.id:lower() == "tw_white_04") then 
         tes3.setEnabled({ reference = item, enabled = true })  
      end
    end
    
end

local function turnLightsOff8(lSwitch)
    
    local cell = tes3.getPlayerCell()
    
    if lSwitch then
      
        local ref = tes3.getReference("tw_lightSwitch_07")
        tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})
      
    end  
    for item in cell:iterateReferences(tes3.objectType.light) do
      if (item.baseObject.id:lower() == "tw_white_04")  then
         tes3.setEnabled({ reference = item, enabled = false })  
      end
    end
    
end

----------------------------------------------------------------------------------------------------
local function setSwitch9(ref,Var)   --  display room/gate  switch
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.tw_lightswitch_08 = tw_lightswitch_08 or {} -- Force initializing the parent table.
    refData.tw_lightswitch_08.switch = Var -- Actually set your value.
end

local function getSwitch9(ref)
    local refData = ref.data
    return refData.tw_lightswitch_08 and refData.tw_lightswitch_08.switch
end
----------------------------------------------------------------------------------------------------
local function turnLightsOn9()  -- display lights
    
    local cell = tes3.getPlayerCell()
    
    local ref = tes3.getReference("tw_lightSwitch_08")
    tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})
    
    for item in cell:iterateReferences(tes3.objectType.light) do
      if (item.baseObject.id:lower() == "tw_white_02") then  
            
          tes3.setEnabled({ reference = item, enabled = true })  
          
      end
    end
end

local function turnLightsOff9(lSwitch)
    
    local cell = tes3.getPlayerCell()
    
    if lSwitch then
      
        local ref = tes3.getReference("tw_lightSwitch_08")
        tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})
      
      
    end  
    for item in cell:iterateReferences(tes3.objectType.light) do
      if (item.baseObject.id:lower() == "tw_white_02")  then 
           
         tes3.setEnabled({ reference = item, enabled = false })  
       
      end
    end
end
---------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
local function setSwitch10(ref,Var)   --  display room/gate  switch
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.tw_lightswitch_09 = tw_lightswitch_09 or {} -- Force initializing the parent table.
    refData.tw_lightswitch_09.switch = Var -- Actually set your value.
end

local function getSwitch10(ref)
    local refData = ref.data
    return refData.tw_lightswitch_09 and refData.tw_lightswitch_09.switch
end
----------------------------------------------------------------------------------------------------
local function turnLightsOn10()  -- display lights
    
    local cell = tes3.getPlayerCell()
    
    local ref = tes3.getReference("tw_lightSwitch_09")
    tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})

    for item in cell:iterateReferences(tes3.objectType.light) do
      if (item.baseObject.id:lower() == "tw_blue ice_01") then  --or 
         tes3.setEnabled({ reference = item, enabled = true })  
      end
    end
end

local function turnLightsOff10(lSwitch)
    
    local cell = tes3.getPlayerCell()
    
    if lSwitch then
      
        local ref = tes3.getReference("tw_lightSwitch_09")
        tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})
      
      
    end  
    for item in cell:iterateReferences(tes3.objectType.light) do
      if (item.baseObject.id:lower() == "tw_blue ice_01")  then 
         tes3.setEnabled({ reference = item, enabled = false })  
      end
    end
end
---------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
local function setSwitch11(ref,Var)   --  display room/gate  switch
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.tw_lightswitch_10 = tw_lightswitch_10 or {} -- Force initializing the parent table.
    refData.tw_lightswitch_10.switch = Var -- Actually set your value.
end

local function getSwitch11(ref)
    local refData = ref.data
    return refData.tw_lightswitch_10 and refData.tw_lightswitch_10.switch
end
----------------------------------------------------------------------------------------------------
local function turnLightsOn11()  -- display lights
    
    local cell = tes3.getPlayerCell()
    
    local ref = tes3.getReference("tw_lightSwitch_10")
    tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})
    
    for item in cell:iterateReferences(tes3.objectType.light) do
      if (item.baseObject.id:lower() == "tw_white_03") then
        
         tes3.setEnabled({ reference = item, enabled = true })    
         
      end
    end
end

local function turnLightsOff11(lSwitch)
    
    local cell = tes3.getPlayerCell()
    
    if lSwitch then
      
        local ref = tes3.getReference("tw_lightSwitch_10")
        tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})
      
    end  
    for item in cell:iterateReferences(tes3.objectType.light) do
      if (item.baseObject.id:lower() == "tw_white_03")  then 
          
        tes3.setEnabled({ reference = item, enabled = false })  
      
      end
    end
end
----------------------------------------------------------------------------------------------------
local function setSwitch12(ref,Var)   --  display room/gate  switch
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.tw_lightswitch_11 = tw_lightswitch_11 or {} -- Force initializing the parent table.
    refData.tw_lightswitch_11.switch = Var -- Actually set your value.
end

local function getSwitch12(ref)
    local refData = ref.data
    return refData.tw_lightswitch_11 and refData.tw_lightswitch_11.switch
end
----------------------------------------------------------------------------------------------------
local function turnLightsOn12()  -- window shutter
    
    local cell = tes3.getPlayerCell()
    
    local ref = tes3.getReference("tw_lightSwitch_11")
    tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})
    
    local refW = tes3.getReference("tw_window_clear_act")
    tes3.playAnimation({reference = refW, group = tes3.animationGroup.idle2, loopCount = 0})
    
end

local function turnLightsOff12(lSwitch)
    
    local cell = tes3.getPlayerCell()
    
    if lSwitch then
      
        local ref = tes3.getReference("tw_lightSwitch_11")
        tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})
        
        local refW = tes3.getReference("tw_window_clear_act")
        tes3.playAnimation({reference = refW, group = tes3.animationGroup.idle3, loopCount = 0})
        
        --timer.delayOneFrame(function() end)  --
        --tes3.playAnimation({reference = refW, group = tes3.animationGroup.idle, loopCount = 0})
       
    end  

end
----------------------------------------------------------------------------------------------------
local function setSwitch13(ref,Var)   --  curators room switch
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.tw_lightswitch_12 = tw_lightswitch_12 or {} -- Force initializing the parent table.
    refData.tw_lightswitch_12.switch = Var -- Actually set your value.
end

local function getSwitch13(ref)
    local refData = ref.data
    return refData.tw_lightswitch_12 and refData.tw_lightswitch_12.switch
end
----------------------------------------------------------------------------------------------------
local function turnLightsOn13()  -- curators room lights
    
    local cell = tes3.getPlayerCell()
    
    local ref = tes3.getReference("tw_lightSwitch_12")
    tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})

    --if (tes3.getReference("tw_chandelier_light_01").disabled == true ) then
    for item in cell:iterateReferences(tes3.objectType.light) do
      if (item.baseObject.id:lower() == "tw_chandelier_light_02") then   
         tes3.setEnabled({ reference = item, enabled = true })  
      end
    end
end

local function turnLightsOff13(lSwitch)
    
    local cell = tes3.getPlayerCell()
    
    local ref = tes3.getReference("tw_lightSwitch_12")
    tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle2, loopCount = 0})
    
   for item in cell:iterateReferences(tes3.objectType.light) do
      if (item.baseObject.id:lower() == "tw_chandelier_light_02") then   
         tes3.setEnabled({ reference = item, enabled = false })  
      end
    end
end

---------------------------------------------------------------------------------------------------
local function setWaterFall(ref,Var)  -- Waterfall light switch - maybe turn of waterfall as well !?!?!?
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.tw_waterfall_switch = refData.tw_waterfall_switch or {} -- Force initializing the parent table.
    refData.tw_waterfall_switch.switch = Var -- Actually set your value.
end

local function getWaterFall(ref)
    local refData = ref.data
    return refData.tw_waterfall_switch and refData.tw_waterfall_switch.switch
end

local function turnWaterFallOn()

 local cell = tes3.getPlayerCell()
  
 for item in cell:iterateReferences(tes3.objectType.light) do
    if (item.baseObject.id:lower() == "tw_waterfall_light")  then
         tes3.setEnabled({ reference = item, enabled = true })  
    end
  end
  
  for item in cell:iterateReferences(tes3.objectType.activator) do
    if (item.baseObject.id:lower() == "tw_waterfall_01")       or
       (item.baseObject.id:lower() == "tw_waterfall_mist_01") then
        
      tes3.setEnabled({ reference = item, enabled = true })  
      tes3.playSound({ sound = "Cave_Waterfall", loop = true, volume = 0.5, pitch = 1.0 })
       
    end
  end
end

local function turnWaterFallOff()

 local cell = tes3.getPlayerCell()
  
 for item in cell:iterateReferences(tes3.objectType.light) do
    if (item.baseObject.id:lower() == "tw_waterfall_light")  then
         tes3.setEnabled({ reference = item, enabled = false })  
    end
  end
  
  for item in cell:iterateReferences(tes3.objectType.activator) do
    if (item.baseObject.id:lower() == "tw_waterfall_01")       or
       (item.baseObject.id:lower() == "tw_waterfall_mist_01") then
        
       tes3.setEnabled({ reference = item, enabled = false })  
       tes3.removeSound({ sound = "Cave_Waterfall" })

    end
  end
end

---------------------------------------------------------------------------------------------------
local function setSwitch1(ref,Var)  -- Main display hall switch
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.tw_lightSwitch_01 = refData.tw_lightSwitch_01 or {} -- Force initializing the parent table.
    refData.tw_lightSwitch_01.switch = Var -- Actually set your value.
end

local function getSwitch1(ref)
    local refData = ref.data
    return refData.tw_lightSwitch_01 and refData.tw_lightSwitch_01.switch
end

----------------------------------------------------------------------------------------------------
local function turnLightsOn1()  --target, ref)
  
 --tes3.messageBox("Lights on....") 
 
 local torch01    = tes3.getReference("tw_torch_01")
 local torchout01 = tes3.getReference("tw_torch_out_01")
 local torch02    = tes3.getReference("tw_torch_02")
 local torchout02 = tes3.getReference("tw_torch_out_02")
 local light01    = tes3.getReference("tw_light_01")   
 local torch03    = tes3.getReference("tw_torch_03")  
 local torchout03 = tes3.getReference("tw_torch_out_03")
 local torch04    = tes3.getReference("tw_torch_04") 
 local torchout04 = tes3.getReference("tw_torch_out_04")
 local light02    = tes3.getReference("tw_light_02")
 
  local cell = tes3.getPlayerCell()

     -- play sound wait till played ???
 tes3.playSound{ reference = tes3.player, sound = "tw_pd_torches_on" }

  for item in cell:iterateReferences(tes3.objectType.light) do
    if (item.baseObject.id:lower() == "tw_torch_01") then
       tes3.setEnabled({ reference = item, enabled = true })  
    end
  end

  timer.delayOneFrame(function() end) 
  
  for item in cell:iterateReferences(tes3.objectType.light) do
     if (item.baseObject.id:lower() == "tw_torch_02") or 
        (item.baseObject.id:lower() == "tw_light_01") then
        tes3.setEnabled({ reference = item, enabled = true })  
     end  
  end
    
  timer.delayOneFrame(function() end)  
  
  for item in cell:iterateReferences(tes3.objectType.light) do     
    if (item.baseObject.id:lower()    == "tw_torch_03") then
        tes3.setEnabled({ reference = item, enabled = true })  
    end
  end
    
  timer.delayOneFrame(function() end)  
  
  for item in cell:iterateReferences(tes3.objectType.light) do     
     if (item.baseObject.id:lower() == "tw_torch_04") or
        (item.baseObject.id:lower() == "tw_light_02") then
       tes3.setEnabled({ reference = item, enabled = true })
    end
  end
end

----------------------------------------------------------------------------------------------------
local function turnLightsOff1(lSnd) --target, ref)
 
 local torch01    = tes3.getReference("tw_torch_01")
 local torchout01 = tes3.getReference("tw_torch_out_01")
 local torch02    = tes3.getReference("tw_torch_02")
 local torchout02 = tes3.getReference("tw_torch_out_02")
 local light01    = tes3.getReference("tw_light_01")   
 local torch03    = tes3.getReference("tw_torch_03")  
 local torchout03 = tes3.getReference("tw_torch_out_03")
 local torch04    = tes3.getReference("tw_torch_04") 
 local torchout04 = tes3.getReference("tw_torch_out_04")
 local light02     = tes3.getReference("tw_light_02")
 
 local cell = tes3.getPlayerCell()  --e.cell  --tes3.getActiveCells()
 -- play sound woosh...
 if lSnd then tes3.playSound{ reference = tes3.player, sound = "tw_pd_torches_on" } end
          
  for item in cell:iterateReferences(tes3.objectType.light) do
    if (item.baseObject.id:lower() == "tw_torch_04") then
        tes3.setEnabled({ reference = item, enabled = false })          
    end
  end

  timer.delayOneFrame(function() end)    
  
  for item in cell:iterateReferences(tes3.objectType.light) do
    if (item.baseObject.id:lower() == "tw_torch_03")  or
       (item.baseObject.id:lower() == "tw_light_02") then
        tes3.setEnabled({ reference = item, enabled = false })          
    end
  end
  
  timer.delayOneFrame(function() end)    

  for item in cell:iterateReferences(tes3.objectType.light) do
    if (item.baseObject.id:lower() == "tw_torch_02") then
        tes3.setEnabled({ reference = item, enabled = false })        
    end
  end
  
  timer.delayOneFrame(function() end)  
  
  for item in cell:iterateReferences(tes3.objectType.light) do  
    if (item.baseObject.id:lower() == "tw_torch_01") or
       (item.baseObject.id:lower() == "tw_light_01") then
       tes3.setEnabled({ reference = item, enabled = false })        
    end    
  end 

end


----------------------------------------------------------------------------------------------------
local function TreasureOpen()   
--local function OpenTreasure()  
  
     local container = tes3.getReference("tw_safe_store_treasure") 

      -- Open remote safe store. 
      --timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_safe_store_treasure")) end)
      --timer.delayOneFrame(function(e) AllowActivate = true; tes3.player:activate(container) end)
      tes3.player:activate(container)
      
      mwscript.addItem{ reference = tes3.getReference("tw_safe_store_treasure"), item = "common_ring_05", count = 1 }
      mwscript.removeItem{ reference = tes3.getReference("tw_safe_store_treasure"), item = "common_ring_05", count = 1 }
      --return false
      
end

----------------------------------------------------------------------------------------------------
local function OpenTreasure() 
  
    local container = tes3.getReference("tw_safe_store_treasure")

    timer.delayOneFrame(function() 
        AllowActivate = true
        tes3.player:activate(container)
        timer.delayOneFrame(function() OnCloseChest() end) 
    end) 
end

----------------------------------------------------------------------------------------------------
local function isItemtreasure(item)
  
  for _, list in pairs(MiscDisplays) do
    if item == list.item then
        return true
    end
  end
  
  return false
  
end

----------------------------------------------------------------------------------------------------
local function getSlots(item)
  
  local slots
  for i = 1, 9 do              
    slots = tes3.getQuickKey({ slot = i }).item 
    if slots == item then 
      --mwse.log("true... %s ", slots)      
      return true  
    end    
  end
  
  return false 
  
end

----------------------------------------------------------------------------------------------------
local function TreasureChest()
    local itemsToTransfer = {} ---@type table<tes3item, number>

    for _, stack in pairs(tes3.player.object.inventory) do
        if (isItemtreasure(stack.object.id)) then
            -- Queue our transfer until we're done searching the inventory.    
            if stack.count >= 1 and  --then
              ( tes3.getItemCount({ reference = "tw_safe_store_treasure", item = stack.object }) == 0 ) then
                if mwscript.hasItemEquipped({reference = tes3.player, item = stack.object }) or
                   getSlots(stack.object) then  
                    -- don't remove
                else
                  itemsToTransfer[stack.object] = stack.count                    
                end
            end
        end
    end
    
local container = tes3.getReference("tw_safe_store_treasure")
    -- Did we find anything we want to transfer?
    if (not table.empty(itemsToTransfer)) then
       for item, count in pairs(itemsToTransfer) do        
         if count >= 1 then
            tes3.transferItem({
               from = tes3.player,
               to = container,
               item = item,
               count = 1,    -- only ever take one.
               playSound = true,
           })
         end
       end
    end

end
----------------------------------------------------------------------------------------------------
local function StoreTreasure(e)
  
    timer.delayOneFrame(function() 
        TreasureChest()
        timer.delayOneFrame(function() OnCloseChest() end) 
    end) 
  
end  
 
----------------------------------------------------------------------------------------------------
local function swapDress(e)
--[[
This will swap what the player is wearing with what the mannequin is wearing and vis versa
It will also transfer anything else that was manually added to the mannequin to the player.
--]]  
 local mann = { 
 {id = 1, name = "tw_dress_mannequin_f01" },
 {id = 2, name = "tw_dress_mannequin_m01" },
 {id = 3, name = "tw_dress_mannequin_f02" },
 {id = 4, name = "tw_dress_mannequin_m02" },
}

 local chest = tes3.getReference("tw_dressing_chest")
 local ref = e.target.baseObject.id:lower()   --- "tw_dressing_chest"
 
 for _, slot in pairs(mann) do
    if ( ref == slot.name ) then  
        local num = slot.id
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
  
    end
 end
 
-- Tranfer everything on or in the mannequin to player 
  itemsToTransfer = {}
  local obj = e.target.baseObject or e.target.object
  local ref = tes3.getReference(obj.id) -- this should now be the mannequin.        
  for item, stack in pairs(ref.object.inventory) do
      -- Queue our transfer until we're done searching the inventory.    
      itemsToTransfer[stack.object] = stack.count
  end            
  if (not table.empty(itemsToTransfer)) then
     for item, stack in pairs(itemsToTransfer) do        
        if stack >= 1 then
          
            if (item.objectType == tes3.objectType.armor) or
               (item.objectType == tes3.objectType.clothing ) then
               -- force equip-player
               tes3.transferItem{from=ref, to=tes3.player, item=item, count=item.count}
               mwscript.equip{ reference = tes3.player, item = item }
            else  -- just put it in the players inventory  
                tes3.transferItem({from = ref,
                    to    = tes3.player,
                    item  = item,
                    count = item.count,
                })
            end
        end
     end
     -- Manneqin should now be empty.
  end

-- Transfer dressing chest content to manniquin. Should only be equipable items.
 --*****************************<<<<<<<<<<<<<<<<<<<<<<<<<<< this seems to work !!!!
  for i, stack in pairs(chest.object.inventory) do
      --tes3.transferItem{from = chest, to = ref, item = stack.object, count = stack.count } --, playSound=true}
      mwscript.equip{ reference = ref, item = stack.object }
      mwscript.removeItem{ reference = chest, item = stack.object, count = stack.count }
  end
end

----------------------------------------------------------------------------------------------------
local function leaveMenuModeIfNotInMenu()
    local topMenu = tes3ui.getMenuOnTop()
    local multiMenu = tes3ui.findMenu("MenuMulti")

    if topMenu and multiMenu
      and topMenu.id == multiMenu.id then
        tes3ui.leaveMenuMode()
    end
end
local function showScrollMenu(text)
    tes3ui.showScrollMenu(text)
    local menu = tes3ui.findMenu("MenuScroll")
    menu:registerAfter("destroy", function()
        timer.delayOneFrame(leaveMenuModeIfNotInMenu, timer.real)
    end)
end

----------------------------------------------------------------------------------------------------
local function getDisplayText(e)

    --if (string.sub(e.target.id:lower(), 1, 10) == "tw_plaque_") then  -- grab all the plaques first.
    
        local stext
        local sub = string.sub(e.target.id:lower(), 11 )
        if ( sub == "iron" ) then
            stext = getIron()
        elseif ( sub == "steel" ) then       
            stext = getSteel()
        elseif ( sub == "daedric" ) then   
            stext =  getDaedric()
        elseif ( sub == "dwemer" ) then  
            stext =  getDwemer()
        elseif ( sub == "silver" ) then       
            stext =  getSilver()
        elseif ( sub == "glass" ) then       
            stext =  getGlass()
        elseif ( sub == "ebony" ) then       
            stext =  getEbony()
        elseif ( sub == "nordic" ) then       
            stext =  getNordic() 
        elseif ( sub == "adaman" ) then       
            stext =  getAdamantium()
        elseif ( sub == "ice" ) then       
            stext =  getIce()
        elseif ( sub == "nordicsilver" ) then       
            stext =  getNordicSilver()  -- silver
        elseif ( sub == "chitin" ) then       
            stext =  getChitin()
        elseif ( sub == "bonemold" ) then       
            stext =  getBonemold()
        elseif ( sub == "redguard" ) then       
            stext =  getRedguards()
        elseif ( sub == "orc" ) then       
            stext =  getOrcs()
        elseif ( sub == "bosmer" ) then       
            stext =  getBosmer()
        elseif ( sub == "altmer" ) then       
            stext =  getAltmer()
        elseif ( sub == "imperial" ) then       
            stext =  getImperial()
        elseif ( sub == "argonian" ) then       
            stext =  getArgonian()
        elseif ( sub == "breton" ) then       
            stext =  getBreton()
        elseif ( sub == "dunmer" ) then       
            stext =  getDunmer()
        elseif ( sub == "khajiit" ) then       
            stext =  getKhajiit()
        elseif ( sub == "nord" ) then       
            stext =  getNord()             
        elseif ( sub == "god" ) then       
            stext =  getGod() 
        elseif ( sub == "clavicus" ) then       
            stext =  getClavicus() 
        elseif ( sub == "inspire" ) then       
            stext =  getInspire()   
        elseif ( sub == "terror" ) then       
            stext =  getTerror()   
        elseif ( sub == "tohan" ) then       
            stext =  getTohan()
        elseif ( sub == "bloodworm" ) then       
            stext =  getBloodworm()   
        elseif ( sub == "graff" ) then       
            stext =  getGraff()    
        elseif ( sub == "bearclaw" ) then       
            stext =  getBearclaw()    
        elseif ( sub == "aurielshield" ) then       
            stext =  getaurielshield    
        elseif ( sub == "eleidon" ) then       
            stext =  getEleidon()    
        elseif ( sub == "akavir" ) then       
            stext =  getAkavir() 
        elseif ( sub == "spellbreaker" ) then       
            stext =  getSpellbreaker()    
        elseif ( sub == "unassigned" ) then       
            stext =  getToDo()                       
        elseif ( sub == "free" ) then       
            stext =  getFree()
        elseif ( sub == "jewlery" ) then       
            stext =  getJewlery()
        elseif ( sub == "solstheim" ) then       
            stext =  getSolstheim()            
        elseif ( sub == "grasslands" ) then       
            stext =  getGrassland() 
        elseif ( sub == "ashlands" ) then       
            stext =  getAshland() 
        elseif ( sub == "molagamur" ) then       
            stext =  getMolagAmur()
        elseif ( sub == "onehanded" ) then       
            stext =  getSingle()
        elseif ( sub == "twohanded" ) then       
            stext =  getTwo()
        elseif ( sub == "swords" ) then       
            stext =  getSword() 
        --elseif ( sub == "" ) then       
         --   stext =  get 
        end
      
        if ( stext ~= nil ) then  
           local text = table.concat { [[<DIV ALIGN="LEFT"><FONT COLOR="000000" SIZE="3" FACE="Magic Cards"><BR>Museum Phamphlet<BR>Information:<BR><BR>]], stext, [[<BR>]] }                

           showScrollMenu(text)

        end
    --end  
end

----------------------------------------------------------------------------------------------------
local function switchLights(e)

    if (e.target.id:lower() == "tw_lightswitch_01") then   -- main hall light switch.
        
        -- Toggle the light switch.
        if getSwitch1(e.target) ~= true then
           setSwitch1(e.target, true)
        else
           setSwitch1(e.target, false)
        end  
        
        --local ref = tes3.getReference(e.target.id)
        if getSwitch1(e.target) == true then     
           turnLightsOn1()    
        else
           turnLightsOff1(true)
        end
    end
--=-=-=-=-=-=-=-
    if (e.target.id:lower() == "tw_lightswitch_02") then  -- Library light switch.
        
       -- Toggle the light switch.
        if getSwitch2(e.target) ~= true then
           setSwitch2(e.target, true)
        else
           setSwitch2(e.target, false)
        end    
        
        --local ref = tes3.getReference(e.target.id)
        if getSwitch2(e.target) == true then     
           turnLightsOn2() --e.target, ref, e)    
        else
          turnLightsOff2(true)
        end        
    end    
--=-=-=-=-=-=-=-   
    if (e.target.id:lower() == "tw_lightswitch_03") then  -- Daedric light switch.
        
       -- Toggle the light switch.
        if getSwitch4(e.target) ~= true then
           setSwitch4(e.target, true)
        else
           setSwitch4(e.target, false)
        end    
        
        --local ref = tes3.getReference(e.target.id)
        if getSwitch4(e.target) == true then     
           turnLightsOn4() --e.target, ref, e)    
        else
          turnLightsOff4(true)
        end        
    end    
 --=-=-=-=-=-=-=-
    if (e.target.id:lower() == "tw_lightswitch_04") then  -- Daedric light switch.
        
       -- Toggle the light switch.
        if getSwitch5(e.target) ~= true then
           setSwitch5(e.target, true)
        else
           setSwitch5(e.target, false)
        end    
        
        --local ref = tes3.getReference(e.target.id)
        if getSwitch5(e.target) == true then     
           turnLightsOn5() --e.target, ref, e)    
        else
          turnLightsOff5(true)
        end        
    end    
 --=-=-=-=-=-=-=-
    if (e.target.id:lower() == "tw_lightswitch_05") then  -- Daedric light switch.
        
       -- Toggle the light switch.
        if getSwitch6(e.target) ~= true then
           setSwitch6(e.target, true)
        else
           setSwitch6(e.target, false)
        end    
        
        --local ref = tes3.getReference(e.target.id)
        if getSwitch6(e.target) == true then     
           turnLightsOn6() --e.target, ref, e)    
        else
          turnLightsOff6(true)
        end        
    end    
--=-=-=-=-=-=-=-
    if (e.target.id:lower() == "tw_lightswitch_06") then  -- hall light switch.
        
       -- Toggle the light switch.
        if getSwitch7(e.target) ~= true then
           setSwitch7(e.target, true)
        else
           setSwitch7(e.target, false)
        end    
        
        --local ref = tes3.getReference(e.target.id)
        if getSwitch7(e.target) == true then     
           turnLightsOn7() --e.target, ref, e)    
        else
          turnLightsOff7(true)
        end        
    end   
--=-=-=-=-=-=-=-
    if (e.target.id:lower() == "tw_lightswitch_07") then  -- hall light switch.
        
       -- Toggle the light switch.
        if getSwitch8(e.target) ~= true then
           setSwitch8(e.target, true)
        else
           setSwitch8(e.target, false)
        end    
        
        --local ref = tes3.getReference(e.target.id)
        if getSwitch8(e.target) == true then     
           turnLightsOn8() --e.target, ref, e)    
        else
          turnLightsOff8(true)
        end        
    end  
--=-=-=-=-=-=-=-
    if (e.target.id:lower() == "tw_lightswitch_08") then  -- hall light switch.
        
       -- Toggle the light switch.
        if getSwitch9(e.target) ~= true then
           setSwitch9(e.target, true)
        else
           setSwitch9(e.target, false)
        end    
        
        --local ref = tes3.getReference(e.target.id)
        if getSwitch9(e.target) == true then     
           turnLightsOn9() --e.target, ref, e)    
        else
          turnLightsOff9(true)
        end        
    end      
--=-=-=-=-=-=-=-
    if (e.target.id:lower() == "tw_lightswitch_09") then  -- hall light switch.
        
       -- Toggle the light switch.
        if getSwitch10(e.target) ~= true then
           setSwitch10(e.target, true)
        else
           setSwitch10(e.target, false)
        end    
        
        --local ref = tes3.getReference(e.target.id)
        if getSwitch10(e.target) == true then     
           turnLightsOn10() --e.target, ref, e)    
        else
          turnLightsOff10(true)
        end        
    end      
 --=-=-=-=-=-=-=-
    if (e.target.id:lower() == "tw_lightswitch_10") then  -- hall light switch.
        
       -- Toggle the light switch.
        if getSwitch11(e.target) ~= true then
           setSwitch11(e.target, true)
        else
           setSwitch11(e.target, false)
        end    
        
        --local ref = tes3.getReference(e.target.id)
        if getSwitch11(e.target) == true then     
           turnLightsOn11() --e.target, ref, e)    
        else
          turnLightsOff11(true)
        end        
    end  
--=-=-=-=-=-=-=-
    if (e.target.id:lower() == "tw_lightswitch_11") then  -- hall light switch.
        
       -- Toggle the light switch.
        if getSwitch12(e.target) ~= true then
           setSwitch12(e.target, true)
        else
           setSwitch12(e.target, false)
        end    
        
        --local ref = tes3.getReference(e.target.id)
        if getSwitch12(e.target) == true then     
           turnLightsOn12() --e.target, ref, e)    
        else
          turnLightsOff12(true)
        end        
    end      
--=-=-=-=-=-=-=-
    if (e.target.id:lower() == "tw_lightswitch_12") then  -- hall light switch.
        
       -- Toggle the light switch.
        if getSwitch13(e.target) ~= true then
           setSwitch13(e.target, true)
        else
           setSwitch13(e.target, false)
        end    
        
        --local ref = tes3.getReference(e.target.id)
        if getSwitch13(e.target) == true then     
           turnLightsOn13() --e.target, ref, e)    
        else
          turnLightsOff13(true)
        end        
    end
end   

----------------------------------------------------------------------------------------------------
--[[local function  DoDressManneqin(e)
-- if here we have a dress mannequin...

--  if AllowActivate then
--     AllowActivate = false
--  else
      -- This is not genaric and would need further work to make it so.
      messageBox{
            message = "What do you want to do?",
            buttons = {{ text = "Swap",   callback = function() swapDress(e)    end },
                       { text = "Open",   callback = function() AllowActivate = true; tes3.player:activate(e.target) end }, 
                       { text = "Cancel", callback = function() return false    end }}              
                }
      
      return false
--  end       
end
--]]
----------------------------------------------------------------------------------------------------
--[[local function doOpenSafe()
  
      messageBox{
            message = "What do you want to do?",
            buttons = {{ text = "Auto",   callback = function() StoreTreasure() end },
                       { text = "Open",   callback = function() OpenTreasure()  end }, 
                       { text = "Cancel", callback = function() return          end }}             
                  }
end
--]]
----------------------------------------------------------------------------------------------------
local function onActivateMuseum(e)
  
    if not (e.activator == tes3.player) then -- Just in case.
          return
    end
    
    if (string.sub(e.target.id:lower(), 1, 10) == "tw_plaque_") then  -- grab all the plaques first.
    
       getDisplayText(e)
       return false
       
    end   
    
    --if ( e.target.id:lower() == "tw_san_mirror_act" ) then
    -- NOT YET possible 
      -- save player stats
      -- call racemenu
      --mwscript.EnableRaceMenu({reference = tes3.player})
      -- restore player stats
    --end
  
--[[    if (e.target.baseObject.id:lower() == "tw_dress_mannequin_f01") or
       (e.target.baseObject.id:lower() == "tw_dress_mannequin_m01") or
       (e.target.baseObject.id:lower() == "tw_dress_mannequin_f02") or
       (e.target.baseObject.id:lower() == "tw_dress_mannequin_m02") then      
--]]       
    if (string.sub(e.target.id:lower(), 1, 10) == "tw_dress_m") then  -- grab all the dress mannequins.   this makes it a bit more generic. 
      
--       DoDressManneqin(e)
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

    if (e.target.id == "tw_safe_01_pd") then
      
--      doOpenSafe()
      messageBox{
            message = "What do you want to do?",
            buttons = {{ text = "Auto",   callback = function() StoreTreasure() end },
                       { text = "Open",   callback = function() OpenTreasure()  end }, 
                       { text = "Cancel", callback = function() return          end }}             
                  }

      return false
      
    end
    
    if (string.sub(e.target.id:lower(), 1, 10) == "tw_lightsw") then  -- grab all the light switchs.
        switchLights(e)
    end
    
---- Can I change these ?????????????    
    if (e.target.id:lower() == "tw_firelighter_01") then  -- Library fire switch. Box of matches
      
       -- Toggle the light switch.
        if getSwitch3(e.target) ~= true then
           setSwitch3(e.target, true)
        else
           setSwitch3(e.target, false)
        end    
        
        --local ref = tes3.getReference(e.target.id)      
        if getSwitch3(e.target) == true then     
           turnLightsOn3() --e.target, ref, e)    
        else
          turnLightsOff3(true)
        end
    end 
--=-=-=-=-=-=-=-   
    if (e.target.id:lower() == "tw_waterfall_switch") then 
        -- Toggle the waterfall switch.
        if getWaterFall(e.target) ~= true then
           setWaterFall(e.target, true)
        else
           setWaterFall(e.target, false)
        end          
        if getWaterFall(e.target) == true then     
           turnWaterFallOn()    
        else
           turnWaterFallOff()
        end
    end
--=-=-=-=-=-=-=-
    if (e.target.id:lower() == "tw_window_clear_act") then   -- open/close
      local lOpen
      
      if lOpen then
         lOpen = false
         timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_window_clear_act")) end)
         --local refW = tes3.getReference("tw_window_clear_act")
         tes3.playAnimation({reference = target, group = tes3.animationGroup.idle2, loopCount = 0})     
        
      else
         lOpen = true
         timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_window_clear_act")) end)
         --local refW = tes3.getReference("tw_window_clear_act")
         tes3.playAnimation({reference = target, group = tes3.animationGroup.idle3, loopCount = 0})     
      
      end  
    end

end
event.register("activate", onActivateMuseum)

----------------------------------------------------------------------------------------------------
local function bookGetTextPamphlet(e)  
  
  if (e.book.type == tes3.bookType.scroll) and 
     (e.book.id:lower() == "tw_museum_pamphlet") then  

    local hasSpell = tes3.hasSpell({ reference = tes3.player, spell = "tw_museum_teleport" })
    if hasSpell ~= true then
       mwscript.addSpell({reference = tes3.player, spell = "tw_museum_teleport"})
    end      
    
    local eText = dofile("tw.tw_pocketDisplay.pamphlet")
    e.text = eText
  
  end    
    
end
event.register("bookGetText", bookGetTextPamphlet)

----------------------------------------------------------------------------------------------------
local function onCellChangMuseum(e)

    local cell = tes3.getPlayerCell()
    
  if cell.id == "tw_Pocket Museum" then 
    --if getDoOnce3(e.reference) ~= true then
    --   setDoOnce3(e.reference, true)
    if  (doOnce3 ~= true ) then
      doOnce3 = true
      -- turn everything off when they first arrive.
      turnLightsOff1(false)
      turnWaterFallOff()
      tes3.removeSound({ sound = "Cave_Waterfall" })
      turnLightsOff2(false)
      turnLightsOff3(false)
      turnLightsOff4(false)    
      local ref = tes3.getReference("tw_portcullis_01")
      tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle})
      turnLightsOff5(false) 
      turnLightsOff6(false)
      turnLightsOff7(false)
      turnLightsOff8(false)
      turnLightsOff9(false)
      turnLightsOff10(false)
      turnLightsOff11(false)
      turnLightsOff12(false)    
      turnLightsOff13(false)       
      OnCloseChest() -- this is controlled via the safe's from here on.

    else  -- switch off every time
      -- turn waterfall off
      turnWaterFallOff()
      setWaterFall(e.target, false)
      tes3.removeSound({ sound = "Cave_Waterfall" })
      
      -- close the shutters.
      local ref = tes3.getReference("tw_window_clear_act")
      tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle})   
      
      -- turn fire off.
      turnLightsOff3(false)
      setSwitch3(e.target, false)
      
      -- close portcullis and turn off the lights.
      turnLightsOff4(false)  
      setSwitch4(e.target, false)
      local ref = tes3.getReference("tw_portcullis_01")
      tes3.playAnimation({reference = ref, group = tes3.animationGroup.idle})
      
      -- turn lights off Dwemer lights
      turnLightsOff5(false)   
      setSwitch5(e.target, false)

      -- turn lights off on side displays
      turnLightsOff6(false)
      turnLightsOff9(false)
      turnLightsOff10(false)
      turnLightsOff11(false)
      setSwitch6(e.target, false)
      setSwitch9(e.target, false)
      setSwitch10(e.target, false)
      setSwitch11(e.target, false)

      -- turn of light in store room
      turnLightsOff8(false)
      setSwitch8(e.target, false)

      -- leave all other lights as they left them
      
    end  
  end    
end
event.register("cellChanged", onCellChangMuseum)

-------------------------------------------------------------------------
local function GetSetWorld()
-- most players will probably never even notice this is going on.
local aWorlds = {
  {id = 1 , name = "tw_os_sky_01"},
  {id = 2 , name = "tw_os_sky_02"},
  {id = 3 , name = "tw_os_sky_03"},
  {id = 4 , name = "tw_os_sky_04"},
  {id = 5 , name = "tw_os_sky_05"},
  {id = 6 , name = "tw_os_sky_06"},
  {id = 7 , name = "tw_os_sky_07"},
  {id = 8 , name = "tw_os_sky_08"},
  {id = 9 , name = "tw_os_sky_09"},
  {id = 10, name = "tw_os_sky_10"},
  }

local ref 
local roll = (math.random(1, 3))  

  if (roll == 3) then -- 1 in 3 chance to change location
      roll = (math.random(1, 10))  -- make the choice random.
      for _, glob in pairs(aWorlds) do     
         ref = tes3.getReference(glob.name)     
         if ( glob.id == roll ) then
            tes3.setEnabled({ reference = ref, enabled = true }) 
         else
            tes3.setEnabled({ reference = ref, enabled = false }) 
         end
      end
  else
    -- don't change anything.  
  end

end

-------------------------------------------------------------------------
local function onLoadMuseum(e)

--Check to see if they already have the teleportation spell
  if getDoOnce2(e.reference) ~= true then
    setDoOnce2(e.reference, true)
    mwscript.addItem({ reference = tes3.player, item = "tw_museum_pamphlet", count = 1 })
    tes3.messageBox("You have been given a Museum pamphlet, you should read it." )
  end

end
event.register("loaded", onLoadMuseum)

---------------------------------------------------------------
local function setMark()
   
    local eRef = tes3.getReference("tw_mannequin_controller")
    -- save current location when spell cast to return to 
    local refData = eRef.data -- Crossing the C-Lua border result is usually not a bad idea.                   
    local p = tes3.player.position
    local r = tes3.player.orientation
    refData.museum = { 
        cell = tes3.player.cell.id,
        pos  = {p.x, p.y, p.z},
        rot  = {r.x, r.y, r.z},
    }                      
                                       
end

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
local function spellCastMuseum(e)
  
 if ( e.source.id == "tw_museum_teleport") then 
    tes3.playSound{ reference = tes3.player, sound = "mysticism hit"}   
       
    local eRef = tes3.getReference("tw_mannequin_controller")
    local cell = tes3.getPlayerCell()
    if cell.id == "tw_Pocket Museum" then
    -- to send them back from wence they came....    
      local lcell = eRef.data.museum.cell
      local lpos  = eRef.data.museum.pos
      local lrot  = eRef.data.museum.rot
      
      tes3.removeSound({ sound = "Cave_Waterfall" })  -- needed otherwise waterfall sound will follow player everywhere :D
      
      -- Send them back
       tes3.positionCell({ reference = tes3.player, 
                           cell = lcell, 
                           position = lpos, 
                           orientation = lrot, 
                           forceCellChange = false, 
                           suppressFader = false, 
                           teleportCompanions = false })      
    
    else    
    -- send them to the display hall and register where they are coming from      
       GetSetWorld() -- randomly set the globe
       setMark()
       tes3.positionCell({ reference = tes3.player, 
                           cell = "tw_pocket museum", 
                           position = { 24, 8, 12 }, 
                           orientation = {0,0,0}, 
                           forceCellChange = false, 
                           suppressFader = false, 
                           teleportCompanions = false })
       
    end
 end
end

local function onInitialized(e)
    event.register("spellCast", spellCastMuseum, { filter = tes3.getObject("tw_museum_teleport") })
end
event.register(tes3.event.initialized, onInitialized)





