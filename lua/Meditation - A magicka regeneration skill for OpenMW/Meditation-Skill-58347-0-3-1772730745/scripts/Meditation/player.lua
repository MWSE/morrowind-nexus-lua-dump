local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local API = I.SkillFramework
local l10n = core.l10n('Meditation')
local input = require('openmw.input')
local async = require('openmw.async')
local ui = require('openmw.ui')
local ambient = require('openmw.ambient')
local animation = require('openmw.animation')
local camera = require('openmw.camera')
local util = require('openmw.util')
local v2 = util.vector2
local storage = require('openmw.storage')
local Player = types.Player

local skillId = 'meditation_skill'

local gameplaySettings = storage.playerSection('SettingsMeditationGameplay')
local controlsSettings = storage.playerSection('SettingsMeditationControls')
local DEFAULT_MEDITATION_KEY = input.KEY.I

local POOL_EXPONENT = 1.8
local RATE_EXPONENT = 1.5
local POOL_MAX_GAIN = 41
local RATE_MAX_GAIN = 2.7

local OVERLAY_MAX_ALPHA   = 0.3
local OVERLAY_FADE_SPEED  = 0.6
local MEDITATION_SOUND    = 'skillraise'
local SOUND_MAX_VOLUME    = 0.35
local XP_INTERVAL         = 2.0
local ANIM_CANDIDATES     = { 'almapray', 'armsalmapray', 'pray', 'prayerdm', 'idle6' }

local REGEN_BASE_RATE     = 0.02
local REGEN_WILLPOWER_SCALE = 0.003

local meditating          = false
local concentrationUsed   = 0
local meterElement        = nil
local pulseTimer          = 0
local xpTimer             = 0
local activeAnimGroup     = nil
local needsPostLoadCleanup = false
local lastToggleTime      = 0
local TOGGLE_COOLDOWN     = 0.5
local ANIM_REFRESH_INTERVAL = 3.0
local animRefreshTimer    = 0

local overlayElement      = nil
local overlayAlpha        = 0
local overlayFading       = 0
local soundPlaying        = false
local savedCameraMode     = nil
local lastGameTime        = nil

local stats = {
    magicka   = types.Actor.stats.dynamic.magicka(self),
    willpower = types.Actor.stats.attributes.willpower(self),
}

local whiteTex = ui.texture { path = 'white' }

local function getColorFromGameSettings(gmst)
    local result = core.getGMST(gmst)
    if not result then return util.color.rgb(1, 1, 1) end
    local rgb = {}
    for c in string.gmatch(result, '(%d+)') do
        table.insert(rgb, tonumber(c))
    end
    if #rgb ~= 3 then return util.color.rgb(1, 1, 1) end
    return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end

local barColor    = util.color.hex("4a6fa5")
local barColorLow = util.color.hex("8b4513")
local textColor   = getColorFromGameSettings("FontColor_color_normal")
local overlayColor = util.color.rgba(0.15, 0.2, 0.55, 1)

-- ═══════════════════════════════════════════════════════════════════════════
-- SKILL REGISTRATION
-- ═══════════════════════════════════════════════════════════════════════════

API.registerSkill(skillId, {
    name        = l10n('skill_meditation_name'),
    description = l10n('skill_meditation_desc'),
    icon        = { fgr = "icons/meditation/meditate.dds" },
    attribute   = "willpower",
    specialization = API.SPECIALIZATION.Magic,
    skillGain   = { [1] = 0.25 },
    startLevel  = 5,
    maxLevel    = 100,
    statsWindowProps = {
        subsection = API.STATS_WINDOW_SUBSECTIONS.Magic,
    },
})

API.registerRaceModifier(skillId, 'breton',   15)
API.registerRaceModifier(skillId, 'altmer',   10)
API.registerRaceModifier(skillId, 'dunmer',    5)
API.registerRaceModifier(skillId, 'orc',     -10)
API.registerRaceModifier(skillId, 'nord',     -5)

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local function getMaxConcentration()
    local s = API.getSkillStat(skillId)
    local level = s and s.modified or 0
    local base = gameplaySettings:get('ConcentrationBase') or 4
    return base + POOL_MAX_GAIN * (level / 100) ^ POOL_EXPONENT
