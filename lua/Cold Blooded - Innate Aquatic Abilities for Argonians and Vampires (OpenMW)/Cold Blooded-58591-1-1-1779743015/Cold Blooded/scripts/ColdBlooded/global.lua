--[[
    Cold Blooded - Global Script

    Applies always-on passive aquatic effects to NPCs:
      - Water Breathing for Argonians and Vampires
      - Swift Swim for Argonians

    Settings are registered and owned by the player script (player
    section). The player script pushes settings snapshots to us via
    the ColdBlooded_SettingsChanged event; we cache the latest
    snapshot and apply its values to all tracked NPCs on every
    change.

    NPC effects are tracked per actor id and persisted through
    onSave/onLoad so save/load, cell reload, and reloadlua do not
    accumulate magnitude on re-activation.

    Underwater-state-dependent features (Night Eye, fatigue regen,
    vampire sun-shelter ability swapping) live in the player script,
    because depth-of-submersion is only meaningful there.
]]

local core  = require('openmw.core')
local types = require('openmw.types')

local SAVE_SCHEMA_VERSION = 2

-- -----------------------------------------------------------------
-- Cached settings. Values arrive via ColdBlooded_SettingsChanged
-- events from the player script. Until the first event arrives
-- (e.g. early in a new game before onLoad has run), defaults
-- drive behaviour.
-- -----------------------------------------------------------------

local function defaultSettings()
    return {
        enabled         = true,
        breathArgonian  = true,
        breathVampire   = true,
        swiftSwim       = true,
        swimBonus       = 25,
    }
end

local settings = defaultSettings()

-- -----------------------------------------------------------------
-- NPC state tracking
-- -----------------------------------------------------------------

local activeNpcs = {}

local function positiveNumber(value)
    local num = tonumber(value) or 0
    if num < 0 then return 0 end
    return num
end

local function isArgonianNpc(actor)
    local record = types.NPC.record(actor)
    return record and record.race and record.race:lower() == "argonian"
end

local function isVampireActor(actor)
    local effects = types.Actor.activeEffects(actor)
    if not effects then return false end
    local eff = effects:getEffect(core.magic.EFFECT_TYPE.Vampirism)
    return eff and eff.magnitude and eff.magnitude > 0
end

local function applyDelta(actor, effectId, currentApplied, targetMagnitude)
    currentApplied = positiveNumber(currentApplied)
    targetMagnitude = positiveNumber(targetMagnitude)
    local delta = targetMagnitude - currentApplied
    if delta == 0 then return currentApplied end
    local effects = types.Actor.activeEffects(actor)
    if not effects then return currentApplied end
    effects:modify(delta, effectId)
    return targetMagnitude
end

local function computeTargets(actor)
    if not settings.enabled then
        return 0, 0
    end

    local argonian = isArgonianNpc(actor)
    local vampire  = isVampireActor(actor)

    local breath = 0
    if (argonian and settings.breathArgonian)
       or (vampire and settings.breathVampire) then
        breath = 1
    end

    local swim = 0
    if argonian and settings.swiftSwim then
        local bonus = positiveNumber(settings.swimBonus)
        if bonus > 0 then swim = bonus end
    end

    return breath, swim
end

local function refreshNpc(entry)
    local actor = entry.obj
    if not actor or not actor:isValid() then
        entry.obj = nil
        return
    end
    local breathTarget, swimTarget = computeTargets(actor)
    entry.breath = applyDelta(actor, core.magic.EFFECT_TYPE.WaterBreathing,
                              entry.breath, breathTarget)
    entry.swim   = applyDelta(actor, core.magic.EFFECT_TYPE.SwiftSwim,
                              entry.swim,   swimTarget)
end

local function clearNpc(entry)
    local actor = entry.obj
    if not actor or not actor:isValid() then
        entry.obj = nil
        return
    end
    entry.breath = applyDelta(actor, core.magic.EFFECT_TYPE.WaterBreathing,
                              entry.breath, 0)
    entry.swim   = applyDelta(actor, core.magic.EFFECT_TYPE.SwiftSwim,
                              entry.swim,   0)
end

local function refreshAllNpcs()
    for _, entry in pairs(activeNpcs) do
        refreshNpc(entry)
    end
end

local function actorKey(actor)
    return actor and actor.id
end

-- -----------------------------------------------------------------
-- Persistence
-- -----------------------------------------------------------------

local function exportNpcState()
    local saved = {}
    for id, entry in pairs(activeNpcs) do
        local breath = positiveNumber(entry.breath)
        local swim = positiveNumber(entry.swim)
        if breath > 0 or swim > 0 then
            saved[id] = { breath = breath, swim = swim }
        end
    end
    return saved
end

local function importNpcState(saved)
    activeNpcs = {}
    if type(saved) ~= "table" then return end
    for id, entry in pairs(saved) do
        if type(entry) == "table" then
            activeNpcs[id] = {
                obj    = nil,
                breath = positiveNumber(entry.breath),
                swim   = positiveNumber(entry.swim),
            }
        end
    end
end

local function exportSettings()
    return {
        enabled         = settings.enabled,
        breathArgonian  = settings.breathArgonian,
        breathVampire   = settings.breathVampire,
        swiftSwim       = settings.swiftSwim,
        swimBonus       = settings.swimBonus,
    }
end

local function importSettings(saved)
    settings = defaultSettings()
    if type(saved) ~= "table" then return end
    for k, v in pairs(saved) do
        if settings[k] ~= nil or k == "swimBonus" then
            settings[k] = v
        end
    end
end

-- -----------------------------------------------------------------
-- Engine handlers
-- -----------------------------------------------------------------

local function onActorActive(actor)
    if not types.NPC.objectIsInstance(actor) then return end

    local id = actorKey(actor)
    if not id then return end

    local entry = activeNpcs[id]
    local shouldTrack = isArgonianNpc(actor) or isVampireActor(actor)

    if not shouldTrack then
        if entry then
            entry.obj = actor
            clearNpc(entry)
            activeNpcs[id] = nil
        end
        return
    end

    if not entry then
        entry = { obj = actor, breath = 0, swim = 0 }
        activeNpcs[id] = entry
    else
        -- Reactivation: keep persisted magnitudes and only refresh the
        -- object reference. This prevents re-adding effects already
        -- present on the actor after save/load or cell reload.
        entry.obj = actor
    end
    refreshNpc(entry)
end

local function onInit()
    settings = defaultSettings()
    activeNpcs = {}
end

local function onLoad(data)
    if type(data) == "table" then
        importSettings(data.settings)
        importNpcState(data.npcs)
    else
        settings = defaultSettings()
        activeNpcs = {}
    end
end

local function onSave()
    return {
        schemaVersion = SAVE_SCHEMA_VERSION,
        settings = exportSettings(),
        npcs = exportNpcState(),
    }
end

-- -----------------------------------------------------------------
-- Event handlers: settings push from player
-- -----------------------------------------------------------------

local function onSettingsChanged(data)
    if type(data) ~= "table" then return end
    -- Accept a whole snapshot. Any missing fields retain their
    -- current values.
    for k, v in pairs(data) do
        if settings[k] ~= nil or k == "swimBonus" then
            settings[k] = v
        end
    end
    refreshAllNpcs()
end

return {
    engineHandlers = {
        onActorActive = onActorActive,
        onInit        = onInit,
        onLoad        = onLoad,
        onSave        = onSave,
    },
    eventHandlers = {
        ColdBlooded_SettingsChanged = onSettingsChanged,
    },
}
