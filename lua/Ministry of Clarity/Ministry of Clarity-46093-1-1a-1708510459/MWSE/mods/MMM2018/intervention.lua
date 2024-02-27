
--[[
	Dreamer Intervention spell
	]]--

local interventionSpell

local function onSpellTick (e)
	if e.target.object.name == "Dreamer" and e.target.mobile.fatigue.current <= 0 then
		tes3.setGlobal("sx1_rw_dream", ( tes3.getGlobal("sx1_rw_dream") + 1 ))
		timer.start({ duration = 1, callback = function() mwscript.disable({reference = e.target }) end, type = timer.real })
	end
end	
	
local function onLoaded(e)
	--Modify our intervention spell to on target
	interventionSpell = tes3.getObject("sx1_intervention")
	interventionSpell.effects[1].rangeType = 1
	event.unregister("spellTick", onSpellTick, { filter = interventionSpell } )
	event.register("spellTick", onSpellTick, { filter = interventionSpell } )
end
--register events
event.register("loaded", onLoaded)