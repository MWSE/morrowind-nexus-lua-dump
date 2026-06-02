local FAVOR_THRESHOLD_G1			= 30
local FAVOR_THRESHOLD_G2			= 60
local FAVOR_THRESHOLD_G3			= 100

ES = ES or {}
ES.DB = ES.DB or {}

ES.C = ES.C or {}
ES.C.FAVOR_MAX = 100
ES.C.GIFT_3_CAST_COST = 10
ES.C.GIFT_3_REVIVE_COST = 15 -- mother's grace (almalexia g3) revive cost

require('scripts.EveningStar.db.es_books')
require('scripts.EveningStar.db.es_actors')
require('scripts.EveningStar.db.es_deities')
require('scripts.EveningStar.db.es_quests')
require('scripts.EveningStar.db.es_spells')
require('scripts.EveningStar.db.es_shrines')

local deityRecords = ES.DB.deities

require('scripts.EveningStar.es_settings')

local esFavorBar = require('scripts.EveningStar.lib.es_favor_bar')

ES.lastDevotionLevel = nil

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

local function getCurrentDeity()
	if not ES.saveData.currentDeity then return nil end
	return getDeity(ES.saveData.currentDeity)
end
ES.getCurrentDeity = getCurrentDeity

local DEVOTION_ORDER = { uninitiated = 0, worshipper = 1, follower = 2, devotee = 3 }
local DEVOTION_BELOW = { devotee = "follower", follower = "worshipper", worshipper = "uninitiated" }
local DEVOTION_HOLD  = {
	worshipper = FAVOR_THRESHOLD_G1,
	follower   = FAVOR_THRESHOLD_G1,
	devotee    = FAVOR_THRESHOLD_G2,
}

local function resolveDevotionLevel(favor, current)
	favor = favor or 0
	current = current or "uninitiated"
	local promoted = "uninitiated"
	if favor >= FAVOR_THRESHOLD_G3 then promoted = "devotee"
	elseif favor >= FAVOR_THRESHOLD_G2 then promoted = "follower"
	elseif favor >= FAVOR_THRESHOLD_G1 then promoted = "worshipper" end
	if DEVOTION_ORDER[promoted] >= DEVOTION_ORDER[current] then return promoted end
	local level = current
	while DEVOTION_ORDER[level] > DEVOTION_ORDER[promoted] and favor < DEVOTION_HOLD[level] do
		level = DEVOTION_BELOW[level]
	end
	return level
end

local function getDevotionLevel(favor)
	return resolveDevotionLevel(favor, ES.saveData and ES.saveData.devotionLevel)
end
ES.getDevotionLevel = getDevotionLevel

-- ------------------------------ favor mutation ---------------------------

local function modifyFavor(amount, reason)
	if not ES.S.TOGGLE_ENABLED then return end
	local old = ES.saveData.favor or 0
	ES.saveData.favor = math.max(0, math.min(ES.C.FAVOR_MAX, old + amount))
	if amount > 0 then
		ES.saveData.lastFavorGain = core.getGameTime()
	end
	esFavorBar.bumpVisible(3)
	log(4, "[EVENING STAR] favor ", old, " -> ", ES.saveData.favor, reason or "")
end
ES.modifyFavor = modifyFavor

-- ------------------------------ abilities ------------------

