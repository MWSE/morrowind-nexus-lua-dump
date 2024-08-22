local types = require('openmw.types')
local self = require('openmw.self')

local function Paralyze()
types.Actor.activeSpells(self):add({id = 'paralysis', effects = { 0 }})
print(self.recordId)
end





return {
    eventHandlers = { Paralyze = Paralyze },
}