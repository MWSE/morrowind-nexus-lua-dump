local types = require("openmw.types")
local async = require("openmw.async")
local core = require("openmw.core")
local util = require("openmw.util")
local I = require("openmw.interfaces")
local world = require("openmw.world")
local storage = require("openmw.storage")

local Actor, ST = types.Actor, types.Actor.STANCE

local handlers = { types.Activator, types.Apparatus, types.Armor, types.Clothing,
	types.Ingredient, types.Light, types.Lockpick, types.Miscellaneous,
	types.Potion, types.Probe, types.Weapon }

local players = {}

local animating = {}
local cleared = true


local function verifyPlayer(arg)
	if players[arg.id] then return end
	players[arg.id] = {obj=arg, sneak=false, nosteal=false, anim=true, spd=750}
end

local function blockTake(obj, actor)
	verifyPlayer(actor)
	if players[actor.id].sneak then return false end
	local block = false
	if obj.owner.recordId then block = true end
	local faction = obj.owner.factionId
	if faction then
		block = true
		local rank, need = types.NPC.getFactionRank(actor, faction), obj.owner.factionRank
--		print(faction, need, rank)
		if (rank > 0 and need == nil) or rank >= need then block = false end
	end
	if block then actor:sendEvent("showUIMessage", "Use sneak to steal item.") end
	return block
end

local function onPickup(o, actor)
	if actor.type ~= types.Player then return end
	if players[actor.id].nosteal and blockTake(o, actor) then return false end
	if o.type == types.Activator or not players[actor.id].anim
		or world.mwscript.getLocalScript(o, actor) or not o.cell then return end
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
	if pickup then return end
	if inTable and not animating[slot] then return false end
--	print(slot, inTable, cleared)
	if cleared and #animating > 10 then animating = {} slot = 1 end
	local npc, gender = types.NPC.record(actor), "female"
	if npc.isMale then gender = "male" end
	local height = 128 * types.NPC.races.record(npc.race).height[gender] * actor.scale
	animating[slot] = {obj=o, actor=actor, startPos=o.position, height=height,
		speed=players[actor.id].speed, k=0, valid=true}
	cleared = false
	return false
end

for i = 1, #handlers do
  I.Activation.addHandlerForType(handlers[i], function(o, actor) return onPickup(o, actor) end)
end

local function playerState(e)
	local actor = e.player
	if not actor or actor.type ~= types.Player then return end
	verifyPlayer(actor)
	if e.sneak ~= nil then players[actor.id].sneak = e.sneak end
	if e.nosteal ~= nil then players[actor.id].nosteal = e.nosteal end
	if e.anim ~= nil then players[actor.id].anim = e.anim end
	if e.spd ~= nil then players[actor.id].speed = e.spd end
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
			if k >= 0.7 then
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


return {
	engineHandlers = { onUpdate = onUpdate, onPlayerAdded = verifyPlayer },
	eventHandlers = { playerState = playerState }
}
