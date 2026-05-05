-- scripts/devilish_thuum_fatigue_target.lua

local self  = require('openmw.self')
local types = require('openmw.types')

local FATIGUE_SPELL_ID = 'detd_thuum_fatigue'

local active = false
local timer = 0.0

local function addFatigueSpell(duration)
    pcall(function()
        types.Actor.spells(self):add(FATIGUE_SPELL_ID)
    end)

    active = true
    timer = duration or 3.0
end

local function removeFatigueSpell()
    pcall(function()
        types.Actor.spells(self):remove(FATIGUE_SPELL_ID)
    end)

    active = false
    timer = 0.0
end

return {
    eventHandlers = {
        DETD_ThuumFatigueHit = function(data)
            addFatigueSpell(data and data.duration or 3.0)
        end,

        DETD_ThuumFatigueCleanup = function()
            removeFatigueSpell()
        end,
    },

    engineHandlers = {
        onUpdate = function(dt)
            if not active then
                return
            end

            timer = timer - dt

            if timer <= 0 then
                removeFatigueSpell()
            end
        end,
    }
}