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

local function createText(label, description)
    return {
        class = "Info",
        label = label,
        text = description
    }
end

local currentFreeElementId = 0
local elementData = {}
local function getElementIds(count)
    local ids = {}
    for i = 1, count do
        table.insert(ids, currentFreeElementId)
        currentFreeElementId = currentFreeElementId + 1
    end
    return ids
end

---@class mwr.gui.lebelBlock
---@field label string|nil
---@field descr string|nil
---@field text string|nil

---@class mwr.gui.buttonBlock
---@field label string|nil
---@field descr string|nil
---@field onText string|nil
---@field offText string|nil

---@class mwr.gui.lebelBlockForMinmax
---@field min mwr.gui.lebelBlock|nil
---@field max mwr.gui.lebelBlock|nil
---@field button mwr.gui.buttonBlock|nil

---@class mwr.gui.minmaxSettingFuncParams
---@field varTable any
---@field varStr string
---@field buttonVarStr string|nil
---@field ingame boolean|nil
---@field button boolean|nil
---@field link boolean|nil
---@field integer boolean|nil
---@field min number|nil
---@field max number|nil
---@field mul number|nil
---@field text mwr.gui.lebelBlockForMinmax|nil

---@param data mwr.gui.minmaxSettingFuncParams
---@return table
local function createSettingsBlock_minmax_alt(data)
    local ids = getElementIds(3)
    local ret = {
        class = "SideBySideBlock",
        components = {},
    }
    if data.button then
        table.insert(ret.components, {
            class = "Category",
            label = "",
            components = {
                {
                    label = (data.text and data.text.button) and data.text.button.label or "",
                    description = (data.text and data.text.button) and data.text.button.descr or "",
                    buttonText = data.varTable[data.varStr][data.buttonVarStr] and
                        ((data.text and data.text.button and data.text.button.onText) and data.text.button.onText or tes3.findGMST(tes3.gmst.sYes).value) or
                        ((data.text and data.text.button and data.text.button.offText) and data.text.button.offText or tes3.findGMST(tes3.gmst.sNo).value),
                    class = "Button",
                    inGameOnly = data.ingame or true,
                    postCreate = function(self)
                        elementData[ids[1]] = self
                        elementData[ids[1]].elements.button.text = data.varTable[data.varStr][data.buttonVarStr] and
                            ((data.text and data.text.button and data.text.button.onText) and data.text.button.onText or tes3.findGMST(tes3.gmst.sYes).value) or
                            ((data.text and data.text.button and data.text.button.offText) and data.text.button.offText or tes3.findGMST(tes3.gmst.sNo).value)
                    end,
                    callback = function(self)
                        local val = not data.varTable[data.varStr][data.buttonVarStr]
                        data.varTable[data.varStr][data.buttonVarStr] = val
                        if val then
                            elementData[ids[1]].elements.button.text = (data.text and data.text.button and data.text.button.onText) and data.text.button.onText or
                                tes3.findGMST(tes3.gmst.sYes).value
                        else
                            elementData[ids[1]].elements.button.text = (data.text and data.text.button and data.text.button.offText) and data.text.button.offText or
                                tes3.findGMST(tes3.gmst.sNo).value
                        end
                    end,
                },
            },
        })
    end
    table.insert(ret.components, {
        class = "TextField",
        label = (data.text and data.text.min and data.text.min.label) and data.text.min.label or "",
        description = (data.text and data.text.min and data.text.min.descr) and data.text.min.descr or "",
        inGameOnly = data.ingame or true,
        postCreate = function(self)
            elementData[ids[2]] = self
            self.elements.submitButton:destroy()
            self.elements.inputField:register("destroy", function()
                local val = tonumber(self.elements.inputField.text)
                if not val then return end
                if data.max and data.max < val then val = data.max end
                if data.min and data.min > val then val = data.min end
                if data.link then
                    local maxVal = (elementData[ids[3]] and tonumber(elementData[ids[3]].elements.inputField.text)) and
                        tonumber(elementData[ids[3]].elements.inputField.text) or (data.varTable[data.varStr].max * (data.mul or 1))
                    if val > maxVal then
                        val = data.min and data.min or (data.varTable[data.varStr].min * (data.mul or 1))
                    end
                end
                local res = data.integer and math.floor(val / (data.mul or 1)) or val / (data.mul or 1)
                data.varTable[data.varStr].min = res
            end)
        end,
        variable = EasyMCM.createVariable{
            numbersOnly = true,
            get = function(self)
                return data.varTable[data.varStr].min * (data.mul or 1)
            end,
            set = function(self, strVal)
                local val = tonumber(strVal)
                if data.max and data.max < val then val = data.max end
                if data.min and data.min > val then val = data.min end
                if data.link then
                    if val > data.varTable[data.varStr].max * (data.mul or 1) then
                        val = data.min and data.min or (data.varTable[data.varStr].min * (data.mul or 1))
                    end
                end
                local res = data.integer and math.floor(val / (data.mul or 1)) or val / (data.mul or 1)
                data.varTable[data.varStr].min = res
            end,
        },
    })
    table.insert(ret.components, {
        class = "TextField",
        label = (data.text and data.text.max and data.text.max.label) and data.text.max.label or "",
        description = (data.text and data.text.max and data.text.max.descr) and data.text.max.descr or "",
        numbersOnly = true,
        inGameOnly = data.ingame or true,
        postCreate = function(self)
            elementData[ids[3]] = self
            self.elements.submitButton:destroy()
            self.elements.inputField:register("destroy", function()
                local val = tonumber(self.elements.inputField.text)
                if not val then return end
                if data.max and data.max < val then val = data.max end
                if data.min and data.min > val then val = data.min end
                if data.link then
                    local minVal = (elementData[ids[2]] and tonumber(elementData[ids[2]].elements.inputField.text)) and
                        tonumber(elementData[ids[2]].elements.inputField.text) or (data.varTable[data.varStr].min * (data.mul or 1))
                    if val < minVal then
                        val = data.max and data.max or (data.varTable[data.varStr].max * (data.mul or 1))
                    end
                end
                local res = data.integer and math.floor(val / (data.mul or 1)) or val / (data.mul or 1)
                data.varTable[data.varStr].max = res
            end)
        end,
        variable = EasyMCM.createVariable{
            numbersOnly = true,
            get = function(self)
                return data.varTable[data.varStr].max * (data.mul or 1)
            end,
            set = function(self, strVal)
                local val = tonumber(strVal)
                if data.max and data.max < val then val = data.max end
                if data.min and data.min > val then val = data.min end
                if data.link then
                    if val < data.varTable[data.varStr].min * (data.mul or 1) then
                        val = data.max and data.max or (data.varTable[data.varStr].max * (data.mul or 1))
                    end
                end
                local res = data.integer and math.floor(val / (data.mul or 1)) or val / (data.mul or 1)
                data.varTable[data.varStr].max = res
            end,
        },
    })
    return ret
