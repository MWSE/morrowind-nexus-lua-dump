 return {
	-- General
	sideBarDefault = [[

 Welcome to Magica Regeneration Suite!

 Use the configuration menu to adjust various features and coefficients.

 Hover over individual settings to see more information.

 ]],

    regenerationFormula = {
        { label = "Morrowind style", value = 0 },
        { label = "Oblivion style", value = 1 },
        { label = "Skyrim style", value = 2 },
		{ label = "Logarithimic INT", value = 4 },
    },

    regenerationFormulasDescription = (
        "\nRegeneration type determines with what magicka regeneration scales. \n\n"..

        "In Skyrim, it scales with maximum magicka. Maximum magicka depends on intelligence,"..
        " so in Skyrim style magicka regeneration speed scales with intelligence. \n\n"..

        "In Oblivion it scales with willpower and intelligence. \n\n"..

        "In Morrowind style regeneration it scales with willpower, "..
        "and your character's current fatigue. \n\n"..

        "In addition, Morrowind and Skyrim regeneration styles "..
        "reduce magicka regeneration while in combat.\n\n"..

		"Now you can also use magicka regeneration formula as in "..
        "Knu's Natural Magicka Regeneration. To get this choose:\n\n"..

        "Regeneration type: Oblivion style\n"..
        "Turn Magicka Decay On\n"..
        "Set exp = 20\n"..
        "On Oblivion regeneration setting page set:\n"..
        "a = 0 and b = 10"
    ),

    decayDescription = (
        "\nMakes magicka regeneration speed lower, "..
        "the fuller magicka is. Formula for this mechanic is:\n\n"..

        "restored' = restored * ( 1 - currentMagicka / maxMagicka ) ^ (exp / 10)\n\n"..

        "Where restored magicka is the amount of magicka you would regenerate per second without "..
        "this feature turned on. restored' is final amount of magicka restored per second. \n\n"..

        "exp is the value you can tweak. Setting it to a higher value makes your magicka "..
        "regen slow down a lot sooner. When exp = 1 then your magicka decays linearly.\n\n"..

        "By default this feature is off and exp = 20"
    ),

    regenerationSpeedModifier = (
        "\nUse this to quickly adjust regeneration speed of your "..
        "chosen regeneration style. At 100 % it has no effect.\n\n"..

        "For much more precise control over individual coefficients, please see each page.\n\n"..

        "Default: 100 %"
    ),

	combatPenaltyGeneral = (
		"\nThis feature will make magicka regeneration slower in combat by a configurable amount."
	),

	combatPenalty = (
        "\nMagicka regeneration is lowered in combat. This setting controls how much it is slower in battle. \n\n"..

		"100 % - no penalty to regeneration in combat\n\n"..

        "1 % - magicka regenerates 1 % of its standard regeneration speed\n\n"..

		"0 % - no magicka regeneration while in combat\n\n"..

		"Default: 33 %"
    ),

	fatigueScaling = (
		"\nScale magicka regeneration speed with fatigueTerm?\n\n"..

		"fatigueTerm is used in many game formulas.\n\n"..

		"fatigueTerm = fFatigueBase - fFatigueMult x ( currentFatigue / maxFatigue )\n\n"..

		"Where fFatigueBase and fFatigueMult are game settings present in "..
		"vanilla Morrowind. By default, their values are 1.25 and 0.5. \n\n"..

        "All right, what this means you might ask. "..
		"Well, it makes your magicka regenerate 25 % faster at full fatigue and 25 % slower at empty fatigue."
	),

	vampireChanges = (
		"\nThis feature makes vampires lose magicka when in broad daylight, but also get faster magicka "..
		"regeneration during night or while indoors. This feature is a double-edged sword as most of the"..
		" game's vampires are encountered indoors, effectively giving them all faster magicka regeneration.\n\n"..

		"From a technical point of view, both day penalty and night bonus are just a percentage "..
		"increase/decrease to the base regeneration speed."
	),

	vampireDayPenalty = (
		"\nRepresents a percentage reduction to regeneration speed.\n\n"..

		"0 % - no penalty during the day\n\n"..

		"1 - 99 % - reduced regeneration speed\n\n"..

		"100 % - no regeneration in broad daylight\n\n" ..

		"101 - 200 % - vampire loses magicka while outside during the day\n\n"..

		"Default: 125 %"
	),

	vampireNightBonus = (
		"\nRepresents a percentage bonus to regeneration speed.\n\n"..

		"0 % - no bonus during the night/indoors\n\n"..

		"1 - 100 % - vampire gets bonus magicka regeneration speed during the night or while indoors\n\n"..

		"Default: 25 %"
	),

	-- Morrowind settings page
    morrowindFormula = (
        "Magicka points regenerated per second\n\n"..

        " = ( log(Willpower, base / 10) x (scale / 10) - (cap / 10) ) x fatigueTerm*\n\n"
    ),

    morrowindBase = (
		"\nThe base used in the logarithm.\n\n"..

		"Default: 50"
    ),

	morrowindScale = (
		"\nRepresents the scaling factor in the formula.\n\n"..

		"Default: 16"
	),

	morrowindCap = (
		"\nRepresents the cap from the formula.\n\n"..

		"Default: 30"
	),

    fatigueTermDescription = (
        "\n\n*fatigueTerm is used in many game formulas.\n\n"..

		"fatigueTerm = fFatigueBase - fFatigueMult x ( currentFatigue / maxFatigue )\n\n"..

		"Where fFatigueBase and fFatigueMult are game settings present in "..
		"vanilla Morrowind. By default, their values are 1.25 and 0.5. \n\n"..

        "All right, what this means you might ask. "..
		"Well, it means your magicka regenerates 25 % faster at full fatigue and 25 % slower at empty fatigue."
    ),

	-- Oblivion settings page
    oblivionFormula = (
        "Magicka % regenerated per second\n\n"..

        " = (a / 100) + (b / 1000) x Willpower\n\n"
    ),

    oblivionASlider = (
        "\nRepresents base % of total magicka regenerated per second.\n\n"..

        "Default (in Oblivion): 75\n"..
		"Default (in Natural Magicka Regeneration): 0"
    ),

    oblivionBSlider = (
        "\nWillpower modifier to % of total magicka regenerated per second.\n\n"..

        "Default (in Oblivion): 20\n"..
		"Default (in Natural Magicka Regeneration): 10"
    ),

	-- Skyrim settings page
    skyrimFormula = (
        "Magicka % regenerated per second\n\n"..

        " = a / 10\n\n"
    ),

    skyrimASlider = (
        "\nModify percentage of maximum magicka which characters regenerate per second.\n\n"..

		"Default (in Skyrim): 30"
    ),

    skyrimCombatPenalty = (
        "\nMagicka regeneration is lowered in combat. This setting controls how much it is slower in battle. \n\n"..

        "100 % - no penalty to regeneration in combat\n\n"..

        "1 % - magicka regenerates 1 % of its standard regeneration speed\n\n"..

		"0 % - no magicka regeneration while in combat\n\n"..

		"Default (in Skyrim): 33 %"
    ),

	-- Logarithmic INT settings page
	INTDescription = (
		"This formula is designed as an improvement to the Skyrim formula.\n\n"..

		"By using log function, this formula ensures that at high levels of intelligence,"..
		"the magicka regeneration isn't excessively high. In addition, for smaller levels "..
		"of intelligence, characters will get higher regeneration gains by in intelligence"..
		" at levelup than at higher levels. This makes the early game a bit easier. Moreover"..
		", log function allows \"capping of the regeneration at really small intelligence. "..
		"This can restrict the usefulness of magicka regeneration to characters with low intelligence."
	),

	INTFormula = (
		"Magicka point regenerated per second\n\n"..

		"= log(Intelligence, base / 10) x (scale / 10) - (cap / 10)\n\n"
	),

	INTBase = (
		"\nThe base used in the logarithm.\n\n"..

		"Default: 25"
	),

	INTScale = (
		"\nRepresents the scaling factor in the formula.\n\n"..

		"Default: 11"
	),

	INTCap = (
		"\nRepresents the cap from the formula.\n\n"..

		"Default: 35"
	),
}
