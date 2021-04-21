local magickaExpanded = require("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("fortifyAgility", 793)
tes3.claimSpellEffectId("fortifyStrength", 790)
tes3.claimSpellEffectId("fortifyIntelligence", 791)
tes3.claimSpellEffectId("fortifyPersonality", 796)

local function addFortifyAgilityEffect()
	magickaExpanded.effects.restoration.createBasicEffect({
		-- Base information.
		id = tes3.effect.fortifyAgility,
		name = "Fortify Agility",
		description = "Fortify Agility",

		-- Basic dials.
		baseCost = 15.0,

		-- Various flags.
		canCastSelf = true,
		canCastTarget = true,
        canCastTouch = true,

		-- Graphics/sounds.
		icon = "s\\Tx_S_Ftfy_Attrib.dds",
	})
end

local function addFortifyStrengthEffect()
	magickaExpanded.effects.restoration.createBasicEffect({
		-- Base information.
		id = tes3.effect.fortifyStrength,
		name = "Fortify Strength",
		description = "Fortify Strength",

		-- Basic dials.
		baseCost = 15.0,

		-- Various flags.
		canCastSelf = true,
		canCastTarget = true,
        canCastTouch = true,

		-- Graphics/sounds.
		icon = "s\\Tx_S_Ftfy_Attrib.dds",
	})
end

local function addFortifyIntelligenceEffect()
	magickaExpanded.effects.restoration.createBasicEffect({
		-- Base information.
		id = tes3.effect.fortifyIntelligence,
		name = "Fortify Intelligence",
		description = "Fortify Intelligence",

		-- Basic dials.
		baseCost = 15.0,

		-- Various flags.
		canCastSelf = true,
		canCastTarget = true,
        canCastTouch = true,

		-- Graphics/sounds.
		icon = "s\\Tx_S_Ftfy_Attrib.dds",
	})
end

local function addFortifyPersonalityEffect()
	magickaExpanded.effects.restoration.createBasicEffect({
		-- Base information.
		id = tes3.effect.fortifyPersonality,
		name = "Fortify Personality",
		description = "Fortify Personality",

		-- Basic dials.
		baseCost = 15.0,

		-- Various flags.
		canCastSelf = true,
		canCastTarget = true,
        canCastTouch = true,

		-- Graphics/sounds.
		icon = "s\\Tx_S_Ftfy_Attrib.dds",
	})
end

event.register("magicEffectsResolved", addFortifyAgilityEffect)
event.register("magicEffectsResolved", addFortifyStrengthEffect)
event.register("magicEffectsResolved", addFortifyIntelligenceEffect)
event.register("magicEffectsResolved", addFortifyPersonalityEffect)