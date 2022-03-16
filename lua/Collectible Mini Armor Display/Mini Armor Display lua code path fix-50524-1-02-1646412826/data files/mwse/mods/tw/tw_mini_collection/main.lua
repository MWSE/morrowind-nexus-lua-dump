-- Display Mini Armour Collector Figurines.
local messageBox = require("tw.tw_mini_collection.MessageBox")
--local messageBox = require("tw.MessageBox")

-- Display offsets for mini's from base display shelf. 
-- Skill = Output text
-- attr  = actual skill name for increase
-- done  = doOnce flag
-- mini  = Carriable mini name.
--
local MiniDisplays = {
      ------------------------
    {id = "tw_mini_01", offset = {-36, 20, 168}, angle = 180, skill = "Light Armor" , attr = "lightArmor",   done = 0, mini = "tw_mini_netch_misc"   },-- skill 21
    {id = "tw_mini_02", offset = {-18, 20, 168}, angle = 180, skill = "Hand-to-Hand", attr = "handToHand",   done = 0, mini = "tw_mini_chitin_misc"  },-- skill 26
    {id = "tw_mini_03", offset = {0, 20, 168},   angle = 180, skill = "Speechcraft" , attr = "speechcraft",  done = 0, mini = "tw_mini_ice_misc"     },-- skill 25
    {id = "tw_mini_04", offset = {18, 20, 168},  angle = 180, skill = "Sneak"       , attr = "sneak",        done = 0, mini = "tw_mini_dbhood_misc"  },-- skill 19
    {id = "tw_mini_05", offset = {36, 20, 168},  angle = 180, skill = "Security"    , attr = "security",     done = 0, mini = "tw_mini_glass_misc"   },-- skill 18
    -------------------------------                                                 "                                                                  
    {id = "tw_mini_06", offset = {-36, 20, 134}, angle = 180, skill = "Athletics"   , attr = "athletics",    done = 0, mini = "tw_mini_bear_misc"    },-- skill 8
    {id = "tw_mini_07", offset = {-18, 19, 134}, angle = 180, skill = "Destruction" , attr = "destruction",  done = 0, mini = "tw_mini_bear2_misc"   },-- skill 10
    {id = "tw_mini_08", offset = {1, 19, 134},   angle = 180, skill = "Acrobatics"  , attr = "acrobatics",   done = 0, mini = "tw_mini_wolf_misc"    },-- skill 20 
    {id = "tw_mini_09", offset = {18, 20, 134},  angle = 180, skill = "Mysticism",    attr = "mysticism",    done = 0, mini = "tw_mini_wolf2_misc"   },-- skill 14
    {id = "tw_mini_10", offset = {36, 20, 134},  angle = 180, skill = "Axe"         , attr = "axe",          done = 0, mini = "tw_mini_nordic_misc"  },-- skill 6
    ------------------------                                                       "                                                                   
    {id = "tw_mini_11", offset = {-36, 20, 99},  angle = 180, skill = "Spear"       , attr = "spear",        done = 0, mini = "tw_mini_chain_misc"   },-- skill 7
    {id = "tw_mini_12", offset = {-18, 20, 99},  angle = 180, skill = "Long Blade"  , attr = "longBlade",    done = 0, mini = "tw_mini_imper_misc"   },-- skill 5
    {id = "tw_mini_13", offset = {0, 20, 99},    angle = 180, skill = "Enchant"     , attr = "enchant",      done = 0, mini = "tw_mini_indor_misc"   },-- skill 9
    {id = "tw_mini_14", offset = {18, 20, 99},   angle = 180, skill = "Medium Armor", attr = "mediumArmor",  done = 0, mini = "tw_mini_orcish_misc"  },-- skill 2
    {id = "tw_mini_15", offset = {36, 20, 99},   angle = 180, skill = "Short Blade" , attr = "shortBlade",   done = 0, mini = "tw_mini_bonem_misc"   },-- skill 22
    ------------------------                                                        "                                                                  
    {id = "tw_mini_16", offset = {-36, 20, 66},  angle = 180, skill = "Marksman"    , attr = "marksman",     done = 0, mini = "tw_mini_dragon_misc"  },-- skill 23
    {id = "tw_mini_17", offset = {-18, 20, 66},  angle = 180, skill = "Armourer"    , attr = "armorer",      done = 0, mini = "tw_mini_steel_misc"   },-- skill 1
    {id = "tw_mini_18", offset = {0, 20, 66},    angle = 180, skill = "Alchemy"     , attr = "alchemy",      done = 0, mini = "tw_mini_almind_misc"  },-- skill 16
    {id = "tw_mini_19", offset = {18, 20, 66},   angle = 180, skill = "Alteration"  , attr = "alteration",   done = 0, mini = "tw_mini_templ_misc"   },-- skill 11
    {id = "tw_mini_20", offset = {36, 20, 66},   angle = 180, skill = "Blunt Weapon", attr = "bluntWeapon",  done = 0, mini = "tw_mini_iron_misc"    },-- skill 4
    ------------------------                                                        "                                                                  
    {id = "tw_mini_21", offset = {-36, -9, 66},  angle = 180, skill = "Mercantile"  , attr = "mercantile",   done = 0, mini = "tw_mini_adaman_misc"  },-- skill 24
    {id = "tw_mini_22", offset = {-18, 0, 66},   angle = 180, skill = "Block"       , attr = "block",        done = 0, mini = "tw_mini_dwemer_misc"  },-- skill 0
    {id = "tw_mini_23", offset = {1, 3, 66},     angle = 180, skill = "Unarmored"   , attr = "unarmored",    done = 0, mini = "tw_mini_daedrc_misc"  },-- skill 17
    {id = "tw_mini_24", offset = {18, -3, 66},   angle = 180, skill = "Heavy Armor" , attr = "heavyArmor",   done = 0, mini = "tw_mini_ebony_misc"   },-- skill 3
    {id = "tw_mini_25", offset = {36, -9, 66},   angle = 180, skill = "Illusion"    , attr = "illusion",     done = 0, mini = "tw_mini_royal_misc"   },-- skill 12
    ------------------------
}


