--[[
	Nudge 'Em
	main.lua

	Main gameplay logic.

	This file handles target detection, range checks, nudging, cast animation, reaction sounds/animations, messages, debug logging, and event registration.
]]

local config = require("NudgeEm.config")
require("NudgeEm.mcm")

local logPrefix = "[Nudge 'Em]"
local nudgeCastEffectId = 143
local pendingNudgeData = nil
local suppressNudgeSkillProgress = false
local nudgeCastBusy = false

local function debugLog(message, ...)
	if not config.current.debugLog then
		return
	end

	mwse.log(logPrefix .. " " .. message, ...)
end

local function showMessage(message, ...)
	if not config.current.showMessages then
		return
	end

	tes3.messageBox(message, ...)
end

local npcVoiceTypes = {
	[0] = { name = "hello", value = tes3.voiceover.hello },
	[1] = { name = "idle", value = tes3.voiceover.idle },
	[2] = { name = "intruder", value = tes3.voiceover.intruder },
	[3] = { name = "thief", value = tes3.voiceover.thief },
	[4] = { name = "hit", value = tes3.voiceover.hit },
	[5] = { name = "attack", value = tes3.voiceover.attack },
	[6] = { name = "flee", value = tes3.voiceover.flee },
}

local creatureSoundTypes = {
	[0] = { name = "moan", value = tes3.soundGenType.moan },
	[1] = { name = "roar", value = tes3.soundGenType.roar },
	[2] = { name = "scream", value = tes3.soundGenType.scream },
}

local hitAnimationTypes = {
	{ name = "hit1", value = tes3.animationGroup.hit1 },
	{ name = "hit2", value = tes3.animationGroup.hit2 },
	{ name = "hit3", value = tes3.animationGroup.hit3 },
	{ name = "hit4", value = tes3.animationGroup.hit4 },
	{ name = "hit5", value = tes3.animationGroup.hit5 },
}

local nudgeHitSounds = {
	"hand to hand hit",
	"hand to hand hit 2",
}

local magicSkills = {
	[tes3.skill.alteration] = true,
	[tes3.skill.conjuration] = true,
	[tes3.skill.destruction] = true,
	[tes3.skill.illusion] = true,
	[tes3.skill.mysticism] = true,
	[tes3.skill.restoration] = true,
}

local function getReferenceName(reference)
	if not reference then
		return "Unknown"
	end

	local object = reference.baseObject or reference.object

	if not object then
		return "Unknown"
	end

	if object.name and object.name ~= "" then
		return object.name
	end

	return object.id or reference.id or "Unknown"
end

local function getReferenceUnderCursor()
	local hit = tes3.rayTest({
		position = tes3.getPlayerEyePosition(),
		direction = tes3.getPlayerEyeVector(),
		ignore = { tes3.player },
	})

	if not hit then
		return nil
	end

	return hit.reference
end

local function isActor(reference)
	if not reference then
		return false
	end

	if not reference.mobile then
		return false
	end

	return true
end

local function isDeadActor(reference)
	if not isActor(reference) then
		return false
	end

	return reference.isDead or reference.mobile.isDead
end

local function isNudgeableActor(reference)
	if not isActor(reference) then
		return false
	end

	if isDeadActor(reference) then
		return false
	end

	return true
end

local function isTargetInNudgeRange(reference)
	if not reference then
		return false
	end

	local range = config.current.nudgeRange or config.defaults.nudgeRange or 256
	local distance = reference.position:distance(tes3.player.position)

	return distance <= range
end

local function nudgeReference(reference)
	local distance = config.current.nudgeDistance or config.defaults.nudgeDistance

	local angle = tes3.player.orientation.z
	local dx = math.sin(angle) * distance
	local dy = math.cos(angle) * distance

	reference.position.x = reference.position.x + dx
	reference.position.y = reference.position.y + dy

	reference.modified = true
	reference:updateLighting()
end