end

local function getMagickaRate()
    local s = API.getSkillStat(skillId)
    local level = s and s.modified or 0
    local baseRate = gameplaySettings:get('MagickaPerConcentration') or 0.8
    return baseRate + RATE_MAX_GAIN * (level / 100) ^ RATE_EXPONENT
end

-- ═══════════════════════════════════════════════════════════════════════════
-- MOVEMENT LOCK
-- ═══════════════════════════════════════════════════════════════════════════

local function lockPlayer()
    Player.setControlSwitch(self, Player.CONTROL_SWITCH.Controls, false)
    Player.setControlSwitch(self, Player.CONTROL_SWITCH.Fighting, false)
    Player.setControlSwitch(self, Player.CONTROL_SWITCH.Jumping,  false)
    Player.setControlSwitch(self, Player.CONTROL_SWITCH.Magic,    false)
end

local function unlockPlayer()
    Player.setControlSwitch(self, Player.CONTROL_SWITCH.Controls, true)
    Player.setControlSwitch(self, Player.CONTROL_SWITCH.Fighting, true)
    Player.setControlSwitch(self, Player.CONTROL_SWITCH.Jumping,  true)
    Player.setControlSwitch(self, Player.CONTROL_SWITCH.Magic,    true)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ANIMATION
-- ═══════════════════════════════════════════════════════════════════════════

local function playMeditationAnim()
    activeAnimGroup = nil
    for _, group in ipairs(ANIM_CANDIDATES) do
        local has = animation.hasGroup(self, group)
        print(string.format("MEDITATION ANIM: hasGroup('%s') = %s", group, tostring(has)))
        if has and not activeAnimGroup then
            activeAnimGroup = group
        end
    end
    if not activeAnimGroup then
        activeAnimGroup = 'idle'
    end
    animation.clearAnimationQueue(self, false)
    animation.playQueued(self, activeAnimGroup, {
        loops     = 0,
        speed     = 0.25,
        forceLoop = true,
    })
    print("MEDITATION: Playing '" .. activeAnimGroup .. "'")
end

local function stopMeditationAnim()
    if activeAnimGroup then
        animation.clearAnimationQueue(self, true)
        activeAnimGroup = nil
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CONCENTRATION METER UI
-- ═══════════════════════════════════════════════════════════════════════════

local function createMeterUI()
    if meterElement then meterElement:destroy() end
    local MWUI = I.MWUI
    meterElement = ui.create({
        type  = ui.TYPE.Container,
        layer = 'HUD',
        template = MWUI.templates.boxSolidThick,
        props = {
            relativePosition = v2(0.5, 0),
            anchor           = v2(0.5, 0),
            position         = v2(0, 36),
        },
        content = ui.content {
            {
                name  = 'inner',
                type  = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    align      = ui.ALIGNMENT.Center,
                    arrange    = ui.ALIGNMENT.Center,
                    size       = v2(200, 50),
                    autoSize   = false,
                },
                content = ui.content {
                    {
                        type     = ui.TYPE.Text,
                        template = MWUI.templates.textNormal,
                        props    = {
                            text       = l10n('concentration_label'),
                            textColor  = textColor,
                            textAlignH = ui.ALIGNMENT.Center,
                        },
                    },
                    { props = { size = v2(1, 1) * 2 } },
                    {
                        name  = 'barOuter',
                        type  = ui.TYPE.Widget,
                        template = MWUI.templates.borders,
                        props = { size = v2(180, 8) },
                        content = ui.content {
                            {
                                name  = 'fill',
                                type  = ui.TYPE.Image,
                                props = {
                                    resource     = whiteTex,
                                    color        = barColor,
                                    relativeSize = v2(1, 1),
                                },
                            },
                        },
                    },
                },
            },
        },
    })
end

