-- ------------------------------ Evening Star : favor sources --------------
-- everything that feeds ES.modifyFavor: sacred books, quest journals, kills,
-- favored spell casts, crime penalties, almsivi pilgrimage, passive regen and
-- idle decay. each source reads the deity record + current favor and calls
-- ES.modifyFavor; nothing here owns favor state.

local deityRecords = ES.DB.deities
local booksDb      = ES.DB.books.favorBooks
local spellsDb     = ES.DB.spells.favorSpells
local questsDb     = ES.DB.journals.favorJournals

-- ------------------------------ tunables ----------------------------------

local FAVOR_TOGGLE_PASSIVE_REGEN_RATE	= 0.1
local TOGGLE_FAVOR_DECAY_GRACE_HOURS	= 12
local TOGGLE_FAVOR_DECAY_RATE			= 0.5
local FAVOR_KILL_AWARD					= 1
local FAVOR_TABOO_PENALTY				= 10
local FAVOR_CRIME_PENALTY_RATIO			= 0.02 -- favor lost per gold of bounty added
local BOOK_READ_MIN_TIME				= 20
local FAVOR_LOCATION_EXPLORE_RATE		= 1.0  -- favor/game hour while exploring a favored cell type
local HOSTILE_FIGHT_THRESHOLD			= 80   -- fight ai-stat at/above this counts as hostile

-- ------------------------------ state -------------------------------------

-- book tracking
local currentBookId  = nil
local bookOpenedTime = nil

-- almsivi intervention teleport detection
local lastAICastTime        = -math.huge  -- real time of last AI Spellcast_Success
local AI_TELEPORT_WINDOW    = 3.0         -- seconds after cast to credit a teleport
local AI_TELEPORT_DISTANCE  = 256         -- max units from temple_marker to count

-- kill classification: creature type names -> engine enum
local creatureTypeByName = {
	creatures = types.Creature.TYPE.Creatures,
	daedra    = types.Creature.TYPE.Daedra,
	humanoid  = types.Creature.TYPE.Humanoid,
	undead    = types.Creature.TYPE.Undead,
}

-- transient combat trackers, rebuilt each session, cleared on cell change
local playerVictims      = {}  -- [actorId] = real time the player last damaged it
local playerAttackers    = {}  -- [actorId] = true once it has attacked the player
local PLAYER_KILL_WINDOW = 10  -- seconds; player damage this recent counts as the kill

-- ------------------------------ passive regen eligibility -----------------
-- any-of match across race / class / faction / equipped item ids

function ES.checkPassiveRegen(deity)
	if not deity or not deity.passiveRegen then return false end
	local r = deity.passiveRegen
	local rec = types.NPC.record(self)
	local race = (rec.race or ""):lower()
	local class = (rec.class or ""):lower()

	if r.races then
		for _, v in ipairs(r.races) do
			if race == v:lower() then return true end
		end
	end
	if r.classes then
		for _, v in ipairs(r.classes) do
			if class == v:lower() then return true end
		end
	end
	if r.factions then
		local factions = types.NPC.getFactions(self)
		for _, f in ipairs(factions) do
			local fl = f:lower()
			for _, v in ipairs(r.factions) do
				if fl == v:lower() then return true end
			end
		end
	end
	if r.equipment then
		local eq = types.Actor.getEquipment(self)
		for _, item in pairs(eq) do
			if item then
				local id = item.recordId:lower()
				for _, v in ipairs(r.equipment) do
					if id == v:lower() then return true end
				end
			end
		end
	end

	-- traveling with companions
	if r.companions and (saveData.countCompanions or 0) > 0 then return true end

	return false
end

-- ------------------------------ favor sources -----------------------------

-- book read for at least BOOK_READ_MIN_TIME seconds, once per book
function ES.onBookRead(bookId)
	if not ES.S.TOGGLE_ENABLED then return end
	if not ES.saveData.currentDeity then return end
	local entry = booksDb[bookId:lower()]
	if not entry or not ES.tableContains(entry.deity, ES.saveData.currentDeity) then return end

	ES.saveData.booksRead = ES.saveData.booksRead or {}
	if ES.saveData.booksRead[bookId:lower()] then return end
	ES.saveData.booksRead[bookId:lower()] = true
	ES.modifyFavor(entry.favor, "book:"..bookId)
	local deity = ES.getCurrentDeity()
	if deity then
--		messageBox(3, string.format("Reading this sacred text pleases %s. Your favor has increased.", deity.name))
	end
	ES.updateAbilities()
end

