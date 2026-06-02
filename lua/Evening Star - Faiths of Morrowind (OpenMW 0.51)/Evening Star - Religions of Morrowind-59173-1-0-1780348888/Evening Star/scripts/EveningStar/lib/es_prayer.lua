-- ------------------------------ Evening Star : prayer + shrine ------------
-- worship at a shrine: a shrine's mwscript opens a blessing menu on activation
-- (which the player can cancel), so after es_g relays the activation we poll
-- active spells every frame until a known blessing actually lands -- then play
-- the kneel pose and grant the larger prayer favor (+ the per-shrine gift_3
-- dispatch). the pray-power cast grants a smaller favor and its own standing
-- pose. both share one diminishing-returns streak.

local deityRecords = ES.DB.deities
local blessSpells  = ES.DB.shrines.blessSpells

local esFavorBar = require('scripts.EveningStar.lib.es_favor_bar')

-- ------------------------------ tunables ----------------------------------

local FAVOR_PRAYER_GAIN				= 5 -- shrine worship base gain (the larger one)
local FAVOR_PRAY_POWER_GAIN			= 3 -- pray-power base gain (less than a shrine)
local FAVOR_PRAYER_LOCATION_MULT	= 1.5
local FAVOR_PRAYER_DIMINISH_WINDOW	= 24  -- game hours of idle resets streak to 0
local FAVOR_PRAYER_DIMINISH_BASE	= 0.5 -- multiplier per repeat (halves each time)
local PRAYER_BAR_LINGER_TIME		= 3.0
local PRAY_POWER_ANIM				= "prayer1"

-- shrine kneel-and-pray pose (bundled prayer animation)
local PRAYER_ANIM_GROUP				= "prayer2"
local PRAYER_ANIM_DELAY				= 0.4 -- let the weapon sheathe before kneeling
local PRAYER_ANIM_HOLD				= 5.0 -- seconds to hold the kneel
local PRAYER_ANIM_RISE				= 1.3 -- closing "rise to feet" segment

-- ------------------------------ state -------------------------------------

local prayerAnimActive = false
local prayerAnimToken  = 0
local savedStance      = nil
local seenBlessings    = nil  -- primed with the load-time active state on first poll

-- pray power spell ids, for swapping the spellcast pose to the pray pose
local prayPowerIds = {}
for _, deity in pairs(deityRecords) do
	if not deity.stub then
		prayPowerIds["es_pray_"..deity.pantheonId.."_"..deity.id] = true
	end
end

-- ------------------------------ pray power animation ----------------------

function ES.playPrayPowerAnim()
	I.AnimationController.playBlendedAnimation(PRAY_POWER_ANIM, {
		startKey = "start",
		stopKey = "stop",
		priority = {
			[animation.BONE_GROUP.RightArm] = animation.PRIORITY.Scripted,
			[animation.BONE_GROUP.LeftArm] = animation.PRIORITY.Scripted,
			[animation.BONE_GROUP.Torso] = animation.PRIORITY.Scripted,
			[animation.BONE_GROUP.LowerBody] = animation.PRIORITY.Scripted,
		},
		blendMask = animation.BLEND_MASK.All,
		autoDisable = true,
		speed = 1,
	})

	-- lock the player for 1s while the pose plays, then restore and stop it
	types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Controls, false)
	types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, false)
	types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic, false)
	async:newUnsavableSimulationTimer(2, async:callback(function()
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Controls, true)
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, true)
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic, true)
		animation.cancel(self, PRAY_POWER_ANIM)
	end))
end

-- ------------------------------ shrine kneel pose -------------------------
-- the full kneel-and-pray played when worshipping at a shrine. technique
-- mirrors "Praying Animated": sheathe the weapon, override movement + combat
-- controls, then play the looped pose at scripted priority. the per-frame
-- hold (in the frame job below) re-forces stance + zeroes movement so the
-- character controller can't break the pose. stops looping for a clean rise.

local function endPrayerAnim()
	if not prayerAnimActive then return end
	prayerAnimActive = false
	if animation.isPlaying(self, PRAYER_ANIM_GROUP) then
		animation.cancel(self, PRAYER_ANIM_GROUP)
	end
	I.Controls.overrideMovementControls(false)
	I.Controls.overrideCombatControls(false)
	if savedStance and types.Actor.getStance(self.object) == types.Actor.STANCE.Nothing then
		types.Actor.setStance(self, savedStance)
	end
	savedStance = nil
end

