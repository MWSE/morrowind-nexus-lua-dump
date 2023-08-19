local HealerNPCs

local function HandleHealerNPC(HealerNPC)
	if not HealerNPC then return false end
	if HealerNPC.mobile == nil then return false end
	if tes3.getCurrentAIPackageId(HealerNPC.mobile) == tes3.aiPackage.follow then
		for mobileActor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
			local animState = mobileActor.actionData.animationAttackState
			if (animState == tes3.animationState.dying or animState == tes3.animationState.dead) then
				return false
			end
			if (HealerNPC.mobile.magicka.current > 20) then
				if (mobileActor.health.normalized < 0.5) then
					if (mobileActor.object.id == HealerNPC.object.id) then
						tes3.cast{ reference = HealerNPC, target = mobileActor, spell = "Hearth Heal"}
						tes3.modStatistic{ reference = HealerNPC, name = "magicka", current = -13 }
						--tes3.messageBox("%s healed himself" , HealerNPC.object.name)
					else
						tes3.cast{ reference = HealerNPC, target = mobileActor, spell = "0s_companion_heal"}
						tes3.modStatistic{ reference = HealerNPC, name = "magicka", current = -13 }
						--tes3.messageBox({ message = HealerNPC.object.name .. " healed " .. mobileActor.object.name })
					end
				end
			end
		end
	end
	return true
end

local function CompanionScan()
	for i, HealerNPC in ipairs(HealerNPCs) do
		HandleHealerNPC(HealerNPC)
	end
end
local function onLoaded()
-- IDs of all healer NPCs
	local healerIDs = {
		"aa_comp_0s_healer",
-- FFrens
		"aa_comp_draytha",
		"aa_comp_amalie",
		"onlyhestandsthere",
		"aa_comp_mia",
		"aa_comp_suriel",
		"aa_comp_jjarso",
		"aa_comp_olin",
		"aa_comp_solanayth",
		"gilvas barelo",
		"aa_comp_driyami",
		"aa_comp_uveen",
		"aa_comp_marcus",
		"aa_comp_wathold",
		"aa_comp_grimm",
		"aa_comp_aridis",
		"aa_comp_tessa",
		"aa_comp_reem",
		"aa_comp_chari",
		"aa_comp_covis",
		"aa_comp_sam",
		"aa_comp_josephin",
		"sosia caristiana",
		"minabibi assardarainat",
		"aa_comp_aria",
		"aa_comp_susan",
		"aa_comp_0s_huntress",
		"aa_comp_valrek",
-- FFrens TR
		"TR_m2_Felms_Sendas",
		"TR_m2_q_ak_Dulis_Llendu",
		"TR_m3_O_Nefeve",
		"TR_m2_Dolrem Pares",
-- Rishajiit
		"aa_latte_comp01",
-- Staff Agency
		"aa_sa_healer"
	}

	HealerNPCs = {}
	for i, healerID in ipairs(healerIDs) do
		table.insert(HealerNPCs, tes3.getReference(healerID))
	end
	timer.start{type=timer.simulate, duration=10, iterations=-1, callback=CompanionScan}
end
local function initialized()
	if tes3.isModActive("HealerCompanion.esp") then
		event.register("loaded", onLoaded)
	end
end
event.register("initialized", initialized)
---------------------------------MCM--------------------------------------
--local function registerModConfig()
--	local template = mwse.mcm.createTemplate("Healer Companion")
--	local page = template:createSideBarPage()
--	page.label = "Settings"
--	page.description =
--	(
--		"Healer Companion preferences"
--	)
--	page.noScroll = false
--	local category = page:createCategory("Healer Companion Options")

--		category:createSlider({
--		label = "Toggle Warping",
--		description = "0 is off, 1 is on",
--		min = 0,
--		max = 1,
--		step = 1,
--		jump = 1,
--		variable = mwse.mcm.createGlobal{id = "0s_healerNPCwarp" },
--	})

--		category:createSlider({
--		label = "Toggle Magicka Regeneration",
--		description = "0 is off, 1 is on",
--		min = 0,
--		max = 1,
--		step = 1,
--		jump = 1,
--		variable = mwse.mcm.createGlobal{id = "0s_healerNPCmgen" },
--	})
--	mwse.mcm.register(template)
--end
--event.register("modConfigReady", registerModConfig)