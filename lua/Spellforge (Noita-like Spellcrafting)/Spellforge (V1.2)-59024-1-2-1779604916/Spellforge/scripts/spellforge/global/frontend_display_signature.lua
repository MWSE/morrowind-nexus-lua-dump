local opcodes = require("scripts.spellforge.shared.opcodes")
local base_effect_display = require("scripts.spellforge.shared.base_effect_display")
local operator_params = require("scripts.spellforge.shared.operator_params")
local log = require("scripts.spellforge.shared.log").new("global.frontend_display_signature")

local frontend_display_signature = {}

frontend_display_signature.VERSION = "spellforge-frontend-display-signature-v4-effect-params"
frontend_display_signature.MAX_FRONTEND_DISPLAY_EFFECTS = 8

local OPERATOR_DISPLAY_EFFECT_IDS = {
    Multicast = "spellforge_display_multicast",
    Spread = "spellforge_display_spread",
    Burst = "spellforge_display_burst",
    ["Speed+"] = "spellforge_display_speed_plus",
    ["Size+"] = "spellforge_display_size_plus",
    Chain = "spellforge_display_chain",
    Bounce = "spellforge_display_bounce",
    Pierce = "spellforge_display_pierce",
    Homing = "spellforge_display_homing",
    Detonate = "spellforge_display_detonate",
    Trigger = "spellforge_display_trigger",
    Timer = "spellforge_display_timer",
}

local MODIFIER_ICON_BASE = "icons/spellforge/modifiers/"
local MODIFIER_BIG_ICON_PATTERN = "icons/spellforge/modifiers/b_*.dds"
local display_icon_paths_audit_logged = false

local function bigIconPathFor(icon)
    if type(icon) ~= "string" or icon == "" then
        return nil
    end
    local prefix, filename = string.match(icon, "^(.*[/\\])([^/\\]+)$")
    local name = filename or icon
    name = string.gsub(name, "%.[^%.]+$", "")
    return (prefix or MODIFIER_ICON_BASE) .. "b_" .. name .. ".dds"
end

local function auditDisplayIconPaths()
    if display_icon_paths_audit_logged then
        return
    end
    display_icon_paths_audit_logged = true

    local small_count = 0
    local big_count = 0
    local big_missing = 0
    for opcode, def in pairs(opcodes or {}) do
        if type(def) == "table" and def.kind ~= nil then
            local icon = def.icon
            local big_icon = def.large_icon or bigIconPathFor(icon)
            if type(icon) == "string" and icon ~= "" then
                small_count = small_count + 1
            end
            if type(big_icon) == "string" and big_icon ~= "" then
                big_count = big_count + 1
            else
                big_missing = big_missing + 1
                log.warn(string.format(
                    "SPELLFORGE_FRONTEND_DISPLAY_BIG_ICON_MISSING opcode=%s small_path=%s large_path=%s",
                    tostring(opcode),
                    tostring(icon),
                    tostring(big_icon)
                ))
            end
        end
    end

    log.info(string.format(
        "SPELLFORGE_FRONTEND_DISPLAY_ICON_PATHS_OK small_count=%s big_count=%s missing_big=%s big_prefix=%s",
        tostring(small_count),
        tostring(big_count),
        tostring(big_missing),
        MODIFIER_BIG_ICON_PATTERN
    ))
end

local function normalizedInteger(value)
    local n = tonumber(value)
    if not n then
        return nil
    end
    local rounded = math.floor(n + 0.5)
    if math.abs(n - rounded) > 0.001 then
        return nil
    end
    return rounded
end

local function numberSuffix(value)
    local n = tonumber(value)
    if not n then
        return nil
    end
    local text = tostring(n)
    text = string.gsub(text, "%.", "_")
    text = string.gsub(text, "%-", "neg_")
    return text
end

local function timerSuffix(value)
    local n = tonumber(value)
    if not n then
        return nil
    end
    local doubled = n * 2
    local rounded = math.floor(doubled + 0.5)
    if math.abs(doubled - rounded) > 0.001 then
        return nil
    end
    return numberSuffix(rounded / 2)
end

