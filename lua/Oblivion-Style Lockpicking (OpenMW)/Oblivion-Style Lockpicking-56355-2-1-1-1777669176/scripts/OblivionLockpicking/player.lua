local types = require("openmw.types")
local self = require("openmw.self")
local input = require("openmw.input")
local ui = require("openmw.ui")
local auxUi = require('openmw_aux.ui')
local async = require("openmw.async")
local core = require("openmw.core")
local nearby = require("openmw.nearby")
local util = require("openmw.util")
local camera = require("openmw.camera")
local I = require("openmw.interfaces")
local ambient = require("openmw.ambient")
local anim = require("openmw.animation")
local vfs = require("openmw.vfs")
local postprocessing = require("openmw.postprocessing")

local shader = postprocessing.load('OblivionLockpicking')

local configPlayer = require('scripts.OblivionLockpicking.config.player')
local configGlobal = require('scripts.OblivionLockpicking.config.global')
local Textures = require('scripts.OblivionLockpicking.textures')

local l10n = core.l10n('OblivionLockpicking')

local state = {}

state.isLockpicking = false
state.activeLockpick = nil
state.activeTarget = nil
state.activeTargetRayHitPos = nil
state.probeMode = false

state.textureOverride = nil
state.elementData = {}

Textures.init()

local function setElementData()
    if not state.textureOverride then
        return
    end
    state.elementData = {}
    for k, v in pairs(Textures.ELEMENT) do
        local data = Textures.getElement(state.textureOverride, v)
        if data then
            state.elementData[v] = {}
            state.elementData[v].texture = ui.texture {
                path = data.texturePath,
                offset = data.offset,
                size = data.size,
            }
            state.elementData[v].pos = data.pos
            state.elementData[v].size = data.size
        end
    end
end

local function getTexture(element)
    if not state.elementData[element] then
        return nil
    end
    return state.elementData[element].texture
end

local function getPosOffset(element)
    if not state.elementData[element] then
        return util.vector2(0, 0)
    end
    return state.elementData[element].pos
end

local function getSize(element)
    if not state.elementData[element] then
        return util.vector2(0, 0)
    end
    return state.elementData[element].size
end

local texturesTension = {
    red = ui.texture {
        path = 'textures/OblivionLockpicking/meter.dds',
        offset = util.vector2(0, 2),
        size = util.vector2(128, 4),
    },
    green = ui.texture {
        path = 'textures/OblivionLockpicking/meter.dds',
        offset = util.vector2(0, 10),
        size = util.vector2(128, 4),
    },
}

local uiBase = { 
    type = ui.TYPE.Image,
    props = {
        relativePosition = util.vector2(0.5, 0.5),
        anchor = util.vector2(0.5, 0.5),
    }
}
local uiPick = { 
    type = ui.TYPE.Image,
    props = {
        relativePosition = util.vector2(0.5, 0.5),
        anchor = util.vector2(1, 0),
    }
}
local uiTumbler = { 
    type = ui.TYPE.Container,
    props = {
        relativePosition = util.vector2(0.5, 0.5),
        anchor = util.vector2(0.5, 0),
    },
    content = ui.content {
        {
            type = ui.TYPE.Flex,
            content = {
                { 
                    type = ui.TYPE.Image,
                    props = {}
                },
                {
                    type = ui.TYPE.Image,
                    props = {},
                },
            }
        }
    }
}
local uiTumblerCover = { 
    type = ui.TYPE.Image,
    props = {
        relativePosition = util.vector2(0.5, 0.5),
        anchor = util.vector2(0.5, 0.5),
    }
}

local function assignTextures()
    local baseTexture = getTexture(Textures.ELEMENT.base)
    local pickTexture = getTexture(Textures.ELEMENT.pick_1)
    local tumblerTexture = getTexture(Textures.ELEMENT.spring)
    local tumblerPinTexture = getTexture(Textures.ELEMENT.pin)
    local tumblerCoverTexture = getTexture(Textures.ELEMENT.cover)

    uiBase.props.resource = baseTexture
    uiPick.props.resource = pickTexture
    uiTumbler.content[1].content[1].props.resource = tumblerTexture
    uiTumbler.content[1].content[2].props.resource = tumblerPinTexture
    uiTumblerCover.props.resource = tumblerCoverTexture
end

state.uiWrapper = nil
state.uiBaseElement, state.uiPickElement, state.uiTumblerCoverElement, state.uiInfoBoxElement, state.uiTensionElement = nil, nil, nil, nil, nil
state.uiTumblerElements = { nil, nil, nil, nil, nil }

state.infoBoxUpdateTimer = 0

state.tumblerSpacing = 51
state.tumblerCount = 5
state.tumblerBaseHeight = -155
state.tumblerBaseSpringHeight = 85
state.tumblerSetSpringHeight = 10
state.activeTumblers = nil
state.setTumblers = nil
state.tumblerPatterns = {}
state.tumblerPatternIndices = {}

state.movingTumbler = nil
state.movingTumblerIndex = nil
state.movingTumblerTime = nil
state.movingTumblerLockpickStartY = nil

state.movingTumblerBaseValues = {
    riseTime = 0.15,
    hangTime = 1/3,
    fallTime = 1.25,
}
state.movingTumblerSpeedMult = nil
state.movingTumblerCurrentValues = nil
state.movingTumblerStage = nil

state.movingPickStart = nil
state.movingPickTarget = nil
state.movingPickDuration = 1 / 16
state.movingPickTimer = nil

state.lockpickOffsetX = -96
state.lockpickOffsetY = 24
state.lockpickVisualOffset = util.vector2(0, 0)
state.lockpickBasePos = util.vector2(state.lockpickOffsetX, state.lockpickOffsetY)
state.lockpickAlignmentTolerance = 20
state.lockpickRangeX = {-128, 136}
state.lockpickRangeY = {0, 32}

state.crimeTimer = 0
state.crimeInterval = 0.5
state.crimeSeen = false

state.overallSuccessChance = nil
state.pinSuccessChance = nil
state.hangTimeMult = 1.0

state.controllerPrompts = false

state.storedRot = nil

state.lastStance = types.Actor.STANCE.Nothing

state.animStart = 0.35
state.animEnd = 0.58
state.animSpeed = 0.5
state.animStartRand = 0
state.animEndRand = 0

state.ambientScrapeIntervalMin = 1
state.ambientScrapeIntervalMax = 5
state.ambientScrapeTimer = 0
state.ambientScrapeLast = -1
state.ambientScrapeSounds = {}
for fileName in vfs.pathsWithPrefix("sound/OblivionLockpicking/scrape/") do
    table.insert(state.ambientScrapeSounds, fileName)
end

state.attempting = false
state.attemptTime = nil
state.attemptRollInterval = 0.5
state.attemptRollTimer = 0
state.attemptInfoBox = nil

state.advancedMode = false
state.tension = 0
state.tensionTarget = 500
state.tensionSweetSpot = 0
state.tensionRange = 0
state.tensionMin = 0
state.tensionMax = 0
state.tensionMaxMinLevel = 1500
state.tensionMaxMaxLevel = 3000
state.tensionLimits = { 0, 0 }
state.tensionTargetMoveSpeed = 0
state.tensionSweetSpotMinLevel = 300
state.tensionSweetSpotMaxLevel = 150
state.tensionRangeMinLevel = 1200
state.tensionRangeMaxLevel = 750
state.tensionLimitsMinLevel = { 0, 750 }
state.tensionLimitsMaxLevel = { 200, 2000 }
state.tensionTargetMoveSpeedRangeMinLevel = { 0, 125 }
state.tensionTargetMoveSpeedRangeMaxLevel = { 0, 200 }
state.tensionTargetVelocity = 0  -- current velocity of the target (for drift)
state.tensionTargetAccelerationTimer = 0
state.tensionTargetJitterRate = 0
state.tensionTargetJitterRateMinLevel = 0
state.tensionTargetJitterRateMaxLevel = 0.02

state.tensionTooLoose = 0
state.tensionTooTight = 0
state.tensionPickDamageAmount = 0
state.tensionFailureInterval = { 0.25, 0.5 }
state.tensionFailureTimer = 0
state.tensionPinSlipVelocity = 0
state.tensionPinsSlipping = {}

state.tensionMovingTumblerLockup = false

state.impactPause = 0
state.impactPauseLength = 1

state.previousSmoothedVelocity = 0
state.previousRightX = 0
state.previousRightY = 0
state.smoothingFactor = 0.99  -- 0 = no smoothing, 1 = very smoothed

-- === Util Functions ===
local function round(float, decimalPlaces)
    local mult = 10 ^ (decimalPlaces or 0)
    return math.floor(float * mult + 0.5) / mult
end

local function stochasticRound(float)
    local intPart = math.floor(float)
    if math.random() < float - intPart then
        return intPart + 1
    else
        return intPart
    end
end

local function lerp(t, a, b)
    return a + t * (b - a)
end

local function lerpQuad(t, a, b)
    return a + t * t * (b - a)
end

local function lerpQuadOut(t, a, b)
    t = 1 - t
    return a + (1 - t * t) * (b - a)
end

local function lerpCubic(t, a, b)
    return a + t * t * t * (b - a)
end

local function lerpQuintic(t, a, b)
    return a + t * t * t * t * t * (b - a)
end
-- ======================

local function scaleTumbler(index, scale)
    scale = util.clamp(scale, 0, 1)
    local springHeight = state.tumblerSetSpringHeight + (state.tumblerBaseSpringHeight - state.tumblerSetSpringHeight) * scale
    state.uiTumblerElements[index].layout.content[1].content[1].props.size = util.vector2(35, springHeight)
end

local function getTumblerScale(index)
    return (state.uiTumblerElements[index].layout.content[1].content[1].props.size.y - state.tumblerSetSpringHeight) / (state.tumblerBaseSpringHeight - state.tumblerSetSpringHeight)
end

local function modTumbler(index, mod)
    scaleTumbler(index, getTumblerScale(index) + mod)
end

