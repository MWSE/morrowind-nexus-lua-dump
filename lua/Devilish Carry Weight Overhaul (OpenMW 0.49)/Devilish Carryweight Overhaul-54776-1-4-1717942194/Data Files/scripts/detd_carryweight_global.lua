local time = require('openmw_aux.time')
local world = require('openmw.world')
local types = require('openmw.types')

local function EquippedWeight(data)
    world.mwscript.getGlobalScript("detd_realistic_carryweight").variables.EquipmentWeight = data
    end

    return {
        eventHandlers = {
        detdGlobalWeight = EquippedWeight
                }
            }