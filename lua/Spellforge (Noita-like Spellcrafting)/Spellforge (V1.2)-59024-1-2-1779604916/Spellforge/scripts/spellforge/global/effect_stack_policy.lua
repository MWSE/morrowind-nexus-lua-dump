local effect_registry = require("scripts.spellforge.shared.effect_support_registry")

local effect_stack_policy = {}

local STACKABLE_EFFECT_IDS = {
    firedamage = true,
    frostdamage = true,
    shockdamage = true,
    poison = true,
    damagehealth = true,
    damagefatigue = true,
    damagemagicka = true,
    damageattribute = true,
    damageskill = true,
    absorbhealth = true,
    absorbfatigue = true,
    absorbmagicka = true,
    drainhealth = true,
    drainfatigue = true,
    drainmagicka = true,
}

local function normalizeEffectId(effect_id)
    return effect_registry.normalizeEffectId(effect_id)
end

local function sanitizeForKey(value)
    local s = tostring(value or "nil")
    s = string.lower(s)
    return (string.gsub(s, "[^%w_]+", "_"))
end

local function sortedParamKeys(params)
    local keys = {}
    if type(params) ~= "table" then
        return keys
    end
    for key in pairs(params) do
        keys[#keys + 1] = tostring(key)
    end
    table.sort(keys)
    return keys
end

local function paramsSignature(params)
    local parts = {}
    for _, key in ipairs(sortedParamKeys(params)) do
        parts[#parts + 1] = sanitizeForKey(key) .. "_" .. sanitizeForKey(params[key])
    end
    return table.concat(parts, "_")
end

local function effectSignature(effect)
    if type(effect) ~= "table" then
        return sanitizeForKey(effect)
    end
    return table.concat({
        sanitizeForKey(effect.id),
        "r" .. sanitizeForKey(effect.range),
        "a" .. sanitizeForKey(effect.area),
        "d" .. sanitizeForKey(effect.duration),
        "n" .. sanitizeForKey(effect.magnitudeMin),
        "x" .. sanitizeForKey(effect.magnitudeMax),
        "attr" .. sanitizeForKey(effect.affectedAttribute),
        "skill" .. sanitizeForKey(effect.affectedSkill),
        "p" .. paramsSignature(effect.params),
    }, "_")
end

local function effectsSignature(effects)
    local parts = {}
    for index, effect in ipairs(effects or {}) do
        parts[index] = effectSignature(effect)
    end
    return table.concat(parts, "__")
end

local function opSignature(op)
    if type(op) ~= "table" then
        return sanitizeForKey(op)
    end
    return table.concat({
        sanitizeForKey(op.opcode),
        sanitizeForKey(op.effect_id),
        paramsSignature(op.params),
    }, "_")
end

local function opsSignature(ops)
    local parts = {}
    for index, op in ipairs(ops or {}) do
        parts[index] = opSignature(op)
    end
    return table.concat(parts, "__")
end

function effect_stack_policy.normalizeEffectId(effect_id)
    return normalizeEffectId(effect_id)
end

function effect_stack_policy.isStackableEffect(effect_id)
    local normalized = normalizeEffectId(effect_id)
    return normalized ~= nil and STACKABLE_EFFECT_IDS[normalized] == true
end

function effect_stack_policy.helperEffectsAreStackable(effects)
    local effect_ids = {}
    local count = 0
    for _, effect in ipairs(effects or {}) do
        local effect_id = normalizeEffectId(effect and effect.id)
        if effect_id ~= nil then
            count = count + 1
            effect_ids[#effect_ids + 1] = effect_id
            if not effect_stack_policy.isStackableEffect(effect_id) then
                return false, "contains_non_damage", effect_ids
            end
        else
            return false, "contains_non_damage", effect_ids
        end
    end
    if count == 0 then
        return false, "contains_non_damage", effect_ids
    end
    return true, "all_damage_like", effect_ids
end

function effect_stack_policy.sharedFanoutKeyForSlot(recipe_id, slot, effects)
    local source_context = slot and slot.source_postfix_opcode or "primary"
    local parent_slot_id = slot and slot.parent_slot_id or "root"
    return table.concat({
        sanitizeForKey(recipe_id),
        "stack_shared",
        "kind_" .. sanitizeForKey(slot and slot.kind),
        "parent_" .. sanitizeForKey(parent_slot_id),
        "source_" .. sanitizeForKey(source_context),
        "group_" .. sanitizeForKey(slot and slot.group_index),
        "prefix_" .. sanitizeForKey(opsSignature(slot and slot.prefix_ops)),
        "effects_" .. sanitizeForKey(effectsSignature(effects)),
    }, "_")
end

return effect_stack_policy
