local common = require("BuildYourOwnRebalance.common")
local config = require("BuildYourOwnRebalance.config")
local util = require("BuildYourOwnRebalance.util")
local mcmConfig = config.loadMcmConfig()

local function createWeaponRestoreDefaultsPage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Restore Defaults" })
    
    page:createInfo({ text = "WARNING: These actions cannot be undone." })
    page:createInfo({ text = "Any changes you've made will be lost." })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createButton({
        buttonText = "Restore ALL Weapon Defaults",
        description = "Restores the default values of ALL settings in the \"BYO Rebalance 4: Weapons\" section.",
        callback = function()
            util.deepMerge(mcmConfig.weapon, defaultMcmConfig.weapon)
        end,
        restartRequired = true,
    })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createButton({
        buttonText = "Restore Weapon \"Subtype\" Defaults",
        description = "Restores the default values of all settings on the \"Subtype\", \"Subtype Count\", \"Subtype Flavor\", \"Detect Subtype\", and \"Detect Tier 2\" tabs.",
        callback = function()
            util.deepMerge(mcmConfig.weapon.subtypeCount, defaultMcmConfig.weapon.subtypeCount)
            util.deepMerge(mcmConfig.weapon.subtype, defaultMcmConfig.weapon.subtype)
        end,
        restartRequired = true,
    })
    
    page:createButton({
        buttonText = "Restore Weapon \"Weight Class\" Defaults",
        description =
            "Restores the default values of all settings on the \"Weight Class\" and \"Detect WC\" tabs."..
            " Also restores the default value of the \"Default Weight Class\" setting on the \"Home\" tab.",
        callback = function()
            mcmConfig.weapon.defaultWeightClass = defaultMcmConfig.weapon.defaultWeightClass
            util.deepMerge(mcmConfig.weapon.weightClass, defaultMcmConfig.weapon.weightClass)
            util.deepMerge(mcmConfig.weapon.detectWeightClass, defaultMcmConfig.weapon.detectWeightClass)
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })
    
    page:createButton({
        buttonText = "Restore Weapon \"Tier\" Defaults",
        description =
            "Restores the default values of all settings on the \"Tier\", \"Detect Tier 1\", and \"Detect Tier 2\" tabs."..
            " Also restores the default value of the \"Tier Count\" setting on the \"Home\" tab.",
        callback = function()
            
            mcmConfig.weapon.tierCount = defaultMcmConfig.weapon.tierCount
            util.deepMerge(mcmConfig.weapon.tier, defaultMcmConfig.weapon.tier)
            util.deepMerge(mcmConfig.weapon.detectTier, defaultMcmConfig.weapon.detectTier)
            
            for weaponType, subtypes in pairs(mcmConfig.weapon.subtype) do
                for subtype, subtypeTable in pairs(subtypes) do
                    
                    subtypeTable.maxDamageTierZero = defaultMcmConfig.weapon.subtype[weaponType][subtype].maxDamageTierZero
                    util.deepMerge(subtypeTable.maxDamage, defaultMcmConfig.weapon.subtype[weaponType][subtype].maxDamage)
                    
                end
            end
            
        end,
        restartRequired = true,
    })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createButton({
        buttonText = "Restore \"Weapon Resist\" Defaults",
        description = "Restores the default values of the \"Silver Weapon\" and \"Weapon Resist\" settings on the \"Home\" tab.",
        callback = function()
            mcmConfig.weapon.fixIsSilverFlag = defaultMcmConfig.weapon.fixIsSilverFlag
            util.deepMerge(mcmConfig.weapon.ignoresNormalWeaponResistance, defaultMcmConfig.weapon.ignoresNormalWeaponResistance)
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })
    
    page:createButton({
        buttonText = "Restore \"Bound Weapon\" Defaults",
        description = "Restores the default values of the \"Bound Weapon\" settings on the \"Home\" tab.",
        callback = function()
            util.deepMerge(mcmConfig.weapon.boundItem, defaultMcmConfig.weapon.boundItem)
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })
    
    page:createButton({
        buttonText = "Restore \"Enchanted Weapon\" Defaults",
        description = "Restores the default values of the \"Enchanted Weapon\" settings on the \"Home\" tab.",
        callback = function()
            util.deepMerge(mcmConfig.weapon.enchantedItem, defaultMcmConfig.weapon.enchantedItem)
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })
    
end

local function createWeaponDetectTierByDamagePage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Detect Tier 2" })
    
    page.sidebar:createInfo({ text =
        "If a weapon's tier was not determined by the \"Detect Tier 1\" tab, its tier is determined by the following process instead:"..
        "\n\nSort the Max Damage values in the weapon's subtype from lowest to highest."..
        " Compare the weapon to each Max Damage value, in ascending order."..
        " If the weapon's pre-rebalance Damage is less than or equal to the Max Damage value, assign it to the corresponding tier."..
        "\n\nIf the weapon was not assigned a tier by this process, it cannot be rebalanced, and you will see an error message when you load a save."..
        " To avoid this, make sure each subtype has one slider set to its maximum value."..
        "\n\nSPECIAL: Weapons assigned to tier zero (T0) will not be rebalanced."..
        " This is useful for items like broken bottles and farming tools that are extremely weak compared to other weapons."..
        "\n\nREQUIRES RESTART: The game must be restarted before any changes to tier zero sliders will come into effect."
    })
    
    for weaponType, _ in util.sortedPairs(mcmConfig.weapon.subtype, common.sortFunction_ByWeaponTypeConfigKey) do
        
        local weaponTypeDisplayName = common.getWeaponTypeConfigKeyDisplayName(weaponType)
        
        page:createInfo({ text = "------------------------------" })
        page:createInfo({ text = weaponTypeDisplayName })
        
        for subtype, _ in util.sortedPairs(mcmConfig.weapon.subtype[weaponType]) do
            
            local subtypeTable = mcmConfig.weapon.subtype[weaponType][subtype]
            local subtypeDisplayName = subtypeTable.displayName
            
            if subtypeDisplayName == "" then
                subtypeDisplayName =  "[Subtype " .. subtype .. "]"
            end
            
            page:createInfo({ text = "------------------------------" })
            
            page:createSlider({
                label = string.format("T0 %s Max Damage", subtypeDisplayName),
                variable = mwse.mcm.createTableVariable({
                    table = subtypeTable,
                    id = "maxDamageTierZero",
                }),
                min = 0,
                max = 200,
                step = 1,
                jump = 10,
                decimalPlaces = 0,
            })
            
            for tier, _ in util.sortedPairs(mcmConfig.weapon.subtype[weaponType][subtype].maxDamage) do
                
                page:createSlider({
                    label = string.format("T%d %s Max Damage", tier, subtypeDisplayName),
                    variable = mwse.mcm.createTableVariable({
                        table = subtypeTable.maxDamage,
                        id = tier,
                    }),
                    min = 0,
                    max = 200,
                    step = 1,
                    jump = 10,
                    decimalPlaces = 0,
                })
                
            end
            
        end
        
    end
    
end

local function createWeaponDetectTierBySearchTermPage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Detect Tier 1", noScroll = true })
    
    page.sidebar:createInfo({ text =
        "Tier:SearchTerm"..
        "\n\nPress Enter to save changes."..
        "\nPress Shift+Enter to add a new line."..
        "\nSearch term is NOT case-sensitive."..
        "\nWhitespace characters matter!"..
        "\n\nEach line of this paragraph field contains a tier and a search term, separated by a colon."..
        " If a weapon's name, mesh, icon, or ID contains the search term, it is assigned the corresponding tier."..
        " If multiple search terms match, ties are broken by search term length (longer wins), then by alphabetical order (earlier wins)."..
        "\n\nIf none of the search terms match, the weapon's tier is determined by the \"Detect Tier 2\" tab."..
        "\n\nSPECIAL: If you start a search term with an asterisk (*), the asterisk will be ignored and the remainder of the search term will be treated as a Lua pattern."..
        "\n\nSPECIAL: Weapons assigned to tier zero will not be rebalanced."..
        " This is an alternative to the \"Excluded Items\" tab for those who prefer it."..
        "\n\nREQUIRES RESTART: The game must be restarted before any additions, removals, or changes to tier zero search terms will come into effect."
    })
    
    page:createParagraphField({
        label = "\"Tier\" Search Terms",
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.weapon.detectTier,
            id = "searchTerms",
        }),
        sNewValue = "Saved changes.",
    })
    
end

local function createWeaponDetectWeightClassBySearchTermPage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Detect WC", noScroll = true })
    
    page.sidebar:createInfo({ text =
        "WeightClass:SearchTerm"..
        "\n\n  L = Light"..
        "\n  M = Medium"..
        "\n  H = Heavy"..
        "\n\nPress Enter to save changes."..
        "\nPress Shift+Enter to add a new line."..
        "\nSearch term is NOT case-sensitive."..
        "\nWhitespace characters matter!"..
        "\n\nEach line of this paragraph field contains a weight class and a search term, separated by a colon."..
        " If a weapon's name, mesh, icon, or ID contains the search term, it is assigned the corresponding weight class."..
        " If multiple search terms match, ties are broken by search term length (longer wins), then by alphabetical order (earlier wins)."..
        "\n\nIf none of the search terms match, the weapon uses the \"Default Weight Class\" specified on the \"Home\" tab."..
        "\n\nSPECIAL: If you start a search term with an asterisk (*), the asterisk will be ignored and the remainder of the search term will be treated as a Lua pattern."
    })
    
    page:createParagraphField({
        label = "\"Weight Class\" Search Terms",
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.weapon.detectWeightClass,
            id = "searchTerms",
        }),
        sNewValue = "Saved changes.",
    })
    
end

local function createWeaponDetectSubtypePage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Detect Subtype" })
    
    page.sidebar:createInfo({ text =
        "Each weapon's subtype is detected by search term, then by speed, then by reach."..
        " Each weapon only cares about the settings under it's corresponding weapon type heading (e.g. 1H Short Blade)."..
        " If a weapon type only has one subtype, the weapon type will not appear on this page."..
        "\n\nThe \"Search Terms\" textbox contains zero or more search terms, separated by forward slashes."..
        " If a weapon's name, mesh, icon, or ID contains one of these search terms, it is assigned the corresponding subtype."..
        " If multiple search terms match, ties are broken by search term length (longer wins), then by alphabetical order (earlier wins)."..
        " Search terms are NOT case-sensitive."..
        " Whitespace characters matter!"..
        "\n\n\"Max Speed\" and \"Max Reach\" both use the following process:"..
        " Sort the Max Stat values from lowest to highest."..
        " Compare the weapon to each Max Stat value, in ascending order."..
        " If the weapon's pre-rebalance Stat is less than or equal to the Max Stat value, assign it to the corresponding subtype."..
        "\n\nIf the weapon was not assigned a subtype by this process, it cannot be rebalanced, and you will see an error message when you load a save."..
        " To avoid this, make sure each weapon type has one slider (either Max Speed or Max Reach) set to its maximum value."..
        "\n\nSPECIAL: If you start a search term with an asterisk (*), the asterisk will be ignored and the remainder of the search term will be treated as a Lua pattern."
    })
    
    for weaponType, _ in util.sortedPairs(mcmConfig.weapon.subtype, common.sortFunction_ByWeaponTypeConfigKey) do
        
        if util.count(mcmConfig.weapon.subtype[weaponType]) > 1 then
            
            local weaponTypeDisplayName = common.getWeaponTypeConfigKeyDisplayName(weaponType)
            local weaponTypeIsRanged = common.getWeaponTypeConfigKeyIsRanged(weaponType)
            
            page:createInfo({ text = "------------------------------" })
            page:createInfo({ text = weaponTypeDisplayName })
            
            for subtype, _ in util.sortedPairs(mcmConfig.weapon.subtype[weaponType]) do
                
                local subtypeTable = mcmConfig.weapon.subtype[weaponType][subtype]
                local subtypeDisplayName = subtypeTable.displayName
                
                if subtypeDisplayName == "" then
                    subtypeDisplayName =  "[Subtype " .. subtype .. "]"
                end
                
                page:createInfo({ text = "------------------------------" })
                
                page:createTextField({
                    label = string.format("%s Search Terms", subtypeDisplayName),
                    variable = mwse.mcm.createTableVariable({
                        table = subtypeTable,
                        id = "searchTerms",
                    }),
                })
                
                page:createSlider({
                    label = string.format("%s Max Speed", subtypeDisplayName),
                    variable = mwse.mcm.createTableVariable({
                        table = subtypeTable,
                        id = "maxSpeed",
                    }),
                    min = 0,
                    max = 5,
                    step = 0.01,
                    jump = 0.1,
                    decimalPlaces = 2,
                })
                
                if not weaponTypeIsRanged then
                    
                    page:createSlider({
                        label = string.format("%s Max Reach", subtypeDisplayName),
                        variable = mwse.mcm.createTableVariable({
                            table = subtypeTable,
                            id = "maxReach",
                        }),
                        min = 0,
                        max = 5,
                        step = 0.01,
                        jump = 0.1,
                        decimalPlaces = 2,
                    })
                    
                end
                
            end
            
        end
        
    end
    