local function operatorMarkerId(effect, opcode)
    local params = operator_params.paramsForEffect(effect, opcode)
    if opcode == "Multicast" then
        local count = normalizedInteger(params.count)
        local max_count = opcodes.Multicast
            and opcodes.Multicast.parameters
            and opcodes.Multicast.parameters.count
            and opcodes.Multicast.parameters.count.max
            or 8
        if count and count >= 2 and count <= max_count then
            return "spellforge_display_multicast_x" .. tostring(count)
        end
    elseif opcode == "Timer" then
        local suffix = timerSuffix(params.seconds)
        if suffix then
            return "spellforge_display_timer_" .. suffix .. "s"
        end
    elseif opcode == "Chain" then
        local hops = normalizedInteger(params.hops)
        if hops and hops >= 1 and hops <= 5 then
            return "spellforge_display_chain_" .. tostring(hops)
        end
    elseif opcode == "Bounce" then
        local bounces = normalizedInteger(params.bounces)
        if bounces and bounces >= 1 and bounces <= 12 then
            return "spellforge_display_bounce_" .. tostring(bounces)
        end
    elseif opcode == "Pierce" then
        local pierces = normalizedInteger(params.pierces)
        if pierces and pierces >= 1 and pierces <= 5 then
            return "spellforge_display_pierce_" .. tostring(pierces)
        end
    elseif opcode == "Speed+" then
        local percent = normalizedInteger(params.percent)
        if percent and percent >= -90 and percent <= 400 then
            return "spellforge_display_speed_plus_" .. tostring(numberSuffix(percent)) .. "p"
        end
    elseif opcode == "Size+" then
        local percent = normalizedInteger(params.percent)
        if percent and percent >= -90 and percent <= 300 then
            return "spellforge_display_size_plus_" .. tostring(numberSuffix(percent)) .. "p"
        end
    elseif opcode == "Spread" then
        local preset = normalizedInteger(params.preset)
        if preset and preset >= 1 and preset <= 4 then
            return "spellforge_display_spread_preset_" .. tostring(preset)
        end
    end
    return OPERATOR_DISPLAY_EFFECT_IDS[opcode]
end

local SCHOOL_MARKERS = {
    destruction = "spellforge_marker_destruction",
    restoration = "spellforge_marker_restoration",
    alteration = "spellforge_marker_alteration",
    illusion = "spellforge_marker_illusion",
    mysticism = "spellforge_marker_mysticism",
    conjuration = "spellforge_marker_conjuration",
    unknown = "spellforge_marker_unknown",
}

local function normalizeSchool(value)
    if value == nil then
        return "unknown"
    end
    local text = string.lower(tostring(value))
    text = string.gsub(text, "%s+", "")
    if text == "" then
        return "unknown"
    end
    if text == "destruction" then
        return "destruction"
    elseif text == "restoration" then
        return "restoration"
    elseif text == "alteration" then
        return "alteration"
    elseif text == "illusion" then
        return "illusion"
    elseif text == "mysticism" then
        return "mysticism"
    elseif text == "conjuration" then
        return "conjuration"
    end
    return "unknown"
end

local function schoolMarkerEffectIdForSchool(school)
    return SCHOOL_MARKERS[normalizeSchool(school)] or SCHOOL_MARKERS.unknown
end

local function cloneEffect(effect)
    return {
        id = effect.id,
        range = effect.range,
        area = effect.area or 0,
        duration = effect.duration or 0,
        magnitudeMin = effect.magnitudeMin or 0,
        magnitudeMax = effect.magnitudeMax or 0,
        affectedAttribute = effect.affectedAttribute,
        affectedSkill = effect.affectedSkill,
    }
end

local function markerEffect(effect_id, marker_range)
    return {
        id = effect_id,
        range = marker_range or 0,
        area = 0,
        duration = 0,
        magnitudeMin = 0,
        magnitudeMax = 0,
    }
end

local function schoolQualifiedDisplayEffectId(effect_id, school)
    local normalized = normalizeSchool(school)
    if normalized == "unknown" or effect_id == nil then
        return effect_id
    end
    return tostring(effect_id) .. "_" .. normalized
end

