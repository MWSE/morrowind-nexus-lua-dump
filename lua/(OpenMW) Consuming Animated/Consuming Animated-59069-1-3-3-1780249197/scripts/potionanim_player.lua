local self    = require('openmw.self')
local core    = require('openmw.core')
local types   = require('openmw.types')
local anim    = require('openmw.animation')
local async   = require('openmw.async')
local storage = require('openmw.storage')
local ambient = require('openmw.ambient')
local nearby  = require('openmw.nearby')
local input   = require('openmw.input')
local camera  = require('openmw.camera')
local I       = require('openmw.interfaces')
local shared  = require('scripts.potionanim_shared')

-- CONSTANTS

local SETTINGS_SECTION     = "Settings_PotionAnimations_General"
local NPC_SETTINGS_SECTION = "Settings_PotionAnimations_NPC"

local ANIM_GROUP    = "potion"    -- default drink animation group (potions)
local INGRED_GROUP  = "eatingr"   -- animation group for ingredients
local SD_DRINK_GROUP = "drink3"   -- animation group for SunsDusk generated drinks
local VFX_MESH      = "meshes/dbs/potion_standard_drink.nif"
local VFX_ID        = "potionanim_drink"
local VFX_BONE      = "Weapon Bone"
local QUERY_WINDOW  = 0.2
local SOUND_DELAY   = 0.7         -- seconds after animation start before the consume sound plays, changed below to match the animation speed

-- check if Expanded Loot is installed
local hasExpandedLoot = core.contentFiles.has("Expanded Loot.esm")

-- SETTINGS

local settings    = storage.playerSection(SETTINGS_SECTION)
local npcSettings = storage.playerSection(NPC_SETTINGS_SECTION)

local function cfg(key)
    local v = settings:get(key)
    if v == nil then return shared.DEFAULTS[key] end
    return v
end

local function npcCfg(key)
    local v = npcSettings:get(key)
    if v == nil then return shared.DEFAULTS[key] end
    return v
end

local function broadcastNpcSettings()
    core.sendGlobalEvent("PotionAnim_SettingsUpdated", {
        NPC_ENABLE             = npcCfg('NPC_ENABLE'),
        NPC_ANIMATION_COOLDOWN = npcCfg('NPC_ANIMATION_COOLDOWN'),
        NPC_ANIMATION_SPEED    = npcCfg('NPC_ANIMATION_SPEED'),
        NPC_LOCK_WEAPON        = npcCfg('NPC_LOCK_WEAPON'),
        NPC_SOUND_ENABLE       = npcCfg('NPC_SOUND_ENABLE'),
        NPC_SOUND_VOLUME       = npcCfg('NPC_SOUND_VOLUME'),
        NPC_SOUND_PITCH        = npcCfg('NPC_SOUND_PITCH'),
    })
end

npcSettings:subscribe(async:callback(function()
    broadcastNpcSettings()
end))

-- true if the item is a SunsDusk generated drink
local function isSdDrink(item)
    if not I.SunsDusk then return false end
    if not types.Potion.objectIsInstance(item) then return false end
    local record = types.Potion.records[item.recordId]
    return record ~= nil and record.mwscript == "sd_liquid_tracker"
end

-- true if the item is a SunsDusk cooked food item
local function isSdCooked(item)
    if not I.SunsDusk then return false end
    local _, typ = I.SunsDusk.isConsumable(item)
    return typ == "cooked" and cfg('SD_EAT_COOKED')
end

-- SunsDusk blacklist check
local function sdBlacklisted(item)
    if not I.SunsDusk then return false end

    local _, typ = I.SunsDusk.isConsumable(item)
    if typ == "cooked" then
        return not cfg('SD_EAT_COOKED')
    end

    if isSdDrink(item) then
        return not cfg('SD_SUPPORT')
    end

    return false
end

-- resolve which animation group a consumed item should use
local function animGroupFor(item)
    if types.Ingredient.objectIsInstance(item) or isSdCooked(item) then
        return INGRED_GROUP
    end
   if hasExpandedLoot and types.Potion.objectIsInstance(item) then
        if shared.EXPANDED_LOOT_EAT[item.recordId:lower()] then
            return INGRED_GROUP
        end
    end
    -- SunsDusk generated drinks use the drink3 animation
    if isSdDrink(item) then
        return SD_DRINK_GROUP
    end
    return shared.CUSTOM_ANIM[item.recordId] or ANIM_GROUP
end

-- resolve the model of an item's own record, across consumable types
local function recordModelFor(item)
    local rec
    if types.Ingredient.objectIsInstance(item) then
        rec = types.Ingredient.records[item.recordId]
    elseif types.Potion.objectIsInstance(item) then
        rec = types.Potion.records[item.recordId]
    end
    if rec and rec.model and rec.model ~= "" then
        return rec.model
    end
    return nil
end

