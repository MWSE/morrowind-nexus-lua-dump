local common = require("mer.fishing.common")
local config = require("mer.fishing.config")
local logger = common.createLogger("FishingRod")
local FishingRod = require("mer.fishing.FishingRod.FishingRod")

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
                --Remove vanilla fishing pole
                tes3.removeItem{
                    reference = e.reference,
                    item = e.item,
                    count = 1
                }
            end)
            --block event
            return true
        end
    end
end)


---@param e objectCreatedEventData
event.register("objectCreated", function(e)
    local rodConfig = e.copiedFrom and FishingRod.getConfig(e.copiedFrom.id)
    if rodConfig then
        logger:info("objectCreated: registering fishing rod %s", e.object.id)
        FishingRod.register{
            id = e.object.id,
            quality = rodConfig.quality
        }
        config.persistent.copiedFishingRods[e.copiedFrom.id:lower()] = e.object.id:lower()
    end
end)

event.register("loaded", function(e)
    --Register copied fishing rods
    for originalId, copiedId in pairs(config.persistent.copiedFishingRods) do
        logger:info("Registering copied fishing rod. Original: %s, New: %s",
        originalId, copiedId)
        local originalConfig = FishingRod.getConfig(originalId)
        if originalConfig then
            ---@type Fishing.FishingRod.config
            local newConfig = table.copy(originalConfig)
            newConfig.id = copiedId
            FishingRod.register(newConfig)
        end
    end
end)