local function presentationQualifiedDisplayEffectId(effect_id, presentation_effect_id, school)
    local normalized = base_effect_display.normalizeId(presentation_effect_id)
    if normalized then
        return tostring(effect_id) .. "_" .. normalized
    end
    return schoolQualifiedDisplayEffectId(effect_id, school)
end

local function baseDisplayEffect(effect_id, source_effect, marker_range)
    return {
        id = effect_id,
        range = source_effect and source_effect.range or marker_range or 0,
        area = source_effect and source_effect.area or 0,
        duration = source_effect and source_effect.duration or 0,
        magnitudeMin = source_effect and source_effect.magnitudeMin or 0,
        magnitudeMax = source_effect and source_effect.magnitudeMax or 0,
        affectedAttribute = source_effect and source_effect.affectedAttribute or nil,
        affectedSkill = source_effect and source_effect.affectedSkill or nil,
    }
end

local function hashString(value)
    local hash = 5381
    local text = tostring(value or "")
    for i = 1, #text do
        hash = ((hash * 33) + string.byte(text, i)) % 2147483647
    end
    return string.format("%08x", hash)
end

local function appendEffect(out, effect_ids, effect)
    local cloned = cloneEffect(effect)
    out[#out + 1] = cloned
    effect_ids[#effect_ids + 1] = cloned.id
end

local function collectRecipeComponents(effects)
    local components = {}
    for index, effect in ipairs(effects or {}) do
        local opcode = operator_params.opcodeForEffect(effect)
        if opcode then
            local marker_id = operatorMarkerId(effect, opcode)
            if marker_id then
                local def = opcodes[opcode] or {}
                components[#components + 1] = {
                    kind = "operator",
                    opcode = opcode,
                    marker_id = marker_id,
                    icon = def.icon,
                    large_icon = def.large_icon or bigIconPathFor(def.icon),
                    first_index = index,
                }
            end
        else
            local proxy_id = base_effect_display.proxyEffectIdForEffect(effect)
            local presentation_effect_id = effect.id
            if not proxy_id then
                proxy_id = schoolMarkerEffectIdForSchool(effect and effect.school)
                presentation_effect_id = nil
            end
            if proxy_id then
                components[#components + 1] = {
                    kind = "base_effect",
                    effect_id = presentation_effect_id,
                    marker_id = proxy_id,
                    source_effect = effect,
                    first_index = index,
                }
            end
        end
    end
    return components
end

local function firstBasePresentationEffectId(components)
    for _, component in ipairs(components or {}) do
        if component.kind == "base_effect" and component.effect_id ~= nil then
            return component.effect_id
        end
    end
    return nil
end

local function buildHashInput(effects, icon_paths, dominant_school)
    local effect_parts = {}
    for i, effect in ipairs(effects or {}) do
        effect_parts[i] = table.concat({
            tostring(effect.id),
            tostring(effect.range),
            tostring(effect.area),
            tostring(effect.duration),
            tostring(effect.magnitudeMin),
            tostring(effect.magnitudeMax),
            tostring(effect.affectedAttribute),
            tostring(effect.affectedSkill),
        }, ":")
    end
    return table.concat({
        frontend_display_signature.VERSION,
        tostring(dominant_school or "unknown"),
        table.concat(effect_parts, ","),
        table.concat(icon_paths or {}, ","),
    }, "|")
end

local function effectsText(effect_ids)
    return table.concat(effect_ids or {}, ",")
end

local function recipeId(input)
    return tostring((input and input.recipe_id) or "unknown")
end

local function logFirstDisplayIcon(input, effect_ids, components, include_school_marker, icon_paths, large_icon_paths)
    local first_effect = effect_ids and effect_ids[1] or nil
    local first_component = components and components[1] or nil
    local first_kind = "fallback_marker"
    local opcode = nil
    local icon_path = nil
    local large_icon_path = nil

    if not include_school_marker and first_component then
        first_kind = first_component.kind or "component"
        opcode = first_component.opcode
        if first_component.kind == "operator" then
            icon_path = first_component.icon
            large_icon_path = first_component.large_icon
        elseif first_component.kind == "base_effect" then
            icon_path = icon_paths and icon_paths[1] or nil
            large_icon_path = large_icon_paths and large_icon_paths[1] or nil
        end
    end

    if first_component and first_component.kind == "operator" then
        if not (type(icon_path) == "string" and icon_path ~= "") then
            log.warn(string.format(
                "SPELLFORGE_FRONTEND_DISPLAY_FIRST_ICON_MISSING recipe_id=%s opcode=%s effect_id=%s icon_path=%s large_icon_path=%s",
                recipeId(input),
                tostring(opcode),
                tostring(first_effect),
                tostring(icon_path),
                tostring(large_icon_path)
            ))
        elseif not (type(large_icon_path) == "string" and large_icon_path ~= "") then
            log.warn(string.format(
                "SPELLFORGE_FRONTEND_DISPLAY_FIRST_BIG_ICON_MISSING recipe_id=%s opcode=%s effect_id=%s icon_path=%s large_icon_path=%s",
                recipeId(input),
                tostring(opcode),
                tostring(first_effect),
                tostring(icon_path),
                tostring(large_icon_path)
            ))
        end
    end

    log.info(string.format(
        "SPELLFORGE_FRONTEND_DISPLAY_FIRST_ICON_OK recipe_id=%s first_effect=%s first_kind=%s opcode=%s icon_path=%s large_icon_path=%s fallback_marker=%s",
        recipeId(input),
        tostring(first_effect),
        tostring(first_kind),
        tostring(opcode),
        tostring(icon_path),
        tostring(large_icon_path),
        tostring(include_school_marker)
    ))
end

local function logCastPresentation(input, presentation_effect_id, display_effect_ids)
    local recipe_id = recipeId(input)
    if presentation_effect_id ~= nil then
        log.info(string.format(
            "SPELLFORGE_FRONTEND_CAST_PRESENTATION_OK recipe_id=%s presentation_effect_id=%s source=base_effect display_effects=%s",
            recipe_id,
            tostring(presentation_effect_id),
            effectsText(display_effect_ids)
        ))
    else
        log.info(string.format(
            "SPELLFORGE_FRONTEND_CAST_PRESENTATION_FALLBACK recipe_id=%s presentation_effect_id=nil source=none display_effects=%s",
            recipe_id,
            effectsText(display_effect_ids)
        ))
    end
end

local function logDisplayEffectPresentation(input, display_effect_id, component, presentation_effect_id)
    log.info(string.format(
        "SPELLFORGE_FRONTEND_DISPLAY_EFFECT_PRESENTATION_OK recipe_id=%s display_effect_id=%s opcode=%s presentation_effect_id=%s source=%s",
        recipeId(input),
        tostring(display_effect_id),
        tostring(component and component.opcode),
        tostring(presentation_effect_id),
        presentation_effect_id ~= nil and "base_effect" or "none"
    ))
end

function frontend_display_signature.operatorDisplayEffectId(opcode)
    return OPERATOR_DISPLAY_EFFECT_IDS[opcode]
end

function frontend_display_signature.operatorIconPath(opcode)
    local def = opcodes[opcode] or {}
    return def.icon
end

function frontend_display_signature.operatorBigIconPath(opcode)
    local def = opcodes[opcode] or {}
    return def.large_icon or bigIconPathFor(def.icon)
end

function frontend_display_signature.isDisplayMarkerEffectId(effect_id)
    local id = tostring(effect_id or "")
    if id == "spellforge_display_more" then
        return true
    end
    for _, marker_id in pairs(OPERATOR_DISPLAY_EFFECT_IDS) do
        if marker_id == id then
            return true
        end
    end
    for _, marker_id in pairs(SCHOOL_MARKERS) do
        if marker_id == id then
            return true
        end
    end
    return string.sub(id, 1, 19) == "spellforge_display_"
end

function frontend_display_signature.schoolMarkerEffectId(school)
    return schoolMarkerEffectIdForSchool(school)
end

function frontend_display_signature.build(input, opts)
    auditDisplayIconPaths()

    local options = opts or {}
    local max_effects = tonumber(options.max_effects) or frontend_display_signature.MAX_FRONTEND_DISPLAY_EFFECTS
    if max_effects < 2 then
        max_effects = 2
    end

    local cost = input and input.cost_model or {}
    local dominant_school = cost.dominant_school or options.dominant_school or "Unknown"
    local marker_range = input and input.marker_range or options.marker_range or 0
    local effects = {}
    local effect_ids = {}
    local icon_paths = {}
    local large_icon_paths = {}

    local components = collectRecipeComponents(input and input.effects)
    local presentation_effect_id = firstBasePresentationEffectId(components)
    local include_school_marker = #components == 0
    if include_school_marker then
        appendEffect(effects, effect_ids, markerEffect(frontend_display_signature.schoolMarkerEffectId(dominant_school), marker_range))
    end

    local fixed_count = include_school_marker and 1 or 0
    local total_displayable = fixed_count + #components
    local capped = total_displayable > max_effects
    local component_slots = max_effects - fixed_count
    if capped then
        component_slots = math.max(0, max_effects - fixed_count - 1)
    end

    for i = 1, math.min(component_slots, #components) do
        local component = components[i]
        local display_effect_id = nil
        if component.kind == "base_effect" then
            display_effect_id = component.marker_id
            appendEffect(effects, effect_ids, baseDisplayEffect(display_effect_id, component.source_effect, marker_range))
        else
            display_effect_id = presentationQualifiedDisplayEffectId(component.marker_id, presentation_effect_id, dominant_school)
            appendEffect(effects, effect_ids, markerEffect(display_effect_id, marker_range))
        end
        logDisplayEffectPresentation(input, display_effect_id, component, presentation_effect_id)
        if type(component.icon) == "string" and component.icon ~= "" then
            icon_paths[#icon_paths + 1] = component.icon
        end
        if type(component.large_icon) == "string" and component.large_icon ~= "" then
            large_icon_paths[#large_icon_paths + 1] = component.large_icon
        end
    end

    if capped then
        appendEffect(effects, effect_ids, markerEffect(
            presentationQualifiedDisplayEffectId("spellforge_display_more", presentation_effect_id, dominant_school),
            marker_range
        ))
    end
    logFirstDisplayIcon(input, effect_ids, components, include_school_marker, icon_paths, large_icon_paths)
    logCastPresentation(input, presentation_effect_id, effect_ids)

    local hash = hashString(buildHashInput(effects, icon_paths, dominant_school))
    local result = {
        ok = true,
        version = frontend_display_signature.VERSION,
        recipe_id = input and input.recipe_id or nil,
        effects = effects,
        effect_ids = effect_ids,
        icon_paths = icon_paths,
        large_icon_paths = large_icon_paths,
        hash = hash,
        dominant_school = dominant_school,
        presentation_effect_id = presentation_effect_id,
        total_displayable_count = total_displayable,
        visible_count = #effects,
        capped = capped,
    }

    if capped then
        log.info(string.format(
            "SPELLFORGE_FRONTEND_DISPLAY_SIGNATURE_CAPPED recipe_id=%s visible=%s total=%s",
            recipeId(input),
            tostring(#effects),
            tostring(total_displayable)
        ))
    end
    log.info(string.format(
        "SPELLFORGE_FRONTEND_DISPLAY_SIGNATURE_OK recipe_id=%s count=%s hash=%s",
        recipeId(input),
        tostring(#effects),
        tostring(hash)
    ))

    return result
end

function frontend_display_signature.cacheMatches(entry, signature)
    if type(entry) ~= "table" or type(signature) ~= "table" then
        return false
    end
    return entry.frontend_display_signature_version == frontend_display_signature.VERSION
        and entry.frontend_display_hash == signature.hash
end

function frontend_display_signature.cacheMismatchReason(entry, signature)
    if type(entry) ~= "table" then
        return "missing_cache"
    end
    if entry.frontend_display_signature_version ~= frontend_display_signature.VERSION then
        return "display_signature_version"
    end
    if not signature or entry.frontend_display_hash ~= signature.hash then
        return "display_signature_hash"
    end
    return nil
end

function frontend_display_signature.effectsText(signature)
    return effectsText(signature and signature.effect_ids)
end

return frontend_display_signature
