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
        "t_mw_und_skelarc_01",
        "skeleton warrior",
        "tr_m4_dead1_i4-260-hla",
        "skeleton hero dead",
        "skeleton_weak",
        "tr_m4_cr_aa_sehutuske02",  
        "bm_wolf_skeleton",
        "skeleton nord ",
        "tr_m3_skeleton_plague",
        "dead_skeleton",
        "skeleton nord_2",  
        "t_glb_und_skelcmppl_01", 
        "t_glb_und_skelcmpgr_01",
        "t_glb_und_skelorc_02",
        "t_glb_und_skelpl_01",
        "t_glb_und_skelarise_02",
        "skeleton_relvel",
        "worm lord",
        "skeleton_vemynal",
        "slaughterfish",
        "slaughterfish_small",
        "ancestor_ghost_greater",
        "scamp",
        "lich_barilzar",
        "clannfear",
        "atronach_flame",
        "atronach_storm",
        "atronach_frost",
        "daedroth",
        "winged twilight",
        "bm_draugr01",
        "centurion_steam",
        "centurion_spider", 
        "centurion_spider_dead",
        "centurion_sphere",
        "centurion_steam_advance",
        "t_mw_und_mum_rise_02",
        "t_dwe_cre_centarc_01",
        "t_mw_und_mum_01",
        "hunger",
        "ogrim",
        "ancestor_ghost",
        "golden saint",
        "dwarven ghost",
        "fabricant_verminous",
        "bonelord",
        "dremora",
        "lich",
        "bonewalker_greater",
        "t_dwe_und_ghstgr_01",
        "dremora_lord",
        "t_dae_cre_drid_01",
        "t_dae_cre_lesserclfr_01",  
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
                      if not types.Actor.activeEffects(self):getEffect("vampirism") or types.Actor.activeEffects(self):getEffect("vampirism").magnitude == 0 then  -- if not vampire
                        
                        if types.Actor.stats.dynamic.health(acts[i]).current <= 0 then -- if actor is dead
                           
                          types.Actor.spells(self):add("eat_corpse_option") -- given spell
                          
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