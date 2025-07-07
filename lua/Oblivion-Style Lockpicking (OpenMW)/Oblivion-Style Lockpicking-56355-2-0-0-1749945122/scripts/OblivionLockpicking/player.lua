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

local isLockpicking = false
local activeLockpick = nil
local activeTarget = nil
local probeMode = false

local textureOverride = nil
local elementData = {}

Textures.init()

local function setElementData()
    if not textureOverride then
        return
    end
    elementData = {}
    for k, v in pairs(Textures.ELEMENT) do
        local data = Textures.getElement(textureOverride, v)
        if data then
            elementData[v] = {}
            elementData[v].texture = ui.texture {
                path = data.texturePath,
                offset = data.offset,
                size = data.size,
            }
            elementData[v].pos = data.pos
            elementData[v].size = data.size
        end
    end
end

local function getTexture(element)
    if not elementData[element] then
        return nil
    end
    return elementData[element].texture
end

local function getPosOffset(element)
    if not elementData[element] then
        return util.vector2(0, 0)
    end
    return elementData[element].pos
end

local function getSize(element)
    if not elementData[element] then
        return util.vector2(0, 0)
    end
    return elementData[element].size
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

local uiWrapper = nil
local uiBaseElement, uiPickElement, uiTumblerCoverElement, uiInfoBoxElement, uiTensionElement = nil, nil, nil, nil, nil
local uiTumblerElements = { nil, nil, nil, nil, nil }

local infoBoxUpdateTimer = 0

local tumblerSpacing = 51
local tumblerCount = 5
local tumblerBaseHeight = -155
local tumblerBaseSpringHeight = 85
local tumblerSetSpringHeight = 10
local activeTumblers = nil
local setTumblers = nil
local tumblerPatterns = {}
local tumblerPatternIndices = {}

local movingTumbler = nil
local movingTumblerIndex = nil
local movingTumblerTime = nil
local movingTumblerLockpickStartY = nil

local movingTumblerBaseValues = {
    riseTime = 0.15,
    hangTime = 1/3,
    fallTime = 1.25,
}
local movingTumblerSpeedMult = nil
local movingTumblerCurrentValues = nil
local movingTumblerStage = nil

local movingPickStart = nil
local movingPickTarget = nil
local movingPickDuration = 1 / 16
local movingPickTimer = nil

local lockpickOffsetX = -96
local lockpickOffsetY = 24
local lockpickBasePos = util.vector2(lockpickOffsetX, lockpickOffsetY)
local lockpickAlignmentTolerance = 20
local lockpickRangeX = {-128, 136}
local lockpickRangeY = {0, 32}

local crimeTimer = 0
local crimeInterval = 0.5
local crimeSeen = false

local overallSuccessChance = nil
local pinSuccessChance = nil
local hangTimeMult = 1.0

local controllerPrompts = false

local overrideCombatControls = false
local storedRot = nil

local lastStance = types.Actor.STANCE.Nothing

local animStart = 0.35
local animEnd = 0.58
local animSpeed = 0.5
local animStartRand = 0
local animEndRand = 0

local ambientScrapeIntervalMin = 1
local ambientScrapeIntervalMax = 5
local ambientScrapeTimer = 0
local ambientScrapeLast = -1
local ambientScrapeSounds = {}
for fileName in vfs.pathsWithPrefix("sound/OblivionLockpicking/scrape/") do
    table.insert(ambientScrapeSounds, fileName)
end

local advancedMode = false
local tension = 0
local tensionTarget = 500
local tensionSweetSpot = 0
local tensionRange = 0
local tensionMin = 0
local tensionMax = 0
local tensionMaxMinLevel = 1500
local tensionMaxMaxLevel = 3000
local tensionLimits = { 0, 0 }
local tensionTargetMoveSpeed = 0
local tensionSweetSpotMinLevel = 300
local tensionSweetSpotMaxLevel = 150
local tensionRangeMinLevel = 1200
local tensionRangeMaxLevel = 750
local tensionLimitsMinLevel = { 0, 750 }
local tensionLimitsMaxLevel = { 200, 2000 }
local tensionTargetMoveSpeedRangeMinLevel = { 0, 125 }
local tensionTargetMoveSpeedRangeMaxLevel = { 0, 200 }
local tensionTargetVelocity = 0  -- current velocity of the target (for drift)
local tensionTargetAccelerationTimer = 0
local tensionTargetJitterLevelStart = 50
local tensionTargetJitterRate = 0
local tensionTargetJitterRateMinLevel = 0
local tensionTargetJitterRateMaxLevel = 0.02

local tensionTooLoose = 0
local tensionTooTight = 0
local tensionPickDamageAmount = 0
local tensionFailureInterval = { 0.25, 0.5 }
local tensionFailureTimer = 0
local tensionPinSlipVelocity = 0
local tensionPinsSlipping = {}

local tensionMovingTumblerLockup = false

local impactPause = 0
local impactPauseLength = 1

local previousSmoothedVelocity = 0
local previousRightX = 0
local previousRightY = 0
local smoothingFactor = 0.99  -- 0 = no smoothing, 1 = very smoothed

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
    local springHeight = tumblerSetSpringHeight + (tumblerBaseSpringHeight - tumblerSetSpringHeight) * scale
    uiTumblerElements[index].layout.content[1].content[1].props.size = util.vector2(35, springHeight)
end

local function getTumblerScale(index)
    return (uiTumblerElements[index].layout.content[1].content[1].props.size.y - tumblerSetSpringHeight) / (tumblerBaseSpringHeight - tumblerSetSpringHeight)
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
    local deltaX = currentRightX - previousRightX
    local deltaY = currentRightY - previousRightY
    local controllerVelocity = math.sqrt(deltaX * deltaX + deltaY * deltaY) / dt
    controllerVelocity = controllerVelocity * 200  -- tweak this scale as needed

    -- Update previous controller positions
    previousRightX = currentRightX
    previousRightY = currentRightY

    -- Use the higher of the two
    local rawVelocity = math.max(mouseVelocity, controllerVelocity)

    -- Apply smoothing
    local smoothedVelocity = smoothingFactor * previousSmoothedVelocity + (1 - smoothingFactor) * rawVelocity
    previousSmoothedVelocity = smoothedVelocity

    return smoothedVelocity
end

