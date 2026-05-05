-- bound item record factory
-- creates and caches bound records per base and per conjuration bucket,
-- optionally rescaling weight, damage, armor and enchantments
local world  = require('openmw.world')
local types  = require('openmw.types')
local core   = require('openmw.core')

local trData = require('scripts.tr_spells.trData')
require('scripts.tr_spells.SETTINGS')

local M = {}

-- shape: cache[baseId][bucket] = { recordIds = {...}, nextIndex = N }
local cache = nil

-- bucketed so we don't mint a record per skill point
local BOUND_SCALING_BUCKET_SIZE = 5

------------------------- INIT -------------------------

function M.init(saveDataCacheTable)
	cache = saveDataCacheTable
end

------------------------- SCALING -------------------------

-- bucket 0 also covers disabled scaling and non-actor callers
local function getSkillBucket(actor)
	if not BOUND_SCALING_ENABLED then return 0 end
	if not actor or not actor:isValid() then return 0 end
	if actor.type ~= types.NPC and actor.type ~= types.Player then return 0 end
	local skill = types.NPC.stats.skills.conjuration(actor).modified
	if not skill then return 0 end
	local size = BOUND_SCALING_BUCKET_SIZE or 5
	if size < 1 then size = 1 end
	return math.floor(math.floor(skill) / size) * size
end

local function buildScaledEnchantment(srcId, mult)
	local src = core.magic.enchantments.records[srcId]
	if not src then return srcId end
	local effects = {}
	for i, eff in ipairs(src.effects) do
		effects[i] = {
			id = eff.id,
			range = eff.range,
			area = eff.area,
			duration = eff.duration,
			magnitudeMin = math.max(1, math.floor((eff.magnitudeMin or 0) * mult + 0.5)),
			magnitudeMax = math.max(1, math.floor((eff.magnitudeMax or 0) * mult + 0.5)),
			affectedSkill = eff.affectedSkill,
			affectedAttribute = eff.affectedAttribute,
		}
	end
	local draft = core.magic.enchantments.createRecordDraft({
		type       = src.type,
		charge     = src.charge,
		cost       = src.cost,
		isAutocalc = src.isAutocalc,
		effects    = effects,
	})
	local newRec = world.createRecord(draft)
	return newRec.id
end

------------------------- RECORD BUILDING -------------------------

-- type lookup
local function resolveRecord(baseId)
	local rec = types.Armor.records[baseId]
	if rec then return types.Armor, rec end
	rec = types.Weapon.records[baseId]
	if rec then return types.Weapon, rec end
	rec = types.Clothing.records[baseId]
	if rec then return types.Clothing, rec end
	rec = types.Miscellaneous.records[baseId]
	if rec then return types.Miscellaneous, rec end
	return nil, nil
end

-- stats scale as base% + bonus% * bucketSkill
local function buildOverrides(baseId, rec, recType, bucketSkill)
	local tbl = { template = rec }

	local baseWeight = trData.BOUND_BASE_WEIGHTS[baseId] * (BOUND_WEIGHT_BASE or 100) / 100
	if baseWeight then
		local reduction = (BOUND_WEIGHT_REDUCTION_PER_LEVEL or 0) * bucketSkill / 100
		tbl.weight = math.max(0, baseWeight * (1 - reduction))
	end

	if recType == types.Weapon then
		local mult = (BOUND_DAMAGE_BASE or 100) / 100
			+ (BOUND_DAMAGE_BONUS_PER_LEVEL or 0) * bucketSkill / 100
		if mult ~= 1 then
			local function scale(v) return v and math.floor(v * mult + 0.5) or v end
			tbl.chopMinDamage   = scale(rec.chopMinDamage)
			tbl.chopMaxDamage   = scale(rec.chopMaxDamage)
			tbl.slashMinDamage  = scale(rec.slashMinDamage)
			tbl.slashMaxDamage  = scale(rec.slashMaxDamage)
			tbl.thrustMinDamage = scale(rec.thrustMinDamage)
			tbl.thrustMaxDamage = scale(rec.thrustMaxDamage)
		end
	elseif recType == types.Armor then
		local mult = (BOUND_ARMOR_BASE or 100) / 100
			+ (BOUND_ARMOR_BONUS_PER_LEVEL or 0) * bucketSkill / 100
		if mult ~= 1 and rec.baseArmor then
			tbl.baseArmor = math.floor(rec.baseArmor * mult + 0.5)
		end
	end

	if rec.enchant and rec.enchant ~= "" then
		local mult = (BOUND_ENCHANT_BASE or 100) / 100
			+ (BOUND_ENCHANT_BONUS_PER_LEVEL or 0) * bucketSkill / 100
		if mult ~= 1 then
			tbl.enchant = buildScaledEnchantment(rec.enchant, mult)
		end
	end

	return tbl
end

local function buildDraft(baseId, bucketSkill)
	local recType, rec = resolveRecord(baseId)
	if not rec then return nil, nil end

	local tbl
	if BOUND_SCALING_ENABLED then
		tbl = buildOverrides(baseId, rec, recType, bucketSkill or 0)
	else
		tbl = { template = rec }
	end

	return recType, recType.createRecordDraft(tbl)
end

------------------------- PUBLIC API -------------------------

-- cap of 2 per bucket prevents re-summons from colliding on a still-equipped copy
function M.resolve(actor, baseRecordId)
	if not cache then
		error("boundRecords.resolve called before init")
	end

	local bucket = getSkillBucket(actor)
	local perBase = cache[baseRecordId]
	if not perBase then
		perBase = {}
		cache[baseRecordId] = perBase
	end
	local entry = perBase[bucket]
	if not entry then
		entry = { recordIds = {}, nextIndex = 1 }
		perBase[bucket] = entry
	end

	local inv = types.Actor.inventory(actor)
	local function inInventory(recId)
		local found = inv:find(recId)
		return found and found:isValid()
	end

	-- recycle
	for _, recId in ipairs(entry.recordIds) do
		if not inInventory(recId) then
			return recId
		end
	end

	-- mint
	if #entry.recordIds < 2 then
		local _, draft = buildDraft(baseRecordId, bucket)
		if not draft then
			return baseRecordId
		end
		local newRec = world.createRecord(draft)
		entry.recordIds[#entry.recordIds + 1] = newRec.id
		return newRec.id
	end

	-- rotate
	local idx = entry.nextIndex
	entry.nextIndex = (idx % #entry.recordIds) + 1
	return entry.recordIds[idx]
end

function M.collectKnownRecordIds()
	local set = {}
	if not cache then return set end
	for _, perBase in pairs(cache) do
		for _, entry in pairs(perBase) do
			for _, recId in ipairs(entry.recordIds) do
				set[recId] = true
			end
		end
	end
	return set
end

return M