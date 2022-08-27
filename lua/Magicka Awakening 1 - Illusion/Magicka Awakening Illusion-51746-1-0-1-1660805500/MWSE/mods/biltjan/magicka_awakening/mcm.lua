local config = require("biltjan.magicka_awakening.config")

local template = mwse.mcm.createTemplate("Magicka Awakening - Illusion")
template:saveOnClose("biltjan.magicka_awakening.config", config)

local illusionPage = template:createSideBarPage{label="Illusion"}
illusionPage:createButton{ buttonText = "=== Illusion Perks ===" }
--- Rally
illusionPage:createButton{ buttonText = "Permanent Rally", 
description = "The Flee value of the target will be decreased by the Rally spell magnitude.\nResistance applies (e.g. Bretons will be harder to rally)." }
-- Enable/Disable
illusionPage:createOnOffButton{label = "Permanent Rally - Enable/Disable",
description = "Enable/Disable permanent rally",
variable = mwse.mcm.createTableVariable{id = "rallyEnabled", table = config}}
-- Enable/Disable Willpower Resistance
illusionPage:createOnOffButton{label = "Permanent Rally - Willpower Resistance",
description = "If enabled, the PERMANENT decrease will be reduced by 1/3 of the target's willpower.\nYou would still be able to rally a high willpower enemy like vanilla, but to permanently rally them you would need a very high magnitude of Rally.",
variable = mwse.mcm.createTableVariable{id = "rallyWillpowerResist", table = config}}
-- Minimum Illusion level
illusionPage:createSlider{label = "Permanent Rally - Minimum Illusion",
description = "Minimum Base Illusion level to permanently rally.\nFortify skills won't work here.\nDefault value: 10.",
min = 1, max = 100,
step = 1, jump = 5,
variable = mwse.mcm.createTableVariable{id = "rallyIllusionRequirement", table = config }}

--- Frenzy
illusionPage:createButton{ buttonText = "Permanent Frenzy",
description = "The Fight value of the target will be increased by the Frenzy spell magnitude.\nResistance applies (e.g. Bretons will be harder to frenzy)." }
-- Enable/Disable
illusionPage:createOnOffButton{label = "Permanent Frenzy - Enable/Disable",
description = "Enable/Disable permanent frenzy",
variable = mwse.mcm.createTableVariable{id = "frenzyEnabled", table = config}}
-- Enable/Disable Willpower Resistance
illusionPage:createOnOffButton{label = "Permanent Frenzy - Willpower Resistance",
description = "If enabled, the PERMANENT increase will be reduced by 1/3 of the target's willpower.\nYou would still be able to frenzy a high willpower enemy like vanilla, but to permanently frenzy them you would need a very high magnitude of Frenzy.",
variable = mwse.mcm.createTableVariable{id = "frenzyWillpowerResist", table = config}}
-- Minimum Illusion level
illusionPage:createSlider{label = "Permanent Frenzy - Minimum Illusion",
description = "Minimum Base Illusion level to permanently frenzy.\nFortify skills won't work here.\nDefault value: 20.",
min = 1, max = 100,
step = 1, jump = 5,
variable = mwse.mcm.createTableVariable{id = "frenzyIllusionRequirement", table = config }}

--- Light
illusionPage:createButton{ buttonText = "Enfeebling Light",
description = "When light hits (except on self), the target gets drain willpower. It doesn't count as assault.\nThe magnitude is: Light Magnitude/Variable (default 5)\nTarget resistance affect the magnitude (e.g. less willpower drained from a Breton).\nThe duration is the same as the light duration." }
-- Enable/Disable
illusionPage:createOnOffButton{label = "Enfeebling Light - Enable/Disable",
description = "Enable/disable enfeebling, invisibility extra effect.",
variable = mwse.mcm.createTableVariable{id = "lightEnabled", table = config}}
-- Light Magnitude
illusionPage:createSlider{label = "Enfeebling Light - Drain Willpower Magnitude",
description = "Magnitude rate for the drain willpower, more = lesser effect.\nDefault value: 5. 5 is as expensive as drain willpower.\nValue is rounded down.",
min = 1, max = 10,
step = 1, jump = 2,
variable = mwse.mcm.createTableVariable{id = "lightMagnitudeRate", table = config }}
-- Minimum Illusion level
illusionPage:createSlider{label = "Enfeebling Light - Minimum Illusion",
description = "Minimum Base Illusion level to enable enfeebling light.\nFortify skills won't work here.\nDefault value: 30.",
min = 1, max = 100,
step = 1, jump = 5,
variable = mwse.mcm.createTableVariable{id = "lightIllusionRequirement", table = config }}

