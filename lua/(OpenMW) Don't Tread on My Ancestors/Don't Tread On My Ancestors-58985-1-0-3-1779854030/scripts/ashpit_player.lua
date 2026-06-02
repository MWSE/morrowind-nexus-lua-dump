local self    = require('openmw.self')
local types   = require('openmw.types')
local core    = require('openmw.core')
local storage = require('openmw.storage')
local async   = require('openmw.async')
local ui      = require('openmw.ui')
local time    = require('openmw_aux.time')

local shared  = require('scripts.ashpit_shared')
local DEFAULTS = shared.DEFAULTS

local util = require('openmw.util')

local SPAWN_RING_DIST = 40

local function findDistinctSpawnPositions(origin, count)
    local accepted = {}
    if count < 1 then return accepted end

    local startAngle = math.random() * 2 * math.pi
    local step       = (2 * math.pi) / math.max(count, 3)

    for i = 0, count - 1 do
        local a = startAngle + i * step
        accepted[#accepted + 1] = origin + util.vector3(
            math.sin(a) * SPAWN_RING_DIST,
            math.cos(a) * SPAWN_RING_DIST,
            5
        )
    end
    return accepted
end

local section = storage.playerSection('SettingsAshpitUndead')

local cfg = {}

local function reloadSetting(key)
    local val = section:get(key)
    if val ~= nil then cfg[key] = val else cfg[key] = DEFAULTS[key] end
end

local function reloadAllSettings()
    for key in pairs(DEFAULTS) do
        reloadSetting(key)
    end
    cfg.SPAWN_RADIUS_SQ = cfg.SPAWN_RADIUS * cfg.SPAWN_RADIUS
end

reloadAllSettings()

local function broadcastSettings()
    local data = {}
    for k in pairs(DEFAULTS) do data[k] = cfg[k] end
    core.sendGlobalEvent('Ashpit_SettingsUpdated', data)
end

broadcastSettings()

section:subscribe(async:callback(function(_, key)
    if key then
        reloadSetting(key)
        if key == 'SPAWN_RADIUS' then
            cfg.SPAWN_RADIUS_SQ = cfg.SPAWN_RADIUS * cfg.SPAWN_RADIUS
        end
    else
        reloadAllSettings()
    end
    broadcastSettings()
end))

local function log(msg)
    if cfg.PRINT_LOG then
        print('[AshpitUndead P] ' .. msg)
    end
end

-- cell identity
local function cellKey(cell)
    if not cell then return nil end
    local name = cell.name or ''
    if cell.isExterior then
        return ('ext:%d,%d'):format(cell.gridX or 0, cell.gridY or 0)
    end
    return 'int:' .. name
end

local function cellDescriptor(cell)
    if not cell then return nil end
    return {
        name       = cell.name or '',
        isExterior = cell.isExterior and true or false,
        gridX      = cell.gridX or 0,
        gridY      = cell.gridY or 0,
    }
end

local activeAshpits   = {}
local tickAccumulator = 0
local lastCellKey     = nil

local rolledAshpits   = {}

local trackedUndead   = {}

local watchdogGen     = 0
local WATCHDOG_DELAY  = 10 * time.second

-- variable to track accumulating chance from failed rolls
local bonusChance     = 0

local function findAshpitNearby(pPos)
    local sH  = cfg.SPAWN_HEIGHT
    local sR2 = cfg.SPAWN_RADIUS_SQ
    for id, pit in pairs(activeAshpits) do
        if pit and pit:isValid() then
            if not rolledAshpits[id] then
                local fPos = pit.position
                if math.abs(fPos.z - pPos.z) < sH then
                    local dx = fPos.x - pPos.x
                    local dy = fPos.y - pPos.y
                    if dx*dx + dy*dy < sR2 then
                        return pit
                    end
                end
            end
        else
            activeAshpits[id] = nil
            rolledAshpits[id] = nil
        end
    end
    return nil
end

local function getTempleRank()
    return types.NPC.getFactionRank(self.object, shared.TEMPLE_FACTION) or 0
end

local function sameCellAsPlayer(undead)
    if not undead or not undead:isValid() then return false end
    local ucell = undead.cell
    local pcell = self.cell
    if not ucell or not pcell then return false end
    return ucell == pcell
end

local function declareLost(id)
    local entry = trackedUndead[id]
    if not entry then return end
    trackedUndead[id] = nil
    log(('Undead %s (%s) declared lost, requesting despawn'):format(id, entry.mode or '?'))
    core.sendGlobalEvent('Ashpit_DespawnLost', {
        undead = entry.obj,
        mode   = entry.mode,
    })
end

