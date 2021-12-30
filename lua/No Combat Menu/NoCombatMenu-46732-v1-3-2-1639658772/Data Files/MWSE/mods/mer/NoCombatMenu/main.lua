
local CONFIG_PATH = "noCombatMenu"
local IN_COMBAT_MESSAGE = "You are in combat."
local DEVICE_KEYBOARD = 0
local DEVICE_MOUSE = 1
local BUTTONS_TO_BLOCK = {
    tes3.keybind.menuMode,
    tes3.keybind.quickMenu,
}
local HOSTILE_OBJECT_TYPES = {
    [tes3.objectType.npc] = true,
    [tes3.objectType.creature] = true,
}

local config = mwse.loadConfig(CONFIG_PATH, {
    enable = true,
    safeDistance = 1000,
    logLevel = "INFO"
})

local logger = require("mer.NoCombatMenu.logger").new{
    name = "No Combat Menu",
    logLevel = config.logLevel
}


local function getDeviceName(device)
    if device == DEVICE_KEYBOARD then
        return "Keyboard"
    elseif device == DEVICE_MOUSE then
        return "Mouse"
    end
    logger:error("Unknown device: " .. device)
    return "Unknown"
end

local function showInCombatMessage()
    tes3.messageBox(IN_COMBAT_MESSAGE)
end

local function isHostile(enemy)
    if not enemy.mobile then return end
    if not HOSTILE_OBJECT_TYPES[enemy.baseObject.objectType] then return end
    --Check enemy's hostile actors for the player
    local playerInHostileList
    for actor in tes3.iterate(enemy.mobile.hostileActors) do
        if actor.reference == tes3.player then
            playerInHostileList = true
            break
        end
    end
    if enemy.mobile.inCombat and playerInHostileList then
        return true
    end
    return false
end

local function getEnemyDistance(enemy)
    return tes3.player.mobile.position:distance(enemy.position)
end

local function getDistanceOfClosestEnemy()
    --Find nearest enemy
    local minDistance = math.huge
    for _, cell in ipairs(tes3.getActiveCells()) do
        for objectType, _ in pairs(HOSTILE_OBJECT_TYPES) do
            for enemy in cell:iterateReferences(objectType) do
                if isHostile(enemy) then
                    local hostileDistance = getEnemyDistance(enemy)
                    minDistance = math.min(minDistance, hostileDistance)
                end
            end
        end
    end
    return minDistance
end

local function checkInCombat()
    if not config.enable then return false end
    local inCombat = true
    local minDistance = getDistanceOfClosestEnemy()
    if minDistance >= config.safeDistance then
        inCombat = false
    end
    return inCombat
end

---@param reference tes3reference
local function getLootableTarget(reference)
    local isContainer = reference.baseObject.objectType == tes3.objectType.container
    local isDead = reference.mobile and reference.mobile.isDead
    return isContainer or isDead
end

local function onActivate(e)
    if getLootableTarget(e.target) then
        if checkInCombat() then
            showInCombatMessage()
            return false
        end
    end
end

event.register("activate", onActivate)

local function isBlockedButtonPressed(buttonPressed, device)
    for _, keybind in ipairs(BUTTONS_TO_BLOCK) do
        local inputBinding = tes3.getInputBinding(keybind)
        local isButton = buttonPressed == inputBinding.code
        local isDevice = inputBinding.device == device
        if isButton and isDevice then
            return true
        end
    end
    return false
end

local function getButtonStateData()
    tes3.player.tempData.noCombatMenuButtonState = tes3.player.tempData.noCombatMenuButtonState or {
        [DEVICE_KEYBOARD] = {},
        [DEVICE_MOUSE] = {}
    }
    return tes3.player.tempData.noCombatMenuButtonState
end

local function setButtonPressed(button, device)
    getButtonStateData()[device][tostring(button)] = true
end

local function unsetButtonPressed(button, device)
    getButtonStateData()[device][tostring(button)] = nil
end

local function getButtonPressed(button, device)
    return getButtonStateData()[device][tostring(button)] == true
end


local function doBlockButton(button, device)
    logger:debug("%s Button Blocked: %s", button, getDeviceName(device))
    if device == DEVICE_KEYBOARD then
        tes3.worldController.inputController.keyboardState[button +1] = 0
    else
        tes3.worldController.inputController.mouseState.buttons[button +1] = 0
    end
end

local function checkBlockButton(button, device)
    if not tes3.player then return end
    if isBlockedButtonPressed(button, device) then
        logger:debug("ButtonDown: %s, device: %s", button, getDeviceName(device))
        if getButtonPressed(button, device) then
            logger:debug("button %s already blocked", button, getDeviceName(device))
            doBlockButton(button, device)
        elseif checkInCombat() then
            showInCombatMessage()
            setButtonPressed(button, device)
            doBlockButton(button, device)
            timer.start{
                duration = 1.0,
                callback = function()
                    unsetButtonPressed(button, device)
                end
            }
        end
    end
end

---@param e mouseButtonDownEventData
local function onMouseButtonDown(e)
    checkBlockButton(e.button, DEVICE_MOUSE)
end
event.register("mouseButtonDown", onMouseButtonDown)


---@param e keyDownEventData
local function onKeyDown(e)
    checkBlockButton(e.keyCode, DEVICE_KEYBOARD)
end
event.register("keyDown", onKeyDown)


------------------------------------------------------
--MCM
------------------------------------------------------
local sidebarDefault = (
    "No Combat Menu prevents you from accessing your inventory menu, " ..
    "as well as preventing looting containers/corpses, while you are in combat. \n" ..
    "Yes, this makes combat significantly more difficult. You will need to plan " ..
    "ahead and make strategic use of your quick keys, as they are your only " ..
    "way into your inventory. And no, you can not change your quick keys while " ..
    "in combat either. "
)

local function addSideBar(component)
    component.sidebar:createInfo{ text = sidebarDefault }
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

local function makeVar(id, numbersOnly)
    return mwse.mcm.createTableVariable{
        id = id,
        table = config,
        numbersOnly = numbersOnly
    }
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate("No Combat Menu")
    template:saveOnClose(CONFIG_PATH, config)
    template:register()

    local page = template:createSideBarPage()
    addSideBar(page)

    page:createOnOffButton{
        label = "Enable No Combat Menu",
        description = "Turn this mod on or off.",
        variable = makeVar("enable")
    }

    page:createSlider{
        label = "Safe Distance",
        description = "The distance from the nearest enemy at which you can access your inventory.",
        variable = makeVar("safeDistance"),
        min = 0,
        max = 10000,
        jump = 1000,
        step = 1
    }

    page:createDropdown{
        label = "Logging Level",
        description = "Set the log level.",
        options = {
            { label = "Trace", value = "TRACE"},
            { label = "Debug", value = "DEBUG"},
            { label = "Info", value = "INFO"},
            { label = "Error", value = "ERROR"},
            { label = "None", value = "NONE"},
        },
        variable = mwse.mcm.createTableVariable{ id = "logLevel", table = config },
        callback = function(self)
            logger:setLogLevel(self.variable.value)
        end
    }
end

event.register("modConfigReady", registerModConfig)