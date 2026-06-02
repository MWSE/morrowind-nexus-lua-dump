local AI    = require('openmw.interfaces').AI
local self  = require('openmw.self')
local core  = require('openmw.core')
local types = require('openmw.types')
local anim  = require('openmw.animation')
local async = require('openmw.async')

local VFX_SUMMON_START = 'VFX_Summon_Start'
local VFX_SUMMON_END   = 'VFX_Summon_End'
local VFX_PARTICLE     = 'vfx_conj_flare02.tga'

local target           = nil
local mode             = nil   -- "hostile" | "follower"
local spawnVfxPlayed   = false
local terminalHandled  = false -- true once we've initiated despawn
local despawnDeadline  = nil   -- sim time at which a follower despawns
local removalReported  = false -- ensure we only fire the global event once

-- one-shot timer generation: bump to invalidate any pending timer
local timerGen = 0

local function playStaticVfx(staticId, opts)
    opts = opts or {}
    local rec = types.Static.records[staticId]
    if rec and rec.model then
        anim.addVfx(self, rec.model, {
            particleTextureOverride = opts.particleTexture,
            loop = opts.loop,
            vfxId = opts.vfxId,
        })
    end
end

local function playSpawnVfx()
    if spawnVfxPlayed then return end
    playStaticVfx(VFX_SUMMON_START, { particleTexture = VFX_PARTICLE })
    spawnVfxPlayed = true
end

local function playDespawnVfx()
    playStaticVfx(VFX_SUMMON_END, { particleTexture = VFX_PARTICLE })
end

local function reportRemoval()
    if removalReported then return end
    removalReported = true
    core.sendGlobalEvent("Ashpit_UndeadInactive", { undead = self.object })
end

-- visible despawn: VFX, then ask global to remove + clear lockout
local function handleTerminal()
    if terminalHandled then return end
    terminalHandled = true
    timerGen = timerGen + 1

    playDespawnVfx()

    async:newUnsavableSimulationTimer(0.2, function()
        reportRemoval()
    end)
end

-- schedule a one-shot timer that fires when the follower's deadline elapses
local function scheduleFollowerDeadline()
    if mode ~= "follower" then return end
    if not despawnDeadline then return end
    if terminalHandled then return end

    local remaining = despawnDeadline - core.getSimulationTime()
    if remaining <= 0 then
        handleTerminal()
        return
    end

    timerGen = timerGen + 1
    local myGen = timerGen
    async:newUnsavableSimulationTimer(remaining, function()
        if myGen ~= timerGen then return end
        if terminalHandled then return end
        handleTerminal()
    end)
end

-- engine handlers
local function onSave()
    return {
        target          = target,
        mode            = mode,
        spawnVfxPlayed  = spawnVfxPlayed,
        terminalHandled = terminalHandled,
        despawnDeadline = despawnDeadline,
        removalReported = removalReported,
    }
end

local function onLoad(saved)
    if not saved then return end
    target          = saved.target
    mode            = saved.mode
    spawnVfxPlayed  = saved.spawnVfxPlayed or false
    terminalHandled = saved.terminalHandled or false
    despawnDeadline = saved.despawnDeadline
    removalReported = saved.removalReported or false

    -- if we already died before the save, finish the despawn now
    if types.Actor.isDead(self) and not removalReported then
        handleTerminal()
        return
    end

    if terminalHandled then return end

    -- if hostile, re-register with the global lockout
    if mode == "hostile" then
        core.sendGlobalEvent("Ashpit_RegisterHostile", { undead = self.object })
    end

    -- re-arm the follower deadline timer with whatever time remains
    if mode == "follower" then
        scheduleFollowerDeadline()
    end
end

-- event handlers
local function onBeginHostile(data)
    target = data.target
    mode   = "hostile"
    AI.startPackage({
        type   = "Combat",
        target = target,
    })
end

local function onBeginFollower(data)
    target = data.target
    mode   = "follower"
    despawnDeadline = core.getSimulationTime() + (data.duration or 300)
    AI.startPackage({
        type        = "Follow",
        target      = target,
        cancelOther = true,
    })
    scheduleFollowerDeadline()
end

local function onPlayVfxSelf()
    playSpawnVfx()
end

local function onDied()
    handleTerminal()
end

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        Ashpit_BeginHostile  = onBeginHostile,
        Ashpit_BeginFollower = onBeginFollower,
        Ashpit_PlayVFX_Self  = onPlayVfxSelf,
        Died                 = onDied,
    },
}