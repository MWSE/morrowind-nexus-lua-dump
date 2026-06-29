local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local cfg = require('scripts.cmc.config')

local EFFECT_SCAN_INTERVAL = tonumber(cfg.thresholds.effectScanInterval or 0.50) or 0.50

local effectScanTimer = math.random() * EFFECT_SCAN_INTERVAL
local processedEffectKeys = {}
local pendingActiveSpellRemovals = {}
local deathMarkCleared = false

local function getCaster(activeSpell)
    if activeSpell and activeSpell.caster and activeSpell.caster:isValid() then
        return activeSpell.caster
    end
    return nil
end

local function effectMagnitude(activeSpell, eff)
    if eff and eff.magnitude then return eff.magnitude end
    if eff and eff.magnitudeMax then return eff.magnitudeMax end
    if activeSpell and activeSpell.id then
        local spellId = cfg.lowerId(activeSpell.id)
        local amount = cfg.resistScaledDamage and cfg.resistScaledDamage[spellId]
        if amount then return amount end
        amount = cfg.antiBlightDamage and cfg.antiBlightDamage[spellId]
        if amount then return amount end
    end
    return 25
end

local function queueActiveSpellRemoval(activeSpell)
    local asId = activeSpell and activeSpell.activeSpellId
    if asId ~= nil then pendingActiveSpellRemovals[tostring(asId)] = asId end
end

local function sendDamageFromSpell(activeSpell, effectId, magnitude)
    local spellId = cfg.lowerId(activeSpell and activeSpell.id)

    -- NPCs cannot be swapped into diseased/blighted creature variants, but OPP
    -- still needs confirmed blight-spread hits on NPCs to mark them as
    -- scourge-vulnerable. Do this from the target actor's active-effect scan,
    -- the same confirmed-hit path used by the script-resolved damage effects.
    local spreadKind = cfg.isSpreadEffect(effectId)
    if spreadKind then
        core.sendGlobalEvent('cmcApplySpread', {
            actor = getCaster(activeSpell),
            target = self.object,
            kind = spreadKind,
            spellId = spellId,
        })
        queueActiveSpellRemoval(activeSpell)
        return 'spread', spreadKind
    end

    local scaledKind = cfg.isResistScaledDamageEffect(effectId)
    if scaledKind then
        core.sendGlobalEvent('cmcApplyResistScaledDamage', {
            actor = getCaster(activeSpell),
            target = self.object,
            kind = scaledKind,
            spellId = spellId,
            magnitude = magnitude,
        })
        -- These custom damage spells are implemented as script-resolved one-shot
        -- effects. If their harmless carrier effect remains active on the actor,
        -- active-spell polling will see it again and reapply damage. Remove the
        -- carrier after the event is queued, matching the one-shot handling used
        -- by other OpenMW spell-script frameworks.
        queueActiveSpellRemoval(activeSpell)
        return 'damage', scaledKind
    end

    if cfg.isAntiBlightEffect(effectId) then
        core.sendGlobalEvent('cmcApplyAntiBlightDamage', {
            actor = getCaster(activeSpell),
            target = self.object,
            spellId = spellId,
            magnitude = magnitude,
        })
        queueActiveSpellRemoval(activeSpell)
        return 'anti', 'antiBlight'
    end

    return nil, nil
end

