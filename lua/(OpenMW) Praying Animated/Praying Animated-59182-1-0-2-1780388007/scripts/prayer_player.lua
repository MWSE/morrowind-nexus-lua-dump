local self    = require('openmw.self')
local types   = require('openmw.types')
local anim    = require('openmw.animation')
local async   = require('openmw.async')
local core    = require('openmw.core')
local camera  = require('openmw.camera')
local storage = require('openmw.storage')
local ambient = require('openmw.ambient')
local I       = require('openmw.interfaces')
local shared  = require('scripts.prayer_shared')

local GLANCE_YAW = math.rad(shared.GLANCE_YAW_DEG or 0)

local settings = storage.playerSection('Settings_Prayer_General')
local function cfg(key)
    local v = settings:get(key)
    if v == nil then return shared.DEFAULTS[key] end
    return v
end

local function broadcastSettings()
    core.sendGlobalEvent('Prayer_SettingsUpdated', {
        SHRINE_ACTIVATOR = cfg('SHRINE_ACTIVATOR'),
        ALLOW_IMPERIAL   = cfg('ALLOW_IMPERIAL'),
        ALLOW_DAEDRA     = cfg('ALLOW_DAEDRA'),
    })
end

settings:subscribe(async:callback(function()
    broadcastSettings()
end))

-- STATE
local active             = false
local token              = 0
local savedStance        = nil
local savedViewMode      = nil
local savedYaw           = nil
local previewApplied     = false
local movementOverridden = false

-- normalize trigger keys to lowercase once
local TRIGGERS = {}
for questId, v in pairs(shared.TRIGGERS) do
    TRIGGERS[questId:lower()] = v
end

local function beginLockout()
    if movementOverridden then return end
    movementOverridden = true
    I.Controls.overrideMovementControls(true)
    I.Controls.overrideCombatControls(true)
end

local function endLockout()
    if not movementOverridden then return end
    movementOverridden = false
    I.Controls.overrideMovementControls(false)
    I.Controls.overrideCombatControls(false)
end

local function restoreStance()
    if savedStance == nil then return end
    if types.Actor.getStance(self.object) == types.Actor.STANCE.Nothing then
        types.Actor.setStance(self, savedStance)
    end
    savedStance = nil
end

local function finishPrayer()
    if not active then return end
    active = false
    if anim.isPlaying(self, shared.ANIM_GROUP) then
        anim.cancel(self, shared.ANIM_GROUP)
    end
    
    if cfg('MURMUR_SOUND') then
        ambient.stopSoundFile("Sound\\freesound_community-murmur-27730.mp3")
    end

    endLockout()
    restoreStance()
    if previewApplied then
        camera.setMode(savedViewMode or camera.MODE.ThirdPerson)
        camera.setYaw(savedYaw)
        previewApplied = false
        savedViewMode = nil
    elseif savedViewMode ~= nil then
        camera.setMode(savedViewMode)
        savedViewMode = nil
    end
    savedYaw   = nil
end

local function beginRise()
    if not active then return end
    local myToken = token

    -- disabling looping lets the current play continue past loop stop -> stop
    if anim.isPlaying(self, shared.ANIM_GROUP) then
        anim.setLoopingEnabled(self, shared.ANIM_GROUP, false)
    end

    async:newUnsavableSimulationTimer(shared.RISE_DURATION, function()
        if myToken ~= token then return end
        finishPrayer()
    end)
end

local function startPrayer()
    if active then return end
    active = true
    token = token + 1
    local myToken = token

    local stance = types.Actor.getStance(self.object)
    if stance ~= types.Actor.STANCE.Nothing then
        savedStance = stance
        types.Actor.setStance(self, types.Actor.STANCE.Nothing)
    end

    savedViewMode = camera.getMode()
    savedYaw      = camera.getYaw()

    -- in third person, switch to preview
    if savedViewMode ~= camera.MODE.FirstPerson then
        camera.setMode(camera.MODE.Preview)
        previewApplied = true
    end

    beginLockout()

    -- wait DELAY, then play the prayer
    async:newUnsavableSimulationTimer(cfg('DELAY'), function()
        if myToken ~= token then return end

        -- play the murmur sound if the setting is enabled
        if cfg('MURMUR_SOUND') then
            ambient.playSoundFile("Sound\\freesound_community-murmur-27730.mp3", { 
                loop = true, 
                volume = cfg('VOLUME') / 100.0
            })
        end

        I.AnimationController.playBlendedAnimation(shared.ANIM_GROUP, {
            startKey = shared.START_KEY,
            stopKey  = shared.STOP_KEY,
            loops = 100000,
            speed = 0.8,
            priority = {
                [anim.BONE_GROUP.RightArm]  = anim.PRIORITY.Scripted,
                [anim.BONE_GROUP.LeftArm]   = anim.PRIORITY.Scripted,
                [anim.BONE_GROUP.Torso]     = anim.PRIORITY.Scripted,
                [anim.BONE_GROUP.LowerBody] = anim.PRIORITY.Scripted,
            },
            autoDisable = true,
            blendMask = anim.BLEND_MASK.All,
        })

        -- after the hold, stop looping so the closing rise plays naturally
        async:newUnsavableSimulationTimer(cfg('DURATION'), function()
            if myToken ~= token then return end
            beginRise()
        end)
    end)
end

-- HANDLERS

local function onQuestUpdate(questId, stage)
    -- when the shrine-activator trigger is enabled, quest updates are ignored
    if cfg('SHRINE_ACTIVATOR') then return end
    local t = TRIGGERS[questId:lower()]
    if t == nil then return end
    if t == true or t[stage] then
        startPrayer()
    end
end

-- the global script detects shrine activation and sends this event
local function onStartPrayerEvent()
    if not cfg('SHRINE_ACTIVATOR') then return end
    startPrayer()
end

local function onFrame()
    if not active then return end

    if types.Actor.getStance(self.object) ~= types.Actor.STANCE.Nothing then
        types.Actor.setStance(self, types.Actor.STANCE.Nothing)
    end

    self.controls.movement     = 0
    self.controls.sideMovement = 0
    self.controls.run          = false
    self.controls.jump         = false

    if not previewApplied and savedViewMode ~= nil and camera.getMode() ~= savedViewMode then
        camera.setMode(savedViewMode)
    end

    if savedYaw == nil then return end

    if previewApplied then return end

    local firstPerson = camera.getMode() == camera.MODE.FirstPerson

    if firstPerson then
        -- first person: yaw is the body, so only allow a glance cone
        if GLANCE_YAW <= 0 then
            camera.setYaw(savedYaw)
        else
            -- shortest signed angular difference from savedYaw, wrapped to [-pi, pi]
            local diff = (camera.getYaw() - savedYaw + math.pi) % (2 * math.pi) - math.pi
            if diff > GLANCE_YAW then
                camera.setYaw(savedYaw + GLANCE_YAW)
            elseif diff < -GLANCE_YAW then
                camera.setYaw(savedYaw - GLANCE_YAW)
            end
        end
    else
        camera.setYaw(savedYaw)
    end
end

return {
    engineHandlers = {
        onInit        = broadcastSettings,
        onLoad        = broadcastSettings,
        onQuestUpdate = onQuestUpdate,
        onFrame       = onFrame,
    },
    eventHandlers = {
        Prayer_StartPrayer = onStartPrayerEvent,
    },
}