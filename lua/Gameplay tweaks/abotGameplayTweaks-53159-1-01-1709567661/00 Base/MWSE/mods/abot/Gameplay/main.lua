---@diagnostic disable: deprecated
-- begin configurable parameters
local defaultConfig = {
addBoundSpells = true, -- true = add a bound weapon spell to daedra bipeds
disableSittingNPCsCollision = true,
addLights = true, -- true = dynamically add lights to caravaners/shipmasters/gondoliers
addClothes = true, -- true = add clothes to dancers/naked people
guantletToGauntlet = true, -- fix misspelled guantlet --> gauntlet
fixWearingLegionUni = true, -- fix setting global short variable WearingLegionUni from script wearingLegionUni not always working
preventSwimmingHostilesFromPreventingRest = true, -- NullCascade's trick https://discord.com/channels/210394599246659585/643946536170160138/855273560561418280
NOM_shelterPreventsRestingHostiles = true, -- NOM_shelter global variable set to 1 prevents hostiles when resting
fixFloatingActors = true, -- fix floating actors on reload
fixInteriorWaterLevel = true, -- fix interiors water level not updated correctly
fixPlacedItemsLighting = true, -- fix placed items lighting
fixCarriableLights = false, -- fix carriable lights settings to avoid unexpected glowing player/actors
minPlayerSpeed = 20, -- min Player Speed, even when encumbered
goToJailTweaks = true, -- tweaks some goToJail prison mine gameplay if the mod is detected
gold100weight = 1, -- gold weight X 100 if the mod is detected
containerWeightMultX100 = 75, -- Inventory helpers/MWSE containers weight multiplier X 100
closeInspectionTweaks = true,  -- true to tweak Close Inspection to avoid possible crashes
saoWaterTweaks = true,  -- true to disable SAO shader when looking at water activators
logLevel = 0,
}
-- end configurable parameters

local author = 'abot'
local modName = 'Gameplay'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end

local config = mwse.loadConfig(configName, defaultConfig)
if config.debugLevel then  -- update legacy
	config.logLevel = config.debugLevel
	config.debugLevel = nil
end

---assert(config)

local addBoundSpells, disableSittingNPCsCollision, addLights, addClothes
local fixPlacedItemsLighting, fixCarriableLights, minPlayerSpeed
local closeInspectionTweaks, saoWaterTweaks
local logLevel, logLevel1, logLevel2, logLevel3, logLevel4

local function updateFromConfig()
	addBoundSpells = config.addBoundSpells
	disableSittingNPCsCollision = config.disableSittingNPCsCollision
	addLights = config.addLights
	addClothes = config.addClothes
	fixPlacedItemsLighting = config.fixPlacedItemsLighting
	fixCarriableLights = config.fixCarriableLights
	minPlayerSpeed = config.minPlayerSpeed
	closeInspectionTweaks = config.closeInspectionTweaks
	saoWaterTweaks = config.saoWaterTweaks
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
local ab01EigNewClothes1Script, YAC_CI_GlobalScript, YAC_CI_RunEvery, YAC_CI_ZoomState


local player, mobilePlayer -- set in loaded()


local tes3_objectType_armor = tes3.objectType.armor
local tes3_armorSlot_cuirass = tes3.armorSlot.cuirass

local wearingLegionUni -- set in modConfigready()

local function legionUniCheck()
	tes3.updateInventoryGUI({reference = player}) -- maybe it helps
	local v = wearingLegionUni.value
	---assert(v)
	v = math.floor(v + 0.5)
	local v2 = 0
	local equippedArmorStack = tes3.getEquippedItem({ actor = player, objectType = tes3_objectType_armor, slot = tes3_armorSlot_cuirass })

	if equippedArmorStack then
		local item = equippedArmorStack.object
		---assert(item)
		if item then
			if logLevel2 then
				mwse.log("%s: equipped armor %s", modPrefix, item.id)
			end
			local itemData = equippedArmorStack.itemData
			if itemData then
				local script = itemData.script
				if script then
					local id = script.id:lower()
					if logLevel2 then
						mwse.log("%s: local script %s", modPrefix, id)
					end
					if (id == 'legionuniform')
					or (id == 'ab01lordsmailscript') then
						v2 = 1
						if logLevel1 then
							mwse.log("%s: %s local script found on equipped armor", modPrefix, id)
						end
					end
				end
			end
		end
	end
	if not (v2 == v) then
		if logLevel1 then
			mwse.log("%s: fixing WearingLegionUni global short to %s", modPrefix, v2)
		end
		wearingLegionUni.value = v2
		---assert(wearingLegionUni.value == v2)
	end
