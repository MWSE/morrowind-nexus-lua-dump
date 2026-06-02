-- Declarations --
local self = require("openmw.self")
local types = require("openmw.types")
local core = require("openmw.core")

-- Engine Handlers --
local function onUpdate()
    local spells = types.Actor.activeSpells(self.object)
    for _, spell in pairs(spells) do
        for _, effect in pairs(spell.effects) do
            if effect.name == 'Cure Common Disease' then
                core.sendGlobalEvent('cureCritter', self.object)
            end
        end
    end
end

-- Return
return {
    engineHandlers = {
        onUpdate = onUpdate,
    }
}
