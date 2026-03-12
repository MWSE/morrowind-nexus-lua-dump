local types = require('openmw.types')

local Actor = types.Actor

-- NEW: also consume the receptacle itself
local RECEPTACLE_ID = 'sch_contfirm_cl_starring'

local function consumeFromActor(actor, required)
  if not actor or type(required) ~= 'table' then return end

  local inv = Actor.inventory(actor)
  if not inv then return end

  -- NEW: always remove the receptacle (1)
  required[RECEPTACLE_ID] = (tonumber(required[RECEPTACLE_ID]) or 0) + 1

  for id, need in pairs(required) do
    need = tonumber(need) or 0
    if need > 0 then
      -- Remove by repeatedly finding stacks and shrinking them.
      while need > 0 do
        local item = inv:find(id)
        if not item then break end

        local stack = tonumber(item.count) or 1
        local take = (need < stack) and need or stack

        item:remove(take) -- global-only, works here
        need = need - take
      end
    end
  end
end

return {
  eventHandlers = {
    SCH_ContFirmConsumeStars = function(data)
      if not data or not data.actor or not data.required then return end
      consumeFromActor(data.actor, data.required)
    end
  }
}