-- Initialize tension system with lock level
local function initTensionSystem(lockLevel)
    local level01 = util.clamp(lockLevel / 100, 0, 1)

    tension = tensionMin
    previousSmoothedVelocity, previousRightX, previousRightY = tensionMin, 0, 0
    tensionSweetSpot = lerp(level01, tensionSweetSpotMinLevel, tensionSweetSpotMaxLevel)
    tensionRange = lerp(level01, tensionRangeMinLevel, tensionRangeMaxLevel)

    tensionLimits[1] = lerp(level01, tensionLimitsMinLevel[1], tensionLimitsMaxLevel[1])
    tensionLimits[2] = lerp(level01, tensionLimitsMinLevel[2], tensionLimitsMaxLevel[2])

    tensionMax = lerp(level01, tensionMaxMinLevel, tensionMaxMaxLevel)

    tensionTargetMoveSpeed = lerp(level01, tensionTargetMoveSpeedRangeMinLevel[2], tensionTargetMoveSpeedRangeMaxLevel[2])

    -- Start target in middle of range
    tensionTarget = (tensionLimits[1] + tensionLimits[2]) / 2
    tensionTargetVelocity = 0
    tensionTargetAccelerationTimer = 0
    tensionTargetJitterRate = lerp((lockLevel - tensionTargetJitterLevelStart) / (100 - tensionTargetJitterLevelStart), tensionTargetJitterRateMinLevel, tensionTargetJitterRateMaxLevel)
end

local function updateTensionTarget(dt)
    tensionTargetAccelerationTimer = tensionTargetAccelerationTimer - dt
    if tensionTargetAccelerationTimer <= 0 then
        tensionTargetAccelerationTimer = 0.3 + math.random() * 0.5  -- randomize interval
        -- Randomly nudge velocity (change direction/speed a bit)
        tensionTargetVelocity = tensionTargetVelocity + (math.random() * 2 - 1) * tensionTargetMoveSpeed
        tensionTargetVelocity = util.clamp(tensionTargetVelocity, -tensionTargetMoveSpeed, tensionTargetMoveSpeed)
    end
    
    if math.random() < tensionTargetJitterRate then
        tensionTargetVelocity = tensionTargetVelocity * 2
    end

    tensionTarget = tensionTarget + tensionTargetVelocity * dt

    -- Keep it in bounds and bounce off edges
    if tensionTarget < tensionLimits[1] then
        tensionTarget = tensionLimits[1]
        tensionTargetVelocity = math.abs(tensionTargetVelocity)
    elseif tensionTarget > tensionLimits[2] then
        tensionTarget = tensionLimits[2]
        tensionTargetVelocity = -math.abs(tensionTargetVelocity)
    end
end

local function updateTensionEffects()
    local sweetSpotBounds = { tensionTarget - tensionSweetSpot / 2, tensionTarget + tensionSweetSpot / 2 }
    local rangeBounds = { tensionTarget - tensionRange / 2, tensionTarget + tensionRange / 2 }

    if tension < sweetSpotBounds[1] then
        if tension >= rangeBounds[1] then
            local range = sweetSpotBounds[1] - rangeBounds[1]
            tensionTooLoose = (sweetSpotBounds[1] - tension) / range
        else
            tensionTooLoose = 1
        end
    else
        tensionTooLoose = 0
    end
    tensionPinSlipVelocity = tensionTooLoose * 0.05
    
    if tension > sweetSpotBounds[2] then
        if tension <= rangeBounds[2] then
            local range = rangeBounds[2] - sweetSpotBounds[2]
            tensionTooTight = (tension - sweetSpotBounds[2]) / range
        else
            tensionTooTight = 1
        end
    else
        tensionTooTight = 0
    end
    tensionPickDamageAmount = tensionTooTight * 1
end

local tensionShakeTime = 0
local function updateTensionShake(dt)
    -- No shake in sweet zone
    local sweetSpotMax = tensionTarget + tensionSweetSpot / 2
    local rangeMax = tensionTarget + tensionRange / 2

    if tension <= sweetSpotMax then return 0, 0 end

    -- How deep into the danger zone are we? (0 to 1)
    local dangerLevel = math.min((tension - sweetSpotMax) / (rangeMax - sweetSpotMax), 1.0)

    -- Shake intensity grows with danger level
    local maxShake = 6
    local shakeIntensity = maxShake * dangerLevel^1.5  -- exponential for punch

    -- Shake frequency also ramps up
    local baseFreq = 6
    local maxFreq = 40
    local freq = baseFreq + (maxFreq - baseFreq) * dangerLevel

    -- Update shake time
    tensionShakeTime = tensionShakeTime + dt * freq

    -- Generate smooth chaotic offset (sin + noise-style randomization)
    local x = math.sin(tensionShakeTime * 2.1 + math.random()) * shakeIntensity
    local y = math.cos(tensionShakeTime * 1.8 + math.random()) * shakeIntensity * 0.6  -- vertical slightly lower for flavor

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
    local quality = activeLockpick.quality
    local qualityMult = configGlobal.tweaks.n_PickQualityMult
    return quality * qualityMult + (1 - qualityMult)
end

