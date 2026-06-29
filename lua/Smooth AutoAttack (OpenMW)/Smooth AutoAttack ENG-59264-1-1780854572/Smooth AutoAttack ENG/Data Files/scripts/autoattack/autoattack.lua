-- AutoAttack для OpenMW 0.50+
-- Toggle auto-attack: Middle Mouse Button (настраивается в Скрипты → AutoAttack)
-- Toggle attack type:  ' (настраивается в Скрипты → AutoAttack)

local async   = require('openmw.async')
local input   = require('openmw.input')
local self    = require('openmw.self')
local I       = require('openmw.interfaces')
local types   = require('openmw.types')
local anim    = require('openmw.animation')
local ui      = require('openmw.ui')
local util    = require('openmw.util')
local storage = require('openmw.storage')
local Actor   = types.Actor

local FOLLOW_BASE_DURATION  = 1.0
local DRAW_BASE_DURATION    = 0.367
local FOLLOW_ACCEL_DURATION = 0.033
local FASTEST_COOLDOWN      = 0.15

-- ── Storage ───────────────────────────────────────────────────────────────────
local DEFAULTS = {
    attackType     = 'FullCharged',
    smoothArbalest = true,
    bindToggle     = 'mouse2',
    bindType       = 'Bksl',
}

local function getSetting(key)
    local ok, val = pcall(function()
        return storage.playerSection('SettingsAutoAttack'):get(key)
    end)
    if ok and val ~= nil then return val end
    return DEFAULTS[key]
end

local currentAttackType = nil  -- initialized on first getSetting call
local menuOpen = false  -- suppresses actions while keybind menu is waiting
local menuOpenCooldown = 0  -- frames to keep menuOpen after clearWaiting

-- ── Per-weapon on/off state ────────────────────────────────────────────────────
local weaponAutoOn = {}

local function getWeaponId()
    local slot = Actor.equipment(self)
    local w = slot and slot[Actor.EQUIPMENT_SLOT.CarriedRight]
    if not w then return '__fist__' end
    local ok, rec = pcall(types.Weapon.record, w)
    if ok and rec and rec.id then return rec.id end
    return '__fist__'
end

local function isAutoOn()
    local v = weaponAutoOn[getWeaponId()]
    if v == nil then return true end
    return v
end

local function setAutoOn(v) weaponAutoOn[getWeaponId()] = v end

-- ── Notification ──────────────────────────────────────────────────────────────
local function notify(text)
    pcall(function() ui.showMessage(text) end)
end

-- ── Toggle actions ────────────────────────────────────────────────────────────
local function ensureInit()
    if currentAttackType == nil then
        currentAttackType = getSetting('attackType')
    end
end

local function doToggleAutoAttack()
    if menuOpen then return end
    ensureInit()
    local newState = not isAutoOn()
    setAutoOn(newState)
    local typeStr = (currentAttackType == 'Fastest') and 'Fastest' or 'Full Charged'
    notify(newState and ('Auto-Attack ON  |  ' .. typeStr) or 'Auto-Attack OFF')
end

local function doToggleAttackType()
    if menuOpen then return end
    ensureInit()
    currentAttackType = (currentAttackType == 'FullCharged') and 'Fastest' or 'FullCharged'
    -- Reset attack cycle so new mode takes effect immediately
    maxAttackReached = false
    releaseNextFrame = true  -- force NoAttack next frame to interrupt current swing
    fastestTimer     = 0.0
    local typeStr = (currentAttackType == 'Fastest') and 'Fastest' or 'Full Charged'
    notify('Attack Type: ' .. typeStr .. '  |  Auto-Attack ' .. (isAutoOn() and 'ON' or 'OFF'))
end

-- ── Custom keyBinding renderer ────────────────────────────────────────────────
-- value = string key identifier (e.g. 'mouse2', "'", 'f', etc.)
-- Displays a button; click to enter "Press a key..." state, then captures next key.

local waitingForKey = {}  -- [settingKey] = set_function, signals we're capturing

local function makeKeyLabel(value)
    if value == 'mouse2' then return 'Mouse 3'
    elseif value == 'mouse1' then return 'Mouse 2'
    elseif value == 'mouse3' then return 'Mouse 4'
    else return value ~= '' and value or '---' end
end

