local T = require('openmw.types')
local I = require("openmw.interfaces")
local core = require('openmw.core')
local self = require('openmw.self')
local ui = require('openmw.ui')
local time = require('openmw_aux.time')
local debug = require('openmw.debug')

local mDef = require('scripts.HBFS.config.definition')
if not mDef.isOpenMW49OrAbove then return end
local mStore = require('scripts.HBFS.config.store')
local mTools = require('scripts.HBFS.util.tools')
local log = require('scripts.HBFS.util.log')

I.Settings.registerPage {
    key = mDef.MOD_NAME,
    l10n = mDef.MOD_NAME,
    name = "name",
    description = "description",
}

local settings = {}
for key, setting in pairs(mStore.settings) do
    if setting.section.key == mStore.sections.player.key then
        settings[key] = setting.get()
    end
end

local l10n = core.l10n(mDef.MOD_NAME)
local actorId = mTools.actorId(self)
local health = T.Actor.stats.dynamic.health(self)
local lastStolenItemsUpdate = 0
local lastTalkingGuard
local lastBounty = 0
local itemConditions = {}
local lastUiModeTarget

local GMSTs = {
    fMagicSunBlockedMult = core.getGMST("fMagicSunBlockedMult"),
    Weather_Sunrise_Time = core.getGMST("Weather_Sunrise_Time") or 6,
    Weather_Sunset_Time = core.getGMST("Weather_Sunset_Time") or 18,
    Weather_Sunrise_Duration = core.getGMST("Weather_Sunrise_Duration") or 2,
    Weather_Sunset_Duration = core.getGMST("Weather_Sunset_Duration") or 2,
}

local healthDamagingEffectIds = {
    [core.magic.EFFECT_TYPE.DrainHealth] = true,
    [core.magic.EFFECT_TYPE.DamageHealth] = true,
    [core.magic.EFFECT_TYPE.AbsorbHealth] = true,
    [core.magic.EFFECT_TYPE.FireDamage] = true,
    [core.magic.EFFECT_TYPE.FrostDamage] = true,
    [core.magic.EFFECT_TYPE.ShockDamage] = true,
    [core.magic.EFFECT_TYPE.Poison] = true,
    [core.magic.EFFECT_TYPE.SunDamage] = true,
}

local state = {
    effectDamage = { time = 0, drain = 0 },
    guardOwnedItems = {},
    stolenGuardItems = {},
}

local function getSunRisen()
    local hour = (core.getGameTime() % time.day) / time.hour
    if hour <= GMSTs.Weather_Sunrise_Time or hour >= GMSTs.Weather_Sunset_Time + GMSTs.Weather_Sunset_Duration then
        return 0
    elseif hour <= GMSTs.Weather_Sunrise_Time + GMSTs.Weather_Sunrise_Duration then
        return (hour - GMSTs.Weather_Sunrise_Time) / GMSTs.Weather_Sunrise_Duration
    elseif hour > GMSTs.Weather_Sunset_Time then
        return 1 - (hour - GMSTs.Weather_Sunset_Time) / GMSTs.Weather_Sunset_Duration
    end
    return 1
end

local function damageHealth(damage)
    health.current = math.min(health.current - damage, math.max(health.base, health.current))
end

