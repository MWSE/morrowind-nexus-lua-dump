--- SkillFramework Wrapper
---
--- A drop-in fallback for SkillFramework (by `Elvis#3710`) that lets mods function whether or
--- not the framework is installed. Mirrors the real API (minus the StatsWindowExtender
--- integration); if SkillFramework is present, all calls transparently delegate to it.
---
--- ## Setup
--- The host script must wire in the wrapper's lifecycle hooks:
--- ```lua
--- local SF = require('scripts.MyMod.sf_wrapper')
---
--- return {
---     engineHandlers = {
---         onInit         = SF.onInit,
---         onLoad         = SF.onLoad,
---         onSave         = SF.onSave,
---         onUpdate       = SF.onUpdate,
---     },
---     eventHandlers = {
---         UiModeChanged  = SF.onUiModeChanged,
---     },
--- }
--- ```
--- If the host needs its own engine/event handlers, it should delegate to the
--- wrapper hooks from within them.
---
--- The `interface` field holds the API table. In standalone mode it emulates
--- SkillFramework; once the real interface binds (~0.1s after script load),
--- calls forward to it.
---
--- modifier tick from every-frame onUpdate to on-read. See setLazyMode docs
--- for the tradeoffs.
-- Tradeoffs when enabled:
--   - No per-frame cost for actors that aren't having their skills queried.
--   - skillStatChanged handlers only fire when a read causes a tick, NOT
--     asynchronously as a modifier's return value changes over time.
--   - Bound mode is unaffected: SF itself decides when to tick.
local lazyMode = true


local async = require('openmw.async')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local types = require('openmw.types')
local util = require('openmw.util')

local BIND_DELAY = 0.1
local API_VERSION = 2

