local cf = mwse.loadConfig("4NM_ARMORER", {upgm = true})
local G = {}	local A = {furn_anvil00 = true, furn_t_fireplace_01 = true, furn_de_forge_01 = true, furn_de_bellows_01 = true, Furn_S_forge = true}

local function onEquip(e) if not tes3.mobilePlayer.inCombat and e.item.objectType == tes3.objectType.repairItem then	local anvil
	for r in tes3.player.cell:iterateReferences(tes3.objectType.static) do if A[r.object.id] and tes3.player.position:distance(r.position) < 1000 then anvil = true	break end end
	tes3.findGMST("fRepairAmountMult").value = anvil and 2 or 1			local Qal = math.min(e.item.quality,2)	local Skill = math.min(tes3.mobilePlayer:getSkillValue(1) + tes3.mobilePlayer.agility.base/5 + tes3.mobilePlayer.luck.base/10, 100)
	if not G.ImpTab then local ob, ida, Kmax, KF		G.ImpTab = {}	G.ImpD = {}
		for _, s in pairs(cf.upgm and tes3.player.object.equipment or tes3.player.object.inventory) do ob = s.object
			if ((ob.objectType == tes3.objectType.armor) or (ob.objectType == tes3.objectType.weapon and ob.type < 11)) and ob.weight > 0 then
				Kmax = math.min(Qal/10, Skill/500)
				KF = math.min((Skill * Qal - math.min(ob.value,10000)^0.5)/100, 1)
				if KF > 0 then
					if not cf.upgm then for i = 1, s.count do ida = s.variables and s.variables[i] or tes3.addItemData{to = tes3.player, item = ob, updateGUI = false}	ida.tempData.upg = true		G.ImpD[ida] = true end end
					G.ImpTab[ob] = ob.maxCondition		ob.maxCondition = math.round(ob.maxCondition * (1 + KF * Kmax))
				end
			end
		end
		timer.delayOneFrame(function() for iob, max in pairs(G.ImpTab) do iob.maxCondition = max end	G.ImpTab = nil
			if not cf.upgm then for ida, _ in pairs(G.ImpD) do ida.tempData.upg = nil end	tes3.updateInventoryGUI{reference = tes3.player} end	G.ImpD = nil
		end)
	end
end end		event.register("equip", onEquip)


local function registerModConfig()		local template = mwse.mcm.createTemplate("4NM_ARMORER")	template:saveOnClose("4NM_ARMORER", cf)	template:register()		local page = template:createPage()
page:createYesNoButton{label = "Allow to upgrade only equipped weapons and armor", variable = mwse.mcm.createTableVariable{id = "upgm", table = cf}}
end		event.register("modConfigReady", registerModConfig)