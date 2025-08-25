local self = require("openmw.self")
local types = require("openmw.types")
local async = require("openmw.async")
local core = require("openmw.core")
local util = require("openmw.util")
local I = require("openmw.interfaces")
local anim = require("openmw.animation")
local camera = require("openmw.camera")
local ui = require("openmw.ui")
local input = require("openmw.input")
local nearby = require("openmw.nearby")
local time = require("openmw_aux.time")

I.Settings.registerPage {
   key = "FlightAnimated",
   l10n = "FlightAnimated",
   name = "Flight Animated",
   description = "version 0.71\n\nEnhances levitation with flying animations and vertical movement controls."
}

I.Settings.registerGroup({
   key = "Settings_FlightAnimated",
   page = "FlightAnimated",
   l10n = "FlightAnimated",
   name = "Settings",
   permanentStorage = true,
   settings = {
      {
         key = "animations",
         default = true,
         renderer = "checkbox",
         name = "Enable flying animations"
      },
      {
         key = "liftControl",
         default = true,
         renderer = "checkbox",
         name = "Move vertically using Jump/Sneak"
      },
      {
         key = "ringVfx",
         default = true,
         renderer = "checkbox",
         name = "Show levitation ring VFX"
      },
   },
})


local Actor, ctrls = types.Actor, self.controls
local stance, ST = types.Actor.getStance(self), types.Actor.STANCE
local effects = Actor.activeEffects(self)

local isMoving, isFlying, isSwimming = true
local inFirst = camera.getMode() == camera.MODE.FirstPerson
local saved = { group="", options = {} }

local switch1 = {
	["turnright"] = { id="swimturnright", opt={speed=1} },
	["turnright1h"] = { id="swimturnright", opt={speed=1} },
	["turnright2c"] = { id="swimturnright", opt={speed=1} },
	["turnright2w"] = { id="swimturnright", opt={speed=1} },
	["turnrighthh"] = { id="swimturnright", opt={speed=1} },
	["spellturnright"] = { id="swimturnright", opt={speed=1} },
	["turnleft"] = { id="swimturnleft", opt={speed=1} },
	["turnleft1h"] = { id="swimturnleft", opt={speed=1} },
	["turnleft2c"] = { id="swimturnleft", opt={speed=1} },
	["turnleft2w"] = { id="swimturnleft", opt={speed=1} },
	["turnlefthh"] = { id="swimturnleft", opt={speed=1} },
	["spellturnleft"] = { id="swimturnleft", opt={speed=1} },
	["hit1"] = { id="hit1", opt={blendMask=14} },
	["hit2"] = { id="hit2", opt={blendMask=14} },
	["hit3"] = { id="hit3", opt={blendMask=14} },
	["hit4"] = { id="hit4", opt={blendMask=14} },
	["hit5"] = { id="hit5", opt={blendMask=14} },
	["death1"] = "swimdeath",
	["death2"] = "swimdeath",
	["death3"] = "swimdeath",
	["death4"] = "swimdeath",
	["death5"] = "swimdeath",
	["deathknockdown"] = "swimdeathknockdown",
	["deathknockout"] = "swimdeathknockout",
	["knockdown"] = "swimknockdown",
	["knockout"] = "swimknockout",

	["walkforward"] = { id="flywalkforward", opt={speed=0.6} },
	["walkforward1h"] = { id="flywalkforward", opt={speed=0.6} },
	["walkforward2c"] = { id="flywalkforward", opt={speed=0.6} },
	["walkforward2w"] = { id="flywalkforward", opt={speed=0.6} },
	["walkforwardhh"] = { id="flywalkforward", opt={speed=0.6} },

	["runforward"] = { id="flyrunforward", opt={speed=0.6} },
	["runforward1h"] = { id="flyrunforward", opt={speed=0.6} },
	["runforward2c"] = { id="flyrunforward", opt={speed=0.6} },
	["runforward2w"] = { id="flyrunforward", opt={speed=0.6} },
	["runforwardhh"] = { id="flyrunforward", opt={speed=0.6} },

	}

