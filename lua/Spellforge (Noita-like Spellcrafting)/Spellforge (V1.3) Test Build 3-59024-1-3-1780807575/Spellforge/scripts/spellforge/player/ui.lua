---@omw-context player
local async = require("openmw.async")
local core = require("openmw.core")
local self = require("openmw.self")
local types = require("openmw.types")

local events = require("scripts.spellforge.shared.events")
local effect_identity = require("scripts.spellforge.shared.effect_identity")
local effect_registry = require("scripts.spellforge.shared.effect_support_registry")
local generated_lifecycle = require("scripts.spellforge.shared.generated_spell_lifecycle")
local log = require("scripts.spellforge.shared.log").new("player.ui")
local rejection_messages = require("scripts.spellforge.shared.rejection_messages")
local storage = require("scripts.spellforge.player.storage")

local ui = {}

local REQUEST_TIMEOUT_SECONDS = 2.0

local state = {
    next_request_id = 1,
    pending = {},
    catalog = nil,
    available_effects = nil,
    validation_by_recipe_id = {},
    preview_by_recipe_id = {},
    lifecycle_by_saved_id = {},
    known_effect_scan_diagnostics_emitted = false,
}

local SCAN_SAMPLE_LIMIT = 5

local function nextRequestId(prefix)
    local id = state.next_request_id
    state.next_request_id = id + 1
    return string.format("%s-%d-%d", prefix or "ui", os.time(), id)
end

local function sendGlobal(event_name, payload)
    local p = payload or {}
    p.sender = self.object
    core.sendGlobalEvent(event_name, p)
end

local function structuredError(code, path, message)
    return {
        code = code,
        path = path or "",
        message = message,
        severity = "error",
    }
end

local function normalizeEffectId(value)
    return effect_registry.normalizeEffectId(value)
end

