local modInfo = require("RationalNames.modInfo")
local config = require("RationalNames.config")
local data = require("RationalNames.data")

-- Returns a list of the IDs of every object potentially affected by this mod, to populate the overall blacklist.
local function overallList()
    local list = {}

    for _, objectType in ipairs(data.components) do
        for object in tes3.iterateObjects(objectType) do
            local name = object.name

            if ( not name )
            or name == ""
            or name == "FOR SPELL CASTING" then
                goto continue
            end

            local id = object.id:lower()
            local newBaseName = data.baseNames[objectType][id]

            if objectType == tes3.objectType.ingredient
            or objectType == tes3.objectType.apparatus
            or objectType == tes3.objectType.lockpick
            or objectType == tes3.objectType.light
            or objectType == tes3.objectType.probe
            or objectType == tes3.objectType.repairItem then
                if not newBaseName then
                    goto continue
                end
            elseif objectType == tes3.objectType.alchemy then
                if ( not data.drinksList[id] )
                and ( not newBaseName ) then
                    goto continue
                end
            elseif objectType == tes3.objectType.book then
                if object.type ~= tes3.bookType.scroll
                and not newBaseName then
                    goto continue
                end
            elseif objectType == tes3.objectType.miscItem then
                if ( not object.isKey )
                and ( not object.isSoulGem )
                and ( not data.goldList[id] )
                and ( not data.soulgemList[id] )
                and ( not data.propylonList[id] )
                and ( not data.keyList[id] )
                and ( not newBaseName ) then
                    goto continue
                end
            end

            table.insert(list, id)

            ::continue::
        end
    end

    table.sort(list)
    return list
end

-- Returns a list of the IDs of every object with a new base name specified in data.lua, to populate the base name
-- blacklist.
local function baseNameList()
    return data.baseNameList
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
            "Potions: Sort by effect. Drinks sort at end.\n" ..
            "\n" ..
            "Ingredients: Minor name tweaks for a couple items.\n" ..
            "\n" ..
            "Books: Non-magic scrolls sort at beginning. Magic scrolls sort at end.\n" ..
            "\n" ..
            "Lights: Sort by light type (e.g. candles, lanterns).\n" ..
            "\n" ..
            "Misc items: Keys, soulgems and propylon indexes sort separately. Gold sorts at end.\n" ..
            "\n" ..
            "Apparatus/lockpicks/probes/repair items: Sort in quality order.\n" ..
            "\n" ..
            "Other changes to item names have also been made for more convenient inventory sorting. Additionally, item names can now be longer than 31 characters. See the readme for details.\n" ..
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

    categoryGeneral:createYesNoButton{
        label = "Only use two digits for attack/AR in prefix",
        description =
            "The max attack of most weapons and the base AR of most armor are two digits or less. But, in vanilla Morrowind (without mods changing item stats), there are a very few weapons with a max attack of 100+, and a very few armor pieces with a base AR of 100+.\n" ..
            "\n" ..
            "By default (with this option disabled), attack/AR will be displayed with three digits in the prefix. For example, \"(H-Cu-080) Daedric Cuirass\", \"(BW-1-003) Chitin Club\". This ensures that all items, including those with an attack/AR of 100+, will sort correctly in the inventory, but it uses more digits than needed in most cases.\n" ..
            "\n" ..
            "If this option is enabled, attack/AR will only be displayed with two digits in the prefix (unless attack/AR is actually 100+, in which case it will still use three digits). This cuts down on unneeded characters in the prefix in most cases, but it will result in items with attack/AR of 100+ sorting incorrectly in the inventory. For example, among other medium cuirasses, the Ebony Mail (\"(M-Cu-100) Ebony Mail\") will sort as though it had an AR of 10, not 100.\n" ..
            "\n" ..
            "Default: no",
        variable = mwse.mcm.createTableVariable{
            id = "shortPrefixAttackAR",
            table = config,
        },
        restartRequired = true,
        defaultSetting = false,
    }

    categoryGeneral:createYesNoButton{
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

    categoryGeneral:createYesNoButton{
        label = "Alternate names for spoiled potions",
        description =
            "This mod renames potions so that they sort by effect. By default (with this option disabled), spoiled potions sort along with other potions of the same (positive) effect. (Example: \"Swift Swim, Spoiled\".)\n" ..
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
        label = "Move gold to end of misc items",
        description =
            "Since gold is a misc item, and misc items sort alphabetically, gold sorts in the middle of the misc item list.\n" ..
            "\n" ..
            "If this option is enabled, the name of the \"Gold\" item will have a \"~\" in front so it will sort at the end of the misc item list. The various stacks of gold will also be renamed, for consistency.\n" ..
            "\n" ..
            "Default: yes",
        variable = mwse.mcm.createTableVariable{
            id = "goldAtEnd",
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

    local categoryComponent = page:createCategory("Component Enable Settings")

    for _, objectType in ipairs(data.components) do
        local label = string.format("Enable %s component", data.componentNames[objectType])

        categoryComponent:createYesNoButton{
            label = label,
            description =
                "Enables the " .. data.componentNames[objectType] .. " component of the mod. If this option is disabled, " .. data.componentNames[objectType] .. " will not be touched by the mod at all.\n" ..
                "\n" ..
                "Default: yes",
            variable = mwse.mcm.createTableVariable{
                id = tostring(objectType),
                table = config.componentEnable,
            },
            restartRequired = true,
            defaultSetting = true,
        }
    end

    local categoryBaseNames = page:createCategory("Base Name Changes Settings")

    categoryBaseNames:createInfo{
        text = "If you want to disable base name changes for an object type not listed in this section, just disable the relevant component above.",
    }

    for _, objectType in ipairs(data.baseNameDisableOptions) do
        local label = string.format("Enable %s base name changes", data.componentNames[objectType])

        categoryBaseNames:createYesNoButton{
            label = label,
            description =
                "Enables base name changes for " .. data.componentNames[objectType] .. ". If this option is disabled, " .. data.componentNames[objectType] .. " will not have their base names changed by this mod (though prefixes might still be added if the relevant component is enabled).\n" ..
                "\n" ..
                "Default: yes",
            variable = mwse.mcm.createTableVariable{
                id = tostring(objectType),
                table = config.baseNameEnable,
            },
            restartRequired = true,
            defaultSetting = true,
        }
    end
end

local function createBaseNamesBlacklistPage(template)
    template:createExclusionsPage{
        label = "Base Names Blacklist",
        description = "This page can be used to blacklist specific items. Blacklisted items will not have their base names changed by this mod (though they might still have a prefix added, depending on the item type). Any changes to the blacklist will require restarting Morrowind.",
        leftListLabel = "Blacklisted items",
        rightListLabel = "Items",
        variable = mwse.mcm.createTableVariable{
            id = "baseNameBlacklist",
            table = config,
        },
        filters = {
            { callback = baseNameList },
        },
    }
end

local function createOverallBlacklistPage(template)
    template:createExclusionsPage{
        label = "Overall Blacklist",
        description = "This page can be used to blacklist specific items. Blacklisted items will not be touched by this mod at all. Any changes to the blacklist will require restarting Morrowind.",
        leftListLabel = "Blacklisted items",
        rightListLabel = "Items",
        variable = mwse.mcm.createTableVariable{
            id = "overallBlacklist",
            table = config,
        },
        filters = {
            { callback = overallList },
        },
    }
end

local template = mwse.mcm.createTemplate("Rational Names")
template:saveOnClose("RationalNames", config)

createMainPage(template)
createBaseNamesBlacklistPage(template)
createOverallBlacklistPage(template)

mwse.mcm.register(template)