end

local function createWeaponSubtypeFlavorPage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Subtype Flavor" })
    
    page.sidebar:createInfo({ text =
        "Display Name = The name of this subtype. Only used in these mod configuration menus."..
        "\n\nMin Damage = Attack type max damage is multiplied by this value to determine the attack type's min damage."..
        "\n\nChop, Slash, and Thrust = WeaponDamage is multiplied by this value to determine the attack type's max damage."..
        "\n\nBest Attack = Used to tiebreak attack types."..
        " Ensures that the \"Always Use Best Attack\" toggle in the \"Options\" menu will always select this attack type."..
        " Make sure the attack type selected in this dropdown is also the highest (or is tied for the highest) Chop, Slash, or Thrust value."..
        "\n\nREQUIRES RESTART: The game must be restarted before any changes to Display Names will come into effect."
    })
    
    for weaponType, _ in util.sortedPairs(mcmConfig.weapon.subtype, common.sortFunction_ByWeaponTypeConfigKey) do
        
        local weaponTypeDisplayName = common.getWeaponTypeConfigKeyDisplayName(weaponType)
        local weaponTypeIsRanged = common.getWeaponTypeConfigKeyIsRanged(weaponType)
        
        page:createInfo({ text = "------------------------------" })
        page:createInfo({ text = weaponTypeDisplayName })
        
        for subtype, _ in util.sortedPairs(mcmConfig.weapon.subtype[weaponType]) do
            
            local subtypeTable = mcmConfig.weapon.subtype[weaponType][subtype]
            local subtypeDisplayName = subtypeTable.displayName
            
            if subtypeDisplayName == "" then
                subtypeDisplayName =  "[Subtype " .. subtype .. "]"
            end
            
            page:createInfo({ text = "------------------------------" })
            
            page:createTextField({
                label = string.format("%s Display Name", subtypeDisplayName),
                variable = mwse.mcm.createTableVariable({
                    table = subtypeTable,
                    id = "displayName",
                }),
            })
            
            page:createSlider({
                label = string.format("%s Min Damage", subtypeDisplayName),
                variable = mwse.mcm.createTableVariable({
                    table = subtypeTable,
                    id = "minDamage",
                }),
                min = 0,
                max = 1,
                step = 0.01,
                jump = 0.1,
                decimalPlaces = 2,
            })
            
            if not weaponTypeIsRanged then
                
                page:createSlider({
                    label = string.format("%s Chop", subtypeDisplayName),
                    variable = mwse.mcm.createTableVariable({
                        table = subtypeTable,
                        id = "chop",
                    }),
                    min = 0,
                    max = 1,
                    step = 0.01,
                    jump = 0.1,
                    decimalPlaces = 2,
                })
                
                page:createSlider({
                    label = string.format("%s Slash", subtypeDisplayName),
                    variable = mwse.mcm.createTableVariable({
                        table = subtypeTable,
                        id = "slash",
                    }),
                    min = 0,
                    max = 1,
                    step = 0.01,
                    jump = 0.1,
                    decimalPlaces = 2,
                })
                
                page:createSlider({
                    label = string.format("%s Thrust", subtypeDisplayName),
                    variable = mwse.mcm.createTableVariable({
                        table = subtypeTable,
                        id = "thrust",
                    }),
                    min = 0,
                    max = 1,
                    step = 0.01,
                    jump = 0.1,
                    decimalPlaces = 2,
                })
                
                page:createDropdown{
                    label = string.format("%s Best Attack", subtypeDisplayName),
                    variable = mwse.mcm.createTableVariable({
                        table = subtypeTable,
                        id = "bestAttack",
                    }),
                    options = {
                        { label = "Chop", value = "chop" },
                        { label = "Slash", value = "slash" },
                        { label = "Thrust", value = "thrust" },
                    },
                }
                
            end
            
        end
        
    end
    
end

local function createWeaponSubtypeCountPage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Subtype Count" })
    
    page.sidebar:createInfo({ text =
        "These sliders determine the number of customizable subtypes within each weapon type."..
        "\n\nREQUIRES RESTART: The game must be restarted before any changes to these sliders will come into effect."
    })
    
    for weaponType, _ in util.sortedPairs(mcmConfig.weapon.subtypeCount, common.sortFunction_ByWeaponTypeConfigKey) do
        
        page:createSlider({
            label = common.getWeaponTypeConfigKeyDisplayName(weaponType),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.weapon.subtypeCount,
                id = weaponType,
            }),
            min = 1,
            max = 10,
            step = 1,
            jump = 1,
            decimalPlaces = 0,
        })
        
    end
    
end

local function createWeaponTierPage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Tier" })
    
    page.sidebar:createInfo({ text =
        "WeaponDamage ="..
        "\n  SubtypeDamage (0 to 100) *"..
        "\n  WeightClassDamage (0.0 to 10.0) *"..
        "\n  TierDamage (0.00 to 2.00)"..
        "\n\nWeaponWeight ="..
        "\n  SubtypeWeight (0.0 to 50.0) *"..
        "\n  WeightClassWeight (0.0 to 10.0) *"..
        "\n  TierWeight (0.0 to 10.0)"..
        "\n\nWeaponEnchant ="..
        "\n  SubtypeEnchant (0.0 to 50.0) *"..
        "\n  WeightClassEnchant (0.0 to 10.0) *"..
        "\n  TierEnchant (0.0 to 10.0)"..
        "\n\nWeaponHealth ="..
        "\n  SubtypeHealth (0 to 5000) *"..
        "\n  WeightClassHealth (0.0 to 10.0) *"..
        "\n  TierHealth (0.0 to 10.0)"..
        "\n\nWeaponValue ="..
        "\n  SubtypeValue (0.0 to 100.0) *"..
        "\n  WeightClassValue (0.0 to 10.0) *"..
        "\n  TierValue (0 to 10000)"
    })
    
    for tier, _ in util.sortedPairs(mcmConfig.weapon.tier.damage) do
        
        page:createSlider({
            label = string.format("T%d Damage", tier),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.weapon.tier.damage,
                id = tier,
            }),
            min = 0,
            max = 2,
            step = 0.01,
            jump = 0.1,
            decimalPlaces = 2,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for tier, _ in util.sortedPairs(mcmConfig.weapon.tier.weight) do
        
        page:createSlider({
            label = string.format("T%s Weight", tier),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.weapon.tier.weight,
                id = tier,
            }),
            min = 0,
            max = 10,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for tier, _ in util.sortedPairs(mcmConfig.weapon.tier.enchant) do
        
        page:createSlider({
            label = string.format("T%s Enchant", tier),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.weapon.tier.enchant,
                id = tier,
            }),
            min = 0,
            max = 10,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for tier, _ in util.sortedPairs(mcmConfig.weapon.tier.health) do
        
        page:createSlider({
            label = string.format("T%s Health", tier),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.weapon.tier.health,
                id = tier,
            }),
            min = 0,
            max = 10,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for tier, _ in util.sortedPairs(mcmConfig.weapon.tier.value) do
        
        page:createSlider({
            label = string.format("T%s Value", tier),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.weapon.tier.value,
                id = tier,
            }),
            min = 0,
            max = 10000,
            step = 1,
            jump = 100,
            decimalPlaces = 0,
        })
        
    end
    
end

local function createWeaponWeightClassPage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Weight Class" })
    
    page.sidebar:createInfo({ text =
        "WeaponDamage ="..
        "\n  SubtypeDamage (0 to 100) *"..
        "\n  WeightClassDamage (0.0 to 10.0) *"..
        "\n  TierDamage (0.00 to 2.00)"..
        "\n\nWeaponWeight ="..
        "\n  SubtypeWeight (0.0 to 50.0) *"..
        "\n  WeightClassWeight (0.0 to 10.0) *"..
        "\n  TierWeight (0.0 to 10.0)"..
        "\n\nWeaponEnchant ="..
        "\n  SubtypeEnchant (0.0 to 50.0) *"..
        "\n  WeightClassEnchant (0.0 to 10.0) *"..
        "\n  TierEnchant (0.0 to 10.0)"..
        "\n\nWeaponHealth ="..
        "\n  SubtypeHealth (0 to 5000) *"..
        "\n  WeightClassHealth (0.0 to 10.0) *"..
        "\n  TierHealth (0.0 to 10.0)"..
        "\n\nWeaponValue ="..
        "\n  SubtypeValue (0.0 to 100.0) *"..
        "\n  WeightClassValue (0.0 to 10.0) *"..
        "\n  TierValue (0 to 10000)"
    })
    
    for weightClass, _ in util.sortedPairs(mcmConfig.weapon.weightClass.damage, common.sortFunction_ByWeaponWeightClassConfigKey) do
        
        page:createSlider({
            label = string.format("%s Damage", util.capitalizeFirstLetter(weightClass)),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.weapon.weightClass.damage,
                id = weightClass,
            }),
            min = 0,
            max = 10,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for weightClass, _ in util.sortedPairs(mcmConfig.weapon.weightClass.weight, common.sortFunction_ByWeaponWeightClassConfigKey) do
        
        page:createSlider({
            label = string.format("%s Weight", util.capitalizeFirstLetter(weightClass)),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.weapon.weightClass.weight,
                id = weightClass,
            }),
            min = 0,
            max = 10,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for weightClass, _ in util.sortedPairs(mcmConfig.weapon.weightClass.enchant, common.sortFunction_ByWeaponWeightClassConfigKey) do
        
        page:createSlider({
            label = string.format("%s Enchant", util.capitalizeFirstLetter(weightClass)),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.weapon.weightClass.enchant,
                id = weightClass,
            }),
            min = 0,
            max = 10,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for weightClass, _ in util.sortedPairs(mcmConfig.weapon.weightClass.health, common.sortFunction_ByWeaponWeightClassConfigKey) do
        
        page:createSlider({
            label = string.format("%s Health", util.capitalizeFirstLetter(weightClass)),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.weapon.weightClass.health,
                id = weightClass,
            }),
            min = 0,
            max = 10,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for weightClass, _ in util.sortedPairs(mcmConfig.weapon.weightClass.value, common.sortFunction_ByWeaponWeightClassConfigKey) do
        
        page:createSlider({
            label = string.format("%s Value", util.capitalizeFirstLetter(weightClass)),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.weapon.weightClass.value,
                id = weightClass,
            }),
            min = 0,
            max = 10,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
