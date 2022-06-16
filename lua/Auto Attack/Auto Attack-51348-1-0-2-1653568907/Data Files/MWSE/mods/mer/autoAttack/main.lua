require("mer.autoAttack.mcm")

local util = require("mer.autoAttack.util")
local config = util.config
local logger = util.createLogger("main")
local attackToggled = false

---@param e keyDownEventData
local function onKeyDown(e)
    if not config.mcm.enabled then return end
    if not tes3.player then return end
    if not tes3.player.mobile then return end
    if not tes3.player.mobile.weaponDrawn then return end
    if util.isKeyPressed(e, config.mcm.hotKey) then
        attackToggled = not attackToggled
        logger:debug("Toggling Auto-Attack %s", attackToggled and "on" or "off")
        if config.mcm.displayMessages then
            tes3.messageBox("Auto-Attack %s.", attackToggled and "On" or "Off")
        end
    end
end


local function getAttackKeyConfig()
    local inputController = tes3.worldController.inputController
    ---@type tes3inputConfig
    local attackConfig = inputController.inputMaps[config.static.useKeyOptionIndex]
    return attackConfig
end

local function getPlayerAtMaxSwing()
    local attackSwing = tes3.mobilePlayer.animationController:calculateAttackSwing()
    local atMaxSwing = attackSwing >= math.max(1, config.mcm.maxSwing) / 100
    logger:trace("At Max Swing: %s", atMaxSwing)
    return atMaxSwing
end

---@param e simulateEventData
local function onSimulate(e)
    if not config.mcm.enabled then return end
    if not attackToggled then return end
    if not tes3.player.mobile then return end
    if not tes3.player.mobile.weaponDrawn then return end

    local inputController = tes3.worldController.inputController
    local attackConfig = getAttackKeyConfig()
    local attackSwing = tes3.player.mobile.actionData.attackSwing
    logger:trace("AttackSwing: %s", attackSwing)

    --Mouse
    if attackConfig.device == config.static.deviceMouse then
        local state = getPlayerAtMaxSwing() and 0 or config.static.buttonDown
        logger:trace("Setting state to %s", state)
        inputController.mouseState.buttons[attackConfig.code + 1] = state
    --Keyboard
    elseif attackConfig.device == config.static.deviceKeyboard then
        local state = getPlayerAtMaxSwing() and 0 or config.static.buttonDown
        logger:trace("Setting state to %s", state)
        inputController.keyboardState[attackConfig.code + 1] = state
    end
end


local function initialise()
    event.register(tes3.event.keyDown, onKeyDown)
    event.register(tes3.event.simulate, onSimulate)
    logger:info("Initialised: %s", util.getVersion())
end
event.register(tes3.event.initialized, initialise)