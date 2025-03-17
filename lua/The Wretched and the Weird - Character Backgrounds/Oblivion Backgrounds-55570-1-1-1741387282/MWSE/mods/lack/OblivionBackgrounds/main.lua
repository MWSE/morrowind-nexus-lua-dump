local namiraTimer

--items azura doesnt let you use
local blockedShrines = {
	["Furn_imp_altar_cure_01"] = true,
	["Furn_shrine_aralor_cure_01"] = true,
	["Furn_shrine_delyn_cure_01"] = true,
	["Furn_shrine_felms_cure_01"] = true,
	["Furn_shrine_llothis_cure_01"] = true,
	["Furn_shrine_meris_cure_01"] = true,
	["Furn_shrine_Nerevar_cure_01"] = true,
	["Furn_shrine_Olms_cure_01"] = true,
	["Furn_shrine_Rilm_cure_01"] = true,
	["Furn_shrine_Roris_cure_01"] = true,
	["Furn_shrine_Seryn_cure_01"] = true,
	["Furn_shrine_Tribunal_cure_01"] = true,
	["Furn_shrine_Veloth_cure_01"] = true,
	["Furn_shrine_Vivec_cure_01"] = true,
	["T_De_Furn_ShrineAkatosh"] = true,
	["T_De_Furn_ShrineArkay"] = true,
	["T_De_Furn_ShrineDib"] = true,
	["T_De_Furn_ShrineJul"] = true,
	["T_De_Furn_ShrineKyn"] = true,
	["T_De_Furn_ShrineMara"] = true,
	["T_De_Furn_ShrineSten"] = true,
	["T_De_Furn_ShrineTal"] = true,
	["T_De_Furn_ShrineZen"] = true,
	["T_De_SetHla_AltarAkatosh_01"] = true,
	["T_De_SetHla_AltarArkay_01"] = true,
	["T_De_SetHla_AltarDibella_01"] = true,
	["T_De_SetHla_AltarDivines_01"] = true,
	["T_De_SetHla_AltarDivines_02"] = true,
	["T_De_SetHla_AltarJulianos_01"] = true,
	["T_De_SetHla_AltarKynareth_01"] = true,
	["T_De_SetHla_AltarMara_01"] = true,
	["T_De_SetHla_AltarStendarr_01"] = true,
	["T_De_SetHla_AltarTalos_01"] = true,
	["T_De_SetHla_AltarZenithar_01"] = true,
	["T_De_Var_ShrineAlmaMercy_01"] = true,
	["T_De_Var_ShrineOrdinator_01"] = true,
	["T_De_Var_ShrineSothaMastery_01"] = true,
	["T_De_Var_ShrineTribunal_02"] = true,
	["T_De_Var_ShrineTribunal_03"] = true,
	["T_Imp_Legion_AltarCure_01"] = true,
	["T_Imp_Set_Shrine_Alessia01"] = true,
	["T_Imp_Set_Shrine_Clavicus"] = true,
	["T_Imp_Set_Shrine_Emp0"] = true,
	["T_Imp_Set_Shrine_Morihaus"] = true,
	["T_Imp_Set_Shrine_Pelinal"] = true,
	["T_Imp_Set_Shrine_Reman"] = true,
	["T_Imp_Set_Shrine_SaintArt_01"] = true,
	["T_Imp_Set_Shrine_SaintArt_02"] = true,
	["T_Imp_Set_Shrine_SaintArt_03"] = true,
	["T_Imp_Set_Shrine_SaintArt_04"] = true,
	["T_Imp_Set_Shrine_SaintArt_05"] = true,
	["T_Imp_Set_Shrine_SaintArt_06"] = true,
	["T_Imp_Set_Shrine_SaintArt_07"] = true,
	["T_Imp_Set_Shrine_SaintArt_08"] = true,
	["T_Imp_Set_Shrine_SaintColo_01"] = true,
	["T_Imp_Set_Shrine_SaintColo_02"] = true,
	["T_Imp_Set_Shrine_SaintColo_03"] = true,
	["T_Imp_Set_Shrine_SaintColo_04"] = true,
	["T_Imp_Set_Shrine_SaintColo_05"] = true,
	["T_Imp_Set_Shrine_SaintColo_06"] = true,
	["T_Imp_Set_Shrine_SaintColo_07"] = true,
	["T_Imp_Set_Shrine_SaintColo_08"] = true,
	["T_Imp_Set_Shrine_SaintEmp_01"] = true,
	["T_Imp_Set_Shrine_SaintEmp_02"] = true,
	["T_Imp_Set_Shrine_SaintEmp_03"] = true,
	["T_Imp_Set_Shrine_SaintEmp_04"] = true,
	["T_Imp_Set_Shrine_SaintEmp_05"] = true,
	["T_Imp_Set_Shrine_SaintEmp_06"] = true,
	["T_Imp_Set_Shrine_SaintEmp_07"] = true,
	["T_Imp_Set_Shrine_SaintHealer_01"] = true,
	["T_Imp_Set_Shrine_SaintHealer_02"] = true,
	["T_Imp_Set_Shrine_SaintHealer_03"] = true,
	["T_Imp_Set_Shrine_SaintHealer_04"] = true,
	["T_Imp_Set_Shrine_SaintHealer_05"] = true,
	["T_Imp_Set_Shrine_SaintHealer_06"] = true,
	["T_Imp_Set_Shrine_SaintHearth_01"] = true,
	["T_Imp_Set_Shrine_SaintHearth_02"] = true,
	["T_Imp_Set_Shrine_SaintHearth_03"] = true,
	["T_Imp_Set_Shrine_SaintHearth_04"] = true,
	["T_Imp_Set_Shrine_SaintHearth_05"] = true,
	["T_Imp_Set_Shrine_SaintLaw_01"] = true,
	["T_Imp_Set_Shrine_SaintLaw_02"] = true,
	["T_Imp_Set_Shrine_SaintLaw_03"] = true,
	["T_Imp_Set_Shrine_SaintLaw_04"] = true,
	["T_Imp_Set_Shrine_SaintLaw_05"] = true,
	["T_Imp_Set_Shrine_SaintLaw_06"] = true,
	["T_Imp_Set_Shrine_SaintLuck_01"] = true,
	["T_Imp_Set_Shrine_SaintLuck_02"] = true,
	["T_Imp_Set_Shrine_SaintLuck_03"] = true,
	["T_Imp_Set_Shrine_SaintLuck_04"] = true,
	["T_Imp_Set_Shrine_SaintLuck_05"] = true,
	["T_Imp_Set_Shrine_SaintLuck_06"] = true,
	["T_Imp_Set_Shrine_SaintLuck_07"] = true,
	["T_Imp_Set_Shrine_SaintProph_01"] = true,
	["T_Imp_Set_Shrine_SaintProph_02"] = true,
	["T_Imp_Set_Shrine_SaintProph_03"] = true,
	["T_Imp_Set_Shrine_SaintProph_04"] = true,
	["T_Imp_Set_Shrine_SaintProph_05"] = true,
	["T_Imp_Set_Shrine_SaintProph_06"] = true,
	["T_Imp_Set_Shrine_SaintProph_07"] = true,
	["T_Imp_Set_Shrine_SaintTeach_01"] = true,
	["T_Imp_Set_Shrine_SaintTeach_02"] = true,
	["T_Imp_Set_Shrine_SaintTeach_03"] = true,
	["T_Imp_Set_Shrine_SaintTeach_04"] = true,
	["T_Imp_Set_Shrine_SaintTeach_05"] = true,
	["T_Imp_Set_Shrine_SaintTeach_06"] = true,
	["T_Imp_Set_Shrine_SaintTrade_01"] = true,
	["T_Imp_Set_Shrine_SaintTrade_02"] = true,
	["T_Imp_Set_Shrine_SaintTrade_03"] = true,
	["T_Imp_Set_Shrine_SaintTrade_04"] = true,
	["T_Imp_Set_Shrine_SaintTrade_05"] = true,
	["T_Imp_Set_Shrine_SaintTrade_06"] = true,
	["T_Imp_Set_Shrine_SaintTrade_07"] = true,
	["T_Imp_Set_Shrine_SaintTrade_08"] = true,
	["T_Imp_Set_Shrine_SaintWar_01"] = true,
	["T_Imp_Set_Shrine_SaintWar_02"] = true,
	["T_Imp_Set_Shrine_SaintWar_03"] = true,
	["T_Imp_Set_Shrine_SaintWar_04"] = true,
	["T_Imp_Set_Shrine_SaintWar_05"] = true,
	["T_Imp_Set_Shrine_SaintWar_06"] = true,
	["T_Imp_Set_Shrine_SaintWar_07"] = true,
	["T_Imp_Set_Shrine_SaintWar_08"] = true,
	["T_Imp_Set_Shrine_SaintWar_09"] = true,
	["T_Imp_Set_Shrine_SaintWork_01"] = true,
	["T_Imp_Set_Shrine_SaintWork_02"] = true,
	["T_Imp_Set_Shrine_SaintWork_03"] = true,
	["T_Imp_Set_Shrine_SaintWork_04"] = true,
	["T_Imp_Set_Shrine_SaintWork_05"] = true,
	["T_Imp_Set_WayshrineAkatosh_01"] = true,
	["T_Imp_Set_WayshrineArkay_01"] = true,
	["T_Imp_Set_WayshrineDibella_01"] = true,
	["T_Imp_Set_WayshrineJulianos_01"] = true,
	["T_Imp_Set_WayshrineKynareth_01"] = true,
	["T_Imp_Set_WayshrineMara_01"] = true,
	["T_Imp_Set_WayshrineStendarr_01"] = true,
	["T_Imp_Set_WayshrineTiber_01"] = true,
	["T_Imp_Set_WayshrineZenithar_01"] = true,
	["T_Imp_SetChapel_AltarCure_01"] = true,
	["T_Imp_SetChapel_AltarCure_02"] = true,
	["T_Imp_SetChapel_AltarCure_03"] = true,
	["T_Imp_SetChapel_AltarCure_04"] = true,
	["T_Imp_SetChapel_AltarCure_05"] = true,
	["PC_m1_ShrineAlessia"] = true,
	["PC_m1_ShrineAmiel"] = true,
	["PC_m1_ShrineMorachellis"] = true,
	["PC_m1_WayshrineArkay"] = true
}

