-- Fish With Fishing Poles by RacerPlume
-- Skill exposer module and OAAB/TR-DATA expansion by Booze (B00ze64)
-- Based on Abot's show Water Life Fishing skill exposer

local author = "Booze"
local modName = "Fish With Fishing Poles Expansion"
local modPrefix = author .. "/".. modName

local skillModule = include("OtherSkills.skillModule")

local skillModuleMySkill	-- Reference to the skillModule's skill
local fishSkillGlobal		-- Reference to the global used by the ESP
local previousCastCount		-- Keep track of CastCount (Mod's Global)
local showDebug = 0

local function onSkillReady() -- This triggers on every game load

--	if ( fishSkillGlobal ~= nil ) then

		local fishingSkillId = "PoleFishing"

		skillModule.registerSkill(

			fishingSkillId,
			{
			name = "Pole Fishing",
			value =	0,		-- This will be replaced by the savegame value when already defined
			progress = 0,		-- This will be replaced by the savegame value when already defined
			lvlCap = 100,
			icon = "Icons/otherskills/PoleFishing.dds",
			attribute = tes3.attribute.endurance,
			description = "The Pole Fishing skill determines your effectiveness at catching something when using the Fish With Fishing Poles action.",
--		     	specialization = tes3.specialization.stealth, -- this makes the skill progress faster than the Mod when you are a Stealth guy
			active = "active"
			}
		)

		skillModuleMySkill = skillModule.getSkill(fishingSkillId) -- Reference to the skillModule's skill

		if ( skillModuleMySkill ~= nil ) then

			local modSkill       = math.floor ( fishSkillGlobal.value / 50 ) -- round down
			local modProgress    = fishSkillGlobal.value % 50
			local savedCastCount = ( skillModuleMySkill.value * 50 + skillModuleMySkill.progress / 2 )
			previousCastCount    = fishSkillGlobal.value

			if ( showDebug > 0 ) then

				mwse.log("[%s] Previous CastCount %s Saved CastCount %s", modPrefix, previousCastCount, savedCastCount)
				mwse.log("[%s] Skill per Previous CastCount %s with progress %s", modPrefix, modSkill, modProgress)
				mwse.log("[%s] Skill per Skill Module %s with progress %s", modPrefix, skillModuleMySkill.value, skillModuleMySkill.progress)
			end

			if ( savedCastCount ~= previousCastCount ) then -- Attempt to reSync (even if that means negative progress)

				local adjustSkill = savedCastCount - previousCastCount
				skillModuleMySkill:progressSkill( adjustSkill * 2)
				mwse.log("[%s] Re-Adjusted Skill Level by %s progress units", modPrefix, adjustSkill)
			end
		else
			mwse.log("[%s] Error, Failed to register Pole-Fishing Skill.", modPrefix)
		end
--	else
--		mwse.log("[%s] Error, Fish With Fishing Poles Fishing.esp not found.", modPrefix)
--	end
end

local function onFrame() -- Increment Skill Progress by 2/100 each time the mod's global increases by 1

--	if ( fishSkillGlobal ~= nil ) then
	if ( skillModuleMySkill ~= nil ) then

		if ( previousCastCount < fishSkillGlobal.value ) then

			skillModuleMySkill:progressSkill(2)
			previousCastCount = fishSkillGlobal.value

			if ( showDebug > 0 ) then

				mwse.log("[%s] PROGRESS + 2", modPrefix)

				local modSkill       = math.floor( fishSkillGlobal.value / 50 ) -- round down
				local modProgress    = fishSkillGlobal.value % 50
				local savedCastCount = ( skillModuleMySkill.value * 50 + skillModuleMySkill.progress / 2 )

				mwse.log("[%s] New CastCount %s Saved CastCount %s", modPrefix, previousCastCount, savedCastCount)
				mwse.log("[%s] Skill per Previous CastCount %s with progress %s", modPrefix, modSkill, modProgress)
				mwse.log("[%s] Skill per Skill Module %s with progress %s", modPrefix, skillModuleMySkill.value, skillModuleMySkill.progress)
			end
		end
	end
--	end
end

local function updateIngred(ingredSrc,ingredDst) -- Update our ingredients in case they've changed since we copied them out of the ESM's

	local iSrc = tes3.getObject(ingredSrc)
	local iDst = tes3.getObject(ingredDst)

	if ( iSrc ~= nil ) then

		for _, iProperty in pairs{"icon", "mesh", "name", "value", "weight"} do

			iDst[iProperty] = iSrc[iProperty]

			if ( showDebug > 0 ) then

				mwse.log("[%s] Updated %s From %s, %s = %s", modPrefix, iDst.id, iSrc.id, iProperty, iSrc[iProperty])
			end
		end

		for i = 1, 4 do

			iDst.effects[i] = iSrc.effects[i]
			iDst.effectAttributeIds[i] = iSrc.effectAttributeIds[i]
			iDst.effectSkillIds[i] = iSrc.effectSkillIds[i]

			if ( showDebug > 0 ) then

				mwse.log("[%s] Updated %s From %s, Effect#%s = %s/%s/%s", modPrefix, iDst.id, iSrc.id, i, iSrc.effects[i], iSrc.effectAttributeIds[i], iSrc.effectSkillIds[i])
			end
		end
	else
		mwse.log("[%s] Warning, Ingredient %s not found.", modPrefix, ingredSrc)
	end
end

local function initialized()

	local ashfall = include("mer.ashfall.interop")

	if ashfall then

		ashfall.registerFoods{

			pf_IngFood_SfMeat_01 = "meat",
			pf_IngFood_FishBrowntrout_01 = "meat",
			pf_IngFood_FishPike_01 = "meat",
			pf_IngFood_FishPikeperch_01 = "meat",
			pf_IngFood_FishSpr_01 = "meat",
			pf_IngFood_FishStrid_01 = "meat",
			pf_IngFood_FishSalmon_01 = "meat",
			pf_IngFood_FishCod_01 = "meat",
			pf_IngFood_FishChrysophant_01 = "meat",
			}
	else
		mwse.log("[%s] Warning, Ashfall not found.", modPrefix)
	end

	fishSkillGlobal = tes3.findGlobal("FishingCastCount") -- Reference to the global variable used by the ESP

	if ( fishSkillGlobal ~= nil ) then -- Fishing With Poles is loaded

		local FishingOATR = tes3.findGlobal("FishingOATR") -- Are we running correct version of the mod?

		if ( FishingOATR ~= nil ) then

			local activeLibraries = 0

			if tes3.isModActive("OAAB_Data.esm") or ( tes3.findGlobal("AB_EnchantBonus") ~= nil ) then

				activeLibraries = 1
				mwse.log("[%s] Found OAAB-Data.", modPrefix)
				updateIngred("AB_IngCrea_SfMeat_01", "pf_IngFood_SfMeat_01")
			end

			if tes3.isModActive("Tamriel_Data.esm") or ( tes3.findGlobal("T_Glob_PassTimeHours") ~= nil ) then

				activeLibraries = activeLibraries + 2
				mwse.log("[%s] Found Tamriel-Data.", modPrefix)
				updateIngred("T_IngFood_FishBrowntrout_01", "pf_IngFood_FishBrowntrout_01")
				updateIngred("T_IngFood_FishPike_01", "pf_IngFood_FishPike_01")
				updateIngred("T_IngFood_FishPikeperch_01", "pf_IngFood_FishPikeperch_01")
				updateIngred("T_IngFood_FishSpr_01", "pf_IngFood_FishSpr_01")
				updateIngred("T_IngFood_FishStrid_01", "pf_IngFood_FishStrid_01")
				updateIngred("T_IngFood_FishSalmon_01", "pf_IngFood_FishSalmon_01")
				updateIngred("T_IngFood_FishCod_01", "pf_IngFood_FishCod_01")
				updateIngred("T_IngFood_FishChrysophant_01", "pf_IngFood_FishChrysophant_01")
			end

			FishingOATR.value = activeLibraries
		else
			mwse.log("[%s] Warning, Fishing-Expansion.esp not found.", modPrefix)
		end

		if ( skillModule ) then

			event.register("OtherSkills:Ready", onSkillReady) -- Register the Skill with the UI (Fires same as loaded)
			event.register("simulate", onFrame) -- This will take care of keeping the skill in sync with the mod's CastCount
		else
			mwse.log("[%s] Warning, Merlord's skillModule not found.", modPrefix)
		end
	else
		mwse.log("[%s] Error, Fish With Fishing Poles Fishing.esp not found.", modPrefix)
	end

	mwse.log("[%s] Initialized.", modPrefix)
end

event.register("initialized", initialized)
