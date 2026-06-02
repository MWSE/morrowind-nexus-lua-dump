--Hit Test script--
local I = require('openmw.interfaces')
local core  = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local util = require('openmw.util')
local anim = require('openmw.animation')

local AttackEffects = require('scripts.MoveLikeThis.attackEffects')
local OnHitLogic = require('scripts.MoveLikeThis.OnHitLogic')


I.Combat.addOnHitHandler(function(attack)
	OnHitLogic.DoOnHit(attack, self, false)
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
	--if true then
	if not (isPlayingStaggerAnim() or isPlayingKnockBackOrOutAnim()) then
		if eventData.knockdown then
			-- staggerAnim = "knockdown"\
			staggerAnim = "knockdown"
			anim.clearAnimationQueue(self, true)
			anim.playQueued(self, staggerAnim, { 
				startKey = "start", 
				stopKey = "stop",
				loops = 0,
				forceLoop = true
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
				forceLoop = true
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

return {
    eventHandlers = {
		MLT_DirAttack_blockAnimSound = MLT_DoBlockFeedback,
		MLT_DirAttack_doStagger = MLT_DoStagger,
		MLT_shortBladeBuff = MLT_ApplyShortBladeBuff
    },
}


--core.sound.playSound3d("heavy armor hit", victim)


