local magickaExpanded = require("OperatorJack.MagickaExpanded.magickaExpanded")
local strings = require("NecroCraft.strings")
local utility = require("NecroCraft.utility")
local undead = require("NecroCraft.undead")
local soulGemLib = require("NecroCraft.soulgem")
local lichdom = require("NecroCraft.lichdom")

local effects = {}

effects.onTick = require("NecroCraft.magic.onTick")

tes3.claimSpellEffectId("callSkeletonCripple", 656)
tes3.claimSpellEffectId("callSkeletonWarrior", 657)
tes3.claimSpellEffectId("callSkeletonChampion", 658)
tes3.claimSpellEffectId("callBonespider", 659)
tes3.claimSpellEffectId("callBonelord", 660)
tes3.claimSpellEffectId("callBoneoverlord", 661)
tes3.claimSpellEffectId("callBonewalker", 662)
tes3.claimSpellEffectId("callGreaterBonewalker", 663)
tes3.claimSpellEffectId("callMummy", 664)
tes3.claimSpellEffectId("communeDead", 665)
tes3.claimSpellEffectId("raiseSkeleton", 666)
tes3.claimSpellEffectId("raiseBoneConstruct", 667)
tes3.claimSpellEffectId("raiseCorpse", 668)
tes3.claimSpellEffectId("deathPact", 669)
tes3.claimSpellEffectId("corruptSoulgem", 670)
tes3.claimSpellEffectId("spreadDisease", 671)
tes3.claimSpellEffectId("darkRitual", 672)
tes3.claimSpellEffectId("feintDeath", 673)
tes3.claimSpellEffectId("concealUndead", 674)
tes3.claimSpellEffectId("summonSpirit", 675)
tes3.claimSpellEffectId("boneBinding", 676)

local blackSoulgemVersion = {
	Misc_SoulGem_Grand = "AB_Misc_SoulGemBlack",
	Misc_SoulGem_Azura = "NC_SoulGem_AzuraB"
}

local function onCorruptSoulgemCollision(e)
	if not e.collision then
		return
	end
	---@type tes3magicEffect
	local effect = magickaExpanded.functions.getEffectFromEffectOnEffectEvent(e, tes3.effect.corruptSoulgem)
	local magnitude = magickaExpanded.functions.getCalculatedMagnitudeFromEffect(effect)
	local caster = e.sourceInstance.caster
	local radius = effect.radius*21.3
	local collisionPoint = e.collision.point:copy()
	for ref in caster.cell:iterateReferences(tes3.objectType.misc) do
		local distance = collisionPoint:distance(ref.position)
		if (distance <= radius) then
			if ref.object.isSoulGem and not (ref.itemData and ref.itemData.soul) then
				if ref.object.soulGemCapacity <= magnitude*30 then
					local corrupted = blackSoulgemVersion[ref.id]
					if corrupted then
						utility.replace(ref, corrupted, caster.cell)
					end
					if corrupted == "NC_SoulGem_AzuraB" then
						tes3.createVisualEffect{
							effect = "VFX_Soul_Trap",
							position = collisionPoint,
							repeatCount = 1
						}
						tes3.createReference{
							object = "winged twilight",
							position = collisionPoint,
							orientation = {0, 0, 0},
							cell = caster.cell
						}
						tes3.createVisualEffect{
							effect = "VFX_Soul_Trap",
							position = collisionPoint + tes3vector3.new(100, 0, 0),
							repeatCount = 1
						}
						tes3.createReference{
							object = "winged twilight",
							position = collisionPoint + tes3vector3.new(100, 0, 0),
							orientation = {0, 0, 0},
							cell = caster.cell
						}
						tes3.createVisualEffect{
							effect = "VFX_Soul_Trap",
							position = collisionPoint + tes3vector3.new(0, 100, 0),
							repeatCount = 1
						}
						tes3.createReference{
							object = "winged twilight",
							position = collisionPoint + tes3vector3.new(0, 100, 0),
							orientation = {0, 0, 0},
							cell = caster.cell
						}
						-- wt1.mobile:startCombat(caster)
						-- wt2.mobile:startCombat(caster)
						-- wt3.mobile:startCombat(caster)
					end
				end
			end
		end
	end
end


