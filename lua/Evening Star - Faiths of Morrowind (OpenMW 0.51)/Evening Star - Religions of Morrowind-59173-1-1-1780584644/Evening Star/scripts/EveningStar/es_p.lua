local FAVOR_THRESHOLD_G1            = 30
local FAVOR_THRESHOLD_G2            = 60
local FAVOR_THRESHOLD_G3            = 100

ES = ES or {}
ES.DB = ES.DB or {}

ES.C = ES.C or {}
ES.C.FAVOR_MAX = 100
ES.C.GIFT_3_CAST_COST = 10
ES.C.GIFT_3_REVIVE_COST = 15 -- mother's grace (almalexia g3) revive cost
ES.C.FAVOR_THRESHOLDS = { FAVOR_THRESHOLD_G1, FAVOR_THRESHOLD_G2, FAVOR_THRESHOLD_G3 } -- devotion tier favor gates

require('scripts.EveningStar.db.es_books')
require('scripts.EveningStar.db.es_actors')
require('scripts.EveningStar.db.es_deities')
require('scripts.EveningStar.db.es_quests')
require('scripts.EveningStar.db.es_spells')
require('scripts.EveningStar.db.es_shrines')

local deityRecords = ES.DB.deities

require('scripts.EveningStar.es_settings')

local esFavorBar = require('scripts.EveningStar.lib.es_favor_bar')

ES.lastDevotionLevel = {}
ES.lastFavorReason = {} -- transient: most recent modifyFavor reason per deity, picks the right demotion message

-- ------------------------------ helpers -----------------------------------

local function tableContains(haystack, value)
	if type(haystack) ~= "table" then return haystack == value end
	for _, v in ipairs(haystack) do
		if v == value then return true end
	end
	return false
end
ES.tableContains = tableContains

local function getDeity(id)
	if not id then return nil end
	local d = deityRecords[id:lower()]
	if d and d.stub then return nil end
	return d
end
ES.getDeity = getDeity

-- ------------------------------ deity state access ------------------------
-- multi-deity: per-deity state in ES.saveData.deities[id], slot order in activeDeities

local function getHighestFavorDeity()
	local bestId, bestFavor
	for _, id in ipairs(ES.saveData.activeDeities) do
		local st = ES.saveData.deities[id]
		if st and (not bestFavor or (st.favor or 0) > bestFavor) then
			bestId, bestFavor = id, st.favor or 0
		end
	end
	return bestId and getDeity(bestId) or nil
end
ES.getHighestFavorDeity = getHighestFavorDeity

-- prayer urgency [0,1]: idle game-hours since this deity last gained favor, over the decay
-- grace window. 0 freshly tended, 1 at/after the decay deadline. drives the hud icon styling.
local function getDeityUrgency(deityId)
	local st = ES.saveData.deities[deityId]
	if not st then return 0 end
	local grace = tonumber(ES.S.FAVOR_DECAY_GRACE_HOURS) or 12
	if grace <= 0 then return 0 end
	local now = core.getGameTime()
	local hoursIdle = (now - (st.lastFavorGain or now)) / 3600
	return math.max(0, hoursIdle / grace)
end
ES.getDeityUrgency = getDeityUrgency

-- the worshipped deity most overdue for prayer; ties broken toward lower favor
local function getMostUrgentDeity()
	local bestId, bestUrgency, bestFavor
	for _, id in ipairs(ES.saveData.activeDeities) do
		local st = ES.saveData.deities[id]
		if st then
			local urgency = getDeityUrgency(id)
			local favor = st.favor or 0
			if not bestId or urgency > bestUrgency
				or (urgency == bestUrgency and favor < bestFavor) then
				bestId, bestUrgency, bestFavor = id, urgency, favor
			end
		end
	end
	return bestId and getDeity(bestId) or nil, bestUrgency or 0
end
ES.getMostUrgentDeity = getMostUrgentDeity

