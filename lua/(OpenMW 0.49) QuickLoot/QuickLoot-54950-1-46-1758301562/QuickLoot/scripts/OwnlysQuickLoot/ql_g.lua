local acti = require("openmw.interfaces").Activation
local types = require('openmw.types')
local core = require('openmw.core')
local disabledPlayers = {}
local activateNextUpdate = {}
local activateSecondNextUpdate = {}
local deleteSecondNextUpdate = {}
local limbo = {}
local world = require('openmw.world')
local I = require("openmw.interfaces")
local vanillaActivateTable = {}
local openedGUIs = {}
local getSound = require("scripts.OwnlysQuickLoot.ql_getSound")
local util = require('openmw.util')
local organicContainers = {
	barrel_01_ahnassi_drink=true,
	barrel_01_ahnassi_food =true,
	com_chest_02_fg_supply =true,
	com_chest_02_mg_supply =true,
	flora_treestump_unique =true,
}

if not core.mwscripts then
	scriptDB = require("scripts.OwnlysQuickLoot.ql_script_db")
end

onActivateStuffOnce = {}
local getSound = require("scripts.OwnlysQuickLoot.ql_getSound")

local function removeInvisibility(player)
	for a,b in pairs(types.Actor.activeSpells(player)) do
		for c,d in pairs(b.effects) do
			if d.duration and d.id == "invisibility" then--and (d.id == "fortifyhealth" or d.id == "fortifyfatigue" or d.id == "fortifymagicka") then
				types.Actor.activeSpells(player):remove(b.activeSpellId)
			end
		end
	end
end

local function sa(cont)
	--if (cont.recordId:find("contain_bm_stalhrim")) then
	--	playerItems = types.Container.inventory(self):getAll()
	--	for a,b in pairs(playerItems) do
	--		if b.recordId == "bm nordic pick" then
	--			return true
	--		end
	--	end
	--	return false
	--end
	if types.Lockable.getTrapSpell(cont) then
		return false
	end
	local script = cont.type.record(cont).mwscript
	if script then
		if core.mwscripts then
			local scriptRecord = core.mwscripts.records[script]
			if scriptRecord and not scriptRecord.text:lower():find("onactivate") then
				print("onActivate: "..script.." ok")
				return true
			else
				print("onActivate: "..script.." not ok")
				return false
			end
		else
			if scriptDB[script] == false then
				print("onActivate: "..script.." ok")
				return true
			elseif scriptDB[script] then
				print("onActivate: "..script.." not ok (blacklist)")
				return false
			else
				print("onActivate: "..script.." ok (unknown)")
				return true
			end
		end
	else
		return true
	end
end

local function scriptAllows(cont)
	return not sa(cont)
end

function triggerMwscriptTrap(obj, player)
	local script = world.mwscript.getLocalScript(obj, player)
	--print(world.mwscript.getLocalScript(obj, player).scriptText)
	--print(world.mwscript.getGlobalScript(recordId, player).scriptText)
	
	if script then
		if script.variables.setonce == 0 
		or script.variables.done == 0 
		or script.variables.doOnce == 0
		then
			--obj:activateBy(player)
			player:sendEvent("OwnlysQuickLoot_fellForTrap", obj)
			world._runStandardActivationAction(obj, player)
			return true
		
		elseif not script.variables.setonce
		and not script.variables.done
		and not script.variables.doOnce
		and onActivateStuff[obj.recordId]
		and not onActivateStuffOnce[obj.recordId] then
			onActivateStuffOnce[obj.recordId] = true
			player:sendEvent("OwnlysQuickLoot_fellForTrap", obj)
			--obj:activateBy(player)
			world._runStandardActivationAction(obj, player)
			return true
		end
	end
end



local function activateContainer(cont, player)
	removeInvisibility(player)

	if cont.type.record(cont).isOrganic and not organicContainers[cont.recordId] then --plants but not guild chests
		return true
	end
	if types.Lockable.isLocked(cont) or types.Lockable.getTrapSpell(cont) then
		return true
	end
	if disabledPlayers[player.id] or vanillaActivateTable[player.id] then
		return true
	end
	if scriptAllows(cont) then
		return true
	else
		return false
	end
	--	--world._runStandardActivationAction(cont, world.players[1])
	--	triggerMwscriptTrap(cont,player)
	--	if not types.Lockable.isLocked(cont)
	--	and not types.Lockable.getTrapSpell(cont)
	--	and (not cont.type.record(cont).isOrganic or organicContainers[cont.recordId])
	--	then
	--		player:sendEvent("OwnlysQuickLoot_activatedContainer", {cont})
	--		return false
	--	end
	--end
