local world = require('openmw.world')
local core = require('openmw.core')
local time = require('openmw_aux.time')
local types = require('openmw.types')

local config = require('scripts.niftyspellpack.config.global')

local l10n = core.l10n('NiftySpellPack')

local payloads = {}
local removedSpells = {}

local alreadyProcessedSpells = {}
local alreadyProcessedItems = {}

local function copyEffectParams(effect)
    return {
        id = effect.id,
        magnitudeMin = effect.magnitudeMin,
        magnitudeMax = effect.magnitudeMax,
        duration = effect.duration,
        range = effect.range,
        area = effect.area,
        affectedAttribute = effect.affectedAttribute,
        affectedSkill = effect.affectedSkill,
    }
end

local function createSpellPayload(spell)
    local payload, nonPayload = {}, {}
    local isPayload = false

    local anyOfSchool = {
        alteration = false,
        conjuration = false,
        destruction = false,
        illusion = false,
        mysticism = false,
        restoration = false,
    }

    for _, effect in ipairs(spell.effects) do
        if isPayload and effect.range == core.magic.RANGE.Self and effect.id ~= 'nsp_contingency' then
            anyOfSchool[effect.effect.school] = true
            -- local effect = copyEffectParams(effect)
            -- effect.range = core.magic.RANGE.Self
            table.insert(payload, effect)
        else
            table.insert(nonPayload, effect)
            if effect.id == 'nsp_contingency' then
                isPayload = true
            end
        end
    end

    if #payload > 0 then
        for _, school in ipairs({ 'alteration', 'conjuration', 'destruction', 'illusion', 'mysticism', 'restoration' }) do
            if anyOfSchool[school] then
                table.insert(nonPayload, {
                    id = 'nsp_contingency_payload_' .. school,
                    magnitudeMin = 0,
                    magnitudeMax = 0,
                    duration = 0,
                    range = core.magic.RANGE.Self,
                })
            end
        end
        return payload, nonPayload
    else
        return nil
    end
end

local function processSpell(spell, target)
    if alreadyProcessedSpells[spell.id] or payloads[spell.id] then return end
    alreadyProcessedSpells[spell.id] = true

    local payload, nonPayload = createSpellPayload(spell)
    if payload then
        local targetSpells = target.type.spells(target)
        local newBaseRecord = world.createRecord(core.magic.spells.createRecordDraft{
            template = spell,
            effects = nonPayload,
        })
        local newPayloadRecord = world.createRecord(core.magic.spells.createRecordDraft{
            template = spell,
            effects = payload,
        })
        payloads[newBaseRecord.id] = newPayloadRecord.id
        targetSpells:remove(spell)
        table.insert(removedSpells, spell.id)
        targetSpells:add(newBaseRecord)
        alreadyProcessedSpells[newBaseRecord.id] = true

        return true
    end
end

local function processItem(item, target)
    if alreadyProcessedItems[item.recordId] then return end -- record IDs are unique for player-enchanted items, so this is fine
    alreadyProcessedItems[item.recordId] = true
    local enchantId = item.type.record(item).enchant
    if not enchantId or payloads[enchantId] then return end

    local enchantment = core.magic.enchantments.records[enchantId]
    local payload, nonPayload = createSpellPayload(enchantment)
    if payload then
        local newBaseRecord = world.createRecord(core.magic.enchantments.createRecordDraft{
            template = enchantment,
            effects = nonPayload,
        })
        local newPayloadRecord = world.createRecord(core.magic.enchantments.createRecordDraft{
            template = enchantment,
            effects = payload,
        })
        payloads[newBaseRecord.id] = newPayloadRecord.id

        local oldData = types.Item.itemData(item)
        local newItemRecord = world.createRecord(item.type.createRecordDraft{
            template = item.type.record(item),
            enchant = newBaseRecord.id,
        })
        local newItem = world.createObject(newItemRecord.id, item.count)
        local newData = types.Item.itemData(newItem)
        for _, attr in ipairs{'condition', 'enchantmentCharge', 'soul'} do
            if oldData[attr] then
                newData[attr] = oldData[attr]
            end
        end
        item:remove()
        newItem:moveInto(target.type.inventory(target))
        alreadyProcessedItems[newItem.recordId] = true
        
        return true
    end
end

return {
    onTrigger = function(ctx)
        if not ctx.target then return end

        world.mwscript.getGlobalVariables(ctx.target).nsp_resurrect = 1

        if config.contingency.b_SoulStrain then
            ctx.target.type.spells(ctx.target):add('nsp_soulstrain')
        end

        local callback = time.registerTimerCallback(ctx.target.id .. '_soulstrain', function()
            if not ctx.target then return end
            ctx.target.type.spells(ctx.target):remove('nsp_soulstrain')
        end)
        time.newGameTimer(time.day, callback)

        ctx.target:sendEvent('NSP_EffectEvent', { type = 'onResurrect', effectId = 'nsp_contingency' })
    end,
    onSpellCreation = function(ctx)
        if not ctx.target then return end
        local anyChanged = false
        for _, spell in ipairs(ctx.target.type.spells(ctx.target)) do
            if processSpell(spell, ctx.target) then
                anyChanged = true
            end
        end
        if anyChanged then
            ctx.target:sendEvent('NSP_EffectEvent', { type = 'onNewPayload', effectId = 'nsp_contingency', ctx = { payloads = payloads, removedSpells = removedSpells } })
        end
    end,
    onEnchant = function(ctx)
        if not ctx.target then return end
        local anyChanged = false
        for _, item in ipairs(ctx.target.type.inventory(ctx.target):getAll()) do
            if processItem(item, ctx.target) then
                anyChanged = true
            end
        end
        if anyChanged then
            ctx.target:sendEvent('NSP_EffectEvent', { type = 'onNewPayload', effectId = 'nsp_contingency', ctx = { payloads = payloads } })
        end
    end,
    onLoad = function(save)
        if save then
            payloads = save.payloads or {}
            removedSpells = save.removedSpells or {}
        end
    end,
    onSave = function()
        return {
            payloads = payloads,
            removedSpells = removedSpells,
        }
    end,
}