-- devotion tier as a number (0 uninitiated .. 3 devotee); names are ui-only
ES.DEVOTION_NAMES = {
	[0] = "Uninitiated",
	[1] = "Worshipper",
	[2] = "Follower",
	[3] = "Devotee",
}

-- favor needed to hold each tier once reached (hysteresis floor, by level)
local DEVOTION_HOLD = {
	[1] = FAVOR_THRESHOLD_G1,
	[2] = FAVOR_THRESHOLD_G1,
	[3] = FAVOR_THRESHOLD_G2,
}

local function resolveDevotionLevel(favor, current)
	favor = favor or 0
	-- a stale string from a pre-numeric save coerces to uninitiated
	if type(current) ~= "number" then current = 0 end
	local promoted = 0
	if favor >= FAVOR_THRESHOLD_G3 then promoted = 3
	elseif favor >= FAVOR_THRESHOLD_G2 then promoted = 2
	elseif favor >= FAVOR_THRESHOLD_G1 then promoted = 1 end
	if promoted >= current then return promoted end
	local level = current
	while level > promoted and favor < DEVOTION_HOLD[level] do
		level = level - 1
	end
	return level
end

local function getDevotionLevel(deityId)
	local st = ES.saveData.deities[deityId]
	if not st then return 0 end
	return resolveDevotionLevel(st.favor or 0, st.devotionLevel)
end
ES.getDevotionLevel = getDevotionLevel

-- ------------------------------ favor mutation ---------------------------

-- skipGainStamp: a gain that shouldn't reset the decay grace (passive trickle)
local function modifyFavor(deityId, amount, reason, skipGainStamp)
	if not ES.S.TOGGLE_ENABLED then return end
	local st = ES.saveData.deities[deityId]
	if not st then return end
	local old = st.favor or 0
	st.favor = math.max(0, math.min(ES.C.FAVOR_MAX, old + amount))
	if amount > 0 and not skipGainStamp then
		st.lastFavorGain = core.getGameTime()
	end
	ES.lastFavorReason[deityId] = reason
	esFavorBar.bumpVisible(3)
	log(4, "[EVENING STAR] favor ", deityId, " ", old, " -> ", st.favor, " ", reason or "")
end
ES.modifyFavor = modifyFavor

-- ------------------------------ abilities ------------------
-- reconciles granted spells per active deity: pray power, granted, g1, g3
local function updateAbilities()
	if not ES.S.TOGGLE_ENABLED then return end
	if G_preventAddingAnyBuffs then return end
	
	local spells = typesActorSpellsSelf
	
	for _, deityId in ipairs(ES.saveData.activeDeities) do
		local deity = getDeity(deityId)
		local st = ES.saveData.deities[deityId]
		if deity and st then
			local favor = st.favor or 0
			local level = getDevotionLevel(deityId)
			st.devotionLevel = level
			
			local prayId = "es_pray_"..deity.pantheonId.."_"..deity.id
			if ES.S.PRAYER_POWER == "Power per Deity" and core.magic.spells.records[prayId] then
				spells:add(prayId)
			elseif core.magic.spells.records[prayId] then
				spells:remove(prayId)
			end
			for _, spellId in ipairs(deity.grantedSpells or {}) do
				if core.magic.spells.records[spellId] then spells:add(spellId) end
			end
			
			-- g1: worshipper ability
			local wantWorship = level > 0 and deity.gift_1
			if wantWorship and core.magic.spells.records[deity.gift_1] then
				local has = false
				for _, sp in pairs(spells) do
					if sp.id == deity.gift_1 then has = true; break end
				end
				if not has then
					spells:add(deity.gift_1)
				end
				st.currentGift1 = deity.gift_1
			elseif st.currentGift1 and core.magic.spells.records[st.currentGift1] then
				spells:remove(st.currentGift1)
				st.currentGift1 = nil
			end
			
			-- g3: devotee ability, gated on this deity's favor
			local wantDevotee = level == 3 and deity.gift_3
				and favor >= ES.C.GIFT_3_CAST_COST
			if wantDevotee and core.magic.spells.records[deity.gift_3] then
				local has = false
				for _, sp in pairs(spells) do
					if sp.id == deity.gift_3 then has = true; break end
				end
				if not has then
					spells:add(deity.gift_3)
				end
			elseif deity.gift_3 and core.magic.spells.records[deity.gift_3] then
				spells:remove(deity.gift_3)
			end
			
			local last = ES.lastDevotionLevel[deityId]
			if last ~= level then
				if level == 1 and last == 0 then
					messageBox(2, string.format("You have become a Worshipper of %s.", deity.name))
				elseif level == 2 and last and last < 2 then
					messageBox(2, string.format("You have become a Follower of %s and have earned %s.", deity.name, deity.gift_2_alias))
					ambient.playSound("skillraise")
				elseif level == 3 and last then
					messageBox(2, string.format("You have become a Devotee of %s and have earned %s.", deity.name, deity.gift_3_alias))
					ambient.playSound("skillraise")
				-- only the silent idle-decay drop announces itself; penalty drops already showed a displeasure box
				elseif level == 0 and last and last ~= 0 and ES.lastFavorReason[deityId] == "decay" then
					messageBox(2, string.format("You have not prayed to %s in a while. Your favor has diminished.", deity.name))
				end
				ES.lastDevotionLevel[deityId] = level
			end
		end
	end

	-- one shared power, granted only while worshipping at least one deity
	if ES.S.PRAYER_POWER == "All-Deity Power" and #ES.saveData.activeDeities > 0
		and core.magic.spells.records["es_pray_all"] then
		spells:add("es_pray_all")
	elseif core.magic.spells.records["es_pray_all"] then
		spells:remove("es_pray_all")
	end
