local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local Activation = require('openmw.interfaces').Activation

local function addHammer(object,actor)
  if types.NPC.record(object).class == "smith" then
    if types.NPC.inventory(object):isResolved() then
     if types.NPC.inventory(object):countOf("repair_hammer_weapon") == 0 then
      world.createObject("repair_hammer_weapon",1):moveInto(object)
     end
    end
  end
end

Activation.addHandlerForType(types.NPC,addHammer)