local modInfo           = require('scripts.ngarde.modinfo')
local world             = require('openmw.world')
local types             = require('openmw.types')
local core              = require("openmw.core")
local I                 = require('openmw.interfaces')
local async             = require('openmw.async')
local logging           = require('scripts.ngarde.helpers.logger').new()
local ACTOR_SCRIPT      = 'scripts/ngarde/fencer.lua'
local CREATURE_SCRIPT   = 'scripts/ngarde/creature.lua'
local Helpers           = require('scripts.ngarde.helpers.helpers')
local storage           = require('openmw.storage')
local SettingsConstants = require('scripts.ngarde.helpers.settings_constants')

local playSoundFile3d   = core.sound.playSoundFile3d
local playSound3d       = core.sound.playSound3d
local stopSound3d       = core.sound.stopSound3d
local max               = math.max
logging:setLoglevel(logging.LOG_LEVELS.OFF)

local attachedActorsCache = {}


local function migrateEffectivenessSettings()
    local storageSection = storage.globalSection(SettingsConstants.generalSettingsStorageKey)
    local flag = storageSection:get("effectivenessMigrated")
    if flag == true then return end
    logging:status("Old settings detected. Starting migration")

    local balanceSettings = storage.globalSection(SettingsConstants.balanceSettingsGroupKey)
    balanceSettings:set(SettingsConstants.baseShortBladeOneHandParryEffectivenessKey,
        SettingsConstants.baseShieldParryEffectivenessDefault)
    balanceSettings:set(SettingsConstants.baseLongBladeOneHandParryEffectivenessKey,
        SettingsConstants.baseLongBladeOneHandParryEffectivenessDefault)
    balanceSettings:set(SettingsConstants.baseLongBladeTwoHandParryEffectivenessKey,
        SettingsConstants.baseLongBladeTwoHandParryEffectivenessDefault)
    balanceSettings:set(SettingsConstants.baseBluntOneHandParryEffectivenessKey,
        SettingsConstants.baseBluntOneHandParryEffectivenessDefault)
    balanceSettings:set(SettingsConstants.baseBluntTwoCloseParryEffectivenessKey,
        SettingsConstants.baseBluntTwoCloseParryEffectivenessDefault)
    balanceSettings:set(SettingsConstants.baseBluntTwoWideParryEffectivenessKey,
        SettingsConstants.baseBluntTwoWideParryEffectivenessDefault)
    balanceSettings:set(SettingsConstants.baseSpearTwoWideParryEffectivenessKey,
        SettingsConstants.baseSpearTwoWideParryEffectivenessDefault)
    balanceSettings:set(SettingsConstants.baseAxeOneHandParryEffectivenessKey,
        SettingsConstants.baseAxeOneHandParryEffectivenessDefault)
    balanceSettings:set(SettingsConstants.baseAxeTwoHandParryEffectivenessKey,
        SettingsConstants.baseAxeTwoHandParryEffectivenessDefault)

    logging:status("Old settings migrated")
    storageSection:set("effectivenessMigrated", true)
end


local function onInit()
    migrateEffectivenessSettings()
    return
end
local function onLoad(data)
    migrateEffectivenessSettings()
    return
end

local function parryImpact(params)
    if string.match(params.soundData.path:lower(), "armor") then
        playSound3d(params.soundData.path, params.playSoundAt, params.soundData.options)
    else
        playSoundFile3d(params.soundData.path, params.playSoundAt, params.soundData.options)
    end
    if params.soundData.overlap then
        if params.soundData.overlap == true then
            if string.match(params.baseSoundData.path:lower(), "armor") then
                playSound3d(params.baseSoundData.path, params.playSoundAt, params.baseSoundData.options)
            else
                playSoundFile3d(params.baseSoundData.path, params.playSoundAt, params.baseSoundData.options)
            end
        end
    end
end

local function onParryItemCondition(eventData)
    local ok, itemData = pcall(types.Item.itemData, eventData.item)
    if ok then
        itemData.condition = max(itemData.condition - eventData.damage, 0)
    end
end


local function onCombatTargetChanged(eventData)
    local targetScript = nil
    local scriptString = ""
    if eventData.fencer then
        targetScript = ACTOR_SCRIPT
        scriptString = "FENCER"
    else
        targetScript = CREATURE_SCRIPT
        scriptString = "CREATURE"
    end
    if targetScript then
        logging:debug("got target changed event")
        local actorId = eventData.actor.id
        if #eventData.targets > 0 then
            logging:debug(("ATTACHING %s SCRIPT"):format(scriptString))
            eventData.actor:addScript(targetScript)
            attachedActorsCache[actorId] = eventData.actor
            eventData.actor:sendEvent("ngarde_onScriptAttached", eventData)
        elseif #eventData.targets == 0 then
            logging:debug("Target list is empty")
            if attachedActorsCache[actorId] ~= nil then
                logging:debug(("DETACHING %s SCRIPT"):format(scriptString))
                eventData.actor:sendEvent("ngarde_onScriptDetached")
                async:newUnsavableSimulationTimer(0.5, function() --allow actor to do their own cleanup
                    eventData.actor:removeScript(targetScript)
                    attachedActorsCache[actorId] = nil
                end)
            end
        end
    end
end


local function onStopSFX(eventData)
    stopSound3d(eventData.magicEffect.hitSound, eventData.object)
    stopSound3d(eventData.magicEffect.areaSound, eventData.object)
    stopSound3d(eventData.magicEffect.boltSound, eventData.object)
    for _, player in pairs(world.players) do
        player:sendEvent("ngarde_stopSFXPl", eventData.magicEffect)
    end
end


return {
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
    },
    eventHandlers = {
        ngarde_ParrySuccess = parryImpact,
        ngarde_combatTargetChanged = onCombatTargetChanged,
        ngarde_parryItemCondition = onParryItemCondition,
        ngarde_stopSFX = onStopSFX,
    },
}
