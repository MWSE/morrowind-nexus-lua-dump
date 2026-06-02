local types = require("openmw.types")
local core = require("openmw.core")
local util = require("openmw.util")
local I = require("openmw.interfaces")
local world = require("openmw.world")
local storage = require("openmw.storage")

local direct = require("scripts.AnimatedPickup.directPurchase")

local Actor, ST = types.Actor, types.Actor.STANCE

local players = {}

local animating = {}	local verify = {}
local quickloot = {}
local noUpdate = true


local function addPlayer(o)
	if players[o.id] then return			end
	local p = {ref=o, sneak=false, nosteal=false, direct=true, anim=true, speed=750, speedtk=100}
	players[o.id] = p			return p
end

for _, v in ipairs(world.players) do		addPlayer(v)		end

local send = {
	activateAll = function(o, actor, c)
		actor:sendEvent("ANP_Event",
			{ eventName="PickupItemActivate", object=o, container=c, takeAll=true })
	end
}
for k, v in pairs {
	activate = "PickupItemActivate",
	moveInto = "PickupItemMoveInto",
	animStart = "PickupAnimationStart",
	crimeItem = "StealingBlockedItem",
	crimeActivator = "StealingBlockedActivator",
	takeAll = "QuicklootTakeAll"
		} do
	send[k] = function(o, actor, c)
		actor:sendEvent("ANP_Event", { eventName=v, object=o, container=c })
	end
end

local function isThieving(o, actor)
	local block = false
	if o.owner.recordId then block = true end
	local faction = o.owner.factionId
	if faction then
		block = true
		local rank = types.NPC.getFactionRank(actor, faction) or 0
		local need = o.owner.factionRank or 1
--		print(faction, need, rank)
		if rank >= need then block = false		end
	end
	if block then
		send[types.Item.objectIsInstance(o) and "crimeItem" or "crimeActivator"](o, actor)
--[[
		local msg = types.Item.objectIsInstance(o) and "msg_usesneak" or "msg_usesneakact"
		actor:sendEvent("anpUiMessage", {show=msg})
		actor:sendEvent("anpUiSound", {id="Menu Click"})
--]]
	end
	return block
end

local function reverseQuickloot(o, loot)
	if loot then
	--	print("cancel quickloot "..o.recordId)
		o:moveInto(loot.container)
		quickloot[o.id] = nil
	end
	return false
end

local function onPickup(o, actor)

	local player = players[actor.id]
	if not player then		return		end

	local loot = quickloot[o.id]
	local allowPurchase = true
	if loot and loot.takeall then	allowPurchase = false		end
	if not player.sneak then
		if player.direct and allowPurchase and not direct.onActivate(o, actor) then
			return reverseQuickloot(o, loot)
		end
		if player.nosteal and isThieving(o, actor) then return reverseQuickloot(o, loot)	end
	end
	if not o.cell then			return		end

	-- skip for takeAll action by quickloot
	if loot and loot.takeall then
		quickloot[o.id] = nil
		return send.activateAll(o, actor, loot.container)
	end
	-- skip for anim disabled or MWScript
	if not player.anim or world.mwscript.getLocalScript(o, actor) then
		return send.activate(o, actor)
	end
	-- skip for ashfall gear
	if o.recordId:find("^ashfall_") then
		return send.activate(o, actor)
	end

	local pickup, inTable, slot = false, false, #animating + 1
	for i=1, #animating do
		if animating[i].obj == o then
			inTable = true
			if not animating[i].valid then
				slot = i
			elseif animating[i].k  == 4 then
				pickup = true
				animating[i].valid = false
			else
				return false
			end
		end
	end
	-- check object hasn't been deleted and is still in the world
	if not o:isValid() or o.count == 0 then
		return false
	end
	-- pass through activation of an animated object
	if pickup then
		if loot then quickloot[o.id] = nil		end
		return send.activate(o, actor)
	end
	-- pass through if item is being quickloot pickpocketed
	if loot and loot.container and types.NPC.objectIsInstance(loot.container)
		and not types.Actor.isDead(loot.container) then
		quickloot[o.id] = nil
		return send.activate(o, actor)
	end
	if inTable and not animating[slot] then
		return false
	end

--	print(slot, inTable, noUpdate)
	local npc, gender = types.NPC.records[actor.recordId], "female"
	if npc.isMale then gender = "male" end
	local height = 128 * types.NPC.races.records[npc.race].height[gender] * actor.scale
	local speed, maxK = player.speed, 0.7
	local distance = (actor.position - o.position):length()
	if Actor.activeEffects(actor):getEffect("telekinesis").magnitude > 0 and distance > 220 then
		speed = player.speedtk		maxK = 1 - (60 / distance)
	end
	local startPos
	if loot then
		startPos = types.NPC.objectIsInstance(loot.container) and loot.container:getBoundingBox().center
			or loot.container.position
	else
		startPos = o.position
	end
	animating[slot] = { obj=o, actor=actor, startPos=startPos, height=height,
		speed=speed, k=0, maxK=maxK, valid=true
	}
	noUpdate = false
	send.animStart(o, actor)
	return false
end

for _, v in ipairs{ types.Apparatus, types.Armor, types.Clothing,
	types.Ingredient, types.Lockpick, types.Miscellaneous,
	types.Potion, types.Probe, types.Repair, types.Weapon }
	do
	I.Activation.addHandlerForType(v, onPickup)
end