end

local function activateActor(actor,player)
	--if not disabledPlayers[player.id] and not vanillaActivateTable[player.id] and not actor.type.isDead(actor) then
	--	player:sendEvent("OwnlysQuickLoot_activatedContainer", {actor, not actor.type.isDead(actor)})
	--	return false
	--end
	if disabledPlayers[player.id] or vanillaActivateTable[player.id] then
		return true
	end
	
	if not actor.type.isDead(actor) and openedGUIs[player.id] then-- sneaking
		return false
	end
	if not actor.type.isDead(actor) then
		return true
	end
	if scriptAllows(actor) then
		return true
	else
		return false
	end
	
	--	)
	--)
	--then
	--	triggerMwscriptTrap(actor,player)
	--	player:sendEvent("OwnlysQuickLoot_activatedContainer", {actor, not actor.type.isDead(actor)})
	--	
	--	return false
	--end
	--return true
end

local function resolve(cont)
	types.Container.inventory(cont):resolve()
end

local function deposit(data)
	local player = data[1]
	local container = data[2]
	local thing = data[3]
	local isPickpocketing = data[4]
	local experimentalLooting = data[5]
	local count = data[6]
	local use = data[7]
	if thing.count == 0 then
		return
	end
	if count then
		if count < thing.count then
			thing = thing:split(count)
		end
	end
	if use then
		if types.Potion.objectIsInstance(thing) then
			core.sendGlobalEvent('UseItem', {object = thing, actor = container})
		else
			thing:moveInto(types.Container.inventory(container))
			core.sendGlobalEvent('UseItem', {object = thing, actor = container})
		end
	else
		thing:moveInto(types.Container.inventory(container))
	end
	player:sendEvent("OwnlysQuickLoot_playSound", getSound(thing))
end




local function depositAll(data)
	local player = data[1]
	local container = data[2]
	local selectiveDesposit = data[3]
	local isCorpse = data[4]
	local experimentalLooting = data[5]
	local i =0
	--if not triggerMwscriptTrap(container,player) then
		--print(container,container.type,types.Container.inventory(container):isResolved())
		local containerInventory = types.Container.inventory(container)
		for _, thing in pairs(types.Player.inventory(player):getAll()) do
			if not types.Actor.hasEquipped(player,thing) then
				if not selectiveDesposit 
				or selectiveDesposit == "restack" and containerInventory:countOf(thing.recordId) > 0 
				or selectiveDesposit == "ingredients" and types.Ingredient.objectIsInstance(thing) then
					thing:moveInto(containerInventory)
					player:sendEvent("OwnlysQuickLoot_playSound", getSound(thing))
				end
				i=i+1
			end
		end
	--end
end

local function take(data)
	local player = data[1]
	local container = data[2]
	local thing = data[3]
	local isPickpocketing = data[4]
	local experimentalLooting = data[5]
	if thing.count == 0 then
		return
	end
	if I.TransferItemsSpells then
		if I.TransferItemsSpells.moveSelectedItemsToContainer(player, container) then
			return
		end
    end
	if isPickpocketing then
		thing:moveInto(types.Player.inventory(player))
	elseif thing.type == types.Book or experimentalLooting and container.owner.factionId == nil and container.owner.recordId == nil then
		thing:moveInto(types.Player.inventory(player))
		player:sendEvent("OwnlysQuickLoot_playSound",getSound(thing))
	elseif thing.recordId == "gold_001" or thing.recordId == "gold_005" or thing.recordId == "gold_010" or thing.recordId == "gold_025" or thing.recordId == "gold_100" then --90% sure its just gold_001
		thing:teleport(player.cell, player.position, player.rotation)
		table.insert(activateSecondNextUpdate,{thing,player,container}) -- gold takes 2 ticks to become valid and allow owner changes
	else
		thing:teleport(player.cell, player.position, player.rotation)
		thing.owner.factionId = container.owner.factionId
		thing.owner.factionRank = container.owner.factionRank
		thing.owner.recordId = container.owner.recordId
		table.insert(activateNextUpdate,{thing,player})
	end
	player:sendEvent("HUDM_recheckObject", container)
	--thing:activateBy(player)
--moveInto(types.Player.inventory(player))
	--player:sendEvent("TakeAll_closeUI")