local function addsummonSpiritEffect()
	magickaExpanded.effects.conjuration.createBasicEffect({
		id = tes3.effect.summonSpirit,
		name = strings.summonSpirit,
		description = strings.summonSpiritDesc, 
		baseCost = 10.0, -- check this 
		allowEnchanting = true,
		allowSpellmaking = true,
		appliesOnce = true,
		--canCastSelf = true,
		hasNoDuration = true,
		illegalDaedra = true,
		hasContinuousVFX = false,
		isHarmful = true,

		-- icon = "s\\tx_s_soultrap.dds",
		-- particleTexture = "vfx_particle064.tga",
		-- lighting = { 0.41, 0.06, 0.72 },
		-- hitVFX = "VFX_SoulTrapHit",

		onTick = effects.onTick.summonSpirit
	})
end

local function addCorruptSoulgemEffect()
	magickaExpanded.effects.alteration.createBasicEffect({
		id = tes3.effect.corruptSoulgem,
		name = strings.corruptSoulgem,
		description = strings.corruptSoulgemDesc, 
		baseCost = 10.0,
		allowEnchanting = true,
		allowSpellmaking = true,
		appliesOnce = true,
		canCastTarget = true,
		--canCastSelf = true,
		hasNoDuration = true,
		canCastTouch = true,
		illegalDaedra = true,
		hasContinuousVFX = true,
		isHarmful = true,

		icon = "s\\tx_s_soultrap.dds",
		particleTexture = "vfx_particle064.tga",
		lighting = { 0.41, 0.06, 0.72 },
		hitVFX = "VFX_SoulTrapHit",

		onCollision = onCorruptSoulgemCollision
	})
end

local function addDeathPactEffect()
    magickaExpanded.effects.mysticism.createBasicEffect({
		id = tes3.effect.deathPact,
		name = strings.deathPact,
		description = strings.deathPactDesc, 
		baseCost = 12.0,
		allowEnchanting = true,
		allowSpellmaking = true,
		appliesOnce = true,
		canCastTarget = true,
		canCastSelf = true,
		canCastTouch = true,
		hasNoMagnitude = true,
		illegalDaedra = true,
		hasContinuousVFX = true,
		isHarmful = false,

		icon = "s\\tx_s_soultrap.dds",
		particleTexture = "vfx_particle064.tga",
		lighting = { 0.41, 0.06, 0.72 },
		hitVFX = "VFX_SoulTrapHit",
	})
end

local function addConcealUndeadEffect()
    magickaExpanded.effects.illusion.createBasicEffect({
		id = tes3.effect.concealUndead,
		name = strings.concealUndead,
		description = strings.concealUndeadDesc, 
		baseCost = 10.0,
		allowEnchanting = true,
		allowSpellmaking = true,
		
		canCastTarget = true,
		canCastSelf = true,
		canCastTouch = true,
		hasNoMagnitude = true,

		icon = "s\\tx_s_chameleon.dds",
		
		onTick = effects.onTick.concealUndead
	})
end

local function addFeintDeathEffect()
    magickaExpanded.effects.alteration.createBasicEffect({
		id = tes3.effect.feintDeath,
		name = strings.feintDeath,
		description = strings.feintDeathDesc, 
		baseCost = 20.0,
		allowEnchanting = true,
		allowSpellmaking = true,
		canCastTarget = true,
		canCastSelf = true,
		canCastTouch = true,
		hasNoMagnitude = true,
		--appliesOnce = true,

		icon = "s\\tx_s_burden.dds",
		
		onTick = effects.onTick.feintDeath,
	})
end

local function addDarkRitualEffect()
    magickaExpanded.effects.mysticism.createBasicEffect({
		id = tes3.effect.darkRitual,
		name = strings.darkRitual,
		description = strings.darkRitualDesc, 
		baseCost = 1.0,
		allowEnchanting = false,
		allowSpellmaking = false,
		appliesOnce = false,
		canCastTarget = false,
		canCastSelf = true,
		canCastTouch = false,
		hasNoMagnitude = true,

		icon = "s\\tx_s_soultrap.dds",
		
		onTick = effects.onTick.darkRitual,
	})
end

local function addCommuneDeadEffect()
    magickaExpanded.effects.conjuration.createBasicEffect({
		id = tes3.effect.communeDead,
		name = strings.communeDead,
		description = strings.communeDeadDesc, 
		baseCost = 25.0,
		allowEnchanting = true,
		allowSpellmaking = true,
		appliesOnce = true,
		canCastTarget = true,
		canCastSelf = true,
		canCastTouch = true,
		hasNoMagnitude = true,
		illegalDaedra = true,
		isHarmful = false,

		icon = "s\\tx_S_Smmn_AnctlGht.dds",
		
		onTick = effects.onTick.communeDead,
	})
end

