local Class, base = require("herbert100.Class"), require("herbert100.more quick loot.managers.abstract.base")

---@class MQL.Managers.Living : MQL.Manager
local Living = Class.new( {name="Living", parents={base}} )

-- we should stop updating each frame if: 
-- 1) the person we're looking at doesn't exist,
-- 2) the person we're looking at is not alive, or 
-- 3) we are sneaking
function Living:on_simulate()
    return self.ref ~= nil                -- container exists
        and self.ref.isDead ~= false      -- target is alive
        and tes3.mobilePlayer                       -- player reference exists
        and tes3.mobilePlayer.isSneaking ~= true    -- player is not sneaking
end

return Living