local function updateMeterUI(ratio, dt)
    if not meterElement or not meterElement.layout then return end
    local fill = meterElement.layout.content.inner.content.barOuter.content.fill
    if ratio <= 0.05 then
        pulseTimer = pulseTimer + dt
        local alpha = 0.3 + 0.7 * math.abs(math.sin(pulseTimer * 3))
        fill.props.relativeSize = v2(math.max(0.01, ratio), 1)
        fill.props.color = barColorLow
        fill.props.alpha = alpha
    else
        pulseTimer = 0
        fill.props.relativeSize = v2(ratio, 1)
        local t = 1 - ratio
        fill.props.color = util.color.rgb(
            barColor.r + t * (barColorLow.r - barColor.r),
            barColor.g + t * (barColorLow.g - barColor.g),
            barColor.b + t * (barColorLow.b - barColor.b)
        )
        fill.props.alpha = 1
    end
    meterElement:update()
end

local function destroyMeterUI()
    if meterElement then
        meterElement:destroy()
        meterElement = nil
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- BLUE SCREEN OVERLAY
-- ═══════════════════════════════════════════════════════════════════════════

local function createOverlay()
    if overlayElement then overlayElement:destroy() end
    overlayElement = ui.create({
        type  = ui.TYPE.Image,
        layer = 'HUD',
        props = {
            resource     = whiteTex,
            color        = overlayColor,
            alpha        = 0,
            relativeSize = v2(1, 1),
        },
    })
end

local function updateOverlayAlpha(alpha)
    if not overlayElement or not overlayElement.layout then return end
    overlayElement.layout.props.alpha = alpha
    overlayElement:update()
end

local function destroyOverlay()
    if overlayElement then
        overlayElement:destroy()
        overlayElement = nil
    end
    overlayAlpha = 0
    overlayFading = 0
end

-- ═══════════════════════════════════════════════════════════════════════════
-- AMBIENT SOUND
-- ═══════════════════════════════════════════════════════════════════════════

local function startMeditationSound()
    soundPlaying = true
    ambient.playSound(MEDITATION_SOUND, {
        volume = SOUND_MAX_VOLUME,
        pitch  = 0.4,
        loop   = true,
    })
end

local function stopMeditationSound()
    if soundPlaying then
        ambient.stopSound(MEDITATION_SOUND)
        soundPlaying = false
    end
end

local function killMeditationSound()
    ambient.stopSound(MEDITATION_SOUND)
    soundPlaying = false
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CAMERA
-- ═══════════════════════════════════════════════════════════════════════════

local function forceThirdPerson()
    savedCameraMode = camera.getMode()
    if savedCameraMode == camera.MODE.FirstPerson then
        camera.setMode(camera.MODE.ThirdPerson, true)
    end
    Player.setControlSwitch(self, Player.CONTROL_SWITCH.ViewMode, false)
end

local function restoreCamera()
    Player.setControlSwitch(self, Player.CONTROL_SWITCH.ViewMode, true)
    if savedCameraMode and savedCameraMode == camera.MODE.FirstPerson then
        camera.setMode(camera.MODE.FirstPerson, true)
    end
    savedCameraMode = nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- MEDITATION START / STOP
-- ═══════════════════════════════════════════════════════════════════════════

local function canStartMeditation()
    if I.UI.getMode() then return false, "Can't meditate in a menu" end
    if types.Actor.getStance(self) ~= types.Actor.STANCE.Nothing then
        return false, "Can't meditate in combat stance"
    end
    if types.Actor.isSwimming(self) then
        return false, "Can't meditate while swimming"
    end
    if types.Actor.isDead(self) then return false end
    if concentrationUsed >= getMaxConcentration() then
        return false, "Your mind is exhausted. You must rest to restore concentration."
    end
    if stats.magicka.current >= stats.magicka.base + stats.magicka.modifier then
        return false, "Magicka is already full"
    end
    return true
end

