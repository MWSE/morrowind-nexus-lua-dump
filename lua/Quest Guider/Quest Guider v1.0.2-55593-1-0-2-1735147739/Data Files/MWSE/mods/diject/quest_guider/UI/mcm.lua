local config = include("diject.quest_guider.config")
local log = include("diject.quest_guider.utils.log")

local markerIconInfo = include("diject.quest_guider.markers")

local mcm = mwse.mcm

local this = {}

---@class questGuider.mcm.createLabel
---@field self mwseMCMExclusionsPage|mwseMCMFilterPage|mwseMCMMouseOverPage|mwseMCMPage|mwseMCMSideBarPage
---@field labelColor tes3.palette|string|nil
---@field textColor tes3.palette|string|nil

---@param params mwseMCMCategory.createInfo.data|questGuider.mcm.createLabel
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


---@class questGuider.mcm.configPath
---@field path string table with the value
---@field name string the value

---@class questGuider.mcm.createYesNo
---@field self mwseMCMExclusionsPage|mwseMCMFilterPage|mwseMCMMouseOverPage|mwseMCMPage|mwseMCMSideBarPage
---@field variable mwseMCMCustomVariable|mwseMCMVariable|nil
---@field config questGuider.mcm.configPath
---@field customCallback nil|fun(newValue:boolean)

---@param params mwseMCMCategory.createYesNoButton.data|questGuider.mcm.createYesNo
---@return mwseMCMYesNoButton
local function createYesNo(params)
    ---@type mwseMCMYesNoButton
    local button
    ---@type mwse.mcm.createCustom.variable
    local variable = params.variable or {}

    variable.setter = function(self, newValue)
        local path = params.config.path.."."..params.config.name

        local configValue = config.getValueByPath(path)
        if configValue ~= newValue then
            if not config.setValueByPath(path, newValue) then
                log("config value is not set", path)
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

    return button
end

---@class questGuider.mcm.minMax
---@field min number|nil
---@field max number|nil

---@class questGuider.mcm.createNumberEdit
---@field self mwseMCMExclusionsPage|mwseMCMFilterPage|mwseMCMMouseOverPage|mwseMCMPage|mwseMCMSideBarPage
---@field variable mwseMCMCustomVariable|mwseMCMVariable|nil
---@field labelMaxWidth number|nil
---@field config questGuider.mcm.configPath
---@field limits questGuider.mcm.minMax|nil
---@field maxForLinkedGroup number|nil
---@field int boolean|nil

---@param params mwseMCMCategory.createTextField.data|questGuider.mcm.createNumberEdit
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

    local function setValue(value)
        local val = tonumber(value)
        if not val then return end
        if params.int then val = math.floor(val) end
        if params.limits.max and params.limits.max < val then val = params.limits.max end
        if params.limits.min and params.limits.min > val then val = params.limits.min end
        local configValue = getConfigValue()

        if configValue ~= val then
            if not config.setValueByPath(path, val) then
                log("config value is not set", params.config.path.."."..params.config.name)
            end

            field.elements.inputField.text = tostring(val)

            if params.maxForLinkedGroup then
                local sum = 0
                for _, elem in pairs(field.customLinkedElements) do
                    if not elem then break end
                    local v = tonumber(elem.customGetValue()) or elem.customGetConfigValue()
                    if not v then break end
                    if params.int then v = math.floor(v) end
                    sum = sum + v
                end
                sum = sum + val - params.maxForLinkedGroup
                if sum > 0 then
                    for _, elem in pairs(field.customLinkedElements) do
                        local elemVal = tonumber(elem.customGetValue()) or elem.customGetConfigValue()
                        local v = math.min(elemVal, sum)
                        if params.int then v = math.floor(v) end
                        elem.customSetValue(elemVal - v)
                        sum = sum - v
                        if sum <= 0 then break end -- neat part
                    end
                end
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

    field.customSetValue = setValue ---@diagnostic disable-line: inject-field
    field.customGetValue = getElementValue ---@diagnostic disable-line: inject-field
    field.customGetConfigValue = getConfigValue ---@diagnostic disable-line: inject-field
    field.customLinkedElements = {} ---@diagnostic disable-line: inject-field

    return field
end



local function onSearch(searchText)
    local text = searchText:lower()
    if text:find("quest") or text:find("guider") or text:find("map") or text:find("marker") then
        return true
    end
    return false
end

local function onClose()
    config.save()
end

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

