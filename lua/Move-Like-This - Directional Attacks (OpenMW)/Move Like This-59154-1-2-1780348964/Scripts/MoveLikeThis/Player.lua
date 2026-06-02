--Hit Test script--
local ui = require('openmw.ui')

local I = require('openmw.interfaces')
local core  = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local util = require('openmw.util')
local anim = require('openmw.animation')
local ambient = require('openmw.ambient')

local AttackEffects = require('scripts.MoveLikeThis.attackEffects')
local OnHitLogic = require('scripts.MoveLikeThis.OnHitLogic')


I.Combat.addOnHitHandler(function(attack)
	OnHitLogic.DoOnHit(attack, self, true)
end)



local function MLT_DoBlockFeedback(eventData)
	core.sound.playSound3d("heavy armor hit", self)
	I.AnimationController.playBlendedAnimation("shield", {
		startKey = 'block start',
		stopKey = 'block stop',
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
	if not (isPlayingStaggerAnim() or isPlayingKnockBackOrOutAnim()) then
		if eventData.knockdown then
			staggerAnim = "knockdown"
			anim.clearAnimationQueue(self, true)
			anim.playQueued(self, staggerAnim, { 
				startKey = "start", 
				stopKey = "stop",
				loops = 0,
				forceLoop = true,
				speed = 1.2
			})
		else
			randomHit = math.random(1,5)
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
				speed = 1.2
			 })
		end
	end
end

local function isPlayingStaggerAnim()
	return anim.isPlaying(self, "hit1") or anim.isPlaying(self, "hit2") or anim.isPlaying(self, "hit3") or anim.isPlaying(self, "hit4") or anim.isPlaying(self, "hit5")
end

local function isPlayingKnockBackOrOutAnim()
	return anim.isPlaying(self, "knockdown") or anim.isPlaying(self, "knockout")
end


local function MLT_ApplyShortBladeBuff(eventData)
	shortBladeSkill = types.NPC.stats.skills.axe(self).modified
	buffId = ""
	if shortBladeSkill < 10 then
		buffId = "MLT_ShortBladeBuff_00"
	elseif shortBladeSkill < 20 then
		buffId = "MLT_ShortBladeBuff_10"
	elseif shortBladeSkill < 30 then
		buffId = "MLT_ShortBladeBuff_20"
	elseif shortBladeSkill < 40 then
		buffId = "MLT_ShortBladeBuff_30"
	elseif shortBladeSkill < 50 then
		buffId = "MLT_ShortBladeBuff_40"
	elseif shortBladeSkill < 60 then
		buffId = "MLT_ShortBladeBuff_50"
	elseif shortBladeSkill < 70 then
		buffId = "MLT_ShortBladeBuff_60"
	elseif shortBladeSkill < 80 then
		buffId = "MLT_ShortBladeBuff_70"
	elseif shortBladeSkill < 90 then
		buffId = "MLT_ShortBladeBuff_80"
	elseif shortBladeSkill < 100 then
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


local function MLT_CriticalHitMessage(eventData)
	ui.showMessage('Critical Hit!')
	if isPlaying == ambient.isSoundPlaying("critical damage") then
		ambient.stopSound("critical damage")
	end
	ambient.playSound("critical damage", options)
end

return {
    eventHandlers = {
		MLT_DirAttack_blockAnimSound = MLT_DoBlockFeedback,
		MLT_DirAttack_doStagger = MLT_DoStagger,
		MLT_DirAttack_criticalHit = MLT_CriticalHitMessage,
		MLT_shortBladeBuff = MLT_ApplyShortBladeBuff
    },
}