-- credits per quest, checked once per minute
function ES.scanJournals()
	if not ES.S.TOGGLE_ENABLED then return end
	if not ES.saveData.currentDeity then return end
	ES.saveData.journalsCredited = ES.saveData.journalsCredited or {}

	local quests = types.Player.quests(self)
	local current = ES.saveData.currentDeity

	for questId, entry in pairs(questsDb) do
		if ES.tableContains(entry.deity, current) and not ES.saveData.journalsCredited[questId] then
			local ok, q = pcall(function() return quests[questId] end)
			if ok and q and q.stage and q.stage >= entry.stage then
				ES.saveData.journalsCredited[questId] = true
				ES.modifyFavor(entry.favor, "journal:"..questId)
			end
		end
	end
	ES.updateAbilities()
end

-- counted hostile if authored to attack on sight, or it has attacked us
local function actorWasHostile(actor)
	if playerAttackers[actor.id] then return true end
	local ok, fight = pcall(function()
		return types.Actor.stats.ai.fight(actor).modified
	end)
	return ok and fight ~= nil and fight >= HOSTILE_FIGHT_THRESHOLD
end

-- player landed a damaging blow on this actor within the kill window
local function playerKilled(actor)
	local t = playerVictims[actor.id]
	return t ~= nil and (core.getRealTime() - t) <= PLAYER_KILL_WINDOW
end

-- victim is the actor that just died, doesn't filter by killer
function ES.onActorDied(actor)
	if not ES.S.TOGGLE_ENABLED then return end
	if not ES.saveData.currentDeity then return end
	if not actor or not actor:isValid() then return end
	local deity = ES.getCurrentDeity()
	if not deity then return end

	local recordId = (actor.recordId or ""):lower()

	-- npc: check race + faction taboos
	local victimRace, victimFactions = "", {}
	if types.NPC.objectIsInstance(actor) then
		local rec = types.NPC.record(actor)
		victimRace = (rec.race or ""):lower()
		victimFactions = types.NPC.getFactions(actor) or {}
	end

	-- taboo kills (recordId substring; covers ordinator etc.)
	if deity.tabooKills and deity.tabooKills.recordIdContains then
		for _, frag in ipairs(deity.tabooKills.recordIdContains) do
			if recordId:find(frag, 1, true) then
				ES.modifyFavor(-FAVOR_TABOO_PENALTY, "taboo:"..frag)
				messageBox(2, string.format("%s is displeased by this killing.", deity.name))
				ES.updateAbilities()
				return
			end
		end
	end

	-- taboo kills: race
	if deity.tabooKills and deity.tabooKills.races then
		for _, r in ipairs(deity.tabooKills.races) do
			if victimRace == r:lower() then
				ES.modifyFavor(-FAVOR_TABOO_PENALTY, "taboo_race:"..r)
				messageBox(2, string.format("%s is displeased by this killing.", deity.name))
				ES.updateAbilities()
				return
			end
		end
	end

	-- taboo kills: faction (any victim faction matches)
	if deity.tabooKills and deity.tabooKills.factions then
		for _, f in ipairs(deity.tabooKills.factions) do
			local fl = f:lower()
			for _, vf in ipairs(victimFactions) do
				if vf:lower() == fl then
					ES.modifyFavor(-FAVOR_TABOO_PENALTY, "taboo_faction:"..f)
					messageBox(2, string.format("%s is displeased by this killing.", deity.name))
					ES.updateAbilities()
					return
				end
			end
		end
	end

	-- favored kills: race
	if deity.favorKills and deity.favorKills.races then
		for _, r in ipairs(deity.favorKills.races) do
			if victimRace == r:lower() then
				ES.modifyFavor(FAVOR_KILL_AWARD, "kill_race:"..r)
				ES.updateAbilities()
				return
			end
		end
	end

	-- favored kills: faction (any victim faction matches)
	if deity.favorKills and deity.favorKills.factions then
		for _, f in ipairs(deity.favorKills.factions) do
			local fl = f:lower()
			for _, vf in ipairs(victimFactions) do
				if vf:lower() == fl then
					ES.modifyFavor(FAVOR_KILL_AWARD, "kill_faction:"..f)
					ES.updateAbilities()
					return
				end
			end
		end
	end

	-- favored kills: recordId substring (blighted creatures)
	if deity.favorKills and deity.favorKills.recordIdContains then
		for _, frag in ipairs(deity.favorKills.recordIdContains) do
			if recordId:find(frag, 1, true) then
				ES.modifyFavor(FAVOR_KILL_AWARD, "kill_id:"..frag)
				ES.updateAbilities()
				return
			end
		end
	end

	-- favored kills: explicit recordIds
	if deity.favorKills and deity.favorKills.recordIdSet
		and deity.favorKills.recordIdSet[recordId] then
		ES.modifyFavor(FAVOR_KILL_AWARD, "kill_set:"..recordId)
		ES.updateAbilities()
		return
	end

	-- favored kills: creature type (daedra), proximity-credited like the sets above
	if deity.favorKills and deity.favorKills.creatureTypes
		and types.Creature.objectIsInstance(actor) then
		local ctype = types.Creature.record(actor).type
		for _, name in ipairs(deity.favorKills.creatureTypes) do
			if creatureTypeByName[name:lower()] == ctype then
				ES.modifyFavor(FAVOR_KILL_AWARD, "kill_ctype:"..name)
				ES.updateAbilities()
				return
			end
		end
	end

	-- favored kills: hostile magic-specialization npcs (rogue mages)
	if deity.favorKills and deity.favorKills.hostileMageClasses
		and types.NPC.objectIsInstance(actor) then
		local classId = (types.NPC.record(actor).class or ""):lower()
		local class = classId ~= "" and types.NPC.classes.record(classId) or nil
		if class and tostring(class.specialization or ""):lower() == "magic"
			and actorWasHostile(actor) then
			ES.modifyFavor(FAVOR_KILL_AWARD, "kill_mage:"..classId)
			ES.updateAbilities()
			return
		end
	end

	-- senseless murder: a player-dealt kill of a non-hostile npc displeases the magus
	if deity.tabooKills and deity.tabooKills.senselessMurder
		and types.NPC.objectIsInstance(actor)
		and playerKilled(actor) and not actorWasHostile(actor) then
		ES.modifyFavor(-FAVOR_TABOO_PENALTY, "murder")
		messageBox(2, string.format("%s is displeased by this senseless killing.", deity.name))
		ES.updateAbilities()
	end
