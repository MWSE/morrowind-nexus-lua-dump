local common = require("blight.common")

local function getRecentCells()
    -- ensure player.data.blight exists
    local t = tes3.player.data
    t.blight = t.blight or {}

    -- ensure blight.recentCells exists
    t.blight.recentCells = t.blight.recentCells or {}

    -- now return the recentCells table
    return t.blight.recentCells
end

-- Track cells via the `blight.recentCells` table
-- We use this to process a cell only once per day
local function onCellExit(e)
    if not e.cell.region then return end
    local recentCells = getRecentCells()
    local editorName = e.cell.editorName
    local daysPassed = tes3.worldController.daysPassed.value
    recentCells[editorName] = daysPassed
    -- common.debug("Leaving cell '%s' on day %s.", editorName, daysPassed)
end
event.register("cellDeactivated", onCellExit)

-- Clean up the `blight.recentCells` table on save
-- Just so we can keep save files nice and minimal
local function onSave(e)
    local daysPassed = tes3.worldController.daysPassed.value
    local recentCells = getRecentCells()
    for k, v in pairs(recentCells) do
        if v ~= daysPassed then
            recentCells[k] = nil
        end
    end
end
event.register("save", onSave)

-- Helper function to get the day a cell was visited
-- Will only return a value for recently visited cells
local function getDayCellVisited(cell)
    return getRecentCells()[cell.editorName]
end

-- Passive Transmission
local function passiveTransmission(e)
    if not common.config.enablePassiveTransmission then return end

    local object = e.reference.object

    -- ensure the reference is susceptible to blight
    if  object.organic ~= true
        and object.objectType ~= tes3.objectType.npc
        and object.objectType ~= tes3.objectType.creature
    then
        return
    end

    -- ensure the region is susceptible to blight
    local blightLevel = common.getBlightLevel(e.reference.cell)
    if blightLevel <= 0 then
        return
    end

    -- restrict passive transmission to once per day
    local daysPassed = tes3.worldController.daysPassed.value
    local lastVisitDay = getDayCellVisited(e.reference.cell)
    if lastVisitDay == daysPassed then
        -- common.debug("'%s' was reloaded on day %s.", e.reference, daysPassed)
        return
    end

    -- get reference blight data
    local data = e.reference.data
    data.blight = data.blight or {}

    -- check for expired blight diseases on reference, remove if expired
    if data.blight.passiveTransmission then
        for spellId, day in pairs(data.blight.passiveTransmission) do
            if day <= daysPassed then
                common.debug("'%s' recovered from '%s' as on day %s.", e.reference, spellId, daysPassed)
                common.removeBlight(e.reference, spellId)
                data.blight.passiveTransmission[spellId] = nil
            end
        end
    end

    -- we don't need to do anything else if it already had blight disease
    if common.hasBlight(e.reference) then
        return
    end

    -- roll for chance of triggering passive transmission mechanic.
    -- blight level 1 -> 1*5 == 5%
    -- blight level 3 -> 3*5 == 15%
    -- blight level 5 -> 5*5 == 25%
    local chance = blightLevel * 5
    if common.calculateChanceResult(chance) == false then
        return
    end

    common.debug("'%s' was loaded in a blighted cell of level %s on day %s.", e.reference, blightLevel, daysPassed)
    event.trigger("blight:TriggerBlight", {
        reference = e.reference,
        displayMessage = false,
        callback = function(spell)
            -- Setup information to remove disease later.
            data.blight.passiveTransmission = data.blight.passiveTransmission or {}
            data.blight.passiveTransmission[spell.id] = daysPassed + math.random(2, 4)
        end
    })
end

-- Trigger for actors / creatures
event.register("mobileActivated", passiveTransmission)

-- Trigger for organic containers
event.register("referenceActivated", function(e)
    if e.reference.object.organic then
        passiveTransmission(e)
    end
end)