end

local function toggleCollision()
	-- note: the game resets collision on reload anyway so safe enough
---@diagnostic disable-next-line: missing-fields
	tes3.runLegacyScript({command = 'TCL'})
end

local function randBoundWeaponSpell()
	return boundWeaponSpells[math.random(1, #boundWeaponSpells)]
end

local function isValidDaedra(obj)
	return (obj.type == tes3_creatureType_daedra)
	and obj.biped
	and obj.usesEquipment
end

local tes3_animationState_dead = tes3.animationState.dead
local tes3_animationState_dying = tes3.animationState.dying

local function isMobileDead(mobile)
	if mobile.health then
		if mobile.health.current then
			if mobile.health.current <= 0 then
				return true
			end
		end
	end
	local actionData = mobile.actionData
	if not actionData then
		return false -- it may happen
	end
	local animState = actionData.animationAttackState
	if not animState then
		return false
	end
	if (animState == tes3_animationState_dead)
	or (animState == tes3_animationState_dying) then
		return true
	end
	return false
end

local tes3_objectType_clothing = tes3.objectType.clothing
local tes3_objectType_light = tes3.objectType.light

local tes3_clothingSlot_shirt = tes3.clothingSlot.shirt
local tes3_clothingSlot_pants = tes3.clothingSlot.pants
local tes3_clothingSlot_skirt = tes3.clothingSlot.skirt

local tes3_activeBodyPartLayer_base = tes3.activeBodyPartLayer.base
local tes3_activeBodyPart_groin = tes3.activeBodyPart.groin
local tes3_activeBodyPart_chest = tes3.activeBodyPart.chest

local function addItem(mobRef, itemId, classId)
	if not mobRef.object.inventory:contains(itemId) then
		mwscript.addItem({reference = mobRef, item = itemId})
		if logLevel1 then
			mwse.log("%s: %s added to %s %s", modPrefix, itemId, classId, mobRef.id)
		end
		mwscript.equip({reference = mobRef, item = itemId})
	end
end

local tes3_actorType_npc = tes3.actorType.npc
local tes3_actorType_creature = tes3.actorType.creature

local function back2slash(s)
	return string.gsub(s, [[\]], [[/]])
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
				mwse.log("%s: mwscript.addItem({reference = %s, item = %s, count = %s})", modPrefix, mobRef, i, c)
			end
			mwscript.addItem({reference = mobRef, item = i, count = c})
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
					mwse.log("%s: mwscript.addSpell({reference = %s, spell = %s})", modPrefix, mobRef, sp)
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

	if disableSittingNPCsCollision then
		if string.multifind(string.lower(back2slash(obj.mesh)),
			{'am_eater', 'am_reader2', 'am_sitbar', 'am_writer'}, 1, true) then
			mob.movementCollision = false
		end
	end

	local objClass = obj.class
	if not objClass then
		---assert(objClass) --it happens a lot /abot
		return
	end

	local classId = objClass.id
	local lcClassId = string.lower(classId)

	if addLights then
		if (lcClassId == 'shipmaster')
		or (lcClassId == 'gondolier') then
			if not mobRef.object.inventory:contains(shipMasterLight) then
				mwscript.addItem({reference = mobRef, item = shipMasterLight})
				if logLevel1 then
					mwse.log("%s: %s added to %s %s", modPrefix, shipMasterLight, classId, mobRef.id)
				end
			end
		elseif lcClassId == 'caravaner' then
			if not mobRef.object.inventory:contains(caravanerLight) then
				mwscript.addItem({reference = mobRef, item = caravanerLight})
				if logLevel1 then
					mwse.log("%s: %s added to %s %s", modPrefix, caravanerLight, classId, mobRef.id)
				end
			end
		end
	end

	if addClothes then
		local function addShirt()
			local itemId = string.format("common_shirt_0%s", math.random(1,5))
			addItem(mobRef, itemId, classId)
		end

		local bpm = mobRef.bodyPartManager

		if bpm then
			local lcId = obj.id:lower()

			local function isClothingSlotEmpty(clothingSlot)
				return not tes3.getEquippedItem({ actor = mobRef, objectType = tes3_objectType_clothing, slot = clothingSlot })
			end

			local bodyPart = bpm:getActiveBodyPart(tes3_activeBodyPartLayer_base, tes3_activeBodyPart_groin)

			if bodyPart
			and bodyPart.node then

				local function addPants()
					local itemId = string.format("common_pants_0%s", math.random(2,5))
					addItem(mobRef, itemId, classId)
				end
				local function addSkirt()
					local itemId = string.format("common_skirt_0%s", math.random(1,7))
					addItem(mobRef, itemId, classId)
				end

				if string.find(lcId, 'dancer', 1, true) then
					if isClothingSlotEmpty(tes3_clothingSlot_pants) then
						if obj.female and ab01EigNewClothes1Script then
							mwscript.startScript({reference = mobRef, script = ab01EigNewClothes1Script})
						else
							addPants()
						end
					end
				elseif string.find(lcId, 'dreamer', 1, true) then
					if obj.female then
						if isClothingSlotEmpty(tes3_clothingSlot_skirt) then
							addSkirt()
						end
					elseif isClothingSlotEmpty(tes3_clothingSlot_pants) then
						addPants()
					end
				elseif lcClassId == 'slave' then
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
				if lcClassId == 'slave' then
					bodyPart = bpm:getActiveBodyPart(tes3_activeBodyPartLayer_base, tes3_activeBodyPart_chest)
					if bodyPart
					and bodyPart.node then
						if isClothingSlotEmpty(tes3_clothingSlot_shirt) then
							if not tes3.getEquippedItem({ actor = mobRef, objectType = tes3_objectType_armor,
									slot = tes3_armorSlot_cuirass }) then
								if mobRef.cell.isInterior and ab01EigNewClothes1Script then
									mwscript.startScript({reference = mobRef, script = ab01EigNewClothes1Script})
								else
									addShirt()
								end
							end
						end
					end
				end
			end -- if obj.female

		end -- if bpm

	end

end

local T3OT = tes3.objectType

local function getTimerRef(e)
	local timer = e.timer
	local data = timer.data
	local handle = data.handle
	if not handle then
		return
	end
	if not handle.valid then
		return
	end
	if not handle:valid() then
		return
	end
	local ref = handle:getObject()
	return ref
end

local function ab01gplyPT1(e)
	local ref = getTimerRef(e)
	if not ref then
		return
	end
	if logLevel2 then
		mwse.log('%s: ab01gplyPT1(e) "%s":updateLighting()', modPrefix, ref.id)
	end
	ref:updateLighting()
end

local function referenceSceneNodeCreated(e)
	local ref = e.reference
	local mob = ref.mobile
	if not mob then
		if (not ref.sourceMod)
		and fixPlacedItemsLighting
		and ref.baseObject.objectType == T3OT.container then
			timer.start({duration = 0.29, type = timer.real, callback = 'ab01gplyPT1',
				data = {handle = tes3.makeSafeObjectHandle(ref)}
			})
		end
		return
	end
	if not mob.actorType then
		return
	end
	if isMobileDead(mob) then
		return
	end
	processActor(ref)
end


local function activateAddBoundSpells(e)
	local targetRef = e.target
	local mobile = targetRef.mobile
	if not mobile then
		return
	end
	local targetObj = targetRef.baseObject
	if isValidDaedra(targetObj) then
		if isMobileDead(mobile) then
			local i = 'daedric arrow'
			local c = tes3.getItemCount({reference = targetRef, item = i})
			if c > 0 then
				mwscript.removeItem({ reference = targetRef, item = i, count = c })
			end
		end
	end
end

local function fixPlayerEncumbrance()
	if mobilePlayer.encumbrance.current > 0 then
		mobilePlayer.encumbrance.current = 0
	end
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
	if math.floor(gtj_never_prison_mine.value + 0.5) >= 1 then
		state = 2
	end
	if state <= 0 then
		return
	end

	local function skipSpecial(item)
-- skip e.g. CDC inventory helpers/MWSE containers light icons
-- MWSE containers is especially nasty as it will block the player forever
-- if you force transfer one of its special light icons into another container
		if string.startswith(item.id:lower(), 'gtj_') then
			return false -- skip GoToJail special items
		end
		local ok
		if item.objectType == tes3_objectType_light then
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

	if tes3.transferInventory({from = player, to = destRef, filter = skipSpecial,
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
	if math.floor(gtj_never_prison_mine.value + 0.5) < 1 then
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
	if cell == e.previousCell then
		assert(false) -- should never happen?
		return
	end
	if logLevel3 then
		mwse.log("%s: cellChangedGoToJail(e)", modPrefix)
	end
	event.register('simulate', simulate)
end

local NOM_shelter -- set in modConfigready()

local function preventRest(e)
	if config.preventSwimmingHostilesFromPreventingRest then
		if e.mobile.isSwimming and (not mobilePlayer.isSwimming) then
			return false
		end
	end
	if config.NOM_shelterDisablesRestingHostiles then
		if NOM_shelter then
			if math.floor(NOM_shelter.value + 0.5) > 0 then
				return false
			end
		end
	end
end

local sao -- set in modConfigReady()


--[[
Tip: This event can be filtered based on the current event data.
Tip: An event can be claimed by setting e.claim to true, or by returning false from the callback. Claiming the event prevents any lower priority callbacks from being called.
Event Data:
current (tes3reference): Read-only. The activation target for the player, should they press the activation key.
previous (tes3reference): Read-only. The previous activation target.
]]

local saoBlacklist = {'water','nom_source','spout','crystal','pool'}
local function checkSao(ref)
	if not ref then
		return
	end
	if not sao then
		return
	end
	local lcId = ref.object.id:lower()
	if string.multifind(lcId, saoBlacklist, 1, true) then
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

local function activationTargetChanged(e)
	if saoWaterTweaks then
		if e then
			checkSao(e.current)
		end
	end
	if not closeInspectionTweaks then
		return
	end
	if not YAC_CI_GlobalScript then
		return
	end
	local c = YAC_CI_GlobalScript.context -- note: context field/variables are case sensitive
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
		mwse.log("%s: activationTargetChanged(), resetting YAC_CI_GlobalScript", modPrefix)
	end
end

local function removeBadLights(light)
	local c, inventory, ref
	
	local function removeBadLight(obj)
		inventory = obj.inventory
		c = math.abs(inventory:getItemCount(light))
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
	
	for obj in tes3.iterateObjects({tes3.objectType.container,
			tes3.objectType.creature, tes3.objectType.npc}) do
		removeBadLight(obj)
	end
	ref = tes3.player
	if ref then
		removeBadLight(ref.object)
	end
end

local function fixBadCarriableLights()
	for obj in tes3.iterateObjects(tes3.objectType.light) do
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

local function toggleEvent(on, eventName, eventFunc, options)
	local currentlyOn = event.isRegistered(eventName, eventFunc, options)
	if on == currentlyOn then
		return
	end
	local regOrUnreg
	if on then
		if logLevel2 then
			mwse.log('%s: "%s" registered', modPrefix, eventName)
		end			
		regOrUnreg = event.register
	else
		if logLevel2 then
			mwse.log('%s: "%s" unregistered', modPrefix, eventName)
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

local function loaded()

	player = tes3.player
	mobilePlayer = tes3.mobilePlayer

	if config.fixFloatingActors then
		local t1
		local function TCL()
			if not tes3ui.menuMode() then
				if t1 then
					t1:cancel()
					t1 = nil
				end
				toggleCollision()
				timer.frame.delayOneFrame(toggleCollision)
			end
		end
		t1 = timer.start({duration = 2, iterations = -1, callback = TCL})
	end

	if closeInspectionTweaks then
		activationTargetChanged() -- try and reset close inspection on reload
	end

	if config.fixWearingLegionUni then
		legionUniCheck()
	end

	if config.fixCarriableLights then
		fixBadCarriableLights()
	end

	toggleEvent(config.minPlayerSpeed > 0, 'calcMoveSpeed', calcMoveSpeed)
		
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
	if waterLevel then
		if not cell.hasWater then
			if waterLevel > -9999999999 then
				cell.hasWater = true
				cell.waterLevel = math.floor(waterLevel)
			end
		end
	end
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId, table = config}
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
	if sourceMod == 'Bloodmoon.esm' then
		local femalePart = tes3.getObject('A_Steel_Cuir_Female')
		if femalePart then
			mwse.log("%s: steel_cuirass female body part fixed to %s", modPrefix, femalePart)
---@diagnostic disable-next-line: assign-type-mismatch
			steel_cuirass.parts[1].female = femalePart
		end
	end
end

--[[
-- used in modConfigready for event toggle
local cellChangedGoToJailRegistered = false
local cellChangedFixInteriorWaterLevelRegistered = false
local referenceSceneNodeCreatedRegistered = false
local activateAddBoundSpellsRegistered = false
local preventRestRegistered = false
local activationTargetChangedRegistered = false
]]

local function modConfigReady()
	---sYes = tes3.findGMST(tes3.gmst.sYes).value
	---sNo = tes3.findGMST(tes3.gmst.sNo).value
	g7_container_mult = tes3.findGlobal('g7_container_mult')
	ab01goldWeight = tes3.findGlobal('ab01goldWeight')
	gtj_never_prison_mine = tes3.findGlobal('gtj_never_prison_mine')
	gtj_global_mine = tes3.findGlobal('gtj_global_mine')
	YAC_CI_GlobalScript = tes3.getScript('YAC_CI_Global')
	wearingLegionUni = tes3.findGlobal('wearingLegionUni')
	ab01EigNewClothes1Script = tes3.getScript('ab01EigNewClothes1Script')
	NOM_shelter = tes3.findGlobal('NOM_shelter')
	YAC_CI_RunEvery = tes3.findGlobal('YAC_CI_RunEvery')
	YAC_CI_ZoomState = tes3.findGlobal('YAC_CI_ZoomState')

	fixSteelCuirass()

	local template = mwse.mcm.createTemplate(mcmName)

	local function getSaoShader()
		local mgeShadersConfig = mge.shaders
		if not mgeShadersConfig then
			return nil
		end
		local shaders = mgeShadersConfig.list
		if not shaders then
			return nil
		end
		local result, v, name
		for i = 1, #shaders do
			v = shaders[i]
			if v then
				name = v.name
				if name then
					if name:lower():find('sao', 1, true) then
						result = v
						break
					end
				end
			end
		end
		return result
	end
	sao = getSaoShader()

	template.onClose = function()

		updateFromConfig()

		if g7_container_mult then
			g7_container_mult.value = config.containerWeightMultX100 / 100
		end
		if ab01goldWeight then
			ab01goldWeight.value = config.gold100weight / 100
		end

		if config.guantletToGauntlet then
			local tes3_armorSlot_rightGauntlet = tes3.armorSlot.rightGauntlet
			local tes3_armorSlot_leftGauntlet = tes3.armorSlot.leftGauntlet
			local s, s2, slot
			for obj in tes3.iterateObjects(tes3_objectType_armor) do
	---@diagnostic disable-next-line: undefined-field
				slot = obj.slot
				---assert(slot)
				if slot then
					if (slot == tes3_armorSlot_rightGauntlet)
					or (slot == tes3_armorSlot_leftGauntlet) then
						s = obj.name
						if s then
							s2 = string.gsub(s,'uantlet','auntlet')
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

		local function setCellChangedGoToJail(on)
			toggleEvent(on, 'cellChanged', cellChangedGoToJail)
		end

		local function setCellChangedFixInteriorWaterLevel(on)
			toggleEvent(on, 'cellChanged', cellChangedFixInteriorWaterLevel)
		end	

		local function setReferenceSceneNodeCreated(on)
			toggleEvent(on, 'referenceSceneNodeCreated', referenceSceneNodeCreated)
		end
		
		local function setActivateAddBoundSpells(on)
			toggleEvent(on, 'activate', activateAddBoundSpells, {priority = 2})
		end

		local function setPreventRest(on)
			toggleEvent(on, 'preventRest', preventRest, {priority = 2})
		end

		local function setActivationTargetChanged(on)
			toggleEvent(on, 'activationTargetChanged', activationTargetChanged)
		end

		local on = false
		if config.goToJailTweaks
		and gtj_never_prison_mine then -- GoToJail mod
			on = true
		end
		setCellChangedGoToJail(on)

		on = config.fixInteriorWaterLevel
		setCellChangedFixInteriorWaterLevel(on)

		on = fixPlacedItemsLighting
			or addBoundSpells
			or disableSittingNPCsCollision
			or addLights
			or addClothes
		setReferenceSceneNodeCreated(on)

		on = addBoundSpells
		setActivateAddBoundSpells(on)

		on = config.preventSwimmingHostilesFromPreventingRest
			or config.NOM_shelterPreventsRestingHostiles
		setPreventRest(on)

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
		setActivationTargetChanged(on)

		if config.fixCarriableLights then
			fixBadCarriableLights()
		end

		toggleEvent(config.minPlayerSpeed > 0, 'calcMoveSpeed', calcMoveSpeed)
		
		mwse.saveConfig(configName, config, {indent = true})

	end

		-- Preferences Page
	local preferences = template:createSideBarPage{
		label="Info",
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.4
			self.elements.sideToSideBlock.children[2].widthProportional = 0.6
		end
	}

	local sidebar = preferences.sidebar
	sidebar:createInfo({text = [[Gameplay settings for standard game and some .esp/.esm mods/MGE-XE shaders (when detected).
Note: some settings may need to restart Morrowind.exe to be effective.]]})


	--[[local function getDescription(frmt, variableId)
		return string.format(frmt, defaultConfig[variableId])
	end]]

	local function getDescription(frmt, variableId)
		return string.format(frmt, defaultConfig[variableId])
	end
	
	local yesOrNo = {[false] = 'No', [true] = 'Yes'}

	local function getYesNoDescription(frmt, variableId)
		return string.format(frmt, yesOrNo[defaultConfig[variableId]])
	end

	local optionList = {'No', 'Yes, No Overburdening', 'Yes, Overburdening'}
	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = string.format("%s", optionList[i]), value = i - 1}
		end
		return options
	end

	local function getDropDownDescription(frmt, variableId)
		local i = defaultConfig[variableId]
		return string.format(frmt, string.format('%s', i, optionList[i+1]))
	end

	---local controls = preferences:createCategory{label = mcmName}
	local controls = preferences:createCategory({})

	controls:createYesNoButton({
		label = 'Disable sitting NPCs collision',
		description = getYesNoDescription([[Default: %s.
Try and fix sitting NPCs floating over stools and chairs.
Effective on game restart.]], 'disableSittingNPCsCollision'),
		variable = createConfigVariable('disableSittingNPCsCollision')
	})

	controls:createYesNoButton({
		label = 'Transporters lights',
		description = getYesNoDescription([[Default: %s.
Dynamically add lights to caravaners/shipmasters/gondoliers...
Effective on game restart.]], 'addLights'),
		variable = createConfigVariable('addLights')
	})

	controls:createYesNoButton({
		label = 'Daedra Bound Weapons',
		description = getYesNoDescription([[Default: %s.
Add a Bound Weapon spell to Daedra bipeds.]], 'addBoundSpells'),
		variable = createConfigVariable('addBoundSpells')
	})

	controls:createYesNoButton({
		label = 'Fix placed items lighting',
		description = getYesNoDescription([[Default: %s.
Update lighting for placed/dropped misc and container items.
Usually useful with scripted containers mods.]], 'fixPlacedItemsLighting'),
		variable = createConfigVariable('fixPlacedItemsLighting')
	})

	controls:createYesNoButton({
		label = 'Fix misspelled gauntlet',
		description = getYesNoDescription([[Default: %s.
Fix misspelled guantlet --> gauntlet.]], 'guantletToGauntlet'),
		variable = createConfigVariable('guantletToGauntlet')
	})

	controls:createYesNoButton({
		label = 'Fix WearingLegionUni',
		description = getYesNoDescription([[Default: %s.
Try and fix setting global short variable WearingLegionUni from script wearingLegionUni not always working.]], 'guantletToGauntlet'),
		variable = createConfigVariable('fixWearingLegionUni')
	})

	if ab01EigNewClothes1Script then
		controls:createYesNoButton({
			label = 'Add clothes to dancers/naked people',
			description = getYesNoDescription([[Default: %s.
Add clothes to dancers/naked people.]], 'addClothes'),
			variable = createConfigVariable('addClothes')
		})
	end

	controls:createYesNoButton({
		label = 'Prevent swimming hostiles from preventing rest',
			description = getYesNoDescription([[Default: %s.
Prevent swimming hostiles (e.g. slaughterfish) from preventing player resting.]],
'preventSwimmingHostilesFromPreventingRest'),
		variable = createConfigVariable('preventSwimmingHostilesFromPreventingRest')
	})

	controls:createYesNoButton({
		label = 'NOM_shelter prevents resting hostiles',
		description = getYesNoDescription([[Default: %s.
Prevent hostiles from preventing rest when NOM_shelter global variable is set.]],
'NOM_shelterPreventsRestingHostiles'),
		variable = createConfigVariable('NOM_shelterPreventsRestingHostiles')
	})

	controls:createYesNoButton({
		label = 'Fix floating actors',
		description = getYesNoDescription([[Default: %s.
Toggles Collision off/on again on cell change, warping actors to the floor.
Useful if you experience some floating actors on reload.]],
'fixFloatingActors'),
		variable = createConfigVariable('fixFloatingActors')
	})

	controls:createYesNoButton({
		label = 'Fix interior water level',
		description = getYesNoDescription([[Default: %s.
Try and fix water level for interior cells modded to have water but not updating correctly from in-progress games.]],
'fixInteriorWaterLevel'),
		variable = createConfigVariable('fixInteriorWaterLevel')
	})

	controls:createYesNoButton({
		label = 'Fix carriable lights',
		description = getYesNoDescription([[Default: %s.
Try and fix carriable lights settings to avoid unexpected glowing player/actors.]],
'fixCarriableLights'), inGameOnly = true,
		variable = createConfigVariable('fixCarriableLights')
	})

	controls:createSlider({
		label = 'Minimum player speed',
		description = getDescription([[Default: %s.
Minimum player speed (even when encumbered).
0 = disabled.]], 'minPlayerSpeed'),
		variable = createConfigVariable('minPlayerSpeed')
		,min = 0, max = 100, step = 1, jump = 5
	})
	
	if gtj_never_prison_mine then -- GoToJail mod
		controls:createYesNoButton({
			label = 'GoToJail tweaks',
			description = getYesNoDescription([[Default: %s.
Tweaks some goToJail prison mine gameplay (only if the mod is detected).]],
'goToJailTweaks'),
			variable = createConfigVariable('goToJailTweaks')
		})
	end

	if ab01goldWeight then
		controls:createSlider({
			label = 'Weight for 100 gold: %s',
			description = [[Suggested: 1, e.g. 100 gold weight = 1, 1 gold weight = 0.01
Set it to 0 to disable gold weight as in vanilla game. Only if ab01goldWeight global variable from abot's gold weight mods is detected.]],
			variable = createConfigVariable('gold100weight')
			,min = 0, max = 100, step = 1, jump = 5
		})
	end

	if g7_container_mult then
		controls:createSlider({
			label = 'MWSE containers/MWSE containers NOM weight multiplier: %s%%',
			description = 'Suggested: 75, e.g. a 100 weight item becomes 75 perceived weight when packed in a container. Only if g7_container_mult global variable from the mods is detected.',
			variable = createConfigVariable('containerWeightMultX100')
			,min = 0, max = 100, step = 1, jump = 5
		})
	end

	optionList = {
		'Reset (all lights on)',
		'Randomly skip 75% of spawned lights (suggested)',
		'Skip all lights',
	}

	if YAC_CI_GlobalScript then
		controls:createYesNoButton({
			label = 'Close Inspection tweaks',
			description = getYesNoDescription(
[[Yacoby's Close Inspection tweaks to avoid some possible crashes.
Suggested: %s. Only if the YAC_CI_GlobalScript from the mod is detected.]],
'closeInspectionTweaks'),
			variable = createConfigVariable('closeInspectionTweaks')
		})
	end

	if sao then
		controls:createYesNoButton({
			label = 'SAO shader water tweaks',
			description = getYesNoDescription(
[[Automatically disables a detected MGE-XE SAO shader when looking at a water source activator (e.g waterfalls).
Default: %s. This should make water shadow artifacts less noticeable.]],
'saoWaterTweaks'),
			variable = createConfigVariable('saoWaterTweaks')
		})
	end


	optionList = {'Off', 'Low', 'Medium', 'High', 'Max'}
	controls:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		description = getDropDownDescription('Default: %s','logLevel'),
		variable = createConfigVariable('logLevel')
	})

	event.register('loaded', loaded)
	timer.register('ab01gplyPT1', ab01gplyPT1)

	mwse.mcm.register(template)

	logConfig(config, {indent = false})

end
event.register('modConfigReady', modConfigReady)
