local config = require("Ring a Bell.config")
local i18n = mwse.loadTranslations("Ring a Bell")


local log = mwse.Logger.new({
	name = "Ring a Bell",
	logLevel = config.logLevel,
})

dofile("Ring a Bell.mcm")

log:info("Initialized v%s", config.version)

local sounds = {
	["active_6th_bell_01"] = "fx\\envrn\\bell6.wav",
	["active_6th_bell_02"] = "fx\\envrn\\bell5.wav",
	["active_6th_bell_03"] = "fx\\envrn\\bell4.wav",
	["active_6th_bell_04"] = "fx\\envrn\\bell3.wav",
	["active_6th_bell_05"] = "fx\\envrn\\bell2.wav",
	["active_6th_bell_06"] = "fx\\envrn\\bell1.wav",
}

local impactSoundsInstalled = lfs.directoryexists("Data Files\\MWSE\\mods\\Impact Sounds")
local impactSoundsFolderSounds = "4NM"

---@param reference tes3reference
local function getSoundPath(reference)
	local object = reference.baseObject
	if object.objectType ~= tes3.objectType.activator then return end
	return sounds[string.lower(object.id)]
end

---@param e activateEventData
local function blockBellActivation(e)
	if not getSoundPath(e.target) then return end
	tes3.messageBox(i18n("message"))
	e.block = true
end
event.register(tes3.event.activate, blockBellActivation)


-- Changes the pitch by given number of semitones
local function changePich(pitch, semitones)
	return pitch * 2 ^ (semitones / 12)
end


local initialPitch = {
	[tes3.weaponType.shortBladeOneHand] = 1.6,
	[tes3.weaponType.longBladeOneHand] = 1.5,
	[tes3.weaponType.longBladeTwoClose] = 1.2,
	[tes3.weaponType.bluntOneHand] = 1.2,
	[tes3.weaponType.bluntTwoClose] = 1.0,
	[tes3.weaponType.bluntTwoWide] = 1.2,
	[tes3.weaponType.spearTwoWide] = 1.2,
	[tes3.weaponType.axeOneHand] = 1.3,
	[tes3.weaponType.axeTwoHand] = 1.0,
}
local blockNextSound = false
local firstSound = false


---@param e addTempSoundEventData
local function blockNextImpactSound(e)
	if not impactSoundsInstalled then return end
	if e.reference ~= tes3.player then return end
	if e.isVoiceover then return end
	if not blockNextSound then return end
	if not e.path:startswith(impactSoundsFolderSounds) then return end
	-- The first sound played by Impact Sounds is custom attack swing sound.
	-- The next one is attack hit sound which we want to block in this case.
	firstSound = not firstSound
	if firstSound then return end
	log:debug("Blocking sound: %q", e.path)
	blockNextSound = false
	return true
end
event.register(tes3.event.addTempSound, blockNextImpactSound, { priority = 100 })

local function setBlockNextSound()
	blockNextSound = true
end

---@param e attackEventData
local function onAttack(e)
	local ref = e.reference
	if ref ~= tes3.player then return end
	local equipped = tes3.mobilePlayer.readiedWeapon
	if not equipped then return end
	local weapon = equipped.object

	local hit = tes3.rayTest({
		position = tes3.getPlayerEyePosition(),
		direction = tes3.getPlayerEyeVector(),
		ignore = { tes3.player, tes3.player1stPerson },
		maxDistance = tes3.getPlayerActivationDistance(),
		root = tes3.game.worldPickRoot,
	})
	if not hit then return end
	local hitReference = hit.reference
	local sound = getSoundPath(hitReference)
	if not sound then return end

	local pitch = initialPitch[weapon.type]
	local swing = e.mobile.actionData.attackSwing

	pitch = math.remap(swing, 0.0, 1.0, changePich(pitch, -config.semitones), changePich(pitch, config.semitones))
	local refHandle = tes3.makeSafeObjectHandle(hitReference)
	setBlockNextSound()
	timer.start({
		duration = 0.25,
		type = timer.simulate,
		callback = function()
			if not refHandle:valid() then return end
			tes3.playSound({
				reference = refHandle:getObject(),
				-- The pitch can't be changed if the same sound is played multiple
				-- times by passing `sound` param, while passing a `soundPath` can.
				soundPath = sound,
				pitch = pitch,
			})
		end
	})
end
event.register(tes3.event.attack, onAttack)
