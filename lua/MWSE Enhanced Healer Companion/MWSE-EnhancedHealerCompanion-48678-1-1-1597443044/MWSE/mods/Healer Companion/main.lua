local HealerNPC

local function CompanionScan()
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
end
local function onLoaded()
	HealerNPC = tes3.getReference("0s_healer_companion")
	timer.start{type=timer.simulate, duration=10, iterations=-1, callback=CompanionScan}
end
local function initialized()
	if tes3.isModActive("HealerCompanion.esp") then
		event.register("loaded", onLoaded)
	end
end
event.register("initialized", initialized)
---------------------------------MCM--------------------------------------
local function registerModConfig()
	local template = mwse.mcm.createTemplate("Healer Companion")
	local page = template:createSideBarPage()
	page.label = "Settings"
	page.description =
	(
		"Healer Companion preferences"
	)
	page.noScroll = false
	local category = page:createCategory("Healer Companion Options")

		category:createSlider({
		label = "Toggle Warping",
		description = "0 is off, 1 is on",
		min = 0,
		max = 1,
		step = 1,
		jump = 1,
		variable = mwse.mcm.createGlobal{id = "0s_healerNPCwarp" },
	})

		category:createSlider({
		label = "Toggle Magicka Regeneration",
		description = "0 is off, 1 is on",
		min = 0,
		max = 1,
		step = 1,
		jump = 1,
		variable = mwse.mcm.createGlobal{id = "0s_healerNPCmgen" },
	})
	mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)