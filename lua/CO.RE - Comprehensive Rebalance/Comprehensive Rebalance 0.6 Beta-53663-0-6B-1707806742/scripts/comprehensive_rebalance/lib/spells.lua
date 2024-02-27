local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')

local Actor = types.Actor

local actorSpells = Actor.spells(self)


local spells = {}

function spells.addOrRemoveSpell(spell,add)
    if add then
        actorSpells:add(spell)
        core.sound.stopSound3d("magic sound", self) --dirty hack
        --ui.showMessage("adding " .. spell)
    else
        actorSpells:remove(spell)
        --ui.showMessage("removing " .. spell)
    end
end

return spells
