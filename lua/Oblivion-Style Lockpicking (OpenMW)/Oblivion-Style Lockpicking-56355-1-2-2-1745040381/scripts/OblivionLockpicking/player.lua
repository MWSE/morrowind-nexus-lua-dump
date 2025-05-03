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

local configPlayer = require('scripts.OblivionLockpicking.config.player')
local configGlobal = require('scripts.OblivionLockpicking.config.global')

local l10n = core.l10n('OblivionLockpicking')

local isLockpicking = false
local activeLockpick = nil
local activeTarget = nil

local textureAtlas = 'textures/OblivionLockpicking/atlas.dds'
local textureBase = ui.texture {
    path = textureAtlas,
    offset = util.vector2(0, 0),
    size = util.vector2(684, 640),
}
local function texturePick(i)
    return ui.texture {
        path = textureAtlas,
        offset = util.vector2(0, 640 + (i - 1) * 64),
        size = util.vector2(519, 64),
    }
end
local textureTumbler = ui.texture {
    path = textureAtlas,
    offset = util.vector2(684, 110),
    size = util.vector2(35, 98),
}
local textureTumblerSpring = ui.texture {
    path = textureAtlas,
    offset = util.vector2(684, 0),
    size = util.vector2(35, 110),
}
local textureTumblerCover = ui.texture {
    path = textureAtlas,
    offset = util.vector2(684, 208),
    size = util.vector2(317, 211),
}

local uiBase = { 
    layer = 'HUD',
    type = ui.TYPE.Image,
    props = {
        resource = textureBase,
        relativePosition = util.vector2(0.5, 0.5),
        position = util.vector2(5, -4),
        anchor = util.vector2(0.5, 0.5),
        size = util.vector2(684, 640),
    }
}
local uiPick = { 
    layer = 'HUD',
    type = ui.TYPE.Image,
    props = {
        resource = texturePick(1),
        relativePosition = util.vector2(0.5, 0.5),
        anchor = util.vector2(1, 0),
        size = util.vector2(519, 64),
    }
}
local uiTumbler = { 
    layer = 'HUD',
    type = ui.TYPE.Flex,
    props = {
        relativePosition = util.vector2(0.5, 0.5),
        anchor = util.vector2(0.5, 0),
    },
    content = {
        { 
            layer = 'HUD',
            type = ui.TYPE.Image,
            props = {
                resource = textureTumblerSpring,
                size = util.vector2(35, 110),
            }
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = textureTumbler,
                size = util.vector2(35, 98),
                --position = util.vector2(0, 110)
            },
        },
    }
}
local uiTumblerCover = { 
    layer = 'HUD',
    type = ui.TYPE.Image,
    props = {
        resource = textureTumblerCover,
        relativePosition = util.vector2(0.5, 0.5),
        anchor = util.vector2(0.5, 0.5),
        size = util.vector2(317, 211),
        position = util.vector2(-9, -88),
    }
}

local uiBaseElement, uiPickElement, uiTumblerCoverElement, uiInfoBoxElement = nil, nil, nil, nil
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
local lockpickOffsetY = 32
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

local probeMode = false

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

