local modInfo = require("MWSEVampireOptions.modInfo")
local config = require("MWSEVampireOptions.config")

local function createPage(template)
	local page = template:createSideBarPage{
		description = 'Vampire options'
	}

	local categoryEffects = page:createCategory("Effects")

	categoryEffects:createYesNoButton{
		label = 'Closed Helmets Hide Vampirism Until Having Dialogue',
		description = "Wearing a closed helmet will hide the player's vampirism. Speaking to an NPC will reveal the player as a vampire.\n\nIf enabling or disabling this option, save and reload for changes to take effect.",
		variable = mwse.mcm.createTableVariable{
			id = 'helmHides',
			table = config,
		},
		defaultSetting = true
	}

	categoryEffects:createYesNoButton{
		label = 'Vampires Can Speak To Those That Adore Them (Or Under Their Command)',
		description = "The player can speak, barter, and train with NPCs normally if the NPC has a disposition of 90 or higher. The NPC will also regard the player as a non-vampire if the NPC is under a Command Humanoid spell.\n\nNPCs which have special quests for vampires are excluded from this mechanic and will always speak to the player as normal.\n\nIf enabling or disabling this option, save and reload for changes to take effect.",
		variable = mwse.mcm.createTableVariable{
			id = 'talkToCharmed',
			table = config,
		},
		defaultSetting = true
	}

	categoryEffects:createYesNoButton{
		label = 'Must Feed To Restore Health',
		description = "Vampires must rely on absorb health spells (such as Vampire Touch) to restore health. Restore health spells, potions, enchantments etc will be resisted.\n\nThis is a mechanic to roleplay needing to feed without adding a complicated hunger mechanic.\n\nIf enabling or disabling this option, save and reload for changes to take effect.",
		variable = mwse.mcm.createTableVariable{
			id = 'cannotRestoreHealth',
			table = config,
		},
		defaultSetting = true
	}
	
	categoryEffects:createYesNoButton{
		label = 'Vampires Do Not Need To Breathe',
		description = "Vampirism gives a permanent waterbreathing ability.\n\nIf enabling or disabling this option, save and reload for changes to take effect.",
		variable = mwse.mcm.createTableVariable{
			id = 'canBreathUnderWater',
			table = config,
		},
		defaultSetting = true
	}

	categoryEffects:createYesNoButton{
		label = 'Vamipres Get The Eye Of Night Spell',
		description = "Vampires get the same zero-cost night-eye spell that Khajiits have.\n\nIf enabling or disabling this option, save and reload for changes to take effect.",
		variable = mwse.mcm.createTableVariable{
			id = 'hasEyeOfNight',
			table = config,
		},
		defaultSetting = true
	}

	categoryEffects:createYesNoButton{
		label = 'Vampires Cannot Walk On Water',
		description = "Water-walking spells will now be resisted. This is a nod to myths that vampires cannot cross running water.\n\nIf enabling or disabling this option, save and reload for changes to take effect.",
		variable = mwse.mcm.createTableVariable{
			id = 'cannotWaterWalk',
			table = config,
		},
		defaultSetting = true
	}

	categoryEffects:createYesNoButton{
		label = 'Vampires Cannot Take Fall Damage',
		description = "Especially useful with the option that disables restoring health, this prevents vampires from taking damage when falling from high heights.\n\nIf enabling or disabling this option, save and reload for changes to take effect.",
		variable = mwse.mcm.createTableVariable{
			id = 'noFallDamage',
			table = config,
		},
		defaultSetting = true
	}

	categoryEffects:createYesNoButton{
		label = 'Vampries Can Rest Until Nightfall',
		description = "A small modification of the 'rest' menu which replaces the 'until healed' option with 'Until Nightfall'  (only when the player is a vampire).\n\nInspired by the mod Limited Resting Waiting and Regen by akh\n\nIf enabling or disabling this option, save and reload for changes to take effect.",
		variable = mwse.mcm.createTableVariable{
			id = 'talkToCharmed',
			table = config,
		},
		defaultSetting = true
	}

	categoryEffects:createYesNoButton{
		label = "Vampire Levitate Spell",
		description = "Gives the player the spell 'vampire fly', which is in the vanilla game but was not added in the vampire script.",
		variable = mwse.mcm.createTableVariable{
			id = 'levitateAbility',
			table = config,
		},
		defaultSetting = true
	}

	categoryEffects:createYesNoButton{
		label = "Silver Weapons Do Increased Damage To Vampires",
		description = "Silver weapons do +50% damage to any vampire (player or NPC).\n\nIf enabling or disabling this option, save and reload for changes to take effect.",
		variable = mwse.mcm.createTableVariable{
			id = 'silverDamageAbility',
			table = config,
		},
		defaultSetting = true
	}

	categoryEffects:createYesNoButton{
		label = "Vampires Take Damage On Temple Grounds",
		description = "Vampires will take a small amount of damage every second they walking on temple grounds.\n\nIf enabling or disabling this option, save and reload for changes to take effect.",
		variable = mwse.mcm.createTableVariable{
			id = 'holyGroundAbility',
			table = config,
		},
		defaultSetting = true
	}

	categoryEffects:createYesNoButton{
		label = "Namira's Shroud Only Works When Taking It Slow",
		description = "Namira's Shroud (an item from Tamriel Rebuilt) will only be in effect when the player is not running.\n\nThis is a way to nerf the Shroud's power in an immersive way; Wearing the Shroud as a Vampire now feels like going undercover.\n\nIf enabling or disabling this option, save and reload for changes to take effect.",
		variable = mwse.mcm.createTableVariable{
			id = 'namiraShroudOnlyWhileWalking',
			table = config,
		},
		defaultSetting = true
	}

	return page
end

local template = mwse.mcm.createTemplate("MWSE Vampire Options")
template:saveOnClose("MWSEVampireOptions", config)

createPage(template)

mwse.mcm.register(template)
