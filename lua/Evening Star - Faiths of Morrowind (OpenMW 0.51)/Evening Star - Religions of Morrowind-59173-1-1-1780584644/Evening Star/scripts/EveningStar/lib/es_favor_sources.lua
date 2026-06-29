-- ------------------------------ Evening Star : favor sources --------------
-- everything that feeds ES.modifyFavor: books, journals, kills, favored casts, crime, almsivi pilgrimage, passive regen, idle decay.
-- nothing here owns favor state.

local deityRecords = ES.DB.deities
local booksDb      = ES.DB.books.favorBooks
local spellsDb     = ES.DB.spells.favorSpells
local questsDb     = ES.DB.journals.favorJournals

-- ------------------------------ tunables ----------------------------------

-- base rates; the difficulty preset scales these via ES.S.*_MULT
local FAVOR_TOGGLE_PASSIVE_REGEN_RATE   = 0.1
local TOGGLE_FAVOR_DECAY_RATE           = 0.5
local FAVOR_KILL_AWARD                  = 1
local FAVOR_TABOO_PENALTY               = 10
local FAVOR_CRIME_PENALTY_RATIO         = 0.02 -- favor lost per gold of bounty added
local BOOK_READ_MIN_TIME                = 20
local FAVOR_LOCATION_EXPLORE_RATE       = 1.0  -- favor/hour in a fresh favored cell
local FAVOR_LOCATION_EXPLORE_FLOOR      = 0.1  -- favor/hour once fully explored
local EXPLORE_MIDPOINT_MINUTES          = 150  -- minutes in-cell where the rate is halfway to the floor
local EXPLORE_STEEPNESS                 = 0.03 -- logistic falloff steepness

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

-- transient player-damage tracker, rebuilt each session, cleared on cell change
local playerVictims      = {}  -- [actorId] = real time the player last damaged it
local PLAYER_KILL_WINDOW = 10  -- seconds; player damage this recent counts as the kill

-- ------------------------------ passive regen eligibility -----------------
-- any-of match across race / class / faction / equipped item ids

function ES.checkPassiveRegen(deity)
	if not deity or not deity.passiveRegen then return false end
	local regen = deity.passiveRegen
	local rec = types.NPC.record(self)
	local race = (rec.race or ""):lower()
	local class = (rec.class or ""):lower()
	
	if regen.races then
		for _, v in ipairs(regen.races) do
			if race == v:lower() then return true end
		end
	end
	if regen.classes then
		for _, v in ipairs(regen.classes) do
			if class == v:lower() then return true end
		end
	end
	if regen.factions then
		local factions = types.NPC.getFactions(self)
		for _, f in ipairs(factions) do
			local fl = f:lower()
			for _, v in ipairs(regen.factions) do
				if fl == v:lower() then return true end
			end
		end
	end
	if regen.equipment then
		local eq = types.Actor.getEquipment(self)
		for _, item in pairs(eq) do
			if item then
				local id = item.recordId:lower()
				for _, v in ipairs(regen.equipment) do
					if id == v:lower() then return true end
				end
			end
		end
	end
	
	-- traveling with companions
	if regen.companions and (saveData.countCompanions or 0) > 0 then return true end
	
	return false
end

-- ------------------------------ favor sources -----------------------------

-- book read for at least BOOK_READ_MIN_TIME seconds, once per book per deity
function ES.onBookRead(bookId)
	if not ES.S.TOGGLE_ENABLED then return end
	local entry = booksDb[bookId:lower()]
	if not entry then return end
	local key = bookId:lower()
	
	local credited = false
	for _, deityId in ipairs(ES.saveData.activeDeities) do
		if ES.tableContains(entry.deity, deityId) then
			local st = ES.saveData.deities[deityId]
			st.booksRead = st.booksRead or {}
			if not st.booksRead[key] then
				st.booksRead[key] = true
				ES.modifyFavor(deityId, entry.favor * ES.S.FAVOR_BOOK_MULT * ES.S.FAVOR_GAIN_MULT, "book:"..bookId)
				credited = true
			end
		end
	end
	if credited then ES.updateAbilities() end
end

