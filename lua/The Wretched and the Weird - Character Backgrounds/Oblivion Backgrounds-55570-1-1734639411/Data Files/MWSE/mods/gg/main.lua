local namiraTimer

local function isDayTime()
    local hour = tes3.worldController.hour.value
    local wc = tes3.worldController.weatherController

    if (hour >= wc.sunriseHour and hour < wc.sunsetHour) then
        return true
    else
        return false
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