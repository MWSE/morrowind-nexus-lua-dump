-- =============================================================================
-- VAIN (Vastly Augmented Intelligence for NPCs)
--
-- Entry point. Loads all submodules, registers MWSE events, builds the root
-- domain plus three sub-domains, and mounts them into slots based on the
-- current MCM toggles.
--
-- The interesting bit is reconfigureSlots(): it's called once at init, again
-- on every load, and again whenever the MCM page closes. It clears each slot
-- and re-mounts only the ones the user has enabled. Slot toggles take effect
-- on the next planner tick - no save/reload needed.
--
-- File layout:
--   config.lua             MCM defaults, slot ID constants
--   data.lua               static spell tables, runtime spell registry
--   helpers.lua            equipStone, fireRangedSpell, dbg
--   runtime.lua            shared player/registry container
--   context.lua            VainContext class
--   operators.lua          all primitive task operators
--   domains/root.lua             root selector with 6 slots + frozen + idle tidy
--   domains/heal.lua             SLOT_HEAL
--   domains/flee_override.lua    SLOT_FLEE_OVERRIDE
--   domains/search_reengage.lua  SLOT_SEARCH_REENGAGE
--   domains/sessionless.lua      SLOT_SESSIONLESS
--   domains/ranged_stance.lua    SLOT_RANGED_STANCE
--   domains/archer_stance.lua    SLOT_ARCHER_STANCE
--   main.lua                     (this file)
-- =============================================================================
local htn = include("sb_htn.interop")
if not htn then
	mwse.log(
	"[VAIN] ERROR: sb_htn.interop not found. FluadHTN – The AI Framework is a required dependency. VAIN will not load.")
	tes3.messageBox("VAIN: FluadHTN not found. VAIN will not load. See MWSE.log for details.")
	return
end
local Planner = htn.Planners.Planner

local cfg = require("VAIN.config")
local config = cfg.config
local data = require("VAIN.data")
local helpers = require("VAIN.helpers")
local runtime = require("VAIN.runtime")
local VainContext = require("VAIN.context")
local reactionRules = require("VAIN.reaction_rules")
local scoringRules = require("VAIN.spell_scoring_rules")

-- Sub-domain factories
local buildRoot = require("VAIN.domains.root")
local buildHeal = require("VAIN.domains.heal")
local buildFleeOverride = require("VAIN.domains.flee_override")
local buildSearchReengage = require("VAIN.domains.search_reengage")
local buildSessionless = require("VAIN.domains.sessionless")
local buildRangedStance = require("VAIN.domains.ranged_stance")
local buildArcherStance = require("VAIN.domains.archer_stance")

local log = mwse.Logger.new { modName = "VAIN", moduleName = "main", level = config.logLevel }

-- Cached vanilla GMST values for the optional combat-delay tweak (nil until first applyGMSTConfig call).
local origCombatDelayCreature
local origCombatDelayNPC

-- =============================================================================
-- AI STATE TABLES
-- BEH_NAME: tes3.aiBehaviorState - https://mwse.github.io/MWSE/references/ai-behavior-states/
--   Values 1 and 5 are not in the official reference but appear in combat logs.
--   1 is tentatively "pursue" (observed during active chase with LOS).
--   5 is tentatively "search" (behaviourState == 5 in search_reengage.lua fires when the actor loses the player).
-- ACT_NAME: tes3combatSession.selectedAction - https://mwse.github.io/MWSE/types/tes3combatSession/#selectedaction
--   All values are official.
-- =============================================================================

local BEH_NAME = {
	[-1] = "frozen", -- official: no decision yet; observed when control spells fire
	[0] = "hello", -- official
	[1] = "pursue", -- not in reference; tentative - observed during active chase with LOS
	[2] = "idle", -- official
	[3] = "attack", -- official: active melee/ranged combat
	[4] = "avoid", -- official: meaning unclear; not yet observed in logs
	[5] = "search", -- not in reference; tentative - seen when player is lost
	[6] = "flee", -- official
	[8] = "walk", -- official: setAITravel forces this state, kills the combat session
	[12] = "greet", -- official
	[16] = "?", -- observed when in combat but target not yet detected (pre-pursue?)
}

