-- Pattern reference: Trap Handling's load-context custom effect registration (adapted).

local content = require('openmw.content')
local base_effect_display = require("scripts.spellforge.shared.base_effect_display")
local limits = require("scripts.spellforge.shared.limits")

-- Inert shell marker resources:
-- - shell spells must still follow vanilla cast flow/text keys
-- - visuals/audio should be inert; real payload is launched later through SFP.
local static_records = content.statics and content.statics.records
if static_records then
    static_records.spellforge_invisible_static = {
        model = "meshes/spellforge/invisible_marker.nif",
    }
end

local sound_records = (content.sounds and content.sounds.records)
if sound_records then
    sound_records.spellforge_silence = {
        fileName = "sound/spellforge/silence.wav",
        volume = 0,
        minRange = 0,
        maxRange = 0,
    }
end
-- TODO(2.2b hardening): confirm load-context record table names for all supported
-- OpenMW versions in use; if unavailable, marker effect falls back to nil shell
-- VFX/SFX fields rather than crashing load-context.

content.magicEffects.records.spellforge_marker_target = {
    name = "Spellforge Target Marker",
    school = "alteration",
    description = "Internal target shell marker. Spellforge launches real payload after cast success authorization.",
    baseCost = 0,
    hasMagnitude = false,
    hasArea = false,
    hasDuration = false,
    harmful = false,
    allowsEnchanting = false,
    allowsSpellmaking = false,
    -- Keep normal vanilla cast/fizzle feedback on hands/animation.
    -- Inert only the placeholder projectile path (bolt/hit/area) for shell casts.
    hitStatic = static_records and "spellforge_invisible_static" or nil,
    areaStatic = static_records and "spellforge_invisible_static" or nil,
    bolt = static_records and "spellforge_invisible_static" or nil,
    hitSound = sound_records and "spellforge_silence" or nil,
    areaSound = sound_records and "spellforge_silence" or nil,
    boltSound = sound_records and "spellforge_silence" or nil,
}

local fire_reference = content.magicEffects.records.fireDamage
local destruction_marker_school = fire_reference and fire_reference.school or "destruction"
local destruction_cast_static = fire_reference and fire_reference.castStatic or nil
local destruction_cast_sound = fire_reference and fire_reference.castSound or nil
local destruction_particle = fire_reference and fire_reference.particle or nil

local function isUsableIconPath(icon_value)
    if type(icon_value) ~= "string" then
        return false
    end
    local normalized = string.lower(icon_value)
    if normalized == "" or normalized == "icons/" or normalized == "icons/b_" then
        return false
    end
    if string.sub(normalized, 1, 6) ~= "icons/" then
        return false
    end
    return #normalized > 8
end

local function resolveDestructionMarkerIcon()
    local fire_icon = fire_reference and fire_reference.icon or nil
    if isUsableIconPath(fire_icon) then
        return fire_icon
    end

    for _, record in pairs(content.magicEffects.records or {}) do
        local school = record and record.school
        local icon = record and record.icon
        if school == destruction_marker_school and isUsableIconPath(icon) then
            return icon
        end
    end

    local open_reference = content.magicEffects.records.open
    local open_icon = open_reference and open_reference.icon or nil
    if isUsableIconPath(open_icon) then
        return open_icon
    end

    -- TODO(2.2b hardening): if no usable icon can be resolved from runtime records,
    -- add a bundled Spellforge icon asset and reference it explicitly here.
    return nil
end

local destruction_marker_icon = resolveDestructionMarkerIcon()

content.magicEffects.records.spellforge_marker_target_destruction = {
    name = "Spellforge Target Marker (Destruction)",
    school = destruction_marker_school,
    description = "Internal target shell marker using manual fire/destruction cast presentation. Real projectile/hit behavior is SFP-dispatched.",
    baseCost = 0,
    hasMagnitude = false,
    hasArea = false,
    hasDuration = false,
    harmful = false,
    allowsEnchanting = false,
    allowsSpellmaking = false,
    -- Safety rule: do not use template cloning (see LESSONS.md Open Lock incident).
    -- Only borrow known-safe presentation flavor from fire/destruction reference.
    icon = destruction_marker_icon,
    castStatic = destruction_cast_static,
    castSound = destruction_cast_sound,
    particle = destruction_particle,
    -- Always inert/silent for vanilla placeholder projectile path.
    hitStatic = static_records and "spellforge_invisible_static" or nil,
    areaStatic = static_records and "spellforge_invisible_static" or nil,
    bolt = static_records and "spellforge_invisible_static" or nil,
    hitSound = sound_records and "spellforge_silence" or nil,
    areaSound = sound_records and "spellforge_silence" or nil,
    boltSound = sound_records and "spellforge_silence" or nil,
}

