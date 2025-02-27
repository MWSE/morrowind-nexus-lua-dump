local self = require('openmw.self')
local storage = require('openmw.storage')
local time = require('openmw_aux.time')
local core = require('openmw.core')
local types = require('openmw.types')

require('scripts.SimpleHealthRegeneration.settings')
local settings = storage.playerSection('SettingsSimpleHealthRegeneration')

local function getCurrentPlayerHealth()
    return types.Player.stats.dynamic.health(self).current
end

local function getMaxPlayerHealth()
    return types.Player.stats.dynamic.health(self).base + types.Player.stats.dynamic.health(self).modifier
end

local function isFullHealth()
    return getCurrentPlayerHealth() == getMaxPlayerHealth()
end

local function getEndurance()
    return types.Player.stats.attributes['endurance'](self).base + types.Player.stats.attributes['endurance'](self).modifier
end

local function modPlayerHealth(amount)
    local total = getCurrentPlayerHealth() + amount
    if total > getMaxPlayerHealth() then
        total = getMaxPlayerHealth()
    end
    types.Player.stats.dynamic.health(self).current = total
end

local function regen()
    local amount = (getEndurance() * settings:get('endurancemod')) / 60 * core.getGameTimeScale() * settings:get('healthregenmulti')
    modPlayerHealth(amount)
end


local cachedHealth = getCurrentPlayerHealth()
local lastRegenTime = core.getGameTime()
local hitDelayActive = true
local hitDelayOffTime = core.getGameTime() + 2 * core.getGameTimeScale()

local function onUpdate()

    --always track damage
    if getCurrentPlayerHealth() < cachedHealth then
        hitDelayOffTime = core.getGameTime() + settings:get('hitdelay') * core.getGameTimeScale()
        hitDelayActive = true
    end

    --if delay time passed set the flag
    if hitDelayActive and core.getGameTime() > hitDelayOffTime then
        hitDelayActive = false
    end

    if isFullHealth() == false and hitDelayActive == false and core.getGameTime() > lastRegenTime then
        lastRegenTime = core.getGameTime() + time.second * core.getGameTimeScale()
        regen()
    end

    cachedHealth = getCurrentPlayerHealth()
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    }
}