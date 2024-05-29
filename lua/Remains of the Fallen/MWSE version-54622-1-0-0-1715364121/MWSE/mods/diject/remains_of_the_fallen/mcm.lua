local config = include("diject.remains_of_the_fallen.config")
local log = include("diject.remains_of_the_fallen.utils.log")
local mcm = mwse.mcm

local this = {}

local isShiftDown = false
local isAltDown = false

---@type mwseMCMTemplate|nil
this.modData = nil

local function getSettingColor(isLocal)
    return isLocal and tes3ui.getPalette(tes3.palette.bigAnswerPressedColor) or tes3ui.getPalette("normal_color")
end


---@class rotf.mcm.createLabel
---@field self mwseMCMExclusionsPage|mwseMCMFilterPage|mwseMCMMouseOverPage|mwseMCMPage|mwseMCMSideBarPage
---@field labelColor tes3.palette|string|nil
---@field textColor tes3.palette|string|nil

---@param params mwseMCMCategory.createInfo.data|rotf.mcm.createLabel
---@return mwseMCMActiveInfo|mwseMCMHyperlink|mwseMCMInfo|mwseMCMMouseOverInfo
local function createLabel(params)
    local info = params.self:createInfo(params)
    info.postCreate = function(self)
        self.elements.label.color = params.labelColor and tes3ui.getPalette(params.labelColor) or self.elements.label.color
        self.elements.info.color = params.textColor and tes3ui.getPalette(params.textColor) or self.elements.info.color
        self:update()
    end
    return info
end


---@class rotf.mcm.configPath
---@field path string table with the value
---@field name string the value

---@class rotf.mcm.createYesNo
---@field self mwseMCMExclusionsPage|mwseMCMFilterPage|mwseMCMMouseOverPage|mwseMCMPage|mwseMCMSideBarPage
---@field variable mwseMCMCustomVariable|mwseMCMVariable|nil
---@field config rotf.mcm.configPath
---@field customCallback nil|fun(newValue:boolean)

---@param params mwseMCMCategory.createYesNoButton.data|rotf.mcm.createYesNo
---@return mwseMCMYesNoButton
local function createYesNo(params)
    ---@type mwseMCMYesNoButton
    local button
    ---@type mwse.mcm.createCustom.variable
    local variable = params.variable or {}
    variable.setter = function(self, newValue)
        local path = params.config.path.."."..params.config.name
        if isShiftDown then
            config.resetValueToGlobal(path)
            button.elements.label.color = getSettingColor(false)
            button.elements.label:getTopLevelMenu():updateLayout()
        elseif isAltDown then
            config.setGlobalValueByPath(path, newValue)
            config.resetValueToGlobal(path)
            button.elements.label.color = getSettingColor(false)
            button.elements.label:getTopLevelMenu():updateLayout()
        else
            local configValue = config.getValueByPath(path)
            if configValue ~= newValue then
                if not config.setValueByPath(path, newValue) then
                    log("config value is not set", params.config.path.."."..params.config.name)
                end
                button.elements.label.color = getSettingColor(tes3.player)
                button.elements.label:getTopLevelMenu():updateLayout()
            end
        end
        if params.customCallback then params.customCallback(newValue) end
    end
    variable.getter = function(self)
        local path = params.config.path.."."..params.config.name
        local value = config.getValueByPath(path)
        if value == nil then log("config value not found", path) end
        return value or false
    end
    params.variable = mcm.createCustom(variable)
    button = params.self:createYesNoButton(params)
    button.postCreate = function(self)
        local path = params.config.path.."."..params.config.name
        local _, isLocal = config.getValueByPath(path)
        self.elements.label.color = getSettingColor(isLocal)
        self.elements.button:register("destroy", function()
            if isShiftDown then
                config.resetValueToGlobal(path)
            elseif isAltDown then
                local value, isLocal = config.getValueByPath(path) ---@diagnostic disable-line: redefined-local
                if isLocal then
                    config.setGlobalValueByPath(path, value)
                    config.resetValueToGlobal(path)
                end
            end
        end)
        self.elements.label:getTopLevelMenu():updateLayout()
    end
    return button
end

---@class rotf.mcm.minMax
---@field min number|nil
---@field max number|nil

---@class rotf.mcm.createNumberEdit
---@field self mwseMCMExclusionsPage|mwseMCMFilterPage|mwseMCMMouseOverPage|mwseMCMPage|mwseMCMSideBarPage
---@field variable mwseMCMCustomVariable|mwseMCMVariable|nil
---@field labelMaxWidth number|nil
---@field config rotf.mcm.configPath
---@field limits rotf.mcm.minMax|nil
---@field maxForLinkedGroup number|nil