local function changeMagicDamageTaken(deltaTime)
    if debug.isGodMode()
            or settings[mStore.settings.magicDamagePercent.key].actual == 100
            and settings[mStore.settings.sunDamagePercent.key].actual == 100 then return end

    state.effectDamage.time = state.effectDamage.time + deltaTime
    if state.effectDamage.time < 0.1 then return end
    local duration = state.effectDamage.time
    state.effectDamage.time = 0

    local magicDamageSum = 0
    local sunDamageSum = 0
    local drainDamage = 0
    local numEffects = 0
    for _, effect in pairs(T.Actor.activeEffects(self)) do
        if healthDamagingEffectIds[effect.id] then
            numEffects = numEffects + 1
            local magnitude = math.max(0, effect.magnitude)
            if effect.id == core.magic.EFFECT_TYPE.DrainHealth then
                drainDamage = magnitude
            elseif effect.id == core.magic.EFFECT_TYPE.SunDamage then
                if self.cell.isExterior or self.cell:hasTag("QuasiExterior") then
                    local sunRisen = getSunRisen()
                    local sunVisibility = core.weather.getCurrentSunVisibility(self.cell)
                    sunDamageSum = sunDamageSum + magnitude * math.min(1, math.max(0, math.max(sunVisibility * sunRisen, GMSTs.fMagicSunBlockedMult * sunRisen)))
                end
            else
                magicDamageSum = magicDamageSum + magnitude
            end
        end
    end

    -- Drain health value changed: Update player health (increase, reduce, cancel drain)
    if drainDamage ~= state.effectDamage.drain then
        local damage = ((settings[mStore.settings.magicDamagePercent.key].actual - 100) / 100) * (drainDamage - state.effectDamage.drain)
        damageHealth(damage)
        log(string.format("%s adding %.2f drain health damage to base %.2f", actorId, damage, drainDamage))
        state.effectDamage.drain = drainDamage
    end

    if magicDamageSum ~= 0 or sunDamageSum ~= 0 then
        local damage = ((settings[mStore.settings.magicDamagePercent.key].actual - 100) / 100) * duration * magicDamageSum
                + ((settings[mStore.settings.sunDamagePercent.key].actual - 100) / 100) * duration * sunDamageSum
        damageHealth(damage)
        log(string.format("%s taken magic damage was %s by %.2f from %d effect(s) over %.2f seconds",
                actorId, (damage > 0) and "increased" or "reduced", damage, numEffects, duration))
    end
end

local function noBackRunning()
    if not settings[mStore.settings.noBackRunning.key] then return end
    if T.Actor.getStance(self) ~= T.Actor.STANCE.Nothing and self.controls.run == true and self.controls.movement < 0 then
        self.controls.run = false
    end
end

local function checkStolenItems(deltaTime)
    if not settings[mStore.settings.deadGuardItemPickingIsCrime.key] then return end
    lastStolenItemsUpdate = lastStolenItemsUpdate + deltaTime
    if lastStolenItemsUpdate < 1 then return end
    lastStolenItemsUpdate = 0

    local inventory = self.type.inventory(self)
    for _, item in ipairs(inventory:getAll()) do
        if state.guardOwnedItems[item.id] then
            local value = item.type.record(item).value or 1
            core.sendGlobalEvent(mDef.events.commitTheft, { player = self, value = value })
            state.guardOwnedItems[item.id] = nil
            state.stolenGuardItems[item.id] = item
        end
    end
end

local function setGuardOwnedItems(guard)
    for _, item in ipairs(guard.type.inventory(guard):getAll()) do
        if not mTools.isGold(item.recordId) then
            state.guardOwnedItems[item.id] = true
        end
    end
end

local function onUpdate(deltaTime)
    if deltaTime == 0 then return end
    changeMagicDamageTaken(deltaTime)
end

local function onFrame(deltaTime)
    noBackRunning() -- doesn't work with onUpdate
    checkStolenItems(deltaTime)
end

local function showMessage(message)
    ui.showMessage(message)
end

local function updateSetting(key, value)
    settings[key] = value
end

