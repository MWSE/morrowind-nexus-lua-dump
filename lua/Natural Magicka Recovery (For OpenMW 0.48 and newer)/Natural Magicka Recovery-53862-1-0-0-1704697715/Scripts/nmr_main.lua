local self = require('openmw.self')
local types = require('openmw.types')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local mwui = require('openmw.interfaces').MWUI
local input = require('openmw.input')



local settings = {
    base = storage.playerSection('NMRSettingsA'),
    addons = storage.playerSection('NMRSettingsB'),
}

local tick_time = 0.1
local tick_timer = 0
local statsTime = 2
local statsTimer = 0

local current = types.Actor.stats.dynamic.magicka(self).current
local maxMagickaToRegenerate = 0
local regenAmount = 0


local positiveModifier = 0
local negativeModifier = 1

local SECOND = 1


return {
    engineHandlers = {
        -- Calls after the game is loaded


        -- Calls every frame except for when world is paused.
        onUpdate = function(dt)

            --print(types.NPC.record(self).race)
            if settings.base:get('NMRisActive') then
                statsTimer = statsTimer + dt
                tick_timer = tick_timer + dt

                if tick_timer >= tick_time then
                    tick_timer = 0
                    current = types.Actor.stats.dynamic.magicka(self).current
                    maxMagickaToRegenerate = I.NMR_CALC.calculateMax()
                    regenAmount = I.NMR_CALC.calculateBase(tick_time)


                    positiveModifier = I.NMR_CALC.calculatePositives()
                    negativeModifier = I.NMR_CALC.calculateNegatives()

                    regenAmount = (regenAmount + positiveModifier) * negativeModifier
                    -- Calculating fatigue modifier
                    

                    if current < maxMagickaToRegenerate then
                    local newValue = math.min(current + regenAmount, maxMagickaToRegenerate)
                    types.Actor.stats.dynamic.magicka(self).current = newValue
                    end
                end

                if statsTimer >= statsTime then
                    statsTimer = 0
                    print('Regen amount: ' .. regenAmount.. '. Max Magicka to regenerate: ' .. maxMagickaToRegenerate .. '. Positive Modifier: ' ..positiveModifier.. '. Negative Modifier: ' ..negativeModifier.. '.')
                end
            end
        end

}}