end

local function createWeaponSubtypePage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Subtype" })
    
    page.sidebar:createInfo({ text =
        "WeaponDamage ="..
        "\n  SubtypeDamage (0 to 100) *"..
        "\n  WeightClassDamage (0.0 to 10.0) *"..
        "\n  TierDamage (0.00 to 2.00)"..
        "\n\nWeaponWeight ="..
        "\n  SubtypeWeight (0.0 to 50.0) *"..
        "\n  WeightClassWeight (0.0 to 10.0) *"..
        "\n  TierWeight (0.0 to 10.0)"..
        "\n\nWeaponEnchant ="..
        "\n  SubtypeEnchant (0.0 to 50.0) *"..
        "\n  WeightClassEnchant (0.0 to 10.0) *"..
        "\n  TierEnchant (0.0 to 10.0)"..
        "\n\nWeaponHealth ="..
        "\n  SubtypeHealth (0 to 5000) *"..
        "\n  WeightClassHealth (0.0 to 10.0) *"..
        "\n  TierHealth (0.0 to 10.0)"..
        "\n\nWeaponValue ="..
        "\n  SubtypeValue (0.0 to 100.0) *"..
        "\n  WeightClassValue (0.0 to 10.0) *"..
        "\n  TierValue (0 to 10000)"
    })
    
    -- Spear, Long Spear, Halberd, and Staff have an interesting thrust animation.
    -- The thrust animation is 1.25x faster than most other animations when not charged,
    -- but the same speed as other animations when fully charged.
    -- Full-charged shots per minute: 40/m Crossbow, 30/m Bow, 60/m Thrown
    -- Thrown weapons deal double the listed damage.
    
    for weaponType, _ in util.sortedPairs(mcmConfig.weapon.subtype, common.sortFunction_ByWeaponTypeConfigKey) do
        
        local weaponTypeDisplayName = common.getWeaponTypeConfigKeyDisplayName(weaponType)
        local weaponTypeIsRanged = common.getWeaponTypeConfigKeyIsRanged(weaponType)
        local weaponTypeIsProjectile = common.getWeaponTypeConfigKeyIsProjectile(weaponType)
        
        page:createInfo({ text = "------------------------------" })
        page:createInfo({ text = weaponTypeDisplayName })
        
        for subtype, _ in util.sortedPairs(mcmConfig.weapon.subtype[weaponType]) do
            
            local subtypeTable = mcmConfig.weapon.subtype[weaponType][subtype]
            local subtypeDisplayName = subtypeTable.displayName
            
            if subtypeDisplayName == "" then
                subtypeDisplayName =  "[Subtype " .. subtype .. "]"
            end
            
            page:createInfo({ text = "------------------------------" })
            
            page:createSlider({
                label = string.format("%s Damage", subtypeDisplayName),
                variable = mwse.mcm.createTableVariable({
                    table = subtypeTable,
                    id = "damage",
                }),
                min = 0,
                max = 100,
                step = 1,
                jump = 10,
                decimalPlaces = 0,
            })
            
            if not weaponTypeIsRanged then
                
                page:createSlider({
                    label = string.format("%s Speed", subtypeDisplayName),
                    variable = mwse.mcm.createTableVariable({
                        table = subtypeTable,
                        id = "speed",
                    }),
                    min = 0,
                    max = 5,
                    step = 0.01,
                    jump = 0.1,
                    decimalPlaces = 2,
                })
                
                page:createSlider({
                    label = string.format("%s Reach", subtypeDisplayName),
                    variable = mwse.mcm.createTableVariable({
                        table = subtypeTable,
                        id = "reach",
                    }),
                    min = 0,
                    max = 5,
                    step = 0.01,
                    jump = 0.1,
                    decimalPlaces = 2,
                })
                
            end
            
            page:createSlider({
                label = string.format("%s Weight", subtypeDisplayName),
                variable = mwse.mcm.createTableVariable({
                    table = subtypeTable,
                    id = "weight",
                }),
                min = 0,
                max = 50,
                step = 0.1,
                jump = 1,
                decimalPlaces = 1,
            })
            
            page:createSlider({
                label = string.format("%s Enchant", subtypeDisplayName),
                variable = mwse.mcm.createTableVariable({
                    table = subtypeTable,
                    id = "enchant",
                }),
                min = 0,
                max = 50,
                step = 0.1,
                jump = 1,
                decimalPlaces = 1,
            })
            
            if not weaponTypeIsProjectile then
                
                page:createSlider({
                    label = string.format("%s Health", subtypeDisplayName),
                    variable = mwse.mcm.createTableVariable({
                        table = subtypeTable,
                        id = "health",
                    }),
                    min = 0,
                    max = 5000,
                    step = 1,
                    jump = 100,
                    decimalPlaces = 0,
                })
                
            end
            
            page:createSlider({
                label = string.format("%s Value", subtypeDisplayName),
                variable = mwse.mcm.createTableVariable({
                    table = subtypeTable,
                    id = "value",
                }),
                min = 0,
                max = 100,
                step = 0.1,
                jump = 1,
                decimalPlaces = 1,
            })
            
        end
        
    end
    
end

local function createWeaponHomePage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Home" })
    
    page:createYesNoButton({
        label = "Weapon Rebalance Enabled",
        description =
            "Yes = Updates the stats of every weapon in the game (including ammunition) according to the settings in the \"BYO Rebalance 4: Weapons\" section."..
            " Any changes to these settings will come into effect when you load a save."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.weapon.rebalanceEnabled),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.weapon,
            id = "rebalanceEnabled",
        }),
        restartRequired = true,
    })
    
    page:createDropdown{
        label = "Default Weight Class:",
        description =
            "When a weapon's weight class cannot be determined by the search terms on the \"Detect WC\" tab, it defaults to this weight class."..
            "\n\nDefault Value: " .. util.capitalizeFirstLetter(common.getWeaponWeightClassSearchValueConfigKey(defaultMcmConfig.weapon.defaultWeightClass)),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.weapon,
            id = "defaultWeightClass",
        }),
        options = {
            { label = "Light", value = "L" },
            { label = "Medium", value = "M" },
            { label = "Heavy", value = "H" },
        },
    }
    
    page:createSlider({
        label = "Tier Count (Requires Restart)",
        description =
            "The number of customizable weapon tiers."..
            "\n\nDefault Value: " .. defaultMcmConfig.weapon.tierCount,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.weapon,
            id = "tierCount",
        }),
        min = 2,
        max = 20,
        step = 1,
        jump = 1,
        decimalPlaces = 0,
    })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createYesNoButton({
        label = "Fix \"Silver Weapon\" Flags",
        description =
            "Yes = Marks weapons as silver if they contain the word \"Silver\" in their name, mesh, icon, or ID."..
            " This will never unmark weapons as silver."..
            " I highly recommend you leave this set to \"Yes\" if you do not have the Bloodmoon.esm enabled."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.weapon.ignoresNormalWeaponResistance.fixIsSilverFlag),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.weapon,
            id = "fixIsSilverFlag",
        }),
    })
    
    page:createYesNoButton({
        label = "Ignore Weapon Resist - Include Silver",
        description =
            "Yes = Silver weapons bypass the \"Resist Normal Weapons\" magic effect."..
            " This is how silver weapons work in vanilla Morrowind."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.weapon.ignoresNormalWeaponResistance.includeSilver),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.weapon.ignoresNormalWeaponResistance,
            id = "includeSilver",
        }),
    })
    
    page:createYesNoButton({
        label = "Ignore Weapon Resist - Include Enchanted",
        description =
            "Yes = Enchanted weapons bypass the \"Resist Normal Weapons\" magic effect."..
            " This is how enchanted weapons work in vanilla Morrowind."..
            "\n\nNo = Enchanted weapons can have their non-magical damage reduced by the \"Resist Normal Weapons\" magic effect."..
            " The \"on Touch\" and \"on Target\" effects of weapon enchantments affect the target as they normally would."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.weapon.ignoresNormalWeaponResistance.includeEnchanted),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.weapon.ignoresNormalWeaponResistance,
            id = "includeEnchanted",
        }),
    })
    
    page:createSlider({
        label = "Ignore Weapon Resist - Min Tier",
        description =
            "Weapons of this tier and above bypass the \"Resist Normal Weapons\" magic effect.",
            "\n\nDefault Value: " .. defaultMcmConfig.weapon.ignoresNormalWeaponResistance.minTier,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.weapon.ignoresNormalWeaponResistance,
            id = "minTier",
        }),
        min = 1,
        max = mcmConfig.weapon.tierCount,
        step = 1,
        jump = 1,
        decimalPlaces = 0,
    })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createDropdown{
        label = "Bound Weapon - Weight Class:",
        description =
            "The weight class of bound weapons."..
            "\n\nDefault Value: " .. util.capitalizeFirstLetter(common.getWeaponWeightClassSearchValueConfigKey(defaultMcmConfig.weapon.boundItem.weightClass)),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.weapon.boundItem,
            id = "weightClass",
        }),
        options = {
            { label = "Light", value = "L" },
            { label = "Medium", value = "M" },
            { label = "Heavy", value = "H" },
        },
    }
    
    page:createSlider({
        label = "Bound Weapon - Tier",
        description =
            "The tier of bound weapons."..
            "\n\nDefault Value: " .. defaultMcmConfig.weapon.boundItem.tier,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.weapon.boundItem,
            id = "tier",
        }),
        min = 1,
        max = mcmConfig.weapon.tierCount,
        step = 1,
        jump = 1,
        decimalPlaces = 0,
    })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createYesNoButton({
        label = "Enchanted Weapon - Recalculate Value",
        description =
            "Yes = This mod will recalculate the value of pre-enchanted weapons from scratch using the \"Value Base\", \"Value Multiplier\", \"Value Per Max Charge\", and \"Value Per Effect Cost\" settings."..
            "\n\nNo = This mod will scale the vanilla value of pre-enchanted weapons using the \"Value Scale\" setting."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.weapon.enchantedItem.recalculateValue),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.weapon.enchantedItem,
            id = "recalculateValue",
        }),
    })
    
    page:createSlider({
        label = "Enchanted Weapon - Value Base",
        description =
            "When \"Recalculate Value\" is \"Yes\":"..
            "\n\nEnchantedValue ="..
            "\n  ValueBase +"..
            "\n  UnenchantedValue * ValueMultiplier +"..
            "\n  MaxCharge * ValuePerMaxCharge +"..
            "\n  EffectCost * ValuePerEffectCost"..
            "\n\nMaxCharge is only non-zero for \"Cast When Strikes\" and \"Cast When Used\" enchantments."..
            " EffectCost is only non-zero for \"Constant Effect\" enchantments."..
            "\n\nDefault Value: " .. defaultMcmConfig.weapon.enchantedItem.valueBase,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.weapon.enchantedItem,
            id = "valueBase",
        }),
        min = 0,
        max = 1000,
        step = 1,
        jump = 100,
        decimalPlaces = 0,
    })
    
    page:createSlider({
        label = "Enchanted Weapon - Value Multiplier",
        description =
            "When \"Recalculate Value\" is \"Yes\":"..
            "\n\nEnchantedValue ="..
            "\n  ValueBase +"..
            "\n  UnenchantedValue * ValueMultiplier +"..
            "\n  MaxCharge * ValuePerMaxCharge +"..
            "\n  EffectCost * ValuePerEffectCost"..
            "\n\nMaxCharge is only non-zero for \"Cast When Strikes\" and \"Cast When Used\" enchantments."..
            " EffectCost is only non-zero for \"Constant Effect\" enchantments."..
            "\n\nDefault Value: " .. defaultMcmConfig.weapon.enchantedItem.valueMult,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.weapon.enchantedItem,
            id = "valueMult",
        }),
        min = 1,
        max = 2,
        step = 0.01,
        jump = 0.1,
        decimalPlaces = 2,
    })
    
    page:createSlider({
        label = "Enchanted Weapon - Value Per Max Charge",
        description =
            "When \"Recalculate Value\" is \"Yes\":"..
            "\n\nEnchantedValue ="..
            "\n  ValueBase +"..
            "\n  UnenchantedValue * ValueMultiplier +"..
            "\n  MaxCharge * ValuePerMaxCharge +"..
            "\n  EffectCost * ValuePerEffectCost"..
            "\n\nMaxCharge is only non-zero for \"Cast When Strikes\" and \"Cast When Used\" enchantments."..
            " EffectCost is only non-zero for \"Constant Effect\" enchantments."..
            "\n\nDefault Value: " .. defaultMcmConfig.weapon.enchantedItem.valuePerMaxCharge,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.weapon.enchantedItem,
            id = "valuePerMaxCharge",
        }),
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        decimalPlaces = 0,
    })
    
    page:createSlider({
        label = "Enchanted Weapon - Value Per Effect Cost",
        description =
            "When \"Recalculate Value\" is \"Yes\":"..
            "\n\nEnchantedValue ="..
            "\n  ValueBase +"..
            "\n  UnenchantedValue * ValueMultiplier +"..
            "\n  MaxCharge * ValuePerMaxCharge +"..
            "\n  EffectCost * ValuePerEffectCost"..
            "\n\nMaxCharge is only non-zero for \"Cast When Strikes\" and \"Cast When Used\" enchantments."..
            " EffectCost is only non-zero for \"Constant Effect\" enchantments."..
            "\n\nDefault Value: " .. defaultMcmConfig.weapon.enchantedItem.valuePerEffectCost,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.weapon.enchantedItem,
            id = "valuePerEffectCost",
        }),
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        decimalPlaces = 0,
    })
    
    page:createSlider({
        label = "Enchanted Weapon - Value Scale",
        description =
            "When \"Recalculate Value\" is \"No\": The new value of pre-enchanted weapons is equal to the item's VANILLA value multiplied by this setting."..
            "\n\nDefault Value: " .. defaultMcmConfig.weapon.enchantedItem.valueScale,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.weapon.enchantedItem,
            id = "valueScale",
        }),
        min = 0,
        max = 2,
        step = 0.01,
        jump = 0.1,
        decimalPlaces = 2,
    })
    
