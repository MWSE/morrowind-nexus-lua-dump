I.Settings.registerPage {
	key = MOD_NAME,
	l10n = MOD_NAME,
	name = "MBSP",
	description = "Your effective skill level for magicka refunding is:\nSkill Level + Willpower/5 + Luck/10 - RefundStart\n\nThe formula for the effective mana costs after refund is Scaling^(Skill/LevelScaling) (for example 0.5^(50/100) = 0.7071)\n\nThe experience per successful spell cast is halfed but you receive bonus exp equal to [Magicka Cost] * [Magicka XP Multiplier]"
}

-- suggested defaults (frequently used skills = 0.9, rare skills up to 1.5)
local skillMultipliers = {
    -- Combat Skills
    combat = {
        ["armorer"]     = 1,
        ["athletics"]   = 0.9,
        ["axe"]         = 0.9,
        ["block"]       = 1,
        ["bluntweapon"] = 0.9,
        ["heavyarmor"]  = 1.2,
        ["longblade"]   = 0.9,
        ["mediumarmor"] = 1.1,
        ["spear"]       = 0.9,
    },
    
    -- Magic Skills
    magic = {
        ["alchemy"]     = 1,
        ["alteration"]  = 1.4,
        ["conjuration"] = 1.5,
        ["destruction"] = 0.9,
        ["enchant"]     = 1.1,
        ["illusion"]    = 1.5,
        ["mysticism"]   = 1.5,
        ["restoration"] = 1,
        ["unarmored"]   = 1.3,
    },
    
    -- Stealth Skills
    stealth = {
        ["acrobatics"]  = 0.8,
        ["handtohand"]  = 0.9,
        ["lightarmor"]  = 1.1,
        ["marksman"]    = 0.9,
        ["mercantile"]  = 1,
        ["security"]    = 1.1,
        ["shortblade"]  = 0.9,
        ["sneak"]       = 1.6,
        ["speechcraft"] = 1.1,
    }
}

	settings = {
		--{
		--	key = "magickaXPRate",
		--	name = "Magicka XP Rate",
		--	description = "spent magicka per experience point\nIgnores Refunds\n0 = disabled for compatibility with ncgd or other leveling/uncapper mods",
		--	default = 15,
		--	argument = {
		--		min = 0,
		--		max = 1000,
		--	},
		--	renderer = "number",
		--},
		{
			key = "magickaXPMult",
			name = "Magicka XP Multiplier",
			description = "Multiplies magicka costs to calculate experience per spell cast\nIgnores Refunds\n0 = disabled for compatibility with ncgd or other leveling/uncapper mods",
			default = playerSection:get("magickaXPRate") and math.floor(1/playerSection:get("magickaXPRate")*1000)/1000 or 0.1,
			argument = {
				min = 0,
				max = 1000,
			},
			renderer = "number",
		},
		{
			key = "enableUncapper",
			name = "Enable Uncapper",
			description = "Allows any skill to reach a higher level than 100.\nIf you want, there's also multipliers for every skill's xp in the lua file that i don't wanna list here.",
			default = false,
			renderer = 'checkbox',
		},
		{
			key = "refundMode",
			name = "Enable Refund",
			description = "Refund magicka on successful casts or before spending the magicka (EXPERIMENTAL)",
			default = "Refund", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"Disabled", "Refund", "EXPERIMENTAL"},
			},
		},
		{
			key = "refundStart",
			name = "Refund: Skill Start",
			description = "Before this skill level, you won't get any Magicka Refunds.\nThis Value is also subtracted from your effective Level for the refund formula",
			default = 35,
			renderer = 'number',
			argument = {
				integer = true,
				min = 1,
				max = 1000,
			},
		},
		{
			key = "refundMult",
			name = "Refund: Magicka Cost Scaling",
			description = "The effective magicka costs get multiplied by this value every 100 levels (by default, setting below)",
			default = 0.5,
			argument = {
				min = 0.01,
				max = 10,
			},
			renderer = "number",
		},
		{
			key = "levelScaling",
			name = "Refund: Level Scaling",
			description = "Every 100 levels (by default, or whatever this setting's value is) your effective spell costs get multiplied by 0.5 (by default, setting above), so your effective spell costs would be 25% at level 200 with default settings for example.",
			default = 100,
			renderer = 'number',
			argument = {
				integer = true,
				min = 1,
				max = 10000,
			},
		},
		{
			key = "negativeRefunds",
			name = "Refunds Can Be Negative",
			description = "For example when your skill is lower than the 'Refund Skill Start'\nRequires the 'EXPERIMENTAL' refund mode\nfor example: 0.5^(-25/100) = 1.19x",
			default = false,
			renderer = "checkbox",
		},
		{
			key = "spellCostMultiplier",
			name = "Spell Cost Multiplier",
			description = "Requires the 'Negative Refunds' setting and the 'EXPERIMENTAL' refund mode!\nThis is a multiplier on the spell costs after the exponential refund formula was applied",
			default = 1,
			renderer = 'number',
			argument = {
				min = 0,
				max = 10000,
			},
		},
		{
			key = "spellCostOffset",
			name = "Spell Cost Offset",
			description = "Requires the 'Negative Refunds' setting and the 'EXPERIMENTAL' refund mode!\nThis setting adds or subtracts a portion of the spell's base(vanilla) cost to the final result after the multiplier above has been applied",
			default = 0,
			renderer = 'number',
			argument = {
				min = -1,
				max = 1,
			},
		},
		{
			key = "PrintDebug",
			name = "Print Debug Messages",
			description = "into the console",
			default = false,
			renderer = "checkbox",
		},
		{
			key = "rapidfire",
			name = "Experimental: Rapidfire Casting",
			description = "Allows you to spam spells by holding the button",
			default = false,
			renderer = "checkbox",
		},
		{
			key = "CATCH_UP_SPEED",
			name = "XP: Catch up speed",
			description = "The experience multiplier for skills that are below 2x your player level (ramps up gradually)",
			default = 1.5,
			argument = {
				min = 0.5,
				max = 10,
			},
			renderer = "number",
		},
	}

for spec, skills in pairs(skillMultipliers) do
for skill, mult in pairs(skills) do
	table.insert(settings, {
		key = "SKILL_MULT_"..skill,
		name = skill.. " XP Mult",
		description = "",
		default = mult,
		renderer = 'number',
		argument = {
			min = 0,
			max = 10000,
		},
	})
end
end

I.Settings.registerGroup {
	key = "SettingsPlayer" .. MOD_NAME,
	l10n = "MBSP",
	name = "",
	page = MOD_NAME,
	description = "",
	permanentStorage = true,
	settings = settings
}