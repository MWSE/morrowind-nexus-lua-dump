---@omw-context global
local core = require("openmw.core")
local ok_types, types = pcall(require, "openmw.types")
local ok_settings, settings = pcall(require, "openmw.settings")
local log = require("scripts.spellforge.shared.log").new("global.projectile_speed_policy")

local projectile_speed_policy = {}

-- Diagnostic only. When true, Spellforge omits explicit speed/maxSpeed
-- for unmodified helper projectiles so SFP/MagExp auto speed fallback can
-- be tested. Do not enable for release unless explicitly desired.
projectile_speed_policy.SPELLFORGE_DIAG_OMIT_EXPLICIT_PROJECTILE_SPEED = false

local FALLBACK_TARGET_SPELL_MAX_SPEED = 1000
local USE_CASTER_RACE_WEIGHT_FOR_PROJECTILE_SPEED = true
-- MagExp launches helper projectiles as moving actor objects. OpenMW's magic
-- effect speed formula is still the source of truth, but the helper launch API
-- needs that engine value converted into its actor-velocity scale. Release logs
-- showed launch speed 1250 landing about half vanilla-fast, while 4500 was too
-- fast; the observed helper movement lands near half the submitted velocity, so
-- convert engine target-spell speed with one backend scale instead of using
-- MagExp's per-effect Oblivion-style auto speed table.
local BACKEND_PROJECTILE_SPEED_SCALE = 1.8
local normalise_race_speed_unreadable_logged = false

