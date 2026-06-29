-- ------------------------------ Evening Star : prayer + shrine ------------
-- shrine blessing, pray-power, and world-interaction prayer.
-- blessing + power share a diminishing streak; world prayer has its own once-a-day cooldown.

local deityRecords = ES.DB.deities
local shrineDb     = ES.DB.shrines.shrineIds
local blessSpells  = ES.DB.shrines.blessSpells

local esFavorBar = require('scripts.EveningStar.lib.es_favor_bar')

-- ------------------------------ tunables ----------------------------------

local FAVOR_PRAYER_GAIN             = 5
local FAVOR_PRAY_POWER_GAIN         = 3
local FAVOR_PRAYER_LOCATION_MULT    = 1.5
local FAVOR_PRAYER_DIMINISH_WINDOW  = 24  -- idle game-hours that reset the streak
local FAVOR_PRAYER_DIMINISH_BASE    = 0.5
local FAVOR_WORLD_PRAYER_FULL_HOURS = 24
local PRAYER_BAR_LINGER_TIME        = 3.0
local PRAY_POWER_ANIM               = "prayer1"

-- shrine kneel pose tunables
local PRAYER_ANIM_GROUP             = "prayer2"
local PRAYER_ANIM_DELAY             = 0.4
local PRAYER_ANIM_HOLD              = 5.0
local PRAYER_ANIM_RISE              = 1.3

-- ------------------------------ state -------------------------------------

local prayerAnimActive = false
local prayerAnimToken  = 0
local savedStance      = nil
local seenBlessings    = nil

-- shrine blessing poll, armed by es_g's relay
local shrinePollActive = false
local shrinePollOrigin = nil
local SHRINE_POLL_MOVE_LIMIT = 1

local prayPowerToDeity = {}
for _, deity in pairs(deityRecords) do
	if not deity.stub then
		prayPowerToDeity["es_pray_"..deity.pantheonId.."_"..deity.id] = deity.id
	end
end

-- ------------------------------ shrine lookup -----------------------------

function ES.isShrineRecord(recordId)
	if not recordId then return nil end
	local entry = shrineDb[recordId:lower()]
	return entry and entry.deity or nil
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
	
	-- lock the player while the pose plays, then restore and stop it
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
-- looped kneel at scripted priority;
-- the frame job re-forces stance so the controller can't break it, then stops looping for a clean rise.

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
-- after es_g relays an activation, poll active spells and fire on a newly seen blessing.
-- baseline primed at activation so a pre-existing one won't re-fire.

G_eventHandlers.EveningStar_shrineActivated = function(shrine)
	shrinePollActive = true
	shrinePollOrigin = self.position
	seenBlessings = nil
end

function ES.pollShrineBlessings()
	if not ES.S.TOGGLE_ENABLED or not shrinePollActive then return end
	if shrinePollOrigin and (self.position - shrinePollOrigin):length() > SHRINE_POLL_MOVE_LIMIT then
		shrinePollActive = false
		return
	end
	-- key on activeSpellId so re-praying re-fires while a prior blessing still runs
	local activeNow = {}
	for _, params in pairs(types.Actor.activeSpells(self)) do
		local entry = blessSpells[params.id]
		if entry then
			activeNow[params.activeSpellId] = entry
		end
	end
	if not seenBlessings then
		seenBlessings = activeNow
		return
	end
	for activeId, entry in pairs(activeNow) do
		if not seenBlessings[activeId] then
			-- newly received blessing: pray each honored deity, else offer to adopt
			if not ES.grantShrinePrayer(entry.deity, "shrine") and ES.S.TOGGLE_DEITY_SHRINE_MENU then
				ES.openDeityChoice(entry.deity)
			end
		end
	end
	seenBlessings = activeNow
end

-- ------------------------------ prayer favor ------------------------------
-- favor for any prayer, scaled by route mult + location.
-- world interaction has its own cooldown; shrine + power share the diminishing streak.

