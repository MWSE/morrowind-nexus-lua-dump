local common = require("mer.midnightOil.common")
local logger = common.createLogger("nightDay")
local config = require("mer.midnightOil.config").getConfig()
local Dungeon = require("mer.midnightOil.dungeon")

local function doUpdateLight(reference)
    -- add some randomness to stagger window lighting.
    local hour = tes3.worldController.hour.value
    if config.useVariance then
        local position = reference.position
        local varianceScalar = config.varianceInMinutes / 60
        hour = hour + math.sin(position.x * 1.35 + position.y) * varianceScalar
    end

    if ((hour < config.dawnHour) or (hour > config.duskHour)) then
        logger:debug("doUpdateLight(%s) - turning on", reference.object.id)
        common.onLight(reference)
    else
        logger:debug("doUpdateLight(%s) - turning off", reference.object.id)
        common.removeLight(reference)
    end
end

local function updateLightsInCell(cell)
    if common.cellIsBlacklisted(cell) then
        --Cell is excluded
        return
    end
    if config.settlementsOnly and not cell.restingIsIllegal then
        -- Only update lights in settlements
        return
    end
    logger:debug("updateLightsInCell(%s)", cell.id)

    ---@param reference tes3reference
    local function isValid(reference)
        if reference.disabled then
            --Reference is disabled
            logger:trace("Reference %s is disabled", reference.object.id)
            return false
        end
        if reference.deleted then
            --Reference is deleted
            logger:trace("Reference %s is deleted", reference.object.id)
            return false
        end
        if not reference.supportsLuaData then
            --Can't support lua data
            logger:trace("Reference %s does not support lua data", reference.object.id)
            return false
        end
        if not reference.sceneNode then
            --No scene node
            logger:trace("Reference %s has no scene node", reference.object.id)
            return false
        end
        if (config.staticLightsOnly and reference.object.canCarry) then
            --Carryable light when staticLightsOnly is set
            logger:trace("Reference %s is a carryable light", reference.object.id)
            return false
        end
        if not common.isSwitchable(reference.object) then
            --Not a switchable light
            logger:trace("Reference %s is not a switchable light", reference.object.id)
            return false
        end
        if common.wasToggledToday(reference) then
            --Already toggled today
            logger:trace("Reference %s was toggled today", reference.object.id)
            return false
        end
        return true
    end

    local lightsToProcess = {}
    for reference in cell:iterateReferences(tes3.objectType.light) do
        if isValid(reference) then
            table.insert(lightsToProcess, reference)
        end
    end

    for _, reference in ipairs(lightsToProcess) do
        doUpdateLight(reference)
    end
end

-- Manual flag for forcing an update. If set.
local needUpdate = false
-- The timestamp of the last time we updated glow objects.
local lastUpdateTimestamp = 0
local function onSimulate(e)
    if not common.modActive() then return end
    local timeDifference = e.timestamp - lastUpdateTimestamp
    if (needUpdate or timeDifference > 0.08) then
        needUpdate = false
        lastUpdateTimestamp = e.timestamp
        if tes3.player.cell.isInterior ~= true then
            for _, cell in pairs(tes3.getActiveCells()) do
                updateLightsInCell(cell)
            end
        end
    end
end
--event.register("simulate", onSimulate)


local function turnOffDungeonLights()
    if not common.modActive() then return end
    if not config.dungeonLightsOff then return end
    logger:debug("turnOffDungeonLights()")
    local cell = tes3.player.cell
    local dungeon = Dungeon:new(cell)
    if dungeon then
        logger:debug("turnOffDungeonLights() - processing dungeon")
        dungeon:processLights()
    end
end

---@param cell tes3cell
local function findAndRemoveDupLights(cell)
    if tes3.player.data.tmpCellsDupProcessed and tes3.player.data.tmpCellsDupProcessed[cell.id] then
        return
    end
    tes3.player.data.tmpCellsDupProcessed = tes3.player.data.tmpCellsDupProcessed or {}
    tes3.player.data.tmpCellsDupProcessed[cell.id] = true
    local lightPositions = {}
    local refsToDelete = {}
    for reference in cell:iterateReferences(tes3.objectType.light) do
        local posKey = string.format("%.2f,%.2f,%.2f", reference.position.x, reference.position.y, reference.position.z)
        if lightPositions[posKey] then
            logger:warn("Found duplicate light: %s", reference.object.id)
            table.insert(refsToDelete, reference)
        else
            lightPositions[posKey] = true
        end
    end
    for _, ref in ipairs(refsToDelete) do
        ref:delete()
    end
end


-- When we load the game or change cell, flag an update.
local function enterCell(e)
    if not common.modActive() then return end
    turnOffDungeonLights()
    findAndRemoveDupLights(e.cell or tes3.player.cell)
    needUpdate = true
end
event.register("loaded", enterCell)
event.register("cellChanged", enterCell)

