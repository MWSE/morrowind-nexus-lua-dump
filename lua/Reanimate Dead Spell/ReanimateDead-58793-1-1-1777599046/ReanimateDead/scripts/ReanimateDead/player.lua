local self = require('openmw.self')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local ui = require('openmw.ui')
local storage = require('openmw.storage')
local animation = require('openmw.animation')
local Settings = require('openmw.interfaces').Settings
local C = require('scripts.ReanimateDead.common')

-- registerPage is player/menu only (not bound for global). The Spell
-- group is registered here (not in global.lua) because load.lua needs
-- to read it, and LOAD-context storage exposes only playerSection
-- (verified in components/lua/storage.cpp `initLoadPackage`).
Settings.registerPage({
    key = C.SETTINGS.PAGE,
    l10n = C.L10N,
    name = 'settings_page_name',
    description = 'settings_page_description',
})

Settings.registerGroup({
    key = C.SETTINGS.SECTION_SPELL,
    page = C.SETTINGS.PAGE,
    l10n = C.L10N,
    name = 'group_spell_name',
    description = 'group_spell_description',
    permanentStorage = true,
    order = 0,
    settings = {
        {
            key = 'duration',
            renderer = 'number',
            name = 'setting_duration_name',
            description = 'setting_duration_description',
            default = 30,
            argument = { integer = true, min = 5, max = 600 },
        },
        {
            key = 'magnitude',
            renderer = 'number',
            name = 'setting_magnitude_name',
            description = 'setting_magnitude_description',
            default = 5,
            argument = { integer = true, min = 1, max = 100 },
        },
        {
            key = 'baseCost',
            renderer = 'number',
            name = 'setting_base_cost_name',
            description = 'setting_base_cost_description',
            default = 20,
            argument = { integer = true, min = 1, max = 200 },
        },
        {
            key = 'radiusFeet',
            renderer = 'number',
            name = 'setting_radius_feet_name',
            description = 'setting_radius_feet_description',
            default = 30,
            argument = { integer = true, min = 1, max = 100 },
        },
    },
})

local spellSettings = storage.playerSection(C.SETTINGS.SECTION_SPELL)
-- Player scripts can read globalSection (storage.cpp:188-190
-- `initLocalPackage`).
local behaviorSettings = storage.globalSection(C.SETTINGS.SECTION_BEHAVIOR)

local l10n = core.l10n(C.L10N)

local rejectionShownThisCast = false

local function showRejection(key, corpse)
    if rejectionShownThisCast then return end
    rejectionShownThisCast = true
    ui.showMessage(l10n(key))
    -- world.vfx.spawn is global-only, so route the considered-corpse
    -- flash through global.lua. Re-rise rejections come from global
    -- and have already spawned their own VFX, so they pass corpse=nil.
    if corpse then
        core.sendGlobalEvent(C.EVENTS.SPAWN_CONSIDERED_VFX, { corpse = corpse })
    end
end

local EFFECT_ID = C.EFFECT_ID

-- The 22 is the engine's `static_cast<int>(std::ceil(Constants::UnitsPerFoot))`
-- (UnitsPerFoot = 21.33333333). Hardcoded because Misc::Constants isn't
-- exposed in any Lua namespace (verified in util.cpp, corebindings.cpp).
local UNITS_PER_FOOT = 22
local function radiusFeet() return spellSettings:get('radiusFeet') or 30 end
local function radiusUnits() return radiusFeet() * UNITS_PER_FOOT end

-- Corpse selection runs in Lua because OpenMW's AoE (and projectile
-- collision) skip dead actors. activeSpellId is stable across
-- save/load (verified by probe), so it doubles as the binding handle
-- between caster and minion.
local seenActiveSpellIds = {}

-- Match by effect id rather than spell id: the same effect can come
-- from a cast (`params.id == spell record id`), an enchantment
-- (`params.id == enchantment record id`), or constant-effect gear.
local function findOurActiveSpells()
    local result = {}
    for _, params in pairs(types.Actor.activeSpells(self)) do
        for _, effect in pairs(params.effects or {}) do
            if effect.id == EFFECT_ID then
                table.insert(result, params)
                break
            end
        end
    end
    return result
end

local function getSourceRecord(activeSpell)
    local spellRec = core.magic.spells.records[activeSpell.id]
    if spellRec then return spellRec end

    local item = activeSpell.item
    if item and item.type and item.type.record then
        local itemRec = item.type.record(item)
        if itemRec and itemRec.enchant then
            return core.magic.enchantments.records[itemRec.enchant]
        end
    end
    return nil
end

-- Fallback for when the active effect doesn't materialize a value:
-- in 0.51 RC, `effect.magnitude` is sometimes nil when min == max.
local function sourceEffectField(activeSpell, field)
    local rec = getSourceRecord(activeSpell)
    if rec and rec.effects then
        for _, e in pairs(rec.effects) do
            if e.id == EFFECT_ID then return e[field] end
        end
    end
    return nil