-- === Util Functions ===
local function round(float, decimalPlaces)
    local mult = 10 ^ (decimalPlaces or 0)
    return math.floor(float * mult + 0.5) / mult
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
-- ======================

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
        layer = 'HUD',
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
            setInfoLineText(content, 'InfoBoxKeybindMove', l10n('InfoBoxKeybindMoveText') .. " " .. input.getKeyName(configPlayer.keybinds.keybindPreviousPin) .. "/" .. input.getKeyName(configPlayer.keybinds.keybindNextPin))
            setInfoLineText(content, 'InfoBoxKeybindPick', input.getKeyName(configPlayer.keybinds.keybindPickPin))
            setInfoLineText(content, 'InfoBoxKeybindAutoAttempt', input.getKeyName(configPlayer.keybinds.keybindAutoAttempt))
            setInfoLineText(content, 'InfoBoxKeybindStop', input.getKeyName(configPlayer.keybinds.keybindCancel))
        else 
            setInfoLineText(content, 'InfoBoxKeybindMove', l10n('InfoBoxKeybindMoveControllerText'))
            setInfoLineText(content, 'InfoBoxKeybindPick', l10n('InfoBoxKeybindPickControllerText'))
            setInfoLineText(content, 'InfoBoxKeybindAutoAttempt', l10n('InfoBoxKeybindAutoAttemptControllerText'))
            setInfoLineText(content, 'InfoBoxKeybindStop', l10n('InfoBoxKeybindStopControllerText'))
        end
    end
    uiInfoBoxElement:update()
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
    local thresholds = probeMode and { math.huge, 1.5, 1.25, 1, 0.75 } or { 5, 1.5, 1.4, 1.3, 1.1 }
    local tier = round(activeLockpick.quality, 3)
    for i = 1, #thresholds do
        if tier >= thresholds[i] then
            uiPickElement.layout.props.resource = texturePick(7 - i)
            uiPickElement:update()
            return
        end
    end
    uiPickElement.layout.props.resource = texturePick(1)
    uiPickElement:update()
end

local function createElements()
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
        layout.content[1].props.size = util.vector2(35, springHeight)
        uiTumblerElements[i] = ui.create(layout)
        setTumblers[i] = i > activeTumblers
    end

    uiTumblerCoverElement = ui.create(uiTumblerCover)
    uiInfoBoxElement = ui.create(getInfoBox())
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
end

local function destroyElements()
    if uiBaseElement then
        uiBaseElement:destroy()
        uiBaseElement = nil
    end
    if uiPickElement then
        uiPickElement:destroy()
        uiPickElement = nil
    end

    for i = 1, 5 do
        if uiTumblerElements[i] then
            uiTumblerElements[i]:destroy()
            uiTumblerElements[i] = nil
        end
    end

    if uiTumblerCoverElement then
        uiTumblerCoverElement:destroy()
        uiTumblerCoverElement = nil
    end

    if uiInfoBoxElement then
        uiInfoBoxElement:destroy()
        uiInfoBoxElement = nil
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

    setActiveTumblers()
    setTumblerPatterns()

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
end

local function onUse()
    if not isLockpicking then startLockpicking() return true end
    return false
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
            uiTumblerElements[i].layout.content[1].props.size = util.vector2(35, tumblerBaseSpringHeight)
            uiTumblerElements[i]:update()
        elseif badTiming and setTumblers[i] then
            keepUp = keepUp - 1
        end
    end
end

