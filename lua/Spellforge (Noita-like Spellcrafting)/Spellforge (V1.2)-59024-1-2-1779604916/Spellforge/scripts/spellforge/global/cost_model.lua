local core = require("openmw.core")

local parser = require("scripts.spellforge.global.parser")
local runtime_ir = require("scripts.spellforge.global.runtime_ir")
local base_effect_catalog = require("scripts.spellforge.shared.base_effect_catalog")
local effect_registry = require("scripts.spellforge.shared.effect_support_registry")
local validation = require("scripts.spellforge.shared.validation_contract")
local log = require("scripts.spellforge.shared.log").new("global.cost_model")

local cost_model = {}

cost_model.VERSION = "spellforge-cost-v2-effect-registry"

local RANGE_TARGET = 2
local PUBLIC_MINIMUM_COST = 5

local FALLBACK_EFFECT_COSTS = {
    absorbhealth = { baseCost = 10, school = "Mysticism", hasMagnitude = true, hasDuration = true },
    blind = { baseCost = 1, school = "Illusion", hasMagnitude = true, hasDuration = true },
    burden = { baseCost = 1, school = "Alteration", hasMagnitude = true, hasDuration = true },
    chameleon = { baseCost = 3, school = "Illusion", hasMagnitude = true, hasDuration = true },
    damagehealth = { baseCost = 8, school = "Destruction", hasMagnitude = true, hasDuration = false, isAppliedOnce = true },
    detectanimal = { baseCost = 0.2, school = "Mysticism", hasMagnitude = true, hasDuration = true },
    detectenchantment = { baseCost = 0.2, school = "Mysticism", hasMagnitude = true, hasDuration = true },
    detectkey = { baseCost = 0.2, school = "Mysticism", hasMagnitude = true, hasDuration = true },
    drainhealth = { baseCost = 8, school = "Destruction", hasMagnitude = true, hasDuration = true },
    feather = { baseCost = 1, school = "Alteration", hasMagnitude = true, hasDuration = true },
    firedamage = { baseCost = 5, school = "Destruction", hasMagnitude = true, hasDuration = true },
    fireshield = { baseCost = 3, school = "Alteration", hasMagnitude = true, hasDuration = true },
    fortifyfatigue = { baseCost = 1, school = "Restoration", hasMagnitude = true, hasDuration = true },
    fortifyhealth = { baseCost = 1, school = "Restoration", hasMagnitude = true, hasDuration = true },
    fortifymagicka = { baseCost = 1, school = "Restoration", hasMagnitude = true, hasDuration = true },
    frostdamage = { baseCost = 5, school = "Destruction", hasMagnitude = true, hasDuration = true },
    frostshield = { baseCost = 3, school = "Alteration", hasMagnitude = true, hasDuration = true },
    invisibility = { baseCost = 20, school = "Illusion", hasMagnitude = false, hasDuration = true },
    jump = { baseCost = 3, school = "Alteration", hasMagnitude = true, hasDuration = true },
    levitate = { baseCost = 3, school = "Alteration", hasMagnitude = true, hasDuration = true },
    lightningshield = { baseCost = 3, school = "Alteration", hasMagnitude = true, hasDuration = true },
    open = { baseCost = 1, school = "Alteration", hasMagnitude = true, hasDuration = false },
    paralyze = { baseCost = 40, school = "Illusion", hasMagnitude = false, hasDuration = true },
    poison = { baseCost = 9, school = "Destruction", hasMagnitude = true, hasDuration = true },
    resistfire = { baseCost = 2, school = "Restoration", hasMagnitude = true, hasDuration = true },
    resistfrost = { baseCost = 2, school = "Restoration", hasMagnitude = true, hasDuration = true },
    resistpoison = { baseCost = 2, school = "Restoration", hasMagnitude = true, hasDuration = true },
    resistshock = { baseCost = 2, school = "Restoration", hasMagnitude = true, hasDuration = true },
    restorefatigue = { baseCost = 2, school = "Restoration", hasMagnitude = true, hasDuration = false, isAppliedOnce = true },
    restorehealth = { baseCost = 5, school = "Restoration", hasMagnitude = true, hasDuration = false, isAppliedOnce = true },
    restoremagicka = { baseCost = 5, school = "Restoration", hasMagnitude = true, hasDuration = false, isAppliedOnce = true },
    shield = { baseCost = 2, school = "Alteration", hasMagnitude = true, hasDuration = true },
    shockdamage = { baseCost = 7, school = "Destruction", hasMagnitude = true, hasDuration = true },
    silence = { baseCost = 40, school = "Illusion", hasMagnitude = false, hasDuration = true },
    slowfall = { baseCost = 1, school = "Alteration", hasMagnitude = true, hasDuration = true },
    telekinesis = { baseCost = 1, school = "Mysticism", hasMagnitude = true, hasDuration = true },
    waterbreathing = { baseCost = 1, school = "Alteration", hasMagnitude = false, hasDuration = true },
    waterwalking = { baseCost = 1, school = "Alteration", hasMagnitude = false, hasDuration = true },
    weaknesstofire = { baseCost = 1, school = "Destruction", hasMagnitude = true, hasDuration = true },
    weaknesstofrost = { baseCost = 1, school = "Destruction", hasMagnitude = true, hasDuration = true },
    weaknesstopoison = { baseCost = 1, school = "Destruction", hasMagnitude = true, hasDuration = true },
    weaknesstoshock = { baseCost = 1, school = "Destruction", hasMagnitude = true, hasDuration = true },
}