local function infoLine(infoName, titleText)
    return {
        type = ui.TYPE.Flex,
        name = infoName .. 'Line',
        props = {
            horizontal = true,
            grow = 1,
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
    infoBoxUpdateTimer = 0
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
        infoLine('InfoBoxPickName', probeMode and l10n('InfoBoxProbeName') or l10n('InfoBoxPickName')),
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
    if advancedMode then
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
    if not uiTensionElement then return end
    if not advancedMode then
        uiTensionElement.layout.props.alpha = 0
    else
        local dt = core.getRealFrameDuration()
        updateTensionTarget(dt)
        updateTensionEffects()

        if tensionTooTight > 0 and not ambient.isSoundFilePlaying("sound/OblivionLockpicking/tension1.wav") then
            ambient.playSoundFile("sound/OblivionLockpicking/tension1.wav", { volume = 0.3, scale = false, loop = true })
        elseif tensionTooTight <= 0 and ambient.isSoundFilePlaying("sound/OblivionLockpicking/tension1.wav") then
            ambient.stopSoundFile("sound/OblivionLockpicking/tension1.wav")
        end

        if tensionFailureTimer <= 0 then
            tensionFailureTimer = math.random() * (tensionFailureInterval[2] - tensionFailureInterval[1]) + tensionFailureInterval[1]
            -- Too loose: Start slipping pins
            for i = 1, activeTumblers do
                if math.random() < tensionTooLoose and setTumblers[i] == true then
                    tensionPinsSlipping[i] = true
                    break
                end
            end
            -- Too tight: Start damaging pick
            if tensionTooTight >= 1 then
                core.sendGlobalEvent('DrainLockpick', { player = self, full = true })
                tension = tensionTarget
                impactPause = impactPauseLength
                previousSmoothedVelocity, previousRightX, previousRightY = tensionTarget, 0, 0
                uiPickElement.layout.props.position = lockpickBasePos
                if ambient.isSoundFilePlaying("sound/OblivionLockpicking/tension1.wav") then
                    ambient.stopSoundFile("sound/OblivionLockpicking/tension1.wav")
                end
            elseif math.random() < tensionTooTight then
                ambient.playSoundFile("sound/OblivionLockpicking/tension" .. math.random(2, 3) .. ".wav", { volume = tensionTooTight * tensionTooTight, pitch = 0.9 + math.random() * 0.2, scale = false })
                core.sendGlobalEvent('DrainLockpick', { player = self, amount = stochasticRound(tensionPickDamageAmount) })
            end
        else
            tensionFailureTimer = tensionFailureTimer - dt
        end

        local slippingCount = 0
        for i = 1, activeTumblers do
            if tensionPinsSlipping[i] then
                if tensionPinSlipVelocity > 0 then
                    if not ambient.isSoundFilePlaying("sound/OblivionLockpicking/tumbler_fall.wav") then
                        ambient.playSoundFile("sound/OblivionLockpicking/tumbler_fall.wav")
                    end
                    modTumbler(i, tensionPinSlipVelocity * (getTumblerScale(i) + 0.05))
                    if getTumblerScale(i) >= 1 then
                        setTumblers[i] = false
                        tensionPinsSlipping[i] = false
                        ambient.playSoundFile("sound/OblivionLockpicking/tumbler_crash.wav")
                    else
                        slippingCount = slippingCount + 1
                    end
                end
            end
        end
        if slippingCount == 0 and not movingTumblerIndex then
            ambient.stopSoundFile("sound/OblivionLockpicking/tumbler_fall.wav")
        end

        uiTensionElement.layout.props.alpha = 1
        tension = math.max(tensionMin, math.min(tensionMax, getInputVelocity(dt)))
        local tensionMeter = uiTensionElement.layout.content[1].content[1]
        local tensionMarker = tensionMeter.content['TensionMeterMarker']
        local tensionMeterRange = tensionMeter.content['TensionMeterRange']
        local tensionMeterGreen = tensionMeter.content['TensionMeterGreen']
        local tensionMeterOverlay = tensionMeter.content['TensionMeterOverlay']

        local tensionPercent = (tension - tensionMin) / (tensionMax - tensionMin)
        local tensionTargetPercent = (tensionTarget - tensionMin) / (tensionMax - tensionMin)
        local tensionMarkerPos = util.vector2(tensionPercent, 0)

        tensionMarker.props.relativePosition = tensionMarkerPos
        tensionMeterRange.props.relativePosition = util.vector2(tensionTargetPercent, 0)
        tensionMeterGreen.props.relativePosition = util.vector2(tensionTargetPercent, 0)
        tensionMeterRange.props.size = util.vector2((tensionRange / (tensionMax - tensionMin)) * 256, 16)
        tensionMeterGreen.props.size = util.vector2((tensionSweetSpot / (tensionMax - tensionMin)) * 256 * 2, 16)

        if tensionTooLoose > 0 then
            tensionMeterOverlay.props.color = util.color.rgb(0, 0, 0.25)
            tensionMeterOverlay.props.alpha = util.clamp(lerp(tensionTooLoose, 0, 0.25), 0, 0.25)
        elseif tensionTooTight > 0 then
            tensionMeterOverlay.props.color = util.color.rgb(0.25, 0, 0)
            tensionMeterOverlay.props.alpha = util.clamp(lerp(tensionTooTight, 0, 1), 0, 1)
        else
            tensionMeterOverlay.props.alpha = 0
        end

        local shakeX, shakeY = updateTensionShake(dt)
        uiTensionElement.layout.props.position = util.vector2(shakeX, 150 + shakeY)
        uiPickElement.layout.props.position = util.vector2(-shakeX * 0.5 + lockpickOffsetX, shakeY * 0.5 + lockpickOffsetY)
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
    if not uiInfoBoxElement then return end
    if not configPlayer.options.b_ShowInfoWindow then
        uiInfoBoxElement.layout.props.visible = false
        return
    end

    infoBoxUpdateTimer = infoBoxUpdateTimer - 1
    if infoBoxUpdateTimer > 0 then return
    else
        infoBoxUpdateTimer = configPlayer.options.n_InfoWindowUpdateInterval
    end

    local content = uiInfoBoxElement.layout.content[1].content[1]

    local difficulty
    if overallSuccessChance < 5 then
        difficulty = 6
    elseif overallSuccessChance < 10 then
        difficulty = 5
    elseif overallSuccessChance < 20 then
        difficulty = 4
    elseif overallSuccessChance < 40 then
        difficulty = 3
    elseif overallSuccessChance < 60 then
        difficulty = 2
    else
        difficulty = 1
    end

    local optProb = configPlayer.options.s_ShowInfoWindowProbability
    local optPick = configPlayer.options.b_ShowInfoWindowPick
    local optKeybinds = configPlayer.options.b_ShowInfoWindowKeybinds

    if optProb == 'ShowInfoWindowProbabilityBoth' then
        setInfoLineText(content, 'InfoBoxPinChance', string.format("%.2f%%", pinSuccessChance))
        setInfoLineText(content, 'InfoBoxAutoAttemptChance', string.format("%.2f%%", overallSuccessChance * configGlobal.tweaks.n_AutoAttemptSuccessModifier))
    end
    if optProb ~= 'ShowInfoWindowProbabilityNone' then
        setInfoLineText(content, 'InfoBoxDifficulty', l10n('InfoBoxDifficulty' .. difficulty))
        content.content['InfoBoxDifficultyLine'].content['InfoBoxDifficulty'].props.textColor = difficultyColors[difficulty]
    end
    if optPick then
        setInfoLineText(content, 'InfoBoxPickName', activeLockpick.name)
        local qualityString = string.format("%.2fx", activeLockpick.quality)
        if configGlobal.tweaks.n_PickQualityMult ~= 1 then qualityString = qualityString .. " (" .. string.format("%.2fx", getAdjustedPickQuality()) .. ")" end
        setInfoLineText(content, 'InfoBoxPickQuality', qualityString)
        local lockpick = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
        local condition = lockpick and types.Item.itemData(lockpick).condition or 0
        setInfoLineText(content, 'InfoBoxPickCondition', tostring(condition) .. "/" .. activeLockpick.maxCondition)
    end
    if optKeybinds then
        if not controllerPrompts then
            local moveText = advancedMode and l10n('InfoBoxKeybindMoveTextAdvanced') or l10n('InfoBoxKeybindMoveText')
            setInfoLineText(content, 'InfoBoxKeybindMove', moveText .. input.getKeyName(configPlayer.keybinds.keybindPreviousPin) .. "/" .. input.getKeyName(configPlayer.keybinds.keybindNextPin))
            setInfoLineText(content, 'InfoBoxKeybindPick', input.getKeyName(configPlayer.keybinds.keybindPickPin) .. l10n('InfoBoxKeybindPickText'))
            setInfoLineText(content, 'InfoBoxKeybindAutoAttempt', input.getKeyName(configPlayer.keybinds.keybindAutoAttempt))
            setInfoLineText(content, 'InfoBoxKeybindStop', input.getKeyName(configPlayer.keybinds.keybindCancel))
            if advancedMode then
                setInfoLineText(content, 'InfoBoxKeybindTension', l10n('InfoBoxKeybindTensionText'))
            end
        else 
            local moveText = advancedMode and l10n('InfoBoxKeybindMoveControllerTextAdvanced') or l10n('InfoBoxKeybindMoveControllerText')
            setInfoLineText(content, 'InfoBoxKeybindMove', moveText)
            setInfoLineText(content, 'InfoBoxKeybindPick', l10n('InfoBoxKeybindPickControllerText'))
            setInfoLineText(content, 'InfoBoxKeybindAutoAttempt', l10n('InfoBoxKeybindAutoAttemptControllerText'))
            setInfoLineText(content, 'InfoBoxKeybindStop', l10n('InfoBoxKeybindStopControllerText'))
            if advancedMode then
                setInfoLineText(content, 'InfoBoxKeybindTension', l10n('InfoBoxKeybindTensionControllerText'))
            end
        end
    end
end

local function getType()
    if probeMode then return types.Probe end
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
    local agility = types.Actor.stats.attributes.agility(self).modified
    local luck = types.Actor.stats.attributes.luck(self).modified
    local fatigueCurrent = types.Actor.stats.dynamic.fatigue(self).current
    local fatigueMax = types.Actor.stats.dynamic.fatigue(self).base
    local lockLevel = getLockLevel(activeTarget)

    local statsMod = security + (agility / 5) + (luck / 10)
    local qualityMult = configGlobal.tweaks.n_PickQualityMult
    local equipmentMod = activeLockpick.quality * qualityMult + (1 - qualityMult)
    local fatigueNorm
    if fatigueMax > 0 then
        fatigueNorm = (fatigueCurrent / fatigueMax)
    else
        fatigueNorm = 1
    end
    local fatigueMod = core.getGMST('fFatigueBase') - core.getGMST('fFatigueMult') * (1 - fatigueNorm)
    
    if probeMode then
        statsMod = statsMod + (core.getGMST('fTrapCostMult') * getTrapLevel(activeTarget))
    end

    local finalMod = statsMod * equipmentMod * fatigueMod

    if not probeMode then
        finalMod = finalMod + (core.getGMST('fPickLockMult') * lockLevel)
    end

    hangTimeMult = 0.65 + (finalMod / 100) * 0.85
    return finalMod
end

local function getPinSuccessChance()
    if not configGlobal.options.b_SkillAffectsChance then return 100 end

    local baseMod = util.clamp(getOverallSuccessChance(), 0, 100)
    return util.clamp(math.pow(baseMod / 100, 1 / (activeTumblers)) * 100 * (1 - math.exp(-baseMod / 10)), configGlobal.tweaks.n_BasePinChanceMin, configGlobal.tweaks.n_BasePinChanceMax) * configGlobal.tweaks.n_BasePinChanceMult
end

local function setActiveTumblers()
    local tumblerCount
    if configGlobal.tweaks.n_TumblerCountScale == 0 then
        tumblerCount = 5
    else
        tumblerCount = math.min(1 + math.floor((probeMode and getTrapLevel(activeTarget) or getLockLevel(activeTarget)) / configGlobal.tweaks.n_TumblerCountScale), 5)
    end
    activeTumblers = tumblerCount
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
    for i = 1, activeTumblers do
        local pattern = generatePattern(probeMode and getTrapLevel(activeTarget) or getLockLevel(activeTarget))
        tumblerPatterns[i] = pattern
        tumblerPatternIndices[i] = 1
    end
end

local function restoreStoredRot()
    if storedRot then
        local yawDiff = storedRot:getYaw() - self.rotation:getYaw()
        local pitchDiff = storedRot:getPitch() - self.rotation:getPitch()
        self.controls.yawChange = yawDiff
        self.controls.pitchChange = pitchDiff
    end
end

local function setControlsEnabled(enabled)
    types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Controls, enabled)
    types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Looking, enabled)
    types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.VanityMode, enabled)
    types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.ViewMode, enabled)
