local config = require("MWSEVampireOptions.config")

local fakeVampirismSpell
local vampireWaterBreathingSpell

-- MARK: CREATE SPELLS
local function createVampireWaterBreathingSpell()
	vampireWaterBreathingSpell = tes3.createObject({id = 'mwseVA vampire waterbreathing', objectType = tes3.objectType.spell})

	vampireWaterBreathingSpell.name = 'Vampirism'
	local effect = vampireWaterBreathingSpell.effects[1]
	effect.id = 0 -- waterbreathing
	effect.rangeType = 0
	effect.min = 0
	effect.max = 0
	effect.duration = 0
	effect.radius = 0
	effect.skill = -1
	effect.attribute = -1
	vampireWaterBreathingSpell.magickaCost = 0
	vampireWaterBreathingSpell.castType = 1

	return vampireWaterBreathingSpell
end

local function createFakeVampirism()
	fakeVampirismSpell = tes3.createObject({id = 'mwseVA vampire fake', objectType = tes3.objectType.spell})
	fakeVampirismSpell.name = 'Vampirism'	
	local effectSun = fakeVampirismSpell.effects[1]
	effectSun.id = 135 -- sun damage
	effectSun.rangeType = 0
	effectSun.min = 5
	effectSun.max = 5
	effectSun.duration = 0
	effectSun.radius = 0
	effectSun.skill = -1
	effectSun.attribute = -1

	local effectFireWeakness = fakeVampirismSpell.effects[2]
	effectFireWeakness.id = 28 -- weakness to fire
	effectFireWeakness.rangeType = 0
	effectFireWeakness.min = 50
	effectFireWeakness.max = 50
	effectFireWeakness.duration = 0
	effectFireWeakness.radius = 0
	effectFireWeakness.skill = -1
	effectFireWeakness.attribute = -1

	fakeVampirismSpell.magickaCost = 0
	fakeVampirismSpell.castType = 1

	return fakeVampirismSpell
end
-- end Create spells

-- MARK: HELPER FUNCTIONS
local function isPlayerVamp()
	return tes3.findGlobal("PCVampire").value == 1
end

local function isWearingShroud()
	local equippedShroudStack = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.clothing, slot = tes3.clothingSlot.robe })
	return equippedShroudStack and equippedShroudStack.object.id == "T_Dae_UNI_RobeShroud"
end

local function isWearingClosedHelm()
	local equippedHelm = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.armor, slot = tes3.armorSlot.helmet })
	return equippedHelm and equippedHelm.object.isClosedHelmet
end

local function hideVampirism()
	if tes3.hasSpell({ reference = tes3.player, spell = "Vampire Sun Damage"}) then
		tes3.removeSpell({reference = tes3.mobilePlayer, spell = "Vampire Sun Damage", updateGUI = true})
	end
	if not tes3.hasSpell({ reference = tes3.player, spell = fakeVampirismSpell }) and not isWearingShroud() then
		tes3.addSpell({reference = tes3.player, spell = fakeVampirismSpell, updateGUI = true})
	end
end

local function unhideVampirism()
	if not tes3.hasSpell({ reference = tes3.player, spell = "Vampire Sun Damage"}) and not isWearingShroud() then
		tes3.addSpell({reference = tes3.mobilePlayer, spell = "Vampire Sun Damage", updateGUI = true})
	end
	if tes3.hasSpell({ reference = tes3.player, spell = fakeVampirismSpell }) then
		tes3.removeSpell({ reference = tes3.mobilePlayer, spell = "mwseVA vampire fake", updateGUI = true })
	end
end

-- MARK:  HEALING --
local function spellResistCallbackHealing(e)
	if e.target == tes3.player then
		if e.effect.id == 75 then
			e.resistedPercent = 100
		end
	end
end

local function addNoHealingAbility()
	if not event.isRegistered(tes3.event.spellResist, spellResistCallbackHealing) then
		event.register(tes3.event.spellResist, spellResistCallbackHealing)
	end
