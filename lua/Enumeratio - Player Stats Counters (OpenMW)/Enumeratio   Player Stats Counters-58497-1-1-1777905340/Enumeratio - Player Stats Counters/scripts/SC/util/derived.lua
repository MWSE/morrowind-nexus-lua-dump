local core = require('openmw.core')
local storage = require('openmw.storage')

local module = {}

local function get(profileId, key)
    return storage.playerSection(profileId):get(key) or 0
end

function module.elapsedDays()
    local days = core.getGameTime() / 86400
    if days < 0 then return 0 end
    return days
end

function module.displayDaysPassed()
    local rawDays = math.floor(core.getGameTime() / 86400)
    return rawDays > 0 and rawDays - 1 or 0
end

function module.safePerDay(total)
    local days = module.elapsedDays()
    if days <= 0 then return nil end
    return total / days
end

function module.kdRatio(profileId)
    local kills = get(profileId, "killCount")
    local deaths = get(profileId, "deathCount")
    if kills == 0 and deaths == 0 then return nil end
    if deaths <= 0 then return math.huge end
    return kills / deaths
end

function module.totalDistance(profileId)
    return get(profileId, "distOnFoot")
        + get(profileId, "distLevitated")
        + get(profileId, "distJumped")
        + get(profileId, "distSwum")
        + get(profileId, "distMounted")
end

function module.topTravelMode(profileId)
    local entries = {
        { key = "distOnFoot", label = "On Foot" },
        { key = "distMounted", label = "Mounted" },
        { key = "distSwum", label = "Swimming" },
        { key = "distLevitated", label = "Levitating" },
        { key = "distJumped", label = "Airborne" },
    }
    local bestLabel = "None yet"
    local bestValue = 0
    for _, entry in ipairs(entries) do
        local value = get(profileId, entry.key)
        if value > bestValue then
            bestValue = value
            bestLabel = entry.label
        end
    end
    return bestLabel, bestValue
end

function module.favourite(entries, fallback)
    if not entries or #entries == 0 then
        return fallback or "None yet", 0
    end
    return entries[1].name, entries[1].count
end

function module.get(profileId, key)
    return get(profileId, key)
end

return module
