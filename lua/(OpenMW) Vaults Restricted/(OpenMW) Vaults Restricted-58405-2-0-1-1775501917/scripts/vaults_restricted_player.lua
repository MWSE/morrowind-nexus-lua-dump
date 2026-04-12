local I       = require('openmw.interfaces')
local self    = require('openmw.self')
local ui      = require('openmw.ui')
local nearby  = require('openmw.nearby')
local storage = require('openmw.storage')
local async   = require('openmw.async')
local core    = require('openmw.core')

local shared   = require('scripts.vaults_shared')
local DEFAULTS = shared.DEFAULTS

local section = storage.playerSection('SettingsVaultsRestricted')

local function get(key)
    local val = section:get(key)
    if val == nil then return DEFAULTS[key] end
    return val
end

local cachedSettings = {
    MOD_ENABLED         = get('MOD_ENABLED'),
    COUNTDOWN           = get('COUNTDOWN'),
    WITNESS_RADIUS      = get('WITNESS_RADIUS'),
    BOUNTY_AMOUNT       = get('BOUNTY_AMOUNT'),
    CHAMELEON_THRESHOLD = get('CHAMELEON_THRESHOLD'),
    SNEAK_THRESHOLD     = get('SNEAK_THRESHOLD'),
    SIGN_COMPAT         = get('SIGN_COMPAT'),
}

local function broadcastSettings()
    core.sendGlobalEvent('VaultsRestricted_SettingsUpdated', {
        MOD_ENABLED         = cachedSettings.MOD_ENABLED,
        COUNTDOWN           = cachedSettings.COUNTDOWN,
        WITNESS_RADIUS      = cachedSettings.WITNESS_RADIUS,
        BOUNTY_AMOUNT       = cachedSettings.BOUNTY_AMOUNT,
        CHAMELEON_THRESHOLD = cachedSettings.CHAMELEON_THRESHOLD,
        SNEAK_THRESHOLD     = cachedSettings.SNEAK_THRESHOLD,
        SIGN_COMPAT         = cachedSettings.SIGN_COMPAT,
    })
end

section:subscribe(async:callback(function()
    for k in pairs(cachedSettings) do
        cachedSettings[k] = get(k)
    end
    broadcastSettings()
end))

local lastMsg  = ""
local msgTimer = 0
local wasSneak = false

local function resolveIsSneaking()
    if cachedSettings.SIGN_COMPAT then
        local signIface = I.SneakIsGoodNow
        if signIface and signIface.playerState then
            return signIface.playerState.isSneaking == true
        end
        -- SIGN enabled in settings but mod not installed: treat as not sneaking
        return false
    end
    return self.controls.sneak
end

return {
    engineHandlers = {
        onInit = function()
            broadcastSettings()
        end,
        onLoad = function()
            broadcastSettings()
        end,
        onUpdate = function(dt)
            msgTimer = math.max(0, msgTimer - dt)

            local isSneak = resolveIsSneaking()
            if isSneak ~= wasSneak then
                wasSneak = isSneak
                for _, actor in ipairs(nearby.actors) do
                    actor:sendEvent("PlayerSneakChanged", { sneaking = isSneak })
                end
            end
        end,
    },
    eventHandlers = {
        GuardWarning = function(data)
            if data.message ~= lastMsg or msgTimer <= 0 then
                ui.showMessage(data.message)
                lastMsg  = data.message
                msgTimer = 0.5
            end
        end,
    },
}