I.Settings.registerRenderer('keyBinding', function(value, set, arg)
    local settingKey = arg and arg.settingKey or 'unknown'
    local isWaiting = waitingForKey[settingKey] ~= nil

    local btnText = isWaiting and '...' or makeKeyLabel(value)

    return {
        type = ui.TYPE.Text,
        props = {
            text           = '[' .. btnText .. ']',
            textSize       = 15,
            textColor      = isWaiting
                             and util.color.rgb(1, 1, 0)
                             or  util.color.rgb(0.8, 0.8, 0.8),
        },
        events = {
            mouseClick = async:callback(function()
                if not isWaiting then
                    waitingForKey[settingKey] = set
                    -- Force re-render by setting same value (triggers renderer refresh)
                    -- We'll update via onKeyPress instead
                end
            end),
        },
    }
end)

-- ── Settings registration ─────────────────────────────────────────────────────
I.Settings.registerPage({
    key         = 'AutoAttack',
    l10n        = 'autoattack',
    name        = 'page_name',
    description = 'page_desc',
})

I.Settings.registerGroup({
    key              = 'SettingsAutoAttack',
    page             = 'AutoAttack',
    l10n             = 'autoattack',
    name             = 'group_name',
    description      = 'group_desc',
    permanentStorage = true,
    settings = {
        {
            key         = 'attackType',
            l10n        = 'autoattack',
            name        = 'attackType_name',
            description = 'attackType_desc',
            default     = 'FullCharged',
            renderer    = 'select',
            argument    = {
                l10n  = 'autoattack',
                items = { 'FullCharged', 'Fastest' },
            },
        },
        {
            key         = 'smoothArbalest',
            l10n        = 'autoattack',
            name        = 'smoothArbalest_name',
            description = 'smoothArbalest_desc',
            default     = true,
            renderer    = 'checkbox',
            argument    = {},
        },
        {
            key         = 'bindToggle',
            l10n        = 'autoattack',
            name        = 'bind_toggle_name',
            description = 'bind_toggle_desc',
            default     = 'mouse2',
            renderer    = 'keyBinding',
            argument    = { settingKey = 'bindToggle' },
        },
        {
            key         = 'bindType',
            l10n        = 'autoattack',
            name        = 'bind_type_name',
            description = 'bind_type_desc',
            default     = 'Bksl',
            renderer    = 'keyBinding',
            argument    = { settingKey = 'bindType' },
        },
    },
})

-- ── Crossbow smooth follow ────────────────────────────────────────────────────
local inCrossbowFollow = false
local inCrossbowDraw   = false

I.AnimationController.addPlayBlendedAnimationHandler(function(groupname, options)
    if groupname ~= 'crossbow' then return end
    local sk = options.startkey or options.startKey or ''
    if sk ~= 'shoot follow start' then return end
    if not getSetting('smoothArbalest') then return end
    options.skip = true
    anim.playBlended(self, 'crossbow', {
        startkey = options.startkey, stopkey = options.stopkey,
        startKey = options.startKey, stopKey = options.stopKey,
        priority = options.priority,
        blendMask = 0, speed = 9999, loops = 0, autoDisable = true,
    })
end)

I.AnimationController.addTextKeyHandler('crossbow', function(_, key)
    if key == 'shoot start'       then inCrossbowFollow = false; inCrossbowDraw = false end
    if key == 'shoot min attack'  then inCrossbowDraw = true end
    if key == 'shoot release'     then inCrossbowFollow = true; inCrossbowDraw = false end
    if key == 'shoot follow stop' then inCrossbowFollow = false end
end)

-- ── Attack loop ───────────────────────────────────────────────────────────────
local maxAttackReached  = false
local releaseNextFrame  = false
local combatOverridden  = false
local fastestTimer      = 0.0

local function setCombatOverride(v)
    if combatOverridden ~= v then
        combatOverridden = v
        I.Controls.overrideCombatControls(v)
    end
end