end

local function createSettingsBlock_number(varTable, varStr, varMul, min, max, step, labels, ingame)
    return {
        class = "Category",
        components = {
            {
                class = "Info",
                text = labels.label,
                description = labels.descr,
            },
            {
                class = "SideBySideBlock",
                components = {
                    {
                        class = "Info",
                        description = labels.descr,
                        text = labels.text or " ",
                    },
                    {
                        class = "TextField",
                        description = labels.descr,
                        inGameOnly = ingame == nil and true or ingame,
                        postCreate = function(self)
                            self.elements.submitButton:destroy()
                            self.elements.border.maxWidth = 150
                            self.elements.inputField:register("destroy", function()
                                local val = tonumber(self.elements.inputField.text)
                                if not val then return end
                                if max and max < val then val = max end
                                if min and min > val then val = min end
                                if varTable ~= nil and varTable[varStr] ~= nil then
                                    varTable[varStr] = val / varMul
                                end
                            end)
                        end,
                        variable = EasyMCM.createVariable{
                            numbersOnly = true,
                            get = function(self)
                                if varTable ~= nil and varTable[varStr] ~= nil then
                                    return varTable[varStr] * varMul
                                end
                                return min
                            end,
                            set = function(self, strVal)
                                local val = tonumber(strVal)
                                if not val then return end
                                if max and max < val then val = max end
                                if min and min > val then val = min end
                                if varTable ~= nil and varTable[varStr] ~= nil then
                                    varTable[varStr] = val / varMul
                                end
                            end,
                        },
                    },
                }
            },
        },
    }
end

local function createSettingsBlock_regionMinMax(varTable)
    return createSettingsBlock_minmax_alt{varTable = varTable, varStr = "region", min = 0, max = 100, mul = 100, text = {
        min = {label = this.i18n("modConfig.label.leftShift"), descr = this.i18n("modConfig.description.regionMinMax")},
        max = {label = this.i18n("modConfig.label.rightShift"), descr = this.i18n("modConfig.description.regionMinMax")}}}
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

local function enableRandomizerCallback(e)
    if e.button == 0 then
        this.funcs.randomizeLoadedCells()
    elseif e.button == 1 then
        this.funcs.randomizeLoadedCellsFunc()
    end
end

