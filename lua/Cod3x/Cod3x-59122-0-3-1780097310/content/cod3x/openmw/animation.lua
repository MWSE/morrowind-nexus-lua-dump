---@meta

-- This file was mechanically drafted from files/lua_api/openmw/animation.lua.
-- It uses LuaLS/LLS annotations and stub bodies only; runtime behavior is provided by OpenMW.
-- OpenMW script contexts: local

---Defines functions that allow control of character animations.
---Note that for some methods, such as openmw.animation.playBlended you should use the associated methods on the
---[AnimationController](interface_animation.html) interface rather than invoking this API directly.
---@class openmw.animation
local animation = {}

---`animation.PRIORITY`
---@class openmw.animation.Priority
---@field Default number "0"
---@field WeaponLowerBody number "1"
---@field SneakIdleLowerBody number "2"
---@field SwimIdle number "3"
---@field Jump number "4"
---@field Movement number "5"
---@field Hit number "6"
---@field Weapon number "7"
---@field Block number "8"
---@field Knockdown number "9"
---@field Torch number "10"
---@field Storm number "11"
---@field Death number "12"
---@field Scripted number "13" Special priority used by scripted animations. When any animation with this priority is present, all animations without this priority are paused.
local Priority = {}

---`animation.BLEND_MASK`
---@class openmw.animation.BlendMask
---@field LowerBody number "1" All bones from 'Bip01 pelvis' and below
---@field Torso number "2" All bones from 'Bip01 Spine1' and up, excluding arms
---@field LeftArm number "4" All bones from 'Bip01 L Clavicle' and out
---@field RightArm number "8" All bones from 'Bip01 R Clavicle' and out
---@field UpperBody number "14" All bones from 'Bip01 Spine1' and up, including arms
---@field All number "15" All bones
local BlendMask = {}

---`animation.BONE_GROUP`
---@class openmw.animation.BoneGroup
---@field LowerBody number "1" All bones from 'Bip01 pelvis' and below
---@field Torso number "2" All bones from 'Bip01 Spine1' and up, excluding arms
---@field LeftArm number "3" All bones from 'Bip01 L Clavicle' and out
---@field RightArm number "4" All bones from 'Bip01 R Clavicle' and out
local BoneGroup = {}

---Possible Priority values
---@type openmw.animation.Priority
animation.PRIORITY = nil

---Possible BlendMask values
---@type openmw.animation.BlendMask
animation.BLEND_MASK = nil

---Possible BoneGroup values
---@type openmw.animation.BoneGroup
animation.BONE_GROUP = nil

---Check if the object has an animation object or not
---@param actor openmw.Object
---@return boolean
function animation.hasAnimation(actor) end

---Skips animations for one frame, equivalent to mwscript's SkipAnim.
---Can only be used on self.
---@param actor openmw.SelfObject
function animation.skipAnimationThisFrame(actor) end

---Get the absolute position within the animation track of the given text key
---@param actor openmw.Object
---@param text string key
---@return number
function animation.getTextKeyTime(actor, text) end

---Check if the given animation group is currently playing
---@param actor openmw.Object
---@param groupName string
---@return boolean
function animation.isPlaying(actor, groupName) end

---Get the current absolute time of the given animation group if it is playing, or -1 if it is not playing.
---@param actor openmw.Object
---@param groupName string
---@return number
function animation.getCurrentTime(actor, groupName) end

---Check whether the animation is a looping animation or not. This is determined by a combination
---of groupName, some of which are hardcoded to be looping, and the presence of loop start/stop keys.
---The groupNames that are hardcoded as looping are the following, as well as per-weapon-type suffixed variants of each.
---"walkforward", "walkback", "walkleft", "walkright", "swimwalkforward", "swimwalkback", "swimwalkleft", "swimwalkright",
---"runforward", "runback", "runleft", "runright", "swimrunforward", "swimrunback", "swimrunleft", "swimrunright",
---"sneakforward", "sneakback", "sneakleft", "sneakright", "turnleft", "turnright", "swimturnleft", "swimturnright",
---"spellturnleft", "spellturnright", "torch", "idle", "idle2", "idle3", "idle4", "idle5", "idle6", "idle7", "idle8",
---"idle9", "idlesneak", "idlestorm", "idleswim", "jump", "inventoryhandtohand", "inventoryweapononehand",
---"inventoryweapontwohand", "inventoryweapontwowide"
---@param actor openmw.Object
---@param groupName string
---@return boolean
function animation.isLoopingAnimation(actor, groupName) end

---Cancels and removes the animation group from the list of active animations.
---Can only be used on self.
---@param actor openmw.SelfObject
---@param groupName string
function animation.cancel(actor, groupName) end

---Enables or disables looping for the given animation group. Looping is enabled by default.
---Can only be used on self.
---@param actor openmw.SelfObject
---@param groupName string
---@param enabled boolean
function animation.setLoopingEnabled(actor, groupName, enabled) end

---Returns the completion of the animation, or nil if the animation group is not active.
---@param actor openmw.Object
---@param groupName string
---@return number|nil
function animation.getCompletion(actor, groupName) end

---Returns the remaining number of loops, not counting the current loop, or nil if the animation group is not active.
---@param actor openmw.Object
---@param groupName string
---@return number|nil
function animation.getLoopCount(actor, groupName) end

---Get the current playback speed of an animation group, or nil if the animation group is not active.
---@param actor openmw.Object
---@param groupName string
---@return number|nil
function animation.getSpeed(actor, groupName) end

