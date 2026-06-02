local byId = {}
local relevantBooks = {}
local relevantQuests = {}
local relevantSkillThresholds = {}
for _, r in ipairs(require("scripts.jewelcrafting.recipes")) do
	byId[r.id:lower()] = { disabled = r.disabled, nameOpt = r.nameOpt }
	if type(r.disabled) == "string" and r.disabled:find(":", 1, true) then
		for atom in (r.disabled .. "|"):gmatch("([^|&]+)[|&]") do
			local kind, rest = atom:match("^(%a+):(.+)$")
			if kind == "read" then
				relevantBooks[rest:lower()] = true
			elseif kind == "journal" then
				local id = rest:match("^(.-)>=") or rest
				relevantQuests[id:lower()] = true
			elseif kind == "skill" then
				local thr = tonumber(rest:match(">=(%d+)$"))
				if thr then relevantSkillThresholds[thr] = true end
			end
		end
	end
end

G_onLoadJobs.unlocking = function()
	saveData.unlockedRecipes = saveData.unlockedRecipes or {}
end

------------------------------ unlock ------------------------------

local function applyUnlock(recipeId)
	I.CraftingFramework.discoverRecipe(recipeId, "discovery")
	local r = byId[recipeId]
	if r and type(r.disabled) == "string" then
		I.CraftingFramework.enableRecipe(recipeId, r.disabled)
	end
end

local function markUnlocked(recipeId)
	if saveData.unlockedRecipes[recipeId] then return end
	saveData.unlockedRecipes[recipeId] = true
	applyUnlock(recipeId)
	core.sendGlobalEvent("Jewelcrafting_syncUnlock", { player = self, recipe = recipeId })
	local r = byId[recipeId]
	ui.showMessage("You have learned how to craft: " .. (r and r.nameOpt or recipeId))
end

------------------------------ parser ------------------------------

-- journal:<id>[>=n], skill:<name>>=n, read:<id>
local function evalAtom(atom, ctx)
	local kind, rest = atom:match("^(%a+):(.+)$")
	if not kind then return false end
	if kind == "journal" then
		local id, threshold = rest:match("^(.-)>=(%d+)$")
		local n = tonumber(threshold) or 1
		id = (id or rest):lower()
		local q = types.Player.quests(self)[id]
		local stage = (q and q.started) and q.stage or 0
		return stage >= n
	elseif kind == "skill" then
		local _, threshold = rest:match("^(.-)>=(%d+)$")
		local n = tonumber(threshold)
		if not n then return false end
		return G_skillStat ~= nil and G_skillStat.base >= n
	elseif kind == "read" then
		return ctx.readBook == rest:lower()
	end
	return false
end

-- OR split on | // AND split on &
local function evalExpression(expr, ctx)
	for clause in (expr .. "|"):gmatch("([^|]+)|") do
		local ok = true
		for atom in (clause .. "&"):gmatch("([^&]+)&") do
			if not evalAtom(atom, ctx) then ok = false; break end
		end
		if ok then return true end
	end
	return false
end

local function runParserPass(ctx)
	for id, r in pairs(byId) do
		if not saveData.unlockedRecipes[id]
		and type(r.disabled) == "string"
		and evalExpression(r.disabled, ctx) then
			markUnlocked(id)
		end
	end
end

------------------------------ reader ------------------------------

G_eventHandlers.UiModeChanged = function(data)
	if data.newMode ~= "Scroll" and data.newMode ~= "Book" then return end
	if not data.arg then return end
	local bookId = data.arg.recordId:lower()
	if bookId:sub(1, 6) == "jc_rs_" then
		local tag = bookId:sub(-5) == "_wild" and bookId:sub(1, -6) or bookId
		local pool = {}
		for id, r in pairs(byId) do
			if r.disabled == tag and not saveData.unlockedRecipes[id] then
				pool[#pool + 1] = id
			end
		end
		if #pool > 0 then
			local pick = pool[math.random(#pool)]
			core.sendGlobalEvent("Jewelcrafting_removeItem", { self, data.arg, 1 })
			markUnlocked(pick)
		else
			ui.showMessage("You already know every recipe from this scroll.")
		end
		return
	end
	if relevantBooks[bookId] then
		runParserPass({ readBook = bookId })
	end
end

G_engineHandlers.onQuestUpdate = function(questId)
	if relevantQuests[questId:lower()] then runParserPass({}) end
end

------------------------------ on load ------------------------------

table.insert(G_onActiveJobs, function()
	if not I.CraftingFramework then return end
	for id in pairs(saveData.unlockedRecipes) do
		applyUnlock(id)
	end
	-- skill-change recompute from SF
	if I.SkillFramework then
		local prevBase = G_skillStat and G_skillStat.base or 0
		I.SkillFramework.addSkillStatChangedHandler(function(skillId)
			if skillId ~= G_skillId then return end
			local newBase = G_skillStat and G_skillStat.base or 0
			local fire = false
			for thr in pairs(relevantSkillThresholds) do
				if prevBase < thr and newBase >= thr then fire = true; break end
			end
			prevBase = newBase
			if fire then runParserPass({}) end
		end)
	end
	runParserPass({})
end)