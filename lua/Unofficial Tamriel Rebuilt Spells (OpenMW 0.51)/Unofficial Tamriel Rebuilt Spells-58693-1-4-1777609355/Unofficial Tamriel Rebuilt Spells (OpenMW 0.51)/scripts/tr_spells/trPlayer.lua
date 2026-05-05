core = require('openmw.core')
types = require('openmw.types')
self = require('openmw.self')
I = require('openmw.interfaces')
ui = require('openmw.ui')
util = require('openmw.util')
v2 = util.vector2
v3 = util.vector3
async = require('openmw.async')
input = require('openmw.input')
storage = require('openmw.storage')
nearby = require('openmw.nearby')
camera = require('openmw.camera')
ambient = require('openmw.ambient')
animation = require('openmw.animation')
vfs = require('openmw.vfs')
activeEffects = types.Actor.activeEffects(self)
isPlayer = true

trData = require('scripts.tr_spells.trData')
require('scripts.tr_spells.SETTINGS')

local hasCuttingRoomFloor = core.mwscripts.records["magicsound"]

MODNAME = "TRSpells"
local UPDATE_INTERVAL = 0.15

------------------------- GLOBALS -------------------------
G = {
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
	currentUiMode              = nil,
	
	-- Generic job registries
	onHitJobs         = {}, -- (attack)
	onUseAction       = {}, -- (dt, use, sneak, run) -> nil|bool (bool overrides Use)
	uiModeChangedJobs = {}, -- (data) {oldMode, newMode, arg}
	onTeleportedJobs  = {},
	eventHandlers     = {}, -- player eventHandlers
	
	-- onUpdate Jobs.. but not *every* frame
	sluggishJobs     = {},
	sluggishIterator = nil,
	
	-- Helpers (assigned below)
	scheduleJob            = nil,
	overrideSpell          = nil,
	registerPreviewAction  = nil,
}

local G = G

------------------------- HELPERS -------------------------

function G.scheduleJob(fn, delaySec)
	local runAfter = core.getSimulationTime() + (delaySec or 0)
	local key = {} -- unique key
	G.sluggishJobs[key] = function()
		if core.getSimulationTime() >= runAfter then
			G.sluggishJobs[key] = nil
			fn()
		end
	end
end

-- cast preview helper
function G.registerPreviewAction(opts)
	local wasHeld = false
	local ctx = nil
	local actionId = opts.id or "previewAction"..math.random()
	G.onUseAction[actionId] = function(dt, use, sneak, run)
		local ready = opts.isReady()
		if not ready then
			if wasHeld then
				wasHeld = false
				ctx = nil
				if opts.onCancel then opts.onCancel() end
			end
			return nil
		end
		
		if use then
			wasHeld = true
			ctx = ready
			if opts.onHold then opts.onHold(ctx, dt) end
			return false
		end
		
		-- Released
		if wasHeld then
			wasHeld = false
			local savedCtx = ctx
			ctx = nil
			local fire = opts.onRelease and opts.onRelease(savedCtx)
			if fire then return true end
			if opts.onCancel then opts.onCancel() end
		end
		return nil
	end
end

------------------------- SPELL MODULES -------------------------

for filename in vfs.pathsWithPrefix("scripts/tr_spells/shared/") do
	if filename:match("%.lua$") and not filename:match("/%._") then
		local require_path = filename:gsub("%.lua$", ""):gsub("/", ".")
		require(require_path)
	end
end
for filename in vfs.pathsWithPrefix("scripts/tr_spells/player/") do
	if filename:match("%.lua$") and not filename:match("/%._") then
		local require_path = filename:gsub("%.lua$", ""):gsub("/", ".")
		require(require_path)
	end
end

------------------------- SCAN LOOP -------------------------

local nextUpdate = 0