local function addCallSkeletonCrippleEffect()
   	magickaExpanded.effects.conjuration.createBasicEffect({
		id = tes3.effect.callSkeletonCripple,
		name = strings.callSkeletonCripple,
		description = strings.callSkeletonCrippleDesc, 
		baseCost = 250.0,
		allowEnchanting = true,
		allowSpellmaking = true,
		appliesOnce = true,
		canCastSelf = true,
		hasNoMagnitude = true,
		hasNoDuration = true,
		illegalDaedra = true,
		isHarmful = false,

		icon = "s\\tx_s_smmn_skltlmnn.dds",
		
		onTick = effects.onTick.callSkeletonCripple,
	})
end

local function addCallSkeletonWarriorEffect()
    magickaExpanded.effects.conjuration.createBasicEffect({
		id = tes3.effect.callSkeletonWarrior,
		name = strings.callSkeletonWarrior,
		description = strings.callSkeletonWarriorDesc, 
		baseCost = 400.0,
		allowEnchanting = true,
		allowSpellmaking = true,
		appliesOnce = true,
		canCastSelf = true,
		hasNoMagnitude = true,
		hasNoDuration = true,
		illegalDaedra = true,
		isHarmful = false,

		icon = "s\\tx_s_smmn_skltlmnn.dds",

		onTick = effects.onTick.callSkeletonWarrior,
	})
end

local function addCallSkeletonChampionEffect()
    magickaExpanded.effects.conjuration.createBasicEffect({
		id = tes3.effect.callSkeletonChampion,
		name = strings.callSkeletonChampion,
		description = strings.callSkeletonChampionDesc, 
		baseCost = 600.0,
		allowEnchanting = true,
		allowSpellmaking = true,
		appliesOnce = true,
		canCastSelf = true,
		hasNoMagnitude = true,
		hasNoDuration = true,
		illegalDaedra = true,
		isHarmful = false,

		icon = "s\\tx_s_smmn_skltlmnn.dds",

		onTick = effects.onTick.callSkeletonChampion,
	})
end

local function addCallBonewalkerEffect()
   	magickaExpanded.effects.conjuration.createBasicEffect({
		id = tes3.effect.callBonewalker,
		name = strings.callBonewalker,
		description = strings.callBonewalkerDesc, 
		baseCost = 250.0,
		allowEnchanting = true,
		allowSpellmaking = true,
		appliesOnce = true,
		canCastSelf = true,
		hasNoMagnitude = true,
		hasNoDuration = true,
		illegalDaedra = true,
		isHarmful = false,

		icon = "s\\tx_s_smmn_lstbnwlkr.dds",

		onTick = effects.onTick.callBonewalker,
	})
end

local function addCallGreaterBonewalkerEffect()
	magickaExpanded.effects.conjuration.createBasicEffect({
		id = tes3.effect.callGreaterBonewalker,
		name = strings.callGreaterBonewalker,
		description = strings.callGreaterBonewalkerDesc, 
		baseCost = 400.0,
		allowEnchanting = true,
		allowSpellmaking = true,
		appliesOnce = true,
		canCastSelf = true,
		hasNoMagnitude = true,
		hasNoDuration = true,
		illegalDaedra = true,
		isHarmful = false,

		icon = "s\\tx_s_smmn_grtrbnwlkr.dds",

		onTick = effects.onTick.callGreaterBonewalker,
	})
end

local function addCallBonespiderEffect()
    magickaExpanded.effects.conjuration.createBasicEffect({
		id = tes3.effect.callBonespider,
		name = strings.callBonespider,
		description = strings.callBonespiderDesc, 
		baseCost = 250.0,
		allowEnchanting = true,
		allowSpellmaking = true,
		appliesOnce = true,
		canCastSelf = true,
		hasNoMagnitude = true,
		hasNoDuration = true,
		illegalDaedra = true,
		isHarmful = false,

		icon = "s\\tx_s_smmn_bnlord.dds",

		onTick = effects.onTick.callBoneSpider,
	})
end

local function addCallBonelordEffect()
    magickaExpanded.effects.conjuration.createBasicEffect({
		id = tes3.effect.callBonelord,
		name = strings.callBonelord,
		description = strings.callBonelordDesc, 
		baseCost = 400.0,
		allowEnchanting = true,
		allowSpellmaking = true,
		appliesOnce = true,
		canCastSelf = true,
		hasNoMagnitude = true,
		hasNoDuration = true,
		illegalDaedra = true,
		isHarmful = false,

		icon = "s\\tx_s_smmn_bnlord.dds",

		onTick = effects.onTick.callBonelord,
	})
