local I     = require('openmw.interfaces')
local ai    = I.AI
local self  = require('openmw.self')
local types = require('openmw.types')
local core  = require('openmw.core')
local async = require('openmw.async')

local clearTimer = 0
local allyWasFound = false

local function findAlly()
  local follow = ai.getActiveTarget('Follow')
  local escort = ai.getActiveTarget('Escort')
  local isPlayer = function(target_obj) return target_obj and types.Player.objectIsInstance(target_obj) end
  local isAlly = isPlayer(follow) or isPlayer(escort)

    if isAlly then
        -- союзник найден:
        clearTimer = 0
        if not allyWasFound then
            --print("СОЮЗНИК НАЙДЕН")
            core.sendGlobalEvent('ReportPlayerAlly', { id = self.object.id, time = core.getSimulationTime() })
            allyWasFound = true
        end
    else
        -- союзник не найден/перестал следовать за игроком:
        if allyWasFound then
            clearTimer = clearTimer + 0.2 --неточно, но неважно
            if clearTimer >= 2.0 then
                --print("НА УДАЛЕНИЕ")
                core.sendGlobalEvent('ClearPlayerAlly')
                allyWasFound = false
                clearTimer = 0
            end
        end
    end
    async:newUnsavableSimulationTimer(0.2, findAlly)
end

async:newUnsavableSimulationTimer(0.2, findAlly)