end

local function createClothingRestoreDefaultsPage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Restore Defaults" })
    
    page:createInfo({ text = "WARNING: These actions cannot be undone." })
    page:createInfo({ text = "Any changes you've made will be lost." })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createButton({
        buttonText = "Restore ALL Clothing Defaults",
        description = "Restores the default values of ALL settings in the \"BYO Rebalance 3: Clothing\" section.",
        callback = function()
            util.deepMerge(mcmConfig.clothing, defaultMcmConfig.clothing)
        end,
        restartRequired = true,
    })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createButton({
        buttonText = "Restore Clothing \"Slot\" Defaults",
        description = "Restores the default values of all settings on the \"Slot\" tab.",
        callback = function()
            util.deepMerge(mcmConfig.clothing.slot, defaultMcmConfig.clothing.slot)
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })
    
    page:createButton({
        buttonText = "Restore Clothing \"Tier\" Defaults",
        description =
            "Restores the default values of all settings on the \"Tier\", \"Detect Tier 1\", and \"Detect Tier 2\" tabs."..
            " Also restores the default value of the \"Tier Count\" setting on the \"Home\" tab.",
        callback = function()
            mcmConfig.clothing.tierCount = defaultMcmConfig.clothing.tierCount
            util.deepMerge(mcmConfig.clothing.tier, defaultMcmConfig.clothing.tier)
            util.deepMerge(mcmConfig.clothing.detectTier, defaultMcmConfig.clothing.detectTier)
        end,
        restartRequired = true,
    })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createButton({
        buttonText = "Restore \"Enchanted Clothing\" Defaults",
        description = "Restores the default values of the \"Enchanted Clothing\" settings on the \"Home\" tab.",
        callback = function()
            util.deepMerge(mcmConfig.clothing.enchantedItem, defaultMcmConfig.clothing.enchantedItem)
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })
    
    page:createButton({
        buttonText = "Restore \"Unenchanted\" Defaults",
        description = "Restores the default values of the \"Unenchanted\" settings on the \"Home\" tab.",
        callback = function()
            util.deepMerge(mcmConfig.clothing.unenchantedItem, defaultMcmConfig.clothing.unenchantedItem)
        end,
        restartRequired = true,
    })
    
end

local function createClothingDetectTierByEnchantPage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Detect Tier 2" })
    
    page.sidebar:createInfo({ text =
        "If an clothing piece's tier was not determined by the \"Detect Tier 1\" tab, its tier is determined by the following process instead:"..
        "\n\nSort the Max Enchant values in the clothing piece's slot from lowest to highest."..
        " Compare the clothing piece to each Max Enchant value, in ascending order."..
        " If the clothing piece's pre-rebalance Enchant is less than or equal to the Max Enchant value, assign it to the corresponding tier."..
        "\n\nIf the clothing piece was not assigned a tier by this process, it cannot be rebalanced, and you will see an error message when you load a save."..
        " To avoid this, make sure each slot has one slider set to its maximum value."
    })
    
    for slot, _ in util.sortedPairs(mcmConfig.clothing.detectTier.maxEnchant, common.sortFunction_ByClothingSlotConfigKey) do
        
        for tier, _ in util.sortedPairs(mcmConfig.clothing.detectTier.maxEnchant[slot]) do
            
            page:createSlider({
                label = string.format("T%d %s Max Enchant", tier, util.capitalizeFirstLetter(slot)),
                variable = mwse.mcm.createTableVariable({
                    table = mcmConfig.clothing.detectTier.maxEnchant[slot],
                    id = tier,
                }),
                min = 0,
                max = 200,
                step = 1,
                jump = 10,
                decimalPlaces = 0,
            })
            
        end
        
        if slot ~= "robe" then
            page:createInfo({ text = "------------------------------" })
        end
        
    end
    
end

local function createClothingDetectTierBySearchTermPage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Detect Tier 1", noScroll = true })
    
    page.sidebar:createInfo({ text =
        "Tier:SearchTerm"..
        "\n\nPress Enter to save changes."..
        "\nPress Shift+Enter to add a new line."..
        "\nSearch term is NOT case-sensitive."..
        "\nWhitespace characters matter!"..
        "\n\nEach line of this paragraph field contains a tier and a search term, separated by a colon."..
        " If a clothing piece's name, mesh, icon, or ID contains the search term, it is assigned the corresponding tier."..
        " If multiple search terms match, ties are broken by search term length (longer wins), then by alphabetical order (earlier wins)."..
        "\n\nIf none of the search terms match, the clothing piece's tier is determined by the \"Detect Tier 2\" tab."..
        "\n\nSPECIAL: If you start a search term with an asterisk (*), the asterisk will be ignored and the remainder of the search term will be treated as a Lua pattern."..
        "\n\nSPECIAL: Clothing pieces assigned to tier zero will not be rebalanced."..
        " This is an alternative to the \"Excluded Items\" tab for those who prefer it."..
        "\n\nREQUIRES RESTART: The game must be restarted before any additions, removals, or changes to tier zero search terms will come into effect."
    })
    
    page:createParagraphField({
        label = "\"Tier\" Search Terms",
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.clothing.detectTier,
            id = "searchTerms",
        }),
        sNewValue = "Saved changes.",
    })
    
end

local function createClothingTierPage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Tier" })
    
    page.sidebar:createInfo({ text = 
        "ClothingWeight ="..
        "\n  SlotWeight (0.0 to 10.0) *"..
        "\n  TierWeight (0.0 to 10.0)"..
        "\n\nClothingEnchant ="..
        "\n  SlotEnchant (0.0 to 50.0) *"..
        "\n  TierEnchant (0.0 to 20.0)"..
        "\n\nClothingValue ="..
        "\n  SlotValue (0.0 to 50.0) *"..
        "\n  TierValue (0.0 to 100.0)"
    })
    
    for tier, _ in util.sortedPairs(mcmConfig.clothing.tier.weight) do
        
        page:createSlider({
            label = string.format("T%s Weight", tier),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.clothing.tier.weight,
                id = tier,
            }),
            min = 0,
            max = 10,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for tier, _ in util.sortedPairs(mcmConfig.clothing.tier.enchant) do
        
        page:createSlider({
            label = string.format("T%s Enchant", tier),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.clothing.tier.enchant,
                id = tier,
            }),
            min = 0,
            max = 20,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for tier, _ in util.sortedPairs(mcmConfig.clothing.tier.value) do
        
        page:createSlider({
            label = string.format("T%s Value", tier),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.clothing.tier.value,
                id = tier,
            }),
            min = 0,
            max = 100,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
end

local function createClothingSlotPage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Slot" })
    
    page.sidebar:createInfo({ text = 
        "ClothingWeight ="..
        "\n  SlotWeight (0.0 to 10.0) *"..
        "\n  TierWeight (0.0 to 10.0)"..
        "\n\nClothingEnchant ="..
        "\n  SlotEnchant (0.0 to 50.0) *"..
        "\n  TierEnchant (0.0 to 20.0)"..
        "\n\nClothingValue ="..
        "\n  SlotValue (0.0 to 50.0) *"..
        "\n  TierValue (0.0 to 100.0)"
    })
    
    for slot, _ in util.sortedPairs(mcmConfig.clothing.slot.weight, common.sortFunction_ByClothingSlotConfigKey) do
        
        page:createSlider({
            label = string.format("%s Weight", util.capitalizeFirstLetter(slot)),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.clothing.slot.weight,
                id = slot,
            }),
            min = 0.1,
            max = 10,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for slot, _ in util.sortedPairs(mcmConfig.clothing.slot.enchant, common.sortFunction_ByClothingSlotConfigKey) do
        
        page:createSlider({
            label = string.format("%s Enchant", util.capitalizeFirstLetter(slot)),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.clothing.slot.enchant,
                id = slot,
            }),
            min = 0,
            max = 50,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for slot, _ in util.sortedPairs(mcmConfig.clothing.slot.value, common.sortFunction_ByClothingSlotConfigKey) do
        
        page:createSlider({
            label = string.format("%s Value", util.capitalizeFirstLetter(slot)),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.clothing.slot.value,
                id = slot,
            }),
            min = 0,
            max = 50,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
end

