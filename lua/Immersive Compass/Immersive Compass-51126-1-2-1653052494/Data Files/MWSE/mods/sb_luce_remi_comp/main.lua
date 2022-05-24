local mcm = require("sb_luce_remi_comp.mcm")
local utils = require("sb_luce_remi_comp.utils")

mcm.init()

local names = { "MenuMulti", "MenuMap" }
local chNames = { "MenuMap_local_player", "MenuMap_world_player" }
local icon = "Icons\\sb_luce_remi_comp\\marker.tga"

--- @param e enterFrameEventData
local function enterFrameCallback(e)
    if (tes3.player) then
        for id, name in ipairs(names) do
            local menu = tes3ui.findMenu(name)
            if (menu) then
                local uiRefresh = id == 1 and mcm.uiMultiRefreshState or mcm.uiMapRefreshState
                for _, chName in ipairs(chNames) do
                    local compass = menu:findChild(chName)
                    if (compass and compass.parent) then
                        if (uiRefresh and mcm.config.mode == 2) then
                            compass.imageScaleX = 1
                            compass.imageScaleY = 1
                        elseif (mcm.config.mode ~= 2) then
                            compass.imageScaleX = 0.001
                            compass.imageScaleY = 0.001
                        end

                        local marker = compass.parent:findChild("sb_luce_marker")
                        if (uiRefresh) then
                            if (mcm.config.mode ~= 1) then
                                marker.visible = false
                            else
                                marker.visible = true
                            end
                        end
                        marker.absolutePosAlignX = compass.absolutePosAlignX
                        marker.absolutePosAlignY = compass.absolutePosAlignY
                        marker.positionX = compass.positionX - 8
                        marker.positionY = compass.positionY + 8

                        if (uiRefresh) then
                            mcm[id == 1 and "uiMultiRefreshState" or "uiMapRefreshState"] = false
                        end
                    end
                end
            end
        end

        local compasses = { tes3.player.sceneNode:getObjectByName("Compass"), tes3.mobilePlayer.firstPersonReference.sceneNode:getObjectByName("Compass") }
        ---@param compass niAVObject
        for _, compass in pairs(compasses) do
            local compassRot = compass.parent.rotation:copy()
            compassRot:toRotationX(math.rad(90))
            compassRot:toRotationY(math.rad(90))
            compass.parent.rotation = compassRot

            local compassLoc = compass.parent.translation:copy()
            compassLoc.x = -1
            compassLoc.z = -4
            compass.parent.translation = compassLoc
        end

        local needles = { tes3.player.sceneNode:getObjectByName("Needle"), tes3.mobilePlayer.firstPersonReference.sceneNode:getObjectByName("Needle") }
        local northMarker = tes3.getReference("NorthMarker")
        ---@param needle niAVObject
        for _, needle in pairs(needles) do
            local needleRot = needle.rotation:copy()
            needleRot:toRotationZ((northMarker and northMarker.cell == tes3.getPlayerCell() and northMarker.orientation.z or 0) - tes3.player.orientation.z)
            needle.rotation = needleRot
        end

        if (e.menuMode == false and utils.getKeyPressRaw(mcm.config.keyBind.keyCode)) then
            local miscEquipped = tes3.getEquippedItem { actor = tes3.player, objectType = tes3.objectType.lockpick }
            local lastEquipped = tes3.player.data["sb_comp_lastEquipped"]
            local lastReady = tes3.player.data["sb_comp_lastReady"]
            if (tes3.getItemCount { reference = tes3.player, item = "sb_luce_compass" } > 0) then
                if (miscEquipped and miscEquipped.object.id == "sb_luce_compass") then
                    tes3.mobilePlayer.weaponReady = lastReady[1]
                    tes3.mobilePlayer.castReady = lastReady[2]
                    if (lastEquipped[2] ~= nil) then
                        if (lastEquipped[1]) then
                            tes3.mobilePlayer:equip { item = lastEquipped[1].object, itemData = lastEquipped[1].itemData, addItem = false, selectBestCondition = false, selectWorstCondition = false }
                        else
                            tes3.mobilePlayer:equip { item = lastEquipped[2], addItem = false, selectBestCondition = false, selectWorstCondition = false }
                        end
                    else
                        tes3.mobilePlayer:unequip { item = tes3.getObject("sb_luce_compass"), type = tes3.objectType.lockpick }
                    end
                else
                    tes3.player.data["sb_comp_lastEquipped"] = { tes3.mobilePlayer.readiedWeapon, tes3.mobilePlayer.readiedWeapon and tes3.mobilePlayer.readiedWeapon.object.id }
                    tes3.player.data["sb_comp_lastReady"] = { tes3.mobilePlayer.weaponReady, tes3.mobilePlayer.castReady }
                    tes3.mobilePlayer:equip { item = tes3.getObject("sb_luce_compass"), addItem = false, selectBestCondition = false, selectWorstCondition = false }
                    tes3.mobilePlayer.weaponReady = true
                end
            end
        end
    end