local function getInputVelocity(dt)
    -- Mouse delta
    local dx = input.getMouseMoveX()
    local dy = input.getMouseMoveY()
    local mouseVelocity = math.sqrt(dx * dx + dy * dy) / dt

    -- Controller stick delta
    local currentRightX = input.getAxisValue(input.CONTROLLER_AXIS.LeftX)
    local currentRightY = input.getAxisValue(input.CONTROLLER_AXIS.LeftY)
    local deltaX = currentRightX - state.previousRightX
    local deltaY = currentRightY - state.previousRightY
    local controllerVelocity = math.sqrt(deltaX * deltaX + deltaY * deltaY) / dt
    controllerVelocity = controllerVelocity * 200  -- tweak this scale as needed

    -- Update previous controller positions
    state.previousRightX = currentRightX
    state.previousRightY = currentRightY

    -- Use the higher of the two
    local rawVelocity = math.max(mouseVelocity, controllerVelocity)

    -- Apply smoothing
    local smoothedVelocity = state.smoothingFactor * state.previousSmoothedVelocity + (1 - state.smoothingFactor) * rawVelocity
    state.previousSmoothedVelocity = smoothedVelocity

    return smoothedVelocity
end

local function initTensionSystem()
    state.tension = state.tensionMin
    state.previousSmoothedVelocity, state.previousRightX, state.previousRightY = state.tensionMin, 0, 0
     -- Start target in middle of range
    state.tensionTarget = (state.tensionLimits[1] + state.tensionLimits[2]) / 2
    state.tensionTargetVelocity = 0
    state.tensionTargetAccelerationTimer = 0
end

local function updateTensionDifficulty()
    local difficultyNormalized = util.clamp(1 - (state.overallSuccessChance or 0) / 100, 0, 1)

    state.tensionSweetSpot = lerp(difficultyNormalized, state.tensionSweetSpotMinLevel, state.tensionSweetSpotMaxLevel)
    state.tensionRange = lerp(difficultyNormalized, state.tensionRangeMinLevel, state.tensionRangeMaxLevel)

    state.tensionLimits[1] = lerp(difficultyNormalized, state.tensionLimitsMinLevel[1], state.tensionLimitsMaxLevel[1])
    state.tensionLimits[2] = lerp(difficultyNormalized, state.tensionLimitsMinLevel[2], state.tensionLimitsMaxLevel[2])

    state.tensionMax = lerp(difficultyNormalized, state.tensionMaxMinLevel, state.tensionMaxMaxLevel)

    state.tensionTargetMoveSpeed = lerp(difficultyNormalized, state.tensionTargetMoveSpeedRangeMinLevel[2], state.tensionTargetMoveSpeedRangeMaxLevel[2])
    state.tensionTargetJitterRate = lerp(difficultyNormalized, state.tensionTargetJitterRateMinLevel, state.tensionTargetJitterRateMaxLevel)
end

local function updateTensionTarget(dt)
    state.tensionTargetAccelerationTimer = state.tensionTargetAccelerationTimer - dt
    if state.tensionTargetAccelerationTimer <= 0 then
        state.tensionTargetAccelerationTimer = 0.3 + math.random() * 0.5  -- randomize interval
        -- Randomly nudge velocity (change direction/speed a bit)
        state.tensionTargetVelocity = state.tensionTargetVelocity + (math.random() * 2 - 1) * state.tensionTargetMoveSpeed
        state.tensionTargetVelocity = util.clamp(state.tensionTargetVelocity, -state.tensionTargetMoveSpeed, state.tensionTargetMoveSpeed)
    end
    
    if math.random() < state.tensionTargetJitterRate then
        state.tensionTargetVelocity = state.tensionTargetVelocity * (1 + math.random())  -- random jitter up to ±50% of current velocity
    end

    state.tensionTarget = state.tensionTarget + state.tensionTargetVelocity * dt

    -- Keep it in bounds and bounce off edges
    if state.tensionTarget < state.tensionLimits[1] then
        state.tensionTarget = state.tensionLimits[1]
        state.tensionTargetVelocity = math.abs(state.tensionTargetVelocity)
    elseif state.tensionTarget > state.tensionLimits[2] then
        state.tensionTarget = state.tensionLimits[2]
        state.tensionTargetVelocity = -math.abs(state.tensionTargetVelocity)
    end
end

local function updateTensionEffects()
    local sweetSpotBounds = { state.tensionTarget - state.tensionSweetSpot / 2, state.tensionTarget + state.tensionSweetSpot / 2 }
    local rangeBounds = { state.tensionTarget - state.tensionRange / 2, state.tensionTarget + state.tensionRange / 2 }

    if state.tension < sweetSpotBounds[1] then
        if state.tension >= rangeBounds[1] then
            local range = sweetSpotBounds[1] - rangeBounds[1]
            state.tensionTooLoose = (sweetSpotBounds[1] - state.tension) / range
        else
            state.tensionTooLoose = 1
        end
    else
        state.tensionTooLoose = 0
    end
    state.tensionPinSlipVelocity = state.tensionTooLoose * 0.05
    
    if state.tension > sweetSpotBounds[2] then
        if state.tension <= rangeBounds[2] then
            local range = rangeBounds[2] - sweetSpotBounds[2]
            state.tensionTooTight = (state.tension - sweetSpotBounds[2]) / range
        else
            state.tensionTooTight = 1
        end
    else
        state.tensionTooTight = 0
    end
    state.tensionPickDamageAmount = state.tensionTooTight * 1
end

state.tensionShakeTime = 0
local function updateTensionShake(dt)
    -- No shake in sweet zone
    local sweetSpotMax = state.tensionTarget + state.tensionSweetSpot / 2
    local rangeMax = state.tensionTarget + state.tensionRange / 2

    if state.tension <= sweetSpotMax then return 0, 0 end

    -- How deep into the danger zone are we? (0 to 1)
    local dangerLevel = math.min((state.tension - sweetSpotMax) / (rangeMax - sweetSpotMax), 1.0)

    -- Shake intensity grows with danger level
    local maxShake = 6
    local shakeIntensity = maxShake * dangerLevel^1.5  -- exponential for punch

    -- Shake frequency also ramps up
    local baseFreq = 6
    local maxFreq = 40
    local freq = baseFreq + (maxFreq - baseFreq) * dangerLevel

    -- Update shake time
    state.tensionShakeTime = state.tensionShakeTime + dt * freq

    -- Generate smooth chaotic offset (sin + noise-style randomization)
    local x = math.sin(state.tensionShakeTime * 2.1 + math.random()) * shakeIntensity
    local y = math.cos(state.tensionShakeTime * 1.8 + math.random()) * shakeIntensity * 0.6  -- vertical slightly lower for flavor

    return x, y
end

local function playAnim(args)
    local opts = {
        priority = {
            [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Weapon,
            [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Weapon,
            [anim.BONE_GROUP.Torso] = anim.PRIORITY.WeaponLowerBody,
            [anim.BONE_GROUP.LowerBody] = anim.PRIORITY.WeaponLowerBody,
        },
    }
    for k, v in pairs(args) do
        opts[k] = v
    end
    I.AnimationController.playBlendedAnimation('pickprobe', opts)
end

local function getAdjustedPickQuality()
    local quality = state.activeLockpick.quality
    local qualityMult = configGlobal.tweaks.n_PickQualityMult
    return quality * qualityMult + (1 - qualityMult)
end

local function infoLine(infoName, titleText)
    return {
        type = ui.TYPE.Flex,
        name = infoName .. 'Line',
        props = {
            horizontal = true,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                template = I.MWUI.templates.textHeader,
                props = {
                    text = titleText .. ': ',
                    textSize = 16,
                }
            },
            {
                template = I.MWUI.templates.textNormal,
                name = infoName,
                props = {
                    textSize = 16,
                }
            },
        }
    }
end

local function setInfoLineText(content, infoName, value)
    content.content[infoName .. 'Line'].content[infoName].props.text = value
end

local function insertTable(base, toAdd)
    for _, v in ipairs(toAdd) do
        table.insert(base, v)
    end
end

local function getInfoBox()
    state.infoBoxUpdateTimer = 0
    local baseContent = {}
    local divider = {
        { template = I.MWUI.templates.padding },
        { template = I.MWUI.templates.horizontalLine, props = { size = util.vector2(0, 2) }, external = { stretch = 1 } },
        { template = I.MWUI.templates.padding },
    }
    local chanceInfo = {
        infoLine('InfoBoxPinChance', l10n('InfoBoxPinChance')),
        infoLine('InfoBoxAutoAttemptChance', l10n('InfoBoxAutoAttemptChance')),
    }
    chanceInfo[2].props.size = util.vector2(210, 0)
    local difficultyInfo = {
        infoLine('InfoBoxDifficulty', l10n('InfoBoxDifficulty')),
    }
    difficultyInfo[1].props.size = util.vector2(150, 0)
    local pickInfo = {
        infoLine('InfoBoxPickName', state.probeMode and l10n('InfoBoxProbeName') or l10n('InfoBoxPickName')),
        infoLine('InfoBoxPickQuality', l10n('InfoBoxPickQuality')),
        infoLine('InfoBoxPickCondition', l10n('InfoBoxPickCondition')),
    }
    pickInfo[1].props.size = util.vector2(170, 0)
    local keybindInfo = {
        infoLine('InfoBoxKeybindMove', l10n('InfoBoxKeybindMove')),
        infoLine('InfoBoxKeybindPick', l10n('InfoBoxKeybindPick')),
        infoLine('InfoBoxKeybindAutoAttempt', l10n('InfoBoxKeybindAutoAttempt')),
        infoLine('InfoBoxKeybindStop', l10n('InfoBoxKeybindStop')),
    }
    if state.advancedMode then
        keybindInfo[5] = infoLine('InfoBoxKeybindTension', l10n('InfoBoxKeybindTension'))
    end

    local optProb = configPlayer.options.s_ShowInfoWindowProbability
    local optPick = configPlayer.options.b_ShowInfoWindowPick
    local optKeybinds = configPlayer.options.b_ShowInfoWindowKeybinds
    if optProb == 'ShowInfoWindowProbabilityBoth' then
        insertTable(baseContent, chanceInfo)
    end
    if optProb ~= 'ShowInfoWindowProbabilityNone' then
        insertTable(baseContent, difficultyInfo)
        if optPick or optKeybinds then
            insertTable(baseContent, divider)
        end
    end
    if optPick then
        insertTable(baseContent, pickInfo)
        if optKeybinds then
            insertTable(baseContent, divider)
        end
    end
    if optKeybinds then
        insertTable(baseContent, keybindInfo)
    end

    local relOffset = util.vector2(configPlayer.options.n_InfoWindowOffsetXRelative, configPlayer.options.n_InfoWindowOffsetYRelative)
    local absOffset = util.vector2(configPlayer.options.n_InfoWindowOffsetXAbsolute, configPlayer.options.n_InfoWindowOffsetYAbsolute)

    return {
        template = I.MWUI.templates.boxTransparentThick,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            autoSize = true
                        },
                        content = ui.content(baseContent)
                    }
                }
            }
        },
        props = {
            relativePosition = relOffset,
            position = absOffset,
            anchor = util.vector2(0, 0),
        }
    }