--[[ local function subString(arr, x)
	for _, v in pairs(arr) do
		local s = v:lower()
		x = x:lower()
		if string.find(x, s) then
			return true 
		end
	end
	return false
end ]]

local function isDayTime()
    local hour = tes3.worldController.hour.value
    local wc = tes3.worldController.weatherController

    if (hour >= wc.sunriseHour and hour < wc.sunsetHour) then
        return true
    else
        return false
    end
end

-- block shrine use
local function azuraShrineBlock(e)
    if (e.activator == tes3.player) then
		if (e.target and e.target.object) then
			if blockedShrines[e.target.object.id] then
		        tes3.messageBox("Azura prevents you from appealing to this heathen shrine.")
				e.block = true
			end
		end
    end
end

-- Hides the training button.
local function hideTrainingButton(e)
	local menu = tes3ui.findMenu("MenuDialog")

	if ( menu ) then
		local button = menu:findChild("MenuDialog_service_training")
		if ( button ) then
			button.visible = false
		end		
	end	
end

local function dayblind(e)
	if ( not e.cell.isInterior ) then
		if ( isDayTime() ) then
			tes3.addSpell({
				reference = tes3.player,
				spell = "lack_gg_Dayblind"
			})
		end
	else
		tes3.removeSpell({
			reference = tes3.player,
			spell = "lack_gg_Dayblind"
		})
	end
