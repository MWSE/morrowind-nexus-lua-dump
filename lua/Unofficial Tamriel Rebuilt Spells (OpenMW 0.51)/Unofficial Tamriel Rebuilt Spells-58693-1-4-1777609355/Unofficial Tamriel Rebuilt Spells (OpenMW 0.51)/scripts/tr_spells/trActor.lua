core = require('openmw.core')
types = require('openmw.types')
self = require('openmw.self')
animation = require('openmw.animation')
async = require('openmw.async')
I = require('openmw.interfaces')
util = require('openmw.util')
nearby = require('openmw.nearby')
v3 = util.vector3
activeEffects = types.Actor.activeEffects(self)
trData = require('scripts.tr_spells.trData')
vfs = require('openmw.vfs')
local activeSpells = types.Actor.activeSpells(self)

isPlayer = false
local SCRIPT_PATH = 'scripts/tr_spells/trActor.lua'
local CHECK_INTERVAL = 0.25
local loadedAddons = false

G = {
	isDead = false,
	
	-- primary events for all effect modules
	onMgefAdded   = {},
	onMgefTick    = {},
	onMgefRemoved = {},
	
	-- for manually accumulating magnitudes
	onAggregateReset  = {},
	onAggregateEffect = {},
	onAggregateCommit = {},
	
	-- for removing spells at the end of a frame
	pendingActiveSpellRemovals = {},
	
	eventHandlers  = {}, -- returned eventHandlers
	onHitJobs      = {}, -- I.Combat events
	onInactiveJobs = {}, -- Cleanup before the actor becomes inactive
	
	-- onUpdate Jobs.. but not *every* frame
	sluggishJobs     = {},
	sluggishIterator = nil,
	
	scheduleJob = nil -- function to schedule an job (G.scheduleJob(fn, delaySec))
}

local G = G

------------------------- Util -------------------------

-- wrapper for a scheduled onUpdate (sluggish) job
function G.scheduleJob(fn, delaySec)
	local runAfter = core.getSimulationTime() + (delaySec or 0)
	local key = {} --unique random key
	G.sluggishJobs[key] = function()
		if core.getSimulationTime() >= runAfter then
			G.sluggishJobs[key] = nil
			fn()
		end
	end
end

local relevanceCache = {}
local registeredEffects = {}

-- scan if a spell can *ever* contain any of our registered effects (performance optimization)
function isSpellRelevant(spell)
	local cached = relevanceCache[spell.id]
	if cached ~= nil then return cached end
	
	local source = core.magic.spells.records[spell.id] or types.Potion.records[spell.id]
	if not source and spell.item then
		local enchantId = spell.item.type.record(spell.item).enchant or ""
		source = core.magic.enchantments.records[enchantId]
	end
	if not source then
		local bookRecord = types.Book.records[spell.id]
		if bookRecord then
			local enchantId = bookRecord.enchant or ""
			source = core.magic.enchantments.records[enchantId]
		end
	end
	
	local result = false
	if not source then
		result = true
	else
		for _, eff in pairs(source.effects) do
			if registeredEffects[eff.id] then
				result = true
				break
			end
		end
	end
	relevanceCache[spell.id] = result
	return result
end

------------------------- Loading spells -------------------------

-- delayed loading of effects (performance optimization)
function loadAddons()
	for filename in vfs.pathsWithPrefix("scripts/tr_spells/shared/") do
		if filename:match("%.lua$") and not filename:match("/%._") then
			local require_path = filename:gsub("%.lua$", ""):gsub("/", ".")
			require(require_path)
		end
	end
	
	-- for relevance cache
	for _, handlers in pairs({ G.onMgefAdded, G.onMgefTick, G.onMgefRemoved, G.onAggregateReset, G.onAggregateEffect, G.onAggregateCommit }) do
		for effectId in pairs(handlers) do
			registeredEffects[effectId] = true
		end
	end
end

------------------------- ON HIT -------------------------

I.Combat.addOnHitHandler(function(attack)
	for _, fn in pairs(G.onHitJobs) do fn(attack) end
end)

------------------------- SCAN LOOP -------------------------

local nextUpdate = math.random() * 1.0

