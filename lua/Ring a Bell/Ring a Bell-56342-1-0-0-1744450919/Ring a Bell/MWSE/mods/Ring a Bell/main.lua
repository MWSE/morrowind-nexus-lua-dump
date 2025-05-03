local logger = require("logging.logger")

local config = require("Ring a Bell.config")
local i18n = mwse.loadTranslations("Ring a Bell")


local log = logger.new({
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
local hammerId = "6th bell hammer"

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


local initialPitch = 1.0

---@param e attackEventData
local function onAttack(e)
	local ref = e.reference
	if ref ~= tes3.player then return end
	local equipped = tes3.mobilePlayer.readiedWeapon
	if not equipped then return end
	if string.lower(equipped.object.id) ~= hammerId then return end

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

	local swing = e.mobile.actionData.attackSwing
	local pitch = math.remap(swing, 0.0, 1.0,
		changePich(initialPitch, -config.semitones), changePich(initialPitch, config.semitones))
	local refHandle = tes3.makeSafeObjectHandle(hitReference)
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