local function createClothingHomePage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Home" })
    
    page:createYesNoButton({
        label = "Clothing Rebalance Enabled",
        description =
            "Yes = Updates the stats of every clothing piece in the game according to the settings in the \"BYO Rebalance 3: Clothing\" section."..
            " Any changes to these settings will come into effect when you load a save."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.clothing.rebalanceEnabled),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.clothing,
            id = "rebalanceEnabled",
        }),
        restartRequired = true,
    })
    
    page:createSlider({
        label = "Tier Count (Requires Restart)",
        description =
            "The number of customizable clothing tiers."..
            "\n\nDefault Value: " .. defaultMcmConfig.clothing.tierCount,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.clothing,
            id = "tierCount",
        }),
        min = 2,
        max = 20,
        step = 1,
        jump = 1,
        decimalPlaces = 0,
    })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createYesNoButton({
        label = "Enchanted Clothing - Recalculate Value",
        description =
            "Yes = This mod will recalculate the value of pre-enchanted clothing pieces from scratch using the \"Value Base\", \"Value Multiplier\", \"Value Per Max Charge\", and \"Value Per Effect Cost\" settings."..
            "\n\nNo = This mod will scale the vanilla value of pre-enchanted clothing pieces using the \"Value Scale\" setting."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.clothing.enchantedItem.recalculateValue),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.clothing.enchantedItem,
            id = "recalculateValue",
        }),
    })
    
    page:createSlider({
        label = "Enchanted Clothing - Value Base",
        description =
            "When \"Recalculate Value\" is \"Yes\":"..
            "\n\nEnchantedValue ="..
            "\n  ValueBase +"..
            "\n  UnenchantedValue * ValueMultiplier +"..
            "\n  MaxCharge * ValuePerMaxCharge +"..
            "\n  EffectCost * ValuePerEffectCost"..
            "\n\nMaxCharge is only non-zero for \"Cast When Strikes\" and \"Cast When Used\" enchantments."..
            " EffectCost is only non-zero for \"Constant Effect\" enchantments."..
            "\n\nDefault Value: " .. defaultMcmConfig.clothing.enchantedItem.valueBase,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.clothing.enchantedItem,
            id = "valueBase",
        }),
        min = 0,
        max = 1000,
        step = 1,
        jump = 100,
        decimalPlaces = 0,
    })
    
    page:createSlider({
        label = "Enchanted Clothing - Value Multiplier",
        description =
            "When \"Recalculate Value\" is \"Yes\":"..
            "\n\nEnchantedValue ="..
            "\n  ValueBase +"..
            "\n  UnenchantedValue * ValueMultiplier +"..
            "\n  MaxCharge * ValuePerMaxCharge +"..
            "\n  EffectCost * ValuePerEffectCost"..
            "\n\nMaxCharge is only non-zero for \"Cast When Strikes\" and \"Cast When Used\" enchantments."..
            " EffectCost is only non-zero for \"Constant Effect\" enchantments."..
            "\n\nDefault Value: " .. defaultMcmConfig.clothing.enchantedItem.valueMult,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.clothing.enchantedItem,
            id = "valueMult",
        }),
        min = 1,
        max = 100,
        step = 0.1,
        jump = 1,
        decimalPlaces = 1,
    })
    
    page:createSlider({
        label = "Enchanted Clothing - Value Per Max Charge",
        description =
            "When \"Recalculate Value\" is \"Yes\":"..
            "\n\nEnchantedValue ="..
            "\n  ValueBase +"..
            "\n  UnenchantedValue * ValueMultiplier +"..
            "\n  MaxCharge * ValuePerMaxCharge +"..
            "\n  EffectCost * ValuePerEffectCost"..
            "\n\nMaxCharge is only non-zero for \"Cast When Strikes\" and \"Cast When Used\" enchantments."..
            " EffectCost is only non-zero for \"Constant Effect\" enchantments."..
            "\n\nDefault Value: " .. defaultMcmConfig.clothing.enchantedItem.valuePerMaxCharge,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.clothing.enchantedItem,
            id = "valuePerMaxCharge",
        }),
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        decimalPlaces = 0,
    })
    
    page:createSlider({
        label = "Enchanted Clothing - Value Per Effect Cost",
        description =
            "When \"Recalculate Value\" is \"Yes\":"..
            "\n\nEnchantedValue ="..
            "\n  ValueBase +"..
            "\n  UnenchantedValue * ValueMultiplier +"..
            "\n  MaxCharge * ValuePerMaxCharge +"..
            "\n  EffectCost * ValuePerEffectCost"..
            "\n\nMaxCharge is only non-zero for \"Cast When Strikes\" and \"Cast When Used\" enchantments."..
            " EffectCost is only non-zero for \"Constant Effect\" enchantments."..
            "\n\nDefault Value: " .. defaultMcmConfig.clothing.enchantedItem.valuePerEffectCost,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.clothing.enchantedItem,
            id = "valuePerEffectCost",
        }),
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        decimalPlaces = 0,
    })
    
    page:createSlider({
        label = "Enchanted Clothing - Value Scale",
        description =
            "When \"Recalculate Value\" is \"No\": The new value of pre-enchanted clothing pieces is equal to the item's VANILLA value multiplied by this setting."..
            "\n\nDefault Value: " .. defaultMcmConfig.clothing.enchantedItem.valueScale,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.clothing.enchantedItem,
            id = "valueScale",
        }),
        min = 0,
        max = 2,
        step = 0.01,
        jump = 0.1,
        decimalPlaces = 2,
    })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createYesNoButton({
        label = "Unenchanted - Exclude High Value Items",
        description =
            "Yes = This mod will not rebalance unenchanted clothing pieces that have a value greater than the \"Max Value\" setting."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.clothing.unenchantedItem.excludeHighValueItems),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.clothing.unenchantedItem,
            id = "excludeHighValueItems",
        }),
        restartRequired = true,
    })
    
    page:createSlider({
        label = "Unenchanted - Max Value (Requires Restart)",
        description =
            "When \"Exclude High Value Items\" is \"Yes\": This mod will not rebalance unenchanted clothing pieces that have a value greater than this setting."..
            "\n\nDefault Value: " .. defaultMcmConfig.clothing.unenchantedItem.maxValue,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.clothing.unenchantedItem,
            id = "maxValue",
        }),
        min = 0,
        max = 10000,
        step = 1,
        jump = 100,
        decimalPlaces = 0,
    })
    
end

local function createArmorRestoreDefaultsPage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Restore Defaults" })
    
    page:createInfo({ text = "WARNING: These actions cannot be undone." })
    page:createInfo({ text = "Any changes you've made will be lost." })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createButton({
        buttonText = "Restore ALL Armor Defaults",
        description = "Restores the default values of ALL settings in the \"BYO Rebalance 2: Armor\" section EXCEPT for the \"Unarmored\" settings on the \"Home\" tab.",
        callback = function()
            util.deepMerge(mcmConfig.armor, defaultMcmConfig.armor)
        end,
        restartRequired = true,
    })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createButton({
        buttonText = "Restore Armor \"Slot\" Defaults",
        description = "Restores the default values of all settings on the \"Slot\" tab.",
        callback = function()
            util.deepMerge(mcmConfig.armor.slot, defaultMcmConfig.armor.slot)
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })
    
    page:createButton({
        buttonText = "Restore Armor \"Weight Class\" Defaults",
        description = "Restores the default values of all settings on the \"Weight Class\" and \"Detect WC\" tabs.",
        callback = function()
            util.deepMerge(mcmConfig.armor.weightClass, defaultMcmConfig.armor.weightClass)
            util.deepMerge(mcmConfig.armor.detectWeightClass, defaultMcmConfig.armor.detectWeightClass)
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })
    
    page:createButton({
        buttonText = "Restore Armor \"Tier\" Defaults",
        description =
            "Restores the default values of all settings on the \"Tier\", \"Detect Tier 1\", and \"Detect Tier 2\" tabs."..
            " Also restores the default value of the \"Tier Count\" setting on the \"Home\" tab.",
        callback = function()
            mcmConfig.armor.tierCount = defaultMcmConfig.armor.tierCount
            util.deepMerge(mcmConfig.armor.tier, defaultMcmConfig.armor.tier)
            util.deepMerge(mcmConfig.armor.detectTier, defaultMcmConfig.armor.detectTier)
        end,
        restartRequired = true,
    })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createButton({
        buttonText = "Restore \"Base Armor Skill\" Defaults",
        description = "Restores the default value of the \"Base Armor Skill\" setting on the \"Home\" tab.",
        callback = function()
            mcmConfig.armor.baseArmorSkill = defaultMcmConfig.armor.baseArmorSkill
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })
    
    page:createButton({
        buttonText = "Restore \"Bound Armor\" Defaults",
        description = "Restores the default values of the \"Bound Armor\" settings on the \"Home\" tab.",
        callback = function()
            util.deepMerge(mcmConfig.armor.boundItem, defaultMcmConfig.armor.boundItem)
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })
    
    page:createButton({
        buttonText = "Restore \"Enchanted Armor\" Defaults",
        description = "Restores the default values of the \"Enchanted Armor\" settings on the \"Home\" tab.",
        callback = function()
            util.deepMerge(mcmConfig.armor.enchantedItem, defaultMcmConfig.armor.enchantedItem)
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createButton({
        buttonText = "Restore Unarmored Defaults",
        description = "Restores the default values of the \"Unarmored\" settings on the \"Home\" tab.",
        callback = function()
            util.deepMerge(mcmConfig.unarmored, defaultMcmConfig.unarmored)
        end,
        restartRequired = true,
    })
    
end

local function createArmorDetectTierByArmorRatingPage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Detect Tier 2" })
    
    page.sidebar:createInfo({ text =
        "If an armor piece's tier was not determined by the \"Detect Tier 1\" tab, its tier is determined by the following process instead:"..
        "\n\nSort the Max AR values in the armor piece's weight class from lowest to highest."..
        " Compare the armor piece to each Max AR value, in ascending order."..
        " If the armor piece's pre-rebalance AR is less than or equal to the Max AR value, assign it to the corresponding tier."..
        "\n\nIf the armor piece was not assigned a tier by this process, it cannot be rebalanced, and you will see an error message when you load a save."..
        " To avoid this, make sure each weight class has one slider set to its maximum value."
    })
    
    for weightClass, _ in util.sortedPairs(mcmConfig.armor.detectTier.maxArmorRating, common.sortFunction_ByArmorWeightClassConfigKey) do
        
        for tier, _ in util.sortedPairs(mcmConfig.armor.detectTier.maxArmorRating[weightClass]) do
            
            page:createSlider({
                label = string.format("T%d %s Max AR", tier, util.capitalizeFirstLetter(weightClass)),
                variable = mwse.mcm.createTableVariable({
                    table = mcmConfig.armor.detectTier.maxArmorRating[weightClass],
                    id = tier,
                }),
                min = 0,
                max = 200,
                step = 1,
                jump = 10,
                decimalPlaces = 0,
            })
            
        end
        
        if weightClass ~= "heavy" then
            page:createInfo({ text = "------------------------------" })
        end
        
    end
    
end

local function createArmorDetectTierBySearchTermPage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Detect Tier 1", noScroll = true })
    
    page.sidebar:createInfo({ text =
        "Tier:SearchTerm"..
        "\n\nPress Enter to save changes."..
        "\nPress Shift+Enter to add a new line."..
        "\nSearch term is NOT case-sensitive."..
        "\nWhitespace characters matter!"..
        "\n\nEach line of this paragraph field contains a tier and a search term, separated by a colon."..
        " If an armor piece's name, mesh, icon, or ID contains the search term, it is assigned the corresponding tier."..
        " If multiple search terms match, ties are broken by search term length (longer wins), then by alphabetical order (earlier wins)."..
        "\n\nIf none of the search terms match, the armor piece's tier is determined by the \"Detect Tier 2\" tab."..
        "\n\nSPECIAL: If you start a search term with an asterisk (*), the asterisk will be ignored and the remainder of the search term will be treated as a Lua pattern."..
        "\n\nSPECIAL: Armor pieces assigned to tier zero will not be rebalanced."..
        " This is an alternative to the \"Excluded Items\" tab for those who prefer it."..
        "\n\nREQUIRES RESTART: The game must be restarted before any additions, removals, or changes to tier zero search terms will come into effect."
    })
    
    page:createParagraphField({
        label = "\"Tier\" Search Terms",
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.armor.detectTier,
            id = "searchTerms",
        }),
        sNewValue = "Saved changes.",
    })
    
