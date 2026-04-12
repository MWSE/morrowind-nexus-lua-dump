-- devilish_wabbajack_npc.lua
-- Path: scripts/devilish_wabbajack_npc.lua

local self  = require('openmw.self')
local types = require('openmw.types')
local time  = require('openmw_aux.time')
local core  = require('openmw.core')
local anim  = require('openmw.animation')
local AI    = require('openmw.interfaces').AI

local ITEM_LISTS = require('scripts.detd_randomItemLists')

local knockback = require('scripts.detd_wabbajack_knockback').init{
    magnitude = 90,
    verticalFactor = 2.95,
    bounceAmount = 0.18,
    maxBounces = 1,
    adjustByAttackPower = false,
    airborneThreshold = 80,
    landedEventName = 'detd_KnockbackLanded',
    radius = 24,
    indoorRadius = 12,
    outdoorRayMultiplier = 3.0,
    indoorRayMultiplier = 1.15,
    indoorMagnitudeMultiplier = 0.35,
    indoorVerticalMultiplier = 0.35,
}

local POLL_INTERVAL = 0.25 * time.second
local wasTransformed = false
local doOnce = false

local DANCES = {
    'NorthernSoulSpin',
    'bellydance'
}

local ELEMENTAL_SPELLS = {
    'summon golden saint',
}