end

local function getTensionMeter()
    return {
        template = I.MWUI.templates.boxTransparentThick,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        type = ui.TYPE.Widget,
                        props = {
                            size = util.vector2(256, 16),
                        },
                        content = ui.content {
                            {
                                type = ui.TYPE.Image,
                                name = 'TensionMeterRed',
                                props = {
                                    resource = texturesTension.red,
                                    size = util.vector2(256, 16),
                                    anchor = util.vector2(0, 0),
                                    color = util.color.rgb(0.8, 0.05, 0.05),
                                }
                            },
                            {
                                type = ui.TYPE.Image,
                                name = 'TensionMeterRange',
                                props = {
                                    resource = texturesTension.red,
                                    size = util.vector2(256, 16),
                                    relativePosition = util.vector2(0.5, 0),
                                    anchor = util.vector2(0.5, 0),
                                    color = util.color.rgb(1, 1, 0),
                                    alpha = 0.4,
                                }
                            },
                            {
                                type = ui.TYPE.Image,
                                name = 'TensionMeterGreen',
                                props = {
                                    resource = texturesTension.green,
                                    size = util.vector2(256, 16),
                                    relativePosition = util.vector2(0.5, 0),
                                    anchor = util.vector2(0.5, 0),
                                    color = util.color.rgb(0, 0.9, 0),
                                }
                            },
                            {
                                template = I.MWUI.templates.borders,
                                name = 'TensionMeterMarker',
                                props = {
                                    size = util.vector2(6, 16),
                                    relativePosition = util.vector2(0.1, 0),
                                    anchor = util.vector2(0.5, 0),
                                },
                                content = ui.content {
                                    {
                                        type = ui.TYPE.Image,
                                        props = {
                                            resource = texturesTension.red,
                                            size = util.vector2(6, 16),
                                            color = util.color.rgb(0, 0, 0),
                                        }
                                    }
                                }
                            },
                            {
                                type = ui.TYPE.Image,
                                name = 'TensionMeterOverlay',
                                props = {
                                    resource = texturesTension.red,
                                    size = util.vector2(256, 16),
                                    relativePosition = util.vector2(0, 0),
                                    anchor = util.vector2(0, 0),
                                    color = util.color.rgb(0.25, 0, 0),
                                    alpha = 0,
                                }
                            }
                        }
                    }
                }
            }
        },
        props = {
            relativePosition = util.vector2(0.5, 0.5),
            position = util.vector2(0, 150),
            anchor = util.vector2(0.5, 0.5),
        }
    }
end

local function updateTension()
    if not state.uiTensionElement then return end
    if not state.advancedMode then
        state.uiTensionElement.layout.props.alpha = 0
    else
        local dt = core.getRealFrameDuration()
        updateTensionDifficulty()
        updateTensionTarget(dt)
        updateTensionEffects()

        if state.tensionTooTight > 0 and not ambient.isSoundFilePlaying("sound/OblivionLockpicking/tension1.wav") then
            ambient.playSoundFile("sound/OblivionLockpicking/tension1.wav", { volume = 0.3, scale = false, loop = true })
        elseif state.tensionTooTight <= 0 and ambient.isSoundFilePlaying("sound/OblivionLockpicking/tension1.wav") then
            ambient.stopSoundFile("sound/OblivionLockpicking/tension1.wav")
        end

        if state.tensionFailureTimer <= 0 then
            state.tensionFailureTimer = math.random() * (state.tensionFailureInterval[2] - state.tensionFailureInterval[1]) + state.tensionFailureInterval[1]
            -- Too loose: Start slipping pins
            for i = 1, state.activeTumblers do
                if math.random() < state.tensionTooLoose and state.setTumblers[i] == true then
                    state.tensionPinsSlipping[i] = true
                    break
                end
            end
            -- Too tight: Start damaging pick
            if state.tensionTooTight >= 1 then
                core.sendGlobalEvent('OSL_DrainLockpick', { player = self, full = true })
                state.tension = state.tensionTarget
                state.impactPause = state.impactPauseLength
                state.previousSmoothedVelocity, state.previousRightX, state.previousRightY = state.tensionTarget, 0, 0
                state.uiPickElement.layout.props.position = state.lockpickBasePos
                if ambient.isSoundFilePlaying("sound/OblivionLockpicking/tension1.wav") then
                    ambient.stopSoundFile("sound/OblivionLockpicking/tension1.wav")
                end
            elseif math.random() < state.tensionTooTight then
                ambient.playSoundFile("sound/OblivionLockpicking/tension" .. math.random(2, 3) .. ".wav", { volume = state.tensionTooTight * state.tensionTooTight, pitch = 0.9 + math.random() * 0.2, scale = false })
                core.sendGlobalEvent('OSL_DrainLockpick', { player = self, amount = stochasticRound(state.tensionPickDamageAmount) })
            end
        else
            state.tensionFailureTimer = state.tensionFailureTimer - dt
        end

        local slippingCount = 0
        for i = 1, state.activeTumblers do
            if state.tensionPinsSlipping[i] then
                if state.tensionPinSlipVelocity > 0 then
                    if not ambient.isSoundFilePlaying("sound/OblivionLockpicking/tumbler_fall.wav") then
                        ambient.playSoundFile("sound/OblivionLockpicking/tumbler_fall.wav")
                    end
                    modTumbler(i, state.tensionPinSlipVelocity * (getTumblerScale(i) + 0.05))
                    if getTumblerScale(i) >= 1 then
                        state.setTumblers[i] = false
                        state.tensionPinsSlipping[i] = false
                        ambient.playSoundFile("sound/OblivionLockpicking/tumbler_crash.wav")
                    else
                        slippingCount = slippingCount + 1
                    end
                end
            end
        end
        if slippingCount == 0 and not state.movingTumblerIndex then
            ambient.stopSoundFile("sound/OblivionLockpicking/tumbler_fall.wav")
        end

        state.uiTensionElement.layout.props.alpha = 1
        state.tension = math.max(state.tensionMin, math.min(state.tensionMax, getInputVelocity(dt)))
        local tensionMeter = state.uiTensionElement.layout.content[1].content[1]
        local tensionMarker = tensionMeter.content['TensionMeterMarker']
        local tensionMeterRange = tensionMeter.content['TensionMeterRange']
        local tensionMeterGreen = tensionMeter.content['TensionMeterGreen']
        local tensionMeterOverlay = tensionMeter.content['TensionMeterOverlay']

        local tensionPercent = (state.tension - state.tensionMin) / (state.tensionMax - state.tensionMin)
        local tensionTargetPercent = (state.tensionTarget - state.tensionMin) / (state.tensionMax - state.tensionMin)
        local tensionMarkerPos = util.vector2(tensionPercent, 0)

        tensionMarker.props.relativePosition = tensionMarkerPos
        tensionMeterRange.props.relativePosition = util.vector2(tensionTargetPercent, 0)
        tensionMeterGreen.props.relativePosition = util.vector2(tensionTargetPercent, 0)
        tensionMeterRange.props.size = util.vector2((state.tensionRange / (state.tensionMax - state.tensionMin)) * 256, 16)
        tensionMeterGreen.props.size = util.vector2((state.tensionSweetSpot / (state.tensionMax - state.tensionMin)) * 256 * 2, 16)

        if state.tensionTooLoose > 0 then
            tensionMeterOverlay.props.color = util.color.rgb(0, 0, 0.25)
            tensionMeterOverlay.props.alpha = util.clamp(lerp(state.tensionTooLoose, 0, 0.25), 0, 0.25)
        elseif state.tensionTooTight > 0 then
            tensionMeterOverlay.props.color = util.color.rgb(0.25, 0, 0)
            tensionMeterOverlay.props.alpha = util.clamp(lerp(state.tensionTooTight, 0, 1), 0, 1)
        else
            tensionMeterOverlay.props.alpha = 0
        end

        local shakeX, shakeY = updateTensionShake(dt)
        state.uiTensionElement.layout.props.position = util.vector2(shakeX, 150 + shakeY)
        state.uiPickElement.layout.props.position = util.vector2(-shakeX * 0.5 + state.lockpickOffsetX, shakeY * 0.5 + state.lockpickOffsetY) + state.lockpickVisualOffset
    end
end

local difficultyColors = {
    util.color.rgb(0, 1, 0), -- Very Easy
    util.color.rgb(0.5, 1, 0), -- Easy
    util.color.rgb(1, 1, 0), -- Average
    util.color.rgb(1, 0.5, 0), -- Hard
    util.color.rgb(1, 0, 0), -- Very Hard
    util.color.rgb(0.7, 0, 0.3), -- Extreme
}