-- resolve the mesh attached as the held VFX
local function vfxMeshFor(item, group)
    if group == INGRED_GROUP then
        local model = recordModelFor(item)
        if model then return model end
    end
    -- optionally use the item's own model for items using the drink3 animation
    if cfg('MODEL_MESH_NONPOTION') and group == SD_DRINK_GROUP then
        local model = recordModelFor(item)
        if model then return model end
    end
    return VFX_MESH
end

-- ANIMATION STATE

local cooldownUntil   = 0
local pending         = false
local hostileSeen     = false
local savedStance     = nil
local animActive      = false
local eatingActive    = false
local sdDrinkActive   = false
local animToken       = 0
local movementOverridden = false
local savedCameraMode = nil
local povLockActive   = false

-- lock the player's perspective for the duration of the animation
local function beginPovLock()
    if not cfg('LOCK_POV') then return end
    if povLockActive then return end
    local mode = I.Camera.getPrimaryMode()
    if mode == camera.MODE.FirstPerson or mode == camera.MODE.ThirdPerson then
        savedCameraMode = mode
        povLockActive   = true
        if mode == camera.MODE.FirstPerson then
            -- no preview allowed when in first person
            I.Camera.disableStandingPreview('potionanim')
        end
    end
end

local function endPovLock()
    if not povLockActive then return end
    if savedCameraMode == camera.MODE.FirstPerson then
        I.Camera.enableStandingPreview('potionanim')
    end
    povLockActive   = false
    savedCameraMode = nil
end

-- begin overriding movement
local function beginMovementOverride()
    if not cfg('ALLOW_MOVEMENT') then return end
    if movementOverridden then return end
    movementOverridden = true
    I.Controls.overrideMovementControls(true)
end

local function endMovementOverride()
    if not movementOverridden then return end
    movementOverridden = false
    I.Controls.overrideMovementControls(false)
end

local function restoreStance()
    if savedStance == nil then return end
    if types.Actor.getStance(self.object) == types.Actor.STANCE.Nothing then
        types.Actor.setStance(self, savedStance)
    end
    savedStance = nil
end

