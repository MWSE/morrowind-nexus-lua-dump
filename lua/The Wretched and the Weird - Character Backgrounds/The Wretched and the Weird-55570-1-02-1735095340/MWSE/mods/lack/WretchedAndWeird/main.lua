
local drinkTimer
local SOBER_TIME = 21600 -- If you play with withdrawal for 6 hrs, you no longer need drinks

local drinks = { "mead", "ale", "beer", "brandy", "bourbon", "liquor", "wine", "whiskey", "local_brew", "vodka", "grog", "booze",
"dri_musa", "dri_sillapi", "dri_yamuz", "punavit", "t_imp_drink", "t_nor_drink", "drink_aibe", "drink_sift", "t_we_drink", "t_yne_drink"}

local function subString(arr, x)
	for _, v in pairs(arr) do
		local s = v:lower()
		x = x:lower()
		if string.find(x, s) then
			return true 
		end
	end
	return false
end

-- Check whether the player is meaningfully naked -- counts equipped items other than jewelry, weapons, ammo
local function isNaked()
	-- the slots we care about
	local armorSlots = {0,1,2,3,4,6,7,9}
	local clothingSlots = {0,2,4}

	for _, s in ipairs(armorSlots) do
		if ( tes3.getEquippedItem({ actor = tes3.mobilePlayer, objectType = tes3.objectType.armor, slot = s})) then
			return false
		end
	end

	for _, s in ipairs(clothingSlots) do
		if ( tes3.getEquippedItem({ actor = tes3.mobilePlayer, objectType = tes3.objectType.clothing, slot = s})) then
			return false
		end
	end

	return true
end

-- Hides the training button. Event registered for "Autodidact" and "Wretch" backgrounds.
local function hideTrainingButton(e)
	local menu = tes3ui.findMenu("MenuDialog")

	if ( menu ) then
		local button = menu:findChild("MenuDialog_service_training")
		if ( button ) then
			button.visible = false
		end		
	end	
end

-- Removes all items, for "Wretch" and "Deprived" backgrounds
local function removeAllItems()
	local stacks = tes3.mobilePlayer.inventory

	for _, stack in ipairs(stacks) do
		tes3.removeItem({
			reference = tes3.player,
			item = stack.object,
			count = stack.count
		})
	end
end

-- Register the hide training button function
local function autodidactCallback()
	event.register(tes3.event.uiEvent, hideTrainingButton)
end

-- For wretch. Check if the skill is higher than 15
local function getLowerSkill(n)
	local lower = tes3.mobilePlayer:getSkillStatistic(n)
	local i = lower.base
	if ( lower.base >= 15) then
		i = 15
	end
	return i
end

-- For wretch, registered to levelUp event. Check if we have reached level 20 each time we level up, and if we have, let the player choose if they want the blessing.
local function wretchBlessing(e)
	if (e.level == 20) then
		tes3.messageBox({
			message = "You have turned your life around. You are no longer a worthless wretch, and you feel a burgeoning sense of pride and achievement. The gods smile on your accomplishment, and wish to bestow a blessing upon you (5x Fortify Maximum Magicka, 30pt Fortify Attack, 100pt Fortify Unarmored). Do you accept?",
			buttons = {"I have earned this!", "I am not worthy."},
			showInDialog = false,
			callback = function(e)
				if e.button == 0 then
					tes3.addSpell({ reference = tes3.player, spell = "lack_ww_WretchBlessing"})
				else
					tes3.messageBox({message = "You have gotten this far on your own. You will continue to improve yourself without the help of the gods.", buttons = {"OK"}})
				end
			end
		})
	end
end