local ACT_NAME = {
	[0] = "undecided", -- official
	[1] = "melee", -- official: use melee weapon
	[2] = "marksman", -- official: use marksman weapon
	[3] = "h2h", -- official: use hand-to-hand attacks. should be used by NPCs with no weapons equipped
	[4] = "touch-spell", -- official: use on-touch offensive spell
	[5] = "target-spell", -- official: use on-target offensive spell
	[6] = "summon", -- official: use summon spell
	[7] = "flee", -- official
	[8] = "empower", -- official: cast empowering spell (e.g. Ancestor Guardian)
	[9] = "alchemy", -- official: use alchemy item
	[10] = "enchanted", -- official: use enchanted item
}

local function behStr(v)
	return string.format("%d(%s)", v, BEH_NAME[v] or "?")
end
local function actStr(v)
	return string.format("%d(%s)", v, ACT_NAME[v] or "?")
end

-- =============================================================================
-- HTN STATE
-- =============================================================================

local rootDomain ---@type table  -- sb_htn Domain (untyped external library)
local sharedPlanner ---@type table  -- sb_htn Planner (untyped external library)
local subDomains = {} -- slotId -> built sub-domain (rebuilt on init only)

local timerHandle ---@type mwseTimer?

-- =============================================================================
-- SLOT MANAGEMENT
-- Mount/unmount sub-domains based on the current MCM toggles. Cheap enough
-- to call on every MCM close - it just walks 3 slot IDs.
-- =============================================================================

local function mountSlot(slotId, subDomain)
	rootDomain:ClearSlot(slotId) ---@diagnostic disable-line: undefined-field
	rootDomain:TrySetSlotDomain(slotId, subDomain) ---@diagnostic disable-line: undefined-field
end

-- Apply (or restore) the optional combat-delay GMSTs and range weapon priority.
-- Captures the vanilla values on first call (before any modification) and reuses
-- them for all subsequent calls, so toggling off always restores correctly.
local function applyGMSTConfig()
	tes3.findGMST("fAIRangeMeleeWeaponMult").value = config.gmst
	if origCombatDelayCreature == nil then
		origCombatDelayCreature = tes3.findGMST("fCombatDelayCreature").value
		origCombatDelayNPC = tes3.findGMST("fCombatDelayNPC").value
	end
	if config.atak then
		tes3.findGMST("fCombatDelayCreature").value = -0.4
		tes3.findGMST("fCombatDelayNPC").value = -0.4
	else
		tes3.findGMST("fCombatDelayCreature").value = origCombatDelayCreature
		tes3.findGMST("fCombatDelayNPC").value = origCombatDelayNPC
	end
end

local function reconfigureSlots()
	if not rootDomain then
		return
	end

	if config.healPotion then
		mountSlot(cfg.SLOT_HEAL, subDomains[cfg.SLOT_HEAL])
	else
		rootDomain:ClearSlot(cfg.SLOT_HEAL) ---@diagnostic disable-line: undefined-field
	end

	if config.fleeOverride then
		mountSlot(cfg.SLOT_FLEE_OVERRIDE, subDomains[cfg.SLOT_FLEE_OVERRIDE])
	else
		rootDomain:ClearSlot(cfg.SLOT_FLEE_OVERRIDE) ---@diagnostic disable-line: undefined-field
	end

	if config.searchReengage then
		mountSlot(cfg.SLOT_SEARCH_REENGAGE, subDomains[cfg.SLOT_SEARCH_REENGAGE])
	else
		rootDomain:ClearSlot(cfg.SLOT_SEARCH_REENGAGE) ---@diagnostic disable-line: undefined-field
	end

	if config.sessionless then
		mountSlot(cfg.SLOT_SESSIONLESS, subDomains[cfg.SLOT_SESSIONLESS])
	else
		rootDomain:ClearSlot(cfg.SLOT_SESSIONLESS) ---@diagnostic disable-line: undefined-field
	end

	if config.smartMages then
		mountSlot(cfg.SLOT_RANGED_STANCE, subDomains[cfg.SLOT_RANGED_STANCE])
	else
		rootDomain:ClearSlot(cfg.SLOT_RANGED_STANCE) ---@diagnostic disable-line: undefined-field
	end

	if config.archerStance then
		mountSlot(cfg.SLOT_ARCHER_STANCE, subDomains[cfg.SLOT_ARCHER_STANCE])
	else
		rootDomain:ClearSlot(cfg.SLOT_ARCHER_STANCE) ---@diagnostic disable-line: undefined-field
	end

	mwse.log("[VAIN] Slots reconfigured: heal=%s flee=%s search=%s sessionless=%s smartMages=%s archerStance=%s",
	         tostring(config.healPotion), tostring(config.fleeOverride), tostring(config.searchReengage),
	         tostring(config.sessionless), tostring(config.smartMages), tostring(config.archerStance))
