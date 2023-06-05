local common = require("mer.fishing.common")
local logger = common.createLogger("interop")
local config = require("mer.fishing.config")

local Interop = {}

Interop.registerBait = require("mer.fishing.Bait.Bait").register
Interop.registerBaitType = require("mer.fishing.Bait.BaitType").register
Interop.registerFishType = require("mer.fishing.Fish.FishType").register
Interop.registerFishingRod = require("mer.fishing.FishingRod.FishingRod").register
Interop.registerFishingSupply = require("mer.fishing.Merchant.Supplies").register
Interop.registerMerchant = function()
    logger:info("Registering fishing merchant")
    local target = tes3ui.findMenu("MenuConsole"):getPropertyObject("MenuConsole_current_ref")
    local targetIsNPC = target
        and target.baseObject.objectType == tes3.objectType.npc
    if not targetIsNPC then
        logger:warn("Target is not an NPC")
        return
    end
    config.mcm.fishingMerchants[target.baseObject.id:lower()] = true
    config.save()
    event.trigger("Fishing:McmUpdated")
    logger:info("Set %s as a fishing merchant", target.baseObject.id)
end

event.register("UIEXP:sandboxConsole", function(e)
    e.sandbox.fishing = Interop
end)

return Interop