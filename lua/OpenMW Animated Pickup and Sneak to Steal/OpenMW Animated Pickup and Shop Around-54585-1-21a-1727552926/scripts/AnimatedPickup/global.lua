local types = require("openmw.types")
local async = require("openmw.async")
local core = require("openmw.core")
local util = require("openmw.util")
local I = require("openmw.interfaces")
local world = require("openmw.world")
local storage = require("openmw.storage")

local direct = require("scripts.AnimatedPickup.directPurchase")

local Actor, ST = types.Actor, types.Actor.STANCE

local handlers = { types.Activator, types.Apparatus, types.Armor, types.Clothing,
	types.Ingredient, types.Light, types.Lockpick, types.Miscellaneous,
	types.Potion, types.Probe, types.Repair, types.Weapon }

local players = {}

local animating = {}
local quickloot = {}
local cleared = true


local function verifyPlayer(arg)
	if players[arg.id] then return end
	players[arg.id] = {obj=arg, sneak=false, nosteal=false, direct=true, anim=true, speed=750, speedtk=100}
end

local function isThieving(obj, actor)
	local block = false
	if obj.owner.recordId then block = true end
	local faction = obj.owner.factionId
	if faction then
		block = true
		local rank, need = types.NPC.getFactionRank(actor, faction), obj.owner.factionRank
--		print(faction, need, rank)
		if (rank > 0 and need == nil) or rank >= need then block = false end
	end
	if block then
		actor:sendEvent("apShowMessage", "msg_usesneak")
		actor:sendEvent("ambientPlaySound", {id="Menu Click"})
	end
	return block
end

local function noQuickloot(o, loot)
	if not loot then return false end
--	print("cancel quickloot "..o.recordId)
	o:moveInto(loot.container)
	quickloot[o.id] = nil
	return false
end

local function onPickup(o, actor)
	if actor.type ~= types.Player then return end
	verifyPlayer(actor)
	local player = players[actor.id]
	local loot = quickloot[o.id]
	local directPurchase = true
	if loot and loot.blocked then directPurchase = false end
	if not player.sneak then
		if player.direct and not types.Activator.objectIsInstance(o) and directPurchase
			and not direct.onActivate(o, actor) then return noQuickloot(o, loot) end
		if player.nosteal and isThieving(o, actor) then return noQuickloot(o, loot) end
	end
	-- skip for ashfall gear
	if o.recordId:find("^ashfall_") then return end
	if o.type == types.Activator or not players[actor.id].anim or not o.cell
		or world.mwscript.getLocalScript(o, actor) then
			return
	end
	-- skip for takeAll action by quickloot
	if loot and loot.blocked then quickloot[o.id] = nil return end
	local pickup, inTable, slot = false, false, #animating + 1
	for i=1, #animating do
		if animating[i].obj == o then
			inTable = true
			if not animating[i].valid then slot = i
			elseif animating[i].k  == 4 then
				pickup = true
				animating[i].valid = false
			else return false
			end
		end
	end
	-- check object hasn't been deleted and is still in the world
	if not o:isValid() then return false end
	if pickup then
		if loot then quickloot[o.id] = nil end
		return
	end
	if inTable and not animating[slot] then return false end
--	print(slot, inTable, cleared)
	if cleared and #animating > 10 then animating = {} slot = 1 end
	local npc, gender = types.NPC.record(actor), "female"
	if npc.isMale then gender = "male" end
	local height = 128 * types.NPC.races.record(npc.race).height[gender] * actor.scale
	local speed, maxK = players[actor.id].speed, 0.7
	local distance = (actor.position - o.position):length()
	if Actor.activeEffects(actor):getEffect("telekinesis").magnitude > 0 and distance > 220 then
		speed = players[actor.id].speedtk
		maxK = 1 - (60 / distance)
	end
	local start = o.position
	if loot then start = loot.container.position end
	animating[slot] = {obj=o, actor=actor, startPos=start, height=height,
		speed=speed, k=0, maxK=maxK, valid=true}
	cleared = false
	return false
end

for i = 1, #handlers do
  I.Activation.addHandlerForType(handlers[i], function(o, actor) return onPickup(o, actor) end)
end

local function playerUpdate(e)
	local actor = e.player
	if not actor or actor.type ~= types.Player then return end
	verifyPlayer(actor)
	if e.sneak ~=nil then players[actor.id].sneak = e.sneak end
	if e.nosteal ~=nil then players[actor.id].nosteal = e.nosteal end
	if e.direct ~=nil then players[actor.id].direct = e.direct end
	if e.anim ~= nil then players[actor.id].anim = e.anim end
	if e.spd then players[actor.id].speed = e.spd end
	if e.spdtk then players[actor.id].speedtk = e.spdtk end
--	print("sneaking", players[actor.id].sneak, "nosteal", players[actor.id].nosteal, "anim", players[actor.id].anim)
end

local function onUpdate(dt)
	if cleared then return end
	cleared = true
	for i=1, #animating do
		local data = animating[i]
		local o = data.obj
		-- check object hasn't been deleted and is still in the world
		if not o:isValid() or not o.cell then data.valid = false end
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
			if data.k > 3 then o:activateBy(data.actor) end
		end
	end
end

local function logQuickloot(e)
	local player, container, o = unpack(e)
	if not player or not container then return end
	local type = types.Actor
	if types.Container.objectIsInstance(container) then type = types.Container end
	if not o then
		for k, v in pairs(type.inventory(container):getAll()) do
			quickloot[v.id] = { object=v, player=player, container=container, blocked=true }
--			print("LOGGED "..k.." "..v.recordId)
		end
	else
		loot = { object=object, player=player, container=container }
		quickloot[o.id] = { object=object, player=player, container=container }
--		print("LOGGED "..o.recordId)
	end
end

return {
	engineHandlers = { onUpdate = onUpdate, onPlayerAdded = verifyPlayer },
	eventHandlers = { anpPlayerUpdate = playerUpdate,
		apMessageMenu = direct.uiMessageMenu,
		OwnlysQuickLoot_take = logQuickloot,
		OwnlysQuickLoot_takeAll = logQuickloot
 }
}
