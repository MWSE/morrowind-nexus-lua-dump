local core = require('openmw.core')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local types = require('openmw.types')

local function onUpdate(dt)
  local nearcreat = nearby.actors
  for a, _ in pairs(nearcreat) do
    if nearcreat[a].type == types.Creature then
     if nearcreat[a].recordId ~= string.lower("AAV_skeleton_warrior") then
      if types.Creature.stats.dynamic.health(nearcreat[a]).current > 0 then
        if (self.position - nearcreat[a].position):length() < 1000 then
          core.sendGlobalEvent("madgodmissingmarbles_addskel", { creatureself = nearcreat[a] } )
        end
      end
     end
    end 
  end
end

return { engineHandlers = { onUpdate = onUpdate } }