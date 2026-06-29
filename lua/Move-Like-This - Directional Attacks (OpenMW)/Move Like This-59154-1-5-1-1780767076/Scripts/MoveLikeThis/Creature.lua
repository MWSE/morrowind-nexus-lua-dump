--Hit Test script--
local I = require("openmw.interfaces")
local core  = require("openmw.core")
local self = require("openmw.self")
local types = require("openmw.types")
local util = require("openmw.util")
local anim = require("openmw.animation")

local AttackEffects = require("scripts.MoveLikeThis.attackEffects")
local OnHitLogic = require("scripts.MoveLikeThis.OnHitLogic")
local MLTUtils = require("scripts.MoveLikeThis.utils")


I.Combat.addOnHitHandler(function(attack)
	OnHitLogic.DoOnHit(attack, self, false)
end)


local function MLT_DoBlockFeedback(eventData)
	core.sound.playSound3d("heavy armor hit", self)
	I.AnimationController.playBlendedAnimation("shield", {
		startKey = "block start",
		stopKey = "block stop",
		priority = {
			[anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Block,
			[anim.BONE_GROUP.Torso] = anim.PRIORITY.Block,
		},
		autoDisable = true,
		blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.Torso,
		speed = 1
	})
end

local function MLT_DoStagger(eventData)
	staggerAnim = nil
	if not (MLTUtils.isPlayingKnockBackOrOutAnim(self)) then
		if eventData.knockdown then
			-- staggerAnim = "knockdown"\
			staggerAnim = "knockdown"
			anim.clearAnimationQueue(self, true)
			anim.playQueued(self, staggerAnim, { 
				startKey = "start", 
				stopKey = "stop",
				loops = 0,
				forceLoop = true,
				speed = 1
			})
		else
			randomHit = math.random(1,5)
			--randomHit = 1
			staggerAnim = "hit" .. tostring(randomHit)
			if not anim.hasGroup(self, staggerAnim) then
				staggerAnim = "hit1"
			end
			anim.clearAnimationQueue(self, true)
			anim.playQueued(self, staggerAnim, { 
				startKey = "start", 
				stopKey = "stop",
				loops = 0,
				forceLoop = true,
				speed = 0.5
			 })
		end
		anim.clearAnimationQueue(self, false)
	end
end

local function MLT_DeathStaggerUnscrambler(eventData)
	--if MLTUtils.isPlayingKnockdownAnim(self) then --isPlayingStaggerAnim
	--	anim.clearAnimationQueue(self, true)
	if MLTUtils.isPlayingStaggerAnim(self) then
		anim.clearAnimationQueue(self, true)
		deathAnim = "death" .. tostring(randomHit)
		if not anim.hasGroup(self, deathAnim) then
			deathAnim = "death1"
		end
	end
end



local function MLT_ApplyMobilityBuff(eventData)
	attackSkill = eventData.skillLevel
	buffId = ""
	if attackSkill < 10 then
		buffId = "MLT_ShortBladeBuff_00"
	elseif attackSkill < 20 then
		buffId = "MLT_ShortBladeBuff_10"
	elseif attackSkill < 30 then
		buffId = "MLT_ShortBladeBuff_20"
	elseif attackSkill < 40 then
		buffId = "MLT_ShortBladeBuff_30"
	elseif attackSkill < 50 then
		buffId = "MLT_ShortBladeBuff_40"
	elseif attackSkill < 60 then
		buffId = "MLT_ShortBladeBuff_50"
	elseif attackSkill < 70 then
		buffId = "MLT_ShortBladeBuff_60"
	elseif attackSkill < 80 then
		buffId = "MLT_ShortBladeBuff_70"
	elseif attackSkill < 90 then
		buffId = "MLT_ShortBladeBuff_80"
	elseif attackSkill < 100 then
		buffId = "MLT_ShortBladeBuff_90"
	else
		buffId = "MLT_ShortBladeBuff_100"
	end
	options = {}
	options.id = buffId
	options.effects = { 0 }
	options.ignoreResistances  = true
	options.ignoreSpellAbsorption = true
	options.ignoreReflect  = true
	activeSpells = types.Actor.activeSpells(self)
	activeSpells:add(options)
end


local function MLT_ApplyBlindDebuff(eventData)
	attackSkill = eventData.skillLevel
	buffId = ""
	if attackSkill < 10 then
		buffId = "MLT_BlindDebuff_00"
	elseif attackSkill < 20 then
		buffId = "MLT_BlindDebuff_10"
	elseif attackSkill < 30 then
		buffId = "MLT_BlindDebuff_20"
	elseif attackSkill < 40 then
		buffId = "MLT_BlindDebuff_30"
	elseif attackSkill < 50 then
		buffId = "MLT_BlindDebuff_40"
	elseif attackSkill < 60 then
		buffId = "MLT_BlindDebuff_50"
	elseif attackSkill < 70 then
		buffId = "MLT_BlindDebuff_60"
	elseif attackSkill < 80 then
		buffId = "MLT_BlindDebuff_70"
	elseif attackSkill < 90 then
		buffId = "MLT_BlindDebuff_80"
	elseif attackSkill < 100 then
		buffId = "MLT_BlindDebuff_90"
	else
		buffId = "MLT_BlindDebuff_100"
	end
	options = {}
	options.id = buffId
	options.effects = { 0 }
	options.ignoreResistances  = true
	options.ignoreSpellAbsorption = true
	options.ignoreReflect  = true
	activeSpells = types.Actor.activeSpells(self)
	activeSpells:add(options)
end


return {
    eventHandlers = {
		Died = MLT_DeathStaggerUnscrambler,
		MLT_DirAttack_blockAnimSound = MLT_DoBlockFeedback,
		MLT_DirAttack_doStagger = MLT_DoStagger,
		MLT_shortBladeBuff = MLT_ApplyShortBladeBuff
    },
}