-- plays the consume sound matching the active animation
local function playConsumeSound()
    local sounds, enabled
    if eatingActive then
        enabled = cfg('EAT_SOUND_ENABLE')
        sounds  = shared.EAT_SOUNDS
    else
        enabled = cfg('SOUND_ENABLE')
        sounds  = shared.DRINK_SOUNDS
    end
    if not enabled then return end
    if not sounds or #sounds == 0 then return end
    ambient.playSoundFile(sounds[math.random(#sounds)], {
        volume = cfg('SOUND_VOLUME') / 100,
        pitch  = cfg('SOUND_PITCH') / 100,
    })
end

local function endAnimation()
    if not animActive then return end
    -- SunsDusk drinks aren't in a breakable bottle: no shatter sound for them
    if not eatingActive and not sdDrinkActive then
        playConsumeSound()
    end
    animActive = false
    I.Controls.overrideCombatControls(false)
    endMovementOverride()
    endPovLock()
    anim.removeVfx(self, VFX_ID)
    restoreStance()
    core.sendGlobalEvent('PotionAnim_PlayerDrinkEnd', {})
end

local function playPotionAnimation(group, vfxMesh, itemId)
    animToken = animToken + 1
    local myToken = animToken

    I.AnimationController.playBlendedAnimation(group, {
        startKey = 'start',
        stopKey  = 'stop',
        priority = {
            [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Scripted,
            [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted,
            [anim.BONE_GROUP.Torso]    = anim.PRIORITY.Scripted,
        },
        autoDisable = true,
        blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.Torso
                  + anim.BLEND_MASK.RightArm,
        speed = cfg('ANIMATION_SPEED'),
    })

    -- clear any VFX left over from a previous run before adding ours
    anim.removeVfx(self, VFX_ID)
    anim.addVfx(self, vfxMesh, {
        loop     = true,
        vfxId    = VFX_ID,
        boneName = VFX_BONE,
    })

    -- play the consume sound a delay after the animation starts
    if eatingActive then
        local scaledSoundDelay = SOUND_DELAY / cfg('ANIMATION_SPEED')
        async:newUnsavableSimulationTimer(scaledSoundDelay, function()
            if myToken ~= animToken then return end
            playConsumeSound()
        end)

        -- food disappears after eating and not when the animation is done
        local baseVfxRemovalTime = 1.6
        -- clipping issues with some food
        if itemId and shared.FAST_EAT_TIMINGS[itemId] then
            baseVfxRemovalTime = shared.FAST_EAT_TIMINGS[itemId]
        end
        local scaledVfxTime = baseVfxRemovalTime / cfg('ANIMATION_SPEED')
        
        async:newUnsavableSimulationTimer(scaledVfxTime, function()
            if myToken ~= animToken then return end
            anim.removeVfx(self, VFX_ID)
        end)

    end

    local fallback = cfg('ANIMATION_COOLDOWN') / cfg('ANIMATION_SPEED') + 1.0
    async:newUnsavableSimulationTimer(fallback, function()
        if myToken ~= animToken then return end
        endAnimation()
    end)
end

local function commitAnimation(group, vfxMesh, isEat, isSd, itemId)
    local stance = types.Actor.getStance(self.object)
    if stance ~= types.Actor.STANCE.Nothing then
        savedStance = stance
        types.Actor.setStance(self, types.Actor.STANCE.Nothing)
    end
    if cfg('LOCK_WEAPON') then
        I.Controls.overrideCombatControls(true)
    end
    beginMovementOverride()
    beginPovLock()
    animActive    = true
    eatingActive  = isEat
    sdDrinkActive = isSd
    cooldownUntil = core.getSimulationTime() + cfg('ANIMATION_COOLDOWN')
    playPotionAnimation(group, vfxMesh, itemId)
end

local function askThenPlay(group, vfxMesh, isEat, isSd, itemId)
    pending     = true
    hostileSeen = false

    for _, actor in ipairs(nearby.actors) do
        if actor ~= self.object then
            actor:sendEvent("PotionAnim_Query", { player = self.object })
        end
    end

    async:newUnsavableSimulationTimer(QUERY_WINDOW, function()
        pending = false
        if not hostileSeen then
            commitAnimation(group, vfxMesh, isEat, isSd, itemId)
        else
            -- hostile nearby: no animation will play, so end the lockout now
            core.sendGlobalEvent('PotionAnim_PlayerDrinkEnd', {})
        end
    end)
end

-- HANDLERS

local function onConsume(item)
    if not cfg('ENABLE') then return end

    local isPotion     = types.Potion.objectIsInstance(item)
    local isIngredient = types.Ingredient.objectIsInstance(item)
    -- potions and ingredients only
    if not (isPotion or isIngredient) then return end
    -- ingredient eating has its own toggle
    if isIngredient and not cfg('EAT_ENABLE') then return end
    -- skip blacklisted records
    if shared.BLACKLIST[item.recordId:lower()] then return end
    if sdBlacklisted(item) then return end

    local now = core.getSimulationTime()
    if now < cooldownUntil then return end
    if pending then return end

    local group   = animGroupFor(item)
    local vfxMesh = vfxMeshFor(item, group)
    local isSd    = isSdDrink(item)
    local isEat   = (group == INGRED_GROUP)
    local itemId  = item.recordId:lower()

    if cfg('PREVENT_CONSECUTIVE') then
        core.sendGlobalEvent('PotionAnim_PlayerDrinkStart', {})
    end

    if cfg('COMBAT_BLOCKS') then
        askThenPlay(group, vfxMesh, isEat, isSd, itemId)
    else
        commitAnimation(group, vfxMesh, isEat, isSd, itemId)
    end
end

local function onHostileReport()
    if pending then hostileSeen = true end
end

local function registerTextKeys()
    local function handler(groupname, key)
        if key == 'discard' then
            anim.removeVfx(self, VFX_ID)
        elseif key == 'stop' then
            endAnimation()
        end
    end
    -- register for the default group, the ingredient group, and every custom potion group
    local seen = {}
    local function register(group)
        if seen[group] then return end
        seen[group] = true
        I.AnimationController.addTextKeyHandler(group, handler)
    end
    register(ANIM_GROUP)
    register(INGRED_GROUP)
    register(SD_DRINK_GROUP)
    for _, group in pairs(shared.CUSTOM_ANIM) do
        register(group)
    end
end

-- while movement is overridden, the engine processes no movement controls, so re-apply the move actions
local function onFrame(dt)

    if cfg('LOCK_WEAPON') and animActive and types.Actor.getStance(self.object) ~= types.Actor.STANCE.Nothing then
        types.Actor.setStance(self, types.Actor.STANCE.Nothing)
    end

    -- enforce the saved perspective.
    if povLockActive and savedCameraMode ~= nil then
        if savedCameraMode == camera.MODE.FirstPerson then
            local mode = camera.getMode()
            if mode ~= camera.MODE.FirstPerson then
                camera.setMode(camera.MODE.FirstPerson, true)
            end
        else
            if I.Camera.getPrimaryMode() ~= savedCameraMode then
                camera.setMode(savedCameraMode, true)
            end
        end
    end

    if not movementOverridden then return end

    local fwd  = input.getRangeActionValue('MoveForward')  or 0
    local back = input.getRangeActionValue('MoveBackward') or 0
    local left = input.getRangeActionValue('MoveLeft')     or 0
    local right= input.getRangeActionValue('MoveRight')    or 0

    self.controls.movement     = fwd - back
    self.controls.sideMovement = right - left
    -- keep the player at walking speed for the duration of the animation
    self.controls.run          = false
end

local function onInit()
    registerTextKeys()
    broadcastNpcSettings()
end

return {
    engineHandlers = {
        onInit        = onInit,
        onLoad        = onInit,
        onConsume     = onConsume,
        onFrame       = onFrame,
    },
    eventHandlers = {
        PotionAnim_HostileReport = onHostileReport,
    },
}