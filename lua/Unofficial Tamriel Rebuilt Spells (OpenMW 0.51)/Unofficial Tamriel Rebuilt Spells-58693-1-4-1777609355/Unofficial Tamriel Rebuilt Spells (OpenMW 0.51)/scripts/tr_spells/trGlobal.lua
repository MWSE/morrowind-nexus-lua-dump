world = require('openmw.world')
core = require('openmw.core')
types = require('openmw.types')
util = require('openmw.util')
I = require('openmw.interfaces')

local trData = require('scripts.tr_spells.trData')
local containerLeveledLists = require('scripts.tr_spells.container_lists')
local leveledLists = require('scripts.tr_spells.leveled_lists')
local boundRecords = require('scripts.tr_spells.boundRecords')

local v3 = util.vector3

local function getStaticModel(recordId)
	local rec = types.Static.records[recordId]
	if rec then return rec.model end
	return nil
end

local ACTOR_SUMMON_SCRIPT = 'scripts/tr_spells/trActor.lua'
local SUMMON_AI_SCRIPT    = 'scripts/tr_spells/trSummon.lua'

local nextSummonCheck = 0
local SUMMON_CHECK_INTERVAL = 0.5

-- =====================================================
-- Insight
-- =====================================================

local function resolveLeveledList(id, depth)
	depth = depth or 0
	if depth > 10 then return nil end
	local entries = leveledLists[id]
	if not entries then return id end  
	local pick = entries[math.random(1, #entries)]
	return resolveLeveledList(pick, depth + 1)
end

local function applyInsightLoot(player, cont)
	if saveData.inspectedContainers[cont.id] then return end
	saveData.inspectedContainers[cont.id] = true
	local lists = containerLeveledLists[cont.recordId]
	if not lists then return end
	local mag = types.Actor.activeEffects(player):getEffect("t_mysticism_insight").magnitude
	local success = true
	while success do
		if math.random() < mag/100 then
			local listId = lists[math.random(1, #lists)]
			local itemId = resolveLeveledList(listId)
			if itemId then
				world.createObject(itemId, 1):moveInto(cont.type.inventory(cont))
			end
			mag = mag * 0.8
		else
			success = false
		end
	end
end

-- ===============================
-- Banishing
-- ===============================

local function checkBanishSigils()
	for i = #saveData.banishSigils, 1, -1 do
		local entry = saveData.banishSigils[i]
		local container = entry.container
		local light = entry.light
		
		if not container or not container:isValid()
			or #types.Container.content(container):getAll() == 0
		then
			core.sendGlobalEvent("SpawnVfx", {
				model = "meshes/td/td_vfx_banish.nif",--"meshes/e/soultraphit.nif",
				position = light.position- v3(0,0,30),
				options = {scale = 0.50}
			})
			core.sound.playSound3d("mysticism area", light)
			if light and light:isValid() then
				light:remove()
			end
			if container and container:isValid() then
				container:remove()
			end
			table.remove(saveData.banishSigils, i)
		end
	end
end

local function TD_BanishDelete(data)
	local actor = data.actor
	if not actor or not actor:isValid() then return end
	
	local inv = types.Actor.inventory(actor)
	if not inv:isResolved() then inv:resolve() end
	
	local keepItems = {}
	local removedItems = 1
	for _, item in ipairs(inv:getAll()) do
		local id = item.recordId
		if id ~= "ingred_daedras_heart_01"
			and id ~= "ingred_daedra_skin_01"
			and id ~= "ingred_scamp_skin_01"
			and id ~= "t_ingcrea_dridreasilk_01"
			and id ~= "t_ingcrea_prismaticdust_01"
		then
			keepItems[#keepItems + 1] = item
		else
			removedItems = removedItems + 1
		end
	end
	local bonusChance = 0
	if removedItems > 0 and #keepItems == 0 then
		bonusChance = 0.2
	end
	if data.caster then
		bonusChance = bonusChance + types.Actor.activeEffects(data.caster):getEffect("t_mysticism_insight").magnitude / 100
	end
	bonusChance = math.random() < bonusChance and 1 or 0
	
	if #keepItems > 0 or bonusChance > 0 then
		local bbox = actor:getBoundingBox()
		
		-- scale 2/3 as baseline, 1.0x at lvl 22
		local level = types.Actor.stats.level(actor).current
		local scale = math.min(1.0, (2/3) + (level - 1) * 0.015)
		
		local sigilPos = v3(
			actor.position.x,
			actor.position.y,
			bbox.center.z + bbox.halfSize.z * scale
		)
		
		local container = world.createObject("t_glb_banishdae_empty")
		container:teleport(actor.cell, sigilPos)
		container:setScale(scale)
		
		local containerInv = types.Container.content(container)
		for _, item in ipairs(keepItems) do
			item:moveInto(containerInv)
		end
		if bonusChance > 0 and leveledLists.t_mw_lvl_weaponsdaedra then
			local randomItem = resolveLeveledList("t_mw_lvl_weaponsdaedra")
			local bonus = world.createObject(randomItem, 1)
			bonus:moveInto(containerInv)
		end
		local light = world.createObject("t_glb_banishdae_light")
		light:teleport(actor.cell, sigilPos)
		light:setScale(scale)
		saveData.banishSigils[#saveData.banishSigils + 1] = {
			container = container,
			light     = light,
		}
	end
	actor:remove()
end

-- ===============================
-- Summoning
-- ===============================

local function spawnSummon(data)
	local summoner = data.summoner
	
	if not summoner or not summoner:isValid() then return end
	
	local creatureId = data.creatureId
	
	local yaw = summoner.rotation:getYaw()
	local offset = v3(math.sin(yaw), math.cos(yaw), 0) * 150
	local spawnPos = summoner.position + offset
	
	local creature = world.createObject(creatureId)
	creature:teleport(summoner.cell, spawnPos, {
		onGround = true,
		rotation = util.transform.rotateZ(yaw + math.pi),
	})
	
	creature:addScript(SUMMON_AI_SCRIPT)
	creature:addScript(ACTOR_SUMMON_SCRIPT)
	
	creature:sendEvent('StartAIPackage', {
		type = 'Follow',
		target = summoner,
		cancelOther = true,
		sideWithTarget = true,
		isRepeat = true,
	})
	
	local vfxModel = getStaticModel("vfx_summon_start")
	if vfxModel then
		creature:sendEvent('AddVfx', { model = vfxModel })
	end
	
	creature:sendEvent('PlaySound3d', { sound = "conjuration cast" })
	
	saveData.activeSummons[data.key] = {
		creature = creature,
		summoner = summoner,
		activeSpellId = data.activeSpellId,
	}
end

local function despawnSummon(data)
	local entry = saveData.activeSummons[data.key]
	if not entry then return end
	
	local creature = entry.creature
	if creature and creature:isValid() then
		local vfxModel = getStaticModel("vfx_summon_end")
		if vfxModel then
			world.vfx.spawn(vfxModel, creature.position)
		end
		creature:sendEvent('PlaySound3d', { sound = "conjuration hit" })
		creature:remove()
	end
	saveData.activeSummons[data.key] = nil
end

local function checkDeadSummons()
	for key, entry in pairs(saveData.activeSummons) do
		local creature = entry.creature
		if not creature or not creature:isValid() then
			saveData.activeSummons[key] = nil
		elseif types.Actor.isDead(creature) then
			local summoner = entry.summoner
			
			-- spell effect will stay active but it's the best we can do
			local hasMultipleSummons = false
			if entry.activeSpellId then
				for otherKey, otherEntry in pairs(saveData.activeSummons) do
					if otherKey ~= key
						and otherEntry.activeSpellId == entry.activeSpellId
						and otherEntry.summoner == summoner
					then
						hasMultipleSummons = true
						break
					end
				end
			end
			
			if not hasMultipleSummons and summoner and summoner:isValid() and entry.activeSpellId then
				types.Actor.activeSpells(summoner):remove(entry.activeSpellId)
			end
			local vfxModel = getStaticModel("vfx_summon_end")
			if vfxModel then
				world.vfx.spawn(vfxModel, creature.position)
			end
			creature:remove()
			saveData.activeSummons[key] = nil
		end
	end
end

-- TD_DaedricSummonCrime (illegal daedra)
local function daedricSummonCrime(data)
	local player = data.player
	if not player or not player:isValid() then return end
	if not I.Crimes then return end
	
	I.Crimes.commitCrime(player, {
		type = types.Player.OFFENSE_TYPE.Assault,
	})
end

-- ===============================
-- Bound items
-- ===============================

local function despawnBoundItem(item)
	if not item or not item:isValid() then return end
	if item.count <= 0 then return end
	if not item.parentContainer then
		core.sound.playSound3d("conjuration hit", item)
		core.sendGlobalEvent("SpawnVfx", {
			model = "meshes/e/magic_summon.nif",
			position = item.position,
			options = {scale = 0.3}
		})
	end
	item:remove()
end

local function handleBoundSpawn(data)
	local actor = data.actor
	if not actor or not actor:isValid() then return end
	
	local forActor = {} 
	for _, slotItem in ipairs(data.slotItems) do
		local resolvedId = boundRecords.resolve(actor, slotItem.baseRecordId)
		local item = world.createObject(resolvedId)
		item:moveInto(types.Actor.inventory(actor))
--		print(item, item.type.record(item).name)
		forActor[slotItem.slot] = { item = item }
	end
	
	actor:sendEvent('TD_BoundEquip', {
		key   = data.key,
		items = forActor,
	})
end

local function handleBoundDespawn(data)
	if not data.items then return end
	for _, item in ipairs(data.items) do
		despawnBoundItem(item)
	end
end

local function blinkTeleportPlayer(data)
	local player = world.players[1]
	if not player or not player:isValid() then return end
	core.sendGlobalEvent("SpawnVfx", {
		model = "meshes/steam_lavariver.nif",
		position = data.destination - v3(0, 0, 19),
		options = {scale = 0.15}
	})	
	if data.rotation then
		player:teleport(player.cell, data.destination, {
			rotation = data.rotation,--util.transform.rotateZ(data.yaw),
		})
	else
		player:teleport(player.cell, data.destination)
	end
end

local function blinkSwap(data)
	local a = data.a
	local b = data.b
	if not a or not b then return end
	if not a.actor or not a.actor:isValid() then return end
	if not b.actor or not b.actor:isValid() then return end
	
	local cellA = a.actor.cell
	local cellB = b.actor.cell
	
	a.actor:teleport(cellB, a.destination, {
		rotation = util.transform.rotateZ(a.yaw),
	})
	b.actor:teleport(cellA, b.destination, {
		rotation = util.transform.rotateZ(b.yaw),
	})
end

local function blinkTeleportActor(data)
	if not data.actor or not data.actor:isValid() then return end
	
	data.actor:teleport(data.actor.cell, data.destination, {
		rotation = util.transform.rotateZ(data.yaw),
	})
end

local BLINK_PREVIEW_VFX_ID = "TR_BlinkPreview"
local BLINK_PREVIEW_VFX_ID2 = "TR_BlinkPreview2"
local blinkPreviewActive = false

local function blinkPreviewHide()
	if blinkPreviewActive then
		world.vfx.remove(BLINK_PREVIEW_VFX_ID)
		world.vfx.remove(BLINK_PREVIEW_VFX_ID2)
		blinkPreviewActive = false
	end
end

local function blinkPreviewShow(data)
	if not data or not data.position or not data.model then return end
	
	if blinkPreviewActive then
		world.vfx.remove(BLINK_PREVIEW_VFX_ID)
		world.vfx.remove(BLINK_PREVIEW_VFX_ID2)
	end
	
	world.vfx.spawn(data.model, data.position+data.offset, {
		vfxId           = BLINK_PREVIEW_VFX_ID,
		loop            = true,
		scale           = data.scale or 1,
		useAmbientLight = false,
	})
	if data.model2 then
		world.vfx.spawn(data.model2, data.position+data.offset2, {
			vfxId           = BLINK_PREVIEW_VFX_ID2,
			loop            = true,
			scale           = data.scale2 or 1,
			useAmbientLight = false,
		})
	end
	blinkPreviewActive = true
end

-- ===============================
-- Kyne's Intervention
-- ===============================

-- because we can't get the region or position of an interior cell
local function getClosestExteriorCell(cell, position)
	local cellToDo = { {cell, position} }
	local traversedCells = {}
	while #cellToDo > 0 do
		local current = table.remove(cellToDo, 1) 
		if current[1].isExterior then
			return current[1], current[2], false
		elseif current[1]:hasTag("QuasiExterior") then
			return current[1], current[2], true
		end
		if not traversedCells[current[1].id] then
			traversedCells[current[1].id] = true
			for _, door in ipairs(current[1]:getAll(types.Door)) do
				if types.Door.isTeleport(door) then
					local dest = types.Door.destCell(door)
					if dest and not traversedCells[dest.id] then
						table.insert(cellToDo, {dest, types.Door.destPosition(door)})
					end
				end
			end
		end
	end
	return nil
end

-- only allow teleporting from here (add more regions as SHOTN gets updated)
local skyrimRegions = {
	["druadach highlands region"] = true,
	["falkheim region"] = true,
	["lorchwuir heath region"] = true,
	["vorndgad forest region"] = true,
	["midkarth region"] = true,
	["sundered hills region"] = true,
	["grey plains region"] = true,
}

local function kyneIntervention(player)
	local searchCell, searchPos = getClosestExteriorCell(player.cell, player.position)
	if not searchCell then -- error? interior with no connection outside
		player:sendEvent('ShowMessage', {
			message = core.getGMST('sTeleportDisabled') or "Teleportation is disabled here."
		})
		return
	end
	
	-- only works in skyrim
	if not skyrimRegions[searchCell.region] then
		player:sendEvent('ShowMessage', {
			message = "The power of Kyne does not extend to these lands."
		})
		return
	end
	
	local bestDist = math.huge
	local bestRotation = nil
	local bestPos = nil
	local bestCell = nil
	local bestMarker = nil
	
	-- grab the nearest marker in skyrim
	for _, cell in ipairs(world.cells) do
		if cell.isExterior and skyrimRegions[cell.region] then
			local statics = cell:getAll(types.Static)
			if statics then
				for _, obj in ipairs(statics) do
					if obj.recordId == trData.KYNE_MARKER_ID then
						local dist = (obj.position - searchPos):length()
						if dist < bestDist then
							bestDist = dist
							bestPos = obj.position
							bestCell = cell
							bestRotation = obj.rotation
						end
					end
				end
			end
		end
	end
	
	-- fallback markers, hardcoded
	if not bestPos then
		for contentFile, markers in pairs(trData.KYNE_MARKERS) do
			if core.contentFiles.has(contentFile) then
				for _, marker in ipairs(markers) do
					local markerPos = v3(marker.position[1], marker.position[2], marker.position[3])
					local dist = (markerPos - searchPos):length()
					if dist < bestDist then
						bestDist = dist
						bestPos = markerPos
						bestCell = world.getExteriorCell(marker.x, marker.y)
						bestMarker = marker
						if marker.rotation then
							bestRotation = util.transform.rotateZ(marker.rotation)
						else
							bestRotation = nil
						end
					end
				end
			end
		end
	end
	
	if bestPos and bestCell then
		player:teleport(bestCell, bestPos, { onGround = true, rotation = bestRotation })
	else
		player:sendEvent('ShowMessage', {
			message = "No nearby shrine can be found."
		})
	end
end

-- ===============================
-- Resartus
-- ===============================

local maxDurabilityCache = {}

local function getMaxDurability(item)
	local record = item.type.record(item)
	if not record then return nil end
	local cached = maxDurabilityCache[record.id]
	if cached ~= nil then
		return cached or nil
	end
	local health = record.health
	if not health or health <= 0 then
		maxDurabilityCache[record.id] = false
		return nil
	end
	maxDurabilityCache[record.id] = health
	return health
end

local function resartus(data)
	local actor = data.actor
	local magnitude = data.magnitude or 20
	local equipment = types.Actor.getEquipment(actor)
	
	if data.kind == "armor" then
		for _, item in pairs(equipment) do
			if types.Armor.objectIsInstance(item) then
				local maxHealth = getMaxDurability(item)
				if maxHealth then
					local amount = math.floor(maxHealth * magnitude / 100) + magnitude
					if amount > 0 then
						core.sendGlobalEvent('ModifyItemCondition', {
							actor = actor,
							item = item,
							amount = amount,
						})
					end
				end
			end
		end
	elseif data.kind == "weapon" then
		local weapon = equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight]
		if weapon and types.Weapon.objectIsInstance(weapon) then
			local maxHealth = getMaxDurability(weapon)
			if maxHealth then
				local amount = math.floor(maxHealth * magnitude / 100) + magnitude
				if amount > 0 then
					core.sendGlobalEvent('ModifyItemCondition', {
						actor = actor,
						item = weapon,
						amount = amount,
					})
				end
			end
		end
	end
end

-- ===============================
-- Radiant Shield
-- ===============================

local function applyBlind(data)
	if not data.target or not data.target:isValid() then return end
	
	local magnitude = math.min(math.floor(data.magnitude or 1), 127)
	local indices = {}
	local bit = 0
	local remaining = magnitude
	while remaining > 0 do
		if remaining % 2 == 1 then
			table.insert(indices, bit)
		end
		remaining = math.floor(remaining / 2)
		bit = bit + 1
	end
	if #indices == 0 then return end
	
	types.Actor.activeSpells(data.target):add({
		id = "t_alteration_radshield_blind",
		effects = indices,
		ignoreResistances = true,
		ignoreSpellAbsorption = true,
		ignoreReflect = true,
	})
	
	data.target:sendEvent('TD_RadiantShieldHitVfx', {})
end

-- =====================================================
-- Passwall teleport
-- =====================================================

local function passwallCheckTrespass(player, targetObj)
	if not targetObj or not targetObj:isValid() then return end
	if not targetObj.owner then return end
	if not types.Lockable.isLocked(targetObj) then return end
	
	if targetObj.globalVariable then
		local globals = world.mwscript.getGlobalVariables(player)
		if globals[targetObj.globalVariable] ~= 0 then return end
	end
	
	local ownerData = targetObj.owner
	local trespassing = false
	
	if ownerData.recordId then
		trespassing = true
	elseif ownerData.factionId then
		local rank = types.NPC.getFactionRank(player, ownerData.factionId)
		if rank == 0 or rank < (ownerData.factionRank or 1) then
			trespassing = true
		end
	end
	
	if trespassing then
		if I.Crimes then
			I.Crimes.commitCrime(player, {
				faction = ownerData.factionId,
				type = types.Player.OFFENSE_TYPE.Trespassing,
			})
		end
	end
end

local function passwallTeleport(data)
	local player = world.players[1]
	if not player or not player:isValid() then return end
	
	if data.destCell and data.destPosition then
		local pos = v3(data.destPosition[1], data.destPosition[2], data.destPosition[3])
		local rot = data.destRotation
		player:teleport(data.destCell, pos, {
			onGround = true,
			rotation = rot,
		})
		passwallCheckTrespass(player, data.doorObject)
		return
	end
	
	if data.destination then
		local pos = v3(data.destination[1], data.destination[2], data.destination[3])
		player:teleport(data.cellName or player.cell.name, pos, { onGround = true })
		passwallCheckTrespass(player, data.targetObject)
	end
end

-- =====================================================
-- Test spell tomes
-- =====================================================

local function giveStartingTomes(data)
	local player = data.player
	if not player or not player:isValid() then
		player = world.players[1]
	end
	if not player or not player:isValid() then return end
	
	local inv = types.Actor.inventory(player)
	for _, def in ipairs(trData.TOME_DEFS) do
		if not inv:find(def.tomeId) then
			local tome = world.createObject(def.tomeId, 1)
			tome:moveInto(inv)
		end
	end
end

-- ===============================
-- Distract
-- ===============================

TD_DistractTeleportBack = function(data)
--	print(111)
	if not (data.actor and data.position) then return end
--	print(222)
	data.actor:teleport(data.cell or "", data.position)
end

-- ===============================
-- Engine Events
-- ===============================

local function onActorActive(object)
	object:addScript(ACTOR_SUMMON_SCRIPT)
	
	for _, entry in pairs(saveData.activeSummons) do
		if entry.creature == object and entry.summoner and entry.summoner:isValid() then
			object:sendEvent('StartAIPackage', {
				type = 'Follow',
				target = entry.summoner,
				cancelOther = true,
				sideWithTarget = true,
				isRepeat = true,
			})
			break
		end
	end
end

-- onActorInactive
local function TD_RemoveScript(data)
	if data.actor and data.actor:isValid() and data.script then
		data.actor:removeScript(data.script)
	end
end

local function onUpdate(dt)
	local now = core.getSimulationTime()
	if now < nextSummonCheck then return end
	nextSummonCheck = now + SUMMON_CHECK_INTERVAL
	
	checkDeadSummons()
	checkBanishSigils()	
end

local function OwnlysQuickLoot_freshLoot(data)
	local player = data[1]
	local obj = data[2]
	applyInsightLoot(player, obj)
end

local function onActivate(obj, player)
	if not types.Player.objectIsInstance(player) then return end
	if types.Actor.objectIsInstance(obj) then
		if not types.Actor.isDead(obj) then return end
	else
		if types.Container.record(obj).isOrganic then
			return
		end
	end
	
	local inv = obj.type.inventory(obj)
	if not inv:isResolved() then inv:resolve() end
	applyInsightLoot(player, obj)
end

I.Activation.addHandlerForType(types.NPC, onActivate)
I.Activation.addHandlerForType(types.Container, onActivate)
I.Activation.addHandlerForType(types.Creature, onActivate)

local function onLoad(data)
	saveData = data or {}
	saveData.inspectedContainers = saveData.inspectedContainers or {}
	saveData.activeSummons = saveData.activeSummons or {}
	saveData.banishSigils = saveData.banishSigils or {}
	saveData.boundRecordCache = saveData.boundRecordCache or {}
	
	boundRecords.init(saveData.boundRecordCache)
	
	for key, entry in pairs(saveData.activeSummons) do
		if not entry.creature or not entry.creature:isValid() then
			saveData.activeSummons[key] = nil
		end
	end
end

local function onSave()
	return saveData
end

return {
	engineHandlers = {
		onSave         = onSave,
		onLoad         = onLoad,
		onInit         = onLoad,
		onUpdate       = onUpdate,
		onActorActive  = onActorActive,
	},
	eventHandlers = {
		OwnlysQuickLoot_freshLoot = OwnlysQuickLoot_freshLoot,
		TD_SpawnSummon      = spawnSummon,
		TD_DespawnSummon    = despawnSummon,
		TD_DaedricSummonCrime = daedricSummonCrime,
		TD_BoundSpawn       = handleBoundSpawn,
		TD_BoundDespawn     = handleBoundDespawn,
		TD_BlinkPlayer      = blinkTeleportPlayer,
		TD_BlinkSwap        = blinkSwap,
		TD_BlinkActor       = blinkTeleportActor,
		TD_BlinkPreviewShow = blinkPreviewShow,
		TD_BlinkPreviewHide = blinkPreviewHide,
		TD_KyneIntervention = kyneIntervention,
		TD_Passwall         = passwallTeleport,
		TD_Resartus         = resartus,
		TD_ApplyBlind       = applyBlind,
		TD_GiveStartingTomes = giveStartingTomes,
		TD_BanishDelete     = TD_BanishDelete,
		TD_RemoveScript     = TD_RemoveScript,
		TD_DistractTeleportBack = TD_DistractTeleportBack,
	},
}