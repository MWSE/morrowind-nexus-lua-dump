local config = require("mer.beenThere.config")

local logger = require("logging.logger").new{
    name = string.format(config.modName),
    logLevel = config.mcm.logLevel
}

---@param ref tes3reference
local function refIsHostile(ref)
    logger:trace("Checking if %s is hostile", ref)
    local mobile = ref.mobile
    if mobile then
        local hostile = mobile.fight >= config.minActorAiFightTrigger
        if hostile then
            logger:trace("- Ref is hostile")
            return true
        end
    end
    logger:trace("- Ref is not hostile")
    return false
end

---@param ref tes3reference
local function refIsAlive(ref)
    local mobile = ref.mobile
    if mobile then
        if not mobile.isDead then
            return true
        end
    end
    return false
end

---@param cell tes3cell
local function cellHasHostiles(cell)
    logger:debug("Checking if %s has hostiles", cell)
    ---@param ref tes3reference
    for _, ref in pairs(cell.actors) do
        if refIsAlive(ref) and refIsHostile(ref) then
            logger:debug("- Cell has hostiles")
            return true
        end
    end
    logger:debug("- Cell does not have hostiles")
    return false
end

local function setMapMenuLabel()
    if not tes3.player then return end
    local cellId = tes3.player.cell.id:lower()
    logger:debug("menuEnter: Checking if %s is cleared", cellId)

    local mapMenu = tes3ui.findMenu("MenuMap")
    if not (mapMenu and mapMenu) then
        logger:trace("MapMenu doesn't exist")
        return
    end
    logger:trace("MapMenu activated for cleared cell")
    local cellLabel = mapMenu:findChild("PartDragMenu_title")
    if not cellLabel then return end
    local enabled = config.mcm.enabled
    local isCleared = (config.persistent.dungeons[cellId] == "cleared") and enabled
    local hasCleared = string.endswith(cellLabel.text, ' (Cleared)')
    if hasCleared and not isCleared then
        --remove cleared
        logger:debug("Removing cleared label from %s", cellId)
        cellLabel.text = string.sub(cellLabel.text, 1, -11)
    end
    if (not hasCleared) and isCleared then
        --add cleared
        logger:debug("Adding cleared label to %s", cellId)
        cellLabel.text = cellLabel.text .. " (Cleared)"
    end
end

--[[
    When entering a cell, check if there are hostiles
    First time entering a cell, set it to invalid if there are no hostiles
]]
---@param e cellChangedEventData
event.register("cellChanged", function(e)
    logger:trace("Checking if %s has hostiles", e.cell)
    if not e.cell.isInterior then return end
    local currentStatus = config.persistent.dungeons[e.cell.id:lower()]
    if currentStatus == "invalid" then
        logger:debug("Cell %s is invalid", e.cell)
        return
    end
    if cellHasHostiles(e.cell) then
        logger:debug("Setting %s to uncleared", e.cell)
        config.persistent.dungeons[e.cell.id:lower()] = "uncleared"
    else
        if currentStatus == nil then
            logger:debug("Setting %s to invalid", e.cell)
            config.persistent.dungeons[e.cell.id:lower()] = "invalid"
        elseif currentStatus == "uncleared" then
            logger:debug("Setting %s to cleared", e.cell)
            config.persistent.dungeons[e.cell.id:lower()] = "cleared"
        end
    end
    setMapMenuLabel()
end)

--[[
    When killing an enemy, check if it was the last hostile
    in the cell, and set the cell to cleared
]]
---@param e deathEventData
event.register("death", function(e)
    logger:trace("Checking if %s is the last hostile in %s", e.reference, e.reference.cell)
    if not e.reference then return end
    if not e.reference.cell.isInterior then return end
    if config.persistent.dungeons[e.reference.cell.id:lower()] == "invalid" then return end
    if not refIsHostile(e.reference) then return end
    if not cellHasHostiles(e.reference.cell) then
        logger:debug("Setting %s to cleared", e.reference.cell)
        config.persistent.dungeons[e.reference.cell.id:lower()] = "cleared"
        setMapMenuLabel()
    end
end)

--[[
    When a mobile is activated and a cell has been cleared,
    check if its hostile and unclear the cell
]]
---@param e mobileActivatedEventData
event.register("mobileActivated", function(e)
    logger:trace("Checking if %s is hostile", e.reference)
    if not e.reference then return end
    if not e.reference.cell.isInterior then return end
    if config.persistent.dungeons[e.reference.cell.id:lower()] == "invalid" then return end
    if not refIsHostile(e.reference) then return end
    if config.persistent.dungeons[e.reference.cell.id:lower()] == "cleared" then
        logger:debug("Setting %s to uncleared", e.reference.cell)
        config.persistent.dungeons[e.reference.cell.id:lower()] = "uncleared"
        setMapMenuLabel()
    end
end)

--[[
    When looking at a door, check if target cell is cleared
    and add "cleared" label to tooltip
]]
---@param e uiObjectTooltipEventData
event.register("uiObjectTooltip", function(e)
    if not config.mcm.enabled then return end
    if not e.object then return end
    if e.object.objectType ~= tes3.objectType.door then return end
    logger:trace("Looking at door")
    local targetCell = e.reference
        and e.reference.destination
        and e.reference.destination.cell
    if not targetCell then return end
    logger:trace("Target cell is %s", targetCell)
    if config.persistent.dungeons[e.reference.destination.cell.id:lower()] == "cleared" then
        logger:debug("Adding cleared label to tooltip")
        local destinationLabel = e.tooltip:findChild("HelpMenu_destinationCell")
        if not destinationLabel then return end
        destinationLabel.text = destinationLabel.text .. " (Cleared)"
    end
end)

--[[
    When the MapMenu is activated, add "Cleared" to the cell name
]]
event.register("menuEnter", setMapMenuLabel)

local function registerMCM()
    local function addSideBar(component)
        component.sidebar:createInfo{ text = config.modDescription}
        component.sidebar:createHyperLink{
            text = "Made by Merlord",
            exec = "start https://www.nexusmods.com/users/3040468?tab=user+files",
            postCreate = (
                function(self)
                    self.elements.outerContainer.borderAllSides = self.indent
                    self.elements.outerContainer.alignY = 1.0
                    self.elements.outerContainer.layoutHeightFraction = 1.0
                    self.elements.info.layoutOriginFractionX = 0.5
                end
            ),
        }
    end

    local template = mwse.mcm:createTemplate("Been There Done That")
    template.onClose = function()
        config.save()
    end
    template:register()
    local page = template:createSideBarPage()
    addSideBar(page)
    page:createOnOffButton{
        label = "Enable Mod",
        description = "Enable the mod.",
        variable = mwse.mcm.createTableVariable{
            id = "enabled",
            table = config.mcm,
        },
        callback = setMapMenuLabel,
    }

    page:createDropdown{
        label = "Log Level",
        description = "Set the logging level for mwse.log. Keep on INFO unless you are debugging.",
        options = {
            { label = "TRACE", value = "TRACE"},
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
            { label = "ERROR", value = "ERROR"},
            { label = "NONE", value = "NONE"},
        },
        variable =  mwse.mcm.createTableVariable{ id = "logLevel", table = config.mcm },
        callback = function(self)
            logger.logLevel = self.variable.value
        end,
    }
end
event.register("modConfigReady", registerMCM)