local function hideUnfixableItems()
    local itemUpdates = {}
    for _, type in ipairs({ T.Weapon, T.Armor }) do
        for _, item in ipairs(self.type.inventory(self):getAll(type)) do
            local condition = T.Item.itemData(item).condition
            if condition then
                local maxCondition = math.max(1, item.type.record(item).health or 1)
                local armorer = T.NPC.stats.skills.armorer(self).modified
                if -(armorer / 100) ^ 0.5 + 1 > condition / maxCondition then
                    table.insert(itemUpdates, { item = item, condition = maxCondition })
                    table.insert(itemConditions, { item = item, condition = condition })
                end
            end
        end
    end
    if #itemUpdates > 0 then
        core.sendGlobalEvent(mDef.events.modItemCondition, { updates = itemUpdates, refreshUi = { player = self, mode = "Repair", target = lastUiModeTarget } })
        if #itemUpdates == 1 then
            showMessage(l10n("unfixableItem"))
        else
            showMessage(l10n("unfixableItems", { count = #itemUpdates }))
        end
    end
end

local function uiModeChanged(oldMode, newMode, target)
    if oldMode == newMode then return end
    lastUiModeTarget = target
    log(string.format('UI mode changed from %s to %s (%s)', oldMode, newMode, target))
    if not oldMode and newMode == "Dialogue" and target and target.type.record(target).class == "guard" then
        log(string.format("Talking to guard \"%s\"", target.recordId))
        lastTalkingGuard = target
        lastBounty = T.Player.getCrimeLevel(self)
        return
    end
    if oldMode == "Dialogue" and not newMode and lastTalkingGuard and lastBounty > 0 then
        if T.Player.getCrimeLevel(self) == 0 then
            log(string.format("Bounty paid to guard \"%s\"", lastTalkingGuard.recordId))
            for itemId, item in pairs(state.stolenGuardItems) do
                if item.parentContainer and item.parentContainer.id == self.id then
                    core.sendGlobalEvent(mDef.events.moveItem, { item = item, actor = lastTalkingGuard })
                    state.stolenGuardItems[itemId] = nil
                end
            end
            lastBounty = 0
        else
            log(string.format("Bounty not paid to guard \"%s\"", lastTalkingGuard.recordId))
        end
    end
    if not oldMode then
        lastTalkingGuard = nil
    end
    if settings[mStore.settings.minimumConditionRepairRequirement.key] then
        if newMode == "Repair" then
            hideUnfixableItems()
        elseif oldMode == "Repair" then
            if #itemConditions > 0 then
                core.sendGlobalEvent(mDef.events.modItemCondition, { updates = itemConditions })
                itemConditions = {}
            end
        end
    end
    if newMode == "Container" then
        core.sendGlobalEvent(mDef.events.onOpenContainer, target)
    end
end

local function refreshUiMode(mode, target)
    I.UI.removeMode(mode)
    I.UI.addMode(mode, { target = target })
end

local function addOnHitHandler()
    local handler = function(attack)
        if attack.successful and attack.damage.health and (attack.sourceType == "melee" or attack.sourceType == "ranged") then
            local factor = settings[mStore.settings.physicalDamagePercent.key].actual / 100
            log(string.format("%s taken physical damage was %.2f, altered to %.2f", actorId, attack.damage.health, attack.damage.health * factor))
            attack.damage.health = attack.damage.health * factor
        end
    end
    if I.SkillEvolution and I.SkillEvolution.addOnHitHandler then
        I.SkillEvolution.addOnHitHandler(handler)
    elseif I.Combat then
        I.Combat.addOnHitHandler(handler)
    end
end

local function onInit()
    addOnHitHandler()
end

local function onSave()
    return {
        state = state,
        version = mDef.gameSaveVersion,
    }
end

local function onLoad(data)
    if data then
        if data.version < 2.1 then
            data.state.guardOwnedItems = {}
            data.state.stolenGuardItems = {}
        end
        state = data.state
    end
    addOnHitHandler()
end

return {
    interfaceName = mDef.MOD_NAME,
    interface = {
        version = mDef.interfaceVersion,
    },
    eventHandlers = {
        UiModeChanged = function(data) uiModeChanged(data.oldMode, data.newMode, data.arg) end,
        [mDef.events.showMessage] = showMessage,
        [mDef.events.refreshUiMode] = function(data) refreshUiMode(data.mode, data.target) end,
        [mDef.events.updatePlayerSetting] = function(data) updateSetting(data.key, data.value) end,
        [mDef.events.setGuardOwnedItems] = setGuardOwnedItems,
    },
    engineHandlers = {
        onUpdate = onUpdate,
        onFrame = onFrame,
        onInit = onInit,
        onSave = onSave,
        onLoad = onLoad,
    },
}