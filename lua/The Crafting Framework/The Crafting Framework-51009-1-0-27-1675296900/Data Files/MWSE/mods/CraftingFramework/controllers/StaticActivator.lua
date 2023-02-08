local Craftable = require("CraftingFramework.components.Craftable")
local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("StaticActivator")
local config = require("CraftingFramework.config")
local uiCommon = require("CraftingFramework.util.uiCommon")

local isBlocked
local function blockScriptedActivate(e)
    logger:debug("BlockScriptedActivate doBlock: %s", e.doBlock)
    isBlocked = e.doBlock
end
event.register("BlockScriptedActivate", blockScriptedActivate)

local function createActivatorIndicator(reference)
    local craftable
    if reference then
        craftable = Craftable.getPlacedCraftable(reference.object.id)
    end
    local hasName = reference and reference.object.name and reference.object.name ~= ""
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    local showIndicator = menu and craftable and not hasName
    if showIndicator then
        local headerText = craftable and craftable:getName()
        uiCommon.createOrUpdateTooltipMenu(headerText)
    else
        uiCommon.disableTooltipMenu()
    end
end

local function callRayTest(e)
    local eyePos = tes3.getPlayerEyePosition()
    local eyeDirection = tes3.getPlayerEyeVector()
    --If in menu, use cursor position
    if tes3ui.menuMode() then
        local inventory = tes3ui.findMenu("MenuInventory")
        local inventoryVisible = inventory and inventory.visible == true
        if inventoryVisible then
            local cursor = tes3.getCursorPosition()
            local camera = tes3.worldController.worldCamera.camera
            eyePos, eyeDirection = camera:windowPointToRay{cursor.x, cursor.y}
        end
    end

    if not (eyeDirection or eyeDirection) then return end
    local activationDistance = tes3.getPlayerActivationDistance()
    local result = tes3.rayTest{
        position = eyePos,
        direction = eyeDirection,
        ignore = { tes3.player },
        maxDistance = activationDistance,
    }
    if e.eventName then
        local eventData = {
            rayResult = result,
            reference = result and result.reference
        }
        event.trigger(e.eventName, eventData)
    end
    if result and result.reference and result.reference.data and result.reference.data.crafted then
        createActivatorIndicator(result.reference)
        return result.reference
    end
    createActivatorIndicator()
end

local function startIndicatorTimer()
    logger:debug("Starting activation indicator timer")
    timer.start{
        duration = 0.1,
        type = timer.real,
        iterations = -1,
        callback = function()
            callRayTest{
                eventName = "CraftingFramework:StaticActivatorIndicator"
            }
        end
    }
end
event.register("loaded", startIndicatorTimer)

local function doTriggerActivate()
    local activationBlocked =
        config.persistent.positioningActive
        or isBlocked
        or tes3ui.menuMode()
        or tes3.mobilePlayer.controlsDisabled
    if not activationBlocked then
        logger:debug("Triggered Activate")
        local ref = callRayTest{
            eventName = "CraftingFramework:StaticActivation"
        }
        if ref then
            event.trigger("BlockScriptedActivate", { doBlock = true })
            timer.delayOneFrame(function()
                event.trigger("BlockScriptedActivate", { doBlock = false })
            end)
            local eventData = {
                reference = ref
            }
            event.trigger("CraftingFramework:CraftableActivated", eventData, { filter = ref.baseObject.id:lower() })
        end
    end
end

local function triggerActivateKey(e)
    if (e.keyCode == tes3.getInputBinding(tes3.keybind.activate).code) and (tes3.getInputBinding(tes3.keybind.activate).device == 0) then
        doTriggerActivate()
    end
end
event.register("keyDown", triggerActivateKey, { priority = 50})

local function triggerActivateMouse(e)
    if (e.button == tes3.getInputBinding(tes3.keybind.activate).code) and (tes3.getInputBinding(tes3.keybind.activate).device == 1) then
        doTriggerActivate()
    end
end
event.register("mouseButtonUp", triggerActivateMouse, { priority = 50})

local function blockActivate(e)
    if e.activator ~= tes3.player then return end
    if e.target.data and e.target.data.crafted then
        if not e.target.data.allowActivate then
            Util.log:debug("Crafted, block activation")
            return false
        end
    end
end
event.register("activate", blockActivate)