local function updateInfoBox()
    if not state.uiInfoBoxElement then return end
    if not configPlayer.options.b_ShowInfoWindow then
        state.uiInfoBoxElement.layout.props.visible = false
        return
    end

    state.infoBoxUpdateTimer = state.infoBoxUpdateTimer - 1
    if state.infoBoxUpdateTimer > 0 then return
    else
        state.infoBoxUpdateTimer = configPlayer.options.n_InfoWindowUpdateInterval
    end

    local content = state.uiInfoBoxElement.layout.content[1].content[1]

    local difficulty
    if state.overallSuccessChance < 5 then
        difficulty = 6
    elseif state.overallSuccessChance < 10 then
        difficulty = 5
    elseif state.overallSuccessChance < 20 then
        difficulty = 4
    elseif state.overallSuccessChance < 40 then
        difficulty = 3
    elseif state.overallSuccessChance < 60 then
        difficulty = 2
    else
        difficulty = 1
    end

    local optProb = configPlayer.options.s_ShowInfoWindowProbability
    local optPick = configPlayer.options.b_ShowInfoWindowPick
    local optKeybinds = configPlayer.options.b_ShowInfoWindowKeybinds

    if optProb == 'ShowInfoWindowProbabilityBoth' then
        setInfoLineText(content, 'InfoBoxPinChance', string.format("%.2f%%", state.pinSuccessChance))
        setInfoLineText(content, 'InfoBoxAutoAttemptChance', string.format("%.2f%%", state.overallSuccessChance * configGlobal.tweaks.n_AutoAttemptSuccessModifier))
    end
    if optProb ~= 'ShowInfoWindowProbabilityNone' then
        setInfoLineText(content, 'InfoBoxDifficulty', l10n('InfoBoxDifficulty' .. difficulty))
        content.content['InfoBoxDifficultyLine'].content['InfoBoxDifficulty'].props.textColor = difficultyColors[difficulty]
    end
    if optPick then
        setInfoLineText(content, 'InfoBoxPickName', state.activeLockpick.name)
        local qualityString = string.format("%.2fx", state.activeLockpick.quality)
        if configGlobal.tweaks.n_PickQualityMult ~= 1 then qualityString = qualityString .. " (" .. string.format("%.2fx", getAdjustedPickQuality()) .. ")" end
        setInfoLineText(content, 'InfoBoxPickQuality', qualityString)
        local lockpick = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
        local condition = lockpick and types.Item.itemData(lockpick).condition or 0
        setInfoLineText(content, 'InfoBoxPickCondition', tostring(condition) .. "/" .. state.activeLockpick.maxCondition)
        content.content['InfoBoxPickConditionLine'].content['InfoBoxPickCondition'].props.textColor = state.attempting and util.color.rgb(1, 1, 0) or nil
    end
    if optKeybinds then
        if not state.controllerPrompts then
            local moveText = state.advancedMode and l10n('InfoBoxKeybindMoveTextAdvanced') or l10n('InfoBoxKeybindMoveText')
            setInfoLineText(content, 'InfoBoxKeybindMove', moveText .. input.getKeyName(configPlayer.keybinds.keybindPreviousPin) .. "/" .. input.getKeyName(configPlayer.keybinds.keybindNextPin))
            setInfoLineText(content, 'InfoBoxKeybindPick', input.getKeyName(configPlayer.keybinds.keybindPickPin) .. l10n('InfoBoxKeybindPickText'))
            setInfoLineText(content, 'InfoBoxKeybindAutoAttempt', input.getKeyName(configPlayer.keybinds.keybindAutoAttempt))
            setInfoLineText(content, 'InfoBoxKeybindStop', input.getKeyName(configPlayer.keybinds.keybindCancel))
            if state.advancedMode then
                setInfoLineText(content, 'InfoBoxKeybindTension', l10n('InfoBoxKeybindTensionText'))
            end
        else 
            local moveText = state.advancedMode and l10n('InfoBoxKeybindMoveControllerTextAdvanced') or l10n('InfoBoxKeybindMoveControllerText')
            setInfoLineText(content, 'InfoBoxKeybindMove', moveText)
            setInfoLineText(content, 'InfoBoxKeybindPick', l10n('InfoBoxKeybindPickControllerText'))
            setInfoLineText(content, 'InfoBoxKeybindAutoAttempt', l10n('InfoBoxKeybindAutoAttemptControllerText'))
            setInfoLineText(content, 'InfoBoxKeybindStop', l10n('InfoBoxKeybindStopControllerText'))
            if state.advancedMode then
                setInfoLineText(content, 'InfoBoxKeybindTension', l10n('InfoBoxKeybindTensionControllerText'))
            end
        end
    end
end

local function updateAttemptInfoBox()
    if state.attemptInfoBox then
        if not state.attempting then
            state.attemptInfoBox:destroy()
            state.uiWrapper.layout.content[state.uiWrapper.layout.content:indexOf(state.attemptInfoBox)] = nil
            state.attemptInfoBox = nil
        else
            local pick = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
            local condition = pick and types.Item.itemData(pick).condition or 0
            state.attemptInfoBox.layout.content[1].content[1].content['durability'].props.text = l10n('AttemptInfoBoxDurability'):gsub('%%{durability}', tostring(condition) .. "/" .. state.activeLockpick.maxCondition)
            state.attemptInfoBox.layout.content[1].content[1].content['cancel'].props.text = l10n('AttemptInfoBoxCancel'):gsub('%%{cancelKey}', state.controllerPrompts and l10n('InfoBoxKeybindPickControllerText') or (input.getKeyName(configPlayer.keybinds.keybindPickPin) .. l10n('InfoBoxKeybindPickText')))
        end
    end
end

local function getType()
    if state.probeMode then return types.Probe end
    return types.Lockpick
end

local function getLockLevel(target)
    return types.Lockable.getLockLevel(target) * configGlobal.tweaks.n_BaseDifficultyMult
end

local function getTrapLevel(target)
    local trapSpell = types.Lockable.getTrapSpell(target)
    return (trapSpell and trapSpell.cost or 0) * configGlobal.tweaks.n_BaseDifficultyMult
end

local function getOverallSuccessChance()
    local security = types.NPC.stats.skills.security(self).modified
    local agiOrInt
    if configGlobal.options.b_UseIntelligence then
        agiOrInt = types.Actor.stats.attributes.intelligence(self).modified
    else
        agiOrInt = types.Actor.stats.attributes.agility(self).modified
    end
    local luck = types.Actor.stats.attributes.luck(self).modified
    local fatigueCurrent = types.Actor.stats.dynamic.fatigue(self).current
    local fatigueMax = types.Actor.stats.dynamic.fatigue(self).base
    local lockLevel = getLockLevel(state.activeTarget)

    local statsMod = security + (agiOrInt / 5) + (luck / 10)
    local qualityMult = configGlobal.tweaks.n_PickQualityMult
    local equipmentMod = state.activeLockpick.quality * qualityMult + (1 - qualityMult)
    local fatigueNorm
    if fatigueMax > 0 then
        fatigueNorm = (fatigueCurrent / fatigueMax)
    else
        fatigueNorm = 1
    end
    local fatigueMod = core.getGMST('fFatigueBase') - core.getGMST('fFatigueMult') * (1 - fatigueNorm)
    
    if state.probeMode then
        statsMod = statsMod + (core.getGMST('fTrapCostMult') * getTrapLevel(state.activeTarget))
    end

    local finalMod = statsMod * equipmentMod * fatigueMod

    if not state.probeMode then
        finalMod = finalMod + (core.getGMST('fPickLockMult') * lockLevel)
    end

    state.hangTimeMult = 0.65 + (finalMod / 100) * 0.85
    return finalMod
end

local function getPinSuccessChance()
    if configGlobal.options.s_SkillAffectsChance == 'SkillChecks_Disabled' then return 100 end

    local baseMod = util.clamp(getOverallSuccessChance(), 0, 100)
    return util.clamp(math.pow(baseMod / 100, 1 / (state.activeTumblers)) * 100 * (1 - math.exp(-baseMod / 10)), configGlobal.tweaks.n_BasePinChanceMin, configGlobal.tweaks.n_BasePinChanceMax) * configGlobal.tweaks.n_BasePinChanceMult
end

local function setActiveTumblers()
    local tumblerCount
    if configGlobal.tweaks.n_TumblerCountScale == 0 then
        tumblerCount = 5
    else
        tumblerCount = math.min(1 + math.floor((state.probeMode and getTrapLevel(state.activeTarget) or getLockLevel(state.activeTarget)) / configGlobal.tweaks.n_TumblerCountScale), 5)
    end
    state.activeTumblers = tumblerCount
end

local function generatePattern(level)
    level = math.max(1, math.min(100, level))
    local minTrueThreshold = 0.2
    local maxTrueThreshold = 0.4

    local config = configGlobal.tweaks
    local minLen = config.n_PatternLengthBaseMin
    local maxLen = config.n_PatternLengthBaseMax
    local minVar = config.n_PatternLengthVariationMin
    local maxVar = config.n_PatternLengthVariationMax
    
    maxLen = math.max(minLen, maxLen)
    maxVar = math.max(minVar, maxVar)

    -- Map input (1–100) to a base pattern length (before variation)
    local baseLength = math.floor(minLen + (level - 1) * ((maxLen - minLen) / 99))
    local variation = math.floor(minVar + (level - 1) * ((maxVar - minVar) / 99))

    -- Apply variation
    local variationApplied = math.random(0, variation)
    local patternLength = math.max(1, baseLength + variationApplied)

    local minTrues = math.floor(patternLength * minTrueThreshold)
    local maxTrues = math.floor(patternLength * maxTrueThreshold)
    if minTrues < 1 then minTrues = 1 end
    if maxTrues < minTrues then maxTrues = minTrues end
    
    local numTrues = math.random(minTrues, maxTrues)

    -- Randomly assign unique positions for slow values
    local truePositions = {}
    local trueCount = 0
    while trueCount < numTrues do
        local pos = math.random(1, patternLength)
        if not truePositions[pos] then
            truePositions[pos] = true
            trueCount = trueCount + 1
        end
    end

    -- Build the final pattern with numeric values
    local pattern = {}
    for i = 1, patternLength do
        if truePositions[i] then
            -- Slow value: 0.9–1.0
            pattern[i] = 0.9 + math.random() * 0.1
        else
            -- Fast value: 0.2–0.5
            pattern[i] = 0.2 + math.random() * 0.3
        end
    end

    return pattern
end

local function setTumblerPatterns()
    for i = 1, state.activeTumblers do
        local pattern = generatePattern(state.probeMode and getTrapLevel(state.activeTarget) or getLockLevel(state.activeTarget))
        state.tumblerPatterns[i] = pattern
        state.tumblerPatternIndices[i] = 1
    end
end

local function restoreStoredRot()
    if state.storedRot then
        local yawDiff = state.storedRot:getYaw() - self.rotation:getYaw()
        local pitchDiff = state.storedRot:getPitch() - self.rotation:getPitch()
        self.controls.yawChange = yawDiff
        self.controls.pitchChange = pitchDiff
    end
end

state.activeEffects = self.type.activeEffects(self)
state.iMaxActivateDist = core.getGMST("iMaxActivateDist")
local function getRange()
    local dist = state.iMaxActivateDist + camera.getThirdPersonDistance()
    local telekinesis = state.activeEffects:getEffect(core.magic.EFFECT_TYPE.Telekinesis)
    if telekinesis then
        dist = dist + (telekinesis.magnitude * 22)
    end
    return dist
end

local function getTargetedObject()
    -- To do this, we will use the nearby module to cast a ray in the direction the player is facing
    local range = getRange()
    local pos = camera.getPosition()
    local v = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
	return nearby.castRenderingRay(pos, pos + v * range, { ignore = self })
end

local function toolEquipped()
    local equippedR = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if not equippedR then return false end
    local isLockpick = types.Lockpick.objectIsInstance(equippedR)
    local isProbe = types.Probe.objectIsInstance(equippedR)
    if not (isLockpick or (isProbe and configGlobal.options.b_UseForDisarming)) then return false end
    return true, equippedR, isLockpick, isProbe
