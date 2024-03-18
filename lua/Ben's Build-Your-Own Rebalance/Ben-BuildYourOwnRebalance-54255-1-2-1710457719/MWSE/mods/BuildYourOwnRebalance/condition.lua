local common = require("BuildYourOwnRebalance.common")
local config = require("BuildYourOwnRebalance.config")
local gameConfig = config.getGameConfig()

local function fixItemCondition(item, itemData, isPlayerInventory)
    
    if not item then return end
    if not itemData then return end
    
    if item.objectType ~= tes3.objectType.weapon
    and item.objectType ~= tes3.objectType.armor then
        return
    end
    
    local oldCondition = itemData.condition
    
    if itemData.condition > item.maxCondition then
        
        if not gameConfig.condition.fixItemHealthOverflow then return end
        itemData.condition = item.maxCondition
        
    elseif itemData.condition < item.maxCondition then
        
        if isPlayerInventory then return end -- never repair player-held items
        if not gameConfig.condition.repairDamagedItems then return end
        itemData.condition = item.maxCondition
        
    end
    
    if itemData.condition ~= oldCondition then
        
        local message =
            "Item ID: %s | Name: %s" ..
            " | Condition: %d/%d -> %d/%d"
        
        common.log(message,
            item.id, item.name,
            oldCondition, item.maxCondition,
            itemData.condition, item.maxCondition)
        
    end
    
end

local function fixInventoryItemCondition(inventory, isPlayerInventory)
    
    if not inventory then return end
    
    for _, stack in pairs(inventory) do
        if stack.variables then
            for _, itemData in pairs(stack.variables) do
                fixItemCondition(stack.object, itemData, isPlayerInventory)
            end
        end
    end
    
end

local function fixCellItemCondition(cell)
    
    if not cell then return end
    
    for ref in cell:iterateReferences({ tes3.objectType.weapon, tes3.objectType.armor }) do
        fixItemCondition(ref.object, ref.itemData, false)
    end
    
    for ref in cell:iterateReferences({ tes3.objectType.npc, tes3.objectType.creature, tes3.objectType.container }) do
        fixInventoryItemCondition(ref.object.inventory, false)
    end
    
end

local loaded = false

local function fixItemConditionEnabled()
    
    return gameConfig.condition.fixItemHealthOverflow
        or gameConfig.condition.repairDamagedItems
    
end

local function onCellActivated(e)
    
    if not loaded then return end
    if not fixItemConditionEnabled() then return end
    
    fixCellItemCondition(e.cell)
    
end

local function onLoaded()
    
    loaded = true
    
    if not fixItemConditionEnabled() then return end
    
    common.log("--------------------------------------------------")
    common.log("Condition onLoaded Start")
    common.log("--------------------------------------------------")
    
    fixInventoryItemCondition(tes3.player.object.inventory, true)
    
    for _, cell in pairs(tes3.getActiveCells()) do
        fixCellItemCondition(cell)
    end
    
    common.log("--------------------------------------------------")
    common.log("Condition onLoaded End")
    common.log("--------------------------------------------------")
    
end

local function onLoad(e)
    
    loaded = false
    
end

local function onInitialized()
    
    if not gameConfig.shared.modEnabled then return false end
    
    event.register(tes3.event.load, onLoad, { priority = config.eventPriority.load.condition })
    event.register(tes3.event.loaded, onLoaded, { priority = config.eventPriority.loaded.condition })
    event.register(tes3.event.cellActivated, onCellActivated, { priority = config.eventPriority.cellActivated.condition })
    
end

event.register(tes3.event.initialized, onInitialized, { priority = config.eventPriority.initialized.condition })
