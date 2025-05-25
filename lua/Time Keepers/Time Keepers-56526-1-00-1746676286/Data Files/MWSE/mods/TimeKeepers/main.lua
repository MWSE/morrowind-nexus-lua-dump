--- @param e enterFrameEventData
local function enterFrameCallback(e)
    if (tes3.player) then

        local timekeepers = { tes3.player.sceneNode:getObjectByName("TimeKeeper"), tes3.mobilePlayer.firstPersonReference.sceneNode:getObjectByName("TimeKeeper") }
        ---@param timekeeper niAVObject
        for _, timekeeper in pairs(timekeepers) do
            local timekeeperRot = timekeeper.parent.rotation:copy()
            timekeeperRot:toRotationX(math.rad(90))
            timekeeperRot:toRotationY(math.rad(90))
            timekeeper.parent.rotation = timekeeperRot

            local timekeeperLoc = timekeeper.parent.translation:copy()
            timekeeperLoc.x = -1
            timekeeperLoc.z = -4
            timekeeper.parent.translation = timekeeperLoc
        end

        local hands = { tes3.player.sceneNode:getObjectByName("Hand"), tes3.mobilePlayer.firstPersonReference.sceneNode:getObjectByName("Hand") }
        local hour = tes3.getGlobal('GameHour')
        ---@param hand niAVObject
        for _, hand in pairs(hands) do
            local handRot = hand.rotation:copy()
	    if (hour >= 12 ) then
		hour = hour - 12
	    end
            handRot:toRotationZ((hour * 30) * 0.01745)
            hand.rotation = handRot
        end

        local timekeepers24 = { tes3.player.sceneNode:getObjectByName("TimeKeeper24"), tes3.mobilePlayer.firstPersonReference.sceneNode:getObjectByName("TimeKeeper24") }
        ---@param timekeeper niAVObject
        for _, timekeeper24 in pairs(timekeepers24) do
            local timekeeper24Rot = timekeeper24.parent.rotation:copy()
            timekeeper24Rot:toRotationX(math.rad(90))
            timekeeper24Rot:toRotationY(math.rad(90))
            timekeeper24.parent.rotation = timekeeper24Rot

            local timekeeper24Loc = timekeeper24.parent.translation:copy()
            timekeeper24Loc.x = -1
            timekeeper24Loc.z = -4
            timekeeper24.parent.translation = timekeeper24Loc
        end

        local hands24 = { tes3.player.sceneNode:getObjectByName("Hand24"), tes3.mobilePlayer.firstPersonReference.sceneNode:getObjectByName("Hand24") }
        local hour = tes3.getGlobal('GameHour')
        ---@param hand24 niAVObject
        for _, hand24 in pairs(hands24) do
            local hand24Rot = hand24.rotation:copy()
            hand24Rot:toRotationZ((hour * 15) * 0.01745)
            hand24.rotation = hand24Rot
        end

        if (e.menuMode == false and utils.getKeyPressRaw(mcm.config.keyBind.keyCode)) then
            local miscEquipped = tes3.getEquippedItem { actor = tes3.player, objectType = tes3.objectType.lockpick }
            local lastEquipped = tes3.player.data["tk_lastEquipped"]
            local lastReady = tes3.player.data["tk_lastReady"]
            if (tes3.getItemCount { reference = tes3.player, item = "tk_12" } > 0) then
                if (miscEquipped and miscEquipped.object.id == "tk_12") then
                    tes3.mobilePlayer.weaponReady = lastReady[1]
                    tes3.mobilePlayer.castReady = lastReady[2]
                    if (lastEquipped[2] ~= nil) then
                        if (lastEquipped[1]) then
                            tes3.mobilePlayer:equip { item = lastEquipped[1].object, itemData = lastEquipped[1].itemData, addItem = false, selectBestCondition = false, selectWorstCondition = false }
                        else
                            tes3.mobilePlayer:equip { item = lastEquipped[2], addItem = false, selectBestCondition = false, selectWorstCondition = false }
                        end
                    else
                        tes3.mobilePlayer:unequip { item = tes3.getObject("tk_12"), type = tes3.objectType.lockpick }
                    end
                else
                    tes3.player.data["tk_lastEquipped"] = { tes3.mobilePlayer.readiedWeapon, tes3.mobilePlayer.readiedWeapon and tes3.mobilePlayer.readiedWeapon.object.id }
                    tes3.player.data["tk_lastReady"] = { tes3.mobilePlayer.weaponReady, tes3.mobilePlayer.castReady }
                    tes3.mobilePlayer:equip { item = tes3.getObject("tk_12"), addItem = false, selectBestCondition = false, selectWorstCondition = false }
                    tes3.mobilePlayer.weaponReady = true
                end
            end
            if (tes3.getItemCount { reference = tes3.player, item = "tk_24" } > 0) then
                if (miscEquipped and miscEquipped.object.id == "tk_24") then
                    tes3.mobilePlayer.weaponReady = lastReady[1]
                    tes3.mobilePlayer.castReady = lastReady[2]
                    if (lastEquipped[2] ~= nil) then
                        if (lastEquipped[1]) then
                            tes3.mobilePlayer:equip { item = lastEquipped[1].object, itemData = lastEquipped[1].itemData, addItem = false, selectBestCondition = false, selectWorstCondition = false }
                        else
                            tes3.mobilePlayer:equip { item = lastEquipped[2], addItem = false, selectBestCondition = false, selectWorstCondition = false }
                        end
                    else
                        tes3.mobilePlayer:unequip { item = tes3.getObject("tk_24"), type = tes3.objectType.lockpick }
                    end
                else
                    tes3.player.data["tk_lastEquipped"] = { tes3.mobilePlayer.readiedWeapon, tes3.mobilePlayer.readiedWeapon and tes3.mobilePlayer.readiedWeapon.object.id }
                    tes3.player.data["tk_lastReady"] = { tes3.mobilePlayer.weaponReady, tes3.mobilePlayer.castReady }
                    tes3.mobilePlayer:equip { item = tes3.getObject("tk_24"), addItem = false, selectBestCondition = false, selectWorstCondition = false }
                    tes3.mobilePlayer.weaponReady = true
                end
            end
            if (tes3.getItemCount { reference = tes3.player, item = "tk_sun" } > 0) then
                if (miscEquipped and miscEquipped.object.id == "tk_sun") then
                    tes3.mobilePlayer.weaponReady = lastReady[1]
                    tes3.mobilePlayer.castReady = lastReady[2]
                    if (lastEquipped[2] ~= nil) then
                        if (lastEquipped[1]) then
                            tes3.mobilePlayer:equip { item = lastEquipped[1].object, itemData = lastEquipped[1].itemData, addItem = false, selectBestCondition = false, selectWorstCondition = false }
                        else
                            tes3.mobilePlayer:equip { item = lastEquipped[2], addItem = false, selectBestCondition = false, selectWorstCondition = false }
                        end
                    else
                        tes3.mobilePlayer:unequip { item = tes3.getObject("tk_sun"), type = tes3.objectType.lockpick }
                    end
                else
                    tes3.player.data["tk_lastEquipped"] = { tes3.mobilePlayer.readiedWeapon, tes3.mobilePlayer.readiedWeapon and tes3.mobilePlayer.readiedWeapon.object.id }
                    tes3.player.data["tk_lastReady"] = { tes3.mobilePlayer.weaponReady, tes3.mobilePlayer.castReady }
                    tes3.mobilePlayer:equip { item = tes3.getObject("tk_sun"), addItem = false, selectBestCondition = false, selectWorstCondition = false }
                    tes3.mobilePlayer.weaponReady = true
                end
            end
        end
    end