local function firstSchoolIcon(school)
    for _, record in pairs(content.magicEffects.records or {}) do
        if record and record.school == school and isUsableIconPath(record.icon) then
            return record.icon
        end
    end
    return nil
end

local function compactId(value)
    if value == nil then
        return nil
    end
    local text = string.lower(tostring(value))
    text = string.gsub(text, "%s+", "")
    text = string.gsub(text, "_+", "")
    if text == "" then
        return nil
    end
    return text
end

local function resolveMagicEffectRecord(effect_id)
    local records = content.magicEffects.records or {}
    local normalized = compactId(effect_id)
    if not normalized then
        return nil
    end

    local direct = records[effect_id] or records[normalized]
    if direct then
        return direct
    end

    for key, record in pairs(records) do
        if compactId(key) == normalized or compactId(record and record.id) == normalized then
            return record
        end
    end
    return nil
end

local CAST_PRESENTATION_FIELDS = {
    "castStatic",
    "castSound",
    "particle",
}
local CAST_PRESENTATION_CACHE = {}

local function castPresentationFromEffect(effect_id)
    local normalized = compactId(effect_id)
    if not normalized then
        return nil
    end
    if CAST_PRESENTATION_CACHE[normalized] ~= nil then
        return CAST_PRESENTATION_CACHE[normalized] or nil
    end

    local source = resolveMagicEffectRecord(effect_id)
    if not source then
        CAST_PRESENTATION_CACHE[normalized] = false
        return nil
    end

    local presentation = {}
    local has_field = false
    for _, field in ipairs(CAST_PRESENTATION_FIELDS) do
        if source[field] ~= nil then
            presentation[field] = source[field]
            has_field = true
        end
    end
    if has_field then
        CAST_PRESENTATION_CACHE[normalized] = presentation
        return presentation
    end
    CAST_PRESENTATION_CACHE[normalized] = false
    return nil
end

local function copyCastPresentation(fields, presentation)
    if type(fields) ~= "table" or type(presentation) ~= "table" then
        return
    end
    for _, field in ipairs(CAST_PRESENTATION_FIELDS) do
        if presentation[field] ~= nil then
            fields[field] = presentation[field]
        end
    end
end

local function inertMarkerFields(name, school, description, icon)
    return {
        name = name,
        school = school or "alteration",
        description = description,
        icon = icon,
        baseCost = 0,
        hasMagnitude = false,
        hasArea = false,
        hasDuration = false,
        harmful = false,
        allowsEnchanting = false,
        allowsSpellmaking = false,
        hitStatic = static_records and "spellforge_invisible_static" or nil,
        areaStatic = static_records and "spellforge_invisible_static" or nil,
        bolt = static_records and "spellforge_invisible_static" or nil,
        hitSound = sound_records and "spellforge_silence" or nil,
        areaSound = sound_records and "spellforge_silence" or nil,
        boltSound = sound_records and "spellforge_silence" or nil,
    }
end

local function nonEmptyText(value)
    if type(value) ~= "string" then
        return nil
    end
    if value == "" then
        return nil
    end
    return value
end

local function registerSchoolMarker(id, name, school, icon, presentation)
    local fields = inertMarkerFields(
        name,
        school,
        "Internal Spellforge display marker. Runtime payload resolution is handled by Spellforge executor.",
        icon
    )
    for key, value in pairs(presentation or {}) do
        fields[key] = value
    end
    content.magicEffects.records[id] = fields
end

registerSchoolMarker("spellforge_marker_destruction", "Spellforge Destruction", destruction_marker_school, destruction_marker_icon, {
    castStatic = destruction_cast_static,
    castSound = destruction_cast_sound,
    particle = destruction_particle,
})
registerSchoolMarker("spellforge_marker_restoration", "Spellforge Restoration", "restoration", firstSchoolIcon("restoration"))
registerSchoolMarker("spellforge_marker_alteration", "Spellforge Alteration", "alteration", firstSchoolIcon("alteration"))
registerSchoolMarker("spellforge_marker_illusion", "Spellforge Illusion", "illusion", firstSchoolIcon("illusion"))
registerSchoolMarker("spellforge_marker_mysticism", "Spellforge Mysticism", "mysticism", firstSchoolIcon("mysticism"))
registerSchoolMarker("spellforge_marker_conjuration", "Spellforge Conjuration", "conjuration", firstSchoolIcon("conjuration"))
registerSchoolMarker("spellforge_marker_unknown", "Spellforge", "alteration", firstSchoolIcon("alteration"))