end

local function canLockpick()
    if not configGlobal.options.b_EnableMod then return false end
    if state.isLockpicking then return false end
    if core.isWorldPaused() then return false end
    if types.Actor.getStance(self) ~= types.Actor.STANCE.Weapon then return false end
    local hasTool, equippedR, isLockpick, isProbe = toolEquipped()
    if not hasTool then return false end

    local targetRay = getTargetedObject()
    local target = targetRay.hitObject
    if not target then return false, equippedR end
    if not types.Lockable.objectIsInstance(target) 
        or (isLockpick and not types.Lockable.isLocked(target)) 
        or (isProbe and not types.Lockable.getTrapSpell(target)) 
        then return false, equippedR end

    local record
    if isLockpick then
        record = types.Lockpick.records[equippedR.recordId]
    else
        record = types.Probe.records[equippedR.recordId]
    end
    state.activeTargetRayHitPos = targetRay.hitPos
    return true, record, target, isProbe
end

local function updateUiPick()
    local thresholds = state.probeMode and { math.huge, 1.5, 1.25, 1, 0.75, -math.huge } or { 5, 1.5, 1.4, 1.3, 1.1, -math.huge }
    local tier = round(state.activeLockpick.quality, 3)
    local prefix = state.probeMode and 'probe_' or 'pick_'
    for i = 1, #thresholds do
        if tier >= thresholds[i] then
            state.uiPickElement.layout.props.resource = getTexture(Textures.ELEMENT[prefix .. (7 - i)])
            state.uiPickElement.layout.props.size = getSize(Textures.ELEMENT[prefix .. (7 - i)])
            return
        end
    end
end

local function createElements()
    state.textureOverride = Textures.getOverride(state.activeTarget)
    setElementData()
    assignTextures()

    
    uiBase.props.size = getSize(Textures.ELEMENT.base)
    uiBase.props.position = getPosOffset(Textures.ELEMENT.base)
    uiTumblerCover.props.size = getSize(Textures.ELEMENT.cover)
    uiTumblerCover.props.position = getPosOffset(Textures.ELEMENT.cover)
    uiTumbler.content[1].content[2].props.size = getSize(Textures.ELEMENT.pin)

    state.uiBaseElement = ui.create(uiBase)
    state.uiPickElement = ui.create(uiPick)
    state.uiPickElement.layout.props.position = state.lockpickBasePos
    updateUiPick()

    state.setTumblers = {}
    for i = 1, state.tumblerCount do
        local layout = auxUi.deepLayoutCopy(uiTumbler)
        local yOffset = state.tumblerBaseHeight
        local springHeight = i > state.activeTumblers and state.tumblerSetSpringHeight or state.tumblerBaseSpringHeight
        layout.props.position = util.vector2(state.tumblerSpacing * (i-3) - 6, yOffset)
        layout.content[1].content[1].props.size = util.vector2(35, springHeight)
        state.uiTumblerElements[i] = ui.create(layout)
        state.setTumblers[i] = i > state.activeTumblers
    end

    state.uiTumblerCoverElement = ui.create(uiTumblerCover)
    state.uiInfoBoxElement = ui.create(getInfoBox())
    state.uiTensionElement = ui.create(getTensionMeter())

    state.uiWrapper = ui.create {
        layer = 'Notification',
        props = {
            relativeSize = util.vector2(1, 1),
        },
        content = ui.content {
            state.uiBaseElement,
            state.uiPickElement,
            state.uiTumblerElements[1],
            state.uiTumblerElements[2],
            state.uiTumblerElements[3],
            state.uiTumblerElements[4],
            state.uiTumblerElements[5],
            state.uiTumblerCoverElement,
            state.uiInfoBoxElement,
            state.uiTensionElement,
        }
    }
end

local function initValues()
    state.lockpickOffsetX = state.lockpickBasePos.x
    state.lockpickOffsetY = state.lockpickBasePos.y
    state.movingTumbler = nil
    state.movingTumblerIndex = nil
    state.movingTumblerTime = nil
    state.movingTumblerLockpickStartY = nil
    state.movingTumblerSpeedMult = nil
    state.movingTumblerCurrentValues = nil
    state.movingTumblerStage = nil
    state.movingPickStart = nil
    state.movingPickTarget = nil
    state.movingPickTimer = nil
    state.crimeTimer = state.crimeInterval
    state.crimeSeen = false
    state.tensionPinsSlipping = { false, false, false, false, false }
    state.impactPause = 0
end

local function destroyElements()
    if state.uiWrapper then
        auxUi.deepDestroy(state.uiWrapper)
        state.uiWrapper = nil
        state.attemptInfoBox = nil
    end
end

state.autoSheathe = false
state.trySheathe = false

local function dropTumblers(index, badTiming)
    index = index or -1
    local keepUp
    if not configGlobal.options.b_SecurityAffectsTumblerDrops then 
        keepUp = 0
    else
        local security = types.NPC.stats.skills.security(self).base
        local interval = configGlobal.tweaks.n_SecurityAffectsTumblerDropsLevelInterval
        keepUp = math.floor(security / interval)
    end

    ambient.playSoundFile("sound/OblivionLockpicking/tumbler_crash.wav")
    for i = 1, state.activeTumblers do
        local shouldReset = (i == index) or (badTiming and state.setTumblers[i] and keepUp == 0)
        if shouldReset then
            state.setTumblers[i] = false
            scaleTumbler(i, 1)
        elseif badTiming and state.setTumblers[i] then
            keepUp = keepUp - 1
        end
    end
end

local function stopLockpicking(success)
    if not state.isLockpicking then return end
    ambient.stopSoundFile("sound/OblivionLockpicking/tension1.wav")
    if state.attempting then
        state.attempting = false
        dropTumblers(state.movingTumblerIndex, configGlobal.options.b_MissedRollsDropOtherPins)
        state.movingPickStart = util.vector2(state.lockpickOffsetX, state.lockpickOffsetY)
        state.movingPickTarget = util.vector2(state.tumblerSpacing * (state.movingTumblerIndex - 3) + 8, 24)
        state.movingPickTimer = 0
        state.movingTumbler = nil
        state.movingTumblerIndex = nil
        state.movingTumblerTime = nil
        state.movingTumblerSpeedMult = nil
        state.movingTumblerCurrentValues = nil
        state.movingTumblerLockpickStartY = nil
        state.movingTumblerStage = nil
        return
    end
    success = success or false
    anim.cancel(self, 'pickprobe')
    if success then
        ui.showMessage(state.probeMode and l10n('Msg_ProbeSuccess') or l10n('Msg_LockpickSuccess'))
        core.sendGlobalEvent('OSL_DrainLockpick', { player = self })
        core.sendGlobalEvent("OSL_LockpickSuccess", { player = self, target = state.activeTarget, probe = state.probeMode })
        local skillUseType = state.probeMode and I.SkillProgression.SKILL_USE_TYPES.Security_DisarmTrap or I.SkillProgression.SKILL_USE_TYPES.Security_PickLock
        I.SkillProgression.skillUsed('security', { useType = skillUseType })
    end
    state.activeTarget = nil
    state.activeLockpick = nil
    state.isLockpicking = false
    state.activeTumblers = nil
    destroyElements()
    core.sendGlobalEvent('OSL_PauseWorldLockpicking', { paused = false })
    
    for _, group in pairs(anim.BONE_GROUP) do
        anim.cancel(self, anim.getActiveGroup(self, group))
    end

    anim.cancel(self, 'pickprobe')
    if success then
        playAnim({ speed = 1, startPoint = 0 })
    end
    
    if state.autoSheathe then
        state.autoSheathe = false
        state.trySheathe = true
    end

    restoreStoredRot()

    shader:disable()
end

local function startLockpicking()
    if type(configGlobal.options.s_SkillAffectsChance) ~= 'string' then
        configGlobal.options.s_SkillAffectsChance = 'SkillChecks_Automatic'
    end

    local canPick, lockpick, target, probe = canLockpick()
    if not canPick then 
        if lockpick and I.UI.getMode() == nil then
            if state.lastStance ~= types.Actor.STANCE.Weapon then
                playAnim({ startKey = 'equip start', stopKey = 'equip end' })
            else
                playAnim({})
            end
        end
        return
    end
    state.storedRot = self.rotation
    state.probeMode = probe or false
    state.activeLockpick = lockpick
    state.activeTarget = target
    state.isLockpicking = true
    state.advancedMode = configGlobal.options.b_AdvancedMode
    state.attemptRollInterval = configGlobal.tweaks.n_SkillCheckAttemptInterval or 0.5

    setActiveTumblers()
    setTumblerPatterns()

    state.overallSuccessChance = getOverallSuccessChance()
    state.pinSuccessChance = getPinSuccessChance()

    updateTensionDifficulty()
    initTensionSystem()

    createElements()
    initValues()
    core.sendGlobalEvent('OSL_PauseWorldLockpicking', { paused = true})

    restoreStoredRot()

    -- Compatibility with UI Modes' auto-draw feature
    if state.lastStance ~= types.Actor.STANCE.Weapon then
        state.autoSheathe = true
        playAnim({ startKey = 'equip start', stopKey = 'start' })
    else 
        state.autoSheathe = false
        playAnim({ speed = state.animSpeed, startPoint = 0 })
    end

    shader:setBool('uDarken', configPlayer.options.b_DarkenBackground)
    shader:setBool('uBlur', configPlayer.options.b_BlurBackground)
    shader:setFloat('uDarkenStrength', configPlayer.options.f_DarkenStrength)
    shader:setFloat('uBlurStrength', configPlayer.options.f_BlurStrength)
    shader:enable()
end

