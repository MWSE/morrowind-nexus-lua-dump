local defaults = {
	--- Illusion
  -- Rally
  rallyEnabled = true,
  rallyWillpowerResist = true,
  rallyIllusionRequirement = 10,
  -- Frenzy
  frenzyEnabled = true,
  frenzyWillpowerResist = true,
  frenzyIllusionRequirement = 20,
  -- Light
  lightEnabled = true,
  lightMagnitudeRate = 5,
  lightIllusionRequirement = 30,
  -- Blind
  blindEnabled = true,
  blindMagnitudeMult = 20,
  blindDurationMult = 75,
  blindIllusionRequirement = 40,
  -- Calm
  calmEnabled = true,
  calmWillpowerResist = true,
  calmIllusionRequirement = 50,
  -- Charm
  charmEnabled = true,
  charmMagnitudeRate = 2,
  charmIllusionRequirement = 60,
  -- Demoralize
  demoralizeEnabled = true,
  demoralizeWillpowerResist = true,
  demoralizeIllusionRequirement = 70,
  -- Silence
  silenceEnabled = true,
  silenceDurationRate = 5,
  silenceIllusionRequirement = 80,
  -- Paralyze
  paralyzeEnabled = true,
  paralyzeDurationRate = 2,
  paralyzeIllusionRequirement = 90,
  -- Invisibility
  invisibilityEnabled = true,
  invisibilityDurationRate = 10,
  invisibilityIllusionRequirement = 100
}

local config = mwse.loadConfig ("biltjan_magicka_awakening", defaults)
return config