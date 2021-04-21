local magickaExpanded = include("OperatorJack.MagickaExpanded.magickaExpanded")

-- ID of a dummy NPC that's summoned by the Skull of Corruption. Needs to exist in the esp.
local corruptedDoubleId = "_TT_Corrupted_Double"
-- ID of the enchantement that the MExp one will replace. Needs to exist in the esp, have one effect and be cast on target. 
local skullOfCorruptionEnchantment = "_TT_CorruptedDouble_en"
-- Multipliers applied to skills and abilities of the double in regards to the original
local doubleSkillMultiplier = 1
local doubleAbilityMultiplier = 1

tes3.claimSpellEffectId("summonCorruptedDouble", 1202)
tes3.claimSpellEffectId("summonCorruptedDoublePotion", 1203)

local summonCorruptedDoubleEffect
local summonCorruptedDoublePotionEffect

local function onPotionTick(e)
	e:triggerSummon(corruptedDoubleId)
end

local function onSpellTick(e)
	e.effectInstance.state = tes3.spellState.retired
	local caster = e.sourceInstance.caster
	local target = e.effectInstance.target.object
	local baseTarget = target.baseObject
	--mwse.log("%s",e.effectInstance.target.id)
	corruptedDouble = tes3.getObject(corruptedDoubleId)

	corruptedDouble.race = baseTarget.race
	corruptedDouble.female = baseTarget.female
	corruptedDouble.head = baseTarget.head
	corruptedDouble.hair = baseTarget.hair
	corruptedDouble.scale = baseTarget.scale

	corruptedDouble.class = target.class
	corruptedDouble.level = target.level
	corruptedDouble.health = target.health
	corruptedDouble.fatigue = target.fatigue
	corruptedDouble.magicka = target.magicka

	for i, skillValue in ipairs(target.skills) do
		corruptedDouble.skills[i] = skillValue
	end
		
	for j, attributeValue in ipairs(target.attributes) do
		corruptedDouble.attributes[j] = attributeValue
	end

	local effect = magickaExpanded.functions.getEffectFromEffectOnEffectEvent(e, tes3.effect.summonCorruptedDouble)
	local duration = effect.duration
	
	local potion = magickaExpanded.alchemy.createBasicPotion({
		id = "_TT_Corrupted_Double_Potion",
		name = "Summon Corrupted Double",
		effect = tes3.effect.summonCorruptedDoublePotion,
		duration = duration
	})
	
	mwscript.equip({
		reference = caster,
		item = potion
	})

	for _, targetEquipment in pairs(target.equipment) do
		targetEquipmentId = targetEquipment.object.id
		--mwse.log("%s",targetEquipmentId)
		--mwscript.addItem({reference = corruptedDoubleId, item = "common_ring_04", count = 1})
	end
end

local function addSummonCorruptedDoublePotionEffect()
	summonCorruptedDoublePotionEffect = magickaExpanded.effects.conjuration.createBasicEffect({
		id = tes3.effect.summonCorruptedDoublePotion,
		name = "Summon Corrupted Double Potion",
		description = "Subspell.",
		baseCost = 0.0,
		
		canCastTouch = true,
		canCastTarget = true,
		canCastSelf = true,
		allowEnchanting = true,
        allowSpellmaking = true,
        appliesOnce = true,
        hasNoMagnitude = true,
		casterLinked = true,
		icon = "RFD\\RFD_ms_conjuration.tga",
		particleTexture = "vfx_conj_flare02.tga",
        lighting = { 0, 0, 0 },
		onTick = onPotionTick,
	})	
	--mwse.log("%s", tes3.effect.summonCorruptedDoublePotion)
end

local function addSummonCorruptedDoubleEffect()
	summonCorruptedDoubleEffect = magickaExpanded.effects.conjuration.createBasicEffect({
		id = tes3.effect.summonCorruptedDouble,
		name = "Summon Corrupted Double",
		description = "Summons a corrupted double of the target.",
		baseCost = 60.0,
		
		canCastTouch = true,
		canCastTarget = true,
		isHarmful = true,
		canCastSelf = true,
		allowEnchanting = true,
        allowSpellmaking = true,
        appliesOnce = true,
        hasNoMagnitude = true,
		casterLinked = true,
		icon = "RFD\\RFD_ms_conjuration.tga",
		particleTexture = "vfx_conj_flare02.tga",
        lighting = { 0.99, 0.95, 0.67 },
		onTick = onSpellTick,
	})
	--mwse.log("%s", tes3.effect.summonCorruptedDouble)
end

local function registerEnchantments()
	magickaExpanded.enchantments.createBasicEnchantment({
		id = skullOfCorruptionEnchantment,
		effect = tes3.effect.summonCorruptedDouble,
		range = tes3.effectRange.target,
		castType = tes3.enchantmentType.onUse,
		chargeCost = 150,
		maxCharge = 3000,
		duration = 30
	})
	--mwse.log("registerEnchantments")
end
--mwse.log("Double")
event.register("magicEffectsResolved", addSummonCorruptedDoublePotionEffect)
event.register("magicEffectsResolved", addSummonCorruptedDoubleEffect)
event.register("MagickaExpanded:Register", registerEnchantments)