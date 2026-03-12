--local function L(_, fallback)
--	return fallback
--end
function registerRestockingSettings()
local MODNAME = "SimplyMining"
local RENDERER_SLIDER = "SuperSlider2"
local async = require('openmw.async')
local storage = require('openmw.storage')

local restockSettings = {
	key = 'SettingsGlobal'..MODNAME..'Restocking',
	page = MODNAME,
	l10n = "none",
	name = L("Group.Restocking", "Restocking").."                                             ",
	permanentStorage = true,
	description = L("Group.Restocking.desc", "Merchants restock up to one day's worth of ore per visit (max 24h between visits counts).\nStock capacity = restock rate x days of stock."),
	order = 100,
	settings = {
		{
			key = "RESTOCK_ORES",
			name = L("RESTOCK_ORES.name", "Merchants sell ore"),
			description = L("RESTOCK_ORES.desc", "Smiths, traders and other merchants will stock ore for sale"),
			renderer = "checkbox",
			default = true,
		},
		{
			key = "RESTOCK_DAYS",
			name = L("RESTOCK_DAYS.name", "Days of Stock"),
			description = L("RESTOCK_DAYS.desc", "How many days' worth of ore a merchant can hold\nA smith restocking 3/day with 2 days holds 6, a pawnbroker at 0.25/day holds 1"),
			renderer = RENDERER_SLIDER,
			default = 3,
			argument = {
				min = 1,
				max = 7,
				step = 0.5,
				default = 3,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = L("label.Few", "Few"),
				maxLabel = L("label.Many", "Many"),
				width = 150,
			},
		},
		{
			key = "RESTOCK_SPEED",
			name = L("RESTOCK_SPEED.name", "Restock Speed (%)"),
			description = L("RESTOCK_SPEED.desc", "How quickly merchants replenish their ore between visits\nAt 100%, a smith restocks ~3 ore/day, a trader ~1.5/day"),
			renderer = RENDERER_SLIDER,
			default = 100,
			argument = {
				min = 25,
				max = 300,
				step = 25,
				default = 100,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = L("label.Slow", "Slow"),
				maxLabel = L("label.Fast", "Fast"),
				width = 150,
			},
		},
		{
			key = "RESTOCK_RARITY_BIAS",
			name = L("RESTOCK_RARITY_BIAS.name", "Rarity Bias (%)"),
			description = L("RESTOCK_RARITY_BIAS.desc", "How strongly merchants favor common ores over rare ones\n0 = all ores equally likely\n100 = normal weights\n200 = rare ores almost never appear"),
			renderer = RENDERER_SLIDER,
			default = 100,
			argument = {
				min = 0,
				max = 200,
				step = 10,
				default = 100,
				showDefaultMark = true,
				showResetButton = false,
				minLabel = L("label.Flat", "Flat"),
				maxLabel = L("label.Biased", "Biased"),
				width = 150,
			},
		},
	},
}

I.Settings.registerGroup(restockSettings)

local restockSection = storage.globalSection(restockSettings.key)

local function syncRestockSettings()
	for _, entry in ipairs(restockSettings.settings) do
		local val = restockSection:get(entry.key)
		if val == nil then val = entry.default end
		_G["S_" .. entry.key] = val
	end
end

syncRestockSettings()

restockSection:subscribe(async:callback(function()
	syncRestockSettings()
end))
end

-- Profiles (exp and invertBias removed — oreWeights handles distribution)
local oreProfiles = {
	{ pattern = "smith",      restockPerDay = 3    },
	{ pattern = "miner",      restockPerDay = 2    },
	{ pattern = "jewel",      restockPerDay = 1    },
	{ pattern = "alchemist",  restockPerDay = 1    },
	{ pattern = "apothecary", restockPerDay = 0.5  },
	{ pattern = "trader",     restockPerDay = 1.5  },
	{ pattern = "merchant",   restockPerDay = 1    },
	{ pattern = "broker",     restockPerDay = 0.25 },
}

