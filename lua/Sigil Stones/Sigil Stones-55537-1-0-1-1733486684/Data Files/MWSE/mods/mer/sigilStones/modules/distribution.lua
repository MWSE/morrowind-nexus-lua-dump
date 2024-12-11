local common = require("mer.sigilStones.common")
local logger = common.createLogger("distribution")
local SigilStone = require("mer.sigilStones.components.SigilStone")

---@param e leveledItemPickedEventData
event.register("leveledItemPicked", function(e)
    if not e.pick then return end
    if SigilStone.getSigilStoneConfig(e.pick.id) then
        logger:debug("Converting sigil stone")
        local sigilStone = SigilStone:create{
            baseObjectId = e.pick.id
        }
        if not sigilStone then
            return
        end

        local safeRef = tes3.makeSafeObjectHandle(e.spawner)
        timer.delayOneFrame(function()
            if safeRef and safeRef:valid() then
                sigilStone:replaceInInventory{
                    reference = safeRef:getObject()
                }
            end
        end)
    end
end)