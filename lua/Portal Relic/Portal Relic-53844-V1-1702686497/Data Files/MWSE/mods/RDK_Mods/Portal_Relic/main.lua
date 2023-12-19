
-- Check if a specific door exists in the player data
local function doesDoorExist(doorID)
    local doorRef = tes3.getReference(tes3.player.data.Portal_Relic[doorID])
    return doorRef ~= nil
end

-- Unsummon portal
local function unsummonPortal(doorID)
    local doorRef = tes3.getReference(tes3.player.data.Portal_Relic[doorID])
    if doorRef then
        doorRef:delete()
        tes3.player.data.Portal_Relic[doorID] = nil
        tes3.messageBox("Portal unsummoned.")
    end
end

-- Create and place a door
local function createAndPlaceDoor(doorID, position, cell, orientation)
    -- Check if the door already exists
    if doesDoorExist(doorID) then
        tes3.messageBox("Portal already exists in this location.")
        return
    end

    -- Determine the ID of the corresponding Ac orb based on the doorID
    local correspondingAcOrbID = (doorID == "RDK_Portal1") and "AcReceiverOrb" or "AcTransmissionOrb"
    local orbObject = tes3.getObject(correspondingAcOrbID)

    -- Check if the corresponding Ac orb is placed
    if not tes3.player.data.Portal_Relic or not tes3.player.data.Portal_Relic[correspondingAcOrbID] then
        tes3.messageBox("You need to create a tether to summon a portal, set the " .. orbObject.name .. " on it's stand as well.")
        return
    end

    -- Create the door at the specified position and cell
    local door = tes3.createReference({
        object = doorID,
        position = position,
        orientation = orientation,
        cell = cell
    })

    if door then
        -- Determine the destination based on the doorID
        local destinationStand = (doorID == "RDK_Portal1") and tes3.getReference("OrbStandTwo") or tes3.getReference("OrbStandOne")

        -- Calculate the forward direction of the destination stand based on its orientation (rotated by 90 degrees clockwise)
        local forward = tes3vector3.new(
            math.cos(destinationStand.orientation.z),  -- Rotated by 90 degrees clockwise
            -math.sin(destinationStand.orientation.z), -- Rotated by 90 degrees clockwise
            0
        )

        -- Calculate offset destination based on the destination stand's position and its forward direction
        local offsetDestination = destinationStand.position + forward * 40 -- Adjust to your desired offset distance

        -- Set the destination for the door
        tes3.setDestination({
            reference = door,
            position = offsetDestination,
            orientation = {0, 0, destinationStand.orientation.z +1.57},
            cell = destinationStand.cell
        })

        -- Enable the door and store its reference in the player data
        door:enable()
        tes3.player.data.Portal_Relic[doorID] = door.id
        tes3.messageBox("Portal summoned.")
    else
        tes3.messageBox("Failed to summon portal.")
    end
end




-- Show a message box to choose whether to summon the portal
local function showPortalChoice(doorID, position, cell, orientation)
    tes3.messageBox({
        message = "Summon Portal?",
        buttons = { "Yes", "No" },
        callback = function(e)
            if e.button == 0 then
                createAndPlaceDoor(doorID, position, cell, orientation)
            end
        end
    })
end

-- Check if the player has an orb and offer to place it
local function checkAndPlaceOrb(orbID, acOrbID, standRef)
    local playerHasOrb = tes3.player.object.inventory:contains(orbID)
    local orbObject = tes3.getObject(orbID)

    if playerHasOrb then
        tes3.messageBox({
            message = "Place the " .. orbObject.name .. " on the stand?",
            buttons = { "Yes", "No" },
            callback = function(e)
                if e.button == 0 then
                    tes3.removeItem({ reference = tes3.player, item = orbID, playSound = true })
                    local acOrbRef = tes3.createReference({
                        object = acOrbID,
                        position = standRef.position,
                        orientation = standRef.orientation,
                        cell = standRef.cell
                    })
                    acOrbRef:enable()
                    tes3.player.data.Portal_Relic[acOrbID] = acOrbRef.id
                    tes3.messageBox("You placed the " .. orbObject.name)

                    -- Check if both orbs are now placed
                    local otherOrbID = (acOrbID == "AcTransmissionOrb") and "AcReceiverOrb" or "AcTransmissionOrb"
                    if tes3.player.data.Portal_Relic[otherOrbID] then
                        tes3.messageBox("Tether established.")
                    end
                end
            end
        })
    else
        tes3.messageBox("You do not have the required orb.")
    end
end


