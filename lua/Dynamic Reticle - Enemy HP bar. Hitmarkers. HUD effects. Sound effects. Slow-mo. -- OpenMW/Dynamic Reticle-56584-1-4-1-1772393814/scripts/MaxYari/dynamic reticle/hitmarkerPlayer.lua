local mp = "scripts/MaxYari/dynamic reticle/"
local fp = "scripts\\MaxYari\\dynamic reticle\\"

local ui_elements = require(mp .. "ui_elements")
local settings = require(mp .. "settings")
local animConf = ui_elements.animConf
local Tweener = require(mp .. "tweener")
local gutils = require(mp .. "gutils")
local DEFS = require(mp .. "defs")
local shaderUtils = require(mp .. "shader_utils")
local animManager = require(mp .. "anim_manager")

local core = require("openmw.core")
local util = require("openmw.util")
local I = require("openmw.interfaces")
local omwself = require("openmw.self")
local camera = require("openmw.camera")
local ui = require("openmw.ui")
local nearby = require('openmw.nearby')
local types = require('openmw.types')

local selfActor = gutils.Actor:new(omwself)

-- Ui Elements
local hitmarkerWrapperEl = ui_elements.getElementByName("hitmarkerWrapper")
local reticleEl = ui_elements.getElementByName("reticle")
local stealthArrowLEl = ui_elements.getElementByName("stealthArrowL")
local stealthArrowREl = ui_elements.getElementByName("stealthArrowR")

-- Settings
local visualSettings = gutils.SettingsHelper:new('DynamicReticleVisualSettings')
local soundSettings = gutils.SettingsHelper:new("DynamicReticleSoundSettings")

local currentTargetActor = nil
local wasSneaking = false

local tweeners = {}

-- Reticle multiplier state: each slot has its own scale/alpha multipliers and tweener
-- Final values are computed by multiplying all slots together with animConf.reticleAlpha
local reticleState = {
    sneak = { scale = 1.0, alpha = 1.0, tweener = nil },
    shoot = { scale = 1.0, alpha = 1.0, tweener = nil },
    miss = { scale = 1.0, alpha = 1.0, tweener = nil },
    stowed = { scale = 1.0, alpha = 1.0, tweener = nil },
}

-- Compute final reticle size and alpha from all multiplier slots
local function computeReticleValues()
    local s = reticleState
    local ru = reticleEl.userData
    local finalScale = s.sneak.scale * s.shoot.scale * s.miss.scale * s.stowed.scale
    local finalAlpha = animConf.reticleAlpha * s.sneak.alpha * s.shoot.alpha * s.miss.alpha * s.stowed.alpha
    reticleEl.props.size = ru.size * finalScale
    reticleEl.props.alpha = util.clamp(finalAlpha, 0, 1)
end

local targetDistanceTimer = 0
local stanceNoneTimer = 0

local hpWidgetShader = shaderUtils.ShaderWrapper:new('hpWidget', {
    uOpacity = 0,
    uColor = visualSettings["HpWidgetColor"]:asRgb(),
    uDamageColor = visualSettings["HpWidgetDamageColor"]:asRgb(),
    uScale = visualSettings["HpWidgetScale"],
})
hpWidgetShader.animSectors = {}
hpWidgetShader.animSectorsLen = 3

local function canUseSound()
    local stance = selfActor:getDetailedStance()
    return (soundSettings['MeleeSound'] and stance == gutils.Actor.DET_STANCE.Melee) or
        (soundSettings['MarksmanSound'] and stance == gutils.Actor.DET_STANCE.Marksman) or
        (soundSettings['SpellcasterSound'] and stance == gutils.Actor.DET_STANCE.Spell)
end

local function animateSlideMarker(el, isDead, isWeakHit)
    local u = el.userData
    local alpha = animConf.hmAlpha

    if isDead then 
        el.props.color = visualSettings["KillMarkerColor"]
    else 
        el.props.color = visualSettings["hitMarkerColor"]
        if isWeakHit then            
            alpha = animConf.hmWeakAlpha
        else            
            alpha = animConf.hmAlpha
        end
    end

    u.tweener = Tweener:new()
    tweeners[el.name] = u.tweener
    
    u.tweener:add(0.2, Tweener.easings.springOutStrong, function(t)
        el.props.size = gutils.lerp(u.size*animConf.hmPartSizeMult, u.size, t)
        local offset = u.direction * gutils.lerp(animConf.hmPartFromDist, animConf.hmPartToDist, t)
        el.props.relativePosition = util.vector2(0.5, 0.5) + offset
        el.props.alpha = util.clamp(alpha * t * 2, 0, 1)     
    end):add(0.6, Tweener.easings.easeOutCubic, function(t)
        el.props.alpha = util.clamp(alpha * (1 - t), 0, 1)        
    end)
