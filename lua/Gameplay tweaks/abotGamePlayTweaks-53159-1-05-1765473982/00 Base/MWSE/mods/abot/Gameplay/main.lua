---@diagnostic disable: deprecated
-- begin configurable parameters
local defaultConfig = {
addBoundSpells = true, -- true = add a bound weapon spell to daedra bipeds
disableSittingNPCsCollision = true,
addLights = true, -- true = dynamically add lights to caravaners/shipmasters/gondoliers
addClothes = true, -- true = add clothes to dancers/naked people
guantletToGauntlet = true, -- fix misspelled guantlet --> gauntlet
---fixWearingLegionUni = true, -- fix setting global short variable WearingLegionUni from script wearingLegionUni not always working
moreStackables = true, -- Ash Statues, Legion/Ordinator armors stackable replacing their local script. Also overrides WearingLegionUni, WearingOrdinatorUni
preventSwimmingHostilesFromPreventingRest = true, -- NullCascade's trick https://discord.com/channels/210394599246659585/643946536170160138/855273560561418280
NOM_shelterPreventsRestingHostiles = true, -- NOM_shelter global variable set to 1 prevents hostiles when resting
fixFloatingActors = true, -- fix floating actors on reload
fixInteriorWaterLevel = true, -- fix interiors water level not updated correctly
fixPlacedItemsLighting = false, -- fix placed items lighting
fixCarriableLights = false, -- fix carriable lights settings to avoid unexpected glowing player/actors
fixConstantEffects = false, -- fix constant effects on player in case related objects/spells sources are no more existing
noBetterClothesWarning = true,
minPlayerSpeed = 20, -- min Player Speed, even when encumbered
goToJailTweaks = true, -- tweaks some goToJail prison mine gameplay if the mod is detected
gold100weight = 1, -- gold weight X 100 if the mod is detected
containerWeightMultX100 = 75, -- Inventory helpers/MWSE containers weight multiplier X 100
closeInspectionTweaks = true,  -- true to tweak Close Inspection to avoid possible crashes
saoWaterTweaks = true,  -- true to disable SAO shader when looking at water activators
fixDummySubtitles = true,
fixSummonAI = true, -- fix summons AI fight and follow if needed
disableEmptyThreats = true,
onlyBedsAllowResting = false,
logLevel = 0,
}
-- end configurable parameters

local author = 'abot'
local modName = 'Gameplay'
local modPrefix = author..'\\'..modName

---require(modPrefix..'\\infoGetText')

local configName = author..modName
configName = configName:gsub(' ', '_')
local mcmName = author.."'s "..modName

local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end

local config = mwse.loadConfig(configName, defaultConfig)
assert(config)
if config.debugLevel then  -- update legacy
	config.logLevel = config.debugLevel
	config.debugLevel = nil
end

local addBoundSpells, disableSittingNPCsCollision, addLights, addClothes
local fixPlacedItemsLighting, fixCarriableLights, minPlayerSpeed
local closeInspectionTweaks, saoWaterTweaks, fixDummySubtitles, fixSummonAI
local disableEmptyThreats, moreStackables, onlyBedsAllowResting, fixConstantEffects
local logLevel, logLevel1, logLevel2, logLevel3, logLevel4

local function updateFromConfig()
	addBoundSpells = config.addBoundSpells
	disableSittingNPCsCollision = config.disableSittingNPCsCollision
	addLights = config.addLights
	addClothes = config.addClothes
	fixPlacedItemsLighting = config.fixPlacedItemsLighting
	fixCarriableLights = config.fixCarriableLights
	fixConstantEffects = config.fixConstantEffects
	minPlayerSpeed = config.minPlayerSpeed
	closeInspectionTweaks = config.closeInspectionTweaks
	saoWaterTweaks = config.saoWaterTweaks
	fixDummySubtitles = config.fixDummySubtitles
	fixSummonAI = config.fixSummonAI
	disableEmptyThreats = config.disableEmptyThreats
	moreStackables = config.moreStackables
	onlyBedsAllowResting = config.onlyBedsAllowResting
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
	logLevel4 = logLevel >= 4
end
updateFromConfig()

local shipMasterLight = 'light_com_lantern_02_INF'
local caravanerLight = 'torch_infinite_time'

local tes3_creatureType_daedra = tes3.creatureType.daedra

local boundWeaponSpells = {
[1] = 'bound battle-axe',
[2] = 'bound dagger',
[3] = 'bound longbow',
[4] = 'bound longsword',
[5] = 'bound mace',
[6] = 'bound spear',
}

 -- set in modConfigReady()
local g7_container_mult, ab01goldWeight

local gtj_never_prison_mine, gtj_global_mine -- GoToJail
local YAC_CI_RunEvery, YAC_CI_ZoomState


 -- set in loaded()
local player, mobilePlayer
local ab01EigNewClothes1Script, YAC_CI_GlobalScript

local tes3_objectType_armor = tes3.objectType.armor
local tes3_armorSlot_cuirass = tes3.armorSlot.cuirass

local wearingLegionUni, wearingOrdinatorUni -- set in modConfigready()

