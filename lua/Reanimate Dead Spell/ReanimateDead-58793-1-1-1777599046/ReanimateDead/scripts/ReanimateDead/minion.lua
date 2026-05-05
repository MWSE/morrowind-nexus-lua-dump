local self = require('openmw.self')
local core = require('openmw.core')
local types = require('openmw.types')
local animation = require('openmw.animation')
local async = require('openmw.async')
local storage = require('openmw.storage')
local AI = require('openmw.interfaces').AI
local C = require('scripts.ReanimateDead.common')

-- Local scripts can read globalSection without write permission.
local effectsSettings = storage.globalSection(C.SETTINGS.SECTION_EFFECTS)
local behaviorSettings = storage.globalSection(C.SETTINGS.SECTION_BEHAVIOR)

-- The aura ships a recolored copy of the engine's soultraphit.nif
-- with renamed texture references (see tools/recolor_aura.py). The
-- rename keeps the recolor scoped to this mod so Sanctuary, ambient
-- Soul Trap, and other Mysticism flares keep their vanilla purple.
local AURA_VFX_ID = 'raise_aura'
local AURA_MODEL = 'meshes/raise_aura.nif'

-- Resolves the VFX via the Static record (matching what the engine
-- does in mwmechanics/summoning.cpp), so the path tracks whatever the
-- engine itself resolves. `particleTexture` swaps the particle texture
-- without needing a new model.
local function playStaticVfx(staticId, opts)
    opts = opts or {}
    pcall(function()
        local rec = types.Static.records[staticId]
        if rec and rec.model then
            animation.addVfx(self, rec.model, {
                particleTextureOverride = opts.particleTexture,
                loop = opts.loop,
                vfxId = opts.vfxId,
            })
        end
    end)
end

local auraStarted = false

local function startAura()
    if auraStarted then return end
    pcall(function()
        animation.addVfx(self, AURA_MODEL, {
            loop = true,
            vfxId = AURA_VFX_ID,
        })
    end)
    auraStarted = true
end

local function stopAura()
    if not auraStarted then return end
    pcall(function() animation.removeVfx(self, AURA_VFX_ID) end)
    auraStarted = false
end

-- `addVfx`/`removeVfx` aren't documented as no-ops on repeat, so the
-- `auraStarted` flag gates them.
local function reconcileAura()
    if effectsSettings:get('aura') then
        startAura()
    else
        stopAura()
    end
end

-- Self-writes to dynamic stats work; cross-actor writes from a global
-- script don't. Setting `health.current = 0` from the minion's own
-- script is the cleanest termination path.
local caster = nil
local myActiveSpellId = nil
local killed = false
-- {slot = recordId} snapshot. Inventory transfer is deferred a frame
-- (see global.lua), so applying this during onInit would fail; onUpdate
-- retries setEquipment until each slot reports a matching recordId.
local pendingEquipment = nil
-- The engine constructs MWRender::Animation later in the frame than
-- addScript fires onInit, so synchronous animation calls at onInit
-- throw "Object has no animation" (mwworld/worldimp.cpp:2295
-- `World::getAnimation` returning null, which the binding's
-- `getConstAnimationOrThrow` turns into an exception). onActive fires
-- after the actor is added to the scene, so the rise anim is parked
-- here and consumed there. Cleared after first use so cell-reload
-- onActive doesn't replay it.
local pendingRaiseAnim = nil
-- Persisted so a save during the raise window — before the unsavable
-- raise timer has fired — can recover on load and still start the AI
-- package. Otherwise the minion would be stuck with default
-- skeleton/NPC AI.
local aiStarted = false

local function killSelf()
    playStaticVfx(C.VFX.SUMMON_END, { particleTexture = C.VFX.PARTICLE_TEXTURE })
    stopAura()
    pcall(function()
        types.Actor.stats.dynamic.health(self).current = 0
    end)
    killed = true
end

-- Negative speed plays the death anim backward; the cancel timer in
-- playRaiseAnimation divides by abs(RAISE_SPEED), so rescaling here
-- adjusts that automatically.
local RAISE_SPEED = -2.0

-- `sideWithTarget` flips alliance: the minion treats the caster as an
-- ally and the caster's enemies as its own targets, instead of the
-- vanilla skeleton/NPC default of being hostile to the player.
-- Idempotent via `aiStarted` — safe from both the raise-completion
-- timer and the onLoad recovery path.
local function startFollow()
    if aiStarted then return end
    if not caster then return end
    AI.startPackage({
        type = 'Follow',
        target = caster,
        sideWithTarget = true,
    })
    aiStarted = true