end

--- @param e referenceActivatedEventData
local function referenceActivatedCallback(e)
    if (e.reference.object.id == "TK_12") then
        local hand = e.reference.sceneNode:getObjectByName("Hand")
        local hour = tes3.getGlobal('GameHour')
	if (hour >= 12) then
	    hour = hour - 12
	end
        local handRot = hand.rotation:copy()
        handRot:toRotationZ(hour * 30)
        hand.rotation = handRot
        e.reference:updateSceneGraph()
    elseif (e.reference.object.id == "TK_24") then
        local hand = e.reference.sceneNode:getObjectByName("Hand")
        local hour = tes3.worldController.hour.value
        local handRot = hand.rotation:copy()
        handRot:toRotationZ((northMarker and northMarker.cell == e.reference.cell and northMarker.orientation.z or 0) - e.reference.orientation.z)
        hand.rotation = handRot
        e.reference:updateSceneGraph()
    elseif (e.reference.object.id == "TK_sun") then
        local hand = e.reference.sceneNode:getObjectByName("Hand")
        local hour = tes3.worldController.hour.value
        local handRot = hand.rotation:copy()
        handRot:toRotationZ((northMarker and northMarker.cell == e.reference.cell and northMarker.orientation.z or 0) - e.reference.orientation.z)
        hand.rotation = handRot
        e.reference:updateSceneGraph()
    end
end

--- @param e uiObjectTooltipEventData
local function uiObjectTooltipCallback(e)
    if (e.object.id == "TK_12") then
        e.tooltip:findChild("HelpMenu_uses"):destroy()
        e.tooltip:findChild("HelpMenu_qualityCondition"):destroy()
    elseif (e.object.id == "TK_24") then
        e.tooltip:findChild("HelpMenu_uses"):destroy()
        e.tooltip:findChild("HelpMenu_qualityCondition"):destroy()
    elseif (e.object.id == "TK_sun") then
        e.tooltip:findChild("HelpMenu_uses"):destroy()
        e.tooltip:findChild("HelpMenu_qualityCondition"):destroy()
    end
end

--- @param e initializedEventData
local function initializedCallback(e)
    event.register(tes3.event.enterFrame, enterFrameCallback)
    event.register(tes3.event.referenceActivated, referenceActivatedCallback)
    event.register(tes3.event.uiObjectTooltip, uiObjectTooltipCallback)
end

event.register(tes3.event.initialized, initializedCallback)
