--[[
    Oil Paints
    - Purcahaseable paint pots that hold x number of refills.
]]
local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("OilPaints")
local Palette = require("mer.joyOfPainting.items.Palette")
local CraftingFramework = require("CraftingFramework")


---@class JOP.OilPaints : JOP.ItemInstance
local OilPaints = {
    id = "jop_oil_paints_01",
    maxRefills = 10,
    name = "Масляные краски",
    mesh = "jop\\oil_paint_01.nif"
}
OilPaints.__index = OilPaints

function OilPaints:new(e)
    return common.createItemInstance(e, self, logger) --[[@as JOP.OilPaints]]
end


---@param parent tes3uiElement
function OilPaints:doTooltip(parent)
    local labelText = string.format("Объем: %s",
        self:getRefills()
    )
    parent:createLabel{text = labelText}
end

function OilPaints:getRefills()
    return self.data.oilPaintRefills or OilPaints.maxRefills
end

--Find how many oil paint refills is in the player inventory
function OilPaints.getPlayerRefills()
    local refills = 0
    local stack = CraftingFramework.CarryableContainer.findItemStack{ item = OilPaints.id }
    if not stack then
        return refills
    end
    local stackCount = stack.count and stack.count or 1
    local variablesCount = stack.variables and #stack.variables or 0
    local fullPaints = stackCount - variablesCount
    refills = refills + (fullPaints * OilPaints.maxRefills)
    --now check itemdata
    if stack.variables then
        for _, itemData in ipairs(stack.variables) do
            local oilPaints = OilPaints:new{
                item = stack.object,
                itemData = itemData
            }
            if oilPaints.data.oilPaintRefills then
                refills = refills + oilPaints.data.oilPaintRefills
            end
        end
    end
    return refills
end

--Find an oil paints in the inventory and reduce its refills by 1
function OilPaints.reduceRefillsInInventory()
    logger:debug("reduceRefillsInInventory()")
    local stack = CraftingFramework.CarryableContainer.findItemStack{ item = OilPaints.id }
    if not stack then
        logger:error("Could not find oil paints in inventory")
        return
    end
    if stack.variables then
        for _, itemData in ipairs(stack.variables) do
            local oilPaints = OilPaints:new{
                item = stack.object,
                itemData = itemData
            }
            if oilPaints.data.oilPaintRefills then
                logger:debug("Found oil paints with refills, reducing by 1")
                oilPaints.data.oilPaintRefills = oilPaints.data.oilPaintRefills - 1
                return
            end
        end
    end
    --if we get here, we didn't find any refills in the item data,
    --So check if we need to add itemData, then reduce the refills
    if stack.variables == nil or #stack.variables == 0 then
        logger:debug("no item data, adding and setting to max-1")
        local itemData = tes3.addItemData{
            to = tes3.player,
            item = OilPaints.id,
        }
        local oilPaints = OilPaints:new{
            item = stack.object,
            itemData = itemData
        }
        oilPaints.data.oilPaintRefills = OilPaints.maxRefills - 1
    else
        logger:debug("Found item data, reducing first by 1")
        stack.variables[1].data.oilPaintRefills = stack.variables[1].data.oilPaintRefills - 1
    end
end

---@return CraftingFramework.Recipe.data
function OilPaints.getRecipe()
    return {
        name = OilPaints.name,
        id = "refill:jop_oil_paints_01",
        description = "Пополните палитру масляными красками.",
        knownByDefault = true,
        noResult = true,
        previewMesh = OilPaints.mesh,
        customRequirements = {
            {
                getLabel = function()
                    return string.format("%s Объем (1/%s)",
                        OilPaints.name, OilPaints.getPlayerRefills())
                end,
                check = function()
                    return OilPaints.getPlayerRefills() > 0
                end
            }
        },
        craftCallback = function()
            OilPaints.reduceRefillsInInventory()
            local paletteToRefill = Palette.getPaletteToRefill()
            if paletteToRefill then
                paletteToRefill:doRefill()
            end
        end
    }
end

return OilPaints