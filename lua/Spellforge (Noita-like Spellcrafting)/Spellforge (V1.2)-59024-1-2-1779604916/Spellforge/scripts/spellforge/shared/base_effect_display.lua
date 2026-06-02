local effect_registry = require("scripts.spellforge.shared.effect_support_registry")

local base_effect_display = {}

local BASE_EFFECTS = {
    { id = "absorbhealth", display_name = "Absorb Health", school = "mysticism" },
    { id = "blind", display_name = "Blind", school = "illusion" },
    { id = "boundbattleaxe", display_name = "Bound Battle Axe", school = "conjuration" },
    { id = "boundboots", display_name = "Bound Boots", school = "conjuration" },
    { id = "boundcuirass", display_name = "Bound Cuirass", school = "conjuration" },
    { id = "bounddagger", display_name = "Bound Dagger", school = "conjuration" },
    { id = "boundgloves", display_name = "Bound Gloves", school = "conjuration" },
    { id = "boundhelm", display_name = "Bound Helm", school = "conjuration" },
    { id = "boundlongbow", display_name = "Bound Longbow", school = "conjuration" },
    { id = "boundlongsword", display_name = "Bound Longsword", school = "conjuration" },
    { id = "boundmace", display_name = "Bound Mace", school = "conjuration" },
    { id = "boundshield", display_name = "Bound Shield", school = "conjuration" },
    { id = "boundspear", display_name = "Bound Spear", school = "conjuration" },
    { id = "burden", display_name = "Burden", school = "alteration" },
    { id = "chameleon", display_name = "Chameleon", school = "illusion" },
    { id = "damagehealth", display_name = "Damage Health", school = "destruction" },
    { id = "detectanimal", display_name = "Detect Animal", school = "mysticism" },
    { id = "detectenchantment", display_name = "Detect Enchantment", school = "mysticism" },
    { id = "detectkey", display_name = "Detect Key", school = "mysticism" },
    { id = "drainhealth", display_name = "Drain Health", school = "destruction" },
    { id = "feather", display_name = "Feather", school = "alteration" },
    { id = "firedamage", display_name = "Fire Damage", school = "destruction" },
    { id = "fireshield", display_name = "Fire Shield", school = "alteration" },
    { id = "fortifyattribute", display_name = "Fortify Attribute", school = "restoration" },
    { id = "fortifyfatigue", display_name = "Fortify Fatigue", school = "restoration" },
    { id = "fortifyhealth", display_name = "Fortify Health", school = "restoration" },
    { id = "fortifymagicka", display_name = "Fortify Magicka", school = "restoration" },
    { id = "fortifymaximummagicka", display_name = "Fortify Maximum Magicka", school = "restoration" },
    { id = "frostdamage", display_name = "Frost Damage", school = "destruction" },
    { id = "frostshield", display_name = "Frost Shield", school = "alteration" },
    { id = "invisibility", display_name = "Invisibility", school = "illusion" },
    { id = "jump", display_name = "Jump", school = "alteration" },
    { id = "levitate", display_name = "Levitate", school = "alteration" },
    { id = "lightningshield", display_name = "Lightning Shield", school = "alteration" },
    { id = "open", display_name = "Open", school = "alteration" },
    { id = "paralyze", display_name = "Paralyze", school = "illusion" },
    { id = "poison", display_name = "Poison", school = "destruction" },
    { id = "resistfire", display_name = "Resist Fire", school = "restoration" },
    { id = "resistfrost", display_name = "Resist Frost", school = "restoration" },
    { id = "resistmagicka", display_name = "Resist Magicka", school = "restoration" },
    { id = "resistpoison", display_name = "Resist Poison", school = "restoration" },
    { id = "resistshock", display_name = "Resist Shock", school = "restoration" },
    { id = "restorefatigue", display_name = "Restore Fatigue", school = "restoration" },
    { id = "restorehealth", display_name = "Restore Health", school = "restoration" },
    { id = "restoremagicka", display_name = "Restore Magicka", school = "restoration" },
    { id = "shield", display_name = "Shield", school = "alteration" },
    { id = "shockdamage", display_name = "Shock Damage", school = "destruction" },
    { id = "silence", display_name = "Silence", school = "illusion" },
    { id = "slowfall", display_name = "Slowfall", school = "alteration" },
    { id = "summonancestralghost", display_name = "Summon Ancestral Ghost", school = "conjuration" },
    { id = "summonbonelord", display_name = "Summon Bonelord", school = "conjuration" },
    { id = "summongreaterbonewalker", display_name = "Summon Greater Bonewalker", school = "conjuration" },
    { id = "summonbonewalker", display_name = "Summon Bonewalker", school = "conjuration" },
    { id = "summonscamp", display_name = "Summon Scamp", school = "conjuration" },
    { id = "summonskeletalminion", display_name = "Summon Skeletal Minion", school = "conjuration" },
    { id = "telekinesis", display_name = "Telekinesis", school = "mysticism" },
    { id = "waterbreathing", display_name = "Water Breathing", school = "alteration" },
    { id = "waterwalking", display_name = "Water Walking", school = "alteration" },
    { id = "weaknesstofire", display_name = "Weakness to Fire", school = "destruction" },
    { id = "weaknesstofrost", display_name = "Weakness to Frost", school = "destruction" },
    { id = "weaknesstopoison", display_name = "Weakness to Poison", school = "destruction" },
    { id = "weaknesstoshock", display_name = "Weakness to Shock", school = "destruction" },
}