end

local function removeNoHealingAbility()
	if event.isRegistered(tes3.event.spellResist, spellResistCallbackHealing) then
		event.unregister(tes3.event.spellResist, spellResistCallbackHealing)
	end
end
-- end Healing --

-- MARK: SHROUD --
local function simulateCallbackShroud(e) -- only runs when namira shroud is equipped
	if isWearingShroud() then
		if tes3.mobilePlayer.isRunning then
			if config.helmHides and isWearingClosedHelm() then
				if tes3.hasSpell({ reference = tes3.player, spell = "Vampire Sun Damage"}) then
					tes3.removeSpell({reference = tes3.mobilePlayer, spell = "Vampire Sun Damage", updateGUI = true})
				end
				if not tes3.hasSpell({ reference = tes3.player, spell = fakeVampirismSpell }) then
					tes3.addSpell({ reference = tes3.mobilePlayer, spell = "mwseVA vampire fake", updateGUI = true })
				end
			else
				if not tes3.hasSpell({ reference = tes3.player, spell = "Vampire Sun Damage"}) then
					tes3.addSpell({reference = tes3.mobilePlayer, spell = "Vampire Sun Damage", updateGUI = true})
				end
				if tes3.hasSpell({ reference = tes3.player, spell = fakeVampirismSpell }) then
					tes3.removeSpell({ reference = tes3.mobilePlayer, spell = "mwseVA vampire fake", updateGUI = true })
				end
			end
		else
			if tes3.hasSpell({ reference = tes3.player, spell = fakeVampirismSpell }) then
				tes3.removeSpell({ reference = tes3.mobilePlayer, spell = "mwseVA vampire fake", updateGUI = true })
			end
			if tes3.hasSpell({ reference = tes3.player, spell = "Vampire Sun Damage"}) then
				tes3.removeSpell({reference = tes3.mobilePlayer, spell = "Vampire Sun Damage", updateGUI = true})
			end
		end
	else
		if event.isRegistered(tes3.event.simulate, simulateCallbackShroud) then
			event.unregister(tes3.event.simulate, simulateCallbackShroud)
		end
	end
end

local function equipCallbackShroud(e)
	if e.item.id == 'T_Dae_UNI_RobeShroud' then
		if tes3.hasSpell({ reference = tes3.player, spell = fakeVampirismSpell }) then
			tes3.removeSpell({ reference = tes3.mobilePlayer, spell = "mwseVA vampire fake", updateGUI = true })
		end
		if not event.isRegistered(tes3.event.simulate, simulateCallbackShroud) then
			event.register(tes3.event.simulate, simulateCallbackShroud)
		end
	end
end

local function addShroudAbility()
	if not event.isRegistered(tes3.event.equip, equipCallbackShroud) then
		event.register(tes3.event.equip, equipCallbackShroud)
	end

	if isWearingShroud() then
		if not event.isRegistered(tes3.event.simulate, simulateCallbackShroud) then
			event.register(tes3.event.simulate, simulateCallbackShroud)
		end
	end
end

local function removeShroudAbility()
	if event.isRegistered(tes3.event.equip, equipCallbackShroud) then
		event.unregister(tes3.event.equip, equipCallbackShroud)
	end

	if event.isRegistered(tes3.event.simulate, simulateCallbackShroud) then
		event.unregister(tes3.event.simulate, simulateCallbackShroud)
	end
end
-- end Shroud --

-- MARK: EYE OF NIGHT
local function addEyeOfNight()
	if not tes3.hasSpell({ reference = tes3.player, spell = 'eye of night' }) then
		tes3.addSpell({reference = tes3.mobilePlayer, spell = "eye of night", updateGUI = true})
	end
end

local function removeEyeOfNight()
	if tes3.player.object.race.id ~= "Khajiit" then
		if tes3.hasSpell({ reference = tes3.player, spell = 'eye of night' }) then
			tes3.removeSpell({ reference = tes3.mobilePlayer, spell = "eye of night", updateGUI = true })
		end
	end