local function onPick()
    if I.UI.getMode() ~= nil then return end
    if state.impactPause > 0 then return end
    if state.movingTumbler ~= nil then
        if state.movingTumbler.layout.content:indexOf('glow') then
            state.movingTumbler.layout.content.glow = nil
        end

        if not state.tensionMovingTumblerLockup then
            ambient.stopSoundFile("sound/OblivionLockpicking/tumbler_fall.wav")
            local skillRoll = math.random() < (state.pinSuccessChance / 100)
            local tooEarly = state.movingTumblerTime <= state.movingTumblerCurrentValues.riseTime
            local tooLate = state.movingTumblerTime > state.movingTumblerCurrentValues.riseTime + state.movingTumblerCurrentValues.hangTime
            if skillRoll and not tooEarly and not tooLate then
                if state.attempting then
                    state.attempting = false
                    for i = 1, 3 do
                        ambient.stopSoundFile("sound/OblivionLockpicking/tension" .. i .. ".wav")
                    end
                end
                
                state.movingPickStart = util.vector2(state.lockpickOffsetX, state.lockpickOffsetY)
                state.movingPickTarget = util.vector2(state.tumblerSpacing * (state.movingTumblerIndex - 3) + 8, 24)
                state.movingPickTimer = 0
                -- Tumbler is in the right position, lock it in place
                state.setTumblers[state.movingTumblerIndex] = true
                state.movingTumbler.layout.content[1].content[1].props.size = util.vector2(35, state.tumblerSetSpringHeight)

                ambient.playSoundFile("sound/OblivionLockpicking/tumbler_lock.wav", { volume = 2.0 })

                -- Check if all tumblers are set
                local allSet = true
                for i = 1, state.activeTumblers do
                    if not state.setTumblers[i] then
                        allSet = false
                        break
                    end
                end

                if allSet then
                    -- All tumblers are set, unlock the lock and stop lockpicking
                    stopLockpicking(true)
                end
            else
                core.sendGlobalEvent('OSL_DrainLockpick', { player = self })
                -- Fail; reset all tumblers and break the lockpick

                if not tooEarly and not tooLate and not state.attempting and configGlobal.options.s_SkillAffectsChance ~= 'SkillChecks_Hardcore' then
                    state.attempting = true
                    state.attemptTime = 0
                    state.attemptInfoBox = ui.create {
                        template = I.MWUI.templates.boxTransparentThick,
                        content = ui.content {
                            {
                                template = I.MWUI.templates.padding,
                                content = ui.content {
                                    {
                                        type = ui.TYPE.Flex,
                                        props = {
                                            autoSize = true,
                                            arrange = ui.ALIGNMENT.Center,
                                        },
                                        content = ui.content {
                                            {
                                                name = 'header',
                                                template = I.MWUI.templates.textHeader,
                                                props = {
                                                    text = l10n('AttemptInfoBoxHeader'),
                                                },
                                            },
                                            {
                                                name = 'durability',
                                                template = I.MWUI.templates.textNormal,
                                                props = {
                                                    text = l10n('AttemptInfoBoxDurability'),
                                                    textColor = util.color.rgb(1, 1, 0),
                                                },
                                            },
                                            {
                                                name = 'cancel',
                                                template = I.MWUI.templates.textNormal,
                                                props = {
                                                    text = l10n('AttemptInfoBoxCancel'),
                                                },
                                            }
                                        }
                                    }
                                }
                            }
                        },
                        props = {
                            relativePosition = util.vector2(0.5, 0.5),
                            position = util.vector2(0, -uiBase.props.size.y / 2 + 120),
                            anchor = util.vector2(0.5, 1),
                        }
                    }
                    state.uiWrapper.layout.content:add(state.attemptInfoBox)
                end

                if state.attempting then
                    state.attemptRollTimer = state.attemptRollInterval
                    ambient.playSoundFile("sound/OblivionLockpicking/tension" .. math.random(2, 3) .. ".wav")
                    if not ambient.isSoundFilePlaying("sound/OblivionLockpicking/tension1.wav") then
                        ambient.playSoundFile("sound/OblivionLockpicking/tension1.wav", { volume = 0.75, scale = false, loop = true })
                    end
                end

                if not state.attempting then
                    dropTumblers(state.movingTumblerIndex, tooEarly or tooLate or configGlobal.options.b_MissedRollsDropOtherPins)
                    if configPlayer.options.b_ShowFailureReason then
                        if tooEarly then
                            ui.showMessage(l10n('Msg_FailTooEarly'))
                        elseif tooLate then
                            ui.showMessage(l10n('Msg_FailTooLate'))
                        elseif not skillRoll then
                            local percentageString = configPlayer.options.b_ShowFailureReasonPercentage and string.format(" (%.2f%%)", state.pinSuccessChance) or ''
                            ui.showMessage(l10n('Msg_FailSkillRoll') .. percentageString)
                        end
                    end
                    state.movingPickStart = util.vector2(state.lockpickOffsetX, state.lockpickOffsetY)
                    state.movingPickTarget = util.vector2(state.tumblerSpacing * (state.movingTumblerIndex - 3) + 8, 24)
                    state.movingPickTimer = 0
                end
            end

            if not state.attempting then
                state.movingTumbler = nil
                state.movingTumblerIndex = nil
                state.movingTumblerTime = nil
                state.movingTumblerSpeedMult = nil
                state.movingTumblerCurrentValues = nil
                state.movingTumblerLockpickStartY = nil
                state.movingTumblerStage = nil
            end
        end
    else
        -- Find the targeted pin and move the pick up to it
        local nearestTumbler = util.clamp(math.floor(((state.lockpickOffsetX + 94) + state.tumblerSpacing / 2) / state.tumblerSpacing), 0, 4)
        if state.setTumblers[nearestTumbler + 1] == true then return end
        local distanceToTumbler = (state.lockpickOffsetX + 94) - (nearestTumbler * state.tumblerSpacing)
        if math.abs(distanceToTumbler) <= state.lockpickAlignmentTolerance then
            -- Move the pick to the pin position
            state.movingPickStart = util.vector2(state.lockpickOffsetX, state.lockpickOffsetY)
            state.movingPickTarget = util.vector2(state.tumblerSpacing * (nearestTumbler - 2) + 8, 0)
            state.movingPickTimer = 0
        end
    end
end

local function onPrevPin()
    if I.UI.getMode() ~= nil then return end
    if state.impactPause > 0 or state.movingTumbler or state.movingPickTimer then return end
    local nearestTumbler = util.clamp(math.floor(((state.lockpickOffsetX + 94) + state.tumblerSpacing / 2) / state.tumblerSpacing), 0, 4)
    if nearestTumbler > 0 then
        local targetOffsetX = state.tumblerSpacing * (nearestTumbler - 3) + 8
        local targetOffsetY = 24
        state.movingPickTimer = 0
        state.movingPickStart = util.vector2(state.lockpickOffsetX, state.lockpickOffsetY)
        state.movingPickTarget = util.vector2(targetOffsetX, targetOffsetY)
        ambient.playSoundFile("sound/OblivionLockpicking/pickmove1.wav", { pitch = 1.25 })
    end
end

local function onNextPin()
    if I.UI.getMode() ~= nil then return end
    if state.impactPause > 0 or state.movingTumbler or state.movingPickTimer then return end
    local nearestTumbler = util.clamp(math.floor(((state.lockpickOffsetX + 94) + state.tumblerSpacing / 2) / state.tumblerSpacing), 0, 4)
    if nearestTumbler < state.activeTumblers - 1 then
        local targetOffsetX = state.tumblerSpacing * (nearestTumbler - 1) + 8
        local targetOffsetY = 24
        state.movingPickTimer = 0
        state.movingPickStart = util.vector2(state.lockpickOffsetX, state.lockpickOffsetY)
        state.movingPickTarget = util.vector2(targetOffsetX, targetOffsetY)
        ambient.playSoundFile("sound/OblivionLockpicking/pickmove2.wav", { pitch = 1.25 })
    end
end

state.mouseMoveXAccum = 0
state.mouseMoveYAccum = 0

