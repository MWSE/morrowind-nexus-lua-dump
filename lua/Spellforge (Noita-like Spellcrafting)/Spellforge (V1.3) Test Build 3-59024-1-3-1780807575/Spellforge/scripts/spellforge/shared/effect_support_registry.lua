---@omw-context none
local effect_support_registry = {}

effect_support_registry.VERSION = "spellforge-effect-support-registry-v1"

local RANGE_SELF = 0
local RANGE_TOUCH = 1
local RANGE_TARGET = 2

local OPERATOR_EFFECT_IDS = {
    spellforge_multicast = true,
    spellforge_spread = true,
    spellforge_burst = true,
    spellforge_speed_plus = true,
    spellforge_size_plus = true,
    spellforge_chain = true,
    spellforge_bounce = true,
    spellforge_pierce = true,
    spellforge_homing = true,
    spellforge_detonate = true,
    spellforge_trigger = true,
    spellforge_timer = true,
}

local LEGACY_ALIASES = {
    poisondamage = "poison",
    weaknessfire = "weaknesstofire",
    weaknessfrost = "weaknesstofrost",
    weaknessshock = "weaknesstoshock",
    weaknesspoison = "weaknesstopoison",
    weaknessmagicka = "weaknesstomagicka",
    summonlesserbonewalker = "summonbonewalker",
}

local ATTRIBUTE_OPTIONS = {
    { id = "strength", display_name = "Strength" },
    { id = "intelligence", display_name = "Intelligence" },
    { id = "willpower", display_name = "Willpower" },
    { id = "agility", display_name = "Agility" },
    { id = "speed", display_name = "Speed" },
    { id = "endurance", display_name = "Endurance" },
    { id = "personality", display_name = "Personality" },
    { id = "luck", display_name = "Luck" },
}

local SKILL_OPTIONS = {
    { id = "block", display_name = "Block" },
    { id = "armorer", display_name = "Armorer" },
    { id = "mediumarmor", display_name = "Medium Armor" },
    { id = "heavyarmor", display_name = "Heavy Armor" },
    { id = "bluntweapon", display_name = "Blunt Weapon" },
    { id = "longblade", display_name = "Long Blade" },
    { id = "axe", display_name = "Axe" },
    { id = "spear", display_name = "Spear" },
    { id = "athletics", display_name = "Athletics" },
    { id = "enchant", display_name = "Enchant" },
    { id = "destruction", display_name = "Destruction" },
    { id = "alteration", display_name = "Alteration" },
    { id = "illusion", display_name = "Illusion" },
    { id = "conjuration", display_name = "Conjuration" },
    { id = "mysticism", display_name = "Mysticism" },
    { id = "restoration", display_name = "Restoration" },
    { id = "alchemy", display_name = "Alchemy" },
    { id = "unarmored", display_name = "Unarmored" },
    { id = "security", display_name = "Security" },
    { id = "sneak", display_name = "Sneak" },
    { id = "acrobatics", display_name = "Acrobatics" },
    { id = "lightarmor", display_name = "Light Armor" },
    { id = "shortblade", display_name = "Short Blade" },
    { id = "marksman", display_name = "Marksman" },
    { id = "mercantile", display_name = "Mercantile" },
    { id = "speechcraft", display_name = "Speechcraft" },
    { id = "handtohand", display_name = "Hand-to-hand" },
}

local VALID_ATTRIBUTES = {}
for _, entry in ipairs(ATTRIBUTE_OPTIONS) do
    VALID_ATTRIBUTES[entry.id] = true
end

local VALID_SKILLS = {}
for _, entry in ipairs(SKILL_OPTIONS) do
    VALID_SKILLS[entry.id] = true
end

local EFFECTS = {}
local EFFECT_ORDER = {}

local function cloneValue(value, depth)
    if type(value) ~= "table" then
        return value
    end
    if (depth or 0) >= 5 then
        return tostring(value)
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = cloneValue(v, (depth or 0) + 1)
    end
    return out
end

local function normalizeRawId(value)
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

function effect_support_registry.normalizeEffectId(value, opts)
    local options = opts or {}
    if value == nil then
        return nil
    end
    local raw = string.lower(tostring(value))
    raw = string.gsub(raw, "%s+", "")
    if raw == "" then
        return nil
    end
    if OPERATOR_EFFECT_IDS[raw] == true then
        return raw
    end
    if string.sub(raw, 1, 11) == "spellforge_" then
        return raw
    end
    local text = normalizeRawId(raw)
    if options.keep_operators == true and OPERATOR_EFFECT_IDS[text] == true then
        return text
    end
    return LEGACY_ALIASES[text] or text
end

local function normalizeSchool(value)
    if value == nil then
        return nil
    end
    local text = tostring(value)
    local n = tonumber(text)
    if n ~= nil then
        local schools = {
            [0] = "Alteration",
            [1] = "Conjuration",
            [2] = "Destruction",
            [3] = "Illusion",
            [4] = "Mysticism",
            [5] = "Restoration",
        }
        return schools[n]
    end
    if text == "" then
        return nil
    end
    text = string.lower(text)
    return string.upper(string.sub(text, 1, 1)) .. string.sub(text, 2)
end

local function fallbackColor(category, school)
    local c = string.lower(tostring(category or school or ""))
    if string.find(c, "fire", 1, true) then return "fire" end
    if string.find(c, "frost", 1, true) then return "frost" end
    if string.find(c, "shock", 1, true) then return "shock" end
    if string.find(c, "poison", 1, true) then return "poison" end
    if string.find(c, "restore", 1, true) or string.find(c, "cure", 1, true) then return "restore" end
    if string.find(c, "damage", 1, true) or string.find(c, "drain", 1, true) or string.find(c, "absorb", 1, true) then return "drain" end
    return "shield"