local function scanActiveSpells()
	local currentlyActive = {}
	
	for _, fn in pairs(G.onAggregateReset) do
		fn()
	end
	
	for _, activeSpell in pairs(activeSpells) do
		if isSpellRelevant(activeSpell) then
			for _, eff in pairs(activeSpell.effects) do
				local effId = eff.id and eff.id:lower() or ""
				local key = activeSpell.activeSpellId .. "_" .. effId
				local addedFn = G.onMgefAdded[effId]
				if addedFn then
					currentlyActive[key] = true
					local entry = saveData.trackedEffects[key]
					if not entry then
						entry = {
							effectId      = effId,
							spellId       = activeSpell.id,
							activeSpellId = activeSpell.activeSpellId,
							avgMagnitude  = ((eff.minMagnitude or 0) + (eff.maxMagnitude or 0))/2,
						}
						saveData.trackedEffects[key] = entry
						addedFn(key, eff, activeSpell, entry)
					else
						local tickFn = G.onMgefTick[effId]
						if tickFn then tickFn(key, eff, activeSpell, entry, CHECK_INTERVAL) end
					end
				end
				
				if G.onAggregateEffect[effId] then
					G.onAggregateEffect[effId](key, eff, activeSpell)
				end
			end
		end
	end
	
	for _, fn in pairs(G.onAggregateCommit) do
		fn()
	end
	
	for key, entry in pairs(saveData.trackedEffects) do
		if not currentlyActive[key] then
			local removedFn = G.onMgefRemoved[entry.effectId]
			if removedFn then removedFn(key, entry) end
			saveData.trackedEffects[key] = nil
		end
	end
	
	if next(G.pendingActiveSpellRemovals) then
		for _, asId in pairs(G.pendingActiveSpellRemovals) do
			activeSpells:remove(asId)
		end
		G.pendingActiveSpellRemovals = {}
	end
end

------------------------- LIFECYCLE -------------------------

local function teardownAll()
	for key, entry in pairs(saveData.trackedEffects) do
		local removedFn = G.onMgefRemoved[entry.effectId]
		if removedFn then removedFn(key, entry) end
	end
	saveData.trackedEffects = {}
	G.sluggishJobs = {}
	nextUpdate = math.huge
end

local function onUpdate(dt)
	if G.sluggishIterator ~= nil and G.sluggishJobs[G.sluggishIterator] == nil then
		G.sluggishIterator = nil
	end
	G.sluggishIterator = next(G.sluggishJobs, G.sluggishIterator)
	if G.sluggishIterator then
		G.sluggishJobs[G.sluggishIterator]()
	end
	local now = core.getSimulationTime()
	if now < nextUpdate then return end
	nextUpdate = now + CHECK_INTERVAL
	if loadedAddons then
		scanActiveSpells()
	else
		loadedAddons = true
		loadAddons()
	end
end

local function onInactive()
	for _, fn in pairs(G.onInactiveJobs) do fn() end
	teardownAll()
	core.sendGlobalEvent('TD_RemoveScript', {
		actor = self.object,
		script = SCRIPT_PATH,
	})
end

local function onLoad(data)
	saveData = data or {}
	saveData.trackedEffects = saveData.trackedEffects or {}
	saveData.knownBoundRecordIds = saveData.knownBoundRecordIds or {}
end

local function onSave()
	for key, entry in pairs(saveData.trackedEffects) do
		if entry.revertOnSave then
			local removedFn = G.onMgefRemoved[entry.effectId]
			if removedFn then removedFn(key, entry) end
			saveData.trackedEffects[key] = nil
		end
	end
	return saveData
end

------------------------- RETURN -------------------------

local eventHandlers = {
	TD_RadiantShieldHitVfx = function()
		local rec = types.Static.records["t_vfx_radiantshieldhit"]
		if rec then animation.addVfx(self, rec.model) end
	end,
	TD_SummonCleanup = function(data)
		if data.key then
			saveData.trackedEffects[data.key] = nil
		end
	end,
	Died = function()
		teardownAll()
		G.isDead = true
	end,
}

for name, fn in pairs(G.eventHandlers) do
	eventHandlers[name] = fn
end

return {
	engineHandlers = {
		onUpdate   = onUpdate,
		onInit     = onLoad,
		onLoad     = onLoad,
		onSave     = onSave,
		onInactive = onInactive,
	},
	eventHandlers = eventHandlers,
}