local function firstNonNil(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if value ~= nil then
            return value
        end
    end
    return nil
end

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

local function compactKeys(value)
    if value == nil then
        return "nil"
    end
    local keys = {}
    local ok = pcall(function()
        for key in pairs(value) do
            keys[#keys + 1] = tostring(key)
            if #keys >= 8 then
                break
            end
        end
    end)
    if not ok or #keys == 0 then
        for _, key in ipairs({ "id", "recordId", "spellId", "record", "spell", "effects", "effectId", "mgef" }) do
            if readField(value, key) ~= nil then
                keys[#keys + 1] = key
            end
        end
    end
    if #keys == 0 then
        return "-"
    end
    table.sort(keys)
    return table.concat(keys, ",")
end

local function collectValues(iterable)
    local values = {}
    local ok, err = pcall(function()
        for _, value in pairs(iterable or {}) do
            values[#values + 1] = value
        end
    end)
    if not ok then
        return nil, tostring(err)
    end
    return values, nil
end

local function nestedRecordId(value)
    if value == nil then
        return nil
    end
    return scalarString(readField(value, "id"))
        or scalarString(readField(value, "recordId"))
        or scalarString(readField(value, "spellId"))
        or scalarString(readField(value, "refId"))
end

local function engineEffectIdFromRecord(effect)
    return effect_identity.engineEffectIdFromEffect(effect)
end

local function effectIdFromRecord(effect)
    local engine_effect_id = engineEffectIdFromRecord(effect)
    if engine_effect_id then
        return normalizeEffectId(engine_effect_id)
    end
    local id = scalarString(readField(effect, "id"))
        or scalarString(readField(effect, "effectId"))
    if id then
        return normalizeEffectId(id)
    end
    local mgef = readField(effect, "mgef")
    local mgef_id = scalarString(mgef) or nestedRecordId(mgef)
    return normalizeEffectId(mgef_id)
end

local localizedEffectName
local magicEffectSchool
local resolveMagicEffectRecord

local function spellRecordName(record)
    return scalarString(readField(record, "name"))
        or scalarString(readField(record, "displayName"))
end

local function associatedMagicEffectRecord(effect, resolved_record)
    return firstNonNil(
        readField(effect, "effect"),
        readField(effect, "mgef"),
        readField(effect, "magicEffect"),
        resolved_record
    )
end

local function effectSampleFromRecord(effect)
    if effect == nil then
        return nil
    end
    local id = effectIdFromRecord(effect)
    if not id or string.sub(id, 1, 11) == "spellforge_" then
        return nil
    end
    local mgef = readField(effect, "mgef")
    local engine_effect_id = engineEffectIdFromRecord(effect)
    local record = resolveMagicEffectRecord(engine_effect_id or id)
    local associated = associatedMagicEffectRecord(effect, record)
    return {
        id = id,
        engine_effect_id = engine_effect_id,
        display_name = localizedEffectName(effect, engine_effect_id or id),
        school = magicEffectSchool(effect, engine_effect_id or id),
        range = readField(effect, "range"),
        magnitudeMin = firstNonNil(readField(effect, "magnitudeMin"), readField(effect, "minMagnitude"), readField(effect, "min")),
        magnitudeMax = firstNonNil(readField(effect, "magnitudeMax"), readField(effect, "maxMagnitude"), readField(effect, "max")),
        duration = readField(effect, "duration"),
        area = readField(effect, "area"),
        affectedAttribute = firstNonNil(readField(effect, "affectedAttribute"), readField(effect, "attribute")),
        affectedSkill = firstNonNil(readField(effect, "affectedSkill"), readField(effect, "skill")),
        baseCost = firstNonNil(readField(effect, "baseCost"), readField(associated, "baseCost"), readField(mgef, "baseCost"), readField(record, "baseCost")),
        hasMagnitude = firstNonNil(readField(effect, "hasMagnitude"), readField(associated, "hasMagnitude"), readField(mgef, "hasMagnitude"), readField(record, "hasMagnitude")),
        hasDuration = firstNonNil(readField(effect, "hasDuration"), readField(associated, "hasDuration"), readField(mgef, "hasDuration"), readField(record, "hasDuration")),
        hasArea = firstNonNil(readField(effect, "hasArea"), readField(associated, "hasArea"), readField(mgef, "hasArea"), readField(record, "hasArea")),
        hasAttribute = firstNonNil(readField(effect, "hasAttribute"), readField(associated, "hasAttribute"), readField(mgef, "hasAttribute"), readField(record, "hasAttribute")),
        hasSkill = firstNonNil(readField(effect, "hasSkill"), readField(associated, "hasSkill"), readField(mgef, "hasSkill"), readField(record, "hasSkill")),
        onSelf = firstNonNil(readField(effect, "onSelf"), readField(associated, "onSelf"), readField(mgef, "onSelf"), readField(record, "onSelf")),
        onTouch = firstNonNil(readField(effect, "onTouch"), readField(associated, "onTouch"), readField(mgef, "onTouch"), readField(record, "onTouch")),
        onTarget = firstNonNil(readField(effect, "onTarget"), readField(associated, "onTarget"), readField(mgef, "onTarget"), readField(record, "onTarget")),
        allowsSpellmaking = firstNonNil(readField(effect, "allowsSpellmaking"), readField(associated, "allowsSpellmaking"), readField(mgef, "allowsSpellmaking"), readField(record, "allowsSpellmaking")),
        allowsEnchanting = firstNonNil(readField(effect, "allowsEnchanting"), readField(associated, "allowsEnchanting"), readField(mgef, "allowsEnchanting"), readField(record, "allowsEnchanting")),
        casterLinked = firstNonNil(readField(effect, "casterLinked"), readField(associated, "casterLinked"), readField(mgef, "casterLinked"), readField(record, "casterLinked")),
    }
end

local function spellIdFromSpellbookEntry(entry)
    if entry == nil then
        return nil
    end
    if type(entry) == "string" then
        return entry
    end
    return scalarString(readField(entry, "id"))
        or scalarString(readField(entry, "recordId"))
        or scalarString(readField(entry, "spellId"))
        or nestedRecordId(readField(entry, "record"))
        or nestedRecordId(readField(entry, "spell"))
end

local function spellIdCandidates(entry)
    local values = {}
    local seen = {}
    addCandidate(values, seen, spellIdFromSpellbookEntry(entry))
    addCandidate(values, seen, nestedRecordId(entry))
    addCandidate(values, seen, nestedRecordId(readField(entry, "record")))
    addCandidate(values, seen, nestedRecordId(readField(entry, "spell")))
    return values
end

local function diagnosticSpellIdFallback(entry)
    if entry == nil then
        return nil
    end
    local text = tostring(entry)
    if text == "" or text == "nil" then
        return nil
    end
    return text
end

local function spellRecordsTable()
    local magic = readField(core, "magic")
    local spells = readField(magic, "spells")
    local records = readField(spells, "records")
    if records == nil then
        return nil, nil, "spell_record_lookup_unavailable"
    end
    return records, spells, nil
end

local function lookupRecord(container, key)
    if container == nil or type(key) ~= "string" or key == "" then
        return nil
    end
    local ok, record = pcall(function()
        return container[key]
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

local function caseInsensitiveRecord(records, spell_id)
    local lower_id = string.lower(tostring(spell_id or ""))
    if lower_id == "" then
        return nil
    end
    local found = nil
    pcall(function()
        for key, record in pairs(records or {}) do
            if string.lower(tostring(key)) == lower_id
                or string.lower(tostring(nestedRecordId(record) or "")) == lower_id then
                found = record
                break
            end
        end
    end)
    return found
end

local function magicEffectRecordsTable()
    local magic = readField(core, "magic")
    local effects = readField(magic, "effects")
    local records = readField(effects, "records")
    if records == nil then
        return nil, nil
    end
    return records, effects
end

function resolveMagicEffectRecord(effect_id)
    local records, effects = magicEffectRecordsTable()
    if records == nil then
        return nil
    end
    local id = scalarString(effect_id)
    if not id then
        return nil
    end
    local resolved = effect_identity.resolveMagicEffectRecord({ id = id }, records, effects)
    if resolved ~= nil then
        return resolved
    end
    return lookupRecord(records, id)
        or lookupRecord(records, string.lower(id))
        or callRecordGetter(records, id)
        or callRecordGetter(effects, id)
        or caseInsensitiveRecord(records, id)
end

function localizedEffectName(effect, effect_id)
    local explicit = scalarString(readField(effect, "name"))
        or scalarString(readField(effect, "displayName"))
        or scalarString(readField(effect, "display_name"))
    if explicit then
        return explicit
    end
    local associated = associatedMagicEffectRecord(effect)
    explicit = scalarString(readField(associated, "name"))
        or scalarString(readField(associated, "displayName"))
        or scalarString(readField(associated, "display_name"))
    if explicit then
        return explicit
    end
    local record = resolveMagicEffectRecord(effect_id)
    return scalarString(readField(record, "name"))
        or scalarString(readField(record, "displayName"))
        or scalarString(readField(record, "display_name"))
end

function magicEffectSchool(effect, effect_id)
    local school = scalarString(readField(effect, "school"))
        or scalarString(readField(associatedMagicEffectRecord(effect), "school"))
    if school then
        return school
    end
    local record = resolveMagicEffectRecord(effect_id)
    return scalarString(readField(record, "school"))
end

local function resolveSpellRecord(spell_id)
    local records, spells, records_err = spellRecordsTable()
    if records == nil then
        return nil, records_err
    end
    local id = scalarString(spell_id)
    if not id then
        return nil, "spell_id_missing"
    end

    return lookupRecord(records, id)
        or lookupRecord(records, string.lower(id))
        or callRecordGetter(records, id)
        or callRecordGetter(spells, id)
        or caseInsensitiveRecord(records, id),
        nil
end

local NON_SPELL_TYPE_BY_NUMBER = {
    [1] = "ability",
    [2] = "blight",
    [3] = "disease",
    [4] = "curse",
    [5] = "power",
}

local NON_SPELL_TYPE_TEXT_MARKERS = {
    "ability",
    "birthsign",
    "blight",
    "curse",
    "disease",
    "lesserpower",
    "power",
    "racial",
}

local function normalizeSpellTypeText(value)
    local text = scalarString(value)
    if not text then
        return nil
    end
    text = string.lower(text)
    text = string.gsub(text, "[%s_%-%.:]+", "")
    if text == "" then
        return nil
    end
    return text
end

local function spellTypeValue(record, entry)
    return firstNonNil(
        readField(record, "type"),
        readField(record, "spellType"),
        readField(record, "spell_type"),
        readField(record, "kind"),
        readField(entry, "type"),
        readField(entry, "spellType"),
        readField(entry, "spell_type"),
        readField(entry, "kind")
    )
end

local function spellTypeAllowsKnownEffects(record, entry)
    local value = spellTypeValue(record, entry)
    if value == nil then
        return true, "unavailable", "spell_type_unavailable"
    end

    local numeric = tonumber(value)
    if numeric ~= nil then
        if numeric == 0 then
            return true, tostring(numeric), nil
        end
        local blocked = NON_SPELL_TYPE_BY_NUMBER[numeric]
        if blocked then
            return false, blocked, "non_spell_type"
        end
        return true, tostring(numeric), "spell_type_unknown_numeric"
    end

    local text = normalizeSpellTypeText(value)
    if text == nil then
        return true, "unavailable", "spell_type_unavailable"
    end
    for _, marker in ipairs(NON_SPELL_TYPE_TEXT_MARKERS) do
        if string.find(text, marker, 1, true) then
            return false, text, "non_spell_type"
        end
    end
    if text == "spell" or string.find(text, "spell", 1, true) then
        return true, text, nil
    end
    if text == "normal" or text == "regular" then
        return true, text, nil
    end
    return true, text, "spell_type_unknown_text"
end

local function effectsFromRecord(record)
    local effects = readField(record, "effects")
    if effects == nil then
        return nil, "spell_record_effects_missing"
    end
    return collectValues(effects)
end

local function actorSpellsForPlayer()
    local ok_self, actor_spells = pcall(types.Actor.spells, self)
    if ok_self and actor_spells ~= nil then
        return actor_spells, nil
    end
    local player_object = readField(self, "object")
    if player_object ~= nil then
        local ok_object, object_spells = pcall(types.Actor.spells, player_object)
        if ok_object and object_spells ~= nil then
            return object_spells, nil
        end
        if not ok_object then
            return nil, tostring(object_spells)
        end
    end
    if not ok_self then
        return nil, tostring(actor_spells)
    end
    return nil, "actor_spells_nil"
end

local function isSpellforgeGeneratedFrontendRecord(record)
    local effects = effectsFromRecord(record)
    if type(effects) ~= "table" then
        return false
    end
    for _, effect in ipairs(effects) do
        local effect_id = effectIdFromRecord(effect)
        if effect_id
            and (
                string.sub(effect_id, 1, 19) == "spellforge_display_"
                or string.sub(effect_id, 1, 18) == "spellforge_marker_"
                or effect_id == "spellforge_composed"
            ) then
            return true
        end
    end
    return false
end

local function spellbookSpellforgeGeneratedRecords()
    local actor_spells = actorSpellsForPlayer()
    if actor_spells == nil then
        return {}
    end
    local entries = collectValues(actor_spells)
    if type(entries) ~= "table" then
        return {}
    end
    local out = {}
    for _, entry in ipairs(entries) do
        local spell_id = nil
        local record = nil
        for _, candidate in ipairs(spellIdCandidates(entry)) do
            record = resolveSpellRecord(candidate)
            if record ~= nil then
                spell_id = candidate
                break
            end
            spell_id = spell_id or candidate
        end
        if record ~= nil and type(spell_id) == "string" and isSpellforgeGeneratedFrontendRecord(record) then
            out[#out + 1] = {
                spell_id = spell_id,
                name = spellRecordName(record),
                record = record,
            }
        end
    end
    return out
end

local function savedRecipesByTitle()
    local by_title = {}
    for _, saved in ipairs(storage.list()) do
        local title = type(saved) == "table" and saved.title or nil
        if type(title) == "string" and title ~= "" then
            by_title[title] = by_title[title] or {}
            by_title[title][#by_title[title] + 1] = saved
        end
    end
    return by_title
end

local function uniqueSavedRecipeByTitle(title, by_title)
    if type(title) ~= "string" or title == "" then
        return nil, "missing_title"
    end
    local matches = by_title and by_title[title] or nil
    if type(matches) ~= "table" or #matches == 0 then
        return nil, "saved_recipe_title_missing"
    end
    if #matches > 1 then
        return nil, "saved_recipe_title_ambiguous"
    end
    return matches[1], nil
end

local function discoverKnownEffects()
    state.known_effect_scan_diagnostics_emitted = true
    log.info("SPELLFORGE_KNOWN_EFFECT_SCAN_START")
    local actor_spells, actor_spells_err = actorSpellsForPlayer()
    if actor_spells == nil then
        local reason = actor_spells_err or "actor_spells_nil"
        log.info(string.format(
            "SPELLFORGE_KNOWN_EFFECT_SCAN_ACTOR_SPELLS_UNAVAILABLE reason=%s",
            tostring(reason)
        ))
        log.info("SPELLFORGE_KNOWN_EFFECT_SCAN_DONE spell_count=0 effect_count=0 skipped_non_spell_count=0 error_count=1 status=unavailable")
        return {
            known_effect_scan_status = "unavailable",
            known_effect_scan_reason = "actor_spells_unavailable",
            known_effect_ids = {},
            known_effect_samples = {},
        }
    end

    local entries, entries_err = collectValues(actor_spells)
    if not entries then
        log.info(string.format(
            "SPELLFORGE_KNOWN_EFFECT_SCAN_ACTOR_SPELLS_UNAVAILABLE reason=%s",
            tostring(entries_err or "actor_spells_iter_unavailable")
        ))
        log.info("SPELLFORGE_KNOWN_EFFECT_SCAN_DONE spell_count=0 effect_count=0 skipped_non_spell_count=0 error_count=1 status=unavailable")
        return {
            known_effect_scan_status = "unavailable",
            known_effect_scan_reason = "actor_spells_iter_unavailable",
            known_effect_ids = {},
            known_effect_samples = {},
        }
    end

    log.info(string.format(
        "SPELLFORGE_KNOWN_EFFECT_SCAN_ACTOR_SPELLS_OK count=%s",
        tostring(#entries)
    ))

    local records = spellRecordsTable()
    if records == nil then
        log.info("SPELLFORGE_KNOWN_EFFECT_SCAN_RECORD_MISSING spell_id=*")
        log.info("SPELLFORGE_KNOWN_EFFECT_SCAN_DONE spell_count=0 effect_count=0 skipped_non_spell_count=0 error_count=1 status=unavailable")
        return {
            known_effect_scan_status = "unavailable",
            known_effect_scan_reason = "spell_record_lookup_unavailable",
            known_effect_ids = {},
            known_effect_samples = {},
        }
    end

    local ids = {}
    local samples = {}
    local spell_count = 0
    local effect_count = 0
    local record_missing_count = 0
    local skipped_non_spell_count = 0
    local skipped_non_spellmaking_effect_count = 0
    local function visitSpell(entry, index)
        if index <= SCAN_SAMPLE_LIMIT then
            log.info(string.format(
                "SPELLFORGE_KNOWN_EFFECT_SCAN_ENTRY_SAMPLE index=%s type=%s keys=%s",
                tostring(index),
                type(entry),
                compactKeys(entry)
            ))
        end

        local spell_id = nil
        local record = nil
        for _, candidate in ipairs(spellIdCandidates(entry)) do
            record = resolveSpellRecord(candidate)
            if record ~= nil then
                spell_id = candidate
                break
            end
            if spell_id == nil then
                spell_id = candidate
            end
        end
        if record == nil and spell_id == nil then
            local fallback = diagnosticSpellIdFallback(entry)
            if fallback then
                local fallback_record = resolveSpellRecord(fallback)
                if fallback_record ~= nil then
                    spell_id = fallback
                    record = fallback_record
                end
            end
        end

        if type(spell_id) ~= "string" or spell_id == "" then
            if index <= SCAN_SAMPLE_LIMIT then
                log.info(string.format(
                    "SPELLFORGE_KNOWN_EFFECT_SCAN_SPELL_ID_MISSING index=%s",
                    tostring(index)
                ))
            end
            return
        end
        if index <= SCAN_SAMPLE_LIMIT then
            log.info(string.format(
                "SPELLFORGE_KNOWN_EFFECT_SCAN_SPELL_ID_OK spell_id=%s",
                tostring(spell_id)
            ))
        end

        if record == nil then
            record = resolveSpellRecord(spell_id)
        end
        if record == nil then
            record_missing_count = record_missing_count + 1
            if record_missing_count <= SCAN_SAMPLE_LIMIT then
                log.info(string.format(
                    "SPELLFORGE_KNOWN_EFFECT_SCAN_RECORD_MISSING spell_id=%s",
                    tostring(spell_id)
                ))
            end
            return
        end
        local type_ok, spell_type, type_reason = spellTypeAllowsKnownEffects(record, entry)
        if not type_ok then
            skipped_non_spell_count = skipped_non_spell_count + 1
            if skipped_non_spell_count <= SCAN_SAMPLE_LIMIT then
                log.info(string.format(
                    "SPELLFORGE_KNOWN_EFFECT_SCAN_SPELL_TYPE_SKIPPED spell_id=%s spell_type=%s reason=%s",
                    tostring(spell_id),
                    tostring(spell_type),
                    tostring(type_reason)
                ))
            end
            return
        elseif index <= SCAN_SAMPLE_LIMIT then
            log.info(string.format(
                "SPELLFORGE_KNOWN_EFFECT_SCAN_SPELL_TYPE_OK spell_id=%s spell_type=%s",
                tostring(spell_id),
                tostring(spell_type)
            ))
        end
        local effects, effects_err = effectsFromRecord(record)
        if not effects then
            if index <= SCAN_SAMPLE_LIMIT then
                log.info(string.format(
                    "SPELLFORGE_KNOWN_EFFECT_SCAN_RECORD_MISSING spell_id=%s",
                    tostring(spell_id)
                ))
            end
            return effects_err
        end
        if index <= SCAN_SAMPLE_LIMIT then
            log.info(string.format(
                "SPELLFORGE_KNOWN_EFFECT_SCAN_RECORD_OK spell_id=%s effect_count=%s",
                tostring(spell_id),
                tostring(#effects)
            ))
        end
        spell_count = spell_count + 1
        for _, effect in ipairs(effects) do
            local sample = effectSampleFromRecord(effect)
            if sample and sample.allowsSpellmaking == false then
                skipped_non_spellmaking_effect_count = skipped_non_spellmaking_effect_count + 1
                if skipped_non_spellmaking_effect_count <= SCAN_SAMPLE_LIMIT then
                    log.info(string.format(
                        "SPELLFORGE_KNOWN_EFFECT_SCAN_EFFECT_SKIPPED_NON_SPELLMAKING effect_id=%s",
                        tostring(sample.id)
                    ))
                end
            elseif sample and not samples[sample.id] then
                ids[#ids + 1] = sample.id
                samples[sample.id] = sample
                effect_count = effect_count + 1
                if effect_count <= SCAN_SAMPLE_LIMIT then
                    log.info(string.format(
                        "SPELLFORGE_KNOWN_EFFECT_SCAN_EFFECT_OK effect_id=%s",
                        tostring(sample.id)
                    ))
                end
            end
        end
    end

    local unavailable_reason = nil
    for index, entry in ipairs(entries) do
        local err = visitSpell(entry, index)
        unavailable_reason = unavailable_reason or err
    end

    table.sort(ids)
    local status = unavailable_reason == "spell_record_lookup_unavailable" and "unavailable" or "ok"
    local reason = nil
    if status == "unavailable" then
        reason = unavailable_reason
    elseif effect_count == 0 then
        reason = "known_effect_scan_empty"
    end
    log.info(string.format(
        "SPELLFORGE_KNOWN_EFFECT_SCAN_DONE spell_count=%s effect_count=%s skipped_non_spell_count=%s skipped_non_spellmaking_effect_count=%s error_count=%s status=%s",
        tostring(spell_count),
        tostring(effect_count),
        tostring(skipped_non_spell_count),
        tostring(skipped_non_spellmaking_effect_count),
        tostring(record_missing_count),
        tostring(status)
    ))
    return {
        known_effect_scan_status = status,
        known_effect_scan_reason = reason,
        known_effect_ids = ids,
        known_effect_samples = samples,
        known_spell_count = spell_count,
        known_effect_count = effect_count,
        known_effect_skipped_non_spell_count = skipped_non_spell_count,
        known_effect_skipped_non_spellmaking_effect_count = skipped_non_spellmaking_effect_count,
    }
end

local function availabilityPayload(opts)
    local options = opts or {}
    if type(options.available_effects) == "table" then
        return options.available_effects
    end
    if state.available_effects and options.force ~= true and options.dev_full_catalog ~= true and options.force_rescan ~= true then
        return state.available_effects
    end
    local scan = discoverKnownEffects()
    if options.dev_full_catalog == true then
        scan.dev_full_catalog = true
    end
    return scan
end

local function previewDeferredReasons(preview_result)
    local preview = preview_result and preview_result.preview or nil
    local matrix = preview and (preview.feature_matrix or preview.support) or {}
    if type(matrix.deferred_reasons) == "table" then
        return matrix.deferred_reasons
    end
    return {}
end

local function previewIsDeferred(preview_result)
    local preview = preview_result and preview_result.preview or nil
    local matrix = preview and (preview.feature_matrix or preview.support) or {}
    return matrix.live_runtime_status == "deferred" or #previewDeferredReasons(preview_result) > 0
end

local function deferredReasonSummary(preview_result)
    local reasons = previewDeferredReasons(preview_result)
    if #reasons > 0 then
        return rejection_messages.formatDeferredReasons(reasons, "runtime combo deferred")
    end
    return "runtime combo deferred"
end

local function cachedPreviewForSaved(saved)
    if type(saved) ~= "table" then
        return nil
    end
    local preview_recipe_id = saved.last_previewed_recipe_id or saved.recipe_id
    if type(preview_recipe_id) ~= "string" or preview_recipe_id == "" then
        return nil
    end
    return state.preview_by_recipe_id[preview_recipe_id]
end

local function withSavedRecipeIdentity(saved, opts)
    local options = {}
    for k, v in pairs(opts or {}) do
        options[k] = v
    end
    local inner = {}
    if type(options.options) == "table" then
        for k, v in pairs(options.options) do
            inner[k] = v
        end
    end
    if type(saved) == "table" and type(saved.id) == "string" and saved.id ~= "" then
        inner.recipe_identity_salt = saved.id
    end
    options.options = inner
    return options
end

local persistLifecycle

local function persistCompileResult(saved_recipe_id, payload)
    if type(saved_recipe_id) ~= "string" or saved_recipe_id == "" then
        return nil
    end
    local entry = state.lifecycle_by_saved_id[saved_recipe_id] or storage.getLifecycle(saved_recipe_id)
    if not entry then
        local saved = storage.get(saved_recipe_id)
        entry = saved and generated_lifecycle.newEntry(saved) or nil
    end
    if not entry then
        return nil
    end

    local next_entry = generated_lifecycle.applyCompileResult(entry, payload)
    state.lifecycle_by_saved_id[saved_recipe_id] = persistLifecycle(saved_recipe_id, next_entry)
    if payload and payload.ok == true and payload.recipe_id then
        storage.update(saved_recipe_id, {
            recipe_id = payload.recipe_id,
            last_validated_recipe_id = payload.recipe_id,
            last_previewed_recipe_id = payload.recipe_id,
        })
    end
    return state.lifecycle_by_saved_id[saved_recipe_id]
end

local function finishPending(request_id, payload)
    local pending = request_id and state.pending[request_id]
    if not pending then
        return false
    end
    state.pending[request_id] = nil
    if pending.timer then
        pending.timer:cancel()
    end
    if type(pending.callback) == "function" then
        pending.callback(payload)
    end
    return true
end

local function trackPending(request_id, kind, callback, meta)
    local metadata = meta or {}
    state.pending[request_id] = {
        kind = kind,
        callback = callback,
        saved_recipe_id = metadata.saved_recipe_id,
        timer = async:newUnsavableSimulationTimer(REQUEST_TIMEOUT_SECONDS, function()
            if not state.pending[request_id] then
                return
            end
            local pending = state.pending[request_id]
            state.pending[request_id] = nil
            local timeout_payload = {
                request_id = request_id,
                ok = false,
                success = false,
                errors = {
                    structuredError("ui_request_timeout", "request_id", string.format("%s request timed out", tostring(kind))),
                },
            }
            if pending.saved_recipe_id and kind == "compile" then
                timeout_payload.error = "ui_request_timeout"
                persistCompileResult(pending.saved_recipe_id, timeout_payload)
            end
            if type(pending.callback) == "function" then
                pending.callback(timeout_payload)
            end
        end),
    }
end

local function mapCount(index)
    local count = 0
    for _ in pairs(index or {}) do
        count = count + 1
    end
    return count
end

function ui.resetTransientRuntime(reason)
    local pending_count = mapCount(state.pending)
    local lifecycle_cache_count = mapCount(state.lifecycle_by_saved_id)
    local validation_cache_count = mapCount(state.validation_by_recipe_id)
    local preview_cache_count = mapCount(state.preview_by_recipe_id)
    local catalog_cached = state.catalog ~= nil
    local available_effects_cached = state.available_effects ~= nil

    for _, pending in pairs(state.pending or {}) do
        if pending and pending.timer then
            pcall(function()
                pending.timer:cancel()
            end)
        end
    end

    state.pending = {}
    state.catalog = nil
    state.available_effects = nil
    state.validation_by_recipe_id = {}
    state.preview_by_recipe_id = {}
    state.lifecycle_by_saved_id = {}

    log.info(string.format(
        "SPELLFORGE_PLAYER_UI_RUNTIME_RESET reason=%s pending=%s lifecycle_cache=%s validation_cache=%s preview_cache=%s catalog_cached=%s available_effects_cached=%s",
        tostring(reason),
        tostring(pending_count),
        tostring(lifecycle_cache_count),
        tostring(validation_cache_count),
        tostring(preview_cache_count),
        tostring(catalog_cached),
        tostring(available_effects_cached)
    ))
end

local function removeSpellFromSpellbook(spell_id)
    if type(spell_id) ~= "string" or spell_id == "" then
        return false, "missing spell id"
    end
    local actor_spells = types.Actor.spells(self)
    if not actor_spells or type(actor_spells.remove) ~= "function" then
        return false, "ActorSpells.remove unavailable"
    end
    local ok, err = pcall(actor_spells.remove, actor_spells, spell_id)
    if not ok then
        return false, tostring(err)
    end
    return true, nil
end

local function requestCleanup(entry, reason)
    local cleanup = entry and generated_lifecycle.cleanupPlan(entry) or nil
    if not cleanup or not cleanup.needed then
        return cleanup
    end

    local removed, remove_err = removeSpellFromSpellbook(cleanup.spell_id)
    cleanup.remove_from_spellbook = true
    cleanup.remove_from_spellbook_ok = removed == true
    cleanup.remove_from_spellbook_error = remove_err
    if not removed then
        log.warn(string.format(
            "SPELLFORGE_UI_SPELLBOOK_REMOVE_FAILED spell_id=%s reason=%s",
            tostring(cleanup.spell_id),
            tostring(remove_err)
        ))
    end

    sendGlobal(events.DELETE_COMPILED, {
        recipe_id = cleanup.recipe_id,
        spell_id = cleanup.spell_id,
        reason = reason or cleanup.reason,
    })
    return cleanup
end

function persistLifecycle(saved_recipe_id, entry)
    if type(saved_recipe_id) ~= "string" or saved_recipe_id == "" then
        return entry
    end
    local persisted = storage.putLifecycle(saved_recipe_id, entry)
    return persisted.ok and persisted.lifecycle or entry
end

local function lifecycleForSaved(saved_recipe)
    if not saved_recipe or type(saved_recipe.id) ~= "string" then
        return nil
    end
    local entry = state.lifecycle_by_saved_id[saved_recipe.id]
    if not entry then
        entry = storage.getLifecycle(saved_recipe.id) or generated_lifecycle.newEntry(saved_recipe)
        state.lifecycle_by_saved_id[saved_recipe.id] = persistLifecycle(saved_recipe.id, entry)
    end
    return entry
end

function ui.requestCatalog(callback, opts)
    local options = opts or {}
    if state.catalog and options.force ~= true and options.dev_full_catalog ~= true and options.force_rescan ~= true then
        if type(callback) == "function" then
            callback(state.catalog)
        end
        return {
            ok = true,
            request_id = nil,
            cached = true,
            catalog = state.catalog,
        }
    end

    local request_id = options.request_id or nextRequestId("ui-catalog")
    trackPending(request_id, "catalog", callback)
    sendGlobal(events.QUERY_UI_CATALOG, {
        request_id = request_id,
        available_effects = availabilityPayload(options),
    })
    return {
        ok = true,
        request_id = request_id,
        cached = false,
    }
end

function ui.requestAvailableEffects(callback, opts)
    local options = opts or {}
    if state.available_effects and options.force ~= true and options.dev_full_catalog ~= true and options.force_rescan ~= true then
        if type(callback) == "function" then
            callback(state.available_effects)
        end
        return {
            ok = true,
            request_id = nil,
            cached = true,
            available_effects = state.available_effects,
        }
    end

    local request_id = options.request_id or nextRequestId("ui-effects")
    trackPending(request_id, "available_effects", callback)
    sendGlobal(events.QUERY_AVAILABLE_EFFECTS, {
        request_id = request_id,
        available_effects = availabilityPayload(options),
    })
    return {
        ok = true,
        request_id = request_id,
        cached = false,
    }
end

function ui.validateRecipe(recipe, callback, opts)
    local options = opts or {}
    local request_id = options.request_id or nextRequestId("ui-validate")
    trackPending(request_id, "validate", callback)
    sendGlobal(events.VALIDATE_RECIPE, {
        request_id = request_id,
        recipe = recipe,
        options = options.options,
        available_effects = availabilityPayload(options),
    })
    return {
        ok = true,
        request_id = request_id,
    }
end

function ui.previewRecipe(recipe, callback, opts)
    local options = opts or {}
    local request_id = options.request_id or nextRequestId("ui-preview")
    trackPending(request_id, "preview", callback)
    sendGlobal(events.PREVIEW_RECIPE, {
        request_id = request_id,
        recipe = recipe,
        options = options.options,
        available_effects = availabilityPayload(options),
    })
    return {
        ok = true,
        request_id = request_id,
    }
end

function ui.saveRecipe(input, opts)
    local saved = storage.save(input, opts)
    if saved.ok then
        local entry = storage.getLifecycle(saved.saved_recipe.id) or generated_lifecycle.newEntry(saved.saved_recipe)
        state.lifecycle_by_saved_id[saved.saved_recipe.id] = persistLifecycle(saved.saved_recipe.id, entry)
    end
    return saved
end

function ui.updateRecipe(saved_recipe_id, patch, opts)
    local updated = storage.update(saved_recipe_id, patch, opts)
    if updated.ok then
        local current = lifecycleForSaved(updated.saved_recipe) or generated_lifecycle.newEntry(updated.saved_recipe)
        local entry = generated_lifecycle.markRecipeChanged(current, updated.saved_recipe)
        state.lifecycle_by_saved_id[saved_recipe_id] = persistLifecycle(saved_recipe_id, entry)
    end
    return updated
end

function ui.deleteRecipe(saved_recipe_id)
    local saved = storage.get(saved_recipe_id)
    local entry = state.lifecycle_by_saved_id[saved_recipe_id]
    if saved and not entry then
        entry = lifecycleForSaved(saved)
    end

    local delete_entry = entry and generated_lifecycle.markDeleteRequested(entry) or nil
    if delete_entry then
        state.lifecycle_by_saved_id[saved_recipe_id] = persistLifecycle(saved_recipe_id, delete_entry)
    end

    local cleanup = requestCleanup(delete_entry, "delete_saved_recipe")

    local deleted = storage.delete(saved_recipe_id)
    if entry then
        state.lifecycle_by_saved_id[saved_recipe_id] = generated_lifecycle.markDeleted(delete_entry or entry)
    end
    deleted.cleanup = cleanup
    return deleted
end

function ui.validateSavedRecipe(saved_recipe_id, callback, opts)
    local saved = storage.get(saved_recipe_id)
    if not saved then
        local result = {
            ok = false,
            errors = {
                structuredError("saved_recipe_not_found", "saved_recipe.id", string.format("No saved recipe found for id=%s", tostring(saved_recipe_id))),
            },
        }
        if type(callback) == "function" then
            callback(result)
        end
        return result
    end

    return ui.validateRecipe(saved.recipe, function(result)
        local entry = lifecycleForSaved(saved)
        if entry then
            local next_entry = generated_lifecycle.applyValidation(entry, result)
            state.lifecycle_by_saved_id[saved.id] = persistLifecycle(saved.id, next_entry)
        end
        if result and result.ok == true and result.recipe_id then
            state.validation_by_recipe_id[result.recipe_id] = result
            storage.update(saved.id, {
                recipe_id = result.recipe_id,
                last_validated_recipe_id = result.recipe_id,
            })
        end
        if type(callback) == "function" then
            callback(result)
        end
    end, withSavedRecipeIdentity(saved, opts))
end

function ui.previewSavedRecipe(saved_recipe_id, callback, opts)
    local saved = storage.get(saved_recipe_id)
    if not saved then
        local result = {
            ok = false,
            errors = {
                structuredError("saved_recipe_not_found", "saved_recipe.id", string.format("No saved recipe found for id=%s", tostring(saved_recipe_id))),
            },
        }
        if type(callback) == "function" then
            callback(result)
        end
        return result
    end

    return ui.previewRecipe(saved.recipe, function(result)
        local entry = lifecycleForSaved(saved)
        if entry then
            local next_entry = generated_lifecycle.applyPreview(entry, result)
            state.lifecycle_by_saved_id[saved.id] = persistLifecycle(saved.id, next_entry)
        end
        if result and result.ok == true and result.recipe_id then
            state.preview_by_recipe_id[result.recipe_id] = result
            storage.update(saved.id, {
                recipe_id = result.recipe_id,
                last_previewed_recipe_id = result.recipe_id,
            })
        end
        if type(callback) == "function" then
            callback(result)
        end
    end, withSavedRecipeIdentity(saved, opts))
end

function ui.requestCompileSavedRecipe(saved_recipe_id, callback, opts)
    local options = opts or {}
    local saved = storage.get(saved_recipe_id)
    if not saved then
        local result = {
            ok = false,
            errors = {
                structuredError("saved_recipe_not_found", "saved_recipe.id", string.format("No saved recipe found for id=%s", tostring(saved_recipe_id))),
            },
        }
        if type(callback) == "function" then
            callback(result)
        end
        return result
    end

    local entry = lifecycleForSaved(saved)
    local request_id = options.request_id or nextRequestId("ui-compile")
    local cached_preview = cachedPreviewForSaved(saved)
    if previewIsDeferred(cached_preview) then
        if type(cached_preview) ~= "table" then
            cached_preview = {}
        end
        local reason_summary = deferredReasonSummary(cached_preview)
        local result = {
            request_id = request_id,
            ok = false,
            success = false,
            recipe_id = cached_preview.recipe_id,
            saved_recipe_id = saved.id,
            error = "ui_compile_deferred",
            deferred_reasons = previewDeferredReasons(cached_preview),
            errors = {
                structuredError("deferred_runtime_combo", "preview.feature_matrix.deferred_reasons", "Create blocked: " .. reason_summary),
            },
        }
        persistCompileResult(saved.id, result)
        log.warn(string.format(
            "SPELLFORGE_UI_COMPILE_DEFERRED saved_id=%s recipe_id=%s reason=%s",
            tostring(saved.id),
            tostring(cached_preview.recipe_id),
            reason_summary
        ))
        if type(callback) == "function" then
            callback(result)
        end
        return result
    end

    if type(options.force_cleanup_reason) == "string" and options.force_cleanup_reason ~= "" then
        entry = generated_lifecycle.markStale(entry, options.force_cleanup_reason)
        state.lifecycle_by_saved_id[saved.id] = persistLifecycle(saved.id, entry)
    end

    local cleanup = requestCleanup(entry, "recompile_saved_recipe")
    local pending_entry = generated_lifecycle.markCompileRequested(entry, request_id)
    state.lifecycle_by_saved_id[saved.id] = persistLifecycle(saved.id, pending_entry)
    trackPending(request_id, "compile", callback, { saved_recipe_id = saved.id })
    sendGlobal(events.COMPILE_RECIPE, {
        request_id = request_id,
        actor = self,
        actor_id = self.recordId,
        saved_recipe_id = saved.id,
        title = saved.title,
        recipe = saved.recipe,
        available_effects = availabilityPayload(options),
    })
    return {
        ok = true,
        request_id = request_id,
        saved_recipe_id = saved.id,
        lifecycle = state.lifecycle_by_saved_id[saved.id],
        cleanup = cleanup,
        queued = true,
    }
end

function ui.requestRecompileSavedRecipe(saved_recipe_id, callback, opts)
    return ui.requestCompileSavedRecipe(saved_recipe_id, callback, opts)
end

function ui.getCachedCatalog()
    return state.catalog
end

function ui.getCachedAvailableEffects()
    return state.available_effects or (state.catalog and state.catalog.available_effects)
end

function ui.debugKnownEffectDiagnosticsEmitted()
    return state.known_effect_scan_diagnostics_emitted == true
end

function ui.debugKnownEffectSpellTypeFilterForSmoke(records)
    local ids = {}
    local seen = {}
    local skipped = 0
    local accepted = 0
    for _, record in ipairs(records or {}) do
        local allowed = spellTypeAllowsKnownEffects(record, record)
        if allowed then
            accepted = accepted + 1
            local effects = readField(record, "effects") or {}
            for _, effect in ipairs(effects) do
                local id = effectIdFromRecord(effect)
                if id and not seen[id] then
                    ids[#ids + 1] = id
                    seen[id] = true
                end
            end
        else
            skipped = skipped + 1
        end
    end
    table.sort(ids)
    return {
        effect_ids = ids,
        accepted_spell_count = accepted,
        skipped_non_spell_count = skipped,
    }
end

function ui.getSavedRecipes()
    return storage.list()
end

function ui.getLifecycle(saved_recipe_id)
    local entry = state.lifecycle_by_saved_id[saved_recipe_id] or storage.getLifecycle(saved_recipe_id)
    if entry then
        state.lifecycle_by_saved_id[saved_recipe_id] = entry
    end
    return entry
end

local function lifecycleContainsGeneratedId(entry, spell_id)
    if type(entry) ~= "table" or type(spell_id) ~= "string" or spell_id == "" then
        return false
    end
    if entry.frontend_spell_id == spell_id then
        return true
    end
    for _, engine_id in ipairs(entry.generated_engine_spell_ids or {}) do
        if engine_id == spell_id then
            return true
        end
    end
    return false
end

function ui.findLifecycleByGeneratedSpellId(spell_id)
    local lifecycles = storage.listLifecycles()
    if type(lifecycles) ~= "table" then
        lifecycles = {}
    end
    for saved_recipe_id, entry in pairs(lifecycles) do
        if lifecycleContainsGeneratedId(entry, spell_id) then
            state.lifecycle_by_saved_id[saved_recipe_id] = entry
            return {
                saved_recipe_id = saved_recipe_id,
                lifecycle = entry,
            }
        end
    end
    return nil
end

local function findSpellbookGeneratedById(spell_id)
    for _, generated in ipairs(spellbookSpellforgeGeneratedRecords()) do
        if generated.spell_id == spell_id then
            return generated
        end
    end
    return nil
end

local function requestRecompileAfterRehydrate(saved_recipe_id, rehydrate_result, callback, opts)
    local options = opts or {}
    local old_frontend_spell_id = rehydrate_result and rehydrate_result.old_frontend_spell_id
    log.info(string.format(
        "SPELLFORGE_REHYDRATE_RECOMPILE_REQUESTED saved_recipe_id=%s recipe_id=%s old_frontend_spell_id=%s reason=%s",
        tostring(saved_recipe_id),
        tostring(rehydrate_result and rehydrate_result.recipe_id),
        tostring(old_frontend_spell_id),
        tostring(rehydrate_result and rehydrate_result.error)
    ))
    if type(old_frontend_spell_id) == "string" and old_frontend_spell_id ~= "" then
        if options.preserve_old_frontend_spell_id == true then
            log.info(string.format(
                "SPELLFORGE_REHYDRATE_STALE_GENERATED_ID saved_recipe_id=%s old_frontend_spell_id=%s action=preserve_old_spellbook_id reason=%s",
                tostring(saved_recipe_id),
                tostring(old_frontend_spell_id),
                tostring(options.preserve_reason)
            ))
        else
            local removed, remove_err = removeSpellFromSpellbook(old_frontend_spell_id)
            log.info(string.format(
                "SPELLFORGE_REHYDRATE_STALE_GENERATED_ID saved_recipe_id=%s old_frontend_spell_id=%s action=remove_old_spellbook_id removed=%s error=%s",
                tostring(saved_recipe_id),
                tostring(old_frontend_spell_id),
                tostring(removed == true),
                tostring(remove_err)
            ))
        end
    end
    return ui.requestCompileSavedRecipe(saved_recipe_id, function(compile_result)
        if compile_result and compile_result.ok == true then
            compile_result.saved_recipe_id = compile_result.saved_recipe_id or saved_recipe_id
            compile_result.old_frontend_spell_id = compile_result.old_frontend_spell_id or old_frontend_spell_id
            compile_result.repaired_frontend_spell_id = compile_result.repaired_frontend_spell_id or compile_result.spell_id
            log.info(string.format(
                "SPELLFORGE_REHYDRATE_RECOMPILE_OK saved_recipe_id=%s recipe_id=%s old_frontend_spell_id=%s new_frontend_spell_id=%s",
                tostring(saved_recipe_id),
                tostring(compile_result.recipe_id),
                tostring(old_frontend_spell_id),
                tostring(compile_result.spell_id)
            ))
        end
        if type(callback) == "function" then
            callback(compile_result)
        end
    end, {
        force_cleanup_reason = "rehydrate_stale_generated_id",
    })
end

function ui.requestRehydrateLifecycle(saved_recipe_id, callback, opts)
    local options = opts or {}
    local saved = storage.get(saved_recipe_id)
    local entry = saved and lifecycleForSaved(saved) or storage.getLifecycle(saved_recipe_id)
    if not saved or not entry then
        local result = {
            ok = false,
            saved_recipe_id = saved_recipe_id,
            error = "saved_recipe_not_found",
            action = "failed",
        }
        if type(callback) == "function" then
            callback(result)
        end
        return result
    end
    if entry.status ~= generated_lifecycle.STATUS_COMPILED and options.allow_stale ~= true then
        local result = {
            ok = true,
            saved_recipe_id = saved_recipe_id,
            recipe_id = entry.recipe_id,
            frontend_spell_id = entry.frontend_spell_id,
            action = "skipped",
            status = entry.status,
        }
        if type(callback) == "function" then
            callback(result)
        end
        return result
    end

    local request_id = options.request_id or nextRequestId("ui-rehydrate")
    trackPending(request_id, "rehydrate", callback, { saved_recipe_id = saved_recipe_id })
    sendGlobal(events.REHYDRATE_COMPILED_REQUEST, {
        request_id = request_id,
        saved_recipe_id = saved_recipe_id,
        recipe_id = entry.recipe_id or saved.recipe_id,
        frontend_spell_id = entry.frontend_spell_id,
        generated_engine_spell_ids = entry.generated_engine_spell_ids,
        status = entry.status,
    })
    return {
        ok = true,
        queued = true,
        request_id = request_id,
        saved_recipe_id = saved_recipe_id,
    }
end

function ui.rehydrateCompiledLifecycles(callback, opts)
    local options = opts or {}
    local lifecycles = storage.listLifecycles()
    if type(lifecycles) ~= "table" then
        lifecycles = {}
    end
    local saved_list = storage.list()
    local spellbook_generated = spellbookSpellforgeGeneratedRecords()
    local queued = 0
    local lifecycle_count = 0
    local queued_by_saved_id = {}
    for _ in pairs(lifecycles) do
        lifecycle_count = lifecycle_count + 1
    end
    log.info(string.format(
        "SPELLFORGE_REHYDRATE_START saved_recipe_count=%s lifecycle_count=%s spellbook_generated_count=%s mode=player_lifecycle",
        tostring(#saved_list),
        tostring(lifecycle_count),
        tostring(#spellbook_generated)
    ))
    for saved_recipe_id, entry in pairs(lifecycles) do
        if entry and entry.status == generated_lifecycle.STATUS_COMPILED then
            queued = queued + 1
            queued_by_saved_id[saved_recipe_id] = true
            ui.requestRehydrateLifecycle(saved_recipe_id, function(result)
                if result and result.ok == true then
                    if type(callback) == "function" then
                        callback(result)
                    end
                    return
                end
                if result and result.recompile_requested == true and options.recompile ~= false then
                    requestRecompileAfterRehydrate(saved_recipe_id, result, callback)
                    return
                end
                if type(callback) == "function" then
                    callback(result)
                end
            end)
        end
    end

    local by_title = savedRecipesByTitle()
    for _, generated in ipairs(spellbook_generated) do
        local lifecycle_match = ui.findLifecycleByGeneratedSpellId(generated.spell_id)
        if not lifecycle_match then
            local saved, reason = uniqueSavedRecipeByTitle(generated.name, by_title)
            if saved and not queued_by_saved_id[saved.id] then
                queued = queued + 1
                queued_by_saved_id[saved.id] = true
                log.info(string.format(
                    "SPELLFORGE_REHYDRATE_STALE_GENERATED_ID saved_recipe_id=%s old_frontend_spell_id=%s action=spellbook_scan_match title=%s",
                    tostring(saved.id),
                    tostring(generated.spell_id),
                    tostring(generated.name)
                ))
                requestRecompileAfterRehydrate(saved.id, {
                    recipe_id = saved.recipe_id or saved.last_previewed_recipe_id or saved.last_validated_recipe_id,
                    old_frontend_spell_id = generated.spell_id,
                    error = "spellbook_generated_frontend_unindexed",
                }, callback)
            elseif not saved then
                log.warn(string.format(
                    "SPELLFORGE_REHYDRATE_STALE_GENERATED_ID saved_recipe_id=nil old_frontend_spell_id=%s action=spellbook_scan_unmatched title=%s reason=%s",
                    tostring(generated.spell_id),
                    tostring(generated.name),
                    tostring(reason)
                ))
            end
        end
    end

    log.info(string.format(
        "SPELLFORGE_REHYDRATE_COMPLETE queued=%s mode=player_lifecycle",
        tostring(queued)
    ))
    return {
        ok = true,
        queued = queued,
    }
end

function ui.repairGeneratedSpellId(spell_id, callback, opts)
    local options = opts or {}
    local match = ui.findLifecycleByGeneratedSpellId(spell_id)
    if not match then
        local generated = findSpellbookGeneratedById(spell_id)
        local saved, reason = uniqueSavedRecipeByTitle(generated and generated.name, savedRecipesByTitle())
        if saved then
            log.info(string.format(
                "SPELLFORGE_REHYDRATE_STALE_GENERATED_ID saved_recipe_id=%s old_frontend_spell_id=%s action=lazy_spellbook_scan_match title=%s",
                tostring(saved.id),
                tostring(spell_id),
                tostring(generated and generated.name)
            ))
            return requestRecompileAfterRehydrate(saved.id, {
                recipe_id = saved.recipe_id or saved.last_previewed_recipe_id or saved.last_validated_recipe_id,
                old_frontend_spell_id = spell_id,
                error = "generated_spell_lifecycle_not_found",
            }, callback, options)
        end
        return {
            ok = false,
            repaired = false,
            error = reason or "generated_spell_lifecycle_not_found",
        }
    end
    log.info(string.format(
        "SPELLFORGE_REHYDRATE_STALE_GENERATED_ID saved_recipe_id=%s old_frontend_spell_id=%s status=%s",
        tostring(match.saved_recipe_id),
        tostring(spell_id),
        tostring(match.lifecycle and match.lifecycle.status)
    ))
    if match.lifecycle and match.lifecycle.status == generated_lifecycle.STATUS_COMPILED then
        return ui.requestRehydrateLifecycle(match.saved_recipe_id, function(result)
            if result and result.recompile_requested == true then
                requestRecompileAfterRehydrate(match.saved_recipe_id, result, callback, options)
                return
            end
            if type(callback) == "function" then
                callback(result)
            end
        end, { allow_stale = true })
    end
    return requestRecompileAfterRehydrate(match.saved_recipe_id, {
        recipe_id = match.lifecycle and match.lifecycle.recipe_id,
        old_frontend_spell_id = spell_id,
        error = "lifecycle_stale",
    }, callback, options)
end

function ui.handleCatalogResult(payload)
    if payload and payload.ok == true then
        state.catalog = payload
        state.available_effects = payload.available_effects or {
            ok = true,
            source_mode = payload.available_effect_source_mode,
            base_effects = payload.base_effects,
            base_effect_count = payload.base_effect_count,
            warnings = payload.available_effect_warnings,
            capability_notes = payload.available_effect_capability_notes,
        }
    end
    finishPending(payload and payload.request_id, payload)
end

function ui.handleAvailableEffectsResult(payload)
    if payload and payload.ok == true then
        state.available_effects = payload
        if state.catalog then
            state.catalog.available_effects = payload
            state.catalog.base_effects = payload.base_effects
            state.catalog.base_effect_count = payload.base_effect_count
            state.catalog.available_effect_source_mode = payload.source_mode
            state.catalog.available_effect_warnings = payload.warnings
            state.catalog.available_effect_capability_notes = payload.capability_notes
        end
    end
    finishPending(payload and payload.request_id, payload)
end

function ui.handleValidateResult(payload)
    if payload and payload.recipe_id then
        state.validation_by_recipe_id[payload.recipe_id] = payload
    end
    finishPending(payload and payload.request_id, payload)
end

function ui.handlePreviewResult(payload)
    if payload and payload.recipe_id then
        state.preview_by_recipe_id[payload.recipe_id] = payload
    end
    finishPending(payload and payload.request_id, payload)
end

function ui.handleCompileResult(payload)
    local request_id = payload and payload.request_id
    local pending = request_id and state.pending[request_id]
    if pending and pending.saved_recipe_id then
        persistCompileResult(pending.saved_recipe_id, payload)
    end
    finishPending(request_id, payload)
end

function ui.handleRehydrateResult(payload)
    finishPending(payload and payload.request_id, payload)
end

function ui.clearForTests()
    state.pending = {}
    state.catalog = nil
    state.available_effects = nil
    state.validation_by_recipe_id = {}
    state.preview_by_recipe_id = {}
    state.lifecycle_by_saved_id = {}
    state.known_effect_scan_diagnostics_emitted = false
    storage.clearForTests()
end

return ui