end

local function checkCancelDayblind()
	if (tes3.menuMode()) then
		return
	end

	if ( not tes3.mobilePlayer.cell.isInterior ) then
		if ( isDayTime() ) then
			tes3.addSpell({
				reference = tes3.player,
				spell = "lack_gg_Dayblind"
			})
		else
			tes3.removeSpell({
				reference = tes3.player,
				spell = "lack_gg_Dayblind"
			})
		end
	else
		tes3.removeSpell({
			reference = tes3.player,
			spell = "lack_gg_Dayblind"
		})
	end
end

local function meridiaUndeadBlock(e)
	if (e.caster == tes3.player) then
		local isUndead = false
		for _, effect in ipairs(e.source.effects) do
			if ( ( effect.id >= 106 ) and ( effect.id <= 110 ) ) then -- ids in undead-summoning range 
				isUndead = true
			end
		end
		if ( isUndead ) then
			e.castChance = 0
			tes3.messageBox("Your connection to Meridia prevents you from calling on the undead.")
		end
	end
end

local function diseaseBlock(e)
	if (e.caster == tes3.player) then
		if (e.source.id == "lack_gg_PeryiteAttack") or (e.source.id == "lack_gg_PeryiteTask") then
			if not (tes3.mobilePlayer.isDiseased) then
				e.castChance = 0
				tes3.messageBox("You cannot call on Peryite's power unless you are diseased.")
			end
		end
	end