I.AnimationController.addTextKeyHandler('', function(_, key)
    if key:sub(#key - 9) == 'max attack' then maxAttackReached = true end
end)

local function getCrossbowSpeed()
    local slot = Actor.equipment(self)
    local w = slot and slot[Actor.EQUIPMENT_SLOT.CarriedRight]
    if not w then return 1.0 end
    local ok, rec = pcall(types.Weapon.record, w)
    if not ok or not rec then return 1.0 end
    return rec.speed or 1.0
end

local scancodeNames = {
    [40]='Enter',[43]='Tab',[57]='CapsLk',
    [58]='F1',[59]='F2',[60]='F3',[61]='F4',[62]='F5',
    [63]='F6',[64]='F7',[65]='F8',[66]='F9',[67]='F10',
    [68]='F11',[69]='F12',
    [73]='Ins',[76]='Del',[75]='PgUp',[78]='PgDn',
    [74]='Home',[77]='End',
    [79]='Right',[80]='Left',[81]='Down',[82]='Up',
    [224]='LCtrl',[225]='LShift',[226]='LAlt',
    [229]='RShift',[230]='RAlt',
    [45]='Minus',[46]='Equal',
    [47]='LBrk',[48]='RBrk',[49]='Bksl',
    [51]='Semi',[52]='Apos',[53]='Grave',
    [54]='Comma',[55]='Period',[56]='Slash',
}

local function normalizeKey(sym, code)
    if scancodeNames[code] then return scancodeNames[code] end
    if sym ~= nil and sym ~= '' then
        local b = string.byte(sym, 1)
        if b ~= nil and b >= 32 and b < 127 then
            if sym == ' ' then return 'Space' end
            return string.upper(sym)
        end
    end
    return nil
end

local function onKeyPress(key)
    print("[AA] onKeyPress sym=" .. tostring(key.symbol) .. " code=" .. tostring(key.code) .. " menuOpen=" .. tostring(menuOpen))
    local val = normalizeKey(key.symbol, key.code)
    print("[AA] onKeyPress val=" .. tostring(val))
    if val == nil then return end
    local bindType = getSetting('bindType')
    if val == bindType then doToggleAttackType() end
    local bindToggle = getSetting('bindToggle')
    if val == bindToggle then doToggleAutoAttack() end
end

local function onFrame(dt)
    if currentAttackType == nil then
        currentAttackType = getSetting('attackType')
    end

    -- Cooldown: keep menuOpen for a few frames after assignment to suppress stray clicks
    if menuOpenCooldown > 0 then
        menuOpenCooldown = menuOpenCooldown - 1
        if menuOpenCooldown == 0 then
            menuOpen = false
        end
    end

    local stance = Actor.getStance(self)

    if stance == Actor.STANCE.Spell then
        setCombatOverride(false)
        return
    end

    local lmbHeld = input.isMouseButtonPressed(1)

    if not lmbHeld or stance ~= Actor.STANCE.Weapon then
        setCombatOverride(false)
        maxAttackReached  = false
        releaseNextFrame  = false
        fastestTimer      = 0.0
        inCrossbowFollow  = false
        inCrossbowDraw    = false
        return
    end

    if not isAutoOn() then
        setCombatOverride(false)
        return
    end

    setCombatOverride(true)

    if getSetting('smoothArbalest') then
        if inCrossbowFollow then
            anim.setSpeed(self, 'crossbow', 9999)
        end
        if inCrossbowDraw then
            local wSpeed = getCrossbowSpeed()
            local fn = FOLLOW_BASE_DURATION / wSpeed
            local dn = DRAW_BASE_DURATION   / wSpeed
            local df = dn / (dn + fn - FOLLOW_ACCEL_DURATION)
            anim.setSpeed(self, 'crossbow', df)
        end
    end

    if currentAttackType == 'Fastest' then
        fastestTimer = fastestTimer + dt
        if releaseNextFrame then
            self.controls.use = self.ATTACK_TYPE.NoAttack
            releaseNextFrame  = false
            maxAttackReached  = false
        elseif fastestTimer >= FASTEST_COOLDOWN then
            fastestTimer     = 0.0
            releaseNextFrame = true
            self.controls.use = self.ATTACK_TYPE.Any
        else
            self.controls.use = self.ATTACK_TYPE.Any
        end
    else
        if releaseNextFrame then
            self.controls.use = self.ATTACK_TYPE.NoAttack
            releaseNextFrame  = false
            maxAttackReached  = false
        elseif maxAttackReached then
            releaseNextFrame = true
            self.controls.use = self.ATTACK_TYPE.Any
        else
            self.controls.use = self.ATTACK_TYPE.Any
        end
    end
end

local function onGlobalEvent(event, data)
    if event == 'AutoAttackMenuWaiting' then
        menuOpen = data == true
    end
end

local function onMouseButtonPress(btn)
    if menuOpen then return end
    local mouseMap = { [1]='mouse1', [2]='mouse2', [3]='mouse3', [4]='mouse4', [5]='mouse5' }
    local val = mouseMap[btn]
    if val == nil then return end
    local bindToggle = getSetting('bindToggle')
    if val == bindToggle then doToggleAutoAttack() end
    local bindType = getSetting('bindType')
    if val == bindType then doToggleAttackType() end
end

return { engineHandlers = { onFrame = onFrame, onKeyPress = onKeyPress, onMouseButtonPress = onMouseButtonPress }, eventHandlers = {
    AutoAttackMenuWaiting = function(data)
        if data == true then
            menuOpen = true
            menuOpenCooldown = 30
        else
            -- Keep menuOpen=true during cooldown to suppress stray mouse events
            menuOpen = true
            menuOpenCooldown = 30
        end
    end
} }