-- Per-profile ore weights: who sells what, and how often
local oreWeights = {
	smith = {                                      -- forge workers: functional metals, no precious
		["t_ingmine_oreiron_01"]       = 30,       -- bread and butter
		["t_ingmine_coal_01"]          = 25,       -- always need fuel
		["t_ingmine_orecopper_01"]     = 12,       -- bronze fittings
		["t_ingmine_oreorichalcum_01"] = 15,       -- standard dunmer alloy
		["ingred_adamantium_ore_01"]   = 7,        -- rare commissions
		["ingred_raw_ebony_01"]        = 5,        -- prestigious, hard to source
		["ingred_raw_glass_01"]        = 4,        -- exotic, mostly telvanni work
		["t_ingmine_oresilver_01"]     = 0,        -- "go see a jeweler"
		["t_ingmine_oregold_01"]       = 0,
		["ingred_diamond_01"]          = 0,
	},
	miner = {                                      -- pulls it all from the earth
		["t_ingmine_oreiron_01"]       = 25,       -- most common vein
		["t_ingmine_coal_01"]          = 20,       -- everywhere underground
		["t_ingmine_orecopper_01"]     = 14,       -- common vein
		["t_ingmine_oreorichalcum_01"] = 10,       -- decent veins on vvardenfell
		["t_ingmine_oresilver_01"]     = 8,        -- rarer veins
		["t_ingmine_oregold_01"]       = 5,        -- occasionally strikes a vein
		["ingred_diamond_01"]          = 2,        -- rare find in deep rock
		["ingred_adamantium_ore_01"]   = 4,        -- deep excavation
		["ingred_raw_ebony_01"]        = 3,        -- imperial mining charter required
		["ingred_raw_glass_01"]        = 2,        -- volcanic, dangerous to extract
	},
	jewel = {                                      -- precious metals and gemstones
		["t_ingmine_oresilver_01"]     = 30,       -- primary working metal
		["t_ingmine_oregold_01"]       = 26,       -- high-end pieces
		["t_ingmine_orecopper_01"]     = 14,       -- alloy work, cheaper settings
		["ingred_diamond_01"]          = 8,        -- prized but hard to source
		["ingred_raw_glass_01"]        = 6,        -- decorative inlay
		["t_ingmine_oreiron_01"]       = 0,        -- beneath their trade
		["t_ingmine_coal_01"]          = 0,
		["t_ingmine_oreorichalcum_01"] = 0,
		["ingred_adamantium_ore_01"]   = 0,
		["ingred_raw_ebony_01"]        = 0,
	},
	alchemist = {                                  -- reagent value, not metalwork
		["ingred_raw_glass_01"]        = 25,       -- volcanic essence, prized reagent
		["ingred_raw_ebony_01"]        = 20,       -- deeply magical ore
		["ingred_adamantium_ore_01"]   = 14,       -- rare reagent
		["ingred_diamond_01"]          = 8,        -- potent but scarce
		["t_ingmine_oresilver_01"]     = 5,        -- minor catalytic use
		["t_ingmine_oregold_01"]       = 3,        -- trace reagent
		["t_ingmine_orecopper_01"]     = 2,        -- apparatus fittings
		["t_ingmine_oreiron_01"]       = 0,        -- no alchemical value
		["t_ingmine_coal_01"]          = 0,
		["t_ingmine_oreorichalcum_01"] = 0,
	},
	apothecary = {                                 -- lighter alchemist, local remedies
		["ingred_raw_glass_01"]        = 16,       -- fire salts substitute
		["ingred_raw_ebony_01"]        = 10,       -- expensive, keeps small stock
		["ingred_adamantium_ore_01"]   = 6,
		["ingred_diamond_01"]          = 4,        -- ground for poultices, rarely in stock
		["t_ingmine_oresilver_01"]     = 4,        -- purification uses
		["t_ingmine_oregold_01"]       = 2,
		["t_ingmine_orecopper_01"]     = 2,
		["t_ingmine_oreiron_01"]       = 0,
		["t_ingmine_coal_01"]          = 0,
		["t_ingmine_oreorichalcum_01"] = 0,
	},
	trader = {                                     -- general goods, whatever moves
		["t_ingmine_oreiron_01"]       = 20,       -- always in demand
		["t_ingmine_coal_01"]          = 16,       -- steady seller
		["t_ingmine_orecopper_01"]     = 12,       -- decent margin
		["t_ingmine_oreorichalcum_01"] = 8,        -- niche but sells
		["t_ingmine_oresilver_01"]     = 8,        -- good markup
		["t_ingmine_oregold_01"]       = 6,        -- high value, slow turnover
		["ingred_adamantium_ore_01"]   = 4,        -- adventurers buy these
		["ingred_diamond_01"]          = 2,        -- too rare to stock reliably
		["ingred_raw_ebony_01"]        = 2,        -- too expensive to stock much
		["ingred_raw_glass_01"]        = 2,
	},
	merchant = {                                   -- similar to trader, slightly broader
		["t_ingmine_oreiron_01"]       = 18,
		["t_ingmine_coal_01"]          = 14,
		["t_ingmine_orecopper_01"]     = 12,
		["t_ingmine_oresilver_01"]     = 10,       -- more precious metal than traders
		["t_ingmine_oreorichalcum_01"] = 8,
		["t_ingmine_oregold_01"]       = 7,
		["ingred_adamantium_ore_01"]   = 4,
		["ingred_diamond_01"]          = 2,        -- occasional curiosity
		["ingred_raw_ebony_01"]        = 2,
		["ingred_raw_glass_01"]        = 2,
	},
	broker = {                                     -- pawnbroker: whatever people hock
		["t_ingmine_oresilver_01"]     = 14,       -- people pawn precious things
		["t_ingmine_oregold_01"]       = 12,
		["t_ingmine_oreiron_01"]       = 10,       -- miners selling off stock
		["t_ingmine_coal_01"]          = 8,
		["t_ingmine_orecopper_01"]     = 8,
		["t_ingmine_oreorichalcum_01"] = 6,
		["ingred_diamond_01"]          = 4,        -- pawned heirloom, once in a while
		["ingred_adamantium_ore_01"]   = 4,        -- the occasional desperate adventurer
		["ingred_raw_ebony_01"]        = 3,
		["ingred_raw_glass_01"]        = 2,
	},
}


