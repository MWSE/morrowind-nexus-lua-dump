-- Declarations --
local core = require("openmw.core")
local self = require('openmw.self')
local types = require('openmw.types')
local nearby = require('openmw.nearby')

-- Internal Functions --
local function checkIfEquipped(actor, recordId)
    for i, x in pairs(types.Actor.getEquipment(actor)) do
        if x.recordId == recordId then return true end
    end
    return false
end

-- Engine Handlers --
local function onActivated(actor)
    if (types.Player.objectIsInstance(actor))
    then
        if not checkIfEquipped(actor, "autosort_pickup_ring")
        then
            local overflowContainer = nil
            for _, container in ipairs(nearby.containers)
            do
                for _, item in ipairs(types.Container.inventory(container):getAll(types.Miscellaneous))
                do
                    if item.recordId == "autosort_target_apparatus" then
                        core.sendGlobalEvent("moveItems", {actorObject=actor, container=container, list=types.Actor.inventory(actor):getAll(types.Apparatus)})
                    elseif item.recordId == "autosort_target_armor" then
                        core.sendGlobalEvent("moveItems", {actorObject=actor, container=container, list=types.Actor.inventory(actor):getAll(types.Armor)})
                    elseif item.recordId == "autosort_target_book" then
                        core.sendGlobalEvent("moveBooks", {actorObject=actor, container=container, list=types.Actor.inventory(actor):getAll(types.Book)})
                    elseif item.recordId == "autosort_target_clothing" then
                        core.sendGlobalEvent("moveItems", {actorObject=actor, container=container, list=types.Actor.inventory(actor):getAll(types.Clothing)})
                    elseif item.recordId == "autosort_target_gold" then
                        core.sendGlobalEvent("moveGold", {actorObject=actor, container=container})
                    elseif item.recordId == "autosort_target_ingredient" then
                        core.sendGlobalEvent("moveItems", {actorObject=actor, container=container, list=types.Actor.inventory(actor):getAll(types.Ingredient)})
                    elseif item.recordId == "autosort_target_key" then
                        core.sendGlobalEvent("moveKeys", {actorObject=actor, container=container})
                    elseif item.recordId == "autosort_target_misc" then
                        core.sendGlobalEvent("moveMisc", {actorObject=actor, container=container})
                    elseif item.recordId == "autosort_target_potion" then
                        core.sendGlobalEvent("moveItems", {actorObject=actor, container=container, list=types.Actor.inventory(actor):getAll(types.Potion)})
                    elseif item.recordId == "autosort_target_scroll" then
                        core.sendGlobalEvent("moveScrolls", {actorObject=actor, container=container, list=types.Actor.inventory(actor):getAll(types.Book)})
                    elseif item.recordId == "autosort_target_security" then
                        core.sendGlobalEvent("moveItems", {actorObject=actor, container=container, list=types.Actor.inventory(actor):getAll(types.Lockpick)})
                        core.sendGlobalEvent("moveItems", {actorObject=actor, container=container, list=types.Actor.inventory(actor):getAll(types.Probe)})
                    elseif item.recordId == "autosort_target_soulgem" then
                        core.sendGlobalEvent("moveSoulGems", {actorObject=actor, container=container})
                    elseif item.recordId == "autosort_target_repair" then
                        core.sendGlobalEvent("moveItems", {actorObject=actor, container=container, list=types.Actor.inventory(actor):getAll(types.Repair)})
                    elseif item.recordId == "autosort_target_weapon" then
                        core.sendGlobalEvent("moveItems", {actorObject=actor, container=container, list=types.Actor.inventory(actor):getAll(types.Weapon)})
                    elseif item.recordId == "autosort_target_overflow" then
                        overflowContainer = container -- Mark the Overflow container as found
                    end
                end
            end

            -- If we found the Overflow container, use it
            if overflowContainer ~= nil and overflowContainer ~= doNotUseContainer
            then
                core.sendGlobalEvent("moveOverflow", {actorObject=actor, container=overflowContainer})
            end
            actor:sendEvent("sortingComplete")
        else
            core.sendGlobalEvent("moveAutosortMaster", {actorObject=actor, item=self.object})
        end
    end
end

-- Return --
return {
    engineHandlers = {
        onActivated = onActivated
    }
}