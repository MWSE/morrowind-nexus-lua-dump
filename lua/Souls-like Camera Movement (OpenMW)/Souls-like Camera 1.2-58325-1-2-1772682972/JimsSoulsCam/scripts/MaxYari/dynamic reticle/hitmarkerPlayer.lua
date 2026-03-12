
-- 99% OF THIS CODE IS WRITTEN BY MAX YARI, THE 1% IS MODIFIED BY JIMBUSOID.
-- I, JIMBUSOID, TAKE ALL RESPONSIBILITY FOR ANY AND ALL BUGS. 

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
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local omwself = require("openmw.self")
local camera = require("openmw.camera")
local ui = require("openmw.ui")
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local MODE = camera.MODE
local currentReticlePos = util.vector2(0.5, 0.5)

local selfActor = gutils.Actor:new(omwself)

-- Ui Elements
local hitmarkerWrapperEl = ui_elements.getElementByName("hitmarkerWrapper")
local reticleEl = ui_elements.getElementByName("reticle")
local stealthArrowLEl = ui_elements.getElementByName("stealthArrowL")
local stealthArrowREl = ui_elements.getElementByName("stealthArrowR")

-- Settings
local visualSettings = storage.playerSection('DynamicReticleVisualSettings')
local soundSettings = storage.playerSection('DynamicReticleSoundSettings')
local hitMarkerColor = visualSettings:get("HitMarkerColor")
local KillMarkerColor = visualSettings:get("KillMarkerColor")
local HpWidgetOpacity = visualSettings:get("HpWidgetOpacity")
local HpWidgetColor = visualSettings:get("HpWidgetColor")
local HpWidgetDamageColor = visualSettings:get("HpWidgetDamageColor")
local HpWidgetScale = visualSettings:get("HpWidgetScale")
local StowedReticleAlpha = visualSettings:get("StowedReticleAlpha")
local ShowHpWidget = visualSettings:get("ShowHpWidget")
local SlowdownOnKillChance = visualSettings:get("SlowdownOnKillChance")
local SlowdownOnKillDuration = visualSettings:get("SlowdownOnKillDuration")

local currentTargetActor = nil
local wasSneaking = false

local tweeners = {}

local targetDistanceTimer = 0
local stanceNoneTimer = 0

local function dynamicCameraHasLock()
    if not (I.DynamicCamera and I.DynamicCamera.getLockTarget) then return nil end
    local t = I.DynamicCamera.getLockTarget()
    if not t then return nil end

    -- optional: guard stale/invalid
    if t.isValid and not t:isValid() then return nil end
    if types.Actor and types.Actor.isDead and types.Actor.isDead(t) then return nil end

    return t
end


local hpWidgetShader = shaderUtils.ShaderWrapper:new('hpWidget', {
    uOpacity = 0,
    uColor = HpWidgetColor:asRgb(),
    uDamageColor = HpWidgetDamageColor:asRgb(),
    uScale = HpWidgetScale,
})
hpWidgetShader.animSectors = {}
hpWidgetShader.animSectorsLen = 3

local function canUseSound()
    local stance = selfActor:getDetailedStance()
    return (soundSettings:get('MeleeSound') and stance == gutils.Actor.DET_STANCE.Melee) or
        (soundSettings:get('MarksmanSound') and stance == gutils.Actor.DET_STANCE.Marksman) or
        (soundSettings:get('SpellcasterSound') and stance == gutils.Actor.DET_STANCE.Spell)
end

