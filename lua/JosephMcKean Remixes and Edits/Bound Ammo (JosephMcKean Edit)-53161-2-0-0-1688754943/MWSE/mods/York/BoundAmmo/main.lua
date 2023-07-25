-- Loading the magicka expanded framework
local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
if not framework then return end

local logging = require("York.BoundAmmo.logging")
local log = logging.createLogger("main")

-- Effect Id Claiming
-- Has to be outside initialized
tes3.claimSpellEffectId("boundarrow", 704)
tes3.claimSpellEffectId("boundbolt", 705)
tes3.claimSpellEffectId("boundcrossbow", 706)

local ids = {
	boundArrow = "YK_bound_arrow",
	boundArrowSpell = "YK_bound_arrow_spell",
	boundBolt = "YK_bound_bolt",
	boundBoltSpell = "YK_bound_bolt_spell",
	boundCrossbow = "YK_bound_crossbow",
	boundCrossbowSpell = "YK_bound_crossbow_spell",
}

---@param e tes3magicEffectTickEventData
---@param projectile string
local function boundProjectileOnTick(e, projectile)
	if (not e:trigger()) then return end

	local caster = e.sourceInstance.caster
	local casterMobile = caster.mobile ---@cast casterMobile tes3mobileNPC|tes3mobilePlayer|tes3mobileCreature?
	if (e.effectInstance.state == tes3.spellState.working) then
		if not casterMobile then return end
		tes3.addItem({ reference = caster, item = projectile })
		casterMobile:equip({ item = projectile, selectBestCondition = true })
	elseif (e.effectInstance.state == tes3.spellState.retired) then
		if casterMobile then tes3.removeItem({ reference = caster, item = projectile }) end
	end
end

local function addSpellEffects()
	framework.effects.conjuration.createBasicEffect({
		id = tes3.effect.boundarrow,
		name = "Bound Arrows",
		description = "The spell effect conjures a lesser Daedra bound in the form of magical, wondrously light Daedric arrows. The arrows appear automatically equipped on the caster, displacing any currently equipped ammunition to the inventory. When the effect ends, the arrows disappear.",
		baseCost = 2,

		-- Various flags.
		allowEnchanting = true,
		allowSpellmaking = true,
		appliesOnce = true,
		canCastSelf = true,
		hasNoMagnitude = true,
		nonRecastable = true,
		casterLinked = true,

		-- Graphics/sounds.
		icon = "RFD\\RFD_ms_conjuration.tga", -- this is from Magicka Expanded Core
		particleTexture = "vfx_conj_flare02.tga",
		lighting = { 0.99, 0.95, 0.67 },

		-- Required callbacks.
		---@param e tes3magicEffectTickEventData
		onTick = function(e) boundProjectileOnTick(e, ids.boundArrow) end,
	})
	framework.effects.conjuration.createBasicEffect({
		id = tes3.effect.boundbolt,
		name = "Bound Bolts",
		description = "The spell effect conjures a lesser Daedra bound in the form of magical, wondrously light Daedric bolts. The bolts appear automatically equipped on the caster, displacing any currently equipped ammunition to the inventory. When the effect ends, the bolts disappear.",
		baseCost = 2,

		-- Various flags.
		allowEnchanting = true,
		allowSpellmaking = true,
		appliesOnce = true,
		canCastSelf = true,
		hasNoMagnitude = true,
		nonRecastable = true,
		casterLinked = true,

		-- Graphics/sounds.
		icon = "RFD\\RFD_ms_conjuration.tga",
		particleTexture = "vfx_conj_flare02.tga",
		lighting = { 0.99, 0.95, 0.67 },

		-- Required callbacks.
		---@param e tes3magicEffectTickEventData
		onTick = function(e) boundProjectileOnTick(e, ids.boundBolt) end,
	})
	framework.effects.conjuration.createBasicBoundWeaponEffect({
		id = tes3.effect.boundcrossbow,
		name = "Bound Crossbow",
		description = "The spell effect conjures a lesser Daedra bound in the form of a magical, wondrously light crossbow. The crossbow appears automatically equipped on the caster when the spell is cast, displacing any currently equipped weapon in the inventory. When the effect ends, the crossbow disappears, and any previously equipped weapon is automatically re-equipped",
		baseCost = 2,
		weaponId = ids.boundCrossbow,
	})