local function randBoundWeaponSpell()
	return boundWeaponSpells[math.random(1, #boundWeaponSpells)]
end

local function isValidDaedra(obj)
	return (obj.type == tes3_creatureType_daedra)
	and obj.biped
	and obj.usesEquipment
end

local tes3_animationState_dying = tes3.animationState.dying
local tes3_animationState_dead = tes3.animationState.dead

local function isDead(mob)
	local result = false
	if mob.isDead then
		result = true
	else
		local actionData = mob.actionData
		if actionData then
			local animState = actionData.animationAttackState
			if animState then
				if (animState == tes3_animationState_dying)
				or (animState == tes3_animationState_dead) then
					result = true
				end
			end
		end
	end
	local health = mob.health
	if not health then
		return result
	end
	local health_current = health.current
	if not health_current then
		return result
	end
	-- as we are here fix possible health.current glitches
	if result then
		if health_current > 0 then
			health.current = 0
		end
		return true
	end
	if (health.normalized <= 0.025) -- health ratio <= 2.5%
	and (health_current > 0)
	and (health_current < 3)
	and (health.normalized > 0) then
		health.current = 0 -- kill when nearly dead, could be a glitch
		return true
	end
	return result
end

local tes3_objectType = tes3.objectType

local tes3_objectType_clothing = tes3_objectType.clothing
local tes3_objectType_light = tes3_objectType.light

local tes3_clothingSlot_shirt = tes3.clothingSlot.shirt
local tes3_clothingSlot_pants = tes3.clothingSlot.pants
local tes3_clothingSlot_skirt = tes3.clothingSlot.skirt

local tes3_activeBodyPartLayer_base = tes3.activeBodyPartLayer.base
local tes3_activeBodyPart_groin = tes3.activeBodyPart.groin
local tes3_activeBodyPart_chest = tes3.activeBodyPart.chest

local function addAndEquipItemOnce(mobRef, itemId, classId)
	if not mobRef.object.inventory:contains(itemId) then
		---mwscript.addItem({reference = mobRef, item = itemId})
		if logLevel1 then
			mwse.log("%s: %s added to %s %s", modPrefix, itemId, classId, mobRef.id)
		end
		tes3.addItem({reference = mobRef, item = itemId})
		-- mobRef.mobile:equip({item = itemId, addItem = true}) -- nope it does not trigger equip event
		mwscript.equip({reference = mobRef, item = itemId})
	end
end

local tes3_actorType_npc = tes3.actorType.npc
local tes3_actorType_creature = tes3.actorType.creature

local function back2slash(s)
	return s:gsub([[\]], [[/]])
end

local function processActor(mobRef)
	local mob = mobRef.mobile
	if not mob then
		---assert(mob)
		return
	end
	local actorType = mob.actorType
	local obj = mobRef.baseObject

	if actorType == tes3_actorType_creature then
		if not addBoundSpells then
			return
		end
		if not isValidDaedra(obj) then
			return
		end
		-- daedra
		for i = 1, #boundWeaponSpells do
			mwscript.removeSpell({reference = mobRef, spell = boundWeaponSpells[i]})
		end
		mwscript.removeSpell({reference = mobRef, spell = 'bound shield'})
		local weaponSpell = randBoundWeaponSpell()
		if logLevel1 then
			mwse.log("%s: mwscript.addSpell({reference = %s, spell = %s})", modPrefix, mobRef, weaponSpell)
		end
		mwscript.addSpell({reference = mobRef, spell = weaponSpell})
		if weaponSpell == 'bound longbow' then
			local c = 10 + math.random(10)
			local i = 'daedric arrow'
			if logLevel1 then
				mwse.log("%s: addItem({reference = %s, item = %s, count = %s})", modPrefix, mobRef, i, c)
			end
			---mwscript.addItem({reference = mobRef, item = i, count = c})
			tes3.addItem({reference = mobRef, item = i, count = c, reevaluateEquipment = true})
			return
		end
		if (weaponSpell == 'bound battle-axe')
		or (weaponSpell == 'bound spear') then
			return
		end
		if weaponSpell == 'bound longsword' then
			if math.random(1, 100) > 66 then
				local sp = 'bound shield'
				mwscript.addSpell({reference = mobRef, spell = sp})
				if logLevel1 then
					mwse.log("%s: mwscript.addSpell({reference = %s, spell = %s})",
						modPrefix, mobRef, sp)
				end
				mwscript.addSpell({reference = mobRef, spell = sp})
			end
		end

		return -- end creature management
	end


	if not (actorType == tes3_actorType_npc) then
		return
	end

	-- manage NPCs
	if disableSittingNPCsCollision
	and string.multifind(string.lower(back2slash(obj.mesh)),
			{'am_eater', 'am_reader2', 'am_sitbar', 'am_writer'}, 1, true) then
		mob.movementCollision = false
	end

	local objClass = obj.class
	if not objClass then
		---assert(objClass) --it happens a lot /abot
		return
	end

	local classId = objClass.id
	local lcClassId = classId:lower()

	if addLights then
		if (lcClassId == 'shipmaster')
		or (lcClassId == 'gondolier') then
			if not mobRef.object.inventory:contains(shipMasterLight) then
				---mwscript.addItem({reference = mobRef, item = shipMasterLight})
				tes3.addItem({reference = mobRef, item = shipMasterLight, reevaluateEquipment = true})
				if logLevel1 then
					mwse.log("%s: %s added to %s %s", modPrefix, shipMasterLight, classId, mobRef.id)
				end
			end
		elseif lcClassId == 'caravaner' then
			if not mobRef.object.inventory:contains(caravanerLight) then
				---mwscript.addItem({reference = mobRef, item = caravanerLight})
				tes3.addItem({reference = mobRef, item = caravanerLight, reevaluateEquipment = true})
				if logLevel1 then
					mwse.log("%s: %s added to %s %s", modPrefix, caravanerLight, classId, mobRef.id)
				end
			end
		end
	end

	if addClothes then
		local function addShirt()
			---local itemId = string.format("common_shirt_0%s", math.random(1,5))
			local itemId = 'common_shirt_0' .. math.random(1,5)
			addAndEquipItemOnce(mobRef, itemId, classId)
		end

		local bpm = mobRef.bodyPartManager

		if bpm then
			local lcId = obj.id:lower()
			local isSlave = (lcClassId == 'slave')
			or (
				(obj.script)
				and (obj.script.id:lower() == 'slavescript')
			)

			local function isClothingSlotEmpty(clothingSlot)
				return not tes3.getEquippedItem({ actor = mobRef,
					objectType = tes3_objectType_clothing, slot = clothingSlot })
			end

			local bodyPart = bpm:getActiveBodyPart(tes3_activeBodyPartLayer_base, tes3_activeBodyPart_groin)

			if bodyPart
			and bodyPart.node then

				local function addPants()
					---local itemId = string.format("common_pants_0%s", math.random(2,5))
					local itemId = 'common_pants_0' .. math.random(2,5)
					addAndEquipItemOnce(mobRef, itemId, classId)
				end
				local function addSkirt()
					---local itemId = string.format("common_skirt_0%s", math.random(1,7))
					---local itemId = 'common_skirt_0' .. math.random(1,7)
					local itemId = 'common_skirt_0' .. math.random(1,7)
					addAndEquipItemOnce(mobRef, itemId, classId)
				end


				if lcId:find('dancer', 1, true) then
					if isClothingSlotEmpty(tes3_clothingSlot_pants) then
						if obj.female and ab01EigNewClothes1Script then
							mwscript.startScript({reference = mobRef, script = ab01EigNewClothes1Script})
						else
							addPants()
						end
					end
				elseif lcId:find('dreamer', 1, true) then
					if obj.female then
						if isClothingSlotEmpty(tes3_clothingSlot_skirt) then
							addSkirt()
						end
					elseif isClothingSlotEmpty(tes3_clothingSlot_pants) then
						addPants()
					end
				elseif isSlave then
					if obj.female then
						if isClothingSlotEmpty(tes3_clothingSlot_skirt) then
							addSkirt()
						end
					elseif isClothingSlotEmpty(tes3_clothingSlot_pants) then
						addPants()
					end
				end
			end

			if obj.female then
				if isSlave then
					bodyPart = bpm:getActiveBodyPart(tes3_activeBodyPartLayer_base, tes3_activeBodyPart_chest)
					if bodyPart
					and bodyPart.node
					and isClothingSlotEmpty(tes3_clothingSlot_shirt)
					and (not tes3.getEquippedItem({ actor = mobRef,
							objectType = tes3_objectType_armor, slot = tes3_armorSlot_cuirass }) ) then
						if mobRef.cell.isInterior
						and ab01EigNewClothes1Script then
							mwscript.startScript({reference = mobRef, script = ab01EigNewClothes1Script})
						else
							addShirt()
						end
					end
				end
			end -- if obj.female

		end -- if bpm

	end

end


local placeables = {
[tes3_objectType.armor] = true,
[tes3_objectType.container] = true,
[tes3_objectType.miscItem] = true,
---[tes3_objectType.light] = true,
}


---@param e referenceSceneNodeCreatedEventData
local function referenceSceneNodeCreated(e)
	local ref = e.reference
	if not ref then
		return
	end
	if ref.disabled then
		return
	end
	if ref.deleted then
		return
	end
	local mob = ref.mobile
	if not mob then
		if (not ref.sourceMod)
		and fixPlacedItemsLighting then
			if placeables[ref.baseObject.objectType]
			and (not ref.isLeveledSpawn) then
				if logLevel3 then
					mwse.log('%s: referenceSceneNodeCreated() "%s":updateLighting()',
						modPrefix, ref.id)
				end
				ref:updateLighting()
			end
		end

		return
	end

	if not mob.actorType then
		return
	end
	if isDead(mob) then
		return
	end
	processActor(ref)
end
event.register('referenceSceneNodeCreated', referenceSceneNodeCreated)


---@param e activateEventData
local function activateAddBoundSpells(e)
	local targetRef = e.target
	local mob = targetRef.mobile
	if not mob then
		return
	end
	local targetObj = targetRef.baseObject
	if isValidDaedra(targetObj)
	and isDead(mob) then
		local itemId = 'daedric arrow'
		local c = tes3.getItemCount({reference = targetRef, item = itemId})
		if c > 0 then
			--- mwscript.removeItem({ reference = targetRef, item = itemId, count = c })
			tes3.removeItem({reference = targetRef,
				item = itemId, count = c, playSound = false})
		end
	end
end

local function fixPlayerEncumbrance()
	if mobilePlayer.encumbrance.current > 0 then
		mobilePlayer.encumbrance.current = 0
	end
end

local function round(x)
	return math.floor(x + 0.5)
end

local function putPlayerItemsInJailChest()
	if logLevel3 then
		mwse.log("%s: putPlayerItemsInJailChest()", modPrefix)
	end

	if not gtj_never_prison_mine then
		return
	end
	if not gtj_global_mine then
		return
	end
	local destRef = tes3.getReference('gtj_chest_PC')
	if not destRef then
		return
	end
	local state = 0
	if gtj_global_mine.value > 0 then
		state = 1
	end
	if round(gtj_never_prison_mine.value) >= 1 then
		state = 2
	end
	if state <= 0 then
		return
	end
---@param item tes3item
---@return boolean
	local function skipSpecial(item)
-- skip e.g. CDC inventory helpers/MWSE containers light icons
-- MWSE containers is especially nasty as it will block the player forever
-- if you force transfer one of its special light icons into another container
		if string.startswith(item.id:lower(), 'gtj_') then
			return false -- skip GoToJail special items
		end
		local ok
		if item.objectType == tes3_objectType_light then
			---@cast item tes3light
			ok = not ( -- conditions defining a special light icon
				item.canCarry
			and item.isOffByDefault
			and (item.radius < 17)
			)
		else
			ok = true
		end
		return ok
	end

	if tes3.transferInventory({from = player, to = destRef,
			filter = skipSpecial,
			limitCapacity = false, playSound = false, updateGUI = false,
			reevaluateEquipment = false, equipProjectiles = false}) then
		tes3.updateInventoryGUI({reference = player})
		tes3.updateMagicGUI({reference = player})
		tes3ui.showNotifyMenu("The majority of your items have been stored in the %s. You should drop the rest of your properties too.",
			destRef.object.name)
		fixPlayerEncumbrance()
	end
end

local function simulate()
	if not gtj_never_prison_mine then
		return
	end
	if round(gtj_never_prison_mine.value) < 1 then
		return
	end
	event.unregister('simulate', simulate)
	putPlayerItemsInJailChest()
end

local function cellChangedGoToJail(e)
	local cell = e.cell
	if not cell.isInterior then
		return
	end
	if not (cell.id == 'Imperial Raw Ebony Mine') then
		return
	end
	--[[if cell == e.previousCell then
		assert(false) -- should never happen?
		return
	end]]
	if logLevel3 then
		mwse.log("%s: cellChangedGoToJail(e)", modPrefix)
	end
	event.register('simulate', simulate)
end

local NOM_shelter -- set in modConfigready()

local function preventRest(e)
	if config.preventSwimmingHostilesFromPreventingRest
	and e.mobile.isSwimming
	and (not mobilePlayer.isSwimming) then
		return false
	end
	if config.NOM_shelterDisablesRestingHostiles
	and NOM_shelter
	and ( round(NOM_shelter.value) > 0 ) then
		return false
	end
end

local sao -- set in modConfigReady()


local saoBlacklist = {'water','nom_source','spout','crystal','pool'}
local function checkSao(ref)
	if not ref then
		return
	end
	if not sao then
		return
	end
	local lcId = ref.baseObject.id:lower()
	if lcId:multifind(saoBlacklist, 1, true) then
		if sao.enabled then
			sao.enabled = false
			if logLevel2 then
				mwse.log('%s: disabling "%s" shader while looking at "%s"',
					modPrefix, sao.name, lcId)
			end
		end
		return
	end
	if not sao.enabled then
		if logLevel2 then
			mwse.log('%s: enabling "%s" shader', modPrefix, sao.name)
		end
		sao.enabled = true
	end
end

local function checkCloseInspectionReset()
	if not closeInspectionTweaks then
		return
	end
	if not YAC_CI_GlobalScript then
		return
	end
	local c = YAC_CI_GlobalScript.context
	--[[if logLevel4 then
		if c then
			---mwse.log("%s: activationTargetChanged() YAC_CI_GlobalScript.context = %s", modPrefix, c)
			local t = c:getVariableData()
			if type(t) == 'table' then
				for k, v in pairs(t) do
					mwse.log('context["%s"] = %s', k, v)
				end
			end
		end
	end]]
	c.timer = YAC_CI_RunEvery.value
	c.isSameTarget = 0
	---assert(c.isSameTarget == 0)
	c.lastTarget = 0
	c.lastZoomedIn = 0
	YAC_CI_ZoomState.value = 0
	-- still crashing, try resetting everything else
	c.thisTarget = 0
	c.thisTargetID = 0
	c.lastTargetID = 0
	c.lastZoomedInID = 0
	if logLevel4 then
		mwse.log("%s: checkCloseInspectionReset(), resetting YAC_CI_GlobalScript", modPrefix)
	end
	return true
end

local function activationTargetChanged(e)
	local targetRef = e.current
	if targetRef then
		if saoWaterTweaks then
			checkSao(targetRef)
		end
		return
	end
	-- no target
	checkCloseInspectionReset()
end

local function removeBadLights(light)

	local function removeBadLight(obj, ref)
		local inventory = obj.inventory
		local c = math.abs(inventory:getItemCount(light))
		if c > 0 then
			mwse.log('%s: %s "%s" bad lights removed from "%s" %s',
				modPrefix, c, light.id, obj.id, mwse.longToString(obj.objectType))
			if ref then
				tes3.removeItem({reference = ref, item = light, count = c, playSound = false})
			else
				inventory:removeItem({item = light, count = c})
			end
		end
	end

	for obj in tes3.iterateObjects({tes3_objectType.container,
			tes3_objectType.creature, tes3_objectType.npc}) do
		removeBadLight(obj)
	end

	local ref = tes3.player
	if ref then
		removeBadLight(ref.object, ref)
	end
end

local function fixBadCarriableLights()
	for obj in tes3.iterateObjects(tes3_objectType.light) do
		---@cast obj tes3light
	    if obj.canCarry
	    and (obj.mesh == '') then
			if (not obj.isOffByDefault)
			or (obj.radius >= 17) then
				obj.canCarry = false
				obj.modified = true
				if obj.sourceMod then
					mwse.log('%s: "%s" light from "%s" canCarry flag set to false', modPrefix, obj.id, obj.sourceMod)
				else
					mwse.log('%s: "%s" light canCarry flag set to false', modPrefix, obj.id)
				end
				removeBadLights(obj)
			end
		end
	end
end

local tes3_magicSourceType_enchantment = tes3.magicSourceType.enchantment
local tes3_magicSourceType_spell = tes3.magicSourceType.spell
local tes3_enchantmentType_constant = tes3.enchantmentType.constant
local tes3_spellState_working = tes3.spellState.working
local tes3_spellState_ending = tes3.spellState.ending
local tes3_spellState_workingFortify = tes3.spellState.workingFortify
local tes3_spellState_endingFortify = tes3.spellState.endingFortify

local effectsDict = table.invert(tes3.effect)

local function fixBadConstantEffects()
	local mob = tes3.mobilePlayer
	local ame = mob.activeMagicEffectList
	if #ame <= 0 then
		return
	end
	local ref = mob.reference
	local refObj = ref.object
	local sourceInstance, sourceType, source
	local castType, constant, item, state, id, ok
	for _, activeMagicEffect in ipairs(ame) do
		sourceInstance = activeMagicEffect.instance
		source = sourceInstance.source
		constant = false
		if source then
			sourceType = sourceInstance.sourceType
			if sourceType == tes3_magicSourceType_enchantment then
				---@cast source tes3enchantment
				castType = source.castType
				if castType
				and (castType == tes3_enchantmentType_constant) then
					item = sourceInstance.item
					if ( not refObj:hasItemEquipped(item) ) then
						constant = true
						id = item.id
					end
				end
			elseif sourceType == tes3_magicSourceType_spell then
				---@cast source tes3spell
				if source.isAbility
					or source.isCurse then
					if not tes3.getObject(source.id) then
						constant = true
						id = source.id
					end
				end
			end
		end
		if constant then
			state = sourceInstance.state
			ok = false
			if state == tes3_spellState_workingFortify then
				sourceInstance.state = tes3_spellState_endingFortify
				ok = true
			elseif state == tes3_spellState_working then
				sourceInstance.state = tes3_spellState_ending
				ok = true
			end
			if ok then
				mwse.log('%sfixBadConstantEffects(): "%s" "%s" effect removed from "%s"',
					modPrefix, id, effectsDict[activeMagicEffect.effectId], ref.id)
			end
		end
	end
end

local function toggleEvent(on, eventName, eventFunc, options)
	local currentlyOn = event.isRegistered(eventName, eventFunc, options)
	if on == currentlyOn then
		return
	end
	local regOrUnreg
	if on then
		if logLevel2 then
			mwse.log('%s: "%s" "%s" registered', modPrefix, eventName, eventFunc)
		end
		regOrUnreg = event.register
	else
		if logLevel2 then
			mwse.log('%s: "%s" "%s" unregistered', modPrefix, eventName, eventFunc)
		end
		regOrUnreg = event.unregister
	end
	regOrUnreg(eventName, eventFunc, options)
end


local function calcMoveSpeed(e)
	if not (e.reference == tes3.player) then
		return
	end
	if e.speed < minPlayerSpeed then
		e.speed = minPlayerSpeed
	end
end

local function cellChangedFixInteriorWaterLevel(e)
	local cell = e.cell
	if not cell.isInterior then
		return
	end
	if cell.behavesAsExterior then
		return
	end
	local waterLevel = cell.waterLevel
	if waterLevel
	and (not cell.hasWater)
	and (waterLevel > -9999999999) then
		cell.hasWater = true
		cell.waterLevel = math.floor(waterLevel)
	end
end

local function fixSteelCuirass()
	local steel_cuirass = tes3.getObject('steel_cuirass')
	if not steel_cuirass then
		---assert(steel_cuirass)
		return
	end
	local sourceMod = steel_cuirass.sourceMod
	if not sourceMod then
		return
	end
	if sourceMod:lower() == 'bloodmoon.esm' then
		local femalePart = tes3.getObject('A_Steel_Cuir_Female')
		if femalePart then
			mwse.log("%s: steel_cuirass female body part fixed to %s", modPrefix, femalePart)
---@diagnostic disable-next-line: assign-type-mismatch
			steel_cuirass.parts[1].female = femalePart
		end
	end
end

---local tes3_dialogueType_voice = tes3.dialogueType.voice
---local tes3_dialogueType_greeting = tes3.dialogueType.greeting

 -- set in modConfigReady()
local worldController

local stringToNotNotify

local idMenuNotify_message = tes3ui.registerID('MenuNotify_message')

local function uiActivatedMenuNotify(e)
	if not worldController.showSubtitles then
		return
	end
	local menu = e.element
	local el = menu:findChild(idMenuNotify_message)
	if not el then
		return
	end
	local s = el.text
	if not s then
		return
	end
	if string.len(s) <= 0 then
		return
	end
	---mwse.log('el.id = "%s", el.name = "%s", el.text = "%s"', el.id, el.name, s)
	if not stringToNotNotify then
		return
	end
	if s == stringToNotNotify then
		if logLevel1 then
			mwse.log('%s: uiActivatedMenuNotify() "%s" notify hidden',
				modPrefix, stringToNotNotify)
		end
		stringToNotNotify = nil
		menu.visible = false
		menu:destroy()
	end
end

local function stripTags(s)
	return s:gsub('[@#]', '')
end

---local function replacePercent(s)
	---return s:gsub('%%', '%^'):gsub('%^%^', '%^')
---end

local function stripTagsAndApplyTextDefines(s, actorObj)
	local s2 = stripTags(s)
	if actorObj then
		s2 = tes3.applyTextDefines({text = s2, actor = actorObj})
	end
	return tes3.applyTextDefines({text = s2, actor = tes3.player.object})
end

local lastDialogVoiceRef

local function checkSubtitle(ref, s)
	if not fixDummySubtitles then
		return
	end
	if not worldController.showSubtitles then
		return
	end
	if string.len(s) < 3 then
		if logLevel3 then
			mwse.log('%s: checkSubtitle("%s") string.len("%s") < 3, hiding notify',
				modPrefix, ref.id, s)
		end
		stringToNotNotify = s
	end
end

local tes3_dialogueFilterContext_voice = tes3.dialogueFilterContext.voice

local function dialogueFiltered(e)
	if not (e.context == tes3_dialogueFilterContext_voice) then
		return
	end
	local s = e.info.text
	if not s then
		return
	end
	local ref = e.reference
	if not ref then
		return
	end
	if ref == lastDialogVoiceRef then
		return
	end
	local len_s = string.len(s)
	if len_s <= 0 then
		return
	end
	local id = e.dialogue.id
	if (id == 'Hello')
	or (id == 'Idle') then
		if len_s > 3 then
			lastDialogVoiceRef = ref
		end
	end
	s = stripTagsAndApplyTextDefines(s, ref.object)
	checkSubtitle(ref, s)
end

local tes3_aiPackage_follow = tes3.aiPackage.follow

local function spellTick(e)
	local effectInstance = e.effectInstance
	if not effectInstance then
		return
	end
	if not effectInstance.isSummon then
		return
	end
	local createdData = effectInstance.createdData
	if not createdData then
		return
	end
	local ref = createdData.object ---@as tes3reference | nil
	if not ref then
		return
	end
	local mob = ref.mobile
	if not mob then
		return
	end
	local fight = mob.fight
	if not fight then
		return
	end
	local tempData = ref.tempData
	if not tempData then
		assert(tempData) -- should never happen
		return
	end
	if tempData.ab01smnFix then
		return
	end
	tempData.ab01smnFix = true
	if round(fight) <= 50 then
		return
	end
	mob.fight = 50
	if logLevel1 then
		mwse.log('%s: spellTick() "%s" initial Fight reset from %s to %s',
			modPrefix, ref.id, fight, mob.fight)
	end
	local caster = e.caster
	if not caster then
		return
	end
	local ai = tes3.getCurrentAIPackageId({reference = ref})
	if not (ai == tes3_aiPackage_follow) then
		if logLevel1 then
			mwse.log('%s: spellTick() "%s" set to follow "%s"', modPrefix, ref, caster)
		end
		tes3.setAIFollow({reference = mob, target = caster, reset = true})
	end
end


---@param e infoFilterEventData
local function infoFilter(e)
	if not e.passes then
		return
	end
	if tes3.menuMode() then
		return
	end
	if not (e.dialogue.id == 'Attack') then
		return
	end
	local ref = e.reference
	local mob = ref.mobile
	if isDead(mob) then
		if logLevel1 then
			mwse.log('%s: infoFilter() "%s" dead actor "%s" hollow threat voice skipped',
				modPrefix, ref.id, e.dialogue.id)
		end
		e.passes = false
	end
end

local function is6thAshStatue(objId)
	local lcId = objId:lower()
	if lcId:match('ash[_ ]?statue')
	and lcId:multifind({'6th', 'sixth'}, 1, true) then
		return true
	end
	return false
end

local tes3_objectType_miscItem = tes3.objectType.miscItem

---@param e activateEventData
local function activateMoreStackables(e)
	if not (e.activator == tes3.player) then
		return
	end
	local targetRef = e.target
	local targetObj = targetRef.baseObject
	local objType = targetObj.objectType
	if objType == tes3_objectType_miscItem then
		if is6thAshStatue(targetObj.id) then
			tes3.addTopic({topic = 'Ash Statue'})
		end
	end
end

local legionUniformsDict = {}
local ordinatorUniformsDict = {}

---@param e equippedEventData
---@param value integer
local function uniformEvent(e, value)
	if not (e.reference == tes3.player) then
		return
	end
	local lcId = e.item.id:lower()
	if legionUniformsDict[lcId] then
		if wearingLegionUni then
			if logLevel1 then
				mwse.log("%s: uniformEvent() wearingLegionUni.value = %s", modPrefix, value)
			end
			wearingLegionUni.value = value
		end
	elseif ordinatorUniformsDict[lcId] then
		if wearingOrdinatorUni then
			if logLevel1 then
				mwse.log("%s: uniformEvent() wearingOrdinatorUni.value = %s", modPrefix, value)
			end
			wearingOrdinatorUni.value = value
		end
	end
end

local function equippedUniform(e)
	uniformEvent(e, 1)
end

local function unequippedUniform(e)
	uniformEvent(e, 0)
end

local function initMoreStackables()
	if not config.moreStackables then
		return
	end
	local on = false
	for obj in tes3.iterateObjects(tes3_objectType_miscItem) do
		---@cast obj tes3misc
		if is6thAshStatue(obj.id) then
			on = true
			obj.script = nil
		end
	end
	toggleEvent(on, 'activate', activateMoreStackables)

	local tes3_objectType_armor = tes3.objectType.armor
	on = false
	for obj in tes3.iterateObjects(tes3_objectType_armor) do
		---@cast obj tes3armor
		if obj.script then
			local lcId = obj.script.id:lower()
			if lcId == 'legionuniform'
			or (lcId == 'ab01lordsmailscript') then
				legionUniformsDict[lcId] = true
				obj.script = nil
				on = true
			elseif lcId == 'ordinatoruniform' then
				ordinatorUniformsDict[lcId] = true
				obj.script = nil
				on = true
			end
		end
	end
	toggleEvent(on, 'equipped', equippedUniform)
	toggleEvent(on, 'unequipped', unequippedUniform)

end

--- @param e uiActivatedEventData
local function uiActivatedMenuRestWait(e)
	local el = e.element:findChild('MenuRestWait_label_text')
	if el then
		el.text = 'You need a bed for resting.'
	end
end

--- @param e uiShowRestMenuEventData
local function uiShowRestMenu(e)
	if e.scripted then
		return
	end
	e.allowRest = false
	event.register('uiActivated', uiActivatedMenuRestWait,
		{filter = 'MenuRestWait', doOnce = true})
end

local function toggleEvents()
	toggleEvent(fixDummySubtitles, 'dialogueFiltered', dialogueFiltered)

	for i = 1, 3 do
		toggleEvent(fixDummySubtitles, 'uiActivated', uiActivatedMenuNotify,
			{filter = string.format('MenuNotify%d', i)})
	end

	local on = false
	if (config.minPlayerSpeed > 0)
	and tes3.player then
		on = true
	end
	toggleEvent(on, 'calcMoveSpeed', calcMoveSpeed)

	on = false
	if config.goToJailTweaks
	and gtj_never_prison_mine then -- GoToJail mod
		on = true
	end
	toggleEvent(on, 'cellChanged', cellChangedGoToJail)

	on = config.fixInteriorWaterLevel
	toggleEvent(on, 'cellChanged', cellChangedFixInteriorWaterLevel)

	--[[on = fixPlacedItemsLighting
		or addBoundSpells
		or disableSittingNPCsCollision
		or addLights
		or addClothes
	toggleEvent(on, 'referenceSceneNodeCreated', referenceSceneNodeCreated)]]

	on = addBoundSpells
	toggleEvent(on, 'activate', activateAddBoundSpells, {priority = 2})

	on = config.preventSwimmingHostilesFromPreventingRest
		or config.NOM_shelterPreventsRestingHostiles
	toggleEvent(on, 'preventRest', preventRest, {priority = 2})

	on = false
	if YAC_CI_GlobalScript then
		if YAC_CI_RunEvery then
			if YAC_CI_ZoomState then
				on = true
			else
				YAC_CI_GlobalScript = nil
			end
		end
	end
	if not on then
		if sao then
			on = true
		end
	end
	if on
	and (not tes3.player) then
		on = false
	end
	---toggleEvent(on, 'activate', activate)
	toggleEvent(on, 'activationTargetChanged', activationTargetChanged)

	toggleEvent(fixSummonAI, 'spellTick', spellTick)
	toggleEvent(disableEmptyThreats, 'infoFilter', infoFilter)

	toggleEvent(onlyBedsAllowResting, 'uiShowRestMenu', uiShowRestMenu)

end

local function toggleCollision()
-- note: the game resets collision on reload anyway so safe enough
	tes3.runLegacyScript({command = 'TCL', source = tes3.compilerSource.console})
end

local function skipBetterClothesWarning()
	-- thanks NullCascade
	-- https://discord.com/channels/210394599246659585/381219559094616064/1388499386446905358
---@diagnostic disable-next-line: undefined-field
	mwse.memory.writeByte({address = 0x4A1B00, byte = 0xEB})
end


local function loaded()
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer

	assert(worldController == tes3.worldController)

	g7_container_mult = tes3.findGlobal('g7_container_mult')

	YAC_CI_GlobalScript = tes3.getScript('YAC_CI_Global')

	if YAC_CI_GlobalScript then
		local config = mwse.loadConfig("MWSE\\config\\abotSWGTK.json", {})
		if config
		and config.targetAutoZoom then
			YAC_CI_GlobalScript = nil
			mwse.log(
'%s: loaded() abotSWGTK config.targetAutoZoom detected, you should disable old "Close Inspection.esp" mod.', modPrefix)
		end
	end

	ab01EigNewClothes1Script = tes3.getScript('ab01EigNewClothes1Script')

	checkCloseInspectionReset() -- try and reset close inspection on reload

	if config.fixFloatingActors
	and player.cell.isInterior then
		local t1
		local function TCL()
			if not tes3.menuMode() then
				if t1 then
					t1:cancel()
					t1 = nil
				end
				toggleCollision()
				timer.delayOneFrame(toggleCollision)
			end
		end
		t1 = timer.start({duration = 1.75, iterations = -1, callback = TCL})
	end

	if config.fixWearingLegionUni then
		config.fixWearingLegionUni = nil -- reset legacy
	end

	-- if fixCarriableLights then
		-- fixBadCarriableLights()
	-- end
	
	-- if fixConstantEffects then
		-- fixBadConstantEffects()
	-- end

	if config.noBetterClothesWarning then
		skipBetterClothesWarning()
	end

	toggleEvents()

end

local function onClose()
	updateFromConfig()
	toggleEvents()
	if g7_container_mult then
		g7_container_mult.value = config.containerWeightMultX100 / 100
	end
	if ab01goldWeight then
		ab01goldWeight.value = config.gold100weight / 100
	end

	if config.guantletToGauntlet then
		local tes3_armorSlot_rightGauntlet = tes3.armorSlot.rightGauntlet
		local tes3_armorSlot_leftGauntlet = tes3.armorSlot.leftGauntlet
		for obj in tes3.iterateObjects(tes3_objectType_armor) do
---@diagnostic disable-next-line: undefined-field
			local slot = obj.slot
			---assert(slot)
			if slot then
				if (slot == tes3_armorSlot_rightGauntlet)
				or (slot == tes3_armorSlot_leftGauntlet) then
					local s = obj.name
					if s then
						local s2 = string.gsub(s,'uantlet','auntlet')
						if not (s == s2) then
							---to make Visual Studio Code Lua diagnostic happy
							---obj.name = s2 -- fix misspelled gauntlets (the chitin ones by default)
							obj['name'] = s2 -- fix misspelled gauntlets (the chitin ones by default)
						end
					end
				end
			end
		end
	end

	if fixCarriableLights then
		fixBadCarriableLights()
	end
	
	if fixConstantEffects then
		fixBadConstantEffects()
	end

	if config.noBetterClothesWarning then
		skipBetterClothesWarning()
	end

	mwse.saveConfig(configName, config, {indent = true})

end


local function modConfigReady()
	worldController = tes3.worldController
	g7_container_mult = tes3.findGlobal('g7_container_mult')
	ab01goldWeight = tes3.findGlobal('ab01goldWeight')
	gtj_never_prison_mine = tes3.findGlobal('gtj_never_prison_mine')
	gtj_global_mine = tes3.findGlobal('gtj_global_mine')

	wearingLegionUni = tes3.findGlobal('wearingLegionUni')
	wearingOrdinatorUni = tes3.findGlobal('wearingOrdinatorUni')

	NOM_shelter = tes3.findGlobal('NOM_shelter')
	YAC_CI_RunEvery = tes3.findGlobal('YAC_CI_RunEvery')
	YAC_CI_ZoomState = tes3.findGlobal('YAC_CI_ZoomState')

	YAC_CI_GlobalScript = tes3.getScript('YAC_CI_Global')
	ab01EigNewClothes1Script = tes3.getScript('ab01EigNewClothes1Script')

	fixSteelCuirass()

	local template = mwse.mcm.createTemplate({name = mcmName,
		config = config, defaultConfig = defaultConfig,
		showDefaultSetting = true, onClose = onClose})

	local function getSaoShader()
		local mgeShadersConfig = mge.shaders
		if not mgeShadersConfig then
			return
		end
		local shaders = mgeShadersConfig.list
		if not shaders then
			return
		end
		local result
		for i = 1, #shaders do
			local v = shaders[i]
			if v then
				local name = v.name
				if name then
					if logLevel2 then
						mwse.log('%s: getSaoShader() name = "%s"', modPrefix, name)
					end
					if string.find(name:lower(), 'sao', 1, true) then
						if logLevel1 then
							mwse.log('%s: getSaoShader() "%s" SAO shader detected', modPrefix, name)
						end
						result = v
						break
					end
				end
			end
		end
		return result
	end
	sao = getSaoShader()

	local sideBarPage = template:createSideBarPage({
		label = modName,
		showHeader = false,
		description = [[Gameplay settings for standard game and some .esp/.esm mods/MGE-XE shaders (when detected).
Note: some settings may need to restart Morrowind.exe to be effective.]],
		showReset = true,
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.4
			self.elements.sideToSideBlock.children[2].widthProportional = 0.6
		end
	})

	local optionList = {'No', 'Yes, No Overburdening', 'Yes, Overburdening'}
	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = string.format("%s. %s", i - 1, optionList[i]), value = i - 1}
		end
		return options
	end

	sideBarPage:createYesNoButton({
		label = 'Disable sitting NPCs collision',
		description = [[Try and fix sitting NPCs floating over stools and chairs.
Effective on game restart.]],
		configKey = 'disableSittingNPCsCollision',
		restartRequired = true
	})

	sideBarPage:createYesNoButton({
		label = 'Transporters lights',
		description = [[Dynamically add lights to caravaners/shipmasters/gondoliers...
Effective on game restart.]],
		configKey = 'addLights',
		restartRequired = true
	})

	sideBarPage:createYesNoButton({
		label = 'Daedra Bound Weapons',
		description = [[Add a Bound Weapon spell to Daedra bipeds.]],
		configKey = 'addBoundSpells'
	})

	sideBarPage:createYesNoButton({
		label = 'Fix placed items lighting',
		description = [[Update lighting for placed/dropped misc and container items.
Usually useful with scripted containers mods.]],
		configKey = 'fixPlacedItemsLighting'
	})

	sideBarPage:createYesNoButton({
		label = 'Fix misspelled gauntlet',
		description = [[Fix misspelled guantlet --> gauntlet.]],
		configKey = 'guantletToGauntlet'
	})

	sideBarPage:createYesNoButton({
		label = 'More stackable items',
		description = [[Makes some items (e.g. Ash Statues, Legion and Ordinator armor pieces...) stackable replacing their local script with equivalent/better MWSE-Lua alternatives.
Effective on game restart.
Note: this also includes/replaces the old fix for more reliably update the WearingLegionUni, now including also WearingOrdinatorUni global variable.]],
		configKey = 'moreStackables',
		restartRequired = true
	})

	if ab01EigNewClothes1Script then
		sideBarPage:createYesNoButton({
			label = 'Add clothes to dancers/naked people',
			description = [[Add clothes to dancers/naked people.]],
			configKey = 'addClothes'
		})
	end

	sideBarPage:createYesNoButton({
		label = 'Prevent swimming hostiles from preventing rest',
			description = [[Prevent swimming hostiles (e.g. slaughterfish) from preventing player resting.]],
		configKey = 'preventSwimmingHostilesFromPreventingRest'
	})

	sideBarPage:createYesNoButton({
		label = 'NOM_shelter prevents resting hostiles',
		description = [[Prevent hostiles from preventing rest when NOM_shelter global variable is set.]],
		configKey = 'NOM_shelterPreventsRestingHostiles'
	})

	sideBarPage:createYesNoButton({
		label = 'Fix floating actors',
		description = [[Toggles Collision off/on again on cell change, warping actors to the floor.
Useful if you experience some floating actors on reload.]],
		configKey = 'fixFloatingActors'
	})

	sideBarPage:createYesNoButton({
		label = 'Fix interior water level',
		description = [[Try and fix water level for interior cells modded to have water but not updating correctly from in-progress games.]],
		configKey = 'fixInteriorWaterLevel'
	})

	local effective1 = '\nWhen enabled, effective on exiting the MCM panel.'
	
	sideBarPage:createYesNoButton({
		label = 'Fix carriable lights',
		description = [[Try and fix carriable lights settings to avoid unexpected glowing player/actors.]]..effective1,
		configKey = 'fixCarriableLights',
		inGameOnly = true
	})

	sideBarPage:createYesNoButton({
		label = 'Fix invalid player constant effects',
		description = [[Try and fix invalid constant effects remaining on player after the source enchanted item/ability/curse is no more available.]]..effective1,
		configKey = 'fixConstantEffects',
		inGameOnly = true
	})

	sideBarPage:createSlider({
		label = 'Minimum player speed',
		description = [[Minimum player speed (even when encumbered).
0 = disabled.]],
		configKey = 'minPlayerSpeed',
		min = 0, max = 100, step = 1, jump = 5
	})

	if gtj_never_prison_mine then -- GoToJail mod
		sideBarPage:createYesNoButton({
			label = 'GoToJail tweaks',
			description = [[Tweaks some goToJail prison mine gameplay (only if the mod is detected).]],
			configKey = 'goToJailTweaks'
		})
	end

	if ab01goldWeight then
		sideBarPage:createSlider({
			label = 'Weight for 100 gold: %s',
			description = [[Suggested: 1, e.g. 100 gold weight = 1, 1 gold weight = 0.01
Set it to 0 to disable gold weight as in vanilla game. Only if ab01goldWeight global variable from abot's gold weight mod is detected.]],
			configKey = 'gold100weight',
			min = 0, max = 100, step = 1, jump = 5
		})
	end

	if g7_container_mult then
		sideBarPage:createSlider({
			label = 'MWSE containers/MWSE containers NOM weight multiplier: %s%%',
			description = 'Suggested: 75, e.g. a 100 weight item becomes 75 perceived weight when packed in a container. Only if g7_container_mult global variable from the mods is detected.',
			configKey = 'containerWeightMultX100',
			min = 0, max = 100, step = 1, jump = 5
		})
	end

	if YAC_CI_GlobalScript then
		sideBarPage:createYesNoButton({
			label = 'Close Inspection tweaks',
			description = [[Yacoby's Close Inspection tweaks to avoid some possible crashes.
Only if the YAC_CI_GlobalScript from the mod is detected.]],
			configKey = 'closeInspectionTweaks'
		})
	end

	if sao then
		sideBarPage:createYesNoButton({
			label = 'SAO shader water tweaks',
			description = [[Automatically disables a detected MGE-XE SAO shader when looking at a water source activator (e.g waterfalls).
This should make water shadow artifacts less noticeable.]],
			configKey = 'saoWaterTweaks'
		})
	end

	sideBarPage:createYesNoButton({
		label = 'Fix empty subtitles',
		description = [[Hide short dummy subtitles needed by some mods to start scripting from dialog.]],
		configKey = 'fixDummySubtitles'
	})

	sideBarPage:createYesNoButton({
		label = 'Skip Better Clothes warnings',
		description = [[Skip some Better Clothes warnings.]],
		configKey = 'noBetterClothesWarning'
	})

	sideBarPage:createYesNoButton({
		label = 'Fix summons AIFollow and Fight settings',
		description = [[Try and fix summoned followers initial AIFollow and Fight settings in case they are incorrect (e.g. aggressive/not following summoned creatures).]],
		configKey = 'fixSummonAI'
	})

	sideBarPage:createYesNoButton({
		label = 'Disable actors empty threats',
		description = [[Skip dead actors voices sometimes still threatening player.
Equivalent of Empty Threats Disabler mod, with MWSE-Lua advantages (e.g. working with any/future attack/hit dialog voices).]],
		configKey = 'disableEmptyThreats'
	})

	sideBarPage:createYesNoButton({
		label = 'Only beds allow resting',
		description = [[Resting is only allowed while using beds (or traveling).]],
		configKey = 'onlyBedsAllowResting'
	})

	optionList = {'Off', 'Low', 'Medium', 'High', 'Max'}
	sideBarPage:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		configKey = 'logLevel'
	})

	event.register('loaded', loaded)
	---timer.register('ab01gplyPT1', ab01gplyPT1)

	mwse.mcm.register(template)

	logConfig(config, {indent = false})

end
event.register('modConfigReady', modConfigReady)

event.register('initialized', function ()
	initMoreStackables()
end, {doOnce = true})