end

local function addCallBoneoverlordEffect()
    magickaExpanded.effects.conjuration.createBasicEffect({
		id = tes3.effect.callBoneoverlord,
		name = strings.callBoneoverlord,
		description = strings.callBoneoverlordDesc, 
		baseCost = 600.0,
		allowEnchanting = true,
		allowSpellmaking = true,
		appliesOnce = true,
		canCastSelf = true,
		hasNoMagnitude = true,
		hasNoDuration = true,
		illegalDaedra = true,
		isHarmful = false,

		icon = "s\\tx_s_smmn_bnlord.dds",

		onTick = effects.onTick.callBoneoverlord,
	})
end

local function addRaiseSkeletonEffect()
    magickaExpanded.effects.conjuration.createBasicEffect({
		id = tes3.effect.raiseSkeleton,
		name = strings.raiseSkeleton,
		description = strings.raiseSkeletonDesc, 
		baseCost = 25.0,
		allowEnchanting = false,
		allowSpellmaking = false,
		canCastTarget = true,
		canCastTouch = true,
		canCastSelf = true,
		hasNoDuration = true,
		icon = "s\\tx_s_smmn_skltlmnn.dds",
		onTick = effects.onTick.raiseSkeleton,
	})
end

local function addRaiseBoneConstructEffect()
    magickaExpanded.effects.conjuration.createBasicEffect({
		id = tes3.effect.raiseBoneConstruct,
		name = strings.raiseBoneConstruct,
		description = strings.raiseBoneConstructDesc, 
		baseCost = 25.0,
		allowEnchanting = false,
		allowSpellmaking = false,
		canCastTarget = true,
		canCastTouch = true,
		hasNoDuration = true,
		nonRecastable = true,
		unreflectable = true,
		illegalDaedra = true,

		icon = "s\\tx_s_smmn_bnlord.dds",

		onTick = effects.onTick.raiseBoneConstruct,
	})
end

local function addRaiseCorpseEffect()
    magickaExpanded.effects.conjuration.createBasicEffect({
		id = tes3.effect.raiseCorpse,
		name = strings.raiseCorpse,
		description = strings.raiseCorpseDesc, 
		baseCost = 25.0,
		allowEnchanting = false,
		allowSpellmaking = false,
		canCastTarget = true,
		canCastTouch = true,
		hasNoDuration = true,
		nonRecastable = true,
		unreflectable = true,
		illegalDaedra = true,

		icon = "s\\tx_s_smmn_lstbnwlkr.dds",

		onTick = effects.onTick.raiseCorpse,
	})
end

local function addSpreadDiseaseEffect()
    magickaExpanded.effects.destruction.createBasicEffect({
		id = tes3.effect.spreadDisease,
		name = strings.spreadDisease,
		description = strings.spreadDiseaseDesc, 
		baseCost = 100.0,
		allowEnchanting = true,
		allowSpellmaking = true,
		canCastTarget = true,
		canCastTouch = true,
		canCastSelf = true,
		hasNoDuration = true,
		hasNoMagnitude = true,

		icon = "s\\Tx_S_Drain_Fati.dds",

		onTick = effects.onTick.onSpreadDisease,
	})
end

event.register("magicEffectsResolved", addCallSkeletonCrippleEffect)
event.register("magicEffectsResolved", addCallSkeletonWarriorEffect)
event.register("magicEffectsResolved", addCallSkeletonChampionEffect)
event.register("magicEffectsResolved", addCallBonespiderEffect)
event.register("magicEffectsResolved", addCallBonelordEffect)
event.register("magicEffectsResolved", addCallBoneoverlordEffect)
event.register("magicEffectsResolved", addCallBonewalkerEffect)
event.register("magicEffectsResolved", addCallGreaterBonewalkerEffect)
event.register("magicEffectsResolved", addCommuneDeadEffect)
event.register("magicEffectsResolved", addRaiseSkeletonEffect)
event.register("magicEffectsResolved", addRaiseBoneConstructEffect)
event.register("magicEffectsResolved", addRaiseCorpseEffect)
event.register("magicEffectsResolved", addCorruptSoulgemEffect)
event.register("magicEffectsResolved", addDeathPactEffect)
event.register("magicEffectsResolved", addSpreadDiseaseEffect)
event.register("magicEffectsResolved", addDarkRitualEffect)
event.register("magicEffectsResolved", addFeintDeathEffect)
event.register("magicEffectsResolved", addConcealUndeadEffect)

return effects