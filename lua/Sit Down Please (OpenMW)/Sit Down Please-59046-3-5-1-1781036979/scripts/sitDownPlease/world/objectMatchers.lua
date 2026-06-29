-- world/objectMatchers.lua
---@omw-context all
-- Shared, data-driven object classification helpers for Sit Down Please 3.
-- Keep this file pure and conservative: it should not claim, replace, or mutate objects.
local module = {}

local function normalizeId(value)
    if value == nil then return nil end
    return string.lower(tostring(value))
end
module.normalizeId = normalizeId

local function objectRecord(obj)
    local ok, rec = pcall(function()
        if obj and obj.type and obj.type.record then
            return obj.type.record(obj)
        end
        return nil
    end)
    if ok then return rec end
    return nil
end
module.objectRecord = objectRecord

local function addKey(keys, seen, value)
    local key = normalizeId(value)
    if key and key ~= "" and not seen[key] then
        seen[key] = true
        keys[#keys + 1] = key
    end
end

function module.profileKeys(obj)
    local keys = {}
    local seen = {}
    if not obj then return keys end

    addKey(keys, seen, obj.recordId)
    addKey(keys, seen, obj.id)

    local rec = objectRecord(obj)
    if rec then
        addKey(keys, seen, rec.id)
        addKey(keys, seen, rec.name)
        addKey(keys, seen, rec.model)
    end

    return keys
end

function module.objectEnabled(obj)
    if not obj then return false end
    local ok, enabled = pcall(function() return obj.enabled end)
    if ok and enabled == false then return false end
    return true
end

function module.hiddenOrStagedObjectReason(obj)
    local keys = module.profileKeys(obj)
    for _, key in ipairs(keys) do
        if key:find("roht_mg_rubble_chair", 1, true)
            or (key:find("roht", 1, true) and key:find("rubble", 1, true) and key:find("chair", 1, true)) then
            return "hidden_or_staged_furniture"
        end
        if key:find("_invisible", 1, true) or key:find("invisible_", 1, true) or key:find("hidden", 1, true) then
            return "hidden_or_staged_furniture"
        end
    end
    return nil
end

function module.anyKeyLooksLike(keys, predicate)
    for _, key in ipairs(keys or {}) do
        if predicate(key) then return true, key end
    end
    return false, nil
end

function module.recordLooksLikeSittable(recordId)
    if not recordId then return false end
    local text = normalizeId(recordId) or ""
    if (text:find("enchant", 1, true) or text:find("encahnt", 1, true))
        and text:find("table", 1, true) then
        return false
    end
    return text:find("stool", 1, true)
        or text:find("bench", 1, true)
        or text:find("chair", 1, true)
end

function module.recordLooksLikeBed(recordId)
    if not recordId then return false end
    return recordId:find("bed", 1, true) ~= nil
        or recordId:find("bedroll", 1, true) ~= nil
        or recordId:find("hammock", 1, true) ~= nil
        or recordId:find("bunk", 1, true) ~= nil
end

function module.surfaceText(recordId, model, name, kind)
    return (tostring(recordId or "") .. " "
        .. tostring(model or "") .. " "
        .. tostring(name or "") .. " "
        .. tostring(kind or "")):lower()
end

function module.objectText(obj, modelPath, name)
    local model = nil
    if type(modelPath) == "function" then
        local ok, value = pcall(modelPath, obj)
        if ok then model = value end
    else
        model = modelPath
    end
    if name == nil then
        local rec = objectRecord(obj)
        name = rec and rec.name or nil
    end
    return module.surfaceText(obj and (obj.recordId or obj.id), model, name)
end

function module.textLooksLikeSeat(text)
    text = tostring(text or ""):lower()
    return text:find("stool", 1, true) ~= nil
        or text:find("chair", 1, true) ~= nil
        or text:find("bench", 1, true) ~= nil
end

function module.surfaceKindFromText(text)
    text = tostring(text or ""):lower()
    if text:find("barrel", 1, true) or text:find("barrow", 1, true) or text:find("barstool", 1, true) then
        return nil
    end
    if module.textLooksLikeSeat(text) then return nil end
    if text:find("counter", 1, true)
        or text:find("demidbar", 1, true)
        or text:find("de_rm_bar", 1, true)
        or text:find("_bar_", 1, true)
        or text:find("/bar_", 1, true)
        or text:match("^bar[_%-%s]")
        or text:match("[_%-%s]bar[_%-%s]")
        or text:match("[_%-%s]bar$") then
        return "bar"
    end
    if text:find("lecturn", 1, true)
        or text:find("lectern", 1, true) then
        return "lectern"
    end
    if text:find("grinder", 1, true)
        or text:find("grinderwheel", 1, true) then
        return "grinder"
    end
    if text:find("table", 1, true)
        or text:find("desk", 1, true) then
        return "table"
    end
    if text:find("furnm_shelf_02", 1, true)
        or text:find("furn_n_m_shelf_02", 1, true)
        or text:find("furn_n_m_shlf02", 1, true) then
        return "table"
    end
    return nil
end

function module.textLooksLikeTableOrBarSurface(text)
    return module.surfaceKindFromText(text) ~= nil
end

function module.objectSurfaceKind(obj, modelPath, name)
    return module.surfaceKindFromText(module.objectText(obj, modelPath, name))
end

function module.objectLooksLikeTableOrBarSurface(obj, modelPath, name)
    return module.objectSurfaceKind(obj, modelPath, name) ~= nil
end


local lightKinds = {
    candle = { setting = "lightControlCandles" },
    lantern = { setting = "lightControlLanterns" },
    lamp = { setting = "lightControlLanterns" },
    torch = { setting = "lightControlTorches" },
    -- Generic "light" must be checked last. Most real records start with
    -- light_, e.g. light_de_candle_15_64. A pairs() pass can see "light" before
    -- "candle" and misclassify nearby candles as disabled generic lights.
    light = { setting = nil, generic = true },
}

local orderedLightKinds = {
    "candle",
    "lantern",
    "lamp",
    "torch",
    "light",
}

local heatSourceTerms = {
    "fire",
    "brazier",
    "pitfire",
    "forge",
    "heat",
    "lava",
    "burner",
    "logpile",
}

function module.recordLooksLikeHeatSource(recordId)
    if not recordId then return false end
    for _, term in ipairs(heatSourceTerms) do
        if recordId:find(term, 1, true) then return true, term end
    end
    return false, nil
end

function module.classifyLight(obj, settings)
    if not obj then return nil, "missing_object" end
    local keys = module.profileKeys(obj)
    if #keys == 0 then return nil, "missing_record" end

    -- Be conservative with generated/off records so this system does not fight
    -- itself or other light-control mods.
    for _, key in ipairs(keys) do
        if key:find("sitdownplease3_off_", 1, true)
            or key:find("sdp3_off_", 1, true)
            or key:find("leavethelightsoff", 1, true)
            or key:find("ltlo", 1, true) then
            return nil, "generated_or_external_off_record"
        end
    end

    for _, key in ipairs(keys) do
        local heat = module.recordLooksLikeHeatSource(key)
        if heat then
            if settings and settings.lightControlFires == true then
                return "fire", nil
            end
            return nil, "heat_source_excluded"
        end
    end

    for _, key in ipairs(keys) do
        for _, kind in ipairs(orderedLightKinds) do
            local data = lightKinds[kind]
            if key:find(kind, 1, true) then
                local setting = data and data.setting
                if setting and settings and settings[setting] ~= true then
                    return nil, kind .. "_disabled"
                end
                if data and data.generic then
                    -- Generic light records are ordinary controllable lights, but
                    -- classify them as lantern-class so they are not rejected by
                    -- the later category gate.
                    if settings and settings.lightControlLanterns == true then
                        return "lantern", "generic_light_record"
                    elseif settings and settings.lightControlCandles == true then
                        return "candle", "generic_light_record"
                    end
                    return nil, "generic_light_disabled"
                end
                return kind, nil
            end
        end
    end

    -- Some vanilla/MWSE-added candle-like objects are still Light instances but
    -- have unhelpful IDs or names. If the engine says it is a Light and the user
    -- enabled ordinary candle/lantern control, treat it as a generic lantern-class
    -- sleep light instead of silently ignoring nearby bedside lights.
    if settings and (settings.lightControlLanterns == true or settings.lightControlCandles == true) then
        return "lantern", "generic_light_instance"
    end

    return nil, "not_light_like"
end

function module.sameCell(a, b)
    return a and b and a.cell and b.cell and a.cell == b.cell
end

return module
