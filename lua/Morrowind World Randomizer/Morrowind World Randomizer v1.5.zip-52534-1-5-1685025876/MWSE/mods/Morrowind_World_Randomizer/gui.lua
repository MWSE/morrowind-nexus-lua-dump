local this = {}

local EasyMCM = require("easyMCM.EasyMCM")

this.name = "Morrowind World Randomizer"

this.config = nil
this.funcs = nil
this.i18n = nil

this.data = nil

local profilesList = {}
local currentConfig
local updateProfileDropdown

function this.init(config, i18n, functions)
    this.config = config
    this.i18n = i18n
    this.funcs = functions

    for label, val in pairs(this.config.profiles) do
        table.insert(profilesList, {label = label, value = label})
    end
    currentConfig = profilesList[1].value
end

function this.hide()
    this.data.hidden = true
end

function this.show()
    this.data.hidden = false
end

local function createSettingsBlock_slider(varTable, varStr, varMul, min, max, step, labels)
    local slider = {
        class = "Slider",
        label = labels.label or "",
        description = labels.descr or "",
        min = min,
        max = max,
        step = step,
        jump = step * 10,
        inGameOnly = true,
        variable = EasyMCM.createVariable{
            get = function(self)
                if varTable ~= nil and varTable[varStr] ~= nil then
                    return varTable[varStr] * varMul
                end
                return min
            end,
            set = function(self, val)
                if varTable ~= nil and varTable[varStr] ~= nil then
                    varTable[varStr] = val / varMul
                end
            end,
        },
    }
    return slider
end

local function createSettingsBlock_minmaxp(varRegionTable, varStr, varMul, min, max, step, labels)
    local slider = {
        class = "Slider",
        label = labels.label or "",
        description = labels.descr or "",
        min = min,
        max = max,
        step = step,
        jump = step * 10,
        inGameOnly = true,
        variable = EasyMCM.createVariable{
            get = function(self)
                if varRegionTable ~= nil and varRegionTable[varStr] ~= nil then
                    return varRegionTable[varStr] * varMul
                end
                return min
            end,
            set = function(self, val)
                if varRegionTable ~= nil then
                    varRegionTable[varStr] = val / varMul
                    if varRegionTable.min > varRegionTable.max then
                        varRegionTable.max = varRegionTable.min
                    end
                end
            end,
        },
    }
    return slider
end

local function createSettingsBlock_region(varTable, labels)
    local slider = {
        class = "Slider",
        label = labels.label or "",
        description = labels.descr or "",
        min = 0,
        max = 200,
        step = 1,
        jump = 5,
        inGameOnly = true,
        variable = EasyMCM.createVariable{
            get = function(self)
                if varTable ~= nil then
                    return math.floor((varTable.max - -varTable.min) * 100 + 0.5)
                end
                return 0
            end,
            set = function(self, val)
                if varTable ~= nil then
                    local offset = (varTable.max - -varTable.min) / 2
                    varTable.min = varTable.min - offset + val / 200
                    varTable.max = varTable.max - offset + val / 200
                end
            end,
        },
    }
    return slider
end

local function createSettingsBlock_offset(varTable, labels)
    local slider = {
        class = "Slider",
        label = labels.label or "",
        description = labels.descr or "",
        min = -100,
        max = 100,
        step = 1,
        jump = 5,
        inGameOnly = true,
        variable = EasyMCM.createVariable{
            get = function(self)
                if varTable ~= nil then
                    return math.floor((-varTable.min + (varTable.max - -varTable.min) / 2) * 100  + 0.5)
                end
                return 0
            end,
            set = function(self, val)
                if varTable ~= nil then
                    local offset = -varTable.min + (varTable.max - -varTable.min) / 2
                    varTable.min = varTable.min + offset - val / 100
                    varTable.max = varTable.max - offset + val / 100
                end
            end,
        },
    }
    return slider
end

local function createOnOffIngameButton(label, varTable, varId, description)
    local data = {
        class = "OnOffButton",
        label = label,
        description = description,
        inGameOnly = true,
        variable = {
            id = varId,
            class = "TableVariable",
            table = varTable,
        },
    }
    return data
end

local function createOnOffIngameNegativeButton(label, varTable, varId, description)
    local data = {
        class = "OnOffButton",
        label = label,
        description = description,
        inGameOnly = true,
        variable = {
            class = "Variable",
            get = function(self)
                return not varTable[varId]
            end,
            set = function(self, val)
                varTable[varId] = not val
            end,
        },
    }
    return data
end

local function createText(label, description)
    return {
        class = "Info",
        label = label,
        text = description
    }
end