-- Build ore table + validate
local oreTable = {}
local oreRepairSet = {}
local oreIngredSet = {}
local toConvert = {}

local db_difficulties = {
	["t_ingmine_oreiron_01"]       = 15,
	["t_ingmine_coal_01"]          = 22,
	["t_ingmine_oresilver_01"]     = 31,
	["t_ingmine_orecopper_01"]     = 35,
	["t_ingmine_oregold_01"]       = 38,
	["ingred_diamond_01"]          = 40,
	["t_ingmine_oreorichalcum_01"] = 50,
	["ingred_adamantium_ore_01"]   = 65,
	["ingred_raw_ebony_01"]        = 73,
	["ingred_raw_glass_01"]        = 73,
}

for ingredId, difficulty in pairs(db_difficulties) do
	local repairId = "sm_" .. ingredId
	local hasRepair = types.Repair.records[repairId]
	local hasIngred = types.Ingredient.records[ingredId]

	if not hasIngred then
		print("[SM_Restock] WARNING: unknown ingred: " .. ingredId)
	elseif not hasRepair then
		print("[SM_Restock] WARNING: unknown repair: " .. repairId)
	else
		table.insert(oreTable, {
			repairId   = repairId,
			ingredId   = ingredId,
			difficulty = difficulty,
		})
		oreRepairSet[repairId] = ingredId
		oreIngredSet[ingredId] = true
		toConvert[repairId]    = ingredId
	end
end


-- Skill gate: asymmetric curve centered on player skill
-- Below skill: gentle linear fade (outgrown ores linger)
-- Above skill: steep cubic dropoff (hard to get, disappearing fast)
-- 23+ above: flat 1% floor (tiny lucky-find chance)
local function skillFactor(playerSkill, oreDifficulty)
	local gap = oreDifficulty - playerSkill
	if gap > 23 then
		return 0.01
	elseif gap > 0 then
		return 0.01 + (1 - gap / 23) ^ 2
	else
		return math.max(0.35, 1 + gap / 60)
	end
end


