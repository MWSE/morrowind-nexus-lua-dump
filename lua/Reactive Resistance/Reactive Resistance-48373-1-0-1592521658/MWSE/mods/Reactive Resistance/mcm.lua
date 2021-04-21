local config = require("Reactive Resistance.config")

local template = mwse.mcm.createTemplate("Reactive Resistance")
template.headerImagePath = "MWSE/mods/Reactive Resistance/Reactive Resistance Logo v2.tga"
template:saveOnClose("Reactive Resistance", config)

local generalPage = template:createSideBarPage("General Settings")
generalPage.description = config.version

local useUniversalDisableTimeButton = generalPage:createYesNoButton()
useUniversalDisableTimeButton.label = "Use Universal Disable Time"
useUniversalDisableTimeButton.description = "If true, uses the time set below as the disable time for every effect. If false, it uses the times set on each effect page."
useUniversalDisableTimeButton.variable = mwse.mcm:createTableVariable{id = "useUniversalDisableTime", table = config}

local universalDisableTimeField = generalPage:createTextField()
universalDisableTimeField.label = "Universal Disable Time"
universalDisableTimeField.description = "If the above setting is true, then this is the number of seconds any particular disabling effect can last (with respect to scale) before triggering the Time Out"
universalDisableTimeField.variable = mwse.mcm:createTableVariable{id = "universalDisableTime", table = config}

local useUniversalTimeOutTimeButton = generalPage:createYesNoButton()
useUniversalTimeOutTimeButton.label = "Use Universal Time Out Time"
useUniversalTimeOutTimeButton.description = "If true, uses the time set below as the time out time for every effect. If false, it uses the times set on each effect page."
useUniversalTimeOutTimeButton.variable = mwse.mcm:createTableVariable{id = "useUniversalTimeOutTime", table = config}

local universalTimeOutTimeField = generalPage:createTextField()
universalTimeOutTimeField.label = "Universal Time Out Time"
universalTimeOutTimeField.description = "If the above setting is true, then this is the number of seconds a creature or NPC has total resistance to the effect once Time Out is triggered"
universalTimeOutTimeField.variable = mwse.mcm:createTableVariable{id = "universalTimeOutTime", table = config}

local aryonsDominatorOverrideButton = generalPage:createYesNoButton()
aryonsDominatorOverrideButton.label = "Aryon's Dominator Override"
aryonsDominatorOverrideButton.description = "If true, then this mod will not affect the command creature and command humanoid effects from \"Aryon's Dominator\""
aryonsDominatorOverrideButton.variable = mwse.mcm:createTableVariable{id = "aryonsDominatorOverride", table = config}

local spearOfTheHuntOverrideButton = generalPage:createYesNoButton()
spearOfTheHuntOverrideButton.label = "Spear of The Hunt Override"
spearOfTheHuntOverrideButton.description = "If true, then this mod will not affect the paralyze and burden effects from \"Spear of the Hunt\""
spearOfTheHuntOverrideButton.variable = mwse.mcm:createTableVariable{id = "spearOfTheHuntOverride", table = config}

local effectsPage = template:createSideBarPage("Effects")
for key, value in pairs(config.effects) do
    local category = effectsPage:createCategory(key)

    local resistButton = category:createYesNoButton()
    resistButton.label = "Resist"
    resistButton.description = "Is this effect handled by this mod?"
    resistButton.variable = mwse.mcm:createTableVariable{id = "resist", table = value}

    local disableTimeField = category:createTextField()
    disableTimeField.label = "Disable Time"
    disableTimeField.description = "Number of seconds (adjusted by scale, if relevant) before the effect triggers the Time Out"
    disableTimeField.variable = mwse.mcm:createTableVariable{id = "disableTime", table = value}

    local timeOutTimeField = category:createTextField()
    timeOutTimeField.label = "Time Out Time"
    timeOutTimeField.description = "Number of seconds after Time Out is triggered that the creature or NPC is immune to the effect"
    timeOutTimeField.variable = mwse.mcm:createTableVariable{id = "timeOutTime", table = value}

    local compoundButton = category:createYesNoButton()
    compoundButton.label = "Compound"
    compoundButton.description = "If true, scale the disable time based on the magnitude of the spell. Do not set effects with no magnitude (paralyze), or irelevant magnitudes (command) to true."
    compoundButton.variable = mwse.mcm:createTableVariable{id = "compound", table = value}

    local scaleField = category:createTextField()
    scaleField.label = "Scale"
    scaleField.description = "Used in conjunction with the Compound setting. This is the magnitude at which the effect will last equal to Disable Time. For temporary effects (blind) this should be the amount that is completely disabling (100). For permanent effects (damageAttribute), this should be set such that Scale * Disable Time is hampering, but not disabling in most cases."
    scaleField.variable = mwse.mcm:createTableVariable{id = "scale", table = value}
end


mwse.mcm.register(template)