local function animateSlideMarker(el, isDead)
    local u = el.userData
    local alpha = animConf.hmAlpha

    if isDead then 
        el.props.color = KillMarkerColor
    else 
        el.props.color = hitMarkerColor
        if I.s3ChimDamage and I.s3ChimDamage.state and I.s3ChimDamage.state.currentHitQuality == I.s3ChimDamage.HIT_QUALITY.Weak then            
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
    local ru = reticleEl.userData
    
    ru.tweener = Tweener:new()
    tweeners[reticleEl.name] = ru.tweener

    local function animateProps(t)
        for _, el in ipairs(arrows) do
            local eu = el.userData
            local offset = eu.direction * gutils.lerp(animConf.sneakArrowPartFromDist, animConf.sneakArrowPartToDist, t)
            el.props.relativePosition = util.vector2(0.5, 0.5) + offset
            el.props.alpha = util.clamp(animConf.reticleAlpha * t,0,1)
        end
        reticleEl.props.size = gutils.lerp(ru.size, ru.size*animConf.reticleSneakSizeMult, t)
    end

    if show then
        ru.tweener:add(0.5, Tweener.easings.springOutStrong, function(t)
            animateProps(t)
        end)
    else
        ru.tweener:add(0.5, Tweener.easings.springOutStrong, function(t)
            animateProps(1-t)
        end)
    end
end

