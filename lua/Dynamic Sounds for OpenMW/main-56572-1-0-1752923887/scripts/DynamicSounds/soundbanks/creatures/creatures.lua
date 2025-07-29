--animGroupNames:
-- "walkforward", "walkback", "walkleft", "walkright", "swimwalkforward", "swimwalkback",
-- "swimwalkleft", "swimwalkright", "runforward", "runback", "runleft", "runright", "swimrunforward",
-- "swimrunback", "swimrunleft", "swimrunright", "sneakforward", "sneakback", "sneakleft", "sneakright",
-- "turnleft", "turnright", "swimturnleft", "swimturnright", "spellturnleft", "spellturnright", "torch",
-- "idle", "idle2", "idle3", "idle4", "idle5", "idle6", "idle7", "idle8", "idle9", "idlesneak", "idlestorm",
-- "idleswim", "jump", "inventoryhandtohand", "inventoryweapononehand", "inventoryweapontwohand",
-- "inventoryweapontwowide", "attack1", "death1", ...


local creaturesSoundBank = {
    
    -- ==================================================================================
    -- Base Game
    -- ==================================================================================    
    
    {
        creatureId = "ttooth_beetle",
        --removeSounds = "shalk moan",
        sounds = {
            {
                animGroupName = "walkforward",
                animSound = "sounds\\DynamicSounds\\creatures\\shalk_walk_lp.wav",
                loopSound = true,
                volume = 0.8,
                timeOffset = 0,
                replaceOriginalSound = "",   
            },
        },
    },

    {
        creatureId = "durzog",
        aware = {
            sound = "sounds\\DynamicSounds\\creatures\\durzog_aware.wav",
            volume = 1,
            timeOffset = 0,           
        }, 
        sounds = {                                 
            {
                animGroupName = "walkforward",
                animSound = "sounds\\DynamicSounds\\creatures\\durzog_walk_left.wav",
                loopSound = false,
                volume = 0.4,
                timeOffset = 0,
                replaceOriginalSound = "sludgeworm left",
            },
            {
                animGroupName = "walkforward",
                animSound = "sounds\\DynamicSounds\\creatures\\durzog_walk_right.wav",
                loopSound = false,
                volume = 0.4,
                timeOffset = 0,
                replaceOriginalSound = "sludgeworm right",
            },              
            {
                animGroupName = "runforward",
                animSound = "sounds\\DynamicSounds\\creatures\\durzog_run_left.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "sludgeworm left",
            },
            {
                animGroupName = "runforward",
                animSound = "sounds\\DynamicSounds\\creatures\\durzog_run_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "sludgeworm right",
            },
            {
                animGroupName = "attack1",
                animSound = "sounds\\DynamicSounds\\creatures\\durzog_attack1_swish.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "swishm",
            },             
            {
                animGroupName = "attack2",
                animSound = "sounds\\DynamicSounds\\creatures\\durzog_attack2_swish.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "swishm",
            },              
            {
                animGroupName = "attack3",
                animSound = "sounds\\DynamicSounds\\creatures\\durzog_attack3_swish.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "swishm",
            },               
            {
                animGroupName = "attack3",
                animSound = "sounds\\DynamicSounds\\creatures\\durzog_attack_roar.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "sludgeworm roar",
            },                        
        },
    },

    {
        creatureId = "kagouti",
        sounds = {  
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\kagouti_breathing_lp.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0,
                exceptAnimGroups="attack1,attack2,attack3,runforward,death1,death2,deathknockdown,deathknockout",
            },                                            
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\kagouti_walk_left.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "animallargeleft",
            },
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\kagouti_walk_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "animallargeright",
            },              
           
         
        },
    },    

    {
        creatureId = "daedroth",
        aware = {
            sound = "sounds\\DynamicSounds\\creatures\\daedroth_aware.wav",
            volume = 1,
            timeOffset = 0,           
        }, 
        sounds = {      
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\daedroth_breathing.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0,
                exceptAnimGroups="attack1,attack2,attack3,runforward,death1,deathknockdown,deathknockout",
            },                                          
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\daedroth_walk_left.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareleft",
            },
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\daedroth_walk_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareright",
            },  
            -- {
            --     animGroupName = "runforward",
            --     animSound = "sounds\\DynamicSounds\\creatures\\silent.wav",
            --     loopSound = false,
            --     volume = 1,
            --     timeOffset = 0,
            --     replaceOriginalSound = "daedroth roar",
            -- },                        
                                   
        },
    },

    {
        creatureId = "_boar",
        aware = {
            sound = "sounds\\DynamicSounds\\creatures\\boar_aware.wav",
            volume = 1,
            timeOffset = 0,           
        },        
        sounds = {
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\boar_walk_left.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareleft",
            },       
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\boar_walk_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareright",
            },                                           
            {
                animGroupName = "attack1",
                animSound = "sounds\\DynamicSounds\\creatures\\boar_attack1.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "boar roar",
            },  
            {
                animGroupName = "attack2",
                animSound = "sounds\\DynamicSounds\\creatures\\boar_attack2.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "boar roar",
            },          
            {
                animGroupName = "attack3",
                animSound = "sounds\\DynamicSounds\\creatures\\boar_attack3.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "boar roar",
            },   
                                                                                  
        },
    },
    
    -- {
    --     creatureId = "kwama forager",
    --     sounds = {
    --         {
    --             animGroupName = "walkforward",
    --             animSound = "sounds\\DynamicSounds\\creatures\\kwama_forager_walk_lp.wav",
    --             loopSound = true,
    --             volume = 0.4,
    --             timeOffset = 0,
    --             replaceOriginalSound = "", 
    --         },            
    --         {
    --             animGroupName = "runforward",
    --             animSound = "sounds\\DynamicSounds\\creatures\\kwama_forager_run_lp.wav",
    --             loopSound = true,
    --             volume = 1,
    --             timeOffset = 0,
    --             replaceOriginalSound = "",
    --         },
    --     },
    -- },    

    -- {
    --     creatureId = "ancestor_ghost",
    --     sounds = {
    --         {
    --             animGroupName = "walkforward",
    --             animSound = "sounds\\DynamicSounds\\creatures\\ancestor_ghost_walk.wav",
    --             loopSound = false,
    --             volume = 1,
    --             timeOffset = 0,
    --             replaceOriginalSound = "ancestor ghost roar", 
    --         },            
    --     },
    -- }, 

    {
        creatureId = "corprus_lame",
        sounds = {
            {
                animGroupName = "walkforward",
                animSound = "sounds\\DynamicSounds\\creatures\\corprus_lame_walk_foot_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareright", 
            },            
        },
    },
     

    {
        creatureId = "nix%-hound",
        sounds = {
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\nix_walk_right.wav",
                loopSound = false,
                volume = 0.5,
                timeOffset = 0,
                replaceOriginalSound = "footbareright", 
            },
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\nix_walk_left.wav",
                loopSound = false,
                volume = 0.5,
                timeOffset = 0,
                replaceOriginalSound = "footbareleft",
            },
        },
    }, 

    -- {
    --     creatureId = "clannfear",
    --     sounds = {
    --         {
    --             animGroupName = "walkforward",
    --             animSound = "sounds\\DynamicSounds\\creatures\\clannfear_walk_lp.wav",
    --             loopSound = true,
    --             volume = 0.3,
    --             timeOffset = 0.5,
    --             replaceOriginalSound = "", 
    --         },
    --         {
    --             animGroupName = "runforward",
    --             animSound = "sounds\\DynamicSounds\\creatures\\clannfear_run_lp.wav",
    --             loopSound = true,
    --             volume = 2,
    --             timeOffset = 0.5,
    --             replaceOriginalSound = "",
    --         },
    --         {
    --             animGroupName = "idle",
    --             animSound = "sounds\\DynamicSounds\\creatures\\clannfear_idle1.wav",
    --             loopSound = true,
    --             volume = 1,
    --             timeOffset = 0,
    --             replaceOriginalSound = "",
    --         }, 
    --         {
    --             animGroupName = "idle2",
    --             animSound = "sounds\\DynamicSounds\\creatures\\clannfear_idle2.wav",
    --             loopSound = true,
    --             volume = 1,
    --             timeOffset = 0,
    --             replaceOriginalSound = "",
    --         },  
                                               
    --     },
    -- },      
    
    {
        creatureId = "cliff racer",
        sounds = {
            -- {
            --     animGroupName = "*",
            --     animSound = "sounds\\DynamicSounds\\creatures\\cliffracer_wing_right.wav",
            --     loopSound = false,
            --     volume = 1,
            --     timeOffset = 0,
            --     replaceOriginalSound = "footbareright", 
            -- },
            -- {
            --     animGroupName = "*",
            --     animSound = "sounds\\DynamicSounds\\creatures\\cliffracer_wing_left.wav",
            --     loopSound = false,
            --     volume = 1,
            --     timeOffset = 0,
            --     replaceOriginalSound = "footbareleft", 
            -- }, 
            {
                animGroupName = "idle",
                animSound = "sounds\\DynamicSounds\\creatures\\cliffracer_idle_lp.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0.5,
            },
            {
                animGroupName = "idle2",
                animSound = "sounds\\DynamicSounds\\creatures\\cliffracer_idle_lp.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0.5,
            },                                                                    
           
        },
    }, 
    
    {
        creatureId = "rat",
        sounds = {
            {
                animGroupName = "idle",
                animSound = "sounds\\DynamicSounds\\creatures\\rat_iddle_lp.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "", 
            },                       
        },
    },  

    {
        creatureId = "bear",
        aware = {
            sound = "sounds\\DynamicSounds\\creatures\\bear_aware.wav",
            volume = 1,
            timeOffset = 0,           
        },
        sounds = {                         
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\bear_breathing_lp.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0,
                exceptAnimGroups="idle,idle2,idle3,walkforward,death1,death2,death3,deathknockdown,deathknockout",
            },            
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\bear_walk_left.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareleft",
            },       
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\bear_walk_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareright",
            },
            {
                animGroupName = "attack1",
                animSound = "sounds\\DynamicSounds\\creatures\\bear_attack1.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "",
            },  
            {
                animGroupName = "attack2",
                animSound = "sounds\\DynamicSounds\\creatures\\bear_attack2.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "bear roar",
            },  
            {
                animGroupName = "attack3",
                animSound = "sounds\\DynamicSounds\\creatures\\bear_attack3.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "bear roar",
            },                                                
        },
    },    

    {
        creatureId = "scamp",
        aware = {
            sound = "sounds\\DynamicSounds\\creatures\\scamp_aware.wav",
            volume = 1,
            timeOffset = 0,           
        },
        sounds = {                         
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\scamp_breathing_lp.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0,
                exceptAnimGroups="death1,deathknockdown,deathknockout",
            },                                                           
        },
    },       

    {
        creatureId = "riekling",
        sounds = {                         
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\riekling_breathing_lp.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0,
                exceptAnimGroups="idle,idle2,idle3,walkforward,death1,death2,death3,deathknockdown,deathknockout",
            },            
                                              
        },
    },     

    {
        creatureId = "netch_bull",
        sounds = {        
            -- {
            --     animGroupName = "walkforward",
            --     animSound = "sounds\\DynamicSounds\\creatures\\netch_walk_left.wav",
            --     loopSound = false,
            --     volume = 1,
            --     timeOffset = 0,
            --     replaceOriginalSound = "netchbul roar",
            -- },    
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\bullnetch_breathing_lp.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0,
                exceptAnimGroups="death1,deathknockdown,deathknockout",
            },                  
                                 
        },
    },

    {
        creatureId = "netch_betty",
        sounds = {        
            -- {
            --     animGroupName = "walkforward",
            --     animSound = "sounds\\DynamicSounds\\creatures\\netch_walk_left.wav",
            --     loopSound = false,
            --     volume = 1,
            --     timeOffset = 0,
            --     replaceOriginalSound = "netchbul roar",
            -- },    
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\netchbetty_breathing_lp.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0,
                exceptAnimGroups="death1,deathknockdown,deathknockout",
            },                  
                                 
        },
    },    

    -- {
    --     creatureId = "scrib",
    --     sounds = {
    --         {
    --             animGroupName = "walkforward",
    --             animSound = "sounds\\DynamicSounds\\creatures\\scrib_walk_lp.wav",
    --             loopSound = true,
    --             volume = 0.5,
    --             timeOffset = 0.5,
    --             replaceOriginalSound = "", 
    --         },
           
    --     },
    -- },  
    
    {
        creatureId = "_wolf_",
        aware = {
            sound = "sounds\\DynamicSounds\\creatures\\wolf_aware.wav",
            volume = 1,
            timeOffset = 0,           
        },         
        sounds = {
            {
                animGroupName = "runforward",
                animSound = "sounds\\DynamicSounds\\creatures\\wolf_runbreathing_lp.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0,
            },              
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\wolf_walk_left.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareleft",
            },       
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\wolf_walk_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareright",
            },
            {
                animGroupName = "attack1",
                animSound = "sounds\\DynamicSounds\\creatures\\wolf_attack1.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "wolf moan",
            },  
            {
                animGroupName = "attack3",
                animSound = "sounds\\DynamicSounds\\creatures\\wolf_attack3.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "Body Fall Large",
            },                        
        },
    },     

    {
        creatureId = "skeleton",
        aware = {
            sound = "sounds\\DynamicSounds\\creatures\\skeleton_aware.wav",
            volume = 1,
            timeOffset = 0,           
        },
        sounds = {
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\skeleton_walk_left.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareleft",
            },       
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\skeleton_walk_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareright",
            },
                  
        },
    },  
    
    {
        creatureId = "ash_ghoul",
        sounds = {
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\ash_ghoul_walk_left.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareleft",
            },       
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\ash_ghoul_walk_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareright",
            },
                  
        },
    },
    
    {
        creatureId = "werewolf",
        sounds = {
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\werewolf_walk_left.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareleft",
            },       
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\werewolf_walk_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareright",
            },
                  
        },
    },    
    
    {
        creatureId = "ash_zombie",
        aware = {
            sound = "sounds\\DynamicSounds\\creatures\\ash_zombie_aware.wav",
            volume = 1,
            timeOffset = 0,           
        },            
        sounds = {      
        },
    }, 

    {
        creatureId = "spriggan",
        sounds = {
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\spriggan_breathing_lp.wav",
                loopSound = true,
                volume = 0.4,
                timeOffset = 0,
                exceptAnimGroups="death1,death2,death3,deathknockdown,deathknockout",
            },             
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\spriggan_walk_left.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareleft",
            },       
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\spriggan_walk_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareright",
            },
                  
        },
    },  
     
    {
        creatureId = "troll",
        aware = {
            sound = "sounds\\DynamicSounds\\creatures\\troll_aware.wav",
            volume = 1,
            timeOffset = 0,           
        },        
        sounds = {
            {
                animGroupName = "idle",
                animSound = "sounds\\DynamicSounds\\creatures\\troll_breathe_idle_lp.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0,
            },
            {
                animGroupName = "idle2",
                animSound = "sounds\\DynamicSounds\\creatures\\troll_breathe_idle_lp.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0,
            },
            {
                animGroupName = "idle3",
                animSound = "sounds\\DynamicSounds\\creatures\\troll_breathe_idle_lp.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0,
            },                        
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\troll_walk_left.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "animallargeleft",
            },       
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\troll_walk_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "animallargeright",
            },
                  
        },
    },    

    {
        creatureId = "bonewalker",  
        sounds = {
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\bonewalker_walk_left.wav",
                loopSound = false,
                volume = 2,
                timeOffset = 0,
                replaceOriginalSound = "footbareleft",
            },       
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\bonewalker_walk_right.wav",
                loopSound = false,
                volume = 2,
                timeOffset = 0,
                replaceOriginalSound = "footbareright",
            },
                  
        },
    }, 
    
    {
        creatureId = "lich",  
        aware = {
            sound = "sounds\\DynamicSounds\\creatures\\lich_aware.wav",
            volume = 1,
            timeOffset = 0,           
        }, 
        sounds = {
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\lich_walk_left.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareleft",
            },       
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\lich_walk_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareright",
            },
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\lich_breathing_lp.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0,
                exceptAnimGroups="death1,death2,death3,death4,deathknockdown,deathknockout",
            },                                
        },
    },     
    
    {
        creatureId = "draugr",
        aware = {
            sound = "sounds\\DynamicSounds\\creatures\\draugr_aware.wav",
            volume = 1,
            timeOffset = 0,           
        },            
        sounds = {
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\draugr_breathing_lp.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0,
                exceptAnimGroups="death1,death2,death3,deathknockdown,deathknockout",
            },              
            {
                animGroupName = "walkforward",
                animSound = "sounds\\DynamicSounds\\creatures\\draugr_walk_left.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareleft",
            },       
            {
                animGroupName = "walkforward",
                animSound = "sounds\\DynamicSounds\\creatures\\draugr_walk_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareright",
            },
            {
                animGroupName = "runforward",
                animSound = "sounds\\DynamicSounds\\creatures\\draugr_walk_left.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareleft",
            },       
            {
                animGroupName = "runforward",
                animSound = "sounds\\DynamicSounds\\creatures\\draugr_walk_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareright",
            },            
            {
                animGroupName = "attack2",
                animSound = "sounds\\DynamicSounds\\creatures\\draugr_attack2.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
            },  
            {
                animGroupName = "attack3",
                animSound = "sounds\\DynamicSounds\\creatures\\draugr_attack3.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareright",
            },      
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\draugr_death_fall.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "body fall medium",
            },                                            
                  
        },
    },     

    {
        creatureId = "mudcrab",
        sounds = {
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\mudcrab_breathing_lp.wav",
                loopSound = true,
                volume = 0.5,
                timeOffset = 0,
                exceptAnimGroups="death1,death2,deathknockdown,deathknockout",
            },                         
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\mudcrab_walk_left.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "scribleft",
            },       
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\mudcrab_walk_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "scribright",
            },            
                        
        },
    }, 
    
    {
        creatureId = "atronach_storm",
        sounds = {
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\atronach_storm_idle_lp.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0,
                exceptAnimGroups="death1,deathknockdown,deathknockout",
            },
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\atronach_storm_dead_fall.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "Body Fall Large",
            },            
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\atronach_storm_walk_left.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "animallargeleft",
            },       
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\atronach_storm_walk_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "animallargeright",
            },  
            {
                animGroupName = "death1",
                animSound = "sounds\\DynamicSounds\\creatures\\atronach_storm_dead1_lp.wav",
                loopSound = true,
                volume = 0.3,
                timeOffset = 0,
            }, 
            {
                animGroupName = "deathknockdown",
                animSound = "sounds\\DynamicSounds\\creatures\\atronach_storm_dead1_lp.wav",
                loopSound = true,
                volume = 0.3,
                timeOffset = 0,
            },                        
            {
                animGroupName = "dead1",
                animSound = "sounds\\DynamicSounds\\creatures\\atronach_storm_dead_fall.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "body fall medium",
            },             
                                  
        },
    },   
    
    {
        creatureId = "atronach_flame",
        aware = {
            sound = "sounds\\DynamicSounds\\creatures\\atronach_flame_aware.wav",
            volume = 1,
            timeOffset = 0,           
        }, 
        sounds = {
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\atronach_flame_breathing_lp.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0,
                exceptAnimGroups="death1,deathknockdown,deathknockout",
            },            
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\atronach_flame_walk_left.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareleft",
            },       
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\atronach_flame_walk_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareright",
            },
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\atronach_flame_dead_fall.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "body fall large",
            }, 
            {
                animGroupName = "death1",
                animSound = "sounds\\DynamicSounds\\creatures\\atronach_flame_dead_lp.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0,
            },                         
                                  
        },
    },    

   
    {
        creatureId = "atronach_frost",
        sounds = {
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\atronach_frost_breathing_lp.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0,
                exceptAnimGroups="death1,deathknockdown,deathknockout",
            },            
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\atronach_frost_walk_left.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareleft",
            },       
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\atronach_frost_walk_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareright",
            },                                 
            {
                animGroupName = "dead1",
                animSound = "sounds\\DynamicSounds\\creatures\\atronach_frost_dead_fall.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "body fall medium",
            },             
                                  
        },
    }, 

    {
        creatureId = "goblin",
        sounds = {
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\goblin_walk_left.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareleft",
            },       
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\goblin_walk_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareright",
            },
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\goblin_breathing_lp.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0,
                exceptAnimGroups="idle,idle2,idle3,walkforward,death1,death2,death3,deathknockdown,deathknockout",
            },              
          
                                  
        },
    },    

    {
        creatureId = "dremora",
        sounds = {
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\dremora_walk_left2.wav",
                loopSound = false,
                volume = 0.5,
                timeOffset = 0,
                replaceOriginalSound = "footbareleft",
            },       
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\dremora_walk_right2.wav",
                loopSound = false,
                volume = 0.5,
                timeOffset = 0,
                replaceOriginalSound = "footbareright",
            },                                 
                         
        },
    }, 

    {
        creatureId = "golden saint",
        sounds = {
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\dremora_walk_left2.wav",
                loopSound = false,
                volume = 0.5,
                timeOffset = 0,
                replaceOriginalSound = "footbareleft",
            },       
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\dremora_walk_right2.wav",
                loopSound = false,
                volume = 0.5,
                timeOffset = 0,
                replaceOriginalSound = "footbareright",
            },                                 
                         
        },
    }, 
    
    {
        creatureId = "hunger",
        sounds = {
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\hunger_roar.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "were roar",
            }, 
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\hunger_moan.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "were moan",
            }, 
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\hunger_scream.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "were scream",
            },                               
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\hunger_walk_left.wav",
                loopSound = false,
                volume = 0.5,
                timeOffset = 0,
                replaceOriginalSound = "footbareleft",
            }, 
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\hunger_walk_right.wav",
                loopSound = false,
                volume = 0.5,
                timeOffset = 0,
                replaceOriginalSound = "footbareright",
            },                                             
                         
        },
    }, 
    
    -- ==================================================================================
    -- Tamriel Rebuilt
    -- ==================================================================================

    {
        creatureId = "T_Dae_Cre_Seduc_01",
        sounds = {
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\seducer_walk_left.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareleft",
            },       
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\seducer_walk_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareright",
            }, 
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\seducer_moan.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "spriggan moan",
            }, 
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\seducer_roar.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "spriggan roar",
            },  
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\seducer_scrm.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "spriggan scream",
            },                                                                     
                         
        },
    },     

    {
        creatureId = "LrgSpider",
        sounds = {
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\LrgSpider_walk_left.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareleft",
            },       
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\LrgSpider_walk_right.wav",
                loopSound = false,
                volume = 1,
                timeOffset = 0,
                replaceOriginalSound = "footbareright",
            }, 
            {
                animGroupName = "*",
                animSound = "sounds\\DynamicSounds\\creatures\\LrgSpider_breathing.wav",
                loopSound = true,
                volume = 1,
                timeOffset = 0,
                exceptAnimGroups="death1",
            },                                                                              
                         
        },
    },     

}

return creaturesSoundBank