end
-- end Eye of night

-- MARK: WATERBREATHING
local function addWaterBreathingAbility()
	if not tes3.hasSpell({ reference = tes3.player, spell = vampireWaterBreathingSpell }) then
		tes3.addSpell({reference = tes3.player, spell = vampireWaterBreathingSpell, updateGUI = true})
	end
end

local function removeWaterBreathingAbility()
	if tes3.hasSpell({ reference = tes3.player, spell = vampireWaterBreathingSpell }) then
		tes3.removeSpell({ reference = tes3.mobilePlayer, spell = 'mwseVA vampire waterbreathing', updateGUI = true })
	end
end
-- end Waterbreathing

-- MARK: NO FALL DAMAGE
local function damageCallbackNoFall(e)
	if e.reference == tes3.player then
		if e.source == tes3.damageSource.fall then
			e.block = true 
		end
	end
end

local function addNoFallDamageAbility()
	if not event.isRegistered(tes3.event.damage, damageCallbackNoFall) then
		event.register(tes3.event.damage, damageCallbackNoFall)
	end
end

local function removeNoFallDamageAbility()
	if event.isRegistered(tes3.event.damage, damageCallbackNoFall) then
		event.unregister(tes3.event.damage, damageCallbackNoFall)
	end
end
-- end No fall damage

-- MARK: VAMPIRE FLY
local function addLevitateAbility()
	if not tes3.hasSpell({ reference = tes3.player, spell = 'vampire levitate' }) then
		tes3.addSpell({reference = tes3.player, spell = 'vampire levitate', updateGUI = true})
	end
end

local function removeLevitateAbility()
	if tes3.hasSpell({ reference = tes3.player, spell = 'vampire levitate' }) then
		tes3.removeSpell({ reference = tes3.mobilePlayer, spell = 'vampire levitate', updateGUI = true })
	end
end
-- end Vampre fly

-- MARK: WATERWALK
local function spellResistCallbackWaterWalk(e)
	if e.target == tes3.player then
		if e.effect.id == 2 then
			e.resistedPercent = 100
		end
	end
end

local function addWaterWalkAbility()
	if not event.isRegistered(tes3.event.spellResist, spellResistCallbackWaterWalk) then
		event.register(tes3.event.spellResist, spellResistCallbackWaterWalk)
	end
end

local function removeWaterWalkAbility()
	if event.isRegistered(tes3.event.spellResist, spellResistCallbackWaterWalk) then
		event.unregister(tes3.event.magicCasted, spellResistCallbackWaterWalk)
	end
end
-- end Waterwalk

-- MARK: Helm hide
local function hideHelmCallback()
	if not tes3.player then return end
	if isWearingShroud() then return end

	unhideVampirism()

	if config.helmHides and isWearingClosedHelm() then
		hideVampirism()
	end
end

local function menuExitCallbackAddVampirism(e)
	timer.frame.delayOneFrame(hideHelmCallback)
end

local function uiActivatedCallback(e)
	timer.frame.delayOneFrame(hideHelmCallback)
	event.unregister(tes3.event.uiActivated,uiActivatedCallback)
end

local function equipCallbackHelmHide(e)
	timer.frame.delayOneFrame(hideHelmCallback)
end

local function unequippedCallbackHelmHide(e)
	timer.frame.delayOneFrame(hideHelmCallback)
	if e.item.id == "T_Dae_UNI_RobeShroud" then
		if not isWearingShroud() then
			if config.helmHides then
				if isWearingClosedHelm() then
					timer.start({ duration = 0.2, callback = hideVampirism, type = timer.simulate, iterations = 1 }) -- incase player has "quick toggle equipment" mod
				end
			end
		end
	end
end

