local world = require('openmw.world')
local core	= require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')

local helpers = require('scripts.niftyspellpack.util.helpers')
local config = require('scripts.niftyspellpack.config.global')

local CELL_ID = "nsp_pocketspace"

local l10n = core.l10n('NiftySpellPack')

local linkedPockets = {} -- [spellOrItemRecordId] = { recordId, capacity, encumbrance }

local function getLinkedContainer(target)
    local activeSpells = target.type.activeSpells(target)
    for _, spell in pairs(activeSpells) do
        for _, effect in pairs(spell.effects) do
            if effect.id == "nsp_pocket" then
                local recordId = spell.id
                local cell = world.getCellById(CELL_ID)

                if linkedPockets[recordId] then
                    local containers = cell:getAll(types.Container)
                    for _, container in ipairs(containers) do
                        if container.recordId == linkedPockets[recordId].recordId then
                            return container
                        end
                    end
                end

                local linkedCount = helpers.getSize(linkedPockets)
                if config.pocket.i_MaxPockets > 0 and linkedCount >= config.pocket.i_MaxPockets then
                    return nil
                end

                local magnitude = (effect.minMagnitude + effect.maxMagnitude) / 2
                local capacity = util.round(magnitude * config.pocket.f_CapacityMultiplier)

                local record = world.createRecord(types.Container.createRecordDraft({
                    isOrganic = false,
                    isRespawning = false,
                    name = spell.name,
                    weight = capacity,
                }))
                linkedPockets[recordId] = { recordId = record.id, capacity = capacity, encumbrance = 0 }

                local obj = world.createObject(record.id, 1)
                obj:teleport(cell, util.vector3(0, 0, 0))

                return obj
            end
        end
    end
end

return {
    onMagnitudeChange = function(ctx)
        if ctx.oldMagnitude <= 0 and ctx.newMagnitude > 0 then
            local container = getLinkedContainer(ctx.target)
            if not container then
                ctx.target:sendEvent('NSP_EffectEvent', { type = 'onFail', effectId = 'nsp_pocket', ctx = { linkedPockets = linkedPockets } })
            else
                ctx.target:sendEvent('NSP_EffectEvent', { type = 'onTrigger', effectId = 'nsp_pocket', ctx = { container = container, linkedPockets = linkedPockets } })
            end
        end
    end,
    onContainerClosed = function(ctx)
        local container = ctx.container
        for spellOrItemId, pocket in pairs(linkedPockets) do
            if pocket.recordId == container.recordId then
                local inv = types.Container.inventory(container)
                if #inv:getAll() == 0 then
                    linkedPockets[spellOrItemId] = nil
                    container:remove()
                    ctx.target:sendEvent('ShowMessage', { message = l10n('UI_Pocket_Collapsed') })
                else
                    linkedPockets[spellOrItemId].encumbrance = types.Container.getEncumbrance(container)
                end

                ctx.target:sendEvent('NSP_EffectEvent', { type = 'onContainerClosed', effectId = 'nsp_pocket', ctx = { linkedPockets = linkedPockets } })
                return
            end
        end
    end,
    onCollapseChoice = function(ctx)
        local toCollapse = ctx.toCollapse
        local pocket = linkedPockets[toCollapse]
        if not pocket then return end

        local cell = world.getCellById(CELL_ID)
        local containers = cell:getAll(types.Container)
        for _, container in ipairs(containers) do
            if container.recordId == pocket.recordId then
                container:remove()
                linkedPockets[toCollapse] = nil
                
                local newContainer = getLinkedContainer(ctx.target)
                if newContainer then
                    ctx.target:sendEvent('NSP_EffectEvent', { type = 'onTrigger', effectId = 'nsp_pocket', ctx = { container = newContainer, linkedPockets = linkedPockets } })
                else
                    ctx.target:sendEvent('NSP_EffectEvent', { type = 'onFail', effectId = 'nsp_pocket', ctx = { linkedPockets = linkedPockets } })
                end

                return
            end
        end
    end,
    onLoad = function(save)
        if save then
            linkedPockets = save.linkedPockets or {}
        end
    end,
    onSave = function()
        return {
            linkedPockets = linkedPockets,
        }
    end,
}