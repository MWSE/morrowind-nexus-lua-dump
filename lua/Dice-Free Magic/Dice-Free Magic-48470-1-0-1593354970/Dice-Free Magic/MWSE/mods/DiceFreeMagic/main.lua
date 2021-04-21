local function SpellChance(e)
	if e.castChance < 60 then
		e.castChance = 0 
		else
		e.castChance = 100
	end	
end	

 local function initialized()
     event.register("spellCast", SpellChance)
     print("[Dice-Free Magic] Initialized")
 end

 event.register("initialized", initialized)