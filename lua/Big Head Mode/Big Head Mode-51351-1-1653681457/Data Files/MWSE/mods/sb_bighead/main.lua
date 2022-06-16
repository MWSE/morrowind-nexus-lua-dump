local mcm = require("sb_bighead.mcm")
mcm.init()

--- @param e mobileActivatedEventData
local function mobileActivatedCallback(e)
    local head = e.reference.sceneNode:getObjectByName("Bip01 Head")
    local leftHand = e.reference.sceneNode:getObjectByName("Bip01 L Hand")
    local rightHand = e.reference.sceneNode:getObjectByName("Bip01 R Hand")
    if (head) then
        head.scale = mcm.config.mode > 0 and 2 or 1
    end
    if (leftHand) then
        leftHand.scale = mcm.config.mode == 2 and 2 or 1
    end
    if (rightHand) then
        rightHand.scale = mcm.config.mode == 2 and 2 or 1
    end
end

event.register(tes3.event.mobileActivated, mobileActivatedCallback)

--- @param e loadedEventData
local function loadedCallback(e)
    tes3.player.sceneNode:getObjectByName("Bip01 Head").scale = mcm.config.mode > 0 and 2 or 1
    tes3.player.sceneNode:getObjectByName("Bip01 L Hand").scale = mcm.config.mode == 2 and 2 or 1
    tes3.player.sceneNode:getObjectByName("Bip01 R Hand").scale = mcm.config.mode == 2 and 2 or 1
    tes3.mobilePlayer.firstPersonReference.sceneNode:getObjectByName("Bip01 L Hand").scale = mcm.config.mode == 2 and 2 or 1
    tes3.mobilePlayer.firstPersonReference.sceneNode:getObjectByName("Bip01 R Hand").scale = mcm.config.mode == 2 and 2 or 1
end

event.register(tes3.event.loaded, loadedCallback)
