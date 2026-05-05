local self  = require('openmw.self')
local types = require('openmw.types')
local core  = require('openmw.core')
local ui    = require('openmw.ui')

local EFFECT_ID  = 'bound_staff_effect'
local STAFF_ID   = 'bound_staff'

local staffItem       = nil
local effectWasActive = false
local stanceSet       = false
local stanceNeeded    = false

local function isEffectActive()
    for _, spell in pairs(types.Actor.activeSpells(self)) do
        for _, eff in pairs(spell.effects) do
            if eff.id == EFFECT_ID then return true end
        end
    end
    return false
end

local function staffInInventory()
    if not staffItem or not staffItem:isValid() then return false end
    local inv = types.Actor.inventory(self)
    for _, item in ipairs(inv:getAll()) do
        if item == staffItem then return true end
    end
    return false
end

local function onEquip(data)
    staffItem = data.staff
    local equipment = types.Actor.equipment(self)
    equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight] = staffItem
    types.Actor.setEquipment(self, equipment)
end

return {
    engineHandlers = {
        onUpdate = function(dt)
            local isActive = isEffectActive()

            if isActive and not effectWasActive then
                effectWasActive = true
                core.sendGlobalEvent('BoundStaffSummon', { player = self.object })

            elseif not isActive and effectWasActive then
                effectWasActive = false
                stanceSet = false
                core.sendGlobalEvent('BoundStaffRemove', { staff = staffItem })
                staffItem = nil

            elseif isActive and staffItem then
                if not staffInInventory() then
                    ui.showMessage('The bound staff cannot be discarded.')
                    core.sendGlobalEvent('BoundStaffRetrieve', { player = self.object, staff = staffItem })
                end
            end
        end,

        onLoad = function(save)
            staffItem = nil
            effectWasActive = false
            stanceSet = false
            core.sendGlobalEvent('BoundStaffRemove', { staff = staffItem, player = self.object })

            if isEffectActive() then
                local inv = types.Actor.inventory(self)
                for _, item in ipairs(inv:getAll()) do
                    if item.type == types.Weapon then
                        local rec = types.Weapon.record(item)
                        if rec and rec.id == STAFF_ID then
                            staffItem = item
                            effectWasActive = true
                            break
                        end
                    end
                end
                if not staffItem then
                    local equipment = types.Actor.equipment(self)
                    local equipped = equipment[types.Actor.EQUIPMENT_SLOT.CarriedRight]
                    if equipped and equipped.type == types.Weapon then
                        local rec = types.Weapon.record(equipped)
                        if rec and rec.id == STAFF_ID then
                            staffItem = equipped
                            effectWasActive = true
                        end
                    end
                end
            end
        end,

        onSave = function()
            return {}
        end,
    },
    eventHandlers = {
        BoundStaffEquip = onEquip,
        EquipStaff      = onEquip,
        ReadyStaff = function()
            print('[BoundStaff] ReadyStaff received')
            types.Actor.setStance(self, types.Actor.STANCE.Weapon)
        end,
    }
}