local function activateNPC_ores(npc, player)
	if #oreTable == 0 then return end
	if not S_RESTOCK_ORES then return end

	local record = types.NPC.record(npc.recordId)
	local className = record.class:lower()

	if types.Actor.isDead(npc) then
		saveData.oreNPCs[npc.id] = nil
		return
	end

	local profile
	for _, p in ipairs(oreProfiles) do
		if className:find(p.pattern) then
			profile = p
			break
		end
	end
	if not profile then return end

	local weights = oreWeights[profile.pattern]
	if not weights then return end

	local useIngredient = record.servicesOffered["Ingredients"]
	local useRepair     = record.servicesOffered["RepairItem"]
	if not useIngredient and not useRepair then return end

	local now = world.getGameTime() / (24 * 60 * 60)

	if not saveData.oreNPCs[npc.id] then
		saveData.oreNPCs[npc.id] = {
			lastRestock  = now - math.random(),
			initialized  = false,
		}
	end

	local npcData = saveData.oreNPCs[npc.id]
	local daysSinceRestock = now - npcData.lastRestock

	if daysSinceRestock <= 0.01 then return end

	-- Count current ore stock across both item forms
	local currentStock = 0
	local inv = types.NPC.inventory(npc)
	for _, item in pairs(inv:getAll(types.Repair)) do
		if oreRepairSet[item.recordId] then
			currentStock = currentStock + item.count
		end
	end
	for _, item in pairs(inv:getAll(types.Ingredient)) do
		if oreIngredSet[item.recordId] then
			currentStock = currentStock + item.count
		end
	end

	local rate     = profile.restockPerDay * (S_RESTOCK_SPEED / 100)
	local maxStock = rate * S_RESTOCK_DAYS

	local toAdd = 0

	if not npcData.initialized then
		local rawToAdd = math.max(0, rate - currentStock)
		local fraction = rawToAdd % 1
		local bonus = (math.random() < fraction) and 1 or 0
		toAdd = math.floor(rawToAdd) + bonus
	elseif currentStock < maxStock then
		local cappedDays    = math.min(daysSinceRestock, 1.0)
		local restockAmount = cappedDays * rate
		local fraction      = restockAmount % 1
		local bonus         = (math.random() < fraction) and 1 or 0
		local rawToAdd      = math.floor(restockAmount) + bonus
		local headroom      = math.ceil(maxStock) - currentStock
		toAdd = math.min(rawToAdd, headroom)
	end

	if toAdd > 0 then
		local biasPower = S_RESTOCK_RARITY_BIAS / 100

		local playerSkill = 5
		if saveData.playerSkills[player.id] then
			playerSkill = saveData.playerSkills[player.id]
		end

		-- build weighted pool: base weight ^ biasPower * skill factor
		-- ores with base weight 0 are excluded entirely (profile doesn't stock them)
		local pool = {}
		local totalWeight = 0
		for j = 1, #oreTable do
			local ore = oreTable[j]
			local baseW = weights[ore.ingredId] or 0
			if baseW > 0 then
				local w = (baseW ^ biasPower) * skillFactor(playerSkill, ore.difficulty)
				totalWeight = totalWeight + w
				pool[#pool + 1] = { ore = ore, w = w }
			end
		end

		if totalWeight > 0 then
			for _ = 1, toAdd do
				local roll       = math.random() * totalWeight
				local cumulative = 0
				local ore        = pool[#pool].ore
				for j = 1, #pool do
					cumulative = cumulative + pool[j].w
					if roll <= cumulative then
						ore = pool[j].ore
						break
					end
				end
				local itemId = useIngredient and ore.ingredId or ore.repairId
				local tempItem = world.createObject(itemId, 1)
				tempItem:moveInto(inv)
			end
		end
	end

	npcData.initialized = true
	npcData.lastRestock = now
end

I.Activation.addHandlerForType(types.NPC, activateNPC_ores)


-- Convert sm_ repair ores in player inventory -> ingredient form
local function convertOres(player)
	local added = {}
	local removed = {}

	for _, item in pairs(types.NPC.inventory(player):getAll(types.Repair)) do
		local ingredId = oreRepairSet[item.recordId]
		if ingredId and item.count > 0 then
			removed[item.recordId] = (removed[item.recordId] or 0) + item.count
			added[ingredId] = (added[ingredId] or 0) + item.count

			local tempItem = world.createObject(ingredId, item.count)
			tempItem:moveInto(types.NPC.inventory(player))
			item:remove()
		end
	end

	if next(added) or next(removed) then
		player:sendEvent("PrettyLoot_ignoreChanges", { added = added, removed = removed })
	end
end

return convertOres