local function addHelmHideAbility()
	if not event.isRegistered(tes3.event.equip, equipCallbackHelmHide) then
		event.register(tes3.event.equip, equipCallbackHelmHide)
	end

	if not event.isRegistered(tes3.event.unequipped, unequippedCallbackHelmHide) then
		event.register(tes3.event.unequipped, unequippedCallbackHelmHide)
	end

	if not event.isRegistered(tes3.event.menuExit, menuExitCallbackAddVampirism) then
		event.register(tes3.event.menuExit, menuExitCallbackAddVampirism)
	end
	
	if not event.isRegistered(tes3.event.uiActivated, uiActivatedCallback) then
		event.register(tes3.event.uiActivated, uiActivatedCallback)
	end
end

local function removeHelmHideAbility()
	if event.isRegistered(tes3.event.equip, equipCallbackHelmHide) then
		event.unregister(tes3.event.equip, equipCallbackHelmHide)
	end

	if event.isRegistered(tes3.event.unequipped, unequippedCallbackHelmHide) then
		event.unregister(tes3.event.unequipped, unequippedCallbackHelmHide)
	end

	if event.isRegistered(tes3.event.menuExit, menuExitCallbackAddVampirism) then
		event.unregister(tes3.event.menuExit, menuExitCallbackAddVampirism)
	end
	
	if event.isRegistered(tes3.event.uiActivated, uiActivatedCallback) then
		event.unregister(tes3.event.uiActivated, uiActivatedCallback)
	end
end
-- end Helm hid

-- MARK: CHARM
local function menuExitCallbackAddVampirismCharmed()
	if not tes3.player then return end
	if isWearingShroud() then return end

	if config.helmHides == true then
		event.unregister(tes3.event.menuExit, menuExitCallbackAddVampirismCharmed)
		timer.frame.delayOneFrame(hideHelmCallback)
	else
		unhideVampirism()
		event.unregister(tes3.event.menuExit, menuExitCallbackAddVampirismCharmed)
	end
end

local function activateCallbackCharmed(e)
	if e.activator ~= tes3.player then return end
	if e.target.object.objectType ~= tes3.objectType.npc then return end
	if e.target.isDead then return end
	if e.target.attachments.actor.inCombat then return end
	if isWearingShroud() then return end

	unhideVampirism()

	if e.target.attachments.actor.hasVampirism then 
		if not event.isRegistered(tes3.event.menuExit, menuExitCallbackAddVampirismCharmed) then
			event.register(tes3.event.menuExit, menuExitCallbackAddVampirismCharmed)
		end
		return
	end

	local whitelistQuestNPCs = {
		"sanvyn llethri",
		"fathasa llethri",
		"shashev",
		"sirilonwe",
		"rimintil",
		"raven omayn",
		"derar hlervu",
		"anden thilarvel",
		"ervis ules",
		"sarvil sadus",
		"tredere llaren",
		"vulyne rothari",
		"TR_m4_Armas Tyravel",
		"TR_m3_Mette Black-Briar",
		"TR_m4_Darron_Marceau",
		"TR_m4_Dridas Orthil",
		"TR_m4_Eraris_Verenim",
		"TR_m4_Dolmesa Llarvys",
		"TR_m4_Hlavora Tilvur",
		"PC_m1_Volanil"
	}

	for _, NPC in pairs(whitelistQuestNPCs) do
		if NPC == e.target.baseObject.id then
			-- mwse.log(e.target.baseObject.id)
			if not event.isRegistered(tes3.event.menuExit, menuExitCallbackAddVampirismCharmed) then
				event.register(tes3.event.menuExit, menuExitCallbackAddVampirismCharmed)
			end
			return
		end
	end

	if e.target.object.disposition > 89 then
		hideVampirism()
		if not event.isRegistered(tes3.event.menuExit, menuExitCallbackAddVampirismCharmed) then
			event.register(tes3.event.menuExit, menuExitCallbackAddVampirismCharmed)
		end
		return
	end

	for _, effect in pairs(e.target.attachments.actor.activeMagicEffectList) do
		if effect.effectId == 119 then -- Command Humanoid
			hideVampirism()
			if not event.isRegistered(tes3.event.menuExit, menuExitCallbackAddVampirismCharmed) then
				event.register(tes3.event.menuExit, menuExitCallbackAddVampirismCharmed)
			end
			return
		end
	end