---@param params mwseMCMCategory.createTextField.data|rotf.mcm.createNumberEdit
---@return mwseMCMTextField
local function createNumberEdit(params)

    if not params.limits then params.limits = {min = -math.huge, max = math.huge} end

    local path = params.config.path.."."..params.config.name

    ---@type mwseMCMTextField
    local field
    local label

    local function getConfigValue()
        local value = config.getValueByPath(path)
        if value == nil then log("config value not found", path) end
        return value or 0
    end

    local function resetValueToGlobal()
        field.elements.inputField.text = tostring(config.resetValueToGlobal(path))
        label.elements.label.color = getSettingColor(false)
        label.elements.label:getTopLevelMenu():updateLayout()
    end

    local function makeValueGlobal(val)
        config.setGlobalValueByPath(path, val)
        config.resetValueToGlobal(path)
        field.elements.inputField.text = tostring(val)
        label.elements.label.color = getSettingColor(false)
        label.elements.label:getTopLevelMenu():updateLayout()
    end

    local function setValue(value)
        local val = tonumber(value)
        if not val then return end
        if params.limits.max and params.limits.max < val then val = params.limits.max end
        if params.limits.min and params.limits.min > val then val = params.limits.min end
        local configValue = getConfigValue()
        if isShiftDown then
            resetValueToGlobal()
            for _, elem in pairs(field.customLinkedElements or {}) do
                if elem and elem ~= field then
                    elem.resetValueToGlobal()
                end
            end
            return
        -- elseif isAltDown then
        --     makeValueGlobal(val)
        --     for _, elem in pairs(field.customLinkedElements or {}) do
        --         if elem and elem ~= field then
        --             elem.makeValueGlobal(elem.customGetValue())
        --         end
        --     end
        --     return
        end
        if configValue ~= val or isAltDown then
            if not config.setValueByPath(path, val) then
                log("config value is not set", params.config.path.."."..params.config.name)
            end
            label.elements.label.color = getSettingColor(tes3.player)
            field.elements.inputField.text = tostring(val)

            if params.maxForLinkedGroup then
                local sum = 0
                for _, elem in pairs(field.customLinkedElements) do
                    if not elem then break end
                    local v = tonumber(elem.customGetValue()) or elem.customGetConfigValue()
                    if not v then break end
                    sum = sum + v
                end
                sum = sum + val - params.maxForLinkedGroup
                if sum > 0 then
                    for _, elem in pairs(field.customLinkedElements) do
                        local elemVal = tonumber(elem.customGetValue()) or elem.customGetConfigValue()
                        local v = math.min(elemVal, sum)
                        elem.customSetValue(elemVal - v)
                        if isAltDown then
                            elem.makeValueGlobal(elemVal - v)
                        end
                        sum = sum - v
                        if sum <= 0 then break end -- neat part
                    end
                end
            end
            if isAltDown then
                makeValueGlobal(val)
            end
            label.elements.label:getTopLevelMenu():updateLayout()
        end
    end

    local function getElementValue()
        return field.elements.inputField.text
    end

    local block = params.self:createSideBySideBlock{
        indent = 0,
        childIndent = 0,
        childSpacing = 1,
        description = params.description,
        inGameOnly = params.inGameOnly,
        paddingBottom = 0,
        postCreate = function(self)
            self.elements.subcomponentsContainer.childAlignX = 0.5
            self.elements.subcomponentsContainer.childAlignY = 0.5
        end
    }

    label = block:createInfo{
        label = params.label,
        description = params.description,
        postCreate = function(self)
            self.elements.info.minWidth = 100
            self.elements.info.maxWidth = params.labelMaxWidth or 250
            self.elements.info.borderBottom = 0
            local _, isLocal = config.getValueByPath(params.config.path.."."..params.config.name)
            self.elements.label.color = getSettingColor(isLocal)
        end
    }

    ---@type mwse.mcm.createCustom.variable
    local variable = params.variable or {}
    variable.setter = function(self, newValue)
        setValue(newValue)
    end
    variable.getter = function(self)
        return getConfigValue()
    end
    params.variable = mcm.createCustom(variable)
    params.numbersOnly = true
    ---@param self mwseMCMTextField
    params.postCreate = function(self)
        -- self.elements.submitButton:destroy()
        self.elements.inputField.justifyText = "right"
        self.elements.inputField.borderRight = 5
        self.elements.border.minWidth = 100
        self.elements.border.maxWidth = 100
        self.elements.inputField:register("destroy", function()
            setValue(self.elements.inputField.text)
        end)
    end
    params.paddingBottom = 0
    params.label = nil

    field = block:createTextField(params)

    local buttonBlock = block:createSideBySideBlock{
        indent = 0,
        childIndent = 0,
        childSpacing = 0,
        description = params.description,
        inGameOnly = params.inGameOnly,
        paddingBottom = 0,
        postCreate = function(self)
            self.elements.subcomponentsContainer.flowDirection = tes3.flowDirection.topToBottom
        end
    }
    buttonBlock:createButton{
        buttonText = "+",
        paddingBottom = 0,
        childIndent = 0,
        childSpacing = 0,
        indent = 0,
        postCreate = function(self)
            self.elements.button.autoWidth = false
            self.elements.button.width = 24
            self.elements.outerContainer.borderAllSides = 0
            self.elements.outerContainer.maxHeight = 24
            self.elements.outerContainer.maxWidth = 24
        end,
        callback = function(self)
            setValue((tonumber(field.elements.inputField.text) or 0) + 1)
        end
    }
    buttonBlock:createButton{
        buttonText = "-",
        paddingBottom = 0,
        childIndent = 0,
        childSpacing = 0,
        indent = 0,
        postCreate = function(self)
            self.elements.button.autoWidth = false
            self.elements.button.width = 24
            self.elements.outerContainer.borderAllSides = 0
            self.elements.outerContainer.maxHeight = 24
            self.elements.outerContainer.maxWidth = 24
        end,
        callback = function(self)
            setValue((tonumber(field.elements.inputField.text) or 0) - 1)
        end
    }

    field.resetValueToGlobal = resetValueToGlobal ---@diagnostic disable-line: inject-field
    field.makeValueGlobal = makeValueGlobal ---@diagnostic disable-line: inject-field
    field.customSetValue = setValue ---@diagnostic disable-line: inject-field
    field.customGetValue = getElementValue ---@diagnostic disable-line: inject-field
    field.customGetConfigValue = getConfigValue ---@diagnostic disable-line: inject-field
    field.customLinkedElements = {} ---@diagnostic disable-line: inject-field

    return field
