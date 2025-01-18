local CraftingFramework = require("CraftingFramework")
local CarryableContainer = CraftingFramework.CarryableContainer
local BackpackService = require("mer.joyOfPainting.items.Backpack")
local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("carryableContainers")
local JOP = require("mer.joyOfPainting")

---@param self CarryableContainer
local function doEquip(self)
    local item = self.item --[[@as tes3clothing]]
    logger:debug("Equipping backpack `%s`", item.id)
    local didEquip = tes3.mobilePlayer:equip{ item = item }
    if not didEquip then
        logger:error("Failed to equip backpack")
    end
    self:updateStats()
end

local function replaceAndEquip(self)
    if not self:isCopy() then
        self:replaceInInventory()
        timer.frame.delayOneFrame(function()
            doEquip(self)
        end)
    else
        doEquip(self)
    end
end

---@param self CarryableContainer
local function doOpen(self)
    logger:debug("Opening backpack `%s`", self.item.id)
    self:openFromInventory()
end

local callbacks = {
    ---@param self CarryableContainer
    openFromInventory = function(self)
        logger:debug("Opening from inventory")
        if CraftingFramework.Util.isQuickModifierDown() then
            doOpen(self)
        else
            replaceAndEquip(self)
        end
    end,
    ---@param self CarryableContainer
    getWeightModifier = function(self)
        logger:debug("getWeightModifier()")
        --Set weight modifier to 0.1 if the backpack is equipped,
        --otherwise set it to 1.0
        local equippedStack = tes3.getEquippedItem{
            actor = tes3.player,
            objectType = tes3.objectType.clothing,
            slot = 11
        }
        local isEquipped = equippedStack and equippedStack.object == self.item
        if isEquipped then
            logger:debug("- Updating weight for equipped backpack")
            return self.containerConfig.weightModifier
        end
        logger:debug("- Updating weight for unequipped backpack")
        return 1
    end,
    ---@param self CarryableContainer
    getWeightModifierText = function(self)
        return string.format("Множитель веса: %.1fx при экипировке", self.containerConfig.weightModifier)
    end,

}


---@type CarryableContainers.ItemFilter.new.data[]
local filters = {
    {
        id = "paintingSupplies",
        name = "Принадлежности для рисования",
        isValidItem = function(item, itemData)
            local isPainting = JOP.Painting.itemDataIsPainting(itemData)
            local isCanvas = JOP.Painting.idIsCanvas(item.id)
            local isPaintBrush = JOP.Brush.isBrush(item.id)
            local isFrame = JOP.Frame.isFrame(item)
            local isPalette = JOP.Palette.isPalette(item.id)
            local isSketchbook = JOP.Sketchbook.isSketchbook(item.id)
            local isRefill = JOP.Refill.isRefillItem(item.id)
            local isEasel = JOP.Easel.getEaselFromMiscId(item.id) ~= nil
            return isPainting or isCanvas or isPaintBrush or isFrame or isPalette or isSketchbook or isRefill or isEasel
        end
    }
}
for _, filter in ipairs(filters) do
    CraftingFramework.ItemFilter.register(filter)
end



---@type CarryableContainer.containerConfig[]
local containers = {
    {
        -- Brown fur
        itemId = "jop_easel_pack_02",
        capacity = 100,
        openFromInventory = callbacks.openFromInventory,
        getWeightModifier = callbacks.getWeightModifier,
        getWeightModifierText = callbacks.getWeightModifierText,
        weightModifier = 0.5,
        onCopyCreated = function (self, data)
            logger:debug("onCopyCreated")
            BackpackService.registerBackpack{
                id = data.copy.id,
                offset = {
                    translation = { x = 8, y = -10, z = 0 },
                    rotation = { x = 270, y = 0, z = 90 },
                    scale = 0.76
                }
            }

            local staticId = JOP.Easel.getSavedStaticId(data.copy.id)
            if not staticId then
                local newStaticEasel = tes3.getObject("jop_field_easel_02"):createCopy{}
                staticId = newStaticEasel.id
                JOP.Easel.saveStaticId{ miscId = data.copy.id, staticId = staticId }
            end
            logger:debug("Registering easel. static id: %s, misc id: %s", staticId, data.copy.id)
            JOP.Easel.registerEasel{
                id = staticId,
                miscItem = data.copy.id,
                doesPack = true,
            }
        end,
        blockWorldActivate = true,
        allowUnfiltered = true,
        filter = "paintingSupplies"
    },
}

for _, container in ipairs(containers) do
    CarryableContainer.register(container)
end


---@param e unequippedEventData
event.register("unequipped", function(e)
    logger:trace("unequipped %s", e.item)
    local container = CarryableContainer:new{ item = e.item, itemData = e.itemData }
    if not container then
        logger:trace("not a carryable container")
        return
    end
    logger:trace("- updating stats on unequip")
    container:updateStats()
end)