local SCHOOL_BY_NUMBER = {
    [0] = "Alteration",
    [1] = "Conjuration",
    [2] = "Destruction",
    [3] = "Illusion",
    [4] = "Mysticism",
    [5] = "Restoration",
}

local function readField(value, key)
    if value == nil then
        return nil
    end
    local ok, field = pcall(function()
        return value[key]
    end)
    if ok then
        return field
    end
    return nil
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

local function normalizeId(value)
    return effect_registry.normalizeEffectId(value)
end

local function compactId(value)
    local text = normalizeId(value)
    if not text then
        return nil
    end
    return string.gsub(text, "_+", "")
end

local function numberValue(value, fallback)
    local n = tonumber(value)
    if n ~= nil then
        return n
    end
    return fallback
end

local function boolValue(value)
    if value == nil then
        return nil
    end
    if type(value) == "boolean" then
        return value
    end
    if type(value) == "number" then
        return value ~= 0
    end
    local text = string.lower(tostring(value))
    if text == "true" or text == "yes" or text == "1" then
        return true
    elseif text == "false" or text == "no" or text == "0" then
        return false
    end
    return nil
end

local function normalizeSchool(value)
    if value == nil then
        return "Unknown"
    end
    local numeric = tonumber(value)
    if numeric ~= nil and SCHOOL_BY_NUMBER[numeric] then
        return SCHOOL_BY_NUMBER[numeric]
    end
    local text = tostring(value)
    local lower = string.lower(text)
    if string.find(lower, "destruction", 1, true) then
        return "Destruction"
    elseif string.find(lower, "alteration", 1, true) then
        return "Alteration"
    elseif string.find(lower, "restoration", 1, true) then
        return "Restoration"
    elseif string.find(lower, "mysticism", 1, true) then
        return "Mysticism"
    elseif string.find(lower, "illusion", 1, true) then
        return "Illusion"
    elseif string.find(lower, "conjuration", 1, true) then
        return "Conjuration"
    end
    return "Unknown"
end

local function cloneIssues(values)
    local out = {}
    for i, value in ipairs(values or {}) do
        out[i] = value
    end
    return out
end

local function addWarning(state, reason, detail)
    state.warnings[#state.warnings + 1] = {
        reason = reason,
        detail = detail,
    }
end

