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

    if (hour < config.dawnHour or hour > config.duskHour) then
        common.onLight(reference)
    else
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
    for reference in cell:iterateReferences(tes3.objectType.light) do
        if not reference.supportsLuaData then
            --Can't support lua data
            return
        end
        if not reference.sceneNode then
            --No scene node
            return
        end
        if (config.staticLightsOnly and reference.object.canCarry) then
            --Carryable light when staticLightsOnly is set
            return
        end
        if not reference.sourceMod then
            --Ignore lights placed by the player
            return
        end
        if not common.isSwitchable(reference.object) then
            --Not a switchable light
            return
        end
        if common.wasToggledToday(reference) then
            --Already toggled today
            return
        end
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
        local cell = tes3.player.cell
        if cell.isInterior ~= true then
            for _, cell in pairs(tes3.getActiveCells()) do
                updateLightsInCell(cell)
            end
        end
    end
end

event.register("simulate", onSimulate)


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

-- When we load the game or change cell, flag an update.
local function enterCell()
    if not common.modActive() then return end
    turnOffDungeonLights()
    needUpdate = true
end
event.register("loaded", enterCell)
event.register("cellChanged", enterCell)

