local config = require("Danae.adventCalendar.config")
local dateStrings = require("Danae.adventCalendar.dateStrings")
local logger = require("logging.logger").new{
    name = "adventCalendar",
    level = "DEBUG",
}

---@param reference tes3reference
local function getIsOpened(reference)
    return reference.data.adventCalenderHasOpened
end

---@param reference tes3reference
---@param value boolean
local function setIsOpened(reference, value)
    reference.data.adventCalenderHasOpened = value
end

---Add the gifts to the player's inventory
---@param gifts table<string, number>
local function addGiftsToInventory(gifts)
    for giftId, count in pairs(gifts) do
        local gift = tes3.getObject(giftId)
        if gift then
            tes3.addItem({
                reference = tes3.player,
                item = gift,
                count = count,
                showMessage = false,
                playSound = false
            })
        end
    end
    tes3.playSound{ sound = "Item Misc Up" }
end

--Open the box and give the gifts
---@param boxRef tes3reference
---@param boxConfig AdventCalendar.BoxConfig
local function openBox(boxRef, boxConfig)
    local itemStrings = {}
    for giftId, count in pairs(boxConfig.gifts) do
        local gift = tes3.getObject(giftId)
        if gift then
            table.insert(itemStrings, string.format("%d x %s", count, gift.name))
        end
    end

    tes3.playSound{ soundPath = "adventCal/1stDayOfXmas.wav"}

    tes3ui.showMessageMenu{
        header = boxConfig.message,
        customBlock = function(parent)
            parent.childAlignX = 0.5
            parent.paddingAllSides = 8
            for _, itemString in ipairs(itemStrings) do
                parent:createLabel{ text = itemString }
            end
        end,
        buttons = {
            {
                ---@diagnostic disable-next-line
                text = config.messages.acceptGifts,
                callback = function()
                    addGiftsToInventory(boxConfig.gifts)
                    tes3.messageBox(config.messages.receivedGifts)
                    setIsOpened(boxRef, true)
                end
            }
        },
        cancels = true,
    }
end

---Compare the current date to the minimum date
local function checkCanOpen(boxConfig)
    local currentDate = os.date("*t")
    local minimumDate = boxConfig.minimumDate
    local canOpen = currentDate.month >= minimumDate.month
        and currentDate.day >= minimumDate.day
    return canOpen
end

---@param e activateEventData
event.register("activate", function(e)
    logger:debug("onactivate")
    local boxId = e.target.object.id:lower()
    local boxConfig = config.boxes[boxId]
    if boxConfig then
        local boxRef = e.target
        logger:debug("Found Christmas present box: %s", boxId)
        if checkCanOpen(boxConfig) then
            if getIsOpened(boxRef) then
                logger:debug("Already opened")
                tes3.messageBox{
                    message = config.messages.alreadyOpened,
                    ---@diagnostic disable-next-line
                    buttons = { tes3.findGMST(tes3.gmst.sOK).value }
                }
            else
                logger:debug("Can open box")
                openBox(boxRef, boxConfig)
            end
        else
            logger:debug("Can't open box")
            tes3.messageBox{
                message = config.messages.cantOpen,
                ---@diagnostic disable-next-line
                buttons = { tes3.findGMST(tes3.gmst.sOK).value }
            }
        end
    end
end)

---@param tooltip tes3uiElement
---@param message string
local function addToTooltip(tooltip, message)
    tooltip:createLabel{ text = message }
    tooltip:reorderChildren(1, -1, 1)
end

---@param e uiObjectTooltipEventData
event.register("uiObjectTooltip", function(e)
    local boxId = e.object.id:lower()
    local boxConfig = config.boxes[boxId]
    if boxConfig then
        local boxRef = e.reference
        if checkCanOpen(boxConfig) then
            if getIsOpened(boxRef) then
                addToTooltip(e.tooltip, config.messages.alreadyOpened )
            else
                addToTooltip(e.tooltip, config.messages.canOpen )
            end
        else
            local day = dateStrings.days[boxConfig.minimumDate.day]
            local month = dateStrings.months[boxConfig.minimumDate.month]
            addToTooltip(e.tooltip, string.format("Open on %s %s", day, month))
        end
    end
end, { priority = -1000 })