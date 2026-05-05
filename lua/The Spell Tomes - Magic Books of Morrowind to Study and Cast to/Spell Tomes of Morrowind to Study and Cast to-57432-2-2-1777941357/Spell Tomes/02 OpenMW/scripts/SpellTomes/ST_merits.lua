local self = require("openmw.self")
local core = require("openmw.core")
local types = require("openmw.types")
local ui = require("openmw.ui")
local ambient = require("openmw.ambient")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")

async:newUnsavableSimulationTimer(1.0, function()
	if not I.MeritsOfService then
		return
	end
	local FACTION_SCHOOLS = {
		["Mages Guild"]           = { alteration = true, conjuration = true, destruction = true, illusion = true, mysticism = true, restoration = true },
		["House Telvanni"]  = { alteration = true, conjuration = true, destruction = true, illusion = true, mysticism = true, restoration = true },
		["Temple"]                = { mysticism = true, restoration = true },
		["Imperial Cult"]         = { mysticism = true, restoration = true },
		["Morag Tong"]            = { illusion = true },
		["Thieves Guild"]         = { illusion = true },
	}

	local settingsSection = storage.globalSection("SettingsSpellTomes")
	
	local function getWeight()
		return S.MOS_TOME_WEIGHT
	end
	
	local function getMin()
		return S.MOS_MIN_TOMES
	end
	
	local function getMax()
		return S.MOS_MAX_TOMES
	end
	
	-- from mirrors ST_getCastChance.lua
	local function dominantSchool(spell)
		local totals = {}
		for _, eff in pairs(spell.effects) do
			local s = eff.effect.school
			if s then
				local minMagn = eff.effect.hasMagnitude and eff.magnitudeMin or 1
				local maxMagn = eff.effect.hasMagnitude and eff.magnitudeMax or 1
				local dur = (eff.effect.hasDuration and not eff.effect.isAppliedOnce) and math.max(1, eff.duration or 1) or 1
				local x = 0.5 * (math.max(1, minMagn) + math.max(1, maxMagn))
					* 0.1 * eff.effect.baseCost
					* dur
				totals[s] = (totals[s] or 0) + x
			end
		end
		local best, bestVal = nil, -1
		for s, v in pairs(totals) do
			if v > bestVal then best, bestVal = s, v end
		end
		return best
	end
	
	local function playerKnowsSpell(spellId)
		for _, spell in pairs(types.Player.spells(self)) do
			if spell.id == spellId then return true end
		end
		return false
	end

	local function buildPools()
		local pools = {}
		for factionName, _ in pairs(FACTION_SCHOOLS) do
			pools[factionName] = {}
		end
		
		for tomeId, def in pairs(registeredTomes) do
			local spell = core.magic.spells.records[def.spellId]
			if spell then
				local school = dominantSchool(spell)
				if school then
					for factionName, schools in pairs(FACTION_SCHOOLS) do
						if schools[school] then
							table.insert(pools[factionName], tomeId)
						end
					end
				end
			end
		end
		
		for tomeId, spellId in pairs(spellTomes) do
			local spell = core.magic.spells.records[spellId]
			if spell then
				local school = dominantSchool(spell)
				if school then
					for factionName, schools in pairs(FACTION_SCHOOLS) do
						if schools[school] then
							table.insert(pools[factionName], tomeId)
						end
					end
				end
			end
		end
		
		return pools
	end
	
	-- at least one tome in the list teaches a spell the player doesn't know
	local function condition(rewardList)
		if not rewardList then return false end
		for _, tomeId in ipairs(rewardList) do
			local spellId = spellTomes[tomeId]
			if spellId and not playerKnowsSpell(spellId) then
				return true
			end
		end
		return false
	end
	
	local function rewardAmountPicker()
		local lo, hi = getMin(), getMax()
		if hi < lo then hi = lo end
		return math.random(lo, hi)
	end
	
	-- adds unknown tomes as quest reward
	local function rewardGiver(rewardList, amount)
		-- mos passes the faction's full reward map here (not the inner list, despite api docs)
		local tomes = rewardList.spelltomes or rewardList

		-- filter to unknown tomes
		local pool = {}
		for _, tomeId in ipairs(tomes) do
			local spellId = spellTomes[tomeId]
			if spellId and not playerKnowsSpell(spellId) then
				pool[#pool + 1] = tomeId
			end
		end
		if #pool == 0 then return end
		
		-- pick tomes
		local granted = {}
		for _ = 1, math.min(amount, #pool) do
			local idx = math.random(#pool)
			granted[#granted + 1] = pool[idx]
			table.remove(pool, idx)
		end
		
		-- give items and build message
		local lines = {}
		for _, tomeId in ipairs(granted) do
			core.sendGlobalEvent("SpellTomes_giveTome", { player = self, tomeId = tomeId })
			local bookRec = types.Book.record(tomeId)
			local name = bookRec and bookRec.name or tomeId
			lines[#lines + 1] = "You have received " .. name .. "."
		end
		
		ui.showMessage(table.concat(lines, "\n"))
		ambient.playSound("Item Book Up")
	end
	
	-------------------------------------------------- registration --------------------------------------------------
	
	I.MeritsOfService.registerNewReward({
		rewardKey = "spelltomes",
		weightGetter = getWeight,
		rewardAmountPicker = rewardAmountPicker,
		rewardGiver = rewardGiver,
		condition = condition,
	})
	
	-- mirror mos's factionParser
	local function getMosFactions()
		local set = {}
		for _, rec in ipairs(core.factions.records) do
			local isDummy = #rec.attributes == 2
				and rec.attributes[1] == "strength"
				and rec.attributes[2] == "strength"
			if not isDummy and (rec.attributes[1] or rec.skills[1]) then
				set[rec.name] = true
			end
		end
		return set
	end
	
	-- build spell tome pools for each faction and register rewards
	local pools = buildPools()
	local mosFactions = getMosFactions()
	for factionName, list in pairs(pools) do
		if #list > 0 then
			if mosFactions[factionName] then
				I.MeritsOfService.addRewardToFactionPool({
					factionName = factionName,
					rewardKey = "spelltomes",
					rewardList = list,
				})
			end
		end
	end
end)