function ES.playPrayerAnim()
	if prayerAnimActive then return end
	if not animation.hasGroup(self, PRAYER_ANIM_GROUP) then return end
	prayerAnimActive = true
	prayerAnimToken = prayerAnimToken + 1
	local myToken = prayerAnimToken

	-- sheathe any drawn weapon/spell so the full-body kneel can play
	local stance = types.Actor.getStance(self.object)
	if stance ~= types.Actor.STANCE.Nothing then
		savedStance = stance
		types.Actor.setStance(self, types.Actor.STANCE.Nothing)
	end

	I.Controls.overrideMovementControls(true)
	I.Controls.overrideCombatControls(true)

	-- small delay lets the sheathe settle, then play the looping kneel
	async:newUnsavableSimulationTimer(PRAYER_ANIM_DELAY, async:callback(function()
		if myToken ~= prayerAnimToken then return end
		I.AnimationController.playBlendedAnimation(PRAYER_ANIM_GROUP, {
			startKey = "start",
			stopKey = "stop",
			loops = 100000,
			speed = 0.8,
			priority = {
				[animation.BONE_GROUP.RightArm] = animation.PRIORITY.Scripted,
				[animation.BONE_GROUP.LeftArm] = animation.PRIORITY.Scripted,
				[animation.BONE_GROUP.Torso] = animation.PRIORITY.Scripted,
				[animation.BONE_GROUP.LowerBody] = animation.PRIORITY.Scripted,
			},
			autoDisable = true,
			blendMask = animation.BLEND_MASK.All,
		})
		-- hold, then stop looping so the closing rise plays out before finishing
		async:newUnsavableSimulationTimer(PRAYER_ANIM_HOLD, async:callback(function()
			if myToken ~= prayerAnimToken then return end
			if animation.isPlaying(self, PRAYER_ANIM_GROUP) then
				animation.setLoopingEnabled(self, PRAYER_ANIM_GROUP, false)
			end
			async:newUnsavableSimulationTimer(PRAYER_ANIM_RISE, async:callback(function()
				if myToken ~= prayerAnimToken then return end
				endPrayerAnim()
			end))
		end))
	end))
end

-- ------------------------------ shrine blessing poll ----------------------
-- worship = receiving a shrine blessing. a shrine's mwscript opens a blessing
-- menu the player can cancel, and the granted blessing is only briefly active,
-- so we poll active spells every frame and fire on the 0->1 transition:
-- uninitiated get the deity choice, worshippers of a deity the shrine honors
-- get a prayer. the baseline is primed on the first poll so a blessing already
-- active at load doesn't fire.

function ES.pollShrineBlessings()
	if not ES.S.TOGGLE_ENABLED then return end
	local active = types.Actor.activeSpells(self)
	if not seenBlessings then
		seenBlessings = {}
		for spellId in pairs(blessSpells) do
			seenBlessings[spellId] = active:isSpellActive(spellId)
		end
		return
	end
	for spellId, entry in pairs(blessSpells) do
		local isActive = active:isSpellActive(spellId)
		if isActive and not seenBlessings[spellId] then
			-- newly received blessing
			seenBlessings[spellId] = true
			if not ES.saveData.currentDeity then
				if ES.S.TOGGLE_DEITY_SHRINE_MENU then ES.openDeityChoice(entry.deity) end
			elseif ES.tableContains(entry.deity, ES.saveData.currentDeity) then
				ES.grantShrinePrayer(ES.saveData.currentDeity)
			elseif ES.S.TOGGLE_DEITY_SHRINE_MENU then
				-- another deity's blessing: offer to switch to them
				ES.openDeityChoice(entry.deity)
			end
		elseif not isActive then
			seenBlessings[spellId] = false
		end
	end
end

-- ------------------------------ prayer favor ------------------------------
-- shared favor award for any prayer (shrine worship or pray power). applies
-- the sacred-location bonus and the diminishing-returns streak so prayer can't
-- be spammed; the streak is shared across both prayer sources.