end

local function getTargetedObject()
    -- To do this, we will use the nearby module to cast a ray in the direction the player is facing
    local pos = camera.getPosition()
    local v = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
	local dist = core.getGMST("iMaxActivateDist") + camera.getThirdPersonDistance()
    local telekinesis = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis)
    if telekinesis then
        dist = dist + (telekinesis.magnitude * 22)
    end
	return nearby.castRenderingRay(pos, pos + v * dist, { ignore = self })
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
    if isLockpicking then return false end
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
        record = types.Lockpick.record(equippedR)
    else
        record = types.Probe.record(equippedR)
    end
    return true, record, target, isProbe
end

local function updateUiPick()
    local thresholds = probeMode and { math.huge, 1.5, 1.25, 1, 0.75, -math.huge } or { 5, 1.5, 1.4, 1.3, 1.1, -math.huge }
    local tier = round(activeLockpick.quality, 3)
    local prefix = probeMode and 'probe_' or 'pick_'
    for i = 1, #thresholds do
        if tier >= thresholds[i] then
            uiPickElement.layout.props.resource = getTexture(Textures.ELEMENT[prefix .. (7 - i)])
            uiPickElement.layout.props.size = getSize(Textures.ELEMENT[prefix .. (7 - i)])
            return
        end
    end
end

local function createElements()
    textureOverride = Textures.getOverride(activeTarget)
    setElementData()
    assignTextures()

    
    uiBase.props.size = getSize(Textures.ELEMENT.base)
    uiBase.props.position = getPosOffset(Textures.ELEMENT.base)
    uiTumblerCover.props.size = getSize(Textures.ELEMENT.cover)
    uiTumblerCover.props.position = getPosOffset(Textures.ELEMENT.cover)
    uiTumbler.content[1].content[2].props.size = getSize(Textures.ELEMENT.pin)

    uiBaseElement = ui.create(uiBase)
    uiPickElement = ui.create(uiPick)
    uiPickElement.layout.props.position = lockpickBasePos
    updateUiPick()

    setTumblers = {}
    for i = 1, tumblerCount do
        local layout = auxUi.deepLayoutCopy(uiTumbler)
        local yOffset = tumblerBaseHeight
        local springHeight = i > activeTumblers and tumblerSetSpringHeight or tumblerBaseSpringHeight
        layout.props.position = util.vector2(tumblerSpacing * (i-3) - 6, yOffset)
        layout.content[1].content[1].props.size = util.vector2(35, springHeight)
        uiTumblerElements[i] = ui.create(layout)
        setTumblers[i] = i > activeTumblers
    end

    uiTumblerCoverElement = ui.create(uiTumblerCover)
    uiInfoBoxElement = ui.create(getInfoBox())
    uiTensionElement = ui.create(getTensionMeter())

    uiWrapper = ui.create {
        layer = 'Notification',
        props = {
            relativeSize = util.vector2(1, 1),
        },
        content = ui.content {
            uiBaseElement,
            uiPickElement,
            uiTumblerElements[1],
            uiTumblerElements[2],
            uiTumblerElements[3],
            uiTumblerElements[4],
            uiTumblerElements[5],
            uiTumblerCoverElement,
            uiInfoBoxElement,
            uiTensionElement,
        }
    }
