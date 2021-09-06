local modInfo = require("RationalNames.modInfo")
local config = require("RationalNames.config")
local data = require("RationalNames.data")
local common = require("RationalNames.common")

local titles = {
    overall = "Overall",
    prefix = "Prefix",
    baseName = "Base Name",
}

local blacklistDescription = {
    overall = "Blacklisted items will not be touched by this mod at all.",
    prefix = "Blacklisted items will not have prefixes added by this mod (though they might still have their base names changed). This will remove prefixes entirely (not just hide them), which will affect item sorting.",
    baseName = "Blacklisted items will not have their base names changed by this mod (though they might still have a prefix added if applicable).",
}

local labels = {
    overall = "component",
    prefix = "prefixes",
    baseName = "base name changes",
}

-- Returns a list of the IDs of every object potentially affected by this mod, to populate the blacklists.
local function blacklist()
    local list = {}

    for _, objectType in ipairs(data.components) do
        for object in tes3.iterateObjects(objectType) do
            if common.checkValidObject(object) then
                table.insert(list, object.id:lower())
            end
        end
    end

    table.sort(list)
    return list
end

local function createMainPage(template)
    local page = template:createSideBarPage{
        label = "Settings",
        description =
            modInfo.mod .. "\n" ..
            "Version " .. modInfo.version .. "\n" ..
            "\n" ..
            "This mod renames many items to improve the way they sort in the inventory. To very briefly summarize the most important changes:\n" ..
            "\n" ..
            "Weapons/ammunition: Sort by type, and optionally by max attack.\n" ..
            "\n" ..
            "Armor: Sort by weight class, slot, and optionally by base armor rating.\n" ..
            "\n" ..
            "Clothing: Sort by slot.\n" ..
            "\n" ..
            "Potions: Sort by effect. Drinks sort at end, and other special potions sort at beginning.\n" ..
            "\n" ..
            "Ingredients: Minor name tweaks for a couple items.\n" ..
            "\n" ..
            "Books: Non-magic scrolls sort at beginning. Magic scrolls sort at end.\n" ..
            "\n" ..
            "Lights: Sort by radius, then by time, then by light type (e.g. candles, lanterns).\n" ..
            "\n" ..
            "Misc items: Keys, soulgems and propylon indexes sort separately. Gold sorts at end.\n" ..
            "\n" ..
            "Apparatus/lockpicks/probes/repair items: Sort in quality order.\n" ..
            "\n" ..
            "Other changes to item names have also been made for more convenient inventory sorting. Additionally, item names can now be longer than 31 characters. See the documentation for details.\n" ..
            "\n" ..
            "Hover over each option to learn more about it.",
    }

    local categoryGeneral = page:createCategory("General Settings")

    categoryGeneral:createYesNoButton{
        label = "Enable mod",
        description =
            "Use this button to enable or disable the mod.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "enable",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    categoryGeneral:createYesNoButton{
        label = "Set value/weight of keys to 0",
        description =
            "If this option is enabled, all keys will have their value and weight set to 0.\n" ..
            "\n" ..
            "In the Construction Set, the value of almost all keys is 300, but only those that don't open anything can actually be sold. This is a consistency change so you can no longer sell a handful of keys for good money while the rest are valueless. Also, two vanilla keys have a weight above 0, which is also lowered to 0 for consistency.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "keyWeightValue",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    categoryGeneral:createYesNoButton{
        label = "Set isKey flag for all keys",
        description =
            "If this option is enabled, all keys will have the \"isKey\" flag set to true.\n" ..
            "\n" ..
            "In vanilla Morrowind, any misc item that is set to open a lock has the \"isKey\" flag set. The major consequences of this are that the Detect Key effect will detect the item as a key, and merchants will refuse to buy the item from you, even if they normally buy misc items.\n" ..
            "\n" ..
            "But there are many keys - slave keys, for example - that aren't technically flagged as keys because they don't open anything. This means that Detect Key won't detect them, and merchants will buy them.\n" ..
            "\n" ..
            "This option flags these items as keys, so they will behave like other keys in these respects. Now Detect Key will detect all keys, including slave keys.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "keyIsKey",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    categoryGeneral:createYesNoButton{
        label = "Change message when unlocking with key",
        description =
            "In vanilla Morrowind, when you unlock a door or container with the key, a messagebox appears that includes the name of the key, and this name is the actual object name, not the correct display name (for example, it will include the \"(K) \" prefix even if the mod is configured to not display prefixes).\n" ..
            "\n" ..
            "If this option is enabled, this messagebox will be modified to use the correct display name for the key (e.g. removing the prefix). If this option is disabled, the mod will not touch this messagebox.\n" ..
            "\n" ..
            "I recommend leaving this option enabled, unless you're using another mod that changes this messagebox or how the game checks for a key to unlock things.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "changeKeyMessage",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    categoryGeneral:createYesNoButton{
        label = "Enable logging",
        description =
            "Enables extensive logging to mwse.log. Don't enable this unless you're troubleshooting a problem or you want to see a very large (huge, enormous) number of lines in the log.\n" ..
            "\n" ..
            "Default: no",
        variable = mwse.mcm.createTableVariable{
            id = "logging",
            table = config,
        },
        restartRequired = true,
        defaultSetting = false,
    }

    local categoryPrefix = page:createCategory("Prefix Settings")

    categoryPrefix:createYesNoButton{
        label = "Enable prefixes",
        description =
            "By default (with this option enabled), this mod adds prefixes to certain types of objects to improve inventory sorting.\n" ..
            "\n" ..
            "If this option is turned off, prefixes will be entirely disabled. No prefixes will be added to object names, which means objects in the inventory will mostly sort in the vanilla manner. If you just want to hide prefixes so they won't display in the UI, then disable the \"display prefixes\" option instead.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "addPrefixes",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    categoryPrefix:createYesNoButton{
        label = "Display prefixes",
        description =
            "If this option is enabled, the prefixes added to item names by this mod will be visible in the UI (e.g. in object tooltips and various menus where item names are displayed).\n" ..
            "\n" ..
            "With this option disabled (the default), prefixes will still be added to item names to improve inventory sorting, but they'll be hidden in the UI so you won't see them - you'll only see items' base names (which can still be longer than 31 characters) in the UI.\n" ..
            "\n" ..
            "Default: no",
        variable = mwse.mcm.createTableVariable{
            id = "displayPrefixes",
            table = config,
        },
        defaultSetting = false,
    }

    categoryPrefix:createYesNoButton{
        label = "Add attack/AR to weapon/armor prefix",
        description =
            "This mod adds a prefix to weapon/armor names so they'll sort more conveniently in the inventory. For weapons, the prefix indicates the weapon type (e.g. short blade), and for armor it indicates the weight class (e.g. heavy) and armor slot (e.g. cuirass). Examples: \"(SB) Daedric Dagger\", \"(H-Cu) Daedric Cuirass\".\n" ..
            "\n" ..
            "If this option is enabled, the max attack (for weapons) or base armor rating (for armor) will be added to the prefix, so items will sort by attack/AR within each category. Examples: \"(SB-012) Daedric Dagger\", \"(H-Cu-080) Daedric Cuirass\".\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "prefixAttackAR",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    categoryPrefix:createYesNoButton{
        label = "Sort armor by slot first",
        description =
            "Armor prefixes indicate both the weight class and the armor slot of armor pieces. By default (with this option disabled), weight class comes first, then armor slot. (Example: \"(H-Cu-080) Daedric Cuirass\".) This means that all armor pieces of each weight class will sort together, and then, within each weight class, armor will sort by slot.\n" ..
            "\n" ..
            "If this option is enabled, this order will be reversed - armor slot will come first, then weight class. So the above example will be: \"(Cu-H-080) Daedric Cuirass\". This means that all armor pieces for each slot will sort together, and then, within each slot, armor will sort by weight class.\n" ..
            "\n" ..
            "Default: no",
        variable = mwse.mcm.createTableVariable{
            id = "armorBySlotFirst",
            table = config,
        },
        restartRequired = true,
        defaultSetting = false,
    }

    categoryPrefix:createYesNoButton{
        label = "Improved armor weight class sorting",
        description =
            "With this option disabled, weight class is indicated in armor prefixes by \"L\" for light, \"M\" for medium, and \"H\" for heavy. What these indicators mean is obvious when looking at the prefix, but, since armor sorts alphabetically by weight class indicator, it also results in armor sorting heavy first, then light, then medium - not exactly the ideal order.\n" ..
            "\n" ..
            "If this option is enabled, weight class will be indicated by \"1\" for light, \"2\" for medium, and \"3\" for heavy. This means armor will sort in a more rational order, but if you have the mod configured to display prefixes in the UI, the meaning of the weight class indicators will not be obvious. This will also cause armor to sort first in the enchanted items lists in the magic and magic select menus, even if the \"add object type indicator to prefixes\" option is disabled.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "armorAltWeight",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    categoryPrefix:createYesNoButton{
        label = "Add object type indicator to prefixes",
        description =
            "If this option is enabled, an element will be added to the beginning of prefixes for certain object types indicating the object type: \"W\" for weapons and ammunition, \"A\" for armor, and \"C\" for clothing.\n" ..
            "\n" ..
            "This will cause items of these types to sort together in the enchanted items lists in the magic and magic select menus - armor first, then clothing, then weapons (with scrolls at the end). This will not affect sorting elsewhere, such as in the inventory, container, and inventory select menus.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "objectTypePrefixes",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    categoryPrefix:createYesNoButton{
        label = "Sort lights in reverse order",
        description =
            "This mod adds prefixes to lights which cause them to sort by radius (an approximation of brightness) and time.\n" ..
            "\n" ..
            "If this option is enabled, lights will sort in order from brightest to least bright, and then from most to least time. This is handy with the mod Torch Hotkey, which equips the first light in your inventory. The downside of this is that, if the mod is configured to display prefixes, the numbers in light prefixes won't particularly make sense.\n" ..
            "\n" ..
            "If this option is disabled, lights will instead sort from least bright to brightest, and then from least to most time (and the numbers in the prefixes will be the actual radius and time values).\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "lightsInReverseOrder",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    for _, miscOption in ipairs(data.miscPrefixOptions) do
        local label = string.format("Enable prefixes for %s", miscOption)

        categoryPrefix:createYesNoButton{
            label = label,
            description =
                "By default (with this option enabled), this mod gives prefixes to " .. miscOption .. ", so they will sort together in the inventory. If this option is disabled, there will be no prefixes for " .. miscOption .. ". This allows you to disable prefixes for " .. miscOption .. " without disabling them for all misc items.\n" ..
                "\n" ..
                "Default: yes",
            variable = mwse.mcm.createTableVariable{
                id = miscOption,
                table = config.miscPrefixes,
            },
            restartRequired = true,
            defaultSetting = true,
        }
    end

    categoryPrefix:createYesNoButton{
        label = "Move gold to end of misc items",
        description =
            "Since gold is a misc item, and misc items sort alphabetically, gold sorts in the middle of the misc item list.\n" ..
            "\n" ..
            "If this option is enabled, the \"Gold\" item will have a \"~\" prefix so it will sort at the end of the misc item list. The various stacks of gold will also be given this prefix, for consistency. (Note that, like other prefixes, this prefix will not display in the UI if the \"display prefixes\" setting is disabled.)\n" ..
            "\n" ..
            "This setting will have no effect if the \"enable prefixes\" setting is turned off.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "goldAtEnd",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    local categoryBaseName = page:createCategory("Base Name Settings")

    categoryBaseName:createYesNoButton{
        label = "Enable base name changes",
        description =
            "By default (with this option enabled), this mod changes the base names (after prefix) of many objects for a number of reasons: for better sorting, to make more sense, to take advantage of the mod's ability to display long item names, or otherwise for convenience.\n" ..
            "\n" ..
            "If this option is turned off, base name changes will be entirely disabled, though prefixes will still be added to item names if applicable.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "changeBaseNames",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    categoryBaseName:createYesNoButton{
        label = "Use Roman numeral potion suffixes",
        description =
            "This mod renames potions so that they sort by effect, and then by quality. By default (with this option disabled), potion suffixes use BTB's naming scheme so that potions of the same effect will sort in quality order (Bargain, Cheap, Normal, Quality, Special). For example, \"Swift Swim, Quality\".\n" ..
            "\n" ..
            "If this option is enabled, Roman numerals will be used instead (I, II, III, IV, V). So, the above example becomes \"Swift Swim IV\".\n" ..
            "\n" ..
            "Default: no",
        variable = mwse.mcm.createTableVariable{
            id = "potionRomanNumerals",
            table = config,
        },
        restartRequired = true,
        defaultSetting = false,
    }

    categoryBaseName:createYesNoButton{
        label = "Alternate names for spoiled potions",
        description =
            "By default (with this option disabled), spoiled potions sort along with other potions of the same (positive) effect. (Example: \"Swift Swim, Spoiled\".)\n" ..
            "\n" ..
            "If this option is enabled, spoiled potions will instead sort with each other. So, the above becomes: \"Spoiled Swift Swim\".\n" ..
            "\n" ..
            "Default: no",
        variable = mwse.mcm.createTableVariable{
            id = "altSpoiledNames",
            table = config,
        },
        restartRequired = true,
        defaultSetting = false,
    }

    categoryBaseName:createYesNoButton{
        label = "Remove \"Scroll of\" from magic scrolls",
        description =
            "If this option is enabled, the text \"Scroll of\" will be removed from the beginning of magic scroll names. For example, \"Scroll of Ekash's Lock Splitter\" will become \"Ekash's Lock Splitter\".\n" ..
            "\n" ..
            "Note that, regardless of this setting, magic scrolls will sort together at the end of the book list as long as the \"enable prefixes\" option is on.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "removeScrollOf",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    categoryBaseName:createYesNoButton{
        label = "Book sorting ignores articles at beginning",
        description =
            "If this option is enabled, articles (\"The\", \"A\", \"An\") will be removed from the beginning of book object names. This will not affect display names, so you'll still see the article in the UI, but the book will sort as though the article weren't there. For example, \"The Armorer's Challenge\" will sort with the As, though you'll still see the article in the tooltip.\n" ..
            "\n" ..
            "This makes it easier to find a specific book in the inventory.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "removeArticlesFromBooks",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    categoryBaseName:createYesNoButton{
        label = "Change base names of keys",
        description =
            "By default (with this option enabled), this mod renames keys so they'll sort more conveniently in the inventory. The word \"key\" is removed, and word order is rearranged so that the most important word comes first.\n" ..
            "\n" ..
            "If this option is disabled, the base names of keys will not be changed. This allows you to disable base name changes for keys only, without disabling them for other types of misc items. Note that disabling this setting will not remove the prefixes from keys, so keys will still sort together in the inventory.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "keyBaseNames",
            table = config,
        },
        restartRequired = true,
        defaultSetting = true,
    }

    categoryBaseName:createYesNoButton{
        label = "Add \"Key, \" to beginning of key names",
        description =
            "By default, this mod removes the word \"Key\" from the names of almost all keys, because with the prefix it's not needed to make them sort together, and because it's usually obvious the item is a key.\n" ..
            "\n" ..
            "If this option is enabled, \"Key, \" will be added to the beginning of almost all key names.\n" ..
            "\n" ..
            "Default: no",
        variable = mwse.mcm.createTableVariable{
            id = "addKeyAtBeginning",
            table = config,
        },
        restartRequired = true,
        defaultSetting = false,
    }

    for _, tweakOption in ipairs(table.keys(data.nameTweaksOptions, true)) do
        local changeTo = data.nameTweaksOptions[tweakOption]
        local label = string.format("Names tweak: %s", changeTo)

        categoryBaseName:createYesNoButton{
            label = label,
            description =
                "If this option is enabled, all instances of \"" .. tweakOption .. "\" in item names will be changed to \"" .. changeTo .. "\".\n" ..
                "\n" ..
                "Default: yes",
            variable = mwse.mcm.createTableVariable{
                id = tweakOption,
                table = config.nameTweaks,
            },
            restartRequired = true,
            defaultSetting = true,
        }
    end

    for _, listType in ipairs(data.mcmListTypes) do
        local category = page:createCategory("Component " .. titles[listType] .. " Enable Settings")

        for _, objectType in ipairs(data.components) do
            if listType ~= "prefix"
            or objectType ~= tes3.objectType.ingredient then
                local label = string.format("Enable %s %s", data.componentNames[objectType], labels[listType])

                local descriptions = {
                    overall = string.format("Enables the %s component of the mod. If this option is disabled, %s will not be touched by the mod at all.", data.componentNames[objectType], data.componentNames[objectType]),
                    prefix = string.format("Enables prefixes for %s. If this option is disabled, %s will not have prefixes added (though base names might still be changed if applicable). This will disable prefixes entirely for the affected object type, which will affect item sorting.", data.componentNames[objectType], data.componentNames[objectType]),
                    baseName = string.format("Enables base name changes for %s. If this option is disabled, %s will not have their base names changed by this mod (though prefixes might still be added if applicable).", data.componentNames[objectType], data.componentNames[objectType]),
                }

                category:createYesNoButton{
                    label = label,
                    description =
                        descriptions[listType] .. "\n" ..
                        "\n" ..
                        "Default: yes",
                    variable = mwse.mcm.createTableVariable{
                        id = tostring(objectType),
                        table = config.componentEnable[listType],
                    },
                    restartRequired = true,
                    defaultSetting = true,
                }
            end
        end
    end
end

local function createBlacklistPage(template, listType)
    template:createExclusionsPage{
        label = titles[listType] .. " Blacklist",
        description = "This page can be used to blacklist specific items. " .. blacklistDescription[listType] .. " Any changes to the blacklist will require restarting Morrowind.",
        leftListLabel = "Blacklisted items",
        rightListLabel = "Items",
        variable = mwse.mcm.createTableVariable{
            id = listType,
            table = config.blacklists,
        },
        filters = {
            { callback = blacklist },
        },
    }
end

local template = mwse.mcm.createTemplate("Rational Names")
template:saveOnClose("RationalNames", config)

createMainPage(template)

for _, listType in ipairs(data.mcmListTypes) do
    createBlacklistPage(template, listType)
end

mwse.mcm.register(template)