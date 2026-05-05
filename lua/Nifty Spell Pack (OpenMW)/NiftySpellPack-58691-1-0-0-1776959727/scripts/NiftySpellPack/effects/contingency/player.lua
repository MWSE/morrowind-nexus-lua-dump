local self = require('openmw.self')
local ambient = require('openmw.ambient')
local core = require('openmw.core')
local anim = require('openmw.animation')
local ui = require('openmw.ui')
local camera = require('openmw.camera')
local types = require('openmw.types')
local I = require('openmw.interfaces')

local helpers = require('scripts.niftyspellpack.util.helpers')
local config = require('scripts.niftyspellpack.config.global')

local l10n = core.l10n('NiftySpellPack')
local health = self.type.stats.dynamic.health(self)
local spells = self.type.spells(self)

local lastCameraState = {
    mode = nil,
    pitch = nil,
    yaw = nil,
}

local payloads = {} -- synced from global
local removedSpells = {} -- synced from global, used to prevent re-adding spells that were removed when creating payloads

local function initMWETooltips()
    if I.MagicWindow and I.MagicWindow.Tooltips then
        local Type = I.MagicWindow.Constants.TooltipType
        local BaseTemplates = I.MagicWindow.Templates.BASE
        local MagicTemplates = I.MagicWindow.Templates.MAGIC
        local MWEHelpers = require('scripts.magicwindowextender.util.helpers')

        local modifierId = 'nsp_contingency'

        local baseFn = function(payload, layout)
            local innerContent = layout.content.padding.content.tooltip.content
            local replaced = false

            local effectsIdx = innerContent:indexOf('effects')
            if effectsIdx then
                local effects = innerContent[effectsIdx]
                for i, layout in ipairs(effects.content) do
                    if replaced then
                        effects.content[i] = {}
                    elseif layout.content then
                        for _, piece in ipairs(layout.content) do
                            if piece.props and piece.props.text and piece.props.text:find(l10n('effect_nsp_contingency_payload')) then
                                replaced = true
                                local effectLayouts = {}
                                for i, effect in ipairs(payload.effects) do
                                    local effectLayout = {
                                        type = ui.TYPE.Flex,
                                        props = {
                                            horizontal = true,
                                            arrange = ui.ALIGNMENT.Center,
                                        },
                                        content = ui.content {
                                            MagicTemplates.effectIcon(effect.id),
                                            BaseTemplates.intervalH(4),
                                            {
                                                template = BaseTemplates.textNormal,
                                                props = {
                                                    text = MWEHelpers.createSpellEffectString(effect),
                                                }
                                            }
                                        }
                                    }
                                    if i ~= 1 then
                                        table.insert(effectLayouts, BaseTemplates.intervalV(8))
                                    end
                                    table.insert(effectLayouts, effectLayout)
                                end

                                local newLayout = {
                                    type = ui.TYPE.Flex,
                                    props = {
                                        arrange = ui.ALIGNMENT.Center,
                                    },
                                    external = {
                                        stretch = 1,
                                    },
                                    content = ui.content {
                                        {
                                            template = BaseTemplates.textHeader,
                                            props = {
                                                text = l10n('UI_Contingency_Tooltip_OnTrigger'),
                                            },
                                        },
                                        {
                                            type = ui.TYPE.Flex,
                                            props = {
                                                arrange = ui.ALIGNMENT.Start,
                                            },
                                            content = ui.content(effectLayouts),
                                        }
                                    }
                                }

                                effects.content[i] = newLayout
                            end
                        end
                    end
                end
            end
        end

        I.MagicWindow.Tooltips.registerModifier(Type.SPELL, modifierId, function(spellId, layout)
            if payloads[spellId] then
                baseFn(core.magic.spells.records[payloads[spellId]], layout)
            end
        end)
        I.MagicWindow.Tooltips.registerModifier(Type.MAGIC_ITEM, modifierId, function(item, layout)
            local enchantId = item.type.record(item).enchant
            if enchantId and payloads[enchantId] then
                baseFn(core.magic.enchantments.records[payloads[enchantId]], layout)
            end
        end)
    end
end

local activeSpells = self.type.activeSpells(self)

return {
    realtimeMagnitudeWhileActive = true,
    onUpdate = function(dt, magnitude)
        if dt == 0 or magnitude <= 0 then return end

        if health.current <= 0 then
            if not spells.nsp_soulstrain then
                ambient.playSoundFile('sound/niftyspellpack/contingency.wav')
                core.sendGlobalEvent('NSP_EffectEvent', { type = 'onTrigger', effectId = 'nsp_contingency', target = self, ctx = { magnitude = magnitude } })    
                
                local payloadSpells = {}
                
                for _, spell in pairs(activeSpells) do
                    for _, effect in pairs(spell.effects) do
                        if effect.id == 'nsp_contingency' then
                            local payloadId = payloads[spell.id]
                            if payloadId then
                                local payloadSpell = core.magic.spells.records[payloadId] or core.magic.enchantments.records[payloadId]
                                if payloadSpell then
                                    table.insert(payloadSpells, payloadSpell)
                                end
                            end
                            goto continue
                        end
                    end
                    ::continue::
                    if spell.temporary then
                        activeSpells:remove(spell.activeSpellId)
                    end
                end

                for _, spell in ipairs(payloadSpells) do
                    activeSpells:add({ id = spell.id, effects = helpers.range(0, #spell.effects - 1), ignoreResistances = true, ignoreSpellAbsorption = true, ignoreReflect = true, caster = self })
                    for _, effect in ipairs(spell.effects) do
                        anim.addVfx(self, types.Static.record(effect.effect.hitStatic).model, {
                            particleTextureOverride = effect.effect.particle,
                            loop = false,
                        })
                        ambient.playSound(effect.effect.school .. ' hit')
                    end
                end
            else
                ui.showMessage(l10n('UI_Contingency_Failed'))
            end
            return
        end
        lastCameraState.mode = camera.getMode()
        lastCameraState.pitch = camera.getPitch()
        lastCameraState.yaw = camera.getYaw()
    end,
    onResurrect = function()
        local lastMode = lastCameraState.mode or camera.getMode()
        if lastMode == camera.MODE.Static then lastMode = camera.MODE.ThirdPerson end
        camera.setMode(lastMode)
        camera.setPitch(lastCameraState.pitch or camera.getPitch())
        camera.setYaw(lastCameraState.yaw or camera.getYaw())

        health.current = 1

        local vfx = { 'dispel', 'restorehealth' }
        for _, effectId in ipairs(vfx) do
            local mgef = core.magic.effects.records[effectId]
            anim.addVfx(self, types.Static.record(mgef.hitStatic).model, {
                particleTextureOverride = mgef.particle,
                loop = false,
            })
        end
    end,
    onUiModeChanged = function(oldMode)
        if oldMode == 'SpellCreation' then
            core.sendGlobalEvent('NSP_EffectEvent', { type = 'onSpellCreation', effectId = 'nsp_contingency', target = self })
        elseif oldMode == 'Enchanting' then
            core.sendGlobalEvent('NSP_EffectEvent', { type = 'onEnchant', effectId = 'nsp_contingency', target = self })
        end

        if not config.contingency.b_SoulStrain then
            spells:remove('nsp_soulstrain') 
        end
    end,
    onNewPayload = function(ctx)
        payloads = ctx.payloads or {}
        removedSpells = ctx.removedSpells or {}
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
    onActive = function()
        initMWETooltips()
        for _, id in ipairs(removedSpells) do
            if spells[id] then
                spells:remove(id)
            end
        end
    end,
}