end

local function createArmorDetectWeightClassBySearchTermPage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Detect WC", noScroll = true })
    
    page.sidebar:createInfo({ text =
        "WeightClass:SearchTerm"..
        "\n\n  L = Light"..
        "\n  M = Medium"..
        "\n  H = Heavy"..
        "\n\nPress Enter to save changes."..
        "\nPress Shift+Enter to add a new line."..
        "\nSearch term is NOT case-sensitive."..
        "\nWhitespace characters matter!"..
        "\n\nEach line of this paragraph field contains a weight class and a search term, separated by a colon."..
        " If an armor piece's name, mesh, icon, or ID contains the search term, it is assigned the corresponding weight class."..
        " If multiple search terms match, ties are broken by search term length (longer wins), then by alphabetical order (earlier wins)."..
        "\n\nIf none of the search terms match, the armor piece keeps its pre-rebalance weight class."..
        "\n\nSPECIAL: If you start a search term with an asterisk (*), the asterisk will be ignored and the remainder of the search term will be treated as a Lua pattern."
    })
    
    page:createParagraphField({
        label = "\"Weight Class\" Search Terms",
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.armor.detectWeightClass,
            id = "searchTerms",
        }),
        sNewValue = "Saved changes.",
    })
    
end

local function createArmorTierPage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Tier" })
    
    page.sidebar:createInfo({ text = 
        "ArmorAR ="..
        "\n  WeightClassAR (0.0 to 10.0) *"..
        "\n  TierAR (0 to 100)"..
        "\n\nArmorWeight ="..
        "\n  SlotWeight (0.1 to 10.0) *"..
        "\n  WeightClassWeight (1, 2, or 4) *"..
        "\n  TierWeight (1.50 to 2.90)"..
        "\n\nArmorEnchant ="..
        "\n  SlotEnchant (0.0 to 50.0) *"..
        "\n  WeightClassEnchant (0.0 to 10.0) *"..
        "\n  TierEnchant (0.0 to 10.0)"..
        "\n\nArmorHealth ="..
        "\n  SlotHealth (0 to 500) *"..
        "\n  WeightClassHealth (0.0 to 10.0) *"..
        "\n  TierHealth (0.0 to 10.0)"..
        "\n\nArmorValue ="..
        "\n  SlotValue (0.0 to 10.0) *"..
        "\n  WeightClassValue (0.0 to 10.0) *"..
        "\n  TierValue (0 to 10000)"
    })
    
    for tier, _ in util.sortedPairs(mcmConfig.armor.tier.armorRating) do
        
        page:createSlider({
            label = string.format("T%d AR", tier),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.armor.tier.armorRating,
                id = tier,
            }),
            min = 0,
            max = 100,
            step = 1,
            jump = 10,
            decimalPlaces = 0,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for tier, _ in util.sortedPairs(mcmConfig.armor.tier.weight) do
        
        page:createSlider({
            label = string.format("T%s Weight", tier),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.armor.tier.weight,
                id = tier,
            }),
            min = 1.50,
            max = 2.90,
            step = 0.01,
            jump = 0.1,
            decimalPlaces = 2,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for tier, _ in util.sortedPairs(mcmConfig.armor.tier.enchant) do
        
        page:createSlider({
            label = string.format("T%s Enchant", tier),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.armor.tier.enchant,
                id = tier,
            }),
            min = 0,
            max = 10,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for tier, _ in util.sortedPairs(mcmConfig.armor.tier.health) do
        
        page:createSlider({
            label = string.format("T%s Health", tier),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.armor.tier.health,
                id = tier,
            }),
            min = 0,
            max = 10,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for tier, _ in util.sortedPairs(mcmConfig.armor.tier.value) do
        
        page:createSlider({
            label = string.format("T%s Value", tier),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.armor.tier.value,
                id = tier,
            }),
            min = 0,
            max = 10000,
            step = 1,
            jump = 100,
            decimalPlaces = 0,
        })
        
    end
    
end

local function createArmorWeightClassPage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Weight Class" })
    
    page.sidebar:createInfo({ text = 
        "ArmorAR ="..
        "\n  WeightClassAR (0.0 to 10.0) *"..
        "\n  TierAR (0 to 100)"..
        "\n\nArmorWeight ="..
        "\n  SlotWeight (0.1 to 10.0) *"..
        "\n  WeightClassWeight (1, 2, or 4) *"..
        "\n  TierWeight (1.50 to 2.90)"..
        "\n\nArmorEnchant ="..
        "\n  SlotEnchant (0.0 to 50.0) *"..
        "\n  WeightClassEnchant (0.0 to 10.0) *"..
        "\n  TierEnchant (0.0 to 10.0)"..
        "\n\nArmorHealth ="..
        "\n  SlotHealth (0 to 500) *"..
        "\n  WeightClassHealth (0.0 to 10.0) *"..
        "\n  TierHealth (0.0 to 10.0)"..
        "\n\nArmorValue ="..
        "\n  SlotValue (0.0 to 10.0) *"..
        "\n  WeightClassValue (0.0 to 10.0) *"..
        "\n  TierValue (0 to 10000)"
    })
    
    for weightClass, _ in util.sortedPairs(mcmConfig.armor.weightClass.armorRating, common.sortFunction_ByArmorWeightClassConfigKey) do
        
        page:createSlider({
            label = string.format("%s AR", util.capitalizeFirstLetter(weightClass)),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.armor.weightClass.armorRating,
                id = weightClass,
            }),
            min = 0,
            max = 10,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for weightClass, _ in util.sortedPairs(mcmConfig.armor.weightClass.enchant, common.sortFunction_ByArmorWeightClassConfigKey) do
        
        page:createSlider({
            label = string.format("%s Enchant", util.capitalizeFirstLetter(weightClass)),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.armor.weightClass.enchant,
                id = weightClass,
            }),
            min = 0,
            max = 10,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for weightClass, _ in util.sortedPairs(mcmConfig.armor.weightClass.health, common.sortFunction_ByArmorWeightClassConfigKey) do
        
        page:createSlider({
            label = string.format("%s Health", util.capitalizeFirstLetter(weightClass)),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.armor.weightClass.health,
                id = weightClass,
            }),
            min = 0,
            max = 10,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for weightClass, _ in util.sortedPairs(mcmConfig.armor.weightClass.value, common.sortFunction_ByArmorWeightClassConfigKey) do
        
        page:createSlider({
            label = string.format("%s Value", util.capitalizeFirstLetter(weightClass)),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.armor.weightClass.value,
                id = weightClass,
            }),
            min = 0,
            max = 10,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
end

local function createArmorSlotPage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Slot" })
    
    page.sidebar:createInfo({ text = 
        "ArmorAR ="..
        "\n  WeightClassAR (0.0 to 10.0) *"..
        "\n  TierAR (0 to 100)"..
        "\n\nArmorWeight ="..
        "\n  SlotWeight (0.1 to 10.0) *"..
        "\n  WeightClassWeight (1, 2, or 4) *"..
        "\n  TierWeight (1.50 to 2.90)"..
        "\n\nArmorEnchant ="..
        "\n  SlotEnchant (0.0 to 50.0) *"..
        "\n  WeightClassEnchant (0.0 to 10.0) *"..
        "\n  TierEnchant (0.0 to 10.0)"..
        "\n\nArmorHealth ="..
        "\n  SlotHealth (0 to 500) *"..
        "\n  WeightClassHealth (0.0 to 10.0) *"..
        "\n  TierHealth (0.0 to 10.0)"..
        "\n\nArmorValue ="..
        "\n  SlotValue (0.0 to 10.0) *"..
        "\n  WeightClassValue (0.0 to 10.0) *"..
        "\n  TierValue (0 to 10000)"
    })
    
    for slot, _ in util.sortedPairs(mcmConfig.armor.slot.weight, common.sortFunction_ByArmorSlotConfigKey) do
        
        page:createSlider({
            label = string.format("%s Weight", util.capitalizeFirstLetter(slot)),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.armor.slot.weight,
                id = slot,
            }),
            min = 0.1,
            max = 10,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for slot, _ in util.sortedPairs(mcmConfig.armor.slot.enchant, common.sortFunction_ByArmorSlotConfigKey) do
        
        page:createSlider({
            label = string.format("%s Enchant", util.capitalizeFirstLetter(slot)),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.armor.slot.enchant,
                id = slot,
            }),
            min = 0,
            max = 50,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for slot, _ in util.sortedPairs(mcmConfig.armor.slot.health, common.sortFunction_ByArmorSlotConfigKey) do
        
        page:createSlider({
            label = string.format("%s Health", util.capitalizeFirstLetter(slot)),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.armor.slot.health,
                id = slot,
            }),
            min = 0,
            max = 500,
            step = 1,
            jump = 10,
            decimalPlaces = 0,
        })
        
    end
    
    page:createInfo({ text = "------------------------------" })
    
    for slot, _ in util.sortedPairs(mcmConfig.armor.slot.value, common.sortFunction_ByArmorSlotConfigKey) do
        
        page:createSlider({
            label = string.format("%s Value", util.capitalizeFirstLetter(slot)),
            variable = mwse.mcm.createTableVariable({
                table = mcmConfig.armor.slot.value,
                id = slot,
            }),
            min = 0,
            max = 10,
            step = 0.1,
            jump = 1,
            decimalPlaces = 1,
        })
        
    end
    
end

