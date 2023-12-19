local config = require("MWSE.mods.Danae.adventCalendar.config")
local dateStrings = require("MWSE.mods.Danae.adventCalendar.dateStrings")
local types = require("openmw.types")
local world = require("openmw.world")
local core = require("openmw.core")
local acti = require("openmw.interfaces").Activation
local util = require("openmw.util")
local I = require("openmw.interfaces")

local data = {}

local function getIsOpened(reference)
    return data[reference.id] == true
end


local function setIsOpened(reference, value)
    data[reference.id] = value
    world.players[1]:sendEvent("setBoxData", data)
end
local function getPlayer()
    return world.players[1]
end

local function addGiftsToInventory(gifts)
    for giftId, count in pairs(gifts) do
        local gift = world.createObject(giftId, count)
        if gift then
            gift:moveInto(getPlayer())
        end
    end
    getPlayer():sendEvent("AdventCalendarPlaySound", "Item Misc Up")
end
local function getRecord(id)
    for index, type in pairs(types) do
        if type.record then
            local rec = type.record(id)
            if rec then return rec end
        end
    end
end
local boxToOpen
local boxRefToOpen
--Open the box and give the gifts
--check for the records
for i, boxConfig in pairs(config.boxes) do
for giftId, count in pairs(boxConfig.gifts) do
    local gift = getRecord(giftId)
    if not gift then
        error("Unable to find record: " .. giftId)
    end
end
end
local function openBox(boxRef, boxConfig)
    local itemStrings = {}
    for giftId, count in pairs(boxConfig.gifts) do
        local gift = getRecord(giftId)
        if gift then
            table.insert(itemStrings, string.format("%d x %s", count, gift.name))
        else
            print("no record for " .. giftId)
        end
    end

    getPlayer():sendEvent("AdventCalendarPlaySoundPath", "sound/adventCal/1stDayOfXmas.wav")


    local messageLines = {}
    local dataToSend = {}
    dataToSend.buttons = { config.messages.acceptGifts, "Cancel" }
    dataToSend.winName = boxConfig.message

    dataToSend.message = {}
    --table.insert(dataToSend.message, config.messages.acceptGifts)
    for _, itemString in pairs(itemStrings) do
        table.insert(dataToSend.message, itemString)
    end
    getPlayer():sendEvent("AdventCalendarShowMessageList", dataToSend)
    boxToOpen = boxConfig
    boxRefToOpen = boxRef
end

---Compare the current date to the minimum date
local function checkCanOpen(boxConfig)
  --  if true == true then
   --     return true--for testing
   --- end
    local currentDate = os.date("*t", os.time())
    local minimumDate = boxConfig.minimumDate
    local canOpen = currentDate.month >= minimumDate.month
        and currentDate.day >= minimumDate.day
    return canOpen
end
local function addToTooltip(tooltip, message)
    table.insert(tooltip, message)
end
local function getItemToolTip(item)
    local boxId = item.recordId
    local boxConfig = config.boxes[boxId]
    local messages = {}
    local canOpen = false
    if boxConfig then
        local boxRef = item
        if checkCanOpen(boxConfig) then
            canOpen = true
        else
            local day = dateStrings.days[boxConfig.minimumDate.day]
            local month = dateStrings.months[boxConfig.minimumDate.month]
            addToTooltip(messages, config.messages.cantOpen)
            --addToTooltip(messages, string.format("Open on %s %s", day, month))
        end
    end
    return messages, canOpen
end

acti.addHandlerForType(types.Activator,
    function(object, actor)
        local boxId = object.recordId
        local boxConfig = config.boxes[boxId]
        if boxConfig then
            local boxRef = object
            print("Found Christmas present box: " .. boxId)
            local messageList, canOpen = getItemToolTip(boxRef)
            if canOpen then
                if getIsOpened(boxRef) then
                    getPlayer():sendEvent("AdventCalendarShowMessageList", {
                        buttons = { core.getGMST("sOk") },
                        message = { config.messages.alreadyOpened },
                    })
                else
                    openBox(boxRef, boxConfig)
                end
            else
                getPlayer():sendEvent("AdventCalendarShowMessageList", {
                    buttons = { core.getGMST("sOk") },
                    message = messageList
                })
            end
        end
    end)
local function ButtonClicked(data)
    if boxToOpen and boxToOpen.message == data.name and data.text ~= "Cancel" then
        addGiftsToInventory(boxToOpen.gifts)
        getPlayer():sendEvent("AdventCalendarShowMessage", config.messages.receivedGifts)
        setIsOpened(boxRefToOpen, true)
    elseif boxToOpen then
        print(data.name, data.text)
    end
    if data.winName == "" then

    end
end
local player
local scriptPath = "MWSE/mods/Danae/adventCalendar/omw/acal_tooltip.lua"
local function addScriptToPlayer()
    if not player:hasScript(scriptPath) then
        player:addScript(scriptPath)
        print("Added scr")
    end
end
local function removeScriptFromPlayer()
    if player:hasScript(scriptPath) then
        player:removeScript(scriptPath)
        print("removed scr")
    end
end
local lastCellName
local function onObjectActive(obj)
    local cellName = obj.cell.name
    if lastCellName == cellName then
        return
    end
    if not player then player = getPlayer() end
    if cellName == "Solstheim, Uncle Sweetshare's Workshop" then
        addScriptToPlayer()
    else
        removeScriptFromPlayer()
    end
    lastCellName = cellName
end
return {
    engineHandlers = {
        onSave = function() return { data = data } end,
        onLoad = function(sdata)
            if sdata then
                data = sdata.data
                world.players[1]:sendEvent("setBoxData", data)
            end
        end,
        onObjectActive = onObjectActive,
        onPlayerAdded = onObjectActive,
    },
    eventHandlers = { ButtonClicked = ButtonClicked }
}