end
local function transferIfEmpty(data)
	if I.TransferItemsSpells then
		local player = data[1]
		local container = data[2]
		--local thing = data[3]
		--local isPickpocketing = data[4]
		--local experimentalLooting = data[5]
		I.TransferItemsSpells.moveSelectedItemsToContainer(player, container)
	end
end

local function takeAll(data)
	local player = data[1]
	local container = data[2]
	local disposeCorpse = data[3]
	local isCorpse = data[4]
	local experimentalLooting = data[5]
	local i =0
	types.Container.inventory(container):resolve()
	--if not triggerMwscriptTrap(container,player) then
		--print(container,container.type,types.Container.inventory(container):isResolved())
		for _, thing in pairs(types.Container.inventory(container):getAll()) do
			local thingRecord = thing.type.records[thing.recordId]
			if not thingRecord.name or thingRecord.name == "" or not types.Item.isCarriable(thing) then
				--ignore
			elseif thing.type == types.Book then
				thing:moveInto(types.Player.inventory(player))
				i=i+1
			elseif thing.recordId == "gold_001" or thing.recordId == "gold_005" or thing.recordId == "gold_010" or thing.recordId == "gold_025" or thing.recordId == "gold_100" then --90% sure its just gold_001
				thing:teleport(player.cell, player.position, player.rotation)
				table.insert(activateSecondNextUpdate,{thing,player,container}) -- gold takes 2 ticks to become valid and allow owner changes
			else
				thing:teleport(player.cell, player.position, player.rotation)
				thing.owner.factionId = container.owner.factionId
				thing.owner.factionRank = container.owner.factionRank
				thing.owner.recordId = container.owner.recordId
				table.insert(activateNextUpdate,{thing,player})
				
				i=i+1
			end
			--thing:activateBy(player)
		--moveInto(types.Player.inventory(player))
		end
		if disposeCorpse and types.Actor.objectIsInstance(container) and types.Actor.isDead(container) then
			table.insert(deleteSecondNextUpdate,{container,2, player})
			player:sendEvent("OwnlysQuickLoot_playSound", "item armor light up")
		end
		if i>0 then
			--player:sendEvent("TakeAll_PlaySound","Item Ingredient Up")
		end
		player:sendEvent("HUDM_recheckObject", container)
	--end
end


acti.addHandlerForType(types.Container, activateContainer)
acti.addHandlerForType(types.NPC, activateActor)
acti.addHandlerForType(types.Creature, activateActor)

local function onUpdate(dt)
	for _, t in pairs(activateNextUpdate) do
		if t[3] then
			t[1].owner.factionId = t[3].owner.factionId
			t[1].owner.factionRank = t[3].owner.factionRank
			t[1].owner.recordId = t[3].owner.recordId
		end
		t[1]:activateBy(t[2])
	end
	for a,b in pairs(vanillaActivateTable) do
		vanillaActivateTable[a] = b-1
		if b == 0 then 
			vanillaActivateTable[a] = nil
		end
	end
	for i, t in pairs(deleteSecondNextUpdate) do
		if t[2]>1 then
			t[2] = 1
		else
			if types.Actor.isDeathFinished(t[1]) then
				t[3]:sendEvent("HUDM_objectRemoved",t[1])
				t[1]:remove(1)
			else
				t[1]:teleport(t[1].cell, t[1].position-util.vector3(0,0,300))
				table.insert(limbo, {t[1], t[3]})
			end
			table.remove(deleteSecondNextUpdate,i)
		end
	end
	activateNextUpdate = activateSecondNextUpdate
	activateSecondNextUpdate = {}
	for i, t in pairs(limbo) do
		if types.Actor.isDeathFinished(t[1]) then
			t[2]:sendEvent("HUDM_objectRemoved",t[1])
			t[1]:remove(1)
			limbo[i] = nil
		end
	end
end
local function playerToggledMod(arg)
	local player = arg[1]
	local toggle = arg[2]
	disabledPlayers[player.id] = not toggle
end

local function vanillaActivate(arg)
	local player = arg[1]
	local obj = arg[2]
	local force = arg[3]
	if force then
		vanillaActivateTable[player.id] = 2
		world._runStandardActivationAction(obj, player)
	end
	removeInvisibility(player)
	obj:activateBy(player)
end

