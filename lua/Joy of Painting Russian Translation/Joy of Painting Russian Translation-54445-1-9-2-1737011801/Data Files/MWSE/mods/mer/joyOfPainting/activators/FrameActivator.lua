local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("FrameActivator")
local Painting = require("mer.joyOfPainting.items.Painting")
local Activator = require("mer.joyOfPainting.services.AnimatedActivator")
local Frame = require("mer.joyOfPainting.items.Frame")
local CraftingFramework = require("CraftingFramework")

---@param e equipEventData|activateEventData
local function activate(e)

    local painting = Painting:new{
        reference = e.target,
        item = e.item,
        itemData = e.itemData,
    }
    local frameConfig = Frame.getFrameConfig(painting.item)
    local isPainted = painting:hasPaintingData()
    local safeRef
    if e.target then
        if tes3ui.menuMode() then
            --block picking up from menu to avoid painting in frame in inventory
            return
        end
        safeRef = tes3.makeSafeObjectHandle(painting.reference)
        if safeRef == nil then
            logger:warn("Failed to make safe handle for %s", painting.reference.object.id)
            return
        end
    end
    tes3ui.showMessageMenu{
        message = "Действия с рамкой",
        buttons = {
            {
                text = "Вставить картину",
                callback = function()
                    timer.delayOneFrame(function()
                        if safeRef and not safeRef:valid() then
                            logger:warn("Skipping add painting because reference is invalid")
                            return
                        end

                        local ref = safeRef and safeRef:getObject()
                        if not ref then
                            logger:warn("Skipping add painting because reference is invalid")
                            return
                        end

                        logger:debug("Add Painting")
                        CraftingFramework.InventorySelectMenu.open{
                            title = "Выберите картину",
                            noResultsText = "У вас нет ни одной картины",
                            filter = function(e2)
                                local id = e2.item.id:lower()
                                local painting = Painting:new{
                                    item = e2.item,
                                    itemData = e2.itemData
                                }
                                if not painting:hasPaintingData() then
                                    return false
                                end
                                local canvasConfig = painting:getCanvasConfig()
                                if Frame.isFrame(e2.item) then
                                    logger:debug("Filtering on frame: %s", id)
                                    return false
                                end

                                if frameConfig.frameSize then
                                    logger:debug("Filtering on frame size: %s", frameConfig.frameSize)
                                    if canvasConfig and frameConfig.frameSize ~= canvasConfig.frameSize then
                                        logger:debug("Frame size does not match( %s ~= %s)",
                                            frameConfig.frameSize, canvasConfig.frameSize)
                                        return false
                                    end
                                end
                                if canvasConfig == nil then
                                    return false
                                end
                                logger:debug("Filtering on canvas: %s", id)
                                logger:debug("Frame Size = %s", frameConfig.frameSize)
                                logger:debug("canvas frame size: %s", canvasConfig.frameSize)
                                return true
                            end,
                            callback = function(e2)
                                if not e2.item then return end
                                painting = Painting:new{
                                    reference = ref,
                                    item = e.item,
                                    itemData = e.itemData,
                                }
                                painting:attachCanvas(e2.item, e2.itemData)
                                --Remove the canvas from the player's inventory
                                logger:debug("Removing canvas %s from inventory", e2.item.id)
                                CraftingFramework.CarryableContainer.removeItem{
                                    reference = tes3.player,
                                    item = e2.item.id,
                                    itemData = e2.itemData,
                                    count = 1,
                                    playSound = false,
                                }
                            end,
                        }
                    end)
                end,
                showRequirements = function()
                    return not isPainted
                end,
            },
            {
                text = "Вынуть картину",
                callback = function()
                    timer.delayOneFrame(function()
                        if safeRef and not safeRef:valid() then
                            logger:warn("Skipping remove painting because reference is invalid")
                            return
                        end
                        local ref = safeRef and safeRef:getObject()

                        logger:debug("Remove Painting")
                        painting = Painting:new{
                            reference = ref,
                            item = e.item,
                            itemData = e.itemData,
                        }
                        painting:takeCanvas()
                    end)
                end,
                showRequirements = function()
                    return isPainted
                end,
            },
            {
                text = "Посмотреть картину",
                callback = function()
                    timer.delayOneFrame(function()
                        if safeRef and not safeRef:valid() then
                            logger:warn("Skipping view painting because reference is invalid")
                            return
                        end
                        local ref = safeRef and safeRef:getObject()
                        Painting:new{
                            reference = ref,
                            item = e.item,
                            itemData = e.itemData,
                        }:paintingMenu()
                    end)
                end,
                showRequirements = function()
                    return isPainted
                end,
            },
            {
                text = "Переместить",
                callback = function()
                    if safeRef and not safeRef:valid() then
                        logger:warn("Skipping view painting because reference is invalid")
                        return
                    end
                    local ref = safeRef:getObject()
                    common.positioner{
                        reference = ref,
                        pinToWall = true,
                        placementSetting = "free",
                        blockToggle = true
                    }
                end,
            },
            {
                text = "Взять",
                callback = function()
                    timer.delayOneFrame(function()
                        if safeRef and not safeRef:valid() then
                            logger:warn("Skipping take frame because reference is invalid")
                            return
                        end
                        local ref = safeRef and safeRef:getObject()

                        logger:debug("Take Frame")
                        painting = Painting:new{
                            reference = ref,
                            item = e.item,
                            itemData = e.itemData,
                        }
                        painting:takeCanvas()
                        common.pickUp(ref)
                    end)
                end,
            },
        },
        cancels = true
    }
end

Activator.registerActivator{
    onActivate = activate,
    onPickup = function(e)
        if not e.target then return end
        local painting = Painting:new{
            reference = e.target,
            item = e.item,
            itemData = e.itemData,
        }
        painting:takeCanvas()
    end,
    isActivatorItem = function(e)
        if not e.target then return false end
        return Frame.isFrame(e.object)
    end,
    blockStackActivate = true
}
