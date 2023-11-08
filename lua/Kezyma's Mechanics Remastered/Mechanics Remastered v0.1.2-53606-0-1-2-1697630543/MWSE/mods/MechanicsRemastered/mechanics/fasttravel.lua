local config = require('MechanicsRemastered.config')
local K = require('MechanicsRemastered.mechanics.common')

-- Fast Travel Overhaul

local fastTravelDestination = nil

local fastTravelTravelMarker = "TravelMarker"
local fastTravelDivineMarker = "DivineMarker"
local fastTravelTempleMarker = "TempleMarker"
local fastTravelDoorMarker = "DoorMarker"

local function fastTravelCellValid(cellName)
    local visited = false
    local cells = tes3.dataHandler.nonDynamicData.cells
    for ix, cellItm in ipairs(cells) do
        if cellItm.displayName == cellName and cellItm.modified == true then
            visited = true
        end
    end
    return visited
end

local function fastTravelStatRegen(hours)
    if (config.HealthRegenEnabled == true) then
        local int = tes3.mobilePlayer.endurance.current
        local totalRegen = K.healthPerSecond(int) * 60 * 60 * hours
        local newHealth = tes3.mobilePlayer.health.current + totalRegen
        if (newHealth > tes3.mobilePlayer.health.base) then
            newHealth = tes3.mobilePlayer.health.base
        end
        tes3.setStatistic{ reference = tes3.player, name = "health", current = newHealth }
    end
    if (config.MagickaRegenEnabled == true) then
        local atronach = tes3.isAffectedBy({ reference = tes3.mobilePlayer, effect = tes3.effect.stuntedMagicka })
        if (atronach == false) then
            local int = tes3.mobilePlayer.intelligence.current
            local totalRegen = K.magickaPerSecond(int) * 60 * 60 * hours
            local newMagicka = tes3.mobilePlayer.magicka.current + totalRegen
            if (newMagicka > tes3.mobilePlayer.magicka.base) then
                newMagicka = tes3.mobilePlayer.magicka.base
            end
            tes3.setStatistic{ reference = tes3.player, name = "magicka", current = newMagicka }
        end
    end
end

local function fastTravelSkipTime(currentPos, destinationPos)
    local distUnits = math.sqrt((currentPos.r - destinationPos.r)^2 + (currentPos.g - destinationPos.g)^2 + (currentPos.b - destinationPos.b)^2)
    local unitsPerHour = tes3.mobilePlayer.walkSpeed * 60 * 60
    if (unitsPerHour > 0) then
        local totalHours = (distUnits / unitsPerHour) * tes3.findGlobal("timescale").value * config.FastTravelTimescale
        fastTravelStatRegen(totalHours)
        tes3.advanceTime({
            hours = totalHours
        })
    end
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
            fastTravelSkipTime(tes3.mobilePlayer.reference.position, travel.position)
            tes3.positionCell({ position = travel.position, orientation = travel.orientation })
        elseif (divine ~= nil) then
            fastTravelSkipTime(tes3.mobilePlayer.reference.position, divine.position)
            tes3.positionCell({ position = divine.position, orientation = divine.orientation })
        elseif (temple ~= nil) then
            fastTravelSkipTime(tes3.mobilePlayer.reference.position, temple.position)
            tes3.positionCell({ position = temple.position, orientation = temple.orientation })
        elseif (door ~= nil) then
            fastTravelSkipTime(tes3.mobilePlayer.reference.position, door.position)
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
                local newPos = { r = (midX * 8192) + 4096, g = (midY * 8192) + 4096, b = tes3.mobilePlayer.reference.position.b }
                fastTravelSkipTime(tes3.mobilePlayer.reference.position, newPos)
                tes3.positionCell({ position = newPos })
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
                if (tes3.mobilePlayer.inCombat == true) then
                    tes3ui.showMessageMenu({
                        message = "You cannot fast travel while in combat.",
                        buttons = { { text = tes3.findGMST(tes3.gmst.sOK).value, callback = fastTravelCancel }, }
                    })
                elseif (tes3.mobilePlayer.encumbrance.normalized > 1) then
                    tes3ui.showMessageMenu({
                        message = "You cannot fast travel while over-encumbered.",
                        buttons = { { text = tes3.findGMST(tes3.gmst.sOK).value, callback = fastTravelCancel }, }
                    })
                elseif (tes3.mobilePlayer.cell.isOrBehavesAsExterior == false) then
                    tes3ui.showMessageMenu({
                        message = "You cannot fast travel from the current location.",
                        buttons = { { text = tes3.findGMST(tes3.gmst.sOK).value, callback = fastTravelCancel }, }
                    })
                elseif (fastTravelCellValid(fastTravelDestination) == false) then
                    tes3ui.showMessageMenu({
                        message = "You have not visited this location yet.",
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

event.register(tes3.event.uiActivated, uiActivatedCallback, { filter = "MenuMap" })
mwse.log(config.Name .. ' Fast Travel Module Initialised.')