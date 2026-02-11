local anim = require("openmw.animation")
local self = common.omw.self
local util = common.omw.util

local Actor, MD = common.Actor, common.MD

local Anim = {
	cancel = anim.cancel,
	isPlaying = anim.isPlaying,
	getActiveGroup = anim.getActiveGroup
}

Anim.items = { "None", "Hand on Hip contrapose", "Ready Pose", "Idle2", "Arms Folded",
	"Arms Back Clasp", "anim_akimbo" }
Anim.settings = {}
for i=1, #Anim.items do	Anim.settings[Anim.items[i]] = i		end

Anim.idle = {
	base = { {id="none", speed=1},
		{id="handhippose", speed=0.5},
		{id="readypose", speed=0.5},
		{id="idle2", speed=0.5},
		{id="armsfolded", speed=0.5},
		{id="armsatback", speed=0.5},
		{id="armsakimbo", speed=0.5},
	},
	rnd = {
{ {id="armsakimbo", opt={loops=2}}, {id="idle4", opt={speed=2}} },
{ {id="armsfolded", opt={loops=2}}, {id="idle8", opt={loops=1, speed=2}} }
	}
}

Anim.combo = { armsStrPose = { "handhippose", {mask=3} },
	armsFoldPose = { "handhippose", {mask=3}, "armsfolded", {mask=12, spd=1} },
	armsOneBackPose = { "handhippose", {mask=3}, "armsatback", {mask=8, spd=1} },
	armsBackClaspPose = { "handhippose", {mask=3}, "armsatback", {mask=12, spd=1} },
	armsFoldedOrAkimbo = { "armsakimbo", {}, "armsfolded", {mask=12, spd=1} },
}

Anim.clear = { "handhippose", "readypose", "armsfolded", "armsakimbo", "armsatback", "posealma3",
	"idle2", "idle4", "idle8" }
Anim.poses = require("scripts.DynamicActors.userConfig.PoseMode Playlist")

Anim.idleGroups = { idle=true }
for _, v in ipairs(Anim.poses) do	Anim.idleGroups[v.id] = true		end
for _, v in ipairs(Anim.clear) do	Anim.idleGroups[v] = true		end


Anim.beastBlendMasks = {
--	handhippose = 0, armsakimbo = 12,
--	readypose = 0,
	armsfolded = 12, armsatback = 12, armssunshield = 8,
	armsfoldpose = 12, armsstrpose = 12, armsonebackpose = 12,
	armsbackclasppose = 12,
	armsalmapray = 12, posealma3 = 0, idle2_copy = 0, idle7_copy = 12, idle8_copy = 12
}


local function playHandler(g, o)
	local shield = MD.getMode() ~= MD.FirstPerson
		and (Anim.visibleShields or not anim.hasBone(self, "Bip01 AttachShield"))
		and Actor.getEquipment(self, Actor.Shield)
	local mask = shield and 11
	mask = mask or ((anim.isPlaying(self, "idlestorm") or anim.isPlaying(self, "torch")) and 15)
	if mask then
		if g == "armsfolded" then
			g = "armsakimbo"
		elseif g == "posealma3" then
			mask = util.bitAnd(mask, 3)
		end
	else
		mask = 15
	end

	if Anim.isBeast then
		local v = Anim.beastBlendMasks[g]
		if v then		mask = util.bitAnd(v, mask)		end
	end

	o.blendMask = util.bitAnd(o.blendMask or 15, mask)
	if mask > 0 then
		anim.playBlended(self, g, o)
	end
end

function Anim.handler(a, g, o)
	local mask = 15
--[[
	if Anim.isBeast then
		if g:find("_copy$") then g = g:gsub("_copy$", "")	end
		local v = Anim.beastBlendMasks[g:lower()]
		if v and a == "play" then
			o = o or {}	mask = v or 12
			o.blendMask = o.blendMask or mask
			o.blendMask = util.bitAnd(v, mask)
		end
	end
--]]
	if Anim.isBeast and g:find("_copy$") then
		g = g:gsub("_copy$", "")
	end

	local combo = Anim.combo[g]
	local play = true
	if g == "none" then return true end
	if a == "isPlay" and not combo then
		return anim.isPlaying(self, g)
	end
	if not combo then
		if a == "play" then playHandler(g, o)	else	anim.cancel(self, g)	end
		return
	end
	if a == "isPlay" then
--[[
		if g == "armsFoldPose" and not anim.isPlaying(self, "armsfolded") then
			play = false
		end
		if ( g == "armsBackClaspPose" or g == "armsOneBackPose" )
			and not anim.isPlaying(self, "armsatback") then
			play = false
		end
--]]
		if not anim.isPlaying(self, combo[1]) then	play = false		end
		return play
	end
	if a == "cancel" then
		if combo[3] then	anim.cancel(self, combo[3])			end
		anim.cancel(self, combo[1])
		return
	end

	local options = {}
	for k, v in pairs(o) do		options[k] = v		end
	if combo[4] then	o.blendMask = util.bitAnd(combo[4].mask, mask)		end
	options.blendMask = combo[2].mask or options.blendMask or 15
	options.blendMask = util.bitAnd(options.blendMask, mask)
--	print(mask, options.blendMask)
	o.priority = o.priority + 1
	playHandler(combo[1], options)
	if combo[3] then	playHandler(combo[3], o)		end
end


return Anim