local registered_base_display_proxies = {}

local function registerBaseDisplayEffect(entry, opts)
    if not entry or not entry.proxy_id then
        return
    end
    local options = opts or {}
    if registered_base_display_proxies[entry.proxy_id] and options.allow_overwrite ~= true then
        return
    end
    local source = resolveMagicEffectRecord(entry.id)
    local icon = source and source.icon or nil
    if not isUsableIconPath(icon) then
        icon = firstSchoolIcon((source and source.school) or entry.school)
    end
    local display_name = nonEmptyText(entry.display_name)
        or nonEmptyText(entry.name)
        or nonEmptyText(source and source.name)
        or tostring(entry.id or entry.proxy_id)
    local fields = inertMarkerFields(
        display_name,
        (source and source.school) or entry.school or "alteration",
        "Display-only Spellforge base-effect marker. It is not used as a runtime effect.",
        icon
    )
    -- These proxies are only vanilla-visible labels. They keep baseCost zero so
    -- copied display magnitude/duration/area does not become an extra mana cost.
    fields.baseCost = 0
    fields.hasMagnitude = source and source.hasMagnitude
    if fields.hasMagnitude == nil then
        fields.hasMagnitude = true
    end
    fields.hasDuration = source and source.hasDuration
    if fields.hasDuration == nil then
        fields.hasDuration = true
    end
    fields.hasArea = source and source.hasArea
    if fields.hasArea == nil then
        fields.hasArea = true
    end
    copyCastPresentation(fields, castPresentationFromEffect(entry.id))
    content.magicEffects.records[entry.proxy_id] = fields
    registered_base_display_proxies[entry.proxy_id] = true
end

for _, entry in ipairs(base_effect_display.all()) do
    registerBaseDisplayEffect(entry)
end

local dynamic_display_entries = {}
for key, record in pairs(content.magicEffects.records or {}) do
    local id = base_effect_display.normalizeId((record and record.id) or key)
    if id
        and string.sub(id, 1, 11) ~= "spellforge_"
        and record
        and record.allowsSpellmaking == true then
        local display = base_effect_display.get(id)
        dynamic_display_entries[#dynamic_display_entries + 1] = {
            id = id,
            display_name = nonEmptyText(record.name)
                or nonEmptyText(display and display.display_name)
                or tostring(key),
            school = record.school,
            proxy_id = "spellforge_display_base_" .. id,
        }
    end
end
for _, entry in ipairs(dynamic_display_entries) do
    registerBaseDisplayEffect(entry)
end

local MODIFIER_ICON_BASE = "icons/spellforge/modifiers/"
local DISPLAY_SCHOOLS = {
    "destruction",
    "restoration",
    "alteration",
    "illusion",
    "mysticism",
    "conjuration",
}

local function registerModifierRecord(id, name, school, filename, presentation_effect_id)
    local fields = inertMarkerFields(
        name,
        school,
        "Display-only Spellforge modifier marker. It is not used as a runtime effect.",
        MODIFIER_ICON_BASE .. filename
    )
    copyCastPresentation(fields, castPresentationFromEffect(presentation_effect_id))
    content.magicEffects.records[id] = fields
end

local function registerModifierDisplayEffect(id, name, filename)
    registerModifierRecord(id, name, "alteration", filename)
    for _, school in ipairs(DISPLAY_SCHOOLS) do
        registerModifierRecord(id .. "_" .. school, name, school, filename)
    end
    for _, entry in ipairs(base_effect_display.all()) do
        local suffix = base_effect_display.normalizeId(entry and entry.id)
        if suffix then
            registerModifierRecord(
                id .. "_" .. suffix,
                name,
                entry.school or "alteration",
                filename,
                entry.id
            )
        end
    end
end