end

local function initValues()
    lockpickOffsetX = lockpickBasePos.x
    lockpickOffsetY = lockpickBasePos.y
    movingTumbler = nil
    movingTumblerIndex = nil
    movingTumblerTime = nil
    movingTumblerLockpickStartY = nil
    movingTumblerSpeedMult = nil
    movingTumblerCurrentValues = nil
    movingTumblerStage = nil
    movingPickStart = nil
    movingPickTarget = nil
    movingPickTimer = nil
    crimeTimer = crimeInterval
    crimeSeen = false
    tensionPinsSlipping = { false, false, false, false, false }
    impactPause = 0
end

local function destroyElements()
    if uiWrapper then
        auxUi.deepDestroy(uiWrapper)
        uiWrapper = nil
    end
end

local autoSheathe = false
local trySheathe = false

local function stopLockpicking(success)
    if not isLockpicking then return end
    success = success or false
    anim.cancel(self, 'pickprobe')
    if success then
        ui.showMessage(probeMode and l10n('Msg_ProbeSuccess') or l10n('Msg_LockpickSuccess'))
        core.sendGlobalEvent('DrainLockpick', { player = self })
        core.sendGlobalEvent("LockpickSuccess", { player = self, target = activeTarget, probe = probeMode })
        local skillUseType = probeMode and I.SkillProgression.SKILL_USE_TYPES.Security_DisarmTrap or I.SkillProgression.SKILL_USE_TYPES.Security_PickLock
        I.SkillProgression.skillUsed('security', { useType = skillUseType })
    end
    activeTarget = nil
    activeLockpick = nil
    isLockpicking = false
    activeTumblers = nil
    destroyElements()
    setControlsEnabled(true)
    core.sendGlobalEvent('PauseWorldLockpicking', { paused = false })
    
    for _, group in pairs(anim.BONE_GROUP) do
        anim.cancel(self, anim.getActiveGroup(self, group))
    end

    anim.cancel(self, 'pickprobe')
    if success then
        playAnim({ speed = 1, startPoint = 0 })
    end
    
    if autoSheathe then
        autoSheathe = false
        trySheathe = true
    end

    restoreStoredRot()

    shader:disable()
end

local function startLockpicking()
    local canPick, lockpick, target, probe = canLockpick()
    if not canPick then 
        if lockpick and I.UI.getMode() == nil then
            if lastStance ~= types.Actor.STANCE.Weapon then
                playAnim({ startKey = 'equip start', stopKey = 'equip end' })
            else
                playAnim({})
            end
        end
        return
    end
    storedRot = self.rotation
    probeMode = probe or false
    activeLockpick = lockpick
    activeTarget = target
    isLockpicking = true
    advancedMode = configGlobal.options.b_AdvancedMode

    setActiveTumblers()
    setTumblerPatterns()
    initTensionSystem(getLockLevel(activeTarget))

    overallSuccessChance = getOverallSuccessChance()
    pinSuccessChance = getPinSuccessChance()

    setControlsEnabled(false)
    createElements()
    initValues()
    core.sendGlobalEvent('PauseWorldLockpicking', { paused = true})

    restoreStoredRot()

    -- Compatibility with UI Modes' auto-draw feature
    if lastStance ~= types.Actor.STANCE.Weapon then
        autoSheathe = true
        playAnim({ startKey = 'equip start', stopKey = 'start' })
    else 
        autoSheathe = false
        playAnim({ speed = animSpeed, startPoint = 0 })
    end

    shader:setBool('uDarken', configPlayer.options.b_DarkenBackground)
    shader:setBool('uBlur', configPlayer.options.b_BlurBackground)
    shader:setFloat('uDarkenStrength', configPlayer.options.f_DarkenStrength)
    shader:setFloat('uBlurStrength', configPlayer.options.f_BlurStrength)
    shader:enable()
end

local function dropTumblers(movingTumblerIndex, badTiming)
    movingTumblerIndex = movingTumblerIndex or -1
    local keepUp
    if not configGlobal.options.b_SecurityAffectsTumblerDrops then 
        keepUp = 0
    else
        local security = types.NPC.stats.skills.security(self).base
        local interval = configGlobal.tweaks.n_SecurityAffectsTumblerDropsLevelInterval
        keepUp = math.floor(security / interval)
    end

    ambient.playSoundFile("sound/OblivionLockpicking/tumbler_crash.wav")
    for i = 1, activeTumblers do
        local shouldReset = (i == movingTumblerIndex) or (badTiming and setTumblers[i] and keepUp == 0)
        if shouldReset then
            setTumblers[i] = false
            scaleTumbler(i, 1)
        elseif badTiming and setTumblers[i] then
            keepUp = keepUp - 1
        end
    end
end

local function onPick()
    if I.UI.getMode() ~= nil then return end
    if impactPause > 0 then return end
    if movingTumbler ~= nil then
        if movingTumbler.layout.content:indexOf('glow') then
            movingTumbler.layout.content.glow = nil
        end

        if not tensionMovingTumblerLockup then
            ambient.stopSoundFile("sound/OblivionLockpicking/tumbler_fall.wav")
            local skillRoll = math.random() < (pinSuccessChance / 100)
            local tooEarly = movingTumblerTime <= movingTumblerCurrentValues.riseTime
            local tooLate = movingTumblerTime > movingTumblerCurrentValues.riseTime + movingTumblerCurrentValues.hangTime
            if skillRoll and not tooEarly and not tooLate then
                -- Tumbler is in the right position, lock it in place
                setTumblers[movingTumblerIndex] = true
                movingTumbler.layout.content[1].content[1].props.size = util.vector2(35, tumblerSetSpringHeight)

                ambient.playSoundFile("sound/OblivionLockpicking/tumbler_lock.wav", { volume = 2.0 })

                -- Check if all tumblers are set
                local allSet = true
                for i = 1, activeTumblers do
                    if not setTumblers[i] then
                        allSet = false
                        break
                    end
                end

                if allSet then
                    -- All tumblers are set, unlock the lock and stop lockpicking
                    stopLockpicking(true)
                end
            else
                core.sendGlobalEvent('DrainLockpick', { player = self })
                -- Fail; reset all tumblers and break the lockpick
                
                dropTumblers(movingTumblerIndex, tooEarly or tooLate or configGlobal.options.b_MissedRollsDropOtherPins)
                if configPlayer.options.b_ShowFailureReason then
                    if tooEarly then
                        ui.showMessage(l10n('Msg_FailTooEarly'))
                    elseif tooLate then
                        ui.showMessage(l10n('Msg_FailTooLate'))
                    elseif not skillRoll then
                        local percentageString = configPlayer.options.b_ShowFailureReasonPercentage and string.format(" (%.2f%%)", pinSuccessChance) or ''
                        ui.showMessage(l10n('Msg_FailSkillRoll') .. percentageString)
                    end
                end
            end

            movingTumbler = nil
            movingTumblerIndex = nil
            movingTumblerTime = nil
            movingTumblerSpeedMult = nil
            movingTumblerCurrentValues = nil
            movingTumblerLockpickStartY = nil
            movingTumblerStage = nil
        end
    else
        -- Find the targeted pin and move the pick up to it
        local nearestTumbler = util.clamp(math.floor(((lockpickOffsetX + 94) + tumblerSpacing / 2) / tumblerSpacing), 0, 4)
        if setTumblers[nearestTumbler + 1] == true then return end
        local distanceToTumbler = (lockpickOffsetX + 94) - (nearestTumbler * tumblerSpacing)
        if math.abs(distanceToTumbler) <= lockpickAlignmentTolerance then
            -- Move the pick to the pin position
            movingPickStart = util.vector2(lockpickOffsetX, lockpickOffsetY)
            movingPickTarget = util.vector2(tumblerSpacing * (nearestTumbler - 2) + 8, 0)
            movingPickTimer = 0
        end
    end
