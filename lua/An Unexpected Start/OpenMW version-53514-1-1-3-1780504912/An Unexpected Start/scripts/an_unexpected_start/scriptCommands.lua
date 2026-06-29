local world = require('openmw.world')

local this = {}

function this.raceMenu()
    local activator = world.createObject("usbd_race_menu_script_activator", 1)
    activator:teleport(world.players[1].cell, world.players[1].position, {})
    return activator
end

function this.classMenu()
    local activator = world.createObject("usbd_class_menu_script_activator", 1)
    activator:teleport(world.players[1].cell, world.players[1].position, {})
    return activator
end

function this.birthMenu()
    local activator = world.createObject("usbd_birth_menu_script_activator", 1)
    activator:teleport(world.players[1].cell, world.players[1].position, {})
    return activator
end

function this.statReviewMenu()
    local activator = world.createObject("usbd_statreview_menu_script_activator", 1)
    activator:teleport(world.players[1].cell, world.players[1].position, {})
    return activator
end

function this.enableControls()
    local activator = world.createObject("usbd_finish_chargen_script_activator", 1)
    activator:teleport(world.players[1].cell, world.players[1].position, {})
    return activator
end

function this.finishChargen()
    local activator = world.createObject("usbd_set_chargenstate_script_activator", 1)
    activator:teleport(world.players[1].cell, world.players[1].position, {})
    return activator
end

function this.addFindspymasterQuest()
    local activator = world.createObject("usbd_add_findspymaster_quest_activator", 1)
    activator:teleport(world.players[1].cell, world.players[1].position, {})
    return activator
end

return this