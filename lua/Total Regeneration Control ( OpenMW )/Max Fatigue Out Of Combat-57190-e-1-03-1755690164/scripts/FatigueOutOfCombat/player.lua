local async = require('openmw.async')
local self  = require('openmw.self')
local types = require('openmw.types')
local core  = require('openmw.core')

local settings = require('scripts.FatigueOutOfCombat.settings')
local settings_section = settings.globalSettings

local function getDelaySetting()
    return settings_section:get('delay') or 7
end

local table = {}
local fatigue = types.Actor.stats.dynamic.fatigue(self)

local function eventFatigueKeepMaximum(data)
    table[data.id] = data.set_max_stamina
end

local tick = 0.4
local timer = 0
local sim_time_last = core.getSimulationTime()
local function fatigueRegen()
    local set_max_stamina = true
    local sim_time_now = core.getSimulationTime()
    local delta_sim_time = sim_time_now - sim_time_last

    for _, bool in pairs(table) do
        if bool == false then
            set_max_stamina = false
            timer = getDelaySetting() + delta_sim_time
        end
    end
    --print("timer= ", timer)
    timer = math.max(timer - delta_sim_time, 0)

    if set_max_stamina and timer == 0 then
        local fatigue_max = fatigue.base + fatigue.modifier
        fatigue.current = fatigue_max
        --print("MAX")
    end

    table = {}
    sim_time_last = core.getSimulationTime()

    async:newUnsavableSimulationTimer(tick, fatigueRegen)
end
async:newUnsavableSimulationTimer(tick, fatigueRegen)


return {
    eventHandlers = {
        eventFatigueKeepMaximum = eventFatigueKeepMaximum,
    }
}