local switch2 = {
	["walkback"] = "swimwalkback",
	["walkleft"] = "swimwalkleft",
	["walkright"] = "swimwalkright",
	["walkback1h"] = "swimwalkback",
	["walkback2c"] = "swimwalkback",
	["walkback2w"] = "swimwalkback",
	["walkbackhh"] = "swimwalkback",
	["walkleft1h"] = "swimwalkleft",
	["walkleft2c"] = "swimwalkleft",
	["walkleft2w"] = "swimwalkleft",
	["walklefthh"] = "swimwalkleft",
	["walkright1h"] = "swimwalkright",
	["walkright2c"] = "swimwalkright",
	["walkright2w"] = "swimwalkright",
	["walkrighthh"] = "swimwalkright",
	["runback"] = "flyrunback",
	["runleft"] = "swimrunleft",
	["runright"] = "swimrunright",
	["runback1h"] = "flyrunback",
	["runback2c"] = "flyrunback",
	["runback2w"] = "flyrunback",
	["runbackhh"] = "flyrunback",
	["runleft1h"] = "swimrunleft",
	["runleft2c"] = "swimrunleft",
	["runleft2w"] = "swimrunleft",
	["runlefthh"] = "swimrunleft",
	["runright1h"] = "swimrunright",
	["runright2c"] = "swimrunright",
	["runright2w"] = "swimrunright",
	["runrighthh"] = "swimrunright",

	["idleswim"] = "idleswim",
	["swimturnleft"] = "swimturnleft",
	["swimturnright"] = "swimturnright",
	["swimwalkforward"] = "swimrunforward",
	["swimwalkback"] = "flyrunback",
	["swimwalkleft"] = "swimrunleft",
	["swimwalkright"] = "swimrunright",
	["swimrunforward"] = "swimrunforward",
	["swimrunback"] = "flyrunback",
	["swimrunleft"] = "swimrunleft",
	["swimrunright"] = "swimrunright",

	}


local flyCancel = { "swimturnleft", "swimturnright", "idleflight", "swimwalkforward", "swimwalkback",
	"swimwalkleft", "swimwalkright", "flywalkforward",
	"flyrunforward", "flyrunforwardup", "flyrunforwarddown", "flyrunback", "swimrunleft", "swimrunright",
	"levitate", "levitateforward", "levitatebackward", "levitateleft", "levitateright"

	}
for _, v in ipairs(flyCancel) do	flyCancel[v] = true		end


local L = {
	castRay = nearby.castRay,
	pressed = input.isActionPressed,
	Jump = input.ACTION.Jump,
	Sneak = input.ACTION.Sneak,
	v3 = util.vector3,
	center = util.vector3(0, 0, 75),
}

local fn = { groups = { idleflight = {} } }
fn.groups.resetVfxBone = { blendMask=1, priority=6, startKey="resetvfx", stopKey="resetvfx", delay=1 }
fn.groups.levitateforward = { blendMask=1, priority=6, startKey="forward", stopKey="forward" }
fn.groups.levitatebackward = { blendMask=1, priority=6, startKey="backward", stopKey="backward", delay=1 }
fn.groups.levitateleft = { blendMask=1, priority=6, startKey="flyleft", stopKey="flyleft", delay=1 }
fn.groups.levitateright = { blendMask=1, priority=6, startKey="flyright", stopKey="flyright", delay=1 }


fn.play = function(g, o)
	-- ReAnimations throws an error if keys are missing
	o.startKey = o.startKey or "start"
	o.stopKey = o.stopKey or "stop"

	I.AnimationController.playBlendedAnimation(g, o)
end
fn.vfx = function(g)
	if inFirst then		return		end
	if g ~= anim.getActiveGroup(self, 0) then
		return
	end

	-- All Fly groups already animate the vfx bone
	if g:sub(1,3) == "fly" then
	--	print("FLY BLOCK")
		return
	end

--	print(g)
	local vfx = fn.groups[g]
--	print(vfx, fn.lastVfx)
	if vfx and vfx ~= fn.lastVfx then
		if next(vfx) then
			-- print(g)
			anim.playBlended(self, "vfxflight", vfx)
		end
		fn.lastVfx = vfx
	end
end
fn.vfxReset = function()
	local g = anim.getActiveGroup(self, 0) or ""
--	print(g)
	if g:sub(1,3) == "fly" or fn.groups[g] then
	--	print("IDLE BLOCK")
		return
	end

	local vfx = fn.groups["resetVfxBone"]
	if vfx ~= fn.lastVfx then
		-- print(g)
		anim.playBlended(self, "vfxflight", vfx)
		fn.lastVfx = vfx
	end
end
	
local lift = { d = 0, v = 0, mag = 0 }

local settings = require("openmw.storage").playerSection("Settings_FlightAnimated")
function fn.updateSettings()
	L.noAnim = types.NPC.races.records[types.NPC.record(self).race].isBeast
		or (not settings:get("animations"))
	L.doVfx = settings:get("ringVfx")
	L.liftOn = I.luaHelper and I.luaHelper.version > 55 and settings:get("liftControl")
end

settings:subscribe(async:callback(fn.updateSettings))
fn.updateSettings()


local function switchVFX()
	if inFirst or not isFlying then		return		end

	anim.removeAllVfx(self)
	self:sendEvent("vfxRemoveAll")
	if L.doVfx then
		anim.addVfx(self, "meshes/e/taitech/levitateRings.nif",
			{boneName="Bip01 LevitateVfx", loop=true, vfxId=core.magic.EFFECT_TYPE.Levitate})
	end