-- Set all skills to 15 or lower. Set all attributes to 10, or 10 + ability/birthsign bonuses
local function wretchDoOnce()
	local index = 0

	removeAllItems()

	-- Calculate the differences between the raw values and the base so we know how much of an ability bonus to leave the player with
	local diff = { (tes3.mobilePlayer.strength.base - tes3.player.object.attributes[1]), (tes3.mobilePlayer.intelligence.base - tes3.player.object.attributes[2])
    , (tes3.mobilePlayer.willpower.base - tes3.player.object.attributes[3]), (tes3.mobilePlayer.agility.base - tes3.player.object.attributes[4]), (tes3.mobilePlayer.speed.base - tes3.player.object.attributes[5]),
    (tes3.mobilePlayer.endurance.base - tes3.player.object.attributes[6]), (tes3.mobilePlayer.personality.base - tes3.player.object.attributes[7]), (tes3.mobilePlayer.luck.base - tes3.player.object.attributes[8])}

	while ( index < 8 ) do
		tes3.setStatistic({
			reference = tes3.player,
			attribute = index,
			value = ( 10 + diff[index+1]),
		})
		index = index + 1
	end

	index = 0
	while ( index < 27 ) do
		tes3.setStatistic({
			reference = tes3.player,
			skill = index,
			value = ( getLowerSkill(index) ),
		})
		index = index + 1
	end
end

-- Register training block and level 20 check events
local function wretchCallback()
	event.register(tes3.event.uiEvent, hideTrainingButton)
	event.register(tes3.event.levelUp, wretchBlessing)
end

local function extraPlanarDoOnce()
	tes3.modStatistic({
		reference = tes3.player,
		skill = tes3.skill.conjuration,
		value = 10
	})
	tes3.modStatistic({
		reference = tes3.player,
		skill = tes3.skill.acrobatics,
		value = -5
	})
	tes3.modStatistic({
		reference = tes3.player,
		skill = tes3.skill.alteration,
		value = -5
	})
end

-- For "bad with people" background. Reduce personality back to 0 every level, if the player tried to raise it.
local function limitPersonality()
	tes3.setStatistic({
		reference = tes3.player,
		attribute = tes3.attribute.personality,
		value = 0
	})
end

local function badPeopleDoOnce()
	tes3.setStatistic({
		reference = tes3.player,
		attribute = tes3.attribute.personality,
		value = 0
	})
	tes3.modStatistic({
		reference = tes3.player,
		skill = tes3.skill.alchemy,
		value = 10
	})
	tes3.modStatistic({
		reference = tes3.player,
		skill = tes3.skill.enchant,
		value = 10
	})
	tes3.modStatistic({
		reference = tes3.player,
		skill = tes3.skill.armorer,
		value = 10
	})
	tes3.modStatistic({
		reference = tes3.player,
		skill = tes3.skill.security,
		value = 10
	})
end

local function badPeopleCallback()
	event.register(tes3.event.levelUp, limitPersonality)
end

-- Take all items and debuff attributes/skills. Not as harshly as wretch
local function deprivedDoOnce()

	local index = 0

	removeAllItems()

	while ( index < 8 ) do
		tes3.modStatistic({
			reference = tes3.player,
			attribute = index,
			value = -10,
			limit = true
		})
		index = index + 1
	end

	index = 0
	while ( index < 27 ) do
		tes3.modStatistic({
			reference = tes3.player,
			skill = index,
			value = -10,
			limit = true
		})
		index = index + 1
	end

end

-- For bog witch. For player-casted spells, check if they are poison, and give the player back half the magicka.
local function bogWitchPoisonBuff(e)

	if (e.caster == tes3.player) then
		local isPoison = true
		for _, effect in ipairs(e.source.effects) do
			if ( not ( effect.id == tes3.effect.poison ) ) then
				if ( effect.id >= 0 ) then
					isPoison = false
					break
				end
			end
		end
		if ( isPoison ) then
			tes3.modStatistic({
				reference = tes3.mobilePlayer,
				name = "magicka",
				current = ( e.source.magickaCost / 2 ),
				limitToBase = true
			})
		end
	end
end

local function bogWitchDoOnce()
	tes3.modStatistic({
		reference = tes3.player,
		skill = tes3.skill.alchemy,
		value = 10
	})
	tes3.modStatistic({
		reference = tes3.player,
		attribute = tes3.attribute.endurance,
		value = -10
	})
	tes3.modStatistic({
		reference = tes3.player,
		attribute = tes3.attribute.personality,
		value = -10
	})
	tes3.addSpell({
		reference = tes3.player,
		spell = "poison"
	})

	if (tes3.isModActive("Tamriel_Data.esm")) then
		tes3.equip({
			reference = tes3.player,
			item = "T_Bre_Ep_HatWizard_01",
			addItem = true
		})
		tes3.equip({
			reference = tes3.player,
			item = "T_Bre_Ep_RobeWizard_01",
			addItem = true
		})
	else
		tes3.equip({
			reference = tes3.player,
			item = "lack_ww_WitchHat",
			addItem = true
		})
	end