end

local function addCharmedAbility()
	if not event.isRegistered(tes3.event.activate, activateCallbackCharmed) then
		event.register(tes3.event.activate, activateCallbackCharmed)
	end
end

local function removeCharmedAbility()
	if event.isRegistered(tes3.event.activate, activateCallbackCharmed) then
		event.unregister(tes3.event.activate, activateCallbackCharmed)
	end
end
-- end Charm

-- MARK: WAIT FOR NIGHTFALL
local function replaceUntilHealedWithUntilHour(e, text, targetHour)
    local restUntilHealedButton = e.element:findChild(tes3ui.registerID('MenuRestWait_untilhealed_button'))
    local restButton = e.element:findChild(tes3ui.registerID('MenuRestWait_rest_button'))
    if restUntilHealedButton ~= nil and restButton ~= nil and restButton.visible == true then
        restUntilHealedButton.visible = true
        restUntilHealedButton.text = text
        local scrollBar = e.element:findChild(tes3ui.registerID('MenuRestWait_scrollbar'))
        restUntilHealedButton:register(
            'mouseClick',
            function()
                local gameHour = tes3.getGlobal('GameHour')
                local hoursToRest
                if (gameHour >= targetHour) then
                    hoursToRest = 24 - gameHour + targetHour
                else
                    hoursToRest = targetHour - gameHour
                end
                scrollBar.widget.current = hoursToRest
                scrollBar:triggerEvent('PartScrollBar_changed')
                restButton:triggerEvent('mouseClick')
            end
        )
    end
end

local function onMenuRestWaitActivated(e)
	replaceUntilHealedWithUntilHour(e, 'Until Nightfall', 20)
end

local function addRestUntilNightfallAbility()
	if not event.isRegistered('uiActivated', onMenuRestWaitActivated, {filter = 'MenuRestWait'}) then
		event.register('uiActivated', onMenuRestWaitActivated, {filter = 'MenuRestWait'})
	end
end

local function removeRestUntilNightfallAbility()
	if event.isRegistered('uiActivated', onMenuRestWaitActivated, {filter = 'MenuRestWait'}) then
		event.unregister('uiActivated', onMenuRestWaitActivated, {filter = 'MenuRestWait'})
	end
end
-- end Wait for nightfall

-- MARK: SILVER DAMAGE
local function damageCallbackSilver(e)
	if config.silverDamageAbility == false then return end

	if e.mobile.hasVampirism or (e.reference == tes3.player and isPlayerVamp()) then
		if e.source == tes3.damageSource.attack then
			local stack = tes3.getEquippedItem({ actor = e.attacker , objectType = tes3.objectType.weapon})
			if stack then

				local silverWeaponsThatDoNotHaveSilverInTheMeshName = {
					"nord_battleaxe",
					"nord_claymore",
					'nord_dagger',
					'nord_longsword',
					'nord_mace',
					'nord_shortsword',
					"nord_waraxe"
				}

				local isSilverWeapon
				for _, weapon in pairs(silverWeaponsThatDoNotHaveSilverInTheMeshName) do
					if stack.object.mesh:lower():find(weapon) then
						isSilverWeapon = true
					end
				end

				if stack.object.mesh:lower():find("silver") or isSilverWeapon then
					e.damage = e.damage * 1.5
					tes3.playSound({ soundPath = '/Fx/magic/fireH.wav', volume = 0.5 })
				end
			end
		end
	end
end

local function addSilverDamageAbility()
	if not event.isRegistered(tes3.event.damage, damageCallbackSilver) then
		event.register(tes3.event.damage, damageCallbackSilver)
	end
end

local function removeSilverDamageAbility()
	if event.isRegistered(tes3.event.damage, damageCallbackSilver) then
		event.unregister(tes3.event.damage, damageCallbackSilver)
	end