local function playRandomNudgeHitSound(reference)
	if not reference then
		return
	end

	local sound = nudgeHitSounds[math.random(#nudgeHitSounds)]

	local success = tes3.playSound({
		reference = reference,
		sound = sound,
	})

	debugLog("Played nudge hit sound %s for %s. Success: %s", sound, getReferenceName(reference), tostring(success))
end

local function playPlayerNudgeCastAnimation(targetReference)
	if not targetReference then
		return
	end

	local effectObject = tes3.getMagicEffect(nudgeCastEffectId)

	if not effectObject then
		debugLog("Nudge cast effect not found: %s", tostring(nudgeCastEffectId))
		nudgeCastBusy = false
		pendingNudgeData = nil
		return
	end

	local oldMagicka = tes3.mobilePlayer.magicka.current

	local spell = tes3.createObject({
		id = "npcnudge_cast_animation_spell",
		objectType = tes3.objectType.spell,
		getIfExists = true,
	})

	if not spell then
		debugLog("Failed to create nudge cast animation spell.")
		nudgeCastBusy = false
		pendingNudgeData = nil
		return
	end

	spell.name = "Nudge 'Em Cast Animation"
	spell.magickaCost = 0

	local effect = spell.effects[1]

	if not effect then
		debugLog("Nudge cast animation spell has no effect slot.")
		nudgeCastBusy = false
		pendingNudgeData = nil
		return
	end

	effect.id = nudgeCastEffectId
	effect.rangeType = tes3.effectRange.target
	effect.min = 0
	effect.max = 0
	effect.duration = 0
	effect.radius = 0
	effect.skill = -1
	effect.attribute = -1

	suppressNudgeSkillProgress = true

	local success, errorMessage = pcall(function()
		tes3.cast({
			reference = tes3.player,
			target = targetReference,
			spell = spell,
			instant = false,
			alwaysSucceeds = true,
		})
	end)

	tes3.mobilePlayer.magicka.current = oldMagicka

	if not success then
		pendingNudgeData = nil
		suppressNudgeSkillProgress = false
		nudgeCastBusy = false
	end

	timer.start({
		duration = 1.5,
		type = timer.real,
		callback = function()
			suppressNudgeSkillProgress = false
			nudgeCastBusy = false
		end,
	})

	debugLog("Nudge cast animation success: %s error: %s", tostring(success), tostring(errorMessage))
end

local function playNpcVoiceover(reference, voiceConfigValue)
	if not reference or not reference.mobile or voiceConfigValue == nil or voiceConfigValue < 0 then
		return
	end

	local voice = npcVoiceTypes[voiceConfigValue]

	if not voice then
		return
	end

	local success = pcall(function()
		tes3.playVoiceover({
			actor = reference,
			voiceover = voice.value,
		})
	end)

	if success then
		debugLog("Played NPC voiceover %s for %s.", voice.name, getReferenceName(reference))
	else
		debugLog("No usable NPC voiceover %s for %s.", voice.name, getReferenceName(reference))
	end
end

local function playRandomNpcVoiceover(reference)
	local pool = {}

	for _, voice in pairs(npcVoiceTypes) do
		table.insert(pool, voice)
	end

	while #pool > 0 do
		local index = math.random(#pool)
		local choice = table.remove(pool, index)

		local success = pcall(function()
			tes3.playVoiceover({
				actor = reference,
				voiceover = choice.value,
			})
		end)

		if success then
			debugLog("Played random NPC voiceover %s for %s.", choice.name, getReferenceName(reference))
			return
		end
	end

	debugLog("No usable random NPC voiceover found for %s.", getReferenceName(reference))
end

local function playCreatureSound(reference, soundConfigValue)
	if not reference or soundConfigValue == nil or soundConfigValue < 0 then
		return false
	end

	local soundType = creatureSoundTypes[soundConfigValue]

	if not soundType then
		return false
	end

	local object = reference.baseObject or reference.object

	if not object then
		return false
	end

	local soundObject = object.soundCreature or object
	local soundGenerator = tes3.getSoundGenerator(soundObject.id, soundType.value)

	if not soundGenerator or not soundGenerator.sound then
		debugLog("No usable creature sound %s for %s.", soundType.name, getReferenceName(reference))
		return false
	end

	tes3.playSound({
		reference = reference,
		sound = soundGenerator.sound,
	})

	debugLog(
		"Played creature sound %s for %s. Sound record: %s.",
		soundType.name,
		getReferenceName(reference),
		soundGenerator.sound.id or "?"
	)

	return true
end

local function playRandomCreatureSound(reference)
	local pool = {}

	for _, soundType in pairs(creatureSoundTypes) do
		table.insert(pool, soundType)
	end

	while #pool > 0 do
		local index = math.random(#pool)
		local choice = table.remove(pool, index)

		local object = reference.baseObject or reference.object

		if object then
			local soundObject = object.soundCreature or object
			local soundGenerator = tes3.getSoundGenerator(soundObject.id, choice.value)

			if soundGenerator and soundGenerator.sound then
				tes3.playSound({
					reference = reference,
					sound = soundGenerator.sound,
				})

				debugLog(
					"Played random creature sound %s for %s. Sound record: %s.",
					choice.name,
					getReferenceName(reference),
					soundGenerator.sound.id or "?"
				)

				return
			end
		end
	end

	debugLog("No usable random creature sound found for %s.", getReferenceName(reference))
end

local function playRandomHitAnimation(reference)
	if not reference or not reference.mobile then
		return false
	end

	local pool = {}

	for _, animation in ipairs(hitAnimationTypes) do
		table.insert(pool, animation)
	end

	while #pool > 0 do
		local index = math.random(#pool)
		local choice = table.remove(pool, index)

		local timing = tes3.getAnimationActionTiming({
			reference = reference,
			group = choice.value,
		})

		if timing then
			tes3.playAnimation({
				reference = reference,
				group = choice.value,
				loopCount = 1,
			})

			debugLog("Played random hit animation %s for %s.", choice.name, getReferenceName(reference))
			return true
		end
	end

	debugLog("No usable hit animation found for %s.", getReferenceName(reference))
	return false
end

local function playNudgeReaction(reference)
	if not reference then
		return
	end

	local object = reference.baseObject or reference.object

	if not object then
		return
	end

	if object.objectType == tes3.objectType.npc then
		if config.current.reactionVoice == -2 then
			playRandomNpcVoiceover(reference)
		else
			playNpcVoiceover(reference, config.current.reactionVoice)
		end

		if config.current.playNpcReactionAnimation then
			playRandomHitAnimation(reference)
		end

		return
	end

	if object.objectType == tes3.objectType.creature then
		if config.current.creatureReactionSound == -2 then
			playRandomCreatureSound(reference)
		else
			playCreatureSound(reference, config.current.creatureReactionSound)
		end

		if config.current.playCreatureReactionAnimation then
			playRandomHitAnimation(reference)
		end

		return
	end
end

local function resolvePendingNudge()
	local data = pendingNudgeData
	pendingNudgeData = nil

	if not data or not data.reference then
		return
	end

	local reference = data.reference
	local name = data.name or getReferenceName(reference)

	if not isNudgeableActor(reference) then
		debugLog("Pending nudge target is no longer valid.")
		return
	end

	nudgeReference(reference)
	playRandomNudgeHitSound(reference)

	showMessage("Nudged: %s", name)
	debugLog("Nudged %s.", name)

	playNudgeReaction(reference)
end

local function nudgeTargetUnderCursor()
	if not config.current.enabled then
		return
	end

	if nudgeCastBusy and not config.current.instantNudge then
		debugLog("Nudge ignored. Cast is still busy.")
		return
	end

	local reference = getReferenceUnderCursor()

	if not isActor(reference) then
		showMessage("No NPC or creature under cursor.")
		debugLog("No nudgeable actor under cursor.")
		return
	end

	local name = getReferenceName(reference)

	if isDeadActor(reference) then
		showMessage("Can't nudge %s. It's dead.", name)
		debugLog("Can't nudge %s. It's dead.", name)
		return
	end

	if not isNudgeableActor(reference) then
		showMessage("No NPC or creature under cursor.")
		debugLog("No nudgeable actor under cursor.")
		return
	end

	if not isTargetInNudgeRange(reference) then
		return
	end

	if config.current.instantNudge then
		nudgeReference(reference)
		playRandomNudgeHitSound(reference)

		showMessage("Nudged: %s", name)
		debugLog("Instant nudged %s.", name)

		playNudgeReaction(reference)
		return
	end

	pendingNudgeData = {
		reference = reference,
		name = name,
	}

	nudgeCastBusy = true
	playPlayerNudgeCastAnimation(reference)
	debugLog("Started nudge cast for %s.", name)
end

local function keyMatches(e)
	local keyCombo = config.current.keyCombo or config.defaults.keyCombo

	if type(keyCombo) ~= "table" then
		return false
	end

	if e.keyCode ~= keyCombo.keyCode then
		return false
	end

	if keyCombo.isShiftDown and not tes3.isKeyDown({ keyCode = tes3.scanCode.leftShift }) and not tes3.isKeyDown({ keyCode = tes3.scanCode.rightShift }) then
		return false
	end

	if keyCombo.isAltDown and not tes3.isKeyDown({ keyCode = tes3.scanCode.leftAlt }) and not tes3.isKeyDown({ keyCode = tes3.scanCode.rightAlt }) then
		return false
	end

	if keyCombo.isControlDown and not tes3.isKeyDown({ keyCode = tes3.scanCode.leftControl }) and not tes3.isKeyDown({ keyCode = tes3.scanCode.rightControl }) then
		return false
	end

	return true
end

local function onKeyDown(e)
	if tes3ui.menuMode() then
		return
	end

	if not keyMatches(e) then
		return
	end

	nudgeTargetUnderCursor()
end

local function onMagicEffectsResolved()
	tes3.addMagicEffect({
		id = nudgeCastEffectId,
		name = "Nudge 'Em Cast Animation Effect",
		description = "Hidden effect used by Nudge 'Em to play the player's target-cast animation.",
		icon = "m\\Tx_Absorb.dds",
		particleTexture = "NudgeEm\\nudge.dds",

		baseCost = 0,
		school = tes3.magicSchool.alteration,

		canCastSelf = false,
		canCastTouch = false,
		canCastTarget = true,

		hasNoMagnitude = true,
		hasNoDuration = true,
		appliesOnce = true,
		isHarmful = false,
		allowEnchanting = false,
		allowSpellmaking = false,

		size = 0.01,
		sizeCap = 0.01,
		speed = 500,
		lighting = { x = 1.0, y = 1.0, z = 1.0 },

		castVFX = "VFX_Hands",
		boltVFX = "VFX_DefaultBolt",
		hitVFX = "VFX_Hands",
		areaVFX = "VFX_Hands",

		castSound = "nil",
		boltSound = "nil",
		hitSound = "nil",
		areaSound = "nil",

		onCollision = function()
			resolvePendingNudge()
			return false
		end,
	})
end

local function onExerciseSkill(e)
	if not suppressNudgeSkillProgress then
		return
	end

	if magicSkills[e.skill] then
		debugLog("Blocked nudge magic skill progress. Skill: %s Progress: %s", tostring(e.skill), tostring(e.progress))
		e.block = true
		return false
	end
end

local function onInitialized()
	mwse.log("%s Initialized.", logPrefix)
end

event.register(tes3.event.magicEffectsResolved, onMagicEffectsResolved)
event.register(tes3.event.exerciseSkill, onExerciseSkill)
event.register("initialized", onInitialized)
event.register("keyDown", onKeyDown)