local common = require("SSQN.common")
local config = require("SSQN.config")
local iconlist = require("SSQN.iconlist")

local log = common.log
local myMenu = {}
local questData = {}
local qIndex = 0
local qCursor = 1

function myMenu.init()
    myMenu.id_menu = tes3ui.registerID("SSQNMainWindow")
end
--Table of active quest names. Keeps different journal topics with the same quest name from displaying extra notifications
local function initQNames()
    local data = tes3.player.data
    data.SSQN = data.SSQN or {}
end
--returns list of quest names
local function getQListData()
    return tes3.player.data.SSQN
end
--adds a questname to the list
local function addQListData(name)
    local qList = getQListData()
    qList[name] = true
end
--removes a questname from the list
local function removeQListData(name)
    local qList = getQListData()
    qList[name] = nil
end

local function iconpicker()
    local qIDString = questData[qCursor].topic:__tostring()
    --checks for full name of index first as requested, then falls back on finding prefix
    if (iconlist[qIDString] ~= nil) then
        return iconlist[qIDString]
    else
        local loc = nil
        local i = 0
        repeat
            i = i - 1
            loc = string.find(qIDString, "_", i)
        until (loc ~= nil) or (i == -string.len(qIDString))
        local iconID
        if ( loc ~= nil ) then
            loc = loc - 1
            iconID = string.sub(qIDString,1,loc)
        else
            return "\\Icons\\SSQN\\DEFAULT.dds"
        end
        if (iconlist[iconID] ~= nil) then
            return iconlist[iconID]
        else
            return "\\Icons\\SSQN\\DEFAULT.dds" --Default in case no icon is found
        end
    end
end

local function questName(j)
    for i = 1,#j.topic.info do
        if (j.topic.info[i].isQuestName) then
            return j.topic.info[i].text
        end
    end
end

-- Create window and layout
function myMenu.createWindow(qName)
    -- Return if window is already open
    if (tes3ui.findMenu(myMenu.id_menu) ~= nil)  then
        return false
    end
    local titleText

    if (questData[qCursor].info.isQuestFinished) then
        titleText = "Quest Finished:"
        removeQListData(qName)
    elseif (questData[qCursor].new) then
        titleText = "Quest Started:"
    end

    -- Create window
    local menu = tes3ui.createMenu{ id = myMenu.id_menu, fixedFrame = true, modal = false}
    menu.alpha = 0.75
    menu.absolutePosAlignX = config.xlocation * .01
    menu.absolutePosAlignY = config.ylocation * .01

    -- Create layout
    local notificationBlock = menu:createBlock{}
    notificationBlock.autoWidth = true
    notificationBlock.height = 50
    notificationBlock.flowDirection = tes3.flowDirection.leftToRight

    if (config.imageonoff) then
        local imageBlock = notificationBlock:createBlock{}
        imageBlock.height = 48
        imageBlock.width = 48
        imageBlock.borderLeft = 5

        local notificationImage
        if (pcall(function() notificationImage = imageBlock:createImage{ path = iconpicker()} end)) then
            --It's cool bro. Don't do anything
        else
            log:warn(questData[qCursor].topic:__tostring() .. " Icon file not found. Displaying default")
            notificationImage = imageBlock:createImage{ path = "\\Icons\\SSQN\\DEFAULT.dds"}
        end
        notificationImage.imageScaleX = 0.75
        notificationImage.imageScaleY = 0.75
    end

    local textBlock = notificationBlock:createBlock{}
    textBlock.autoHeight = true
    textBlock.minWidth = 200
    textBlock.width = (string.len(qName) * 9 )
    textBlock.flowDirection = tes3.flowDirection.topToBottom

    local typeText = textBlock:createTextSelect{ id = "title", text = titleText}
    typeText.autoHeight = true
    typeText.wrapText = true
    typeText.justifyText = "center"
    typeText.borderBottom = 10

    local questText = textBlock:createTextSelect{ id = "desc", text = qName}
    questText.color = { 0.8, 0.8, 0.85 }
    questText.wrapText = true
    questText.justifyText = "center"

    --update the menu changes
    menu:updateLayout()
    return true
end

local function journalValidate(e)
    --makes sure the journal has a quest name, is a valid index, and is either a finish or new entry
    local qList = getQListData()
    local tempqName = questName(e)
    if (e.info == nil) then
        log:error(e.topic:__tostring() .. " passed an index that doesn't exist")
        return false
    elseif ((not e.info.isQuestFinished) and (not e.new)) then
        return false
    elseif (tempqName == nil) then
        log:info(e.topic:__tostring() .. " Doesnt have a quest name. Not displaying notification by design")
        return false
    elseif ((not e.info.isQuestFinished) and (qList[tempqName])) then
        log:info(e.topic:__tostring() .. "Quest Name already registerd. Not displaying notification")
        return false
    else
        return true
    end
end

local function journalHandler(e)
    if (journalValidate(e)) then
        if ((not config.SSQNFenabled) and (e.info.isQuestFinished)) then
            return
        elseif (((not config.SSQNSenabled) and (e.new)) and (not e.info.isQuestFinished)) then
            return
        else
            qIndex = qIndex + 1
            questData[qIndex] = e
            if (tes3.menuMode()) then
                if (not myMenu["registered"]) then
                    event.register(tes3.event.menuExit, myMenu.display)
                    myMenu["registered"] = true
                end
            else
                local displaytimer = timer.start({
                    type = timer.simulate,
                    iterations = 1,
                    duration = 1,
                    callback = myMenu.display
                })
            end
        end
    end
end

--Clears Menu
function myMenu.clear()
    local menu = tes3ui.findMenu(myMenu.id_menu)
    if (menu) then
        menu:destroy()
        event.trigger("SSQN_popuphasbeencleared")
    end
end

function myMenu.delay()
    local timer = timer.start({
        type = timer.simulate,
        iterations = 1,
        duration = 0.5,
        callback = myMenu.display
    })
end

--Initiates display of Quest Notification
function myMenu.display()
    event.unregister(tes3.event.menuExit, myMenu.display)
    myMenu["registered"] = false
    if (qCursor <= qIndex) then
        local qName = questName(questData[qCursor])
        addQListData(qName)
        if (myMenu.createWindow(qName)) then
            if (config.soundfile ~= "NONE") then
                if (pcall(function () tes3.playSound({
                        soundPath = config.soundfile,
                        reference = tes3.player,}) end)) then
                    --It's cool bro. Don't do anything
                else
                    log:error(questData[qCursor].topic:__tostring() .. "Sound file not found. Did you delete it?")
                end
            end
            local clearTimer = timer.start({
                type = timer.real,
                iterations = 1,
                duration = 5,
                callback = myMenu.clear
            })
            questData[qCursor] = nil
            qCursor = qCursor + 1
        end
    else
        --reset "traversal pointers"
        qCursor = 1
        qIndex = 0
    end
end

event.register("SSQN_popuphasbeencleared", myMenu.delay)
event.register(tes3.event.initialized, myMenu.init)
event.register(tes3.event.loaded, initQNames)
event.register(tes3.event.journal, journalHandler)

dofile("SSQN.mcm")