local function freshLoot(arg)
	local player = arg[1]
	local obj = arg[2]
	--vanillaActivateTable[player.id] = 2
	--world._runStandardActivationAction(obj, player)
	if I.FreshLoot then
		if I.FreshLoot.processLoot then
			I.FreshLoot.processLoot(obj, player)
		else
			print("PLEASE UPDATE FRESHLOOT")
		end
	end
end

function test(tbl)
	local player = tbl[1]
	local item = tbl[2]
	
	local originalRecord = types.Weapon.records[item.recordId]
		
		local itemTable = {name = originalRecord.name, template = originalRecord, enchantCapacity = originalRecord.enchantCapacity * 1.25}
		
		--local newRecordDraft = item.type.createRecordDraft{itemTable}
		local newRecordDraft = types.Weapon.createRecordDraft(itemTable)
	
		--add to world
		local newRecord = world.createRecord(newRecordDraft)
		print(newRecord.id)
		
		local upgradedItem = world.createObject(newRecord.id, 1)
		print(upgradedItem.id)
		
		local cell = world.getCellById(player.cell.id)
	
		--moves to altar
		--upgradedItem:teleport(player.cell, player.position, player.rotation)
		upgradedItem:teleport(player.cell, player.position, player.rotation)
end

local function openGUI(playerObject)
	openedGUIs[playerObject.id] = world.getGameTime()
end

local function closeGUI(playerObject)
	openedGUIs[playerObject.id] = nil
end

local function getCrimesVersion(player)
	player:sendEvent("OwnlysQuickLoot_receiveCrimesVersion", I.Crimes.version)
end

local function commitCrime(data)
	local player = data[1]
	local container = data[2]
	local price = data[3]
	local type = data[4] or types.Player.OFFENSE_TYPE.Pickpocket
	local commitCrimeOutputs = I.Crimes.commitCrime(player,{
		type = type,
		victim = container,
		arg = price,
		victimAware = true
	})
end

local function rotateNpc(data)
	local player = data[1]
	local npc = data[2]
	
	local directionToPlayer = player.position - npc.position
	local targetYaw = math.atan2(directionToPlayer.y, directionToPlayer.x)
	npc:teleport(npc.cell, npc.position, util.transform.rotateZ(-targetYaw+math.pi/2))
end

local function modDisposition(data)
	local player = data[1]
	local target = data[2]
	local value = data[3]
	types.NPC.modifyBaseDisposition(target, player, value)
end

local function tryScript(data)
	player = data[1]
	obj = data[2]
	obj:activateBy(player)
	player:sendEvent("OwnlysQuickLoot_triedScript", obj)
	--world._runStandardActivationAction(obj, player)
end

local function onObjectActive(object)
	if types.Container.objectIsInstance(object) and not types.Container.record(object).isOrganic then
		--print("+", object)
		object:addScript("scripts/OwnlysQuickLoot/ql_cont2.lua")
		object:sendEvent("OwnlysQuickLoot_initialize")
	end
end

local function unhookObject(object)
	--if object:hasScript("scripts/OwnlysQuickLoot/ql_cont2.lua") then --unnecessary?
	--print("-", object)
	object:removeScript("scripts/OwnlysQuickLoot/ql_cont2.lua")
end

return {
	eventHandlers = {
		OwnlysQuickLoot_freshLoot = freshLoot,
		OwnlysQuickLoot_take = take,
		OwnlysQuickLoot_deposit = deposit,
		OwnlysQuickLoot_depositAll = depositAll,
		OwnlysQuickLoot_takeAll = takeAll,
		OwnlysQuickLoot_takeBook = takeBook,
		OwnlysQuickLoot_resolve = resolve,
		OwnlysQuickLoot_vanillaActivate = vanillaActivate,
		OwnlysQuickLoot_playerToggledMod = playerToggledMod,
		OwnlysQuickLoot_test = test,
		OwnlysQuickLoot_openGUI = openGUI,
		OwnlysQuickLoot_closeGUI = closeGUI,
		OwnlysQuickLoot_getCrimesVersion = getCrimesVersion,
		OwnlysQuickLoot_commitCrime = commitCrime,
		OwnlysQuickLoot_rotateNpc = rotateNpc,
		OwnlysQuickLoot_modDisposition = modDisposition,
		OwnlysQuickLoot_tryScript = tryScript,
		OwnlysQuickLoot_unhookObject = unhookObject,
		OwnlysQuickLoot_transferIfEmpty = transferIfEmpty,
	},
	engineHandlers = {
		onUpdate = onUpdate,
		onObjectActive = onObjectActive,
	}
}