function ES.applyPrayerFavor(deity, baseGain)
	esFavorBar.beginPraying(deity, ES.saveData.favor or 0)

	local gain = baseGain
	-- sacred location bonus
	local cellName = self.cell and self.cell.name and self.cell.name:lower() or ""
	if deity.favorLocations and deity.favorLocations[cellName] then
		gain = gain * FAVOR_PRAYER_LOCATION_MULT
		messageBox(3, "Your prayer is strengthened by this sacred place.")
	end

	-- diminishing returns: streak resets after window of idle, otherwise stacks
	local now       = core.getGameTime()
	local lastTime  = ES.saveData.lastShrinePrayerTime or -math.huge
	local idleHours = (now - lastTime) / 3600
	local streak    = idleHours >= FAVOR_PRAYER_DIMINISH_WINDOW
		and 0
		or (ES.saveData.shrinePrayerStreak or 0)
	gain = math.max(1, math.floor((gain * (FAVOR_PRAYER_DIMINISH_BASE ^ streak)) + 0.5))

	if streak == 0 then messageBox(3, string.format("Your favor has increased to %.2f%%.", math.min(ES.C.FAVOR_MAX, (ES.saveData.favor or 0) + gain))) end
	messageBox(2, string.format("+%.2f%%", gain))
	ES.modifyFavor(gain, "prayer")
	ES.saveData.shrinePrayerStreak   = streak + 1
	ES.saveData.lastShrinePrayerTime = now

	esFavorBar.markCompleted(gain, PRAYER_BAR_LINGER_TIME)
	ES.updateAbilities()
end

-- worship grant, fired when the player receives a shrine blessing for their
-- deity: play the kneel, award the larger shrine favor, dispatch the gift.

function ES.grantShrinePrayer(deityId)
	local shrineDeity = deityId and deityRecords[deityId] or nil
	if not shrineDeity or shrineDeity.stub then return end

	ES.playPrayerAnim()
	ES.applyPrayerFavor(shrineDeity, FAVOR_PRAYER_GAIN)

	-- gift 3 hook: dispatch the deity's gift_3 effect at devotee tier. both
	-- gifts spawn an orb *behind* the player at the shrine (so the shrine
	-- isn't in the way); the pray-power path (in gifts_p) spawns in front.
	local cur = ES.getCurrentDeity()
	if cur and ES.getDevotionLevel(ES.saveData.favor or 0) == "devotee" then
		if cur.gift_3 == "poets_charm" then
			local yaw = self.rotation:getYaw()
			local dir = util.vector3(math.sin(yaw), math.cos(yaw), 0):normalize()
			local pos = self.position - dir * 120 + util.vector3(0, 0, 30)
			core.sendGlobalEvent("EveningStar_poetsCharmSpawn", {
				position = pos,
				caster   = self.object,
			})
		elseif cur.gift_3 == "sothas_reflection" and ES.spawnReflectionOrb then
			ES.spawnReflectionOrb(false) -- shrine: spawn behind
		end
	end
end

-- ------------------------------ handlers ----------------------------------

-- replace the default spellcast pose with the pray pose on a pray cast.
-- returning false only skips other handlers, not the engine's own play, so we
-- play the pose (scripted priority wins) and cancel the spellcast group next
-- frame -- handlers run before playBlended, so there is nothing to cancel yet.
I.AnimationController.addPlayBlendedAnimationHandler(function(groupname, options)
	if not ES.S.TOGGLE_ENABLED then return end
	if groupname ~= "spellcast" or options.startKey ~= "self start" then return end
	local selected = types.Actor.getSelectedSpell(self)
	if not selected or not prayPowerIds[selected.id:lower()] then return end
	-- confirmed pray cast
	ES.playPrayPowerAnim()
	-- change local PRAY_POWER_ANIM = "vasitting2" and enable this for cool glitches: (also change control switch timer to 5)
	-- async:newUnsavableSimulationTimer(0.4, async:callback(function()
	-- 	animation.cancel(self, "spellcast")
	-- end))
	local deity = ES.getCurrentDeity()
	local timeOut = core.getSimulationTime() + 3
	if not deity then return end
	G_onFrameJobs.waitForPrayerFinished = function(dt)
		if typesActorActiveSpellsSelf:isSpellActive("es_pray_"..deity.pantheonId.."_"..deity.id) then
			ES.applyPrayerFavor(deity, FAVOR_PRAY_POWER_GAIN)
			ES.onPrayed()
			G_onFrameJobs.waitForPrayerFinished = nil
		elseif core.getSimulationTime() > timeOut then
			G_onFrameJobs.waitForPrayerFinished = nil
		end
	end
end)

-- per-frame: watch for shrine blessings, hold the kneel pose (re-force stance +
-- zero movement so the character controller can't break it), tick the favor bar
table.insert(G_onFrameJobs, function(dt)
	ES.pollShrineBlessings()
	if prayerAnimActive then
		if types.Actor.getStance(self.object) ~= types.Actor.STANCE.Nothing then
			types.Actor.setStance(self, types.Actor.STANCE.Nothing)
		end
		self.controls.movement     = 0
		self.controls.sideMovement = 0
		self.controls.run          = false
		self.controls.jump         = false
	end
	esFavorBar.update()
end)