end

-- ##################################################

local function registerTemplate(self)
    local modData = {}

	--- @param container tes3uiElement
	modData.onCreate = function(container)
		self:create(container)
		modData.onClose = self.onClose
	end

	--- @param searchText string
	--- @return boolean
	modData.onSearch = function(searchText)
		return self:onSearchInternal(searchText)
	end

	mwse.registerModConfig(self.name, modData)
	mwse.log("%s mod config registered", self.name)
    return modData
end

--- @param e keyDownEventData|mouseButtonDownEventData|mouseWheelEventData
local function keyDownEvent(e)
    if e.isShiftDown then
        isShiftDown = true
    end
    if e.isAltDown then
        isAltDown = true
    end
end

--- @param e keyDownEventData|mouseButtonDownEventData|mouseWheelEventData
local function keyUpEvent(e)
    if not e.isShiftDown then
        isShiftDown = false
    end
    if not e.isAltDown then
        isAltDown = false
    end
end

---@param e tes3uiElement
local function onClose(e)
    config.save()
    event.unregister(tes3.event.keyUp, keyUpEvent)
    event.unregister(tes3.event.keyDown, keyDownEvent)
end

local function onOpen()
    isShiftDown = false
    isAltDown = false
    if not event.isRegistered(tes3.event.keyUp, keyUpEvent) then
        event.register(tes3.event.keyUp, keyUpEvent)
    end
    if not event.isRegistered(tes3.event.keyDown, keyDownEvent) then
        event.register(tes3.event.keyDown, keyDownEvent)
    end
end