local function setReticleScreenPos(screenPos)
    currentReticlePos = screenPos
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

    -- Throttle marker and sounds
    local currentTime = core.getRealTime()
    if data.currentHealth > 0 and currentTime - lastHostileDamagedTime < throttleInterval then
        return
    end
    lastHostileDamagedTime = currentTime

    for name, el in pairs(hitmarkerWrapperEl.content) do
        if not el.name then goto continue end

        animateSlideMarker(el, data.currentHealth <= 0)

        ::continue::
    end

    setCurrentEnemy(data.hostile)

    if canUseSound() then
        local params
        local pitches = {0.8,1, 1.2}
        local soundPath = nil
        if data.currentHealth <= 0 then
            params = { volume = soundSettings:get("DeathMarkerVolume"), pitch = pitches[math.random(1,#pitches)], loop = false }
            soundPath = settings.fileSelectors["DeathMarkerSound"]:getFilePath()
        else
            if I.s3ChimDamage and I.s3ChimDamage.state and I.s3ChimDamage.state.currentHitQuality == I.s3ChimDamage.HIT_QUALITY.Weak then
                -- Weak hit, play no sound
            else
                params = { volume = soundSettings:get("HitMarkerVolume"), pitch = pitches[math.random(1,#pitches)], loop = false }
                soundPath = settings.fileSelectors["HitMarkerSound"]:getFilePath()
            end
        end        
        core.sound.playSoundFile3d(soundPath, omwself, params)
    end

    -- Send slowdown event to global script when enemy is killed
    
    if data.currentHealth <= 0 and math.random() <= SlowdownOnKillChance then
        core.sendGlobalEvent("SlowdownEffect", { minScale = 0.2*SlowdownOnKillDuration, hold = 0.1*SlowdownOnKillDuration, inTime = 0.05*SlowdownOnKillDuration, outTime = 0.3*SlowdownOnKillDuration })
    end
end

-- Reticle bounce on shoot -----------------
--------------------------------------------
animManager.addOnKeyHandler(function(groupname, key)
    if key == "shoot release" then
        local ru = reticleEl.userData
        ru.tweener = Tweener:new()
        tweeners[reticleEl.name] = ru.tweener

        local originalSize = reticleEl.props.size
        local enlargedSize = originalSize * 1.75
        local originalAlpha = reticleEl.props.alpha
        local reducedAlpha = originalAlpha * 0.33

        -- Animate size and alpha when extending
        ru.tweener:add(0.1, Tweener.easings.springOutStrong, function(t)
            reticleEl.props.size = gutils.lerp(originalSize, enlargedSize, t)
            reticleEl.props.alpha = gutils.lerp(originalAlpha, reducedAlpha, t)
        end)
        -- Animate size and alpha when shrinking back
        :add(0.3, Tweener.easings.easeOutCubic, function(t)
            reticleEl.props.size = gutils.lerp(enlargedSize, originalSize, t)
            reticleEl.props.alpha = gutils.lerp(reducedAlpha, originalAlpha, t)
        end)
    end
end)

-- onUpdate -------------------------------------------
-------------------------------------------------------
local function onUpdate(dt)
    local isHudVisible = I.UI.isHudVisible()
    local now = core.getSimulationTime()

    local hasLock = dynamicCameraHasLock()

    -- Hiding/Showing widgets based on hud visibility and ensuring that hp widget is above hex dof from first person view dynamics.
    ui_elements.parentElement.layout.props.alpha = isHudVisible and 1 or 0
    -- Health widget is also hidden based on isHudVisible, but later down the line
    
    local widgetShouldStart = false
    if I.DynamicCamera then
        widgetShouldStart = I.DynamicCamera.shaders["hexDoFProgrammable"].enabled
    else
        widgetShouldStart = true
    end

    if widgetShouldStart and ShowHpWidget then
        hpWidgetShader:enable()
    else
        hpWidgetShader:disable()
    end
    
        if hasLock then
        
            if stance == types.Actor.STANCE.Nothing then
                reticleEl.props.alpha = gutils.lerp(reticleEl.props.alpha, StowedReticleAlpha, gutils.dtForLerp(dt, 5))
            else
                reticleEl.props.alpha = gutils.lerp(reticleEl.props.alpha, animConf.reticleAlpha, gutils.dtForLerp(dt, 5))
            end
        end

    if camera.getMode() ~= MODE.FirstPerson then
        if not hasLock then
            reticleEl.props.alpha = gutils.lerp(reticleEl.props.alpha, 0, gutils.dtForLerp(dt, 10))
            local center = util.vector2(0.5, 0.5)

        currentReticlePos = gutils.lerp(
        currentReticlePos,
        center,
        gutils.dtForLerp(dt, 6)
        )

        setReticleScreenPos(currentReticlePos)
        end
    end
    if camera.getMode() == MODE.FirstPerson then
        reticleEl.props.alpha = gutils.lerp(reticleEl.props.alpha, StowedReticleAlpha, gutils.dtForLerp(dt, 5))
        local center = util.vector2(0.5, 0.5)

        currentReticlePos = gutils.lerp(
        currentReticlePos,
        center,
        gutils.dtForLerp(dt, 6)
        )

        setReticleScreenPos(currentReticlePos)
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
    

    
    -- Removing current target actor if necessary. Curent target actor is the actor whos health is shown on the health widget
    if currentTargetActor and currentTargetActor:isDead() then 
        currentTargetActor = nil        
    end

    local stance = types.Actor.getStance(omwself)
    if currentTargetActor then
        -- Distance can't be more than 10 meters for more than 3 seconds
        local distance = (currentTargetActor.gameObject.position - omwself.position):length()
        if distance > 50*DEFS.GUtoM then
            targetDistanceTimer = targetDistanceTimer + dt
            if targetDistanceTimer >= 3 then
                currentTargetActor = nil
                targetDistanceTimer = 0
            end
        else
            targetDistanceTimer = 0
        end

        -- No-weapon stance hides enemy hp bar after 1 second        
        if stance == types.Actor.STANCE.Nothing then
            stanceNoneTimer = stanceNoneTimer + dt
            if stanceNoneTimer > 1 then
                currentTargetActor = nil
                stanceNoneTimer = 0
            end
        else
            stanceNoneTimer = 0
        end
    end

    -- Fade reticle alpha when stance is "nothing"    
    

    -- Update health widget

    if currentTargetActor then
        
        hpWidgetShader.u.uOpacity = gutils.lerp(hpWidgetShader.u.uOpacity, HpWidgetOpacity, gutils.dtForLerp(dt, 5))

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
    },
    interfaceName = "DynamicReticle",
    interface = {
        version=1.0, 
        setReticleWorldPos=setReticleWorldPos,
        setReticleScreenPos = setReticleScreenPos,
        setCurrentEnemy = setCurrentEnemy
    }
}