end

local function getMagnitude(activeSpell)
    for _, effect in pairs(activeSpell.effects) do
        if effect.id == EFFECT_ID then
            if effect.magnitude then return effect.magnitude end
            if effect.magnitudeBase then return effect.magnitudeBase end
            break
        end
    end
    return sourceEffectField(activeSpell, 'magnitudeMax') or 0
end

-- `types.Actor.stats` is a namespace, not a function: per-stat
-- accessors are nested functions taking the actor —
-- `types.Actor.stats.level(actor)`, not `types.Actor.stats(actor).level`.
local function getActorLevel(actor)
    local ok, stat = pcall(function()
        return types.Actor.stats.level(actor)
    end)
    if ok and stat and stat.current then return stat.current end
    return 1
end

local function scanCorpses(activeSpell, activeSpellId, magnitude)
    local origin = self.position
    rejectionShownThisCast = false

    local radiusUnitsLocal = radiusUnits()
    local closest, closestDist
    for _, actor in ipairs(nearby.actors) do
        if actor.id ~= self.id
            and actor.enabled
            and types.Actor.isDead(actor)
        then
            local dist = (actor.position - origin):length()
            if dist <= radiusUnitsLocal and (not closestDist or dist < closestDist) then
                closest = actor
                closestDist = dist
            end
        end
    end

    if not closest then
        showRejection(C.L10N_KEYS.NO_CORPSES_NEARBY)
        return
    end

    local allowDaedra = behaviorSettings:get('raiseDaedra')
    local allowUndead = behaviorSettings:get('raiseUndead')
    local level = getActorLevel(closest)
    -- `Creature.record(corpse).type` is one of 'Creatures', 'Daedra',
    -- 'Humanoid', 'Undead'. NPC records have no equivalent enum, so
    -- creatureType stays nil for NPC corpses.
    local creatureType = nil
    if closest.type == types.Creature then
        local ok, rec = pcall(types.Creature.record, closest)
        if ok and rec then creatureType = rec.type end
    end
    local CT = types.Creature.TYPE

    if creatureType == CT.Daedra and not allowDaedra then
        showRejection(C.L10N_KEYS.NO_EFFECT_DAEDRA, closest)
        return
    end
    if creatureType == CT.Undead and not allowUndead then
        showRejection(C.L10N_KEYS.NO_EFFECT_UNDEAD, closest)
        return
    end
    if level > magnitude then
        showRejection(C.L10N_KEYS.NO_EFFECT_TOO_POWERFUL, closest)
        return
    end

    -- Death plays on all bones (full-body anim with autoDisable=false
    -- in character.cpp:867), so any BONE_GROUP works as the query —
    -- LowerBody is always present on humanoid + creature skeletons.
    local deathAnim = nil
    local ok, group = pcall(animation.getActiveGroup, closest, animation.BONE_GROUP.LowerBody)
    if ok and group and group ~= '' then
        deathAnim = group
    end

    core.sendGlobalEvent(C.EVENTS.CAST, {
        caster = self,
        corpses = { closest },
        activeSpellId = activeSpellId,
        deathAnim = deathAnim,
    })
end

-- Triggered by global.lua when a filter that lives there rejects a
-- corpse. Used because `hasScript` is GObject-only, so the check can't
-- run from this player script.
local function onShowRejection(data)
    if data and data.key then showRejection(data.key) end
end

local function onUpdate()
    local current = findOurActiveSpells()
    local currentIds = {}
    for _, params in ipairs(current) do
        currentIds[params.activeSpellId] = true
        if not seenActiveSpellIds[params.activeSpellId] then
            seenActiveSpellIds[params.activeSpellId] = true
            scanCorpses(params, params.activeSpellId, getMagnitude(params))
        end
    end
    for id in pairs(seenActiveSpellIds) do
        if not currentIds[id] then
            seenActiveSpellIds[id] = nil
        end
    end
end

local function onLoad()
    -- The engine restores active spells with their persisted
    -- activeSpellIds, so pre-seed the seen set to suppress
    -- false-triggers on already-active sources from before the save.
    seenActiveSpellIds = {}
    for _, params in ipairs(findOurActiveSpells()) do
        seenActiveSpellIds[params.activeSpellId] = true
    end
end

-- The Lua `expel` binding hardcodes printMessage=false
-- (mwlua/types/npc.cpp:462), suppressing the engine's expulsion
-- notification — we replay it ourselves from PLAYER context, where
-- openmw.ui is bound.
local function onShowExpelMessage(data)
    if data and data.message then
        ui.showMessage(data.message)
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onLoad = onLoad,
    },
    eventHandlers = {
        [C.EVENTS.SHOW_REJECTION] = onShowRejection,
        [C.EVENTS.SHOW_EXPEL_MESSAGE] = onShowExpelMessage,
    },
}