local by_id = nil

local function normalizeId(value)
    return effect_registry.normalizeEffectId(value)
end

local function cloneEntry(entry)
    if type(entry) ~= "table" then
        return nil
    end
    return {
        id = entry.id,
        display_name = entry.display_name,
        school = entry.school,
        proxy_id = entry.proxy_id,
        hasAttribute = entry.hasAttribute,
        hasSkill = entry.hasSkill,
    }
end

local function parameterizedDisplayName(base_name, kind, parameter_name)
    local text = tostring(base_name or "")
    local param = tostring(parameter_name or "")
    if kind == "attribute" then
        text = string.gsub(text, "Attribute", param)
    elseif kind == "skill" then
        text = string.gsub(text, "Skill", param)
    end
    if text == "" or text == base_name then
        return (base_name or "Effect") .. " " .. param
    end
    return text
end

local function addIndexedEntry(indexed, entry)
    local normalized = normalizeId(entry and entry.id)
    if not normalized then
        return
    end
    local display = effect_registry.getDisplayInfo(normalized, entry) or entry
    display.proxy_id = display.proxy_id or ("spellforge_display_base_" .. normalized)
    indexed[normalized] = display
end

local function addParameterizedEntries(indexed, entry)
    local normalized = normalizeId(entry and entry.id)
    if not normalized then
        return
    end
    if entry.hasAttribute == true then
        for _, option in ipairs(effect_registry.attributeOptions()) do
            local suffix = normalized .. "_" .. option.id
            indexed[suffix] = {
                id = normalized,
                display_name = parameterizedDisplayName(entry.display_name, "attribute", option.display_name),
                school = entry.school,
                proxy_id = "spellforge_display_base_" .. suffix,
                hasAttribute = true,
            }
        end
    elseif entry.hasSkill == true then
        for _, option in ipairs(effect_registry.skillOptions()) do
            local suffix = normalized .. "_" .. option.id
            indexed[suffix] = {
                id = normalized,
                display_name = parameterizedDisplayName(entry.display_name, "skill", option.display_name),
                school = entry.school,
                proxy_id = "spellforge_display_base_" .. suffix,
                hasSkill = true,
            }
        end
    end
end

local function index()
    if by_id then
        return by_id
    end
    by_id = {}
    for _, entry in ipairs(effect_registry.staticEffects()) do
        addIndexedEntry(by_id, entry)
        addParameterizedEntries(by_id, entry)
    end
    for _, entry in ipairs(BASE_EFFECTS) do
        addIndexedEntry(by_id, entry)
    end
    return by_id
end

function base_effect_display.normalizeId(value)
    return normalizeId(value)
end

function base_effect_display.get(effect_id)
    local id = normalizeId(effect_id)
    return cloneEntry(index()[id] or effect_registry.getDisplayInfo(id))
end

function base_effect_display.proxyEffectId(effect_id)
    local id = normalizeId(effect_id)
    local entry = index()[id]
    return entry and entry.proxy_id or nil
end

function base_effect_display.proxyEffectIdForEffect(effect)
    local id = normalizeId(effect and effect.id)
    if not id then
        return nil
    end
    local info = effect_registry.getFallbackInfo(id)
    local suffix = id
    if info and info.hasAttribute == true and effect and effect.affectedAttribute then
        suffix = id .. "_" .. tostring(effect.affectedAttribute)
    elseif info and info.hasSkill == true and effect and effect.affectedSkill then
        suffix = id .. "_" .. tostring(effect.affectedSkill)
    end
    local entry = index()[suffix] or index()[id]
    return entry and entry.proxy_id or nil
end

function base_effect_display.all()
    local indexed = index()
    local out = {}
    local keys = {}
    for id in pairs(indexed) do
        keys[#keys + 1] = id
    end
    table.sort(keys)
    for _, id in ipairs(keys) do
        out[#out + 1] = cloneEntry(indexed[id])
    end
    return out
end

return base_effect_display
