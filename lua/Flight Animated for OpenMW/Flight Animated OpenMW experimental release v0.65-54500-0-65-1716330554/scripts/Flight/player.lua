local self = require("openmw.self")
local types = require("openmw.types")
local async = require("openmw.async")
local core = require("openmw.core")
local util = require("openmw.util")
local I = require("openmw.interfaces")
local animation = require("openmw.animation")
local camera = require("openmw.camera")

local Actor, ctrls = types.Actor, self.controls
local stance, ST = types.Actor.getStance(self), types.Actor.STANCE

local flight, moved = false, true
local savedOptions = {}

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
	["hit1"] = { id="hit1", opt={blendmask=14} },
	["hit2"] = { id="hit2", opt={blendmask=14} },
	["hit3"] = { id="hit3", opt={blendmask=14} },
	["hit4"] = { id="hit4", opt={blendmask=14} },
	["hit5"] = { id="hit5", opt={blendmask=14} },
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
	"swimwalkleft", "swimwalkright", "flyrunforward", "flyrunforwardup", "flyrunforwarddown",
	"flyrunback", "swimrunleft", "swimrunright" }

local flypitch = { "flyrunforward", "flyrunforwardup", "flyrunforwarddown", "flywalkforward" } 



local function switchAnimation(g, o)
	if Actor.activeEffects(self):getEffect("levitate").magnitude == 0 then return g end
	if camera.getMode() == camera.MODE.FirstPerson then flight=false return g end
	if not flight then
		animation.removeAllVfx(self)
		animation.addVfx(self, "VFX_LevitateHit", {bonename="Bip01 LevitateVfx", loop=true, vfxId="levitate"})
	end
	flight = true
	if Actor.activeEffects(self):getEffect("levitate").magnitude > 99 then
		g = string.gsub(g, "walk", "run")
	end
-- Compensate for omw Camera script doing 3rd person auto-rotate
	if string.find(g, "turnleft") or string.find(g, "turnright") then moved = true end
	local switch = switch1[g]
	if switch then
		if type(switch) == "table" then
			g = switch.id
			for k,v in pairs(switch.opt) do o[k] = v end
		else
			g = switch
		end
		if g == "flyrunforward" then
			for k,v in pairs(o) do savedOptions[k] = v end
			savedOptions.startkey, savedOptions.stopkey = "loop start", "stop"
			local pitch = math.deg(self.rotation:getPitch())
			if pitch < -35 then g = g.."up" end
			if pitch > 30 then g = g.."down" end
		end
		if g == "flywalkforward" then
			for k,v in pairs(o) do savedOptions[k] = v end
			savedOptions.startkey, savedOptions.stopkey = "loop start", "stop"
		end
	else
		switch = switch2[g]
		if switch then
			g = switch
			o.speed = 0.2
		end
	end
	return g
end


I.AnimationController.addPlayBlendedAnimationHandler(function (groupname, options)
  groupname = switchAnimation(groupname, options)
  return true, groupname
end)

local WPN = types.Weapon.TYPE
local wpnTypes = { [WPN.AxeOneHand] = "idle1h", [WPN.BluntOneHand] = "idle1h", [WPN.LongBladeOneHand] = "idle1h",
	[WPN.ShortBladeOneHand] = "idle1h", [WPN.AxeTwoHand] = "idle2c", [WPN.BluntTwoClose] = "idle2c",
	[WPN.BluntTwoWide] = "idle2w", [WPN.LongBladeTwoHand] = "idle2c", [WPN.SpearTwoWide] = "idle2w",
	[WPN.MarksmanBow] = "idle1h", [WPN.MarksmanCrossbow] = "idlecrossbow", [WPN.MarksmanThrown] = "idle1h"
		}

local function getIdleStance()
	if Actor.getStance(self) == ST.Nothing then return "idleflight" end
	if Actor.getStance(self) == ST.Spell then return "idlespell" end
	local item = Actor.getEquipment(self, Actor.EQUIPMENT_SLOT.CarriedRight)
	if item == nil then return "idlehh" end
	if item.type ~= types.Weapon then return "idleflight" end
	local idle = wpnTypes[types.Weapon.record(item).type]
	if not idle then idle = "idleflight" end
	return idle
end

local function onUpdate(dt)
	if camera.getMode() == camera.MODE.FirstPerson then return end
	if Actor.activeEffects(self):getEffect("levitate").magnitude == 0 then
		if not flight then return end
		for i=1, #flyCancel do
			animation.cancel(self, flyCancel[i])
		end
		flight = false
		return
	end
	local isPlay = nil
	for i=1, #flypitch do
		if animation.isPlaying(self, flypitch[i]) then isPlay = flypitch[i] end
	end
	if isPlay and string.find(isPlay, "runforward") then
		local pitch = math.deg(self.rotation:getPitch())
		if pitch < -35 and isPlay ~= "flyrunforwardup" then
			animation.cancel(self, isPlay)
			animation.playBlended(self, "flyrunforwardup", savedOptions)
		elseif pitch > 30 and isPlay ~= "flyrunforwarddown" then
			animation.cancel(self, isPlay)
			animation.playBlended(self, "flyrunforwarddown", savedOptions)
		elseif pitch >= -35 and pitch <= 30 and isPlay ~= "flyrunforward" then
			animation.cancel(self, isPlay)
			animation.playBlended(self, "flyrunforward", savedOptions)
		end
	end
	if ctrls.movement ~= 0 or ctrls.sideMovement ~= 0 or ctrls.yawChange ~= 0 then
		moved = true
		return
	end
	if stance ~= Actor.getStance(self) then
		moved = true
		stance = Actor.getStance(self)
	end
	if isPlay == nil then
		if moved then
			animation.cancel(self, "idleflight")
			moved = false
			local idleStance = getIdleStance()
			if idleStance == "idleflight" then
	animation.playBlended(self, "idleflight", {loops=50, priority=5, speed=0.2, forceloop=true})
			else
	animation.playBlended(self, idleStance, {loops=50, blendmask=14, priority=5})
	animation.playBlended(self, "idleflight", {loops=50, blendmask=1, priority=5, speed=0.2, forceloop=true})
			end
		end
		return
	end
	if string.find(isPlay, "runforward") then
		animation.cancel(self, isPlay)
		animation.playBlended(self, "swimrunforward", {startkey="loop stop", priority=6, speed=0.6})
	elseif string.find(isPlay, "walkforward") then
		animation.cancel(self, isPlay)
		animation.playBlended(self, "swimwalkforward", {startkey="loop stop", priority=6, speed=0.6})
	end
end

return {
	engineHandlers = { onUpdate = onUpdate },
}