local function scanActiveSpells()
	local activeSpells = types.Actor.activeSpells(self)
	local currentlyActive = {}
	
	-- aggregate effects count their magnitudes themselves. reset before the scan loop
	for _, c in pairs(G.onAggregateReset) do
		c()
	end
	
	for _, activeSpell in pairs(activeSpells) do
		for _, eff in ipairs(activeSpell.effects) do
			local effId = eff.id and eff.id:lower() or ""
			local key = activeSpell.activeSpellId .. "_" .. effId
			
			-- lifecycle (added, ticks, removed)
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
					if tickFn then tickFn(key, eff, activeSpell, entry, UPDATE_INTERVAL) end
				end
			elseif G.onMgefTick[effId] then
				G.onMgefTick[effId](key, eff, activeSpell, entry, UPDATE_INTERVAL)
			end
			
			-- aggregate: add up magnitudes
			if G.onAggregateEffect[effId] then
				G.onAggregateEffect[effId](key, eff, activeSpell)
			end
		end
	end
	
	-- aggregate: commit to magnitude
	for _, c in pairs(G.onAggregateCommit) do
		c()
	end
	
	-- find expired effects
	for key, entry in pairs(saveData.trackedEffects) do
		if not currentlyActive[key] then
			local removedFn = G.onMgefRemoved[entry.effectId]
			if removedFn then removedFn(key, entry) end
			saveData.trackedEffects[key] = nil
		end
	end
	
	-- requested spell removals
	local clearPendingRemovals = false
	for _, asId in pairs(G.pendingActiveSpellRemovals) do
		activeSpells:remove(asId)
		clearPendingRemovals = true
	end
	if clearPendingRemovals then
		G.pendingActiveSpellRemovals = {}
	end
end

------------------------- EVENTS -------------------------

local function onFrame(dt)
	if hasCuttingRoomFloor then
		core.sound.stopSound3d("magic sound", self)
		core.sound.playSound3d("magic sound", self, {volume = 0})
	end
	if G.sluggishIterator ~= nil and G.sluggishJobs[G.sluggishIterator] == nil then
		G.sluggishIterator = nil
	end
	G.sluggishIterator = next(G.sluggishJobs, G.sluggishIterator)
	if G.sluggishIterator then
		G.sluggishJobs[G.sluggishIterator]()
	end
	
	local now = core.getSimulationTime()
	if now < nextUpdate then return end
	nextUpdate = now + UPDATE_INTERVAL
	scanActiveSpells()
end

I.Combat.addOnHitHandler(function(attack)
	for _, fn in pairs(G.onHitJobs) do fn(attack) end
end)

input.bindAction('Use', async:callback(function(dt, use, sneak, run)
	local override
	for _, fn in pairs(G.onUseAction) do
		local r = fn(dt, use, sneak, run)
		if r ~= nil then override = r end
	end
	if override ~= nil then return override end
	return use
end), {})

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

local function uiModeChanged(data)
	G.currentUiMode = data.newMode
	for _, fn in pairs(G.uiModeChangedJobs) do fn(data) end
end

local function onTeleported()
	for _, fn in pairs(G.onTeleportedJobs) do fn() end
end

-- console command for the spell tomes
local function onConsoleCommand(mode, command)
	if command == "lua trtomes" then
		core.sendGlobalEvent('TD_GiveStartingTomes', { player = self.object })
		ui.showMessage("Spell tomes have been added to your inventory.")
	end
end

------------------------- RETURN -------------------------

local eventHandlers = {
	UiModeChanged = uiModeChanged,
}
for name, fn in pairs(G.eventHandlers) do
	eventHandlers[name] = fn
end

return {
	interfaceName = "TRSpells",
	interface     = {
		version = 1,
	},
	engineHandlers = {
		onFrame          = onFrame,
		onSave           = onSave,
		onLoad           = onLoad,
		onInit           = onLoad,
		onConsoleCommand = onConsoleCommand,
		onTeleported     = onTeleported,
	},
	eventHandlers = eventHandlers,
}