end

local function onPrevPin()
    if I.UI.getMode() ~= nil then return end
    if impactPause > 0 then return end
    local nearestTumbler = util.clamp(math.floor(((lockpickOffsetX + 94) + tumblerSpacing / 2) / tumblerSpacing), 0, 4)
    if nearestTumbler > 0 then
        local targetOffsetX = tumblerSpacing * (nearestTumbler - 3) + 8
        local targetOffsetY = 24
        movingPickTimer = 0
        movingPickStart = util.vector2(lockpickOffsetX, lockpickOffsetY)
        movingPickTarget = util.vector2(targetOffsetX, targetOffsetY)
        ambient.playSoundFile("sound/OblivionLockpicking/pickmove" .. math.random(1, 2) .. ".wav", { pitch = 1.25 })
    end
end

local function onNextPin()
    if I.UI.getMode() ~= nil then return end
    if impactPause > 0 then return end
    local nearestTumbler = util.clamp(math.floor(((lockpickOffsetX + 94) + tumblerSpacing / 2) / tumblerSpacing), 0, 4)
    if nearestTumbler < activeTumblers - 1 then
        local targetOffsetX = tumblerSpacing * (nearestTumbler - 1) + 8
        local targetOffsetY = 24
        movingPickTimer = 0
        movingPickStart = util.vector2(lockpickOffsetX, lockpickOffsetY)
        movingPickTarget = util.vector2(targetOffsetX, targetOffsetY)
        ambient.playSoundFile("sound/OblivionLockpicking/pickmove" .. math.random(1, 2) .. ".wav", { pitch = 1.25 })
    end
end

local function updateLockpick()
    local mouseMoveX = input.getMouseMoveX()
    local mouseMoveY = input.getMouseMoveY()
    if movingPickTimer == nil then
        local nearestTumbler = util.clamp(math.floor(((lockpickOffsetX + 94) + tumblerSpacing / 2) / tumblerSpacing), 0, 4)
        local distanceToTumbler = (lockpickOffsetX + 94) - (nearestTumbler * tumblerSpacing)
        -- "Gravitate" the lockpick towards valid tumbler positions
        if not advancedMode and (mouseMoveX ~= 0 or mouseMoveY ~= 0) then
            mouseMoveX = mouseMoveX * (0.05 + 0.45 * math.abs(distanceToTumbler) / tumblerSpacing) * 3
            mouseMoveY = mouseMoveY / 3
            local clampToHoles = false
            if math.abs(distanceToTumbler) > lockpickAlignmentTolerance then
                if lockpickOffsetY < 10 then
                    clampToHoles = true
                    mouseMoveY = math.max(mouseMoveY, 0)
                    if distanceToTumbler > 0 then
                        mouseMoveX = math.min(mouseMoveX, 0)
                    else
                        mouseMoveX = math.max(mouseMoveX, 0)
                    end
                end
            end

            lockpickOffsetX = util.clamp(lockpickOffsetX + mouseMoveX, lockpickRangeX[1], lockpickRangeX[2])
            lockpickOffsetY = util.clamp(lockpickOffsetY + mouseMoveY, lockpickRangeY[1], lockpickRangeY[2])
        end

        if movingTumbler == nil and lockpickOffsetY < 8 and nearestTumbler < activeTumblers and not setTumblers[nearestTumbler + 1] and math.abs(distanceToTumbler) <= lockpickAlignmentTolerance then
            movingTumblerIndex = nearestTumbler + 1
            movingTumbler = uiTumblerElements[movingTumblerIndex]
            movingTumblerTime = 0
            movingTumblerCurrentValues = {}
            local hangTimeMod = hangTimeMult * configGlobal.tweaks.n_BaseHangTimeMult
            if configGlobal.options.b_TumblerSpeedFollowsPattern then
                if tumblerPatternIndices[movingTumblerIndex] > #tumblerPatterns[movingTumblerIndex] then
                    tumblerPatternIndices[movingTumblerIndex] = 1
                end
                movingTumblerSpeedMult = tumblerPatterns[movingTumblerIndex][tumblerPatternIndices[movingTumblerIndex]]
                tumblerPatternIndices[movingTumblerIndex] = tumblerPatternIndices[movingTumblerIndex] + 1
                if movingTumblerSpeedMult < 0.8 then
                    hangTimeMod = math.random(1, 5) / 10
                end
            else
                if math.random(1, 5) > 2 then
                    hangTimeMod = math.random(1, 5) / 10
                    movingTumblerSpeedMult = math.random(20, 50) / 100
                else
                    movingTumblerSpeedMult = math.random(90, 100) / 100
                end
            end
            movingTumblerSpeedMult = movingTumblerSpeedMult * configGlobal.tweaks.n_BaseTimeMult
            movingTumblerCurrentValues.riseTime = movingTumblerBaseValues.riseTime * movingTumblerSpeedMult
            movingTumblerCurrentValues.hangTime = movingTumblerBaseValues.hangTime * movingTumblerSpeedMult * hangTimeMod
            movingTumblerCurrentValues.fallTime = movingTumblerBaseValues.fallTime * movingTumblerSpeedMult
            movingTumblerLockpickStartY = lockpickOffsetY
            movingTumblerStage = 0

            if advancedMode and math.random() < tensionTooTight then
                tensionMovingTumblerLockup = true
                movingTumblerCurrentValues.riseTime = 0.1
                movingTumblerCurrentValues.hangTime = 0
                movingTumblerCurrentValues.fallTime = 0.1
                core.sendGlobalEvent('DrainLockpick', { player = self })
            else
                tensionMovingTumblerLockup = false
            end
        end

        uiPickElement.layout.props.position = util.vector2(lockpickOffsetX, lockpickOffsetY)
    else
        -- Move the pick towards the tumbler position
        local dt = core.getRealFrameDuration()
        movingPickTimer = movingPickTimer + dt
        local t = movingPickTimer / movingPickDuration
        if t >= 1 then
            t = 1
            movingPickTimer = nil
        end
        lockpickOffsetX = lerp(t, movingPickStart.x, movingPickTarget.x)
        lockpickOffsetY = lerp(t, movingPickStart.y, movingPickTarget.y)
        uiPickElement.layout.props.position = util.vector2(lockpickOffsetX, lockpickOffsetY)
    end
