local common = require("mer.fishing.common")
local logger = common.createLogger("FishingRod")

---When a misc_de_fishing_pole is equipped, replace it
-- with a mer_fishing_pol and equip that instead
---@param e equipEventData
event.register("equip", function(e)
    logger:debug("Equip event: %s", e.item.id)
    if e.item.id:lower() == "misc_de_fishing_pole" then
        logger:debug("Replacing misc_de_fishing_pole with mer_fishing_pole_01")
        local pole = tes3.getObject("mer_fishing_pole_01") --[[@as tes3weapon]]
        if not pole then
            logger:warn("mer_fishing_pole_01 not found")
        else
            --Remove fishing pole
            tes3.removeItem{
                reference = e.reference,
                item = e.item,
                count = 1
            }
            --Add new fishing pole
            tes3.addItem{
                reference = e.reference,
                item = pole,
                count = 1
            }
            --Equip new fishing pole
            timer.frame.delayOneFrame(function()
                ---@diagnostic disable-next-line
                mwscript.equip{
                    reference = e.reference,
                    item = pole
                }
            end)
            --block event
            return true
        end
    end
end)
