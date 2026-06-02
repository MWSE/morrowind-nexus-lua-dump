-- gem rolls during mining, insight buff to gem find rate
local insightAvailable = core.magic.effects.records["t_mysticism_insight"]
local insightMult = 0.005

local accumulatedChance = 0

G_onLoadJobs.mining = function()
	saveData.nodeCooldowns = saveData.nodeCooldowns or {}
end

------------------------------ cursed gems (red mountain) ------------------------------

local cursedGemChance = 0.35
local cellRMCache = {} -- cellId -> bool, populated lazily by global

local cursedGems = {
	["amethyst"]		= "t_ingmine_amethystdae_01",
	["aquamarine"]		= "t_ingmine_aquamarinedae_01",
	["bloodstone"]		= "t_ingmine_bloodstonedae_01",
	["garnet"]			= "t_ingmine_garnetdae_01",
	["jet"]				= "t_ingmine_jetdae_01",
	["khajiiteye"]		= "t_ingmine_khajiiteyedae_01",
	["moonstone"]		= "t_ingmine_moonstonedae_01",
	["opal"]			= "t_ingmine_opaldae_01",
	["peridot"]			= "t_ingmine_peridotdae_01",
	["rockcrystal"]		= "t_ingmine_rockcrystaldae_01",
	["sapphire"]		= "t_ingmine_sapphiredae_01",
	["spinel"]			= "t_ingmine_spineldae_01",
	["tektite"]			= "t_ingmine_tektitedae_01",
	["turquoise"]		= "t_ingmine_turquoisedae_01",
}

G_eventHandlers.Jewelcrafting_updateInRM = function(data)
	cellRMCache[data[1]] = data[2]
end

------------------------------ gem roll ------------------------------

-- chanceMultiplier 0-1 (based on progress); returns list of gem ids (may be >1)
local function rollForGem(chanceMultiplier)
	local luck = types.Actor.stats.attributes.luck(self).modified
	local jcSkill = G_skillStat.modified
	local insightMag = insightAvailable and types.Actor.activeEffects(self):getEffect("t_mysticism_insight").magnitude * insightMult or 0
	local baseChance = (0.15 + luck * 0.001 + jcSkill * 0.003) * (1 + insightMag * 1.5)
	
	local currentChance = baseChance*chanceMultiplier + accumulatedChance ^ 2
	accumulatedChance = accumulatedChance + baseChance * chanceMultiplier
	if currentChance < 0.15 then return {} end
	
	local count = math.floor(currentChance + math.random())
	if count == 0 then return {} end
	accumulatedChance = 0

	-- insight nudges toward rarer gems
	local rareCut = 0.08 + jcSkill * 0.001 + insightMag * 0.04
	local uncommonCut = rareCut + 0.25
	local gems = {}
	for _ = 1, count do
		local tierRoll = math.random()
		local pool
		if tierRoll < rareCut and #G_gems.rare > 0 then
			pool = G_gems.rare
		elseif tierRoll < uncommonCut and #G_gems.uncommon > 0 then
			pool = G_gems.uncommon
		else
			pool = G_gems.common
		end
		if #pool == 0 then pool = G_gems.common end
		if #pool > 0 then gems[#gems + 1] = pool[math.random(#pool)] end
	end
	return gems
end

------------------------------ event handlers ------------------------------

-- { object, size, progressed, currentProgress, usedSkill, skillLevel, player }
G_eventHandlers.Jewelcrafting_gemMiningProgress = function(data)
	local progressed = data[3]
	if not progressed or progressed <= 0 then return end
	for i=1, 4 do
		I.SkillFramework.skillUsed(G_skillId, { skillGain = progressed * G_testBoost / 4 })
	end

	local gems = rollForGem(progressed * G_testBoost)
	if #gems > 0 then
		local cell = self.cell
		local inRM = false
		if cell then
			if cell.isExterior then
				inRM = cell.region == "red mountain region"
			elseif cellRMCache[cell.id] ~= nil then
				inRM = cellRMCache[cell.id]
			else
				core.sendGlobalEvent("Jewelcrafting_checkInRM", { self, cell.id })
			end
		end
		for _, gemId in ipairs(gems) do
			local cursedId
			if inRM and math.random() < cursedGemChance then
				local name = gemId:match("^t_ingmine_(.+)_01$")
				cursedId = name and cursedGems[name]
			end
			if cursedId then
				core.sendGlobalEvent("Jewelcrafting_spawnCursedGem", { self, cursedId })
				local record = types.Ingredient.records[cursedId]
				ui.showMessage("A cursed " .. (record and record.name or "gem") .. " falls at your feet...")
			else
				core.sendGlobalEvent("Jewelcrafting_giveGem", { self, gemId })
			end
		end
		for i=1, 4 do
			I.SkillFramework.skillUsed(G_skillId, { skillGain = G_skillStat.base * 0.1 / 4 })
		end
	end
end

-- cooldown
G_eventHandlers.Jewelcrafting_fallbackActivation = function(data)
	if G_hasSimplyMining then return end
	local object = data[1]
	if not object or not object:isValid() then return end
	local now  = core.getGameTime()
	local last = saveData.nodeCooldowns[object.id]
	if last and (now - last) < time.day / G_testBoost then return end
	saveData.nodeCooldowns[object.id] = now

	-- one activation = ~95% of a node
	local gems = rollForGem(0.95 * G_testBoost)
	if #gems > 0 then
		local cell = self.cell
		local inRM = false
		if cell then
			if cell.isExterior then
				inRM = cell.region == "red mountain region"
			elseif cellRMCache[cell.id] ~= nil then
				inRM = cellRMCache[cell.id]
			else
				core.sendGlobalEvent("Jewelcrafting_checkInRM", { self, cell.id })
			end
		end
		for _, gemId in ipairs(gems) do
			local cursedId
			if inRM and math.random() < cursedGemChance then
				local name = gemId:match("^t_ingmine_(.+)_01$")
				cursedId = name and cursedGems[name]
			end
			if cursedId then
				core.sendGlobalEvent("Jewelcrafting_spawnCursedGem", { self, cursedId })
				local record = types.Ingredient.records[cursedId]
				ui.showMessage("A suspicious " .. (record and record.name or "gem") .. " was added to your inventory when you suddenly hear a noise.")
			else
				core.sendGlobalEvent("Jewelcrafting_giveGem", { self, gemId })
			end
		end
		for i=1, 4 do
			I.SkillFramework.skillUsed(G_skillId, { skillGain = 0.05 / 4})
		end
	end
end

G_eventHandlers.Jewelcrafting_notifyGemFound = function(data)
	ui.showMessage("You found " .. (data[1] or "a gem") .. " while mining!")
end

--[[
Ingredient	T_IngMine_AmberDae_01	Amber
Ingredient	T_IngMine_DiamondDeTomb_01	Diamond
Ingredient	T_IngMine_EmeraldDeTomb_01	Emerald
Ingredient	T_IngMine_OreGoldDae_01	Gold Ore
Ingredient	T_IngMine_PearlBlackDae_01	Black Pearl
Ingredient	T_IngMine_PearlBlueDae_01	Blue Pearl
Ingredient	T_IngMine_PearlDeTomb_01	Pearl
Ingredient	T_IngMine_PearlPinkDae_01	Pink Pearl
Ingredient	T_IngMine_RubyDeTomb_01	Ruby]]