end

--- @param e referenceActivatedEventData
local function referenceActivatedCallback(e)
    if (e.reference.object.id == "sb_luce_compass") then
        local needle = e.reference.sceneNode:getObjectByName("Needle")
        local northMarker = tes3.getReference("NorthMarker")
        local needleRot = needle.rotation:copy()
        needleRot:toRotationZ((northMarker and northMarker.cell == e.reference.cell and northMarker.orientation.z or 0) - e.reference.orientation.z)
        needle.rotation = needleRot
        e.reference:updateSceneGraph()
    end
end

--- @param e uiObjectTooltipEventData
local function uiObjectTooltipCallback(e)
    if (e.object.id == "sb_luce_compass") then
        e.tooltip:findChild("HelpMenu_uses"):destroy()
        e.tooltip:findChild("HelpMenu_qualityCondition"):destroy()

        local compasses = {
            [0]  = "N",
            [1]  = "N-N-W",
            [2]  = "N-W",
            [3]  = "W-N-W",
            [4]  = "W",
            [5]  = "W-S-W",
            [6]  = "S-W",
            [7]  = "S-S-W",
            [8]  = "S",
            [9]  = "S-S-E",
            [10] = "S-E",
            [11] = "E-S-E",
            [12] = "E",
            [13] = "E-N-E",
            [14] = "N-E",
            [15] = "N-N-E",
            [16] = "N"
        }
        local northMarker = tes3.getReference("NorthMarker")
        ---@type tes3reference
        local container = tes3ui.findMenu("MenuContents") and tes3ui.findMenu("MenuContents"):getPropertyObject("MenuContents_ObjectRefr")
        local referenceOrientation = e.reference and e.reference.orientation.z or container and container.orientation.z or tes3.player.orientation.z
        local referenceCell = e.reference and e.reference.cell or container and container.cell or tes3.player.cell
        local angleIndex = math.deg((northMarker and northMarker.cell == referenceCell and northMarker.orientation.z or 0) - (referenceOrientation))
        e.tooltip:createLabel { id = "HelpMenu_direction", text = "Direction: " .. compasses[math.round((angleIndex < 0 and angleIndex + 360 or angleIndex) / (360 / 16))] }
        e.tooltip.children[1]:reorderChildren(1, -1, 1)
    end
end

--- @param e uiActivatedEventData
local function uiActivatedCallback(e)
    for _, name in ipairs(names) do
        if (e.element.name == name) then
            for _, chName in ipairs(chNames) do
                local compass = e.element:findChild(chName)
                if (compass and compass.parent) then
                    local marker = compass.parent:createImage { id = "sb_luce_marker", path = icon }
                    marker.absolutePosAlignX = compass.absolutePosAlignX
                    marker.absolutePosAlignY = compass.absolutePosAlignY
                    marker.positionX = compass.positionX - 8
                    marker.positionY = compass.positionY + 8
                end
            end
        end
    end
end

--- @param e initializedEventData
local function initializedCallback(e)
    event.register(tes3.event.enterFrame, enterFrameCallback)
    event.register(tes3.event.referenceActivated, referenceActivatedCallback)
    event.register(tes3.event.uiObjectTooltip, uiObjectTooltipCallback)
    event.register(tes3.event.uiActivated, uiActivatedCallback)
end

event.register(tes3.event.initialized, initializedCallback)
