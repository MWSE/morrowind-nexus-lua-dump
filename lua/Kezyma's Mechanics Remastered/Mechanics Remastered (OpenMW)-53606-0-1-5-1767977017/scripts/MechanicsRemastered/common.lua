--[[
    Kezyma's Mechanics Remastered - Common Utilities
    OpenMW Port

    Shared utility functions and formulas.
    Mathematical formulas match the MWSE implementation exactly.
]]

local core = require('openmw.core')

local K = {}

--[[
    Clamp a value to a range.
]]
function K.limitToRange(val, min, max)
    if val > max then
        val = max
    elseif val < min then
        val = min
    end
    return val
end

--[[
    Health regeneration rate per second (before timescale).
    Formula: (0.1 * endurance) / 3600 * speedMultiplier
    Base rate: 10% of endurance per hour

    Matches MWSE: K.healthPerSecond(endurance)
]]
function K.healthPerSecond(endurance, speedMultiplier)
    local rps = (0.1 * endurance) / 60 / 60
    return rps * speedMultiplier
end

--[[
    Health regeneration calculation per tick.
    MWSE runs on 1-second timer and multiplies by timescale.
    OpenMW uses onUpdate(dt) so we multiply by dt * timescale for equivalent behavior,
    OR pass dt=1 for 1-second equivalent.

    Matches MWSE: K.healthRegenCalculation(endurance)
]]
function K.healthRegenCalculation(endurance, speedMultiplier, timescale)
    local rps = K.healthPerSecond(endurance, speedMultiplier)
    return rps * timescale
end

--[[
    Magicka regeneration rate per second (before timescale).
    Formula: (fRestMagicMult * intelligence) / 3600 * speedMultiplier
    Default fRestMagicMult is 0.15 (15% of intelligence per hour)

    Matches MWSE: K.magickaPerSecond(int)
]]
function K.magickaPerSecond(intelligence, speedMultiplier)
    local mult = 0.15
    pcall(function()
        mult = core.getGMST('fRestMagicMult') or 0.15
    end)
    local rps = (mult * intelligence) / 60 / 60
    return rps * speedMultiplier
end

--[[
    Magicka regeneration calculation per tick.

    Matches MWSE: K.magickaRegenCalculation(int)
]]
function K.magickaRegenCalculation(intelligence, speedMultiplier, timescale)
    local rps = K.magickaPerSecond(intelligence, speedMultiplier)
    return rps * timescale
end

--[[
    Calculate total regeneration for a time period (used for waiting).
    hoursWaited: number of game hours
    Returns total health/magicka to regenerate
]]
function K.healthRegenForHours(endurance, speedMultiplier, hoursWaited)
    local rps = K.healthPerSecond(endurance, speedMultiplier)
    return rps * 60 * 60 * hoursWaited
end

function K.magickaRegenForHours(intelligence, speedMultiplier, hoursWaited)
    local rps = K.magickaPerSecond(intelligence, speedMultiplier)
    return rps * 60 * 60 * hoursWaited
end

return K
