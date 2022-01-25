
local common = require('ss20.common')
local config = common.config
local modName = config.modName

local offerings = config.offerings
local offeringsList = {}
for k, _ in pairs(offerings) do
    table.insert(offeringsList, k)
end

local function getCurrentHours()
    return (tes3.worldController.daysPassed.value * 24) + tes3.worldController.hour.value
end

local function getLastOffering()
    local data = tes3.player.data[modName]
    data.lastOffering = data.lastOffering or -24
    return data.lastOffering
end

local function updateLastOffering()
    local now = getCurrentHours()
    tes3.player.data[modName].lastOffering = now
    common.log:debug("Updating lastOffering to %s", now)
end

local function hasCompletedQuest()
    local jIndex = tes3.getJournalIndex{ id = 'ss20_main' }
    return jIndex >= 60
end

local function hasDayPassed()
    common.log:debug("Checking hasDayPassed. CurrentHours: %s, lastOfferingHours:, %s",
    getCurrentHours(), getLastOffering() )
    return (getCurrentHours() - getLastOffering()) > 24
end

local function pickOffering()
    local offering = table.choice(offeringsList)
    common.log:debug("Picked %s as offering", offering)
    return offering
end

local function getRefHeight(ref)
    local bb = ref.sceneNode:createBoundingBox(ref.scale)
    return -bb.min.z * ref.scale
end

local function makeOffering(platter)
    local offeringId = pickOffering()
    local offering = tes3.createReference{
        object = offeringId,
        position = platter.position:copy() ,
        orientation = platter.orientation:copy(),
        cell = platter.cell,
    }
    local height = getRefHeight(offering)
    common.log:debug("Height: %s", height)
    offering.position = {
        platter.position.x,
        platter.position.y,
        platter.position.z + height
    }
    updateLastOffering()
    common.log:debug("Placed new offering: %s", offering)
end

local function checkReplaceEmptyPlatter(e)
    local platter = tes3.getReference('ss20_platter_offering')
    if platter then
        local platterEmpty = true
        for ref in e.cell:iterateReferences() do
            if offerings[ref.baseObject.id:lower()] then
                if ref.position:distance(platter.position) < 20 then
                    mwse.log("Found %s already on platter", ref)
                    platterEmpty = false
                end
            end
        end
        if platterEmpty then
            common.log:debug("Platter is empty")
            makeOffering(platter)
        end
    end
end

local function onCellChanged(e)
    local isShrine = e.cell.id == 'Shrine of Vernaccus'
    if isShrine and hasDayPassed() and hasCompletedQuest() then
        common.log:debug("Offering check passed")
        checkReplaceEmptyPlatter(e)
    end
end

event.register("cellChanged", onCellChanged)