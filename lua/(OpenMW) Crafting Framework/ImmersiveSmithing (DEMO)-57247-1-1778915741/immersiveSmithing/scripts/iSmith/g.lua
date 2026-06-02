-- iSmith global side: anvil activation, workpiece spawn, craft completion
local core = require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local world = require('openmw.world')
local I = require('openmw.interfaces')

local v3 = util.vector3

-- -------------------------------------------------- state --------------------------------------------------
local pendingHits = {}        -- per-swing quality [0..1], 0 = miss
local workpieceRecords = {}   -- activator records cached by model
local workpieces = {}         -- live workpieces by id
local pendingSettle = {}      -- spawned, awaiting one-frame settle

-- -------------------------------------------------- workpiece spawn --------------------------------------------------
local function getOrCreateWorkpieceRecord(model)
	local cached = workpieceRecords[model]
	if cached then
		return cached
	end
	local draft = types.Activator.createRecordDraft({
		name = "Workpiece",
		model = model,
	})
	local rec = world.createRecord(draft)
	workpieceRecords[model] = rec.id
	return rec.id
end

-- spawn at anchor; final placement corrected next frame in onUpdate
local function handleSpawnWorkpiece(data)
	local id = data.id
	if not id then return end
	-- de-dupe by id
	if workpieces[id] and workpieces[id]:isValid() then
		workpieces[id]:remove()
	end
	if not data.model or not data.cell or not data.position then return end
	local recordId = getOrCreateWorkpieceRecord(data.model)
	local obj = world.createObject(recordId, 1)
	obj:teleport(data.cell, data.position, {
		rotation = data.rotation,
	})
	workpieces[id] = obj

	-- settle next frame: seat on anvil, then report bbox
	pendingSettle[#pendingSettle + 1] = {
		id       = id,
		obj      = obj,
		cell     = data.cell,
		anchor   = data.position,
		rotation = data.rotation,
		player   = data.player,
	}
end

-- -------------------------------------------------- settle pass --------------------------------------------------
local function onUpdate()
	if #pendingSettle == 0 then return end
	for _, s in ipairs(pendingSettle) do
		if s.obj:isValid() then
			local bbox = s.obj:getBoundingBox()
			local correction = v3(
				s.anchor.x - bbox.center.x,
				s.anchor.y - bbox.center.y,
				s.anchor.z - (bbox.center.z - bbox.halfSize.z)
			)
			s.obj:teleport(s.cell, s.obj.position + correction, {
				rotation = s.rotation,
			})
			-- analytic post-shift bbox (re-query would be model-local)
			if s.player then
				s.player:sendEvent("iSmith_workpieceBox", {
					id = s.id,
					object = s.obj,
					center = bbox.center + correction,
					halfSize = bbox.halfSize,
				})
			end
		end
	end
	pendingSettle = {}
end

local function handleDespawnWorkpiece(data)
	local id = data and data.id
	if not id then return end
	local obj = workpieces[id]
	if obj and obj:isValid() then
		obj:remove()
	end
	workpieces[id] = nil
end

-- -------------------------------------------------- minigame hit recording --------------------------------------------------
local function handleResetHits()
	pendingHits = {}
end

local function handleRecordHit(data)
	if not data then return end
	table.insert(pendingHits, tonumber(data.quality) or 0)
end

-- -------------------------------------------------- craft completion --------------------------------------------------
local function qualityToMult(avg)
	local clamped = math.max(0, math.min(1, avg or 0))
	return 0.6 + clamped * 0.8  -- 0.6x..1.4x stats
end

-- CF craft-finished hook
local function handleComplete(data)
	-- average recorded hits
	local sum = 0
	local n = #pendingHits
	for _, q in ipairs(pendingHits) do
		sum = sum + q
	end
	local avg = (n > 0) and (sum / n) or 0
	pendingHits = {}

	-- no minigame ran -> no quality penalty
	local baseMult = data.qualityMult or 1
	local newMult = baseMult
	if n > 0 then
		newMult = baseMult * qualityToMult(avg)
	end

	print("iSmith complete", "recordId=", data and data.recordId, "type=", data and data.recordType, "player=", data and data.player, "hits=", #pendingHits, "quality=", newMult)
	-- snapshot workpiece transform to drop the item there
	local workpieceId = data.player and tostring(data.player.id)
	local workpiece = workpieceId and workpieces[workpieceId] or nil
	local wpCell, wpPos, wpRot
	if workpiece and workpiece:isValid() then
		wpCell = workpiece.cell
		wpPos  = workpiece.position
		wpRot  = workpiece.rotation
	end

	-- createCraftedObject so we can place it; rest of CF flow replicated below

	-- consume ingredients
	for ingItem, cnt in pairs(data.consumedIngredients or {}) do
		core.sendGlobalEvent("CraftingFramework_removeItem", {data.player, ingItem, cnt})
	end

	-- spawn main item
	local count = data.count or 1
	local item = I.CraftingFramework.createCraftedObject({
		player = nil,
		recordType = data.recordType,
		recordId = data.recordId,
		customName = data.customName,
		count = count,
		value = data.value,
		stats = data.stats,
		enchantment = data.enchantment,
		qualityMult = newMult,
		preserveRecordId = data.preserveRecordId,
	})

	-- pickup sound + message
	if data.player then
		data.player:sendEvent("CraftingFramework_notifyItem",
			{item, count, data.recordId, data.shiftPressed, data.playPickupSound})
	end

	-- swap workpiece for the finished item
	if item and wpPos then
		item:teleport(wpCell, wpPos, { rotation = wpRot })
	end
	if workpiece and workpiece:isValid() then
		workpiece:remove()
	end
	if workpieceId then workpieces[workpieceId] = nil end

	-- byproducts to inventory
	for _, product in ipairs(data.additionalProducts or {}) do
		local productCount = math.floor((product.count or 1) + math.random())
		if productCount > 0 then
			local productItem = I.CraftingFramework.createCraftedObject({
				player = data.player,
				recordType = product.type,
				recordId = product.id,
				count = productCount,
				preserveRecordId = true,
			})
			if data.player then
				data.player:sendEvent("CraftingFramework_notifyItem",
					{productItem, productCount, product.id, false})
			end
		end
	end

	-- refresh ralt's inventory extender
	if data.player then
		data.player:sendEvent("MI_Update")
	end

	-- notify player: done
	if data.player then
		data.player:sendEvent("iSmith_finished", {
			recordId = data.recordId,
			qualityMult = newMult,
			minigameAverage = avg,
			hitCount = n,
		})
	end
end

return {
	engineHandlers = {
		onUpdate = onUpdate,
	},
	eventHandlers = {
		iSmith_spawnWorkpiece = handleSpawnWorkpiece,
		iSmith_despawnWorkpiece = handleDespawnWorkpiece,
		iSmith_resetHits = handleResetHits,
		iSmith_recordHit = handleRecordHit,
		iSmith_complete = handleComplete,
	},
}
