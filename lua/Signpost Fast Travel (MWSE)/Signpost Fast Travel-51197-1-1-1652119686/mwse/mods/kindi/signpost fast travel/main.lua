local config
local pen
local destName
local destCell
local destination = require("kindi.signpost fast travel.destination")
local function defaultTele(default, ref)
    local store
    local gX, gY
    if destCell then
        gX, gY = destCell.gridX, destCell.gridY
    elseif type(default) == "table" then
        gX, gY = default[1][1], default[1][2]
    end

    if default and not default.isInterior then
        for _, celldef in ipairs(default) do
            for x in tes3.getCell {x = celldef[1], y = celldef[2]}:iterateReferences() do
                if
                    x.destination and x.destination.cell.id:lower():match(destName:lower()) and
                        ((x.cell.id):lower() == destName:lower() or x.cell == destCell)
                 then
                    store = x
                end
            end
        end
    elseif default.isInterior == true then
        for x in default:iterateReferences() do
            if x.object.id == "DoorMarker" and ((x.cell.id):lower() == destName:lower() or x.cell == destCell) then
                store = x
            end
        end
    end

    if store then
        tes3.positionCell {
            cell = store.cell,
            reference = ref,
            orientation = store.orientation,
            position = store.position,
            teleportCompanions = false
        }
        tes3.messageBox(string.format("You have arrived in %s", destName))
        return
    end
    tes3.runLegacyScript {
        reference = ref,
        command = string.format("coe %s %s", default[1][1], default[1][2])
    }
    tes3.messageBox(string.format("You have arrived in %s", destName))
end

local function SPActivate(e)
    if not config.modActive then
        return
    end

    local ref = e.activator
    local tar = e.target

    if not ref or not tar then
        return
    end
    if tar.object.objectType ~= tes3.objectType.activator then
        return
    end
    if ref.object.objectType ~= tes3.objectType.npc and ref ~= tes3.player then
        return
    end

    destName = ((tar.object.name):gsub("[,%(].+", "")):gsub("%s$", "")

    if destination[destName:lower()] then
        destCell = tes3.getCell(destination[destName:lower()])
    end

    if not tes3.getCell {id = destName} and not destCell then
        --tes3.messageBox("No matching destination name!")
        return
    end

    if not tes3.canRest {checkForSolidGround = false} and config.combatDeny then
        tes3.messageBox("Cannot fast travel during combat")
        return
    end

    local allCell = {}
    local goToPoint = {}
    local default = nil
    local goHere = nil

    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        if not cell.isInterior and ((cell.id):lower() == destName:lower() or cell == destCell) then
            table.insert(allCell, {cell.gridX, cell.gridY})
            table.insert(allCell, {cell.gridX + 1, cell.gridY})
            table.insert(allCell, {cell.gridX - 1, cell.gridY})
            table.insert(allCell, {cell.gridX + 1, cell.gridY + 1})
            table.insert(allCell, {cell.gridX - 1, cell.gridY + 1})
            table.insert(allCell, {cell.gridX, cell.gridY + 1})
            table.insert(allCell, {cell.gridX, cell.gridY - 1})
            table.insert(allCell, {cell.gridX + 1, cell.gridY - 1})
            table.insert(allCell, {cell.gridX - 1, cell.gridY - 1})
        end
    end

    for _, cell in ipairs(allCell) do
        for spawnPoint in tes3.getCell {x = cell[1], y = cell[2]}:iterateReferences() do
            if
                (spawnPoint.object.id == "TravelMarker" or spawnPoint.object.id == "TempleMarker" or
                    spawnPoint.object.id == "DivineMarker") and
                    (spawnPoint.cell.id):lower() == destName:lower()
             then
                goToPoint[spawnPoint.object.id] = {
                    cell = {x = cell[1], y = cell[2]},
                    reference = ref,
                    orientation = spawnPoint.orientation,
                    position = spawnPoint.position,
                    teleportCompanions = config.bringFriends
                }
            elseif
                not goToPoint["other"] and spawnPoint.object.objectType == tes3.objectType.activator and
                    spawnPoint.object.name == destName and
                    (spawnPoint.cell.id):lower() == destName:lower()
             then
                goToPoint["other"] = {
                    cell = {x = cell[1], y = cell[2]},
                    reference = ref,
                    orientation = spawnPoint.orientation,
                    position = spawnPoint.position,
                    teleportCompanions = config.bringFriends
                }
            else
                default = allCell
            end
        end
    end

    for i = 1, 4 do
        local this = "travelTo" .. i
        local index = config[this]
        goHere = goToPoint[index]
        if goHere then
            break
        end
    end

    local curPos = tar.position:copy()

    local function commenceTeleport(travelType)
        if goHere then
            tes3.positionCell(goHere)
            tes3.messageBox(string.format("You have arrived in %s", destName))
        elseif tes3.getCell {id = destName} and tes3.getCell {id = destName}.isInterior then
            defaultTele(tes3.getCell {id = destName}, ref)
        else
            defaultTele(default, ref)
        end

        tes3.runLegacyScript {
            reference = ref,
            command = "fixme"
        }
        destName = nil
        destCell = nil
        pen.penalties(ref, curPos, tar, travelType)

    end

    if config.showConfirm then
        if config.extraRealism then
            tes3.messageBox {
                message = string.format("Fast travel to %s?", destName),
                buttons = {"Recklessly", "Cautiously", "No"},
                callback = function(e)
                    if e.button == 0 then
                        commenceTeleport("reckless")
                    elseif e.button == 1 then
                        commenceTeleport("cautious")
                    end
                end
            }
        else
            tes3.messageBox {
                message = string.format("Fast travel to %s?", destName),
                buttons = {"Yes", "No"},
                callback = function(e)
                    if e.button == 0 then
                        commenceTeleport()
                    end
                end
            }
        end
    else
        commenceTeleport()
    end
end

event.register("activate", SPActivate)

event.register(
    "modConfigReady",
    function()
        config = require("kindi.signpost fast travel.config")
        pen = require("kindi.signpost fast travel.penalties")
        require("kindi.signpost fast travel.mcm")
    end
)
