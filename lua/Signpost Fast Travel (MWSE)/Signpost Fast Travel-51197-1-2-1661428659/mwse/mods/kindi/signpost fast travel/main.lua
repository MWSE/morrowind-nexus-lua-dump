local config
local auxFuncs = require("kindi.signpost fast travel.auxFuncs")
local destination = require("kindi.signpost fast travel.destination")
local i18n = mwse.loadTranslations("kindi.signpost fast travel")

local function tryDetermineCell(name)
    if destination[name] then
        return name
    end
    for str in name:gmatch("[^,()]+") do
        str = str:gsub("^%s+","")
        str = str:gsub("%s+$","")
        str = str:gsub("%s%a", string.upper)
        local str2 = str:gsub("(%w+)%s(%w+)", "%2 %1")

        if destination[str] then
            return str
        elseif destination[str2] then
            return str2
        end     
    end
end

local function goToPresetPoint(e, CELL)
    tes3.positionCell {
        reference = e.activator,
        cell = CELL,
        position = destination[CELL].position,
        orientation = destination[CELL].orientation,
        suppressFader = false,
        teleportCompanions = config.bringFriends
    }
end

local function postFastTravel(e, CELL, travelType)

    -- //playbink here i guess?
    -- //tes3.runLegacyScript{command = string.format('playbink "%s" 1', "?")}

    -- //if traveller is in combat and the option is enabled, travelling is disabled
    if config.combatDeny and e.activator.mobile.inCombat then
        tes3.messageBox(i18n("main.noTravelCombatNotify"))
        tes3.fadeIn({duration = 2})
        return
    end

    -- //travel immediately to the preset position of this town
    goToPresetPoint(e, CELL)

    local TM -- travel
    local DM -- divine
    local AM -- almsivi

    -- //find these markers reference in active cells (usually covers a whole town)
    for _, cell in pairs(tes3.getActiveCells()) do
        if cell.id:lower() == e.activator.cell.id:lower() then
            for ref in cell:iterateReferences() do
                if ref.object.id == "TempleMarker" then
                    AM = ref
                end
                if ref.object.id == "DivineMarker" then
                    DM = ref
                end
                if ref.object.id == "TravelMarker" then
                    TM = ref
                end
            end
        end
    end

    --//get the markers position and orientation
    local function getTravel(travelType)
        if travelType == "TravelMarker" and TM then
            return TM.position, TM.orientation
        elseif travelType == "DivineMarker" and DM then
            return DM.position, DM.orientation
        elseif travelType == "TempleMarker" and AM then
            return AM.position, AM.orientation
        elseif travelType == "Preset" then
            return false
        else
            return false
        end
    end

    -- //priority check for the travel point 1,2,3,4
    -- //if any of those points are found first, reposition to that point
    local arrivalPos -- arrival position
    local arrivalAng -- arrival angle 
    local travelPrio -- travel priority
    for i = 1, 4 do
        travelPrio = config["travelTo" .. i]
        arrivalPos, arrivalAng = getTravel(travelPrio)
        if arrivalPos and arrivalAng and tes3.positionCell {
            reference = e.activator,
            cell = CELL,
            position = arrivalPos,
            orientation = arrivalAng,
            teleportCompanions = config.bringFriends
        } then
            break
        end
        if arrivalPos == false then
            break
        end
    end

    if config.debug then
        tes3.messageBox(i18n("debug.UsingTravelPoint", {travelPrio}))
    end

    -- //move on to the penalty section (health, fatigue, time advance, gold, disease, etc...)
    timer.delayOneFrame(function()auxFuncs.penalties(e.activator, e.target.position:copy(), e.target, travelType, CELL)
        tes3.fadeIn({duration = 6})
    end)
end

local function postActivated(e)

    --// if mod is off, travel is disabled
    if not config.modActive then
        return
    end

    --//if target activation is not a activator type, travel is disabled
    --//signposts are and should be activators
    if e.target.object.objectType ~= tes3.objectType.activator then
        return
    end

    --//determine if this cell is in the list, if not travel is disabled
    local CELL = tryDetermineCell(e.target.object.name)


    --//if there is no valid cell matching the signpost, travel is disabled
    --//note: some signposts may show invalid cell names, for now just ignore them
    if not CELL then
        if config.debug then
            tes3.messageBox(i18n("debug.noCellFound", {e.target.object.name}))
        end
        return
    end

    --//if the activator is in the cell (or near) already, show alternate travel
    if e.activator.cell.id:lower():find(CELL:lower(), nil, true) or e.activator.position:distance(tes3vector3.new(unpack(destination[CELL].position))) <= 8196 then
        if config.showConfirm then
            tes3.messageBox{
                message = i18n("main.alreadyInCell", {CELL}),
                buttons = {tes3.findGMST("sYes").value, tes3.findGMST("sNo").value},
                callback = function(b)
                    if b.button == 0 then
                        goToPresetPoint(e, CELL)
                    end
                end
            }
        else
            goToPresetPoint(e, CELL)
        end
        return
    end

    -- //reset? deactivate any transition fader to start a new one from this mod
    tes3.worldController.transitionFader:deactivate()
    tes3.fadeOut({duration = 0.3})

    --//check if confirmation is needed and if 'extra realism' mode is enabled, then proceed to the next stage
    if config.showConfirm then
        if config.extraRealism then
            tes3.messageBox {
                message = string.format(i18n("main.travelTo", {e.target.object.name})),
                buttons = {i18n("main.recklessly"), i18n("main.cautiously"), "No"},
                callback = function(b)
                    if b.button == 0 then
                        postFastTravel(e, CELL, "Reckless")
                    elseif b.button == 1 then
                        postFastTravel(e, CELL, "Cautious")
                    else
                        tes3.fadeIn({duration = 2})
                    end
                end
            }
        else
            tes3.messageBox {
                message = string.format(i18n("main.travelTo", {e.target.object.name})),
                buttons = {tes3.findGMST("sYes").value, tes3.findGMST("sNo").value},
                callback = function(b)
                    if b.button == 0 then
                        postFastTravel(e, CELL, "Normal")
                    else
                        tes3.fadeIn({duration = 2})
                    end
                end
            }
        end
    else
        postFastTravel(e, CELL, "Normal")
    end

end

event.register("activate", postActivated)

event.register("modConfigReady", function()
    config = require("kindi.signpost fast travel.config")
    require("kindi.signpost fast travel.mcm")
end)

event.register("initialized", function()
    --//remove old mod file
    os.remove("Data Files\\MWSE\\mods\\kindi\\signpost fast travel\\penalties.lua")
end)