function this.registerModConfig()
    local data = {
        name = this.name,
        onClose = (function()
            this.config.save()
        end),
        pages = {
            {
                label = this.i18n("modConfig.label.mainPage"),
                class = "Page",
                components = {
                    {
                        class = "SideBySideBlock",
                        components = {
                            {
                                class = "OnOffButton",
                                label = this.i18n("modConfig.label.enableRandomizer"),
                                inGameOnly = true,
                                variable = {
                                    class = "Variable",
                                    get = function(self)
                                        return this.config.data.enabled
                                    end,
                                    set = function(self, val)
                                        this.config.data.enabled = val
                                        if val then
                                            this.funcs.randomizeLoadedCellsFunc()
                                        end
                                    end,
                                },
                            },
                            {
                                class = "Button",
                                buttonText = this.i18n("modConfig.label.randomizeLoadedCells"),
                                inGameOnly = true,
                                callback = function()
                                    this.funcs.randomizeLoadedCells(0, true, true)
                                end,
                            },
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.profiles"),
                        components = {
                            {
                                label = this.i18n("modConfig.label.createNewProfile"),
                                class = "TextField",
                                sNewValue = "",
                                inGameOnly = true,
                                variable = {
                                    class = "Variable",
                                    get = function(self)
                                        return ""
                                    end,
                                    set = function(self, val)
                                        local exists = false
                                        for i, profileVal in pairs(profilesList) do
                                            if profileVal.value == val then
                                                exists = true
                                                break
                                            end
                                        end
                                        if not exists then
                                            currentConfig = nil
                                            table.insert(profilesList, {label = val, value = val})
                                            if updateProfileDropdown then updateProfileDropdown() end
                                            this.config.saveCurrentProfile(val)
                                            this.config.saveProfiles()
                                            tes3.messageBox(this.i18n("modConfig.label.profileAdded"))
                                        else
                                            tes3.messageBox(this.i18n("modConfig.label.profileNotAdded"))
                                        end
                                    end,
                                },
                            },
                            {
                                class = "SideBySideBlock",
                                components = {
                                    {
                                        label = this.i18n("modConfig.label.selectProfile"),
                                        class = "Dropdown",
                                        inGameOnly = true,
                                        options = profilesList,
                                        postCreate = function(self)
                                            self:enable()
                                            updateProfileDropdown = function()
                                                self:enable()
                                            end
                                        end,
                                        variable = {
                                            class = "Variable",
                                            get = function(self)
                                                return ""
                                            end,
                                            set = function(self, val)
                                                for i, profileVal in pairs(profilesList) do
                                                    if profileVal.value == val then
                                                        currentConfig = profileVal
                                                        break
                                                    end
                                                end
                                            end,
                                        },
                                    },
                                    {
                                        class = "Category",
                                        label = "",
                                        components = {
                                            {
                                                class = "Button",
                                                buttonText = this.i18n("modConfig.label.load"),
                                                inGameOnly = true,
                                                callback = function()
                                                    if currentConfig then
                                                        if this.config.loadProfile(currentConfig.value) then
                                                            tes3.messageBox(this.i18n("modConfig.label.profileLoaded"))
                                                        else
                                                            tes3.messageBox(this.i18n("modConfig.label.profileNotLoaded"))
                                                        end
                                                    end
                                                end,
                                            },
                                            {
                                                class = "Button",
                                                buttonText = this.i18n("modConfig.label.delete"),
                                                inGameOnly = true,
                                                callback = function()
                                                    if currentConfig and not this.config.defaultProfileNames[currentConfig.value] then
                                                        for i, val in pairs(profilesList) do
                                                            if val.value == currentConfig.value then
                                                                this.config.deleteProfile(val.value)
                                                                this.config.saveProfiles()
                                                                table.remove(profilesList, i)
                                                            end
                                                        end
                                                        if updateProfileDropdown then updateProfileDropdown() end
                                                        currentConfig = nil
                                                    end
                                                end,
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                    createText(nil, this.i18n("modConfig.text.warningAboutRandomization"))
                },
            },
            {
                label = this.i18n("modConfig.label.globalPage"),
                class = "Page",
                components = {
                    {
                        label = this.i18n("modConfig.label.logging"),
                        class = "OnOffButton",
                        restartRequired = true,
                        variable = {
                            class = "TableVariable",
                            id = "logging",
                            table = this.config.global,
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.cellRandomization"),
                        components = {
                            {
                                class = "Slider",
                                label = this.i18n("modConfig.label.cellRandomizationIntervalRealTime"),
                                min = 0,
                                max = 1800,
                                step = 60,
                                jump = 300,
                                variable = {
                                    class = "TableVariable",
                                    id = "cellRandomizationCooldown",
                                    table = this.config.global,
                                },
                            },
                            {
                                class = "Slider",
                                label = this.i18n("modConfig.label.cellRandomizationIntervalGameTime"),
                                min = 0,
                                max = 336,
                                step = 1,
                                jump = 24,
                                variable = {
                                    class = "TableVariable",
                                    id = "cellRandomizationCooldown_gametime",
                                    table = this.config.global,
                                },
                            },
                        },
                    },
                    {
                        class = "OnOffButton",
                        label = this.i18n("modConfig.label.allowDoubleLoad"),
                        description = "",
                        variable = {
                            id = "allowDoubleLoading",
                            class = "TableVariable",
                            table = this.config.global,
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.pregeneratedDataTables"),
                        description = "",
                        components = {
                            {
                                label = this.i18n("modConfig.label.forceTTRData"),
                                class = "OnOffButton",
                                variable = {
                                    class = "Variable",
                                    get = function(self) return this.config.global.dataTables.forceTRData end,
                                    set = function(self, val)
                                        this.config.global.dataTables.forceTRData = val
                                        this.funcs.generateStaticFunc()
                                    end,
                                },
                            },
                            -- {
                            --     label = this.i18n("modConfig.label.pregeneratedItems"),
                            --     class = "OnOffButton",
                            --     variable = {
                            --         class = "Variable",
                            --         get = function(self) return this.config.global.dataTables.usePregeneratedItemData end,
                            --         set = function(self, val)
                            --             this.config.global.dataTables.usePregeneratedItemData = val
                            --             this.funcs.generateStaticFunc()
                            --         end,
                            --     },
                            -- },
                            -- {
                            --     label = this.i18n("modConfig.label.pregeneratedCreatures"),
                            --     class = "OnOffButton",
                            --     variable = {
                            --         class = "Variable",
                            --         get = function(self) return this.config.global.dataTables.usePregeneratedCreatureData end,
                            --         set = function(self, val)
                            --             this.config.global.dataTables.usePregeneratedCreatureData = val
                            --             this.funcs.generateStaticFunc()
                            --         end,
                            --     },
                            -- },
                            -- {
                            --     label = this.i18n("modConfig.label.pregeneratedHeadHair"),
                            --     class = "OnOffButton",
                            --     variable = {
                            --         class = "Variable",
                            --         get = function(self) return this.config.global.dataTables.usePregeneratedHeadHairData end,
                            --         set = function(self, val)
                            --             this.config.global.dataTables.usePregeneratedHeadHairData = val
                            --             this.funcs.generateStaticFunc()
                            --         end,
                            --     },
                            -- },
                            -- {
                            --     label = this.i18n("modConfig.label.pregeneratedSpells"),
                            --     class = "OnOffButton",
                            --     variable = {
                            --         class = "Variable",
                            --         get = function(self) return this.config.global.dataTables.usePregeneratedSpellData end,
                            --         set = function(self, val)
                            --             this.config.global.dataTables.usePregeneratedSpellData = val
                            --             this.funcs.generateStaticFunc()
                            --         end,
                            --     },
                            -- },
                            -- {
                            --     label = this.i18n("modConfig.label.pregeneratedHerbs"),
                            --     class = "OnOffButton",
                            --     variable = {
                            --         class = "Variable",
                            --         get = function(self) return this.config.global.dataTables.usePregeneratedHerbData end,
                            --         set = function(self, val)
                            --             this.config.global.dataTables.usePregeneratedHerbData = val
                            --             this.funcs.generateStaticFunc()
                            --         end,
                            --     },
                            -- },
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.landTextures"),
                        description = "",
                        components = {
                            {
                                label = this.i18n("modConfig.label.randomizationOfLandTextures"),
                                class = "OnOffButton",
                                description = this.i18n("modConfig.description.randomizationOfLandTextures"),
                                variable = {
                                    class = "Variable",
                                    get = function(self) return this.config.global.landscape.randomize end,
                                    set = function(self, val)
                                        this.config.global.landscape.randomize = val
                                        if val then
                                            this.funcs.genRandLandTextureInd()
                                            this.funcs.loadRandLandTextures()
                                        end
                                    end,
                                },
                            },
                            {
                                label = this.i18n("modConfig.label.randomizeLandTextureOnlyOnce"),
                                class = "OnOffButton",
                                variable = {
                                    class = "TableVariable",
                                    id = "randomizeOnlyOnce",
                                    table = this.config.global.landscape,
                                },
                            },
                            {
                                class = "Button",
                                buttonText = this.i18n("modConfig.label.rerandomizeLandTextures"),
                                callback = function()
                                    this.funcs.genRandLandTextureInd()
                                    this.funcs.loadRandLandTextures()
                                end,
                            },
                        },
                    },
                },
            },
            {
                label = this.i18n("modConfig.label.items"),
                class = "FilterPage",
                components = {
                    {
                        class = "OnOffButton",
                        label = this.i18n("modConfig.label.makeItemsUnique"),
                        description = this.i18n("modConfig.description.makeItemsUnique"),
                        inGameOnly = true,
                        variable = {
                            class = "Variable",
                            get = function(self)
                                return this.config.data.item.unique
                            end,
                            set = function(self, val)
                                local newVal = true
                                if not this.config.data.item.unique then
                                    newVal = true
                                    this.funcs.clearCellList()
                                end
                                this.config.data.item.unique = newVal
                            end,
                        },
                    },
                    {
                        label = this.i18n("modConfig.label.artifactsAsSeparate"),
                        class = "OnOffButton",
                        inGameOnly = true,
                        variable = {
                            class = "TableVariable",
                            id = "randomizeArtifactsAsSeparateCategory",
                            table = this.config.data.other,
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.randomizeItemInCont"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeItemInCont"), this.config.data.containers.items, "randomize"),
                            createSettingsBlock_region(this.config.data.containers.items.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.containers.items.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.randomizeItemWithoutCont"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeItemWithoutCont"), this.config.data.items, "randomize"),
                            createSettingsBlock_region(this.config.data.items.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.items.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.randomizeNPCItems"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeNPCItems"), this.config.data.NPCs.items, "randomize"),
                            createSettingsBlock_region(this.config.data.NPCs.items.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.NPCs.items.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.randomizeCreatureItems"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeCreatureItems"), this.config.data.creatures.items, "randomize"),
                            createSettingsBlock_region(this.config.data.creatures.items.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.creatures.items.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.randomizeSoulsInGems"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeSoulsInGems"), this.config.data.soulGems.soul, "randomize"),
                            createSettingsBlock_region(this.config.data.soulGems.soul.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.soulGems.soul.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.randomizeGold"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeGold"), this.config.data.gold, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.gold.region, "min", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.minMultiplier"),}),
                            createSettingsBlock_minmaxp(this.config.data.gold.region, "max", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.maxMultiplier"),}),
                        },
                    },
                },
            },
            {
                label = this.i18n("modConfig.label.itemStats"),
                class = "FilterPage",
                components = {
                    {
                        class = "OnOffButton",
                        label = this.i18n("modConfig.label.makeItemsUnique"),
                        description = this.i18n("modConfig.description.makeItemsUnique"),
                        inGameOnly = true,
                        variable = {
                            class = "Variable",
                            get = function(self)
                                return this.config.data.item.unique
                            end,
                            set = function(self, val)
                                local newVal = true
                                if not this.config.data.item.unique then
                                    newVal = true
                                    this.funcs.clearCellList()
                                end
                                this.config.data.item.unique = newVal
                            end,
                        },
                    },
                    createText(nil, this.i18n("modConfig.description.itemStatsGeneration")),
                    {
                        buttonText = this.i18n("modConfig.label.randomizeBaseItems"),
                        class = "Button",
                        inGameOnly = true,
                        callback = function()
                            this.funcs.randomizeBaseItems()
                        end,
                    },
                    {
                        class = "Category",
                        label = "",
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randItemMeshes"), this.config.data.item, "changeMesh"),
                            createOnOffIngameButton(this.i18n("modConfig.label.randItemParts"), this.config.data.item, "changeParts"),
                            createOnOffIngameButton(this.i18n("modConfig.label.linkMeshToParts"), this.config.data.item, "linkMeshToParts", this.i18n("modConfig.description.linkMeshToParts")),
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.itemStats"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeItemStats"), this.config.data.item.stats, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.item.stats.region, "min", 100, 10, 500, 1, {label = this.i18n("modConfig.label.minMultiplier"), description = this.i18n("modConfig.description.itemStatsRandValue")}),
                            createSettingsBlock_minmaxp(this.config.data.item.stats.region, "max", 100, 10, 500, 1, {label = this.i18n("modConfig.label.maxMultiplier"), description = this.i18n("modConfig.description.itemStatsRandValue")}),
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.weaponDamageStats"),
                                description = "",
                                components = {
                                    createSettingsBlock_minmaxp(this.config.data.item.stats.weapon.region, "min", 100, 10, 500, 1, {label = this.i18n("modConfig.label.minMultiplier"), description = this.i18n("modConfig.description.itemStatsRandValue")}),
                                    createSettingsBlock_minmaxp(this.config.data.item.stats.weapon.region, "max", 100, 10, 500, 1, {label = this.i18n("modConfig.label.maxMultiplier"), description = this.i18n("modConfig.description.itemStatsRandValue")}),
                                },
                            },
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.itemEnchantment"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeItemEnch"), this.config.data.item.enchantment, "randomize"),
                            createOnOffIngameNegativeButton(this.i18n("modConfig.label.randomizeEffectsFromScrolls"), this.config.data.item.enchantment, "exceptScrolls"),
                            createOnOffIngameNegativeButton(this.i18n("modConfig.label.randomizeEffectsFromAlchemy"), this.config.data.item.enchantment, "exceptAlchemy"),
                            createOnOffIngameNegativeButton(this.i18n("modConfig.label.randomizeEffectsFromIngredient"), this.config.data.item.enchantment, "exceptIngredient"),
                            createOnOffIngameButton(this.i18n("modConfig.label.useExistingEnch"), this.config.data.item.enchantment, "useExisting"),
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.existedEnchValue"),
                                description = "",
                                components = {
                                    createSettingsBlock_region(this.config.data.item.enchantment.existing.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                                    createSettingsBlock_offset(this.config.data.item.enchantment.existing.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                                },
                            },
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.newEnchPower"),
                                description = "",
                                components = {
                                    createSettingsBlock_minmaxp(this.config.data.item.enchantment.region, "min", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.minMultiplier"), description = this.i18n("modConfig.description.itemStatsRandEnch")}),
                                    createSettingsBlock_minmaxp(this.config.data.item.enchantment.region, "max", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.maxMultiplier"), description = this.i18n("modConfig.description.itemStatsRandEnch")}),
                                    createSettingsBlock_slider(this.config.data.item.enchantment, "arrowPower", 100, 1, 300, 1, {label = this.i18n("modConfig.label.arrowPower")}),
                                },
                            },
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.numberOfEnchCasts"),
                                description = "",
                                components = {
                                    createSettingsBlock_minmaxp(this.config.data.item.enchantment.numberOfCasts, "min", 1, 1, 50, 1, {label = this.i18n("modConfig.label.minVal"),}),
                                    createSettingsBlock_minmaxp(this.config.data.item.enchantment.numberOfCasts, "max", 1, 1, 50, 1, {label = this.i18n("modConfig.label.maxVal"),}),
                                },
                            },
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.enchCost"),
                                description = "",
                                components = {
                                    createSettingsBlock_minmaxp(this.config.data.item.enchantment.cost, "min", 1, 1, 100, 1, {label = this.i18n("modConfig.label.minVal"),}),
                                    createSettingsBlock_minmaxp(this.config.data.item.enchantment.cost, "max", 1, 1, 5000, 1, {label = this.i18n("modConfig.label.maxVal"),}),
                                    createSettingsBlock_slider(this.config.data.item.enchantment, "scrollBase", 1, 1, 400, 1, {label = this.i18n("modConfig.label.scrollEnchCapacity")}),
                                },
                            },
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.enchEffects"),
                                description = "",
                                components = {
                                    createSettingsBlock_slider(this.config.data.item.enchantment.effects, "maxDuration", 1, 1, 200, 1, {label = this.i18n("modConfig.label.maxEnchEffectDuration")}),
                                    createSettingsBlock_slider(this.config.data.item.enchantment.effects, "maxRadius", 1, 1, 200, 1, {label = this.i18n("modConfig.label.maxEnchEffectRadius")}),
                                    createSettingsBlock_slider(this.config.data.item.enchantment.effects, "maxMagnitude", 1, 1, 500, 1, {label = this.i18n("modConfig.label.maxEnchEffectMagnitude")}),
                                    createSettingsBlock_slider(this.config.data.item.enchantment.effects, "durationForConstant", 1, 10, 500, 1, {label = this.i18n("modConfig.label.durationForConstant"), description = this.i18n("modConfig.description.durationForConstant")}),
                                    createSettingsBlock_slider(this.config.data.item.enchantment.effects, "fortifyForSelfChance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.fortifyForSelfChance")}),
                                    createSettingsBlock_slider(this.config.data.item.enchantment.effects, "damageForTargetChance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.damageForTargetChance")}),
                                    createSettingsBlock_slider(this.config.data.item.enchantment.effects, "restoreForAlchemyChance", 100, 0, 50, 1, {label = this.i18n("modConfig.label.restoreForAlchemyChance")}),
                                    {
                                        class = "Category",
                                        label = this.i18n("modConfig.label.itemEnchantment"),
                                        description = "",
                                        components = {
                                            createOnOffIngameButton(this.i18n("modConfig.label.safeEnchantmentForConstant"), this.config.data.item.enchantment.effects, "safeMode"),
                                            createSettingsBlock_slider(this.config.data.item.enchantment.effects, "oneTypeChance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.oneEnchTypeChance")}),
                                            createSettingsBlock_slider(this.config.data.item.enchantment.effects, "maxCount", 1, 1, 8, 1, {label = this.i18n("modConfig.label.maxEnchEffCount")}),
                                            createSettingsBlock_slider(this.config.data.item.enchantment.effects, "chanceToNegative", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToNegativeEffectForConstant")}),
                                            createSettingsBlock_slider(this.config.data.item.enchantment.effects, "chanceToNegativeForTarget", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToNegativeEffectForTarget")}),
                                        },
                                    },
                                    {
                                        class = "Category",
                                        label = this.i18n("modConfig.label.potionEffNum"),
                                        description = "",
                                        components = {
                                            createSettingsBlock_minmaxp(this.config.data.item.enchantment.effects.alchemyCount, "min", 1, 1, 4, 1, {label = this.i18n("modConfig.label.minVal"),}),
                                            createSettingsBlock_minmaxp(this.config.data.item.enchantment.effects.alchemyCount, "max", 1, 1, 4, 1, {label = this.i18n("modConfig.label.maxVal"),}),
                                        },
                                    },
                                    {
                                        class = "Category",
                                        label = this.i18n("modConfig.label.ingredientEffNum"),
                                        description = "",
                                        components = {
                                            createSettingsBlock_minmaxp(this.config.data.item.enchantment.effects.ingredient.count, "min", 1, 1, 4, 1, {label = this.i18n("modConfig.label.minVal"),}),
                                            createSettingsBlock_minmaxp(this.config.data.item.enchantment.effects.ingredient.count, "max", 1, 1, 4, 1, {label = this.i18n("modConfig.label.maxVal"),}),
                                        },
                                    },
                                },
                            },
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.addNewEnch"),
                                description = "",
                                components = {
                                    createOnOffIngameButton(this.i18n("modConfig.label.dontAddToScrolls"), this.config.data.item.enchantment.add, "exceptScrolls"),
                                    createSettingsBlock_slider(this.config.data.item.enchantment.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceAddEnchantment")}),
                                    {
                                        class = "Category",
                                        label = this.i18n("modConfig.label.addedEnchPower"),
                                        description = "",
                                        components = {
                                            createSettingsBlock_minmaxp(this.config.data.item.enchantment.add.region, "min", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.minMultiplier"), description = this.i18n("modConfig.description.itemStatsRandEnch")}),
                                            createSettingsBlock_minmaxp(this.config.data.item.enchantment.add.region, "max", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.maxMultiplier"), description = this.i18n("modConfig.description.itemStatsRandEnch")}),
                                        },
                                    },
                                },
                            },
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.removeEnch"),
                                description = "",
                                components = {
                                    createOnOffIngameButton(this.i18n("modConfig.label.dontRemoveFromScrolls"), this.config.data.item.enchantment.remove, "exceptScrolls"),
                                    createSettingsBlock_slider(this.config.data.item.enchantment.remove, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceRemoveEnchantment")}),
                                },
                            },
                        },
                    },
                },
            },
            {
                label = this.i18n("modConfig.label.creatures"),
                class = "FilterPage",
                components = {
                    createOnOffIngameButton(this.i18n("modConfig.label.randomizeCreatureOnlyOnce"), this.config.data.creatures, "randomizeOnlyOnce", this.i18n("modConfig.description.willBeAppliedAfterNext").."\n\n"..this.i18n("modConfig.description.randomizeCellOnlyOnce")),
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.creatures"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeCreatures"), this.config.data.creatures, "randomize"),
                            createSettingsBlock_region(this.config.data.creatures.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.creatures.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.items"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeItems"), this.config.data.creatures.items, "randomize"),
                            createSettingsBlock_region(this.config.data.creatures.items.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.creatures.items.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.health"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeHealth"), this.config.data.creatures.health, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.creatures.health.region, "min", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.minMultiplier"),}),
                            createSettingsBlock_minmaxp(this.config.data.creatures.health.region, "max", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.maxMultiplier"),}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.magicka"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeMagicka"), this.config.data.creatures.magicka, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.creatures.magicka.region, "min", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.minMultiplier"),}),
                            createSettingsBlock_minmaxp(this.config.data.creatures.magicka.region, "max", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.maxMultiplier"),}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.fatigue"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeFatigue"), this.config.data.creatures.fatigue, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.creatures.fatigue.region, "min", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.minMultiplier"),}),
                            createSettingsBlock_minmaxp(this.config.data.creatures.fatigue.region, "max", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.maxMultiplier"),}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.attackDamage"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeDamage"), this.config.data.creatures.attack, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.creatures.attack.region, "min", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.minMultiplier"),}),
                            createSettingsBlock_minmaxp(this.config.data.creatures.attack.region, "max", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.maxMultiplier"),}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.scale"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeScale"), this.config.data.creatures.scale, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.creatures.scale.region, "min", 100, 10, 1000, 1, {label = this.i18n("modConfig.label.minMultiplier"),}),
                            createSettingsBlock_minmaxp(this.config.data.creatures.scale.region, "max", 100, 10, 1000, 1, {label = this.i18n("modConfig.label.maxMultiplier"),}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.skills"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeSkills"), this.config.data.creatures.skills, "randomize"),
                            createSettingsBlock_slider(this.config.data.creatures.skills, "limit", 1, 1, 255, 1, {label = this.i18n("modConfig.label.maxValueOfSkill")}),

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.combatSkills"),
                                description = "",
                                components = {
                                    createSettingsBlock_region(this.config.data.creatures.skills.combat.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                                    createSettingsBlock_offset(this.config.data.creatures.skills.combat.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                                },
                            },

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.magicSkills"),
                                description = "",
                                components = {
                                    createSettingsBlock_region(this.config.data.creatures.skills.magic.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                                    createSettingsBlock_offset(this.config.data.creatures.skills.magic.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                                },
                            },

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.stealthSkills"),
                                description = "",
                                components = {
                                    createSettingsBlock_region(this.config.data.creatures.skills.stealth.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                                    createSettingsBlock_offset(this.config.data.creatures.skills.stealth.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                                },
                            },
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.AI"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeAIFight"), this.config.data.creatures.ai.fight, "randomize"),
                            createSettingsBlock_region(this.config.data.creatures.ai.fight.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.creatures.ai.fight.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),

                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeAIFlee"), this.config.data.creatures.ai.flee, "randomize"),
                            createSettingsBlock_region(this.config.data.creatures.ai.flee.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.creatures.ai.flee.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),

                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeAIAlarm"), this.config.data.creatures.ai.alarm, "randomize"),
                            createSettingsBlock_region(this.config.data.creatures.ai.alarm.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.creatures.ai.alarm.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),

                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeAIHello"), this.config.data.creatures.ai.hello, "randomize"),
                            createSettingsBlock_region(this.config.data.creatures.ai.hello.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.creatures.ai.hello.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.spells"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeSpells"), this.config.data.creatures.spells, "randomize"),
                            createSettingsBlock_region(this.config.data.creatures.spells.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.creatures.spells.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.addNewSpells"),
                                description = "",
                                components = {
                                    createSettingsBlock_slider(this.config.data.creatures.spells.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd"), descr = this.i18n("modConfig.description.chanceToAddSpell")}),
                                    createSettingsBlock_slider(this.config.data.creatures.spells.add, "count", 1, 0, 50, 1, {label = this.i18n("modConfig.label.addXMore")}),
                                    createSettingsBlock_slider(this.config.data.creatures.spells.add, "levelReference", 1, 1, 50, 1, {label = this.i18n("modConfig.label.levelLimiter"), descr = this.i18n("modConfig.description.listLimiter")}),
                                },
                            },
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.abilities"),
                        description = this.i18n("modConfig.description.abilitiesCategory"),
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeAbilities"), this.config.data.creatures.abilities, "randomize"),
                            createSettingsBlock_region(this.config.data.creatures.abilities.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.creatures.abilities.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.addNewAbilities"),
                                description = "",
                                components = {
                                    createSettingsBlock_slider(this.config.data.creatures.abilities.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd"), descr = this.i18n("modConfig.description.chanceToAddAbility")}),
                                    createSettingsBlock_slider(this.config.data.creatures.abilities.add, "count", 1, 0, 50, 1, {label = this.i18n("modConfig.label.addXMore")}),
                                },
                            },
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.diseases"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeDiseases"), this.config.data.creatures.diseases, "randomize"),
                            createSettingsBlock_region(this.config.data.creatures.diseases.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.creatures.diseases.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.addNewDiseases"),
                                description = "",
                                components = {
                                    createSettingsBlock_slider(this.config.data.creatures.diseases.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd"), descr = this.i18n("modConfig.description.chanceToAddDisease")}),
                                    createSettingsBlock_slider(this.config.data.creatures.diseases.add, "count", 1, 0, 50, 1, {label = this.i18n("modConfig.label.addXMore")}),
                                },
                            },
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.addNewEffects"),
                        description = "",
                        components = {
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.positiveEffects"),
                                description = this.i18n("modConfig.description.positiveEffects"),
                                components = {
                                    createSettingsBlock_slider(this.config.data.creatures.effects.positive.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd"), descr = this.i18n("modConfig.description.chanceToAddEffect")}),
                                    createSettingsBlock_slider(this.config.data.creatures.effects.positive.add, "count", 1, 0, 10, 1, {label = this.i18n("modConfig.label.addXMore")}),

                                    createSettingsBlock_minmaxp(this.config.data.creatures.effects.positive.add.region, "min", 1, 0, 100, 1, {label = this.i18n("modConfig.label.minEffectVal"),}),
                                    createSettingsBlock_minmaxp(this.config.data.creatures.effects.positive.add.region, "max", 1, 0, 100, 1, {label = this.i18n("modConfig.label.maxEffectVal"),}),
                                },
                            },

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.negativeEffects"),
                                description = this.i18n("modConfig.description.negativeEffects"),
                                components = {
                                    createSettingsBlock_slider(this.config.data.creatures.effects.negative.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd"), descr = this.i18n("modConfig.description.chanceToAddEffect")}),
                                    createSettingsBlock_slider(this.config.data.creatures.effects.negative.add, "count", 1, 0, 10, 1, {label = this.i18n("modConfig.label.addXMore")}),

                                    createSettingsBlock_minmaxp(this.config.data.creatures.effects.negative.add.region, "min", 1, 0, 100, 1, {label = this.i18n("modConfig.label.minEffectVal"),}),
                                    createSettingsBlock_minmaxp(this.config.data.creatures.effects.negative.add.region, "max", 1, 0, 100, 1, {label = this.i18n("modConfig.label.maxEffectVal"),}),
                                },
                            },
                        },
                    },
                },
            },
            {
                label = this.i18n("modConfig.label.NPCs"),
                class = "FilterPage",
                components = {
                    createOnOffIngameButton(this.i18n("modConfig.label.randomizeNPCOnlyOnce"), this.config.data.NPCs, "randomizeOnlyOnce", this.i18n("modConfig.description.willBeAppliedAfterNext").."\n\n"..this.i18n("modConfig.description.randomizeCellOnlyOnce")),
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.items"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeItems"), this.config.data.NPCs.items, "randomize"),
                            createSettingsBlock_region(this.config.data.NPCs.items.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.NPCs.items.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.health"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeHealth"), this.config.data.NPCs.health, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.NPCs.health.region, "min", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.minMultiplier"),}),
                            createSettingsBlock_minmaxp(this.config.data.NPCs.health.region, "max", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.maxMultiplier"),}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.magicka"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeMagicka"), this.config.data.NPCs.magicka, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.NPCs.magicka.region, "min", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.minMultiplier"),}),
                            createSettingsBlock_minmaxp(this.config.data.NPCs.magicka.region, "max", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.maxMultiplier"),}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.fatigue"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeFatigue"), this.config.data.NPCs.fatigue, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.NPCs.fatigue.region, "min", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.minMultiplier"),}),
                            createSettingsBlock_minmaxp(this.config.data.NPCs.fatigue.region, "max", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.maxMultiplier"),}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.scale"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeScale"), this.config.data.NPCs.scale, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.NPCs.scale.region, "min", 100, 10, 1000, 1, {label = this.i18n("modConfig.label.minMultiplier"),}),
                            createSettingsBlock_minmaxp(this.config.data.NPCs.scale.region, "max", 100, 10, 1000, 1, {label = this.i18n("modConfig.label.maxMultiplier"),}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.head"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeHead"), this.config.data.NPCs.head, "randomize"),
                            createOnOffIngameButton(this.i18n("modConfig.label.limitByRace"), this.config.data.NPCs.head, "raceLimit"),
                            createOnOffIngameButton(this.i18n("modConfig.label.limitByGender"), this.config.data.NPCs.head, "genderLimit"),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.hairs"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeHair"), this.config.data.NPCs.hair, "randomize"),
                            createOnOffIngameButton(this.i18n("modConfig.label.limitByRace"), this.config.data.NPCs.hair, "raceLimit"),
                            createOnOffIngameButton(this.i18n("modConfig.label.limitByGender"), this.config.data.NPCs.hair, "genderLimit"),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.skills"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeSkills"), this.config.data.NPCs.skills, "randomize"),
                            createSettingsBlock_slider(this.config.data.NPCs.skills, "limit", 1, 1, 255, 1, {label = this.i18n("modConfig.label.maxValueOfSkill")}),

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.combatSkills"),
                                description = "",
                                components = {
                                    createSettingsBlock_region(this.config.data.NPCs.skills.combat.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                                    createSettingsBlock_offset(this.config.data.NPCs.skills.combat.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                                },
                            },

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.magicSkills"),
                                description = "",
                                components = {
                                    createSettingsBlock_region(this.config.data.NPCs.skills.magic.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                                    createSettingsBlock_offset(this.config.data.NPCs.skills.magic.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                                },
                            },

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.stealthSkills"),
                                description = "",
                                components = {
                                    createSettingsBlock_region(this.config.data.NPCs.skills.stealth.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                                    createSettingsBlock_offset(this.config.data.NPCs.skills.stealth.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                                },
                            },
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.attributes"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeAttributes"), this.config.data.NPCs.attributes, "randomize"),
                            createSettingsBlock_slider(this.config.data.NPCs.attributes, "limit", 1, 1, 255, 1, {label = this.i18n("modConfig.label.maxValueOfAttribute")}),

                            createSettingsBlock_minmaxp(this.config.data.NPCs.attributes.region, "min", 100, 0, 100, 1, {label = this.i18n("modConfig.label.minAttributeVal"),}),
                            createSettingsBlock_minmaxp(this.config.data.NPCs.attributes.region, "max", 100, 0, 100, 1, {label = this.i18n("modConfig.label.maxAttributeVal"),}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.AI"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeAIFight"), this.config.data.NPCs.ai.fight, "randomize"),
                            createSettingsBlock_region(this.config.data.NPCs.ai.fight.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.NPCs.ai.fight.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),

                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeAIFlee"), this.config.data.NPCs.ai.flee, "randomize"),
                            createSettingsBlock_region(this.config.data.NPCs.ai.flee.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.NPCs.ai.flee.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),

                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeAIAlarm"), this.config.data.NPCs.ai.alarm, "randomize"),
                            createSettingsBlock_region(this.config.data.NPCs.ai.alarm.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.NPCs.ai.alarm.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),

                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeAIHello"), this.config.data.NPCs.ai.hello, "randomize"),
                            createSettingsBlock_region(this.config.data.NPCs.ai.hello.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.NPCs.ai.hello.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.spells"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeSpells"), this.config.data.NPCs.spells, "randomize"),
                            createSettingsBlock_region(this.config.data.NPCs.spells.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.NPCs.spells.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.addNewSpells"),
                                description = "",
                                components = {
                                    createSettingsBlock_slider(this.config.data.NPCs.spells.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd"), descr = this.i18n("modConfig.description.chanceToAddSpell")}),
                                    createSettingsBlock_slider(this.config.data.NPCs.spells.add, "count", 1, 0, 50, 1, {label = this.i18n("modConfig.label.addXMore")}),
                                    createSettingsBlock_slider(this.config.data.NPCs.spells.add, "levelReference", 1, 1, 50, 1, {label = this.i18n("modConfig.label.levelLimiter"), descr = this.i18n("modConfig.description.listLimiter")}),
                                },
                            },
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.abilities"),
                        description = this.i18n("modConfig.description.abilitiesCategory"),
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeAbilities"), this.config.data.NPCs.abilities, "randomize"),
                            createSettingsBlock_region(this.config.data.NPCs.abilities.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.NPCs.abilities.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.addNewAbilities"),
                                description = "",
                                components = {
                                    createSettingsBlock_slider(this.config.data.NPCs.abilities.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd"), descr = this.i18n("modConfig.description.chanceToAddAbility")}),
                                    createSettingsBlock_slider(this.config.data.NPCs.abilities.add, "count", 1, 0, 50, 1, {label = this.i18n("modConfig.label.addXMore")}),
                                },
                            },
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.diseases"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeDiseases"), this.config.data.NPCs.diseases, "randomize"),
                            createSettingsBlock_region(this.config.data.NPCs.diseases.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.NPCs.diseases.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.addNewDiseases"),
                                description = "",
                                components = {
                                    createSettingsBlock_slider(this.config.data.NPCs.diseases.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd"), descr = this.i18n("modConfig.description.chanceToAddDisease")}),
                                    createSettingsBlock_slider(this.config.data.NPCs.diseases.add, "count", 1, 0, 50, 1, {label = this.i18n("modConfig.label.addXMore")}),
                                },
                            },
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.addNewEffects"),
                        description = "",
                        components = {
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.positiveEffects"),
                                description = this.i18n("modConfig.description.positiveEffects"),
                                components = {
                                    createSettingsBlock_slider(this.config.data.NPCs.effects.positive.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd"), descr = this.i18n("modConfig.description.chanceToAddEffect")}),
                                    createSettingsBlock_slider(this.config.data.NPCs.effects.positive.add, "count", 1, 0, 10, 1, {label = this.i18n("modConfig.label.addXMore")}),

                                    createSettingsBlock_minmaxp(this.config.data.NPCs.effects.positive.add.region, "min", 1, 0, 100, 1, {label = this.i18n("modConfig.label.minEffectVal"),}),
                                    createSettingsBlock_minmaxp(this.config.data.NPCs.effects.positive.add.region, "max", 1, 0, 100, 1, {label = this.i18n("modConfig.label.maxEffectVal"),}),
                                },
                            },

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.negativeEffects"),
                                description = this.i18n("modConfig.description.negativeEffects"),
                                components = {
                                    createSettingsBlock_slider(this.config.data.NPCs.effects.negative.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd"), descr = this.i18n("modConfig.description.chanceToAddEffect")}),
                                    createSettingsBlock_slider(this.config.data.NPCs.effects.negative.add, "count", 1, 0, 10, 1, {label = this.i18n("modConfig.label.addXMore")}),

                                    createSettingsBlock_minmaxp(this.config.data.NPCs.effects.negative.add.region, "min", 1, 0, 100, 1, {label = this.i18n("modConfig.label.minEffectVal"),}),
                                    createSettingsBlock_minmaxp(this.config.data.NPCs.effects.negative.add.region, "max", 1, 0, 100, 1, {label = this.i18n("modConfig.label.maxEffectVal"),}),
                                },
                            },
                        },
                    },
                },
            },
            {
                label = this.i18n("modConfig.label.barterTransport"),
                class = "FilterPage",
                components = {
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.barterGold"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeMerchantGold"), this.config.data.barterGold, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.barterGold.region, "min", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.minMultiplier"),}),
                            createSettingsBlock_minmaxp(this.config.data.barterGold.region, "max", 100, 0, 1000, 1, {label = this.i18n("modConfig.label.maxMultiplier"),}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.transport"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeTransport"), this.config.data.transport, "randomize"),
                            createSettingsBlock_slider(this.config.data.transport, "unrandomizedCount", 1, 0, 4, 1, {label = this.i18n("modConfig.label.numOfDestinationsWithoutRand")}),
                            createSettingsBlock_slider(this.config.data.transport, "toDoorsCount", 1, 0, 4, 1, {label = this.i18n("modConfig.label.numOfDestinationsToDoor")}),
                        },
                    },
                },
            },
            {
                label = this.i18n("modConfig.label.containers"),
                class = "FilterPage",
                components = {
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.items"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeItemInCont"), this.config.data.containers.items, "randomize"),
                            createSettingsBlock_region(this.config.data.containers.items.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.containers.items.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.locks"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeLock"), this.config.data.containers.lock, "randomize"),
                            createSettingsBlock_region(this.config.data.containers.lock.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.containers.lock.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.addLock"),
                                description = "",
                                components = {
                                    createSettingsBlock_slider(this.config.data.containers.lock.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToLock")}),
                                    createSettingsBlock_slider(this.config.data.containers.lock.add, "levelMultiplier", 1, 0, 100, 1, {label = this.i18n("modConfig.label.lockLevMul"), descr = this.i18n("modConfig.description.lockLevMul")}),
                                },
                            },
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.traps"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeTrap"), this.config.data.containers.trap, "randomize"),
                            createSettingsBlock_region(this.config.data.containers.trap.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.containers.trap.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.addTrap"),
                                description = "",
                                components = {
                                    createSettingsBlock_slider(this.config.data.containers.trap.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd")}),
                                    createSettingsBlock_slider(this.config.data.containers.trap.add, "levelMultiplier", 1, 0, 100, 1, {label = this.i18n("modConfig.label.maxValMulOfTrapSpell"), descr = this.i18n("modConfig.description.trapSpellListSize")}),
                                    createOnOffIngameButton(this.i18n("modConfig.label.useOnlyDestruction"), this.config.data.containers.trap.add, "onlyDestructionSchool"),
                                },
                            },
                        },
                    },
                },
            },
            {
                label = this.i18n("modConfig.label.doors"),
                class = "FilterPage",
                components = {
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.destination"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeDoors"), this.config.data.doors, "randomize"),
                            createSettingsBlock_slider(this.config.data.doors, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToRandomize")}),
                            createSettingsBlock_slider(this.config.data.doors, "cooldown", 1, 0, 500, 1, {label = this.i18n("modConfig.label.cooldownGameHours")}),
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeDoorsWhenCellLoading"), this.config.data.doors, "onlyOnCellRandomization"),
                            createOnOffIngameButton(this.i18n("modConfig.label.doNotRandomizeInToIn"), this.config.data.doors, "doNotRandomizeInToIn"),
                            {
                                class = "Category",
                                label = "",
                                description = "",
                                components = {
                                    createOnOffIngameButton(this.i18n("modConfig.label.randomizeOnlyToNearestDoors"), this.config.data.doors, "onlyNearest"),
                                    createSettingsBlock_slider(this.config.data.doors, "nearestCellDepth", 1, 1, 10, 1, {label = this.i18n("modConfig.label.radiusInCellsForCell")}),
                                    {
                                        class = "Category",
                                        label = this.i18n("modConfig.label.smartAlgorithm"),
                                        description = "",
                                        components = {
                                            createOnOffIngameButton(this.i18n("modConfig.label.smartDoorRandomizer"), this.config.data.doors.smartInToInRandomization, "enabled", this.i18n("modConfig.description.smartDoorRandomizer")),
                                            createOnOffIngameButton(this.i18n("modConfig.label.tryToRandBothDoors"), this.config.data.doors.smartInToInRandomization, "backDoorMode", this.i18n("modConfig.description.smartDoorRandomizer")),
                                        },
                                    },
                                },
                            },
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.locks"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeLock"), this.config.data.doors.lock, "randomize"),
                            createSettingsBlock_region(this.config.data.doors.lock.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.doors.lock.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.addLock"),
                                description = "",
                                components = {
                                    createSettingsBlock_slider(this.config.data.doors.lock.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToLock")}),
                                    createSettingsBlock_slider(this.config.data.doors.lock.add, "levelMultiplier", 1, 0, 100, 1, {label = this.i18n("modConfig.label.lockLevMul"), descr = this.i18n("modConfig.description.lockLevMul")}),
                                },
                            },
                            {
                                class = "Category",
                                label = "",
                                description = "",
                                components = {
                                    createOnOffIngameButton(this.i18n("modConfig.label.doNotLockIfNoEnemy"), this.config.data.doors.lock.safeCellMode, "enabled"),
                                    createSettingsBlock_slider(this.config.data.doors.lock.safeCellMode, "fightValue", 1, 0, 100, 1, {label = this.i18n("modConfig.label.minFightToBeEnemy")}),
                                },
                            },
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.traps"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeTrap"), this.config.data.doors.trap, "randomize"),
                            createSettingsBlock_region(this.config.data.doors.trap.region, {label = this.i18n("modConfig.label.regionSize"), descr = this.i18n("modConfig.description.region")}),
                            createSettingsBlock_offset(this.config.data.doors.trap.region, {label = this.i18n("modConfig.label.regionOffset"), descr = this.i18n("modConfig.description.region")}),
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.addTrap"),
                                description = "",
                                components = {
                                    createSettingsBlock_slider(this.config.data.doors.trap.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd")}),
                                    createSettingsBlock_slider(this.config.data.doors.trap.add, "levelMultiplier", 1, 0, 100, 1, {label = this.i18n("modConfig.label.maxValMulOfTrapSpell"), descr = this.i18n("modConfig.description.trapSpellListSize")}),
                                    createOnOffIngameButton(this.i18n("modConfig.label.useOnlyDestruction"), this.config.data.doors.trap.add, "onlyDestructionSchool"),
                                },
                            },
                            {
                                class = "Category",
                                label = "",
                                description = "",
                                components = {
                                    createOnOffIngameButton(this.i18n("modConfig.label.doNotTrapIfNoEnemy"), this.config.data.doors.trap.safeCellMode, "enabled"),
                                    createSettingsBlock_slider(this.config.data.doors.trap.safeCellMode, "fightValue", 1, 0, 100, 1, {label = this.i18n("modConfig.label.minFightToBeEnemy")}),
                                },
                            },
                        },
                    },
                },
            },
            {
                label = this.i18n("modConfig.label.world"),
                class = "FilterPage",
                components = {
                    createOnOffIngameButton(this.i18n("modConfig.label.randomizeCellOnlyOnce"), this.config.data.cells, "randomizeOnlyOnce"),
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.landTextures"),
                        description = "",
                        components = {
                            {
                                label = this.i18n("modConfig.label.randomizationOfLandTextures"),
                                class = "OnOffButton",
                                description = this.i18n("modConfig.description.randomizationOfLandTextures"),
                                variable = {
                                    class = "Variable",
                                    get = function(self) return this.config.global.landscape.randomize end,
                                    set = function(self, val)
                                        this.config.global.landscape.randomize = val
                                        if val then
                                            this.funcs.genRandLandTextureInd()
                                            this.funcs.loadRandLandTextures()
                                        end
                                    end,
                                },
                            },
                            {
                                label = this.i18n("modConfig.label.randomizeLandTextureOnlyOnce"),
                                class = "OnOffButton",
                                variable = {
                                    class = "TableVariable",
                                    id = "randomizeOnlyOnce",
                                    table = this.config.global.landscape,
                                },
                            },
                            {
                                class = "Button",
                                buttonText = this.i18n("modConfig.label.rerandomizeLandTextures"),
                                callback = function()
                                    this.funcs.genRandLandTextureInd()
                                    this.funcs.loadRandLandTextures()
                                end,
                            },
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.globalPage"),
                        description = "",
                        components = {
                            {
                                label = this.i18n("modConfig.label.disableDistantLand"),
                                class = "OnOffButton",
                                inGameOnly = true,
                                variable = {
                                    class = "Variable",
                                    get = function(self) return this.config.data.other.disableMGEDistantLand end,
                                    set = function(self, val)
                                        this.config.data.other.disableMGEDistantLand = val
                                        if mge.enabled() and this.config.data.other.disableMGEDistantLand then
                                            mge.render.distantStatics = false
                                            mge.render.distantLand = false
                                            mge.render.distantWater = false
                                        end
                                    end,
                                },
                            },
                            {
                                label = this.i18n("modConfig.label.disableDistantStatics"),
                                class = "OnOffButton",
                                inGameOnly = true,
                                variable = {
                                    class = "Variable",
                                    get = function(self) return this.config.data.other.disableMGEDistantStatics end,
                                    set = function(self, val)
                                        this.config.data.other.disableMGEDistantStatics = val
                                        if mge.enabled() and this.config.data.other.disableMGEDistantStatics then
                                            mge.render.distantStatics = false
                                            mge.render.distantWater = false
                                        end
                                    end,
                                },
                            },
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.light"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeLight"), this.config.data.light, "randomize"),
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.herbs"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeHerbs"), this.config.data.herbs, "randomize"),
                            createOnOffIngameButton(this.i18n("modConfig.label.doNotRandomizeInventoryForHerb"), this.config.data.herbs, "doNotRandomizeInventory"),
                            createSettingsBlock_slider(this.config.data.herbs, "herbSpeciesPerCell", 1, 1, 20, 1, {label = this.i18n("modConfig.label.herbSpeciesPerCell")}),
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.trees"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeTrees"), this.config.data.trees, "randomize"),
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.stones"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeStones"), this.config.data.stones, "randomize"),
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.flora"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeFlora"), this.config.data.flora, "randomize"),
                            createSettingsBlock_slider(this.config.data.flora, "typesPerCell", 1, 1, 10, 1, {label = this.i18n("modConfig.label.speciesPerCell")}),
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.weather"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeWeather"), this.config.data.weather, "randomize"),
                        },
                    },
                },
            },
            {
                label = this.i18n("modConfig.label.otherSettings"),
                class = "FilterPage",
                components = {
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.randomizeOnlyOnce"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeCellOnlyOnce"), this.config.data.cells, "randomizeOnlyOnce", this.i18n("modConfig.description.willBeAppliedAfterNext").."\n\n"..this.i18n("modConfig.description.randomizeCellOnlyOnce")),
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeDoorsWhenCellLoading"), this.config.data.doors, "onlyOnCellRandomization"),
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeNPCOnlyOnce"), this.config.data.NPCs, "randomizeOnlyOnce", this.i18n("modConfig.description.willBeAppliedAfterNext").."\n\n"..this.i18n("modConfig.description.randomizeCellOnlyOnce")),
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeCreatureOnlyOnce"), this.config.data.creatures, "randomizeOnlyOnce", this.i18n("modConfig.description.willBeAppliedAfterNext").."\n\n"..this.i18n("modConfig.description.randomizeCellOnlyOnce")),
                            {
                                label = this.i18n("modConfig.label.randomizeLandTextureOnlyOnce"),
                                class = "OnOffButton",
                                variable = {
                                    class = "TableVariable",
                                    id = "randomizeOnlyOnce",
                                    table = this.config.global.landscape,
                                },
                            },
                            {
                                class = "Button",
                                buttonText = this.i18n("modConfig.label.rerandomizeLandTextures"),
                                callback = function()
                                    this.funcs.genRandLandTextureInd()
                                    this.funcs.loadRandLandTextures()
                                end,
                            },
                        },
                    },
                },
            },
        },
    }

    this.data = EasyMCM.registerModData(data)
    mwse.registerModConfig(this.name, this.data)
end

return this