-- Magicka Regen

local config = require("Magicka Regen.config")

local function clamp(x, a, b)
	if (x < a) then
		return a
	end
	
	if (x > b) then
		return b
	end
	
	return x
end

local function regenMagicka()
	if config.pcRegen then
		local mobilePlayer = tes3.getMobilePlayer()
		local wp = tes3.mobilePlayer.willpower.current
		local int = tes3.mobilePlayer.intelligence.current
		local reg = (((wp / 5) + (int / 10)) * (config.pcRate / 10000))
		if config.vanillaRate then
			if config.magickaDecay then
				reg = (((((0.15 * int) / 60) * tes3.findGlobal("timescale").value) * (config.pcRate / 10000)) * (0.01 * (tes3.mobilePlayer.magicka.base - tes3.mobilePlayer.magicka.current)))
			else
				reg = ((((0.15 * int) / 60) * tes3.findGlobal("timescale").value) * (config.pcRate / 10000))
			end
		elseif config.magickaDecay then
			reg = ((((wp / 5) + (int / 10)) * (config.pcRate / 10000)) * (0.01 * (tes3.mobilePlayer.magicka.base - tes3.mobilePlayer.magicka.current)))
		end
		local newMagicka = (tes3.mobilePlayer.magicka.current + reg)
		newMagicka = clamp(newMagicka, 0, tes3.mobilePlayer.magicka.base)
		local lowMagicka = (tes3.mobilePlayer.magicka.current < tes3.mobilePlayer.magicka.base)
		
		if tes3.player.object.spells:contains("wombburn") then
			return
		end
		
		if lowMagicka then
			tes3.setStatistic{ reference = tes3.player, name = "magicka", current = newMagicka }
		end
	end
	
	if config.npcRegen then
		for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.actor, tes3.objectType.creature) do
			if ref.mobile then
				local wp = ref.mobile.willpower.current
				local int = ref.mobile.intelligence.current
				local reg = (((wp / 5) + (int / 10)) * (config.npcRate / 10000))
				if config.vanillaRate then
					if config.magickaDecay then
						reg = (((((0.15 * int) / 60) * tes3.findGlobal("timescale").value) * (config.npcRate / 10000)) * (0.01 * (ref.mobile.magicka.base - ref.mobile.magicka.current)))
					else
						reg = ((((0.15 * int) / 60) * tes3.findGlobal("timescale").value) * (config.npcRate / 10000))
					end
				elseif config.magickaDecay then
					reg = ((((wp / 5) + (int / 10)) * (config.npcRate / 10000)) * (0.01 * (ref.mobile.magicka.base - ref.mobile.magicka.current)))
				end
				local newMagicka = (ref.mobile.magicka.current + reg)
				newMagicka = clamp(newMagicka, 0, tes3.mobilePlayer.magicka.base)
				local lowMagicka = (ref.mobile.magicka.current < ref.mobile.magicka.base)
				
				if ref.mobile.object.spells:contains("wombburn") then
					return
				end
			
				if lowMagicka then
					tes3.setStatistic{ reference = ref.mobile, name = "magicka", current = newMagicka }
				end
			end
		end
	end
end

local function waitMagicka(e)
	if config.pcRegen then
		local mobilePlayer = tes3.getMobilePlayer()
		local wp = tes3.mobilePlayer.willpower.current
		local int = tes3.mobilePlayer.intelligence.current
		local reg = (((wp / 5) + (int / 10)) * (config.pcRate / 10000))
		local lowMagicka = (tes3.mobilePlayer.magicka.current < tes3.mobilePlayer.magicka.base)
		local waitMagicka = (tes3.mobilePlayer.magicka.current + ((reg * 3600) * tes3.mobilePlayer.restHoursRemaining))
		waitMagicka = clamp(waitMagicka, 0, tes3.mobilePlayer.magicka.base)
		
		if tes3.player.object.spells:contains("wombburn") then
			return
		end
		
		if lowMagicka then
			tes3.setStatistic{ reference = tes3.player, name = "magicka", current = waitMagicka }
		end
	end
		
	if config.npcRegen then
		for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.actor) do
			if ref.mobile then
				local wp = ref.mobile.willpower.current
				local int = ref.mobile.intelligence.current
				local reg = (((wp / 5) + (int / 10)) * (config.npcRate / 10000))
				local lowMagicka = (ref.mobile.magicka.current < ref.mobile.magicka.base)
				local waitMagicka = (ref.mobile.magicka.current + ((reg * 3600) * tes3.mobilePlayer.restHoursRemaining))
				waitMagicka = clamp(waitMagicka, 0, tes3.mobilePlayer.magicka.base)
				
				if ref.mobile.object.spells:contains("wombburn") then
					return
				end
			
				if lowMagicka then
					tes3.setStatistic{ reference = ref.mobile, name = "magicka", current = waitMagicka }
				end
			end
		end
	end
end

local function initialized()
	event.register("loaded", function()
		timer.start{iterations = -1, duration = 0.1, callback = regenMagicka}
	end)
	event.register("calcRestInterrupt", waitMagicka)
end

event.register("initialized", initialized)

event.register("modConfigReady", function()
	require("Magicka Regen.mcm")
end)