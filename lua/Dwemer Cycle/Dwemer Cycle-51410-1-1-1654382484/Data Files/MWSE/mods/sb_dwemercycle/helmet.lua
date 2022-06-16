local ui = require("sb_dwemercycle.ui")
local zero = require("sb_dwemercycle.zero")
local utils = require("sb_dwemercycle.utils")
local mcm = require("sb_dwemercycle.mcm")
local helmet = {}

local function simulateCallback(e)
    local helmet = tes3.getEquippedItem { actor = tes3.player, objectType = tes3.objectType.armor, slot = tes3.armorSlot.helmet }
    if ((zero.getReference() and zero.isMounted() ~= true or zero.getReference() == nil)
            and (helmet and helmet.object.id == "sb_dwemer_helm")) then
        ui.showSpawnControl()
        if (utils.getKeyPressRaw(mcm.config.keyBind.keyCode)) then
            local spawnCost = zero.getSpeedLimitKilometers(1) * 10
            if (tes3.mobilePlayer.magicka.current >= spawnCost) then
                tes3.mobilePlayer.magicka.current = tes3.mobilePlayer.magicka.current - spawnCost
                tes3.mobilePlayer:updateDerivedStatistics()
                zero.create()
            else
                tes3.messageBox(tes3.findGMST(tes3.gmst.sMagicInsufficientSP).value)
            end
        end
    else
        ui.hideSpawnControl()
    end
end

local function bodyPartAssignedCallback(e)
    if (e.index == tes3.activeBodyPart.head) then
        timer.delayOneFrame(function()
            local helmet = tes3.getEquippedItem { actor = tes3.player, objectType = tes3.objectType.armor, slot = tes3.armorSlot.helmet }
            if (helmet and helmet.object.id == "sb_dwemer_helm") then
                local head = tes3.player.sceneNode:getObjectByName("Head")
                if (head) then
                    head.appCulled = true
                    head:update()
                end
            end
        end)
    end
end

local function loadedCallback(e)
    tes3.player:updateEquipment()
    tes3.mobilePlayer.firstPersonReference:updateEquipment()
end

function helmet.init()
    event.register("simulate", simulateCallback)
    event.register("bodyPartAssigned", bodyPartAssignedCallback)
    event.register("loaded", loadedCallback)
end

return helmet