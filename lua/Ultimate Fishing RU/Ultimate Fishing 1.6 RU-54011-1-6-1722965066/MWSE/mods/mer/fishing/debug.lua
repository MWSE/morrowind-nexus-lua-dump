local LocationManager = require("mer.fishing.Habitat.LocationManager")
local Habitat = require("mer.fishing.Habitat.Habitat")
local FishGenerator = require("mer.fishing.Fish.FishGenerator")

---@param e keyDownEventData
event.register("keyDown", function(e)
    if tes3.player and tes3.player.data.merDebugEnabled then
        if e.keyCode == tes3.scanCode.forwardSlash then
            Habitat.showHabitatMessage()
        end

        if e.keyCode == tes3.scanCode.period then
            local validFish = FishGenerator.getValidFish()
            local message = "Valid fish:\n"

            local lists = {
                validFish.small.all,
                validFish.medium.all,
                validFish.large.all,
            }
            for _, list in ipairs(lists) do
                for _, fish in ipairs(list) do
                    local fishObj = fish:getBaseObject()
                    if fishObj then
                        message = message .. fishObj.name .. "\n"
                    end
                end
            end
            message = message:sub(1, -2)
            tes3.messageBox(message)
        end
    end
end)
