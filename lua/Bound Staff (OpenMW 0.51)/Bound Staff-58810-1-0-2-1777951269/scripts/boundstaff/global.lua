local world  = require('openmw.world')
local types  = require('openmw.types')
local async  = require('openmw.async')
local core   = require('openmw.core')
local I      = require('openmw.interfaces')

local SPELL_ID      = 'bound_staff_spell'
local STAFF_ID      = 'bound_staff'
local ESTIRDALIN_ID = 'estirdalin'

local staffItem = nil

local equipCallback = async:registerTimerCallback('equipStaff', function(data)
    data.player:sendEvent('EquipStaff', { staff = data.staff })
end)

local stanceCallback = async:registerTimerCallback('readyStaff', function(data)
    data.player:sendEvent('ReadyStaff', {})
end)

local function summonStaff(data)
    local player = data.player
    local inv    = types.Actor.inventory(player)

    -- Remove any leftover Spells Reforged bound spear by name
    for _, item in ipairs(inv:getAll()) do
        if item.type == types.Weapon then
            local rec = types.Weapon.record(item)
            if rec and rec.name == 'Bound Spear' then
                item:remove(1)
                break
            end
        end
    end

    staffItem = world.createObject(STAFF_ID, 1)
    staffItem:moveInto(inv)
    async:newSimulationTimer(0.1, equipCallback, { player = player, staff = staffItem })
    async:newSimulationTimer(1.1, stanceCallback, { player = player })
end

local function removeStaff(data)
    if staffItem and staffItem:isValid() then
        staffItem:remove(1)
        staffItem = nil
        return
    end
    if data.player then
        local inv = types.Actor.inventory(data.player)
        for _, item in ipairs(inv:getAll()) do
            if item.type == types.Weapon then
                local rec = types.Weapon.record(item)
                if rec and rec.id == STAFF_ID then
                    item:remove(1)
                    break
                end
            end
        end
    end
end

local function retrieveStaff(data)
    local inv = types.Actor.inventory(data.player)
    data.staff:moveInto(inv)
    data.player:sendEvent('EquipStaff', { staff = data.staff })
end

-- Assign spell to Estirdalin when player activates her
I.Activation.addHandlerForType(types.NPC, function(npc)
    if npc.recordId:lower() ~= ESTIRDALIN_ID then return end
    if not types.NPC.record(npc).servicesOffered.Spells then return end

    local spell = core.magic.spells.records[SPELL_ID]
    if spell then
        types.NPC.spells(npc):add(spell)
    end
end)

return {
    eventHandlers = {
        BoundStaffSummon   = summonStaff,
        BoundStaffRemove   = removeStaff,
        BoundStaffRetrieve = retrieveStaff,
    }
}
