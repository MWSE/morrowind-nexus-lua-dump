local common = require("mer.fishing.common")
local logger = common.createLogger("interop")
local config = require("mer.fishing.config")

local UF = {
    Bait = require("mer.fishing.Bait.Bait"),
    BaitType = require("mer.fishing.Bait.BaitType"),
    FishType = require("mer.fishing.Fish.FishType"),
    FishingRod = require("mer.fishing.FishingRod.FishingRod"),
    FishingNet = require("mer.fishing.FishingNet"),
    Supplies = require("mer.fishing.Merchant.Supplies"),
    Merchant = require("mer.fishing.Merchant.Merchant"),
    LocationManager = require("mer.fishing.Habitat.LocationManager"),
    ---Register the current target NPC as a fishing merchant
    registerMerchant = function()
        logger:info("Registering fishing merchant")
        local target = tes3ui.findMenu("MenuConsole"):getPropertyObject("MenuConsole_current_ref")
        local targetIsNPC = target
            and target.baseObject.objectType == tes3.objectType.npc
        if not targetIsNPC then
            logger:warn("Target is not an NPC")
            tes3.messageBox("Target is not an NPC")
            return
        end
        config.mcm.fishingMerchants[target.baseObject.id:lower()] = true
        config.save()
        event.trigger("Fishing:McmUpdated")
        logger:info("Set %s as a fishing merchant", target.baseObject.id)
    end,
    FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")
}
event.register("UIEXP:sandboxConsole", function(e)
    e.sandbox.fishing = UF
end)

---A set of APIs for registering fishing related objects
---@class Fishing.Interop
local Interop = {}

Interop.registerBait = UF.Bait.register
Interop.registerBaitType = UF.BaitType.register
Interop.registerFishType = UF.FishType.register
Interop.registerFishingRod = UF.FishingRod.register
Interop.registerFishingNet = UF.FishingNet.register
Interop.registerFishingSupply = UF.Supplies.register
Interop.registerFishingMerchant = UF.Merchant.register
Interop.registerLocation = UF.LocationManager.registerLocation

Interop.registerLocationCategory = UF.LocationManager.registerCategory
Interop.registerLocationType = UF.LocationManager.registerLocationType
Interop.registerLocation = UF.LocationManager.registerLocation

Interop.getWaterType = function()
    local locationTypes = UF.LocationManager.getLocations("water")
    for _, locationType in pairs(locationTypes) do
        mwse.log(locationType.name)
    end
end


return Interop