end

local function animateStealthStuff(show)
    local arrows = {stealthArrowLEl,stealthArrowREl}
    local slot = reticleState.sneak

    -- Cancel existing sneak animation and reset multiplier
    if slot.tweener then
        slot.tweener:finish()
        slot.scale = 1.0
    end

    slot.tweener = Tweener:new()
    tweeners["reticle_sneak"] = slot.tweener

    local function animateArrows(t)
        for _, el in ipairs(arrows) do
            local eu = el.userData
            local offset = eu.direction * gutils.lerp(animConf.sneakArrowPartFromDist, animConf.sneakArrowPartToDist, t)
            el.props.relativePosition = util.vector2(0.5, 0.5) + offset
            el.props.alpha = util.clamp(animConf.reticleAlpha * t, 0, 1)
        end
    end

    if show then
        slot.tweener:add(0.5, Tweener.easings.springOutStrong, function(t)
            slot.scale = gutils.lerp(1, animConf.reticleSneakSizeMult, t)
            animateArrows(t)
        end)
    else
        slot.tweener:add(0.5, Tweener.easings.springOutStrong, function(t)
            slot.scale = gutils.lerp(animConf.reticleSneakSizeMult, 1, t)
            animateArrows(1 - t)
        end)
    end
end

local function setReticleScreenPos(screenPos)
    ui_elements.parentElement.layout.props.relativePosition = screenPos
    hpWidgetShader.u.uPosition = screenPos
    ui_elements.parentElement:update()
end

local function setReticleWorldPos(worldPos)
    local screenPosAbs = camera.worldToViewportVector(worldPos)
    local screenPosRel = util.vector2(screenPosAbs.x/ui.screenSize().x, screenPosAbs.y/ui.screenSize().y)
    setReticleScreenPos(screenPosRel)
    return screenPosRel
end

local function setCurrentEnemy(enemy)
    if not currentTargetActor or currentTargetActor.gameObject ~= enemy then        
        currentTargetActor = gutils.Actor:new(enemy)

        -- Reset some shader variables
        hpWidgetShader.animSectors = {}

        if hpWidgetShader.lostHpTween then hpWidgetShader.lostHpTween:finish() end
        hpWidgetShader.lostHpTween = nil
        tweeners["lostHpTween"] = nil
        
        if hpWidgetShader.onHitTween then hpWidgetShader.onHitTween:finish() end
        hpWidgetShader.onHitTween = nil
        tweeners["onHitTween"] = nil
    end
end

-- Hitmarker and hp widget update on hosile damaged event --------------------
------------------------------------------------------------------------------
local lastHostileDamagedTime = 0
local throttleInterval = 0.333