end
-- end Silver damage

-- MARK: HOLY GROUND
local holyDamageThrottled = false
local vivecOrAlmaDomain = 'neither'
local isVivecDead
local isAlmaDead

local function calcWalkSpeedCallbackHolyGround(e)
	if e.mobile ~= tes3.mobilePlayer then return end
	if e.mobile.isJumping then return end

	if holyDamageThrottled == false then
		if isVivecDead and vivecOrAlmaDomain == 'vivec' then return end
		if isAlmaDead and vivecOrAlmaDomain == 'alma' then return end

		holyDamageThrottled = true
		tes3.messageBox({ message = 'Sacred Ground', duration = 1 })
		tes3.mobilePlayer:applyDamage({ damage = 1})
		timer.start({ duration = 1, callback = function() holyDamageThrottled = false end , type = timer.simulate })
	end
end

local function checkIfAlmaOrVivecIsDead()
	if not tes3.mobilePlayer then return end

	local playerKills = tes3.getKillCounts()
	for actor, count in pairs(playerKills) do
		if actor.id == 'vivec_god' then
			isVivecDead = true
		end
		if actor.id == 'almalexia' or actor.id:lower() == 'almalexia_warrior' then
			isAlmaDead = true
		end
	end
end

local function cellChangedCallbackHolyGround(e)
	if isVivecDead == true and isAlmaDead == true then 
		if event.isRegistered(tes3.event.calcWalkSpeed, calcWalkSpeedCallbackHolyGround) then
			event.unregister(tes3.event.calcWalkSpeed, calcWalkSpeedCallbackHolyGround)
		end
		return
	end

	if e.cell.id:lower():find("temple") then
		if e.cell.id:lower():find("mournhold") then
			vivecOrAlmaDomain = 'alma'
		else
			vivecOrAlmaDomain = 'vivec'
		end

		checkIfAlmaOrVivecIsDead()

		if not event.isRegistered(tes3.event.calcWalkSpeed, calcWalkSpeedCallbackHolyGround) then
			event.register(tes3.event.calcWalkSpeed, calcWalkSpeedCallbackHolyGround)
		end
	else
		holyDamageTimer = 0
		vivecOrAlmaDomain = 'neither'
		if event.isRegistered(tes3.event.calcWalkSpeed, calcWalkSpeedCallbackHolyGround) then
			event.unregister(tes3.event.calcWalkSpeed, calcWalkSpeedCallbackHolyGround)
		end
	end
end

local function addHolyGroundAbility()
	if not event.isRegistered(tes3.event.cellChanged, cellChangedCallbackHolyGround) then
		event.register(tes3.event.cellChanged, cellChangedCallbackHolyGround)
	end
end

local function removeHolyGroundAbility()
	if event.isRegistered(tes3.event.cellChanged, cellChangedCallbackHolyGround) then
		event.unregister(tes3.event.cellChanged, cellChangedCallbackHolyGround)
	end
	if event.isRegistered(tes3.event.calcWalkSpeed, calcWalkSpeedCallbackHolyGround) then
		event.unregister(tes3.event.calcWalkSpeed, calcWalkSpeedCallbackHolyGround)
	end
end
-- end Holy ground