local function enableRandomizerMessage()
    tes3.messageBox({ message = this.i18n("modConfig.message.modEnabled"),
        buttons = {tes3.findGMST(tes3.gmst.sOK).value, this.i18n("modConfig.button.runInitialization"),},
        callback = enableRandomizerCallback, showInDialog = false})
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
                                            enableRandomizerMessage()
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
                                        val = val:lower()
                                        -- local exists = false
                                        -- for i, profileVal in pairs(profilesList) do
                                        --     if profileVal.value == val then
                                        --         exists = true
                                        --         break
                                        --     end
                                        -- end
                                        if not this.config.defaultProfileNames[val] then
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
                            createSettingsBlock_number(this.config.global, "cellRandomizationCooldown", 1, 0, nil, 1, {label = this.i18n("modConfig.label.cellRandomizationIntervalRealTime")}, false),
                            createSettingsBlock_number(this.config.global, "cellRandomizationCooldown_gametime", 1, 0, nil, 1, {label = this.i18n("modConfig.label.cellRandomizationIntervalGameTime")}, false),
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
                            createText(nil, this.i18n("modConfig.text.dataGeneration")),
                            {
                                label = this.i18n("modConfig.label.generateTreeData"),
                                class = "OnOffButton",
                                variable = {
                                    class = "Variable",
                                    get = function(self) return this.config.global.generation.generateTreeData end,
                                    set = function(self, val)
                                        this.config.global.generation.generateTreeData = val
                                    end,
                                },
                            },
                            {
                                label = this.i18n("modConfig.label.generateRockData"),
                                class = "OnOffButton",
                                variable = {
                                    class = "Variable",
                                    get = function(self) return this.config.global.generation.generateRockData end,
                                    set = function(self, val)
                                        this.config.global.generation.generateRockData = val
                                    end,
                                },
                            },
                            {
                                class = "Button",
                                buttonText = this.i18n("modConfig.label.regenerateData"),
                                inGameOnly = false,
                                callback = function()
                                    this.funcs.generateStaticFunc()
                                end,
                            },
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
                            createSettingsBlock_regionMinMax(this.config.data.containers.items),
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.randomizeItemWithoutCont"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeItemWithoutCont"), this.config.data.items, "randomize"),
                            createSettingsBlock_regionMinMax(this.config.data.items),
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.randomizeNPCItems"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeNPCItems"), this.config.data.NPCs.items, "randomize"),
                            createSettingsBlock_regionMinMax(this.config.data.NPCs.items),
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.randomizeCreatureItems"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeCreatureItems"), this.config.data.creatures.items, "randomize"),
                            createSettingsBlock_regionMinMax(this.config.data.creatures.items),
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.randomizeSoulsInGems"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeSoulsInGems"), this.config.data.soulGems.soul, "randomize"),
                            createSettingsBlock_regionMinMax(this.config.data.soulGems.soul),
                            createSettingsBlock_number(this.config.data.soulGems.soul.add, "chance", 100, 1, 100, 1, {label = this.i18n("modConfig.label.chanceToAddSoul")}),
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.randomizeGold"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeGold"), this.config.data.gold, "randomize"),
                            createSettingsBlock_minmax_alt({varTable = this.config.data.gold, varStr = "region", button = true, link = true,
                                buttonVarStr = "additive", text = {button = {onText = this.i18n("modConfig.label.addBetween"), offText = this.i18n("modConfig.label.multiplyBetween")},
                                min = {label = this.i18n("modConfig.label.min")}, max = {label = this.i18n("modConfig.label.max")}}}),
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
                            createSettingsBlock_minmax_alt({varTable = this.config.data.item.stats, varStr = "region", link = true, min = 10, mul = 100,
                                text = {min = {label = this.i18n("modConfig.label.minMultiplier"), descr = this.i18n("modConfig.description.itemStatsRandValue")},
                                max = {label = this.i18n("modConfig.label.maxMultiplier"), descr = this.i18n("modConfig.description.itemStatsRandValue")}}}),
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.weaponDamageStats"),
                                description = "",
                                components = {
                                    createSettingsBlock_minmax_alt({varTable = this.config.data.item.stats.weapon, varStr = "region", link = true, min = 10, mul = 100,
                                        text = {min = {label = this.i18n("modConfig.label.minMultiplier"), descr = this.i18n("modConfig.description.itemStatsRandValue")},
                                        max = {label = this.i18n("modConfig.label.maxMultiplier"), descr = this.i18n("modConfig.description.itemStatsRandValue")}}}),
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
                                    createSettingsBlock_regionMinMax(this.config.data.item.enchantment.existing),
                                },
                            },
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.newEnchPower"),
                                description = "",
                                components = {
                                    createSettingsBlock_minmax_alt({varTable = this.config.data.item.enchantment, varStr = "region", link = true, mul = 100, min = 0,
                                        text = {min = {label = this.i18n("modConfig.label.minMultiplier"), descr = this.i18n("modConfig.description.itemStatsRandEnch")},
                                        max = {label = this.i18n("modConfig.label.maxMultiplier"), descr = this.i18n("modConfig.description.itemStatsRandEnch")}}}),
                                    createSettingsBlock_number(this.config.data.item.enchantment, "arrowPower", 100, 1, nil, 1, {label = this.i18n("modConfig.label.arrowPower")}),
                                },
                            },
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.numberOfEnchCasts"),
                                description = "",
                                components = {
                                    createSettingsBlock_minmax_alt({varTable = this.config.data.item.enchantment, varStr = "numberOfCasts", link = true, min = 1, integer = true,
                                        text = {min = {label = this.i18n("modConfig.label.minVal")}, max = {label = this.i18n("modConfig.label.maxVal")}}}),
                                },
                            },
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.enchCost"),
                                description = "",
                                components = {
                                    createSettingsBlock_minmax_alt({varTable = this.config.data.item.enchantment, varStr = "cost", link = true, integer = true, min = 0,
                                        text = {min = {label = this.i18n("modConfig.label.minVal")}, max = {label = this.i18n("modConfig.label.maxVal")}}}),
                                    createSettingsBlock_number(this.config.data.item.enchantment, "scrollBase", 1, 1, nil, 1, {label = this.i18n("modConfig.label.scrollEnchCapacity")}),
                                },
                            },
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.enchEffects"),
                                description = "",
                                components = {
                                    createSettingsBlock_number(this.config.data.item.enchantment.effects, "maxDuration", 1, 1, nil, 1, {label = this.i18n("modConfig.label.maxEnchEffectDuration")}),
                                    createSettingsBlock_number(this.config.data.item.enchantment.effects, "maxRadius", 1, 1, nil, 1, {label = this.i18n("modConfig.label.maxEnchEffectRadius")}),
                                    createSettingsBlock_number(this.config.data.item.enchantment.effects, "maxMagnitude", 1, 1, nil, 1, {label = this.i18n("modConfig.label.maxEnchEffectMagnitude")}),
                                    createSettingsBlock_number(this.config.data.item.enchantment.effects, "durationForConstant", 1, 10, nil, 1, {label = this.i18n("modConfig.label.durationForConstant"), description = this.i18n("modConfig.description.durationForConstant")}),
                                    createSettingsBlock_number(this.config.data.item.enchantment.effects, "fortifyForSelfChance", 100, 0, nil, 1, {label = this.i18n("modConfig.label.fortifyForSelfChance")}),
                                    createSettingsBlock_number(this.config.data.item.enchantment.effects, "damageForTargetChance", 100, 0, nil, 1, {label = this.i18n("modConfig.label.damageForTargetChance")}),
                                    createSettingsBlock_number(this.config.data.item.enchantment.effects, "restoreForAlchemyChance", 100, 0, nil, 1, {label = this.i18n("modConfig.label.restoreForAlchemyChance")}),
                                    {
                                        class = "Category",
                                        label = this.i18n("modConfig.label.itemEnchantment"),
                                        description = "",
                                        components = {
                                            createOnOffIngameButton(this.i18n("modConfig.label.safeEnchantmentForConstant"), this.config.data.item.enchantment.effects, "safeMode"),
                                            createSettingsBlock_number(this.config.data.item.enchantment.effects, "oneTypeChance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.oneEnchTypeChance")}),
                                            createSettingsBlock_number(this.config.data.item.enchantment.effects, "maxCount", 1, 1, 8, 1, {label = this.i18n("modConfig.label.maxEnchEffCount")}),
                                            createSettingsBlock_number(this.config.data.item.enchantment.effects, "chanceToNegative", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToNegativeEffectForConstant")}),
                                            createSettingsBlock_number(this.config.data.item.enchantment.effects, "chanceToNegativeForTarget", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToNegativeEffectForTarget")}),
                                        },
                                    },
                                    {
                                        class = "Category",
                                        label = this.i18n("modConfig.label.potionEffNum"),
                                        description = "",
                                        components = {
                                            createSettingsBlock_minmax_alt({varTable = this.config.data.item.enchantment.effects, varStr = "alchemyCount", link = true, min = 1, max = 4, integer = true,
                                                text = {min = {label = this.i18n("modConfig.label.minVal")}, max = {label = this.i18n("modConfig.label.maxVal")}}}),
                                        },
                                    },
                                    {
                                        class = "Category",
                                        label = this.i18n("modConfig.label.ingredientEffNum"),
                                        description = "",
                                        components = {
                                            createSettingsBlock_minmax_alt({varTable = this.config.data.item.enchantment.effects.ingredient, varStr = "count", link = true, min = 1, max = 4, integer = true,
                                                text = {min = {label = this.i18n("modConfig.label.minVal")}, max = {label = this.i18n("modConfig.label.maxVal")}}}),
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
                                    createSettingsBlock_number(this.config.data.item.enchantment.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceAddEnchantment")}),
                                    {
                                        class = "Category",
                                        label = this.i18n("modConfig.label.addedEnchPower"),
                                        description = "",
                                        components = {
                                            createSettingsBlock_minmax_alt({varTable = this.config.data.item.enchantment.add, varStr = "region", link = true, min = 0,
                                                text = {min = {label = this.i18n("modConfig.label.minMultiplier"), descr = this.i18n("modConfig.description.itemStatsRandEnch")},
                                                max = {label = this.i18n("modConfig.label.maxMultiplier"), descr = this.i18n("modConfig.description.itemStatsRandEnch")}}}),
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
                                    createSettingsBlock_number(this.config.data.item.enchantment.remove, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceRemoveEnchantment")}),
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
                            createSettingsBlock_regionMinMax(this.config.data.creatures),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.items"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeItems"), this.config.data.creatures.items, "randomize"),
                            createSettingsBlock_regionMinMax(this.config.data.creatures.items),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.health"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeHealth"), this.config.data.creatures.health, "randomize"),
                            createSettingsBlock_minmax_alt({varTable = this.config.data.creatures.health, varStr = "region", button = true, link = true,
                                buttonVarStr = "additive", text = {button = {onText = this.i18n("modConfig.label.addBetween"), offText = this.i18n("modConfig.label.multiplyBetween")},
                                min = {label = this.i18n("modConfig.label.min")}, max = {label = this.i18n("modConfig.label.max")}}}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.magicka"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeMagicka"), this.config.data.creatures.magicka, "randomize"),
                            createSettingsBlock_minmax_alt({varTable = this.config.data.creatures.magicka, varStr = "region", button = true, link = true,
                                buttonVarStr = "additive", text = {button = {onText = this.i18n("modConfig.label.addBetween"), offText = this.i18n("modConfig.label.multiplyBetween")},
                                min = {label = this.i18n("modConfig.label.min")}, max = {label = this.i18n("modConfig.label.max")}}}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.fatigue"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeFatigue"), this.config.data.creatures.fatigue, "randomize"),
                            createSettingsBlock_minmax_alt({varTable = this.config.data.creatures.fatigue, varStr = "region", button = true, link = true,
                                buttonVarStr = "additive", text = {button = {onText = this.i18n("modConfig.label.addBetween"), offText = this.i18n("modConfig.label.multiplyBetween")},
                                min = {label = this.i18n("modConfig.label.min")}, max = {label = this.i18n("modConfig.label.max")}}}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.attackDamage"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeDamage"), this.config.data.creatures.attack, "randomize"),
                            createSettingsBlock_minmax_alt({varTable = this.config.data.creatures.attack, varStr = "region", button = true, link = true,
                                buttonVarStr = "additive", text = {button = {onText = this.i18n("modConfig.label.addBetween"), offText = this.i18n("modConfig.label.multiplyBetween")},
                                min = {label = this.i18n("modConfig.label.min")}, max = {label = this.i18n("modConfig.label.max")}}}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.scale"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeScale"), this.config.data.creatures.scale, "randomize"),
                            createSettingsBlock_minmax_alt({varTable = this.config.data.creatures.scale, varStr = "region", button = true, link = true,
                                buttonVarStr = "additive", text = {button = {onText = this.i18n("modConfig.label.addBetween"), offText = this.i18n("modConfig.label.multiplyBetween")},
                                min = {label = this.i18n("modConfig.label.min")}, max = {label = this.i18n("modConfig.label.max")}}}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.skills"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeSkills"), this.config.data.creatures.skills, "randomize"),
                            createSettingsBlock_number(this.config.data.creatures.skills, "limit", 1, 1, nil, 1, {label = this.i18n("modConfig.label.maxValueOfSkill")}),

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.combatSkills"),
                                description = "",
                                components = {
                                    createSettingsBlock_regionMinMax(this.config.data.creatures.skills.combat),
                                },
                            },

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.magicSkills"),
                                description = "",
                                components = {
                                    createSettingsBlock_regionMinMax(this.config.data.creatures.skills.magic),
                                },
                            },

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.stealthSkills"),
                                description = "",
                                components = {
                                    createSettingsBlock_regionMinMax(this.config.data.creatures.skills.stealth),
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
                            createSettingsBlock_regionMinMax(this.config.data.creatures.ai.fight),

                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeAIFlee"), this.config.data.creatures.ai.flee, "randomize"),
                            createSettingsBlock_regionMinMax(this.config.data.creatures.ai.flee),

                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeAIAlarm"), this.config.data.creatures.ai.alarm, "randomize"),
                            createSettingsBlock_regionMinMax(this.config.data.creatures.ai.alarm),

                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeAIHello"), this.config.data.creatures.ai.hello, "randomize"),
                            createSettingsBlock_regionMinMax(this.config.data.creatures.ai.hello),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.spells"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeSpells"), this.config.data.creatures.spells, "randomize"),
                            createSettingsBlock_regionMinMax(this.config.data.creatures.spells),

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.addNewSpells"),
                                description = "",
                                components = {
                                    createSettingsBlock_number(this.config.data.creatures.spells.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd"), descr = this.i18n("modConfig.description.chanceToAddSpell")}),
                                    createSettingsBlock_number(this.config.data.creatures.spells.add, "count", 1, 0, nil, 1, {label = this.i18n("modConfig.label.addXMore")}),
                                    createSettingsBlock_number(this.config.data.creatures.spells.add, "levelReference", 1, 1, nil, 1, {label = this.i18n("modConfig.label.levelLimiter"), descr = this.i18n("modConfig.description.listLimiter")}),
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
                            createSettingsBlock_regionMinMax(this.config.data.creatures.abilities),

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.addNewAbilities"),
                                description = "",
                                components = {
                                    createSettingsBlock_number(this.config.data.creatures.abilities.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd"), descr = this.i18n("modConfig.description.chanceToAddAbility")}),
                                    createSettingsBlock_number(this.config.data.creatures.abilities.add, "count", 1, 0, nil, 1, {label = this.i18n("modConfig.label.addXMore")}),
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
                            createSettingsBlock_regionMinMax(this.config.data.creatures.diseases),

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.addNewDiseases"),
                                description = "",
                                components = {
                                    createSettingsBlock_number(this.config.data.creatures.diseases.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd"), descr = this.i18n("modConfig.description.chanceToAddDisease")}),
                                    createSettingsBlock_number(this.config.data.creatures.diseases.add, "count", 1, 0, nil, 1, {label = this.i18n("modConfig.label.addXMore")}),
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
                                    createSettingsBlock_number(this.config.data.creatures.effects.positive.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd"), descr = this.i18n("modConfig.description.chanceToAddEffect")}),
                                    createSettingsBlock_number(this.config.data.creatures.effects.positive.add, "count", 1, 0, 10, 1, {label = this.i18n("modConfig.label.addXMore")}),

                                    createSettingsBlock_minmax_alt({varTable = this.config.data.creatures.effects.positive.add, varStr = "region", link = true, integer = true, min = 0,
                                        text = {min = {label = this.i18n("modConfig.label.minEffectVal")}, max = {label = this.i18n("modConfig.label.maxEffectVal")}}}),
                                },
                            },

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.negativeEffects"),
                                description = this.i18n("modConfig.description.negativeEffects"),
                                components = {
                                    createSettingsBlock_number(this.config.data.creatures.effects.negative.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd"), descr = this.i18n("modConfig.description.chanceToAddEffect")}),
                                    createSettingsBlock_number(this.config.data.creatures.effects.negative.add, "count", 1, 0, 10, 1, {label = this.i18n("modConfig.label.addXMore")}),

                                    createSettingsBlock_minmax_alt({varTable = this.config.data.creatures.effects.negative.add, varStr = "region", link = true, integer = true, min = 0,
                                        text = {min = {label = this.i18n("modConfig.label.minEffectVal")}, max = {label = this.i18n("modConfig.label.maxEffectVal")}}}),
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
                            createSettingsBlock_regionMinMax(this.config.data.NPCs.items),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.health"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeHealth"), this.config.data.NPCs.health, "randomize"),
                            createSettingsBlock_minmax_alt({varTable = this.config.data.NPCs.health, varStr = "region", button = true, link = true,
                                buttonVarStr = "additive", text = {button = {onText = this.i18n("modConfig.label.addBetween"), offText = this.i18n("modConfig.label.multiplyBetween")},
                                min = {label = this.i18n("modConfig.label.min")}, max = {label = this.i18n("modConfig.label.max")}}}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.magicka"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeMagicka"), this.config.data.NPCs.magicka, "randomize"),
                            createSettingsBlock_minmax_alt({varTable = this.config.data.NPCs.magicka, varStr = "region", button = true, link = true,
                                buttonVarStr = "additive", text = {button = {onText = this.i18n("modConfig.label.addBetween"), offText = this.i18n("modConfig.label.multiplyBetween")},
                                min = {label = this.i18n("modConfig.label.min")}, max = {label = this.i18n("modConfig.label.max")}}}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.fatigue"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeFatigue"), this.config.data.NPCs.fatigue, "randomize"),
                            createSettingsBlock_minmax_alt({varTable = this.config.data.NPCs.fatigue, varStr = "region", button = true, link = true,
                                buttonVarStr = "additive", text = {button = {onText = this.i18n("modConfig.label.addBetween"), offText = this.i18n("modConfig.label.multiplyBetween")},
                                min = {label = this.i18n("modConfig.label.min")}, max = {label = this.i18n("modConfig.label.max")}}}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.scale"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeScale"), this.config.data.NPCs.scale, "randomize"),
                            createSettingsBlock_minmax_alt({varTable = this.config.data.NPCs.scale, varStr = "region", button = true, link = true,
                                buttonVarStr = "additive", text = {button = {onText = this.i18n("modConfig.label.addBetween"), offText = this.i18n("modConfig.label.multiplyBetween")},
                                min = {label = this.i18n("modConfig.label.min")}, max = {label = this.i18n("modConfig.label.max")}}}),
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
                            createSettingsBlock_number(this.config.data.NPCs.skills, "limit", 1, 1, nil, 1, {label = this.i18n("modConfig.label.maxValueOfSkill")}),

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.combatSkills"),
                                description = "",
                                components = {
                                    createSettingsBlock_regionMinMax(this.config.data.NPCs.skills.combat),
                                },
                            },

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.magicSkills"),
                                description = "",
                                components = {
                                    createSettingsBlock_regionMinMax(this.config.data.NPCs.skills.magic),
                                },
                            },

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.stealthSkills"),
                                description = "",
                                components = {
                                    createSettingsBlock_regionMinMax(this.config.data.NPCs.skills.stealth),
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
                            createSettingsBlock_number(this.config.data.NPCs.attributes, "limit", 1, 1, nil, 1, {label = this.i18n("modConfig.label.maxValueOfAttribute")}),

                            createSettingsBlock_minmax_alt({varTable = this.config.data.NPCs.attributes, varStr = "region", button = true, link = true,
                                buttonVarStr = "additive", text = {button = {onText = this.i18n("modConfig.label.addBetween"), offText = this.i18n("modConfig.label.multiplyBetween")},
                                min = {label = this.i18n("modConfig.label.min")}, max = {label = this.i18n("modConfig.label.max")}}}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.AI"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeAIFight"), this.config.data.NPCs.ai.fight, "randomize"),
                            createSettingsBlock_regionMinMax(this.config.data.NPCs.ai.fight),

                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeAIFlee"), this.config.data.NPCs.ai.flee, "randomize"),
                            createSettingsBlock_regionMinMax(this.config.data.NPCs.ai.flee),

                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeAIAlarm"), this.config.data.NPCs.ai.alarm, "randomize"),
                            createSettingsBlock_regionMinMax(this.config.data.NPCs.ai.alarm),

                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeAIHello"), this.config.data.NPCs.ai.hello, "randomize"),
                            createSettingsBlock_regionMinMax(this.config.data.NPCs.ai.hello),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.spells"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeSpells"), this.config.data.NPCs.spells, "randomize"),
                            createSettingsBlock_regionMinMax(this.config.data.NPCs.spells),

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.addNewSpells"),
                                description = "",
                                components = {
                                    createSettingsBlock_number(this.config.data.NPCs.spells.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd"), descr = this.i18n("modConfig.description.chanceToAddSpell")}),
                                    createSettingsBlock_number(this.config.data.NPCs.spells.add, "count", 1, 0, nil, 1, {label = this.i18n("modConfig.label.addXMore")}),
                                    createOnOffIngameButton(this.i18n("modConfig.label.spellsBySkill"), this.config.data.NPCs.spells.add, "bySkill"),
                                    createSettingsBlock_number(this.config.data.NPCs.spells.add, "bySkillMax", 1, 1, nil, 1, {label = this.i18n("modConfig.label.spellsBySkillMax")}),
                                    createSettingsBlock_number(this.config.data.NPCs.spells.add, "levelReference", 1, 1, nil, 1, {label = this.i18n("modConfig.label.levelLimiter"), descr = this.i18n("modConfig.description.listLimiter")}),
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
                            createSettingsBlock_regionMinMax(this.config.data.NPCs.abilities),

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.addNewAbilities"),
                                description = "",
                                components = {
                                    createSettingsBlock_number(this.config.data.NPCs.abilities.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd"), descr = this.i18n("modConfig.description.chanceToAddAbility")}),
                                    createSettingsBlock_number(this.config.data.NPCs.abilities.add, "count", 1, 0, nil, 1, {label = this.i18n("modConfig.label.addXMore")}),
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
                            createSettingsBlock_regionMinMax(this.config.data.NPCs.diseases),

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.addNewDiseases"),
                                description = "",
                                components = {
                                    createSettingsBlock_number(this.config.data.NPCs.diseases.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd"), descr = this.i18n("modConfig.description.chanceToAddDisease")}),
                                    createSettingsBlock_number(this.config.data.NPCs.diseases.add, "count", 1, 0, nil, 1, {label = this.i18n("modConfig.label.addXMore")}),
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
                                    createSettingsBlock_number(this.config.data.NPCs.effects.positive.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd"), descr = this.i18n("modConfig.description.chanceToAddEffect")}),
                                    createSettingsBlock_number(this.config.data.NPCs.effects.positive.add, "count", 1, 0, 10, 1, {label = this.i18n("modConfig.label.addXMore")}),

                                    createSettingsBlock_minmax_alt({varTable = this.config.data.NPCs.effects.positive.add, varStr = "region", link = true, integer = true, min = 0,
                                        text = {min = {label = this.i18n("modConfig.label.minEffectVal")}, max = {label = this.i18n("modConfig.label.maxEffectVal")}}}),
                                },
                            },

                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.negativeEffects"),
                                description = this.i18n("modConfig.description.negativeEffects"),
                                components = {
                                    createSettingsBlock_number(this.config.data.NPCs.effects.negative.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd"), descr = this.i18n("modConfig.description.chanceToAddEffect")}),
                                    createSettingsBlock_number(this.config.data.NPCs.effects.negative.add, "count", 1, 0, 10, 1, {label = this.i18n("modConfig.label.addXMore")}),

                                    createSettingsBlock_minmax_alt({varTable = this.config.data.NPCs.effects.negative.add, varStr = "region", link = true, integer = true, min = 0,
                                        text = {min = {label = this.i18n("modConfig.label.minEffectVal")}, max = {label = this.i18n("modConfig.label.maxEffectVal")}}}),
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
                            createSettingsBlock_minmax_alt({varTable = this.config.data.barterGold, varStr = "region", button = true, link = true,
                                buttonVarStr = "additive", text = {button = {onText = this.i18n("modConfig.label.addBetween"), offText = this.i18n("modConfig.label.multiplyBetween")},
                                min = {label = this.i18n("modConfig.label.min")}, max = {label = this.i18n("modConfig.label.max")}}}),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.transport"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeTransport"), this.config.data.transport, "randomize"),
                            createSettingsBlock_number(this.config.data.transport, "unrandomizedCount", 1, 0, 4, 1, {label = this.i18n("modConfig.label.numOfDestinationsWithoutRand")}),
                            createSettingsBlock_number(this.config.data.transport, "toDoorsCount", 1, 0, 4, 1, {label = this.i18n("modConfig.label.numOfDestinationsToDoor")}),
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
                            createSettingsBlock_regionMinMax(this.config.data.containers.items),
                        },
                    },

                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.locks"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeLock"), this.config.data.containers.lock, "randomize"),
                            createSettingsBlock_regionMinMax(this.config.data.containers.lock),
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.addLock"),
                                description = "",
                                components = {
                                    createSettingsBlock_number(this.config.data.containers.lock.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToLock")}),
                                    createSettingsBlock_number(this.config.data.containers.lock.add, "levelMultiplier", 1, 0, 100, 1, {label = this.i18n("modConfig.label.lockLevMul"), descr = this.i18n("modConfig.description.lockLevMul")}),
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
                            createSettingsBlock_regionMinMax(this.config.data.containers.trap),
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.addTrap"),
                                description = "",
                                components = {
                                    createSettingsBlock_number(this.config.data.containers.trap.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd")}),
                                    createSettingsBlock_number(this.config.data.containers.trap.add, "levelMultiplier", 1, 0, 100, 1, {label = this.i18n("modConfig.label.maxValMulOfTrapSpell"), descr = this.i18n("modConfig.description.trapSpellListSize")}),
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
                            createSettingsBlock_number(this.config.data.doors, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToRandomize")}),
                            createSettingsBlock_number(this.config.data.doors, "cooldown", 1, 0, nil, 1, {label = this.i18n("modConfig.label.cooldownGameHours")}),
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeDoorsWhenCellLoading"), this.config.data.doors, "onlyOnCellRandomization"),
                            createOnOffIngameButton(this.i18n("modConfig.label.doNotRandomizeInToIn"), this.config.data.doors, "doNotRandomizeInToIn"),
                            {
                                class = "Category",
                                label = "",
                                description = "",
                                components = {
                                    createOnOffIngameButton(this.i18n("modConfig.label.randomizeOnlyToNearestDoors"), this.config.data.doors, "onlyNearest"),
                                    createSettingsBlock_number(this.config.data.doors, "nearestCellDepth", 1, 1, 10, 1, {label = this.i18n("modConfig.label.radiusInCellsForCell")}),
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
                            createSettingsBlock_regionMinMax(this.config.data.doors.lock),
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.addLock"),
                                description = "",
                                components = {
                                    createSettingsBlock_number(this.config.data.doors.lock.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToLock")}),
                                    createSettingsBlock_number(this.config.data.doors.lock.add, "levelMultiplier", 1, 0, 100, 1, {label = this.i18n("modConfig.label.lockLevMul"), descr = this.i18n("modConfig.description.lockLevMul")}),
                                },
                            },
                            {
                                class = "Category",
                                label = "",
                                description = "",
                                components = {
                                    createOnOffIngameButton(this.i18n("modConfig.label.doNotLockIfNoEnemy"), this.config.data.doors.lock.safeCellMode, "enabled"),
                                    createSettingsBlock_number(this.config.data.doors.lock.safeCellMode, "fightValue", 1, 0, 100, 1, {label = this.i18n("modConfig.label.minFightToBeEnemy")}),
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
                            createSettingsBlock_regionMinMax(this.config.data.doors.trap),
                            {
                                class = "Category",
                                label = this.i18n("modConfig.label.addTrap"),
                                description = "",
                                components = {
                                    createSettingsBlock_number(this.config.data.doors.trap.add, "chance", 100, 0, 100, 1, {label = this.i18n("modConfig.label.chanceToAdd")}),
                                    createSettingsBlock_number(this.config.data.doors.trap.add, "levelMultiplier", 1, 0, 100, 1, {label = this.i18n("modConfig.label.maxValMulOfTrapSpell"), descr = this.i18n("modConfig.description.trapSpellListSize")}),
                                    createOnOffIngameButton(this.i18n("modConfig.label.useOnlyDestruction"), this.config.data.doors.trap.add, "onlyDestructionSchool"),
                                },
                            },
                            {
                                class = "Category",
                                label = "",
                                description = "",
                                components = {
                                    createOnOffIngameButton(this.i18n("modConfig.label.doNotTrapIfNoEnemy"), this.config.data.doors.trap.safeCellMode, "enabled"),
                                    createSettingsBlock_number(this.config.data.doors.trap.safeCellMode, "fightValue", 1, 0, 100, 1, {label = this.i18n("modConfig.label.minFightToBeEnemy")}),
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
                            createSettingsBlock_number(this.config.data.herbs, "herbSpeciesPerCell", 1, 1, 50, 1, {label = this.i18n("modConfig.label.herbSpeciesPerCell")}),
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.trees"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeTrees"), this.config.data.trees, "randomize"),
                            createSettingsBlock_number(this.config.data.trees, "typesPerCell", 1, 1, 50, 1, {label = this.i18n("modConfig.label.speciesPerCell")}),
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.stones"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeStones"), this.config.data.stones, "randomize"),
                            createSettingsBlock_number(this.config.data.stones, "typesPerCell", 1, 1, 50, 1, {label = this.i18n("modConfig.label.speciesPerCell")}),
                        },
                    },
                    {
                        class = "Category",
                        label = this.i18n("modConfig.label.flora"),
                        description = "",
                        components = {
                            createOnOffIngameButton(this.i18n("modConfig.label.randomizeFlora"), this.config.data.flora, "randomize"),
                            createSettingsBlock_number(this.config.data.flora, "typesPerCell", 1, 1, 50, 1, {label = this.i18n("modConfig.label.speciesPerCell")}),
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