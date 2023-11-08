local world = require('openmw.world')
local types = require('openmw.types')
local core = require('openmw.core')

local function funcname(var)
    
  local lp = world.cells
    for i, _ in pairs(lp) do
      if lp[i].name == "The Arcane Academy of Venarius, Training Room" then
        local misc = lp[i]:getAll(types.Activator)  
          for a, _ in pairs(misc) do
            if misc[a].recordId == string.lower("AAV_GG_fence_s_02p") then
                misc[a].enabled = false
            end
          end
      end
    end
end    

return { eventHandlers = { disappear = funcname } } 
