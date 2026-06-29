-- calibration/testActors.lua
---@omw-context none
--
-- Vanilla Morrowind.esm records used by developer calibration fill/test actions.
-- Keep this list independent of the user's mod stack; unavailable records fall
-- back in the action controller at spawn time.

local M = {}

M.records = {
    "ken",
    "fargoth",
    "todd",
    "ajira",
    "m'aiq",
}

local labels = {
    ["ajira"] = "Ajira",
    ["bm_snowarmortest"] = "Snow Bear armor test guy",
    ["bm_snowarmortest_2"] = "Snow Wolf armor test guy",
    ["chappy_test_guy"] = "Chappy's Test guy",
    ["fargoth"] = "Fargoth",
    ["ken"] = "Admiral Rolston",
    ["m'aiq"] = "M'Aiq the Liar",
    ["therana"] = "Therana",
    ["todd"] = "Todd's Super Tester Guy",
}

local legacyGeneratedRecords = {
    ["bm_snowarmortest"] = true,
    ["bm_snowarmortest_2"] = true,
    ["chappy_test_guy"] = true,
}

local actorBaseLabels = {
    ["todd"] = "Todd",
}

function M.normalizedRecordId(objOrRecordId)
    if type(objOrRecordId) == "string" then return string.lower(objOrRecordId) end
    return objOrRecordId and objOrRecordId.recordId and string.lower(tostring(objOrRecordId.recordId)) or ""
end

function M.isTestRecord(recordId)
    local id = M.normalizedRecordId(recordId)
    for _, candidate in ipairs(M.records) do
        if id == string.lower(candidate) then return true end
    end
    return legacyGeneratedRecords[id] == true
end

function M.recordLabel(recordId)
    local id = M.normalizedRecordId(recordId)
    return labels[id] or tostring(recordId or "test NPC")
end

function M.actorBaseLabel(actor)
    local raw = actor and actor.recordId and tostring(actor.recordId) or tostring(actor and actor.id or "test NPC")
    local id = M.normalizedRecordId(raw)
    if actorBaseLabels[id] then return actorBaseLabels[id] end
    return M.recordLabel(raw)
end

return M
