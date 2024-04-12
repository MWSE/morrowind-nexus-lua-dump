require("BuildYourOwnRebalance.mcm")
local armor = require("BuildYourOwnRebalance.armor")
local unarmored = require("BuildYourOwnRebalance.unarmored")
local clothing = require("BuildYourOwnRebalance.clothing")
local weapon = require("BuildYourOwnRebalance.weapon")
local condition = require("BuildYourOwnRebalance.condition")
local common = require("BuildYourOwnRebalance.common")
local config = require("BuildYourOwnRebalance.config")
local gameConfig = config.getGameConfig()

local function onItemLoaded(item, itemData, isPlayerInventory)
    
    local e = {
        item = item,
        itemData = itemData,
        isPlayerInventory = isPlayerInventory,
    }
    
    armor.onItemLoaded(e)
    clothing.onItemLoaded(e)
    weapon.onItemLoaded(e)
    condition.onItemLoaded(e)
    
end

local function onInventoryLoaded(inventory, isPlayerInventory)
    
    for _, stack in pairs(inventory) do
        
        -- restocking items have a negative count
        local itemCount = math.abs(stack.count)
        local item = stack.object
        
        if stack.variables ~= nil then
            for _, itemData in pairs(stack.variables) do
                onItemLoaded(item, itemData, isPlayerInventory)
                itemCount = itemCount - itemData.count
            end
        end
        
        if itemCount > 0 then
            onItemLoaded(item, nil, isPlayerInventory)
        end
        
    end
    
end

local function onCellLoaded(cell)
    
    for ref in cell:iterateReferences({ tes3.objectType.armor, tes3.objectType.clothing, tes3.objectType.weapon, tes3.objectType.ammunition }) do
        onItemLoaded(ref.object, ref.itemData, false)
    end
    
    for ref in cell:iterateReferences({ tes3.objectType.npc, tes3.objectType.creature, tes3.objectType.container }) do
        onInventoryLoaded(ref.object.inventory, false)
    end
    
end

local loaded = false

local function onDamage(e)
    
    weapon.onDamage(e)
    
end

local function onCellActivated(e)
    
    if not loaded then return end
    
    onCellLoaded(e.cell)
    
end

local function onLoaded(e)
    
    loaded = true
    
    armor.onLoaded(e)
    unarmored.onLoaded(e)
    clothing.onLoaded(e)
    weapon.onLoaded(e)
    
    common.log("--------------------------------------------------")
    common.log("Initial onItemLoaded Start")
    common.log("--------------------------------------------------")
    
    onInventoryLoaded(tes3.player.object.inventory, true)
    
    for _, cell in pairs(tes3.getActiveCells()) do
        onCellLoaded(cell)
    end
    
    common.log("--------------------------------------------------")
    common.log("Initial onItemLoaded End")
    common.log("--------------------------------------------------")
    
end

local function onLoad(e)
    
    loaded = false
    
end

local function onInitialized(e)
    
    if not gameConfig.shared.modEnabled then return false end
    
    event.register(tes3.event.load, onLoad)
    event.register(tes3.event.loaded, onLoaded, { priority = -10 })
    event.register(tes3.event.cellActivated, onCellActivated, { priority = -10 })
    event.register(tes3.event.damage, onDamage, { priority = -10 })
    
    armor.onInitialized(e)
    clothing.onInitialized(e)
    weapon.onInitialized(e)
    
end

event.register(tes3.event.initialized, onInitialized, { priority = -10 })