function this.registerModConfig()

    local template = mcm.createTemplate{name = "Remains of the Fallen", onClose = onClose, postCreate = onOpen}

    local mapPage = template:createPage{label = "Main"}
    createLabel{self = mapPage, label = "The settings related to spawning characters from other playthroughs", labelColor = tes3.palette.headerColor}
    createLabel{self = mapPage, label = "All the settings will be either local (individual for the character) "..
        "or global (will apply by default to each player character unless the setting has become local). "..
        "Local settings will be highlighted in yellow. "..
        "If you are ingame, any settings you change will become local. "..
        "If you want to reset a setting to global, hold down the shift key and change that setting. "..
        "If you want to set global value of the setting, hold down the alt key. "..
        "If you want to reset/set global on all settings from a tab, select this tab, hold down shift/alt and change the tab."
    }

    createYesNo{self = mapPage, config = {path = "map", name = "enabled"}, label = "Spawn died characters from other playthroughs"}
    createNumberEdit{self = mapPage, config = {path = "map.spawn", name = "count"}, label = "Number of attempts to spawn a character per cell (0 - disabled)", limits = {min = 0}}
    createNumberEdit{self = mapPage, config = {path = "map.spawn", name = "chance"}, label = "Chance to spawn per each attempt", limits = {min = 0, max = 100}}
    createNumberEdit{self = mapPage, config = {path = "map.spawn", name = "interval"}, label = "Interval in game hours between attempts", limits = {min = 0}}
    createNumberEdit{self = mapPage, config = {path = "map.spawn", name = "maxCount"}, label = "Maximum number of spawned characters per cell", limits = {min = 0}}
    createNumberEdit{self = mapPage, config = {path = "map.spawn", name = "playerCount"}, label = "Maximum number of spawned characters from same playthrough", limits = {min = 0}}

    local itemGroup = mapPage:createCategory{label = "Inventory of the spawned characters"}
    createYesNo{self = itemGroup, config = {path = "map.spawn.items.change", name = "enbaled"}, label = "Recreate items in the inventory of a created character with unique ids. It will prevent quest abuse"}
    createNumberEdit{self = itemGroup, config = {path = "map.spawn.items.change", name = "multiplier"}, label = "Multiplier for stats for these recreated items", limits = {min = 0, max = 1}}
    createNumberEdit{self = itemGroup, config = {path = "map.spawn.items.change", name = "costMul"}, label = "Multiplier for the value of these recreated items", limits = {min = 0, max = 1}}

    local bodyGroup = mapPage:createCategory{label = "Copy of the character"}
    createNumberEdit{self = bodyGroup, config = {path = "map.spawn.body", name = "chanceToCorpse"}, label = "Chance in % to kill the copy (it will spawn as a dead)", limits = {min = 0, max = 100}}
    createNumberEdit{self = bodyGroup, config = {path = "map.spawn.body.stats", name = "health"}, label = "Health multiplier (in %) for the copy", limits = {min = 0}}
    createNumberEdit{self = bodyGroup, config = {path = "map.spawn.body.stats", name = "fatigue"}, label = "Fatigue multiplier (in %) for the copy", limits = {min = 0}}
    createNumberEdit{self = bodyGroup, config = {path = "map.spawn.body.stats", name = "magicka"}, label = "Magicka multiplier (in %) for the copy", limits = {min = 0}}

    -- local creaGroup = mapPage:createCategory{label = "Creature with the player's stats"}
    -- local spawnCrea = createNumberEdit{self = creaGroup, config = {path = "map.spawn.creature", name = "chance"}, label = "Chance in % to create a creature with the player's stats", limits = {min = 0, max = 100}, maxForLinkedGroup = 100}
    -- createNumberEdit{self = creaGroup, config = {path = "map.spawn.creature", name = "chanceToCorpse"}, label = "Chance in % to kill the creature (it will spawn as a dead)", limits = {min = 0, max = 100}}
    -- createNumberEdit{self = creaGroup, config = {path = "map.spawn.creature.stats", name = "health"}, label = "Health multiplier (in %) for the creature", limits = {min = 0}}
    -- createNumberEdit{self = creaGroup, config = {path = "map.spawn.creature.stats", name = "fatigue"}, label = "Fatigue multiplier (in %) for the creature", limits = {min = 0}}
    -- createNumberEdit{self = creaGroup, config = {path = "map.spawn.creature.stats", name = "magicka"}, label = "Magicka multiplier (in %) for the creature", limits = {min = 0}}
    -- table.insert(spawnBody.customLinkedElements, spawnCrea) ---@diagnostic disable-line: undefined-field
    -- table.insert(spawnCrea.customLinkedElements, spawnBody) ---@diagnostic disable-line: undefined-field

    local transferGroup = mapPage:createCategory{label = "Transferring items to the copy"}
    createLabel{self = transferGroup, label = "Most of the settings below are number (or percentage) of item stacks in the inventory of dead character. Each stack may contain several identical items"}
    createYesNo{self = transferGroup, config = {path = "map.spawn.transfer", name = "inPersent"}, label = "Transfer percentage of items instead of quantity"}
    createNumberEdit{self = transferGroup, config = {path = "map.spawn.transfer", name = "equipedItems"}, label = "Transfer this number or % of equipped items", limits = {min = 0, max = 100}}
    createNumberEdit{self = transferGroup, config = {path = "map.spawn.transfer", name = "equipment"}, label = "Transfer this number or % of items that you can equip but are currently unequipped", limits = {min = 0, max = 100}}
    createNumberEdit{self = transferGroup, config = {path = "map.spawn.transfer", name = "magicItems"}, label = "Transfer this number or % of items like scrolls or potions", limits = {min = 0, max = 100}}
    -- createNumberEdit{self = transferGroup, config = {path = "map.spawn.transfer", name = "misc"}, label = "Transfer this number or % of miscellaneous items", limits = {min = 0, max = 100}}
    -- createNumberEdit{self = transferGroup, config = {path = "map.spawn.transfer", name = "books"}, label = "Transfer this number or % of books", limits = {min = 0, max = 100}}
    -- createNumberEdit{self = transferGroup, config = {path = "map.spawn.transfer", name = "goldPercent"}, label = "Transfer this % of gold", limits = {min = 0, max = 100}}

    -- template:register()
    this.modData = registerTemplate(template)
end

event.register(tes3.event.modConfigReady, this.registerModConfig)

return this