local function applyRandomElementalDamage()
    local spellId = ELEMENTAL_SPELLS[math.random(#ELEMENTAL_SPELLS)]

    types.Actor.activeSpells(self):add({
        id = spellId,
        effects = { 0 },
        stackable = true,
        caster = self,
    })
end

local function applyRandomSpellEffect()
    local which = math.random(3)

    if which == 1 then
        print("invisibility")
        types.Actor.activeSpells(self):add({
            id = 'invisibility',
            effects = { 0 },
        })
    elseif which == 2 then
        print("paralysis")
        types.Actor.activeSpells(self):add({
            id = 'Paralysis',
            effects = { 0 },
        })
    else
        print("elemental damage")
        applyRandomElementalDamage()
    end
end

local function rollEffect()
    local roll = math.random()

    if roll < 0.216 then
        print("transform")
        return 1

    elseif roll < 0.432 then
        print("dance")
        return 4

    elseif roll < 0.648 then
        print("knockback")
        return 9

    elseif roll < 0.798 then
        print("spell effect")
        return 2

    elseif roll < 0.848 then
        print("change clothes")
        return 5

    elseif roll < 0.898 then
        print("weather")
        return 10

    else
        local rare = math.random(3)

        if rare == 1 then
            print("clone")
            return 6
        elseif rare == 2 then
            print("scale")
            return 8
        else
            print("disposition")
            return 7
        end
    end
end

local function disableSelf()
    core.sendGlobalEvent('detd_DisableActor', { obj2 = self })
end

local function isWabbaActive()
    return types.Actor.activeSpells(self):isSpellActive('T_Dae_UNI_Wabbajack')
end

local function chooseReplacementItems()
    local replacements = {}

    for key, entry in pairs(ITEM_LISTS) do
        local equipped = types.Actor.getEquipment(self, entry.slot)
        local ids = entry.ids
        if equipped and ids and #ids > 0 then
            replacements[key] = ids[math.random(#ids)]
        end
    end

    return replacements
end

local function handleScaleOption()
    local s = self.scale
    core.sendGlobalEvent('detd_rememberBaseline', { obj = self })

    if s < 0.75 then
        core.sendGlobalEvent('detd_StartGradualGrow', { obj = self })
        core.sendGlobalEvent('detd_WabbaReset', { obj = self })

    elseif s > 1.50 then
        core.sendGlobalEvent('detd_StartGradualNormalize', { obj = self })
        core.sendGlobalEvent('detd_WabbaReset', { obj = self })

    elseif s >= 0.95 and s <= 1.05 then
        if math.random() < 0.5 then
            core.sendGlobalEvent('detd_StartGradualShrink', { obj = self })
            core.sendGlobalEvent('detd_WabbaWeak', { obj = self })
        else
            core.sendGlobalEvent('detd_StartGradualEnlarge', { obj = self })
            core.sendGlobalEvent('detd_WabbaStrong', { obj = self })
        end
    elseif s < 1.0 then
        core.sendGlobalEvent('detd_StartGradualShrink', { obj = self })
        core.sendGlobalEvent('detd_WabbaWeak', { obj = self })
    else
        core.sendGlobalEvent('detd_StartGradualEnlarge', { obj = self })
        core.sendGlobalEvent('detd_WabbaStrong', { obj = self })
    end
end

local function applyKnockbackLandingPenalty(data)
    local riseAmount = 0
    if data and data.riseAmount then
        riseAmount = data.riseAmount
    end

    if riseAmount <= 0 then
        return
    end

    types.Actor.stats.dynamic.fatigue(self).current = -10
    types.Actor.stats.dynamic.health(self).current =
        types.Actor.stats.dynamic.health(self).current - 100
end

local function castWeatherOrFallback()
    if self.cell and self.cell.isExterior then
        core.sendGlobalEvent('detd_WabbaRandomWeather', { obj = self })
    else
        applyRandomSpellEffect()
    end
end

local function castWabbaEffect()
    local option = rollEffect()

    if option == 1 then
        core.sendGlobalEvent('detd_WabbaEvent', { obj = self })
        core.sendGlobalEvent('detd_SmallifyActorWabba', { obj2 = self })
        types.Actor.stats.dynamic.health(self).current = 0
        types.Actor.stats.dynamic.fatigue(self).current = 0
        types.Actor.spells(self):add('detd_wabbakillinvis')
        types.Actor.setEquipment(self, {})
        wasTransformed = true

    elseif option == 2 then
        applyRandomSpellEffect()

    elseif option == 4 then
        types.Actor.stats.ai.fight(self).base = 0
        local animId = DANCES[math.random(#DANCES)]
        AI.removePackages('Combat')
        types.Actor.stats.ai.alarm(self).base = 0
        anim.playBlended(self, animId, { priority = anim.PRIORITY.Scripted })

    elseif option == 5 then
        local replacements = chooseReplacementItems()
        if next(replacements) then
            core.sendGlobalEvent('detd_wabbahat', { obj3 = self, items = replacements })
        end

    elseif option == 6 then
        core.sendGlobalEvent('detd_SpawnClone', { obj = self, chance = 0.50 })

    elseif option == 7 then
        core.sendGlobalEvent('detd_ModifyDisposition', { npc = self, amount = 100 })
        AI.removePackages('Combat')
        types.Actor.stats.ai.alarm(self).base = 0

    elseif option == 8 then
        handleScaleOption()

    elseif option == 9 then
        print("[WABBA NPC] starting knockback")
        knockback.start()

    elseif option == 10 then
        castWeatherOrFallback()
    end
end

time.runRepeatedly(function()
    if wasTransformed and types.Actor.isDeathFinished(self) then
        disableSelf()
        return
    end

    local active = isWabbaActive()
    if not active then
        doOnce = false
        return
    end

    if doOnce then
        return
    end

    castWabbaEffect()
    doOnce = true
end, POLL_INTERVAL)

local function detd_WabbaInventoryComplete(data)
    local equipment = types.Actor.getEquipment(self)
    for key, id in pairs(data) do
        local entry = ITEM_LISTS[key]
        if entry and entry.slot then
            equipment[entry.slot] = id
        end
    end
    types.Actor.setEquipment(self, equipment)
end

return {
    engineHandlers = knockback.engineHandlers,
    eventHandlers = {
        detd_WabbaInventoryComplete = detd_WabbaInventoryComplete,
        detd_TELE_DONE = knockback.eventHandlers.detd_TELE_DONE,
        detd_KnockbackLanded = applyKnockbackLandingPenalty,
    }
}