end

-- Play the corpse's death animation in reverse as a "rise" effect.
-- Verified against engine source:
--   * Negative speed: `Animation::runAnimation` (mwrender/animation.cpp:1356)
--     drives time backward via `timepassed = duration * mSpeedMult`,
--     but `mPlaying = (getTime() < mStopTime)` (line 1375) stays true
--     as time decreases past mStartTime — the engine never auto-stops
--     a reverse-playing animation, so we cancel via timer.
--   * `Animation::reset` (animation.cpp:1011) refuses when
--     startKey > stopKey, so reverse playback can't be done by
--     swapping keys — we use forward keys with negative speed and
--     startPoint near 1.0.
--   * startPoint must be < 1.0: at 1.0, `Play()` sets
--     `time = mStopTime` and `mPlaying = (time < mStopTime) = false`
--     (animation.cpp:934), so runAnimation never advances.
--   * `PRIORITY.Scripted` overrides default-priority idle/movement
--     anims the newly-spawned minion is in.
-- Contract: `onComplete` is called exactly once — synchronously on
-- any short-circuit, or asynchronously when the cancel timer fires.
-- The caller relies on this to start the AI follow package.
local function playRaiseAnimation(deathAnim, onComplete)
    if not deathAnim or deathAnim == '' or not animation.hasGroup(self, deathAnim) then
        onComplete()
        return
    end

    local startTime = animation.getTextKeyTime(self, deathAnim .. ': start')
    local stopTime = animation.getTextKeyTime(self, deathAnim .. ': stop')
    if not (startTime and stopTime) or stopTime <= startTime then
        onComplete()
        return
    end
    local raiseDuration = (stopTime - startTime) / math.abs(RAISE_SPEED)

    local ok = pcall(animation.playBlended, self, deathAnim, {
        priority = animation.PRIORITY.Scripted,
        blendMask = animation.BLEND_MASK.All,
        autoDisable = false,
        speed = RAISE_SPEED,
        startKey = 'start',
        stopKey = 'stop',
        startPoint = 0.99,
    })
    if not ok then
        onComplete()
        return
    end

    -- The unsavable timer takes a function directly without the
    -- `registerTimerCallback` dance `newSimulationTimer` requires
    -- (asyncpackage.cpp:84). Save-during-raise is handled by the
    -- persisted `aiStarted` flag + onLoad recovery instead.
    async:newUnsavableSimulationTimer(raiseDuration, function()
        pcall(animation.cancel, self, deathAnim)
        onComplete()
    end)
end

local function onInit(data)
    if not data or not data.caster or not data.activeSpellId then
        killSelf()
        return
    end
    caster = data.caster
    myActiveSpellId = data.activeSpellId
    if data.equipMap and next(data.equipMap) then
        pendingEquipment = data.equipMap
    end
    -- `addVfx` is queued via `context.mLuaManager->addAction`
    -- (animationbindings.cpp:246), so it tolerates being called
    -- before the actor's MWRender::Animation exists — the queued
    -- action fires later when the actor enters the scene.
    -- `hasGroup`/`getTextKeyTime`/`playBlended` are synchronous and
    -- have no such escape hatch, hence the rise anim deferral via
    -- pendingRaiseAnim.
    playStaticVfx(C.VFX.SUMMON_START, { particleTexture = C.VFX.PARTICLE_TEXTURE })
    pendingRaiseAnim = data.deathAnim
    reconcileAura()
end

local function onSave()
    return {
        caster = caster,
        activeSpellId = myActiveSpellId,
        pendingEquipment = pendingEquipment,
        aiStarted = aiStarted,
    }
end

local function onLoad(saved)
    if saved then
        caster = saved.caster
        myActiveSpellId = saved.activeSpellId
        pendingEquipment = saved.pendingEquipment
        aiStarted = saved.aiStarted or false
    end
    -- Looped renderer VFX are transient scene-graph state and don't
    -- survive save/load — restart the aura.
    if not types.Actor.isDead(self) then
        reconcileAura()
        -- Save-during-raise recovery: the unsavable raise timer that
        -- would have called startFollow is gone after deserialization.
        if not aiStarted then
            startFollow()
        end
    end
end