local function updateAbilities()
	if not ES.S.TOGGLE_ENABLED then return end
	if not ES.saveData.currentDeity then return end
	if G_preventAddingAnyBuffs then return end
	
	local deity = getCurrentDeity()
	if not deity then return end
	
	local level = getDevotionLevel(ES.saveData.favor or 0)
	ES.saveData.devotionLevel = level
	local spells = typesActorSpellsSelf
	
	local prayId = "es_pray_"..deity.pantheonId.."_"..deity.id
	if core.magic.spells.records[prayId] then spells:add(prayId) end
	for _, spellId in ipairs(deity.grantedSpells or {}) do
		if core.magic.spells.records[spellId] then spells:add(spellId) end
	end
	
	-- g1: worshipper ability
	local wantWorship = level ~= "uninitiated" and deity.gift_1
	if wantWorship and core.magic.spells.records[deity.gift_1] then
		local has = false
		for _, sp in pairs(spells) do
			if sp.id == deity.gift_1 then has = true; break end
		end
		if not has then
			spells:add(deity.gift_1)
		end
		ES.saveData.currentGift1 = deity.gift_1
	elseif ES.saveData.currentGift1 and core.magic.spells.records[ES.saveData.currentGift1] then
		spells:remove(ES.saveData.currentGift1)
		ES.saveData.currentGift1 = nil
	end
	
	-- g3
	local wantDevotee = level == "devotee" and deity.gift_3
		and (ES.saveData.favor or 0) >= ES.C.GIFT_3_CAST_COST
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
	
	if ES.lastDevotionLevel ~= level then
		if level == "worshipper" and ES.lastDevotionLevel == "uninitiated" then
			messageBox(2, string.format("You have become a Worshipper of %s.", deity.name))
		elseif level == "follower" and ES.lastDevotionLevel
			and DEVOTION_ORDER[ES.lastDevotionLevel] < DEVOTION_ORDER.follower then
			messageBox(2, string.format("You have become a Follower of %s and have earned %s.", deity.name, deity.gift_2_alias))
			ambient.playSound("skillraise")
		elseif level == "devotee" and ES.lastDevotionLevel then
			messageBox(2, string.format("You have become a Devotee of %s and have earned %s.", deity.name, deity.gift_3_alias))
			ambient.playSound("skillraise")
		elseif level == "uninitiated" and ES.lastDevotionLevel and ES.lastDevotionLevel ~= "uninitiated" then
			messageBox(2, string.format("You have not prayed to %s in a while. Your favor has diminished.", deity.name))
		end
		ES.lastDevotionLevel = level
	end
end
ES.updateAbilities = updateAbilities

local function removeDeityBuffs()
	if not ES.S.TOGGLE_ENABLED then return end
	local spells = typesActorSpellsSelf
	if ES.saveData.currentGift1 and core.magic.spells.records[ES.saveData.currentGift1] then
		spells:remove(ES.saveData.currentGift1)
	end
end
ES.removeDeityBuffs = removeDeityBuffs
table.insert(G_removeAbilitiesJobs, removeDeityBuffs)

-- re-apply buffs after sleep ends
table.insert(G_postSleepJobs, function(slept)
	ES.lastDevotionLevel = nil
	updateAbilities()
end)

-- ------------------------------ console command ---------------------------

if G_consoleJobs then
	G_consoleJobs.eveningStarFavor = function(mode, str)
		local sign, num = str:lower():match("^lua%s+favor%s+([%+%-]?)(%d+%.?%d*)%s*$")
		if not num then return end
		if not ES.saveData then
			ui.printToConsole("favor: no save loaded", ui.CONSOLE_COLOR.Error)
			return true
		end
		local amount = tonumber(num)
		local current = ES.saveData.favor or 0
		local delta
		if sign == "+" then
			delta = amount
		elseif sign == "-" then
			delta = -amount
		else
			delta = amount - current
		end
		modifyFavor(delta, "console")
		updateAbilities()
		local deity = getCurrentDeity()
		ui.printToConsole(string.format("favor with %s set to %d",
			deity and deity.name or "your deity",
			math.floor((ES.saveData.favor or 0) + 0.5)), ui.CONSOLE_COLOR.Success)
		return true
	end
end

-- ------------------------------ onLoad ------------------------------------

local function onLoad(eventName)
	if not saveData.EveningStar then
		saveData.EveningStar = {
			favor                = 0,
			booksRead            = {},
			journalsCredited     = {},
			currentDeity         = nil,
			devotionLevel        = "uninitiated",
			lastShrinePrayerTime = nil,
			shrinePrayerStreak   = nil,
			lastFavorGain        = nil,
			lastBounty           = nil,
			currentGift1         = nil,
			mothersGraceReadyAt  = nil,
			seenReligionPrompt   = false,
		}
	end
	ES.saveData = saveData.EveningStar
	ES.lastDevotionLevel = nil

	-- restore abilities if we already worship someone
	if ES.saveData.currentDeity then
		updateAbilities()
	end
end
table.insert(G_onLoadJobs, onLoad)

require('scripts.EveningStar.lib.es_favor_sources')
require('scripts.EveningStar.lib.es_prayer')
require('scripts.EveningStar.lib.es_ui')

require('scripts.EveningStar.lib.es_ct_interop')
require('scripts.EveningStar.lib.es_ralts_interop')
require('scripts.EveningStar.lib.es_first_sleep')
require('scripts.EveningStar.gifts.gifts_p')

log(3, "[Evening Star] deity worship module loaded (Vivec only)")