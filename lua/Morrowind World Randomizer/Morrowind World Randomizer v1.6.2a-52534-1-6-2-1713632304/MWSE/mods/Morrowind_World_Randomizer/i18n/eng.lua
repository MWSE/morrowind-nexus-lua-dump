return {
    ["messageBox.enableRandomizer.message"] = "Would you like to enable the randomizer? It cannot be completely undone.",

    ["messageBox.enableRandomizer.button.yes"] = "Yes, enable it",
    ["messageBox.enableRandomizer.button.no"] = "No",

    ["messageBox.randomize.button.yes"] = "Yes, randomize them",

    ["messageBox.selectDistantLandOption.message"] = "Randomization of statics does not work properly with Distant Land. You can fully disable Distant Land or "..
        "disable Distant Statics (statics will be displayed only in nearby cells). This only applies to this character.",

    ["messageBox.selectDistantLandOption.button.disableDistantLand"] = "Disable Distant Land",
    ["messageBox.selectDistantLandOption.button.disableDistantStatics"] = "Disable Distant Statics",
    ["messageBox.selectDistantLandOption.button.disableRandomization"] = "Disable randomization of statics",
    ["messageBox.selectDistantLandOption.button.doNothing"] = "Do nothing",

    ["messageBox.enableLandscapeRand.message"] = "Do you want to enable randomisation of landscape textures? This option will affect all game sessions until it is disabled.",

    ["modConfig.description.region"] = "Principle of the randomizer: First, the position of the object (or value) to be randomized is found in the sorted list, "..
        "then the boundary values of the region are calculated relative to it. The object's position is in the center of the region. Offset shifts the center of the region."..
        "\n\nFor example, in a list of 100 objects, you need to randomize the 50th with a region of 20% and an offset of -10%. The result will be a random object with "..
        "a range of 30 to 50.\n\nMost of the lists are sorted by object level.",

    ["modConfig.description.regionMinMax"] =  "Principle of the randomizer:\nFirst, the position of the object (or value) to be randomized is found in the sorted list,\n"..
        "then the boundary values of the region are calculated relative to it.\nLeft shift decrease(increase if negative) the minimum boundary value\n"..
        "by the shift value multiplied by the list length.\nRight shift increase(decrease if negative) the maximum boundary value\n"..
        "by the shift value multiplied by the list length.\n\n"..
        "For example, in a list of 100 elements,\nyou need to randomize the 50th with the left shift of 20% and the right of 10%.\n"..
        "The result will be a random object with a range of 30 to 60.\n"..
        "If the left shift is 100% and the right is 100% the result will be between 1 and 100.\n"..
        "If the left shift is -20% and the right is 40% the result will be between 70 and 90.\n"..
        "If the left shift is 40% and the right is -20% the result will be between 10 and 30.\n"..
        "If the left shift is 100% and the right is 0% the result will be between 1 and 50.\n"..
        "If the left shift is 0% and the right is 100% the result will be between 50 and 100.\n\nThe minimum range is 5% or 3 items.\nMost of the lists are sorted by object level.",

    ["modConfig.button.apply"] = "Set",

    ["modConfig.label.regionSize"] = "Region size %%",
    ["modConfig.label.regionOffset"] = "Offset %%",

    ["modConfig.label.minMultiplier"] = "Minimum multiplier %%",
    ["modConfig.label.maxMultiplier"] = "Maximum multiplier %%",

    ["modConfig.label.min"] = "Minimum",
    ["modConfig.label.max"] = "Maximum",

    ["modConfig.label.leftShift"] = "Left shift %%",
    ["modConfig.label.rightShift"] = "Right shift %%",

    ["modConfig.label.multiply"] = "Multiply",
    ["modConfig.label.add"] = "Add",

    ["modConfig.label.multiplyBetween"] = "Multiply between",
    ["modConfig.label.addBetween"] = "Add between",

    ["modConfig.label.minVal"] = "Minimum ",
    ["modConfig.label.maxVal"] = "Maximum ",

    ["modConfig.label.enableRandomizer"] = "Enable Randomizer",

    ["modConfig.label.pregeneratedDataTables"] = "Data tables",
    ["modConfig.label.forceTTRData"] = "Force to use Tamriel Rebuilt data",
    ["modConfig.label.pregeneratedItems"] = "Use pregenerated item data",
    ["modConfig.label.pregeneratedCreatures"] = "Use pregenerated creature data",
    ["modConfig.label.pregeneratedHeadHair"] = "Use pregenerated head/hairs data",
    ["modConfig.label.pregeneratedSpells"] = "Use pregenerated spell data",
    ["modConfig.label.pregeneratedHerbs"] = "Use pregenerated herb data",

    ["modConfig.label.randomizeItemInCont"] = "Randomize items in container inventories",
    ["modConfig.label.randomizeItemWithoutCont"] = "Randomize items without a container",
    ["modConfig.label.randomizeNPCItems"] = "Randomize items in NPC inventories",
    ["modConfig.label.randomizeCreatureItems"] = "Randomize items in creature inventories",
    ["modConfig.label.randomizeSoulsInGems"] = "Randomize souls in soulgems",
    ["modConfig.label.randomizeGold"] = "Randomize the amount of gold",

    ["modConfig.label.randomizeCreatures"] = "Randomize ceatures",
    ["modConfig.label.randomizeItems"] = "Randomize items",
    ["modConfig.label.randomizeHealth"] = "Randomize health points",
    ["modConfig.label.randomizeMagicka"] = "Randomize magicka points",
    ["modConfig.label.randomizeFatigue"] = "Randomize fatigue points",
    ["modConfig.label.randomizeDamage"] = "Randomize attack damage",
    ["modConfig.label.randomizeScale"] = "Randomize the object's scale",

    ["modConfig.label.randomizeSkills"] = "Randomize skill values",
    ["modConfig.label.combatSkills"] = "Combat skills",
    ["modConfig.label.magicSkills"] = "Magic skills",
    ["modConfig.label.stealthSkills"] = "Stealth skills",

    ["modConfig.label.randomizeAIFight"] = "Randomize fight parameter",
    ["modConfig.label.randomizeAIFlee"] = "Randomize flee parameter",
    ["modConfig.label.randomizeAIAlarm"] = "Randomize alarm parameter",
    ["modConfig.label.randomizeAIHello"] = "Randomize hello parameter",

    ["modConfig.label.randomizeSpells"] = "Randomize spells",
    ["modConfig.label.randomizeAbilities"] = "Randomize abilities",
    ["modConfig.label.randomizeDiseases"] = "Randomize diseases",
    ["modConfig.label.randomizeAttributes"] = "Randomize attributes",

    ["modConfig.label.addNewEffects"] = "Add positive or negative effects",
    ["modConfig.label.positiveEffects"] = "Positive effects",
    ["modConfig.label.negativeEffects"] = "Negative effects",

    ["modConfig.label.randomizeHead"] = "Randomize the object's head",
    ["modConfig.label.randomizeHair"] = "Randomize the object's hairs",
    ["modConfig.label.limitByRace"] = "Limit by race",
    ["modConfig.label.limitByGender"] = "Limit by gender",

    ["modConfig.label.addNewSpells"] = "Add new spells",
    ["modConfig.label.addNewAbilities"] = "Add new abilities",
    ["modConfig.label.addNewDiseases"] = "Add new diseases",

    ["modConfig.label.randomizeLock"] = "Randomize lock value",
    ["modConfig.label.randomizeTrap"] = "Randomize trap spells",
    ["modConfig.label.addLock"] = "Lock object without a look",
    ["modConfig.label.addTrap"] = "Add a trap to an object without it",

    ["modConfig.label.useOnlyDestruction"] = "Use only destruction spells",

    ["modConfig.label.randomizeDoors"] = "Randomize door destinations",
    ["modConfig.label.randomizeOnlyToNearestDoors"] = "Change destination to nearest doors only",

    ["modConfig.label.disableDistantLand"] = "Disable Distant Land",
    ["modConfig.label.disableDistantStatics"] = "Disable only Distant Statics",

    ["modConfig.label.randomizeHerbs"] = "Randomize herbs",
    ["modConfig.label.randomizeTrees"] = "Randomize trees",
    ["modConfig.label.randomizeStones"] = "Randomize rocks",
    ["modConfig.label.randomizeWeather"] = "Randomize weather",

    ["modConfig.label.mainPage"] = "Main",
    ["modConfig.label.globalPage"] = "Global",
    ["modConfig.label.items"] = "Items",
    ["modConfig.label.creatures"] = "Creatures",
    ["modConfig.label.health"] = "Health",
    ["modConfig.label.magicka"] = "Magicka",
    ["modConfig.label.fatigue"] = "Fatigue",
    ["modConfig.label.attackDamage"] = "Attack damage",
    ["modConfig.label.scale"] = "Scale",
    ["modConfig.label.skills"] = "Skills",
    ["modConfig.label.AI"] = "AI",
    ["modConfig.label.spells"] = "Spells",
    ["modConfig.label.abilities"] = "Abilities",
    ["modConfig.label.diseases"] = "Diseases",
    ["modConfig.label.NPCs"] = "NPCs",
    ["modConfig.label.head"] = "Head",
    ["modConfig.label.hairs"] = "Hairs",
    ["modConfig.label.attributes"] = "Attributes",
    ["modConfig.label.barterTransport"] = "Barter/Transport",
    ["modConfig.label.barterGold"] = "Barter gold",
    ["modConfig.label.transport"] = "Transport",
    ["modConfig.label.containers"] = "Containers",
    ["modConfig.label.locks"] = "Locks",
    ["modConfig.label.traps"] = "Traps",
    ["modConfig.label.doors"] = "Doors",
    ["modConfig.label.destination"] = "Destination",
    ["modConfig.label.world"] = "World",
    ["modConfig.label.herbs"] = "Herbs",
    ["modConfig.label.trees"] = "Trees",
    ["modConfig.label.stones"] = "Rocks",
    ["modConfig.label.weather"] = "Weather",

    ["modConfig.label.maxValueOfSkill"] = "The maximum value of a skill is ",
    ["modConfig.label.chanceToAdd"] = "%% chance to add",
    ["modConfig.label.addXMore"] = "Add  more",

    ["modConfig.description.listLimiter"] = "The level of the creature, in proportion to which the list of spells is limited. If a creature has this level, the whole spell list will be available for randomization.",
    ["modConfig.description.positiveEffects"] = "Positive effects are \"Chameleon\", \"Water Breathing\", \"Water Walking\", \"Swift Swim\", \"Resist Normal Weapons\", \"Sanctuary\", \"Attack Bonus\", \"Resist Magicka\", \"Resist Fire\", \"Resist Frost\", \"Resist Shock\", \"Resist Common Disease\", \"Resist Blight Disease\", \"Resist Corprus\", \"Resist Poison\", \"Resist Paralysis\", \"Shield\"",
    ["modConfig.description.negativeEffects"] = "Negative effects are \"Sound\", \"Silence\", \"Blind\", \"Paralyze\" and \"Resist Normal Weapons\", \"Sanctuary\", \"Attack Bonus\", \"Resist Magicka\", \"Resist Fire\", \"Resist Frost\", \"Resist Shock\", \"Resist Common Disease\", \"Resist Blight Disease\", \"Resist Corprus\", \"Resist Poison\", \"Resist Paralysis\", \"Shield\" with negative value",

    ["modConfig.label.maxValueOfAttribute"] = "The maximum value of a attribute is ",
    ["modConfig.label.minAttributeVal"] = "Minimum attribute value %% relative to the limit",
    ["modConfig.label.maxAttributeVal"] = "Maximum attribute value %% relative to the limit",
    ["modConfig.label.numOfDestinationsWithoutRand"] = "Number of Destinations without randomization ",
    ["modConfig.label.numOfDestinationsToDoor"] = "Number of Destinations to a door ",

    ["modConfig.label.randomizeTransport"] = "Randomize transport destinations",
    ["modConfig.label.randomizeMerchantGold"] = "Randomize merchant's gold supply",

    ["modConfig.label.maxValMulOfTrapSpell"] = "Multiplier of the maximum value of the trap spell list ",

    ["modConfig.description.trapSpellListSize"] = "Spell list size %% = multiplier * player level",

    ["modConfig.label.chanceToRandomize"] = "%% chance to randomize",
    ["modConfig.label.cooldownGameHours"] = "Cooldown  game hours",

    ["modConfig.label.radiusInCellsForCell"] = "Radius in cells for list of nearest cells",

    ["modConfig.label.chanceToLock"] = "%% chance to lock",
    ["modConfig.label.lockLevMul"] = "Lock level multiplier ",

    ["modConfig.description.lockLevMul"] = "New lock level = random (1, multiplier * player level)",

    ["modConfig.label.herbSpeciesPerCell"] = "Number of herb species per cell ",

    ["modConfig.label.minEffectVal"] = "Minimum effect value ",
    ["modConfig.label.maxEffectVal"] = "Maximum effect value ",

    ["modConfig.description.abilitiesCategory"] = "Abilities like the dunmer fire resistance.",

    ["modConfig.label.levelLimiter"] = "Level limiter ",

    ["modConfig.description.chanceToAddAbility"] = "Chance to add for each new ability.",
    ["modConfig.description.chanceToAddDisease"] = "Chance to add for each new disease.",
    ["modConfig.description.chanceToAddEffect"] = "Chance to add for each new effect.",
    ["modConfig.description.chanceToAddSpell"] = "Chance to add for each new spell.",

    ["modConfig.label.logging"] = "Logging",

    ["modConfig.label.cellRandomization"] = "Cell randomization",
    ["modConfig.label.cellRandomizationIntervalRealTime"] = "Cell randomization interval. Real-time s",
    ["modConfig.label.cellRandomizationIntervalGameTime"] = "Cell randomization interval. Game-time h",

    ["modConfig.label.artifactsAsSeparate"] = "Randomize artifacts as a separate category",

    ["modConfig.label.otherSettings"] = "Other",
    ["modConfig.label.randomizeOnlyOnce"] = "Randomize only once",
    ["modConfig.label.randomizeCellOnlyOnce"] = "Randomize a cell only once",
    ["modConfig.label.randomizeNPCOnlyOnce"] = "Randomize an NPC only once",
    ["modConfig.label.randomizeCreatureOnlyOnce"] = "Randomize a creature only once",

    ["modConfig.label.randomizeLoadedCells"] = "Randomize active cells",

    ["modConfig.label.doNotRandomizeInToIn"] = "Don't randomize interior to interior doors",
    ["modConfig.label.smartDoorRandomizer"] = "Use a smart randomization algorithm for interior to interior doors",
    ["modConfig.description.smartDoorRandomizer"] = "Use a smart randomization algorithm that won't let you get stuck in dead-end cells. All doors from interior cells will be randomized when you enter to the first interior cell from the exterior cell.",

    ["modConfig.label.profiles"] = "Presets",
    ["modConfig.label.createNewProfile"] = "Create a new preset",
    ["modConfig.label.profileAdded"] = "The preset added",
    ["modConfig.label.profileNotAdded"] = "This preset already exists",
    ["modConfig.label.selectProfile"] = "Select a preset",
    ["modConfig.label.selectRandProfile"] = "Select a randomization preset",
    ["modConfig.label.load"] = "Load",
    ["modConfig.label.delete"] = "Delete",
    ["modConfig.label.profileLoaded"] = "The preset has been loaded",
    ["modConfig.label.theProfileLoaded"] = "\"%{profile}\" preset has been loaded",
    ["modConfig.label.profileNotLoaded"] = "The preset was not loaded",

    ["modConfig.description.willBeAppliedAfterNext"] = "Will be applied after the next randomization.",
    ["modConfig.description.randomizeCellOnlyOnce"] = "Attention, objects affected by this option can never be randomized again. Even if the option is disabled.",

    ["modConfig.label.randomizeDoorsWhenCellLoading"] = "Randomize doors during cell randomization step",

    ["modConfig.label.smartAlgorithm"] = "A smart algorithm",
    ["modConfig.label.tryToRandBothDoors"] = "Try to randomize both in and out doors",

    ["modConfig.label.randomizeLight"] = "Randomize light objects",
    ["modConfig.label.light"] = "Light objects",

    ["modConfig.label.landTextures"] = "Land textures",
    ["modConfig.label.rerandomizeLandTextures"] = "Re-randomize land textures",
    ["modConfig.label.randomizationOfLandTextures"] = "Randomization of land textures",
    ["modConfig.label.randomizeLandTextureOnlyOnce"] = "Randomize land textures only once",
    ["modConfig.description.randomizationOfLandTextures"] = "As long as this setting is enabled, the landscape textures of all game characters will be changed. Deactivation requires a restart of the game.",

    ["modConfig.label.randomizeBaseItems"] = "Randomize all items according to the settings below",
    ["modConfig.label.itemStats"] = "Item stats",
    ["modConfig.label.randomizeItemStats"] = "Randomize item stats",
    ["modConfig.label.weaponDamageStats"] = "Weapon speed and damage stats",
    ["modConfig.label.itemEnchantment"] = "Item enchantments",
    ["modConfig.label.randomizeItemEnch"] = "Randomize the enchantment on an item of equipment",
    ["modConfig.label.numberOfEnchCasts"] = "The number of times you can cast an enchantment",
    ["modConfig.label.minEnchCost"] = "Minimum enchantment cost",
    ["modConfig.label.maxEnchCost"] = "Maximum enchantment cost",
    ["modConfig.label.enchCost"] = "Enchantment cost",
    ["modConfig.label.enchEffects"] = "Effects",
    ["modConfig.label.safeEnchantmentForConstant"] = "Don't add damaging effects to constant enchantments",
    ["modConfig.label.oneEnchTypeChance"] = "Chances are the effects will be of the same type in terms of range",
    ["modConfig.label.maxEnchEffCount"] = "Maximum number of effects",
    ["modConfig.label.chanceToNegativeEffectForConstant"] = "Chance to add a negative effect to a constant enchantment",
    ["modConfig.label.chanceToNegativeEffectForTarget"] = "Chance to add a negative effect to a target/touch enchantment",
    ["modConfig.label.maxEnchEffectDuration"] = "Maximum effect duration",
    ["modConfig.label.maxEnchEffectRadius"] = "Maximum effect radius",
    ["modConfig.label.maxEnchEffectMagnitude"] = "Maximum effect magnitude",
    ["modConfig.label.chanceAddEnchantment"] = "Chance to add an enchantment to an item without it",
    ["modConfig.label.chanceRemoveEnchantment"] = "Chance to remove an enchantment",
    ["modConfig.label.addedEnchPower"] = "The power of a new enchantment",
    ["modConfig.label.randItemMeshes"] = "Randomize item models",
    ["modConfig.label.randItemParts"] = "randomize wearable parts",

    ["modConfig.description.itemStatsRandValue"] = "The higher the value, the better the item",
    ["modConfig.description.itemStatsRandEnch"] = "The higher the value, the better the enchantment",

    ["modConfig.message.randItemStats"] = "Do you want to randomize almost all items stats (e.g. weight, price, enchantment, etc.) and models? This applies to wearable items as well.",
    ["modConfig.label.randBaseItemToPreset"] = "Randomize according to the loaded preset",
    ["modConfig.label.randBaseItemOnlyStats"] = "Randomize only stats",
    ["modConfig.label.randBaseItemOnlyModels"] = "Randomize only models",
    ["modConfig.label.randBaseItemAll"] = "Randomize all",

    ["modConfig.label.excludeScrolls"] = "Exclude scrolls",
    ["modConfig.label.excludeAlchemy"] = "Exclude potions",
    ["modConfig.label.dontAddToScrolls"] = "Don't add to scrolls",
    ["modConfig.label.addNewEnch"] = "Add a new enchantment",
    ["modConfig.label.removeEnch"] = "Remove an enchantment",
    ["modConfig.label.maxAlchemyEffCount"] = "Maximum number of effects for a potion",
    ["modConfig.label.dontRemoveFromScrolls"] = "Don't remove from scrolls",

    ["modConfig.label.randomizeEffectsFromScrolls"] = "Randomize the enchantment on a scroll",
    ["modConfig.label.randomizeEffectsFromAlchemy"] = "Randomize effects on a potions",
    ["modConfig.label.randomizeEffectsFromIngredient"] = "Randomize effects on a ingredient",

    ["modConfig.label.newEnchPower"] = "New enchantment power",

    ["modConfig.label.useExistingEnch"] = "Randomize to the enchantment that exists in the game",
    ["modConfig.label.existedEnchValue"] = "Region to randomize existing enchantments",
    ["modConfig.label.potionEffNum"] = "Number of effects on a potion",
    ["modConfig.label.ingredientEffNum"] = "Number of effects on an ingredient",

    ["modConfig.label.allowDoubleLoad"] = "Allow double loading of a save",

    ["messageBox.randomizeOnce.message"] = "Do you want the cells to keep randomizing after a certain period of time or just once (you can do this manually from the Mod Config menu)?",
    ["modConfig.label.leaveAccordingToPreset"] = "Leave it according to the loaded preset",
    ["modConfig.label.randomizingAfterCertainPeriod"] = "After a certain period of time",
    ["modConfig.label.randomizingJustOnce"] = "Just once",

    ["modConfig.label.doNotRandomizeInventoryForHerb"] = "Don't randomize inventory for new herbs",

    ["modConfig.label.doNotLockIfNoEnemy"] = "Don't lock the door if there is no enemy in the cell",
    ["modConfig.label.doNotTrapIfNoEnemy"] = "Don't trap the door if there is no enemy in the cell",
    ["modConfig.label.minFightToBeEnemy"] = "Minimum fight value to be considered an enemy",

    ["modConfig.label.fortifyForSelfChance"] = "Chance to add a fortify type effect to an \"on self\" enchantment",
    ["modConfig.label.damageForTargetChance"] = "Chance to add a damage type effect to an \"on target/touch\" enchantment",

    ["modConfig.label.flora"] = "Other static flora",
    ["modConfig.label.randomizeFlora"] = "Randomize flora",
    ["modConfig.label.speciesPerCell"] = "Species per cell",
    ["modConfig.label.linkMeshToParts"] = "Use the same model with the wearable part and the world object",
    ["modConfig.description.linkMeshToParts"] = "Without this option, wearable items may have different models in the world and on the player/NPC.",

    ["modConfig.label.makeItemsUnique"] = "Make all wearable items unique",
    ["modConfig.description.makeItemsUnique"] = "Once enabled, it cannot be disabled.\n\nAll wearable items you can find in the game will have unique characteristics.\n\nIn order not to break quests, the original item will be placed in the inventory. But it will be hidden. Some inventory mods may break this feature.\n\nDON'T ENABLE THIS OPTION AFTER THE SHIP SECTION, BECAUSE MANY ITEMS THAT ARE OUTSIDE THE PLAYER'S INVENTORY CAN BE LOST.",

    ["modConfig.label.durationForConstant"] = "The duration component in the constant enchantment formula",
    ["modConfig.description.durationForConstant"] = "Default id 100.\nMorrowind effect cost formula is\n(Min Magnitude + Max Magnitude) * (Duration + Area) * (Base Cost / 40)\n\nThe lower the value, the more powerful the constant enchantments.",

    ["modConfig.text.warningAboutRandomization"] = "Most of the settings from the following tabs will only be applied during the next randomization.\nMost of the settings are stored in the game session and will be lost if you don't save the game before.",

    ["modConfig.message.uniqueItems"] = "Do you want to make each wearable item unique with random stats and enchantments?\n\nOnce enabled, it cannot be disabled.\nIn order not to break quests, the original item will be placed in the inventory. But it will be hidden. Some inventory mods may break this feature.\n\nIf you want items to be less random, try using DRIP instead.",

    ["modConfig.label.arrowPower"] = "Arrow enchantment power multiplier is %%",

    ["modConfig.label.scrollEnchCapacity"] = "Base enchantment capacity for a scroll",
    ["modConfig.label.restoreForAlchemyChance"] = "Chance to add a restore health/fatigue/magicka effect for a potion %%",

    ["modConfig.description.itemStatsGeneration"] = "The options below will work after item stat randomization, which is triggered by the button below. The exception is unique wearable items. With them, the options will work on the next generated new item.",

    ["modConfig.label.spellsBySkill"] = "This will be the new spell from the schools with the highest skill value",
    ["modConfig.label.spellsBySkillMax"] = "Number of spell schools with the highest skills value",

    ["modConfig.button.runInitialization"] = "Run initialization",
    ["modConfig.message.modEnabled"] = "The randomizer is enabled",

    ["modConfig.label.chanceToAddSoul"] = "Chance to add a soul to an empty soulgem",

    ["modConfig.label.generateTreeData"] = "Generate tree data after the game starts",
    ["modConfig.label.generateRockData"] = "Generate rock data after the game starts",
    ["modConfig.text.dataGeneration"] = "By default, the mod uses pregenerated data tables (with base game data, Tamriel Data v10 and OAAB Data) for randomization of rock and tree static objects. You can enable the options below to generate this data when the game starts.",
    ["modConfig.label.regenerateData"] = "Re-generate all data",
}