local function updateLockpick()
    if state.attempting then
        state.lockpickVisualOffset = util.vector2(0, math.cos(state.attemptTime * 2 * math.pi / state.attemptRollInterval) * 3)
        state.lockpickOffsetX = state.tumblerSpacing * (state.movingTumblerIndex - 3) + 8
        state.lockpickOffsetY = 8
        state.uiPickElement.layout.props.position = util.vector2(state.lockpickOffsetX, state.lockpickOffsetY) + state.lockpickVisualOffset
        return
    else
        state.lockpickVisualOffset = util.vector2(0, 0)
    end

    
    if state.movingPickTimer == nil then
        local mouseMoveX = input.getMouseMoveX()
        local mouseMoveY = input.getMouseMoveY()
        if (mouseMoveX > 0 and state.mouseMoveXAccum < 0) or (mouseMoveX < 0 and state.mouseMoveXAccum > 0) then
            state.mouseMoveXAccum = 0
        end
        if mouseMoveY == 0 or (mouseMoveY > 0 and state.mouseMoveYAccum < 0) or (mouseMoveY < 0 and state.mouseMoveYAccum > 0) then
            state.mouseMoveYAccum = 0
        end

        if not state.movingTumbler then
            state.mouseMoveXAccum = state.mouseMoveXAccum + mouseMoveX
            state.mouseMoveYAccum = state.mouseMoveYAccum + mouseMoveY
        else
            state.mouseMoveXAccum = 0
            state.mouseMoveYAccum = 0
        end

        local nearestTumbler = util.clamp(math.floor(((state.lockpickOffsetX + 94) + state.tumblerSpacing / 2) / state.tumblerSpacing), 0, 4)
        local distanceToTumbler = (state.lockpickOffsetX + 94) - (nearestTumbler * state.tumblerSpacing)
        if state.movingTumbler == nil and state.lockpickOffsetY < 8 and nearestTumbler < state.activeTumblers and not state.setTumblers[nearestTumbler + 1] and math.abs(distanceToTumbler) <= state.lockpickAlignmentTolerance then
            state.movingTumblerIndex = nearestTumbler + 1
            state.movingTumbler = state.uiTumblerElements[state.movingTumblerIndex]
            state.movingTumblerTime = 0
            state.movingTumblerCurrentValues = {}
            local hangTimeMod = state.hangTimeMult * configGlobal.tweaks.n_BaseHangTimeMult
            if configGlobal.options.b_TumblerSpeedFollowsPattern then
                if state.tumblerPatternIndices[state.movingTumblerIndex] > #state.tumblerPatterns[state.movingTumblerIndex] then
                    state.tumblerPatternIndices[state.movingTumblerIndex] = 1
                end
                state.movingTumblerSpeedMult = state.tumblerPatterns[state.movingTumblerIndex][state.tumblerPatternIndices[state.movingTumblerIndex]]
                state.tumblerPatternIndices[state.movingTumblerIndex] = state.tumblerPatternIndices[state.movingTumblerIndex] + 1
                if state.movingTumblerSpeedMult < 0.8 then
                    hangTimeMod = math.random(1, 5) / 10
                end
            else
                if math.random(1, 5) > 2 then
                    hangTimeMod = math.random(1, 5) / 10
                    state.movingTumblerSpeedMult = math.random(20, 50) / 100
                else
                    state.movingTumblerSpeedMult = math.random(90, 100) / 100
                end
            end
            state.movingTumblerSpeedMult = state.movingTumblerSpeedMult * configGlobal.tweaks.n_BaseTimeMult
            state.movingTumblerCurrentValues.riseTime = state.movingTumblerBaseValues.riseTime * state.movingTumblerSpeedMult
            state.movingTumblerCurrentValues.hangTime = state.movingTumblerBaseValues.hangTime * state.movingTumblerSpeedMult * hangTimeMod
            state.movingTumblerCurrentValues.fallTime = state.movingTumblerBaseValues.fallTime * state.movingTumblerSpeedMult
            state.movingTumblerLockpickStartY = state.lockpickOffsetY
            state.movingTumblerStage = 0

            if state.advancedMode and math.random() < state.tensionTooTight then
                state.tensionMovingTumblerLockup = true
                state.movingTumblerCurrentValues.riseTime = 0.1
                state.movingTumblerCurrentValues.hangTime = 0
                state.movingTumblerCurrentValues.fallTime = 0.1
                core.sendGlobalEvent('OSL_DrainLockpick', { player = self })
            else
                state.tensionMovingTumblerLockup = false
            end
        end

        if not state.movingTumbler and not state.advancedMode then
            if configPlayer.options.b_FreePickMovement then
                if (mouseMoveX ~= 0 or mouseMoveY ~= 0) then
                    mouseMoveX = mouseMoveX * (0.05 + 0.45 * math.abs(distanceToTumbler) / state.tumblerSpacing) * 3
                    mouseMoveY = mouseMoveY / 3
                    local clampToHoles = false
                    if math.abs(distanceToTumbler) > state.lockpickAlignmentTolerance then
                        if state.lockpickOffsetY < 10 then
                            clampToHoles = true
                            mouseMoveY = math.max(mouseMoveY, 0)
                            if distanceToTumbler > 0 then
                                mouseMoveX = math.min(mouseMoveX, 0)
                            else
                                mouseMoveX = math.max(mouseMoveX, 0)
                            end
                        end
                    end

                    state.lockpickOffsetX = util.clamp(state.lockpickOffsetX + mouseMoveX, state.lockpickRangeX[1], state.lockpickRangeX[2])
                    state.lockpickOffsetY = util.clamp(state.lockpickOffsetY + mouseMoveY, state.lockpickRangeY[1], state.lockpickRangeY[2])
                end
            else
                if state.mouseMoveXAccum < -24 then
                    onPrevPin()
                    state.mouseMoveXAccum = 0
                    return
                elseif state.mouseMoveXAccum > 24 then
                    onNextPin()
                    state.mouseMoveXAccum = 0
                    return
                elseif state.mouseMoveYAccum < -8 then
                    onPick()
                    state.mouseMoveYAccum = 0
                    return
                elseif state.mouseMoveYAccum > 8 then
                    state.mouseMoveYAccum = 0
                end
            end
        end

        state.uiPickElement.layout.props.position = util.vector2(state.lockpickOffsetX, state.lockpickOffsetY) + state.lockpickVisualOffset
    else
        -- Move the pick towards the tumbler position
        local dt = core.getRealFrameDuration()
        state.movingPickTimer = state.movingPickTimer + dt
        local t = state.movingPickTimer / state.movingPickDuration
        if t >= 1 then
            t = 1
            state.movingPickTimer = nil
        end
        state.lockpickOffsetX = lerp(t, state.movingPickStart.x, state.movingPickTarget.x)
        state.lockpickOffsetY = lerp(t, state.movingPickStart.y, state.movingPickTarget.y)
        state.uiPickElement.layout.props.position = util.vector2(state.lockpickOffsetX, state.lockpickOffsetY) + state.lockpickVisualOffset
    end
end

state.pickMoveStartY = nil

local function updateMovingTumbler()
    if state.movingTumbler then
        if state.attempting then
            scaleTumbler(state.movingTumblerIndex, 0.05 + math.cos(state.attemptTime * 2 * math.pi / state.attemptRollInterval) * 0.05)
            return
        end

        local dt = core.getRealFrameDuration()
        state.movingTumblerTime = state.movingTumblerTime + dt
        local riseTime = state.movingTumblerCurrentValues.riseTime
        local hangTime = state.movingTumblerCurrentValues.hangTime
        local fallTime = state.movingTumblerCurrentValues.fallTime

        local pickDropTime = util.clamp(state.movingPickDuration * 3, 0, fallTime)
        local timeToFall = riseTime + hangTime + fallTime - pickDropTime
        if state.movingTumblerTime < riseTime then
            state.lockpickOffsetY = lerp(state.movingTumblerTime / riseTime, state.movingTumblerLockpickStartY, 12)
            state.uiPickElement.layout.props.position = util.vector2(state.lockpickOffsetX, state.lockpickOffsetY) + state.lockpickVisualOffset
            state.pickMoveStartY = nil
        elseif state.movingTumblerTime > timeToFall then
            if not state.pickMoveStartY then
                state.pickMoveStartY = state.lockpickOffsetY
            end
            state.lockpickOffsetY = math.max(lerp((state.movingTumblerTime - timeToFall) / pickDropTime, state.pickMoveStartY, 24), state.lockpickOffsetY)
            state.uiPickElement.layout.props.position = util.vector2(state.lockpickOffsetX, state.lockpickOffsetY) + state.lockpickVisualOffset
        end

        if state.movingTumblerTime < riseTime then
            if state.movingTumblerStage == 0 then
                state.movingTumblerStage = 1
                ambient.playSoundFile("sound/OblivionLockpicking/tumbler_move.wav")
            end
            local t = state.movingTumblerTime / riseTime
            local scale = lerpQuadOut(t, 1, state.tensionMovingTumblerLockup and 0.9 or 0)
            scaleTumbler(state.movingTumblerIndex, scale)
        elseif state.movingTumblerTime < riseTime + hangTime then
            if state.movingTumblerStage == 1 then
                state.movingTumblerStage = 2
                ambient.playSoundFile("sound/OblivionLockpicking/tumbler_click.wav")
            end
            if not ambient.isSoundFilePlaying("sound/OblivionLockpicking/tumbler_fall.wav") then
                ambient.playSoundFile("sound/OblivionLockpicking/tumbler_fall.wav")
            end
            scaleTumbler(state.movingTumblerIndex, state.tensionMovingTumblerLockup and 0.9 or 0)
            
            if configPlayer.options.b_TimingWindowGlow then
                if not state.movingTumbler.layout.content:indexOf('glow') then
                    state.movingTumbler.layout.content:add({
                        type = ui.TYPE.Image,
                        name = 'glow',
                        props = {
                            resource = ui.texture {
                                path = 'textures/OblivionLockpicking/pin-glow.dds'
                            },
                            size = util.vector2(32, 128),
                            color = configPlayer.options.c_TimingWindowGlowColor,
                        }
                    })
                end
                state.movingTumbler.layout.content.glow.props.alpha = lerpQuintic(util.clamp((state.movingTumblerTime - riseTime) / hangTime, 0, 1), 1, 0)
            end
        elseif state.movingTumblerTime < riseTime + hangTime + fallTime then
            if state.movingTumblerStage < 3 then
                if state.movingTumblerStage == 1 and not state.tensionMovingTumblerLockup then
                    ambient.playSoundFile("sound/OblivionLockpicking/tumbler_click.wav")
                end
                state.movingTumblerStage = 3
            end
            if not ambient.isSoundFilePlaying("sound/OblivionLockpicking/tumbler_fall.wav") then
                ambient.playSoundFile("sound/OblivionLockpicking/tumbler_fall.wav")
            end
            local t = (state.movingTumblerTime - riseTime - hangTime) / fallTime
            local scale = lerpQuad(t, state.tensionMovingTumblerLockup and 0.9 or 0, 1)
            scaleTumbler(state.movingTumblerIndex, scale)

            if state.movingTumbler.layout.content:indexOf('glow') then
                state.movingTumbler.layout.content.glow = nil
            end
        else
            -- Tumbler has fallen back down, reset the values and set the tumbler to its original position
            scaleTumbler(state.movingTumblerIndex, 1)

            if state.movingTumbler.layout.content:indexOf('glow') then
                state.movingTumbler.layout.content.glow = nil
            end

            state.movingTumbler = nil
            state.movingTumblerIndex = nil
            state.movingTumblerTime = nil
            state.movingTumblerCurrentValues = nil
            ambient.stopSoundFile("sound/OblivionLockpicking/tumbler_fall.wav")
        end
    end
end

local function getNewPick()
    -- First, search the inventory
    local candidates = {}
    local count = 0
    for i, v in ipairs(types.Actor.inventory(self):getAll(getType())) do
        candidates[i] = v
        count = count + 1
    end
    if count == 0 then return false end

    local condPref = configPlayer.options.s_AutoEquipPrefCond
    local tierPref = configPlayer.options.s_AutoEquipPrefTier

    local currTier = round(state.activeLockpick.quality, 3)

    -- First, try to find the same tier, and if not, go by tier preference (higher or lower)
    local newPick = nil
    local prefersHigher = (tierPref == "AutoEquipPrefTierHigher")
    
    -- Track best candidates in each category
    local bestSameTier = nil
    local bestPreferred = nil
    local bestFallback = nil
    
    local function isBetterCond(a, b)
        return (condPref == "AutoEquipPrefCondHigher" and a > b)
            or (condPref == "AutoEquipPrefCondLower" and a < b)
    end
    
    for _, pick in ipairs(candidates) do
        local tier = round(getType().records[pick.recordId].quality, 3)
        local cond = types.Item.itemData(pick).condition
        local diff = tier - currTier
        local absDiff = math.abs(diff)

        if tier == currTier then
            if not bestSameTier or isBetterCond(cond, types.Item.itemData(bestSameTier).condition) then
                bestSameTier = pick
            end
        elseif (prefersHigher and diff > 0) or (not prefersHigher and diff < 0) then
            if not bestPreferred or absDiff < math.abs(round(getType().records[bestPreferred.recordId].quality, 3) - currTier)
                or (absDiff == math.abs(round(getType().records[bestPreferred.recordId].quality, 3) - currTier)
                    and isBetterCond(cond, types.Item.itemData(bestPreferred).condition)) then
                bestPreferred = pick
            end
        else
            if not bestFallback or absDiff < math.abs(round(getType().records[bestFallback.recordId].quality, 3) - currTier)
                or (absDiff == math.abs(round(getType().records[bestFallback.recordId].quality, 3) - currTier)
                    and isBetterCond(cond, types.Item.itemData(bestFallback).condition)) then
                bestFallback = pick
            end
        end
    end

    newPick = bestSameTier or bestPreferred or bestFallback

    state.activeLockpick = getType().records[newPick.recordId]
    local equipment = types.Actor.getEquipment(self)
    equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight] = newPick
    types.Actor.setEquipment(self, equipment)
    updateUiPick()
    return true
