local moragTongHelm

local function onMobileActivated(e)
	if e.reference.object.objectType ~= tes3.objectType.npc then
		return
	end
	if e.reference.object.faction then
		if e.reference.object.faction.id == "Morag Tong" then

			local hasHelm = tes3.getEquippedItem({
				actor = e.reference,
				objectType = tes3.objectType.armor,
				slot = tes3.armorSlot.helmet
			  })
			if hasHelm then
				return
			end

			local itemPick = table.choice(moragTongHelm)
			tes3.addItem({ reference = e.reference, playSound = false, limit = false, item = itemPick })
			mwscript.equip({ reference = e.reference, item = itemPick })
		end
	end
end

local function initialized()
	if tes3.isModActive("Morag Tong Helm Diversity.ESP") then
		moragTongHelm = {
			"_RV_morag_tong_helm_1",
			"_RV_morag_tong_helm_2",
			"_RV_morag_tong_helm_3",
			"_RV_morag_tong_helm_4",
			"_RV_morag_tong_helm_5",
			"_RV_morag_tong_helm_7",
			"_RV_morag_tong_helm_8",
			"morag_tong_helm",
			"netch_leather_boiled_helm"
		}
	else
		moragTongHelm = {
			"morag_tong_helm",
			"netch_leather_boiled_helm"
		}
	end
	event.register("mobileActivated", onMobileActivated)
end
event.register("initialized", initialized)