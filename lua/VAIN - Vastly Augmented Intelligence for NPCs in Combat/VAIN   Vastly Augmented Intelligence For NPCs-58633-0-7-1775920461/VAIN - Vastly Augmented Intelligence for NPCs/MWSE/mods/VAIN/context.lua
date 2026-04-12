-- =============================================================================
-- VAIN.context
-- Per-enemy HTN context. Subclasses BaseContext from sb_htn.
--
-- The context holds:
--   * Per-enemy persistent state (set once in onCombatStarted): mobile ref,
--     actor object, attack type, flee limit, ranged spell list.
--   * Multi-tick operator state: stone counter, stone wind-up progress.
--   * Per-tick world snapshot, refreshed each tick by Refresh() to capture
--     every engine read in one place.
--
-- Conditions and operators read from the context only. Only operators may
-- mutate the engine.
-- =============================================================================
local htn = require("sb_htn.interop")
local BaseContext = htn.Contexts.BaseContext
local DefaultFactory = htn.Factory.DefaultFactory
local DefaultPlannerSt = htn.Planners.DefaultPlannerState

---@diagnostic disable-next-line: undefined-doc-class
---@class VainContext : BaseContext
local VainContext = BaseContext:subclass("VainContext")

function VainContext:initialize()
	BaseContext.initialize(self)

	-- Per-enemy persistent state
	self.ref = nil
	self.mobile = nil
	self.actionData = nil
	self.actorObj = nil
	self.attackType = nil -- 1 = biped (can throw stones), 3 = creature
	self.fleeLimit = 100
	self.rangedSpells = nil

	-- Multi-tick operator state
	self.counter = 0 -- frames spent under flee/search before stone throw
	self.stoneCharge = 0 -- ticks spent winding up a stone throw
	self.stoneChargeMax = 3 -- ticks of "wind-up" before the stone leaves the hand
	self.combatActive = false

	-- Heal-potion state
	self.cachedHealPotion = nil ---@type tes3alchemy?  -- last potion we found in inventory
	self.healPotionDirty = true -- if true, re-scan inventory next tick

	-- Per-tick world snapshot (Refresh sets these each tick)
	self.behaviourState = 0
	self.selectedAction = 0
	self.readiedWeapon = nil
	self.hasRangedWeapon = false
	self.playerDetected = false
	self.hasLineOfSight = false
	self.heightAdvantage = false
	self.healthNorm = 1.0
	self.magickaCurrent = 0
	self.fightValue = 0
	self.fleeValue = 0
	self.combatSession = nil
	-- Combat session detail snapshot (for logging / future conditions)
	self.combatDistance = 0 -- combatSession.distance = preferred engagement range, NOT actual distance
	self.playerDistance = 0 -- actual distance to player (mobile.playerDistance)
	self.isKnockedDown = false
	self.fatigueNorm = 1.0
	self.selectedSpellName = "-"
	self.selectedWeaponName = "-"
	self.selectedItemName = "-"

	-- Empower-loop tracking (updated in onDeterminedAction)
	self.offensiveSpells = nil -- list of {spell=tes3spell, action=4|5} built at combat start; nil if none

	self.empowerSpell = nil -- spell pinned on first action==8 tick; nil when not in empower cycle
	self.empowerTicks = 0 -- consecutive determinedAction calls with action==8
	self.empowerBrokeTime = 0 -- os.clock() when we last broke out; 0 is safe because empowerBreakDuration also starts at 0 (clock-0 < 0 is never true)
	self.empowerBreakDuration = 0 -- seconds to suppress re-entry (= pinned spell's duration, or config fallback)

	self.summonTicks = 0 -- consecutive determinedAction calls with action==6 (summon stuck counter)
	self.summonBrokeTime = -60 -- os.clock() when summon loop was last broken; -60 prevents false cooldown on first attempt

	-- Debug breadcrumb set by operators
	self.lastStatus = nil

	-- BaseContext requires these. We use direct fields rather than the
	-- WorldState slot system, so WorldState is intentionally empty.
	self.WorldState = {}
	self.Factory = DefaultFactory:new()
	self.PlannerState = DefaultPlannerSt:new()
end

--- Capture the current world state for this enemy. Called at the top of every
--- combat tick before the planner runs. Returns false if the mobile or its
--- reference has become invalid (dead/unloaded).
---@param player tes3reference
---@param playerPos tes3vector3
---@return boolean ok
function VainContext:Refresh(player, playerPos)
	local m = self.mobile
	if not (m and m.reference) then
		return false
	end

	self.combatSession = m.combatSession
	self.selectedAction = self.combatSession and self.combatSession.selectedAction or 0
	self.behaviourState = self.actionData.aiBehaviorState

	local rw = m.readiedWeapon and m.readiedWeapon.object
	self.readiedWeapon = rw
	self.hasRangedWeapon = (rw and rw.type and rw.type >= 9) and true or false

	self.playerDetected = m.isPlayerDetected
	self.hasLineOfSight = self.playerDetected and tes3.testLineOfSight { reference1 = self.ref, reference2 = player } or
	                      false

	self.heightAdvantage = math.abs(playerPos.z - self.ref.position.z) > 128 * (rw and rw.reach or 0.7)

	self.healthNorm = m.health.normalized
	self.fatigueNorm = m.fatigue.normalized
	self.magickaCurrent = m.magicka.current
	self.isKnockedDown = m.isKnockedDown or false
	self.fightValue = m.fight
	self.fleeValue = m.flee
	self.playerDistance = m.playerDistance or 0

	local cs = self.combatSession
	self.combatDistance = cs and cs.distance or 0

	local ss = cs and cs.selectedSpell
	self.selectedSpellName = ss and ss.name or "-"

	local sw = cs and cs.selectedWeapon
	self.selectedWeaponName = sw and sw.object and sw.object.name or "-"

	local si = cs and cs.selectedItem
	self.selectedItemName = si and si.object and si.object.name or "-"

	return true
end

return VainContext