end

local function autoAttempt()
    if I.UI.getMode() ~= nil then return end
    if state.impactPause > 0 then return end
    local skillRoll = math.random() < (state.overallSuccessChance / 100 * configGlobal.tweaks.n_AutoAttemptSuccessModifier)
    if skillRoll then
        stopLockpicking(true)
    else
        core.sendGlobalEvent('OSL_DrainLockpick', { player = self })
        dropTumblers(-1, true)
        if configPlayer.options.b_ShowFailureReason then
            local percentageString = configPlayer.options.b_ShowFailureReasonPercentage and string.format(" (%.2f%%)", state.overallSuccessChance * configGlobal.tweaks.n_AutoAttemptSuccessModifier) or ''
            ui.showMessage(l10n('Msg_FailSkillRoll') .. percentageString)
        end
    end
end

local function handleKeyPress(key)
    state.controllerPrompts = false
    if not state.isLockpicking then return end
    if key.code == configPlayer.keybinds.keybindPreviousPin then
        onPrevPin()
    elseif key.code == configPlayer.keybinds.keybindNextPin then
        onNextPin()
    elseif key.code == configPlayer.keybinds.keybindPickPin then
        if state.attempting then
            stopLockpicking()
        elseif not state.movingPickTimer then
            onPick()
        end
    elseif key.code == configPlayer.keybinds.keybindAutoAttempt then
        autoAttempt()
    elseif key.code == configPlayer.keybinds.keybindCancel then
        stopLockpicking()
    end
end

local function handleControllerPress(button)
    state.controllerPrompts = true
    if not state.isLockpicking then return end
    if state.advancedMode then
        if button == input.CONTROLLER_BUTTON.LeftShoulder then
            onPrevPin()
        elseif button == input.CONTROLLER_BUTTON.RightShoulder then
            onNextPin()
        end
    else
        if button == input.CONTROLLER_BUTTON.DPadLeft then
            onPrevPin()
        elseif button == input.CONTROLLER_BUTTON.DPadRight then
            onNextPin()
        end
    end
    if button == input.CONTROLLER_BUTTON.A then
        if state.attempting then
            stopLockpicking()
        elseif not state.movingPickTimer then
            onPick()
        end
    elseif button == input.CONTROLLER_BUTTON.X then
        autoAttempt()
    elseif button == input.CONTROLLER_BUTTON.Y then
        stopLockpicking()
    end
end

local function frame()
    local frameDuration = core.getRealFrameDuration()

    if configGlobal.options.b_EnableMod and (state.isLockpicking or (toolEquipped() and types.Actor.getStance(self) == types.Actor.STANCE.Weapon)) then
        self.controls.use = self.ATTACK_TYPE.NoAttack
    end

    state.lastStance = types.Actor.getStance(self)

    if state.trySheathe and types.Actor.getStance(self) ~= types.Actor.STANCE.Nothing then
        types.Actor.setStance(self, types.Actor.STANCE.Nothing)
        if types.Actor.getStance(self) == types.Actor.STANCE.Nothing then
            state.trySheathe = false
        end
    end

    if not state.isLockpicking then return end

    types.Actor.setStance(self, types.Actor.STANCE.Weapon)
    self.controls.jump = false
    self.controls.movement = 0
    self.controls.pitchChange = 0
    self.controls.sideMovement = 0
    self.controls.yawChange = 0

    if I.UI.getMode() ~= nil or (core.isWorldPaused() and not configGlobal.options.b_PauseTime) then 
        state.uiWrapper.layout.layer = 'HUD'
        auxUi.deepUpdate(state.uiWrapper)
        return
    else
        state.uiWrapper.layout.layer = 'Notification'
    end

    local distance = (camera.getPosition() - state.activeTargetRayHitPos):length()
    if distance > getRange() then
        ui.showMessage(l10n('Msg_LockOutOfRange'))
        stopLockpicking()
        return 
    end

    if state.crimeTimer < state.crimeInterval then
        if not core.isWorldPaused() then
            state.crimeTimer = state.crimeTimer + frameDuration
        end
    else
        if state.crimeSeen then 
            if configPlayer.options.b_StopIfCaught then
                stopLockpicking()
                return
            end
        end
        local ownerFaction = state.activeTarget.owner.factionId
        local ownerNPC = state.activeTarget.owner.recordId

        if ownerFaction or ownerNPC then
            core.sendGlobalEvent("OSL_PlayerLockpicking", { player = self, faction = ownerFaction })
        end
        state.crimeTimer = 0
    end

    if configPlayer.options.b_PlayLockpickAnimation and (not anim.isPlaying(self, 'pickprobe') or anim.getCompletion(self, 'pickprobe') >= state.animEnd + state.animEndRand) then
        anim.cancel(self, 'pickprobe')
        state.animStartRand = math.random() * 0.1 - 0.05
        state.animEndRand = math.random() * 0.1 - 0.05
        local speedRand = state.animSpeed * (0.85 + math.random() * 0.4 - 0.3)
        playAnim({ speed = speedRand, startPoint = state.animStart + state.animStartRand })
    end

    if state.ambientScrapeTimer > 0 then
        state.ambientScrapeTimer = state.ambientScrapeTimer - frameDuration
    elseif configPlayer.options.b_PlayRandomSounds then
        local rand = math.random(1, #state.ambientScrapeSounds - 1)
        rand = (rand >= state.ambientScrapeLast) and (rand + 1) or rand
        ambient.playSoundFile(state.ambientScrapeSounds[rand], { volume = 0.25 })
        state.ambientScrapeTimer = state.ambientScrapeIntervalMin + math.random() * (state.ambientScrapeIntervalMax - state.ambientScrapeIntervalMin)
        state.ambientScrapeLast = rand
    end

    local lockpick = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if not lockpick or not getType().objectIsInstance(lockpick) then
        ambient.playSoundFile("sound/OblivionLockpicking/lock_pickbreak.wav")
        ui.showMessage(state.probeMode and l10n('Msg_ProbeBreak') or l10n('Msg_LockpickBreak'))
        if not configPlayer.options.b_AutoEquip or not getNewPick() then
            ui.showMessage(state.probeMode and l10n('Msg_ProbeNoneLeft') or l10n('Msg_LockpickNoneLeft'))
            stopLockpicking()
        else
            state.impactPause = state.impactPauseLength
            anim.cancel(self, 'pickprobe')
            playAnim({ speed = 0.5, startKey = 'equip start', stopKey = 'start' })
        end
    end

    if state.impactPause > 0 then
        state.impactPause = state.impactPause - frameDuration
        local progress = (state.impactPauseLength - state.impactPause) / state.impactPauseLength
        local pickX = lerpQuadOut(progress, state.lockpickBasePos.x - 800, state.lockpickOffsetX)
        local pickY = lerpQuadOut(progress, state.lockpickBasePos.y, state.lockpickOffsetY)
        state.lockpickVisualOffset = util.vector2(0, 0)
        state.uiPickElement.layout.props.position = util.vector2(pickX, pickY)
        local tensionMeterOverlay = state.uiTensionElement.layout.content[1].content[1].content['TensionMeterOverlay']
        tensionMeterOverlay.props.color = util.color.rgb(util.clamp(lerpCubic(progress, 0, 0.25), 0, 0.25), 0, 0)
        tensionMeterOverlay.props.alpha = util.clamp(lerpCubic(progress, 1, 0), 0, 1)
        state.uiPickElement:update()
        state.uiTensionElement:update()
        return
    end

    if state.attempting then
        state.attemptTime = state.attemptTime + frameDuration
        if state.attemptRollTimer > 0 then
            state.attemptRollTimer = state.attemptRollTimer - frameDuration
        else
            onPick()
        end
    end

    if not state.isLockpicking then return end

    state.overallSuccessChance = getOverallSuccessChance()
    state.pinSuccessChance = getPinSuccessChance()

    updateLockpick()
    updateMovingTumbler()
    updateInfoBox()
    updateTension()
    updateAttemptInfoBox()
    auxUi.deepUpdate(state.uiWrapper)
    if (configGlobal.options.b_HardSkillGating and state.overallSuccessChance < 0) then
        ui.showMessage(state.probeMode and l10n('Msg_ProbeTooComplex') or l10n('Msg_LockpickTooComplex'))
        stopLockpicking()
        return
    elseif (configGlobal.options.b_SkipIfGuaranteed and state.overallSuccessChance >= 100) then
        stopLockpicking(true)
        return
    end
end

local function onUse()
    if not state.isLockpicking then 
        startLockpicking()
    else
        if state.attempting then
            stopLockpicking()
        elseif not state.movingPickTimer then
            onPick()
        end
    end
end

input.registerActionHandler("Use", async:callback(function(e)
    if configGlobal.options.b_EnableMod then
        if e then onUse() end
    end
end))

I.SkillProgression.addSkillLevelUpHandler(function(skillid)
    if skillid == 'security' and configGlobal.options.b_SecurityAffectsTumblerDrops then
        local level = types.NPC.stats.skills.security(self).base + 1
        local interval = configGlobal.tweaks.n_SecurityAffectsTumblerDropsLevelInterval
        if level % interval == 0 then
            if (level / interval <= 4) then
                ui.showMessage(l10n('Msg_SecurityLevelThreshold' .. (level / interval)))
            end
        end
    end
    return true
end)

return {
    engineHandlers = {
        onFrame = frame,
        onKeyPress = handleKeyPress,
        onControllerButtonPress = handleControllerPress,
        onLoad = function()
            shader:disable()
        end,
    },
    eventHandlers = {
        OSL_PlayerLockpickingSeen = function()
            state.crimeSeen = true
        end,
        UiModeChanged = function(data)
            if state.isLockpicking and data.newMode == nil then
                state.advancedMode = configGlobal.options.b_AdvancedMode
            end
        end,
    }
}
