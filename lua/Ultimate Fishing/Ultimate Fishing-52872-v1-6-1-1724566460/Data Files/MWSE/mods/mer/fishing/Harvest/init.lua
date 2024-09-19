local common = require("mer.fishing.common")
local logger = common.createLogger("Harvest")


local CraftingFramework = include("CraftingFramework")
logger:assert(CraftingFramework ~= nil, "CraftingFramework is required to use Harvesting mechanics")

---@class Fishing.Harvest
local Harvest = {
    ---@type table<string, Fishing.FishType>
    harvestableFish = {}
}

---@param fishType Fishing.FishType
function Harvest.registerFish(fishType)
    logger:debug("Registering fish %s", fishType.baseId)
    if fishType.harvestables and #fishType.harvestables > 0 then
        logger:debug("- Has %d harvestables", #fishType.harvestables)
        Harvest.harvestableFish[fishType.baseId:lower()] = fishType
    else
        logger:debug("- No harvestables, skipping")
    end
end


local function isChisel(itemStack)
    local chisel = CraftingFramework.Tool.getTool("chisel")
    if not chisel then return false end
    return chisel:itemIsTool(itemStack.object)
end

local function isKnife(itemStack)
    return itemStack.object.objectType == tes3.objectType.weapon
        and itemStack.object.type == tes3.weaponType.shortBladeOneHand
        and not isChisel(itemStack)
end

local function hasKnife()
    for _, stack in pairs(tes3.player.object.inventory) do
        if isKnife(stack) then
            return true
        end
    end
    return false
end

local function getHarvestedItems(fishType)
    local harvested = {}
    for _, harvestable in ipairs(fishType.harvestables) do
        local count = math.random(harvestable.min, harvestable.max)
        local obj = tes3.getObject(harvestable.id) --[[@as tes3ingredient]]
        if count > 0 and obj then
            table.insert(harvested, { item = obj, count = count})
        end
    end
    return harvested
end




local function startHarvest(fishRef, fishType)
    --[[
        Fade out
        Replace fish with harvested items
        Fade in
    ]]
    common.disablePlayerControls()
    tes3.playSound{
        reference = tes3.player,
        sound = "mer_fish_chop"
    }
    tes3.fadeOut{ duration = 2 }
    timer.start{
        duration = 2,
        callback = function()
            local harvested = getHarvestedItems(fishType)
            for _, harvestedItem in ipairs(harvested) do
                local ref = tes3.createReference{
                    object = harvestedItem.item,
                    position = fishRef.position:copy(),
                    orientation = fishRef.orientation:copy(),
                    cell = fishRef.cell
                }
                ref.itemData.count = harvestedItem.count
            end
            common.safeDelete(fishRef)
            tes3.fadeIn{ duration = 1 }
            timer.start{
                duration = 1,
                callback = function()
                    common.enablePlayerControls()
                end
            }
        end
    }
end

---@param ref tes3reference
---@return boolean
local function isStack(ref)
    return (
        ref.attachments and
        ref.attachments.variables and
        ref.attachments.variables.count > 1
    )
end

---@param e activateEventData
event.register("activate", function(e)
    logger:debug("Activate event: %s", e.target.object.id)

    local fishType = Harvest.harvestableFish[e.target.object.id:lower()]
    if not fishType then
        logger:debug("Not a harvestable fish")
        return
    end

    if isStack(e.target) then
        logger:debug("Stacked fish, picking up")
        return
    end

    local isModifierKeyPressed = CraftingFramework.Util.isQuickModifierDown()
    if isModifierKeyPressed then
        logger:debug("Modifier key pressed, picking up")
        return
    end

    logger:debug("Activating harvestable fish")
    tes3ui.showMessageMenu{
        message = string.format("%s", e.target.object.name),
        buttons = {
            {
                text = "Harvest",
                enableRequirements = hasKnife,
                ---@diagnostic disable-next-line
                tooltipDisabled = {
                    text =  "You need a knife to harvest this."
                },
                callback = function()
                    startHarvest(e.target, fishType)
                end
            },
            {
                text = "Pick Up",
                callback = function()
                    common.pickUp(e.target, true)
                end
            }
        },
        cancels = true,
        cancelText = "No",
    }
    return false
end)


return Harvest