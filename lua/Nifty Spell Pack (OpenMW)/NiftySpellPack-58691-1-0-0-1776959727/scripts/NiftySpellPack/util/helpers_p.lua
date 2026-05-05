local self = require('openmw.self')

local activeSpells = self.type.activeSpells(self)

local Helpers = {}

Helpers.removeSpellsByEffectId = function(effectId, force)
    for _, spell in pairs(activeSpells) do
        for _, effect in pairs(spell.effects) do
            if effect.id == effectId then
                if spell.temporary then
                    activeSpells:remove(spell.activeSpellId)
                elseif spell.fromEquipment and force then
                    self:sendEvent('Unequip', { item = spell.item })
                end
                break
            end
        end
    end
end

return Helpers