function ES.applyPrayerFavor(deity, baseGain, source)
	local st = ES.saveData.deities[deity.id]
	if not st then return end
	esFavorBar.beginPraying(deity, st.favor or 0)
	
	local now = core.getGameTime()
	
	local locationMult = 1
	local cellName = self.cell and self.cell.name and self.cell.name:lower() or ""
	if deity.favorLocations and deity.favorLocations[cellName] then
		locationMult = FAVOR_PRAYER_LOCATION_MULT
		messageBox(3, "Your prayer is strengthened by this sacred place.")
	end
	
	-- world-interaction favor: once-a-day, scales with idle hours (full at 24h)
	local function worldPrayerGain()
		local idleHours = (now - (st.lastWorldInteraction or -math.huge)) / 3600
		local mult = math.min(1, idleHours / FAVOR_WORLD_PRAYER_FULL_HOURS)
		st.lastWorldInteraction = now
		return baseGain * ES.S.FAVOR_PRAYER_WORLD_MULT * ES.S.FAVOR_GAIN_MULT * locationMult * mult / 2, mult >= 1
	end
	
	local gain, showSummary
	if source == "worldInteraction" then
		gain, showSummary = worldPrayerGain()
	else
		-- shrine / power diminishing streak: resets after an idle window
		local routeMult = (source == "power") and ES.S.FAVOR_PRAYER_POWER_MULT or ES.S.FAVOR_PRAYER_SHRINE_MULT
		local idleHours = (now - (st.lastShrinePrayerTime or -math.huge)) / 3600
		local streak = idleHours >= FAVOR_PRAYER_DIMINISH_WINDOW and 0 or (st.shrinePrayerStreak or 0)
		gain = math.max(0.5, baseGain * routeMult * ES.S.FAVOR_GAIN_MULT * locationMult * (FAVOR_PRAYER_DIMINISH_BASE ^ streak))
		st.shrinePrayerStreak   = streak + 1
		st.lastShrinePrayerTime = now
		showSummary = streak == 0
		
		-- buying a blessing = half shrine favor + the day's world favor,
		-- so a full charge buy matches a plain buff-buy while spending the world prayer
		if source == "shrine" and ES.S.SHRINE_WORLD_INTERACTION then
			local worldGain, worldFull = worldPrayerGain()
			gain = gain / 2 + worldGain
			showSummary = showSummary or worldFull
		end
	end
	
	--if showSummary then messageBox(3, string.format("Your favor with %s has increased to %.2f%%.", deity.name, math.min(ES.C.FAVOR_MAX, (st.favor or 0) + gain))) end
	messageBox(2, string.format("%s: +%.2f%%", deity.name, gain))
	ES.modifyFavor(deity.id, gain, "prayer")
	
	esFavorBar.markCompleted(deity, gain, PRAYER_BAR_LINGER_TIME)
	ES.updateAbilities()
end

