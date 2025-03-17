local ui = require('openmw.ui')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local types = require('openmw.types')
local time = require('openmw_aux.time')

--local function onKeyPress(key)
--           if key.symbol == 'c' then  -- would run on keypress, need two ends
 
--local function onUpdate(dt)    -- would run on every frame, needs one end

local stopFn = time.runRepeatedly(function() -- runs the function every 1 second, defined at bottom
             local acts = nearby.actors 
              for i, a in pairs(acts) do
                local dist = (self.position - acts[i].position):length() -- the distance to actor
                
                if dist < 100 and dist > 10 then  -- the max distance and over 0 to prevent player
                  
                  if self.controls.sneak == true then -- if sneaking
                          
                    
                    local miss = { 
                "skeleton",
                "scrib",
        "skeleton champion",
        "skeleton entrance",
        "skeleton archer",
        "T_Mw_Und_SkelArc_01",
        "skeleton warrior",
        "TR_m4_dead1_i4-260-hla",
        "skeleton hero dead",
        "skeleton_weak",
        "TR_m4_Cr_AA_SehutuSke02",  
        "BM_wolf_skeleton",
        "skeleton nord ",
        "TR_m3_skeleton_plague",
        "dead_skeleton",
        "skeleton nord_2",  
        "T_Glb_Und_SkelCmpPl_01", 
        "T_Glb_Und_SkelCmpGr_01",
        "T_Glb_Und_SkelOrc_02",
        "T_Glb_Und_SkelPl_01",
        "T_Glb_Und_SkelArise_02",
        "skeleton_relvel",
        "worm lord",
        "skeleton_Vemynal",
        "slaughterfish",
        "Slaughterfish_Small",
        "ancestor_ghost_greater",
        "scamp",
        "lich_barilzar",
        "clannfear",
        "atronach_flame",
        "atronach_storm",
        "atronach_frost",
        "daedroth",
        "winged twilight",
        "BM_draugr01",
        "centurion_steam",
        "centurion_spider", 
        "centurion_spider_dead",
        "centurion_sphere",
        "centurion_steam_advance",
        "T_Mw_Und_Mum_Rise_02",
        "T_Dwe_Cre_CentArc_01",
        "T_Mw_Und_Mum_01",
        "hunger",
        "ogrim",
        "ancestor_ghost",
        "golden saint",
        "dwarven ghost",
        "fabricant_verminous",
        "bonelord",
        "dremora",
        "lich",
        "Bonewalker_Greater",
        "T_Dwe_Und_GhstGr_01",
        "dremora_lord",
        "T_Dae_Cre_Drid_01",
        "T_Dae_Cre_LesserClfr_01",  
        "bonewalker",
        "corprus_stalker",
        "ascended_sleeper",
        "bonewalker_weak"
                        }
                        
                        
                    for c, v in pairs(miss) do -- ensures all nearby actors are taken into account, ie. no duplicates                    
                      if acts[i].recordId == miss[c] then
                                              
                        return
                                                                        
                      end
                    end
                  
                  
                    local spe = types.Player.spells(self)
                     for c, v in pairs(spe) do
                      if spe[c].name == "telekinesis" then  -- if vampire
                        
                        if types.Actor.stats.dynamic.health(acts[i]).current <= 0 then -- if actor is dead
                           
                          types.Actor.spells(self):add("Bloodthirst_Drink_Option") -- given spell
                          
                        end
                      end
                    end
                  end
                end
              end

           end,
     1 * time.second)  -- time interval
                  
   --end             
--end


--return { engineHandlers = { onUpdate = onUpdate } }
--return { engineHandlers = { onKeyPress = onKeyPress } }