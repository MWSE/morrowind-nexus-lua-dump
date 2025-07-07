--[[
ErnSpellBooks for OpenMW.
Copyright (C) 2025 Erin Pentecost

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]] local types = require("openmw.types")
local settings = require("scripts.ErnSpellBooks.settings")
local core = require("openmw.core")
local animation = require('openmw.animation')
local async = require('openmw.async')
local self = require("openmw.self")

local clearVFXCallback = async:registerTimerCallback('ernClearVFXCallback', function(data)
    animation.removeVfx(data.actor, data.vfxID)
end)

-- can only be used on Self
local function applySpellEffectWithParams(effectWithParams, actor)
    if effectWithParams == nil then
        error("applySpellEffectWithParams() has nil effectWithParams")
    end
    if actor == nil then
        error("applySpellEffectWithParams() has nil actor")
    end
    settings.debugPrint("applying FX " .. effectWithParams.effect.name .. " on " .. actor.id)

    if effectWithParams.effect.hitSound ~= nil then
        core.sound.playSound3d(effectWithParams.effect.hitSound, actor, {
            loop = false,
            volume = 1.5,
            pitch = 1.0
        })
    end
    if (effectWithParams.effect.hitStatic ~= nil) then
        local vfxID = settings.MOD_NAME .. tostring(effectWithParams.effect.id) .. math.random(1, 1000)
        animation.addVfx(self, types.Static.record(effectWithParams.effect.hitStatic).model, {
            vfxId = vfxID,
            particuleTextureOverride = effectWithParams.effect.particle,
            loop = effectWithParams.effect.continuousVfx
        })
        async:newSimulationTimer(effectWithParams.duration, clearVFXCallback, {
            actor = actor,
            vfxID = vfxID
        })
    else

    end
end

local function applySpellFX(data)
    if data.spellID == nil then
        error("applySpellFX() data.spellID is nil")
        return
    end
    local spell = core.magic.spells.records[data.spellID]
    if spell == nil then
        error("applySpellFX() unknown spellID " .. data.spellID)
        return
    end
    if data.indices == nil then
        -- apply all effects
        for _, effectWithParams in ipairs(spell.effects) do
            applySpellEffectWithParams(effectWithParams, self)
        end
    else
        for _, index in data.indices do
            applySpellEffectWithParams(spell.effects[index], self)
        end
    end
end

return {
    eventHandlers = {
        ernApplySpellFX = applySpellFX
    }
}