local function createArmorHomePage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Home" })
    
    page:createYesNoButton({
        label = "Armor Rebalance Enabled",
        description =
            "Yes = Updates the stats of every armor piece in the game according to the settings in the \"BYO Rebalance 2: Armor\" section."..
            " Any changes to these settings will come into effect when you load a save."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.armor.rebalanceEnabled),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.armor,
            id = "rebalanceEnabled",
        }),
        restartRequired = true,
    })
    
    page:createSlider({
        label = "Base Armor Skill",
        description =
            "The AR calculations in this mod determine an item's effective AR at skill level 100."..
            "\n\nIf the calculated AR is a multiple of 10, the item's AR will be calculated correctly with this setting's default (vanilla) value."..
            "\n\nIf the calculated AR is NOT a multiple of 10, the item's AR will be rounded to the nearest whole number, resulting in a slightly inaccurate AR at skill level 100."..
            "\n\nIf you change this setting to 100, item AR will always be calculated with 100% accuracy, but any armor pieces in the \"Excluded Items\" list will have their effective ARs greatly reduced."..
            "\n\nDefault Value: " .. defaultMcmConfig.armor.baseArmorSkill,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.armor,
            id = "baseArmorSkill",
        }),
        min = 10,
        max = 100,
        step = 1,
        jump = 10,
        decimalPlaces = 0,
    })
    
    page:createSlider({
        label = "Tier Count (Requires Restart)",
        description =
            "The number of customizable armor tiers."..
            "\n\nDefault Value: " .. defaultMcmConfig.armor.tierCount,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.armor,
            id = "tierCount",
        }),
        min = 2,
        max = 20,
        step = 1,
        jump = 1,
        decimalPlaces = 0,
    })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createYesNoButton({
        label = "Bound Armor - AR Scaling Enabled",
        description =
            "Yes = The AR of bound armor scales with your \"Light Armor\" skill, just like all other armor."..
            " This is accomplished by making bound armor pieces weigh 0.01, instead of 0."..
            "\n\nNo = The AR of bound armor is static and does not scale with any skill."..
            " This is how bound armor works in vanilla Morrowind."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.armor.boundItem.scaleWithLightArmorSkill),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.armor.boundItem,
            id = "scaleWithLightArmorSkill",
        }),
    })
    
    page:createDropdown{
        label = "Bound Armor - Weight Class:",
        description =
            "The weight class of bound armor."..
            " This is only used for calculating item health, and for calculating AR if \"AR Scaling\" is enabled."..
            "\n\nDefault Value: " .. util.capitalizeFirstLetter(common.getArmorWeightClassSearchValueConfigKey(defaultMcmConfig.armor.boundItem.weightClass)),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.armor.boundItem,
            id = "weightClass",
        }),
        options = {
            { label = "Light", value = "L" },
            { label = "Medium", value = "M" },
            { label = "Heavy", value = "H" },
        },
    }
    
    page:createSlider({
        label = "Bound Armor - Tier",
        description =
            "The tier of bound armor."..
            " This is only used for calculating item health, and for calculating AR if \"AR Scaling\" is enabled."..
            "\n\nDefault Value: " .. defaultMcmConfig.armor.boundItem.tier,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.armor.boundItem,
            id = "tier",
        }),
        min = 1,
        max = mcmConfig.armor.tierCount,
        step = 1,
        jump = 1,
        decimalPlaces = 0,
    })
    
    page:createSlider({
        label = "Bound Armor - Non-Scaling AR",
        description =
            "The AR of bound armor."..
            " This AR is static and does not scale with any skill."..
            " This setting is only used when \"AR Scaling\" is disabled."..
            "\n\nDefault Value: " .. defaultMcmConfig.armor.boundItem.armorRating,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.armor.boundItem,
            id = "armorRating",
        }),
        min = 0,
        max = 200,
        step = 1,
        jump = 10,
        decimalPlaces = 0,
    })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createYesNoButton({
        label = "Enchanted Armor - Recalculate Value",
        description =
            "Yes = This mod will recalculate the value of pre-enchanted armor pieces from scratch using the \"Value Base\", \"Value Multiplier\", \"Value Per Max Charge\", and \"Value Per Effect Cost\" settings."..
            "\n\nNo = This mod will scale the vanilla value of pre-enchanted armor pieces using the \"Value Scale\" setting."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.armor.enchantedItem.recalculateValue),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.armor.enchantedItem,
            id = "recalculateValue",
        }),
    })
    
    page:createSlider({
        label = "Enchanted Armor - Value Base",
        description =
            "When \"Recalculate Value\" is \"Yes\":"..
            "\n\nEnchantedValue ="..
            "\n  ValueBase +"..
            "\n  UnenchantedValue * ValueMultiplier +"..
            "\n  MaxCharge * ValuePerMaxCharge +"..
            "\n  EffectCost * ValuePerEffectCost"..
            "\n\nMaxCharge is only non-zero for \"Cast When Strikes\" and \"Cast When Used\" enchantments."..
            " EffectCost is only non-zero for \"Constant Effect\" enchantments."..
            "\n\nDefault Value: " .. defaultMcmConfig.armor.enchantedItem.valueBase,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.armor.enchantedItem,
            id = "valueBase",
        }),
        min = 0,
        max = 1000,
        step = 1,
        jump = 100,
        decimalPlaces = 0,
    })
    
    page:createSlider({
        label = "Enchanted Armor - Value Multiplier",
        description =
            "When \"Recalculate Value\" is \"Yes\":"..
            "\n\nEnchantedValue ="..
            "\n  ValueBase +"..
            "\n  UnenchantedValue * ValueMultiplier +"..
            "\n  MaxCharge * ValuePerMaxCharge +"..
            "\n  EffectCost * ValuePerEffectCost"..
            "\n\nMaxCharge is only non-zero for \"Cast When Strikes\" and \"Cast When Used\" enchantments."..
            " EffectCost is only non-zero for \"Constant Effect\" enchantments."..
            "\n\nDefault Value: " .. defaultMcmConfig.armor.enchantedItem.valueMult,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.armor.enchantedItem,
            id = "valueMult",
        }),
        min = 1,
        max = 2,
        step = 0.01,
        jump = 0.1,
        decimalPlaces = 2,
    })
    
    page:createSlider({
        label = "Enchanted Armor - Value Per Max Charge",
        description =
            "When \"Recalculate Value\" is \"Yes\":"..
            "\n\nEnchantedValue ="..
            "\n  ValueBase +"..
            "\n  UnenchantedValue * ValueMultiplier +"..
            "\n  MaxCharge * ValuePerMaxCharge +"..
            "\n  EffectCost * ValuePerEffectCost"..
            "\n\nMaxCharge is only non-zero for \"Cast When Strikes\" and \"Cast When Used\" enchantments."..
            " EffectCost is only non-zero for \"Constant Effect\" enchantments."..
            "\n\nDefault Value: " .. defaultMcmConfig.armor.enchantedItem.valuePerMaxCharge,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.armor.enchantedItem,
            id = "valuePerMaxCharge",
        }),
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        decimalPlaces = 0,
    })
    
    page:createSlider({
        label = "Enchanted Armor - Value Per Effect Cost",
        description =
            "When \"Recalculate Value\" is \"Yes\":"..
            "\n\nEnchantedValue ="..
            "\n  ValueBase +"..
            "\n  UnenchantedValue * ValueMultiplier +"..
            "\n  MaxCharge * ValuePerMaxCharge +"..
            "\n  EffectCost * ValuePerEffectCost"..
            "\n\nMaxCharge is only non-zero for \"Cast When Strikes\" and \"Cast When Used\" enchantments."..
            " EffectCost is only non-zero for \"Constant Effect\" enchantments."..
            "\n\nDefault Value: " .. defaultMcmConfig.armor.enchantedItem.valuePerEffectCost,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.armor.enchantedItem,
            id = "valuePerEffectCost",
        }),
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        decimalPlaces = 0,
    })
    
    page:createSlider({
        label = "Enchanted Armor - Value Scale",
        description =
            "When \"Recalculate Value\" is \"No\": The new value of pre-enchanted armor pieces is equal to the item's VANILLA value multiplied by this setting."..
            "\n\nDefault Value: " .. defaultMcmConfig.armor.enchantedItem.valueScale,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.armor.enchantedItem,
            id = "valueScale",
        }),
        min = 0,
        max = 2,
        step = 0.01,
        jump = 0.1,
        decimalPlaces = 2,
    })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createYesNoButton({
        label = "Unarmored Rebalance Enabled",
        description =
            "Yes = Changes the AR granted by the \"Unarmored\" skill (at skill level 100) to the value specified by the \"Unarmored AR\" setting."..
            " Any changes to that setting will come into effect when you load a save."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.unarmored.rebalanceEnabled),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.unarmored,
            id = "rebalanceEnabled",
        }),
        restartRequired = true,
    })
    
    page:createSlider({
        label = "Unarmored AR",
        description =
            "The AR granted by the \"Unarmored\" skill at skill level 100."..
            "\n\nDefault Value: " .. defaultMcmConfig.unarmored.armorRating,
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.unarmored,
            id = "armorRating",
        }),
        min = 0,
        max = 200,
        step = 1,
        jump = 10,
        decimalPlaces = 0,
    })
    
end

local function createMainRestoreDefaultsPage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Restore Defaults" })
    
    page:createInfo({ text = "WARNING: These actions cannot be undone." })
    page:createInfo({ text = "Any changes you've made will be lost." })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createButton({
        buttonText = "Restore ALL Defaults",
        description = "Restores the default values of ALL settings EVERYWHERE in this mod.",
        callback = function()
            mcmConfig.shared.excludedItemIds = util.deepCopy(defaultMcmConfig.shared.excludedItemIds)
            util.deepMerge(mcmConfig, defaultMcmConfig)
        end,
        restartRequired = true,
    })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createButton({
        buttonText = "Restore ALL Armor Defaults",
        description = "Restores the default values of ALL settings in the \"BYO Rebalance 2: Armor\" section EXCEPT for the \"Unarmored\" settings on the \"Home\" tab.",
        callback = function()
            util.deepMerge(mcmConfig.armor, defaultMcmConfig.armor)
        end,
        restartRequired = true,
    })
    
    page:createButton({
        buttonText = "Restore ALL Clothing Defaults",
        description = "Restores the default values of ALL settings in the \"BYO Rebalance 3: Clothing\" section.",
        callback = function()
            util.deepMerge(mcmConfig.clothing, defaultMcmConfig.clothing)
        end,
        restartRequired = true,
    })
    
    page:createButton({
        buttonText = "Restore ALL Weapon Defaults",
        description = "Restores the default values of ALL settings in the \"BYO Rebalance 4: Weapons\" section.",
        callback = function()
            util.deepMerge(mcmConfig.weapon, defaultMcmConfig.weapon)
        end,
        restartRequired = true,
    })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createButton({
        buttonText = "Restore Unarmored Defaults",
        description = "Restores the default values of the \"Unarmored\" settings on the \"Home\" tab of the \"BYO Rebalance 2: Armor\" section.",
        callback = function()
            util.deepMerge(mcmConfig.unarmored, defaultMcmConfig.unarmored)
        end,
        restartRequired = true,
    })
    
    page:createButton({
        buttonText = "Restore \"Item Health\" Defaults",
        description = "Restores the default values of the \"Fix Item Health Overflow\" and \"Repair Damaged Items\" settings on the \"Home\" tab.",
        callback = function()
            util.deepMerge(mcmConfig.condition, defaultMcmConfig.condition)
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })
    
    page:createButton({
        buttonText = "Restore \"Excluded Items\" Defaults",
        description = "Restores the default values of all settings on the \"Excluded Items\" tab.",
        callback = function()
            mcmConfig.shared.excludedItemIds = util.deepCopy(defaultMcmConfig.shared.excludedItemIds)
        end,
        restartRequired = true,
    })
    
    page:createButton({
        buttonText = "Restore \"Bound Items\" Defaults",
        description =
            "Restores the default values of all settings on the \"Bound Items\" tab."..
            " Also restores the default value of the \"Detect Bound Items by Name\" setting on the \"Home\" tab.",
        callback = function()
            mcmConfig.shared.detectBoundItemsByName = defaultMcmConfig.shared.detectBoundItemsByName
            mcmConfig.shared.boundItemIds = util.deepCopy(defaultMcmConfig.shared.boundItemIds)
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })
    
    page:createButton({
        buttonText = "Restore \"Custom-Enchanted Items\" Defaults",
        description = "Restores the default value of the \"Rebalance Custom-Enchanted Items\" setting on the \"Home\" tab.",
        callback = function()
            mcmConfig.shared.rebalanceCustomEnchantedItems = defaultMcmConfig.shared.rebalanceCustomEnchantedItems
        end,
        restartRequired = true,
        restartRequiredMessage = "Success!",
    })
    
end

local function getDefaultExclusionsCallback(filter, defaultItemIds)
    
    return function()
        
        local objectIds = {}
        
        for object in tes3.iterateObjects(filter) do
            if defaultItemIds[object.id] and common.shouldCacheItem(object) then
                table.insert(objectIds, object.id)
            end
        end
        
        table.sort(objectIds, util.sortFunction_ByStringKey)
        return objectIds
        
    end
    
end