local function setDoOnce(ref,Var)
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.tw_mini_collection = refData.tw_mini_collection or {} -- Force initializing the parent table.
    refData.tw_mini_collection.doOnce = Var -- Actually set your value.
end

local function getDoOnce(ref)
    local refData = ref.data
    return refData.tw_mini_collection and refData.tw_mini_collection.doOnce
end

--Place a container -500 below the feet of a merchant and assign ownership.
--This is how we add stock to merchants without editing the cell in the CS.
local function placeContainer(merchant)
    local position = merchant.position:copy()
    position = {
        position.x,
        position.y,
        position.z + -500 ,
        }
    local container = tes3.createReference{
        object = "tw_mini_merchant_chest",
        position = position,
        orientation = merchant.orientation:copy(),
        cell = merchant.cell
    }
    tes3.setOwner{ reference = container, owner = merchant}

end

local function onMobileActivatedChest(e) 
  
  local obj = e.reference.baseObject or e.reference.object
  if ( obj.id:lower() == "alveno andules" ) then  -- only if it's mine  ?!?!?
    if getDoOnce(e.reference) ~= true then
      setDoOnce(e.reference, true)
      
--      local obj = e.reference.baseObject or e.reference.object
--      if obj.id:lower() == "alveno andules" then
         placeContainer(e.reference)
--      end
    end
  end
end
event.register("mobileActivated", onMobileActivatedChest)

local function onDisplaySet(cell, position, rotation)
    -- create loop for all mini's
    -- Get the original misc display and create the activator replacement
    local miscRef = tes3.createReference{
          object = "tw_displaycase_act",
          position = position,
          cell = cell
          }
  	miscRef.orientation = rotation
  
    -- Create the 25 mini displays in relation to display shelves.
    for i, display in pairs(MiniDisplays) do
        local offset = tes3vector3.new(unpack(display.offset))
        local ref = tes3.createReference {
              object = display.id,
              position = position + (rotation * offset),
              orientation = miscRef.orientation,
              cell = cell
              }
      ref.orientation = {
          ref.orientation.x,
          ref.orientation.y,
          ref.orientation.z   -- + math.rad(180)
        }
    end
    
    -- remove misc display from player inventory.
    mwscript.removeItem{ reference = tes3.player, item = "tw_mini_displaycase_misc", count = 1 }

end

----------------------------------------------------------------------------------------------------
local function onActivateMinis(e)
    if not (e.activator == tes3.player) then
        return
    end
        
    if (e.target.id == "tw_mini_displaycase_misc") then
        -- save information about the reference before its gets deleted
    	  local cell = e.target.cell
        local position = e.target.position:copy()
        local rotation = e.target.sceneNode.rotation:copy()
        
        messageBox {
            message = "What do you want to do?",
            buttons = {
                {
                    text = "set",
                    callback = function()
                        onDisplaySet(cell, position, rotation)
                    end
                },
                {
                    text = "Cancel",
                    callback = function()
                        return
                    end
                }
            }
        }
                
    elseif (e.target.id == "tw_displaycase_act") then
          -- Open remote safe store.
          timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_mini_displaycase")) end)
          mwscript.addItem{ reference = tes3.getReference("tw_mini_displaycase"), item = "common_ring_05", count = 1 }
          mwscript.removeItem{ reference = tes3.getReference("tw_mini_displaycase"), item = "common_ring_05", count = 1 }
        
          return false
      
    end
end
event.register("activate", onActivateMinis)

local function onEquipMinis(e)
  
  local mob = tes3.mobilePlayer
  
  for i, display in pairs(MiniDisplays) do      
     if (e.item.id:lower() == display.mini ) then
        if (display.done == 0) then
          display.done = 1
          
          local skill = display.attr
           
          tes3.messageBox("This is a special item and has increased your '%s' skill by 5", display.skill) -- shows correctly

          for i = 1, 5 do
            mob:progressSkillToNextLevel(tes3.skill[skill])
          end
        end        
      end
  end
end
event.register("equip", onEquipMinis)



--[[
-------------------------------------------------------------------------
local function onLoadMinis()
    --add topics
    mwscript.addTopic{ topic = "Mini Armor Display."}
    --mwscript.addTopic{ topic = "teach me a song"}
    --event.trigger("BardicInspiration:DataLoaded")
end
event.register("loaded", onLoadMinis)

-------------------------------------------------------------------------
else
    --Bard has a song matching the player's level, not advanced
    message = messages.dialog_teachChoice
    e.text = string.format(message, difficultyMsg, songToLearn.name)
end
            
-------------------------------------------------------------------------            
--]]