local MessageBox = require("Danae.Stables.util.messageBox")
local logger = require("logging.logger").new{
    name = "Guar Stables",
    logLevel = "INFO"
}

local MAX_RESIDENT_DISTANCE = 100
local activatorIds = {
    aa_stable_guar_act = true
}

local function getName(resident)
    local name = resident.data.tgw and resident.data.tgw.name or resident.object.name
    return name
end

local function getNearbyCompanions()
    logger:debug("Getting Nearby Companions")
    local nearbyCompanions = {}
    for mobile in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
        if tes3.getCurrentAIPackageId(mobile) == tes3.aiPackage.follow then
            table.insert(nearbyCompanions, mobile.reference)
        end
    end
    logger:debug("Found %d companions", #nearbyCompanions)
    return nearbyCompanions
end

local function filterCreatures(companions)
    logger:debug("Filtering Creatures")
    local creatures = {}
    for _, companion in ipairs(companions) do
        if companion.baseObject.objectType == tes3.objectType.creature then
            table.insert(creatures, companion)
        end
    end
    logger:debug("Found %d creatures", #creatures)
    return creatures
end

---@param stables tes3reference
local function getResident(stables)
    logger:debug("Getting Resident")
    local residentID = stables.data.guarStablesResident
    if not residentID then return end
    for reference in stables.cell:iterateReferences() do
        if reference then
            if reference.baseObject.id:lower() == residentID:lower() then
                if reference.position:distance(stables.position) < MAX_RESIDENT_DISTANCE then
                    logger:debug("Found Resident: %s", reference.baseObject.id)
                    return reference
                end
            end
        end
    end
end

local function getStables(resident)
    logger:debug("Getting Stables")
    for reference in resident.cell:iterateReferences() do
        if reference then
            logger:debug(reference)
            if activatorIds[reference.baseObject.id:lower()] then
                logger:debug("Found Stables, checking resident data %s", reference.baseObject.id)
                if reference.data.guarStablesResident == resident.baseObject.id:lower() then
                    logger:debug("Has resident data, checking distance: %s", reference.baseObject.id)
                    if reference.position:distance(resident.position) < MAX_RESIDENT_DISTANCE then
                        logger:debug("Has correct resident data and distance, returning: %s", reference.baseObject.id)
                        return reference
                    end
                end
            end
        else
            logger:error("Missing reference in :iterateReferences")
        end
    end
end

---@param stables tes3reference
---@param resident tes3reference
local function releaseResident(resident, stables)
    logger:debug("Releasing Resident %s", resident.object.id)
    tes3.setAIFollow{ reference = resident, target = tes3.player }
    --Guar whisperer shit...
    if resident.data.tgw then
        resident.data.tgw.aiState = "following"
        resident.data.tgw.followingRef = "player"
    end
    if stables then
        stables.data.guarStablesResident = nil
    else
        logger:error("unable to find stables for resident %s", resident.object.id)
    end
    resident.data.inGuarStables = nil
    tes3.messageBox("%s has been released from the stables.", getName(resident))
end

---@param stables tes3reference
---@param resident tes3reference
local function houseResident(stables, resident)
    logger:debug("Housing Resident %s", resident.object.id)
    tes3.positionCell{
        reference = resident,
        cell = stables.cell,
        position = stables.position,
        orientation = stables.orientation
    }
    tes3.setAIWander{
        reference = resident,
        range = 0,
        idles = {
            0, --sit
            0, --eat
            0, --look
            0, --wiggle
            0, --n/a
            0, --n/a
            0, --n/a
            0
        },
        duration = 2
    }
    --Guar whisperer shit...
    if resident.data.tgw then
        resident.data.tgw.aiState = "waiting"
        resident.data.tgw.followingRef = nil
    end

    --tes3.setAITravel{ reference = resident, destination = stables.position }
    stables.data.guarStablesResident = resident.baseObject.id:lower()
    resident.data.inGuarStables = true

    tes3.messageBox("%s will wait for you in the stables.", getName(resident))
end

local function selectCompanionMenu(stables, companions)
    logger:debug("Opening Select Companion Menu")
    local buttons = {}
    for _, companion in ipairs(companions) do
        local button = {
            text = getName(companion),
            callback = function()
                logger:debug("Selected %s to house", companion.object.id)
                houseResident(stables, companion)
            end
        }
        table.insert(buttons, button)
    end

    MessageBox{
        message = "Select a companion to house in the stables.",
        buttons = buttons,
        doesCancel = true
    }
end


---@param stables tes3reference
local function selectResident(stables)
    local nearbyCompanions = getNearbyCompanions()
    local creatures = filterCreatures(nearbyCompanions)
    if #creatures == 0 then
        tes3.messageBox("You have no companions to house.")
    elseif #creatures == 1 then
        houseResident(stables, creatures[1])
    elseif #creatures > 1 then
        selectCompanionMenu(stables, creatures)
    end
end

---@param e activateEventData
local function onActivate(e)
    local playerActivating = e.activator == tes3.player
    local isStable = activatorIds[e.target.baseObject.id:lower()]
    if playerActivating and isStable then
        logger:debug("Player activating stables")
        local stables = e.target
        local resident = getResident(e.target)
        if resident then
            --Stables already has resident, make them follow player
            releaseResident(resident, stables)
        else
            selectResident(stables)
        end
    end
end
event.register(tes3.event.activate, onActivate)

---@param e activateEventData
local function activateHousedResident(e)
    local isResident = e.target.data.inGuarStables
    if isResident then
        logger:debug("Activating Resident")
        local resident = e.target
        local stables = getStables(resident)
        releaseResident(resident, stables)
        return false
    end
end
event.register(tes3.event.activate, activateHousedResident, { priority = 100000})