end

-- pantheons with crimePenalty=true (Tribunal Temple) lose favor proportional
-- to bounty increases. polled each sluggish frame. bounty decreases (paying
-- off) don't refund favor but do update lastBounty so future deltas track.
function ES.checkCrimePenalty()
	if not ES.S.TOGGLE_ENABLED then return end
	if not ES.saveData.currentDeity then return end
	local deity = ES.getCurrentDeity()
	if not deity or not deity.pantheon or not deity.pantheon.crimePenalty then return end

	local bounty = types.Player.getCrimeLevel(self) or 0
	local last   = ES.saveData.lastBounty or bounty
	if bounty > last then
		local delta   = bounty - last
		local penalty = delta * FAVOR_CRIME_PENALTY_RATIO
		ES.modifyFavor(-penalty, "crime:"..delta)
		messageBox(2, string.format("%s is displeased by your crimes.", deity.name))
		ES.updateAbilities()
	end
	ES.saveData.lastBounty = bounty
end

-- cell change shortly after an AI cast + a temple_marker static near the
-- player position = successful intervention to a temple. grants pilgrimage
-- favor on top of the per-cast +2.
function ES.checkAITeleportArrival(prevCell)
	if not ES.S.TOGGLE_ENABLED then return end
	if not ES.saveData.currentDeity then return end
	local deity = ES.getCurrentDeity()
	if not deity then return end
	-- must have cast almsivi intervention very recently
	if core.getRealTime() - lastAICastTime > AI_TELEPORT_WINDOW then return end

	-- delay one frame so nearby.statics reflects the new cell
	async:newUnsavableSimulationTimer(0.1, async:callback(function()
		local pos = self.position
		for _, obj in ipairs(nearby.statics or {}) do
			if obj.recordId:lower() == "templemarker" then
				if (obj.position - pos):length() < AI_TELEPORT_DISTANCE then
					-- credit only once per cast
					lastAICastTime = -math.huge
					ES.modifyFavor(1, "almsivi_to_temple")
					messageBox(3, string.format("%s welcomes you to this temple.", deity.name))
					ES.updateAbilities()
					return
				end
			end
		end
	end))
end

