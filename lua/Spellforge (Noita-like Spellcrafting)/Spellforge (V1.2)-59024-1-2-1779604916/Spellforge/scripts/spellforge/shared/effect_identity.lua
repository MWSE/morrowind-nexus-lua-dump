local effect_registry = require("scripts.spellforge.shared.effect_support_registry")

local effect_identity = {}

local function readField(value, key)
    if value == nil then
        return nil
    end
    local ok, result = pcall(function()
        return value[key]
    end)
    if ok then
        return result
    end
    return nil
end

local function scalarString(value)
    local value_type = type(value)
    if value_type == "string" then
        return value ~= "" and value or nil
    end
    if value_type == "number" or value_type == "boolean" then
        return tostring(value)
    end
    return nil
end

local function addCandidate(out, seen, value)
    local text = scalarString(value)
    if text and not seen[text] then
        out[#out + 1] = text
        seen[text] = true
    end
end

local function lookupRecord(records, key)
    if records == nil or type(key) ~= "string" or key == "" then
        return nil
    end
    local ok, record = pcall(function()
        return records[key]
    end)
    if ok and record ~= nil then
        return record
    end
    return nil
end

local function callRecordGetter(container, key)
    if container == nil or type(key) ~= "string" or key == "" then
        return nil
    end
    for _, name in ipairs({ "get", "record", "getRecord", "getById" }) do
        local fn = readField(container, name)
        if type(fn) == "function" then
            local ok_self, record_self = pcall(fn, container, key)
            if ok_self and record_self ~= nil then
                return record_self
            end
            local ok_plain, record_plain = pcall(fn, key)
            if ok_plain and record_plain ~= nil then
                return record_plain
            end
        end
    end
    return nil
end

local function normalized(value)
    return effect_registry.normalizeEffectId(value)
end

local function recordId(record)
    return scalarString(readField(record, "id"))
        or scalarString(readField(record, "recordId"))
        or scalarString(readField(record, "effectId"))
        or scalarString(readField(record, "refId"))
end

local function nestedRecordId(value)
    if value == nil then
        return nil
    end
    return recordId(value)
end

local function directRecordFromEffect(effect)
    return readField(effect, "effect")
        or readField(effect, "mgef")
        or readField(effect, "magicEffect")
end

local function exactIdCandidates(effect)
    local out = {}
    local seen = {}
    local effect_type = type(effect)
    if effect_type == "string" or effect_type == "number" or effect_type == "boolean" then
        addCandidate(out, seen, effect)
    elseif effect ~= nil then
        addCandidate(out, seen, readField(effect, "engine_effect_id"))
        addCandidate(out, seen, readField(effect, "record_effect_id"))
        addCandidate(out, seen, readField(effect, "effectId"))
        addCandidate(out, seen, readField(effect, "id"))
        local mgef = readField(effect, "mgef")
        addCandidate(out, seen, scalarString(mgef) or nestedRecordId(mgef))
        addCandidate(out, seen, recordId(directRecordFromEffect(effect)))
    end
    return out
end

local function recordEngineId(record, fallback)
    return recordId(record) or scalarString(fallback)
end

local function findDirect(records, effects_api, candidate)
    return lookupRecord(records, candidate)
        or lookupRecord(records, string.lower(candidate))
        or callRecordGetter(records, candidate)
        or callRecordGetter(effects_api, candidate)
end

local function findCaseInsensitive(records, candidate)
    local lower = string.lower(tostring(candidate or ""))
    if lower == "" then
        return nil
    end
    local found = nil
    local found_key = nil
    pcall(function()
        for key, record in pairs(records or {}) do
            if string.lower(tostring(key)) == lower
                or string.lower(tostring(recordId(record) or "")) == lower then
                found = record
                found_key = key
                break
            end
        end
    end)
    return found, found_key
end

local function uniqueNormalizedMatch(records, normalized_id)
    if type(normalized_id) ~= "string" or normalized_id == "" then
        return nil, {}, 0
    end
    local matches = {}
    pcall(function()
        for key, record in pairs(records or {}) do
            local key_norm = normalized(key)
            local record_norm = normalized(recordId(record))
            if key_norm == normalized_id or record_norm == normalized_id then
                matches[#matches + 1] = {
                    key = key,
                    record = record,
                    engine_effect_id = recordEngineId(record, key),
                }
            end
        end
    end)
    if #matches == 1 then
        return matches[1], matches, 1
    end
    return nil, matches, #matches
end

function effect_identity.readField(value, key)
    return readField(value, key)
end

function effect_identity.scalarString(value)
    return scalarString(value)
end

function effect_identity.normalizeEffectId(value)
    return normalized(value)
end

function effect_identity.recordId(record)
    return recordId(record)
end

function effect_identity.engineEffectIdFromEffect(effect)
    local candidates = exactIdCandidates(effect)
    return candidates[1]
end

function effect_identity.isSpellforgeEffectId(effect_id)
    local id = normalized(effect_id)
    return type(id) == "string" and string.sub(id, 1, 11) == "spellforge_"
end

function effect_identity.copyEngineEffectId(source, target)
    if type(source) ~= "table" or type(target) ~= "table" then
        return target
    end
    local engine_effect_id = scalarString(source.engine_effect_id)
        or scalarString(source.record_effect_id)
    if engine_effect_id then
        target.engine_effect_id = engine_effect_id
    end
    return target
end

function effect_identity.resolveMagicEffectRecord(effect_or_id, records, effects_api)
    local effect = type(effect_or_id) == "table" and effect_or_id or { id = effect_or_id }
    local direct = directRecordFromEffect(effect)
    if direct ~= nil then
        return direct, recordEngineId(direct, effect_identity.engineEffectIdFromEffect(effect)), "embedded_record"
    end

    for _, candidate in ipairs(exactIdCandidates(effect)) do
        local record = findDirect(records, effects_api, candidate)
        if record ~= nil then
            return record, recordEngineId(record, candidate), "exact"
        end
        local ci_record, ci_key = findCaseInsensitive(records, candidate)
        if ci_record ~= nil then
            return ci_record, recordEngineId(ci_record, ci_key or candidate), "case_insensitive"
        end
    end

    local normalized_id = normalized(readField(effect, "id") or effect_identity.engineEffectIdFromEffect(effect))
    local match, matches, count = uniqueNormalizedMatch(records, normalized_id)
    if match ~= nil then
        return match.record, match.engine_effect_id, "normalized_unique"
    end
    if count > 1 then
        return nil, nil, "ambiguous", matches
    end
    return nil, nil, "missing"
end

function effect_identity.resolveEngineEffectId(effect, records, effects_api)
    local record, engine_effect_id, source, matches = effect_identity.resolveMagicEffectRecord(effect, records, effects_api)
    if record ~= nil and type(engine_effect_id) == "string" and engine_effect_id ~= "" then
        return {
            ok = true,
            engine_effect_id = engine_effect_id,
            record = record,
            source = source,
        }
    end

    local id = type(effect) == "table" and readField(effect, "id") or effect
    local normalized_id = normalized(id)
    if source == "ambiguous" then
        local ids = {}
        for i, match in ipairs(matches or {}) do
            ids[i] = tostring(match.engine_effect_id or match.key or "?")
        end
        table.sort(ids)
        return {
            ok = false,
            code = "ambiguous_magic_effect_record",
            message = string.format("custom magic effect id is ambiguous: %s", tostring(id)),
            normalized_id = normalized_id,
            matches = ids,
        }
    end

    if effect_registry.getFallbackInfo(normalized_id) ~= nil then
        return {
            ok = true,
            engine_effect_id = normalized_id,
            record = nil,
            source = "registry_fallback",
        }
    end

    return {
        ok = false,
        code = "missing_magic_effect_record",
        message = string.format("missing magic effect record: %s", tostring(id)),
        normalized_id = normalized_id,
    }
end

return effect_identity