--- Blind
illusionPage:createButton{ buttonText = "Stolen Vision",
description = "When blind hits, you also gain a fortify attack.\nThe magnitude is: Variable (default 0.1) * (min blind to max blind)\nTarget resistance affect the magnitude (e.g. you gained less attack from a Breton).\nThe duration is: Variable (default 0.5) * Blind duration." }
-- Enable/Disable
illusionPage:createOnOffButton{label = "Stolen Vision - Enable/Disable",
description = "Enable/disable stolen vision, gaining attack when you're blinding others.",
variable = mwse.mcm.createTableVariable{id = "blindEnabled", table = config}}
-- Blind Magnitude
illusionPage:createSlider{label = "Stolen Vision - Blind Magnitude",
description = "Magnitude multiplier for blind, value is out of 100 (50 is 50%).\nDefault value: 10.\nValue is rounded down.",
min = 1, max = 200,
step = 1, jump = 5,
variable = mwse.mcm.createTableVariable{id = "blindMagnitudeMult", table = config }}
-- Blind Duration
illusionPage:createSlider{label = "Stolen Vision - Blind Duration",
description = "Duration multiplier for blind, value is out of 100 (50 is 50%).\nDefault value: 10.\nValue is rounded down.",
min = 1, max = 200,
step = 1, jump = 5,
variable = mwse.mcm.createTableVariable{id = "blindDurationMult", table = config }}
-- Minimum Illusion level
illusionPage:createSlider{label = "Stolen Vision - Minimum Illusion",
description = "Minimum Base Illusion level to enable stolen vision.\nFortify skills won't work here.\nDefault value: 40.",
min = 1, max = 100,
step = 1, jump = 5,
variable = mwse.mcm.createTableVariable{id = "blindIllusionRequirement", table = config }}

--- Calm
illusionPage:createButton{ buttonText = "Permanent Calm",
description = "The Fight value of the target will be reduced by the Calm spell magnitude.\nResistance applies (e.g. Bretons will be harder to calm down)." }
-- Enable/Disable
illusionPage:createOnOffButton{label = "Permanent Calm - Enable/Disable",
description = "Enable/Disable permanent calm",
variable = mwse.mcm.createTableVariable{id = "calmEnabled", table = config}}
-- Enable/Disable Willpower Resistance
illusionPage:createOnOffButton{label = "Permanent Calm - Willpower Resistance",
description = "If enabled, the PERMANENT decrease will be reduced by 1/3 of the target's willpower.\nYou would still be able to calm a high willpower enemy like vanilla, but to permanently calm them you would need a very high magnitude of Calm.",
variable = mwse.mcm.createTableVariable{id = "calmWillpowerResist", table = config}}
-- Minimum Illusion level
illusionPage:createSlider{label = "Permanent Calm - Minimum Illusion Requirement",
description = "Minimum Base Illusion level to permanently calm.\nFortify skills won't work here.\nDefault value: 50.",
min = 1, max = 100,
step = 1, jump = 5,
variable = mwse.mcm.createTableVariable{id = "calmIllusionRequirement", table = config }}

--- Charm
illusionPage:createButton{ buttonText = "Alluring Trade",
description = "When charm hits (except on self), the target gets drain mercantile. It doesn't count as assault.\nThe magnitude is: Light Magnitude/Variable (default 2)\nTarget resistance affect the magnitude (e.g. less mercantile drained from a Breton).\nThe duration is the same as the charm duration." }
-- Enable/Disable
illusionPage:createOnOffButton{label = "Alluring Trade - Enable/Disable",
description = "The Flee value of the target will be decreased by the Rally spell magnitude.\nResistance applies (e.g. Bretons will be harder to rally).",
variable = mwse.mcm.createTableVariable{id = "charmEnabled", table = config}}
-- Light Magnitude
illusionPage:createSlider{label = "Alluring Trade - Drain Mercantile Magnitude",
description = "Magnitude rate for the drain mercantile, more = lesser effect.\nDefault value: 5. 5 is as expensive as drain mercantile.\nValue is rounded down.",
min = 1, max = 10,
step = 1, jump = 2,
variable = mwse.mcm.createTableVariable{id = "charmMagnitudeRate", table = config }}
-- Minimum Illusion level
illusionPage:createSlider{label = "Alluring Trade - Minimum Illusion",
description = "Minimum Base Illusion level to drain mercantile.\nFortify skills won't work here.\nDefault value: 60.",
min = 1, max = 100,
step = 1, jump = 5,
variable = mwse.mcm.createTableVariable{id = "charmIllusionRequirement", table = config }}

--- Demoralize
illusionPage:createButton{ buttonText = "Permanent Demoralize",
description = "The Flee value of the target will be increased by the Demoralize spell magnitude.\nResistance applies (e.g. Bretons will be harder to scare)." }
-- Enable/Disable
illusionPage:createOnOffButton{label = "Permanent Demoralize - Enable/Disable",
description = "Enable/Disable permanent demoralize",
variable = mwse.mcm.createTableVariable{id = "demoralizeEnabled", table = config}}
-- Enable/Disable Willpower Resistance
illusionPage:createOnOffButton{label = "Permanent Demoralize - Willpower Resistance",
description = "If enabled, the PERMANENT increase will be reduced by 1/3 of the target's willpower.\nYou would still be able to scare a high willpower enemy like vanilla, but to permanently scare them you would need a very high magnitude of Demoralize.",
variable = mwse.mcm.createTableVariable{id = "demoralizeWillpowerResist", table = config}}
-- Minimum Illusion level
illusionPage:createSlider{label = "Permanent Demoralize - Minimum Illusion",
description = "Minimum Base Illusion level to permanently calm.\nFortify skills won't work here.\nDefault value: 70.",
min = 1, max = 100,
step = 1, jump = 5,
variable = mwse.mcm.createTableVariable{id = "demoralizeIllusionRequirement", table = config }}