end

local function addEffect(id, display_name, school, category, opts)
    local options = opts or {}
    local canonical = effect_support_registry.normalizeEffectId(id)
    if not canonical or EFFECTS[canonical] then
        return
    end
    local entry = {
        id = canonical,
        display_name = display_name,
        school = school,
        category = category or school,
        range = options.range or RANGE_TARGET,
        magnitudeMin = options.magnitudeMin or options.magnitude or 1,
        magnitudeMax = options.magnitudeMax or options.magnitude or options.magnitudeMin or 1,
        area = options.area or 0,
        duration = options.duration or 1,
        allowed_ranges = cloneValue(options.allowed_ranges or { RANGE_SELF, RANGE_TOUCH, RANGE_TARGET }, 0),
        color = options.color or fallbackColor(category, school),
        hasMagnitude = options.hasMagnitude,
        hasDuration = options.hasDuration,
        hasArea = options.hasArea,
        hasAttribute = options.hasAttribute == true,
        hasSkill = options.hasSkill == true,
        runtime_category = options.runtime_category or category or "Utility",
        stack_category = options.stack_category,
        baseCost = options.baseCost,
        allowsSpellmaking = options.allowsSpellmaking,
        allowsEnchanting = options.allowsEnchanting,
        application_limited = options.application_limited == true,
        application_limit_reason = options.application_limit_reason,
        explicit_support = true,
    }
    if entry.hasMagnitude == nil then entry.hasMagnitude = true end
    if entry.hasDuration == nil then entry.hasDuration = true end
    if entry.hasArea == nil then entry.hasArea = true end
    if entry.hasAttribute then
        entry.required_parameter_kind = "attribute"
    elseif entry.hasSkill then
        entry.required_parameter_kind = "skill"
    end
    EFFECTS[canonical] = entry
    EFFECT_ORDER[#EFFECT_ORDER + 1] = canonical
end

local SELF = { RANGE_SELF }
local TOUCH_TARGET = { RANGE_TOUCH, RANGE_TARGET }
local ALL_RANGES = { RANGE_SELF, RANGE_TOUCH, RANGE_TARGET }

local function addDamage(id, name, baseCost, duration)
    addEffect(id, name, "Destruction", "Damage", {
        range = RANGE_TARGET, magnitude = 5, duration = duration or 1,
        allowed_ranges = TOUCH_TARGET, color = string.find(id, "fire", 1, true) and "fire"
            or string.find(id, "frost", 1, true) and "frost"
            or string.find(id, "shock", 1, true) and "shock"
            or string.find(id, "poison", 1, true) and "poison"
            or "drain",
        baseCost = baseCost,
        runtime_category = "Timed damage",
        stack_category = "damage",
    })
end

local function addBuff(id, name, school, category, magnitude, duration, opts)
    local options = opts or {}
    addEffect(id, name, school, category, {
        range = options.range or RANGE_SELF,
        magnitude = magnitude or 10,
        duration = duration or 20,
        allowed_ranges = options.allowed_ranges or ALL_RANGES,
        color = options.color,
        baseCost = options.baseCost,
        hasMagnitude = options.hasMagnitude,
        hasDuration = options.hasDuration,
        hasArea = options.hasArea,
        hasAttribute = options.hasAttribute,
        hasSkill = options.hasSkill,
        allowsSpellmaking = options.allowsSpellmaking,
        allowsEnchanting = options.allowsEnchanting,
        runtime_category = options.runtime_category or "Buff",
        application_limited = options.application_limited,
        application_limit_reason = options.application_limit_reason,
    })
end

addDamage("firedamage", "Fire Damage", 5, 1)
addDamage("frostdamage", "Frost Damage", 5, 1)
addDamage("shockdamage", "Shock Damage", 7, 1)
addDamage("poison", "Poison", 9, 5)
addDamage("damagehealth", "Damage Health", 8, 1)
addDamage("damagefatigue", "Damage Fatigue", 4, 1)
addDamage("damagemagicka", "Damage Magicka", 4, 1)
addDamage("damageattribute", "Damage Attribute", 8, 1)
EFFECTS.damageattribute.hasAttribute = true
EFFECTS.damageattribute.required_parameter_kind = "attribute"
addDamage("damageskill", "Damage Skill", 4, 1)
EFFECTS.damageskill.hasSkill = true
EFFECTS.damageskill.required_parameter_kind = "skill"

addEffect("drainhealth", "Drain Health", "Destruction", "Drain", { range = RANGE_TOUCH, magnitude = 8, duration = 5, allowed_ranges = TOUCH_TARGET, color = "drain", baseCost = 8, runtime_category = "Debuff/control", stack_category = "damage" })
addEffect("drainfatigue", "Drain Fatigue", "Destruction", "Drain", { range = RANGE_TOUCH, magnitude = 8, duration = 5, allowed_ranges = TOUCH_TARGET, color = "drain", baseCost = 4, runtime_category = "Debuff/control", stack_category = "damage" })
addEffect("drainmagicka", "Drain Magicka", "Destruction", "Drain", { range = RANGE_TOUCH, magnitude = 8, duration = 5, allowed_ranges = TOUCH_TARGET, color = "drain", baseCost = 4, runtime_category = "Debuff/control", stack_category = "damage" })
addEffect("drainattribute", "Drain Attribute", "Destruction", "Drain", { range = RANGE_TOUCH, magnitude = 5, duration = 10, allowed_ranges = TOUCH_TARGET, color = "drain", baseCost = 1, hasAttribute = true, runtime_category = "Debuff/control" })
addEffect("drainskill", "Drain Skill", "Destruction", "Drain", { range = RANGE_TOUCH, magnitude = 5, duration = 10, allowed_ranges = TOUCH_TARGET, color = "drain", baseCost = 1, hasSkill = true, runtime_category = "Debuff/control" })

addEffect("absorbhealth", "Absorb Health", "Mysticism", "Absorb", { range = RANGE_TOUCH, magnitude = 6, duration = 5, allowed_ranges = TOUCH_TARGET, color = "drain", baseCost = 10, runtime_category = "Hybrid absorb", stack_category = "damage" })
addEffect("absorbfatigue", "Absorb Fatigue", "Mysticism", "Absorb", { range = RANGE_TOUCH, magnitude = 6, duration = 5, allowed_ranges = TOUCH_TARGET, color = "drain", baseCost = 4, runtime_category = "Hybrid absorb", stack_category = "damage" })
addEffect("absorbmagicka", "Absorb Magicka", "Mysticism", "Absorb", { range = RANGE_TOUCH, magnitude = 6, duration = 5, allowed_ranges = TOUCH_TARGET, color = "drain", baseCost = 4, runtime_category = "Hybrid absorb", stack_category = "damage" })
addEffect("absorbattribute", "Absorb Attribute", "Mysticism", "Absorb", { range = RANGE_TOUCH, magnitude = 5, duration = 10, allowed_ranges = TOUCH_TARGET, color = "drain", baseCost = 1, hasAttribute = true, runtime_category = "Hybrid absorb" })
addEffect("absorbskill", "Absorb Skill", "Mysticism", "Absorb", { range = RANGE_TOUCH, magnitude = 5, duration = 10, allowed_ranges = TOUCH_TARGET, color = "drain", baseCost = 1, hasSkill = true, runtime_category = "Hybrid absorb" })

addBuff("restorehealth", "Restore Health", "Restoration", "Restore", 10, 1, { baseCost = 5, hasDuration = false, runtime_category = "Healing/restoration", color = "restore" })
addBuff("restorefatigue", "Restore Fatigue", "Restoration", "Restore", 12, 1, { baseCost = 2, hasDuration = false, runtime_category = "Healing/restoration", color = "restore" })
addBuff("restoremagicka", "Restore Magicka", "Restoration", "Restore", 8, 1, { baseCost = 5, hasDuration = false, runtime_category = "Healing/restoration", color = "restore", allowsSpellmaking = false })
addBuff("restoreattribute", "Restore Attribute", "Restoration", "Restore", 5, 1, { baseCost = 1, hasDuration = false, hasAttribute = true, runtime_category = "Healing/restoration", color = "restore" })
addBuff("restoreskill", "Restore Skill", "Restoration", "Restore", 5, 1, { baseCost = 1, hasDuration = false, hasSkill = true, runtime_category = "Healing/restoration", color = "restore" })

addBuff("fortifyhealth", "Fortify Health", "Restoration", "Fortify", 10, 20, { baseCost = 1, color = "restore" })
addBuff("fortifyfatigue", "Fortify Fatigue", "Restoration", "Fortify", 10, 20, { baseCost = 1, color = "restore" })
addBuff("fortifymagicka", "Fortify Magicka", "Restoration", "Fortify", 10, 20, { baseCost = 1, color = "restore" })
addBuff("fortifymaximummagicka", "Fortify Maximum Magicka", "Restoration", "Fortify", 10, 20, { baseCost = 1, color = "restore" })
addBuff("fortifyattribute", "Fortify Attribute", "Restoration", "Fortify", 10, 30, { baseCost = 1, hasAttribute = true, color = "restore" })
addBuff("fortifyskill", "Fortify Skill", "Restoration", "Fortify", 10, 30, { baseCost = 1, hasSkill = true, color = "restore" })
addBuff("fortifyattack", "Fortify Attack", "Restoration", "Fortify", 10, 30, { baseCost = 1, color = "restore" })

addBuff("shield", "Shield", "Alteration", "Defense", 10, 20, { baseCost = 2, color = "shield" })
addBuff("fireshield", "Fire Shield", "Alteration", "Defense", 10, 20, { baseCost = 3, color = "fire" })
addBuff("frostshield", "Frost Shield", "Alteration", "Defense", 10, 20, { baseCost = 3, color = "frost" })
addBuff("lightningshield", "Lightning Shield", "Alteration", "Defense", 10, 20, { baseCost = 3, color = "shock" })

for _, item in ipairs({
    { "resistfire", "Resist Fire", "fire" },
    { "resistfrost", "Resist Frost", "frost" },
    { "resistshock", "Resist Shock", "shock" },
    { "resistmagicka", "Resist Magicka", "shock" },
    { "resistpoison", "Resist Poison", "poison" },
    { "resistcommondisease", "Resist Common Disease", "restore" },
    { "resistblightdisease", "Resist Blight Disease", "restore" },
    { "resistcorprusdisease", "Resist Corprus Disease", "restore" },
    { "resistnormalweapons", "Resist Normal Weapons", "shield" },
    { "resistparalysis", "Resist Paralysis", "shield" },
}) do
    addBuff(item[1], item[2], "Restoration", "Resist", 20, 20, { baseCost = 2, color = item[3] })
end

for _, item in ipairs({
    { "weaknesstofire", "Weakness to Fire", "fire" },
    { "weaknesstofrost", "Weakness to Frost", "frost" },
    { "weaknesstoshock", "Weakness to Shock", "shock" },
    { "weaknesstomagicka", "Weakness to Magicka", "shock" },
    { "weaknesstocommondisease", "Weakness to Common Disease", "poison" },
    { "weaknesstoblightdisease", "Weakness to Blight Disease", "poison" },
    { "weaknesstocorprusdisease", "Weakness to Corprus Disease", "poison" },
    { "weaknesstopoison", "Weakness to Poison", "poison" },
    { "weaknesstonormalweapons", "Weakness to Normal Weapons", "drain" },
}) do
    addEffect(item[1], item[2], "Destruction", "Weakness", { range = RANGE_TARGET, magnitude = 25, duration = 10, allowed_ranges = TOUCH_TARGET, color = item[3], baseCost = 1, runtime_category = "Debuff/control" })
end

addBuff("burden", "Burden", "Alteration", "Control", 20, 15, { range = RANGE_TARGET, allowed_ranges = TOUCH_TARGET, baseCost = 1, color = "drain", runtime_category = "Debuff/control" })
addBuff("feather", "Feather", "Alteration", "Utility", 20, 30, { baseCost = 1 })
addBuff("jump", "Jump", "Alteration", "Movement", 20, 15, { baseCost = 3 })
addBuff("levitate", "Levitate", "Alteration", "Movement", 10, 20, { baseCost = 3 })
addBuff("slowfall", "Slowfall", "Alteration", "Movement", 10, 20, { baseCost = 1 })
addBuff("waterbreathing", "Water Breathing", "Alteration", "Utility", 1, 30, { baseCost = 1, hasMagnitude = false, color = "frost" })
addBuff("waterwalking", "Water Walking", "Alteration", "Utility", 1, 30, { baseCost = 1, hasMagnitude = false, color = "frost" })
addBuff("swiftswim", "Swift Swim", "Alteration", "Movement", 20, 30, { baseCost = 1, color = "frost" })
addEffect("open", "Open", "Alteration", "Utility", { range = RANGE_TARGET, magnitude = 20, duration = 1, allowed_ranges = TOUCH_TARGET, baseCost = 1, hasDuration = false, runtime_category = "Object effect" })
addEffect("lock", "Lock", "Alteration", "Utility", { range = RANGE_TARGET, magnitude = 20, duration = 1, allowed_ranges = TOUCH_TARGET, baseCost = 1, hasDuration = false, runtime_category = "Object effect", application_limited = true, application_limit_reason = "requires lockable object target" })

addBuff("blind", "Blind", "Illusion", "Control", 20, 10, { range = RANGE_TARGET, allowed_ranges = TOUCH_TARGET, baseCost = 1, color = "drain", runtime_category = "Debuff/control" })
addBuff("chameleon", "Chameleon", "Illusion", "Stealth", 20, 20, { baseCost = 3 })
addBuff("invisibility", "Invisibility", "Illusion", "Stealth", 1, 10, { baseCost = 20, hasMagnitude = false })
addEffect("paralyze", "Paralyze", "Illusion", "Control", { range = RANGE_TARGET, magnitude = 1, duration = 3, allowed_ranges = TOUCH_TARGET, baseCost = 40, hasMagnitude = false, runtime_category = "Debuff/control" })
addEffect("silence", "Silence", "Illusion", "Control", { range = RANGE_TARGET, magnitude = 1, duration = 10, allowed_ranges = TOUCH_TARGET, baseCost = 40, hasMagnitude = false, runtime_category = "Debuff/control" })
addEffect("sound", "Sound", "Illusion", "Control", { range = RANGE_TARGET, magnitude = 20, duration = 10, allowed_ranges = TOUCH_TARGET, baseCost = 3, runtime_category = "Debuff/control" })
addBuff("light", "Light", "Illusion", "Utility", 20, 30, { baseCost = 1 })
addBuff("nighteye", "Night Eye", "Illusion", "Utility", 20, 30, { baseCost = 1 })
addBuff("sanctuary", "Sanctuary", "Illusion", "Defense", 10, 20, { baseCost = 1 })
addEffect("charm", "Charm", "Illusion", "Control", { range = RANGE_TARGET, magnitude = 20, duration = 30, allowed_ranges = TOUCH_TARGET, baseCost = 1, runtime_category = "Debuff/control" })

for _, item in ipairs({
    { "calmhumanoid", "Calm Humanoid" },
    { "calmcreature", "Calm Creature" },
    { "frenzyhumanoid", "Frenzy Humanoid" },
    { "frenzycreature", "Frenzy Creature" },
    { "demoralizehumanoid", "Demoralize Humanoid" },
    { "demoralizecreature", "Demoralize Creature" },
    { "rallyhumanoid", "Rally Humanoid" },
    { "rallycreature", "Rally Creature" },
}) do
    addEffect(item[1], item[2], "Illusion", "Control", { range = RANGE_TARGET, magnitude = 20, duration = 20, allowed_ranges = TOUCH_TARGET, baseCost = 1, runtime_category = "Debuff/control" })
end

addBuff("telekinesis", "Telekinesis", "Mysticism", "Utility", 10, 20, { allowed_ranges = SELF, baseCost = 1 })
addBuff("detectanimal", "Detect Animal", "Mysticism", "Detect", 50, 20, { allowed_ranges = SELF, baseCost = 0.2 })
addBuff("detectkey", "Detect Key", "Mysticism", "Detect", 50, 20, { allowed_ranges = SELF, baseCost = 0.2 })
addBuff("detectenchantment", "Detect Enchantment", "Mysticism", "Detect", 50, 20, { allowed_ranges = SELF, baseCost = 0.2 })
addEffect("dispel", "Dispel", "Mysticism", "Utility", { range = RANGE_SELF, magnitude = 20, duration = 1, allowed_ranges = ALL_RANGES, baseCost = 5, hasDuration = false })
addEffect("soultrap", "Soultrap", "Mysticism", "Utility", { range = RANGE_TARGET, magnitude = 1, duration = 30, allowed_ranges = TOUCH_TARGET, baseCost = 10, hasMagnitude = false })
addBuff("spellabsorption", "Spell Absorption", "Mysticism", "Defense", 20, 20, { baseCost = 10 })
addBuff("reflect", "Reflect", "Mysticism", "Defense", 20, 20, { baseCost = 10 })
addEffect("mark", "Mark", "Mysticism", "Teleport", { range = RANGE_SELF, magnitude = 1, duration = 1, allowed_ranges = SELF, baseCost = 18, hasMagnitude = false, hasDuration = false, runtime_category = "Teleport/intervention", application_limited = true, application_limit_reason = "requires self/location context" })
addEffect("recall", "Recall", "Mysticism", "Teleport", { range = RANGE_SELF, magnitude = 1, duration = 1, allowed_ranges = SELF, baseCost = 18, hasMagnitude = false, hasDuration = false, runtime_category = "Teleport/intervention", application_limited = true, application_limit_reason = "requires self/location context" })
addEffect("divineintervention", "Divine Intervention", "Mysticism", "Teleport", { range = RANGE_SELF, magnitude = 1, duration = 1, allowed_ranges = SELF, baseCost = 18, hasMagnitude = false, hasDuration = false, runtime_category = "Teleport/intervention", application_limited = true, application_limit_reason = "requires self/location context" })
addEffect("almsiviintervention", "Almsivi Intervention", "Mysticism", "Teleport", { range = RANGE_SELF, magnitude = 1, duration = 1, allowed_ranges = SELF, baseCost = 18, hasMagnitude = false, hasDuration = false, runtime_category = "Teleport/intervention", application_limited = true, application_limit_reason = "requires self/location context" })

for _, item in ipairs({
    { "curecommondisease", "Cure Common Disease" },
    { "cureblightdisease", "Cure Blight Disease" },
    { "curecorprusdisease", "Cure Corprus Disease" },
    { "curepoison", "Cure Poison" },
    { "cureparalyzation", "Cure Paralyzation" },
}) do
    addEffect(item[1], item[2], "Restoration", "Cure", { range = RANGE_SELF, magnitude = 1, duration = 1, allowed_ranges = ALL_RANGES, baseCost = 5, hasMagnitude = false, hasDuration = false, runtime_category = "Healing/restoration", color = "restore" })
end

addEffect("turnundead", "Turn Undead", "Conjuration", "Control", { range = RANGE_TARGET, magnitude = 20, duration = 20, allowed_ranges = TOUCH_TARGET, baseCost = 1, runtime_category = "Debuff/control" })
addEffect("commandcreature", "Command Creature", "Conjuration", "Control", { range = RANGE_TARGET, magnitude = 20, duration = 20, allowed_ranges = TOUCH_TARGET, baseCost = 15, runtime_category = "Debuff/control" })
addEffect("commandhumanoid", "Command Humanoid", "Conjuration", "Control", { range = RANGE_TARGET, magnitude = 20, duration = 20, allowed_ranges = TOUCH_TARGET, baseCost = 15, runtime_category = "Debuff/control" })

for _, item in ipairs({
    { "summonancestralghost", "Summon Ancestral Ghost" },
    { "summonskeletalminion", "Summon Skeletal Minion" },
    { "summonscamp", "Summon Scamp" },
    { "summonbonewalker", "Summon Bonewalker" },
    { "summongreaterbonewalker", "Summon Greater Bonewalker" },
    { "summonbonelord", "Summon Bonelord" },
    { "summonclannfear", "Summon Clannfear" },
    { "summondaedroth", "Summon Daedroth" },
    { "summondremora", "Summon Dremora" },
    { "summonwingedtwilight", "Summon Winged Twilight" },
    { "summonhunger", "Summon Hunger" },
    { "summongoldensaint", "Summon Golden Saint" },
    { "summonflameatronach", "Summon Flame Atronach" },
    { "summonfrostatronach", "Summon Frost Atronach" },
    { "summonstormatronach", "Summon Storm Atronach" },
}) do
    addEffect(item[1], item[2], "Conjuration", "Summon", { range = RANGE_SELF, magnitude = 1, duration = 30, allowed_ranges = SELF, baseCost = 10, hasMagnitude = false, runtime_category = "Summon", application_limited = true, application_limit_reason = "caster-linked summon" })
end

for _, item in ipairs({
    { "bounddagger", "Bound Dagger" },
    { "boundlongsword", "Bound Longsword" },
    { "boundmace", "Bound Mace" },
    { "boundbattleaxe", "Bound Battle Axe" },
    { "boundspear", "Bound Spear" },
    { "boundlongbow", "Bound Longbow" },
    { "boundcuirass", "Bound Cuirass" },
    { "boundhelm", "Bound Helm" },
    { "boundboots", "Bound Boots" },
    { "boundshield", "Bound Shield" },
    { "boundgloves", "Bound Gloves" },
}) do
    addEffect(item[1], item[2], "Conjuration", "Bound Equipment", { range = RANGE_SELF, magnitude = 1, duration = 30, allowed_ranges = SELF, baseCost = 2, hasMagnitude = false, runtime_category = "Bound equipment", application_limited = true, application_limit_reason = "caster-linked bound equipment" })
end

addEffect("disintegrateweapon", "Disintegrate Weapon", "Destruction", "Object effect", { range = RANGE_TARGET, magnitude = 10, duration = 1, allowed_ranges = TOUCH_TARGET, baseCost = 8, runtime_category = "Object effect", application_limited = true, application_limit_reason = "requires equipped weapon target" })
addEffect("disintegratearmor", "Disintegrate Armor", "Destruction", "Object effect", { range = RANGE_TARGET, magnitude = 10, duration = 1, allowed_ranges = TOUCH_TARGET, baseCost = 8, runtime_category = "Object effect", application_limited = true, application_limit_reason = "requires equipped armor target" })

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

local function firstNonNil(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if value ~= nil then
            return value
        end
    end
    return nil
end

local function boolOrNil(value)
    if type(value) == "boolean" then
        return value
    end
    return nil
end

local function numberOrNil(value)
    local n = tonumber(value)
    if n ~= nil then
        return n
    end
    return nil
end

local function textOrNil(value)
    if type(value) == "string" and value ~= "" then
        return value
    end
    if type(value) == "number" or type(value) == "boolean" then
        return tostring(value)
    end
    return nil
end

local function associatedMagicEffectRecord(record_or_sample)
    if type(record_or_sample) ~= "table" then
        return nil
    end
    return readField(record_or_sample, "effect")
        or readField(record_or_sample, "mgef")
        or readField(record_or_sample, "magicEffect")
end

function effect_support_registry.displayNameFromId(effect_id)
    local id = effect_support_registry.normalizeEffectId(effect_id)
    local fallback = id and EFFECTS[id]
    if fallback and fallback.display_name then
        return fallback.display_name
    end
    local text = tostring(id or effect_id or "")
    text = string.gsub(text, "_", " ")
    text = string.gsub(text, "(%l)(%u)", "%1 %2")
    text = string.gsub(text, "([a-z])([A-Z])", "%1 %2")
    text = string.gsub(text, "^%l", string.upper)
    text = string.gsub(text, " (%l)", function(ch) return " " .. string.upper(ch) end)
    return text ~= "" and text or "Unknown Effect"
end

function effect_support_registry.getFallbackInfo(effect_id)
    local id = effect_support_registry.normalizeEffectId(effect_id)
    return id and cloneValue(EFFECTS[id], 0) or nil
end

local function recordInfo(record_or_sample, id)
    if type(record_or_sample) ~= "table" then
        return {}
    end
    local associated = associatedMagicEffectRecord(record_or_sample)
    return {
        id = id,
        display_name = textOrNil(firstNonNil(
            readField(record_or_sample, "display_name"),
            readField(record_or_sample, "displayName"),
            readField(record_or_sample, "name"),
            readField(associated, "display_name"),
            readField(associated, "displayName"),
            readField(associated, "name")
        )),
        school = normalizeSchool(firstNonNil(readField(record_or_sample, "school"), readField(associated, "school"))),
        icon = textOrNil(firstNonNil(readField(record_or_sample, "icon"), readField(associated, "icon"))),
        description = textOrNil(firstNonNil(readField(record_or_sample, "description"), readField(associated, "description"))),
        baseCost = numberOrNil(firstNonNil(
            readField(record_or_sample, "baseCost"),
            readField(record_or_sample, "base_cost"),
            readField(record_or_sample, "cost"),
            readField(associated, "baseCost"),
            readField(associated, "base_cost"),
            readField(associated, "cost")
        )),
        hasMagnitude = boolOrNil(firstNonNil(readField(record_or_sample, "hasMagnitude"), readField(associated, "hasMagnitude"))),
        hasDuration = boolOrNil(firstNonNil(readField(record_or_sample, "hasDuration"), readField(associated, "hasDuration"))),
        hasArea = boolOrNil(firstNonNil(readField(record_or_sample, "hasArea"), readField(associated, "hasArea"))),
        hasAttribute = boolOrNil(firstNonNil(readField(record_or_sample, "hasAttribute"), readField(associated, "hasAttribute"))),
        hasSkill = boolOrNil(firstNonNil(readField(record_or_sample, "hasSkill"), readField(associated, "hasSkill"))),
        onSelf = boolOrNil(firstNonNil(readField(record_or_sample, "onSelf"), readField(associated, "onSelf"))),
        onTouch = boolOrNil(firstNonNil(readField(record_or_sample, "onTouch"), readField(associated, "onTouch"))),
        onTarget = boolOrNil(firstNonNil(readField(record_or_sample, "onTarget"), readField(associated, "onTarget"))),
        allowsSpellmaking = boolOrNil(firstNonNil(readField(record_or_sample, "allowsSpellmaking"), readField(associated, "allowsSpellmaking"))),
        allowsEnchanting = boolOrNil(firstNonNil(readField(record_or_sample, "allowsEnchanting"), readField(associated, "allowsEnchanting"))),
        harmful = boolOrNil(firstNonNil(readField(record_or_sample, "harmful"), readField(associated, "harmful"))),
        isAppliedOnce = boolOrNil(firstNonNil(readField(record_or_sample, "isAppliedOnce"), readField(associated, "isAppliedOnce"))),
        nonRecastable = boolOrNil(firstNonNil(readField(record_or_sample, "nonRecastable"), readField(associated, "nonRecastable"))),
        casterLinked = boolOrNil(firstNonNil(readField(record_or_sample, "casterLinked"), readField(associated, "casterLinked"))),
        range = numberOrNil(firstNonNil(readField(record_or_sample, "range"), readField(associated, "range"))),
        magnitudeMin = numberOrNil(firstNonNil(readField(record_or_sample, "magnitudeMin"), readField(record_or_sample, "minMagnitude"), readField(record_or_sample, "min"))),
        magnitudeMax = numberOrNil(firstNonNil(readField(record_or_sample, "magnitudeMax"), readField(record_or_sample, "maxMagnitude"), readField(record_or_sample, "max"))),
        area = numberOrNil(readField(record_or_sample, "area")),
        duration = numberOrNil(readField(record_or_sample, "duration")),
    }
end

local function allowedRangesFromInfo(info, fallback)
    if info.onSelf ~= nil or info.onTouch ~= nil or info.onTarget ~= nil then
        local ranges = {}
        if info.onSelf == true then ranges[#ranges + 1] = RANGE_SELF end
        if info.onTouch == true then ranges[#ranges + 1] = RANGE_TOUCH end
        if info.onTarget == true then ranges[#ranges + 1] = RANGE_TARGET end
        if #ranges > 0 then
            return ranges
        end
    end
    return cloneValue((fallback and fallback.allowed_ranges) or ALL_RANGES, 0)
end

local function isSelfRange(range)
    return range == RANGE_SELF or range == "self" or range == "Self"
end

function effect_support_registry.mergeInfo(effect_id, record_or_sample)
    local id = effect_support_registry.normalizeEffectId(effect_id or (record_or_sample and record_or_sample.id))
    if not id then
        return nil
    end
    local fallback = EFFECTS[id]
    local rec = recordInfo(record_or_sample, id)
    local out = cloneValue(fallback or {}, 0)
    out.id = id
    out.display_name = rec.display_name or out.display_name or effect_support_registry.displayNameFromId(id)
    out.school = rec.school or out.school or "Unknown"
    out.category = out.category or out.school
    out.icon = rec.icon or out.icon
    out.description = rec.description or out.description
    out.baseCost = rec.baseCost or out.baseCost
    out.hasMagnitude = firstNonNil(rec.hasMagnitude, out.hasMagnitude, true)
    out.hasDuration = firstNonNil(rec.hasDuration, out.hasDuration, true)
    out.hasArea = firstNonNil(rec.hasArea, out.hasArea, true)
    out.hasAttribute = firstNonNil(rec.hasAttribute, out.hasAttribute, false)
    out.hasSkill = firstNonNil(rec.hasSkill, out.hasSkill, false)
    out.allowsSpellmaking = firstNonNil(rec.allowsSpellmaking, out.allowsSpellmaking)
    out.allowsEnchanting = firstNonNil(rec.allowsEnchanting, out.allowsEnchanting)
    out.harmful = rec.harmful
    out.isAppliedOnce = rec.isAppliedOnce
    out.nonRecastable = rec.nonRecastable
    out.casterLinked = rec.casterLinked
    out.default_range = firstNonNil(rec.range, out.range, RANGE_TARGET)
    out.default_magnitude_min = firstNonNil(rec.magnitudeMin, out.magnitudeMin, 1)
    out.default_magnitude_max = firstNonNil(rec.magnitudeMax, out.magnitudeMax, out.default_magnitude_min, 1)
    out.default_area = firstNonNil(rec.area, out.area, 0)
    out.default_duration = firstNonNil(rec.duration, out.duration, 1)
    out.range = out.default_range
    out.magnitudeMin = out.default_magnitude_min
    out.magnitudeMax = out.default_magnitude_max
    out.area = out.default_area
    out.duration = out.default_duration
    out.allowed_ranges = allowedRangesFromInfo(rec, out)
    out.color = out.color or fallbackColor(out.category, out.school)
    if out.hasAttribute == true then
        out.required_parameter_kind = "attribute"
    elseif out.hasSkill == true then
        out.required_parameter_kind = "skill"
    else
        out.required_parameter_kind = nil
    end
    out.supported = fallback ~= nil or out.allowsSpellmaking == true or record_or_sample ~= nil
    out.player_facing = out.supported == true
    out.spellmaking_legal = out.allowsSpellmaking ~= false
    return out
end

function effect_support_registry.isOperatorEffectId(effect_id)
    local id = effect_support_registry.normalizeEffectId(effect_id, { keep_operators = true })
    return id ~= nil and OPERATOR_EFFECT_IDS[id] == true
end

function effect_support_registry.isSupported(effect_id, record_or_sample)
    local info = effect_support_registry.mergeInfo(effect_id, record_or_sample)
    return info ~= nil and info.supported == true and info.spellmaking_legal ~= false
end

function effect_support_registry.isSpellmakingLegal(effect_id, record_or_sample)
    local info = effect_support_registry.mergeInfo(effect_id, record_or_sample)
    return info ~= nil and info.spellmaking_legal ~= false
end

function effect_support_registry.isSummonEffect(effect_or_id, record_or_sample)
    local effect_id = effect_or_id
    local sample = record_or_sample
    if type(effect_or_id) == "table" then
        effect_id = effect_or_id.id
        sample = sample or effect_or_id
    end
    local id = effect_support_registry.normalizeEffectId(effect_id)
    if type(id) ~= "string" or id == "" then
        return false
    end

    local info = effect_support_registry.mergeInfo(id, sample)
    if info and info.spellmaking_legal == false then
        return false
    end
    if info and string.lower(tostring(info.runtime_category or "")) == "summon" then
        return true
    end
    if string.sub(id, 1, 6) == "summon" then
        return true
    end

    local exact_id = type(sample) == "table"
        and (textOrNil(readField(sample, "engine_effect_id")) or textOrNil(readField(sample, "record_effect_id")))
        or nil
    local display_name = type(sample) == "table"
        and textOrNil(firstNonNil(readField(sample, "display_name"), readField(sample, "displayName"), readField(sample, "name"), readField(sample, "label")))
        or nil
    local school = info and info.school or (type(sample) == "table" and normalizeSchool(readField(sample, "school")) or nil)
    local haystack = string.lower(tostring(id or "") .. " " .. tostring(exact_id or "") .. " " .. tostring(display_name or ""))
    local looks_like_summon = string.find(haystack, "summon", 1, true) ~= nil
    if not looks_like_summon then
        return false
    end
    if school == "Conjuration" then
        return true
    end
    return type(sample) == "table" and isSelfRange(readField(sample, "range"))
end

function effect_support_registry.getDisplayInfo(effect_id, record_or_sample)
    local info = effect_support_registry.mergeInfo(effect_id, record_or_sample)
    if not info then
        return nil
    end
    return {
        id = info.id,
        display_name = info.display_name,
        school = string.lower(tostring(info.school or "alteration")),
        icon = info.icon,
        proxy_id = "spellforge_display_base_" .. info.id,
        generic = EFFECTS[info.id] == nil,
        hasMagnitude = info.hasMagnitude,
        hasDuration = info.hasDuration,
        hasArea = info.hasArea,
        hasAttribute = info.hasAttribute,
        hasSkill = info.hasSkill,
    }
end

function effect_support_registry.getCostInfo(effect_id, record_or_sample)
    local info = effect_support_registry.mergeInfo(effect_id, record_or_sample)
    if not info then
        return nil
    end
    return {
        effect_id = info.id,
        baseCost = info.baseCost or 10,
        school = info.school or "Unknown",
        hasMagnitude = info.hasMagnitude,
        hasDuration = info.hasDuration,
        isAppliedOnce = info.isAppliedOnce,
        source = info.baseCost and "registry_fallback" or "registry_default",
    }
end

function effect_support_registry.buildCatalogEntry(effect_id, opts)
    local options = opts or {}
    local info = effect_support_registry.mergeInfo(effect_id, options.sample or options.record)
    if not info or info.supported ~= true or info.spellmaking_legal == false then
        return nil
    end
    info.known = options.known == true
    info.source = options.source
    info.source_mode = options.source_mode
    info.requiresAttribute = info.hasAttribute == true
    info.requiresSkill = info.hasSkill == true
    info.parameter_kind = info.required_parameter_kind
    info.attribute_options = info.requiresAttribute and effect_support_registry.attributeOptions() or nil
    info.skill_options = info.requiresSkill and effect_support_registry.skillOptions() or nil
    return info
end

function effect_support_registry.staticEffects()
    local out = {}
    for _, id in ipairs(EFFECT_ORDER) do
        out[#out + 1] = cloneValue(EFFECTS[id], 0)
    end
    table.sort(out, function(a, b)
        local school_a = tostring(a.school or "")
        local school_b = tostring(b.school or "")
        if school_a == school_b then
            return tostring(a.display_name or a.id) < tostring(b.display_name or b.id)
        end
        return school_a < school_b
    end)
    return out
end

local function normalizeParamId(value)
    local id = normalizeRawId(value)
    if not id then
        return nil
    end
    return id
end

function effect_support_registry.normalizeEffectParams(effect, entry)
    if type(effect) ~= "table" then
        return effect
    end
    local info = entry or effect_support_registry.mergeInfo(effect.id)
    if not info then
        return effect
    end
    local params = type(effect.params) == "table" and effect.params or nil
    local attribute = effect.affectedAttribute
        or effect.attribute
        or (params and (params.affectedAttribute or params.attribute))
    local skill = effect.affectedSkill
        or effect.skill
        or (params and (params.affectedSkill or params.skill))
    if info.hasAttribute == true then
        effect.affectedAttribute = normalizeParamId(attribute)
        effect.affectedSkill = nil
    elseif info.hasSkill == true then
        effect.affectedSkill = normalizeParamId(skill)
        effect.affectedAttribute = nil
    else
        effect.affectedAttribute = nil
        effect.affectedSkill = nil
    end
    effect.id = effect_support_registry.normalizeEffectId(effect.id)
    return effect
end

function effect_support_registry.validateEffectParams(effect, entry)
    local info = entry or effect_support_registry.mergeInfo(effect and effect.id)
    if not info then
        return false, "effect_unknown", "effect metadata is unavailable"
    end
    local attribute = normalizeParamId(effect and effect.affectedAttribute)
    local skill = normalizeParamId(effect and effect.affectedSkill)
    if info.hasAttribute == true then
        if not attribute then
            return false, "missing_attribute_parameter", string.format("%s requires an affected attribute", tostring(info.display_name or info.id))
        end
        if not VALID_ATTRIBUTES[attribute] then
            return false, "invalid_attribute_parameter", string.format("invalid affected attribute: %s", tostring(effect and effect.affectedAttribute))
        end
    elseif attribute then
        return false, "unexpected_attribute_parameter", string.format("%s does not accept an affected attribute", tostring(info.display_name or info.id))
    end
    if info.hasSkill == true then
        if not skill then
            return false, "missing_skill_parameter", string.format("%s requires an affected skill", tostring(info.display_name or info.id))
        end
        if not VALID_SKILLS[skill] then
            return false, "invalid_skill_parameter", string.format("invalid affected skill: %s", tostring(effect and effect.affectedSkill))
        end
    elseif skill then
        return false, "unexpected_skill_parameter", string.format("%s does not accept an affected skill", tostring(info.display_name or info.id))
    end
    return true, nil, nil
end

function effect_support_registry.attributeOptions()
    return cloneValue(ATTRIBUTE_OPTIONS, 0)
end

function effect_support_registry.skillOptions()
    return cloneValue(SKILL_OPTIONS, 0)
end

function effect_support_registry.parameterDisplayName(kind, id)
    local normalized = normalizeParamId(id)
    local source = kind == "skill" and SKILL_OPTIONS or ATTRIBUTE_OPTIONS
    for _, entry in ipairs(source) do
        if entry.id == normalized then
            return entry.display_name
        end
    end
    return id
end

function effect_support_registry.aliases()
    return cloneValue(LEGACY_ALIASES, 0)
end

return effect_support_registry