-- Performance mode toggle. When true, dynamic modifier callbacks are ticked
-- on read (inside getSkillStat / getSkillProgressRequirement / calcStatFactor)
-- instead of every frame via onUpdate.
--
-- Set via API.setLazyMode(true) before any skill reads happen, or leave off
-- for default behavior (matches SkillFramework's every-frame tick).
--


local Specialization = {
	Combat = 'combat',
	Magic = 'magic',
	Stealth = 'stealth',
}

local SkillIncreaseSource = {
	Book = 'book',
	Jail = 'jail',
	Trainer = 'trainer',
	Usage = 'usage',
}

-- Localized if the SkillFramework l10n file is shipped; otherwise these are
-- just plain English strings. Either way, mods comparing against these
-- constants stay consistent across standalone/bound modes (the strings used
-- at `registerSkill` time are persisted into the records).
local StatsWindowSubsection = {
	Arts     = 'Arts',
	Combat   = 'Combat',
	Crafts   = 'Crafts',
	Language = 'Language',
	Magic    = 'Magic',
	Misc     = 'Misc',
	Movement = 'Movement',
	Nature   = 'Nature',
	Social   = 'Social',
	Theology = 'Theology',
}

-- Reference to the real API once bound. While nil, wrapper runs standalone.
local boundApi = nil

-- Set once the bind check has run; true means "we've given up, SF isn't here".
local bindAttempted = false

-- Buffered registrations/state for standalone mode. Everything here is also
-- forwarded to the real API on handoff.
local customSkills = {}        -- [skillId] = props (defaults filled in)
local customSkillBooks = {}    -- [bookId] = { [skillId] = props }
local raceModifiers = {}       -- [skillId] = { { race, amount }, ... }
local classModifiers = {}      -- [skillId] = { { class, amount }, ... }
local dynamicModifiers = {}    -- [skillId] = { [modId] = callback }
local globalBindings = {}      -- [skillId] = { [globalId] = true }

-- Permanent ownership sets. Populated whenever the host registers a skill or
-- book through the wrapper, regardless of binding state; never cleared. Used
-- by onSave in bound mode to snapshot only SF state this wrapper instance is
-- responsible for, so a later bound->standalone transition (user uninstalls SF
-- between saves) can restore the player's progress.
local ownedSkills = {}         -- [skillId] = true
local ownedBooks = {}          -- [bookId] = { [skillId] = true }

-- Handlers registered via addSkill*Handler. Fire locally in standalone mode;
-- forwarded to the real API on handoff so new events route there.
local handlers = {
	skillRegistered = {},
	skillUsed = {},
	skillLevelUp = {},
	skillStatChanged = {},
}

-- Saved per-character state. Survives script reloads via onSave/onLoad.
local saveData = {
	skills = {},             -- [skillId] = { base, modifier, progress }
	initializedSkills = {},  -- [skillId] = true (race/class mods applied)
	readBooks = {},          -- [bookId] = { [skillId] = true }
	modifierStates = {},     -- [skillId] = { [modId] = lastAppliedValue }
}

-- Stat changes queued during this frame, flushed in onUpdate.
local pendingStatChanges = {}

local function warn(msg)
	print('[SkillFramework Wrapper] WARNING: ' .. msg)
end

--------------------------------------------------------------------------------
-- Helpers (local, not exposed)
--------------------------------------------------------------------------------

local function shallowCopy(tbl)
	if type(tbl) ~= 'table' then return tbl end
	local out = {}
	for k, v in pairs(tbl) do out[k] = v end
	return out
end

local function deepCopy(tbl)
	if type(tbl) ~= 'table' then return tbl end
	local out = {}
	for k, v in pairs(tbl) do
		if type(v) == 'table' then
			out[k] = deepCopy(v)
		else
			out[k] = v
		end
	end
	return out
end

-- Matches the read-only wrapping SF uses on records. Allows the change callback
-- to detect writes to `base`, `modifier`, `progress` on stat tables.
local function makeReadOnly(tbl, whitelist, blacklist, changedCallback)
	local proxy = {}
	local mt = {
		__index = tbl,
		__newindex = function(_, key, value)
			if (whitelist and not whitelist[key]) or (blacklist and blacklist[key]) then
				error("Attempt to modify read-only key: " .. tostring(key), 2)
			else
				local before = deepCopy(tbl)
				rawset(tbl, key, value)
				local after = deepCopy(tbl)
				if changedCallback then
					changedCallback(before, after)
				end
			end
		end,
		__pairs = function() return pairs(tbl) end,
		__ipairs = function() return ipairs(tbl) end,
		__len = function() return #tbl end,
	}
	setmetatable(proxy, mt)
	return proxy
end

local function callHandlers(list, ...)
	if not list then return false end
	for i = #list, 1, -1 do
		if list[i](...) == false then
			return true
		end
	end
	return false
end

local function getSpecialization()
	return self.type.classes.records[self.type.records[self.recordId].class].specialization
end

--------------------------------------------------------------------------------
-- Standalone stat verification (mirrors SF's verifySkillStat)
--------------------------------------------------------------------------------

local function verifySkillStatLocal(id)
	local record = customSkills[id]
	if not record then return end

	local stat = saveData.skills[id] or {}
	if not saveData.initializedSkills[id] then
		-- Not yet initialized for this character; reset so base defaults re-apply.
		stat = {}
	end

	local selfRecord = self.type.records[self.recordId]

	if not stat.base then
		stat.base = record.startLevel

		if raceModifiers[id] then
			local race = selfRecord.race:lower()
			for _, mod in ipairs(raceModifiers[id]) do
				if mod.race == race then
					stat.base = stat.base + mod.amount
				end
			end
		end
		if classModifiers[id] then
			local class = selfRecord.class:lower()
			for _, mod in ipairs(classModifiers[id]) do
				if mod.class == class then
					stat.base = stat.base + mod.amount
				end
			end
		end
	end

	stat.modifier = stat.modifier or 0
	stat.progress = stat.progress or 0

	stat.base = math.max(0, stat.base)
	if record.maxLevel >= 0 and stat.base > record.maxLevel then
		stat.base = record.maxLevel
	end
	stat.modified = math.max(0, stat.base + stat.modifier)

	saveData.skills[id] = stat

	if not saveData.initializedSkills[id] and (not self.type.isCharGenFinished or self.type.isCharGenFinished(self)) then
		saveData.initializedSkills[id] = true
	end
end

-- Runs dynamic modifier callbacks for a single skill and updates its modifier
-- delta. Writes directly to the raw saveData table (not through the read-only
-- proxy), because calling through the proxy would recurse back into
-- verifySkillStatLocal. In lazy mode this runs before every read; otherwise
-- it's driven by onUpdate. Always cheap when no dynamic mods are registered.
local function tickDynamicModifiersLocal(id)
	local callbacks = dynamicModifiers[id]
	local stat = saveData.skills[id]
	if not stat then return end

	saveData.modifierStates[id] = saveData.modifierStates[id] or {}
	local states = saveData.modifierStates[id]

	if callbacks then
		for modId, cb in pairs(callbacks) do
			local newVal = cb() or 0
			local oldVal = states[modId] or 0
			if newVal ~= oldVal then
				stat.modifier = stat.modifier + (newVal - oldVal)
				states[modId] = newVal
			end
		end
	end

	-- Garbage-collect state for modifiers that were unregistered.
	for modId, value in pairs(states) do
		if not callbacks or not callbacks[modId] then
			stat.modifier = stat.modifier - (value or 0)
			states[modId] = nil
		end
	end

	-- Recompute modified in case modifier changed.
	stat.modified = math.max(0, stat.base + stat.modifier)
end

--------------------------------------------------------------------------------
-- Apply the same defaults SF's registerSkill does, so records are usable even
-- in standalone mode and match what SF would produce on handoff.
--------------------------------------------------------------------------------

local function fillSkillDefaults(props)
	props.icon = props.icon or {}
	props.icon.bgr = props.icon.bgr or ('icons/SkillFramework/' .. (props.specialization or 'default') .. '_blank.dds')
	props.icon.bgrColor = props.icon.bgrColor or util.color.rgb(1, 1, 1)
	props.icon.fgr = props.icon.fgr or ('icons/SkillFramework/default.dds')
	props.icon.fgrColor = props.icon.fgrColor or util.color.rgb(1, 1, 1)

	props.skillGain = props.skillGain or {}
	props.startLevel = props.startLevel or 5
	props.maxLevel = props.maxLevel or 100
	props.xpCurve = props.xpCurve or function(currentLevel)
		return (currentLevel + 1) * core.getGMST('fMiscSkillBonus')
	end

	props.statsWindowProps = props.statsWindowProps or {}
	if props.statsWindowProps.visible == nil then
		props.statsWindowProps.visible = true
	end
end

--------------------------------------------------------------------------------
-- Standalone emulation of actor.lua's skillUsed/skillLevelUp flow
--------------------------------------------------------------------------------

local API -- forward declared so the handlers below can call it

local function standaloneSkillUsed(skillId, params)
	if self.type.isWerewolf and self.type.isWerewolf(self) then
		return false
	end

	local stat = API.getSkillStat(skillId)
	local record = API.getSkillRecord(skillId)
	if not stat or not record then return false end

	local req = API.getSkillProgressRequirement(skillId)
	if not req or req <= 0 then
		stat.progress = 1
	else
		stat.progress = stat.progress + params.skillGain / req
	end

	if stat.progress >= 1 and not (record.maxLevel >= 0 and stat.base >= record.maxLevel) then
		API.skillLevelUp(skillId, SkillIncreaseSource.Usage)
	end
end

local function standaloneSkillLevelUp(skillId, source, params)
	local stat = API.getSkillStat(skillId)
	local record = API.getSkillRecord(skillId)
	if not stat or not record then return false end

	if (record.maxLevel >= 0 and stat.base >= record.maxLevel and params.skillIncreaseValue > 0) or
		(stat.base <= 0 and params.skillIncreaseValue < 0) then
		return false
	end

	if params.skillIncreaseValue then
		stat.base = stat.base + params.skillIncreaseValue
	end

	local levelStat = self.type.stats.level(self)
	if params.levelUpProgress then
		levelStat.progress = levelStat.progress + params.levelUpProgress
	end

	-- Standalone note: we do NOT gate attribute progression behind a setting
	-- here (SF has `b_SkillsProgressAttributes` for that). In standalone mode
	-- the wrapper's host mod would need its own toggle; the default matches
	-- SF's default (on). If this matters, expose a flag on the wrapper.
	if params.levelUpAttribute and params.levelUpAttributeIncreaseValue then
		levelStat.skillIncreasesForAttribute[params.levelUpAttribute] =
			levelStat.skillIncreasesForAttribute[params.levelUpAttribute] + params.levelUpAttributeIncreaseValue
	end

	if params.levelUpSpecialization and params.levelUpSpecializationIncreaseValue then
		levelStat.skillIncreasesForSpecialization[params.levelUpSpecialization] =
			levelStat.skillIncreasesForSpecialization[params.levelUpSpecialization] + params.levelUpSpecializationIncreaseValue
	end

	if source ~= SkillIncreaseSource.Jail then
		if self.type == types.Player then
			local ui = require('openmw.ui')
			local ambient = require('openmw.ambient')

			ambient.playSound('skillraise')

			local message = string.format(core.getGMST('sNotifyMessage39'), record.name, stat.base)
			if source == SkillIncreaseSource.Book then
				message = '#{sBookSkillMessage}\n' .. message
			end
			ui.showMessage(message, { showInDialogue = false })

			if levelStat.progress >= core.getGMST('iLevelUpTotal') then
				ui.showMessage('#{sLevelUpMsg}', { showInDialogue = false })
			end
		end
		if not source or source == SkillIncreaseSource.Usage then
			stat.progress = 0
		end
	end
end

local function standaloneOnBookRead(recordId)
	recordId = string.lower(recordId)
	local bookEntry = customSkillBooks[recordId]
	if not bookEntry then return end

	for skillId, props in pairs(bookEntry) do
		if not (saveData.readBooks[recordId] and saveData.readBooks[recordId][skillId]) then
			local grant = true
			local grantFailMsg
			if type(props.grantSkill) == 'function' then
				grant, grantFailMsg = props.grantSkill()
			else
				grant = props.grantSkill
			end

			if grant then
				API.skillLevelUp(skillId, SkillIncreaseSource.Book, props.skillIncrease)
				saveData.readBooks[recordId] = saveData.readBooks[recordId] or {}
				saveData.readBooks[recordId][skillId] = true
			elseif grantFailMsg and self.type == types.Player then
				local ui = require('openmw.ui')
				ui.showMessage(grantFailMsg, { showInDialogue = false })
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Handoff: migrate buffered state into the real API once it binds
--------------------------------------------------------------------------------

local function handoff()
	-- 1. Race/class modifiers first. SF only applies them during a skill's
	--    initial verifySkillStat (stat.base == nil). Registering before the
	--    skill itself ensures they're in place when SF initializes the stat.
	for skillId, mods in pairs(raceModifiers) do
		for _, m in ipairs(mods) do
			boundApi.registerRaceModifier(skillId, m.race, m.amount)
		end
	end
	for skillId, mods in pairs(classModifiers) do
		for _, m in ipairs(mods) do
			boundApi.registerClassModifier(skillId, m.class, m.amount)
		end
	end

	-- 2. Forward skill registrations. NOTE: we deliberately do this BEFORE
	--    forwarding skillRegistered handlers, because those handlers already
	--    fired synchronously during standalone registerSkill calls.
	--    Forwarding them first would cause a double-fire for every skill.
	for id, props in pairs(customSkills) do
		boundApi.registerSkill(id, props)
	end

	-- 3. Forward skill books.
	for bookId, skills in pairs(customSkillBooks) do
		for skillId, props in pairs(skills) do
			boundApi.registerSkillBook(bookId, skillId, props)
		end
	end

	-- 4. Now wire handlers. Future registrations (if any) will route through
	--    SF and trigger these normally.
	for _, h in ipairs(handlers.skillRegistered) do boundApi.addSkillRegisteredHandler(h) end
	for _, h in ipairs(handlers.skillUsed)       do boundApi.addSkillUsedHandler(h) end
	for _, h in ipairs(handlers.skillLevelUp)    do boundApi.addSkillLevelUpHandler(h) end
	for _, h in ipairs(handlers.skillStatChanged)do boundApi.addSkillStatChangedHandler(h) end

	-- 5. Push tracked stats + book-read flags. This is the critical step:
	--    whatever progression happened in standalone mode gets carried over.
	for bookId, skills in pairs(saveData.readBooks) do
		for skillId, isRead in pairs(skills) do
			if isRead then
				boundApi.setSkillBookReadState(bookId, skillId, true)
			end
		end
	end

	for id, tracked in pairs(saveData.skills) do
		if customSkills[id] then
			-- Trigger SF's verifySkillStat. Any race/class mod SF applies here
			-- gets overwritten by the tracked base below, which is correct:
			-- our tracked base already includes those mods from standalone init.
			local stat = boundApi.getSkillStat(id)
			if stat then
				if tracked.base ~= nil then stat.base = tracked.base end
				if tracked.modifier ~= nil then stat.modifier = tracked.modifier end
				if tracked.progress ~= nil then stat.progress = tracked.progress end
			end
		end
	end

	-- 6. Dynamic modifiers: register with SF. SF will call them every frame
	--    and diff against its own modifierStates table, so we can forget the
	--    wrapper's own modifierStates bookkeeping after this point.
	--
	--    BUT: if standalone already applied some delta via these callbacks,
	--    SF starts from its own modifierStates (empty for this skill) and
	--    will think the full callback return is a fresh delta. We already
	--    baked that delta into stat.modifier above via tracked.modifier,
	--    so SF would double-apply. To prevent that, subtract the standalone
	--    deltas from stat.modifier before registering the dynamic mods.
	for skillId, states in pairs(saveData.modifierStates) do
		if customSkills[skillId] and dynamicModifiers[skillId] then
			local stat = boundApi.getSkillStat(skillId)
			if stat then
				for _, value in pairs(states) do
					stat.modifier = stat.modifier - (value or 0)
				end
			end
		end
	end
	saveData.modifierStates = {}

	for skillId, mods in pairs(dynamicModifiers) do
		for modId, cb in pairs(mods) do
			boundApi.registerDynamicModifier(skillId, modId, cb)
		end
	end

	-- 7. Global bindings (players only). SF handles the MWScript side itself.
	if self.type == types.Player then
		for skillId, globals in pairs(globalBindings) do
			for globalId in pairs(globals) do
				boundApi.bindGlobal(globalId, skillId)
			end
		end
	end

	-- Clear standalone state. From here on, every API call delegates.
	saveData.skills = {}
	saveData.initializedSkills = {}
	saveData.readBooks = {}
	customSkills = {}
	customSkillBooks = {}
	raceModifiers = {}
	classModifiers = {}
	dynamicModifiers = {}
	globalBindings = {}
	handlers = { skillRegistered = {}, skillUsed = {}, skillLevelUp = {}, skillStatChanged = {} }
	pendingStatChanges = {}
end



local function tryBind()
	if boundApi or bindAttempted then return end
	bindAttempted = true

	if I.SkillFramework and I.SkillFramework.getVersion then
		boundApi = I.SkillFramework
		handoff()
	end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

API = {}

function API.getVersion()
	if boundApi then return boundApi.getVersion() end
	return API_VERSION
end


API.SPECIALIZATION = util.makeReadOnly(Specialization)
API.SKILL_INCREASE_SOURCES = util.makeReadOnly(SkillIncreaseSource)
API.STATS_WINDOW_SUBSECTIONS = util.makeReadOnly(StatsWindowSubsection)

function API.registerSkill(id, props)
	id = string.lower(id)
	if not props or not props.name then
		warn('registerSkill("' .. id .. '") called without a name. Aborted.')
		return
	end

	ownedSkills[id] = true

	if boundApi then
		boundApi.registerSkill(id, props)
		return
	end

	if customSkills[id] then
		warn('Skill "' .. id .. '" already registered. Overwriting.')
	end

	fillSkillDefaults(props)
	customSkills[id] = props

	callHandlers(handlers.skillRegistered, id, makeReadOnly(props, {}))
end

function API.modifySkill(id, props)
	id = string.lower(id)
	if boundApi then
		boundApi.modifySkill(id, props)
		return
	end

	if not customSkills[id] then
		warn('modifySkill("' .. id .. '"): unknown skill.')
		return
	end
	for k, v in pairs(props) do
		customSkills[id][k] = v
	end
end

function API.registerSkillBook(bookId, skillId, props)
	bookId = string.lower(bookId)
	skillId = string.lower(skillId)

	ownedBooks[bookId] = ownedBooks[bookId] or {}
	ownedBooks[bookId][skillId] = true

	if boundApi then
		boundApi.registerSkillBook(bookId, skillId, props)
		return
	end

	customSkillBooks[bookId] = customSkillBooks[bookId] or {}
	if customSkillBooks[bookId][skillId] then
		warn('Skill book "' .. bookId .. '" already registered for skill "' .. skillId .. '". Overwriting.')
	end

	props = props or {}
	props.skillIncrease = props.skillIncrease or 1
	if props.grantSkill == nil then props.grantSkill = true end
	customSkillBooks[bookId][skillId] = props
end

function API.registerRaceModifier(skillId, raceId, amount)
	skillId = string.lower(skillId)
	raceId = string.lower(raceId)
	if boundApi then
		boundApi.registerRaceModifier(skillId, raceId, amount)
		return
	end
	raceModifiers[skillId] = raceModifiers[skillId] or {}
	table.insert(raceModifiers[skillId], { race = raceId, amount = amount })
end

function API.registerClassModifier(skillId, classId, amount)
	skillId = string.lower(skillId)
	classId = string.lower(classId)
	if boundApi then
		boundApi.registerClassModifier(skillId, classId, amount)
		return
	end
	classModifiers[skillId] = classModifiers[skillId] or {}
	table.insert(classModifiers[skillId], { class = classId, amount = amount })
end

function API.registerDynamicModifier(skillId, modifierId, callback)
	skillId = string.lower(skillId)
	modifierId = string.lower(modifierId)
	if boundApi then
		boundApi.registerDynamicModifier(skillId, modifierId, callback)
		return
	end
	dynamicModifiers[skillId] = dynamicModifiers[skillId] or {}
	if dynamicModifiers[skillId][modifierId] then
		warn('Dynamic modifier "' .. modifierId .. '" already registered for "' .. skillId .. '". Overwriting.')
	end
	dynamicModifiers[skillId][modifierId] = callback
end

function API.unregisterDynamicModifier(skillId, modifierId)
	skillId = string.lower(skillId)
	modifierId = string.lower(modifierId)
	if boundApi then
		boundApi.unregisterDynamicModifier(skillId, modifierId)
		return
	end
	if dynamicModifiers[skillId] then
		dynamicModifiers[skillId][modifierId] = nil
	end
end

function API.addSkillRegisteredHandler(h)
	if boundApi then boundApi.addSkillRegisteredHandler(h); return end
	table.insert(handlers.skillRegistered, h)
end

function API.addSkillUsedHandler(h)
	if boundApi then boundApi.addSkillUsedHandler(h); return end
	table.insert(handlers.skillUsed, h)
end

function API.addSkillLevelUpHandler(h)
	if boundApi then boundApi.addSkillLevelUpHandler(h); return end
	table.insert(handlers.skillLevelUp, h)
end

function API.addSkillStatChangedHandler(h)
	if boundApi then boundApi.addSkillStatChangedHandler(h); return end
	table.insert(handlers.skillStatChanged, h)
end

function API.getSkillRecords()
	if boundApi then return boundApi.getSkillRecords() end
	local out = {}
	for id, props in pairs(customSkills) do
		out[id] = makeReadOnly(props, {})
	end
	return out
end

function API.getSkillRecord(id)
	id = string.lower(id)
	if boundApi then return boundApi.getSkillRecord(id) end
	return customSkills[id] and makeReadOnly(customSkills[id], {}) or nil
end

function API.getSkillBookRecords()
	if boundApi then return boundApi.getSkillBookRecords() end
	local out = {}
	for bookId, skills in pairs(customSkillBooks) do
		out[bookId] = {}
		for skillId, props in pairs(skills) do
			out[bookId][skillId] = makeReadOnly(props, {})
		end
	end
	return out
end

function API.getSkillBookRecord(bookId)
	bookId = string.lower(bookId)
	if boundApi then return boundApi.getSkillBookRecord(bookId) end
	if not customSkillBooks[bookId] then return nil end
	local out = {}
	for skillId, props in pairs(customSkillBooks[bookId]) do
		out[skillId] = makeReadOnly(props, {})
	end
	return out
end

function API.isSkillBookRead(bookId, skillId)
	bookId = string.lower(bookId)
	skillId = string.lower(skillId)
	if boundApi then return boundApi.isSkillBookRead(bookId, skillId) end
	return saveData.readBooks[bookId] and saveData.readBooks[bookId][skillId] or false
end

function API.setSkillBookReadState(bookId, skillId, isRead)
	bookId = string.lower(bookId)
	skillId = string.lower(skillId)
	if boundApi then
		boundApi.setSkillBookReadState(bookId, skillId, isRead)
		return
	end
	if isRead then
		saveData.readBooks[bookId] = saveData.readBooks[bookId] or {}
		saveData.readBooks[bookId][skillId] = true
	elseif saveData.readBooks[bookId] then
		saveData.readBooks[bookId][skillId] = nil
		if not next(saveData.readBooks[bookId]) then
			saveData.readBooks[bookId] = nil
		end
	end
end

-- Reentrancy flag: while a lazy-mode tick is in progress, further reads through
-- the proxy must not re-trigger the tick (callbacks that read the same stat
-- would recurse infinitely).
local _ticking = {}

function API.getSkillStat(id)
	id = string.lower(id)
	if boundApi then return boundApi.getSkillStat(id) end

	if not customSkills[id] then
		warn('getSkillStat("' .. id .. '"): unknown skill.')
		return nil
	end
	verifySkillStatLocal(id)
	if lazyMode then tickDynamicModifiersLocal(id) end

	local stat = saveData.skills[id]

	-- Change callback for __newindex: queues a pendingStatChange and re-verifies.
	local function onWrite(old)
		verifySkillStatLocal(id)
		local new = deepCopy(saveData.skills[id])
		if not pendingStatChanges[id] then
			pendingStatChanges[id] = { old = old, new = new }
		else
			pendingStatChanges[id].new = new
		end
	end

	-- Non-lazy: return the plain makeReadOnly proxy. Ticks happen in onUpdate,
	-- so reads don't need to drive them.
	if not lazyMode then
		return makeReadOnly(stat, nil, { modified = true }, onWrite)
	end

	-- Lazy mode: return a proxy whose __index ticks before returning values.
	-- This fixes staleness for callers that capture the proxy and read from it
	-- later (e.g. upvalues read during UI tooltips) without calling back into
	-- getSkillStat each time.
	local proxy = {}
	local mt = {
		__index = function(_, key)
			if not _ticking[id] then
				_ticking[id] = true
				tickDynamicModifiersLocal(id)
				_ticking[id] = nil
			end
			return stat[key]
		end,
		__newindex = function(_, key, value)
			if key == 'modified' then
				error("Attempt to modify read-only key: modified", 2)
			end
			local before = deepCopy(stat)
			rawset(stat, key, value)
			onWrite(before)
		end,
		__pairs = function() return pairs(stat) end,
		__ipairs = function() return ipairs(stat) end,
		__len = function() return #stat end,
	}
	setmetatable(proxy, mt)
	return proxy
end

function API.getSkillProgressRequirement(id)
	id = string.lower(id)
	if boundApi then return boundApi.getSkillProgressRequirement(id) end

	if not customSkills[id] then
		warn('getSkillProgressRequirement("' .. id .. '"): unknown skill.')
		return nil
	end
	verifySkillStatLocal(id)
	if lazyMode then tickDynamicModifiersLocal(id) end

	local req = customSkills[id].xpCurve(saveData.skills[id].base)
	if customSkills[id].specialization and getSpecialization() == customSkills[id].specialization then
		req = req * core.getGMST('fSpecialSkillBonus')
	end
	return req
end

function API.skillUsed(id, options)
	id = string.lower(id)
	if boundApi then
		boundApi.skillUsed(id, options)
		return
	end

	local record = API.getSkillRecord(id)
	if not record then
		warn('skillUsed("' .. id .. '"): unknown skill.')
		return
	end
	verifySkillStatLocal(id)

	options = shallowCopy(options or {})
	if options.useType and not record.skillGain[options.useType] then
		warn('skillUsed("' .. id .. '"): invalid useType ' .. tostring(options.useType))
		return
	end
	if not options.skillGain then
		if not options.useType then
			warn('skillUsed("' .. id .. '"): missing skillGain and useType.')
			return
		end
		options.skillGain = record.skillGain[options.useType]
		if options.scale then
			options.skillGain = options.skillGain * options.scale
		end
	end

	-- Run user-registered skillUsed handlers first (same semantics as SF).
	-- Standalone default skillUsed logic is appended below so it runs last.
	local userList = handlers.skillUsed
	if callHandlers(userList, id, options) then return end
	standaloneSkillUsed(id, options)
end

function API.skillLevelUp(id, source, amount)
	id = string.lower(id)
	if boundApi then
		boundApi.skillLevelUp(id, source, amount)
		return
	end

	local record = API.getSkillRecord(id)
	if not record then
		warn('skillLevelUp("' .. id .. '"): unknown skill.')
		return
	end
	verifySkillStatLocal(id)

	amount = amount or 1
	local levelUpAttrInc = core.getGMST('iLevelupMiscMultAttriubte')

	local options = {}
	if source == SkillIncreaseSource.Jail then
		options.skillIncreaseValue = -amount
	else
		options.skillIncreaseValue = amount
		options.levelUpProgress = 0
		options.levelUpAttribute = record.attribute
		options.levelUpAttributeIncreaseValue = levelUpAttrInc * amount
		options.levelUpSpecialization = record.specialization
		options.levelUpSpecializationIncreaseValue = core.getGMST('iLevelupSpecialization') * amount
	end

	if callHandlers(handlers.skillLevelUp, id, source, options) then return end
	standaloneSkillLevelUp(id, source, options)
end

function API.calcStatFactor(id, attribute)
	id = string.lower(id)
	if boundApi then return boundApi.calcStatFactor(id, attribute) end

	local record = API.getSkillRecord(id)
	if not record then
		warn('calcStatFactor("' .. id .. '"): unknown skill.')
		return nil
	end
	verifySkillStatLocal(id)
	if lazyMode then tickDynamicModifiersLocal(id) end

	if attribute == nil then attribute = record.attribute end
	local factor = saveData.skills[id].modified
	if attribute then
		factor = factor + self.type.stats.attributes[attribute](self).modified * 0.2
	end
	factor = factor + self.type.stats.attributes.luck(self).modified * 0.1
	return factor
end

function API.calcFatigueFactor()
	if boundApi then return boundApi.calcFatigueFactor() end

	local fatigueBase = core.getGMST('fFatigueBase')
	local fatigueMult = core.getGMST('fFatigueMult')
	local fatigueStat = self.type.stats.dynamic.fatigue(self)

	local normalized
	if fatigueStat.base == 0 then
		normalized = 1
	else
		normalized = math.max(0, fatigueStat.current / fatigueStat.base)
	end
	return fatigueBase - fatigueMult * (1 - normalized)
end

function API.bindGlobal(globalId, skillId)
	if self.type ~= types.Player then return end
	globalId = string.lower(globalId)
	skillId = string.lower(skillId)

	if boundApi then
		boundApi.bindGlobal(globalId, skillId)
		return
	end

	-- Standalone: we can't write MWScript globals ourselves (that requires a
	-- global script with world.mwscript access, which the wrapper can't
	-- provide on its own). Queue the binding so handoff can forward it.
	for sid, gtable in pairs(globalBindings) do
		if gtable[globalId] and sid ~= skillId then
			warn('Global "' .. globalId .. '" already bound to skill "' .. sid .. '". Overwriting.')
			gtable[globalId] = nil
		end
	end
	globalBindings[skillId] = globalBindings[skillId] or {}
	globalBindings[skillId][globalId] = true
end

function API.unbindGlobal(globalId)
	if self.type ~= types.Player then return end
	globalId = string.lower(globalId)

	if boundApi then
		boundApi.unbindGlobal(globalId)
		return
	end

	for skillId, gtable in pairs(globalBindings) do
		if gtable[globalId] then
			gtable[globalId] = nil
			if not next(gtable) then globalBindings[skillId] = nil end
		end
	end
end

--------------------------------------------------------------------------------
-- Lifecycle hooks (exposed for host script to wire up)
--------------------------------------------------------------------------------

local function scheduleBindCheck()
	async:newUnsavableSimulationTimer(BIND_DELAY,tryBind)
end

local function onInit()
	-- Mutate in place so any references captured before onLoad stay valid.
	for k in pairs(saveData) do saveData[k] = nil end
	saveData.skills = {}
	saveData.initializedSkills = {}
	saveData.readBooks = {}
	saveData.modifierStates = {}
	scheduleBindCheck()
end

local function onLoad(data)
	if not data then
		onInit()
		return
	end
	-- Mutate saveData in place (same reason as onInit).
	for k in pairs(saveData) do saveData[k] = nil end
	for k, v in pairs(data) do saveData[k] = v end
	saveData.skills = saveData.skills or {}
	saveData.initializedSkills = saveData.initializedSkills or {}
	saveData.readBooks = saveData.readBooks or {}
	saveData.modifierStates = saveData.modifierStates or {}
	scheduleBindCheck()
end

local function onSave()
	-- Standalone: saveData is already the source of truth.
	if not boundApi then
		return saveData
	end

	-- Bound: snapshot SF's live state for skills we own. If the player
	-- uninstalls SF and reloads, standalone mode will restore from this
	-- and the player keeps their progress.
	local snapshot = {
		skills = {},
		initializedSkills = {},
		readBooks = {},
		modifierStates = {}, -- always empty; standalone re-diffs from zero on first onUpdate
	}
	for skillId in pairs(ownedSkills) do
		local stat = boundApi.getSkillStat(skillId)
		if stat then
			snapshot.skills[skillId] = {
				base = stat.base,
				-- We reset modifier to 0 because SF's live modifier includes
				-- contributions from dynamic modifier callbacks. Standalone
				-- will re-register those callbacks on load and diff from 0
				-- on its first onUpdate. If we copied the modifier as-is,
				-- those deltas would double-apply. Tradeoff: any modifier
				-- the host set directly (rare) is lost in this transition.
				modifier = 0,
				progress = stat.progress,
			}
			-- If SF has a stat for it, it was initialized. Marking this
			-- prevents standalone's verifySkillStatLocal from re-applying
			-- race/class mods on top of a base that already includes them.
			snapshot.initializedSkills[skillId] = true
		end
	end
	for bookId, skills in pairs(ownedBooks) do
		for skillId in pairs(skills) do
			if boundApi.isSkillBookRead(bookId, skillId) then
				snapshot.readBooks[bookId] = snapshot.readBooks[bookId] or {}
				snapshot.readBooks[bookId][skillId] = true
			end
		end
	end
	return snapshot
end

local function onUpdate()
	if boundApi then return end

	-- Flush queued stat-change notifications. This runs regardless of lazy
	-- mode: direct writes to stat.base/modifier/progress still queue changes
	-- via the proxy's __newindex, and hosts may wire onUpdate specifically
	-- to receive those notifications.
	local changes = pendingStatChanges
	pendingStatChanges = {}
	for id, change in pairs(changes) do
		callHandlers(handlers.skillStatChanged, id, change.old, change.new)
	end

	-- In lazy mode, dynamic modifiers are ticked on read instead.
	if lazyMode then return end

	-- Dynamic modifier tick (mirrors SF's onUpdate logic). Write through
	-- the read-only proxy so skillStatChanged handlers fire for modifier
	-- changes, matching SF's behavior. The proxy's __newindex queues a
	-- pendingStatChange that'll flush on the next onUpdate tick.
	for skillId in pairs(dynamicModifiers) do
		local stat = API.getSkillStat(skillId)
		if stat then
			saveData.modifierStates[skillId] = saveData.modifierStates[skillId] or {}
			local states = saveData.modifierStates[skillId]
			for modId, cb in pairs(dynamicModifiers[skillId]) do
				local newVal = cb() or 0
				local oldVal = states[modId] or 0
				if newVal ~= oldVal then
					stat.modifier = stat.modifier + (newVal - oldVal)
					states[modId] = newVal
				end
			end
		end
	end

	-- Garbage-collect unregistered modifiers' lingering state.
	for skillId, states in pairs(saveData.modifierStates) do
		local stat = API.getSkillStat(skillId)
		if stat then
			for modId, value in pairs(states) do
				if not dynamicModifiers[skillId] or not dynamicModifiers[skillId][modId] then
					stat.modifier = stat.modifier - (value or 0)
					states[modId] = nil
				end
			end
		end
	end
end

local function onUiModeChanged(data)
	if boundApi then return end
	if data.newMode == 'Book' or data.newMode == 'Scroll' then
		if data.arg then
			standaloneOnBookRead(data.arg.recordId)
		end
	end
end

--------------------------------------------------------------------------------
-- Module exports
--------------------------------------------------------------------------------

return {
	interface = API,
	onInit = onInit,
	onLoad = onLoad,
	onSave = onSave,
	onUpdate = onUpdate,
	onUiModeChanged = onUiModeChanged,
	bind = tryBind,
}