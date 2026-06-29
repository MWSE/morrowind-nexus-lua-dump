-- interactions/sleeping/candidateRules.lua
---@omw-context none
--
-- Conservative fallback-sleep object classifier. Explicit bed profile rows are
-- handled by profiles/catalog.lua; this module decides only whether unprofiled
-- objects are plausible sleep furniture.

local objectMatchers = require('scripts/sitDownPlease/world/objectMatchers')

local M = {}

local function lower(value)
    if value == nil then return "" end
    return string.lower(tostring(value))
end

local function objectRecord(obj)
    return objectMatchers.objectRecord(obj)
end

local function objectRecordId(obj)
    local rec = objectRecord(obj) or {}
    return lower(obj and (obj.recordId or obj.id) or rec.id)
end

local function objectModel(obj, modelPath)
    local rec = objectRecord(obj) or {}
    return lower(modelPath or rec.model)
end

local function fieldText(obj, modelPath)
    local rec = objectRecord(obj) or {}
    return table.concat({
        lower(obj and obj.recordId),
        lower(obj and obj.id),
        lower(rec.id),
        lower(rec.name),
        lower(modelPath or rec.model),
    }, " ")
end

local function tokens(text)
    local list = {}
    local set = {}
    for token in lower(text):gmatch("[a-z0-9]+") do
        list[#list + 1] = token
        set[token] = true
    end
    return list, set
end

local function containsAny(text, terms)
    for _, term in ipairs(terms) do
        if text:find(term, 1, true) then return true, term end
    end
    return false, nil
end

local function hasSequence(list, a, b)
    for i = 1, math.max(0, #list - 1) do
        if list[i] == a and list[i + 1] == b then return true end
    end
    return false
end

local function hasAnyToken(set, terms)
    for _, term in ipairs(terms) do
        if set[term] == true then return true, term end
    end
    return false, nil
end

local forbiddenTerms = {
    "contain_",
    "/contain",
    "chest",
    "crate",
    "barrel",
    "desk",
    "table",
    "counter",
    "text_",
    "/text",
    "parchment",
    "scroll",
    "book",
    "bk_",
    "note",
    "marker",
}

local clothingTokens = {
    "pants", "pant", "shirt", "robe", "robes", "skirt", "shoes", "shoe",
    "boots", "boot", "glove", "gloves", "belt", "helm", "helmet",
    "cuirass", "pauldron", "pauldrons", "greaves", "clothes", "clothing",
    "armor", "armour",
}

local strongSingleTokens = {
    "bed", "beds", "bedroll", "bunk", "hammock", "mattress", "matress", "pallet", "cot",
}

local forbiddenFallbackRecords = {
    jx_pillow_bed = true,
    jx_bed_cushion_round_03 = true,
    jx_bed_cushion_round_06 = true,
    jx_bed_cushion_square_03 = true,
    jx_bed_cushion_square_09 = true,
}

local function classifyBedTypeFromText(text, tokenList, tokenSet)
    if text:find("hammock", 1, true) then return "hammock" end
    if text:find("bedroll", 1, true)
        or text:find("bed_roll", 1, true)
        or text:find("matressnomad", 1, true)
        or text:find("mattressnomad", 1, true)
        or hasSequence(tokenList, "bed", "roll")
        or tokenSet.bedroll
    then
        return "bedroll"
    end
    if tokenSet.bunk
        or text:find("bunkbed", 1, true)
        or text:find("bedbunk", 1, true)
        or text:find("_bunk_", 1, true)
    then
        return "bunk"
    end
    if text:find("beddouble", 1, true)
        or text:find("doublebed", 1, true)
        or text:find("double_bed", 1, true)
        or hasSequence(tokenList, "double", "bed")
        or hasSequence(tokenList, "bed", "double")
    then
        return "double"
    end
    return "single"
end

local function classifyClothing(obj, modelPath, set, text)
    local model = objectModel(obj, modelPath)
    if model:find("meshes/pl/", 1, true) == 1 or model:find("/pl/", 1, true) then
        return true
    end
    if model:find("_gnd", 1, true) and containsAny(model, { "pants", "shirt", "robe", "skirt", "shoe", "boot", "glove", "belt", "helm", "cuirass", "pauldron", "greaves", "clothes", "cloth" }) then
        return true
    end
    local matched = hasAnyToken(set, clothingTokens)
    if matched then return true end
    if text:find("meshes/c/", 1, true) and (text:find("shirt", 1, true) or text:find("robe", 1, true) or text:find("pants", 1, true)) then
        return true
    end
    return false
end

function M.classifyDetailed(obj, modelPath)
    local text = fieldText(obj, modelPath)
    if text == "" then return false, "missing_record_text", nil end

    local model = objectModel(obj, modelPath)
    if model == "meshes/" or model == "" then
        return false, "placeholder_or_missing_model", nil
    end

    local tokenList, tokenSet = tokens(text)

    -- Denylist first. Explicit bedProfiles rows bypass this module entirely.
    local recordId = objectRecordId(obj)
    if recordId == "furn_de_practice_mat" or text:find("practice_mat", 1, true) then
        return false, "forbidden_practice_mat", nil
    end
    if forbiddenFallbackRecords[recordId]
        or text:find("jx_bed_cushion", 1, true)
        or text:find("jx_pillow_bed", 1, true) then
        return false, "forbidden_sleep_cushion", nil
    end

    if classifyClothing(obj, modelPath, tokenSet, text) then
        return false, "clothing", nil
    end

    local forbidden, forbiddenTerm = containsAny(text, forbiddenTerms)
    if forbidden then return false, "forbidden_" .. tostring(forbiddenTerm), nil end

    -- Strong fallback allowlist. These are token/phrase-based, not raw substrings.
    local strong, strongTerm = hasAnyToken(tokenSet, strongSingleTokens)
    if strong then return true, "bedlike_" .. tostring(strongTerm), classifyBedTypeFromText(text, tokenList, tokenSet) end
    if hasSequence(tokenList, "bed", "roll") then return true, "bedlike_bed_roll", "bedroll" end
    if hasSequence(tokenList, "bed", "mat") then return true, "bedlike_bed_mat", classifyBedTypeFromText(text, tokenList, tokenSet) end
    if hasSequence(tokenList, "sleep", "mat") then return true, "bedlike_sleep_mat", classifyBedTypeFromText(text, tokenList, tokenSet) end
    if hasSequence(tokenList, "sleeping", "mat") then return true, "bedlike_sleeping_mat", classifyBedTypeFromText(text, tokenList, tokenSet) end

    -- Weak sleep-ish tokens are deliberately not enough by themselves. This keeps
    -- generic practice mats, rugs, and incidental words out of fallback sleeping.
    if tokenSet.mat or tokenSet.rug or tokenSet.sleep or tokenSet.sleeping or text:find("mat", 1, true) then
        return false, "fallback_bedlike_token_not_strong_enough", nil
    end

    return false, "non_sleep_object", nil
end

function M.classify(obj, modelPath)
    local ok, reason = M.classifyDetailed(obj, modelPath)
    return ok, reason
end

return M