end

local function switchAnimation(g, o)
	if L.noAnim or not isFlying then		return		end
	if camera.getMode() == camera.MODE.FirstPerson then	return		end

	if lift.mag > 99 then
		g = string.gsub(g, "walk", "run")
	end

	-- Compensate for omw Camera script doing 3rd person auto-rotate
	if string.find(g, "turnleft") or string.find(g, "turnright") then isMoving = true	end
	local switch = switch1[g]
	if switch then
		if type(switch) == "table" then
			g = switch.id
			for k,v in pairs(switch.opt) do o[k] = v end
		else
			g = switch
		end
		if flyCancel[g] then
			saved.group = g
			for k,v in pairs(o) do		saved.options[k] = v	end
		end
		if g == "flyrunforward" then
			saved.options.startKey, saved.options.stopKey = "loop start", "stop"
			local pitch = math.deg(self.rotation:getPitch())
			if pitch < -35 then g = g.."up" end
			if pitch > 30 then g = g.."down" end
		end
		if g == "flywalkforward" then
			saved.options.startKey, saved.options.stopKey = "loop start", "stop"
		end
	else
		switch = switch2[g]
		if switch then
			o.speed = 0.2
			g = switch		saved.group = g
			if flyCancel[g] then
				for k,v in pairs(o) do		saved.options[k] = v	end
			end
		end
	end
	if not switch then		return		end

	anim.playBlended(self, g, o)
	o.skip = true
	local vfx = fn.groups[g]
	if L.doVfx and vfx and next(vfx) then
		if vfx.delay then
	--		print("VFX DELAY")
			async:newUnsavableSimulationTimer(vfx.delay, function() fn.vfx(g) end)
		else
			fn.vfx(g)
		end
	elseif g:sub(1,3) == "fly" or vfx then
		fn.lastVfx = nil
	end
	return false
end


I.AnimationController.addPlayBlendedAnimationHandler(switchAnimation)

local wpnTypes
do
	local WPN = types.Weapon.TYPE
	wpnTypes = { [WPN.AxeOneHand] = "idle1h", [WPN.BluntOneHand] = "idle1h", [WPN.LongBladeOneHand] = "idle1h",
		[WPN.ShortBladeOneHand] = "idle1h", [WPN.AxeTwoHand] = "idle2c", [WPN.BluntTwoClose] = "idle2c",
		[WPN.BluntTwoWide] = "idle2w", [WPN.LongBladeTwoHand] = "idle2c", [WPN.SpearTwoWide] = "idle2w",
		[WPN.MarksmanBow] = "idle1h", [WPN.MarksmanCrossbow] = "idlecrossbow", [WPN.MarksmanThrown] = "idle1h"
	}
end

local function getIdleStance()
	if Actor.getStance(self) == ST.Nothing then	return			end
	if Actor.getStance(self) == ST.Spell then	return "idlespell"	end
	local item = Actor.getEquipment(self, Actor.EQUIPMENT_SLOT.CarriedRight)
	if item == nil then				return "idlehh"		end
	if item.type ~= types.Weapon then		return			end
	return wpnTypes[types.Weapon.record(item).type]
end

local flyGroups
fn.initGroups = function()

	local f = function(g) return anim.hasGroup(self, g) and g	end
	flyGroups = { idle = {name="idleflight", speed=0.2} }

	flyGroups.idle = f("levitate") and {name="levitate", speed=1} or flyGroups.idle
	switch1["walkforward"] = f("levitateforward") or switch1.walkforward
	switch2["walkback"] = f("levitatebackward") or switch2.walkback
	switch2["walkleft"] = f("levitateleft") or switch2.walkleft
	switch2["walkright"] = f("levitateright") or switch2.walkright

end