local function addError(state, path, message, code, details)
    state.errors[#state.errors + 1] = validation.error(path, message, code, details)
end

local function logLookupOk(effect_id, info)
    log.info(string.format(
        "SPELLFORGE_COST_MAGIC_EFFECT_LOOKUP_OK effect_id=%s baseCost=%s school=%s",
        tostring(effect_id),
        tostring(info and info.baseCost),
        tostring(info and info.school)
    ))
end

local function logLookupFailed(effect_id, reason)
    log.warn(string.format(
        "SPELLFORGE_COST_MAGIC_EFFECT_LOOKUP_FAILED effect_id=%s reason=%s",
        tostring(effect_id),
        tostring(reason)
    ))
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

local function recordId(record)
    return readField(record, "id")
        or readField(record, "recordId")
        or readField(record, "effectId")
        or readField(record, "refId")
end

local function caseInsensitiveRecord(records, effect_id)
    local lower_id = normalizeId(effect_id)
    if not lower_id then
        return nil
    end
    local found = nil
    pcall(function()
        for key, record in pairs(records or {}) do
            if normalizeId(key) == lower_id
                or normalizeId(recordId(record)) == lower_id
                or compactId(key) == compactId(lower_id)
                or compactId(recordId(record)) == compactId(lower_id) then
                found = record
                break
            end
        end
    end)
    return found
end

local function magicEffectRecordsTable(opts)
    if type(opts and opts.magic_effect_records) == "table" then
        return opts.magic_effect_records, opts.magic_effect_records, nil
    end
    local magic = readField(core, "magic")
    local effects = readField(magic, "effects")
    local records = readField(effects, "records")
    if records == nil then
        return nil, effects, "magic_effect_record_lookup_unavailable"
    end
    return records, effects, nil
end

local function recordInfo(record, effect_id, source)
    if record == nil then
        return nil
    end
    local base_cost = numberValue(
        firstNonNil(readField(record, "baseCost"), readField(record, "base_cost"), readField(record, "cost")),
        nil
    )
    if base_cost == nil then
        return nil
    end
    return {
        effect_id = effect_id,
        baseCost = base_cost,
        school = normalizeSchool(readField(record, "school")),
        hasMagnitude = boolValue(readField(record, "hasMagnitude")),
        hasDuration = boolValue(readField(record, "hasDuration")),
        isAppliedOnce = boolValue(readField(record, "isAppliedOnce")),
        source = source,
    }
end

local function directRecordFromEffect(effect)
    return readField(effect, "effect") or readField(effect, "mgef") or readField(effect, "magicEffect")
end

function cost_model.resolveMagicEffectInfo(effect, effect_id, opts)
    local id = normalizeId(effect_id or (effect and effect.id))
    if not id then
        return nil, "effect_id_missing"
    end

    local direct = directRecordFromEffect(effect)
    local info = recordInfo(direct, id, "effect_record")
    if info then
        logLookupOk(id, info)
        return info, nil
    end

    local records, effects, table_err = magicEffectRecordsTable(opts)
    if records ~= nil then
        local record = lookupRecord(records, id)
            or lookupRecord(records, string.lower(id))
            or callRecordGetter(records, id)
            or callRecordGetter(effects, id)
            or caseInsensitiveRecord(records, id)
        info = recordInfo(record, id, type(opts and opts.magic_effect_records) == "table" and "override" or "openmw")
        if info then
            logLookupOk(id, info)
            return info, nil
        end
    end

    local reason = table_err or "magic_effect_record_missing"
    logLookupFailed(id, reason)
    local fallback = FALLBACK_EFFECT_COSTS[id]
    if fallback then
        return {
            effect_id = id,
            baseCost = fallback.baseCost,
            school = fallback.school or "Unknown",
            hasMagnitude = fallback.hasMagnitude,
            hasDuration = fallback.hasDuration,
            isAppliedOnce = fallback.isAppliedOnce,
            source = "fallback_static",
        },
            reason
    end
    local registry_fallback = effect_registry.getCostInfo(id)
    if registry_fallback then
        return registry_fallback, reason
    end
    return {
        effect_id = id,
        baseCost = 10,
        school = "Unknown",
        hasMagnitude = true,
        hasDuration = true,
        isAppliedOnce = false,
        source = "fallback_default",
    },
        reason
end

local function effectNumber(effect, primary, secondary, tertiary, fallback)
    return numberValue(
        firstNonNil(
            readField(effect, primary),
            secondary and readField(effect, secondary) or nil,
            tertiary and readField(effect, tertiary) or nil
        ),
        fallback
    )
end

local function isTargetRange(range)
    if tonumber(range) == RANGE_TARGET then
        return true
    end
    local text = string.lower(tostring(range or ""))
    return text == "target" or string.find(text, "target", 1, true) ~= nil
end

local function effectCostMult(state, opts)
    if tonumber(opts and opts.fEffectCostMult) ~= nil then
        return tonumber(opts.fEffectCostMult)
    end
    local getter = readField(core, "getGMST")
    if type(getter) == "function" then
        local ok, value = pcall(getter, "fEffectCostMult")
        local numeric = ok and tonumber(value) or nil
        if numeric ~= nil then
            return numeric
        end
    end
    addWarning(state, "gmst_fEffectCostMult_unavailable", "using 1.0")
    return 1.0
end

local function calcEffectCost(effect, info, mult, mode)
    local mag_min = effectNumber(effect, "magnitudeMin", "minMagnitude", "min", nil)
    local mag_max = effectNumber(effect, "magnitudeMax", "maxMagnitude", "max", mag_min)
    local average_magnitude = 0.5 * ((mag_min or 1) + (mag_max or mag_min or 1))
    if info.hasMagnitude == false then
        average_magnitude = 1
    elseif average_magnitude <= 0 and mag_min == nil and mag_max == nil then
        average_magnitude = 1
    end

    local duration = effectNumber(effect, "duration", nil, nil, nil)
    if info.hasDuration == false or duration == nil then
        duration = 1
    elseif info.isAppliedOnce ~= true and duration < 1 then
        duration = 1
    end

    local area = effectNumber(effect, "area", nil, nil, 0)
    local cost = average_magnitude
    cost = cost * (0.1 * math.max(0, tonumber(info.baseCost) or 0))
    cost = cost * math.max(0, duration or 1)
    cost = cost + (0.05 * math.max(0, area or 0) * math.max(0, tonumber(info.baseCost) or 0))
    if isTargetRange(readField(effect, "range")) then
        cost = cost * 1.5
    end
    cost = cost * math.max(0, tonumber(mult) or 1)
    return cost, {
        mode = mode or "player_spell",
        average_magnitude = average_magnitude,
        duration = duration,
        area = area,
        range = readField(effect, "range"),
        baseCost = info.baseCost,
        effectCostMult = mult,
    }
end

function cost_model.calcEffectCostPlayerSpell(effect, magic_effect_info, effect_cost_mult)
    return calcEffectCost(effect, magic_effect_info, effect_cost_mult or 1, "player_spell")
end

function cost_model.calcEffectCostGameSpell(effect, magic_effect_info, effect_cost_mult)
    return calcEffectCost(effect, magic_effect_info, effect_cost_mult or 1, "game_spell")
end

local function hasPostfix(group, opcode)
    for _, op in ipairs(group and group.postfix_ops or {}) do
        if op.opcode == opcode then
            return true, op
        end
    end
    return false, nil
end

local function findPrefix(group, opcode)
    for _, op in ipairs(group and group.prefix_ops or {}) do
        if op.opcode == opcode then
            return op
        end
    end
    return nil
end

local function sourcePostfixOpcode(group)
    if hasPostfix(group, "Trigger") then
        return "Trigger"
    elseif hasPostfix(group, "Timer") then
        return "Timer"
    end
    return nil
end

local function safePositiveInteger(value, fallback)
    local n = tonumber(value)
    if n == nil then
        return fallback
    end
    n = math.floor(n)
    if n < 1 then
        return fallback
    end
    return n
end

local function fanoutCount(group)
    local static = tonumber(group and group.emission_count_static)
    if static ~= nil and static >= 1 then
        return static
    end
    local multicast = findPrefix(group, "Multicast")
    if multicast then
        return safePositiveInteger(multicast.params and multicast.params.count, 1)
    end
    local burst = findPrefix(group, "Burst")
    if burst then
        return safePositiveInteger(burst.params and burst.params.count, 1)
    end
    return 1
end

local function addContributor(state, contributor)
    state.contributors[#state.contributors + 1] = contributor
end

local function realEffectCost(effect, state)
    local id = normalizeId(effect and effect.id)
    if not id or base_effect_catalog.isOperatorEffectId(id) then
        return 0
    end
    local lookup_id = (type(effect and effect.engine_effect_id) == "string" and effect.engine_effect_id ~= "")
        and effect.engine_effect_id
        or id
    local info, lookup_reason = cost_model.resolveMagicEffectInfo(effect, lookup_id, state.opts)
    if lookup_reason then
        state.fallback_cost_count = state.fallback_cost_count + 1
        state.missing_magic_effect_count = state.missing_magic_effect_count + 1
        addWarning(state, "magic_effect_lookup_failed", id .. ":" .. tostring(lookup_reason))
    end
    local cost, calc = cost_model.calcEffectCostPlayerSpell(effect, info, state.effect_cost_mult)
    addContributor(state, {
        kind = "effect",
        label = id,
        effect_id = id,
        cost = cost,
        school = info.school,
        base_cost = info.baseCost,
        lookup_source = info.source,
        calculation = calc,
    })
    if cost > state.dominant_effect_cost then
        state.dominant_effect_cost = cost
        state.dominant_effect_id = id
        state.dominant_school = normalizeSchool(info.school)
    end
    return cost
end

local function sumRealEffects(effects, state)
    local total = 0
    for _, effect in ipairs(effects or {}) do
        total = total + realEffectCost(effect, state)
    end
    return total
end

local function applyPrefixPricing(group, base_cost, state)
    local cost = base_cost
    local count = fanoutCount(group)
    if count > 1 then
        local factor = 1 + (0.55 * (count - 1))
        local before = cost
        cost = cost * factor
        addContributor(state, {
            kind = "operator",
            label = "Fanout x" .. tostring(count),
            opcode = "Multicast",
            cost = cost - before,
            factor = factor,
        })
    end

    local bounce = findPrefix(group, "Bounce")
    if bounce then
        local bounces = safePositiveInteger(bounce.params and bounce.params.bounces, 1)
        local factor = 1 + (0.10 * bounces)
        local before = cost
        cost = cost * factor
        addContributor(state, {
            kind = "operator",
            label = "Bounce x" .. tostring(bounces),
            opcode = "Bounce",
            cost = cost - before,
            factor = factor,
        })
    end

    local pierce = findPrefix(group, "Pierce")
    if pierce then
        local pierces = safePositiveInteger(pierce.params and pierce.params.pierces, 1)
        local factor = 1 + (0.50 * pierces)
        local before = cost
        cost = cost * factor
        addContributor(state, {
            kind = "operator",
            label = "Pierce x" .. tostring(pierces),
            opcode = "Pierce",
            cost = cost - before,
            factor = factor,
        })
    end

    local chain = findPrefix(group, "Chain")
    if chain then
        local hops = safePositiveInteger(chain.params and chain.params.hops, 1)
        local factor = 1 + (0.45 * math.max(0, hops - 1))
        local before = cost
        cost = cost * factor
        addContributor(state, {
            kind = "operator",
            label = "Chain x" .. tostring(hops),
            opcode = "Chain",
            cost = cost - before,
            factor = factor,
        })
    end

    local homing = findPrefix(group, "Homing")
    if homing then
        local mode = string.lower(tostring(homing.params and (homing.params.mode or homing.params.homing_mode) or "hard"))
        local soft = mode == "soft" or homing.params and homing.params.soft == true
        local factor = soft and 1.25 or 1.15
        local before = cost
        cost = cost * factor
        addContributor(state, {
            kind = "operator",
            label = soft and "Soft Homing" or "Hard Homing",
            opcode = "Homing",
            cost = cost - before,
            factor = factor,
        })
    end

    local speed = findPrefix(group, "Speed+")
    local size = findPrefix(group, "Size+")
    local speed_factor = 1
    local size_factor = 1
    if speed then
        speed_factor = 1 + (0.0025 * numberValue(speed.params and speed.params.percent, 0))
    end
    if size then
        size_factor = 1 + (0.004 * numberValue(size.params and size.params.percent, 0))
    end
    if speed or size then
        local factor = speed_factor * size_factor
        if speed and size then
            factor = factor * 1.03
        end
        local before = cost
        cost = cost * factor
        addContributor(state, {
            kind = "operator",
            label = speed and size and "Speed+ Size+" or (speed and "Speed+" or "Size+"),
            opcode = speed and size and "Speed+Size+" or (speed and "Speed+" or "Size+"),
            cost = cost - before,
            factor = factor,
        })
    end

    return cost
end

local estimateGroups

local function payloadGroups(group, state)
    if not group or not group.payload or type(group.payload.effects) ~= "table" or #group.payload.effects == 0 then
        return nil
    end
    local parsed = parser.parseContinuationPayloadEffectList(group.payload.effects, state.opts)
    if parsed.ok ~= true then
        addWarning(state, "payload_parse_failed_for_cost", tostring(group.payload.scope or "payload"))
        addError(state, "cost.payload", "Payload parse failed during cost estimation", "payload_parse_failed_for_cost", {
            recipe_id = state.recipe_id,
            source_opcode = sourcePostfixOpcode(group),
            payload_effect_count = #(group.payload.effects or {}),
            fanout_context = parsed.fanout_context or "continuation_payload",
            allow_non_target_payload_multicast = parsed.allow_non_target_payload_multicast == true,
            parse_errors = parsed.errors,
        })
        log.warn(string.format(
            "SPELLFORGE_COST_PAYLOAD_PARSE_FAILED recipe_id=%s source_opcode=%s payload_effect_count=%s fanout_context=%s allow_non_target_payload_multicast=%s reason=payload_parse_failed_for_cost",
            tostring(state.recipe_id),
            tostring(sourcePostfixOpcode(group)),
            tostring(#(group.payload.effects or {})),
            tostring(parsed.fanout_context or "continuation_payload"),
            tostring(parsed.allow_non_target_payload_multicast == true)
        ))
        return nil
    end
    log.info(string.format(
        "SPELLFORGE_COST_PAYLOAD_PARSE_OK recipe_id=%s source_opcode=%s payload_effect_count=%s payload_group_count=%s fanout_context=%s allow_non_target_payload_multicast=%s",
        tostring(state.recipe_id),
        tostring(sourcePostfixOpcode(group)),
        tostring(#(group.payload.effects or {})),
        tostring(#(parsed.groups or {})),
        tostring(parsed.fanout_context or "continuation_payload"),
        tostring(parsed.allow_non_target_payload_multicast == true)
    ))
    return parsed.groups
end

local function applyPayloadPricing(group, payload_cost, state)
    local cost = payload_cost
    local trigger = hasPostfix(group, "Trigger")
    local timer = hasPostfix(group, "Timer")
    if trigger then
        local before = cost
        cost = cost * 0.80
        addContributor(state, {
            kind = "operator",
            label = "Trigger payload",
            opcode = "Trigger",
            cost = cost - before,
            factor = 0.80,
        })
        local bounce = findPrefix(group, "Bounce")
        if bounce then
            local bounces = safePositiveInteger(bounce.params and bounce.params.bounces, 1)
            local factor = 1 + (0.30 * bounces)
            before = cost
            cost = cost * factor
            addContributor(state, {
                kind = "operator",
                label = "Bounce trigger x" .. tostring(bounces),
                opcode = "BounceTrigger",
                cost = cost - before,
                factor = factor,
            })
        end
    elseif timer then
        local before = cost
        cost = cost * 0.65
        addContributor(state, {
            kind = "operator",
            label = "Timer payload",
            opcode = "Timer",
            cost = cost - before,
            factor = 0.65,
        })
    end
    return cost
end

estimateGroups = function(groups, state, depth)
    if (depth or 0) > 6 then
        addWarning(state, "cost_recursion_depth_exceeded", tostring(depth))
        return 0, 0
    end

    local total = 0
    local vanilla = 0
    for _, group in ipairs(groups or {}) do
        local base = sumRealEffects(group.effects, state)
        vanilla = vanilla + base
        total = total + applyPrefixPricing(group, base, state)

        local children = payloadGroups(group, state)
        if children then
            local payload_total, payload_vanilla = estimateGroups(children, state, (depth or 0) + 1)
            vanilla = vanilla + payload_vanilla
            total = total + applyPayloadPricing(group, payload_total, state)
        end
    end
    return total, vanilla
end

local function pressureFactor(expected_jobs)
    local jobs = tonumber(expected_jobs) or 0
    if jobs <= 32 then
        return 1.00
    elseif jobs <= 64 then
        return 1.10
    elseif jobs <= 96 then
        return 1.20
    end
    return 1.35
end

local function expectedJobs(plan, opts)
    if tonumber(opts and opts.force_expected_jobs) ~= nil then
        return tonumber(opts.force_expected_jobs)
    end
    if tonumber(opts and opts.expected_jobs) ~= nil then
        return tonumber(opts.expected_jobs)
    end

    local ir = plan and plan.runtime_ir
    if type(ir) ~= "table" or ir.ok ~= true then
        local ok, built = pcall(runtime_ir.build, plan or {}, { include_group_snapshots = true })
        if ok and type(built) == "table" and built.ok == true then
            ir = built
        end
    end

    local counts = ir and ir.counts or {}
    local bounds = plan and plan.bounds or {}
    return math.max(
        tonumber(counts.entry_count) or 0,
        tonumber(counts.slot_count) or 0,
        tonumber(plan and plan.helper_spec_count) or 0,
        tonumber(plan and plan.slot_count) or 0,
        tonumber(bounds.static_emission_count) or 0,
        1
    )
end

local function tierFor(cost)
    local c = tonumber(cost) or 0
    if c <= 20 then
        return "Low"
    elseif c <= 50 then
        return "Moderate"
    elseif c <= 100 then
        return "High"
    elseif c <= 200 then
        return "Very High"
    end
    return "Extreme"
end

local function roundCost(cost)
    return math.max(PUBLIC_MINIMUM_COST, math.ceil(math.max(0, tonumber(cost) or 0)))
end

local function hashString(text)
    local hash = 5381
    for i = 1, #text do
        hash = (hash * 33 + string.byte(text, i)) % 4294967296
    end
    return string.format("%08x", hash)
end

local function costHash(result, contributors)
    local parts = {
        tostring(cost_model.VERSION),
        tostring(result.recipe_id),
        tostring(result.estimated_mana_cost),
        tostring(result.vanilla_base_cost),
        tostring(result.spellforge_modifier_cost),
        tostring(result.runtime_pressure_cost),
        tostring(result.dominant_effect_id),
        tostring(result.dominant_school),
    }
    for _, contributor in ipairs(contributors or {}) do
        parts[#parts + 1] = table.concat({
            tostring(contributor.kind),
            tostring(contributor.effect_id or contributor.opcode or contributor.label),
            string.format("%.4f", tonumber(contributor.cost) or 0),
            tostring(contributor.base_cost or ""),
        }, ":")
    end
    return hashString(table.concat(parts, "|"))
end

function cost_model.estimate(plan_or_ir, opts)
    local plan = plan_or_ir or {}
    local state = {
        opts = opts or {},
        recipe_id = plan.recipe_id,
        errors = {},
        warnings = {},
        contributors = {},
        fallback_cost_count = 0,
        missing_magic_effect_count = 0,
        dominant_effect_cost = -1,
        dominant_effect_id = nil,
        dominant_school = "Unknown",
    }
    state.effect_cost_mult = effectCostMult(state, opts or {})

    local groups = plan.groups
    if type(groups) ~= "table" and type(plan.entries) == "table" then
        addWarning(state, "cost_model_ir_without_groups", "falling back to IR entries")
        groups = {
            {
                effects = plan.entries[1] and plan.entries[1].effects or {},
                prefix_ops = plan.entries[1] and plan.entries[1].prefix_ops or {},
                postfix_ops = plan.entries[1] and plan.entries[1].postfix_ops or {},
                emission_count_static = plan.counts and plan.counts.primary_emit_count or 1,
            },
        }
    end

    local pre_pressure_total, vanilla_base_cost = estimateGroups(groups or {}, state, 0)
    if #state.errors > 0 then
        local result = {
            ok = false,
            success = false,
            version = cost_model.VERSION,
            recipe_id = plan.recipe_id,
            error = "payload_parse_failed_for_cost",
            errors = validation.cloneIssues(state.errors, "error"),
            warnings = cloneIssues(state.warnings),
            fallback_cost_count = state.fallback_cost_count,
            missing_magic_effect_count = state.missing_magic_effect_count,
        }
        log.warn(string.format(
            "SPELLFORGE_COST_MODEL_FAIL_CLOSED recipe_id=%s reason=payload_parse_failed_for_cost error_count=%s",
            tostring(result.recipe_id),
            tostring(#(result.errors or {}))
        ))
        return result
    end
    local jobs = expectedJobs(plan, opts or {})
    local pressure = pressureFactor(jobs)
    local total_cost = pre_pressure_total * pressure
    local rounded = roundCost(total_cost)
    local result = {
        ok = true,
        version = cost_model.VERSION,
        recipe_id = plan.recipe_id,
        estimated_mana_cost = rounded,
        total_cost = total_cost,
        vanilla_base_cost = vanilla_base_cost,
        spellforge_modifier_cost = pre_pressure_total - vanilla_base_cost,
        runtime_pressure_cost = total_cost - pre_pressure_total,
        dominant_school = state.dominant_school or "Unknown",
        dominant_effect_id = state.dominant_effect_id,
        tier = tierFor(rounded),
        breakdown = {
            calculation_mode = "player_spell",
            note = "v0 uses PlayerSpell-style effect duration handling for UI-created Spellforge spells.",
            fEffectCostMult = state.effect_cost_mult,
            expected_jobs = jobs,
            runtime_pressure_factor = pressure,
            pre_pressure_total = pre_pressure_total,
            contributors = state.contributors,
        },
        warnings = cloneIssues(state.warnings),
        fallback_cost_count = state.fallback_cost_count,
        missing_magic_effect_count = state.missing_magic_effect_count,
    }
    local hash = costHash(result, state.contributors)
    result.cost_model_hash = hash
    result.cost_breakdown_hash = hash

    for _, warning in ipairs(result.warnings or {}) do
        log.warn(string.format(
            "SPELLFORGE_COST_MODEL_WARNING recipe_id=%s reason=%s",
            tostring(result.recipe_id),
            tostring(warning.reason or warning.code or warning)
        ))
    end
    if rounded >= 201 then
        log.warn(string.format(
            "SPELLFORGE_COST_MODEL_WARNING recipe_id=%s reason=extreme_cost",
            tostring(result.recipe_id)
        ))
    end
    log.info(string.format(
        "SPELLFORGE_COST_MODEL_OK recipe_id=%s cost=%s school=%s tier=%s",
        tostring(result.recipe_id),
        tostring(result.estimated_mana_cost),
        tostring(result.dominant_school),
        tostring(result.tier)
    ))
    return result
end

function cost_model.cacheMatches(entry, estimate)
    if type(entry) ~= "table" or type(estimate) ~= "table" then
        return false
    end
    if entry.cost_model_version ~= cost_model.VERSION then
        return false
    end
    if tonumber(entry.compiled_cost) ~= tonumber(estimate.estimated_mana_cost) then
        return false
    end
    if entry.cost_model_hash ~= nil and estimate.cost_model_hash ~= nil and entry.cost_model_hash ~= estimate.cost_model_hash then
        return false
    end
    return true
end

return cost_model
