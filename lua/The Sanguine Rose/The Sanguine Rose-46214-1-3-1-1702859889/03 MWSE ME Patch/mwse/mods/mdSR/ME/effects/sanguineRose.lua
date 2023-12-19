local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("sanguineRose", 7770)

local summonList = {
    [1] = "mdSR_dae_atroflame",
    [2] = "mdSR_dae_atrofrost",
    [3] = "mdSR_dae_atrostorm",
    [4] = "mdSR_dae_clannfear",
    [5] = "mdSR_dae_daedroth",
    [6] = "mdSR_dae_dremora",
    [7] = "mdSR_dae_DS",
    [8] = "mdSR_dae_GS",
    [9] = "mdSR_dae_herne",
    [10] = "mdSR_dae_hunger",
    [11] = "mdSR_dae_scamp",
	[12] = "mdSR_dae_WT",
    [13] = "mdSR_dae_xivilai"
}

local function onSummonTick(e)
    local caster = e.sourceInstance.caster
    local value = math.random (1, 13)  
    -- framework.debug("Value: " .. value)

    local rounded = math.round(value, 0)
    -- framework.debug("Rounded Value: " .. rounded)

    local id = summonList[rounded]
    -- framework.debug("ID: " .. id)
    e:triggerSummon(id)
end

local function addSummonEffect()
	framework.effects.conjuration.createBasicEffect({
		-- Base information.
		id = tes3.effect.sanguineRose,
		name = "Sanguine Rose",
		description = "Summons a random daedra from Oblivion.",

		-- Basic dials.
		baseCost = 500.0,

		-- Various flags.
		allowEnchanting = false,
        allowSpellmaking = false,
        canCastSelf = true,
        hasNoMagnitude = true,
        casterLinked = true,
        appliesOnce = true,

		-- Graphics/sounds.
		icon = "mdSR\\tx_s_sang_rose.dds",
        lighting = { 0, 0, 0 },

		-- Required callbacks.
		onTick = onSummonTick,
	})
end

print("Effect registered")

event.register("magicEffectsResolved", addSummonEffect)