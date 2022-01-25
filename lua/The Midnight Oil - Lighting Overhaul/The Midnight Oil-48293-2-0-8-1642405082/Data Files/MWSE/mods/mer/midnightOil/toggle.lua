local common = require("mer.midnightOil.common")
local conf = require("mer.midnightOil.config")
--Offer to toggle lights instead of pick up
local function onActivate(e)
    if not common.modActive() then return end
    local ref = e.target
    if ref.stackSize and ref.stackSize > 1 then return end
    if e.activator ~= tes3.player then return end
    if ref.object.script then return end

    if common.isCarryableLight(ref.object) then
        local inputController = tes3.worldController.inputController
        if inputController:isKeyDown(conf.getConfig().toggleHotkey.keyCode) then
            if ref.object.time and (  ref.object.time > 0 and ref.itemData.timeLeft < 1 ) then
                --can't toggle lights with no fuel left
                tes3.messageBox("%s is out of fuel.", ref.object.name)
                return false
            end
            if not ref.data.lightTurnedOff then
                tes3.playSound{ reference = tes3.player, sound = "mer_tmo_alight", pitch = 1.0}
                common.removeLight(ref)
                common.setToggledDay(ref)
                return false
            else
                tes3.playSound{ reference = tes3.player, sound = "mer_tmo_alight", pitch = 1.0}
                common.onLight(ref)
                common.setToggledDay(ref)
                return false
            end
        end
    end
end
event.register("activate", onActivate, {priority = 5})


--Turn off lights already in the world
local function onSceneNodeCreated(e)
    if not common.modActive() then return end

    if e.reference.stackSize and e.reference.stackSize > 1 then
        return
    end
    if not common.isSwitchable(e.reference.object) then return end
    if e.reference.object.isOffByDefault == true then
        if e.reference.data.lightTurnedOff == nil then
            e.reference.data.lightTurnedOff = true
            e.reference.modified = true
        end
    end
    if e.reference.object.objectType == tes3.objectType.light then
        if e.reference.data then
            if e.reference.data.lightTurnedOff  == true then
                common.removeLight(e.reference)
            elseif e.reference.object.isOffByDefault then
                common.onLight(e.reference)
            end
        end
    end
end
event.register("referenceSceneNodeCreated", onSceneNodeCreated)


--Add "On"/"Off" to tooltip for lights
local function onTooltip(e)
    if not common.modActive() then return end
    if e.reference then
        if e.reference.stackSize and e.reference.stackSize > 1 then return end
        if not common.isSwitchable(e.reference.object) then return end
        if e.object.objectType == tes3.objectType.light and e.object.canCarry == true then
            local label = e.tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
            if e.reference.data.lightTurnedOff then
                label.text = label.text .. " (Off)"
            else
                label.text = label.text .. " (On)"
            end
        end
    end
end

event.register("uiObjectTooltip", onTooltip)



local function toggleStaticLights(e)
    if not common.modActive() then return end
    if not tes3.player then return end
    if e.keyCode == tes3.worldController.inputController.inputMaps[6].code then
        local result = tes3.rayTest {
            position = tes3.getPlayerEyePosition(),
            direction = tes3.getPlayerEyeVector(),
            ignore = {tes3.player},
            maxDistance = 200
        };
        if result and result.reference then
            local ref = result.reference
            local inputController = tes3.worldController.inputController
            if inputController:isKeyDown(conf.getConfig().toggleHotkey.keyCode) then
                if ref.object.objectType == tes3.objectType.light then
                    if ref.object.canCarry ~= true then

                        if common.isSwitchable(ref.object) then
                            if not ref.data.lightTurnedOff then
                                tes3.playSound{ reference = tes3.player, sound = "mer_tmo_alight", pitch = 1.0}
                                common.removeLight(ref)
                            else
                                tes3.playSound{ reference = tes3.player, sound = "mer_tmo_alight", pitch = 1.0}
                                common.onLight(ref)
                            end
                            common.setToggledDay(ref)
                        end
                    end
                end
            end
        end
    end
end
event.register("keyDown", toggleStaticLights)


