local common = require("mer.fishing.common")
local logger = common.createLogger("Harvest")

local CraftingFramework = include("CraftingFramework")
logger:assert(CraftingFramework ~= nil, "CraftingFramework is required to use Harvesting mechanics")


local Harvest = {
    ---@type CraftingFramework.MenuActivator.data
    menuActivator = {
        name = "Разделка рыбы",
        id = "Fishing:Harvest",
        type = "event",
        recipes = {},
        defaultFilter = "materials",
        showFilterButton = false,
        showCollapseCategoriesButton = false,
        showCategoriesButton = false,
        showSortButton = false,
    },
    harvestableFish = {}
}

local function getHarvestablesDescription(harvestables)
    local description = "Вы получите: \n"
    for _, harvestable in ipairs(harvestables) do
        local obj = tes3.getObject(harvestable.id)
        if not obj then
            logger:error("Harvestable object %s does not exist", harvestable.id)
        else
            description = description .. string.format("- %s (%s-%s)\n", obj.name, harvestable.min, harvestable.max)
        end
    end
    description = description:sub(1, -2)
    return description
end

local function getReceivedItemsMessage(harvested)
    local message = "Вы получили: \n"
    for id, count in pairs(harvested) do
        local obj = tes3.getObject(id)
        message = message .. string.format("- %dx %s\n", count, obj.name)
    end
    message = message:sub(1, -2)
    return message
end


---@param fishType Fishing.FishType
function Harvest.registerFish(fishType)
    logger:debug("Registering fish %s", fishType.baseId)
    if CraftingFramework and fishType.harvestables and #fishType.harvestables > 0 then
        logger:debug("- Has %d harvestables", #fishType.harvestables)
        local menuId = Harvest.menuActivator.id
        local harvestingMenuActivator = CraftingFramework.MenuActivator.get(menuId)
        if not harvestingMenuActivator then
            logger:error("Could not find Harvesting Menu Activator with id %s", menuId)
        else
            local fishObj = fishType:getBaseObject()
            harvestingMenuActivator:registerRecipe{
                id = "harvest:" .. fishType.baseId,
                name = fishObj.name,
                previewMesh = fishType:getPreviewMesh(),
                noResult = true,
                keepMenuOpen = true,
                description = getHarvestablesDescription(fishType.harvestables),
                toolRequirements  = {
                    { tool = "knife", conditionPerUse = 1 }
                },
                craftCallback = function(_, _)
                    --add each harvestable to inventory
                    local item
                    local harvested = {}
                    for _, harvestable in ipairs(fishType.harvestables) do
                        local count = math.random(harvestable.min, harvestable.max)
                        local obj = tes3.getObject(harvestable.id) --[[@as tes3ingredient]]
                        if count > 0 and obj then
                            item = tes3.addItem{
                                reference = tes3.player,
                                item = obj,
                                count = count,
                                playSound = false
                            }--[[@as tes3misc]]
                            harvested[harvestable.id] = count
                        end
                    end
                    if table.size(harvested) == 0 then
                        tes3.messageBox("Вам не удалось ничего собрать.")
                        return
                    end
                    tes3.messageBox(getReceivedItemsMessage(harvested))
                    tes3.playItemPickupSound{ reference = tes3.player, item = item}
                end,
                materials = {
                    { material = fishObj.id, count = 1}
                }
            }
            Harvest.harvestableFish[fishType.baseId:lower()] = fishType
        end
    end
end

CraftingFramework.MenuActivator:new(Harvest.menuActivator)

CraftingFramework.Tool:new{
    id = "knife",
    name = "Короткий клинок",
    requirement = function(itemStack)
        return itemStack.object.objectType == tes3.objectType.weapon
        and itemStack.object.type == tes3.weaponType.shortBladeOneHand
    end,
}

local requiresKnifeEquipped = false
---@param e equipEventData
event.register("equip", function(e)
    logger:debug("Equip event: %s", e.item.id)
    if Harvest.harvestableFish[e.item.id:lower()] then
        logger:debug("Equipping harvestable fish")
        local hasKnife = CraftingFramework.Tool.getTool("knife"):hasInInventory(true)
        if requiresKnifeEquipped and not hasKnife then
            tes3.messageBox("Используйте короткий клинок, чтобы разделать улов.")
        else
            logger:debug("Equipping harvestable fish")
            event.trigger(Harvest.menuActivator.id)
        end
    end
end)

return Harvest