--- Silence
illusionPage:createButton{ buttonText = "Deafening Silence",
description = "When silence ends, the target will get extra sound effect. The duration depends on the duration of the silence.\nConstant effect counts as 0.\nThe formula for magnitude are:\nmin: 10 + illusion/2 + personality/4 + luck/10\nmax: 15 + illusion + personality/4 + luck/10" }
-- Enable/Disable
illusionPage:createOnOffButton{label = "Deafening Silence - Enable/Disable",
description = "Enable/disable deafening silence, silence extra effect.",
variable = mwse.mcm.createTableVariable{id = "silenceEnabled", table = config}}
-- Chameleon Duration
illusionPage:createSlider{label = "Deafening Silence - Sound Duration",
description = "Duration of Silence required to get 1 second of Sound.\nFor example if the spell is Silence for 40 seconds, you will have 8 second of Sound.\nDefault value: 5.\nValue is rounded down.",
min = 1, max = 100,
step = 1, jump = 5,
variable = mwse.mcm.createTableVariable{id = "silenceDurationRate", table = config }}
-- Minimum Illusion level
illusionPage:createSlider{label = "Deafening Silence - Minimum Illusion",
description = "Minimum Base Illusion level to enable deafening silence.\nFortify skills won't work here.\nDefault value: 80.",
min = 1, max = 100,
step = 1, jump = 5,
variable = mwse.mcm.createTableVariable{id = "silenceIllusionRequirement", table = config }}

--- Paralyze
illusionPage:createButton{ buttonText = "Paralyzing Torpor",
description = "When paralysis ends, the target will get drain speed effect. The duration depends on the duration of the paralyze.\nConstant effect counts as 0.\nThe formula for magnitude are:\nmin: 10 + illusion/2 + personality/4 + luck/10\nmax: 15 + illusion + personality/4 + luck/10" }
-- Enable/Disable
illusionPage:createOnOffButton{label = "Paralyzing Torpor - Enable/Disable",
description = "Enable/disable paralyzing torpor, paralyze extra effect.",
variable = mwse.mcm.createTableVariable{id = "paralyzeEnabled", table = config}}
-- Chameleon Duration
illusionPage:createSlider{label = "Paralyzing Torpor - Drain Speed Duration",
description = "Duration of Paralyze required to get 1 second of Sound.\nFor example if the spell is Paralyze for 40 seconds, you will have 8 second of Sound.\nDefault value: 5.\nValue is rounded down.",
min = 1, max = 100,
step = 1, jump = 5,
variable = mwse.mcm.createTableVariable{id = "paralyzeDurationRate", table = config }}
-- Minimum Illusion level
illusionPage:createSlider{label = "Paralyzing Torpor - Minimum Illusion",
description = "Minimum Base Illusion level to enable paralyzing torpor.\nFortify skills won't work here.\nDefault value: 90.",
min = 1, max = 100,
step = 1, jump = 5,
variable = mwse.mcm.createTableVariable{id = "paralyzeIllusionRequirement", table = config }}

--- Invisibility
illusionPage:createButton{ buttonText = "Persisting Shadows",
description = "When invisibility ends, you will get extra chameleon effect. The duration depends on the duration of the invisibility.\nConstant effect counts as 0.\nThe formula for magnitude are:\nmin: 15 + illusion/2 + personality/4 + luck/10\nmax: 100" }
-- Enable/Disable
illusionPage:createOnOffButton{label = "Persisting Shadows - Enable/Disable",
description = "Enable/disable persisting shadows, invisibility extra effect.",
variable = mwse.mcm.createTableVariable{id = "invisibilityEnabled", table = config}}
-- Chameleon Duration
illusionPage:createSlider{label = "Persisting Shadows - Chameleon Duration",
description = "Duration of Invisibility required to get 1 second of Chameleon.\nFor example if the spell is Invisibility for 40 seconds, and you attack an enemy right away after the effect started, you will have 2 second of Chameleon.\nDefault value: 20.\nValue is rounded down.",
min = 1, max = 100,
step = 1, jump = 5,
variable = mwse.mcm.createTableVariable{id = "invisibilityDurationRate", table = config }}
-- Minimum Illusion level
illusionPage:createSlider{label = "Persisting Shadows - Minimum Illusion",
description = "Minimum Base Illusion level to enable persisting shadows.\nFortify skills won't work here.\nDefault value: 100.",
min = 1, max = 100,
step = 1, jump = 5,
variable = mwse.mcm.createTableVariable{id = "invisibilityIllusionRequirement", table = config }}

mwse.mcm.register(template)