local function startMeditation()
    local ok, reason = canStartMeditation()
    if not ok then
        if reason then ui.showMessage(reason) end
        return
    end

    meditating = true
    xpTimer    = 0
    pulseTimer = 0
    animRefreshTimer = 0

    lockPlayer()
    forceThirdPerson()

    async:newUnsavableSimulationTimer(0.5, async:callback(function()
        if meditating then playMeditationAnim() end
    end))

    createOverlay()
    overlayAlpha = 0
    overlayFading = 1

    startMeditationSound()

    local maxPool = getMaxConcentration()
    local ratio   = 1 - (concentrationUsed / maxPool)
    createMeterUI()
    updateMeterUI(ratio, 0)

    ambient.playSound("conjuration cast", { volume = 0.3, pitch = 0.6 })

    local remaining = maxPool - concentrationUsed
    print(string.format("MEDITATION: Started (pool=%.1f/%.1fs, rate=%.1f/s)",
        remaining, maxPool, getMagickaRate()))
end

local function stopMeditation(reason)
    if not meditating then return end
    meditating = false

    unlockPlayer()
    stopMeditationAnim()
    restoreCamera()
    overlayFading = -1
    stopMeditationSound()
    destroyMeterUI()

    if reason then ui.showMessage(reason) end

    local maxPool = getMaxConcentration()
    print(string.format("MEDITATION: Stopped (%s). Pool: %.1f/%.1fs",
        reason or "manual", maxPool - concentrationUsed, maxPool))
end

-- ═══════════════════════════════════════════════════════════════════════════
-- INPUT
-- ═══════════════════════════════════════════════════════════════════════════

input.registerTrigger({
    key         = 'MeditationToggle',
    l10n        = 'Meditation',
    name        = 'trigger_meditate_name',
    description = 'trigger_meditate_desc',
})

input.registerTriggerHandler('MeditationToggle', async:callback(function()
    local now = core.getRealTime()
    if now - lastToggleTime < TOGGLE_COOLDOWN then return end
    lastToggleTime = now
    if meditating then
        stopMeditation("Meditation ended")
    else
        startMeditation()
    end
end))

-- ═══════════════════════════════════════════════════════════════════════════
-- PER-FRAME UPDATE
-- ═══════════════════════════════════════════════════════════════════════════

local function onUpdate(dt)
    if dt == 0 then return end

    if needsPostLoadCleanup then
        needsPostLoadCleanup = false
        meditating = false
        unlockPlayer()
        stopMeditationAnim()
        destroyMeterUI()
        destroyOverlay()
        killMeditationSound()
        restoreCamera()
        print("MEDITATION: Post-load cleanup complete")
    end

    if overlayFading ~= 0 then
        if overlayFading == 1 then
            overlayAlpha = math.min(OVERLAY_MAX_ALPHA, overlayAlpha + OVERLAY_FADE_SPEED * dt)
            if overlayAlpha >= OVERLAY_MAX_ALPHA then overlayFading = 0 end
        elseif overlayFading == -1 then
            overlayAlpha = math.max(0, overlayAlpha - OVERLAY_FADE_SPEED * dt)
            if overlayAlpha <= 0 then
                overlayFading = 0
                destroyOverlay()
            end
        end
        updateOverlayAlpha(overlayAlpha)
    end

    -- Passive concentration regen based on willpower.
    -- Rate = REGEN_BASE_RATE + REGEN_WILLPOWER_SCALE * willpower (pool seconds restored per real second).
    -- Time jumps from resting/waiting apply the equivalent hours of regen.
    if concentrationUsed > 0 and not meditating then
        local wp = stats.willpower.modified or 40
        local regenRate = REGEN_BASE_RATE + REGEN_WILLPOWER_SCALE * wp

        local currentGameTime = core.getGameTime()
        local regenDt = dt
        if lastGameTime then
            local elapsed = currentGameTime - lastGameTime
            if elapsed > 3600 then
                local hoursJumped = elapsed / 3600
                regenDt = hoursJumped * 3600 / core.getGameTimeScale()
            end
        end
        lastGameTime = currentGameTime

        local before = concentrationUsed
        concentrationUsed = math.max(0, concentrationUsed - regenRate * regenDt)
        if before > 0 and concentrationUsed <= 0 then
            ui.showMessage("Your concentration is fully restored.")
        end
    else
        lastGameTime = core.getGameTime()
    end

    if not meditating then return end

    if I.UI.getMode() then
        stopMeditation("Meditation interrupted")
        return
    end
    if types.Actor.isDead(self) then
        stopMeditation()
        return
    end

    local maxPool = getMaxConcentration()
    concentrationUsed = concentrationUsed + dt

    if concentrationUsed >= maxPool then
        concentrationUsed = maxPool
        local maxMagicka = stats.magicka.base + stats.magicka.modifier
        stats.magicka.current = math.min(maxMagicka, stats.magicka.current + getMagickaRate() * dt)
        updateMeterUI(0, dt)
        stopMeditation("Concentration depleted")
        return
    end

    local maxMagicka = stats.magicka.base + stats.magicka.modifier
    stats.magicka.current = math.min(maxMagicka, stats.magicka.current + getMagickaRate() * dt)

    if stats.magicka.current >= maxMagicka then
        updateMeterUI(1 - (concentrationUsed / maxPool), dt)
        stopMeditation("Magicka fully restored")
        return
    end

    updateMeterUI(1 - (concentrationUsed / maxPool), dt)

    xpTimer = xpTimer + dt
    if xpTimer >= XP_INTERVAL then
        xpTimer = xpTimer - XP_INTERVAL
        API.skillUsed(skillId, { useType = 1 })
    end

    animRefreshTimer = animRefreshTimer + dt
    if animRefreshTimer >= ANIM_REFRESH_INTERVAL and activeAnimGroup then
        animRefreshTimer = 0
        if not animation.isPlaying(self, activeAnimGroup) then
            animation.clearAnimationQueue(self, false)
            animation.playQueued(self, activeAnimGroup, {
                loops     = 0,
                speed     = 0.25,
                forceLoop = true,
            })
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CONSOLE
-- ═══════════════════════════════════════════════════════════════════════════