I.Activation.addHandlerForType(types.Light, function(o, actor)
	if o.type.records[o.recordId].isCarriable then
		return onPickup(o, actor)
	end
end)
I.Activation.addHandlerForType(types.Book, function(o, actor)
	local loot = quickloot[o.id]
	if direct.purchaseTarget == o then
		local runHandlers = onPickup(o, actor)
		for _, v in ipairs(animating) do
			if v.obj == o then
		--		print("PURCHASE PICKUP")
				v.moveInto = true
			end
		end
		if loot then		quickloot[o.id] = nil		end
		return runHandlers
	end
	local c = loot and loot.container or nil
	if loot then		quickloot[o.id] = nil		end
	return send.activate(o, actor, c)
end)
I.Activation.addHandlerForType(types.Activator, function(o, actor)
	local player = players[actor.id]
	if not player then		return		end

	local script = o.type.records[o.recordId].mwscript
	if not player.sneak and script and script:find("bed_") then
		local rent = o.globalVariable
		if rent and rent:find("rent_") then
			if world.mwscript.getGlobalVariables(actor)[rent] ~= 0 then
		--		print("BED IS RENTED")
				return
			end
		end
		return not(player.nosteal and isThieving(o, actor))
	end
end)

local function playerUpdate(e)
	if not e.player then		return		end
	local player = players[e.player.id] or addPlayer(e.player)
	for k, v in pairs(e) do		player[k] = e[k]	end
--	print("sneaking", player.sneak, "nosteal", player.nosteal, "anim", player.anim)
end

local unPause = false

local function onUpdate(dt)
	if unPause then
		unPause = false
	--	for k, v in pairs(world.getPausedTags()) do print(k, v)		end
		if world.getPausedTags()["ui"] then world.unpause("ui")		end
	end
	if dt <= 0 or noUpdate then	return		 end

	local cleared = true
	for i=1, #animating do
		local data = animating[i]
		local o = data.obj
		-- check object hasn't been deleted and is still in the world
		if not o:isValid() or not o.cell or o.count < 1 then
			data.valid = false
		end
		if data.k < 1 and data.valid then
			cleared = false
			local playerPos = data.actor.position
			playerPos = playerPos + util.vector3(0, 0, data.height * 0.6)
			local k = data.k + data.speed * 0.01 * dt
			if o.cell == data.actor.cell then
				local destVec = (playerPos - data.startPos) * k
				o:teleport(o.cell, data.startPos + destVec)
			else data.valid = false
			end
			if k >= data.maxK then
				k = 1
			end
			data.k = k
		elseif data.k < 4 and data.valid then
			-- leave 3 frame gap between end of animate and activateBy command
			data.k = data.k + 1
			cleared = false
			if data.k > 3 then
				local v = { obj=o, cell=o.cell, to=o.position, c=0, actor=data.actor }
				if quickloot[o.id] then
					v.container = quickloot[o.id].container
				else
					v.from = data.startPos
				end
				if data.moveInto then
					o:moveInto(data.actor)
					send.moveInto(o, data.actor, v.container)
				else
					verify[#verify + 1] = v
					o:activateBy(data.actor)
				--	send.activate(o, data.actor)
				end
			end
		end
	end
	for i=1, #verify do
		local data = verify[i]		local o = data.obj
		if o and data.c > 3 then
			if o:isValid() and o.count > 0 and o.cell == data.cell
				and (o.position - data.to):length() < 10 then
				if data.container then
					print("Pickup action was blocked. Returning to original container ...")
					o:moveInto(data.container.type.inventory(data.container))
				else
					print("Pickup action was blocked. Returning to original position ...")
					if data.from then
						o:teleport(data.cell, data.from)
					end
				end
				data.actor:sendEvent("anpUiMessage", {show="msg_pickupblock"})
			end
		--	print(o.count, o.cell, o.position, data.to, data.ql)
			data.obj = nil
		elseif o then
			data.c = data.c + 1
			cleared = false
		end
	end
	if cleared then
		noUpdate = true		animating = {}		verify = {}
	--	print("QUEUE cleared")
	end
end

local function logQuickloot(e)
	local player, container, o = unpack(e)
	if not player or not container then
		return
	end
	local t = types.Container.objectIsInstance(container) and types.Container or types.Actor
	if type(o) == "userdata" then
--		print("LOGGED "..o.recordId)
		quickloot[o.id] = { object=object, player=player, container=container }
		return
	end
--	send.takeAll(_, player, container)
	for k, v in pairs(t.inventory(container):getAll()) do
--		print("LOGGED "..k.." "..v.recordId)
		quickloot[v.id] = { object=v, player=player, container=container, takeall=true }
	end
end

local events = { uiMenu = direct.uiMessageMenu }
events.unPause = function()	unPause = true			end


return {
	engineHandlers = { onUpdate = onUpdate, onPlayerAdded = addPlayer },
	eventHandlers = {
		anpPlayerUpdate = playerUpdate,
		ANP_Event = function(e) events[e.event](e.data)		end,
		OwnlysQuickLoot_take = logQuickloot,
		OwnlysQuickLoot_takeAll = logQuickloot
	},
	interfaceName = "AnimatedPickup",
	interface = {
		version = 129,
		runPickupHandler = function(o, actor)
			onPickup(o, actor)
			for _, v in ipairs(animating) do
				if v.obj == o then
				--	print("INTEROP PICKUP")
					v.moveInto = types.Book.objectIsInstance(o)
				end
			end
		end
	}
}
