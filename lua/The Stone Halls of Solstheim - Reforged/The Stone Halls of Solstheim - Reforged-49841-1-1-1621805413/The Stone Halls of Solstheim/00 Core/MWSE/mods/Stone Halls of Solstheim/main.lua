local tooltipsComplete = include("Tooltips Complete.interop")
local ashfall = include("mer.ashfall.interop")
local function onInit()
    if tooltipsComplete then

        -- Bloodskal Barrow Lore
        tooltipsComplete.addTooltip(
            "bm_nordic_silver_lgswd_bloodska", 
            "A ruddy sword created by Jurgar the Oath-breaker, who forged it using knowledge granted to him by the Father of Manbeasts and the Master of the Hunt. The bones used in its creation are rumored to have been those of the Forgemaster's three sons whom he hunted down and murdered in a fit of cold rage.",
            "unique"
        )

        tooltipsComplete.addTooltip(
            "_shs_bloodskal_lore_01", 
            "Written in ancient runes, the fragmented tablet reads: Here lies Jurgar the Forgemaster. He who betrayed kin and offspring in service of the Great Hunt. He who wrought iron, steel and silver with blood, bone and sinew. . ."            
        )
		
		tooltipsComplete.addTooltip(
            "_shs_bloodskal_lore_02",
            ". . . those who watched the master in life, now watch over him in death."
		)
		
		tooltipsComplete.addTooltip(
            "_shs_bloodskal_lore_03",
            ". . . three sons returned empty handed from the hunt and were forgiven. However, when it became known that they had spent their days in idleness and in debauchery, Jurgar the Forgemaster hunted down his sons and slew them with blade and arrow. Jurgar, distraught by his actions, forged metal, bone and sinew into a weapon. . . his final masterpiece. . ."
		)
			
		tooltipsComplete.addTooltip(
            "_shs_bloodskal_lore_04",
            ". . . we have sealed him in this tomb, desecrated the shrines and embalmed his servants in eternal vigilance. . . the forge, imbued by unknown magic, cannot be destroyed or dismantled and continues to roar with an endless flame. . . "
		)
       
        tooltipsComplete.addTooltip(
            "_shs_forgemaster_veig_01", 
            "A strange, musky concoction, reminiscent of hide and burning wood. "            
        )
        	
        tooltipsComplete.addTooltip(
            "_shs_ing_whitecap",
            "A common mushroom that grows in the dark, murky and damp depths of Solstheim."
          
        )
			
        tooltipsComplete.addTooltip(
            "_shs_ing_bleedingcrown",
            "A red-capped mushroom favored by assassins to brew concoctions that weaken a target's natural resistances."
        )
		
        tooltipsComplete.addTooltip(
            "_shs_ing_blisterwort",
            "A common fungi favored by alchemists for its healing properties."            
        )
			
        tooltipsComplete.addTooltip(
            "_shs_ing_namirarot",
            "A rusty, sickly looking mushroom with a foul, lingering smell reminiscent of a decaying corpse. The fungi is named after the Daedric Prince Namira, who is also known as the Lady of Decay and the Goddess of the Dark."            
        )
		
		tooltipsComplete.addTooltip(
            "_shs_sweetroll",
            "A simple sweet from a simpler time."            
        )		 	    
        
        
    end
end
event.register("initialized", onInit)


local ashfall = include("mer.ashfall.interop")
if ashfall then
    ashfall.registerFoods{
        _shs_ing_bleedingcrown = "mushroom",
		_shs_ing_blisterwort = "mushroom",
		_shs_ing_namirarot = "mushroom",
		_shs_ing_whitecap = "mushroom",
		_shs_sweetroll = "food",
    }
end