-- MARK: APPLY ABILITIES
local function addVampireAbilities()
	if config.cannotRestoreHealth == true then
		addNoHealingAbility()
	elseif config.cannotRestoreHealth == false then
		removeNoHealingAbility()
	end

	if config.hasEyeOfNight == true then
		addEyeOfNight()
	elseif config.hasEyeOfNight == false then
		removeEyeOfNight()
	end

	if config.helmHides == true then
		addHelmHideAbility()
	elseif config.helmHides == false then
		removeHelmHideAbility()
	end

	if config.namiraShroudOnlyWhileWalking == true then
		addShroudAbility()
	elseif config.namiraShroudOnlyWhileWalking == false then
		removeShroudAbility()
	end

	if config.canBreathUnderWater == true then
		addWaterBreathingAbility()
	elseif config.canBreathUnderWater == false then
		removeWaterBreathingAbility()
	end

	if config.noFallDamage == true then
		addNoFallDamageAbility()
	elseif config.noFallDamage == false then
		removeNoFallDamageAbility()
	end

	if config.cannotWaterWalk == true then
		addWaterWalkAbility()
	elseif config.cannotWaterWalk == false then
		removeWaterWalkAbility()
	end

	if config.talkToCharmed == true then
		addCharmedAbility()
	elseif config.talkToCharmed == false then
		removeCharmedAbility()
	end

	if config.restUntilNightfall == true then
		addRestUntilNightfallAbility()
	elseif config.restUntilNightfall == false then
		removeRestUntilNightfallAbility()
	end

	if config.levitateAbility == true then
		addLevitateAbility()
	elseif config.levitateAbility == false then
		removeLevitateAbility()
	end

	if config.holyGroundAbility == true then
		checkIfAlmaOrVivecIsDead()
		addHolyGroundAbility()
	elseif config.holyGroundAbility == false then
		removeHolyGroundAbility()
	end
end

local function removeVampireAbilities()
	removeNoHealingAbility()
	removeShroudAbility()
	removeEyeOfNight()
	removeWaterBreathingAbility()
	removeWaterWalkAbility()
	removeHelmHideAbility()
	removeCharmedAbility()
	removeNoFallDamageAbility()
	removeRestUntilNightfallAbility()
	removeLevitateAbility()
	removeHolyGroundAbility()
end
-- end Apply abilities


-- MARK: INITIALIZATION
local function startGlobalScriptCallback(e)
	if e.script.id == "Vampire_Aundae_PC" or e.script.id == "Vampire_Berne_PC" or e.script.id == "Vampire_Quarra_PC" or e.script.id == "T_ScVamp_Baluath_PC" or e.script.id == "T_ScVamp_Khulari_PC" or e.script.id == "T_ScVamp_Orlukh_PC" then
		checkIfAlmaOrVivecIsDead()
		addVampireAbilities()
	elseif e.script.id == "Vampire_Cure_PC" then
		removeVampireAbilities()

		local function cureVampirism()
			if tes3.hasSpell({ reference = tes3.player, spell = "Vampire Sun Damage"}) and not isWearingShroud() then
				tes3.removeSpell({reference = tes3.mobilePlayer, spell = "Vampire Sun Damage", updateGUI = true})
			end
			if fakeVampirismSpell then
				if tes3.hasSpell({ reference = tes3.player, spell = fakeVampirismSpell }) then
					tes3.removeSpell({ reference = tes3.mobilePlayer, spell = "mwseVA vampire fake", updateGUI = true })
				end
			end
		end
		timer.frame.delayOneFrame(cureVampirism)
	end
end

local function initializedCallback(e)
	if not fakeVampirismSpell then
		fakeVampirismSpell = createFakeVampirism()
	end

	if not vampireWaterBreathingSpell then
		vampireWaterBreathingSpell = createVampireWaterBreathingSpell()
	end
end
event.register(tes3.event.initialized, initializedCallback)

local function loadedCallback(e)
	holyDamageThrottled = false
	removeVampireAbilities()

	if not event.isRegistered(tes3.event.startGlobalScript, startGlobalScriptCallback) then
		event.register(tes3.event.startGlobalScript, startGlobalScriptCallback)
	end

	if config.silverDamageAbility == true then
		addSilverDamageAbility()
	elseif config.silverDamageAbility == false then
		removeSilverDamageAbility()
	end

	if isPlayerVamp() then 
		addVampireAbilities()
		hideHelmCallback()
	end
end

local function onModConfigReady()
    dofile("MWSEVampireOptions.mcm")
end

event.register(tes3.event.modConfigReady, onModConfigReady)
event.register(tes3.event.loaded, loadedCallback)
-- end Initialization