registerModifierDisplayEffect("spellforge_display_multicast", "Multicast", "spellforge_modifier_multicast.png")
registerModifierDisplayEffect("spellforge_display_spread", "Spread", "spellforge_modifier_spread.png")
registerModifierDisplayEffect("spellforge_display_burst", "Burst", "spellforge_modifier_burst.png")
registerModifierDisplayEffect("spellforge_display_speed_plus", "Speed+", "spellforge_modifier_speed_plus.png")
registerModifierDisplayEffect("spellforge_display_size_plus", "Size+", "spellforge_modifier_size_plus.png")
registerModifierDisplayEffect("spellforge_display_chain", "Chain", "spellforge_modifier_chain.png")
registerModifierDisplayEffect("spellforge_display_bounce", "Bounce", "spellforge_modifier_bounce.png")
registerModifierDisplayEffect("spellforge_display_pierce", "Pierce", "spellforge_modifier_pierce.png")
registerModifierDisplayEffect("spellforge_display_homing", "Homing", "spellforge_modifier_homing.png")
registerModifierDisplayEffect("spellforge_display_detonate", "Detonate", "spellforge_modifier_detonate.png")
registerModifierDisplayEffect("spellforge_display_trigger", "Trigger", "spellforge_modifier_trigger.png")
registerModifierDisplayEffect("spellforge_display_timer", "Timer", "spellforge_modifier_timer.png")
registerModifierDisplayEffect("spellforge_display_more", "...more Spellforge Effects", "spellforge_modifier_multicast.png")

for count = 2, limits.MAX_PAYLOAD_FANOUT_HARD do
    registerModifierDisplayEffect("spellforge_display_multicast_x" .. tostring(count), "Multicast x " .. tostring(count), "spellforge_modifier_multicast.png")
end

local function secondLabel(value)
    if value == 1 then
        return "1 second"
    end
    return tostring(value) .. " seconds"
end

local function displayNumberSuffix(value)
    local text = tostring(value)
    text = string.gsub(text, "%.", "_")
    text = string.gsub(text, "%-", "neg_")
    return text
end

local timer_value = 0.5
while timer_value <= 5.0001 do
    local suffix = displayNumberSuffix(timer_value)
    registerModifierDisplayEffect(
        "spellforge_display_timer_" .. suffix .. "s",
        "Timer " .. secondLabel(timer_value),
        "spellforge_modifier_timer.png"
    )
    timer_value = timer_value + 0.5
end

for hops = 1, 5 do
    local label = hops == 1 and "Chain 1 hop" or ("Chain " .. tostring(hops) .. " hops")
    registerModifierDisplayEffect("spellforge_display_chain_" .. tostring(hops), label, "spellforge_modifier_chain.png")
end

for bounces = 1, 12 do
    local label = bounces == 1 and "Bounce 1 time" or ("Bounce " .. tostring(bounces) .. " times")
    registerModifierDisplayEffect("spellforge_display_bounce_" .. tostring(bounces), label, "spellforge_modifier_bounce.png")
end

for pierces = 1, 5 do
    local label = pierces == 1 and "Pierce 1 actor" or ("Pierce " .. tostring(pierces) .. " actors")
    registerModifierDisplayEffect("spellforge_display_pierce_" .. tostring(pierces), label, "spellforge_modifier_pierce.png")
end

for preset = 1, 4 do
    registerModifierDisplayEffect("spellforge_display_spread_preset_" .. tostring(preset), "Spread Pattern " .. tostring(preset), "spellforge_modifier_spread.png")
end

local PERCENT_VALUES = { -90, -50, -25, 25, 50, 75, 100, 125, 150, 200, 300, 400 }
for _, percent in ipairs(PERCENT_VALUES) do
    if percent <= 400 then
        registerModifierDisplayEffect("spellforge_display_speed_plus_" .. displayNumberSuffix(percent) .. "p", "Speed+ " .. tostring(percent) .. "%", "spellforge_modifier_speed_plus.png")
    end
    if percent <= 300 then
        registerModifierDisplayEffect("spellforge_display_size_plus_" .. displayNumberSuffix(percent) .. "p", "Size+ " .. tostring(percent) .. "%", "spellforge_modifier_size_plus.png")
    end
end

content.magicEffects.records.spellforge_display_burst.name = "Burst - Multicast Pattern"

-- Backward-compatibility marker ID for existing saves/content.
content.magicEffects.records.spellforge_composed = {
    name = "Composed Spell",
    school = "alteration",
    description = "Legacy Spellforge marker effect. Runtime payload resolution is handled by Spellforge executor.",
    baseCost = 0,
    hasMagnitude = false,
    hasArea = false,
    hasDuration = false,
    harmful = false,
    allowsEnchanting = false,
    allowsSpellmaking = false,
}