end

local function registerSpells()
	framework.spells.createBasicSpell({ id = ids.boundArrowSpell, name = "Bound Arrows", effect = tes3.effect.boundarrow, range = tes3.effectRange.self, duration = 60 })
	framework.spells.createBasicSpell({ id = ids.boundBoltSpell, name = "Bound Bolts", effect = tes3.effect.boundbolt, range = tes3.effectRange.self, duration = 60 })
	framework.spells.createBasicSpell({ id = ids.boundCrossbowSpell, name = "Bound Crossbow", effect = tes3.effect.boundcrossbow, range = tes3.effectRange.self, duration = 60 })
end

---@param e cellChangedEventData
local function spellsDistribution(e)
	for ref in e.cell:iterateReferences(tes3.objectType.npc) do
		local mobile = ref.mobile
		if mobile and not ref.data.boundAmmoSpellAdded then
			local boundAmmoSpells = { ids.boundArrowSpell, ids.boundBoltSpell, ids.boundCrossbowSpell, "bound longbow" }
			if ref.object.spells:contains("bound longbow") or (mobile.conjuration.current >= 34 and mobile.marksman.current >= 34) then
				for _, boundAmmoSpell in ipairs(boundAmmoSpells) do
					if tes3.getObject(boundAmmoSpell) and not ref.object.spells:contains(boundAmmoSpell) then
						ref.object.spells:add(boundAmmoSpell)
					end
				end
				ref.data.operatorJackSpellAdded = true
			end
		end
	end
end

---@class BoundAmmo.projectileData
---@field effect integer
---@type table<string, BoundAmmo.projectileData>
local projectilesData = { [ids.boundArrow] = { effect = tes3.effect.boundarrow }, [ids.boundBolt] = { effect = tes3.effect.boundbolt } }

---@param mobile tes3mobileNPC|tes3mobilePlayer|tes3mobileCreature
---@param projectile string
local function startAddArrowTimer(mobile, projectile)
	timer.start({
		duration = 0.3,
		callback = function()
			local projectileData = projectilesData[projectile]
			if tes3.isAffectedBy({ reference = mobile, effect = projectileData.effect }) then
				tes3.addItem({ reference = mobile, item = projectile, limit = false })
				mobile:equip({ item = projectile, selectBestCondition = true })
			end
		end,
	})
end

---@param e attackHitEventData
local function checkIfShot(e)
	local actionData = e.mobile.actionData
	if not actionData then return end
	local nockedProjectile = actionData.nockedProjectile
	if not nockedProjectile then return end
	local projectileId = nockedProjectile.reference.id
	if projectilesData[projectileId] then startAddArrowTimer(e.mobile, projectileId) end
end

---@param e damageEventData
local function whenShot(e)
	local projectile = e.projectile
	if not projectile then return end
	if (projectile.reference.id ~= ids.boundArrow) and (projectile.reference.id ~= ids.boundBolt) then return end
	-- checks the appropriate spell effect to check if removing arrows from shot reference inventory
	local projectileData = projectilesData[projectile.reference.id]
	local hasEffect = tes3.isAffectedBy({ reference = e.reference, effect = projectileData.effect })
	-- will get the correct number of bound projectiles to remove from damaged actors inventory
	local numOfArrows = tes3.getItemCount({ reference = e.mobile, item = projectile.reference.id })
	local arrowsToRemove = 0
	if hasEffect and (numOfArrows > 1) then
		arrowsToRemove = numOfArrows - 1
	elseif (not hasEffect) and (numOfArrows > 0) then
		arrowsToRemove = numOfArrows
	end
	if arrowsToRemove > 0 then tes3.removeItem({ reference = e.mobile, item = projectile.reference.id, count = arrowsToRemove }) end
end

-- Has to be outside initialized
event.register("magicEffectsResolved", addSpellEffects)

event.register("initialized", function()
	event.register("MagickaExpanded:Register", registerSpells)
	event.register("cellActivated", spellsDistribution)
	event.register("attackHit", checkIfShot)
	event.register("damaged", whenShot)
	log:info("initialized")
end)
