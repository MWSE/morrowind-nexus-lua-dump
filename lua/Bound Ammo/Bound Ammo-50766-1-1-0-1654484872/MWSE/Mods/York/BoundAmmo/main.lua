local common = require("York.BoundAmmo.common")

--Effect Id Claiming
tes3.claimSpellEffectId("boundarrow", 704)
tes3.claimSpellEffectId("boundbolt",705)
tes3.claimSpellEffectId("boundcrossbow",706)

local ids = {
	boundArrow = "YK_bound_arrow",
	boundArrowSpell = "YK_bound_arrow_spell",
	boundBolt = "YK_bound_bolt",
	boundBoltSpell ="YK_bound_bolt_spell",
	boundCrossbow = "YK_bound_crossbow",
	boundCrossbowSpell = "YK_bound_crossbow_spell",
}

local tomes = {
	{
		id = "YK_bound_crossbow_tome",
		spellId = ids.boundCrossbowSpell,
	},
}

local distributions = {
	["Estirdalin"] = {
        ids.boundArrowSpell,
		ids.boundBoltSpell,
    },
	["Masalinie Merian"] = {
		ids.boundArrowSpell,
		ids.boundBoltSpell,
	}
}

-- Including the magicka expanded framework
local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
if (framework == nil) then
    local function warning()
        tes3.messageBox(
            "["..string.upper(common.modname)..": ERROR] Magicka Expanded framework is not installed!"
            .. " You will need to install it to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end

local function onInit(e)
	common.info("initialized BoundAmmo")
end

local function BoundArrowOnTick(e)
	if (not e:trigger()) then
		return
	end
	
	if (e.effectInstance.state == tes3.spellState.working) then
		if e.sourceInstance.caster.mobile then
			tes3.addItem({ reference = e.sourceInstance.caster.mobile, item = ids.boundArrow, limit = false})
			e.sourceInstance.caster.mobile:equip({item = ids.boundArrow, addItem = false, selectBestCondition = true, selectWorstCondition = false})
		end
	elseif (e.effectInstance.state == tes3.spellState.retired)then
		if e.sourceInstance.caster.mobile then
			tes3.removeItem({ reference = e.sourceInstance.caster.mobile, item = ids.boundArrow})
		end
	end
	--common.info("spell state"..e.effectInstance.state)
end

local function BoundBoltOnTick(e)
	if (not e:trigger()) then
		return
	end
	
	if (e.effectInstance.state == tes3.spellState.working) then
		if e.sourceInstance.caster.mobile then
			tes3.addItem({ reference = e.sourceInstance.caster.mobile, item = ids.boundBolt, limit = false})
			e.sourceInstance.caster.mobile:equip({item = ids.boundBolt, addItem = false, selectBestCondition = true, selectWorstCondition = false})
		end
	elseif (e.effectInstance.state == tes3.spellState.retired)then
		if e.sourceInstance.caster.mobile then
			tes3.removeItem({ reference = e.sourceInstance.caster.mobile, item = ids.boundBolt})
		end
	end
	--common.info("spell state"..e.effectInstance.state)
end


local function addSpellEffects()
	framework.effects.conjuration.createBasicEffect({
		id = tes3.effect.boundarrow,
		name = "Bound Arrows",
		description = "The spell effect conjures a lesser Daedra bound in the form of magical, wondrously light Daedric arrows. The arrows appear automatically equipped on the caster, displacing any currently equipped ammunition to the inventory. When the effect ends, the arrows disappear.",
		baseCost = 2,
		weaponId = ids.boundArrow,
		
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
		onTick = BoundArrowOnTick,
	})
	framework.effects.conjuration.createBasicEffect({
		id = tes3.effect.boundbolt,
		name = "Bound Bolts",
		description = "The spell effect conjures a lesser Daedra bound in the form of magical, wondrously light Daedric bolts. The bolts appear automatically equipped on the caster, displacing any currently equipped ammunition to the inventory. When the effect ends, the bolts disappear.",
		baseCost = 2,
		weaponId = ids.boundBolt,
		
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
		onTick = BoundBoltOnTick,
	})
	framework.effects.conjuration.createBasicBoundWeaponEffect({
		id = tes3.effect.boundcrossbow,
		name = "Bound Crossbow",
		description = "The spell effect conjures a lesser Daedra bound in the form of a magical, wondrously light crossbow. The crossbow appears automatically equipped on the caster when the spell is cast, displacing any currently equipped weapon in the inventory. When the effect ends, the crossbow disappears, and any previously equipped weapon is automatically re-equipped",
		baseCost = 2,
		weaponId = ids.boundCrossbow,
	})
end


event.register("magicEffectsResolved", addSpellEffects)

local function registerSpells()
	framework.spells.createBasicSpell({
		id = ids.boundArrowSpell,
		name = "Bound Arrows",
		effect = tes3.effect.boundarrow,
		range = tes3.effectRange.self,
		duration = 60,
	})
	framework.spells.createBasicSpell({
		id = ids.boundBoltSpell,
		name = "Bound Bolts",
		effect = tes3.effect.boundbolt,
		range = tes3.effectRange.self,
		duration = 60,
	})
	framework.spells.createBasicSpell({
		id = ids.boundCrossbowSpell,
		name = "Bound Crossbow",
		effect = tes3.effect.boundcrossbow,
		range = tes3.effectRange.self,
		duration = 60,
	})
	framework.tomes.registerTomes(tomes)
	for npcId, distributionSpellIds in pairs(distributions) do
        local npc = tes3.getObject(npcId)
        if (npc) then
            if (type(distributionSpellIds) ~= "table") then
                local spell = tes3.getObject(distributionSpellIds)
                if (spell) then
                    npc.spells:add(spell)
                end
            else
                for _, spellId in pairs(distributionSpellIds) do
                    local spell = tes3.getObject(spellId)
                    if (spell) then
                        npc.spells:add(spell)
                    end
                end
            end
        end
    end
end


local function checkIfShot(e)
	if e.mobile.actionData.nockedProjectile then
		--common.info("arrow gave not nil")
		if e.mobile.actionData.nockedProjectile.reference.id == ids.boundArrow then
			timer.start({
				duration = .3,
				callback = function() 
					if tes3.isAffectedBy({reference = e.reference, effect = tes3.effect.boundarrow}) then
						tes3.addItem({ reference = e.mobile, item = ids.boundArrow, limit = false})
						e.mobile:equip({item = ids.boundArrow, addItem = false, selectBestCondition = true, selectWorstCondition = false})
					end
				end,
				type = timer.simulate
			})
		elseif e.mobile.actionData.nockedProjectile.reference.id == ids.boundBolt then
			timer.start({
				duration = .3,
				callback = function()
					if tes3.isAffectedBy({reference = e.reference, effect = tes3.effect.boundbolt})then
						tes3.addItem({ reference = e.mobile, item = ids.boundBolt, limit = false})
						e.mobile:equip({item = ids.boundBolt, addItem = false, selectBestCondition = true, selectWorstCondition = false})
					end
				end,
				type = timer.simulate
			})
		end		
	else
		--common.info("arrow gave nil")
	end
end

local function whenShot(e)
	if e.projectile then
		if (e.projectile.reference.id == ids.boundArrow) or (e.projectile.reference.id == ids.boundBolt) then
			--checks the appropriate spell effect to check removing arrows from shot reference inventory
			local hasEffect
			if e.projectile.reference.id == ids.boundArrow then 
				hasEffect = tes3.isAffectedBy({reference = e.reference, effect = tes3.effect.boundarrow})
			elseif e.projectile.reference.id == ids.boundBolt then
				hasEffect = tes3.isAffectedBy({reference = e.reference, effect = tes3.effect.boundbolt})
			end
			--will get the correct number of bound projectiles to remove from damaged actors inventory
			local numOfArrows = tes3.getItemCount({reference = e.mobile, item = e.projectile.reference.id})
			local arrowsToRemove = 0
			if hasEffect and (numOfArrows > 1) then
				arrowsToRemove = numOfArrows - 1
			elseif (not hasEffect) and (numOfArrows > 0) then
				arrowsToRemove = numOfArrows
			end
			if arrowsToRemove > 0 then
				tes3.removeItem({reference = e.mobile, item = e.projectile.reference.id, count = arrowsToRemove})
			end
		end
	end
end

event.register("damaged", whenShot)
event.register("initialized", onInit)
event.register("attack",checkIfShot)
event.register("MagickaExpanded:Register", registerSpells)