-- worship grant: each honored deity gets the prayer, kneel, and devotee gift
function ES.grantShrinePrayer(shrineDeitySpec, source)
	local prayed = {}
	for _, deityId in ipairs(ES.saveData.activeDeities) do
		if ES.tableContains(shrineDeitySpec, deityId) then
			local deity = ES.getDeity(deityId)
			if deity then prayed[#prayed + 1] = deity end
		end
	end
	if #prayed == 0 then return false end
	
	ES.playPrayerAnim()
	for _, deity in ipairs(prayed) do
		ES.applyPrayerFavor(deity, FAVOR_PRAYER_GAIN, source)
	end
	-- gift 3 orbs at devotee tier; spawn behind the player at a shrine, fanned so they don't clip
	if ES.spawnDevoteeOrbs then ES.spawnDevoteeOrbs(prayed, false) end
	return true
end

-- ------------------------------ classic activate-to-pray ------------------

if G_worldInteractions then
	G_worldInteractions.es_shrine = {
		canInteract = function(object)
			if not ES.S.TOGGLE_ENABLED then return false end
			if not ES.S.SHRINE_WORLD_INTERACTION and not ES.S.SHRINE_WORLD_INTERACTION_CHANGE then return false end
			local shrineDeity = ES.isShrineRecord(object.recordId)
			if not shrineDeity then return false end
			if ES.S.SHRINE_WORLD_INTERACTION_CHANGE then return true end
			if #ES.saveData.activeDeities == 0 then return true end
			for _, deityId in ipairs(ES.saveData.activeDeities) do
				if ES.tableContains(shrineDeity, deityId) then return true end
			end
			return false
		end,
		getActions = function(object)
			local actions = {}
			-- pray action (ready weapon)
			if ES.S.SHRINE_WORLD_INTERACTION then
				local hasDeity = #ES.saveData.activeDeities > 0
				actions[#actions + 1] = {
					label = hasDeity and "Pray" or "Worship",
					preferred = "ToggleWeapon",
					handler = function(obj)
						local shrineDeity = ES.isShrineRecord(obj.recordId)
						if not shrineDeity then return end
						if not ES.grantShrinePrayer(shrineDeity, "worldInteraction") and ES.S.TOGGLE_DEITY_SHRINE_MENU then
							-- multi-deity (generic almsivi) shrine opens the selector
							if type(shrineDeity) == "table" then shrineDeity = nil end
							ES.openDeityChoice(shrineDeity)
						end
					end,
				}
			end
			-- deity-selection action (ready magic)
			if ES.S.SHRINE_WORLD_INTERACTION_CHANGE then
				actions[#actions + 1] = {
					label = "Choose Deity",
					preferred = "ToggleSpell",
					handler = function()
						ES.openDeityChoice()
					end,
				}
			end
			return actions
		end,
	}
end

-- ------------------------------ handlers ----------------------------------

-- swap the spellcast pose for the pray pose on a pray cast (scripted priority wins)
I.AnimationController.addPlayBlendedAnimationHandler(function(groupname, options)
	if not ES.S.TOGGLE_ENABLED or ES.S.PRAYER_POWER == "No Power" then return end
	if groupname ~= "spellcast" or options.startKey ~= "self start" then return end
	local selected = types.Actor.getSelectedSpell(self)
	if not selected then return end
	local selectedId = selected.id:lower()
	local allPower = selectedId == "es_pray_all"
	local deity = not allPower and ES.getDeity(prayPowerToDeity[selectedId])
	if not allPower and not deity then return end
	-- confirmed pray cast
	ES.playPrayPowerAnim()
	-- change local PRAY_POWER_ANIM = "vasitting2" and enable this for cool glitches: (also change control switch timer to 5)
	-- async:newUnsavableSimulationTimer(0.4, async:callback(function()
	-- 	animation.cancel(self, "spellcast")
	-- end))
	-- all-deity power keys on its own spell; per-deity keys on the deity's spell
	local praySpell = allPower and "es_pray_all" or "es_pray_"..deity.pantheonId.."_"..deity.id
	local timeOut = core.getSimulationTime() + 3
	G_onFrameJobs.waitForPrayerFinished = function(dt)
		if typesActorActiveSpellsSelf:isSpellActive(praySpell) then
			if allPower then
				local prayed = {}
				for _, deityId in ipairs(ES.saveData.activeDeities) do
					local d = ES.getDeity(deityId)
					if d then
						ES.applyPrayerFavor(d, FAVOR_PRAY_POWER_GAIN, "power")
						prayed[#prayed + 1] = d
					end
				end
				ES.spawnDevoteeOrbs(prayed, true)
			else
				ES.applyPrayerFavor(deity, FAVOR_PRAY_POWER_GAIN, "power")
				ES.onPrayed(deity)
			end
			G_onFrameJobs.waitForPrayerFinished = nil
		elseif core.getSimulationTime() > timeOut then
			G_onFrameJobs.waitForPrayerFinished = nil
		end
	end
end)

-- per-frame: poll blessings, hold the kneel pose, tick the favor bar
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