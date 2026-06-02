local self    = require('openmw.self')
local types   = require('openmw.types')
local core    = require('openmw.core')
local ambient = require('openmw.ambient')
local storage = require('openmw.storage')
local async   = require('openmw.async')
local anim    = require('openmw.animation')
local I       = require('openmw.interfaces')

local postprocessing = require('openmw.postprocessing')

local shared   = require('scripts.fire_shared')
local DEFAULTS = shared.DEFAULTS

local section = storage.playerSection('SettingsFireDamage')

local cfg = {}

local function reloadSetting(key)
    local val = section:get(key)
    if val ~= nil then cfg[key] = val else cfg[key] = DEFAULTS[key] end
end

local function reloadAllSettings()
    for key in pairs(DEFAULTS) do
        reloadSetting(key)
    end
    cfg.BURN_RADIUS_SQ = cfg.BURN_RADIUS * cfg.BURN_RADIUS
end

reloadAllSettings()

section:subscribe(async:callback(function(_, key)
    if key then
        reloadSetting(key)
        if key == 'BURN_RADIUS' then
            cfg.BURN_RADIUS_SQ = cfg.BURN_RADIUS * cfg.BURN_RADIUS
        end
    else
        reloadAllSettings()
    end
end))

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

-- keyed by obj.id for O(1) insertion and dedup.
local activeFires     = {}
local tickAccumulator = 0
local lastCellKey     = nil

local shader   = postprocessing.load('HealthFatigueEffect')
local vfxTimer = 0
local VFX_DURATION = 0.35

shader:disable()

local function log(msg)
    if cfg.PRINT_LOG then
        print('[POF P] ' .. msg)
    end
end

local function calcFireDamage(base)
    local effects    = types.Actor.activeEffects(self)
    local idWeakness = core.magic.EFFECT_TYPE.WeaknessToFire
    local idResist   = core.magic.EFFECT_TYPE.ResistFire
    local weakness, resist = 0, 0

    for _, effect in pairs(effects) do
        if effect.id == idWeakness then
            weakness = effect.magnitude
        elseif effect.id == idResist then
            resist = effect.magnitude
        end
        if weakness ~= 0 and resist ~= 0 then break end
    end

    local netResist = math.min(100, math.max(-100, resist - weakness))
    return math.max(0, base * (1.0 - netResist / 100.0))
end

local function isNearFire(pPos)
    local burnH = cfg.BURN_HEIGHT
    local burnR2 = cfg.BURN_RADIUS_SQ
    for id, fire in pairs(activeFires) do
        if fire and fire:isValid() then
            local fPos = fire.position
            if math.abs(fPos.z - pPos.z) < burnH then
                local dx = fPos.x - pPos.x
                local dy = fPos.y - pPos.y
                if dx*dx + dy*dy < burnR2 then
                    log('Player burned by object: ' .. tostring(fire.recordId))
                    return true
                end
            end
        else
            activeFires[id] = nil
        end
    end
    return false
end

local function applyBurnDamage()
    local damage = calcFireDamage(cfg.BASE_DAMAGE)
    if damage <= 0 then return end

    local health = types.Actor.stats.dynamic.health(self)
    health.current = health.current - damage

    ambient.playSoundFile('Sound\\fire_sound_by_PeterBitt.wav', { volume = 1.0 })
    ambient.playSound('Health Damage', { volume = 0.1 })

    shader:enable()
    shader:setFloat('uHealthFactor', 1.0)
    vfxTimer = VFX_DURATION

    if cfg.ANIMATIONS_ENABLED then
        I.AnimationController.playBlendedAnimation('hit1', {
            startKey = 'start',
            stopKey  = 'stop',
            priority = anim.PRIORITY.Hit,
        })
    end
end

local function checkCellChange()
    local currentCell = self.cell
    local currentKey  = cellKey(currentCell)
    if currentKey == lastCellKey then return false end
    lastCellKey = currentKey
    activeFires = {}
    core.sendGlobalEvent('RequestFireScan', { cell = cellDescriptor(currentCell) })
    return true
end

local function onUpdate(dt)
    if not cfg.MOD_ENABLED then return end

    if vfxTimer > 0 then
        vfxTimer = vfxTimer - dt
        if vfxTimer <= 0 then
            shader:setFloat('uHealthFactor', 0.0)
            shader:disable()
        end
    end

    tickAccumulator = tickAccumulator + dt
    if tickAccumulator < cfg.DAMAGE_TICK then return end
    tickAccumulator = tickAccumulator - cfg.DAMAGE_TICK

    if checkCellChange() then return end
    if next(activeFires) == nil then return end

    if isNearFire(self.position) then
        applyBurnDamage()
    end
end

-- full replace
local function onUpdateFireList(fires)
    activeFires = {}
    if fires then
        for i = 1, #fires do
            local f = fires[i]
            if f and f:isValid() then
                activeFires[f.id] = f
            end
        end
    end
end

-- incremental add
local function onAddFire(fire)
    if fire and fire:isValid() then
        activeFires[fire.id] = fire
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        UpdateFireList = onUpdateFireList,
        AddFire        = onAddFire,
    },
}