function this.registerModConfig()

    local template = mcm.createTemplate{name = "Quest Guider", onSearch = onSearch, onClose = onClose}

    do
        local mainPage = template:createPage{label = "Main"}

        createLabel{self = mainPage, label = "Quest info, markers and more.", labelColor = tes3.palette.headerColor}
        createYesNo{self = mainPage, config = {path = "main", name = "enabled"}, label = "Enable the mod"}

        local dataGenGroup = mainPage:createCategory{label = "Data generation"}
        createLabel{self = dataGenGroup, label = "The mod requires data that is generated through a separate application"}
        dataGenGroup:createButton{buttonText = "Generate data for the mod", callback = function()
            include("diject.quest_guider.UI.dataGenerator").createMenu{}
        end}
        dataGenGroup:createButton{buttonText = "Show quick init menu", callback = function()
            include("diject.quest_guider.UI.quickInitMenu").show()
        end}
    end

    do
        local dataPage = template:createPage{label = "Data"}
        createNumberEdit{self = dataPage, config = {
            path = "data", name = "maxPos"},
            label = "Limits the maximum number of positions for an tracked object in generated data. Affects mainly only markers for the world map and some descriptions. Requires data re-genereation",
            limits = {min = 1, max = 10000}
        }
        dataPage:createButton{buttonText = "Generate data for the mod", callback = function()
            include("diject.quest_guider.UI.dataGenerator").createMenu{}
        end}
    end

    do
        local journalPage = template:createPage{label = "Journal"}

        createYesNo{self = journalPage, config = {path = "journal", name = "enabled"}, label = "Integrate the mod to the game Journal menu"}

        local infoLabelGroup = journalPage:createCategory{label = "Info about name and stages of a quest"}
        createYesNo{self = infoLabelGroup, config = {path = "journal.info", name = "enabled"}, label = "Enable"}
        createYesNo{self = infoLabelGroup, config = {path = "journal.info", name = "tooltip"}, label = "Show as a tooltip"}

        local mapLabelGroup = journalPage:createCategory{label = "Info about location of quest objects and about requirements"}
        createYesNo{self = mapLabelGroup, config = {path = "journal.map", name = "enabled"}, label = "Enable"}
        createYesNo{self = mapLabelGroup, config = {path = "journal.map", name = "tooltip"}, label = "Show as a tooltip"}
        createNumberEdit{self = mapLabelGroup, config = {path = "journal.map", name = "maxScale"}, label = "Maximum scale value for the map", limits = {min = 1, max = 5}}

        local reqLabelGroup = journalPage:createCategory{label = "Menu about quest requirements"}
        createYesNo{self = reqLabelGroup, config = {path = "journal.requirements", name = "enabled"},
            label = "Show a separate icon for the requirements without info about their location"}
        createYesNo{self = reqLabelGroup, config = {path = "journal.requirements", name = "tooltip"}, label = "Show as a tooltip"}
        createYesNo{self = reqLabelGroup, config = {path = "journal.requirements", name = "currentByDefault"},
            label = "Show info about the current quest stage instead of information about the stage to which this entry corresponds"}
        createYesNo{self = reqLabelGroup, config = {path = "journal.requirements", name = "scriptValues"}, label = "Show info about local variables of involved scripts"}

        createNumberEdit{self = journalPage, config = {path = "journal", name = "objectNames"},
            label = "Maximum number of object names in a tooltip or a field", limits = {min = 0, max = 10}}
        createNumberEdit{self = journalPage, config = {path = "journal.requirements", name = "pathDescriptions"},
            label = "Maximum number of path descriptions on a requirement label", limits = {min = 0, max = 10}}
    end

    do
        local trackingPage = template:createPage{label = "Tracking"}
        createYesNo{self = trackingPage, config = {path = "tracking.quest", name = "enabled"}, label = "Auto track quest objects when a new journal entry has been added"}
        createYesNo{self = trackingPage, config = {path = "tracking.quest", name = "finished"}, label = "Auto track next stages from finished quests. In most of cases, these stages are just different endings of the quest. But sometimes they are useful (but too rarely)"}
        createYesNo{self = trackingPage, config = {path = "map", name = "enabled"}, label = "Integrate tracking info to the game Map menu"}
        createYesNo{self = trackingPage, config = {path = "map", name = "showJournalTextTooltip"},
            label = "Show a tooltip about current journal entry in the map menu. (The game may briefly stutter when you start tracking an object if the game is on HDD)"}
        createNumberEdit{self = trackingPage, config = {path = "tracking", name = "maxPositions"},
            label = "Don't create markers on the world map for objects that have more copies in the world than the value", limits = {min = 1, max = 10000}, int = true}
        createNumberEdit{
            self = trackingPage, config = {path = "tracking", name = "maxCellDepth"},
            label = "Depth in game cells to which markers for doors in interior cells are looked for. The larger the value and the more adjacent interior cells, the longer it will take to calculate (the game will lag when loading or starting to track in interior cells)",
            limits = {min = 1, max = 30}, int = true
        }

        local giverGroup = trackingPage:createCategory{label = "Quest givers"}
        createYesNo{self = giverGroup, config = {path = "tracking.giver", name = "enabled"},
            label = "Mark quest givers on the map (the mod doesn't check if you can take these quests)"}
        createYesNo{self = giverGroup, config = {path = "tracking.giver", name = "hideStarted"}, label = "Hide markers for quests that have already been started/finished"}
        createNumberEdit{self = giverGroup, config = {path = "tracking.giver", name = "namesMax"},
            label = "Maximum number of quest names in the tooltip for a marker", limits = {min = 1, max = 10}, int = true}
    end

    do
        local tooltipsPage = template:createPage{label = "Tooltips"}

        createNumberEdit{self = tooltipsPage, config = {path = "tooltip", name = "width"}, label = "Tooltip width", limits = {min = 300, max = 800}, int = true}

        local objectGroup = tooltipsPage:createCategory{label = "Tooltip on an object"}
        createYesNo{self = objectGroup, config = {path = "tooltip.object", name = "enabled"}, label = "Enable"}
        createNumberEdit{self = objectGroup, config = {path = "tooltip.object", name = "invNamesMax"},
            label = "Maximum number of names of quests in which the object is involved, displayed in the tooltip", limits = {min = 0, max = 10}, int = true}
        createNumberEdit{self = objectGroup, config = {path = "tooltip.object", name = "startsNamesMax"},
            label = "Maximum number of names of quests the object can start, displayed in the tooltip", limits = {min = 0, max = 10}, int = true}

        local doorGroup = tooltipsPage:createCategory{label = "Tooltip on a door to a location"}
        createYesNo{self = doorGroup, config = {path = "tooltip.door", name = "enabled"}, label = "Enable"}
        createNumberEdit{self = doorGroup, config = {path = "tooltip.door", name = "starterNames"},
            label = "Maximum number of names of objects (NPCs) that are in the location and can start a quest, displayed in the tooltip", limits = {min = 0, max = 10}, int = true}
        createNumberEdit{self = doorGroup, config = {path = "tooltip.door", name = "starterQuestNames"},
            label = "Maximum number of names of quests that can be started in a location, displayed in the tooltip", limits = {min = 0, max = 10}, int = true}
        createNumberEdit{self = doorGroup, config = {path = "tooltip.door", name = "objectNames"},
            label = "Maximum number of names of objects that are in the location and involved to a quest, displayed in the tooltip", limits = {min = 0, max = 10}, int = true}
        createNumberEdit{self = doorGroup, config = {path = "tooltip.door", name = "npcNames"},
            label = "Maximum number of names of NPCs that are in the location and involved to a quest, displayed in the tooltip", limits = {min = 0, max = 10}, int = true}

        createNumberEdit{self = tooltipsPage, config = {path = "tooltip.tracking", name = "maxPositions"},
            label = "Don't show info about quest items that have more copies in the world than the value", limits = {min = 1, max = 10000}, int = true}
    end

    do
        local otherPage = template:createPage{label = "Other"}

        ---@type mwseMCMDropdownOption[]
        local options = {}

        for _, id in pairs(markerIconInfo.getIds()) do
            local name = markerIconInfo.getName(id) or id
            ---@type mwseMCMDropdownOption
            local option = {
                label = name,
                value = id,
                callback = function (self)
                    markerIconInfo.apply(id)
                end
            }

            table.insert(options, option)
        end

        otherPage:createDropdown{
            label = "Marker icons. !Will only affect newly created markers",
            options = options,
            variable = mcm.createTableVariable{
                id = "iconProfile",
                table = config.data.main
            }
        }

        createYesNo{self = otherPage, config = {path = "main", name = "helpLabels"}, label = "Show help info in menus"}
    end

    -- template:register()
    this.modData = registerTemplate(template)
end

return this