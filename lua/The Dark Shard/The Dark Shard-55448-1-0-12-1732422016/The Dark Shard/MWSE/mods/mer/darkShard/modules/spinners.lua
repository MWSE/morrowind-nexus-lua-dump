
local common = require("mer.darkShard.common")
local logger = common.createLogger("soulGems")
local CometEffect = require("mer.darkShard.components.CometEffect")
local CraftingFramework = require("CraftingFramework")
local ReferenceManager = CraftingFramework.ReferenceManager
local Spinner = require("mer.darkShard.components.Spinner")


local soulGemManager = ReferenceManager:new{
    id = "DarkShard:Spinners",
    logger = logger,
    requirements = function(self, reference)
        logger:trace("Checking if %s should spin: %s", reference.object.id, reference.object.isSoulGem)
        return Spinner.isSpinner(reference)
    end,
}

---@param e simulateEventData
event.register("simulate", function(e)
    soulGemManager:iterateReferences(function(reference)
        logger:debug("Processing Spinner %s", reference.object.id)
        local spinner = Spinner:new(reference)
        spinner:update(e.delta)
    end)
end)

---@param e itemDroppedEventData
event.register(tes3.event.itemDropped, function(e)
    if e.reference.object.isSoulGem then
        local spinner = Spinner:new(e.reference)
        spinner:reset()
    end
end)