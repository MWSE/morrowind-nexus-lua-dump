local ok, content = pcall(require, 'openmw.content')
if not ok or not content then
	-- print("[Utility Spells] openmw.content API not available - Fortify spells disabled (requires 0.51+)")
	return {}
end

local fortifyEffectDefs = {
	{
		id = "us_fortifybc",
		name = "Fortify Bardcraft",
		icon = "icons/tx_s_bardcraft.tga",
		description = "This effect raises the caster's precision with an instrument and performance aptitude.",
		baseCost = 1,
	},
	{
		id = "us_fortifycooking",
		name = "Fortify Cooking",
		icon = "icons/tx_s_cooking.tga",
		description = "This effect raises the caster's chance of bringing out additional flavors of ingredients when cooking a meal.",
		baseCost = 2,
	},
	{
		id = "us_fortifymining",
		name = "Fortify Mining",
		icon = "icons/tx_s_mining.tga",
		description = "This effect raises the caster's chance of finding rare ore nodes and the amount of ore found from a single vein.",
		baseCost = 2,
	},
	{
		id = "us_fortifyaquatics",
		name = "Fortify Aquatics",
		icon = "icons/tx_s_swimming.tga",
		description = "This effect raises the caster's breath while submerged underwater, allows for faster movement and strengthens attacks from a weapon and with hand-to-hand hits while submerged.",
		baseCost = 1,
	},
}

for _, def in ipairs(fortifyEffectDefs) do
	content.magicEffects.records[def.id] = {
		template = content.magicEffects.records["fortifyattack"],
		name = def.name,
		icon = def.icon,
		baseCost = def.baseCost,
		description = def.description,
	}
end

local fortifySpellDefs = {
	{
		spellId = "fortify_bc",
		effectId = "us_fortifybc",
		name = "Fortify Bardcraft",
		cost = 30,
		duration = 60,
		magMin = 10,
		magMax = 10,
	},
	{
		spellId = "fortify_sd_cooking",
		effectId = "us_fortifycooking",
		name = "Fortify Cooking",
		cost = 30,
		duration = 60,
		magMin = 10,
		magMax = 10,
	},
	{
		spellId = "fortify_pwn_mining",
		effectId = "us_fortifymining",
		name = "Fortify Mining",
		cost = 30,
		duration = 60,
		magMin = 10,
		magMax = 10,
	},
	{
		spellId = "fortify_pwn_aquatics",
		effectId = "us_fortifyaquatics",
		name = "Fortify Aquatics",
		cost = 30,
		duration = 60,
		magMin = 10,
		magMax = 10,
	},
}

-- for pet scrib
content.magicEffects.records["us_scrib"] = {
	template = content.magicEffects.records["summonscamp"],
	name = "Summon Scrib",
	icon = "s/tx_s_bd_gloves.tga",
	baseCost = 11,
	description = "This effect summons a scrib from Oblivion. It appears in front of the caster and attacks any entity that attacjs the caster until the effect ends or the summoning is killed. At death, or when the effect ends, the summoning disappears, returning to Oblivion.\n\nPetting the scrib will increase its size and restore a small amount of health.",
}

content.spells.records["us_summon_scrib"] = {
    name = "Summon Scrib",
    type = content.spells.TYPE.Spell,
    cost = 15,
    isAutocalc = false,
    effects = {
        {
            id = "us_scrib",
            range = content.RANGE.Self,
            area = 0,
            duration = 30,
            magnitudeMin = 1,
            magnitudeMax = 1,
        },
    },
}

-- allow for enchant, spell creating
for _, def in ipairs(fortifySpellDefs) do
	content.spells.records[def.spellId] = {
		name = def.name,
		type = content.spells.TYPE.Spell,
		cost = def.cost,
		effects = {
			{
				id = def.effectId,
				range = content.RANGE.Self,
				area = 0,
				duration = def.duration,
				magnitudeMin = def.magMin,
				magnitudeMax = def.magMax,
			},
		},
	}
end

return {}