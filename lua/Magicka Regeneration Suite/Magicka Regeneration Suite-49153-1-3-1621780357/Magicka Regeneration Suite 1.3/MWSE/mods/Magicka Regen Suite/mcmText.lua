return {
    regenerationTypes = {
        { label = "Morrowind style", value = 0 },
        { label = "Oblivion style", value = 1 },
        { label = "Skyrim style", value = 2 }
    },

    sideBarDefault =
    [[

    Welcome to Magica Regeneration Suite!

    Use the configuration menu to adjust various features and coefficients.

    Hover over individual settings to see more information.

    ]],

    regenerationTypesDescription = (
        "\nRegeneration type determines with what magicka regeneration scales. \n\n"..

        "In Skyrim, it scales with maximum magicka. Maximum magicka depends on intelligence,"..
        " so in Skyrim style magicka regeneration speed scales with intelligence. \n\n"..

        "In Oblivion it scales with willpower and intelligence. \n\n"..

        "In Morrowind style regeneration it scales with willpower, "..
        "intelligence, and your character's current fatigue. \n\n"..

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

    morrowindFormula = (
        "Magicka % regenerated per second\n\n"..

        " = ( (a / 100) + (b / 1000) x Willpower ) x fatigueTerm*\n\n"
    ),

    morrowindASlider = (
        "\nRepresents base % of total magicka regenerated per second.\n\n"..

		"Default: 25\n"..
        "Note: in Oblivion, this value is 75"
    ),

    morrowindBSlider = (
        "\nWillpower modifier to % of total magicka regenerated per second.\n\n"..

        "Default: 10\n"..
        "Note: in Oblivion, this value is: 20"
    ),

    morrowindCombatPenalty = (
        "\nMagicka regeneration is lowered in combat. This setting controls how much it is slower in battle. \n\n"..

		"100 % - no penalty to regeneration in combat\n\n"..

        "1 % - magicka regenerates 1 % of its standard regeneration speed\n\n"..

		"Default: 33 %"
    ),

    fatigueTermDescription = (
        "\n\n*fatigueTerm is used in many game formulas.\n\n"..

		"fatigueTerm = fFatigueBase - fFatigueMult x ( currentFatigue / maxFatigue )\n\n"..

		"Where fFatigueBase and fFatigueMult are game settings present in "..
		"vanilla Morrowind. By default, their values are 1.25 and 0.5. \n\n"..

        "All right, what this means you might ask. "..
		"Well, it means your magicka regenerates 25 % faster at full fatigue and 25 % slower at empty fatigue."
    ),

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

		"Default (in Skyrim): 33 %"
    )

}
