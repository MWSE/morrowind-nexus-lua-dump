MODNAME = "CraftingFramework"
world = require('openmw.world')

local I = require('openmw.interfaces')
types = require('openmw.types')
local core = require('openmw.core')
local vfs = require('openmw.vfs')

local f = vfs.open("scripts/CraftingFramework/api_version.txt")
VERSION = tonumber(f:read("*all"))
f:close()

-- temporary for legacy simply mining
local legacyPreserveIds = {
	["t_de_ebony_pickaxe_01"] = true,
	["bm nordic pick"] = true,
	["miner's pick"] = true
}

function removeItem(data)
	local player = data[1]
	local item = data[2]
	local count = data[3]
	if not item:isValid() or item.count == 0 then
		return
	end
	item:remove(count)
	player:sendEvent("CraftingFramework_removedItem", {item, math.floor(count)})
end

-- stable string for arbitrary serializable data (tables, primitives)
local function serialize(v)
	if type(v) ~= "table" then return tostring(v) end
	local keys = {}
	for k in pairs(v) do keys[#keys+1] = k end
	table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
	local parts = {}
	for _, k in ipairs(keys) do
		parts[#parts+1] = tostring(k) .. ":" .. serialize(v[k])
	end
	return "{" .. table.concat(parts, ",") .. "}"
end

-- 64-bit composite hash (DJB2 + poly-31), pure arithmetic. collision risk negligible at our scale.
local function hashKey(v)
	local s = serialize(v)
	local h1, h2 = 5381, 0
	for i = 1, #s do
		local b = s:byte(i)
		h1 = (h1 * 33 + b) % 4294967296
		h2 = (h2 * 31 + b) % 4294967296
	end
	return string.format("%x:%x", h1, h2)
end

-- hash all record overrides into a short stable cache key
local function cacheKey(customName, value, stats, enchantment)
	return hashKey{
		customName = customName,
		value = value,
		stats = stats,
		enchantment = enchantment,
	}
end

-- resolve the chain's enchantment value to a record id (or nil/1).
-- nil = no override; "" maps to 1, the engine's "no enchantment" sentinel.
-- other strings / numbers are passthrough record ids.
-- a table is a def baked into a new record, cached by hashed def.
local function resolveEnchantmentId(enchantment)
	if enchantment == nil then return nil end
	if enchantment == "" then return 1 end
	local t = type(enchantment)
	if t == "string" or t == "number" then return enchantment end
	if not enchantment.effects or #enchantment.effects == 0 then
		return nil
	end
	local key = hashKey(enchantment)
	if not saveData.generatedEnchantments[key] then
		local draft = core.magic.enchantments.createRecordDraft(enchantment)
		local newRecord = world.createRecord(draft)
		saveData.generatedEnchantments[key] = newRecord.id
	end
	return saveData.generatedEnchantments[key]
end

-- legacy fallback: external callers may pass qualityMult without stats.
-- mirrors the default qualityMult modifier on the player side.
local function legacyQualityStats(record, recordType, qualityMult)
	local stats = {}
	if recordType == "Armor" then
		stats.baseArmor = math.floor(record.baseArmor * qualityMult + 0.5)
	elseif recordType == "Weapon" then
		local maxDamage = math.max(record.thrustMaxDamage, record.slashMaxDamage, record.chopMaxDamage)
		stats.thrustMaxDamage = math.floor(math.max(record.thrustMaxDamage, maxDamage * 0.8) * qualityMult + 0.5)
		stats.slashMaxDamage = math.floor(math.max(record.slashMaxDamage, maxDamage * 0.8) * qualityMult + 0.5)
		stats.chopMaxDamage = math.floor(math.max(record.chopMaxDamage, maxDamage * 0.8) * qualityMult + 0.5)
		stats.thrustMinDamage = math.min(record.thrustMinDamage, stats.thrustMaxDamage)
		stats.slashMinDamage = math.min(record.slashMinDamage, stats.slashMaxDamage)
		stats.chopMinDamage = math.min(record.chopMinDamage, stats.chopMaxDamage)
	elseif recordType == "Clothing" then
		stats.enchantCapacity = math.floor(record.enchantCapacity * qualityMult + 0.5)
	end
	return stats
end

function createCraftedObject(data)
	local player = data.player
	local recordType = data.recordType
	local recordId = data.recordId
	local customName = data.customName
	local count = data.count or 1
	local value = data.value
	local stats = data.stats
	local enchantment = data.enchantment
	local qualityMult = data.qualityMult
	local preserveRecordId = data.preserveRecordId
	if not stats and qualityMult and qualityMult ~= 1
		and (recordType == "Armor" or recordType == "Weapon" or recordType == "Clothing") then
		stats = legacyQualityStats(types[recordType].record(recordId), recordType, qualityMult)
	end
	local item
	-- resolve enchantment def to a record id (cached, reused across identical defs)
	local enchantId = resolveEnchantmentId(enchantment)
	local hasOverrides = (stats and next(stats)) or value or customName or enchantId
	if preserveRecordId or (legacyPreserveIds[recordId] and not I.SimplyMining) or recordType ~= "Armor" and recordType ~= "Weapon" and recordType ~= "Clothing" then
		item = world.createObject(recordId, count)
	elseif hasOverrides then
		-- key includes every override so reuse only fires on identical drafts
		local key = recordId .. "-" .. cacheKey(customName, value, stats, enchantment)
		if not saveData.generatedRecords[key] then
			local tbl = {template = types[recordType].record(recordId)}
			if value then tbl.value = value end
			if customName then tbl.name = customName end
			if stats then
				for k, v in pairs(stats) do tbl[k] = v end
			end
			if enchantId then tbl.enchant = enchantId end
			local recordDraft = types[recordType].createRecordDraft(tbl)
			local newRecord = world.createRecord(recordDraft)
			saveData.generatedRecords[key] = newRecord.id
		end
		item = world.createObject(saveData.generatedRecords[key], count)
	else
		item = world.createObject(recordId, count)
	end
	if player then
		item:moveInto(player)
	end
	return item
end

function craftItem(data)
	local player = data.player
	local recordType = data.recordType
	local recordId = data.recordId
	local customName = data.customName
	local count = math.floor((data.count or 1) + math.random())
	local value = data.value
	local qualityMult = data.qualityMult
	local stats = data.stats
	local enchantment = data.enchantment
	local preserveRecordId = data.preserveRecordId
	local shiftPressed = data.shiftPressed
	local consumedIngredients = data.consumedIngredients
	local playPickupSound = data.playPickupSound
	local additionalProducts = data.additionalProducts
	local toolsUsed = data.toolsUsed
	local craftData = data.craftData

	-- always consume wildcard ingredients regardless of chance outcome
	for item, cnt in pairs(consumedIngredients or {}) do
		removeItem{player, item, cnt}
	end

	if count <= 0 then
		player:sendEvent("CraftingFramework_notifyItem", {nil, 0, recordId, shiftPressed})
	else
		local tempItem = createCraftedObject({
			player = player, recordType = recordType, recordId = recordId,
			customName = customName, count = count, value = value,
			stats = stats, enchantment = enchantment, preserveRecordId = preserveRecordId,
		})
		player:sendEvent("CraftingFramework_notifyItem", {tempItem, count, recordId, shiftPressed, playPickupSound, qualityMult, craftData})
		-- post-create hook: lets other mods correlate the created item
		-- with the craftData accumulated through the modifier chains.
		-- custom craftingEvent handlers should fire this themselves.
		core.sendGlobalEvent("CraftingFramework_itemCrafted", {
			player = player,
			item = tempItem,
			recordType = recordType,
			recordId = recordId,
			customName = customName,
			count = count,
			value = value,
			qualityMult = qualityMult,
			stats = stats,
			enchantment = enchantment,
			touches = data.touches,
			shiftPressed = shiftPressed,
			consumedIngredients = consumedIngredients,
			toolsUsed = toolsUsed,
			craftData = craftData,
		})
	end

	-- produce additional products
	for _, product in ipairs(additionalProducts or {}) do
		local productCount = math.floor((product.count or 1) + math.random())
		if productCount > 0 then
			local productItem = createCraftedObject({
				player = player, recordType = product.type, recordId = product.id,
				count = productCount, preserveRecordId = true,
			})
			player:sendEvent("CraftingFramework_notifyItem", {productItem, productCount, product.id, false})
		end
	end
	player:sendEvent("CraftingFramework_refreshInventory") -- gated player-side
end



local function onSave()
    return saveData
end

local function onLoad(data)
	saveData = data or {}
	if not saveData.generatedRecords then
		saveData.generatedRecords = {}
	end
	if not saveData.generatedEnchantments then
		saveData.generatedEnchantments = {}
	end
end

-- forward roguelite's blessing event to the player so CF_p can mirror the nerf
local function onRogueliteSetPlayerBlessings(data)
	local player = data[1]
	if player then
		player:sendEvent("CraftingFramework_rogueliteNerfSignal")
	end
end

-- collect custom global event handlers from recipe files
local customEvents = require("scripts.CraftingFramework.CF_globalEvents")

local eventHandlers = {
	CraftingFramework_getItem = craftItem,
	CraftingFramework_removeItem = removeItem,
	Roguelite_setPlayerBlessings = onRogueliteSetPlayerBlessings,
}
for name, handler in pairs(customEvents) do
	if eventHandlers[name] then
		print("CF warning: custom event '" .. name .. "' conflicts with built-in handler")
	else
		eventHandlers[name] = handler
	end
end

return {
	interfaceName = "CraftingFramework",
	interface = {
		version = VERSION,
		createCraftedObject = createCraftedObject,
		craftItem = craftItem,
	},
	engineHandlers = {
        onLoad = onLoad,
        onInit = onLoad,
        onSave = onSave,
	},
	eventHandlers = eventHandlers,
}