local types = require("openmw.types")

local rats = {}

local ratModels = {
    -- vanilla
    ["rust rat"] = true,
    -- OAAB_Data
    ["bonerat"] = true,
    -- Tamriel_Data
    ["tr_rat_col_01"] = true,
    ["tr_rat_col_02"] = true,
    ["tr_mouse00_ya"] = true,
    ["tr_mouse01_ya"] = true,
    ["tr_mouse02_ya"] = true,
}

rats.isRat = function(actor)
    if actor.type ~= types.Creature then
        return false
    end

    local record = actor.type.records[actor.recordId]
    
    local name = record.name:lower()
    if name == "rat"
        or name:find("^rat ")
        or name:find(" rat ")
        or name:find(" rat$")
    then
        return true
    end

    local model = record.model
    if ratModels[model] then
        return true
    end

    return false
end

return rats