end

local function updateMovingTumbler()
    if movingTumbler then
        local dt = core.getRealFrameDuration()
        movingTumblerTime = movingTumblerTime + dt
        local riseTime = movingTumblerCurrentValues.riseTime
        local hangTime = movingTumblerCurrentValues.hangTime
        local fallTime = movingTumblerCurrentValues.fallTime

        if movingTumblerTime < movingPickDuration then
            lockpickOffsetY = lerp(movingTumblerTime / movingPickDuration, movingTumblerLockpickStartY, 24)
            uiPickElement.layout.props.position = util.vector2(lockpickOffsetX, lockpickOffsetY)
        end

        if movingTumblerTime < riseTime then
            if movingTumblerStage == 0 then
                movingTumblerStage = 1
                ambient.playSoundFile("sound/OblivionLockpicking/tumbler_move.wav")
            end
            local t = movingTumblerTime / riseTime
            local scale = lerpQuadOut(t, 1, tensionMovingTumblerLockup and 0.9 or 0)
            scaleTumbler(movingTumblerIndex, scale)
        elseif movingTumblerTime < riseTime + hangTime then
            if movingTumblerStage == 1 then
                movingTumblerStage = 2
                ambient.playSoundFile("sound/OblivionLockpicking/tumbler_click.wav")
            end
            if not ambient.isSoundFilePlaying("sound/OblivionLockpicking/tumbler_fall.wav") then
                ambient.playSoundFile("sound/OblivionLockpicking/tumbler_fall.wav")
            end
            scaleTumbler(movingTumblerIndex, tensionMovingTumblerLockup and 0.9 or 0)
            
            if configPlayer.options.b_TimingWindowGlow then
                if not movingTumbler.layout.content:indexOf('glow') then
                    movingTumbler.layout.content:add({
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
                movingTumbler.layout.content.glow.props.alpha = lerpQuintic(util.clamp((movingTumblerTime - riseTime) / hangTime, 0, 1), 1, 0)
            end
        elseif movingTumblerTime < riseTime + hangTime + fallTime then
            if movingTumblerStage < 3 then
                if movingTumblerStage == 1 and not tensionMovingTumblerLockup then
                    ambient.playSoundFile("sound/OblivionLockpicking/tumbler_click.wav")
                end
                movingTumblerStage = 3
            end
            if not ambient.isSoundFilePlaying("sound/OblivionLockpicking/tumbler_fall.wav") then
                ambient.playSoundFile("sound/OblivionLockpicking/tumbler_fall.wav")
            end
            local t = (movingTumblerTime - riseTime - hangTime) / fallTime
            local scale = lerpQuad(t, tensionMovingTumblerLockup and 0.9 or 0, 1)
            scaleTumbler(movingTumblerIndex, scale)

            if movingTumbler.layout.content:indexOf('glow') then
                movingTumbler.layout.content.glow = nil
            end
        else
            -- Tumbler has fallen back down, reset the values and set the tumbler to its original position
            scaleTumbler(movingTumblerIndex, 1)

            if movingTumbler.layout.content:indexOf('glow') then
                movingTumbler.layout.content.glow = nil
            end

            movingTumbler = nil
            movingTumblerIndex = nil
            movingTumblerTime = nil
            movingTumblerCurrentValues = nil
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

    local currTier = round(activeLockpick.quality, 3)

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
        local tier = round(getType().record(pick).quality, 3)
        local cond = types.Item.itemData(pick).condition
        local diff = tier - currTier
        local absDiff = math.abs(diff)

        if tier == currTier then
            if not bestSameTier or isBetterCond(cond, types.Item.itemData(bestSameTier).condition) then
                bestSameTier = pick
            end
        elseif (prefersHigher and diff > 0) or (not prefersHigher and diff < 0) then
            if not bestPreferred or absDiff < math.abs(round(getType().record(bestPreferred).quality, 3) - currTier)
                or (absDiff == math.abs(round(getType().record(bestPreferred).quality, 3) - currTier)
                    and isBetterCond(cond, types.Item.itemData(bestPreferred).condition)) then
                bestPreferred = pick
            end
        else
            if not bestFallback or absDiff < math.abs(round(getType().record(bestFallback).quality, 3) - currTier)
                or (absDiff == math.abs(round(getType().record(bestFallback).quality, 3) - currTier)
                    and isBetterCond(cond, types.Item.itemData(bestFallback).condition)) then
                bestFallback = pick
            end
        end
    end

    newPick = bestSameTier or bestPreferred or bestFallback

    activeLockpick = getType().record(newPick)
    local equipment = types.Actor.getEquipment(self)
    equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight] = newPick
    types.Actor.setEquipment(self, equipment)
    updateUiPick()
    return true
end

local function autoAttempt()
    if I.UI.getMode() ~= nil then return end
    if impactPause > 0 then return end
    local skillRoll = math.random() < (overallSuccessChance / 100 * configGlobal.tweaks.n_AutoAttemptSuccessModifier)
    if skillRoll then
        stopLockpicking(true)
    else
        core.sendGlobalEvent('DrainLockpick', { player = self })
        dropTumblers(-1, true)
        if configPlayer.options.b_ShowFailureReason then
            local percentageString = configPlayer.options.b_ShowFailureReasonPercentage and string.format(" (%.2f%%)", overallSuccessChance * configGlobal.tweaks.n_AutoAttemptSuccessModifier) or ''
            ui.showMessage(l10n('Msg_FailSkillRoll') .. percentageString)
        end
    end
end

local function handleKeyPress(key)
    controllerPrompts = false
    if not isLockpicking then return end
    if key.code == configPlayer.keybinds.keybindPreviousPin then
        onPrevPin()
    elseif key.code == configPlayer.keybinds.keybindNextPin then
        onNextPin()
    elseif key.code == configPlayer.keybinds.keybindPickPin then
        onPick()
    elseif key.code == configPlayer.keybinds.keybindAutoAttempt then
        autoAttempt()
    elseif key.code == configPlayer.keybinds.keybindCancel then
        stopLockpicking()
    end
end

local function handleControllerPress(button)
    controllerPrompts = true
    if not isLockpicking then return end
    if advancedMode then
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
        onPick()
    elseif button == input.CONTROLLER_BUTTON.X then
        autoAttempt()
    elseif button == input.CONTROLLER_BUTTON.Y then
        stopLockpicking()
    end
end

local function frame()
    if not configGlobal.options.b_EnableMod then overrideCombatControls = false
    else
        hasTool, equippedR, isLockpick, isProbe = toolEquipped()
        if not hasTool then overrideCombatControls = false
        elseif isProbe and not configGlobal.options.b_UseForDisarming then overrideCombatControls = false
        elseif types.Actor.getStance(self) == types.Actor.STANCE.Spell then overrideCombatControls = false
        else overrideCombatControls = true end
    end
    I.Controls.overrideCombatControls(overrideCombatControls)

    lastStance = types.Actor.getStance(self)

    if trySheathe and types.Actor.getStance(self) ~= types.Actor.STANCE.Nothing then
        types.Actor.setStance(self, types.Actor.STANCE.Nothing)
        if types.Actor.getStance(self) == types.Actor.STANCE.Nothing then
            trySheathe = false
        end
    end

    if not isLockpicking then return end

    if I.UI.getMode() ~= nil or (core.isWorldPaused() and not configGlobal.options.b_PauseTime) then 
        uiWrapper.layout.layer = 'HUD'
        auxUi.deepUpdate(uiWrapper)
        return
    else
        uiWrapper.layout.layer = 'Notification'
    end

    if crimeTimer < crimeInterval then
        if not core.isWorldPaused() then
            crimeTimer = crimeTimer + core.getRealFrameDuration()
        end
    else
        if crimeSeen then 
            if configPlayer.options.b_StopIfCaught then
                stopLockpicking() 
            end
            return
        end
        local ownerFaction = activeTarget.owner.factionId
        local ownerNPC = activeTarget.owner.recordId

        if ownerFaction or ownerNPC then
            core.sendGlobalEvent("PlayerLockpicking", { player = self, faction = ownerFaction })
        end
        crimeTimer = 0
    end

    if configPlayer.options.b_PlayLockpickAnimation and (not anim.isPlaying(self, 'pickprobe') or anim.getCompletion(self, 'pickprobe') >= animEnd + animEndRand) then
        anim.cancel(self, 'pickprobe')
        animStartRand = math.random() * 0.1 - 0.05
        animEndRand = math.random() * 0.1 - 0.05
        local speedRand = animSpeed * (0.85 + math.random() * 0.4 - 0.3)
        playAnim({ speed = speedRand, startPoint = animStart + animStartRand })
    end

    if ambientScrapeTimer > 0 then
        ambientScrapeTimer = ambientScrapeTimer - core.getRealFrameDuration()
    elseif configPlayer.options.b_PlayRandomSounds then
        local rand = math.random(1, #ambientScrapeSounds - 1)
        rand = (rand >= ambientScrapeLast) and (rand + 1) or rand
        ambient.playSoundFile(ambientScrapeSounds[rand], { volume = 0.25 })
        ambientScrapeTimer = ambientScrapeIntervalMin + math.random() * (ambientScrapeIntervalMax - ambientScrapeIntervalMin)
        ambientScrapeLast = rand
    end

    local lockpick = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if not lockpick or not getType().objectIsInstance(lockpick) then
        ambient.playSoundFile("sound/OblivionLockpicking/lock_pickbreak.wav")
        ui.showMessage(probeMode and l10n('Msg_ProbeBreak') or l10n('Msg_LockpickBreak'))
        if not configPlayer.options.b_AutoEquip or not getNewPick() then
            ui.showMessage(probeMode and l10n('Msg_ProbeNoneLeft') or l10n('Msg_LockpickNoneLeft'))
            stopLockpicking()
        else
            impactPause = impactPauseLength
            anim.cancel(self, 'pickprobe')
            playAnim({ speed = 0.5, startKey = 'equip start', stopKey = 'start' })
        end
    end

    if impactPause > 0 then
        impactPause = impactPause - core.getRealFrameDuration()
        local progress = (impactPauseLength - impactPause) / impactPauseLength
        local pickX = lerpQuadOut(progress, lockpickBasePos.x - 800, lockpickOffsetX)
        local pickY = lerpQuadOut(progress, lockpickBasePos.y, lockpickOffsetY)
        uiPickElement.layout.props.position = util.vector2(pickX, pickY)
        local tensionMeterOverlay = uiTensionElement.layout.content[1].content[1].content['TensionMeterOverlay']
        tensionMeterOverlay.props.color = util.color.rgb(util.clamp(lerpCubic(progress, 0, 0.25), 0, 0.25), 0, 0)
        tensionMeterOverlay.props.alpha = util.clamp(lerpCubic(progress, 1, 0), 0, 1)
        uiPickElement:update()
        uiTensionElement:update()
        return
    end

    overallSuccessChance = getOverallSuccessChance()
    pinSuccessChance = getPinSuccessChance()

    updateLockpick()
    updateMovingTumbler()
    updateInfoBox()
    updateTension()
    auxUi.deepUpdate(uiWrapper)
    if (configGlobal.options.b_HardSkillGating and overallSuccessChance < 0) then
        ui.showMessage(probeMode and l10n('Msg_ProbeTooComplex') or l10n('Msg_LockpickTooComplex'))
        stopLockpicking()
        return
    elseif (configGlobal.options.b_SkipIfGuaranteed and overallSuccessChance >= 100) then
        stopLockpicking(true)
        return
    end
end

local function onUse()
    if not isLockpicking then 
        startLockpicking()
    else 
        onPick() 
    end
end

input.registerActionHandler("Use", async:callback(function(e)
    if configGlobal.options.b_EnableMod and e then onUse() end
end))

input.registerTriggerHandler("ToggleWeapon", async:callback(function()
    if configGlobal.options.b_EnableMod and overrideCombatControls and not isLockpicking then
        local stance = types.Actor.getStance(self)
        if stance == types.Actor.STANCE.Weapon then
            types.Actor.setStance(self, types.Actor.STANCE.Nothing)
        else
            types.Actor.setStance(self, types.Actor.STANCE.Weapon)
        end
    end
end))

input.registerTriggerHandler("ToggleSpell", async:callback(function()
    if configGlobal.options.b_EnableMod and overrideCombatControls and not isLockpicking then
        local stance = types.Actor.getStance(self)
        if stance == types.Actor.STANCE.Spell then
            types.Actor.setStance(self, types.Actor.STANCE.Nothing)
        else
            types.Actor.setStance(self, types.Actor.STANCE.Spell)
        end
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
        onSave = function()
            stopLockpicking()
            return { DidReset = 1 }
        end,
        onLoad = function(data)
            shader:disable()
            if not data or data.DidReset ~= 1 then
                -- Make sure saves made in old versions with pick equipped don't have controls disabled forever
                types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, true)
            end
        end,
    },
    eventHandlers = {
        PlayerLockpickingSeen = function()
            crimeSeen = true
        end,
        UiModeChanged = function(data)
            if isLockpicking and data.newMode == nil then
                advancedMode = configGlobal.options.b_AdvancedMode
            end
        end,
    }
}