local function getExclusionsCallback(filter)
    
    return function()
        
        local objectIds = {}
        
        for object in tes3.iterateObjects(filter) do
            if common.shouldCacheItem(object) then
                table.insert(objectIds, object.id)
            end
        end
        
        table.sort(objectIds, util.sortFunction_ByStringKey)
        return objectIds
        
    end
    
end

local function createMainBoundItemsPage(template, defaultMcmConfig)
    
    template:createExclusionsPage{
        label = "Bound Items",
        description = "Bound items are weightless. Bound armor is rebalanced using different rules.",
        leftListLabel = "Bound Items",
        rightListLabel = "Normal Items",
        variable = mwse.mcm.createTableVariable{
            table = mcmConfig.shared,
            id = "boundItemIds",
        },
        filters = {
            {
                label = "Defaults",
                callback = getDefaultExclusionsCallback(
                    {
                        tes3.objectType.armor,
                        tes3.objectType.weapon,
                        tes3.objectType.ammunition,
                    },
                    config.getDefaultMcmConfig().shared.boundItemIds)
            },
            {
                label = "Armor",
                callback = getExclusionsCallback(tes3.objectType.armor),
            },
            {
                label = "Weapons",
                callback = getExclusionsCallback({ tes3.objectType.weapon, tes3.objectType.ammunition }),
            },
        },
    }
    
end

local function createMainExcludedItemsPage(template, defaultMcmConfig)
    
    template:createExclusionsPage{
        label = "Excluded Items",
        description = "Excluded armor pieces might have their weight tweaked to ensure their weight class remains the same.",
        leftListLabel = "Excluded From Rebalance (Requires Restart)",
        rightListLabel = "Included In Rebalance (Requires Restart)",
        variable = mwse.mcm.createTableVariable{
            table = mcmConfig.shared,
            id = "excludedItemIds",
        },
        filters = {
            {
                label = "Defaults",
                callback = getDefaultExclusionsCallback(
                    {
                        tes3.objectType.armor,
                        tes3.objectType.clothing,
                        tes3.objectType.weapon,
                        tes3.objectType.ammunition,
                    },
                    config.getDefaultMcmConfig().shared.excludedItemIds)
            },
            {
                label = "Armor",
                callback = getExclusionsCallback(tes3.objectType.armor),
            },
            {
                label = "Clothing",
                callback = getExclusionsCallback(tes3.objectType.clothing),
            },
            {
                label = "Weapons",
                callback = getExclusionsCallback({ tes3.objectType.weapon, tes3.objectType.ammunition }),
            },
        },
    }
    
end

local function createMainHomePage(template, defaultMcmConfig)
    
    local page = template:createSideBarPage({ label = "Home" })
    
    page:createYesNoButton({
        label = "Mod Enabled",
        description =
            "No = Disables EVERYTHING in this mod."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.shared.modEnabled),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.shared,
            id = "modEnabled",
        }),
        restartRequired = true,
    })
    
    page:createYesNoButton({
        label = "Logging Enabled",
        description =
            "Yes = Debug messages will appear in the MWSE.log file located in your base Morrowind install directory."..
            "\n\nIf you got a \"Failed to rebalance...\" message when loading a game, set this to \"Yes\", reload the save, and then search for the word \"Failed\" in MWSE.log."..
            "\n\nThese errors are typically caused by an item not being able to determine its Tier or Subtype."..
            " If the problem is Tier, go to the \"Detect Tier by AR\" or \"Detect Tier by Damage\" tab and make sure each group has one slider set to max."..
            " If the problem is Subtype, go to the \"Detect Subtype\" tab and make sure each weapon type (e.g. 1H Short Blade) has one Speed slider set to max or one Range slider set to max."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.shared.loggingEnabled),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.shared,
            id = "loggingEnabled",
        }),
    })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createYesNoButton({
        label = "Armor Rebalance Enabled",
        description =
            "Yes = Updates the stats of every armor piece in the game according to the settings in the \"BYO Rebalance 2: Armor\" section."..
            " Any changes to those settings will come into effect when you load a save."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.armor.rebalanceEnabled),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.armor,
            id = "rebalanceEnabled",
        }),
        restartRequired = true,
    })
    
    page:createYesNoButton({
        label = "Unarmored Rebalance Enabled",
        description =
            "Yes = Changes the AR granted by the \"Unarmored\" skill (at skill level 100) to the value specified by the \"Unarmored AR\" setting found on the \"Home\" tab of the \"BYO Rebalance 2: Armor\" section."..
            " Any changes to that setting will come into effect when you load a save."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.unarmored.rebalanceEnabled),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.unarmored,
            id = "rebalanceEnabled",
        }),
        restartRequired = true,
    })
    
    page:createYesNoButton({
        label = "Clothing Rebalance Enabled",
        description =
            "Yes = Updates the stats of every clothing piece in the game according to the settings in the \"BYO Rebalance 3: Clothing\" section."..
            " Any changes to those settings will come into effect when you load a save."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.clothing.rebalanceEnabled),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.clothing,
            id = "rebalanceEnabled",
        }),
        restartRequired = true,
    })
    
    page:createYesNoButton({
        label = "Weapon Rebalance Enabled",
        description =
            "Yes = Updates the stats of every weapon in the game (including ammunition) according to the settings in the \"BYO Rebalance 4: Weapons\" section."..
            " Any changes to those settings will come into effect when you load a save."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.weapon.rebalanceEnabled),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.weapon,
            id = "rebalanceEnabled",
        }),
        restartRequired = true,
    })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createYesNoButton({
        label = "Fix Item Health Overflow",
        description =
            "Yes = If an item's current health is MORE than its max health, set its current health equal to its max health."..
            "\n\nThis fixes items that have had their max health DECREASED mid-playthrough."..
            " Items are only fixed when their cell is loaded, so you'll need to reload your save if you're changing this setting while in-game."..
            " There are no known downsides to leaving this set to \"Yes\" all the time."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.condition.fixItemHealthOverflow),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.condition,
            id = "fixItemHealthOverflow",
        }),
    })
    
    page:createYesNoButton({
        label = "Repair Damaged Items",
        description = 
            "Yes = If an item's current health is LESS than its max health, set its current health equal to its max health."..
            " This does not affect items in the player's inventory."..
            "\n\nThis fixes items that have had their max health INCREASED mid-playthrough, but has the side-effect of repairing ALL items you encounter."..
            " Items are only repaired when their cell is loaded, so you won't notice any weirdness most of the time."..
            " But if you leave damaged items somewhere and come back later (including reloading the game), those items will be repaired."..
            " I recommend you leave this set to \"No\" except for when you rebalance items mid-playthrough."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.condition.repairDamagedItems),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.condition,
            id = "repairDamagedItems",
        }),
    })
    
    page:createInfo({ text = "------------------------------" })
    
    page:createYesNoButton({
        label = "Detect Bound Items by Name",
        description =
            "Yes = If an item's name starts with the word \"Bound\" (followed by a space), it is considered to be a bound item."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.shared.detectBoundItemsByName),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.shared,
            id = "detectBoundItemsByName",
        }),
    })
    
    page:createYesNoButton({
        label = "Rebalance Custom-Enchanted Items",
        description =
            "Yes = Updates the stats of custom-enchanted items to match their unenchanted counterparts."..
            " This does not update item value, as that is affected by GMSTs that are not touched by this mod."..
            "\n\nThis mod determines which unenchanted item to use based on the custom-enchanted item's mesh and icon."..
            " This mod might pick the wrong unenchanted item when there are multiple unenchanted items with the same mesh and icon."..
            " I recommend you leave this set to \"No\" except for when you rebalance items mid-playthrough."..
            "\n\nIMPORTANT: Unlike all other items, changes to custom-enchanted item stats cannot be undone."..
            " These items can be rebalanced multiple times, but they will not revert to their original stats if this mod is disabled or uninstalled."..
            "\n\nDefault Value: " .. util.getYesNoString(defaultMcmConfig.shared.rebalanceCustomEnchantedItems),
        variable = mwse.mcm.createTableVariable({
            table = mcmConfig.shared,
            id = "rebalanceCustomEnchantedItems",
        }),
    })
    
end

local function onModConfigReady()
    
    local defaultMcmConfig = config.getDefaultMcmConfig()
    
    local mainTemplate = mwse.mcm.createTemplate({ name = "BYO Rebalance 1: Main" })
    mainTemplate.onClose = function() config.saveMcmConfig(mcmConfig) end
    mainTemplate:register()
    
    createMainHomePage(mainTemplate, defaultMcmConfig)
    createMainExcludedItemsPage(mainTemplate, defaultMcmConfig)
    createMainBoundItemsPage(mainTemplate, defaultMcmConfig)
    createMainRestoreDefaultsPage(mainTemplate, defaultMcmConfig)
    
    local armorTemplate = mwse.mcm.createTemplate({ name = "BYO Rebalance 2: Armor" })
    armorTemplate.onClose = function() config.saveMcmConfig(mcmConfig) end
    armorTemplate:register()
    
    createArmorHomePage(armorTemplate, defaultMcmConfig)
    createArmorSlotPage(armorTemplate, defaultMcmConfig)
    createArmorWeightClassPage(armorTemplate, defaultMcmConfig)
    createArmorTierPage(armorTemplate, defaultMcmConfig)
    createArmorDetectWeightClassBySearchTermPage(armorTemplate, defaultMcmConfig)
    createArmorDetectTierBySearchTermPage(armorTemplate, defaultMcmConfig)
    createArmorDetectTierByArmorRatingPage(armorTemplate, defaultMcmConfig)
    createArmorRestoreDefaultsPage(armorTemplate, defaultMcmConfig)
    
    local clothingTemplate = mwse.mcm.createTemplate({ name = "BYO Rebalance 3: Clothing" })
    clothingTemplate.onClose = function() config.saveMcmConfig(mcmConfig) end
    clothingTemplate:register()
    
    createClothingHomePage(clothingTemplate, defaultMcmConfig)
    createClothingSlotPage(clothingTemplate, defaultMcmConfig)
    createClothingTierPage(clothingTemplate, defaultMcmConfig)
    createClothingDetectTierBySearchTermPage(clothingTemplate, defaultMcmConfig)
    createClothingDetectTierByEnchantPage(clothingTemplate, defaultMcmConfig)
    createClothingRestoreDefaultsPage(clothingTemplate, defaultMcmConfig)
    
    local weaponTemplate = mwse.mcm.createTemplate({ name = "BYO Rebalance 4: Weapons" })
    weaponTemplate.onClose = function() config.saveMcmConfig(mcmConfig) end
    weaponTemplate:register()
    
    createWeaponHomePage(weaponTemplate, defaultMcmConfig)
    createWeaponSubtypePage(weaponTemplate, defaultMcmConfig)
    createWeaponWeightClassPage(weaponTemplate, defaultMcmConfig)
    createWeaponTierPage(weaponTemplate, defaultMcmConfig)
    createWeaponSubtypeCountPage(weaponTemplate, defaultMcmConfig)
    createWeaponSubtypeFlavorPage(weaponTemplate, defaultMcmConfig)
    createWeaponDetectSubtypePage(weaponTemplate, defaultMcmConfig)
    createWeaponDetectWeightClassBySearchTermPage(weaponTemplate, defaultMcmConfig)
    createWeaponDetectTierBySearchTermPage(weaponTemplate, defaultMcmConfig)
    createWeaponDetectTierByDamagePage(weaponTemplate, defaultMcmConfig)
    createWeaponRestoreDefaultsPage(weaponTemplate, defaultMcmConfig)
    
end

event.register(tes3.event.modConfigReady, onModConfigReady)
