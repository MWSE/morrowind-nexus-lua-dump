local common = require("mer.fishing.common")
local logger = common.createLogger("FishingNet")

---@class Fishing.FishingNet.config
---@field id string

---@class Fishing.FishingNet
local FishingNet = {
    ---@type table<string, Fishing.FishingNet.config>
    registeredFishingNets = {}
}

--- Register an item as a fishing net
---@param e Fishing.FishingNet.config
function FishingNet.register(e)
    logger:assert(type(e.id) == "string", "Fishing net must have an id")
    FishingNet.registeredFishingNets[e.id:lower()] = e
end

--- Get the fishing net config for an id
---@return Fishing.FishingNet.config|nil
function FishingNet.get(id)
    return FishingNet.registeredFishingNets[id:lower()]
end

--- Check if the player has a fishing net in their inventory
---@return boolean
function FishingNet.playerHasNet()
    --check inventory
    for _, stack in pairs(tes3.player.object.inventory) do
        local fishingNet = FishingNet.get(stack.object.id)
        if fishingNet then
            return true
        end
    end
    return false
end

return FishingNet