---Modifies the playback speed of an animation group.
---Note that this is not sticky and only affects the speed until the currently playing sequence ends.
---Can only be used on self.
---@param actor openmw.SelfObject
---@param groupName string
---@param speed number The new animation speed, where speed=1 is normal speed.
function animation.setSpeed(actor, groupName, speed) end

---Clears all animations currently in the animation queue. This affects animations played by mwscript, openmw.animation.playQueued, and ai packages, but does not affect animations played using openmw.animation.playBlended.
---Can only be used on self.
---@param actor openmw.SelfObject
---@param clearScripted boolean whether to keep animation with priority Scripted or not.
function animation.clearAnimationQueue(actor, clearScripted) end

---Acts as a slightly extended version of MWScript's LoopGroup. Plays this animation exclusively
---until it ends, or the queue is cleared using #clearAnimationQueue. Use #clearAnimationQueue and the `startkey` option
---to imitate the behavior of LoopGroup's play modes.
---Can only be used on self.
---anim.clearAnimationQueue(self, false)
---anim.playQueued(self, 'death1')
---anim.clearAnimationQueue(self, false)
---anim.playQueued(self, 'spellcast', { startKey = 'self start', stopKey = 'self stop' })
---@param actor openmw.SelfObject
---@param groupName string
---@param options table A table of play options.  Can contain: * `loops` - a number >= 0, the number of times the animation should loop after the first play (default: infinite). * `speed` - a floating point number >= 0, the speed at which the animation should play (default: 1); * `startKey` - the animation key at which the animation should start (default: "start") * `stopKey` - the animation key at which the animation should end (default: "stop") * `forceLoop` - a boolean, to set if the animation should loop even if it's not a looping animation (default: false)
function animation.playQueued(actor, groupName, options) end

---Play an animation directly. You probably want to use the [AnimationController](interface_animation.html) interface, which will trigger relevant handlers,
---instead of calling this directly. Note that the still hardcoded character controller may at any time and for any reason alter
---or cancel currently playing animations, so making your own calls to this function either directly or through the [AnimationController](interface_animation.html)
---interface may be of limited utility. For now, use openmw.animation#playQueued to script your own animations.
---Can only be used on self.
---@param actor openmw.SelfObject
---@param groupName string
---@param options table A table of play options. Can contain: * `loops` - a number >= 0, the number of times the animation should loop after the first play (default: 0). * `priority` - Either a single #Priority value that will be assigned to all bone groups. Or a table mapping bone groups to its priority (default: PRIORITY.Default). * `blendMask` - A mask of which bone groups to include in the animation (Default: BLEND_MASK.All). * `autoDisable` - If true, the animation will be immediately  removed upon finishing, which means information will not be possible to query once completed. (Default: true) * `speed` - a floating point number >= 0, the speed at which the animation should play (default: 1) * `startKey` - the animation key at which the animation should start (default: "start") * `stopKey` - the animation key at which the animation should end (default: "stop") * `startPoint` - a floating point number 0 <= value <= 1, starting completion of the animation (default: 0) * `forceLoop` - a boolean, to set if the animation should loop even if it's not a looping animation (default: false)
function animation.playBlended(actor, groupName, options) end

---Check if the actor's animation has the given animation group or not.
---@param actor openmw.Object
---@param groupName string
---@return boolean
function animation.hasGroup(actor, groupName) end

---Check if the actor's skeleton has the given bone or not
---@param actor openmw.Object
---@param boneName string
---@return boolean
function animation.hasBone(actor, boneName) end

---Get the current active animation for a bone group
---@param actor openmw.Object
---@param boneGroup number Bone group enum, see openmw.animation.BONE_GROUP
---@return string
function animation.getActiveGroup(actor, boneGroup) end

---Plays a VFX on the actor.
---Can only be used on self. Can also be evoked by sending an AddVfx event to the target actor.
---anim.addVfx(self, 'VFX_Hands', {boneName = 'Bip01 L Hand', particleTextureOverride = mgef.particle, loop = mgef.continuousVfx, vfxId = mgef.id..'_myuniquenamehere'})
----- later:
---anim.removeVfx(self, mgef.id..'_myuniquenamehere')
---local mgef = core.magic.effects.records[myEffectName]
---target:sendEvent('AddVfx', {
---})
---@param actor openmw.SelfObject
---@param model string path (normally taken from a record such as openmw.types.StaticRecord.model or similar)
---@param options? table optional table of parameters. Can contain: * `loop` - boolean, if true the effect will loop until removed (default: false). * `boneName` - name of the bone to attach the vfx to. (default: "") * `particleTextureOverride` - name of the particle texture to use. (default: "") * `vfxId` - a string ID that can be used to remove the effect later, using #removeVfx, and to avoid duplicate effects. The default value of "" can have duplicates. To avoid interaction with the engine, use unique identifiers unrelated to magic effect IDs. The engine uses this identifier to add and remove magic effects based on what effects are active on the actor. If this is set equal to the openmw.core.MagicEffectId identifier of the magic effect being added, for example core.magic.EFFECT_TYPE.FireDamage, then the engine will remove it once the fire damage effect on the actor reaches 0. (Default: ""). * `useAmbientLight` - boolean, vfx get a white ambient light attached in Morrowind. If false don't attach this. (default: true)
function animation.addVfx(actor, model, options) end

---Removes a specific VFX.
---Can only be used on self.
---@param actor openmw.SelfObject
---@param vfxId string a string ID that uniquely identifies the VFX to remove
function animation.removeVfx(actor, vfxId) end

---Removes all vfx from the actor.
---Can only be used on self.
---@param actor openmw.SelfObject
function animation.removeAllVfx(actor) end

return animation
