-- ============================================================
-- StatCounters global bridge for ErnBurglary
-- Registers with I.ErnBurglary.onStolenCallback at module level
-- (same pattern as ErnBurglary's own xp/global.lua) and forwards
-- stolen item data to the player via SC_StolenItems events.
-- Soft dependency: does nothing if ErnBurglary is not present.
-- ============================================================
local interfaces = require('openmw.interfaces')
local core = require('openmw.core')
local types = require('openmw.types')

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



-- ============================================================
-- Spell Framework Plus / OSSC spell-cast bridge
--
-- OSSC quick-casts by sending MagExp_CastRequest to Spell
-- Framework Plus. Forward successful player requests back to
-- Enumeratio's player script. This also covers OSSC enchanted-item
-- quick-casts, whose charge is consumed outside Enumeratio's normal
-- selected-item polling path.
-- ============================================================
local function getItemName(item)
    if not item then return nil end
    local ok, name = pcall(function()
        for _, itype in ipairs({types.Weapon, types.Armor, types.Clothing, types.Book, types.MiscItem, types.Miscellaneous}) do
            if itype and itype.objectIsInstance and itype.objectIsInstance(item) then
                local rec = itype.record(item)
                if rec and rec.name and rec.name ~= "" then return rec.name end
            end
        end
        return nil
    end)
    if ok and name and name ~= "" then return name end
    return nil
end

local function getSpellName(spellId)
    if not spellId or spellId == "" then return nil end
    local ok, rec = pcall(function() return core.magic.spells.records[tostring(spellId)] end)
    if ok and rec and rec.name and rec.name ~= "" then return rec.name end
    return nil
end

local function onMagExpCastRequest(data)
    if type(data) ~= "table" then return end

    local attacker = data.attacker
    if not attacker then return end

    local isPlayer = false
    pcall(function() isPlayer = types.Player.objectIsInstance(attacker) end)
    if not isPlayer then return end

    local itemName = getItemName(data.item)
    local itemRecordId = data.itemRecordId
    if data.item and not itemRecordId then
        pcall(function() itemRecordId = data.item.recordId end)
    end

    attacker:sendEvent("SC_MagExpCastRequest", {
        spellId      = data.spellId and tostring(data.spellId) or nil,
        spellName    = getSpellName(data.spellId),
        isItem       = data.item ~= nil or itemName ~= nil or itemRecordId ~= nil,
        itemName     = itemName,
        itemRecordId = itemRecordId and tostring(itemRecordId) or nil,
    })
end

return {
    eventHandlers = {
        MagExp_CastRequest = onMagExpCastRequest,
    },
}