local function scheduleWatchdog()
    watchdogGen = watchdogGen + 1
    local myGen = watchdogGen
    async:newUnsavableSimulationTimer(WATCHDOG_DELAY, function()
        if myGen ~= watchdogGen then return end
        if next(trackedUndead) == nil then return end

        local lost = {}
        for id, entry in pairs(trackedUndead) do
            local obj = entry.obj
            if not obj or not obj:isValid() then
                lost[#lost + 1] = id
            elseif not sameCellAsPlayer(obj) then
                lost[#lost + 1] = id
            end
        end
        for _, id in ipairs(lost) do
            declareLost(id)
        end
    end)
end

local function checkCellChange()
    local currentCell = self.cell
    local currentKey  = cellKey(currentCell)
    if currentKey ~= lastCellKey then
        lastCellKey = currentKey
        activeAshpits = {}
        rolledAshpits = {}   -- fresh rolls on returning to a cell
        core.sendGlobalEvent('RequestAshpitScan', { cell = cellDescriptor(currentCell) })

        if next(trackedUndead) ~= nil then
            scheduleWatchdog()
        end
        return true
    end
    return false
end

local function hasActiveHostile()
    for _, entry in pairs(trackedUndead) do
        if entry.mode == "hostile" and entry.obj and entry.obj:isValid() then
            return true
        end
    end
    return false
end

local function tryTriggerSpawn(ashpit)
    -- one-shot per cell visit
    rolledAshpits[ashpit.id] = true

    local rank = getTempleRank()
    local maxRank = shared.TEMPLE_MAX_RANK
    local roll = math.random(1, 100)

    local mode
    local baseChance

    if rank >= maxRank then
        mode   = "follower"
        baseChance = cfg.FOLLOWER_CHANCE
    else
        mode   = "hostile"
        baseChance = cfg.HOSTILE_CHANCE
        if rank > 0 then
            local keep = 100 - rank * cfg.TEMPLE_REDUCTION
            if keep < 0 then keep = 0 end
            baseChance = baseChance * (keep / 100)
        end
    end

    -- add the accumulated bonus to the base chance
    local effectiveChance = baseChance + bonusChance

    if roll > effectiveChance then
        -- increase the chance for the next ashpit interaction
        bonusChance = bonusChance + 5
        log(('roll=%d chance=%.1f (base:%.1f, bonus:%d) mode=%s -- no spawn, bonus increased'):format(roll, effectiveChance, baseChance, bonusChance, mode))

        if cfg.WARN_NO_SPAWN then
            local msgList = (rank > 0) and shared.MESSAGES_WARN_INSIDE or shared.MESSAGES_WARN_OUTSIDE
            if msgList and #msgList > 0 then
                ui.showMessage(msgList[math.random(#msgList)])
            end
        end

        return
    end

    -- reset the accumulated bonus back to 0
    bonusChance = 0
    log(('roll=%d chance=%.1f mode=%s -- spawn requested, bonus reset to 0'):format(roll, effectiveChance, mode))

    local spawnCount = math.random(cfg.MIN_SPAWNS, cfg.MAX_SPAWNS)
    if spawnCount < 1 then return end

    -- spawn ring centered on the ashpit
    local positions = findDistinctSpawnPositions(ashpit.position, spawnCount)

    local playerLevel = (types.Actor.stats.level(self).current) or 1

    core.sendGlobalEvent('Ashpit_Summon', {
        actor       = self.object,
        ashpitPos   = ashpit.position,
        cellDesc    = cellDescriptor(self.cell),
        mode        = mode,
        spawnCount  = spawnCount,
        positions   = positions,
        playerLevel = playerLevel,
        followerDuration = cfg.FOLLOWER_DURATION,
    })
end

local function onUpdate(dt)
    if not cfg.MOD_ENABLED then return end

    tickAccumulator = tickAccumulator + dt
    if tickAccumulator < cfg.CHECK_TICK then return end
    tickAccumulator = tickAccumulator - cfg.CHECK_TICK

    if checkCellChange() then return end
    if next(activeAshpits) == nil then return end

    -- locked out while hostile undead from this mod are alive
    if hasActiveHostile() then return end

    local pit = findAshpitNearby(self.position)
    if pit then
        tryTriggerSpawn(pit)
    end
end

-- full replace
local function onUpdateAshpitList(pits)
    activeAshpits = {}
    if pits then
        for i = 1, #pits do
            local p = pits[i]
            if p and p:isValid() then
                activeAshpits[p.id] = p
            end
        end
    end
end

-- incremental add
local function onAddAshpit(pit)
    if pit and pit:isValid() then
        activeAshpits[pit.id] = pit
    end
end

-- global tells us about each spawned undead so we can watchdog it.
local function onTrackUndead(data)
    if not data or not data.undead then return end
    local obj = data.undead
    if not obj:isValid() then return end
    trackedUndead[obj.id] = {
        obj  = obj,
        mode = data.mode or "hostile",
    }
end

-- global tells us this undead is gone
local function onUntrackUndead(data)
    if not data or not data.undead then return end
    trackedUndead[data.undead.id] = nil
end

local function onShowMessage(data)
    if data and data.message then
        ui.showMessage(data.message)
    end
end

local function onSave()
    local saved = {}
    for id, entry in pairs(trackedUndead) do
        saved[id] = { obj = entry.obj, mode = entry.mode }
    end
    return {
        trackedUndead = saved,
        bonusChance   = bonusChance,
    }
end

local function onLoad(data)
    if data then
        if data.trackedUndead then
            trackedUndead = {}
            for id, entry in pairs(data.trackedUndead) do
                if entry.obj and entry.obj:isValid() then
                    trackedUndead[id] = entry
                end
            end
        end
        bonusChance = data.bonusChance or 0
    else
        bonusChance = 0
    end

    lastCellKey         = nil
    rolledAshpits       = {}
    watchdogGen         = watchdogGen + 1

    broadcastSettings()
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave   = onSave,
        onLoad   = onLoad,
    },
    eventHandlers = {
        UpdateAshpitList    = onUpdateAshpitList,
        AddAshpit           = onAddAshpit,
        Ashpit_TrackUndead  = onTrackUndead,
        Ashpit_UntrackUndead = onUntrackUndead,
        Ashpit_ShowMessage  = onShowMessage,
    },
}