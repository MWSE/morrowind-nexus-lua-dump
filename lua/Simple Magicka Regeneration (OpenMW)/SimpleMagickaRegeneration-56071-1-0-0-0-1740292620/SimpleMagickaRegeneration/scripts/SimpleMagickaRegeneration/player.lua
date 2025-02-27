local self = require('openmw.self')
local storage = require('openmw.storage')
local time = require('openmw_aux.time')
local core = require('openmw.core')
local types = require('openmw.types')

require('scripts.SimpleMagickaRegeneration.settings')
local settings = storage.playerSection('SettingsSimpleMagickaRegeneration')

local function getAttributeSetting()
    if settings:get('usewillpower') then
        return 'willpower'
    else 
        return 'intelligence'
    end
end

local function getCurrentPlayerMagicka()
    return types.Player.stats.dynamic.magicka(self).current
end

local function getMaxPlayerMagicka()
    return types.Player.stats.dynamic.magicka(self).base + types.Player.stats.dynamic.magicka(self).modifier
end

local function isFullMagicka()
    return getCurrentPlayerMagicka() == getMaxPlayerMagicka()
end

local function getAttribute()
    return types.Player.stats.attributes[getAttributeSetting()](self).base + types.Player.stats.attributes[getAttributeSetting()](self).modifier
end

local function modPlayerMagicka(amount)
    local total = getCurrentPlayerMagicka() + amount
    if total > getMaxPlayerMagicka() then
        total = getMaxPlayerMagicka()
    end
    types.Player.stats.dynamic.magicka(self).current = total
end

local function regen()
    local amount = (getAttribute() * settings:get('attributemod')) / 60 * core.getGameTimeScale() * settings:get('magickaregenmulti')
    modPlayerMagicka(amount)
end


local cachedMagicka = getCurrentPlayerMagicka()
local lastRegenTime = core.getGameTime()
local hitDelayActive = true
local hitDelayOffTime = core.getGameTime() + 2 * core.getGameTimeScale()

local function onUpdate()

    --always track damage
    if getCurrentPlayerMagicka() < cachedMagicka then
        hitDelayOffTime = core.getGameTime() + settings:get('delay') * core.getGameTimeScale()
        hitDelayActive = true
    end

    --if delay time passed set the flag
    if hitDelayActive and core.getGameTime() > hitDelayOffTime then
        hitDelayActive = false
    end

    if isFullMagicka() == false and hitDelayActive == false and core.getGameTime() > lastRegenTime then
        lastRegenTime = core.getGameTime() + time.second * core.getGameTimeScale()
        regen()
    end

    cachedMagicka = getCurrentPlayerMagicka()
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    }
}