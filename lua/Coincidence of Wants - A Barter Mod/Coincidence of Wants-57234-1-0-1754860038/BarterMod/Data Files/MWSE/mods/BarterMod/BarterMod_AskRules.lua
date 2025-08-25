-- BarterMod_AskRules.lua
-- Builds askPools filtered by NPC class demand types

local ClassDemand = require("bartermod.BarterMod_ClassDemand")

local this = {}

local fallbackIDs = { "gold_001", "probe_journeyman_01" }

function this.buildAskPools(classID)
    if not classID or classID == "" then classID = "default" end

    local askTypes = ClassDemand.getDemandTypes(classID)
    local askPools = {}

    for _, oType in ipairs(askTypes) do
        askPools[oType] = {}
        for obj in tes3.iterateObjects(oType) do
            if obj.value >= 100
               and obj.value <= 1500
               and not obj.isKey
               and not obj.isSoulGem
            then
                table.insert(askPools[oType], obj)
            end
        end

        -- fallback items if category is empty
        if #askPools[oType] == 0 then
            for _, id in ipairs(fallbackIDs) do
                local obj = tes3.getObject(id)
                if obj then
                    table.insert(askPools[oType], obj)
                end
            end
        end
    end

    return askPools
end

return this