end

local function bogWitchCallback()
	event.register(tes3.event.spellCasted, bogWitchPoisonBuff)
end

-- For blood mage. For player-casted spells, check if they are damage health, and give the player back half the magicka.
local function bloodMagicBuff(e)

	if (e.caster == tes3.player) then
		local isBlood = true
		for _, effect in ipairs(e.source.effects) do
			if ( not ( effect.id == tes3.effect.damageHealth ) ) then
				if ( effect.id >= 0 ) then
					isBlood = false
					break
				end
			end
		end
		if ( isBlood ) then
			--tes3.messageBox("blood")
			tes3.modStatistic({
				reference = tes3.mobilePlayer,
				name = "magicka",
				current = ( e.source.magickaCost / 2 ),
				limitToBase = true
			})
		end
	end

end

local function bloodMageDoOnce()
	tes3.addSpell({
		reference = tes3.player,
		spell = "lack_ww_BloodMageWeaknesses"
	})
	tes3.addSpell({
		reference = tes3.player,
		spell = "lack_ww_BloodBolt"
	})
end

local function bloodMageCallback()
	event.register(tes3.event.spellCasted, bloodMagicBuff)
end

local function drinkTimerCallback()

	if tes3.player.data.TheWretchedAndTheWeird.recovered < SOBER_TIME then
		tes3.player.data.TheWretchedAndTheWeird.recovered = tes3.player.data.TheWretchedAndTheWeird.recovered + 5

		if ( tes3.player.data.TheWretchedAndTheWeird.recovered >= SOBER_TIME ) then
			tes3.messageBox({message = "It feels like ages since you've had a drink, but strangely, you don't feel compelled to find one. You will no longer experience alcohol withdrawal.", buttons = {"I did it!"}})
			tes3.removeSpell({
				reference = tes3.player,
				spell = "lack_ww_AlcoholWithdrawal"
			})
		end

	else
		return
	end

	local currDay = tes3.findGlobal("DaysPassed").value
	local currHour = tes3.findGlobal("GameHour").value
		
	local daysInHours = ( currDay - tes3.player.data.TheWretchedAndTheWeird.drinkDay ) * 24
	local hours = currHour - tes3.player.data.TheWretchedAndTheWeird.drinkHour
	local hoursPassed
	
	hoursPassed = daysInHours + hours

	local prev = tes3.player.data.TheWretchedAndTheWeird.hoursSinceLast

	tes3.player.data.TheWretchedAndTheWeird.hoursSinceLast = hoursPassed + tes3.player.data.TheWretchedAndTheWeird.hoursSinceLast
	tes3.player.data.TheWretchedAndTheWeird.drinkDay = currDay
	tes3.player.data.TheWretchedAndTheWeird.drinkHour = currHour

	if ( prev < 24 and tes3.player.data.TheWretchedAndTheWeird.hoursSinceLast > 24) then
		tes3.messageBox("You could use a drink...")
		tes3.addSpell({
			reference = tes3.player,
			spell = "lack_ww_AlcoholWithdrawal"
		})
	end
end

local function drinkCheck(e)
	if not (e.item.objectType == tes3.objectType.alchemy) then
		--its not a potion
	--	tes3.messageBox("not potion")
	--	return true
	else
		if subString(drinks, e.item.id) then
			if tes3.player.data.TheWretchedAndTheWeird.recovered < SOBER_TIME then
				tes3.player.data.TheWretchedAndTheWeird.recovered = 0
			end
			if tes3.player.data.TheWretchedAndTheWeird.hoursSinceLast > 24 then
				tes3.removeSpell({
					reference = tes3.player,
					spell = "lack_ww_AlcoholWithdrawal"
				})
				tes3.messageBox("Finally, a drink!")
			end
			tes3.player.data.TheWretchedAndTheWeird.hoursSinceLast = 0
			--return true
		end
	end
end