end

-- =============================================================================
-- COMBAT TICK
-- =============================================================================

local function runCombatTick()
	for ref, enemy in pairs(runtime.activeEnemies) do
		local ctx = enemy.htnContext

		if not (ctx and ctx.mobile and ctx.mobile.reference) then
			runtime.activeEnemies[ref] = nil
		else
			local ok = ctx:Refresh(runtime.player, runtime.playerPos)
			if ok then
				sharedPlanner:Tick(rootDomain, ctx) ---@diagnostic disable-line: undefined-field

				log:debug(
				"[%7.2fs] %-20s  beh=%-12s act=%-16s  hp=%3d%%  fat=%3d%%%s  fight=%3d  flee=%3d/%3d  det=%-5s los=%-5s  HTN:%s",
				os.clock(), enemy.actorObj.name, behStr(ctx.behaviourState), actStr(ctx.selectedAction),
				math.floor(ctx.healthNorm * 100), math.floor(ctx.fatigueNorm * 100), ctx.isKnockedDown and "(KO)" or "    ",
				ctx.fightValue, ctx.fleeValue, ctx.fleeLimit, tostring(ctx.playerDetected), tostring(ctx.hasLineOfSight),
				ctx.lastStatus or "?")
				log:debug("  pdist=%-6.0f  spell=%-24s  wpn=%-20s  item=%s", ctx.playerDistance, ctx.selectedSpellName,
				          ctx.selectedWeaponName, ctx.selectedItemName)

				if config.htnDbg then
					local cur = ctx.PlannerState.CurrentTask
					tes3.messageBox("%s: %s [%s]", enemy.actorObj.name, ctx.lastStatus or "?", cur and cur.Name or "<no task>")
				end

				if config.m4 then
					tes3.messageBox("%s %s(%s) fl %d/%d  fg %d  Beh = %s  SA = %s  %s", ref, ctx.lastStatus or "",
					                ctx.counter > 0 and ctx.counter or "", enemy.mobile.flee, enemy.fleeLimit, enemy.mobile.fight,
					                ctx.behaviourState, ctx.selectedAction, enemy.mobile.isPlayerDetected and "" or "No detect")
				end
			end
		end
	end

	if table.size(runtime.activeEnemies) == 0 then
		if timerHandle then
			timerHandle:cancel()
		end
		timerHandle = nil
		if config.m4 then
			tes3.messageBox("The battle is over!")
		end
	end
end

-- =============================================================================
-- EVENT: combatStarted
-- =============================================================================