end
ES.updateAbilities = updateAbilities

local function removeDeityBuffs()
	if not ES.S.TOGGLE_ENABLED then return end
	local spells = typesActorSpellsSelf
	for _, deityId in ipairs(ES.saveData.activeDeities) do
		local st = ES.saveData.deities[deityId]
		if st and st.currentGift1 and core.magic.spells.records[st.currentGift1] then
			spells:remove(st.currentGift1)
		end
	end
end
ES.removeDeityBuffs = removeDeityBuffs
table.insert(G_removeAbilitiesJobs, removeDeityBuffs)

-- re-apply buffs after sleep ends
table.insert(G_postSleepJobs, function(slept)
	ES.lastDevotionLevel = {}
	updateAbilities()
end)

-- ------------------------------ console command ---------------------------
-- lua favor [<deity name or id>] [+|-]N  (no name = all active deities)

if G_consoleJobs then
	G_consoleJobs.eveningStarFavor = function(mode, str)
		local name, sign, num = str:lower():match("^lua%s+favor%s+(.-)%s*([%+%-]?)(%d+%.?%d*)%s*$")
		if not num then return end
		if not ES.saveData then
			ui.printToConsole("favor: no save loaded", ui.CONSOLE_COLOR.Error)
			return true
		end
		local amount = tonumber(num)
		
		local targets = {}
		if name and name ~= "" then
			for _, id in ipairs(ES.saveData.activeDeities) do
				local d = getDeity(id)
				if d and (id == name or (d.name and d.name:lower() == name)) then
					targets[#targets + 1] = id
				end
			end
			if #targets == 0 then
				ui.printToConsole("favor: not worshipping '"..name.."'", ui.CONSOLE_COLOR.Error)
				return true
			end
		else
			for _, id in ipairs(ES.saveData.activeDeities) do
				targets[#targets + 1] = id
			end
			if #targets == 0 then
				ui.printToConsole("favor: no active deity", ui.CONSOLE_COLOR.Error)
				return true
			end
		end
		
		for _, id in ipairs(targets) do
			local st = ES.saveData.deities[id]
			local current = st and st.favor or 0
			local delta
			if sign == "+" then
				delta = amount
			elseif sign == "-" then
				delta = -amount
			else
				delta = amount - current
			end
			modifyFavor(id, delta, "console")
			local d = getDeity(id)
			ui.printToConsole(string.format("favor with %s set to %d",
				d and d.name or id,
				math.floor((st and st.favor or 0) + 0.5)), ui.CONSOLE_COLOR.Success)
		end
		updateAbilities()
		return true
	end
end

-- ------------------------------ deity console command ---------------------
-- lua deity select [<deity name or id>]  (no name opens the selector ui)

if G_consoleJobs then
	G_consoleJobs.eveningStarDeity = function(mode, str)
		local name = str:lower():match("^lua%s+deity%s+select%s*(.-)%s*$")
		if not name then return end
		if not ES.saveData then
			ui.printToConsole("deity: no save loaded", ui.CONSOLE_COLOR.Error)
			return true
		end
		-- no name: open the full selector, same as the shrine flow
		if name == "" then
			ES.openDeityChoice()
			return true
		end
		-- resolve a name or id to a real (non-stub) deity
		local matchId
		for id, d in pairs(deityRecords) do
			if not d.stub and (id == name or (d.name and d.name:lower() == name)) then
				matchId = id
				break
			end
		end
		if not matchId then
			ui.printToConsole("deity: no deity '"..name.."'", ui.CONSOLE_COLOR.Error)
			return true
		end
		if ES.saveData.deities[matchId] then
			ui.printToConsole("deity: already worshipping "..deityRecords[matchId].name, ui.CONSOLE_COLOR.Error)
			return true
		end
		-- opens that deity's tenets screen; accept enforces the slot cap
		ES.openDeityChoice(matchId)
		return true
	end
end

-- ------------------------------ onLoad ------------------------------------

local function onLoad(eventName)
	saveData.EveningStar = saveData.EveningStar or {}
	local sd = saveData.EveningStar
	
	-- migrate a pre-multi-deity save into the per-deity record map
	if sd.currentDeity and not sd.deities then
		sd.deities = {
			[sd.currentDeity] = {
				favor                = sd.favor or 0,
				devotionLevel        = sd.devotionLevel or 0,
				currentGift1         = sd.currentGift1,
				lastFavorGain        = sd.lastFavorGain,
				lastShrinePrayerTime = sd.lastShrinePrayerTime,
				shrinePrayerStreak   = sd.shrinePrayerStreak,
				mothersGraceReadyAt  = sd.mothersGraceReadyAt,
				booksRead            = sd.booksRead or {},
				journalsCredited     = sd.journalsCredited or {},
			},
		}
		sd.activeDeities = { sd.currentDeity }
		sd.currentDeity = nil
		sd.favor = nil
		sd.devotionLevel = nil
		sd.currentGift1 = nil
		sd.lastFavorGain = nil
		sd.lastShrinePrayerTime = nil
		sd.shrinePrayerStreak = nil
		sd.mothersGraceReadyAt = nil
		sd.booksRead = nil
		sd.journalsCredited = nil
	end
	
	sd.deities = sd.deities or {}
	sd.activeDeities = sd.activeDeities or {}
	sd.exploredCells = sd.exploredCells or {}  -- [cellName] = minutes spent, for explore-rate decay
	sd.authoredFight = sd.authoredFight or {}  -- [getId(npc)] = base fight at first sighting, before crime inflates it
	if sd.seenReligionPrompt == nil then sd.seenReligionPrompt = false end
	
	ES.saveData = sd
	ES.lastDevotionLevel = {}
	
	-- restore abilities for any deity we already worship
	if #sd.activeDeities > 0 then
		updateAbilities()
	end
end
table.insert(G_onLoadJobs, onLoad)

require('scripts.EveningStar.lib.es_favor_sources')
require('scripts.EveningStar.lib.es_prayer')
require('scripts.EveningStar.lib.es_ui')
require('scripts.EveningStar.lib.es_sd_widget')

require('scripts.EveningStar.lib.es_ralts_interop')
require('scripts.EveningStar.lib.es_first_sleep')
require('scripts.EveningStar.gifts.gifts_p')

log(6, "[Evening Star] deity worship module loaded")
