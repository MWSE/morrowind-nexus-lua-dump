local common = require("mer.midnightOil.common")
local conf = require("mer.midnightOil.config")


local function updateLightsInCell(cell)
    local config = conf.getConfig()
    if config.settlementsOnly and not cell.restingIsIllegal then
        return
    end

    local dawnHour = config.dawnHour
    local duskHour = config.duskHour
    local useVariance = config.useVariance
    local varianceScalar = config.varianceInMinutes / 60

    local gameHour = tes3.worldController.hour.value
    for reference in cell:iterateReferences() do
        if reference.sceneNode and reference.object.objectType == tes3.objectType.light then
            --check for static light settings
            if not (config.staticLightsOnly and reference.object.canCarry) then
                if common.isSwitchable(reference.object) then
                    if not common.wasToggledToday(reference) then
                        -- add some randomness to stagger window lighting.
                        local hour = gameHour
                        if (useVariance) then
                            local position = reference.position
                            hour = hour + math.sin(position.x * 1.35 + position.y) * varianceScalar
                        end

                        if (hour < dawnHour or hour > duskHour) then
                            common.onLight(reference)
                        else
                            common.removeLight(reference)
                        end
                    end
                end
            end
        end
    end
end

local function updateLights()

    if tes3.player.cell.isInterior ~= true then
        for _, cell in pairs(tes3.getActiveCells()) do
            updateLightsInCell(cell)
        end
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
        updateLights()
        needUpdate = false
        lastUpdateTimestamp = e.timestamp
    end
end

event.register("simulate", onSimulate)


-- When we load the game or change cell, flag an update.
local function flagNeedForUpdate()
    if not common.modActive() then return end
    needUpdate = true
end
event.register("loaded", flagNeedForUpdate)
event.register("cellChanged", flagNeedForUpdate)