local function onCombatStarted(e)
	local mobile = e.actor
	local ref = mobile.reference

	if e.target ~= runtime.mobilePlayer then
		return
	end
	if runtime.activeEnemies[ref] then
		return
	end
	if not mobile.combatSession then
		return
	end

	local actorObj = mobile.object

	if config.excludeScriptedCreatures and mobile.actorType == tes3.actorType.creature and actorObj.script then
		log:debug("[combatStarted] %s: skipped (scripted creature)", actorObj.name)
		return
	end

	local attackType = (mobile.actorType == 1 or actorObj.biped) and 1 or (not actorObj.usesEquipment and 3)

	local ctx = VainContext:new() ---@diagnostic disable-line: undefined-field
	ctx.ref = ref
	ctx.mobile = mobile
	ctx.actionData = mobile.actionData
	ctx.actorObj = actorObj
	ctx.attackType = attackType
	ctx.fleeLimit = math.max(70 + actorObj.level * 5, 100)
	ctx.rangedSpells = data.monsterSpells[actorObj.baseObject.id]
	ctx:Init()

	runtime.activeEnemies[ref] = { mobile = mobile, actorObj = actorObj, fleeLimit = ctx.fleeLimit, htnContext = ctx }

	-- Smart Mages: build offensive spell list, set initial ranged combat distance.
	-- The distance is then managed dynamically each tick by the ranged_stance HTN domain.
	if config.smartMages then
		local offSpells = helpers.buildOffensiveSpellList(actorObj)
		ctx.offensiveSpells = #offSpells > 0 and offSpells or nil
		local targetCount = 0
		for _, entry in ipairs(offSpells) do
			if entry.action == 5 then
				targetCount = targetCount + 1
			end
		end
		if targetCount > 0 then
			mobile.combatSession.distance = config.rangedEngagementDistance
			log:debug("[combatStarted] %s: %d offensive spells (%d target-range), set combat distance to %d", actorObj.name,
			          #offSpells, targetCount, config.rangedEngagementDistance)
		elseif #offSpells > 0 then
			log:debug("[combatStarted] %s: %d offensive spells (touch-range only)", actorObj.name, #offSpells)
		end
	end

	local spellNames = {}
	for _, spell in pairs(actorObj.spells) do
		spellNames[#spellNames + 1] = spell.name
	end
	log:debug("[combatStarted] %-20s  type=%-8s  fleeLimit=%d  rangedSpells=%-5s  spells(%d): %s", actorObj.name,
	          attackType == 1 and "biped" or "creature", ctx.fleeLimit, tostring(ctx.rangedSpells ~= nil), #spellNames,
	          #spellNames > 0 and table.concat(spellNames, " | ") or "none")

	timer.delayOneFrame(function()
		if runtime.activeEnemies[ref] then
			runtime.activeEnemies[ref].htnContext.combatActive = true
		end
	end)

	if config.m4 then
		tes3.messageBox("%s joined the battle! Enemies = %s", actorObj.name, table.size(runtime.activeEnemies))
	end

	if not timerHandle then
		timerHandle = timer.start { duration = 1, iterations = -1, callback = runCombatTick }
	end
end

event.register("combatStarted", onCombatStarted)

-- =============================================================================
-- EVENT: determinedAction
-- Intercepts the engine's action choice for any tracked enemy and applies
-- three overrides:
--   1. Flee suppression: prevent flee when health and flee stat are reasonable.
--   2. Summon without detection: cast summon spells even when the player is not
--      detected (summons are self-targeted and need no LOS). Guards against
--      spam by skipping if the summon is already active.
--   3. Bound-weapon de-spam: if the engine picks an empower spell that is
--      already active, switch to another castable spell instead. Falls back to
--      melee if no alternative is available.
-- =============================================================================

--- Recursively applies a matched rule then follows its `next` chain if defined.
local function applyRuleChain(rule, e, ctx)
	rule.apply(e, ctx)
	if rule.next then
		local nextRule = reactionRules._index[rule.next]
		if nextRule and nextRule.match(e, ctx) then
			applyRuleChain(nextRule, e, ctx)
		end
	end
end

local function onDeterminedAction(e)
	local session = e.session
	local enemy = runtime.activeEnemies[session.mobile.reference]
	if not enemy then
		return
	end
	local ctx = enemy.htnContext
	local action = session.selectedAction

	local branch = reactionRules[action]
	if branch then
		for _, rule in ipairs(branch) do
			if rule.match(e, ctx) then
				applyRuleChain(rule, e, ctx)
				return
			end
		end
		return -- branch handled this action (even if no rule matched); skip fallback
	end

	-- No branch: non-combat actions (melee, h2h, marksman, alchemy, enchanted).
	-- Reset all loop counters so the next cycle starts clean.
	ctx.summonTicks = 0
	ctx.empowerTicks = 0
	ctx.empowerSpell = nil
end

event.register("determinedAction", onDeterminedAction)

-- =============================================================================
-- EVENT: mobileDeactivated
-- =============================================================================

event.register("mobileDeactivated", function(e)
	runtime.activeEnemies[e.reference] = nil
end)

-- =============================================================================
-- EVENT: loaded
-- =============================================================================

event.register("loaded", function()
	runtime.player = tes3.player
	runtime.mobilePlayer = tes3.mobilePlayer
	runtime.playerPos = tes3.player.position
	runtime.activeEnemies = {}
	applyGMSTConfig()
	-- Re-mount slots in case the player changed MCM toggles in the main menu
	reconfigureSlots()
end)

-- =============================================================================
-- EVENT: modConfigReady
-- =============================================================================

event.register("modConfigReady", function()
	local template = mwse.mcm.createTemplate("VAIN")
	template:register()

	-- Custom onClose: save config AND re-mount slots based on new toggle values.
	-- We don't use template:saveOnClose() because it overwrites onClose entirely;
	-- we want both behaviors so we set onClose ourselves.
	template.onClose = function()
		mwse.saveConfig("VAIN", config)
		applyGMSTConfig()
		reconfigureSlots()
	end

	local makeVar = mwse.mcm.createTableVariable

	-- ---------- Combat behavior page ----------
	local combatPage = template:createSideBarPage{ label = "Combat" }
	combatPage.sidebar:createInfo{
		text = "Hover over any option to see what it does.\n\n" ..
		"Most toggles mount or unmount HTN sub-domains and take effect on the next " ..
		"planner tick - no save or reload required.",
	}

	-- General
	local catGeneral = combatPage:createCategory{ label = "General" }
	catGeneral:createYesNoButton{
		label = "Exclude scripted creatures",
		description = "Prevents VAIN from running on creatures that are under script " ..
		"control. Recommended - disabling this can interfere with scripted encounters " ..
		"and quest creatures.",
		variable = makeVar { id = "excludeScriptedCreatures", table = config },
	}

	-- Healing
	local catHeal = combatPage:createCategory{ label = "Healing" }
	catHeal:createYesNoButton{
		label = "Drink healing potion when low health",
		description = "When an NPC's health drops below the threshold, VAIN searches " ..
		"their inventory for a healing potion and drinks it. Takes effect on the next " ..
		"planner tick.",
		variable = makeVar { id = "healPotion", table = config },
	}
	catHeal:createPercentageSlider{
		label = "Heal threshold",
		description = "Health percentage below which an NPC will attempt to drink a " ..
		"healing potion.",
		variable = makeVar { id = "healThreshold", table = config },
	}

	-- Pursuit & re-engagement
	local catPursuit = combatPage:createCategory{ label = "Pursuit & re-engagement" }
	catPursuit:createYesNoButton{
		label = "Fleeing bipeds switch to ranged attacks or charge melee",
		description = "Intercepts the flee behaviour. Instead of running, the NPC " ..
		"fights back using the best option available:\n\n" ..
		"1. Ranged weapon (bow, crossbow, thrown) if readied\n" ..
		"2. Monster ranged spells if available\n" ..
		"3. Stones as a fallback (if stone throwing is enabled below)\n" ..
		"4. Charge melee if none of the above apply\n\n" ..
		"A short delay before throwing stones gives a moment of hesitation, " ..
		"configurable below.",
		variable = makeVar { id = "fleeOverride", table = config },
	}
	catPursuit:createYesNoButton{
		label = "Re-engage from search/flee state",
		description = "When an NPC has lost the player (search state) or is fleeing " ..
		"but still has line of sight, VAIN forces re-engagement. Priority order:\n\n" ..
		"1. Ranged weapon if readied\n" ..
		"2. Monster ranged spells if available\n" ..
		"3. Stones as a fallback (if stone throwing is enabled below)\n" ..
		"4. Hold position if none of the above apply or line of sight is lost\n\n" ..
		"Unlike flee mode, there is no delay before throwing stones here - the " ..
		"player has already been spotted.",
		variable = makeVar { id = "searchReengage", table = config },
	}
	catPursuit:createYesNoButton{
		label = "Force re-engage when session drops",
		description = "Detects when the combat session is silently dropped mid-fight " ..
		"(can happen after a summon completes) and calls startCombat again to resume " ..
		"pursuit.",
		variable = makeVar { id = "sessionless", table = config },
	}
	catPursuit:createYesNoButton{
		label = "Enable stone throwing",
		description = "Bipeds without a ranged weapon or monster ranged spells will " ..
		"pick up and throw stones. NPCs that have either of those will use them instead " ..
		"and never reach the stone path.\n\n" ..
		"This toggle affects both 'Fleeing bipeds' and 'Re-engage from search' above - " ..
		"disabling it removes the stone path from both.",
		variable = makeVar { id = "stoneThrowing", table = config },
	}
	catPursuit:createSlider{
		label = "Stone throw delay (flee mode only)",
		description = "Seconds a fleeing biped waits before reaching for a stone. " ..
		"Gives a moment of hesitation before switching from flee to attack.\n\n" ..
		"Has no effect in search mode - NPCs that have already spotted the player " ..
		"throw immediately.",
		min = 0,
		max = 10,
		step = 1,
		jump = 1,
		variable = makeVar { id = "AIsec", table = config },
	}
	catPursuit:createSlider{
		label = "Stone damage",
		description = "Maximum damage per stone hit.\n\nRequires a game restart - " ..
		"the stone weapon object is created once at startup.",
		min = 1,
		max = 10,
		step = 1,
		jump = 1,
		variable = makeVar { id = "stdmg", table = config },
		restartRequired = true,
	}

	-- Ranged combat
	local catRanged = combatPage:createCategory{ label = "Ranged combat" }
	catRanged:createYesNoButton{
		label = "Smart Mages",
		description = "For NPCs with offensive target-range spells: widens engagement " ..
		"distance while they have enough magicka to cast, collapsing back to melee " ..
		"range when magicka runs low. Also reduces empower/dispel spam.",
		variable = makeVar { id = "smartMages", table = config },
	}
	catRanged:createYesNoButton{
		label = "Archer stance",
		description = "Keeps ranged weapon users at a preferred distance rather than " ..
		"letting the engine push them into melee range.",
		variable = makeVar { id = "archerStance", table = config },
	}
	catRanged:createSlider{
		label = "Archer engagement distance",
		description = "Distance (in game units) that archers try to maintain from the " ..
		"player. Vanilla combat distance is around 128.",
		min = 100,
		max = 1500,
		step = 50,
		jump = 100,
		variable = makeVar { id = "archerEngagementDistance", table = config },
	}

	-- Engine tweaks
	local catEngine = combatPage:createCategory{ label = "Engine tweaks" }
	catEngine:createYesNoButton{
		label = "More frequent attacks",
		description = "Sets fCombatDelayCreature and fCombatDelayNPC to -0.4, making " ..
		"enemies attack more often. Disabled by default to avoid conflicts with other " ..
		"mods that touch these GMSTs.\n\nTakes effect immediately when you close the " ..
		"MCM. Toggling off restores the vanilla values.",
		variable = makeVar { id = "atak", table = config },
	}
	catEngine:createSlider{
		label = "Range weapon priority",
		description = "Controls fAIRangeMeleeWeaponMult: how strongly the AI prefers " ..
		"ranged weapons over melee. Vanilla default is 5; VAIN default is 70.\n\n" ..
		"Takes effect immediately when you close the MCM.",
		min = 0,
		max = 100,
		step = 1,
		jump = 5,
		variable = makeVar { id = "gmst", table = config },
	}

	-- ---------- Debug page ----------
	local debugPage = template:createSideBarPage{ label = "Debug" }
	debugPage.sidebar:createInfo{
		text = "Log level controls what gets written to MWSE.log.\n\n" ..
		"DEBUG: logs AI state every combat tick - beh(aviour state), act(ion), " ..
		"hp, fight, flee, line-of-sight, and the HTN decision. Useful for " ..
		"understanding the engine's combat state machine.\n\n" .. "TRACE: maximum verbosity.",
	}
	debugPage:createLogLevelOptions{ logger = "VAIN", variable = makeVar { id = "logLevel", table = config } }
	debugPage:createYesNoButton{
		label = "Show combat debug messages (on-screen)",
		variable = makeVar { id = "m4", table = config },
	}
	debugPage:createYesNoButton{
		label = "Show HTN plan debug (on-screen)",
		variable = makeVar { id = "htnDbg", table = config },
	}
end)

-- =============================================================================
-- EVENT: initialized
-- =============================================================================

event.register("initialized", function()
	-- Throwing stone weapon

	data.stone = tes3.getObject("4nm_stone") or tes3.createObject {
		objectType = tes3.objectType.weapon,
		id = "4nm_stone",
		name = "Stone",
		type = 11,
		mesh = "w\\stone.nif",
		icon = "w\\stone.tga",
		weight = 1,
		value = 0,
		maxCondition = 100,
		enchantCapacity = 0,
		reach = 1,
		speed = 1,
		chopMin = 0,
		chopMax = 5,
		slashMin = 0,
		slashMax = 5,
		thrustMin = 0,
		thrustMax = 5,
	}
	data.stone.chopMax = config.stdmg

	-- Projectile alchemy objects
	for _, spellDef in ipairs(data.spellDefs) do
		local alch = tes3.createObject {
			objectType = tes3.objectType.alchemy,
			id = "4_" .. spellDef.n,
			name = "4_" .. spellDef.n,
			icon = "s\\b_tx_s_sun_dmg.dds",
		} ---@cast alch tes3alchemy
		alch.sourceless = true
		for i, effect in ipairs(spellDef) do
			alch.effects[i].rangeType = effect[1]
			alch.effects[i].id = effect[2]
			alch.effects[i].min = effect[3]
			alch.effects[i].max = effect[4]
			alch.effects[i].radius = effect[5]
			alch.effects[i].duration = effect[6]
		end
		data.spells[spellDef.n] = alch
	end

	-- AI tuning GMSTs
	tes3.findGMST("fAIFleeFleeMult").value = 0
	tes3.findGMST("fAIFleeHealthMult").value = 88.888
	tes3.findGMST("fFleeDistance").value = 5000
	tes3.findGMST("iAutoSpellTimesCanCast").value = 5
	tes3.findGMST("iAutoSpellConjurationMax").value = 3
	tes3.findGMST("iAutoSpellDestructionMax").value = 15
	tes3.findGMST("fMagicCreatureCastDelay").value = 0
	applyGMSTConfig()

	-- Build the root domain (with empty slots) and the three sub-domains.
	-- Each is built exactly once and then reused across every enemy and tick.
	rootDomain = buildRoot(VainContext)
	sharedPlanner = Planner:new() ---@diagnostic disable-line: undefined-field

	subDomains[cfg.SLOT_HEAL] = buildHeal(VainContext)
	subDomains[cfg.SLOT_FLEE_OVERRIDE] = buildFleeOverride(VainContext)
	subDomains[cfg.SLOT_SEARCH_REENGAGE] = buildSearchReengage(VainContext)
	subDomains[cfg.SLOT_SESSIONLESS] = buildSessionless(VainContext)
	subDomains[cfg.SLOT_RANGED_STANCE] = buildRangedStance(VainContext)
	subDomains[cfg.SLOT_ARCHER_STANCE] = buildArcherStance(VainContext)

	reconfigureSlots()
	helpers.setScoringRules(scoringRules)

	mwse.log("[VAIN] Initialized. Root domain + 6 sub-domains built.")
end)