-- The engine's `Objects::removeCell` / `removeObject`
-- (mwrender/objects.cpp) destroys the MWRender::Animation that holds
-- the aura's scene-graph nodes, but Lua locals persist on
-- `RefData::getLuaScripts()`. Clearing the flag here ensures the
-- next onActive re-adds the VFX to the freshly-built Animation.
local function onInactive()
    auraStarted = false
end

-- onActive is the first event guaranteed to fire after the actor's
-- MWRender::Animation exists, so it's the deferred trigger point for
-- the rise anim that onInit can't safely call.
-- `engine.addEffect` is idempotent for matching looped effects
-- (mwrender/animation.cpp:1714 — early-out when a non-finished looped
-- VFX with the same effectId/bone is already attached), so the
-- onInit-then-onActive double-call on the aura is safe.
local function onActive()
    if pendingRaiseAnim then
        local deathAnim = pendingRaiseAnim
        pendingRaiseAnim = nil
        playRaiseAnimation(deathAnim, startFollow)
    end
    if not types.Actor.isDead(self) then
        reconcileAura()
    end
end

local function isOurInstanceStillActive()
    if not caster or not caster:isValid() then return false end
    for _, params in pairs(types.Actor.activeSpells(caster)) do
        if params.activeSpellId == myActiveSpellId then
            return true
        end
    end
    return false
end

local function applyPendingEquipment()
    if not pendingEquipment then return end

    local inv = types.Actor.inventory(self)
    if not inv or #inv:getAll() == 0 then return end

    pcall(types.Actor.setEquipment, self, pendingEquipment)

    -- The engine silently leaves a slot unequipped if the requested
    -- item isn't in inventory yet, so verify against the post-call
    -- state and retry next frame if any slot is missing.
    local current = types.Actor.getEquipment(self)
    if not current then return end
    for slot, recordId in pairs(pendingEquipment) do
        local equipped = current[slot]
        if not (equipped and equipped.recordId == recordId) then
            return
        end
    end
    pendingEquipment = nil
end

local function onUpdate()
    if killed then return end
    -- `killed` is a script-local that resets every load, so this
    -- isDead check is what actually short-circuits cell re-entry on
    -- already-dead minions. Also covers external-kill cleanup of the
    -- looped aura (killSelf handles the duration-expiry path).
    if types.Actor.isDead(self) then
        stopAura()
        killed = true
        return
    end
    -- Pre-raise AI suppression. Two engine behaviors otherwise produce
    -- unwanted movement before the raise timer fires:
    --   1. `template` copies the source's `mAiPackage` list, so the
    --      minion may spawn carrying inherited Wander/Travel.
    --   2. MWMechanics auto-adds AiCombat when the minion sees the
    --      (still faction-hostile) player — the cloned record keeps
    --      the original's faction membership.
    -- Stripping the AiSequence each frame until startFollow runs
    -- keeps the minion stationary during the rise.
    if not aiStarted then
        AI.removePackages()
    end
    if not caster or not myActiveSpellId then
        killSelf()
        return
    end
    applyPendingEquipment()
    reconcileAura()
    -- Suppress subtitles AND voice barks (greeting, idle, attack, hit,
    -- flee). `DialogueManager::say` (mwdialogue/dialoguemanagerimp.cpp:625)
    -- shows the subtitle via `winMgr->messageBox(info->mResponse)` at
    -- line 656 BEFORE queueing the audio at line 658, so polling
    -- `stopSay` only kills the sound — the subtitle is already on
    -- screen by then. The first short-circuit in `say()` (line 628) is
    -- `if (sndMgr->sayActive(actor)) return false;`, exiting before
    -- BOTH the messageBox and the audio. We keep the say slot occupied
    -- with a silent WAV (sound/rd_silence.wav, tools/make_silence.py)
    -- and requeue when `sayActive` flips false. This is the only
    -- Lua-reachable subtitle suppression: no per-actor subtitle
    -- disable, no API to dismiss a queued messageBox, and the
    -- DialogueResponse Lua event fires after the messageBox is
    -- already shown (luamanagerimp.cpp:489-509).
    if behaviorSettings:get('suppressDialog') and not core.sound.isSayActive(self) then
        pcall(core.sound.say, 'sound/rd_silence.wav', self)
    end
    if not isOurInstanceStillActive() then
        killSelf()
    end
end

return {
    engineHandlers = {
        onInit = onInit,
        onSave = onSave,
        onLoad = onLoad,
        onActive = onActive,
        onInactive = onInactive,
        onUpdate = onUpdate,
    },
}
