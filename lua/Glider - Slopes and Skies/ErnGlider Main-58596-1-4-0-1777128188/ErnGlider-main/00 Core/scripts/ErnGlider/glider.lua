--[[
ErnGlider for OpenMW.
Copyright (C) 2026 Erin Pentecost

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
local MOD_NAME           = require("scripts.ErnGlider.ns")
local core               = require("openmw.core")
local pself              = require("openmw.self")
local camera             = require('openmw.camera')
local util               = require('openmw.util')
local async              = require("openmw.async")
local types              = require('openmw.types')
local input              = require('openmw.input')
local controls           = require('openmw.interfaces').Controls
local nearby             = require('openmw.nearby')
local animation          = require('openmw.animation')
local aux_util           = require('openmw_aux.util')
local interfaces         = require("openmw.interfaces")
local settings           = require("scripts.ErnGlider.settings")
local updraftShader      = require("scripts.ErnGlider.updraftshader")

local glideranim         = require("scripts.ErnGlider.glideranim")

-- how much yaw change contributes to side movement drift
local driftFactor        = 3.0
-- side movement is multiplied by this each frame so it decays back to 0
local driftDecay         = 0.9
-- prevent gliding when fatigue is at this level.
local minFatigue         = 1

local fFatigueReturnBase = core.getGMST("fFatigueReturnBase")
local fFatigueReturnMult = core.getGMST("fFatigueReturnMult")

local updraftShaderInst  = updraftShader.NewUpdraftShader()

local persist            = {
    applied = false,
    appliedDuration = 0,
    sideMovement = 0,
}

if settings.glider.enableQuest then
    pself.type.addTopic(pself, "glider")
end

local cachedCurrentGlider = "basic"
local function getCurrentGlider()
    if settings.glider.enableQuest then
        local gliderQuest = pself.type.quests(pself)["eg_glider"]
        local gliderStage = gliderQuest and gliderQuest.stage or 0
        if gliderStage >= 31 then
            cachedCurrentGlider = "masterwork"
            return cachedCurrentGlider
        elseif gliderStage >= 21 then
            cachedCurrentGlider = "advanced"
            return cachedCurrentGlider
        elseif gliderStage >= 1 then
            cachedCurrentGlider = "basic"
            return cachedCurrentGlider
        else
            return nil
        end
    else
        local acrobatics = pself.type.stats.skills.acrobatics(pself).base
        if acrobatics > 80 then
            cachedCurrentGlider = "masterwork"
            return cachedCurrentGlider
        elseif acrobatics > 40 then
            cachedCurrentGlider = "advanced"
            return cachedCurrentGlider
        else
            cachedCurrentGlider = "basic"
            return cachedCurrentGlider
        end
    end
end

local glideSpells = {
    basic = "eg_glide_1",
    advanced = "eg_glide_2",
    masterwork = "eg_glide_3",
}

local allGliderAnimations = {}
for _, gliderType in pairs(glideranim) do
    allGliderAnimations[gliderType.forward] = true
    allGliderAnimations[gliderType.left] = true
    allGliderAnimations[gliderType.right] = true
end
local function gliderAnimationIsPlaying()
    for animName, present in pairs(allGliderAnimations) do
        if present then
            if animation.isPlaying(pself, animName) then
                return true
            end
        end
    end
    return false
end

local function getSoundFilePath(file)
    return "sound\\" .. MOD_NAME .. "\\" .. file
end

local sounds = {
    wind = getSoundFilePath("wind.mp3"),
    equip = getSoundFilePath("equip glider.wav"),
    hit_wall = "Sound\\Fx\\body hit.wav",
    updraft = getSoundFilePath("up draft with more wind.wav"),
}

local function applyGlideSpell(currentGlider)
    local spell = glideSpells[currentGlider]
    local vfx = glideranim[currentGlider].model
    pself.type.activeSpells(pself):add({
        id = spell,
        effects = { 0, 1 },
        ignoreResistances = true,
        ignoreSpellAbsorption = true,
        ignoreReflect = true
    })
    if vfx and camera.getMode() == camera.MODE.ThirdPerson then
        animation.addVfx(pself, vfx,
            { loop = true, boneName = glideranim[cachedCurrentGlider].bone, vfxId = "glider", useAmbientLight = false })
    end
end

local forward = util.vector3(0.0, 1.0, 0.0)
local function touchingWall()
    local pselfCenter = pself:getBoundingBox().center
    local facing = pself.rotation:apply(forward):normalize() * 70

    local castResult = nearby.castRay(pselfCenter, pselfCenter + facing, {
        collisionType = nearby.COLLISION_TYPE.AnyPhysical,
        ignore = pself
    })

    return castResult
end

local enduranceStat = pself.type.stats.attributes.endurance(pself)
local fatigueStat = pself.type.stats.dynamic.fatigue(pself)

local function instantCost()
    return math.ceil(settings.glider.fatigueCost)
end

local function naturalFatigueRegenRate()
    -- fFatigueReturnBase + (fFatigueReturnMult * endurance)
    return fFatigueReturnBase + (fFatigueReturnMult * enduranceStat.modified)
end

local function onInit(initData)
    if initData ~= nil then
        persist = initData
    end
end
local function onLoad(data)
    if data ~= nil then
        persist = data
    end
end
local function onSave()
    return persist
end

local function canApply()
    if types.Actor.isOnGround(pself) then
        settings.debugPrint("canApply gilder: on ground")
        return false
    end
    if types.Actor.isSwimming(pself) then
        settings.debugPrint("canApply glider: swimming")
        return false
    end
    if types.Actor.getStance(pself) ~= types.Actor.STANCE.Nothing then
        settings.debugPrint("canApply gilder: spell or weapon is readied")
        return false
    end

    if not animation.isPlaying(pself, "jump") then
        if not gliderAnimationIsPlaying() then
            settings.debugPrint("canApply gilder: not jumping")
            return false
        end
    end
    local levitateEffect = types.Actor.activeEffects(pself):getEffect(core.magic.EFFECT_TYPE.Levitate)
    if (levitateEffect ~= nil) and (levitateEffect.magnitude > 0) then
        settings.debugPrint("canApply gilder: levitating")
        return false
    end
    if (not persist.applied) and (fatigueStat.current < instantCost()) then
        settings.debugPrint("canApply gilder: can't pay instant fatigue cost")
        return false
    end
    if fatigueStat.current <= minFatigue then
        settings.debugPrint("canApply gilder: min fatigue")
        return false
    end
    if (not pself.cell.isExterior) and (not pself.cell:hasTag("QuasiExterior")) then
        settings.debugPrint("canApply gilder: interior cell")
        return false
    end
    if not types.Player.getControlSwitch(pself, types.Player.CONTROL_SWITCH.Controls) then
        settings.debugPrint("canApply gilder: no control")
        return false
    end
    return true
end

local updraftStrength = 0
local function onUpdraft(data)
    if data.started then
        core.sound.playSoundFile3d(sounds.updraft, pself, {
            volume = settings.main.volume * .5,
        })
    end
    updraftStrength = data.value
end


local fatigueDebt = 0

local function removeGlider()
    if not persist.applied then
        return
    end
    print("Glide duration: " .. tostring(persist.appliedDuration))
    -- apply skill XP for glides longer than 3 seconds.
    if persist.appliedDuration > 3 then
        interfaces.SkillProgression.skillUsed(core.stats.Skill.records.acrobatics.id,
            {
                scale = persist.appliedDuration - 1,
                useType = interfaces.SkillProgression.SKILL_USE_TYPES
                    .Acrobatics_Jump
            })
    end
    persist.applied = false
    persist.appliedDuration = 0
    persist.sideMovement = 0
    print("Removing glider...")
    -- reset movement
    pself.controls.movement = 0
    -- remove spell effects
    local gliderSpellsByID = {}
    for _, v in pairs(glideSpells) do
        gliderSpellsByID[v] = true
    end
    for _, spell in pairs(pself.type.activeSpells(pself)) do
        if gliderSpellsByID[spell.id] then
            pself.type.activeSpells(pself):remove(spell.activeSpellId)
        end
    end
    -- remove vfx
    animation.removeVfx(pself, "glider")
    -- remove sound
    core.sound.stopSoundFile3d(sounds.wind, pself)
    -- remove all possible glider anims
    settings.debugPrint(aux_util.deepToString(allGliderAnimations, 3))
    for animName, present in pairs(allGliderAnimations) do
        if present then
            --settings.debugPrint("cancel " .. animName)
            animation.cancel(pself, animName)
            animation.cancel(pself, animName:lower())
        end
    end

    if not animation.isPlaying(pself, "jump") then
        animation.playBlended(pself, "jump", {
            priority = animation.PRIORITY.Movement,
            autoDisable = true,
            loops = -1,
        })
    end

    fatigueDebt = 0
    updraftStrength = 0
    updraftShaderInst:setEnabled(false)
end

local function applyGlider()
    if not canApply() then
        return
    end

    local currentGlider = getCurrentGlider()
    if currentGlider == nil then
        settings.debugPrint("glider quest not started")
        return
    end

    persist.applied = true
    print("Applying glider...")
    -- set movement on this frame
    pself.controls.movement = 1
    -- apply sound
    core.sound.playSoundFile3d(sounds.wind, pself, {
        volume = settings.main.volume * 0.3,
        loop = true,
    })
    core.sound.playSoundFile3d(sounds.equip, pself, {
        volume = settings.main.volume,
    })
    -- apply spell
    applyGlideSpell(currentGlider)
    -- apply initial cost
    local cost = instantCost()
    fatigueStat.current = fatigueStat.current - cost
    -- bank up some of that cost.
    fatigueDebt = -0.8 * cost
end

local glideAnimOptions = {
    priority = animation.PRIORITY.Storm,
    autoDisable = true,
}


local function playGliderAnim(newAnim)
    if not animation.isPlaying(pself, newAnim) then
        interfaces.AnimationController.playBlendedAnimation(newAnim, glideAnimOptions)
        --settings.debugPrint("anim start - " .. newAnim)
        --animation.playBlended(pself, newAnim, glideAnimOptions)
    end
end

local function animate()
    local aLeft = glideranim[cachedCurrentGlider].left
    local aRight = glideranim[cachedCurrentGlider].right
    local aForward = glideranim[cachedCurrentGlider].forward
    if types.Actor.isOnGround(pself) then
        animation.cancel(pself, aLeft)
        animation.cancel(pself, aRight)
        animation.cancel(pself, aForward)
    elseif (pself.controls.sideMovement <= -1 * settings.main.deadzone) then
        animation.cancel(pself, aRight)
        animation.cancel(pself, aForward)
        playGliderAnim(aLeft)
    elseif (pself.controls.sideMovement >= settings.main.deadzone) then
        animation.cancel(pself, aLeft)
        animation.cancel(pself, aForward)
        playGliderAnim(aRight)
    elseif (math.abs(pself.controls.sideMovement) < settings.main.deadzone) then
        animation.cancel(pself, aLeft)
        animation.cancel(pself, aRight)
        playGliderAnim(aForward)
    end
end

local function onHit(victimActor)
    -- victimActor is nil or a target actor that was run into.
    core.sound.playSoundFile3d(sounds.hit_wall, pself, {
        volume = settings.main.volume,
    })
    removeGlider()
    -- https://github.com/OpenMW/openmw/blob/87b266c1365696ce76fede471dd549f8184f090a/apps/openmw/mwrender/animation.cpp#L814-L828
    -- https://github.com/OpenMW/openmw/blob/87b266c1365696ce76fede471dd549f8184f090a/apps/openmw/mwmechanics/character.cpp#L219-L245

    local gliderAnim = victimActor and 'hit' .. tostring(math.random(1, 5)) or 'knockdown'

    interfaces.AnimationController.playBlendedAnimation(gliderAnim, {
        priority = animation.PRIORITY.Knockdown,
        autoDisable = true,
    })

    if victimActor then
        victimActor:sendEvent(MOD_NAME .. 'onHitByGlider', {
            glider = pself,
            victim = victimActor,
        })
        if types.NPC.objectIsInstance(victimActor) then
            core.sendGlobalEvent(MOD_NAME .. 'onHitByGlider', {
                glider = pself,
                victim = victimActor,
            })
        end
    end
end

local rayCastDelay = 0

local function onUpdate(dt)
    if dt == 0 then return end
    if persist.applied then
        if not settings.glider.enable then
            removeGlider()
            return
        end
        if not canApply() then
            removeGlider()
            return
        end
        -- only remove whole units of fatigue
        fatigueDebt = fatigueDebt + (naturalFatigueRegenRate() + settings.glider.fatigueCost) * dt
        if fatigueDebt > 1 then
            local whole = math.floor(fatigueDebt)
            fatigueDebt = fatigueDebt - whole
            local newFatigue = fatigueStat.current - whole
            -- kick out of gliding if we hit min fatigue
            -- do this so you don't fall unconscious while flying
            if newFatigue <= minFatigue then
                fatigueStat.current = math.max(0, minFatigue)
                removeGlider()
                return
            end
            fatigueStat.current = fatigueStat.current - whole
        end
        -- do this check less frequently
        rayCastDelay = rayCastDelay + dt
        if rayCastDelay > 0.3 then
            local touchResult = touchingWall()
            if touchResult.hit then
                local actor = nil
                if touchResult.hitObject and types.Actor.objectIsInstance(touchResult.hitObject) then
                    actor = touchResult.hitObject
                end
                onHit(actor)
                return
            end

            -- check for updrafts
            core.sendGlobalEvent(MOD_NAME .. "onDoUpdraft", {
                player = pself,
                dt = dt
            })
        end
        -- put hands up
        animate()
        -- track duration of glide
        persist.appliedDuration = persist.appliedDuration + dt

        -- shader effects
        updraftStrength = updraftStrength - dt
        if updraftStrength > 0 then
            updraftShaderInst:setEnabled(true)
            updraftShaderInst:update(updraftStrength / 10, dt)
        else
            updraftShaderInst:setEnabled(false)
        end
    end
end

local function onFrame()
    if persist.applied then
        pself.controls.movement = 1
        local startingYaw = pself.controls.yawChange
        if math.abs(startingYaw) < 0.05 then
            startingYaw = 0
        end
        persist.sideMovement = util.clamp((persist.sideMovement + startingYaw * driftFactor) * driftDecay, -1, 1)
        pself.controls.sideMovement = (pself.controls.sideMovement + persist.sideMovement) / 2
    end
end

return {
    interfaceName = MOD_NAME .. "Glider",
    interface = {
        version = 1,
        isApplied = function()
            return persist.applied
        end,
        remove = removeGlider,
        apply = applyGlider,
    },
    eventHandlers = {
        [MOD_NAME .. "onUpdraft"] = onUpdraft,
    },
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
        onSave = onSave,
        onUpdate = onUpdate,
        onFrame = onFrame
    }
}
