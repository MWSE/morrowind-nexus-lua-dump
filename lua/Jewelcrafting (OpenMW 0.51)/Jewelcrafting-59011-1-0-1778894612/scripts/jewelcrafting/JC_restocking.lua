-- merchant restocking wildcards + pliers, insight buff for better scrolls
local insightAvailable = core.magic.effects.records["t_mysticism_insight"]
local insightMult = 0.005

local byId = {}
local categories = {}
do
	local seen = {}
	for _, r in ipairs(require("scripts.jewelcrafting.recipes")) do
		local id = r.id:lower()
		local ud = r.userData
		byId[id] = { tier = ud.tier, kind = ud.kind }
		if ud.tier == "exq" then
			if type(r.disabled) == "string" and r.disabled:sub(1, 6) == "jc_rs_" then
				categories[#categories + 1] = {
					tier     = ud.tier,
					kind     = ud.kind,
					scrollId = r.disabled,
					recipe   = { id = id, nameOpt = r.nameOpt },
				}
			end
		else
			local key = ud.tier .. "_" .. ud.kind
			if not seen[key] then
				seen[key] = true
				categories[#categories + 1] = {
					tier     = ud.tier,
					kind     = ud.kind,
					scrollId = "jc_rs_" .. ud.tier .. "_" .. ud.kind .. "_wild",
					recipe   = nil,
				}
			end
		end
	end
end

local BOOK_PATTERNS = {
	"trader", "merchant", "pawnbroker", "bookseller",
	"t_glb_bookseller", "trader service", "t_glb_trader", "t_glb_traderservice",
}
local BOOK_SERVICE    = "Books"
local MAX_STOCK       = 2
local RESTOCK_PER_DAY = 0.5
local START_STOCK     = 1

local PLIERS_ID       = "jc_pliers_common"
local PLIERS_SERVICE  = "Misc"
local PLIERS_PATTERNS = {
	"trader", "merchant", "pawnbroker",
	"trader service", "t_glb_trader", "t_glb_traderservice",
}

local function tierWeights(skill)
	local t = math.max(0, math.min(1, (skill - 5) / 95))
	return {
		com = 1.0 - 0.9 * t,
		exp = 0.4 + 0.4 * t,
		ext = 0.1 + 0.7 * t,
		exq = math.min(0.07, -0.2 + 0.5 * t),
	}
end

local function classMatches(record, patterns)
	local className = record.class:lower()
	for _, pat in ipairs(patterns) do
		if className:find(pat) then return true end
	end
	return false
end

------------------------------ candidate pool ------------------------------

-- a scroll can only be sold when +tier weight and unknown
local function buildCandidates(player, playerInv, npcInv)
	local known = saveData.unlockedRecipes[player.id] or {}
	saveData.unlockedRecipes[player.id] = known
	local weights = tierWeights(saveData.playerSkill[player.id] or 5)
	
	-- unknown wildcard recipe
	local bucketLive = {}
	for id, r in pairs(byId) do
		if r.tier ~= "exq" and not known[id] then
			bucketLive[r.tier .. "_" .. r.kind] = true
		end
	end
	
	-- scrolls in inventory
	local owned = {}
	for _, item in pairs(playerInv:getAll(types.Book)) do owned[item.recordId:lower()] = true end
	for _, item in pairs(npcInv:getAll(types.Book))    do owned[item.recordId:lower()] = true end
	
	local pool = {}
	for _, c in ipairs(categories) do
		local w = weights[c.tier]
		if w and w > 0 and not owned[c.scrollId] then
			local live
			if c.recipe then
				live = not known[c.recipe.id]
			else
				live = bucketLive[c.tier .. "_" .. c.kind] == true
			end
			if live then pool[#pool + 1] = { id = c.scrollId, weight = w } end
		end
	end
	return pool
end

local function weightedPick(pool)
	local total = 0
	for _, p in ipairs(pool) do total = total + p.weight end
	if total <= 0 then return nil end
	local roll = math.random() * total
	local acc  = 0
	for _, p in ipairs(pool) do
		acc = acc + p.weight
		if roll <= acc then return p.id end
	end
end

------------------------------ booksellers ------------------------------

local function restockBookseller(npc, player)
	local TM = G_testBoost and 10 or 1
	if types.Actor.isDead(npc) then
		saveData.restockingNPCs[npc.id] = nil
		return
	end
	local record = types.NPC.record(npc.recordId)
	if not record.servicesOffered[BOOK_SERVICE] then return end
	if not classMatches(record, BOOK_PATTERNS) then return end
	
	local now  = world.getGameTime() / (24 * 60 * 60)
	local data = saveData.restockingNPCs[npc.id]
	if not data then
		data = { lastRestock = now, initialized = false }
		saveData.restockingNPCs[npc.id] = data
	end
	
	local insightMag = insightAvailable and types.Actor.activeEffects(player):getEffect("t_mysticism_insight").magnitude * insightMult or 0
	local insightBuff = 1 + insightMag * 1.0
	
	local toAdd
	if not data.initialized then
		toAdd = START_STOCK * TM
	else
		local amount = math.min(now - data.lastRestock, 1.0) * RESTOCK_PER_DAY * TM * insightBuff
		toAdd = math.floor(amount)
		if math.random() < (amount % 1) then toAdd = toAdd + 1 end
		toAdd = math.min(toAdd, math.ceil(MAX_STOCK * TM * insightBuff))
	end
	
	if toAdd > 0 then
		local npcInv    = types.NPC.inventory(npc)
		local playerInv = types.Actor.inventory(player)
		for _ = 1, toAdd do
			local pool = buildCandidates(player, playerInv, npcInv)
			local id   = weightedPick(pool)
			if not id then break end
			world.createObject(id, 1):moveInto(npcInv)
		end
	end
	
	data.initialized = true
	data.lastRestock = now
end

------------------------------ misc traders ------------------------------

local function stockPliersIfMisc(npc)
	local record = types.NPC.record(npc.recordId)
	if not record.servicesOffered[PLIERS_SERVICE] then return end
	if not classMatches(record, PLIERS_PATTERNS) then return end
	
	local inv = types.NPC.inventory(npc)
	for _, item in pairs(inv:getAll(types.Miscellaneous)) do
		if item.recordId == PLIERS_ID then return end
	end
	world.createObject(PLIERS_ID, 1):moveInto(inv)
end

I.Activation.addHandlerForType(types.NPC, function(npc, player)
	restockBookseller(npc, player)
	stockPliersIfMisc(npc)
end)