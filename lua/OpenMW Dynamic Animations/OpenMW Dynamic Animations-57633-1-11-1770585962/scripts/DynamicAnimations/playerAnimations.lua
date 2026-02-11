local core = require("openmw.core")
local anim = require("openmw.animation")
local self = require("openmw.self")
local types = require("openmw.types")
local I = require("openmw.interfaces")

local Actor = {
	stanceNone = types.Actor.STANCE.Nothing,
	stanceWeapon = types.Actor.STANCE.Weapon
}

local logLevel = 0
local sneakPlaying

local C = {}
C.first = {
	walk10 = 154.064,
	walk09 = 154.064 * 15 / 14,
--	sneak = 33.5452 * 2.8 * 15 / 44,
	sneak = 33.5452,
	run = 222.857
	}

local Anims = {
	firstPerson = {
		walkforward = { g="walkforward_base", velocity=C.first.walk10, max=10000 },
		walkback = { g="walkback_base", velocity=C.first.walk10, max=10000 },
		walkleft = { g="walkleft_base", velocity=C.first.walk10, max=10000 },
		walkright = { g="walkright_base", velocity=C.first.walk10, max=10000 },
		runforward = { g="runforward_base", velocity=C.first.run, max=10000 },
		runback = { g="runback_base", velocity=C.first.run, max=10000 },
		runleft = { g="runleft_base", velocity=C.first.run, max=10000 },
		runright = { g="runright_base", velocity=C.first.run, max=10000 },
		sneakforward = { g="sneakforward_base", velocity=C.first.sneak, max=10000 },
		sneakback = { g="sneakback_base", velocity=C.first.sneak, max=10000 },
		sneakleft = { g="sneakleft_base", velocity=C.first.sneak, max=10000 },
		sneakright = { g="sneakright_base", velocity=C.first.sneak, max=10000 },
		maxWalk = 10000, maxRun = 10000
	},
	thirdPerson = {
		walkforward = { g="walkforward_spd09", velocity=154, max=10000 },
		dynamicWalk = { maxSpeed = 10000 },
		maxWalk = 10000, maxRun = 10000
	},
}



local function debug(m, level)
	if logLevel >= (level or 1) then	print(m)		end
end

function Anims.zillaScale()
--	if Actor.races[Actor.npcRecords.player.race].id == "argonian" then
	if anim.hasGroup(self, "zillarescale") then
		debug("ZILLA BONE RESCALE")
		anim.playBlended(self, "zillarescale", { priority=11 })
	end
end

function Anims.setOverrides(move, groups, overrides)
	for k, v in pairs(groups) do
		local speed, max, always
		if k:find("^walk") then
			speed = move.walkSpeed		max = groups.maxWalk
		elseif k:find("^run") then
			speed = move.runSpeed		max = groups.maxRun
		elseif k:find("^sneak") and Anims.useLowerSneak then
			speed = move.walkSpeed		max = groups.maxWalk
			always = true
		end
		if speed then
			if speed < max and not always then
				v.max = 10000
			else
				overrides[k] = v
				if max < speed then	v.max = max		end
			end
		end
	end
end

function Anims.idleController()
	if anim.getActiveGroup(self, 0) == "idle" then
		if Anims.idleTimer ~= 0 then
			if not Anims.idleTimer then
				Anims.idleTimer = core.getSimulationTime() + 2.9
				anim.setSpeed(self, "idle", 1)
			elseif Anims.idleTimer < core.getSimulationTime() then
				Anims.idleTimer = 0
				anim.setSpeed(self, "idle", 0.5)
			end
		end
	else
		Anims.idleTimer = nil
	end
end

function Anims.sneakController(s)
	if not s.inFirst or not Anims.useLowerSneak then
		sneakPlaying = false
		return
	end
--	debug("ODAR SNEAK EVENT")
	if not s.sneak or s.stance == Actor.stanceWeapon then
		if sneakPlaying then
			anim.cancel(self, "idlesneak_base")		sneakPlaying = false
			debug("ODAR CANCEL SNEAK")
		end
		return
	end
--	if (s.sneak and not sneakPlaying) or (s.viewChange and sneakPlaying) then
	if s.sneak and not anim.isPlaying(self, "idlesneak_base") then
		anim.playBlended(self, "idlesneak_base",
			{ priority={ [0] = 1 }, blendMask=1, forceLoop=true, loops=10000 })
		sneakPlaying = true
		debug("ODAR PLAY SNEAK")
	end
end

function Anims.cancelAll()
	debug("ODAR CANCEL EVENT")
	if sneakPlaying then
		anim.cancel(self, "idlesneak_base")		sneakPlaying = false
		debug("ODAR CANCEL SNEAK")
	end
end


return Anims