-- Remove an Ac orb and unsummon the portal if it exists
local function removeAcOrb(acOrbID, standRef)
    local orbCell = standRef.cell
    local doorID1 = "RDK_Portal1"
    local doorID2 = "RDK_Portal3"
    local coloredOrbID = (acOrbID == "AcTransmissionOrb") and "RDK_BlueOrb" or "RDK_RedOrb"
    local orbObject = tes3.getObject(coloredOrbID)


    -- Get the Ac orb reference
    local acOrbRef = tes3.getReference(tes3.player.data.Portal_Relic[acOrbID])
    if acOrbRef and acOrbRef.cell == orbCell then
        -- Check and delete the first door
        local doorRef1 = tes3.getReference(tes3.player.data.Portal_Relic[doorID1])
        if doorRef1 then
            doorRef1:delete()
            tes3.player.data.Portal_Relic[doorID1] = nil
            tes3.messageBox("Blue Orb portal has collapsed")
        end

        -- Check and delete the second door
        local doorRef2 = tes3.getReference(tes3.player.data.Portal_Relic[doorID2])
        if doorRef2 then
            doorRef2:delete()
            tes3.player.data.Portal_Relic[doorID2] = nil
            tes3.messageBox("Red Orb portal has collapsed")
        end

        -- Delete the Ac orb last
        acOrbRef:delete()
        tes3.player.data.Portal_Relic[acOrbID] = nil
        tes3.addItem({ reference = tes3.player, item = coloredOrbID, count = 1, playSound = true })
        tes3.messageBox(""..orbObject.name.." returned to your inventory")
    end
end


-- Handles activation of orb stands
local function onActivateOrbStand(e)
    if e.activator ~= tes3.player then
        return
    end

    local objectID = e.target.object.id
    if objectID ~= "OrbStandOne" and objectID ~= "OrbStandTwo" then
        return -- Not an orb stand.
    end

    local standRef = e.target
    local acOrbID = (objectID == "OrbStandOne") and "AcTransmissionOrb" or "AcReceiverOrb"
    local orbObject = tes3.getObject(acOrbID)
  

    -- Only handles activations outside of menu mode.
    if not tes3ui.menuMode() then
        if tes3.player.data.Portal_Relic[acOrbID] then
            -- Offer to remove Ac orb
            tes3.messageBox({
                message = "Remove the ".. orbObject.name .." from the stand?",
                buttons = { "Yes", "No" },
                callback = function(choice)
                    if choice.button == 0 then
                        removeAcOrb(acOrbID, standRef)
                    end
                end
            })
        else
            -- Offer to place colored orb
            if objectID == "OrbStandOne" then
                checkAndPlaceOrb("RDK_BlueOrb", "AcTransmissionOrb", standRef)
            else
                checkAndPlaceOrb("RDK_RedOrb", "AcReceiverOrb", standRef)
            end
        end
        return false -- Prevent default pickup behavior outside of menu mode.
    end

    --Only prevents pickup if its orb is on the stand.
    if tes3ui.menuMode() then
       if tes3.player.data.Portal_Relic[acOrbID] then
       tes3.messageBox("You must remove the orb first")
       return false
       end
    end 
end




-- Handle activation of orbs
local function onActivateOrb(e)
    if e.activator ~= tes3.player then
        return
    end

    local objectID = e.target.object.id
    if objectID ~= "AcTransmissionOrb" and objectID ~= "AcReceiverOrb" then
        return
    end

    local doorID = (objectID == "AcTransmissionOrb") and "RDK_Portal1" or "RDK_Portal3"

    if doesDoorExist(doorID) then
        tes3.messageBox({
            message = "Unsummon Portal?",
            buttons = { "Yes", "No" },
            callback = function(choice)
                if choice.button == 0 then
                    unsummonPortal(doorID)
                end
            end
        })
    else
        local position = e.target.position
        local cell = e.target.cell
        local orientation = e.target.orientation
        showPortalChoice(doorID, position, cell, orientation)
    end
end

--Restores the state of the world on game load
local function onGameLoaded()
    if tes3.player.data.Portal_Relic then
        for doorID, doorData in pairs(tes3.player.data.Portal_Relic) do
            if doorData and doorData.id then
                local cell = tes3.getCell({ id = doorData.cell })
                if cell then
                    tes3.createReference({
                        object = doorID,
                        position = doorData.position,
                        orientation = {0, 0, 0},
                        cell = cell
                    }):enable()
                end
            end
        end
    end
end


-- Initialize player data and register event handlers
local function initialized()
    event.register(tes3.event.loaded, function()
        -- Initialize the data structure if it doesn't exist
        tes3.player.data.Portal_Relic = tes3.player.data.Portal_Relic or {
            ["RDK_Portal1"] = nil,
            ["RDK_Portal3"] = nil,
            ["AcTransmissionOrb"] = nil,
            ["AcReceiverOrb"] = nil
        }
    end)

    -- Register the event handlers for orb stand and orb activations
    event.register(tes3.event.activate, onActivateOrbStand)
    event.register(tes3.event.activate, onActivateOrb)
 
 

    -- Register the event handler for restoring state on game load
    event.register(tes3.event.loaded, onGameLoaded)


    print("[Portal Relic] Initialized")
end

event.register(tes3.event.initialized, initialized)
