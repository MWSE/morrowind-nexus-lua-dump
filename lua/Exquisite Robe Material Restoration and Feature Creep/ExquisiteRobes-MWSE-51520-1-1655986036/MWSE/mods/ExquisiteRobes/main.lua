local robeTable = {
	"0s_exq_rob_blu_01",
	"0s_exq_rob_grn_01",
	"0s_exq_rob_ong_01",
	"0s_exq_rob_pnk_01",
	"0s_exq_rob_prp_01",
	"0s_exq_rob_red_01"
	}

local function onMobileActivated(e)

	if (e.reference == tes3.player) or (e.mobile == tes3.mobilePlayer) then
		return
	end

	if e.reference.object.objectType ~= tes3.objectType.npc then
		return
	end

	if e.reference.baseObject.id == "galbedir" then
		return
	end

	local script = e.reference.baseObject.script
	if script then
		local scriptVars = script:getVariableData()
		if scriptVars then
			for var in pairs(scriptVars) do
				var = var:lower()
				if var == "companion" then
					return
				end
			end
		end
	end

	if mwscript.getItemCount{reference = e.reference, item = "exquisite_robe_01"} >= 1 then
		tes3.removeItem({ reference = e.reference, playSound = false, limit = false, item = "exquisite_robe_01" })
		local itemPick = table.choice(robeTable)
		tes3.addItem({ reference = e.reference, playSound = false, limit = false, item = itemPick })
		mwscript.equip({ reference = e.reference, item = itemPick })
	end
end

local function initialized()
	if tes3.isModActive("ExquisiteRobes.ESP") then
		event.register("mobileActivated", onMobileActivated)
	else
		mwse.log("ExquisiteRobes.ESP not found")
	end
end
event.register("initialized", initialized)