local function drunkCallBack()
	tes3.player.data.TheWretchedAndTheWeird = tes3.player.data.TheWretchedAndTheWeird or {}
	tes3.player.data.TheWretchedAndTheWeird.recovered = tes3.player.data.TheWretchedAndTheWeird.recovered or 0
	tes3.player.data.TheWretchedAndTheWeird.hoursSinceLast = tes3.player.data.TheWretchedAndTheWeird.hoursSinceLast or 0

	tes3.player.data.TheWretchedAndTheWeird.drinkHour = tes3.player.data.TheWretchedAndTheWeird.drinkHour or tes3.findGlobal("GameHour").value
	tes3.player.data.TheWretchedAndTheWeird.drinkDay = tes3.player.data.TheWretchedAndTheWeird.drinkDay or tes3.findGlobal("DaysPassed").value

	if drinkTimer then
		drinkTimer:resume()
	else
		if tes3.player.data.TheWretchedAndTheWeird.recovered < SOBER_TIME then
			drinkTimer = timer.start({ duration = 5, callback = drinkTimerCallback, type = timer.simulate, iterations = -1 })
		end
	end

	event.register(tes3.event.equip, drinkCheck)
end

local function drunkDoOnce()
	tes3.modStatistic({
		reference = tes3.player,
		attribute = tes3.attribute.endurance,
		value = 15
	})
end

local function checkNaked()
	local wasClothed = tes3.hasSpell ({
		reference = tes3.player,
		spell = "lack_ww_Nudist"
	})

	if isNaked() then
		if (wasClothed) then
			tes3.removeSpell ({
				reference = tes3.player,
				spell = "lack_ww_Nudist"
			})
			tes3.messageBox("You feel liberated after removing your clothes!")
		end
	else
		if not wasClothed then
			tes3.addSpell ({
				reference = tes3.player,
				spell = "lack_ww_Nudist"
			})
			tes3.messageBox("These clothes feel so stifling...")
		end
	end
end

local function nudistCallback()
	event.register(tes3.event.equipped, checkNaked)
	event.register(tes3.event.unequipped, checkNaked)
end

local function nudistDoOnce()
	checkNaked()
	tes3.addSpell({
		reference = tes3.player,
		spell = "lack_ww_NudistBuff"
	})
end

--[[ local function serialKillerDoOnce()
end

local function serialKillerCallback()
end ]]

-- unregister any background-related events so they don't persist through different saves
local function clearEvents()

	--tes3.messageBox("clearing")
	if ( drinkTimer ) then
		drinkTimer:pause()
	end

	event.unregister(tes3.event.spellCasted, bloodMagicBuff)
	event.unregister(tes3.event.spellCasted, bogWitchPoisonBuff)
	event.unregister(tes3.event.uiEvent, hideTrainingButton)
	event.unregister(tes3.event.levelUp, wretchBlessing)
	event.unregister(tes3.event.levelUp, limitPersonality)
	event.unregister(tes3.event.equip, drinkCheck)
	event.unregister(tes3.event.equipped, checkNaked)
	event.unregister(tes3.event.unequipped, checkNaked)

end

