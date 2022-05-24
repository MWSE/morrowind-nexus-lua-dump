return {
	["mod.name"] = "Enchantment Services Redone",
	["mod.updateRequired"] = "Enchantment Services Redone requires the latest version of MWSE. Please run MWSE-Updater.exe.",

	["service.deciphering.name"] = "Deciphering",
	["service.deciphering.description"] = "Request deciphering of a scroll to learn its effects as a spell.",
	["service.deciphering.descriptionLong"] = "The deciphering service allows learning the effects of a magic scroll as a spell. Deciphering a scroll creates a new spell, with effects identical to those of the scroll's enchantment. By default, the service is offered by NPCs and creatures who offer the spellmaking service, but don't offer repairs, transcription, or recharging services.",
	["service.deciphering.spellTooltip"] = "Deciphered from %{scroll}",
	["service.deciphering.scrollPatterns"] =
		-- If a scroll's name contains one of the strings below then it can be deciphered.
		-- When deciphered, the first match will be removed from the name.
		-- case-insensitive
		"scroll of the"
		.. "\nscroll of"
		.. "\nscroll"
	,
	["service.deciphering.cantDecipher"] = "I lack the skills to decipher that scroll.",
	["service.deciphering.spellLearned"] = "You have learned the spell %{spellName}.",
	["service.deciphering.selectMenu.title"] = "Select the scroll to decipher",
	["service.deciphering.selectMenu.noResultsText"] = "You have no scrolls to decipher.",

	["service.transcription.name"] = "Transcription",
	["service.transcription.verb"] = "Transcribe",
	["service.transcription.description"] = "Request transcription of a magic scroll to create additional copies of it.",
	["service.transcription.descriptionLong"] = "Transcription allows the creation of additional copies of a magic scroll. This requires a source scroll with the desired enchantment, a filled soul gem and, optionally, blank scrolls to copy the enchantment to."
		.. "\n\nTranscribing scrolls can be allowed both by the player, and as a service:"
		.. "\n - Self-transcribing is accessed by equipping a filled soul gem."
		.. "\n - By default, the transcription service is offered by NPCs and creatures who offer the enchanting service, sell enchanted items and don't offer repairs.",
	["service.transcription.equippedSoulGemButton"] = "Transcribe a Magic Scroll",
	["service.transcription.enchantCapacity"] = "Enchant Capacity: %{enchantCapacity}",

	["service.transcription.mainMenu.customNameTooltip"] = "Name of the created transcription.",
	["service.transcription.mainMenu.sourceLabel"] = "Source",
	["service.transcription.mainMenu.sourceTooltip"] = "Slot for the scroll with the original enchantment. Only enchanted scrolls can be used.",
	["service.transcription.mainMenu.scrollLabel"] = "Scroll",
	["service.transcription.mainMenu.scrollTooltip"] = "Slot for the scroll on which to transcribe the enchantment. Only empty, unenchanted scrolls can be used. If the scroll has a lower enchant capacity than the Source, the effects of the enchantment will be reduced and effects that have no duration, magnitude or radius will be discarded.",
	["service.transcription.mainMenu.scrollTooltipLowPower"] = "The scroll has a lower enchant capacity than the Source. This will reduce the effects of the enchantment, and effects that have no duration, magnitude or radius will be discarded.",
	["service.transcription.mainMenu.soulGemTooltip"] = "Slot for the soul gem used to transcribe the scroll. Only soul gems filled with a soul can be used.",	-- sEnchantmentHelp2

--	["service.transcription.mainMenu.costLabel"] = "Cost",
	["service.transcription.mainMenu.countLabel"] = "Count",
	["service.transcription.mainMenu.countTooltipScrollAndSoul"] = "Number of copies to create. Can't be higher than the number of scrolls in the Scroll slot, or higher than what the selected soul allows for.",
	["service.transcription.mainMenu.countTooltipScroll"] = "Number of copies to create. Can't be higher than the number of scrolls in the Scroll slot.",
	["service.transcription.mainMenu.countTooltipSoul"] = "Number of copies to create. Can't be higher than what the selected soul allows for.",
	["service.transcription.mainMenu.countTooltip"] = "Number of copies to create.",
	["service.transcription.mainMenu.maxCount"] = "Max Count",

	["service.transcription.mainMenu.soulAmountLabel"] = "Soul Used",
	["service.transcription.mainMenu.soulAmountTooltip"] = "The first number is the amount of soul required for the transcription. The second number is the amount of soul in the selected soul gem.",
	["service.transcription.mainMenu.costTooltip"] = "Total cost of the transcription.",
	["service.transcription.mainMenu.goldTooltip"] = "Amount of gold you currently have.",

	["service.transcription.mainMenu.noSource"] = "You must select an enchanted scroll to use as the source of the transcription.",
	["service.transcription.mainMenu.noTargetScroll"] = "You must select an empty scroll on which to transcribe the enchantment.",
	["service.transcription.mainMenu.noSoulGem"] = "You must select a soul gem with a soul to transcribe the scroll.",		-- sNotifyMessage52
	["service.transcription.mainMenu.lowSoul"] = "You must select a soul gem with a larger soul to transcribe that scroll.",
	["service.transcription.mainMenu.noEffectsOnResult"] = "You must select an empty scroll with a higher enchant capacity to transcribe that enchantment.",
	["service.transcription.mainMenu.cantTranscribe"] = "I lack the skills to transcribe that scroll.",

	["service.transcription.mainMenu.chanceTooltip"] = "The chance you have of succeeding in the transcription.",
	["service.transcription.mainMenu.transcriptionSucceeded"] = "The scroll has been successfully transcribed.",
	["service.transcription.mainMenu.transcriptionFailed"] = "The transcription failed and your gem is destroyed.",	-- sNotifyMessage34

	["service.transcription.select.scroll.title"] = "Empty Scrolls",
	["service.transcription.select.scroll.noResultsText"] = "You have no empty scrolls.",
	["service.transcription.select.scroll.transcriptionSourceEnchantCapacity"] = "Enchant Capacity of Source: %{enchantCapacity}",
	["service.transcription.select.source.title"] = "Magic Scrolls",
	["service.transcription.select.source.noResultsText"] = "You have no scrolls to transcribe.",

	["experimental.transcription.requireScrollCrash"] = "It looks like the game crashed while last saving. This was likely caused by Enchantment Services Redone. A backup-save called \"esrBackup\" was created before the crash. Sending this save file to Virnetch#0293 on Discord will help fix this crash."
		.. "\n\nDisabling the option \"Require Scroll\" under the Transcription settings in the MCM will prevent crashes like this from happening in the future.",


	["service.recharge.name"] = "Recharging",
	["service.recharge.description"] = "Request recharging of an enchanted item.",
	["service.recharge.descriptionLong"] = "Recharging enchanted items is now available as a service. Using the service restores an item's charge to maximum. By default, the service is offered by NPCs and creatures who offer the enchanting service, sell enchanted items and don't offer repairs.",
	["service.recharge.cantRecharge"] = "I lack the skills to recharge that item.",
	["service.recharge.selectMenu.title"] = "Select items to recharge",
	["service.recharge.selectMenu.noResultsText"] = "You have no items that require recharging.",


	["mcm.restartRequired"] = "Changing this option requires a restart for the changes to come to effect.",
	["mcm.default"] = "Default: %{defaultSetting}",

	["mcm.mainDescription.header"] = "Enchantment Services Redone v%{version} by Virnetch",
	["mcm.mainDescription.description"] = "Adds NPC services for recharging enchanted items, deciphering magic scrolls and the option to transcribe magic scrolls, both by the player, and through a service. Adds empty scrolls from OAAB to enchanters and booksellers, and disables the passive recharging of enchanted items."
		.. "\n\nUse this menu to tweak options to your liking. Hover over individual settings to learn more about them.",
	["mcm.mainDescription.svengineer99"] = "Inspired by svengineer99's",

	["mcm.link.esr.link"] = "https://www.nexusmods.com/morrowind/mods/51249",
	["mcm.link.Enchantment_Services.name"] = "MWSE 2.1 Enchantment Services",
	["mcm.link.Enchantment_Services.link"] = "https://www.nexusmods.com/morrowind/mods/45554",
	["mcm.link.OAAB_Data.name"] = "OAAB_Data",
	["mcm.link.OAAB_Data.link"] = "https://www.nexusmods.com/morrowind/mods/49042",
	["mcm.link.OAAB_Integrations.name"] = "OAAB Integrations: Scroll Qualities",
	["mcm.link.OAAB_Integrations.link"] = "https://www.nexusmods.com/morrowind/mods/49045",
	["mcm.link.buyingGame.name"] = "Buying Game",
	["mcm.link.buyingGame.link"] = "https://www.nexusmods.com/morrowind/mods/50574",

	["mcm.category.gmst"] = "Game Settings (GMST)",
	["mcm.category.general"] = "General Settings",
	["mcm.category.service"] = "Service Settings",
	["mcm.category.player"] = "Player Settings",
	["mcm.category.blankScrolls"] = "Blank Scrolls",
	["mcm.category.misc"] = "Miscellaneous Settings",
	["mcm.category.modLinks"] = "Links to recommended mods:",

	["mcm.page.general.label"] = "General",
	["mcm.page.items.label"] = "Item Additions",

	["mcm.page.offerers.label"] = "Service Offerers",
	["mcm.page.offerers.description"] = "This page allows you to edit who offers each of the services. First, select the service you want to edit from the buttons in the middle. You can then remove the service from someone by clicking their id in the list on the left, or add it to someone from the list on the right. Note that the Blank Scrolls option can be added to NPCs who don't barter books. These NPCs will receive the scrolls but won't be able to sell them."
		.. "\n\nThese settings can be reset for each service by clicking the button at the bottom of the service's settings page.",
	["mcm.page.offerers.leftListLabel"] = "Offers Service",
	["mcm.page.offerers.rightListLabel"] = "Does not offer Service",

	["mcm.page.service.description"] = "Change settings related to %{serviceName}.\n\n%{serviceDescription}",


	["mcm.general.modEnabled.label"] = "Enable Mod",
	["mcm.general.modEnabled.description"] = "Enable or disable the entire mod.",
	["mcm.general.showTooltips.label"] = "Show Service Tooltips",
	["mcm.general.showTooltips.description"] = "Enable to show tooltips for the services in the dialog window.",

	["mcm.general.changePassiveRecharge.label"] = "Change Magic Item Recharge per second",
	["mcm.general.changePassiveRecharge.description"] = "Enable to apply the below setting. Otherwise the GMST will not be changed by this mod.",
	["mcm.general.passiveRecharge.label"] = "Magic Item Recharge per second",
	["mcm.general.passiveRecharge.description"] = "Changes the fMagicItemRechargePerSecond GMST that controls how fast enchanted items recharge over time."
		.. "\n\n"
		.. "Vanilla Default: 0.05"
		.. "\nNo restart required when changing this setting.",

	["mcm.itemAdditions.frequency.label"] = "Frequency",
	["mcm.itemAdditions.frequency.description"] = "Controls the number of items added. Increase for more items, decrease for less. This will only affect NPCs who haven't received the items yet, unless Buying Game is installed, in which case changes for already affected NPCs will come to effect after their next restock.",
	["mcm.itemAdditions.blankScrolls.enabled.label"] = "Enable Blank Scrolls additions",
	["mcm.itemAdditions.blankScrolls.enabled.description"] = "If enabled, blank scrolls with varying enchant capacities will be added to booksellers and enchanters. The number of scrolls added depends on the NPC's base barter gold. NPCs who barter enchanted items will receive roughly double the usual amount. Note that some NPCs might barter magic scrolls without bartering regular books. These NPCs won't receive the empty scrolls."
		.. " This option is recommended if using the \"Require Scroll\" option for the Transcription service."
		.. "\n\nThe added scrolls come from OAAB, so this option requires \"OAAB_Data\". Without it, enabling this option does nothing."
		.. "\n\nIf enabled, the following mods are also highly recommended:"
		.. "\n - \"Buying Game\" - Improves the restocking of these scrolls by adding a delay between restocks, and increasing variety between the items added on each restock."
		.. "\n - \"OAAB Integrations: Scroll Qualities\" - Automatically replaces the meshes of enchanted scrolls with the ones added by OAAB, depending on their value. This changes the enchant capacities of these scrolls, resulting in the requirement of higher soul sizes for transcribing more expensive scrolls."
		.. "\n - \"OAAB Integrations: Leveled Lists\" and other mods dependent on OAAB are also recommended since they can add these scrolls to the game world.",

	["mcm.general.dispositionFactor.label"] = "Disposition effect on service skill requirements",
	["mcm.general.dispositionFactor.description"] = "If skill requirements are enabled for a service, the required chance an NPC has to have to be able to offer the service for a given item will be altered based on your disposition with them. This setting controls the maximum possible change in required chance: At 50 disposition the required chance won't be changed, at 0 it will be increased by this number, and at 100 it will be decreased by this number."
		.. "\n\nThis setting will have no effect if service requirements are disabled for all services.",

	["mcm.service.enable.label"] = "Enable %{serviceName}",
	["mcm.service.enable.description"] = "Enable or disable %{serviceName} entirely.",

	["mcm.service.enableService.label"] = "Enable %{serviceName} Service",
	["mcm.service.enableService.description"] = "Enable or disable the %{serviceName} service. If disabled, NPCs won't offer this service.",
	["mcm.service.costMult.label"] = "Service Cost multiplier",
	-- ["mcm.service.costMult.description"] = "Change how much gold the services cost.",
	["mcm.service.recharge.costMult.description"] = "Change how much gold the services cost. The cost for recharging a specific item is determined by its value, maximum charge, the amount of charge that has to be restored, and the regular checks for disposition, mercantile, etc.",
	["mcm.service.transcription.costMult.description"] = "Change how much gold the services cost. The service's cost is determined by the source scroll's value, its enchantment, the number of transcriptions created, and the regular checks for disposition, mercantile, etc.",
	["mcm.service.deciphering.costMult.description"] = "Change how much gold the services cost. If set to 1, the cost of deciphering a scroll is equal to the cost of the resulting spell, if it were sold by the same NPC. If set to 0.7, the cost will be roughly* equal to what making the spell using the Spellmaking service would cost. \n\n * The Spellmaking service doesn't take into account disposition and mercantile, while deciphering does.",

	["mcm.service.enableChance.label"] = "Enable Skill Requirements",
	["mcm.service.enableChance.description"] = "Enable or disable requirements for the %{serviceName} service. If enabled, only NPCs with high enough skills will offer the service for a given item.",
	["mcm.service.deciphering.enableChance.description"] = "Enable or disable requirements for the Deciphering service. If enabled, only NPCs with high enough cast chance for the deciphered spell will be able to offer the service.",

	["mcm.service.recharge.chanceRequired.label"] = "Required chance",
	["mcm.service.recharge.chanceRequired.description"] = "Change the required chance an NPC has to have for recharging an item to be able to offer the service for it. This number is also slightly modified depending on the NPC's current disposition. The effect disposition has can be changed under General settings.",
	["mcm.service.transcription.chanceRequired.label"] = "Required chance",
	["mcm.service.transcription.chanceRequired.description"] = "Change the required chance an NPC has to have for transcribing a scroll to be able to offer the service for it. This number is also slightly modified depending on the NPC's current disposition. The effect disposition has can be changed under General settings.",
	["mcm.service.deciphering.chanceRequired.label"] = "Required cast chance",
	["mcm.service.deciphering.chanceRequired.description"] = "Change the cast chance the NPC has to have for the deciphered spell to be able to decipher it. This number is also slightly modified depending on the NPC's current disposition. The effect disposition has can be changed under General settings.",

	["mcm.service.resetOfferers.buttonText"] = "RESET",
	["mcm.service.resetOfferers.label"] = "Reset service offerers to default",
	["mcm.service.resetOfferers.description"] = "Clicking this button will reset the settings for who offers the %{serviceName} service. This reverts any changes made for this service in the %{offerersPageLabel} page.",
	["mcm.service.resetOfferers.message"] = "Settings for who offers the %{serviceName} service have been reset to the default values.",

	["mcm.service.deciphering.npcLearns.label"] = "Decipherer learns spell",
	["mcm.service.deciphering.npcLearns.description"] = "If enabled, the NPC offering the service will also learn the deciphered spell.",
	["mcm.service.deciphering.showSourceInTooltip.label"] = "Show scroll's name in spell's tooltip",
	["mcm.service.deciphering.showSourceInTooltip.description"] = "If enabled, the name of the original scroll will be shown in the deciphered spell's tooltip.",

	["mcm.service.deciphering.sourceTextToShowInTooltip.label"] = "Scroll's text to show in spell's tooltip",
	["mcm.service.deciphering.sourceTextToShowInTooltip.description"] = "Select an option to show the original scroll's text in the deciphered spell's tooltip."
		.. "\n\nDefault: First line only",
	["mcm.service.deciphering.sourceTextToShowInTooltip.options.nothing"] = "Nothing",
	["mcm.service.deciphering.sourceTextToShowInTooltip.options.full"] = "Full text",
	["mcm.service.deciphering.sourceTextToShowInTooltip.options.oneLine"] = "First line only",
	["mcm.service.deciphering.sourceTextToShowInTooltip.options.fullEnglish"] = "Full text translated to English",
	["mcm.service.deciphering.sourceTextToShowInTooltip.options.oneLineEnglish"] = "First line only translated to English",

	["mcm.service.transcription.requireScroll.label"] = "Require Scroll",
	["mcm.service.transcription.requireScroll.description"] = "If enabled, transcription requires an empty, unenchanted scroll. When transcribing, a copy of the empty scroll is created, and the enchantment is added to this scroll. If the empty scroll has a lower enchant capacity than the original scroll, the magnitude, duration, and radius of the effects are reduced, and effects that have no duration, magnitude or radius will be discarded."
		.. "\n\nIf disabled, transcribing does not require an additional scroll. When transcribing, an additional copy of the original scroll is added to the player."
		.. "\n\nIf enabled, the following mods are also highly recommended:"
		.. "\n - \"OAAB_Data\" - Adds blank scrolls with varying enchant capacities. \"OAAB Integrations: Leveled Lists\" and other mods dependent on OAAB are also recommended since they can add these scrolls to the game world."
		.. "\n - \"OAAB Integrations: Scroll Qualities\" - Automatically replaces the meshes of enchanted scrolls with the ones added by OAAB, depending on their value. This makes transcribing expensive scrolls require an expensive target scroll, or the effects of the enchantment will get weaker."
		.. "\n - A mod that adds restocking blank scrolls to vendors. This mod includes a feature that dynamically adds the scrolls from OAAB to enchanters and booksellers, this can be enabled on the Item Additions page.",
	["mcm.service.transcription.requireSoulGem.label"] = "Require Soul Gem",
	["mcm.service.transcription.requireSoulGem.description"] = "If enabled, transcription requires a filled soul gem. The amount of soul required is equal to the enchant capacity of the empty scroll, multiplied by the number of transcriptions you want to create. If the \"Require Scroll\" option is disabled, the enchant capacity of the original scroll is used instead.",

	["mcm.service.transcription.enablePlayer.label"] = "Enable self-transcribing",
	["mcm.service.transcription.enablePlayer.description"] = "If enabled, the player can transcribe scrolls. This is accessed from the same menu as recharging or creating enchanted items.\n\nThis option will also add a cancel button to the menu that appears when equipping a filled soul gem.",
	["mcm.service.transcription.playerChanceMult.label"] = "Difficulty Multiplier",
	["mcm.service.transcription.playerChanceMult.description"] = "This value controls the difficulty of transcribing for the player. Increasing this value will make transcribing scrolls harder, while decreasing it will make it easier.",
	["mcm.service.transcription.experienceMult.label"] = "Enchant skill experience gain multiplier",
	["mcm.service.transcription.experienceMult.description"] = "Change the amount of Enchant skill experience gained by successfully transcribing a scroll. The amount of experience gained is equal to the amount of experience gained by creating an enchanted item, multiplied by the square root of the number of transcriptions created, multiplied by this value.",

	["mcm.service.transcription.customName.label"] = "Allow custom name",
	["mcm.service.transcription.customName.description"] = "Adds a text field to the transcription menu to allow changing the created transcription's name."
		.. "\n\nThis option requires the \"Require Scroll\" option. Without it, enabling this option does nothing.",
	["mcm.service.transcription.showOriginalText.label"] = "Show original text",
	["mcm.service.transcription.showOriginalText.description"] = "Whether or not to show the original scroll's text when reading a transcription. If disabled, the displayed text will instead list the effects of the enchantment, similar to player enchanted scrolls in vanilla.",
	["mcm.service.transcription.preventScripted.label"] = "Prevent using scripted scrolls",
	["mcm.service.transcription.preventScripted.description"] = "If enabled, scrolls that have scripts can not be used in the transcription menu. If disabled, scripted scrolls can be used, but the scripts won't be added to newly created objects. Disabling this option might cause issues, do it at your own risk.",
}