local function onPick()
    if movingTumbler ~= nil then
        ambient.stopSoundFile("sound/OblivionLockpicking/tumbler_fall.wav")
        local skillRoll = math.random() < (pinSuccessChance / 100)
        local tooEarly = movingTumblerTime <= movingTumblerCurrentValues.riseTime
        local tooLate = movingTumblerTime > movingTumblerCurrentValues.riseTime + movingTumblerCurrentValues.hangTime
        if skillRoll and not tooEarly and not tooLate then
            -- Tumbler is in the right position, lock it in place
            setTumblers[movingTumblerIndex] = true
            movingTumbler.layout.content[1].props.size = util.vector2(35, tumblerSetSpringHeight)
            movingTumbler:update()
            uiTumblerCoverElement:update()

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
            uiTumblerCoverElement:update()
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
        if mouseMoveX ~= 0 or mouseMoveY ~= 0 then
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
        end

        uiPickElement.layout.props.position = util.vector2(lockpickOffsetX, lockpickOffsetY)
        uiPickElement:update()
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
        uiPickElement:update()
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
            uiPickElement:update()
        end

        if movingTumblerTime < riseTime then
            if movingTumblerStage == 0 then
                movingTumblerStage = 1
                ambient.playSoundFile("sound/OblivionLockpicking/tumbler_move.wav")
            end
            local t = movingTumblerTime / riseTime
            local springHeight = lerpQuadOut(t, tumblerBaseSpringHeight, tumblerSetSpringHeight)
            movingTumbler.layout.content[1].props.size = util.vector2(35, springHeight)
            movingTumbler:update()
        elseif movingTumblerTime < riseTime + hangTime then
            if movingTumblerStage == 1 then
                movingTumblerStage = 2
                ambient.playSoundFile("sound/OblivionLockpicking/tumbler_click.wav")
            end
            if not ambient.isSoundFilePlaying("sound/OblivionLockpicking/tumbler_fall.wav") then
                ambient.playSoundFile("sound/OblivionLockpicking/tumbler_fall.wav")
            end
            movingTumbler.layout.content[1].props.size = util.vector2(35, tumblerSetSpringHeight)
            movingTumbler:update()
        elseif movingTumblerTime < riseTime + hangTime + fallTime then
            if movingTumblerStage == 2 then
                movingTumblerStage = 3
            end
            if not ambient.isSoundFilePlaying("sound/OblivionLockpicking/tumbler_fall.wav") then
                ambient.playSoundFile("sound/OblivionLockpicking/tumbler_fall.wav")
            end
            local t = (movingTumblerTime - riseTime - hangTime) / fallTime
            local springHeight = lerpQuad(t, tumblerSetSpringHeight, tumblerBaseSpringHeight)
            movingTumbler.layout.content[1].props.size = util.vector2(35, springHeight)
            movingTumbler:update()
        else
            -- Tumbler has fallen back down, reset the values and set the tumbler to its original position
            movingTumbler.layout.content[1].props.size = util.vector2(35, tumblerBaseSpringHeight)
            movingTumbler:update()
            movingTumbler = nil
            movingTumblerIndex = nil
            movingTumblerTime = nil
            movingTumblerCurrentValues = nil
            ambient.stopSoundFile("sound/OblivionLockpicking/tumbler_fall.wav")
        end
        uiTumblerCoverElement:update()
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
    local skillRoll = math.random() < (overallSuccessChance / 100 * configGlobal.tweaks.n_AutoAttemptSuccessModifier)
    if skillRoll then
        stopLockpicking(true)
    else
        core.sendGlobalEvent('DrainLockpick', { player = self })
        dropTumblers(-1, true)
        uiTumblerCoverElement:update()
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
    if button == input.CONTROLLER_BUTTON.DPadLeft then
        onPrevPin()
    elseif button == input.CONTROLLER_BUTTON.DPadRight then
        onNextPin()
    elseif button == input.CONTROLLER_BUTTON.A then
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
    if core.isWorldPaused() and not configGlobal.options.b_PauseTime then return end
    overallSuccessChance = getOverallSuccessChance()
    pinSuccessChance = getPinSuccessChance()

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

    updateLockpick()
    updateMovingTumbler()
    updateInfoBox()

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

    local lockpick = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if not lockpick or not getType().objectIsInstance(lockpick) then
        ambient.playSoundFile("sound/OblivionLockpicking/lock_pickbreak.wav")
        ui.showMessage(probeMode and l10n('Msg_ProbeBreak') or l10n('Msg_LockpickBreak'))
        if not configPlayer.options.b_AutoEquip or not getNewPick() then
            ui.showMessage(probeMode and l10n('Msg_ProbeNoneLeft') or l10n('Msg_LockpickNoneLeft'))
            stopLockpicking()
        end
    end
    if (configGlobal.options.b_HardSkillGating and overallSuccessChance < 0) then
        ui.showMessage(probeMode and l10n('Msg_ProbeTooComplex') or l10n('Msg_LockpickTooComplex'))
        stopLockpicking()
        return
    elseif (configGlobal.options.b_SkipIfGuaranteed and overallSuccessChance >= 100) then
        stopLockpicking(true)
        return
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
            if isLockpicking and uiInfoBoxElement and data.newMode == nil then
                uiInfoBoxElement:destroy()
                uiInfoBoxElement = ui.create(getInfoBox())
                updateInfoBox()
            end
        end,
    }
}