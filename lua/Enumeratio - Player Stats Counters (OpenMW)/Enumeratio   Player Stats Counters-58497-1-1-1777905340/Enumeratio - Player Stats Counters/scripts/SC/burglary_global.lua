-- ============================================================
-- StatCounters global bridge for ErnBurglary
-- Registers with I.ErnBurglary.onStolenCallback at module level
-- (same pattern as ErnBurglary's own xp/global.lua) and forwards
-- stolen item data to the player via SC_StolenItems events.
-- Soft dependency: does nothing if ErnBurglary is not present.
-- ============================================================
local interfaces = require('openmw.interfaces')

-- Register at module level, same as ErnBurglary's xp/global.lua.
-- By this point in script loading, ErnBurglary's interface.lua
-- (#114) has already registered the interface since our script
-- (#274) loads after it.
local ok, eb = pcall(function() return interfaces.ErnBurglary end)
if ok and eb and eb.onStolenCallback then
    eb.onStolenCallback(function(stolenItemsData)
        for _, data in ipairs(stolenItemsData) do
            local count = data.count or 1
            local value = 0
            if data.itemRecord and data.itemRecord.value then
                value = data.itemRecord.value * count
            end
            if data.player then
                data.player:sendEvent("SC_StolenItems", {
                    count = count,
                    value = value,
                })
            end
        end
    end)
end

return {}