local function onHostileDamaged(data)
    targetDistanceTimer = 0
    stanceNoneTimer = 0
    local isWeakHit = data.glancedHit

    -- Throttle marker and sounds
    local currentTime = core.getRealTime()
    if data.currentHealth > 0 and currentTime - lastHostileDamagedTime < throttleInterval then
        return
    end
    lastHostileDamagedTime = currentTime

    for name, el in pairs(hitmarkerWrapperEl.content) do
        if not el.name then goto continue end

        animateSlideMarker(el, data.currentHealth <= 0, isWeakHit)

        ::continue::
    end

    setCurrentEnemy(data.hostile)

    if canUseSound() then
        local params
        --local pitches = {0.5,1, 1.5}
        --local pitch = pitches[math.random(1,#pitches)]
        local minPitch = soundSettings["MarkerSoundPitchMin"]
        local maxPitch = soundSettings["MarkerSoundPitchMax"]
        local pitch = math.random() * (maxPitch - minPitch) + minPitch     

        local soundPath = nil

        if data.currentHealth <= 0 then
            params = { volume = soundSettings["DeathMarkerVolume"], pitch = pitch, loop = false }
            soundPath = settings.fileSelectors["DeathMarkerSound"]:getFilePath()
        else
            if isWeakHit then
                -- Weak hit, play no sound
            else
                params = { volume = soundSettings["HitMarkerVolume"], pitch = pitch, loop = false }
                soundPath = settings.fileSelectors["HitMarkerSound"]:getFilePath()
            end
        end
        
        if soundPath then
            core.sound.playSoundFile3d(soundPath, omwself, params)
        end
    end

    -- Send slowdown event to global script when enemy is killed
    
    if data.currentHealth <= 0 and math.random() <= visualSettings["SlowdownOnKillChance"] then
        local SlowdownOnKillDuration = visualSettings["SlowdownOnKillDuration"]
        core.sendGlobalEvent("SlowdownEffect", { minScale = 0.2*SlowdownOnKillDuration, hold = 0.1*SlowdownOnKillDuration, inTime = 0.05*SlowdownOnKillDuration, outTime = 0.3*SlowdownOnKillDuration })
    end
end

-- Missed attack reticle fadeout --------------------
-------------------------------------------------------
local function onMissedAttack()
    local slot = reticleState.miss

    -- Cancel existing miss animation and reset multiplier
    if slot.tweener then
        slot.tweener:finish()
        slot.scale = 1.0
        slot.alpha = 1.0
    end

    slot.tweener = Tweener:new()
    tweeners["reticle_miss"] = slot.tweener

    slot.tweener:add(0.1, Tweener.easings.easeOutCubic, function(t)
        slot.alpha = gutils.lerp(1, visualSettings["MissedReticleAlpha"], t)
    end):add(0.3, Tweener.easings.easeOutCubic, function(t)
        slot.alpha = gutils.lerp(visualSettings["MissedReticleAlpha"], 1, t)
    end)
end

-- Reticle bounce on shoot -----------------
--------------------------------------------
animManager.addOnKeyHandler(function(groupname, key)
    if key == "shoot release" then
        local slot = reticleState.shoot

        -- Cancel existing shoot animation and reset multiplier
        if slot.tweener then
            slot.tweener:finish()
            slot.scale = 1.0
            slot.alpha = 1.0
        end

        slot.tweener = Tweener:new()
        tweeners["reticle_shoot"] = slot.tweener

        -- Animate size and alpha when extending
        slot.tweener:add(0.1, Tweener.easings.springOutStrong, function(t)
            slot.scale = gutils.lerp(1, 1.75, t)
            slot.alpha = gutils.lerp(1, 0.33, t)
        end)
        -- Animate size and alpha when shrinking back
        :add(0.3, Tweener.easings.easeOutCubic, function(t)
            slot.scale = gutils.lerp(1.75, 1, t)
            slot.alpha = gutils.lerp(0.33, 1, t)
        end)
    end
end)

-- onUpdate -------------------------------------------
-------------------------------------------------------
local function onUpdate(dt)
    if dt <= 0 then return end
    local isHudVisible = I.UI.isHudVisible()
    local now = core.getSimulationTime()

    -- Hiding/Showing widgets based on hud visibility and ensuring that hp widget is above hex dof from first person view dynamics.
    ui_elements.parentElement.layout.props.alpha = isHudVisible and 1 or 0
    -- Health widget is also hidden based on isHudVisible, but later down the line
    
    local widgetShouldStart = false
    if I.DynamicCamera then
        widgetShouldStart = I.DynamicCamera.shaders["hexDoFProgrammable"].enabled
    else
        widgetShouldStart = true
    end

    if widgetShouldStart and visualSettings["ShowHpWidget"] then
        hpWidgetShader:enable()
    else
        hpWidgetShader:disable()
    end
    

    -- Handle sneak state
    local isSneaking = omwself.controls.sneak
    if isSneaking ~= wasSneaking then
        animateStealthStuff(isSneaking)
        wasSneaking = isSneaking
    end


    -- Update all tweeners
    for _, tweener in pairs(tweeners) do
        tweener:tick(dt)
    end

    -- Handle stowed stance multiplier (lerp towards stowed alpha when stance is "nothing")
    local stance = types.Actor.getStance(omwself)
    local stowedSlot = reticleState.stowed
    if stance == types.Actor.STANCE.Nothing then
        stowedSlot.alpha = gutils.lerp(stowedSlot.alpha, visualSettings["StowedReticleAlpha"], gutils.dtForLerp(dt, 5))
    else
        stowedSlot.alpha = gutils.lerp(stowedSlot.alpha, 1, gutils.dtForLerp(dt, 5))
    end

    -- Update reticle from multiplier slots
    computeReticleValues()

    if currentTargetActor then
        -- Distance can't be more than 10 meters for more than 3 seconds
        local distance = (currentTargetActor.gameObject.position - omwself.position):length()
        if distance > 10*DEFS.GUtoM then
            targetDistanceTimer = targetDistanceTimer + dt
            if targetDistanceTimer >= 3 then
                currentTargetActor = nil
                targetDistanceTimer = 0
            end
        else
            targetDistanceTimer = 0
        end

        -- No-weapon stance hides enemy hp bar after 1 second        
        if not currentTargetActor.gameObject:isValid() or currentTargetActor:isDead() or stance == types.Actor.STANCE.Nothing then
            stanceNoneTimer = stanceNoneTimer + dt
            if stanceNoneTimer > 1 then
                currentTargetActor = nil
                stanceNoneTimer = 0
            end
        else
            stanceNoneTimer = 0
        end
    end

    -- Update health widget
    if currentTargetActor then
        hpWidgetShader.u.uOpacity = gutils.lerp(hpWidgetShader.u.uOpacity, visualSettings["HpWidgetOpacity"], gutils.dtForLerp(dt, 5))

        -- Calculating size of the hp widget bar
        local healthStat = currentTargetActor:healthStat()
        
        local maxHealth = healthStat.base
        local hpFraction = healthStat.current/maxHealth
        
        local minPossibleArcAngle = math.rad(30)
        local minPossibleHp = 10
        local maxPossibleArcAngle = math.rad(180)
        local maxPossibleHp = 200

        local arcAngleSize = util.remap(maxHealth, minPossibleHp, maxPossibleHp, minPossibleArcAngle, maxPossibleArcAngle)
        arcAngleSize = util.clamp(arcAngleSize, minPossibleArcAngle, maxPossibleArcAngle)
        
        hpWidgetShader.u.uMaxArcAngle = arcAngleSize
        hpWidgetShader.u.uCurArcAngle = arcAngleSize*hpFraction

        local lastHpFraction =  currentTargetActor.hpFraction
        currentTargetActor.hpFraction = hpFraction

        if lastHpFraction and hpFraction < lastHpFraction then
            -- Target actor was damaged! Initiating all relevant hp widget animations
            -- Adding an animated sector for a part of hp which was gone 

            local lostHpStartAngle = arcAngleSize*hpFraction
            local lostHpEndAngle = arcAngleSize*lastHpFraction
            
            -- If last added sector is still very fresh - update it
            local recentSector = hpWidgetShader.animSectors[#hpWidgetShader.animSectors]
            if recentSector and now - recentSector.startedAt <= recentSector.duration/3 then
                recentSector.startAngle = lostHpStartAngle
                recentSector.startedAt = now
            else
                table.insert(hpWidgetShader.animSectors,{
                    startAngle = lostHpStartAngle,
                    endAngle = lostHpEndAngle,
                    startedAt = now,
                    duration = 0.3
                })
            end
            
            if #hpWidgetShader.animSectors > hpWidgetShader.animSectorsLen then table.remove(hpWidgetShader.animSectors,1) end
            
            -- Adding wavy on-hit animation
            hpWidgetShader.onHitTween = Tweener:new()
            tweeners["onHitTween"] = hpWidgetShader.onHitTween
            hpWidgetShader.onHitTween:add(0.3, Tweener.easings.easeOutCubic, function(t)                
                hpWidgetShader.u.uOnHitWaveProgress = t
            end)

            -- Adding a lingering damage tail
            hpWidgetShader.lostHpTween = Tweener:new()
            tweeners["lostHpTween"] = hpWidgetShader.lostHpTween
            local tailAngle = hpWidgetShader.u.uLostHpTailAngle
            if not tailAngle or lostHpEndAngle > tailAngle then tailAngle = lostHpEndAngle end
            hpWidgetShader.lostHpTween:add(2, Tweener.easings.easeInCubic, function(t)
                hpWidgetShader.u.uLostHpTailAngle = gutils.lerp(tailAngle, lostHpStartAngle, t)
            end)
        end        
    else 
        hpWidgetShader.u.uOpacity = gutils.lerp(hpWidgetShader.u.uOpacity, 0, gutils.dtForLerp(dt, 5))
    end

    if not isHudVisible then
        hpWidgetShader.u.uOpacity = 0
    end

    -- Convert currently stored hp widget animated sectors into a proper shader variable
    local uAnimatedSectors = {}
    for _, sectorTable in ipairs(hpWidgetShader.animSectors) do
        local prog = (now - sectorTable.startedAt)/sectorTable.duration
        prog = Tweener.easings.easeOutCubic(prog)
        if prog > 1 then prog = 1 end
        table.insert(uAnimatedSectors,util.vector3(sectorTable.startAngle, sectorTable.endAngle, prog))
    end
    while #uAnimatedSectors < hpWidgetShader.animSectorsLen do
        table.insert(uAnimatedSectors,util.vector3(0, 0, 1))
    end
    hpWidgetShader.u.uAnimatedSectors = uAnimatedSectors

    ui_elements.parentElement:update()
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        [DEFS.e.HostileDamaged] = onHostileDamaged,
        [DEFS.e.MissedAttack] = onMissedAttack
    },
    interfaceName = "DynamicReticle",
    interface = {
        version=1.0, 
        setReticleWorldPos=setReticleWorldPos,
        setReticleScreenPos = setReticleScreenPos,
        setCurrentEnemy = setCurrentEnemy
    }
}
