-- crafting search engine. compiles a query into clauses and matches recipes;
-- each recipe caches two strings: union haystack (_sf_hay) + classifier (_sf_cls).

local M = {}

local FIELD_ALIASES = {
	name = "name",
	id = "id",
	cat = "category",
	category = "category",
	skill = "skill",
	prof = "profession",
	profession = "profession",
	type = "type",
	ing = "ingredient",
	ingredient = "ingredient",
	ingredients = "ingredient",
	faction = "faction",
	level = "level",
	lvl = "level",
	class = "classifier",
}

-- -------------------------------------------------- tokenizer --------------------------------------------------

-- splits into tokens; honors "quoted phrases" and -"negated quoted".
local function tokenize(text)
	local tokens = {}
	local i, n = 1, #text
	while i <= n do
		local c = text:sub(i, i)
		if c == " " or c == "\t" then
			i = i + 1
		elseif c == '"' then
			local j = text:find('"', i + 1, true) or (n + 1)
			tokens[#tokens + 1] = text:sub(i + 1, j - 1)
			i = j + 1
		elseif c == "-" and text:sub(i + 1, i + 1) == '"' then
			local j = text:find('"', i + 2, true) or (n + 1)
			tokens[#tokens + 1] = "-" .. text:sub(i + 2, j - 1)
			i = j + 1
		else
			local j = text:find("[%s]", i) or (n + 1)
			tokens[#tokens + 1] = text:sub(i, j - 1)
			i = j
		end
	end
	return tokens
end

-- -------------------------------------------------- clause parser --------------------------------------------------

-- numeric op forms for level: <N, <=N, >N, >=N, =N, N, A-B
local function parseLevelClause(rest)
	local op, num = rest:match("^(<=)(%-?%d+)$")
	if not op then op, num = rest:match("^(>=)(%-?%d+)$") end
	if not op then op, num = rest:match("^(<)(%-?%d+)$") end
	if not op then op, num = rest:match("^(>)(%-?%d+)$") end
	if op then
		return { field = "level", op = op, value = tonumber(num) }
	end
	local a, b = rest:match("^(%-?%d+)%s*%-%s*(%-?%d+)$")
	if a and b then
		return { field = "level", op = "range", value = tonumber(a), valueHi = tonumber(b) }
	end
	local v = tonumber(rest:match("^=?(%-?%d+)$") or "")
	if v then
		return { field = "level", op = "eq", value = v }
	end
	return nil
end

-- token -> clause { neg, field, value [, op, valueHi] }. bare = no field.
local function parseToken(tok)
	if tok == "" then return nil end
	local neg = false
	if tok:sub(1, 1) == "-" and #tok > 1 then
		neg = true
		tok = tok:sub(2)
	end
	local field, rest = tok:match("^([%w]+):(.*)$")
	if field then
		field = FIELD_ALIASES[field:lower()]
	end
	if field == "level" then
		local c = parseLevelClause(rest)
		if c then
			c.neg = neg
			return c
		end
		-- malformed level: fall through to text search of the whole token
		return { neg = neg, value = tok:lower() }
	end
	if field then
		if rest == "" then return nil end
		return { neg = neg, field = field, value = rest:lower() }
	end
	return { neg = neg, value = tok:lower() }
end

-- -------------------------------------------------- ingredient haystack --------------------------------------------------

local function ingredientHay(recipe)
	local list = recipe.ingredients
	if not list or #list == 0 then return "" end
	local parts = {}
	for _, e in ipairs(list) do
		parts[#parts + 1] = (e.name or e.id or ""):lower()
	end
	return table.concat(parts, " ")
end

-- -------------------------------------------------- classifier (lazy) --------------------------------------------------

-- per-slot reference weight gmst. mirrors ui_descriptionTooltip getArmorData
-- (~L387): light if w <= ref*fLightMaxMod, medium if <= ref*fMedMaxMod.
local ARMOR_WEIGHT_GMST
local function armorWeightGmst()
	if ARMOR_WEIGHT_GMST then return ARMOR_WEIGHT_GMST end
	local T = types.Armor.TYPE
	ARMOR_WEIGHT_GMST = {
		[T.Helmet]    = "iHelmWeight",
		[T.Cuirass]   = "iCuirassWeight",
		[T.LPauldron] = "iPauldronWeight",
		[T.RPauldron] = "iPauldronWeight",
		[T.Greaves]   = "iGreavesWeight",
		[T.Boots]     = "iBootsWeight",
		[T.LGauntlet] = "iGauntletWeight",
		[T.RGauntlet] = "iGauntletWeight",
		[T.Shield]    = "iShieldWeight",
		[T.LBracer]   = "iGauntletWeight",
		[T.RBracer]   = "iGauntletWeight",
	}
	return ARMOR_WEIGHT_GMST
end

local gmstCache = {}
local function gmst(name)
	local v = gmstCache[name]
	if v == nil then
		v = core.getGMST(name) or 0
		gmstCache[name] = v
	end
	return v
end

local ARMOR_EPSILON = 5e-4

-- inverse maps: enum int -> lowercased name (record.type is the int value).
local WEAPON_TYPE_NAME
local function weaponTypeName(t)
	if not WEAPON_TYPE_NAME then
		WEAPON_TYPE_NAME = {}
		for name, val in pairs(types.Weapon.TYPE) do
			WEAPON_TYPE_NAME[val] = name:lower()
		end
	end
	return WEAPON_TYPE_NAME[t] or ""
end

local ARMOR_TYPE_NAME
local function armorTypeName(t)
	if not ARMOR_TYPE_NAME then
		ARMOR_TYPE_NAME = {}
		for name, val in pairs(types.Armor.TYPE) do
			ARMOR_TYPE_NAME[val] = name:lower()
		end
	end
	return ARMOR_TYPE_NAME[t] or ""
end

-- per-type alias strings on the classifier. category-level synonyms only;
-- item-shape names (katana, warhammer) live in the recipe id/name.
local WEAPON_TYPE_ALIASES
local function weaponTypeAliases(t)
	if not WEAPON_TYPE_ALIASES then
		local W = types.Weapon.TYPE
		WEAPON_TYPE_ALIASES = {
			[W.ShortBladeOneHand] = "dagger knife 1h melee",
			[W.LongBladeOneHand]  = "sword 1h melee",
			[W.LongBladeTwoHand]  = "sword 2h melee",
			[W.BluntOneHand]      = "hammer mace 1h melee",
			[W.BluntTwoClose]     = "hammer mace 2h melee",
			[W.BluntTwoWide]      = "staff 2h melee",
			[W.AxeOneHand]        = "onehand 1h melee",
			[W.AxeTwoHand]        = "twohand 2h melee",
			[W.SpearTwoWide]      = "polearm 2h melee",
			[W.MarksmanBow]       = "ranged",
			[W.MarksmanCrossbow]  = "ranged",
			[W.MarksmanThrown]    = "throwing ranged",
			[W.Arrow]             = "arrows ammo ammunition ranged",
			[W.Bolt]              = "bolts ammo ammunition ranged",
		}
	end
	return WEAPON_TYPE_ALIASES[t] or ""
end

local ARMOR_TYPE_ALIASES
local function armorTypeAliases(t)
	if not ARMOR_TYPE_ALIASES then
		local A = types.Armor.TYPE
		ARMOR_TYPE_ALIASES = {
			[A.Helmet]    = "helm helmets head armour",
			[A.Cuirass]   = "chest torso breast armour",
			[A.Greaves]   = "legs leg armour",
			[A.Boots]     = "feet shoe shoes armour",
			[A.LPauldron] = "shoulder pauldrons armour",
			[A.RPauldron] = "shoulder pauldrons armour",
			[A.LGauntlet] = "glove gloves gauntlets hands armour",
			[A.RGauntlet] = "glove gloves gauntlets hands armour",
			[A.LBracer]   = "wrist bracers armour hands",
			[A.RBracer]   = "wrist bracers armour hands",
			[A.Shield]    = "shields armour",
		}
	end
	return ARMOR_TYPE_ALIASES[t] or ""
end

-- classifier blob: weapon/armor TYPE + weight class. "" for non-equippable.
local function buildClassifier(recipe)
	if recipe.type == "Weapon" then
		local ok, rec = pcall(types.Weapon.record, recipe.id)
		if not ok or not rec or rec.type == nil then return "" end
		return weaponTypeName(rec.type) .. " " .. weaponTypeAliases(rec.type)
	elseif recipe.type == "Armor" then
		local ok, rec = pcall(types.Armor.record, recipe.id)
		if not ok or not rec or rec.type == nil then return "" end
		local typeStr = armorTypeName(rec.type) .. " " .. armorTypeAliases(rec.type)
		local w = rec.weight or 0
		local cls
		if w == 0 then
			cls = "unarmored"
		else
			local g = armorWeightGmst()[rec.type]
			local refWeight = g and gmst(g) or 0
			if refWeight <= 0 then
				cls = ""
			elseif w <= refWeight * gmst("fLightMaxMod") + ARMOR_EPSILON then
				cls = "light lightarmor"
			elseif w <= refWeight * gmst("fMedMaxMod") + ARMOR_EPSILON then
				cls = "medium mediumarmor"
			else
				cls = "heavy heavyarmor"
			end
		end
		return typeStr .. " " .. cls
	end
	return ""
end

-- -------------------------------------------------- per-recipe haystacks --------------------------------------------------

-- union haystack: name + id + category + type + skill (no armorer) + faction.
local function getHay(recipe, categoryName)
	local hay = recipe._sf_hay
	if hay then return hay end
	-- armorer is in nearly every recipe -> too noisy as a bare token
	local s1 = (recipe.skill or ""):lower()
	local s2 = (recipe.secondSkill or ""):lower()
	if s1 == "armorer" then s1 = "" end
	if s2 == "armorer" then s2 = "" end
	hay = table.concat({
		(recipe.displayName or ""):lower(),
		recipe.id or "",
		(categoryName or ""):lower(),
		(recipe.type or ""):lower(),
		s1 .. " " .. s2,
		(recipe.faction or ""):lower(),
	}, " ")
	recipe._sf_hay = hay
	return hay
end

-- classifier blob, cached on recipe. "" = computed but non-equippable.
local function getClassifier(recipe)
	local c = recipe._sf_cls
	if c ~= nil then return c end
	c = buildClassifier(recipe)
	recipe._sf_cls = c
	return c
end

-- single-field haystack on the fly for field-qualified clauses (uncached).
local function getField(recipe, categoryName, field)
	if field == "name" then return (recipe.displayName or ""):lower() end
	if field == "id" then return recipe.id or "" end
	if field == "category" then return (categoryName or ""):lower() end
	if field == "profession" then return (recipe.profession or ""):lower() end
	if field == "type" then return (recipe.type or ""):lower() end
	if field == "skill" then
		return ((recipe.skill or "") .. " " .. (recipe.secondSkill or "")):lower()
	end
	if field == "faction" then return (recipe.faction or ""):lower() end
	if field == "ingredient" then return ingredientHay(recipe) end
	return ""
end

-- -------------------------------------------------- match --------------------------------------------------

local function matchLevel(clause, lv)
	local op = clause.op
	if op == "eq" then return lv == clause.value end
	if op == "<"  then return lv <  clause.value end
	if op == "<=" then return lv <= clause.value end
	if op == ">"  then return lv >  clause.value end
	if op == ">=" then return lv >= clause.value end
	if op == "range" then return lv >= clause.value and lv <= clause.valueHi end
	return false
end

local function clauseMatches(clause, recipe, categoryName, hay, cls)
	if clause.field == "level" then
		return matchLevel(clause, recipe.level or 0)
	end
	if clause.field == "classifier" then
		return cls ~= "" and cls:find(clause.value, 1, true) ~= nil
	end
	if not clause.field then
		-- bare token: union haystack, then classifier
		if hay:find(clause.value, 1, true) then return true end
		if cls ~= "" and cls:find(clause.value, 1, true) then return true end
		return false
	end
	-- other field-qualified: recompute that field's haystack inline
	local s = getField(recipe, categoryName, clause.field)
	if s == "" then return false end
	return s:find(clause.value, 1, true) ~= nil
end

-- -------------------------------------------------- public api --------------------------------------------------

-- nil = empty query
function M.parse(text)
	if not text or text == "" then return nil end
	local clauses = {}
	for _, tok in ipairs(tokenize(text)) do
		local c = parseToken(tok)
		if c then
			clauses[#clauses + 1] = c
		end
	end
	if #clauses == 0 then return nil end
	return { clauses = clauses }
end

-- true if recipe satisfies every clause (negation respected). nil query = all.
function M.matches(recipe, categoryName, query)
	if not query then return true end
	local hay = getHay(recipe, categoryName)
	local cls = getClassifier(recipe)
	for _, clause in ipairs(query.clauses) do
		local hit = clauseMatches(clause, recipe, categoryName, hay, cls)
		if clause.neg then hit = not hit end
		if not hit then return false end
	end
	return true
end

-- exposed for invalidation; rarely needed in practice.
function M.clearCache(recipe)
	recipe._sf_hay = nil
	recipe._sf_cls = nil
end

return M