local function scanMagicEffects()
    if types.Actor.isDead(self) then return end

    local activeSpells = types.Actor.activeSpells(self)
    local seen = {}

    for _, activeSpell in pairs(activeSpells) do
        local spellId = cfg.lowerId(activeSpell and activeSpell.id)
        local spellKey = tostring(spellId or activeSpell.activeSpellId or '')
        local handledSpread = {}
        local handledDamage = {}
        local handledAnti = false

        if activeSpell.effects then
            for _, eff in pairs(activeSpell.effects) do
                local effectId = cfg.lowerId(eff.id)
                local key = spellKey .. ':effect:' .. tostring(effectId or '')
                seen[key] = true

                if not processedEffectKeys[key] then
                    local magnitude = effectMagnitude(activeSpell, eff)
                    local category, kind = sendDamageFromSpell(activeSpell, effectId, magnitude)
                    if category then
                        processedEffectKeys[key] = true
                        if category == 'spread' then handledSpread[kind] = true end
                        if category == 'damage' then handledDamage[kind] = true end
                        if category == 'anti' then handledAnti = true end
                    end
                else
                    -- Even when the exact effect key was already processed, record
                    -- what category it represented so the spell-level fallback below
                    -- does not duplicate the same mechanic while still allowing
                    -- compound spells to run their other mechanic.
                    local spreadKind = cfg.isSpreadEffect(effectId)
                    if spreadKind then handledSpread[spreadKind] = true end
                    local damageKind = cfg.isResistScaledDamageEffect(effectId)
                    if damageKind then handledDamage[damageKind] = true end
                    if cfg.isAntiBlightEffect(effectId) then handledAnti = true end
                end
            end
        end

        -- Some OpenMW builds expose cloned/template effects under a generic
        -- engine effect id rather than the custom OPP effect id. Process each
        -- mechanic declared by the spell record independently. This is required
        -- for compound AoE spells such as Contagion: Plagueburst and Ashstorm
        -- Communion, which must both spread affliction and apply damage.
        local spellSpreadKind = cfg.isSpreadSpell(spellId)
        if spellSpreadKind and not handledSpread[spellSpreadKind] then
            local key = spellKey .. ':spellspread:' .. tostring(spellSpreadKind)
            seen[key] = true
            if not processedEffectKeys[key] then
                processedEffectKeys[key] = true
                queueActiveSpellRemoval(activeSpell)
                core.sendGlobalEvent('cmcApplySpread', {
                    actor = getCaster(activeSpell),
                    target = self.object,
                    kind = spellSpreadKind,
                    spellId = spellId,
                })
            end
        end

        local spellDamageKind = cfg.isResistScaledDamageSpell(spellId)
        if spellDamageKind and not handledDamage[spellDamageKind] then
            local key = spellKey .. ':spelldamage:' .. tostring(spellDamageKind)
            seen[key] = true
            if not processedEffectKeys[key] then
                processedEffectKeys[key] = true
                queueActiveSpellRemoval(activeSpell)
                core.sendGlobalEvent('cmcApplyResistScaledDamage', {
                    actor = getCaster(activeSpell),
                    target = self.object,
                    kind = spellDamageKind,
                    spellId = spellId,
                    magnitude = effectMagnitude(activeSpell, nil),
                })
            end
        end

        if cfg.isAntiBlightSpell(spellId) and not handledAnti then
            local key = spellKey .. ':spellanti:antiBlight'
            seen[key] = true
            if not processedEffectKeys[key] then
                processedEffectKeys[key] = true
                queueActiveSpellRemoval(activeSpell)
                core.sendGlobalEvent('cmcApplyAntiBlightDamage', {
                    actor = getCaster(activeSpell),
                    target = self.object,
                    spellId = spellId,
                    magnitude = effectMagnitude(activeSpell, nil),
                })
            end
        end
    end

    if next(pendingActiveSpellRemovals) then
        for _, asId in pairs(pendingActiveSpellRemovals) do
            pcall(function() activeSpells:remove(asId) end)
        end
        pendingActiveSpellRemovals = {}
    end

    for key in pairs(processedEffectKeys) do
        if not seen[key] then processedEffectKeys[key] = nil end
    end
end

local function takeActorDamage(data)
    if not data then return end
    local amount = math.floor(tonumber(data.amount or 0) or 0)
    if amount <= 0 or types.Actor.isDead(self) then return end
    local before, after = nil, nil
    local ok = pcall(function()
        local health = types.Actor.stats.dynamic.health(self)
        before = math.floor(tonumber(health.current or 0) or 0)
        health.current = math.max(0, health.current - amount)
        after = math.floor(tonumber(health.current or 0) or 0)
    end)
    if ok and data.report then
        core.sendGlobalEvent('cmcLocalDamageApplied', {
            actor = data.actor,
            target = self.object,
            amount = amount,
            before = before,
            after = after,
            label = data.label,
        })
    end
end

return {
    eventHandlers = {
        cmcTakeActorDamage = takeActorDamage,
        cmcTakeBlightDamage = takeActorDamage,
    },
    engineHandlers = {
        onUpdate = function(dt)
            effectScanTimer = effectScanTimer + dt
            if effectScanTimer < EFFECT_SCAN_INTERVAL then return end
            effectScanTimer = 0

            if types.Actor.isDead(self) then
                if not deathMarkCleared then
                    deathMarkCleared = true
                    core.sendGlobalEvent('cmcClearNpcBlightMark', { target = self.object })
                end
                return
            end

            scanMagicEffects()
        end,
    },
}
