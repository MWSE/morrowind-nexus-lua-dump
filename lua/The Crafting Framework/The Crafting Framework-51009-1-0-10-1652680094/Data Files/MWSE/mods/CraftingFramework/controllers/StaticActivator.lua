local Craftable = require("CraftingFramework.components.Craftable")
local Util = require("CraftingFramework.util.Util")
local config = require("CraftingFramework.config")
local id_indicator = tes3ui.registerID("Ashfall:activatorTooltip")
local id_label = tes3ui.registerID("Ashfall:activatorTooltipLabel")

local isBlocked
local function blockScriptedActivate(e)
    isBlocked = e.doBlock
end
event.register("BlockScriptedActivate", blockScriptedActivate)

local function centerText(element)
    element.autoHeight = true
    element.autoWidth = true
    element.wrapText = true
    element.justifyText = "center"
end

local function createActivatorIndicator(reference)
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if menu then
        local mainBlock = menu:findChild(id_indicator)
        if mainBlock then
            mainBlock:destroy()
        end

        if not reference then return end
        --objects that already have a name don't need an activator
        if reference.object.name and reference.object.name ~= "" then
            return
        end
        if tes3ui.menuMode() then return end

        local craftable = Craftable.getPlacedCraftable(reference.object.id:lower())
        if craftable then
            mainBlock = menu:createBlock({id = id_indicator })

            mainBlock.absolutePosAlignX = 0.5
            mainBlock.absolutePosAlignY = 0.03
            mainBlock.autoHeight = true
            mainBlock.autoWidth = true

            local labelBackground = mainBlock:createRect({color = {0, 0, 0}})
            --labelBackground.borderTop = 4
            labelBackground.autoHeight = true
            labelBackground.autoWidth = true

            local labelBorder = labelBackground:createThinBorder({})
            labelBorder.autoHeight = true
            labelBorder.autoWidth = true
            labelBorder.paddingAllSides = 10
            labelBorder.flowDirection = "top_to_bottom"

            local text = craftable:getName()
            local label = labelBorder:createLabel{ id=id_label, text = text}
            label.color = tes3ui.getPalette("header_color")
            centerText(label)
        else
        end
    end
end

local function callRayTest(e)
    local eyePos = tes3.getPlayerEyePosition()
    local eyeDirection = tes3.getPlayerEyeVector()

    local result = tes3.rayTest{
        position = eyePos,
        direction = eyeDirection,
        ignore = { tes3.player }
    }

    if result then
        if result.reference and result.reference.data and result.reference.data.crafted then
            local distance = eyePos:distance(result.intersection)
            if distance < tes3.findGMST(tes3.gmst.iMaxActivateDist).value then
                createActivatorIndicator(result.reference)
                return result.reference
            end
        end
    else
        createActivatorIndicator()
    end
end
event.register("simulate", function()
     callRayTest()
end)

local function doTriggerActivate()
    if (not config.persistent.positioningActive)
    and (not isBlocked)
    and (not tes3ui.menuMode())
    then
        local ref = callRayTest({ returnRef = true})
        if ref then
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
event.register("keyDown", triggerActivateKey )

local function triggerActivateMouse(e)
    if (e.button == tes3.getInputBinding(tes3.keybind.activate).code) and (tes3.getInputBinding(tes3.keybind.activate).device == 1) then
        doTriggerActivate()
    end
end
event.register("mouseButtonUp", triggerActivateMouse)

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