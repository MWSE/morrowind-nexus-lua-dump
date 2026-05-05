local self = require('openmw.self')
local vfs = require('openmw.vfs')
local core = require('openmw.core')
local input = require('openmw.input')
local async = require('openmw.async')
local ui = require('openmw.ui')
local ambient = require('openmw.ambient')
local types = require('openmw.types')

---@type table<string, any>
local effectHandlers = {}
---@type table<string, any>
local onUpdateJobs = {}
---@type table<string, any>
local onFrameJobs = {}
---@type table<string, any>
local onActiveJobs = {}
---@type table<string, any>
local onUiModeChangedJobs = {}
---@type table<string, any>
local onUseJobs = {}
---@type table<string, any>
local onSaveJobs = {}
---@type table<string, boolean>
local realtimeMagnitudeWhileActive = {}
local currentUiMode = nil -- for learning spell tomes when UI mode changes to book

local UPDATE_INTERVAL = 0.15

for path in vfs.pathsWithPrefix('scripts/niftyspellpack/effects/') do
    if path:match('player%.lua$') then
        local effectId = path:match('scripts/niftyspellpack/effects/(.-)/player%.lua$')
        if effectId then
            local id = 'nsp_' .. effectId
            local handlers = require('scripts.niftyspellpack.effects.' .. effectId .. '.player')

            effectHandlers[id] = handlers

            if handlers.onUpdate then
                onUpdateJobs[id] = handlers.onUpdate
            end
            if handlers.onFrame then
                onFrameJobs[id] = handlers.onFrame
            end
            if handlers.onActive then
                onActiveJobs[id] = handlers.onActive
            end
            if handlers.onUiModeChanged then
                onUiModeChangedJobs[id] = handlers.onUiModeChanged
            end
            if handlers.onUse then
                onUseJobs[id] = handlers.onUse
            end
            if handlers.onSave then
                onSaveJobs[id] = handlers.onSave
            end
            if handlers.realtimeMagnitudeWhileActive then
                realtimeMagnitudeWhileActive[id] = true
            end
        end
    end
end

local activeEffects = self.type.activeEffects(self)
local state = {
    lastMagnitude = {},
}
local nextEffectScan = 0.0

local function syncEffectMagnitude(effectId, handlers)
    local lastMagnitude = state.lastMagnitude
    local effect = activeEffects:getEffect(effectId)
    local magnitude = (effect and effect.magnitude) or 0
    local oldMagnitude = lastMagnitude[effectId] or 0

    if magnitude ~= oldMagnitude then
        if handlers.onMagnitudeChange then
            handlers.onMagnitudeChange({ oldMagnitude = oldMagnitude, newMagnitude = magnitude })
        end
        core.sendGlobalEvent('NSP_EffectEvent', {
            type = 'onMagnitudeChange',
            effectId = effectId,
            target = self,
            ctx = { oldMagnitude = oldMagnitude, newMagnitude = magnitude }
        })
    end

    lastMagnitude[effectId] = magnitude
    return magnitude
end

local function refreshMagnitudes()
    for effectId, handlers in pairs(effectHandlers) do
        syncEffectMagnitude(effectId, handlers)
    end
end

input.registerActionHandler('Use', async:callback(function(e)
    if core.isWorldPaused() or not e then return end

    local lastMagnitude = state.lastMagnitude
    for effectId, fn in pairs(onUseJobs) do
        if (lastMagnitude[effectId] or 0) > 0 then
            fn()
        end
    end
end))

local tomeDefs = {
	{
		tomeId = "spelltome_nsp_conj",
		message = "You have learned a Conjuration spell from this tome.",
		spells = {
			"nsp_pocket",
		},
	},
	{
		tomeId = "spelltome_nsp_myst",
		message = "You have learned several Mysticism spells from this tome.",
		spells = {
			"nsp_contingency",
			"nsp_projection",
			"nsp_greaterprojection",
			"nsp_wildintervention",
		},
	},
	{
		tomeId = "spelltome_nsp_alt",
		message = "You have learned an Alteration spell from this tome.",
		spells = {
			"nsp_alacrity",
		},
	},
}

---@type table<string, any>
local tomeByBook = {}
for _, def in ipairs(tomeDefs) do
	tomeByBook[def.tomeId:lower()] = def
end

local function teachSpellsFromTome(def)
	local playerSpells = types.Player.spells(self)
	local knownSpells = {}
	for _, spell in pairs(playerSpells) do
		knownSpells[spell.id] = true
	end

	local learnedAny = false
	for _, spellId in ipairs(def.spells) do
		if not knownSpells[spellId] then
			playerSpells:add(spellId)
			knownSpells[spellId] = true
			learnedAny = true
		end
	end
	if learnedAny then
		ui.showMessage(def.message)
		ambient.playSound("skillraise")
	end
end

local function learnFromSpelltomesOnUiMode(data)
	currentUiMode = data.newMode
	if data.newMode == "Book" and data.arg and data.arg.recordId then
		local def = tomeByBook[data.arg.recordId:lower()]
		if def then teachSpellsFromTome(def) end
	end
end

-- Console command "lua nsptomes"
local function onConsoleCommand(mode, command)
	if command == "lua nsptomes" then
		core.sendGlobalEvent('NSP_GiveStartingTomes', { player = self.object })
		ui.showMessage("Spell tomes with some nifty spells have been added to your inventory.")
	end
end

return {
    engineHandlers = {
        onUpdate = function(dt)
            for effectId, enabled in pairs(realtimeMagnitudeWhileActive) do
                if enabled and (state.lastMagnitude[effectId] or 0) > 0 then
                    syncEffectMagnitude(effectId, effectHandlers[effectId])
                end
            end

            local now = core.getSimulationTime()
            if now >= nextEffectScan then
                nextEffectScan = now + UPDATE_INTERVAL
                refreshMagnitudes()
            end

            local lastMagnitude = state.lastMagnitude
            for effectId, fn in pairs(onUpdateJobs) do
                fn(dt, lastMagnitude[effectId] or 0)
            end
        end,
        onFrame = function(dt)
            local lastMagnitude = state.lastMagnitude
            for effectId, fn in pairs(onFrameJobs) do
                fn(dt, lastMagnitude[effectId] or 0)
            end
        end,
        onLoad = function(save)
            if save then
                if save.state then
                    for k,v in pairs(save.state) do
                        state[k] = v
                    end
                end
                if save.effectData then
                    for effectId, data in pairs(save.effectData) do
                        local handlers = effectHandlers[effectId]
                        if handlers and handlers.onLoad then
                            handlers.onLoad(data)
                        end
                    end
                end
            end
        end,
        onSave = function()
            local effectData = {}
            for effectId, fn in pairs(onSaveJobs) do
                local data = fn()
                if data then
                    effectData[effectId] = data
                end
            end

            return {
                state = state,
                effectData = effectData,
            }
        end,
        onActive = function()
            refreshMagnitudes()
            for _, fn in pairs(onActiveJobs) do
                fn()
            end
        end,
		onConsoleCommand = onConsoleCommand,
    },
    eventHandlers = {
        NSP_EffectEvent = function(data)
            local effectHandler = effectHandlers[data.effectId]
            if effectHandler and effectHandler[data.type] then
                effectHandler[data.type](data.ctx)
            end
        end,
        UiModeChanged = function(args)
            for _, fn in pairs(onUiModeChangedJobs) do
                fn(args.oldMode, args.newMode)
            end
			learnFromSpelltomesOnUiMode(args)
        end,
    }
}