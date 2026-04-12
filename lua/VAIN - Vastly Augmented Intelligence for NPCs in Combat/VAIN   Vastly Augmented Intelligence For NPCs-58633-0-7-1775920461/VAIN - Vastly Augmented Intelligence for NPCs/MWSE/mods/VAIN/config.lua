-- =============================================================================
-- VAIN.config
-- MCM-loaded configuration table and slot ID constants.
-- =============================================================================
local M = {}

--- Slot IDs used by the root domain. Each one corresponds to one MCM toggle.
M.SLOT_HEAL = 1 -- highest priority: drink a healing potion
M.SLOT_FLEE_OVERRIDE = 2
M.SLOT_SEARCH_REENGAGE = 3
M.SLOT_SESSIONLESS = 4
M.SLOT_RANGED_STANCE = 5 -- manage combat distance based on magicka availability
M.SLOT_ARCHER_STANCE = 6 -- maintain engagement distance for ranged weapon users

--- Live config table. Mutated by the MCM page in main.lua and persisted via
--- mwse.saveConfig on close. All other modules read from this table.
M.config = mwse.loadConfig("VAIN", {
	-- Original options
	atak = false, -- More frequent enemy attacks (combat delay GMSTs)
	m4 = false, -- Debug messages (combat)
	gmst = 70, -- Range weapon priority (vanilla: 5)
	stoneThrowing = true, -- Bipeds without a ranged weapon throw stones
	AIsec = 2, -- Seconds before enemy switches to throwing stones
	stdmg = 5, -- Stone throw damage

	-- HTN slot toggles. Each one mounts/unmounts an entire sub-domain at runtime.
	healPotion = true,
	fleeOverride = true,
	searchReengage = true,
	sessionless = true,
	smartMages = true, -- ranged stance + empower de-spam + magicka-out fallback
	archerStance = true, -- maintain engagement distance for ranged weapon users
	excludeScriptedCreatures = true, -- skip creatures that have an MWScript attached

	-- Empower-loop breaking
	empowerStuckMax = 5, -- Break empower loop after this many consecutive action==8 ticks
	rangedEngagementDistance = 350, -- combatSession.distance set on NPCs with offensive target-range spells
	archerEngagementDistance = 600, -- combatSession.distance set on NPCs with a readied ranged weapon
	empowerBreakCooldown = 8, -- Fallback cooldown (seconds) when the pinned spell has no duration

	-- Heal-potion behavior tuning
	healThreshold = 0.3, -- Drink when health drops below this fraction (0.0 - 1.0)

	-- HTN debug
	htnDbg = false, -- Print plan/task name in debug box

	-- Logger
	logLevel = mwse.logLevel.info,
})

return M