time.runRepeatedly(function()		local dt = 0.1

	lift.mag = effects:getEffect("levitate").magnitude
	local swim = types.Actor.isSwimming(self)
	if lift.mag == 0 and not isFlying and not swim and not isSwimming then
		return
	end
	if lift.mag == 0 then
		if isFlying then
			-- print(anim.getActiveGroup(self, 0))
			for i=1, #flyCancel do
				anim.cancel(self, flyCancel[i])
			end
		end
		if lift.moveZ ~= 0 and not isSwimming then
		--	print("CLEAR VECTOR")
			core.sendGlobalEvent("olh_playerController")
			lift.moveZ = 0
		end
		isFlying = false
	else
		lift.v = (types.Actor.getWalkSpeed(self) * 0.3 + lift.mag) * 3.2
		if not isFlying then
			isFlying = true		isMoving = true
			lift.d = 0		lift.moveZ = 0
			async:newUnsavableSimulationTimer(2, switchVFX)
		end
	end
	if not isFlying then
		if not swim then
			if lift.moveZ ~= 0 then
			--	print("CLEAR VECTOR")
				core.sendGlobalEvent("olh_playerController")
				lift.moveZ = 0
			end
			if isSwimming then
			--	print("SWIM OFF")
				isSwimming = false		ctrls.sneak = false
			end
		else
			lift.v = (ctrls.run and types.Actor.getRunSpeed
					 or types.Actor.getWalkSpeed)(self) * 0.5
			if not isSwimming then
			--	print("SWIM ON")
				isSwimming = true
				lift.d = 0		lift.moveZ = 0
			end
		end
	end
	if not isFlying and not swim then		return			end

	if L.liftOn then
		local d = (L.pressed(L.Jump) and 1) or
			(L.pressed(L.Sneak) and -1) or 0
		if d == 0 then
			if lift.d ~= 0 then
			--	print("HALT")
				core.sendGlobalEvent("olh_playerController")
				lift.d = 0		lift.moveZ = 0
			end
		else
			local from = self.position + L.center
			local to = from + L.v3(0, 0, (75 + lift.v * dt) * d)
			if L.castRay(from, to, {ignore=self}).hit then
				if lift.d ~= 0 then
					core.sendGlobalEvent("olh_playerController")
				--	print("COLLISION")
				end
				lift.d = 0		lift.moveZ = 0
			else
				local v = lift.v * d
				if types.Actor.getCurrentSpeed(self) > 0 then
					v = v * 0.4
					local pitch = self.rotation:getPitch()
					if math.abs(pitch) > math.rad(25) and pitch * d < 0 then
					--	print("TOO ANGLED")
						v = 0
					end
				end
				if v ~= lift.moveZ then
					core.sendGlobalEvent("olh_playerController",
						{mode=2, vector3={0, 0, v}})
					lift.moveZ = v
				--	print("LIFT", v)
				end
				lift.d = d
			end
		end
	end
	if L.noAnim or not isFlying then		return			end

	if camera.getMode() == camera.MODE.FirstPerson then
		inFirst = true
		return
	end

	local isPlay = anim.getActiveGroup(self, 0) or ""
	if isPlay:find("^flyrunforward") then
		local pitch = math.deg(self.rotation:getPitch())
		if pitch < -35 and isPlay ~= "flyrunforwardup" then
			anim.cancel(self, isPlay)
			fn.play("flyrunforwardup", saved.options)
		elseif pitch > 30 and isPlay ~= "flyrunforwarddown" then
			anim.cancel(self, isPlay)
			fn.play("flyrunforwarddown", saved.options)
		elseif pitch >= -35 and pitch <= 30 and isPlay ~= "flyrunforward" then
			anim.cancel(self, isPlay)
			fn.play("flyrunforward", saved.options)
		end
	end
	if stance ~= Actor.getStance(self) then
		if Actor.getStance(self) == ST.Nothing then
			saved.options.blendMask = 15
			anim.cancel(self, saved.group)
			anim.playBlended(self, saved.group, saved.options)
		end
		isMoving = true
		stance = Actor.getStance(self)
	end

	if inFirst then
		inFirst = false		isMoving = true
		switchVFX()
	end
	if not flyGroups then		fn.initGroups()		end

end, 0.1)

local function onUpdate(dt)
	if dt <= 0 or not (isFlying or isSwimming) then		return		end

	if L.liftOn and L.pressed(L.Sneak) then ctrls.sneak = false			end
	if not isFlying then		return			end

	if ctrls.movement ~= 0 or ctrls.sideMovement ~= 0 or ctrls.yawChange ~= 0 then
		isMoving = true
		return
	end

	if inFirst or L.noAnim then		return			end
	if not isMoving then		return		end

	-- Player is idle. Play correct idle animation
	isMoving = false
	local isPlay = anim.getActiveGroup(self, 0) or ""
	if isPlay:find("^fly") or isPlay:find("^levitate") then
		anim.cancel(self, isPlay)
	end
	local idle = flyGroups.idle
	local idleStance = getIdleStance()
	if idleStance then
		fn.play(idleStance, {loops=50, blendMask=14, priority=5})
		fn.play(idle.name, {loops=50, blendMask=1, priority=5, speed=idle.speed, forceLoop=true})
	else
		anim.cancel(self, idle.name)
		fn.play(idle.name, {loops=50, priority=5, speed=idle.speed, forceLoop=true})
	end
	if L.doVfx then
		async:newUnsavableSimulationTimer(0.5, fn.vfxReset)
	end

end

core.sendGlobalEvent("olh_playerController")


return {
	engineHandlers = { onUpdate = onUpdate },
	eventHandlers = {
		olhInitialized = function()
			L.liftOn = I.luaHelper and I.luaHelper.version > 55 and settings:get("liftControl")
		end
	},
}