local function initialized()

	if not tes3.isModActive("TheWretchedAndTheWeird.esp") then
		tes3.messageBox("Enable Wretched and Weird esp to play weird backgrounds.")
		return
	end

	local interop = require("mer.characterBackgrounds.interop")
	local autodidact = {
		id = "autodidact",
		name = "Autodidact",
		description = "You are entirely self-taught. Your independent way of thinking has sharpened your mind (+10 Intelligence), but you find it nearly impossible to learn from others (training from NPCs is permanently disabled).",
		doOnce = function()
			--Only called once, when the background is activated
			tes3.modStatistic({
				reference = tes3.player,
				attribute = tes3.attribute.intelligence,
				value = 10
			})
			end,
		callback = autodidactCallback
		--This function is called when BG is activated and during onLoad event
	}
	interop.addBackground(autodidact)

	local wretch = {
		id = "wretch",
		name = "Wretch",
		description = "Worthless. That is what you've been called all your life. You are weak, stupid, and unpleasant to look upon (all stats set to 10). You have never been trained in any useful profession (skills set to 15 or lower), and lack the capacity to learn from others (training from NPCs is permanently disabled). You have no belongings, you do not have a single coin to your name, and you've been dumped into Morrowind without a stitch of clothing (inventory is completely emptied). It will take monumental effort to overcome these challenges, but if you do, you may blossom into something truly great (special abilities unlocked if you survive to level 20).",
		doOnce = wretchDoOnce,
		callback = wretchCallback
	}
	interop.addBackground(wretch)

	local deprived = {
		id = "deprived",
		name = "Deprived",
		description = "Poverty and deprivation have been your lifelong companions. You have no possessions, and the years of want have weakened you greatly (all skills and attributes reduced by 10).",
		doOnce = deprivedDoOnce
	}
	interop.addBackground(deprived)

	local extraPlanar = {
		id = "extraPlanar",
		name = "Born on Another Plane",
		description = "Mundus was not the first world you laid eyes upon. You were born in another dimension, and some of your youth was spent in a foreign reality. This has given you an innate talent in communicating across the planes (+10 Conjuration), but you never quite got used to the physics of Nirn (-5 Acrobatics and Alteration).",
		doOnce = extraPlanarDoOnce
	}
	interop.addBackground(extraPlanar)

	local badWithPeople = {
		id = "badWithPeople",
		name = "Bad with People",
		description = "People skills have never come naturally to you. Almost every social interaction feels like a struggle (Personality is set to 0 and cannot be increased with level or birthsign), but you have an affinity for working with inanimate objects (+10 Alchemy, Enchant, Security, and Armorer)",
		doOnce = badPeopleDoOnce,
		callback = badPeopleCallback
	}
	interop.addBackground(badWithPeople)

	local bogWitch = {
		id = "bogWitch",
		name = "Bog Witch",
		description = "Eye of newt and toe of frog, wool of bat and tongue of dog! You are a mysterious bog witch. Your brews are the stuff of legend (Alchemy +10), and " ..
		"you are a master of a swampy sort of magic (spells using only poison effects recoup half their magicka cost when cast). " ..
		"However, a lifetime of breathing swamp gas has left you somewhat frail (Endurance -10), and people seem unnerved by your tendency to cackle (Personality -10).",
		doOnce = bogWitchDoOnce,
		callback = bogWitchCallback
	}
	interop.addBackground(bogWitch)

	local bloodMage = {
		id = "bloodMage",
		name = "Blood Mage",
		description = "You are a diabolical Blood Mage. You've studied techniques to directly harm the life force of your victims " ..
		"rather than using elemental magic (spells using only damage health effects recoup half their magicka cost when cast). " ..
		"Years of self-experimentation with your own blood has left you with some vulnerabilities, however (20% Weakness to Magicka).",
		doOnce = bloodMageDoOnce,
		callback = bloodMageCallback
	}
	interop.addBackground(bloodMage)

	local drunk = {
		id = "drunk",
		name = "Drunkard",
		description = "For as long as you can remember (which admittedly isn't very long), you've needed a drink to get through the working day." .. 
		" You've got a strong stomach (Endurance +15), but on days where you can't get a drink your hands shake (-30 Agility) and you feel awful (fatigue debuff)." .. 
		" You could probably kick the habit if you endured the withdrawal long enough, but it would be tough.",
		doOnce = drunkDoOnce,
		callback = drunkCallBack
	}
	interop.addBackground(drunk)

	local nudist = {
		id = "nudist",
		name = "Nudist",
		description = "It is natural! You've always found clothing and armor stifling, and for most of your life you've avoided wearing clothing unless absolutely necessary." .. 
		" Your lack of attire makes you extremely light on your feet (+75 Unarmored ability), but most clothing makes you feel unbearably stifled (-30 Agility, Personality and Speed when clothed)" .. 
		" You do, however, tolerate footwear at times where terrain is too rough to go barefoot, and sometimes you adorn your bare form with tasteful accessories (shoes, boots, skirts, gloves, belts, and jewelry do not trigger debuff).",
		doOnce = nudistDoOnce,
		callback = nudistCallback
	}
	interop.addBackground(nudist)

--[[ 	local serialKiller = {
		id = "serialKiller",
		name = "Serial Killer",
		description = 
	} ]]

	event.register(tes3.event.loaded, clearEvents, { priority = 99 })
	print("[Wretched and Weird] Wretched and Weird Backgrounds Initialized")
	
end

event.register(tes3.event.initialized, initialized)