end

local function checkMoon()
	if (tes3.menuMode()) then
		return
	end

	local masser = tes3.worldController.weatherController.masser
	local secunda = tes3.worldController.weatherController.secunda

	--tes3.messageBox("Massser " .. masser.phase)
	--tes3.messageBox("Secunda " .. secunda.phase)
	local fullmoon = false

	if (masser.phase == 4) or ( secunda.phase == 4 ) then
		fullmoon = true
	end

	if not fullmoon then
		if tes3.hasSpell({reference = tes3.player, spell = "lack_gg_SheoWhispers"}) then
			tes3.messageBox("The shadowed moons quiet the voices...")
			tes3.removeSpell({
				reference = tes3.player,
				spell = "lack_gg_SheoWhispers"
			})
		end
	else
		if not tes3.hasSpell({reference = tes3.player, spell = "lack_gg_SheoWhispers"}) then
			tes3.messageBox("You begin to hear voices...")
			tes3.addSpell({
				reference = tes3.player,
				spell = "lack_gg_SheoWhispers"
			})
		end
	end
end

-- register pray blocking
local function azuraCallback()
	event.register(tes3.event.activate, azuraShrineBlock)
end

-- Register training block
local function boethiahCallback()
	event.register(tes3.event.uiEvent, hideTrainingButton)
end

local function namiraCallback()
	if ( namiraTimer ) then
		namiraTimer:resume()
	else
		namiraTimer = timer.start({
			duration = 5,
			callback = checkCancelDayblind,
			iterations = -1
		})
	end

	event.register(tes3.event.cellChanged, dayblind)
end

local function meridiaCallback()
	event.register(tes3.event.spellCast, meridiaUndeadBlock)
end

local function peryiteCallback()
	event.register(tes3.event.spellCast, diseaseBlock)
end

local function sheoCallback()
	namiraTimer = timer.start({
		duration = 5,
		callback = checkMoon,
		iterations = -1
	})
end

local function unregEvents()
	if ( namiraTimer ) then
		namiraTimer:pause()
	end
	event.unregister(tes3.event.activate, azuraShrineBlock)
	event.unregister(tes3.event.uiEvent, hideTrainingButton)
	event.unregister(tes3.event.cellChanged, dayblind)
	event.unregister(tes3.event.spellCast, meridiaUndeadBlock)
	event.unregister(tes3.event.spellCast, diseaseBlock)
end

