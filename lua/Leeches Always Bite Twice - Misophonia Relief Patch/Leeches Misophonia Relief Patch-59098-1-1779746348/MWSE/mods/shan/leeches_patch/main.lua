local Leeches = require("leeches.leeches")


--- Remove all leeches from the reference that have expired according to the given timestamp or chance based on Chameleon strength over 20%.
---
---@param ref tes3reference
---@param timestamp TimeStamp
function Leeches:removeExpired(ref, timestamp)
    local mob = ref and ref.mobile
    local chanceRemove = (math.min(mob.chameleon, 60.0) - 20.0) / 40.0 --lowest chance at 21, highest chance at 60
    local leeches = Leeches.get(ref)
    if leeches == nil then
        return
    end

    while leeches:numActive() > 0 do
        local leech = leeches:getOldestActiveLeech()
        if timestamp < leech.expireTime then
            if mob.chameleon > 20 then
              if math.random() > chanceRemove then
                return
              end
            else
              return
            end
        end
        leeches:removeLeech(ref, leech)
    end
end
