local config = require("TheLawIsSacred.config")

local template = mwse.mcm.createTemplate("The Law Is Sacred")
template:saveOnClose("TheLawIsSacred", config)

local page = template:createSideBarPage()
page.label = "Settings"
page.description = config.version
page.noScroll = false

local category = page:createCategory("Settings")

local messageButton = category:createYesNoButton()
messageButton.label = "Show Messages"
messageButton.description = "Shows messages with information about incurring bounties added by this mod. Does not affect the confirmation message box, or the default jail message box."
messageButton.variable = mwse.mcm:createTableVariable{id = "messages", table = config}

local confirmButton = category:createYesNoButton()
confirmButton.label = "Get Confirmation"
confirmButton.description = "After guards render you unconcious, asks if you want to be arrested, or die."
confirmButton.variable = mwse.mcm:createTableVariable{id = "confirm", table = config}

local animateButton = category:createYesNoButton()
animateButton.label = "Animate Knockout"
animateButton.description = "After the guards reduce them to zero health, the player falls to the ground. You watch the player stay on the ground for a few seconds while the guards keep beating on them."
animateButton.variable = mwse.mcm:createTableVariable{id = "animateKO", table = config}

local deathWarrantButton = category:createYesNoButton()
deathWarrantButton.label = "Death Warrants"
deathWarrantButton.description = "If set to true, guards will kill you instead of arresting you if your bounty is over the threshold defined by Death Warrant Value."
deathWarrantButton.variable = mwse.mcm:createTableVariable{id = "deathWarrant", table = config}

local resistArrestPenaltyField = category:createTextField()
resistArrestPenaltyField.label = "Resist Arrest Penalty"
resistArrestPenaltyField.description = "The amount of gold added to your bounty if you choose to resist arrest. Set to zero to disable this feature."
resistArrestPenaltyField.numbersOnly = true
resistArrestPenaltyField.variable = mwse.mcm:createTableVariable{id = "resistArrestPenalty", table = config}

local guardKillPenaltyField = category:createTextField()
guardKillPenaltyField.label = "Guard Killing Penalty"
guardKillPenaltyField.description = "The amount of gold added to your bounty if you kill a guard. Set to zero to disable this feature. If you have a mod that creates a justified situation for killing guards, then disable this feature."
guardKillPenaltyField.numbersOnly = true
guardKillPenaltyField.variable = mwse.mcm:createTableVariable{id = "guardKillPenalty", table = config}

local deathWarrantValueField = category:createTextField()
deathWarrantValueField.label = "Death Warrant Value"
deathWarrantValueField.description = "If Death Warrants is set to true, then this value determines the threshold at which guards kill rather than arrest. Does not affect the death warrant dialogue."
deathWarrantValueField.numbersOnly = true
deathWarrantValueField.variable = mwse.mcm:createTableVariable{id = "deathWarrantValue", table = config}

mwse.mcm.register(template)