local function initialized()

	if not tes3.isModActive("gg_OblivionBackgrounds.esp") then
		tes3.messageBox("Enable Oblivion Backgrounds esp.")
		return
	end

	local interop = require("mer.characterBackgrounds.interop")

	local twilight = {
		id = "twilight",
		name = "Bathed in Twilight",
		description = "You were born in the painted shades of Moonshadow, the garden of Azura. As like art, you are shaped in beauty and wonder (+10 Personality, +5 Willpower). Your experience in the overwhelming sea painted in Her image lets you see beyond surfaces (+5 Mysticism, +5 Conjuration, Detect Power). The constant perfume and song has hazed your mind (-5 Intelligence) and weakened your fist (-5 Strength, -5 Agility). Despite your absence, Azura still sees you as a light in her garden (cannot use religious shrines), and eagerly awaits your return.",
		doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.mysticism,
				value = 5
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.conjuration,
				value = 5
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.willpower,
				value = 5
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.personality,
				value = 10
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.intelligence,
				value = -5
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.strength,
				value = -5
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.agility,
				value = -5
			})
			tes3.addSpell({
				reference = tes3.player,
				spell = "lack_gg_liminalsight"
			})
			end,
			callback = azuraCallback
	}
	interop.addBackground(twilight)

	local weaver = {
		id = "weaver",
		name = "Weaver",
		description = "You were formed in the treacherous Spiral Skein, the dominion of Mephala. Swathed in falsehoods, your movements are as hidden as your intentions (+10 Sneak, daily Charm power). Your strikes are venomous and made in anonymity (+5 Alchemy, 50% poison resist). Webs beget webs, and your seat within the plots of others has scarred you. (-10 Willpower, -10 Endurance) You persist still, holding onto the knowledge of plots and survival.",
		doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.sneak,
				value = 10
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.alchemy,
				value = 5
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.endurance,
				value = -10
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.willpower,
				value = -10
			})
			tes3.addSpell({
				reference = tes3.player,
				spell = "lack_gg_mephalanvenom"
			})
			tes3.addSpell({
				reference = tes3.player,
				spell = "lack_gg_temptingwhisper"
			})
			end
	}
	interop.addBackground(weaver)

	local mazefaced = {
		id = "mazefaced",
		name = "Maze-Faced",
		description = "You escaped the Labyrinth of Attribution's Share, Boethiah's domain. Your trials have hardened your resolve and skill in combat (+5 Attack, +5 Strength, +5 Endurance), but your scars are clearly worn (-10 Personality, -5 Willpower). You no longer trust others in the pursuit of your own strength (training is disabled), and understand the gifts of deception (Chameleon and Sanctuary power.) ",
		doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.strength,
				value = 5
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.endurance,
				value = 5
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.personality,
				value = -10
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.willpower,
				value = -5
			})
			tes3.addSpell({
				reference = tes3.player,
				spell = "lack_gg_boethianire"
			})
			tes3.addSpell({
				reference = tes3.player,
				spell = "lack_gg_ebonShroud"
			})
			end,
			callback = boethiahCallback
	}
	interop.addBackground(mazefaced)

	local fieldsman = {
		id = "fieldsman",
		name = "Fieldsman",
		description = "You were born in the Fields of Regret, the Plane of Clavicus Vile. You are adept at convincing others to take questionable deals (+5 to Mercantile and Speechcraft), ".. 
		"but you struggle to resist making a dodgy bargain yourself (-10 Willpower).",
		doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.mercantile,
				value = 5
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.speechcraft,
				value = 5
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.willpower,
				value = -10
			})
			end
	}
	interop.addBackground(fieldsman)

	local huntsman = {
		id = "huntsman",
		name = "Huntsman",
		description = "You were born in Hircine's Hunting Grounds, and spent your youth as quarry... and then, as predator. You can smell blood from yards away (25 pt Detect Creature), none can escape your pursuit (+5 Speed), " .. 
		"and you are skilled in all the favored weaponry of huntsmen (+5 Spear and Marksman). Hircine's primal forests did little to prepare you for city life, however (-10 Personality and Intelligence).",
		doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.spear,
				value = 5
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.marksman,
				value = 5
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.speed,
				value = 5
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.personality,
				value = -10
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.intelligence,
				value = -10
			})
			tes3.addSpell({
				reference = tes3.player,
				spell = "lack_gg_Huntsman"
			})
			end
	}
	interop.addBackground(huntsman)

	local deadlander = {
		id = "deadlander",
		name = "Deadlander",
		description = "You were born in the Deadlands, the hellish realm of Mehrunes Dagon. The torturous flames have tempered you into an instrument of death (25% Resist Fire, +5 Destruction, Fire Shield Power) " .. 
		"but you are cannot stand colder climes (50% Weakness to Frost) and are incapable of facial expressions beyond a cruel glower (-15 Personality)",
		doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.destruction,
				value = 5
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.personality,
				value = -15
			})
			tes3.addSpell({
				reference = tes3.player,
				spell = "lack_gg_Deadlander"
			})
			tes3.addSpell({
				reference = tes3.player,
				spell = "lack_gg_DeadlanderFlames"
			})
			end
	}
	interop.addBackground(deadlander)

	local reveler = {
		id = "reveler",
		name = "Reveler",
		description = "You were born in Sanguine's Realms of Revelry, and spent your life as a celebrant at the Prince's eternal parties." .. 
		" You are fun to be around (+5 Personality and Speechcraft) and can certainly hold your drink (+5 Endurance), but have no ability to resist temptation (-15 Willpower).",
		doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.personality,
				value = 5
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.endurance,
				value = 5
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.willpower,
				value = -15
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.speechcraft,
				value = 5
			})
			end
	}
	interop.addBackground(reveler)

	local shivering = {
		id = "shivering",
		name = "Shivering Islander",
		description = "You were born in the Madgod's Realm. You can still hear Sheogorath's voice at certain times (sound effect during full moons), and other people have a hard time understanding your disordered thoughts " .. 
		" (-10 Speechcraft). You can share your madness with others (once-per-day Frenzy Power), and the constant hallucinations have made you relatively apt at discerning reality from the Madgod's visions (+10 Willpower).",
		doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.willpower,
				value = 10
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.speechcraft,
				value = -10
			})
			tes3.addSpell({
				reference = tes3.player,
				spell = "lack_gg_InfectiousInsanity"
			})
			end,
		callback = sheoCallback
	}
	interop.addBackground(shivering)

	local voidwalker = {
		id = "voidwalker",
		name = "Voidwalker",
		description = "You were born in Namira's dark plane of Oblivion. You never saw daylight until you arrived on Nirn (10 pt Blind when outdoors at daytime), nor did you ever converse with anyone but dark skittering things (-10 Personality and Speechcraft). " .. 
		" You know how to walk in darkness (daily chameleon power), and can befriend vermin and other wretched things (daily calm creature power).",
		doOnce = function()
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.personality,
				value = -10
			})
			tes3.modStatistic({
				reference = tes3.player,
				skill = tes3.skill.speechcraft,
				value = -10
			})
			tes3.addSpell({
				reference = tes3.player,
				spell = "lack_gg_CalmCreature"
			})
			tes3.addSpell({
				reference = tes3.player,
				spell = "lack_gg_ChameleonPower"
			})
			end,
		callback = namiraCallback
	}
	interop.addBackground(voidwalker)

	local coldharbor = {
		id = "coldharbor",
		name = "Spawn of Coldharbor",
		description = "Much of your life was spent in Coldharbor, the plane of the Prince of Domination. The dismal realm left its scars on your body" .. 
		" (100% Weakness to Fire, 25% Resist Frost), but you have learned how to dominate the weak (daily burden/frost damage power).",
		doOnce = function()
			tes3.addSpell({
				reference = tes3.player,
				spell = "lack_gg_ColdHarborChains"
			})
			tes3.addSpell({
				reference = tes3.player,
				spell = "lack_gg_ColdHarborElements"
			})
			end
	}

	interop.addBackground(coldharbor)

	local meridia = {
		id = "meridian",
		name = "Child of Light",
		description = "Much of your life was spent in Meridia's Colored Rooms. Even now you can command the pure light of your home plane (at-will Light and Turn Undead), and you can purify the tainted for a time (powerful daily Command Humanoid), but you cannot tolerate necromancy (summoning undead disabled), " .. 
		"and the brilliant will of the Lady of Light has diminished your own (-20 Willpower).",
		doOnce = function ()
			tes3.addSpell({
				reference = tes3.player,
				spell = "lack_gg_ColoredLights"
			})
			tes3.addSpell({
				reference = tes3.player,
				spell = "lack_gg_GlisterWitch"
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.willpower,
				value = -20
			})
		end,
		callback = meridiaCallback
	}

	interop.addBackground(meridia)

	local peryite = {
		id = "peryite",
		name = "Pestilent One",
		description = "You were formed in the realm of Peryite, the Lord of Pestilence. Your pustulent youth has left you extremely vulnerable to disease (100% Vulnerability to Common and Blight diseases) and physically frail (-5 Strength and Endurance) but, when diseased, you gain access to the Taskmaster's Command (Command Humanoid and Command Creature) " .. 
		"and you can conjure a blighted attack at will.",
		doOnce = function ()
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.strength,
				value = -5
			})
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.endurance,
				value = -5
			})
			tes3.addSpell({
				reference = tes3.player,
				spell = "lack_gg_PeryiteWeakness"
			})
			tes3.addSpell({
				reference = tes3.player,
				spell = "lack_gg_PeryiteAttack"
			})
			tes3.addSpell({
				reference = tes3.player,
				spell = "lack_gg_PeryiteTask"
			})
		end,
		callback = peryiteCallback
	}

	interop.addBackground(peryite)

	event.register(tes3.event.loaded, unregEvents, { priority = 99 })
	print("Oblivion Backgrounds Initialized")
	
end

event.register(tes3.event.initialized, initialized)