-- per game hour: passive regen if tenets are met, otherwise idle decay
function ES.perHourFavor()
	if not ES.S.TOGGLE_ENABLED then return end
	if not ES.saveData.currentDeity then return end
	local deity = ES.getCurrentDeity()
	if not deity then return end

	-- exploring a favored cell type (dwemer ruins) trickles favor regardless of tenet match
	if deity.favorCells and G_cellInfo then
		for flag in pairs(deity.favorCells) do
			if G_cellInfo[flag] then
				ES.modifyFavor(FAVOR_LOCATION_EXPLORE_RATE, "explore:"..flag)
				break
			end
		end
	end

	local now = core.getGameTime()
	if ES.checkPassiveRegen(deity) and ES.S.TOGGLE_PASSIVE_REGEN then
		ES.modifyFavor(FAVOR_TOGGLE_PASSIVE_REGEN_RATE, "passive")
	elseif ES.S.TOGGLE_FAVOR_DECAY then
		local last = ES.saveData.lastFavorGain or now
		local hoursIdle = (now - last) / 3600
		if hoursIdle > TOGGLE_FAVOR_DECAY_GRACE_HOURS then
			ES.modifyFavor(-TOGGLE_FAVOR_DECAY_RATE, "decay")
		end
	end
	ES.updateAbilities()
end

-- ------------------------------ handlers ----------------------------------

-- award favor for casting favored spells; track almsivi casts for the
-- temple_marker teleport detection. gift 3 cost is handled per-deity in
-- gifts_p (some defer payment until their effect actually lands).
I.SkillProgression.addSkillUsedHandler(function(skillId, params)
	if not ES.S.TOGGLE_ENABLED then return end
	if not ES.saveData.currentDeity then return end
	if params.useType ~= I.SkillProgression.SKILL_USE_TYPES.Spellcast_Success then return end

	local selected = types.Actor.getSelectedSpell(self)
	if not selected then return end
	local spellId = selected.id:lower()
	local deity = ES.getCurrentDeity()
	if not deity then return end

	-- track almsivi intervention casts for temple_marker teleport detection
	if spellId == "almsivi intervention" then
		lastAICastTime = core.getRealTime()
	end

	-- favored spells (deity may be a single id or a list)
	local entry = spellsDb[spellId]
	if entry and ES.tableContains(entry.deity, ES.saveData.currentDeity) then
		ES.modifyFavor(entry.favor, "spell:"..spellId)
		ES.updateAbilities()
	end
end)

-- if another plugin already registered SunsDusk_actorDied, this overwrites.
-- watch out: Sun's Dusk uses a single-handler-per-event pattern.
G_eventHandlers.SunsDusk_actorDied = function(actor)
	ES.onActorDied(actor)
	ES.updateAbilities()
end

-- book read tracker: real time, since the book ui pauses sim time. credits
-- favor once the book has been open at least BOOK_READ_MIN_TIME seconds.
table.insert(G_UiModeChangedJobs, function(data)
	if not ES.S.TOGGLE_ENABLED then return end
	if data.newMode == "Book" or data.newMode == "Scroll" then
		if data.arg and data.arg.recordId then
			currentBookId = data.arg.recordId:lower()
			bookOpenedTime = core.getRealTime()
		end
	elseif currentBookId and bookOpenedTime then
		local readSec = core.getRealTime() - bookOpenedTime
		if readSec >= BOOK_READ_MIN_TIME then
			ES.onBookRead(currentBookId)
		end
		currentBookId = nil
		bookOpenedTime = nil
	end
end)

table.insert(G_cellChangedJobs, ES.checkAITeleportArrival)
table.insert(G_perHourJobs, ES.perHourFavor)
table.insert(G_perMinuteJobs, ES.scanJournals)
G_onFrameJobsSluggish.es_checkCrimePenalty = ES.checkCrimePenalty

-- ------------------------------ combat trackers ---------------------------
-- feed kill attribution (player-dealt damage) and hostility (incoming attacks)

-- incoming-hit handler registered on active, when I.Combat is reliably bound
local combatHandlerRegistered = false
table.insert(G_onActiveJobs, function()
	if combatHandlerRegistered or not I.Combat then return end
	combatHandlerRegistered = true
	I.Combat.addOnHitHandler(function(attack)
		local atk = attack and attack.attacker
		if atk and atk:isValid() and types.Actor.objectIsInstance(atk)
			and not types.Player.objectIsInstance(atk) then
			playerAttackers[atk.id] = true
		end
	end)
end)

table.insert(G_landedHitJobs, function(target)
	if target and target:isValid() then playerVictims[target.id] = core.getRealTime() end
end)
table.insert(G_landedSpellHitJobs, function(target)
	if target and target:isValid() then playerVictims[target.id] = core.getRealTime() end
end)

-- trackers are per-encounter; clear on cell change to bound memory
table.insert(G_cellChangedJobs, function()
	playerVictims = {}
	playerAttackers = {}
end)
