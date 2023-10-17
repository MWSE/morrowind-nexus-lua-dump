local config = require('MechanicsRemastered.config')

-- Fast Travel Overhaul

local fastTravelDestination = nil
local fastTravelIsInCombat = false

local fastTravelTravelMarker = "TravelMarker"
local fastTravelDivineMarker = "DivineMarker"
local fastTravelTempleMarker = "TempleMarker"
local fastTravelDoorMarker = "DoorMarker"

--- @param e combatStartedEventData
local function combatStartedCallback(e)
    fastTravelIsInCombat = true
end

--- @param e combatStoppedEventData
local function combatStoppedCallback(e)
    fastTravelIsInCombat = false
end

local function fastTravelMove()
    if (config.FastTravelEnabled == true) then
        local cells = tes3.dataHandler.nonDynamicData.cells

        -- Find the first reference of each type.
        local travel = nil
        local divine = nil
        local temple = nil
        local door = nil
        for ix, cellItm in ipairs(cells) do
            if cellItm.displayName == fastTravelDestination then
                for ref in cellItm:iterateReferences() do
                    if (ref.isLocationMarker) then
                        if (travel == nil and ref.id == fastTravelTravelMarker) then
                            travel = ref
                        end
                        if (divine == nil and ref.id == fastTravelDivineMarker) then
                            divine = ref
                        end
                        if (temple == nil and ref.id == fastTravelTempleMarker) then
                            temple = ref
                        end
                        if (door == nil and ref.id == fastTravelDoorMarker and ref.position.b >= 0) then
                            door = ref
                        end
                    end
                end           
            end
        end

        if (travel ~= nil) then
            tes3.positionCell({ position = travel.position, orientation = travel.orientation })
        elseif (divine ~= nil) then
            tes3.positionCell({ position = divine.position, orientation = divine.orientation })
        elseif (temple ~= nil) then
            tes3.positionCell({ position = temple.position, orientation = temple.orientation })
        elseif (door ~= nil) then
            tes3.positionCell({ position = door.position, orientation = door.orientation })
        else
            -- If no viable locations are found, move to the center of the cells.
            local minX = nil
            local minY = nil
            local maxX = nil
            local maxY = nil
            for ix, cellItm in ipairs(cells) do
                if cellItm.displayName == fastTravelDestination then
                    if (minX == nil or cellItm.gridX < minX) then
                        minX = cellItm.gridX
                    end
                    if (minY == nil or cellItm.gridY < minY) then
                        minY = cellItm.gridY
                    end
                    if (maxX == nil or cellItm.gridX > maxX) then
                        maxX = cellItm.gridX
                    end
                    if (maxY == nil or cellItm.gridY > maxY) then
                        maxY = cellItm.gridY
                    end              
                end
            end
            if (minX ~= nil) then
                local midX = (minX + maxX) / 2
                local midY = (minY + maxY) / 2
                tes3.positionCell({ position = { (midX * 8192) + 4096, (midY * 8192) + 4096 } })
            end
        end
    end
end

local function fastTravelCancel()
    fastTravelDestination = nil
end

local function fastTravelClick(e) 
    if (config.FastTravelEnabled == true) then
        local helpMenu = tes3ui.findHelpLayerMenu("HelpMenu")
        if (helpMenu) then
            local helpBody = helpMenu:findChild("PartHelpMenu_main")
            if (helpBody) then
                local helpTxt = helpBody.children[1].text
                fastTravelDestination = helpTxt
                if (fastTravelIsInCombat == true) then
                    tes3ui.showMessageMenu({
                        message = "You cannot fast travel while in combat.",
                        buttons = { { text = tes3.findGMST(tes3.gmst.sOK).value, callback = fastTravelCancel }, }
                    })
                elseif (tes3.mobilePlayer.cell.isOrBehavesAsExterior == false) then
                    tes3ui.showMessageMenu({
                        message = "You cannot fast travel from the current location.",
                        buttons = { { text = tes3.findGMST(tes3.gmst.sOK).value, callback = fastTravelCancel }, }
                    })
                else
                    tes3ui.showMessageMenu({
                        message = "Travel to " .. fastTravelDestination .. "?",
                        buttons = { { text = tes3.findGMST(tes3.gmst.sOK).value, callback = fastTravelMove }, },
                        cancels = true,
                        cancelCallback = fastTravelCancel
                    })
                end
            end
        end
    end
end

local function updateMapMenu(e)
    local mapMenu = tes3ui.findMenu("MenuMap")
    if (not mapMenu) then
        return
    end
    local mapContainer = mapMenu:findChild("MenuMap_world_map")
    if (mapContainer) then
        mapContainer.consumeMouseEvents = true
        mapContainer:registerBefore(tes3.uiEvent.mouseDown, fastTravelClick)
    end
end

--- @param e uiActivatedEventData
local function uiActivatedCallback(e)
    e.element:registerBefore(tes3.uiEvent.preUpdate, updateMapMenu)
end

event.register(tes3.event.combatStarted, combatStartedCallback)
event.register(tes3.event.combatStopped, combatStoppedCallback)
event.register(tes3.event.uiActivated, uiActivatedCallback, { filter = "MenuMap" })
mwse.log(config.Name .. ' Fast Travel Module Initialised.')