local function onConsoleCommand(mode, command)
    local cmd = command:gsub("^%s*[Ll][Uu][Aa]%s+", "")
    local prefix, arg = cmd:match("^(%S+)%s*(%S*)")
    if not prefix then return end
    local kw = prefix:lower()
    if kw ~= "meditate" and kw ~= "meditation" then return end
    local s = API.getSkillStat(skillId)
    if not s then return end
    local level = tonumber(arg)
    if level then
        s.base = math.max(0, math.floor(level))
        ui.showMessage("Meditation skill set to " .. level)
    elseif arg == "reset" then
        concentrationUsed = 0
        ui.showMessage("Concentration pool reset.")
    else
        local maxPool = getMaxConcentration()
        local remaining = maxPool - concentrationUsed
        ui.showMessage(string.format(
            "Meditation: base=%d modified=%d  pool=%.1f/%.1fs  rate=%.1f/s  potential=~%.0f",
            s.base, s.modified, remaining, maxPool, getMagickaRate(),
            remaining * getMagickaRate()))
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SAVE / LOAD
-- ═══════════════════════════════════════════════════════════════════════════

return {
    engineHandlers = {
        onUpdate         = onUpdate,
        onConsoleCommand = onConsoleCommand,

        onKeyPress = function(key)
            local binding = controlsSettings:get('MeditationKeybind')
            if not binding or binding == '' then
                if key.code == DEFAULT_MEDITATION_KEY then
                    input.activateTrigger('MeditationToggle')
                end
            end
        end,

        onSave = function()
            if meditating then stopMeditation() end
            destroyOverlay()
            killMeditationSound()
            return {
                version = 3,
                concentrationUsed = concentrationUsed,
            }
        end,

        onLoad = function(data)
            needsPostLoadCleanup = true
            meditating      = false
            lastGameTime    = nil
            overlayAlpha    = 0
            overlayFading   = 0
            soundPlaying    = false
            savedCameraMode = nil
            if data and (data.version or 0) >= 2 then
                concentrationUsed = data.concentrationUsed or 0
            else
                concentrationUsed = 0
            end
            print(string.format("MEDITATION: Loaded (pool used: %.1fs). Cleanup deferred.", concentrationUsed))
        end,
    },
}