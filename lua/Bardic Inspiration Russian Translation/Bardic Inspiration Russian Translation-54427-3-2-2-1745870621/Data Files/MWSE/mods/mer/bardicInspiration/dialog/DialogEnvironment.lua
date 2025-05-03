local common = require("mer.bardicInspiration.common")

---@class BardicInspiration.DialogEnvironment
local DialogEnvironment = {}

---@param publicanRef tes3reference
function DialogEnvironment.clearLuteOwnership(publicanRef)
    local ownedLute = common.getOwnedLuteInCell(publicanRef)
    if ownedLute then
        tes3.setOwner{
            reference = ownedLute,
            remove = true
        }
        common.setHasGivenLute(true)
    end
end

return DialogEnvironment