-- es_quest_watcher relays onQuestUpdate here (sun's dusk has no quest-update job);
-- journalsCredited keeps each quest/stage one-shot.
G_eventHandlers.EveningStar_questUpdate = function(data)
	if not ES.S.TOGGLE_ENABLED or not data.quest or not data.stage then return end
	local questId = data.quest:lower()
	local entry = questsDb[questId]
	if not entry then return end
	
	local stages = entry.stage
	if type(stages) ~= "table" then stages = { stages } end
	
	local credited = false
	for _, deityId in ipairs(ES.saveData.activeDeities) do
		if ES.tableContains(entry.deity, deityId) then
			local st = ES.saveData.deities[deityId]
			st.journalsCredited = st.journalsCredited or {}
			for _, stage in ipairs(stages) do
				-- single stage keeps the bare-questId key for save compat
				local creditKey = (#stages > 1) and questId..":"..stage or questId
				if data.stage == stage and not st.journalsCredited[creditKey] then
					st.journalsCredited[creditKey] = true
					ES.modifyFavor(deityId, entry.favor * ES.S.FAVOR_JOURNAL_MULT * ES.S.FAVOR_GAIN_MULT, "journal:"..questId)
					log(2, "completed "..data.quest.."("..(data.stage or "?").."), +"..entry.favor.." "..deityId)
					credited = true
				end
			end
		end
	end
	if credited then ES.updateAbilities() end
end

-- engine isAggressive trigger (fight + distance bias >= 100), but on authored base fight and minus
-- the disposition bias, since theft/assault inflate .modified and lower disposition.
local fightDistanceBias = core.getGMST("iFightDistanceBase") - core.getGMST("fFightDistanceMultiplier") * 500

local function actorWasHostile(actor)
	local authored = ES.saveData.authoredFight[getId(actor)]
	if authored == nil then
		authored = types.Actor.stats.ai.fight(actor).base or 0
	end
	return authored + fightDistanceBias >= 100
end

-- cache each npc's authored fight the first time we see it, before theft/assault can inflate it
local function snapshotAuthoredFight()
	local authored = ES.saveData and ES.saveData.authoredFight
	if not authored then return end
	for _, actor in ipairs(nearby.actors) do
		if actor:isValid() and types.NPC.objectIsInstance(actor)
			and not types.Player.objectIsInstance(actor) then
			local key = getId(actor)
			if authored[key] == nil then
				authored[key] = types.Actor.stats.ai.fight(actor).base
			end
		end
	end
end

-- ------------------------------ displeasure messaging ---------------------
-- one consolidated box when a single event offends several deities at once,
-- instead of one identical box per active deity.

local function displeasureLine(names, suffix)
	local n = #names
	local subject
	if n == 1 then
		subject = names[1]
	elseif n == 2 then
		subject = names[1].." and "..names[2]
	else
		subject = table.concat(names, ", ", 1, n - 1)..", and "..names[n]
	end
	return string.format("%s %s displeased %s.", subject, n > 1 and "are" or "is", suffix)
end

-- victim is the actor that just died, doesn't filter by killer.
-- each active deity is classified independently (one kill can please one, offend another).
function ES.onActorDied(actor)
	if not ES.S.TOGGLE_ENABLED then return end
	if not actor or not actor:isValid() then return end
	local active = ES.saveData.activeDeities
	if #active == 0 then return end
	
	local recordId = (actor.recordId or ""):lower()
	
	local killAward    = FAVOR_KILL_AWARD * ES.S.FAVOR_KILL_MULT * ES.S.FAVOR_GAIN_MULT
	local tabooPenalty = FAVOR_TABOO_PENALTY * ES.S.FAVOR_PENALTY_MULT
	
	local victimRace, victimFactions = "", {}
	if types.NPC.objectIsInstance(actor) then
		local rec = types.NPC.record(actor)
		victimRace = (rec.race or ""):lower()
		victimFactions = types.NPC.getFactions(actor) or {}
	end
	
	-- displeasure is collected here and flushed as one box per reason after every deity is classified
	local tabooNames, senselessNames = {}, {}

	-- single deity, first match wins. taboo by race/faction/recordId is a sin of omission (credits any
	-- nearby death of the faithful); senselessMurder is commission, requiring player attribution below.
	local function classifyForDeity(deityId)
		local deity = ES.getDeity(deityId)
		if not deity then return end
		
		-- taboo kills (recordId substring; covers ordinator etc.)
		if deity.tabooKills and deity.tabooKills.recordIdContains then
			for _, frag in ipairs(deity.tabooKills.recordIdContains) do
				if recordId:find(frag, 1, true) then
					ES.modifyFavor(deityId, -tabooPenalty, "taboo:"..frag)
					tabooNames[#tabooNames + 1] = deity.name
					return
				end
			end
		end
		
		-- taboo kills: race
		if deity.tabooKills and deity.tabooKills.races then
			for _, r in ipairs(deity.tabooKills.races) do
				if victimRace == r:lower() then
					ES.modifyFavor(deityId, -tabooPenalty, "taboo_race:"..r)
					tabooNames[#tabooNames + 1] = deity.name
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
						ES.modifyFavor(deityId, -tabooPenalty, "taboo_faction:"..f)
						tabooNames[#tabooNames + 1] = deity.name
						return
					end
				end
			end
		end
		
		-- favored kills: race
		if deity.favorKills and deity.favorKills.races then
			for _, r in ipairs(deity.favorKills.races) do
				if victimRace == r:lower() then
					ES.modifyFavor(deityId, killAward, "kill_race:"..r)
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
						ES.modifyFavor(deityId, killAward, "kill_faction:"..f)
						return
					end
				end
			end
		end
		
		-- favored kills: recordId substring (blighted creatures)
		if deity.favorKills and deity.favorKills.recordIdContains then
			for _, frag in ipairs(deity.favorKills.recordIdContains) do
				if recordId:find(frag, 1, true) then
					ES.modifyFavor(deityId, killAward, "kill_id:"..frag)
					return
				end
			end
		end
		
		-- favored kills: explicit recordIds
		if deity.favorKills and deity.favorKills.recordIdSet
			and deity.favorKills.recordIdSet[recordId] then
			ES.modifyFavor(deityId, killAward, "kill_set:"..recordId)
			return
		end
		
		-- favored kills: creature type (daedra), proximity-credited like the sets above
		if deity.favorKills and deity.favorKills.creatureTypes
			and types.Creature.objectIsInstance(actor) then
			local ctype = types.Creature.record(actor).type
			for _, name in ipairs(deity.favorKills.creatureTypes) do
				if creatureTypeByName[name:lower()] == ctype then
					ES.modifyFavor(deityId, killAward, "kill_ctype:"..name)
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
				ES.modifyFavor(deityId, killAward, "kill_mage:"..classId)
				return
			end
		end

		-- senseless murder: a player-dealt kill of a non-hostile npc the deity neither favors nor taboos
		local playerHitTime = playerVictims[actor.id]
		if deity.tabooKills and deity.tabooKills.senselessMurder
			and types.NPC.objectIsInstance(actor)
			and playerHitTime and (core.getRealTime() - playerHitTime) <= PLAYER_KILL_WINDOW
			and not actorWasHostile(actor) then
			ES.modifyFavor(deityId, -tabooPenalty, "murder")
			senselessNames[#senselessNames + 1] = deity.name
		end
	end
	
	for _, deityId in ipairs(active) do
		classifyForDeity(deityId)
	end
	if #tabooNames > 0 then messageBox(2, displeasureLine(tabooNames, "by this killing")) end
	if #senselessNames > 0 then messageBox(2, displeasureLine(senselessNames, "by this senseless killing")) end
	ES.updateAbilities()
end

-- pantheons with crimePenalty=true (Tribunal Temple) lose favor proportional to bounty increases. polled each sluggish frame.
-- bounty decreases (paying off) don't refund favor but do update lastBounty so future deltas track.
function ES.checkCrimePenalty()
	if not ES.S.TOGGLE_ENABLED then return end
	local active = ES.saveData.activeDeities
	if #active == 0 then return end
	
	local bounty = types.Player.getCrimeLevel(self) or 0
	local last   = ES.saveData.lastBounty or bounty
	if bounty > last then
		local delta   = bounty - last
		local penalty = delta * FAVOR_CRIME_PENALTY_RATIO * ES.S.FAVOR_PENALTY_MULT
		local displeased = {}
		for _, deityId in ipairs(active) do
			local deity = ES.getDeity(deityId)
			if deity and deity.pantheon and deity.pantheon.crimePenalty then
				ES.modifyFavor(deityId, -penalty, "crime:"..delta)
				displeased[#displeased + 1] = deity.name
			end
		end
		if #displeased > 0 then
			messageBox(2, displeasureLine(displeased, "by your crimes"))
			ES.updateAbilities()
		end
	end
	ES.saveData.lastBounty = bounty
end

-- cell change shortly after an AI cast + a temple_marker static near the player position = successful intervention to a temple.
-- grants pilgrimage favor on top of the per-cast +2.
function ES.checkAITeleportArrival(prevCell)
	if not ES.S.TOGGLE_ENABLED then return end
	if #ES.saveData.activeDeities == 0 then return end
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
					for _, deityId in ipairs(ES.saveData.activeDeities) do
						ES.modifyFavor(deityId, 1 * ES.S.FAVOR_GAIN_MULT, "almsivi_to_temple")
					end
					local deity = ES.getHighestFavorDeity()
					messageBox(3, string.format("%s welcomes you to this temple.", deity and deity.name or "The Temple"))
					ES.updateAbilities()
					return
				end
			end
		end
	end))
end

-- per game hour, per deity: passive regen if tenets met, else idle decay
function ES.perHourFavor()
	if not ES.S.TOGGLE_ENABLED then return end
	local active = ES.saveData.activeDeities
	if #active == 0 then return end
	
	local now = core.getGameTime()
	for _, deityId in ipairs(active) do
		local deity = ES.getDeity(deityId)
		local st = ES.saveData.deities[deityId]
		if deity and st then
			if ES.checkPassiveRegen(deity) and ES.S.TOGGLE_PASSIVE_REGEN then
				ES.modifyFavor(deityId, FAVOR_TOGGLE_PASSIVE_REGEN_RATE * ES.S.FAVOR_PASSIVE_MULT * ES.S.FAVOR_GAIN_MULT, "passive", true)
			elseif ES.S.FAVOR_DECAY ~= "Off" then
				local last = st.lastFavorGain or now
				local hoursIdle = (now - last) / 3600
				if hoursIdle > ES.S.FAVOR_DECAY_GRACE_HOURS then
					ES.modifyFavor(deityId, -TOGGLE_FAVOR_DECAY_RATE * ES.S.FAVOR_DECAY_MULT, "decay")
				end
			end
		end
	end
	ES.updateAbilities()
end

-- favored cells trickle favor; per-cell minutes (savedata) decay the rate to a floor, killing wait-farming
function ES.perMinuteExplore(_, _, minutesPassed)
	if not ES.S.TOGGLE_ENABLED then return end
	if not minutesPassed or minutesPassed <= 0 then return end
	local active = ES.saveData.activeDeities
	if #active == 0 or not G_cellInfo then return end

	local matched
	for _, deityId in ipairs(active) do
		local deity = ES.getDeity(deityId)
		if deity and deity.favorCells then
			for flag in pairs(deity.favorCells) do
				if G_cellInfo[flag] then
					matched = matched or {}
					matched[#matched + 1] = deityId
					break
				end
			end
		end
	end
	if not matched then return end

	-- logistic falloff over minutes spent in this cell
	local cellKey = self.cell and self.cell.name and self.cell.name:lower() or ""
	local explored = ES.saveData.exploredCells
	local minutesHere = explored[cellKey] or 0
	local rate = FAVOR_LOCATION_EXPLORE_FLOOR + (FAVOR_LOCATION_EXPLORE_RATE - FAVOR_LOCATION_EXPLORE_FLOOR)
		/ (1 + math.exp(EXPLORE_STEEPNESS * (minutesHere - EXPLORE_MIDPOINT_MINUTES)))
	explored[cellKey] = minutesHere + minutesPassed

	-- rate is favor/hour; award only this tick's slice
	local award = rate * ES.S.FAVOR_EXPLORE_MULT * ES.S.FAVOR_GAIN_MULT * minutesPassed / 60
	for _, deityId in ipairs(matched) do
		ES.modifyFavor(deityId, award, "explore")
	end
	ES.updateAbilities()
end

-- ------------------------------ handlers ----------------------------------

-- award favor for casting favored spells; track almsivi casts for the temple_marker teleport detection.
-- gift 3 cost is handled per-deity in gifts_p (some defer payment until their effect actually lands).
I.SkillProgression.addSkillUsedHandler(function(skillId, params)
	if not ES.S.TOGGLE_ENABLED then return end
	if #ES.saveData.activeDeities == 0 then return end
	if params.useType ~= I.SkillProgression.SKILL_USE_TYPES.Spellcast_Success then return end
	
	local selected = types.Actor.getSelectedSpell(self)
	if not selected then return end
	local spellId = selected.id:lower()
	
	-- track almsivi intervention casts for temple_marker teleport detection
	if spellId == "almsivi intervention" then
		lastAICastTime = core.getRealTime()
	end
	
	local entry = spellsDb[spellId]
	if not entry then return end
	local credited = false
	for _, deityId in ipairs(ES.saveData.activeDeities) do
		if ES.tableContains(entry.deity, deityId) then
			ES.modifyFavor(deityId, entry.favor * ES.S.FAVOR_SPELL_MULT * ES.S.FAVOR_GAIN_MULT, "spell:"..spellId)
			credited = true
		end
	end
	if credited then ES.updateAbilities() end
end)

-- preferred: subscribe to Sun's Dusk's fan-out death job list (lets other addons listen too).
-- fallback for older Sun's Dusk without the list: claim the single-handler event (winner-take-all).
if G_actorDiedJobs then
	table.insert(G_actorDiedJobs, ES.onActorDied)
else
	G_eventHandlers.SunsDusk_actorDied = function(actor)
		ES.onActorDied(actor)
	end
end

-- book read tracker: real time, since the book ui pauses sim time.
-- credits favor once the book has been open at least BOOK_READ_MIN_TIME seconds.
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
table.insert(G_perMinuteJobs, ES.perMinuteExplore)
G_onFrameJobsSluggish.es_checkCrimePenalty = ES.checkCrimePenalty

-- snapshot authored fight after each cell change, deferred so the scan doesn't add to the cell-load lag spike
table.insert(G_onLoadJobs, function()
	async:newUnsavableSimulationTimer(0.5, async:callback(snapshotAuthoredFight))
end)
table.insert(G_cellChangedJobs, function()
	async:newUnsavableSimulationTimer(0.5, async:callback(snapshotAuthoredFight))
end)

-- a taunt/persuasion legitimately changes the partner's base fight, so re-snapshot it
-- 0.2s after the conversation closes, overwriting the first-sighting value.
-- exception: the BILL_MT mod spikes fight through a dialogue script (StartScript
-- BILL_MT_calc_legit_kills); that spike isn't authored, so skip the update when it fires.
local dialogueActor = nil
local skipDialogueFightUpdate = false

local function dialogueRunsLegitKillScript(info)
	return info.resultScript ~= nil and info.resultScript:lower():find("^%s*startscript%s+bill_mt_calc_legit_kills") ~= nil
end

-- preferred: Sun's Dusk's dialogue fan-out. fallback: claim the single-handler event.
if G_DialogueResponseJobs then
	table.insert(G_DialogueResponseJobs, function(data, topic, info)
		if dialogueRunsLegitKillScript(info) then skipDialogueFightUpdate = true end
	end)
else
	G_eventHandlers.DialogueResponse = function(data)
		local topic = core.dialogue[data.type].records[data.recordId]
		for _, info in pairs(topic.infos) do
			if info.id == data.infoId then
				if dialogueRunsLegitKillScript(info) then skipDialogueFightUpdate = true end
				return
			end
		end
	end
end

table.insert(G_UiModeChangedJobs, function(data)
	if data.newMode == "Dialogue" then
		if data.arg then dialogueActor = data.arg end
	elseif data.oldMode == "Dialogue" then
		local actor = dialogueActor
		local skip = skipDialogueFightUpdate
		dialogueActor = nil
		skipDialogueFightUpdate = false
		if actor and not skip then
			async:newUnsavableSimulationTimer(0.2, async:callback(function()
				local authored = ES.saveData and ES.saveData.authoredFight
				if not authored or not actor:isValid() then return end
				authored[getId(actor)] = types.Actor.stats.ai.fight(actor).base
			end))
		end
	end
end)

-- ------------------------------ combat trackers ---------------------------
-- feed kill attribution: record actors the player damages, for senseless-murder detection

table.insert(G_landedHitJobs, function(target)
	if target and target:isValid() then playerVictims[target.id] = core.getRealTime() end
end)
-- player-cast spell hits (incl. tr_spells via Sun's Dusk); a hostile cast makes a victim, beneficial doesn't
table.insert(G_landedSpellHitJobs, function(target, _, isHostile)
	if isHostile ~= false and target and target:isValid() then playerVictims[target.id] = core.getRealTime() end
end)

-- fallback when Sun's Dusk is too old to route TD_SpellAdded into the job above: consume it directly.
-- guarded, so a routing-capable Sun's Dusk (which claims this slot unconditionally) wins.
if not G_eventHandlers.TD_SpellAdded then
	G_eventHandlers.TD_SpellAdded = function(data)
		if data.harmful and data.caster and types.Player.objectIsInstance(data.caster)
			and data.target and data.target:isValid() then
			playerVictims[data.target.id] = core.getRealTime()
		end
	end
end

-- trackers are per-encounter; clear on cell change to bound memory
table.insert(G_cellChangedJobs, function()
	playerVictims = {}
end)
