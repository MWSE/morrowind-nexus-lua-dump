
---@class RealisticRepair.EhancementService
local EnhancementService = {}

local config = require("mer.RealisticRepair.config")
local logger = mwse.Logger.new{
    logLevel = config.mcm.logLevel,
}

---@param item tes3weapon|tes3armor
---@param itemData tes3itemData
local function moveDamageToEnhancement(item, itemData)
    if itemData.condition == nil then
        return
    end

    if item.maxCondition == nil then
        return
    end

    if itemData.condition >= item.maxCondition then
        return
    end

    if itemData.data == nil then
        return
    end

    if itemData.data.enhancementLevel == nil then
        return
    end

    local damageAmount = item.maxCondition - itemData.condition
    itemData.condition = item.maxCondition
    itemData.data.enhancementLevel = math.max(0, itemData.data.enhancementLevel - damageAmount)
    logger:debug("Moved %d damage from condition to enhancement for item %s",
        damageAmount, item.name)

end

---@param e damagedEventData
function EnhancementService.handleDamagedEvent(e)
    for _, stack in pairs(e.reference.object.inventory) do
        if stack.variables and #stack.variables > 0 then
            for _, itemData in pairs(stack.variables) do
                if e.reference.object:hasItemEquipped(stack.object, itemData) then
                    moveDamageToEnhancement(stack.object, itemData)
                end
            end
        end
    end
end

return EnhancementService