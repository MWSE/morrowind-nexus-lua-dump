local function onMobileActivated(e)
	if e.reference.object.objectType ~= tes3.objectType.npc then return end
	if e.reference.object.faction then
		if e.reference.object.faction.id == "Redoran" then
			if mwscript.getItemCount{reference = e.reference, item = "0s_housering_R"} >= 1 then return end
			tes3.addItem({ reference = e.reference, playSound = false, limit = false, item = "0s_housering_R" })
		end
		if e.reference.object.faction.id == "Hlaalu" then
			if mwscript.getItemCount{reference = e.reference, item = "0s_housering_h"} >= 1 then return end
			tes3.addItem({ reference = e.reference, playSound = false, limit = false, item = "0s_housering_h" })
		end
		if e.reference.object.faction.id == "Telvanni" then
			if mwscript.getItemCount{reference = e.reference, item = "0s_housering_T"} >= 1 then return end
			tes3.addItem({ reference = e.reference, playSound = false, limit = false, item = "0s_housering_T" })
		end
	end
end


local function initialized()
	if tes3.isModActive("Great_House_Rings.ESP") then
		event.register("mobileActivated", onMobileActivated)
	else
		mwse.log("Great_House_Rings.ESP not detected")
	end
end
event.register("initialized", initialized)
