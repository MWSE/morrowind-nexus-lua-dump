-- =============================================================================
-- VAIN.domains.root
--
-- The root domain. Contains:
--   * Three Slots (FleeOverride, SearchReengage, Sessionless) that main.lua
--     mounts and unmounts at runtime based on MCM toggles.
--   * Two always-on inline branches (Frozen handler, Idle Tidy fallback) that
--     are universal and cheap, and don't benefit from being toggleable.
--
-- Slot order = priority order (Selector tries top to bottom). Each Slot, if
-- empty, simply fails to decompose and the Selector moves on. This means
-- toggling a slot off via MCM is "free" - no rebuild needed.
-- =============================================================================
local htn = require("sb_htn.interop")
local operators = require("VAIN.operators")
local cfg = require("VAIN.config")

---@param ContextClass table
---@return table  -- sb_htn Domain (untyped external library)
local function build(ContextClass)
	local b = htn.DomainBuilder:new(ContextClass, "VAINRoot")

	b:Select("VAIN Root") -- Slot 0 (highest priority): Heal up if low health and has potion
	:Slot(cfg.SLOT_HEAL) -- Slot 1: Override flee (mounted/unmounted at runtime)
	:Slot(cfg.SLOT_FLEE_OVERRIDE) -- Slot 2: Re-engage from search/flee
	:Slot(cfg.SLOT_SEARCH_REENGAGE) -- Slot 3: No combat session (force re-engage / give up)
	:Slot(cfg.SLOT_SESSIONLESS) -- Slot 4: Manage combat distance for NPCs with offensive target-range spells
	:Slot(cfg.SLOT_RANGED_STANCE) -- Slot 5: Maintain engagement distance for ranged weapon users
	:Slot(cfg.SLOT_ARCHER_STANCE) -- Always-on: frozen state (-1) handler - control spell or stuck
	:Sequence("Frozen handler"):Condition("Frozen", function(ctx)
		return ctx.behaviourState == -1
	end):Action("Check control / restart"):Do(operators.checkControlSpell):End():End() -- Always-on fallback: idle tidy. Always succeeds, resets stone counter
	-- if needed. Without this the planner would have nothing to do during
	-- normal melee combat and would fail every tick.
	:Action("Idle tidy"):Do(operators.idleTidy):End():End()

	return b:Build()
end

return build