local function isFiniteNumber(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function positiveNumber(value)
    local n = tonumber(value)
    if isFiniteNumber(n) and n > 0 then
        return n
    end
    return nil
end

local function safeCall(fn)
    local ok, value = pcall(fn)
    if ok then
        return value
    end
    return nil
end

local function safeIndex(value, key)
    if value == nil or key == nil then
        return nil
    end
    return safeCall(function()
        return value[key]
    end)
end

local function normalizeEffectId(effect_id)
    if effect_id == nil then
        return nil
    end
    local s = tostring(effect_id)
    if s == "" then
        return nil
    end
    return string.lower(s)
end

local function compactEffectId(effect_id)
    local normalized = normalizeEffectId(effect_id)
    if normalized == nil then
        return nil
    end
    return (string.gsub(normalized, "[^%w]", ""))
end

local function isSpellforgeDisplayEffect(effect_id)
    local normalized = normalizeEffectId(effect_id)
    return normalized ~= nil and string.sub(normalized, 1, 11) == "spellforge_"
end

local function joinValues(values)
    local out = {}
    for i, value in ipairs(values or {}) do
        out[i] = tostring(value)
    end
    return table.concat(out, ",")
end

local function booleanValue(value)
    if type(value) == "boolean" then
        return value, true
    end
    if type(value) == "number" then
        return value ~= 0, true
    end
    if type(value) == "string" then
        local normalized = string.lower(value)
        if normalized == "true" or normalized == "yes" or normalized == "1" then
            return true, true
        elseif normalized == "false" or normalized == "no" or normalized == "0" then
            return false, true
        end
    end
    return nil, false
end

local function targetSpellMaxSpeed()
    local gmst_speed = positiveNumber(safeCall(function()
        return core.getGMST("fTargetSpellMaxSpeed")
    end))
    return gmst_speed or FALLBACK_TARGET_SPELL_MAX_SPEED
end

local function magicEffectRecords()
    return safeCall(function()
        return core.magic.effects.records
    end)
end

local function recordId(record)
    return safeIndex(record, "id")
end

local function lookupEffectRecord(effect_id)
    local records = magicEffectRecords()
    if records == nil or effect_id == nil then
        return nil
    end

    local normalized = normalizeEffectId(effect_id)
    local compact = compactEffectId(effect_id)
    local candidates = {
        effect_id,
        tostring(effect_id),
        normalized,
        compact,
    }

    for _, candidate in ipairs(candidates) do
        if candidate ~= nil and candidate ~= "" then
            local record = safeIndex(records, candidate)
            if record ~= nil then
                return record
            end
        end
    end

    return safeCall(function()
        for key, record in pairs(records) do
            local key_normalized = normalizeEffectId(key)
            local key_compact = compactEffectId(key)
            local id_normalized = normalizeEffectId(recordId(record))
            local id_compact = compactEffectId(recordId(record))
            if key_normalized == normalized
                or key_compact == compact
                or id_normalized == normalized
                or id_compact == compact then
                return record
            end
        end
        return nil
    end)
end

local function effectId(effect)
    if type(effect) == "string" then
        return effect
    end
    if effect == nil then
        return nil
    end
    return safeIndex(effect, "engine_effect_id")
        or safeIndex(effect, "id")
        or safeIndex(effect, "effect_id")
        or safeIndex(effect, "effectId")
end

local function appendEffects(out, source)
    if type(source) ~= "table" then
        return
    end
    local effects = source.effects
    if type(effects) ~= "table" then
        return
    end
    for _, effect in ipairs(effects) do
        out[#out + 1] = effect
    end
end

local function runtimeEffectIds(source)
    local effects = {}
    appendEffects(effects, source)
    appendEffects(effects, source and source.slot)
    appendEffects(effects, source and source.helper)
    appendEffects(effects, source and source.mapping)
    appendEffects(effects, source and source.launch)

    local out = {}
    for _, effect in ipairs(effects) do
        local id = effectId(effect)
        if id ~= nil and not isSpellforgeDisplayEffect(id) then
            out[#out + 1] = id
        end
    end
    return out
end

local function magicEffectSpeed(effect_id)
    local record = lookupEffectRecord(effect_id)
    return positiveNumber(record and safeIndex(record, "speed"))
end

local function averageEffectSpeeds(effect_ids)
    local speeds = {}
    for _, effect_id in ipairs(effect_ids or {}) do
        local speed = magicEffectSpeed(effect_id)
        if speed ~= nil then
            speeds[#speeds + 1] = speed
        end
    end
    if #speeds == 0 then
        return 1.0, speeds, "fallback"
    end
    local total = 0
    for _, speed in ipairs(speeds) do
        total = total + speed
    end
    return total / #speeds, speeds, "vanilla_baseline"
end

local function normaliseRaceSpeedSetting()
    if not ok_settings or settings == nil then
        return {
            known = false,
            value = nil,
            source = "openmw_settings_unavailable",
        }
    end

    local names = {
        "normalise race speed",
        "normalize race speed",
        "normaliseRaceSpeed",
        "normalizeRaceSpeed",
    }
    local sections = { "Game", "game", "SettingsGame", "SettingsGlobalGame" }

    local function tryValue(value, source)
        local normalized, ok = booleanValue(value)
        if ok then
            return {
                known = true,
                value = normalized,
                source = source,
            }
        end
        return nil
    end

    local settings_get = safeIndex(settings, "get")
    if type(settings_get) == "function" then
        for _, section in ipairs(sections) do
            for _, name in ipairs(names) do
                local result = safeCall(function()
                    return settings_get(section, name)
                end)
                local parsed = tryValue(result, "openmw.settings.get")
                if parsed then
                    return parsed
                end
                result = safeCall(function()
                    return settings_get(settings, section, name)
                end)
                parsed = tryValue(result, "openmw.settings.get")
                if parsed then
                    return parsed
                end
            end
        end
    end

    for _, section_name in ipairs({ "globalSection", "playerSection" }) do
        local section_fn = safeIndex(settings, section_name)
        if type(section_fn) == "function" then
            for _, section in ipairs(sections) do
                local section_obj = safeCall(function()
                    return section_fn(section)
                end)
                if section_obj == nil then
                    section_obj = safeCall(function()
                        return section_fn(settings, section)
                    end)
                end
                local get_fn = section_obj and safeIndex(section_obj, "get")
                if type(get_fn) == "function" then
                    for _, name in ipairs(names) do
                        local result = safeCall(function()
                            return get_fn(section_obj, name)
                        end)
                        local parsed = tryValue(result, "openmw.settings." .. section_name)
                        if parsed then
                            return parsed
                        end
                    end
                end
            end
        end
    end

    return {
        known = false,
        value = nil,
        source = "openmw_settings_unreadable",
    }
end

local function npcApi()
    if ok_types and types and types.NPC then
        return types.NPC
    end
    return nil
end

local function npcRecord(caster)
    local npc = npcApi()
    if caster == nil or npc == nil then
        return nil
    end
    local object_is_instance = safeIndex(npc, "objectIsInstance")
    if type(object_is_instance) == "function" then
        local is_npc = safeCall(function()
            return object_is_instance(caster)
        end)
        if is_npc == false then
            return nil
        end
    end
    local record_fn = safeIndex(npc, "record")
    if type(record_fn) ~= "function" then
        return nil
    end
    return safeCall(function()
        return record_fn(caster)
    end)
end

local function raceRecord(race_id)
    local npc = npcApi()
    if npc == nil or race_id == nil then
        return nil
    end
    local races = safeIndex(npc, "races")
    if races == nil then
        return nil
    end
    local record_fn = safeIndex(races, "record")
    if type(record_fn) == "function" then
        local record = safeCall(function()
            return record_fn(race_id)
        end)
        if record ~= nil then
            return record
        end
    end
    local records = safeIndex(races, "records")
    if records ~= nil then
        local direct = safeIndex(records, race_id) or safeIndex(records, normalizeEffectId(race_id))
        if direct ~= nil then
            return direct
        end
    end
    return nil
end

local function genderedNumberValue(value, is_male)
    local n = positiveNumber(value)
    if n ~= nil then
        return n, "plain"
    end
    local male = positiveNumber(safeIndex(value, "male"))
    local female = positiveNumber(safeIndex(value, "female"))
    if is_male == true then
        return male or female or 1.0, male and "male" or "fallback"
    elseif is_male == false then
        return female or male or 1.0, female and "female" or "fallback"
    elseif male ~= nil and female ~= nil then
        return (male + female) / 2, "sex_unknown_average"
    end
    return male or female or 1.0, (male or female) and "sex_unknown_single" or "fallback"
end

local function casterName(caster, record)
    return safeIndex(caster, "name")
        or safeIndex(record, "name")
        or safeIndex(caster, "recordId")
        or safeIndex(record, "id")
end

local function casterRecordId(caster, record)
    return safeIndex(caster, "recordId")
        or safeIndex(caster, "id")
        or safeIndex(record, "id")
end

local function casterRaceWeight(caster)
    local record = npcRecord(caster)
    local race_id = safeIndex(record, "race")
    local race_record = raceRecord(race_id)
    local weight_values = race_record and safeIndex(race_record, "weight") or nil
    local is_male = safeIndex(record, "isMale")
    if type(is_male) ~= "boolean" then
        is_male = nil
    end
    local weight, weight_source = genderedNumberValue(weight_values, is_male)
    return {
        weight = positiveNumber(weight) or 1.0,
        race_id = race_id,
        caster_id = casterRecordId(caster, record),
        caster_name = casterName(caster, record),
        is_male = is_male,
        source = race_record and weight_source or "race_unavailable",
    }
end

local function emitBaseline(details, opts)
    if opts and opts.log == false then
        return
    end
    log.debug(string.format(
        "SPELLFORGE_PROJECTILE_SPEED_BASELINE recipe_id=%s slot_id=%s helper_engine_id=%s helper_logical_id=%s caster_id=%s caster_name=%s effect_ids=%s effect_speeds=%s averaged_effect_speed=%s gmst_name=fTargetSpellMaxSpeed gmst_speed=%s openmw_baseline_before_backend_scale=%s backend_speed_scale=%s race_id=%s race_weight=%s race_weight_applied=%s normalise_race_speed_known=%s normalise_race_speed=%s baseline_speed_before_race_weight=%s final_baseline_speed=%s source=%s",
        tostring(details.recipe_id),
        tostring(details.slot_id),
        tostring(details.helper_engine_id),
        tostring(details.helper_logical_id),
        tostring(details.caster_id),
        tostring(details.caster_name),
        tostring(details.effect_ids_text),
        tostring(details.effect_speeds_text),
        tostring(details.averaged_effect_speed),
        tostring(details.gmst_speed),
        tostring(details.openmw_baseline_before_backend_scale),
        tostring(details.backend_speed_scale),
        tostring(details.race_id),
        tostring(details.race_weight),
        tostring(details.race_weight_applied == true),
        tostring(details.normalise_race_speed_known == true),
        tostring(details.normalise_race_speed),
        tostring(details.baseline_speed_before_race_weight),
        tostring(details.final_baseline_speed),
        tostring(details.source)
    ))
end

local function metadataFromSource(source)
    return {
        recipe_id = source and (source.recipe_id or (source.mapping and source.mapping.recipe_id) or (source.launch and source.launch.recipe_id)) or nil,
        slot_id = source and (source.slot_id or (source.mapping and source.mapping.slot_id) or (source.launch and source.launch.slot_id)) or nil,
        helper_engine_id = source and (source.engine_id or source.helper_engine_id or (source.helper and source.helper.engine_id) or (source.mapping and source.mapping.engine_id) or (source.launch and source.launch.helper_engine_id)) or nil,
        helper_logical_id = source and (source.logical_id or (source.helper and source.helper.logical_id) or (source.mapping and source.mapping.logical_id)) or nil,
    }
end

local function diagnosticReason(details)
    if type(details) ~= "table" then
        return "speed_policy_missing"
    end
    if details.speed_plus == true or details.speed_source == "speed_plus" then
        return "speed_plus"
    end
    if details.explicit_speed == true or details.speed_source == "explicit" then
        return "explicit_speed"
    end
    return "diagnostic_disabled"
end

function projectile_speed_policy.targetSpellSpeed()
    return targetSpellMaxSpeed()
end

function projectile_speed_policy.targetSpellMaxSpeed()
    return targetSpellMaxSpeed()
end

function projectile_speed_policy.applySpeedPlusMultiplier(baseline, multiplier)
    local speed = (positiveNumber(baseline) or (targetSpellMaxSpeed() * BACKEND_PROJECTILE_SPEED_SCALE))
        * (positiveNumber(multiplier) or 1)
    return speed, false
end

function projectile_speed_policy.resolveEffectSpeed(effect_id, opts)
    return projectile_speed_policy.resolveForSlot({
        effects = effect_id and { { id = effect_id } } or {},
    }, opts)
end

function projectile_speed_policy.resolveForSlot(slot_or_mapping, opts)
    local options = opts or {}
    local meta = metadataFromSource(slot_or_mapping)
    local effect_ids = runtimeEffectIds(slot_or_mapping)
    local averaged_speed, effect_speeds, source = averageEffectSpeeds(effect_ids)
    local gmst_speed = targetSpellMaxSpeed()
    local openmw_before_scale = gmst_speed * averaged_speed
    local before_race = openmw_before_scale * BACKEND_PROJECTILE_SPEED_SCALE
    local apply_race_weight_policy = options.apply_race_weight ~= false
    local normalise = apply_race_weight_policy and normaliseRaceSpeedSetting() or {
        known = true,
        value = true,
        source = "race_weight_skipped",
    }
    local race = apply_race_weight_policy and casterRaceWeight(options.caster or (slot_or_mapping and slot_or_mapping.actor)) or {
        weight = 1.0,
        source = "race_weight_skipped",
    }
    local race_weight = 1.0
    local race_weight_applied = false

    if normalise.known == true then
        if normalise.value == false then
            race_weight = race.weight
            race_weight_applied = true
        end
    elseif USE_CASTER_RACE_WEIGHT_FOR_PROJECTILE_SPEED then
        race_weight = race.weight
        race_weight_applied = true
        if normalise_race_speed_unreadable_logged ~= true then
            normalise_race_speed_unreadable_logged = true
            log.debug(string.format(
                "SPELLFORGE_NORMALISE_RACE_SPEED_UNREADABLE fallback_use_race_weight=%s source=%s",
                tostring(USE_CASTER_RACE_WEIGHT_FOR_PROJECTILE_SPEED),
                tostring(normalise.source)
            ))
        end
    end

    local baseline = before_race * race_weight
    local details = {
        recipe_id = options.recipe_id or meta.recipe_id,
        slot_id = options.slot_id or meta.slot_id,
        helper_engine_id = options.helper_engine_id or meta.helper_engine_id,
        helper_logical_id = options.helper_logical_id or meta.helper_logical_id,
        caster_id = race.caster_id,
        caster_name = race.caster_name,
        effect_ids = effect_ids,
        effect_ids_text = joinValues(effect_ids),
        effect_speeds = effect_speeds,
        effect_speeds_text = joinValues(effect_speeds),
        averaged_effect_speed = averaged_speed,
        gmst_name = "fTargetSpellMaxSpeed",
        gmst_speed = gmst_speed,
        race_id = race.race_id,
        race_weight = race_weight,
        race_weight_source = race.source,
        race_weight_applied = race_weight_applied,
        normalise_race_speed_known = normalise.known == true,
        normalise_race_speed = normalise.value,
        normalise_race_speed_source = normalise.source,
        openmw_baseline_before_backend_scale = openmw_before_scale,
        backend_speed_scale = BACKEND_PROJECTILE_SPEED_SCALE,
        baseline_speed_before_race_weight = before_race,
        final_baseline_speed = baseline,
        baseline_speed = baseline,
        source = source,
    }
    emitBaseline(details, options)
    return baseline, details
end

local function launchSource(launch, explicit_speed)
    if launch and launch.speed_plus == true then
        return "speed_plus"
    end
    if explicit_speed then
        return "explicit"
    end
    return nil
end

function projectile_speed_policy.applyBaselineLaunchSpeed(launch_data, context)
    if type(launch_data) ~= "table" then
        return nil
    end

    local launch = context and context.launch or nil
    local mapping = context and context.mapping or nil
    local explicit_speed = positiveNumber(launch_data.speed) ~= nil
    local explicit_max_speed = positiveNumber(launch_data.maxSpeed) ~= nil
    local speed_plus = launch and launch.speed_plus == true and positiveNumber(launch.speed_plus_multiplier) ~= nil
    local source = speed_plus and "speed_plus" or launchSource(launch, explicit_speed)
    local details = nil

    if speed_plus then
        local baseline = nil
        baseline, details = projectile_speed_policy.resolveForSlot(mapping or launch, {
            log = context and context.log_baseline,
            caster = launch and launch.actor or nil,
            recipe_id = launch and launch.recipe_id or (mapping and mapping.recipe_id),
            slot_id = launch and launch.slot_id or (mapping and mapping.slot_id),
            helper_engine_id = launch and launch.helper_engine_id or (mapping and mapping.engine_id),
            helper_logical_id = mapping and mapping.logical_id or nil,
        })
        local launch_data_source = type(launch) == "table" and launch or {}
        local speed_plus_multiplier = launch_data_source["speed_plus_multiplier"]
        local final_speed, capped = projectile_speed_policy.applySpeedPlusMultiplier(baseline, speed_plus_multiplier)
        launch_data.speed = final_speed
        launch_data.maxSpeed = final_speed
        details.final_speed = final_speed
        details.maxSpeed = final_speed
        details.explicit_speed = true
        details.speed_plus = true
        details.speed_plus_multiplier = speed_plus_multiplier
        details.speed_plus_capped = capped or launch_data_source["speed_plus_capped"] == true
        details.speed_source = "speed_plus"
        details.source = "speed_plus"
        log.debug(string.format(
            "SPELLFORGE_SPEED_PLUS_LAUNCH_SPEED recipe_id=%s slot_id=%s helper_engine_id=%s helper_logical_id=%s caster_id=%s effect_ids=%s effect_speeds=%s averaged_effect_speed=%s gmst_name=fTargetSpellMaxSpeed gmst_speed=%s openmw_baseline_before_backend_scale=%s backend_speed_scale=%s race_id=%s race_weight=%s race_weight_applied=%s normalise_race_speed_known=%s normalise_race_speed=%s baseline_speed_before_race_weight=%s final_baseline_speed=%s speed_plus_multiplier=%s final_speed=%s maxSpeed=%s capped=%s source=speed_plus",
            tostring(details.recipe_id),
            tostring(details.slot_id),
            tostring(details.helper_engine_id),
            tostring(details.helper_logical_id),
            tostring(details.caster_id),
            tostring(details.effect_ids_text),
            tostring(details.effect_speeds_text),
            tostring(details.averaged_effect_speed),
            tostring(details.gmst_speed),
            tostring(details.openmw_baseline_before_backend_scale),
            tostring(details.backend_speed_scale),
            tostring(details.race_id),
            tostring(details.race_weight),
            tostring(details.race_weight_applied == true),
            tostring(details.normalise_race_speed_known == true),
            tostring(details.normalise_race_speed),
            tostring(details.baseline_speed_before_race_weight),
            tostring(details.final_baseline_speed),
            tostring(details.speed_plus_multiplier),
            tostring(final_speed),
            tostring(final_speed),
            tostring(details.speed_plus_capped == true)
        ))
    elseif explicit_speed then
        details = {
            recipe_id = launch and launch.recipe_id or (mapping and mapping.recipe_id),
            slot_id = launch and launch.slot_id or (mapping and mapping.slot_id),
            helper_engine_id = launch and launch.helper_engine_id or (mapping and mapping.engine_id),
            helper_logical_id = mapping and mapping.logical_id or nil,
            effect_ids_text = joinValues(runtimeEffectIds(mapping or launch)),
            baseline_speed = launch and launch.speed_plus_base_speed or nil,
            final_baseline_speed = launch and launch.speed_plus_base_speed or nil,
            final_speed = launch_data.speed,
            maxSpeed = launch_data.maxSpeed,
            explicit_speed = true,
            speed_plus = false,
            speed_source = source or "explicit",
            source = source or "explicit",
        }
    else
        local baseline = nil
        baseline, details = projectile_speed_policy.resolveForSlot(mapping or launch, {
            log = context and context.log_baseline,
            caster = launch and launch.actor or nil,
            recipe_id = launch and launch.recipe_id or (mapping and mapping.recipe_id),
            slot_id = launch and launch.slot_id or (mapping and mapping.slot_id),
            helper_engine_id = launch and launch.helper_engine_id or (mapping and mapping.engine_id),
            helper_logical_id = mapping and mapping.logical_id or nil,
        })
        if positiveNumber(baseline) == nil then
            return nil
        end
        launch_data.speed = baseline
        if not explicit_max_speed then
            launch_data.maxSpeed = baseline
        end
        details.final_speed = baseline
        details.maxSpeed = launch_data.maxSpeed
        details.explicit_speed = false
        details.speed_plus = false
        details.speed_source = "vanilla_baseline"
        details.effect_speed_source = details.source
        details.source = "vanilla_baseline"
    end

    log.debug(string.format(
        "SPELLFORGE_HELPER_LAUNCH_SPEED recipe_id=%s slot_id=%s helper_engine_id=%s helper_logical_id=%s effect_ids=%s averaged_effect_speed=%s gmst_name=fTargetSpellMaxSpeed gmst_speed=%s openmw_baseline_before_backend_scale=%s backend_speed_scale=%s race_id=%s race_weight=%s race_weight_applied=%s normalise_race_speed_known=%s normalise_race_speed=%s final_baseline_speed=%s final_speed=%s maxSpeed=%s explicit_speed=%s speed_plus=%s source=%s",
        tostring(details.recipe_id),
        tostring(details.slot_id),
        tostring(details.helper_engine_id),
        tostring(details.helper_logical_id),
        tostring(details.effect_ids_text),
        tostring(details.averaged_effect_speed),
        tostring(details.gmst_speed),
        tostring(details.openmw_baseline_before_backend_scale),
        tostring(details.backend_speed_scale),
        tostring(details.race_id),
        tostring(details.race_weight),
        tostring(details.race_weight_applied == true),
        tostring(details.normalise_race_speed_known == true),
        tostring(details.normalise_race_speed),
        tostring(details.final_baseline_speed),
        tostring(launch_data.speed),
        tostring(launch_data.maxSpeed),
        tostring(details.explicit_speed == true),
        tostring(details.speed_plus == true),
        tostring(details.source)
    ))

    if details.explicit_speed ~= true then
        log.debug(string.format(
            "SPELLFORGE_VANILLA_PROJECTILE_SPEED_OK recipe_id=%s slot_id=%s helper_engine_id=%s effect_ids=%s averaged_effect_speed=%s gmst_name=fTargetSpellMaxSpeed gmst_speed=%s openmw_baseline_before_backend_scale=%s backend_speed_scale=%s race_id=%s race_weight=%s race_weight_applied=%s final_baseline_speed=%s maxSpeed=%s source=%s",
            tostring(details.recipe_id),
            tostring(details.slot_id),
            tostring(details.helper_engine_id),
            tostring(details.effect_ids_text),
            tostring(details.averaged_effect_speed),
            tostring(details.gmst_speed),
            tostring(details.openmw_baseline_before_backend_scale),
            tostring(details.backend_speed_scale),
            tostring(details.race_id),
            tostring(details.race_weight),
            tostring(details.race_weight_applied == true),
            tostring(launch_data.speed),
            tostring(launch_data.maxSpeed),
            tostring(details.source)
        ))
    end

    return details
end

function projectile_speed_policy.applyDiagnosticExplicitSpeedOmit(launch_data, details)
    if type(launch_data) ~= "table" then
        return nil
    end

    local enabled = projectile_speed_policy.SPELLFORGE_DIAG_OMIT_EXPLICIT_PROJECTILE_SPEED == true
    local previous_speed = launch_data.speed
    local previous_max_speed = launch_data.maxSpeed
    local previous_initial_speed = launch_data.initial_speed
    local speed_source = type(details) == "table" and (details.speed_source or details.source) or nil

    if not enabled then
        return {
            enabled = false,
            omitted = false,
            preserved = true,
            reason = "diagnostic_disabled",
        }
    end

    log.info(string.format(
        "SPELLFORGE_DIAG_OMIT_EXPLICIT_SPEED_ENABLED recipe_id=%s slot_id=%s helper_engine_id=%s speed_source=%s",
        tostring(details and details.recipe_id),
        tostring(details and details.slot_id),
        tostring(details and details.helper_engine_id),
        tostring(speed_source)
    ))

    if speed_source == "vanilla_baseline" and not (details and (details.speed_plus == true or details.explicit_speed == true)) then
        launch_data.speed = nil
        launch_data.maxSpeed = nil
        launch_data.initial_speed = nil
        log.info(string.format(
            "SPELLFORGE_DIAG_EXPLICIT_SPEED_OMITTED recipe_id=%s slot_id=%s helper_engine_id=%s effect_ids=%s previous_speed=%s previous_maxSpeed=%s previous_initial_speed=%s speed_source=%s diagnostic_omit=true",
            tostring(details and details.recipe_id),
            tostring(details and details.slot_id),
            tostring(details and details.helper_engine_id),
            tostring(details and details.effect_ids_text),
            tostring(previous_speed),
            tostring(previous_max_speed),
            tostring(previous_initial_speed),
            tostring(speed_source)
        ))
        return {
            enabled = true,
            omitted = true,
            preserved = false,
            previous_speed = previous_speed,
            previous_maxSpeed = previous_max_speed,
            previous_initial_speed = previous_initial_speed,
            speed_source = speed_source,
        }
    end

    local reason = diagnosticReason(details)
    log.info(string.format(
        "SPELLFORGE_DIAG_EXPLICIT_SPEED_PRESERVED recipe_id=%s slot_id=%s helper_engine_id=%s effect_ids=%s previous_speed=%s previous_maxSpeed=%s speed_source=%s diagnostic_omit=true reason=%s",
        tostring(details and details.recipe_id),
        tostring(details and details.slot_id),
        tostring(details and details.helper_engine_id),
        tostring(details and details.effect_ids_text),
        tostring(previous_speed),
        tostring(previous_max_speed),
        tostring(speed_source),
        tostring(reason)
    ))
    return {
        enabled = true,
        omitted = false,
        preserved = true,
        reason = reason,
        speed_source = speed_source,
    }
end

return projectile_speed_policy
